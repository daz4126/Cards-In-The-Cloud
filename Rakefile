desc "Send an email with daily stats"
task :cron do
  if Time.now.hour % 4 == 0 # run every four hours
    puts "Preparing email..."
    Card.send_daily_stats
    puts "sent." 
end
