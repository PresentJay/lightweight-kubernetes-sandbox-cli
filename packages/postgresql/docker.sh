#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

source ./scripts/kubecheats.sh
getEnv ./packages/postgresql/.env

case $(checkOpt iu $@) in
    i | install)
        applyConfigmap ${DOCKERNAME}-config default \
            "POSTGRES_DB=${POSTGRES_DB}" \
            "POSTGRES_USER=${POSTGRES_USER}" \
            "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
        
        applyPVC ${DOCKERNAME}-data ${STORAGE} ${PVC_SIZE} ${PVC_UNIT} ${PACKAGE_LABEL}
        kubectl apply -f packages/postgresql/postgresql.yaml
    ;;
    u | uninstall | teardown)
        deleteSequence service ${DOCKERNAME}-svc
        deleteSequence statefulset ${DOCKERNAME}
        deleteSequence pvc ${DOCKERNAME}-data
    ;;
    h | help | ? | *)
        logHelpHead "packages/postgresql/helm.sh"
        logHelpContent i install "install postgresql package"
        logHelpContent u uninstall "uninstall postgresql package"
        logHelpTail
    ;;
esac