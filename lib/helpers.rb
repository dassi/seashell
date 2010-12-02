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


# def update_configuration_of_metacello_project(project_name, repository_url, repository_user, repository_password)
#   install_monticello_version("ConfigurationOf#{project_name}", repository_url, repository_user, repository_password)
# end


# Gets a list of available monticello versions (via topaz)
def get_metacello_versions(project_name)

  output_filename = "metacello_versions.txt"
  output_filepath_server = "#{path_application}/#{output_filename}"
  
  # Get versions from monticello and list them in a file
  smalltalk_code = <<-SMALLTALK
    | httpRepository versions myFile |
    versions := Gofer project
      repository: '#{metacello_repository_url}' username: '#{metacello_repository_user}' password: '#{metacello_repository_password}';
      availableVersionsOf: '#{project_name}'.
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
  
  # Delete the temporary transfer files
  run "rm #{output_filepath_server}"
  File.delete(output_filename)

  versions
end


# Loads a metacello project version from the repository
def install_metacello_version(project_name, version_name = nil, group_names = nil, options = {})

  group_names ||= []

  version_parameter = version_name && "version: '#{version_name}'"
  
  group_names_string = group_names.collect{ |gn| "'#{gn}'" }.join(' ')
  if group_names.any?
    group_parameter = "group: #(#{group_names_string})"
  else
    group_parameter = nil
  end
  
  # Build smalltalk script
  # (Setting autoCommit is needed if loading from Topaz)
  metacello_load_script = <<-SMALLTALK
    | autoCommit |
    autoCommit := MCPlatformSupport autoCommit.
    MCPlatformSupport autoCommit: true.
    MCPlatformSupport commitOnAlmostOutOfMemoryDuring: [
      [Gofer project
        repository: '#{metacello_repository_url}' username: '#{metacello_repository_user}' password: '#{metacello_repository_password}';
        load: '#{project_name}' #{version_parameter} #{group_parameter}]
        on: Warning
        do: [:ex |
          Transcript cr; show: ex description.
          ex resume ]].
    MCPlatformSupport autoCommit: autoCommit.
  SMALLTALK

  # Debug: Show the script:
  # Capistrano::CLI.ui.say(monticello_load_script)

  if options[:force] or Capistrano::CLI.ui.agree("Really load version #{version_name} of #{project_name}?")
    run_gs(metacello_load_script)
    say "...loaded."
  else
    say "...loading aborted!"
  end
end


# Executes smalltalk code on gemstone via topaz
# In your Smalltalk code you can use the implicit variable "output" to set content which is returned to seashell
def run_gs(smalltalk_code, options = {})
  
  options[:working_dir] ||= path_application

  output_filename = 'seashell_output.txt'
  working_dir = options[:working_dir]

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
iferr 1 stk
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

  say('Performing Smalltalk code on the server...')
  run_topaz_script(topaz_script, options)

  # Get the output text file and read it
  begin
    get "#{working_dir}/#{output_filename}", output_filename
    output = File.read(output_filename)
    File.delete(output_filename)
  rescue
    output = ''
  end

  # Clean up on server
  run "cd #{working_dir} && rm #{output_filename}"

  # Return the value coming from topaz
  output

end


def run_topaz_script(topaz_script, options = {})

  working_dir = options[:working_dir] || path_application
  
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

  if is_debug_mode
    trace topaz_script
    run "cd #{working_dir} && cat topaz_script.log"
  end

  # Clean up on server
  run "cd #{working_dir} && rm topaz_script.tmp topaz_script.log"
  
end