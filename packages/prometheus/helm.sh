#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/prometheus/.env

case $(checkOpt iub $@) in
    i | install)
        ! checkHelmRepo ${CHART_REPOSITORY_NAME} && \
            helm repo add ${CHART_REPOSITORY_NAME} ${CHART_REGISTRY} && helm repo update
        ! checkNamespace ${INSTALL_NAMESPACE} && \
            kubectl create namespace ${INSTALL_NAMESPACE}
            helm upgrade ${INSTALL_NAME} ${CHART_REPOSITORY_ORG}/${CHART_REPOSITORY_NAME} \
                --version ${INSTALL_VERSION} \
                --namespace ${INSTALL_NAMESPACE} \
                --install \
                --set prometheus-node-exporter.hostRootFsMount.enabled=false
                # https://github.com/prometheus-community/helm-charts/issues/467
                # container 환경에서 rootFS mount를 방지하게 하기 위한 설정 추가
    ;;
    u | uninstall | teardown)
        deleteSequence ingress ${INSTALL_NAME}
        deleteSequence helm ${INSTALL_NAME} ${INSTALL_NAMESPACE}
        deleteSequence namespace ${INSTALL_NAMESPACE}
        deleteSequence helm-repo ${CHART_REPOSITORY_NAME}
    ;;
    open)

    ;;
    h | help | ? | *)
    ;;
esac