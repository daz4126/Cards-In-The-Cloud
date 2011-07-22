require 'main'

desc "Send an email with daily stats"
task :cron do
    puts "Preparing email..."
    Card.send_daily_stats
    puts "sent."
end
