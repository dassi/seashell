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


  def installed_version_of_package(package_name)
    script = "output := (MCPackage named: '#{package_name}') workingCopy description"
    version = run_gs(script, :commit => false)
    version
  end
  
  
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
      version = installed_version_of_package(monticello_package_name)
      say "Current installed version is: #{version}"
    end

    desc 'Show the newest available version'
    task :newest do
      version = get_monticello_versions.first
      say "Newest version is: #{version}"
    end
    
  end
  
  
  namespace :glass do
    desc 'Show the installed GLASS version'
    task :version do
      version = installed_version_of_package('GLASS')
      say "Current installed version of GLASS is: #{version}"
    end
  end
  

end
