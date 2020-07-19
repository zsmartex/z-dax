# Manage the transit secrets engine
path "transit/keys/*" {
  capabilities = [ "create", "read", "list" ]
}

# Decrypt Engines secrets
path "transit/decrypt/z-dax_engines_*" {
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
