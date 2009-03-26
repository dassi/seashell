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
  # Capistrano::CLI.password_prompt("Password for gemstone user #{gemstone_user}: ")
  Capistrano::CLI.ui.ask("Password for gemstone user #{gemstone_user}: ") do |q|
    q.echo = false
    q.default = "swordfish"
  end
end

# Monticello repository
set :monticello_repository_url, 'http://www.yourserver.com/mySeasideApp'
set :monticello_repository_user, 'squeak'
set :monticello_repository_password do
  # Capistrano::CLI.password_prompt("Password for Monticello user #{monticello_repository_user}: ")
  Capistrano::CLI.ui.ask("Password for Monticello user #{monticello_repository_user}: ") do |q|
    q.echo = false
    q.default = "seaside"
  end
end

# Configuration of gems, running one application instance each
# (Don't forget to renew the web server configuration, if you change this!)
set :gems_start_port, 9001
set :gems_count, 3

# Configure your seaside entry points here, as a hash with {YourRootComponent => 'entry-point-name', ...}
set :entry_points, {'VGApplicationComponent' => 'vegl'}
