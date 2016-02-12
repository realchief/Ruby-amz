require 'rake'
require 'active_record'

module Rails
  def self.root
    File.dirname(__FILE__)
  end
end

include ActiveRecord::Tasks

db_dir = File.expand_path('../db', __FILE__)

DatabaseTasks.env              = ENV['ENV'] || 'default_env'
DatabaseTasks.db_dir           = db_dir
DatabaseTasks.migrations_paths = File.join(db_dir, 'migrate')

task :environment do
  ActiveRecord::Base.raise_in_transactional_callbacks = true
  ActiveRecord::Base.establish_connection
end

load 'active_record/railties/databases.rake'
load 'lib/tasks/aggregate_btg_files.rake'
load 'lib/tasks/sidekiq/create_jobs.rake'
