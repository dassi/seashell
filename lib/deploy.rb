#
# SeaShell
#
# Capistrano deployment recipes for seaside platforms
#
# Author: Andreas Brodbeck, mindclue gmbh, www.mindclue.ch
# Licence: MIT (see LICENSE file)
#

#
# Tasks for deployment
#

namespace :deploy do


  def ensure_webserver_can_read_static_files
    sudo "chgrp -R www-data #{path_web_root}"
  end

  desc 'Deploy a version from monticello'
  task :default do
    # Ask for Monticello version (show only latest 50)
    available_versions = get_monticello_versions(monticello_repository_url, monticello_repository_user, monticello_repository_password)
    monticello_file = Capistrano::CLI.ui.choose(*available_versions[0..50])
    install_monticello_version(monticello_file, monticello_repository_url, monticello_repository_user, monticello_repository_password)
  end
  
  desc 'Deploy the latest version from monticello repository'
  task :latest do
    available_versions = get_monticello_versions(monticello_repository_url, monticello_repository_user, monticello_repository_password)
    monticello_file = available_versions.first
    install_monticello_version(monticello_file, monticello_repository_url, monticello_repository_user, monticello_repository_password)
  end


  desc 'Deploys the static files to disk. Taken from your applications FileLibrary classes'
  task :write_file_libraries_to_disk do
    script = ''
    for component, entry_point_name in entry_points
      script << "(WADispatcher default entryPointAt: '#{entry_point_name}') writeLibrariesToDisk.\n"
    end
    
    run_gs(script, :commit => false, :working_dir => "#{path_web_root}/seaside/files")

    # Change file permission, so that web server can read them
    ensure_webserver_can_read_static_files

  end

  desc 'Switches the application to deployment Mode'
  task :set_deployment_mode do
                 
    script = ''
    for component, entry_point_name in entry_points
      script << "(WADispatcher default entryPointAt: '#{entry_point_name}') preferenceAt: #deploymentMode put: true.\n"
    end
    
    run_gs(script)
  end
   
  desc 'Register your seaside entry points'
  task :register do
    script = ''
    for component, entry_point_name in entry_points
      script << "#{component} registerAsApplication: '#{entry_point_name}'.\n"
    end

    run_gs(script)
  end


  #
  # Tasks related to setting up the environment
  #
  namespace :setup do

    desc 'Sets up the folder structure for the project'
    task :default do
      create_folders
      copy_initial_repository
      create_switch_script
      create_topazini_file
    end

    # Create used folders
    task :create_folders do
      run "mkdir -p #{path_application} #{path_data} #{path_data}/backups #{path_application}/logs"
      run "mkdir -p /etc/lighttpd/seaside_applications"

      run "mkdir -p #{path_web_root}"
      run "mkdir -p #{path_web_root}/seaside/files"

      ensure_webserver_can_read_static_files

    end

    task :copy_initial_repository do
      run "cp /opt/gemstone/product/bin/extent0.seaside.dbf #{path_data}/extent0.dbf"
      run "chmod u+w #{path_data}/extent0.dbf"
    end

    # Creates convenience shell script for switching projects when working on the server
    task :create_switch_script do
      switch_shell_script = ''
      for key, value in default_environment
        switch_shell_script << "export #{key}=\"#{value}\"\n"
      end

      put switch_shell_script, "#{path_application}/switch_environment"
    end
    
    task :create_topazini_file do
      topazini = <<-TOPAZ
set gemstone #{stone}
set username #{gemstone_user}
set password #{gemstone_password}
TOPAZ

      put topazini, "#{path_application}/.topazini"
    end

    desc 'Checks all kind of stuff on the server, to ensure things will work.'
    task :check do
      # TODO, check that:
      # - SHR_PAGE_CACHE_SIZE_KB should be half of the RAM, but never bigger! see in /opt/gemstone/product/seaside/data/system.conf
      # - Line GEMS="9001 9002 9003" still in runSeasideGems?
      # - Check that lighty is configured to include the vhost-configs (include_shell "cat seaside_applications/*.conf")
    end

  end

  desc 'Copy files to the server.'
  task :upload do
    files = (ENV["FILES"] || "").split(",").map { |f| Dir[f.strip] }.flatten
    abort "Please specify at least one file or directory to update (via the FILES environment variable)" if files.empty?

    files.each { |file| top.upload(file, File.join(path_application, file)) }
  end

end


