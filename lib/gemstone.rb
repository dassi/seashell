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
      run "cd #{path_application} && umask 0002 && startGemstone"
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

      timestamp = Time.now.strftime('%Y%m%d_%H%M')
      # We use our own modified version of the runBackup script of the GemStone distribution, since that one has fixed pathes inside.
      code = <<-SMALLTALK
        | status |
        status := 'failed'.
        [
          GsFile gciLogServer: DateAndTime now printString.
          GsFile gciLogServer: 'Performing backup from SeaShell...'.
          (System suspendCheckpointsForMinutes: 5)
            ifTrue: [
              System performOnServer: 'cp #{path_data}/extent0.dbf #{path_backups}/backup_#{timestamp}.dbf'.
              status := 'success'.
            ].
        ] ensure: [ System resumeCheckpoints].
        GsFile gciLogServer: DateAndTime now printString.
        GsFile gciLogServer: '...backup status: ', status.
        output := status.
        SMALLTALK
        
        say("Starting backup...")
        status = run_gs(code)
        say("...backup #{status}")
    end
    
    desc 'EXPERIMENTAL. Clean memory and give statistics'
    task :memory_maintenance do
      code = <<-SMALLTALK
Repository markForCollection
SMALLTALK

      run_gs(code)
    end
    

  end

  # Tasks related to gems
  namespace :gems do

    task :configure_runner do
      name = gems_seaside_adaptor
      adaptor_class_name = case gems_seaside_adaptor.downcase.to_sym
      when :swazoo
        'WAGsSwazooAdaptor'
      when :fastcgi
        'WAFastCGIAdaptor'
      else
        raise "Unknown seaside adaptor #{gems_seaside_adaptor}"
      end

      code = <<-SMALLTALK
WAGemStoneRunSeasideGems default
  name: '#{name}';
  adaptorClass: #{adaptor_class_name};
  ports: #(#{gem_ports.join(' ')}).
SMALLTALK

      run_gs(code)

    end

    desc 'Start the seaside gems cluster'
    task :start do
      configure_runner
      run "cd #{path_application} && umask 0002 && runSeasideGems30 start #{gems_seaside_adaptor} #{gem_ports.join(' ')}"
    end

    desc 'Stop the seaside gems cluster'
    task :stop do
      configure_runner
      run "cd #{path_application} && runSeasideGems30 stop #{gems_seaside_adaptor} #{gem_ports.join(' ')}"
    end

    desc 'Restart the seaside gems cluster'
    task :restart do
      configure_runner
      run "cd #{path_application} && runSeasideGems30 restart #{gems_seaside_adaptor} #{gem_ports.join(' ')}"
    end

  end

  # Tasks related to GLASS
  namespace :glass do

    desc 'Updates GLASS package'
    task :update do
      say('Prefered way of doing this is via GemTools for now')
      # glass_repository_url = 'http://seaside.gemstone.com/ss/GLASS'
      # available_versions = get_monticello_versions(glass_repository_url, '', '')
      # available_glass_versions = available_versions.select { |v| v.include?('GLASS') }
      # monticello_file = Capistrano::CLI.ui.choose(*available_glass_versions[0..20])
      # install_monticello_version(monticello_file, glass_repository_url, '', '')
    end
    
    desc 'Installs latest Seaside'
    task :install_seaside do

      groups = ['Base']
      groups.concat(seaside_project_required_groups)
      
      if is_production
        # do nothing
      else
        groups << 'Development'
      end
      
      # The server adaptor which is used by the project
      case gems_seaside_adaptor
        when 'swazoo'
          groups << 'Seaside-Adaptors-Swazoo'
        when 'fastcgi'
          groups << 'Seaside-Adaptors-FastCGI'
      end

      install_metacello_version('Seaside30', nil, groups)
    end
      
  end

  desc 'Displays the status information'
  task :status do
    run 'gslist -vx'
  end
  
end


