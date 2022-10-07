#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/judge0/.env

case $(checkOpt iu $@) in
    i | install)
        applyConfigmap ${DOCKERNAME}-db-config ${INSTALL_NAMESPACE} \
            "POSTGRES_DB=${POSTGRES_DB}" \
            "POSTGRES_USER=${POSTGRES_USER}" \
            "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"

        applyConfigmap ${DOCKERNAME}-redis-config ${INSTALL_NAMESPACE} \
            "REDIS_PASSWORD=${REDIS_PASSWORD}" 

        applyConfigmap ${DOCKERNAME}-config ${INSTALL_NAMESPACE} \
            "REDIS_HOST=${REDIS_HOST}" \
            "REDIS_PASSWORD=${REDIS_PASSWORD}" \
            "POSTGRES_HOST=${POSTGRES_HOST}" \
            "POSTGRES_DB=${POSTGRES_DB}" \
            "POSTGRES_USER=${POSTGRES_USER}" \
            "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"

        kubectl apply -f packages/judge0/judge0.conf.yaml
        
        applyPVC ${DOCKERNAME}-db-data ${STORAGE} ${DB_PVC_SIZE} ${DB_PVC_UNIT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
        applyPVC ${DOCKERNAME}-redis-data ${STORAGE} ${REDIS_PVC_SIZE} ${REDIS_PVC_UNIT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
        
        kubectl apply -f packages/judge0/db.yaml
        kubectl apply -f packages/judge0/redis.yaml
        kubectl apply -f packages/judge0/server.yaml
        kubectl apply -f packages/judge0/worker.yaml
        applyIngressNginxHTTP ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
    ;;
    u | uninstall | teardown)
        deleteSequence service ${DOCKERNAME}-server-svc
        deleteSequence deployment ${DOCKERNAME}-server
        deleteSequence ingress ${INGRESS_SERVICE}
        deleteSequence service ${DOCKERNAME}-worker-svc
        deleteSequence deployment ${DOCKERNAME}-worker
        deleteSequence service ${DOCKERNAME}-db-svc
        deleteSequence statefulset ${DOCKERNAME}-db
        deleteSequence service ${DOCKERNAME}-db-redis
        deleteSequence statefulset ${DOCKERNAME}-redis
        deleteSequence configmap ${DOCKERNAME}-db-config
        deleteSequence configmap ${DOCKERNAME}-redis-config
        deleteSequence configmap ${DOCKERNAME}-conf
        deleteSequence pvc ${DOCKERNAME}-db-data
        deleteSequence pvc ${DOCKERNAME}-redis-data
    ;;
    ingress)
        applyIngressNginxHTTP ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
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
        logHelpHead "packages/judge0/helm.sh"
        logHelpContent i install "install judge0 package"
        logHelpContent u uninstall "uninstall judge0 package"
        logHelpTail
    ;;
esac