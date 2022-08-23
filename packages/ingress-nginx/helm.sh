#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/common.sh

# Prerequisite 검사 (kubectl, helm)
checkPrerequisite helm
checkPrerequisite kubectl

case $(checkOpt iub $@) in
    i | install)
        ### Ingress-Nginx 설치 (클러스터 내 트래픽 관리) ###
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && helm repo update
        helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
            --namespace ingress-nginx \
            --create-namespace \
            --version ${INGRESS_NGINX_VERSION}
    ;;
    u | uninstall | teardown)

    ;;
    conf-update)

    ;;
    conf-delete)

    ;;
    conf-check)

    ;;
    conf-add)

    ;;
esac