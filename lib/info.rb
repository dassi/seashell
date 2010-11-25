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
    
    
    desc 'Show the memory usage of the stone'
    task :show_memory_usage do
      code = <<-SMALLTALK
| ar totalSize instances sizes infoArray |
instances := IdentityDictionary new.
sizes := IdentityDictionary new.
totalSize := 0.
System _generationScavenge_vmMarkSweep.
ar := System _vmInstanceCounts: 3. "old space"
ar associationsDo: [:assoc |
  instances 
      at: assoc key name "class"
      put: (assoc value at: 1). "instance count"
 totalSize := totalSize + (assoc value at: 2).
  sizes 
       at: assoc key name "class"
      put: (assoc value at: 2) "total bytes" ].
infoArray := { "label"
       '75% full'.
   "total size of objects in temporary object space"
       totalSize.
   "sorted list of classes and their total size in bytes"
       sizes associations sortWithBlock: [:a :b | 
           a value >= b value ].
   "sorted list of clases and their instance counts"
       instances associations sortWithBlock: [:a :b | 
           a value >= b value ]}.
output := infoArray printString.
SMALLTALK

      say(run_gs(code, :commit => false))

    end

    desc 'Show the memory usage of the stone'
    task :show_memory_usage2 do
      # Just for the actual session, so not really helpful!
      code = <<-SMALLTALK
output := System _tempObjSpacePercentUsed printString
SMALLTALK

      say(run_gs(code, :commit => false))

    end
    
  end

  namespace :seaside do
    desc 'Show the installed seaside version'
    task :version do
      version = installed_version_of_package('Seaside2')
      say "Current installed version of Seaside is: #{version}"
    end
  end

end
