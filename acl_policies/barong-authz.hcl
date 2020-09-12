# Access system health status
path "sys/health" {
  capabilities = ["read", "list"]
}

# Manage the transit secrets engine
path "transit/keys/*" {
  capabilities = [ "create", "read", "list" ]
}

# Decrypt engines secrets
path "transit/decrypt/z-dax_apikeys_*" {
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
