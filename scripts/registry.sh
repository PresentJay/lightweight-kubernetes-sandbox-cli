#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/common.sh

# Prerequisite 검사 (kubectl, helm)
checkPrerequisite helm
checkPrerequisite kubectl

# cluster management
case $(checkOpt iub $@) in
    b | bootstrap)
      # TODO
    ;;
    i | install)
        case $2 in
            ingress-nginx)
                ### Ingress-Nginx 설치 (클러스터 내 트래픽 관리) ###
                helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && helm repo update
                helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
                    --namespace ingress-nginx \
                    --create-namespace \
                    --version ${INGRESS_NGINX_VERSION}
            ;;
            longhorn)
                ### Longhorn Storage 설치 (클러스터 내 가상 스토리지 관리) ###
                helm repo add longhorn https://charts.longhorn.io && helm repo update
                case $_OS_ in
                    linux)
                        helm upgrade --install longhorn longhorn/longhorn \
                            --namespace longhorn-system \
                            --create-namespace \
                            --set csi.kubeletRootDir=/var/lib/kubelet \
                            --version ${LONGHORN_VERSION}
                    ;;
                    windows)
                        helm upgrade --install longhorn longhorn/longhorn \
                            --install longhorn \
                            --namespace longhorn-system \
                            --create-namespace \
                            --version ${LONGHORN_VERSION}
                    ;;
                esac
            ;;
            k8s-dashboard)
                ### Kubernetes Dashboard 설치 (클러스터 모니터링 도구) ###
                helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard && helm repo update
                helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
                    --namespace kubernetes-dashboard \
                    --create-namespace \
                    --version ${K8S_DASHBOARD_VERSION} \
                    --set=extraArgs="{--token-ttl=0}"
            ;;
            cert-manager)
                kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
                kubectl apply -f objects/cert-selfissuer.yaml
            ;;
            h | help | ? | *)
                logKill "supporting registries: [ingress-nginx], [longhorn], [k8s-dashboard], [cert-manager]"
                scripts/registry.sh --help
            ;;
        esac
    ;;
    u | uninstall)
        case $2 in
            ingress-nginx)
                ### Ingress-Nginx 삭제 ###
                helm uninstall ingress-nginx
                kubectl delete namespace ingress-nginx
            ;;
            longhorn)
                ### Longhorn Storage 삭제 ###
                helm uninstall longhorn
                kubectl delete namespace longhorn-system
            ;;
            k8s-dashboard)
                ### Kubernetes Dashboard 삭제 ###
                helm uninstall kubernetes-dashboard
                kubectl delete namespace kubernetes-dashboard
            ;;
            cert-manager)
                kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
            ;;
            h | help | ? | *)
                logKill "supporting registries: [ingress-nginx], [longhorn], [k8s-dashboard], [cert-manager]"
                scripts/registry.sh --help
            ;;
        esac
    ;;
    set-ingress)
        LOCAL_ADDRESS=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}" | cut -d"/" -f3 | cut -d":" -f1)

        if [[ ${PREFER_PROTOCOL}="https" ]]; then
            PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.spec.ports[1].nodePort}")
        elif [[ ${PREFER_PROTOCOL}="http" ]]; then
            PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.spec.ports[0].nodePort}")
        else
            logKill "PREFER_PROTOCOL env error: please check your config/.env"
        fi

        case $_OS_ in
            linux)
                RUN="open"
                EXP="sh"
            ;;
            windows)
                RUN="start"
                EXP="bat"
            ;;
        esac

        case $2 in
            # TODO
            h | help | ? | *)
                logKill "supporting ingresses: [longhorn], [k8s-dashboard]"
                scripts/registry.sh --help
            ;;
        esac
    ;;
    h | help | ? | *)
        logHelpHead "scripts/registry.sh"
        logHelpContent i install "install registry"
        logHelpContent u uninstall "uninstall registry"
        logHelpContent set-ingress "set ingress of pod"
        logHelpTail
    ;;
esac