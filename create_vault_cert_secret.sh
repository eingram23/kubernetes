kubectl create secret generic vault-server-tls \
    --namespace vault \
    --save-config \
    --dry-run=client \
    --from-file=tls.key=cert.key \
    --from-file=tls.crt=cert.crt \
    --from-file=ca.crt=cert.ca \
    -o yaml | kubectl apply -f -