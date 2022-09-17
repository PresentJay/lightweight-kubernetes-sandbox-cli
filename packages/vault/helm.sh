#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/vault/.env

case $(checkOpt iu $@) in
    i | install)
        ! checkHelmRepo ${CHART_REPOSITORY_NAME} && \
            helm repo add ${CHART_REPOSITORY_NAME} ${CHART_REGISTRY} && helm repo update
        ! checkNamespace ${INSTALL_NAMESPACE} && \
            kubectl create namespace ${INSTALL_NAMESPACE}
        helm upgrade ${INSTALL_NAME} ${CHART_ORG}/${CHART_NAME} \
            --version ${INSTALL_VERSION} \
            --namespace ${INSTALL_NAMESPACE} \
            --install \
            --set server.ha.enabled=true \
            --set server.ha.raft.enabled=true \
            --set ui.enabled=true \
            --set server.enable=true \
            --set server.logLevel=${LOGLEVEL} \
            --set server.dataStorage.storageClass=${STORAGE} \
            --set server.dataStorage.size=${PVC_SIZE} \
            --set server.serviceAccount.name=${SERVICEACCOUNT}
        applyIngressNginxHTTP ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
    ;;
    u | uninstall | teardown)
        deleteSequence helm ${INSTALL_NAME} ${INSTALL_NAMESPACE}
        deleteSequence namespace ${INSTALL_NAMESPACE}
        deleteSequence helm-repo ${CHART_REPOSITORY_NAME}
    ;;
    unseal)
        initResult=$(kubectl exec -n ${INSTALL_NAMESPACE} ${INSTALL_NAME}-$2 -- vault operator init)
        logInfo "init vault-$2 processing. . ."
        unsealKey1=$(echo ${initResult} | awk '{print $4}')
        createSecret unsealKey1 ${unsealKey1} packages/vault/unseal-data-$2
        unsealKey2=$(echo ${initResult} | awk '{print $8}')
        createSecret unsealKey2 ${unsealKey2} packages/vault/unseal-data-$2
        unsealKey3=$(echo ${initResult} | awk '{print $12}')
        createSecret unsealKey3 ${unsealKey3} packages/vault/unseal-data-$2
        unsealKey4=$(echo ${initResult} | awk '{print $16}')
        createSecret unsealKey4 ${unsealKey4} packages/vault/unseal-data-$2
        unsealKey5=$(echo ${initResult} | awk '{print $20}')
        createSecret unsealKey5 ${unsealKey5} packages/vault/unseal-data-$2
        rootKey=$(echo ${initResult} | awk '{print $24}')
        createSecret rootKey ${rootKey} packages/vault/unseal-data-$2
        
        kubectl exec -n ${INSTALL_NAMESPACE} ${INSTALL_NAME}-$2 -- vault operator unseal ${unsealKey1}
        kubectl exec -n ${INSTALL_NAMESPACE} ${INSTALL_NAME}-$2 -- vault operator unseal ${unsealKey2}
        kubectl exec -n ${INSTALL_NAMESPACE} ${INSTALL_NAME}-$2 -- vault operator unseal ${unsealKey3}
        kubectl exec -n ${INSTALL_NAMESPACE} ${INSTALL_NAME}-$2 -- vault operator unseal ${unsealKey4}
        kubectl exec -n ${INSTALL_NAMESPACE} ${INSTALL_NAME}-$2 -- vault operator unseal ${unsealKey5}
    ;;
    open)
        if checkParamIsInList ${INGRESS_PROTOCOL} http https; then
            _HOSTURL_="${INGRESS_HOSTNAME}.${masterNodeIP}.nip.io"
            _PORT_=$(bash packages/ingress-nginx/helm.sh --${INGRESS_PROTOCOL}Port)
            _OPENURI_="${INGRESS_PROTOCOL}://${_HOSTURL_}:${_PORT_}"
            openURI ${_OPENURI_}
            logInfo "If vault is just installed, please check the unseal, and give root-token"
        else
            logKill "please set INGRESS_PROTOCOL to http or https only. (in .env)"
        fi
    ;;
    h | help | ? | *)
        logHelpHead "packages/vault/helm.sh"
        logHelpContent i install "install vault package"
        logHelpContent u uninstall "uninstall vault package"
        logHelpTail
    ;;
esac