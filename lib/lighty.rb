#
# SeaShell
#
# Capistrano deployment recipes for seaside platforms
#
# Author: Andreas Brodbeck, mindclue gmbh, www.mindclue.ch
# Licence: MIT (see LICENSE file)
#                                          

#
# Tasks for lighttpd web server aka "lighty"
#

namespace :lighty do

  desc 'Start lighttpd'
  task :start do
    sudo '/etc/init.d/lighttpd start'
  end

  desc 'Restart lighttpd'
  task :restart do
    sudo '/etc/init.d/lighttpd restart'
  end

  desc 'Stop lighttpd'
  task :stop do
    sudo '/etc/init.d/lighttpd stop'
  end

  desc 'Creates the lighty configuration files on the server'
  task :setup do

    # Beginning of configuration
    lighty_config = <<-TEXT
$HTTP["host"] == "#{domain}" {
  server.document-root = "#{path_application}/web_root"
  #server.errorlog = "#{path_application}/logs/lighty_error_log"
  #accesslog.filename = "#{path_application}/logs/access_log"
  fastcgi.server = ( "/seaside" => (
TEXT

    # Add a line for each gem
    gem_configs = []
    for port in gem_ports
      gem_configs << "( \"host\" => \"127.0.0.1\", \"port\" => #{port}, \"check-local\" => \"disable\")"
    end
    lighty_config << gem_configs.join(",\n") << "\n"

    # End of configuration
    lighty_config << <<-TEXT
    )
  )
}
TEXT

    put lighty_config, "#{path_lighty_application_configs}/#{application}.conf"
  end
end
