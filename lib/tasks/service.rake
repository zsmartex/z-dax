require_relative '../docker_api'

namespace :service do
  def is_service_running?(service)
    DockerAPI.new.send_request("/services/#{service}")
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

  desc 'Run Traefik (reverse-proxy)'
  task :proxy, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
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

  desc 'Run secrets vault'
  task :secrets, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      Rake::Task["service:backend"].invoke('start') unless is_service_running?('backend_db')
      puts '----- Starting dependencies -----'
      sh 'docker stack deploy -c compose/secrets.yml secrets'
    end

    def stop
      puts '----- Stopping dependencies -----'
      sh 'docker stack rm secrets'
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
      Rake::Task["service:secrets"].invoke('start') unless is_service_running?('secrets_vault')
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

  desc '[Optional] Run Z-Maker'
  task :bot, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting Bot -----'
      sh 'docker stack deploy -c compose/bot.yml bot --with-registry-auth'
    end

    def stop
      puts '----- Stopping Bot -----'
      sh 'docker stack rm bot'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run admin (z-control and home page)'
  task :admin, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      Rake::Task["service:proxy"].invoke('start') unless is_service_running?('proxy_traefik')
      puts '----- Starting utils -----'
      sh 'docker stack deploy -c compose/admin.yml admin --with-registry-auth'
    end

    def stop
      puts '----- Stopping Utils -----'
      sh 'docker stack rm admin'
    end

    @switch.call(args, method(:start), method(:stop))
  end
end
