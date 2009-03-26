#
# SeaShell
#
# Capistrano deployment recipes for seaside platforms
#
# Author: Andreas Brodbeck, mindclue gmbh, www.mindclue.ch
# Licence: MIT (see LICENSE file)
#

#
# Generic configurations file
#

# Some helper variables
set :path_application, "#{path_base}/applications/#{application}"
set :path_data, "#{path_application}/data"
set :path_web_root, "#{path_application}/web_root"
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
  'GEMS' => gem_ports.join(' '),                                      # Listing of the local ports, each running one application instance gem
  'HOME' => path_application
}
