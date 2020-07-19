# Manage the transit secrets engine
path "transit/keys/*" {
  capabilities = [ "create", "read", "list" ]
}

# Encrypt Payment Addresses secrets
path "transit/encrypt/z-dax_payment_addresses_*" {
  capabilities = [ "create", "read", "update" ]
}

# Decrypt Payment Addresses secrets
path "transit/decrypt/z-dax_payment_addresses_*" {
  capabilities = [ "create", "read", "update" ]
}

# Decrypt wallets secrets
path "transit/decrypt/z-dax_wallets_*" {
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
