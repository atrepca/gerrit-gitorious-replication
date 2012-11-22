#!/usr/bin/ruby

# Creates repositories in an existing $in_project Gitorious project.
#
# CONFIGURATION: set the variables below, points 1 and 2.

# -------------------------------------------------------------------------
# misc; variables, change these as needed

# 1. the project repositories will be created into
$in_project = 'example_project'

# 2. path to Gitorious environment.rb
gitorious_env = '/opt/gitorious/config/environment.rb'

# setting the Rails environment to production
ENV['RAILS_ENV'] ||= 'production'

# -------------------------------------------------------------------------
# parse arguments

if ARGV.length == 0
  puts "\nUSAGE: #{$0} [repository_name(s)]\n\n"
  exit
end

# -------------------------------------------------------------------------
# load the environment
require gitorious_env 

# -------------------------------------------------------------------------
# method to create repositories using values from $in_project
def create_repo(name)
  project = Project.find_by_slug($in_project)
  repo = Repository.new({
    :project => project,
    :user => project.user,
    :owner => project.owner,
    :merge_requests_enabled => "0"
    }.merge(name)) 
  repo.save
end

# -------------------------------------------------------------------------
# create the repo(s)
ARGV.each do |name|
  create_repo(:name => "#{name.downcase}")
  puts "INFO: Successfully created repository #{name.downcase}."
end
