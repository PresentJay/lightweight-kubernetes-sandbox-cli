#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/common.sh

# Prerequisite 검사 (multipass, kubectl)
checkPrerequisite multipass

# cluster management
case $(checkOpt iupr $@) in
    i | install)
        # 생성한 node에서 k3s cluster 구축
        # k3s 버전은 .env에 정의한 kubernetes를 기반으로 함
        ITER=${CLUSTER_NODE_STARTINDEX}
        while [[ ${ITER} -le $(( CLUSTER_NODE_STARTINDEX + CLUSTER_NODE_AMOUNT - 1 )) ]]; do
            if [[ ${ITER} -eq 1 ]]; then
                # Master node : k3s 설치
                # kubernetes version 고정, traefik 사용 해제(v1이기 때문), servicelb 사용 해제, 기본 스토리지 해제
                # feature gate 활성화: TTLAfterFinished(Job 자동삭제), CronJobControllerV2(크론잡 개선)
                multipass exec node${ITER} -- bash -c "curl -sfL https://get.k3s.io | \
                    INSTALL_K3S_VERSION=${K3S_VERSION} \
                    sh -s - server \
                    --disable traefik \
                    --disable servicelb \
                    --disable local-storage \
                    --kube-apiserver-arg feature-gates=TTLAfterFinished=true,CronJobControllerV2=true"

                # Master node에 접근할 수 있는 인증 토큰 및 Endpoint 정보 저장
                K3S_TOKEN=$(multipass exec node1 -- bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")
                K3S_URL=$(multipass info node1 | grep IPv4 | awk '{print $2}')
                K3S_URL_FULL="https://${K3S_URL}:6443"
            else
                # Worker node : k3s 설치 (Master Node에 대해 K3S_TOKEN을 통한 인증)
                multipass exec node${ITER} -- bash -c "curl -sfL: https://get.k3s.io | \
                    INSTALL_K3S_VERSION=${K3S_VERSION} K3S_URL=\"${K3S_URL_FULL}\" K3S_TOKEN=\"${K3S_TOKEN}\" sh -"
            fi
            
            logSuccess "node${ITER} is set for k3s"
            ITER=$(( ITER+1 ))
        done
        case $(checkOS) in
            "linux" | "mac")
                multipass exec node${CLUSTER_NODE_STARTINDEX} sudo cat /etc/rancher/k3s/k3s.yaml > ${KUBECONFIG_LOC}
                sed -i '' "s/127.0.0.1/${K3S_URL}/" ${KUBECONFIG_LOC}
            ;;
            "win")
                multipass exec node${CLUSTER_NODE_STARTINDEX} -- bash -c "sudo cat /etc/rancher/k3s/k3s.yaml" > ${KUBECONFIG_LOC}
                sed -i "s/127.0.0.1/${K3S_URL}/" ${KUBECONFIG_LOC}
            ;;
        esac

        ### helm의 config permission error 제거 ###
        chmod o-r ${KUBECONFIG_LOC}
        chmod g-r ${KUBECONFIG_LOC}
    ;;
    u | uninstall)
        # TBD
    ;;
    h | help | ? | *)
        logHelpHead "scripts/k3s.sh"
        logHelpContent i install "install k3s cluster"
        logHelpContent u uninstall "uninstall k3s cluster (TBD)"
        logHelpTail
    ;;
esac