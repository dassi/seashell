#
# SeaShell
#
# Capistrano deployment recipes for seaside platforms
#
# Author: Andreas Brodbeck, mindclue gmbh, www.mindclue.ch
# Licence: MIT (see LICENSE file)
#

#
# Some general helper methods
#


# Show the +message+ in the capistrano trace output
def trace(message)
  logger.trace(message) if logger
end


# Show the +message+ on the shell output, highlighted with a color to be important.
def say(message)
  Capistrano::CLI.ui.say("<%= color(\"#{message}\", :green) %>")
end

# Show the +question+ on the shell output, asking for an answer.
def ask(question, default = nil)
  Capistrano::CLI.ui.ask(question) do |q|
    q.default = default
  end
end

# Show the +question+ on the shell output, asking for an answer. Answer is masked, useful for password input and similar secret data.
def ask_password(question, default = nil)
  Capistrano::CLI.ui.ask(question) do |q|
    q.echo = false
    q.default = default
  end
end




# Gets a list of available monticello versions (via topaz)
def get_monticello_versions(repository_url, repository_user, repository_password, exclude_package_prefix = nil, include_package_prefix = nil)

  output_filename = "monticello_versions.txt"
  output_filepath_server = "#{path_application}/#{output_filename}"
  
  # Get versions from monticello and list them in a file
  smalltalk_code = <<-SMALLTALK
    | httpRepository versions myFile |
    httpRepository := MCHttpRepository
        location: '#{repository_url}'
        user: '#{repository_user}'
        password: '#{repository_password}'.
    versions := httpRepository readableFileNames.
    myFile := GsFile openWriteOnServer: '#{output_filepath_server}'.
    versions do: [:each | 
        myFile nextPutAll: each.
        myFile cr.].
    myFile close.
  SMALLTALK

  run_gs(smalltalk_code, :commit => false)

  # Download the file with the list
  get output_filepath_server, output_filename

  # Read in the version names from the text file
  versions = File.readlines(output_filename, "\n").collect{ |s| s.strip }
  
  # Optionally filter out package names
  if include_package_prefix
    versions.reject! { |v| not (v[0, include_package_prefix.size] == include_package_prefix) }
  end
  if exclude_package_prefix
    versions.reject! { |v| v[0, exclude_package_prefix.size] == exclude_package_prefix }
  end

  # Delete the temporary transfer files
  run "rm #{output_filepath_server}"
  File.delete(output_filename)

  versions
end

# Loads the version +file+ from the repository
def install_monticello_version(file, repository_url, repository_user, repository_password)

  monticello_load_script = <<-SMALLTALK
    | httpRepository version rg |
    MCPlatformSupport autoMigrate: true.
    httpRepository := MCHttpRepository
        location: '#{repository_url}'
        user: '#{repository_user}'
        password: '#{repository_password}'.
    "pick up the repository if it's already
     in default repository group"
    MCRepositoryGroup default repositoriesDo: [:rep |
        rep = httpRepository ifTrue: [ httpRepository := rep ]].
    version := httpRepository loadVersionFromFileNamed: '#{file}'.
    version load.
    rg := version workingCopy repositoryGroup.
    rg addRepository: httpRepository.
  SMALLTALK

  # Debug: Show the script:
  # Capistrano::CLI.ui.say(monticello_load_script)

  if Capistrano::CLI.ui.agree("Really load version #{file}?")
    run_gs(monticello_load_script)
    say "Version #{file} loaded"
  else
    say "Loading aborted"
  end
end


# Executes smalltalk code on gemstone via topaz
# In your Smalltalk code you can use the implicit variable "output" to set content which is returned to seashell
def run_gs(smalltalk_code, options = {})
  
  output_filename = 'seashell_output.txt'
  working_dir = options[:working_dir] || path_application

  options[:commit] ||= true
  
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
  if options[:commit]
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
  put topaz_script, "#{working_dir}/topaz_script.tmp"
  begin
    run "cd #{working_dir} && topazl -q -i < topaz_script.tmp > /dev/null"
  rescue CommandError
    # On a topaz error exit code, we display the output of topaz (which has been logged in the background)
    trace 'Topaz error!!!'
    run "cd #{working_dir} && cat topaz_script.log"
    raise
  end

  # Get the output text file and read it
  begin
    get "#{working_dir}/#{output_filename}", output_filename
    output = File.read(output_filename)
    File.delete(output_filename)
  rescue
    output = ''
  end

  if is_debug_mode
    trace smalltalk_code
    run "cd #{working_dir} && cat topaz_script.log"
  end

  # Clean up on server
  run "cd #{working_dir} && rm topaz_script.tmp topaz_script.log #{output_filename}"

  # Return the value coming from topaz
  output

end
