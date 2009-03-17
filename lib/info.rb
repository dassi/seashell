#
# SeaShell
#
# Capistrano deployment recipes for seaside platforms
#
# Author: Andreas Brodbeck, mindclue gmbh, www.mindclue.ch
# Licence: MIT (see LICENSE file)
#                                          

#
# Tasks for getting general information about the server
#

namespace :info do

  desc 'Shows the environment of the server which is active when capistrano does work'
  task :env do
    run 'env | sort'
  end

end
