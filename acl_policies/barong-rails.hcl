# Access system health status
path "sys/health" {
  capabilities = ["read", "list"]
}

# Manage the transit secrets engine
path "transit/keys/*" {
  capabilities = [ "create", "read", "list" ]
}

# Encrypt engines secrets
path "transit/encrypt/z-dax_apikeys_*" {
  capabilities = [ "create", "read", "update" ]
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

# Generate otp code
path "totp/keys/z-dax_*" {
  capabilities = ["create", "read"]
}

# Verify an otp code
path "totp/code/z-dax_*" {
  capabilities = ["update"]
}
