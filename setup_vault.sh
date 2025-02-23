vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
vault write pki_int/config/urls issuing_certificates="https://vault.vault.svc.cluster.local:8200/v1/pki_int/ca" crl_distribution_points="https://vault.vault.svc.cluster.local:8200/v1/pki_int/crl"
vault write pki_int/roles/local-dot-lan allowed_domains=local.lan allow_subdomains=true max_ttl=8760h
vault write pki_int/roles/ycdisp-dot-net allowed_domains=ycdisp.net allow_subdomains=true max_ttl=8760h

vault policy write ansible - <<EOF
path "secret/*" {
  capabilities = [ "read" ]
}
EOF

vault policy write admins - <<EOF
# Read system health check
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# Create and manage ACL policies broadly across Vault

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Enable and manage authentication methods broadly across Vault

# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# Enable and manage the key/value secrets engine at secret/ path

# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read"]
}

# Access pki engine
path "pki_int*"                      
{ 
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF

vault policy write pki - <<EOF
path "pki_int*"                      
{ 
  capabilities = ["read", "list"] 
}

path "pki_int/sign/local-dot-lan"    
{ 
  capabilities = ["create", "update"] 
}

path "pki_int/issue/local-dot-lan"   
{ 
  capabilities = ["create"] 
}

path "pki_int/sign/ycdisp-dot-net"    
{ 
  capabilities = ["create", "update"] 
}

path "pki_int/issue/ycdisp-dot-net"   
{ 
  capabilities = ["create"] 
}
EOF

vault auth enable approle
vault write auth/approle/role/ansible token_num_uses=0 token_ttl=0m secret_id_num_uses=0 token_no_default_policy=false token_policies="ansible"
vault auth enable userpass
vault write auth/userpass/users/eingram password=temppassword policies=admins
vault auth enable kubernetes
vault write auth/kubernetes/config kubernetes_host="https://kubernetes.default.svc.cluster.local:443"
vault write auth/kubernetes/role/issuer bound_service_account_names=issuer bound_service_account_namespaces=cert-manager policies=pki ttl=20m

