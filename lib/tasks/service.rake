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
      sh 'docker-compose up -d db redis rabbitmq nats influxdb vault'
      puts 'Wait 5 second for backend'
      sleep 5 # time for db to start, we can get connection refused without sleeping
    end

    def stop
      puts '----- Stopping dependencies -----'
      sh 'docker-compose rm -fs db redis rabbitmq nats influxdb vault'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run adminer (database management)'
  task :adminer, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting dependencies -----'
      sh 'docker-compose up -d adminer'
    end

    def stop
      puts '----- Stopping dependencies -----'
      sh 'docker-compose rm -fs adminer'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run mikro app (barong, peatio)'
  task :app, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting app -----'
      sh 'docker-compose up -d peatio barong finex-api quantex-api rango applogic envoy coverapp castle assets-currency'
    end

    def stop
      puts '----- Stopping app -----'
      sh 'docker-compose rm -fs peatio barong finex-api quantex-api rango applogic envoy coverapp castle assets-currency'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run peatio daemons (ranger, peatio daemons)'
  task :daemons, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    @daemons = @config['daemons'].select { |key, v| v }

    def start
      puts '----- Starting Daemons -----'
      sh "docker-compose up -d #{@daemons.keys.join(' ')}"
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
      sh 'docker-compose up -d quantex-engine'
    end

    def stop
      puts '----- Stopping Bot -----'
      sh 'docker-compose rm -fs quantex-engine'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run Cryptonodes'
  task :cryptonodes, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting Cryptonodes -----'
      sh 'docker-compose up -d parity bitcoind'
    end

    def stop
      puts '----- Stopping Cryptonodes -----'
      sh 'docker-compose rm -fs parity bitcoind'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run the micro app with dependencies (does not run Optional)'
  task :all, [:command] => 'render:config' do |task, args|
    args.with_defaults(:command => 'start')

    def start
      Rake::Task["service:proxy"].invoke('start')
      Rake::Task["service:backend"].invoke('start')
      Rake::Task["vault:unseal"].invoke('start')
      Rake::Task["service:app"].invoke('start')
      Rake::Task["service:daemons"].invoke('start')
    end

    def stop
      Rake::Task["service:proxy"].invoke('stop')
      Rake::Task["service:backend"].invoke('stop')
      Rake::Task["service:app"].invoke('stop')
      Rake::Task["service:daemons"].invoke('stop')
    end

    @switch.call(args, method(:start), method(:stop))
  end
end
