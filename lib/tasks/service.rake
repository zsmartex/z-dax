namespace :service do
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
      sh 'docker-compose up -d traefik visualizer'
      sleep 10 # time for visualizer to start, we can get connection refused without sleeping
    end

    def stop
      puts '----- Stopping the proxy -----'
      sh 'docker-compose rm -fs traefik visualizer'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run backend (db redis rabbitmq)'
  task :backend, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting dependencies -----'
      sh 'docker-compose up -d db adminer redis influxdb vault'
      sleep 5 # time for db to start, we can get connection refused without sleeping
    end

    def stop
      puts '----- Stopping dependencies -----'
      sh 'docker-compose rm -fs db adminer redis influxdb vault'
    end


    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run stream (nats)'
  task :stream, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting dependencies -----'
      sh 'docker-compose up -d rabbitmq nats nats-replica'
      sh 'docker-compose scale nats-replica=5'
    end

    def stop
      puts '----- Stopping dependencies -----'
      sh 'docker-compose rm -fs rabbitmq nats nats-replica'
    end


    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run mikro app (barong, peatio)'
  task :app, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting app -----'
      sh 'docker-compose up -d --build peatio barong finex-api rango applogic envoy coverapp castle assets-currency'
    end

    def stop
      puts '----- Stopping app -----'
      sh 'docker-compose rm -fs peatio barong finex-api rango applogic envoy coverapp castle assets-currency'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run peatio daemons (ranger, peatio daemons)'
  task :daemons, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    @daemons = @config['daemons'].select { |key, v| v }

    def start
      puts '----- Starting Daemons -----'
      sh "docker-compose up -d --build #{@daemons.keys.join(' ')}"
    end

    def stop
      puts '----- Stopping Daemons -----'
      sh "docker-compose rm -fs #{@daemons.keys.join(' ')}"
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run Z-Maker'
  task :bot, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting Bot -----'
      sh 'docker-compose up -d --build contrive'
    end

    def stop
      puts '----- Stopping Bot -----'
      sh 'docker-compose rm -fs contrive'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run monitoring'
  task :monitoring, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting monitoring -----'
      sh 'docker-compose up -d prometheus node-exporter cadvisor grafana alertmanager'
    end

    def stop
      puts '----- Stopping monitoring -----'
      sh 'docker-compose rm -fs prometheus node-exporter cadvisor grafana alertmanager'
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
      Rake::Task["vault:unseal"].invoke('stop')
      Rake::Task["service:stream"].invoke('start')
      Rake::Task["service:app"].invoke('start')
      Rake::Task["service:daemons"].invoke('start')
      Rake::Task["service:monitoring"].invoke('start')
    end

    def stop
      Rake::Task["service:proxy"].invoke('stop')
      Rake::Task["service:backend"].invoke('stop')
      Rake::Task["service:stream"].invoke('stop')
      Rake::Task["service:app"].invoke('stop')
      Rake::Task["service:daemons"].invoke('stop')
      Rake::Task["service:monitoring"].invoke('stop')
    end

    @switch.call(args, method(:start), method(:stop))
  end
end
