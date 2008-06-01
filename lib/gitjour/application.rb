require 'rubygems'
require 'dnssd'
require 'main'
require 'set'
Thread.abort_on_exception = true

module Gitjour
  GitService = Struct.new(:name, :host, :description)

  Application = Main.create do

    run { help! }

    description "Serve up and use git repositories via Bonjour/DNSSD."

    examples <<-TXT
      gitjour help
      gitjour help <command>
    TXT

    mode "list" do
      description "list the available repositories shared via Bonjour"

      run do
        service_list.each do |service|
          puts "=== #{service.name} on #{service.host} ==="
          puts "  gitjour clone #{service.name}"
          puts "  #{service.description}" if service.description && service.description != '' && service.description !~ /^Unnamed repository/
          puts
        end
      end
    end

    mode "clone" do
      description "clone a repository via gitjour"

      argument "repository_name" do
        required
        attribute # make it available in local scope
      end

      run do
        host, name_of_share = get_host_and_share(repository_name)
        system("git clone git://#{host}/ #{name_of_share}/")
      end
    end

    mode "serve" do
      description "Serve a git repository via Bonjour"

      argument "path" do
        description "The directory containing one or more git repositories to serve"
        default '.'
      end

      option "n", "name" do
        description "an alternate name to share the repository as (only works when serving a single repo)"
        argument_optional
        attribute "share_name"
      end

      run do
        path = File.expand_path(params["path"].value)
        if File.exists?("#{path}/.git")
          announce_repo(path, share_name)
        else
          Dir["#{path}/*"].each{|dir| announce_repo(dir) if File.directory?(dir)}
        end
        `git-daemon --verbose --export-all --base-path=#{path} --base-path-relaxed`
      end
    end

    mode "remote" do
      description "Add a gitjour remote into your current repository"

      argument "repository_name" do
        description "The repository to add as a remote"
        required
        attribute
      end

      run do
        host, name_of_share = get_host_and_share(repository_name)
        system("git remote add #{name_of_share} git://#{host}/")
      end
    end

  end

  class Application

    private

      def get_host_and_share(repository_name)
        name_of_share = repository_name || fail("You have to pass in a name")
        host = service_list(name_of_share).detect{|service| service.name == name_of_share}.host rescue exit_with!("Couldn't find #{name_of_share}")
        system("git clone git://#{host}/ #{name_of_share}/")
        [host, name_of_share]
      end

      def exit_with!(message)
        STDERR.puts message
        exit!
      end

      def service_list(looking_for = nil)
        wait_seconds = 5

        service_list = Set.new
        waiting_thread = Thread.new { sleep wait_seconds }

        service = DNSSD.browse "_git._tcp" do |reply|
          DNSSD.resolve reply.name, reply.type, reply.domain do |resolve_reply|
            service_list << GitService.new(reply.name, resolve_reply.target, resolve_reply.text_record['description'])
            if looking_for && reply.name == looking_for
              waiting_thread.kill
            end
          end
        end
        puts "Searching for repositories for up to #{wait_seconds} seconds..."
        waiting_thread.join
        service.stop
        service_list
      end

      def announce_repo(path, share_name = nil)
        return unless File.exists?("#{path}/.git")
        name = share_name || File.basename(path)
        tr = DNSSD::TextRecord.new
        tr['description'] = File.read(".git/description") rescue "a git project"
        DNSSD.register(name, "_git._tcp", 'local', 9148, tr.encode) do |register_reply|
          puts "Registered #{name}.  Starting service."
        end
      end

  end
end



