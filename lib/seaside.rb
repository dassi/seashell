#
# SeaShell
#
# Capistrano deployment recipes for seaside platforms
#
# Author: Andreas Brodbeck, mindclue gmbh, www.mindclue.ch
# Licence: MIT (see LICENSE file)
#                                          

#
# Tasks related to the seaside framework
#

namespace :seaside do

  desc 'Flush caches (Magritte, ...)'
  task :flush_caches do
    # OPTIMIZE: don't depend on Magritte being installed here!
    # run_gs('MADescriptionBuilder default flush.')
  end

  desc 'Deletes all sessions'
  task :flush_sessions do
    # TODO
    # WARegistry clearAllHandlers.
    # Smalltalk garbageCollect.    
  end     
  
  desc 'Meta-Task, does steps for a deploye seaside application.'
  task :make_secure do
    remove_unused_applications
    set_config_credentials
    # set_deployment_mode
  end

  desc 'Removes unused applications from seaside (examples, etc.)'
  task :remove_unused_applications do
    # TODO
    #
    # Make shure, that isDeployed answers true for the projects main components (see entry_points)
    # WADispatcher default trimForDeployment.
  end
  
  desc 'Changes password for the config application'
  task :set_config_credentials do
    # TODO
    # (WADispatcher default entryPoints at: 'config')
    #   preferenceAt: #login put: 'new id'.
    # (WADispatcher default entryPoints at: 'config')
    #   preferenceAt: #password put: 'new password'.    
  end
  
  desc 'Register a default seaside application'
  task :register_default_entry_point do
    run_gs("WADispatcher default defaultName: '#{default_entry_point}'.")
  end
  
  
  namespace :info do

    desc ''
    task :show_config_credentials do
      # TODO
      # (WADispatcher default entryPoints at: 'config') preferenceAt: #login.
      # (WADispatcher default entryPoints at: 'config') preferenceAt: #password.
    end
    
    
  end
  
end