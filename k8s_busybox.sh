#!/usr/bin/env bash

kubectl run -i --tty tmp-busybox --image=busybox --restart=Never -- "${@:-sh}"
kubectl delete pod tmp-busybox
