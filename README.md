NOTE: DEPRECATED
All was looking good, untill istio installation failed, which lead to discover that the kube-dns service was not really fully working for the DNS requests (although the coredns pods did answer correctly when queried directly on pod-ip)... the coredns config and debug logs did not show anything unusual, and the same k3s config works correctly when installed in a VBOX-VM instead of LXC containers, so the problem seems to be related to lxc and ?maybe the vxlan/flannel/networking and possibly some kernel module that is missing (not passed) in the LXC container via  the profile? Who knows... either way, it seems not many have worke with k3s over lxc, so even if this problems is overcome, more can then appear, and there will be little info/support ... So, I've tried all the same k3s installationd and config in a VBox VM, via Vagrant - and it all went smoothly at first try, and very easy to do via Vagrant, so I'll leave the k3s_on_lxlxd and switch to k3s over Vbox-VM :)

# k3s_on_lxd
k3s on lxd :) 

