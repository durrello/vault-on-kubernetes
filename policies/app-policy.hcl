# Read-only access to the demo app's secrets under secret/data/app/*
path "secret/data/app/*" {
  capabilities = ["read"]
}

# Allow the app to look up its own token info
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
