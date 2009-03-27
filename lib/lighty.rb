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

  desc 'Reload lighttpd configuration'
  task :reload do
    sudo '/etc/init.d/lighttpd reload'
  end

  desc 'Creates the lighty configuration files on the server'
  task :setup do

    # How do I hide seasides paths from the frontend url with lighty?
    # url.rewrite-once = ( "^(.*)" => "/seaside/#{application}$1" )
    # url.rewrite-once = ( "^([^\\?]*)(\\?(.*))?" => "/seaside/#{application}/$2" )
    
    # Beginning of configuration
    lighty_config = ''
    for domain in domains
      lighty_config << <<-TEXT
$HTTP["host"] == "#{domain}" {
  $HTTP["url"] =~ "^/seaside/files/" { 
    server.document-root = "#{path_web_root}/"
  } else $HTTP["url"] =~ "^/seaside" { 
    server.document-root = "#{path_web_root}/"
    #server.errorlog = "#{path_application}/logs/lighty_error_log"
    #accesslog.filename = "#{path_application}/logs/access_log"
    fastcgi.server = ( "/seaside" => (
TEXT


      # Add a line for each gem
      gem_configs = []
      for port in gem_ports
        gem_configs << "( \"host\" => \"127.0.0.1\", \"port\" => #{port}, \"check-local\" => \"disable\", \"mode\" => \"responder\")"
      end
      lighty_config << gem_configs.join(",\n") << "\n"

      # End of configuration
      lighty_config << <<-TEXT
      )
    )
  }
}
TEXT
    end
    
    put lighty_config, "#{path_lighty_application_configs}/#{application}.conf"
    say "Don't forget to restart lighttpd"
  end
end
