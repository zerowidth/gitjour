# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

load 'tasks/setup.rb'

ensure_in_path 'lib'
require 'gitjour'

task :default => 'spec:run'

PROJ.name = 'gitjour'
PROJ.version = "6.1.0"
PROJ.description = "Automates DNSSD-powered serving and cloning of git repositories."
PROJ.authors = ['Chad Fowler', 'Rich Kilmer', 'Evan Phoenix']
PROJ.email = "chad@chadfowler.com"
PROJ.url = 'http://github.com/chad/gitjour/tree'
PROJ.rubyforge.name = 'gitjour'

PROJ.rdoc.opts = ['--quiet', '--title', 'gitjour documentation',
  "--opname", "index.html",
  "--line-numbers", 
  "--main", "README",
  "--inline-source"]

PROJ.spec.opts << '--format specdoc --color'

depend_on "dnnsd", ">= 0.6.0"