# Include stages functionality from capistrano
set :stages, %w(productive development)
set :default_stage, 'development'
set :stage_dir, 'stages'
require 'capistrano/ext/multistage'
       
# Implicitly load the common config file after loading stage configs
for stage_name in stages
  after stage_name do
    load 'lib/config.rb'
  end
end    

