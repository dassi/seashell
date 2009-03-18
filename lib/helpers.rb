def trace(message)
  logger.trace(message) if logger
end

def say(message)
  Capistrano::CLI.ui.say("<%= color('#{message}', :green) %>")
end