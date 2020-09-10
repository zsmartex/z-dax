namespace :image do
  desc 'build app image'
  task :build, [:image] do |task, args|
    name = args[:image]
    image_tag = @images[name]

    puts '----- Creating image -----'
    sh %Q{docker image build vendor/#{name} --tag #{image_tag}}
    puts %Q{----- Created #{name} image successful -----}
  end

  desc 'pushing image'
  task :push, [:image] do |task, args|
    name = args[:image]
    image_tag = @images[name]

    Rake::Task["image:build"].invoke(name)

    puts '----- Pushing image -----'
    sh %Q{docker push #{image_tag}}
    puts %Q{----- Created #{name} image successful -----}
  end

end
