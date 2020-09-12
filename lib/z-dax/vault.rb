# frozen_string_literal: true

module ZDax
  class Vault
    def vault_secrets_path
      'config/vault-secrets.yml'
    end

    def vault_exec(command)
      `docker-compose exec -T vault sh -c '#{command}'`
    end

    def secrets(command, endpoints, options = '')
      endpoints.each { |endpoint| vault_exec("vault secrets #{command} #{options} #{endpoint}") }
    end

    def vault_status
      vault_status = YAML.safe_load(vault_exec('vault status -format yaml'))
    end

    def setup
      puts '----- Checking Vault status -----'
      return if vault_status.nil?

      initialize_vault
      unseal
      apply_acl

      vault_secrets = YAML.safe_load(File.read(vault_secrets_path))
      vault_root_token = vault_secrets['root_token']

      puts '----- Vault login -----'
      vault_exec("vault login #{vault_root_token}")

      puts '----- Configuring the endpoints -----'
      secrets('enable', %w[totp transit])
      secrets('disable', ['secret'])
      secrets('enable', ['kv'], '-path=secret -version=1')
      vault_root_token
    end

    def initialize_vault
      if vault_status['initialized']
        puts '----- Vault is initialized -----'
        begin
          vault_secrets = YAML.safe_load(File.read(vault_secrets_path))
        rescue SystemCallError => e
          puts 'Vault keys are missing'
          return
        end
        vault_root_token = vault_secrets['root_token']
        unseal_keys = vault_secrets['unseal_keys_b64'][0, 3]
      else
        puts '----- Initializing Vault -----'
        vault_init_output = YAML.safe_load(vault_exec('vault operator init -format yaml --recovery-shares=3 --recovery-threshold=2'))
        File.write(vault_secrets_path, YAML.dump(vault_init_output))
        vault_root_token = vault_init_output['root_token']
        unseal_keys = vault_init_output['unseal_keys_b64'][0, 3]
      end
    end

    def unseal
      puts '----- Checking Vault status -----'
      return if vault_status.nil?

      if vault_status['sealed']
        puts '----- Unsealing Vault -----'
        vault_secrets = YAML.safe_load(File.read(vault_secrets_path))
        unseal_keys = vault_secrets['unseal_keys_b64'][0, 3]
        unseal_keys.each { |key| vault_exec("vault operator unseal #{key}") }
      else
        puts '----- Vault is unsealed -----'
      end
    end

    def apply_acl
      vault_secrets = YAML.safe_load(File.read(vault_secrets_path))
      vault_root_token = vault_secrets['root_token']

      ['barong-authz', 'barong-rails', 'peatio-crypto-daemons', 'peatio-rails', 'peatio-upstream-proxy'].each do |policy|
        vault_exec("VAULT_TOKEN=#{vault_root_token} vault policy write #{policy} /acl_policies/#{policy}.hcl")
        vault_exec("VAULT_TOKEN=#{vault_root_token} vault token create -policy=#{policy} -period=240h")
      end
    end
  end
end
