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

  namespace :version do
    desc 'Lists all available versions from the monticello repository'
    task :all do
      say "All available versions are: #{get_monticello_versions.join(', ')}"
    end

    desc 'Show the currently installed version'
    task :installed do
      script = "output := (MCPackage named: '#{monticello_package_name}') workingCopy description"
      version = run_gs(script, false)
      say "Current installed version is: #{version}"
    end

    desc 'Show the newest available version'
    task :newest do
      version = get_monticello_versions.first
      say "Newest version is: #{version}"
    end
    
  end
  

end
