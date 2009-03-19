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
  task :status do
    run 'gslist -vx'
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
# In your Smalltalk code you can use the implicit variable "output" to set content which is returned to seashell
def run_gs(smalltalk_code, commit = true)
  
  output_filename = 'seashell_output.txt'

  # Remove possible whitespaces at begin and end od script
  smalltalk_code.strip!
  
  # For correct syntax we need a "." at the end of the given Smalltalk code piece (which will be embedded in some utility Smalltalk code)
  if smalltalk_code[-1,1] != '.'
    smalltalk_code << '.'
  end

  # Manipulate the first line, if it contains variable declarations of Smalltalk we need to inject our "output" variable
  # OPTIMIZE: Is there no String#lines ?! Do I really have to use this StringIO-workaround?!
  if StringIO.new(smalltalk_code).readlines.first =~ /^.*\|.*\|.*$/
    # Inject out "output" variable name in the declaration
    smalltalk_code.gsub!(/^.*\|(.*)\|.*$/, '| \1 output |')
    declaration_code = nil
  else
    declaration_code = '| output |'
  end
  
  # Automatically add a commit command?
  if commit
    commit_code = 'System commitTransaction.'
  else
    commit_code = nil
  end

  # Important! Don't indent the following script, as the "%" sign needs to come without indentation for topaz!
  topaz_script = <<-TEXT
set gemstone #{stone}
set username #{gemstone_user}
set password #{gemstone_password}
login
output push topaz_script.log
printit
#{declaration_code}
#{smalltalk_code}
#{commit_code}
(GsFile openWriteOnServer: '#{output_filename}')
  nextPutAll: output asString;
  close.
%
logout
exit
TEXT

  # Run smalltalk script via topaz, ignoring standard ini-file and quieting output of topaz.
  put topaz_script, 'topaz_script.tmp'
  begin
    run "topazl -q -i < topaz_script.tmp > /dev/null"
  rescue CommandError
    # On a topaz error exit code, we display the output of topaz (which has been logged in the background)
    trace 'Topaz error!!!'
    run 'cat topaz_script.log'
    raise
  end

  # Get the output text file and read it
  begin
    get output_filename, output_filename
    output = File.read(output_filename)
    File.delete(output_filename)
  rescue
    output = ''
  end

  # Clean up on server
  run "rm topaz_script.tmp #{output_filename}"

  # Return the value coming from topaz
  output

end
