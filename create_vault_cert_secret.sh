kubectl create secret generic vault-server-tls \
    --namespace vault \
    --save-config \
    --dry-run=client \
    --from-file=tls.key=vault-k3s.key \
    --from-file=tls.crt=vault-k3s.crt \
    --from-file=ca.crt=vault.ca \
    -o yaml | kubectl apply -f -