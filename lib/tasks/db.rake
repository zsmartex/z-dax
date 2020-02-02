require 'net/http'

namespace :db do
  ENV['MANAGER_IP'] = @config['app']['manager_ip']

  def mysql_cli
    return "mysql -u root -h db -P 3306 -pdjtdjtdjtdjt"
  end

  def is_volume_exists?(name)
    volume_prefix = "app"
    volume_suffix = "seed"
    volume_name = [volume_prefix, name, volume_suffix].join("_")

    uri = URI("http://#{ENV['MANAGER_IP']}:2375/volumes/#{volume_name}")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    return response.code.to_i == 200
  end

  def is_mysql_running?
    uri = URI("http://#{ENV['MANAGER_IP']}:2375/services/backend_db")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    return response.code.to_i == 200
  end

  def start_mysql_service
    Rake::Task["service:backend"].invoke('start')
  end

  def send_command(name, command)
    image = @config['image'][name]

    sh "bin/swarm-exec.sh --name #{name} -- #{image} #{command}"
  end

  desc 'Create database'
  task :create do
    start_mysql_service unless is_mysql_running?

    send_command('peatio', 'bundle exec rake db:create')
    sleep 5
    send_command('barong', 'bundle exec rake db:create')
    sleep 5
  end

  desc 'setup database'
  task :setup do
    start_mysql_service unless is_mysql_running?

    send_command('peatio', 'bundle exec rake db:create db:migrate db:seed')
    sleep 5
    send_command('barong', 'bundle exec rake db:create db:migrate db:seed')
    sleep 5
  end

  task :update do
    start_mysql_service unless is_mysql_running?

    send_command('peatio', 'bundle exec rake db:migrate')
    sleep 5
    send_command('barong', 'bundle exec rake db:migrate')
    sleep 5
  end
end
