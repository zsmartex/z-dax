namespace :db do
  task :create, [:command] do |task, args|
    Rake::Task["render:config"].execute
    puts '----- Running create database -----'
    sh 'docker-compose run --rm barong sh -c "./barong createdb"'
    sh 'docker-compose run --rm peatio sh -c "./peatio createdb"'
    sh 'docker-compose run --rm kouda sh -c "./kouda createdb"'
    sh 'docker-compose run --rm quantex sh -c "./quantex createdb"'
  end

  task :migrate, [:command] do |task, args|
    Rake::Task["render:config"].execute
    puts '----- Running migrate database -----'
    sh 'docker-compose run --rm barong sh -c "./barong migration"'
    sh 'docker-compose run --rm peatio sh -c "./peatio migration"'
    sh 'docker-compose run --rm kouda sh -c "./kouda migration"'
    sh 'docker-compose run --rm quantex sh -c "./quantex migration"'
  end

  task :seed, [:command] do |task, args|
    Rake::Task["render:config"].execute
    puts '----- Running seed database -----'
    sh 'docker-compose run --rm barong sh -c "./barong seed"'
    sh 'docker-compose run --rm peatio sh -c "./peatio seed"'
  end

  task :setup, [:command] do |task, args|
    Rake::Task["vault:setup"].execute
    Rake::Task["render:config"].execute

    Rake::Task["db:create"].execute
    Rake::Task["db:migrate"].execute
    Rake::Task["db:seed"].execute
  end
end
