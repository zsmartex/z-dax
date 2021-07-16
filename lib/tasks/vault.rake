require_relative '../z-dax/vault'

namespace :vault do
  desc 'Initialize, unseal and set secrets for Vault'
  task :setup do
    if Dir.exist?('./Project/z-dax-test')
      puts '----- Vault not allow to setup again! -----'
      return
    end

    sh 'mkdir data/vault'
    sh 'sudo chmod -R 757 data/vault'

    vault = ZDax::Vault.new
    vault_root_token = vault.setup
    unless vault_root_token.nil?
      @config["vault"]["root_token"] = vault_root_token
      File.open(CONFIG_PATH, 'w') { |f| YAML.dump(@config, f) }

      Rake::Task["vault:load_policies"].invoke
    end
  end

  task :unseal do
    vault = ZDax::Vault.new
    vault.unseal
  end

  task :load_policies do
    vault = ZDax::Vault.new
    vault_tokens = vault.load_policies(@config["app"]["name"], @config["vault"]["root_token"])
    unless vault_tokens.empty?
      vault_tokens.each do |k, v|
        @config["vault"][k] = v
        File.open(CONFIG_PATH, 'w') { |f| YAML.dump(@config, f) }
      end
    end
  end
end
