#!/usr/bin/env bash
# Paulo Aleixo Campos
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__dbg_on_off=on  # on off
function shw_info { echo -e '\033[1;34m'"$1"'\033[0m'; }
function error { echo "ERROR in ${1}"; exit 99; }
trap 'error $LINENO' ERR
function dbg { [[ "$__dbg_on_off" == "on" ]] || return; echo -e '\033[1;34m'"dbg $(date +%Y%m%d%H%M%S) ${BASH_LINENO[0]}\t: $@"'\033[0m';  }
#exec > >(tee -i /tmp/$(date +%Y%m%d%H%M%S.%N)__$(basename $0).log ) 2>&1
set -o errexit
  # NOTE: the "trap ... ERR" alreay stops execution at any error, even when above line is commente-out
set -o pipefail
set -o nounset
set -o xtrace
# https://rancher.com/docs/rancher/v2.x/en/troubleshooting/dns/
set -x

echo "Check if DNS pods are running"
kubectl -n kube-system get pods -l k8s-app=kube-dns

echo "Check if the DNS service is present with the correct cluster-ip"
kubectl -n kube-system get svc -l k8s-app=kube-dns

echo "Check if domain names are resolving"
#kubectl run -it --rm --restart=Never busybox --image=busybox:1.28 -- nslookup kubernetes.default
#kubectl run -it --rm --restart=Never busybox --image=busybox:1.28 -- sh

echo "===== CoreDNS specific ====="
echo "Check CoreDNS logging"
kubectl -n kube-system logs -l k8s-app=kube-dns
echo "Check configuration"
kubectl -n kube-system get configmap coredns -o go-template={{.data.Corefile}}
echo "Enable query logging"
kubectl get configmap -n kube-system coredns -o json | sed -e 's_loadbalance_log\\n    loadbalance_g' | kubectl apply -f -
kubectl run -it --rm --restart=Never busybox --image=busybox:1.28 -- nslookup kubernetes.default.svc.cluster.local



