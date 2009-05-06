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

# Sets a variable only if not already set.
def default_set(var_name, *args)
  if not exists?(var_name.to_sym)
    set var_name.to_sym, *args
  end
end

# Some helper variables
default_set :path_application, "#{path_base}/applications/#{application}"
default_set :path_logs, "#{path_application}/logs"
default_set :path_data, "#{path_application}/data"
default_set :path_backups, "#{path_data}/backups"
default_set :path_web_root, "#{path_application}/web_root"
default_set :stone, application

set :gem_ports, (gems_start_port..(gems_start_port + gems_count - 1)).to_a

# set capistrano hostname for the "app" role
role :app, host

# Whether to use sudo for all shell commands
set :use_sudo, false

# Gemstone environment settings
set :default_environment, {
  'GEMSTONE' => path_gemstone,                                        # Path to the Gemstone product directory
  'GEMSTONE_USER' => user,                                            # Linux username of GemStone administrator
  'GEMSTONE_LOGDIR' => path_logs,                                     # Log dir
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
