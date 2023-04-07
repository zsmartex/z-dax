namespace :utils do
  task :terraform, [:command] do |task, args|
    Rake::Task["render:config"].execute
    puts '----- Running terraform -----'
    sh 'docker-compose run --rm terraform init'
    sh 'docker-compose run --rm terraform apply -auto-approve'
  end
end
