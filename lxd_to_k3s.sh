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

delete_if_k3sLxc_already_exists() {
  if lxc list | grep k3smaster &>/dev/null 
  then
    lxc stop k3smaster && sleep 2
    lxc delete k3smaster
  fi

}

abort_if_k3sLxc_already_exists() {
  if lxc list | grep k3smaster &>/dev/null 
  then
    cat <<EOT
ERROR: lxc-container k3smaster already exists. If you want to manually delete it (and know what your doing), do:
  lxc stop k3smaster
  lxc delete k3smaster
EOT
    exit 1
  fi
}

assure_exists_storagePool_k3s_type_dir() {
  if ! lxc storage list | grep k3s 
  then
    lxc storage create k3s dir
  fi
}

exec_in_container() {
  local container="${1?missing arg}"; shift 
  local cmd="${1?missing arg}"; shift 
  lxc exec "${container}" -- bash -c "${cmd}"
}

assure_exists_profile_k3sprofile() {
  if lxc profile show "${LXC_PROFILE_NAME}" &>/dev/null
  then
    # profile already exists, lets delete it
    lxc profile delete "${LXC_PROFILE_NAME}"
  fi
  lxc profile create "${LXC_PROFILE_NAME}"
  cat "${LXC_PROFILE_NAME}".yaml | lxc profile edit "${LXC_PROFILE_NAME}"
  lxc profile show "${LXC_PROFILE_NAME}"
}

systemctl_k3s_status_or_logs() {
  #exec_in_container k3smaster    'systemctl status k3s; journalctl -xeu k3s'
  #exec_in_container k3smaster    'systemctl stop k3s; clear; k3s'
  exec_in_container k3smaster    'systemctl --no-pager status k3s'
}

extract_and_load_kubeconfig() {
  rm kubeconfig.k3s.yaml || true
  lxc file pull k3smaster/etc/rancher/k3s/k3s.yaml kubeconfig.k3s.yaml
  sed -i 's:127.0.0.1:k3smaster:;s:default:k3s-lxc:g' kubeconfig.k3s.yaml
  #mkdir -p ~/.kube
  #KUBECONFIG=k3s.yaml kubectl config view --raw | tee ~/.kube/config
  export KUBECONFIG=$PWD/kubeconfig.k3s.yaml
  kubectl config use-context k3s-lxc
  kubectl get namespaces
}

report_memory_footprint() {
  echo "Reporting memory footprint"
  set +x
  for ((i=0; i<$(($1 / 5)); i++)); do
    shw_info "[$i/10] $(lxc info k3smaster | grep Memory | tr '\n' '\t')"
    sleep 5
  done
  set -x
}

k__launch_busybox_deployment() {
  kubectl apply -f "${__dir}"/manifests/one-files/busybox.deployment.yaml
  sleep 2
  kubectl get all
  ## old friki code, from tests with NodePort
  ## Code looks so friki, that it deserves to remain as comment :)
  #IP_LxcK3smaster=$(lxc list k3smaster --format json | jq -r '.[0].state.network.eth0.addresses[0].address')
  # #nc $IP_LxcK3smaster 30001
  # # bonus shell-power
  # cat < /dev/tcp/$IP_LxcK3smaster/30001

  # Test the ingress service connection
  curl -kv http://k3smaster

}

k__patch_metrics_server() {
  # As of nov.2020, if "k top nodes" does not work properly, then probably the metrics-server is misconfigured and needs fixing
  # See https://github.com/kubernetes-sigs/kind/issues/398
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
  kubectl patch deployment metrics-server -n kube-system -p '{"spec":{"template":{"spec":{"containers":[{"name":"metrics-server","args":["--cert-dir=/tmp", "--secure-port=4443", "--kubelet-insecure-tls","--kubelet-preferred-address-types=InternalIP"]}]}}}}'
  sleep 5
  # kubectl top nodes should now start working after some minutes
}

main() {
  LXC_PROFILE_NAME=lxdprofile.k3s
  #NOTE: DONT USE ZFS, as k3s will install, but containers might not run 
  # properly and instead show evens about overlay filesystem errors
  #LXC_PROFILE_NAME=lxdprofile.k3s_over_zfs


  delete_if_k3sLxc_already_exists
  #abort_if_k3sLxc_already_exists

  assure_exists_storagePool_k3s_type_dir
  assure_exists_profile_k3sprofile

  lxc launch images:debian/10 k3smaster --profile "${LXC_PROFILE_NAME}"
  #lxc config show k3smaster

  exec_in_container k3smaster    'apt-get install -y ca-certificates curl'
  exec_in_container k3smaster    "echo 'L /dev/kmsg - - - - /dev/console' > /etc/tmpfiles.d/kmsg.conf"
  exec_in_container k3smaster    reboot
  sleep 5

  # k3s latest version v1.18.9+k3s1 consumes 500-800MB ram when idle, before any workload... expected much lighter than that...
  exec_in_container k3smaster    'curl -sfL https://get.k3s.io | sh -'
  # k3s version from jan2020: 1,26GB idle
  #exec_in_container k3smaster    'curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.17.0+k3s.1  sh -'
  sleep 20

  systemctl_k3s_status_or_logs
  
  extract_and_load_kubeconfig
  #report_memory_footprint 60

  k__patch_metrics_server
  
  k__launch_busybox_deployment

  cat <<'EOT'
Manually do:

  # add k3smaster into /etc/hosts
  sudo vi /etc/hosts
  ...
  k3smaster 1.2.3.4   (ip-of-lxc-container k3smaster)

  # go happy hacking with the k3s cluster :)
  source $PWD/k3s.source
  kubectl get namespaces
  k get all,ingress,persistentvolumeclaims

EOT

}

main "$@"
