# Manage the transit secrets engine
path "transit/keys/*" {
  capabilities = [ "create", "read", "list" ]
}

# Encrypt engines secrets
path "transit/encrypt/z-dax_engines_*" {
  capabilities = [ "create", "read", "update" ]
}

# Encrypt wallets secrets
path "transit/encrypt/z-dax_wallets_*" {
  capabilities = [ "create", "read", "update" ]
}

# Renew tokens
path "auth/token/renew" {
  capabilities = [ "update" ]
}

# Lookup tokens
path "auth/token/lookup" {
  capabilities = [ "update" ]
}

# Verify an otp code
path "totp/code/z-dax_*" {
  capabilities = ["update"]
}
