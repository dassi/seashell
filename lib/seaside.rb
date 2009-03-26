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
    run_gs('MADescriptionBuilder default flush. MANamedBuilder default flush.')
  end
   
  desc 'Removes development tools of seaside.'
  task :make_secure do
    # TODO
  end
  
end