#
# SeaShell
#
# Capistrano deployment recipes for seaside platforms
#
# Author: Andreas Brodbeck, mindclue gmbh, www.mindclue.ch
# Licence: MIT (see LICENSE file)
#                                          

#
# Tasks for Gemstone system
#


# Convenience meta-tasks. Starting, stopping the whole application (Stone and gems).
desc 'Start the application'
task :start do
  find_and_execute_task('gemstone:stone:start')
  find_and_execute_task('gemstone:gems:start')
end

desc 'Restart the application'
task :restart do
  find_and_execute_task('stop')
  find_and_execute_task('start')
end

desc 'Stop the application'
task :stop do
  find_and_execute_task('gemstone:gems:stop')
  find_and_execute_task('gemstone:stone:stop')
end


# Tasks for the Gemstone system
namespace :gemstone do

  # Tasks related to stone
  namespace :stone do
    desc 'Start Gemstone stone'
    task :start do
      run "cd #{path_application} && startGemstone"
    end

    desc 'Stop Gemstone stone'
    task :stop do
      run 'stopGemstone'
    end

    desc 'Restart Gemstone stone'
    task :restart do
      run 'stopGemstone'
      run 'startGemstone'
    end

    desc 'Make a backup of the data'
    task :backup do
      run 'runBackup'
    end

  end

  # Tasks related to gems
  namespace :gems do
    desc 'Start the seaside gems cluster'
    task :start do
      run "cd #{path_application} && runSeasideGems start"
    end

    desc 'Stop the seaside gems cluster'
    task :stop do
      run "cd #{path_application} && runSeasideGems stop"
    end

    desc 'Restart the seaside gems cluster'
    task :restart do
      run "cd #{path_application} && runSeasideGems restart"
    end

  end

  # Tasks related to GLASS
  namespace :glass do

    desc 'Updates GLASS package'
    task :update do
      glass_repository_url = 'http://seaside.gemstone.com/ss/GLASS'
      available_versions = get_monticello_versions(glass_repository_url, '', '')
      available_glass_versions = available_versions.select { |v| v.include?('GLASS') }
      monticello_file = Capistrano::CLI.ui.choose(*available_glass_versions[0..20])
      install_monticello_version(monticello_file, glass_repository_url, '', '')
    end
    
    desc 'updates GLASS, if its older than Version 187'
    task :update_from_pre_187 do
      # TODO: Run the following code. Only if version is pre GLASS.187, which is the case on a fresh GLASS 2.3.1 repository.

      smalltalk_code = <<-SMALLTALK
| httpRepository version rg |
SystemChangeAnnouncement 
    compileMethod: 'item: ignored' 
    category: 'accessing'.
MCPlatformSupport autoMigrate: false.
httpRepository := MCHttpRepository
    location: 'http://seaside.gemstone.com/ss/GLASS'
    user: ''
    password: ''.
"pick up the GLASS repository if it's already
 in default repository group"
MCRepositoryGroup default repositoriesDo: [:rep |
    rep = httpRepository ifTrue: [ httpRepository := rep ]].
version := httpRepository
    loadVersionFromFileNamed: 'GLASS.230-dkh.187.mcz'.
version load.
rg := version workingCopy repositoryGroup.
rg addRepository: httpRepository.
MCPlatformSupport autoMigrate: true.
System commitTransaction.      
SMALLTALK

      run_gs(smalltalk_code)
    end
      
  end

  desc 'Displays the status information'
  task :status do
    run 'gslist -vx'
  end
  
  # Will install Gemstone on a fresh server
  # TODO!
  task :install do
    # OK, this is not tested! And most likely needs more stuff to really work...
    run 'wget http://seaside.gemstone.com/scripts/installGemstone2.3-Linux.sh'
    run 'chmod 700 installGemstone2.3-Linux.sh'
    run 'installGemstone2.3-Linux.sh'
  end
end


