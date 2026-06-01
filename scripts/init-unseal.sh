#!/usr/bin/env bash
# Initialize the Raft cluster on vault-0, unseal all replicas, and join followers.
# WARNING: writes unseal keys + root token to ./vault-keys.json (plaintext).
# Protect this file. In production use auto-unseal (KMS/Transit) instead.
set -euo pipefail

NAMESPACE="${NAMESPACE:-vault}"
KEYS_FILE="vault-keys.json"

echo "==> Initializing vault-0"
kubectl -n "$NAMESPACE" exec vault-0 -- vault operator init \
  -key-shares=3 -key-threshold=2 -format=json > "$KEYS_FILE"
echo "Unseal keys + root token written to $KEYS_FILE (KEEP SAFE)."

unseal() {
  local pod="$1"
  for i in 0 1; do
    key=$(python -c "import json,sys; print(json.load(open('$KEYS_FILE'))['unseal_keys_b64'][$i])")
    kubectl -n "$NAMESPACE" exec "$pod" -- vault operator unseal "$key" >/dev/null
  done
}

echo "==> Unsealing vault-0 (leader)"
unseal vault-0

echo "==> Joining and unsealing followers"
for pod in vault-1 vault-2; do
  kubectl -n "$NAMESPACE" exec "$pod" -- \
    vault operator raft join http://vault-0.vault-internal:8200 || true
  unseal "$pod"
done

echo "==> Cluster status"
kubectl -n "$NAMESPACE" exec vault-0 -- vault status || true
echo "Done. Root token is in $KEYS_FILE (do not commit it)."
