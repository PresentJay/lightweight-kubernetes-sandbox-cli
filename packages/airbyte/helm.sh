#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/airbyte/.env

case $(checkOpt iu $@) in
    i | install)
        ! checkHelmRepo ${CHART_REPOSITORY_NAME} && \
            helm repo add ${CHART_REPOSITORY_NAME} ${CHART_REGISTRY} && helm repo update
        ! checkNamespace ${INSTALL_NAMESPACE} && \
            kubectl create namespace ${INSTALL_NAMESPACE}
        
        helm upgrade ${INSTALL_NAME} ${CHART_ORG}/${CHART_NAME} \
            --namespace ${INSTALL_NAMESPACE} \
            --install \
            --set fullnameOverride=${INSTALL_NAME} \
            --set postgresql.postgresqlDatabase=${POSTGRES_DB} \
            --set postgresql.postgresqlUsername=${POSTGRES_USER} \
            --set postgresql.postgresqlPassword=${POSTGRES_PASSWORD} \
            --set webapp.ingress.enabled=false \
            --set server.replicaCount=${SERVER_REPLICA_COUNT} \
            --set worker.replicaCount=${WORKER_REPLICA_COUNT} \
            --set minio.auth.rootUser=${MINIO_ROOT} \
            --set minio.auth.rootPassword=${MINIO_ROOT_SECRET}

        applyIngressNginxHTTP ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
    ;;
    u | uninstall | teardown)
        deleteSequence helm ${INSTALL_NAME} ${INSTALL_NAMESPACE}
        deleteSequence namespace ${INSTALL_NAMESPACE}
        deleteSequence helm-repo ${CHART_REPOSITORY_NAME}
    ;;
    open)
        if checkParamIsInList ${INGRESS_PROTOCOL} http https; then
            _HOSTURL_="${INGRESS_HOSTNAME}.${masterNodeIP}.nip.io"
            _PORT_=$(bash packages/ingress-nginx/helm.sh --${INGRESS_PROTOCOL}Port)
            _OPENURI_="${INGRESS_PROTOCOL}://${_HOSTURL_}:${_PORT_}"
            openURI ${_OPENURI_}
        else
            logKill "please set INGRESS_PROTOCOL to http or https only. (in .env)"
        fi
    ;;
    h | help | ? | *)
        logHelpHead "packages/airbyte/helm.sh"
        logHelpContent i install "install airbyte package"
        logHelpContent u uninstall "uninstall airbyte package"
        logHelpContent open "open airbyte package web"
        logHelpTail
    ;;
esac