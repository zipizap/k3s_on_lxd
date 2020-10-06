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
  if lxc profile show k3sprofile &>/dev/null
  then
    # profile already exists, lets delete it
    lxc profile delete k3sprofile
  fi
  lxc profile create k3sprofile
  cat k3sprofile.yaml | lxc profile edit k3sprofile
  lxc profile show k3sprofile
}

main() {
  delete_if_k3sLxc_already_exists
  #abort_if_k3sLxc_already_exists

  assure_exists_storagePool_k3s_type_dir
  assure_exists_profile_k3sprofile

  lxc launch images:debian/10 k3smaster \
    --profile k3sprofile

  lxc config show k3smaster

  exec_in_container k3smaster    'apt-get install -y ca-certificates curl'
  exec_in_container k3smaster    "echo 'L /dev/kmsg - - - - /dev/console' > /etc/tmpfiles.d/kmsg.conf"
  exec_in_container k3smaster    reboot
  sleep 5
  exec_in_container k3smaster    'curl -sfL https://get.k3s.io | sh -'
  sleep 20

  #exec_in_container k3smaster    'systemctl status k3s; journalctl -xeu k3s'
  #exec_in_container k3smaster    'systemctl stop k3s; clear; k3s'
  exec_in_container k3smaster    'systemctl status k3s'
  
  lxc file pull k3smaster/etc/rancher/k3s/k3s.yaml kubeconfig.k3s.yaml
  sed -i 's:127.0.0.1:k3smaster:;s:default:k3s-lxc:g' kubeconfig.k3s.yaml
  #mkdir -p ~/.kube
  #KUBECONFIG=k3s.yaml kubectl config view --raw | tee ~/.kube/config
  export KUBECONFIG=$PWD/kubeconfig.k3s.yaml
  kubectl config use-context k3s-lxc
  kubectl get namespaces


  cat <<'EOT'
Manually do:

  # add k3smaster into /etc/hosts
  sudo vi /etc/hosts

  # go happy hacking with the k3s cluster :)
  export KUBECONFIG=$PWD/kubeconfig.k3s.yaml
  kubectl config use-context k3s-lxc
  kubectl get namespaces

EOT

}

main "$@"
