require 'rufus-scheduler'
require 'rake'

return unless defined?(Rails::Server)

scheduler = Rufus::Scheduler.singleton

scheduler.every '10m' do
  Rails.logger.info "Rufus triggered at #{Time.now}"
  begin
    Rake::Task.clear
    Rails.application.load_tasks
    Rake::Task['redis_to_db:sync_searches'].invoke
  rescue => e
    Rails.logger.error "Error running sync task: #{e.message}"
  end
end
