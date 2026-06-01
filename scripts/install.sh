#!/usr/bin/env bash
# Install HashiCorp Vault in HA + Raft mode via Helm.
set -euo pipefail

NAMESPACE="${NAMESPACE:-vault}"

echo "==> Adding HashiCorp Helm repo"
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

echo "==> Installing Vault (HA + Raft) into namespace: $NAMESPACE"
helm upgrade --install vault hashicorp/vault \
  --namespace "$NAMESPACE" --create-namespace \
  -f helm/values.yaml

echo "==> Waiting for vault-0 pod to be created"
kubectl -n "$NAMESPACE" wait --for=condition=Initialized pod/vault-0 --timeout=120s || true

echo "Vault installed. Next: ./scripts/init-unseal.sh"
