helm repo add stable https://charts.helm.sh/stable && helm repo update

# correct way to install/upgrade chart, with auto-rollback on failure
# https://medium.com/polarsquad/check-your-helm-deployments-ffe26014804
#    helm upgrade --install --atomic ...
#      and implicitly --atomic adds --wait which implicitly uses --timeout 300 
#      and overall this would be the same as
#    helm upgrade --install --atomic --wait --timeout 300 ...

# k get ingress -o custom-columns=NAME:.metadata.name,INGRESS-IP0:.status.loadBalancer.ingress[].ip,HOST0:.spec.rules[].host,PATH0:.spec.rules[].http.paths[].path,SERVICE-NAME0:.spec.rules[].http.paths[].backend.serviceName,SERVICE-PORT0:.spec.rules[].http.paths[].backend.servicePort
#  - get
#  - ingress
#  - -o
#  - custom-columns=NAME:.metadata.name,INGRESS-IP0:.status.loadBalancer.ingress[].ip,HOST0:.spec.rules[].host,PATH0:.spec.rules[].http.paths[].path,SERVICE-NAME0:.spec.rules[].http.paths[].backend.serviceName,SERVICE-PORT0:.spec.rules[].http.paths[].backend.servicePort
# [ 'get', 'ingress', '-o', 'custom-columns=NAME:.metadata.name,INGRESS-IP0:.status.loadBalancer.ingress[].ip,HOST0:.spec.rules[].host,PATH0:.spec.rules[].http.paths[].path,SERVICE-NAME0:.spec.rules[].http.paths[].backend.serviceName,SERVICE-PORT0:.spec.rules[].http.paths[].backend.servicePort' ]

