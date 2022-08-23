#!/bin/bash
# 쿠버네티스 API 치트코드입니다.
# 리소스 관련 스크립트 등이 포함되어 있습니다.

# Author: PresentJay (정현재, presentj94@gmail.com)

source scripts/common.sh



############
# *ingress #
############

# # # CREATE (apply can create and update) # # #

applyIngressNginxHTTPS() {
    # Validate
    checkParamOrLog $1 "need param 1: hostName (ex. dashboard.kubernetes)"
    checkParamOrLog $2 "need param 2: serviceName (ex. kubernetes-dashboard)"
    checkParamOrLog $3 "need param 3: httpsPort (ex. 443)"
    checkParamOrLog $4 "need param 4: package name"

    # Check On Eyes Phase
    _hostName_=$1
    _serviceName_=$2
    _httpsPort_=$3
    _packageName_=$4
    _namespace_=$(checkNamespaceOption $5)

    # Do
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${_serviceName_}
  namespace: ${_namespace_}
  labels:
    package: ${_packageName_}
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/proxy-body-size: 1000000m
spec:
  tls:
    - hosts:
        - ${_hostName_}.${LOCAL_ADDRESS}.nip.io
  rules:
    - host: ${_hostName_}.${LOCAL_ADDRESS}.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${_serviceName_}
                port:
                  number: ${_httpsPort_}
EOF
}

applyIngressNginxHTTP() {
    # Validate
    checkParamOrLog $1 "need param 1: hostName (ex. dashboard.kubernetes)"
    checkParamOrLog $2 "need param 2: serviceName (ex. kubernetes-dashboard)"
    checkParamOrLog $3 "need param 3: httpPort (ex. 80)"
    checkParamOrLog $4 "need param 4: package name"

    # Check On Eyes Phase
    _hostName_=$1
    _serviceName_=$2
    _httpPort_=$3
    _packageName_=$4
    _namespace_=$(checkNamespaceOption $5)

    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${_serviceName_}
  namespace: ${_namespace_}
  labels:
    package: ${_packageName_}
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: 1000000m
spec:
  rules:
    - host: ${_hostName_}.${LOCAL_ADDRESS}.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${_serviceName_}
                port:
                  number: ${_httpPort_}
EOF
}

# # # GET # # #

# $1: ingress name
# $2: namespace (optional)
getIngressURL() {
    # Validate Phase
    checkParamOrLog $1 "need param 1: ingress name"
    
    # Check On Eyes Phase
    _ingressName_=$1
    _namespace_=$(checkNamespaceOption $2)

    # Do
    find=$(kubectl get ingress ${_ingressName_} -n ${_namespace_} | grep ${_ingressName_} | awk '{print $3}')

    if [[ -n ${find} ]]; then
        echo ${find}
    else
        return $FALSE
        logInfo "can't found ingress of ${_ingressName_}"
    fi
}

# TODO: ingress-nginx에 대해서만 로직 구현. traefik 등과 통합해서 쓰일 수 있도록 코드 확장 필요
# $1: http / https
# $2: ingress-controller service name
# $3: ingress-controller namespace (optional)
getIngressPort() {
    # Validate
    checkParamOrLog $1 "need param 1: \"http\" or \"https\""
    ! checkParamIsInList $1 ("http" "https") &&
        logKill "param 1 should be  \"http\" or \"https\""    
    checkParamOrLog $2 "need param 2: ingress-controller service name"

    # Check On Eyes Phase
    _protocol_=$1
    _serviceName_=$2
    _namespace_=$(checkNamespaceOption $3)
    case $1 in
        http) _index_=0 ;;
        https) _index_=1 ;;
    esac

    # Do
    case ${INGRESS} in
        ingress-nginx)
            find=$(kubectl get svc ${_serviceName_} -n ${_namespace_} -o jsonpath="{.spec.ports[${_index_}].nodePort}")
        ;;
        ? | *)
            logKill "supported ingress controller: \"ingress-nginx\""
        ;;
    esac

    if [[ -n ${find} ]]; then
        echo ${find}
    else
        hide=$(logInfo "can't found $1 port in your kubernetes environment. please check your ingress-controller")
        return $FALSE
    fi
}


