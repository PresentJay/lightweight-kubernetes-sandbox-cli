#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/NOJ/.env

case $(checkOpt iu $@) in
    init)
        applyPVC git-vol ${STORAGE} ${GIT_PVC_SIZE} ${GIT_PVC_UNIT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
        kubectl apply -f packages/NOJ/cloner.yaml
    ;;
    clean-job)
        deleteSequence job git-cloner
    ;;
    i | install)
        applyConfigmap ${DOCKERNAME}-db-config ${INSTALL_NAMESPACE} \
            "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" \
            "MYSQL_USER=${MYSQL_USER}" \
            "MYSQL_DATABASE=${MYSQL_DATABASE}" \
            "MYSQL_PASSWORD=${MYSQL_PASSWORD}" \
            "MYSQL_AUTHENTICATION_PLUGIN=mysql_native_password"
            
        applyConfigmap ${DOCKERNAME}-redis-config ${INSTALL_NAMESPACE} \
            "REDIS_PASSWORD=${REDIS_PASSWORD}" \
            "REDIS_DISABLE_COMMANDS=FLUSHDB,FLUSHALL"

        applyConfigmap ${DOCKERNAME}-noj-config ${INSTALL_NAMESPACE} \
            "DB_HOST=${DB_HOST}" \
            "DB_USERNAME=${MYSQL_USER}" \
            "DB_DATABASE=${MYSQL_DATABASE}" \
            "DB_PASSWORD=${MYSQL_PASSWORD}" \
            "CACHE_DRIVER=redis" \
            "REDIS_HOST=${REDIS_HOST}" \
            "REDIS_PASSWORD=${REDIS_PASSWORD}" \
            "LOG_CHANNEL=stderr"
        
        applyPVC ${DOCKERNAME}-db-data ${STORAGE} ${DB_PVC_SIZE} ${DB_PVC_UNIT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
        applyPVC ${DOCKERNAME}-redis-data ${STORAGE} ${REDIS_PVC_SIZE} ${REDIS_PVC_UNIT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
        
        kubectl apply -f packages/NOJ/db.yaml
        kubectl apply -f packages/NOJ/redis.yaml
        
        kubectl apply -f packages/NOJ/noj.yaml

    ;;
    u | uninstall | teardown)
        deleteSequence service ${DOCKERNAME}-judge-server-svc
        deleteSequence deployment ${DOCKERNAME}-judge-server
        deleteSequence service ${DOCKERNAME}-noj-svc
        deleteSequence deployment ${DOCKERNAME}-noj
        deleteSequence service ${DOCKERNAME}-noj-svc
        deleteSequence deployment ${DOCKERNAME}-noj
        deleteSequence service ${DOCKERNAME}-db-svc
        deleteSequence statefulset ${DOCKERNAME}-db
        deleteSequence service ${DOCKERNAME}-db-redis
        deleteSequence statefulset ${DOCKERNAME}-redis
        deleteSequence configmap ${DOCKERNAME}-db-config
        deleteSequence configmap ${DOCKERNAME}-redis-config
        deleteSequence configmap ${DOCKERNAME}-noj-config
        deleteSequence configmap ${DOCKERNAME}-judge-server-config
        deleteSequence pvc ${DOCKERNAME}-db-data
        deleteSequence pvc ${DOCKERNAME}-redis-data
        deleteSequence pvc git-vol
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
        logHelpHead "packages/NOJ/helm.sh"
        logHelpContent i install "install NOJ package"
        logHelpContent u uninstall "uninstall NOJ package"
        logHelpTail
    ;;
esac