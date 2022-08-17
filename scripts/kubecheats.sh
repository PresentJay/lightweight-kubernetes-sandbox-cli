#!/bin/bash
# 쿠버네티스 API 치트코드입니다.
# 리소스 관련 스크립트 등이 포함되어 있습니다.

# Author: PresentJay (정현재, presentj94@gmail.com)

############ Cheats  ############ 
get_ingress_url() {
    if [[ $# -gt 1 ]]; then
        find=$(kubectl get ingress $1 -n $2 | grep $1 | awk '{print $3}')
    else
        find=$(kubectl get ingress $1 | grep $1 | awk '{print $3}')
    fi

    if [[ -n ${find} ]]; then
        echo ${find}
    else
        return $FALSE
        logInfo "can't found ingress of $1"
    fi
}

# $1: http / https
get_ingress_port() {
    if [[ $1="http" ]];
        then index=0
    elif [[ $1="https" ]]; then
        index=1
    else
        logKill "second parameter should be 'http' or 'https'"
    fi
    case ${INGRESS} in
        ingress-nginx)
            find=$(kubectl get svc ${INGRESS}-controller -n ${INGRESS} -o jsonpath="{.spec.ports[${index}].nodePort}")
        ;;
    esac
    if [[ -n ${find} ]]; then
        echo ${find}
    else
        hide=$(logInfo "can't found $1 port in your kubernetes environment. please check your ingress-controller")
        return $FALSE
    fi
}

# $1: svc name
# $2: port index
# #3: namespace name (optional)
get_svc_nodeport() {
    if [[ $# -eq 3 ]]; then
        find=$(kubectl get svc $1 -n $3 -o jsonpath="{.spec.ports[$2].nodePort}")
    else
        find=$(kubectl get svc $1 -o jsonpath="{.spec.ports[$2].nodePort}")
    fi
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
    if [[ $# -eq 3 ]]; then
        find=$(kubectl get svc $1 -n $3 -o jsonpath="{.spec.ports[$2].port}")
    else
        find=$(kubectl get svc $1 -o jsonpath="{.spec.ports[$2].port}")
    fi
    if [[ -n ${find} ]]; then
        echo ${find}
    else
        return $FALSE
    fi
}



############ Resource Managements ############ 

# $1: pvc name
# $2: storageclass name
# $3: pvc amount (GB unit)
createPVC() {
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $1
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: $2
  resources:
    requests:
      storage: $3Gi
EOF
}


createService() {
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: $1
spec:
  ports:
  - port: 80
    targetPort: $2
    
  selector:
    app: $1
EOF
}


createIngressHTTPS() {
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $1
  namespace: $_NS_
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
spec:
  tls:
    - hosts:
        - ${HOSTNAME}.${LOCAL_ADDRESS}.nip.io
  rules:
    - host: ${HOSTNAME}.${LOCAL_ADDRESS}.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${SERVICENAME}
                port:
                  number: ${HTTPSPORT}
}