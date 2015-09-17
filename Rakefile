require 'rake'
require 'active_record'

include ActiveRecord::Tasks

db_dir = File.expand_path('../db', __FILE__)
DatabaseTasks.db_dir = db_dir
DatabaseTasks.migrations_paths = File.join(db_dir, 'migrate')

task :environment do
  ActiveRecord::Base.establish_connection
end

load 'active_record/railties/databases.rake'
load 'lib/tasks/sidekiq/create_jobs.rake'
