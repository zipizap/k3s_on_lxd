#!/usr/bin/env bash
kubectl get events \
  -o custom-columns=FirstSeen:.firstTimestamp,LastSeen:.lastTimestamp,Count:.count,From:.source.component,Obj:.involvedObject.name,Type:.type,Reason:.reason,Message:.message \

# --field-selector involvedObject.kind=Pod
