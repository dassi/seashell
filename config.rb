#
# SeaShell
#
# Capistrano deployment recipes for seaside platforms
#
# Author: Andreas Brodbeck, mindclue gmbh, www.mindclue.ch
# Licence: MIT (see LICENSE file)
#                                          

###################################################################################################
# Configuration (Edit for your project!)
#

# Name of the application (No whitespace!)
set :application, 'mySeasideApp'

# Domain of the deployed application (Example: www.myhost.com)
set :domain, 'www.myseasideapp.com'

# Hostname of your server. Your deployed application runs there.
set :host, 'myseasideapp.com'

# User and group which is used for logging into the server
set :user, 'glass'
set :user_group, 'adm'

# Some pathes on the server
set :path_base, '/opt/gemstone'
set :path_gemstone, "#{path_base}/product"
set :path_seaside, "#{path_gemstone}/seaside"
set :path_lighty_application_configs, '/etc/lighttpd/seaside_applications'

# User and password for Gemstone
set :gemstone_user, 'DataCurator'
set :gemstone_password do
  Capistrano::CLI.ui.ask("Password for gemstone user #{gemstone_user}: ")
end

# Monticello repository
set :monticello_repository_url, 'http://www.yourserver.com/mySeasideApp'
set :monticello_repository_user, 'squeak'
set :monticello_repository_password do
  Capistrano::CLI.ui.ask("Password for Monticello user #{monticello_repository_user}: ")
end

# Configuration of gems, running one application instance each
# (Don't forget to renew the web server configuration, if you change this!)
set :gems_start_port, 9001
set :gems_count, 3


 

###################################################################################################
# No need to edit this file below here (except nerds, of course)
#

# Some helper variables
set :path_application, "#{path_base}/applications/#{application}"
set :path_data, "#{path_application}/data"
set :gem_ports, (gems_start_port..(gems_start_port + gems_count - 1)).to_a

if not exists?(:stone)
  set :stone, application
end

# set capistrano hostname for the "app" role
role :app, host

# Whether to use sudo for all shell commands
set :use_sudo, false

# Gemstone environment settings
set :default_environment, {
  'GEMSTONE' => path_gemstone,                                        # Path to the Gemstone product directory
  'GEMSTONE_USER' => user,                                            # Linux username of GemStone administrator
  'GEMSTONE_LOGDIR' => path_data,                                     # Log dir
  'GEMSTONE_NAME' => stone,                                           # Stone name
  'GEMSTONE_DATADIR' => path_data,                                    # Data dir
  'GEMSTONE_KEYFILE' => "#{path_seaside}/etc/gemstone.key",           # Path to the Gemstone Web Edition keyfile (Same for all applications!)
  'GEMSTONE_SYS_CONF' => "#{path_seaside}/data/system.conf",          # Path to Gemstone system config file (Same for all applications!)
  'GEMSTONE_EXE_CONF' => "#{path_seaside}/data",                      # Path to Gemstone executable config directory
  'PATH' => "#{path_gemstone}/bin:#{path_seaside}/bin:$PATH",         # Path to Gemstone binaries
  'LD_LIBRARY_PATH' => "#{path_gemstone}/lib:$LD_LIBRARY_PATH",       # Gemstone library path
  'DYLD_LIBRARY_PATH' => "#{path_gemstone}/lib:$DYLD_LIBRARY_PATH",   # MacOSX library path
  'GEMS' => gem_ports.join(' ')                                       # Listing of the local ports, each running one application instance gem
}
