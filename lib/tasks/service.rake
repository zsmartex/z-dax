require 'net/http'
require 'openssl'
require 'uri'

namespace :service do
  ENV['APP_DOMAIN'] = @config['app']['domain']
  ENV['MANAGER_IP'] = @config['app']['manager_ip']
  DEFAULT_OPTIONS = {
    use_ssl: true,
    verify_mode: OpenSSL::SSL::VERIFY_PEER,
    keep_alive_timeout: 30,
    cert: OpenSSL::X509::Certificate.new(File.read("./config/docker_certs/cert.pem")),
    key: OpenSSL::PKey::RSA.new(File.read("./config/docker_certs/key.pem")),
    ca_file: File.join("./config/docker_certs/", "ca.pem")
  }

  def is_service_running?(service)
    http = Net::HTTP.start("docker.local", 2376, DEFAULT_OPTIONS)
    response = http.request Net::HTTP::Get.new "/services/#{service}"

    return response.code.to_i == 200
  end

  @switch = Proc.new do |args, start, stop|
    case args.command
    when 'start'
      start.call
    when 'stop'
      stop.call
    when 'restart'
      stop.call
      start.call
    else
      puts "unknown command #{args.command}"
    end
  end

  desc 'Run autoscaler'
  task :networks, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting the networks -----'
      sh 'docker stack deploy -c compose/networks.yml networks'
    end

    def stop
      puts '----- Stopping the networks -----'
      sh 'docker stack rm networks'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run Traefik (reverse-proxy)'
  task :proxy, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      Rake::Task["service:networks"].invoke('start') unless is_service_running?('networks_autoscaler')
      puts '----- Starting the proxy -----'
      sh 'docker stack deploy -c compose/proxy.yml proxy'
      sleep 10 # time for visualizer to start, we can get connection refused without sleeping
    end

    def stop
      puts '----- Stopping the proxy -----'
      sh 'docker stack rm proxy'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run backend (db redis rabbitmq)'
  task :backend, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      Rake::Task["service:proxy"].invoke('start') unless is_service_running?('proxy_traefik')
      puts '----- Starting dependencies -----'
      sh 'docker stack deploy -c compose/backend.yml backend'
      sleep 5 # time for db to start, we can get connection refused without sleeping
    end

    def stop
      puts '----- Stopping dependencies -----'
      sh 'docker stack rm backend'
    end


    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run mikro gateway'
  task :gateway, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      Rake::Task["service:proxy"].invoke('start') unless is_service_running?('proxy_traefik')
      puts '----- Starting dependencies -----'
      sh 'docker stack deploy -c compose/gateway.yml gateway'
    end

    def stop
      puts '----- Stopping dependencies -----'
      sh 'docker stack rm gateway'
    end


    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run mikro app (barong, peatio)'
  task :app, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      Rake::Task["service:gateway"].invoke('start') unless is_service_running?('gateway_envoy')
      Rake::Task["service:backend"].invoke('start') unless is_service_running?('backend_db')
      puts '----- Starting app -----'
      sh 'docker stack deploy -c compose/app.yml app --with-registry-auth'
    end

    def stop
      puts '----- Stopping app -----'
      sh 'docker stack rm app'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run peatio daemons (ranger, peatio daemons)'
  task :daemons, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      Rake::Task["service:app"].invoke('start') unless is_service_running?('app_peatio')
      puts '----- Starting Daemons -----'
      sh 'docker stack deploy -c compose/daemons.yml daemons --with-registry-auth'
    end

    def stop
      puts '----- Stopping Daemons -----'
      sh 'docker stack rm daemons'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run peatio daemons (ranger, peatio daemons)'
  task :testing, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts is_service_running?('app_peatio')
    end

    def stop
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run the micro app with dependencies (does not run Optional)'
  task :all, [:command] => 'render:config' do |task, args|
    args.with_defaults(:command => 'start')

    def start
      Rake::Task["service:proxy"].invoke('start')
      Rake::Task["service:backend"].invoke('start')
      puts 'Wait 5 second for backend'
      sleep(5)
      Rake::Task["service:app"].invoke('start')
      Rake::Task["service:frontend"].invoke('start')
      Rake::Task["service:utils"].invoke('start')
    end

    def stop
      Rake::Task["service:proxy"].invoke('stop')
      Rake::Task["service:backend"].invoke('stop')
      Rake::Task["service:app"].invoke('stop')
      Rake::Task["service:frontend"].invoke('stop')
      Rake::Task["service:utils"].invoke('start')
    end

    @switch.call(args, method(:start), method(:stop))
  end
end
