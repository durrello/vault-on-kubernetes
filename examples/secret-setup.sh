#!/usr/bin/env bash
# Run INSIDE vault-0 (kubectl exec -it vault-0 -- sh) after logging in with the root token.
# Enables KV, writes a demo secret, configures Kubernetes auth, and binds the app policy.
set -euo pipefail

# 1. Enable KV v2 secrets engine
vault secrets enable -path=secret kv-v2 || true

# 2. Write a demo secret
vault kv put secret/app/config username="appuser" password="example-not-a-real-secret"

# 3. Enable and configure Kubernetes auth
vault auth enable kubernetes || true
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

# 4. Load the read-only policy (copy policies/app-policy.hcl into the pod first)
vault policy write app-policy /vault/userconfig/app-policy.hcl || \
  echo "Provide app-policy.hcl to the pod, then re-run this step."

# 5. Bind a Kubernetes ServiceAccount to the policy
vault write auth/kubernetes/role/app \
  bound_service_account_names="app-sa" \
  bound_service_account_namespaces="default" \
  policies="app-policy" \
  ttl="1h"

echo "Setup complete. A pod using SA 'app-sa' can now read secret/app/*."
