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

    # # "exit 0" is a cheap trick to ignore errors.
    # # TODO: Better handling of "no permission" when doing chgrp
    # sudo "chgrp -fR www-data #{path_web_root}; exit 0" 
    # 
    # # Alternatively using this, for the moment:
    # run "chmod -R o+r,o+x #{path_web_root}" 
    # 
    # # By default the /opt/gemstone folder is not viewable by all. We need to change that, else the webserver can not serve files
    # # OPTIMIZE: This only makes sense, if path_web_root is a subfolder of path_base, which is the case for the default values of SeaShell.
    # run "chmod o+r,o+x #{path_base}" 

    # Better: Run your webserver with appropriate permissions and user/group, so that GemStone AND Server will cooperate on the file system level.
    
  end

  desc 'Deploy a version from metacello'
  task :default do
    
    # TODO: Check, if stone is running. Or even start it implicitly?

    # Ask for Metacello version (show only latest 20)
    # update_configuration_of_metacello_project(metacello_project_name, metacello_repository_url, metacello_repository_user, metacello_repository_password)
    available_versions = get_metacello_versions(metacello_project_name)
    metacello_version = Capistrano::CLI.ui.choose(*available_versions[0..20])

    find_and_execute_task('gemstone:gems:stop')
    find_and_execute_task('gemstone:stone:backup') if is_production
    install_metacello_version(metacello_project_name, metacello_version, nil, :force => true)
    find_and_execute_task('seaside:flush_caches')
    register
    find_and_execute_task('seaside:register_default_entry_point')
    write_file_libraries_to_disk
    set_deployment_mode if is_production
    find_and_execute_task('gemstone:gems:start')
    say("Your application #{metacello_project_name} version #{metacello_version} has been deployed.")
  end

  task :initial do
    
    # Ask for Metacello version
    available_versions = get_metacello_versions(metacello_project_name)
    metacello_version = Capistrano::CLI.ui.choose(*available_versions[0..20])

    install_metacello_version(metacello_project_name, metacello_version, nil, :force => true)
    register
    find_and_execute_task('seaside:register_default_entry_point')
    write_file_libraries_to_disk
    set_deployment_mode if is_production
    find_and_execute_task('gemstone:gems:start')
    say("Your application #{metacello_project_name} version #{metacello_version} has been deployed for the first time.")
  end
  
  desc 'Deploys the static files to disk. Taken from your applications FileLibrary classes'
  task :write_file_libraries_to_disk do
    script = ''
    for component, entry_point_name in entry_points
      script << "(WADispatcher default entryPointAt: '#{entry_point_name}') libraries do: [:each | each deployFiles].\n"
    end

    run_gs(script, :commit => false, :working_dir => "#{path_web_root}/files")

    # Change file permission, so that web server can read them
    ensure_webserver_can_read_static_files

  end

  desc 'Switches the application to deployment Mode'
  task :set_deployment_mode do
                 
    script = ''
    for component, entry_point_name in entry_points
      script << "(WADispatcher default entryPointAt: '#{entry_point_name}') preferenceAt: #deploymentMode put: true.\n"
    end
    
    # TODO: deploymentMode funktioniert nicht so
    # run_gs(script)
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
      create_gemstone_application_config
      create_switch_script
      create_topazini_file
      transfer_helper_files
      say("Your fresh GemStone/Seaside application directory has been setup at #{path_application}. Now go on and surf the seaside!")
    end

    # Create used folders
    task :create_folders do
      run "mkdir -p #{path_application} #{path_data} #{path_backups} #{path_logs}"

      run "mkdir -p #{path_web_root}"
      run "mkdir -p #{path_web_root}/files"

      ensure_webserver_can_read_static_files

    end

    # Copies the Gemstone intial repository into the project folder
    # OPTIMIZE: Make sure that this never destroys data. And shows a warning, if there is already data.
    task :copy_initial_repository do
      run "cp -n -v #{path_gemstone}/bin/extent0.seaside.dbf #{path_data}/extent0.dbf"
      run "chmod u+w #{path_data}/extent0.dbf"
    end
    
    task :create_gemstone_application_config do
      run "cp -n -v #{path_seaside}/data/gem.conf #{path_application}/#{stone}.conf"
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
login
TOPAZ

      put topazini, "#{path_application}/.topazini"
    end
    
    # Copies some files, helper scripts etc., which are held in the "static" folder locally
    task :transfer_helper_files do
      (Dir.glob('static/*') + Dir.glob('static/.[a-z]*')).each do |filename|
        filepath_target = "#{path_application}/#{File.basename(filename)}"
        put File.read(filename), filepath_target
        run "chmod +x #{filepath_target}" # if File.extname(filename) == '.sh'
      end
    end

    # desc 'Checks all kind of stuff on the server, to ensure things will work.'
    task :check do
      # TODO, check that:
      # - SHR_PAGE_CACHE_SIZE_KB should be half of the RAM, but never bigger! see in /opt/gemstone/product/seaside/data/system.conf
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


