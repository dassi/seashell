#
# SeaShell
#
# Capistrano deployment recipes for seaside platforms
#
# Author: Andreas Brodbeck, mindclue gmbh, www.mindclue.ch
# Licence: MIT (see LICENSE file)
#


set :is_debug_mode, false

task :debug_mode do
  set :is_debug_mode, true
end