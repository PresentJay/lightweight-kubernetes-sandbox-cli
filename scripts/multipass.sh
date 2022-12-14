#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/common.sh

# Prerequisite 검사 (multipass, kubectl)
checkPrerequisite multipass

# cluster management
case $(checkOpt iupr $@) in
    i | install)
        # .env에 정의한 cluster setup에 맞춰 노드 생성
        ITER=${CLUSTER_NODE_STARTINDEX}
        while [[ ${ITER} -le $(( CLUSTER_NODE_STARTINDEX + CLUSTER_NODE_AMOUNT - 1 )) ]]; do
            multipass launch \
                --name node${ITER} \
                --cpus ${CLUSTER_CPU_CAPACITY} \
                --mem ${CLUSTER_MEM_CAPACITY}G \
                --disk ${CLUSTER_DISK_AMOUNT}G \
                ${CLUSTER_UBUNTU_VERSION}

            # 각 노드별 필수 유틸리티 설치 (nfs, iscsi : virtual storage 위한 설치)
            multipass exec node${ITER} -- sudo apt-get update -y
            multipass exec node${ITER} -- sudo apt-get install -y \
                nfs-common \
                open-iscsi \
                nfs-kernel-server \
                lvm2 &

            ITER=$(( ITER+1 ))
        done
        wait
    ;;
    u | uninstall)
        # .env에 정의한 cluster setup에 맞춰 노드 삭제
        ITER=${CLUSTER_NODE_STARTINDEX}
        while [[ ${ITER} -le $(( CLUSTER_NODE_STARTINDEX + CLUSTER_NODE_AMOUNT - 1 )) ]]; do
            multipass delete node${ITER} -p &
            ITER=$(( ITER+1 ))
        done
        wait
    ;;
    p | pause)
        # .env에 정의한 cluster setup에 맞춰 노드 stop
        ITER=${CLUSTER_NODE_STARTINDEX}
        while [[ ${ITER} -le $(( CLUSTER_NODE_STARTINDEX + CLUSTER_NODE_AMOUNT - 1 )) ]]; do
            multipass stop node${ITER} &
            ITER=$(( ITER+1 ))
        done
        wait
    ;;
    r | resume)
        # .env에 정의한 cluster setup에 맞춰 노드 restart
        ITER=${CLUSTER_NODE_STARTINDEX}
        while [[ ${ITER} -le $(( CLUSTER_NODE_STARTINDEX + CLUSTER_NODE_AMOUNT - 1 )) ]]; do
            multipass start node${ITER} &
            ITER=$(( ITER+1 ))
        done
        wait
    ;;
    check-node)
        if [[ -n $(multipass list | grep $1) ]]; then
            echo $TRUE
        else
            echo $FALSE
        fi
    ;;
    h | help | ? | *)
        logHelpHead "scripts/multipass.sh"
        logHelpContent i install "install multipass clusters"
        logHelpContent u uninstall "uninstall clusters"
        logHelpContent p pause "pause clusters"
        logHelpContent r resume "resume paused clusters"
        logHelpContent check-node "check node is live"
        logHelpTail
    ;;
esac