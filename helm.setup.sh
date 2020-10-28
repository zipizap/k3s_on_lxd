helm repo add stable https://charts.helm.sh/stable && helm repo update

# correct way to install/upgrade chart, with auto-rollback on failure
# https://medium.com/polarsquad/check-your-helm-deployments-ffe26014804
#    helm upgrade --install --atomic ...
#      and implicitly --atomic adds --wait which implicitly uses --timeout 300 
#      and overall this would be the same as
#    helm upgrae --install --atomic --wait --timeout 300 ...
