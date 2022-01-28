namespace :kafka do
  task :init, [:command] do |task, args|
    Rake::Task["render:config"].execute
    puts '----- Running kafka connector init connectors -----'
    sh 'docker-compose run --rm bash -c "./kafka-connect-init"'
  end
end
