#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/pgadmin4/.env

case $(checkOpt iu $@) in
    i | install)
        applyConfigmap ${DOCKERNAME}-config default \
            "PGADMIN_DEFAULT_EMAIL=${PGADMIN_DEFAULT_EMAIL}" \
            "PGADMIN_DEFAULT_PASSWORD=${PGADMIN_DEFAULT_PASSWORD}"
        
        applyPVC ${DOCKERNAME}-data ${STORAGE} ${PVC_SIZE} ${PVC_UNIT} ${PACKAGE_LABEL}
        kubectl apply -f packages/pgadmin4/pgadmin4.yaml
        applyIngressNginxHTTP ${INGRESS_HOSTNAME} ${INGRESS_SERVICE} ${INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
    ;;
    u | uninstall | teardown)
        deleteSequence service ${DOCKERNAME}-svc
        deleteSequence deployment ${DOCKERNAME}
        deleteSequence ingress ${INGRESS_SERVICE}
        deleteSequence pvc ${DOCKERNAME}-data
    ;;
    open)
        if checkParamIsInList ${INGRESS_PROTOCOL} http https; then
            _HOSTURL_="${INGRESS_HOSTNAME}.${masterNodeIP}.nip.io"
            _PORT_=$(bash packages/ingress-nginx/helm.sh --${INGRESS_PROTOCOL}Port)
            _OPENURI_="${INGRESS_PROTOCOL}://${_HOSTURL_}:${_PORT_}"
            openURI ${_OPENURI_}
            echo "initialized admin: ${PGADMIN_DEFAULT_EMAIL}"
            echo "initialized password: ${PGADMIN_DEFAULT_PASSWORD}"
        else
            logKill "please set INGRESS_PROTOCOL to http or https only. (in .env)"
        fi
    ;;
    h | help | ? | *)
        logHelpHead "packages/pgadmin4/helm.sh"
        logHelpContent i install "install pgadmin4 package"
        logHelpContent u uninstall "uninstall pgadmin4 package"
        logHelpTail
    ;;
esac