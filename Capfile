#
# SeaShell
#
# Capistrano deployment recipes for seaside platforms
#
# Author: Andreas Brodbeck, mindclue gmbh, www.mindclue.ch
# Licence: MIT (see LICENSE file)
#                                          

# Load stages configuration
# TODO: Read stage names automatically from files in that directory
set :stages, Dir["stages/*.rb"].map { |f| File.basename(f, ".rb") }
# set :stages, %w(production development)
set :default_stage, 'development'
set :stage_dir, 'stages'
require 'capistrano/ext/multistage'
       
# Implicitly load the common config file after loading stage configs
for stage_name in stages
  after stage_name do
    load 'lib/config.rb'
  end
end    



# Load tasks from libraries
load 'lib/helpers.rb'
load 'lib/seashell.rb'
load 'lib/lighty.rb'
load 'lib/gemstone.rb'
load 'lib/seaside.rb'
load 'lib/deploy.rb'
load 'lib/info.rb'

# At last, load in project specific tasks, if any.
load 'tasks.rb' if File.exists?('tasks.rb')