############
# *service #
############

# # # CREATE (apply can create and update) # # #

# $1: svc name
# $2: port index
# $3: package name
# $4: namespace (optional)
applyService() {
    # Validate
    checkParamOrLog $1 "need param 1: svc name"
    checkParamOrLog $2 "need param 2: port index"
    checkParamOrLog $3 "need param 3: package name"

    # Check On Eyes Phase
    _nameAndAppName_=$1
    _targetPort_=$2
    _packageName_=$3
    _namespace_=$(checkNamespaceOption $4)

    # Do
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${_nameAndAppName_}
  namespace: ${_namespace_}
  labels:
    package: ${_packageName_}
spec:
  ports:
  - port: ${_targetPort_}
    targetPort: ${_targetPort_}
  selector:
    app: ${_nameAndAppName_}
EOF
}

# $1: svc name
# $2: http port index
# $3: https port index
# $4: package name
# $5: namespace (optional)
applyServiceFull() {
    # Validate
    checkParamOrLog $1 "need param 1: svc name"
    checkParamOrLog $2 "need param 2: http port index"
    checkParamOrLog $3 "need param 3: https port index"
    checkParamOrLog $4 "need param 4: package name"

    # Check On Eyes Phase
    _nameAndAppName_=$1
    _httpPort_=$2
    _httpsPort_=$3
    _packageName_=$4
    _namespace_=$(checkNamespaceOption $5)

    # Do
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
    name: ${_nameAndAppName_}
    namespace: ${_namespace_}
    labels:
        package: ${_packageName_}
spec:
    ports:
    - name: http
        port: ${_httpPort_}
        targetPort: ${_httpPort_}
    - name: https
        port: ${_httpsPort_}
        targetPort: ${_httpsPort_}

  selector:
    app: ${_nameAndAppName_}
EOF
}



# # # GET # # #

# $1: svc name
# $2: port index
# #3: namespace name (optional)
getSvcNodePort() {
    # Validate
    checkParamOrLog $1 "need param 1: service name"
    checkParamOrLog $2 "need param 2: port index"

    # Check On Eyes Phase
    _serviceName_=$1
    _portIndex_=$2
    _namespace_=$(checkNamespaceOption $3)

    # Do
    find=$(kubectl get svc $_serviceName_ -n ${_namespace_} -o jsonpath="{.spec.ports[$2].nodePort}")

    if [[ -n ${find} ]]; then
        echo ${find}
    else
        return $FALSE
    fi
}

# $1: svc name
# $2: port index
# #3: namespace name (optional)
get_svc_port() {
    # Validate
    checkParamOrLog $1 "need param 1: service name"
    checkParamOrLog $2 "need param 2: port index"

    # Check On Eyes Phase
    _serviceName_=$1
    _portIndex_=$2
    _namespace_=$(checkNamespaceOption $3)

    # Do
    find=$(kubectl get svc $_serviceName_ -n ${_namespace_} -o jsonpath="{.spec.ports[$_portIndex_].port}")
    if [[ -n ${find} ]]; then
        echo ${find}
    else
        return $FALSE
    fi
}

########
# *pvc #
########

# # # CREATE (apply can create and update) # # #

# $1: pvc name
# $2: storageclass name
# $3: pvc amount
# $4: pvc units (Gi, Mi)
applyPVC() {
    # Validate
    checkParamOrLog $1 "need param 1: pvc name"
    checkParamOrLog $2 "need param 2: storageclass name"
    checkParamOrLog $3 "need param 3: pvc amount"
    checkParamOrLog $4 "need param 4: pvc unit (Gi, Mi)"
    ! checkParamIsInList $4 ("Gi" "Mi") && \
        logKill "param 4: pvc unit should be \"Gi\" or \"Mi\""
    checkParamOrLog $5 "need param 5: package name"
    

    # Check On Eyes Phase
    _PVCname_=$1
    _storageClassName_=$2
    _PVCamount_=$3
    _PVCunit_=$4
    _packageName_=$5

    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${_PVCname_}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ${_storageClassName_}
  resources:
    requests:
      storage: ${_PVCamount_}${_PVCunit_}
EOF
}
