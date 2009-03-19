#
# SeaShell
#
# Capistrano deployment recipes for seaside platforms
#
# Author: Andreas Brodbeck, mindclue gmbh, www.mindclue.ch
# Licence: MIT (see LICENSE file)
#

#
# Some general helper methods
#

# Show the +message+ in the capistrano trace output
def trace(message)
  logger.trace(message) if logger
end

# Show the +message+ on the shell output, highlighted with a color to be important.
def say(message)
  Capistrano::CLI.ui.say("<%= color('#{message}', :green) %>")
end