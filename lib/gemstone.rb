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
      run 'startGemstone'
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
      run 'runSeasideGems start'
    end

    desc 'Stop the seaside gems cluster'
    task :stop do
      run 'runSeasideGems stop'
    end

    desc 'Restart the seaside gems cluster'
    task :restart do
      run 'runSeasideGems restart'
    end

  end


  desc 'Runs gslist on server and displays the information'
  task :gslist do
    run 'gslist -v'
  end
  
  # Will install Gemstone on a fresh server
  task :install do
    # OK, this is not tested! And most likely needs more stuff to really work...
    run 'wget http://seaside.gemstone.com/scripts/installGemstone2.3-Linux.sh'
    run 'chmod 700 installGemstone2.3-Linux.sh'
    run 'installGemstone2.3-Linux.sh'
  end
end


# Executes smalltalk code on gemstone via topaz
def run_gs(smalltalk_code)

  topaz_script = <<-TEXT
set gemstone #{stone}
set username #{gemstone_user}
set password #{gemstone_password}
login
output pushnew topaz_script.log
printit
#{smalltalk_code}
%
logout
exit
TEXT

  # Run smalltalk script via topaz, ignoring standard ini-file and quieting output of topaz.
  put topaz_script, 'topaz_script.tmp'
  run "topazl -q -i < topaz_script.tmp && rm topaz_script.tmp"

end
