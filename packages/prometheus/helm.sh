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
            --namespace ${INSTALL_NAMESPACE} \
            --install \
            --no-hooks \
            --version ${INSTALL_VERSION} \
            --set prometheus-node-exporter.hostRootFsMount.enabled=false \
            --set grafana.adminPassword=${GRAFANA_ADMIN_PASSWORD} \
            --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=${STORAGE} \
            --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce \
            --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=${PROMETHEUS_PVC_SIZE}
            # https://github.com/prometheus-community/helm-charts/issues/467
            # container 환경에서 rootFS mount를 방지하게 하기 위한 설정 추가: prometheus-node-exporter.hostRootFsMount.enabled=false
        applyIngressNginxHTTP ${PROMETHEUS_INGRESS_HOSTNAME} ${PROMETHEUS_INGRESS_SERVICE} ${PROMETHEUS_INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
        applyIngressNginxHTTP ${GRAFANA_INGRESS_HOSTNAME} ${GRAFANA_INGRESS_SERVICE} ${GRAFANA_INGRESS_PORT} ${PACKAGE_LABEL} ${INSTALL_NAMESPACE}
    ;;
    u | uninstall | teardown)
        deleteSequence ingress ${PROMETHEUS_INGRESS_SERVICE} ${INSTALL_NAMESPACE}
        deleteSequence ingress ${GRAFANA_INGRESS_SERVICE} ${INSTALL_NAMESPACE}
        deleteSequence helm ${INSTALL_NAME} ${INSTALL_NAMESPACE}
        deleteSequence helm-repo ${CHART_REPOSITORY_NAME}
        deleteSequence namespace ${INSTALL_NAMESPACE}
    ;;
    open-prometheus | prometheus | prom | open-prom)
        if checkParamIsInList ${PROMETHEUS_INGRESS_PROTOCOL} http https; then
            _HOSTURL_="${PROMETHEUS_INGRESS_HOSTNAME}.${masterNodeIP}.nip.io"
            _PORT_=$(bash packages/ingress-nginx/helm.sh --${PROMETHEUS_INGRESS_PROTOCOL}Port)
            _OPENURI_="${PROMETHEUS_INGRESS_PROTOCOL}://${_HOSTURL_}:${_PORT_}"
            openURI ${_OPENURI_}
        else
            logKill "please set PROMETHEUS_INGRESS_PROTOCOL to http or https only. (in .env)"
        fi
    ;;
    open-grafana | grafana)
        if checkParamIsInList ${GRAFANA_INGRESS_PROTOCOL} http https; then
            _HOSTURL_="${GRAFANA_INGRESS_HOSTNAME}.${masterNodeIP}.nip.io"
            _PORT_=$(bash packages/ingress-nginx/helm.sh --${GRAFANA_INGRESS_PROTOCOL}Port)
            _OPENURI_="${GRAFANA_INGRESS_PROTOCOL}://${_HOSTURL_}:${_PORT_}"
            openURI ${_OPENURI_}
        else
            logKill "please set PROMETHEUS_INGRESS_PROTOCOL to http or https only. (in .env)"
        fi
    ;;
    h | help | ? | *)
        logHelpHead "packages/prometheus/helm.sh"
        logHelpContent i install "install prometheus package"
        logHelpContent u uninstall "uninstall prometheus package"
        logHelpTail
    ;;
esac