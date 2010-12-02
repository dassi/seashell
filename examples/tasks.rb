#
# This is an example file which shows the basic syntax of defining capistrano tasks
#
# Remark: Put this file on your top directory and name it "tasks.rb", it will be automatically included
#
      

# Top namespace for the tasks
namespace :my_tasks do

  desc 'Just an example...'
  task :calculate do
    say('Calculating 3 + 5 by Smalltalk results in: ' + run_gs('output := 3 + 5', :commit => false))
  end
  
  # Nested namespace
  namespace :cool_tasks do

    desc 'Do this'
    task :do_this do

      # Call normal methods
      do_this_with_parameter(3)
      
      # Call another task from the same namespace like a normal method
      do_that
      
      # Call any task generically by task name (including namespaces)
      find_and_execute_task('info:env')
      
    end
    
    # No desc leads to a "hidden" task, which is fully functional but does not show up in the list
    task :do_that do
      
    end
    

    # Defining normale ruby methods with parameter
    def do_this_with_parameter(a_number)
      # Do something with that number
    end
    
  end
  
  task :flush_caches do
    # Flush magritte caches
    run_gs('MADescriptionBuilder default flush.')
  end
  
  
end


# Install hooks on other existing tasks. Here we want a cache flush, after each deployment.
after 'deploy' do
  find_and_execute_task('sirop:flush_caches')
end
