#!/bin/bash

# Author: PresentJay (정현재, presentj94@gmail.com)

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