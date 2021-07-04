#!/bin/bash

source /etc/kubecube/manifests/cube.conf
source /etc/kubecube/manifests/utils.sh

function sign_cert() {
  clog info "signing cert for kubecube"
  mkdir -p ca
  cd ca

  clog debug "generate ca key and ca cert"
  openssl genrsa -out ca.key 2048
  openssl req -x509 -new -nodes -key ca.key -subj "/CN=*.kubecube-system" -days 10000 -out ca.crt

  clog debug "generate tls key"
  openssl genrsa -out tls.key 2048

  clog debug "make tls csr"
cat << EOF >csr.conf
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = ch
ST = zj
L = hz
O = kubecube
CN = *.kubecube-system

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = *.kubecube-system
DNS.2 = *.kubecube-system.svc
DNS.3 = *.kubecube-system.svc.cluster.local
IP.1 = 127.0.0.1
IP.2 = ${IPADDR}

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF
  openssl req -new -key tls.key -out tls.csr -config csr.conf

  clog debug "generate tls cert"
  openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tls.crt -days 10000 -extensions v3_ext -extfile csr.conf
  cd ..
}

function render_values() {
  clog info "render values for kubecube helm chart"
cat >values.yaml <<EOF
kubecube:
  replicas: ${kubecube_replicas}
  args:
    logLevel: ${kubecube_args_logLevel}
  env:
    pivotCubeHost: ${IPADDR}:30443

webhook:
  caBundle: $(cat ca/ca.crt | base64 -w 0)

tlsSecret:
  key: $(cat ca/tls.key | base64 -w 0)
  crt: $(cat ca/tls.crt | base64 -w 0)

caSecret:
  key: $(cat ca/ca.key | base64 -w 0)
  crt: $(cat ca/ca.crt | base64 -w 0)

pivotCluster:
  kubernetesAPIEndpoint: ${IPADDR}:6443
  kubeconfig: $(cat /root/.kube/config | base64 -w 0)
EOF
}

clog debug "create namespace for kubecube"
kubectl apply -f /etc/kubecube/manifests/ns/ns.yaml

clog info "deploy frontend for kubecube"
kubectl apply -f /etc/kubecube/manifests/frontend/frontend.yaml

clog info "deploy audit server for kubecube"
kubectl apply -f /etc/kubecube/manifests/audit/audit.yaml

sign_cert
render_values

clog info "deploy kubecube"
/usr/local/bin/helm install -f values.yaml kubecube /etc/kubecube/manifests/kubecube/v0.0.1

clog info "waiting for kubecube ready"
spin & spinpid=$!
clog debug "spin pid: ${spinpid}"
while true
do
  cube_healthz=$(curl -s -k https://${IPADDR}:30443/healthz)
  warden_healthz=$(curl -s -k https://${IPADDR}:31443/healthz)
  if [[ ${cube_healthz} = "healthy" && ${warden_healthz} = "healthy" ]]; then
    echo
    echo -e "\033[32m========================================================\033[0m"
    echo -e "\033[32m========================================================\033[0m"
    echo -e "\033[32m               Welcome to KubeCube!                   \033[0m"
    echo -e "\033[32m         Please use 'admin/admin123' to access        \033[0m"
    echo -e "\033[32m                '${IPADDR}:30080'                     \033[0m"
    echo -e "\033[32m         You must change password after login         \033[0m"
    echo -e "\033[32m========================================================\033[0m"
    echo -e "\033[32m========================================================\033[0m"
    kill "$spinpid" > /dev/null
    exit 0
  fi
  sleep 7 > /dev/null
done


