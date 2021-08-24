namespace :db do
  task :create, [:command] do |task, args|
    Rake::Task["render:config"].execute
    puts '----- Running create database -----'
    sh 'docker-compose run --rm barong bash -c "./bin/link_config && bundle exec rake db:create"'
    sh 'docker-compose run --rm peatio bash -c "./bin/link_config && bundle exec rake db:create"'
    sh 'docker-compose run --rm applogic sh -c "lucky db.create"'
  end

  task :migrate, [:command] do |task, args|
    Rake::Task["render:config"].execute
    puts '----- Running migrate database -----'
    sh 'docker-compose run --rm barong bash -c "./bin/link_config && bundle exec rake db:migrate"'
    sh 'docker-compose run --rm peatio bash -c "./bin/link_config && bundle exec rake db:migrate"'
    sh 'docker-compose run --rm applogic sh -c "lucky db.migrate"'
    sh 'docker-compose run --rm quantex-api sh -c "./quantex-migrator"'
  end

  task :seed, [:command] do |task, args|
    Rake::Task["render:config"].execute
    puts '----- Running seed database -----'
    sh 'docker-compose run --rm barong bash -c "./bin/link_config && bundle exec rake db:seed"'
    sh 'docker-compose run --rm peatio bash -c "./bin/link_config && bundle exec rake db:seed"'
  end

  task :setup, [:command] do |task, args|
    Rake::Task["vault:setup"].execute
    Rake::Task["render:config"].execute

    Rake::Task["db:create"].execute
    Rake::Task["db:migrate"].execute
    Rake::Task["db:seed"].execute
    Rake::Task["db:influx"].execute
  end

  task :influx, [:command] do |task, args|
    sh 'docker-compose up -d influxdb'
    sh 'docker-compose exec influxdb bash -c "cat influxdb.sql | influx"'
  end
end
