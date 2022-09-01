
# prerequisite
- multipass
- kubectl, helm

# QuickStart

1. multipass (VMware cluster) 설치
   - `bash scripts/multipass.sh -i`
     - teardown: `bash scripts/multipass.sh -u`
     - vm 임시 종료 시: `bash scripts/multipass.sh -p`
     - vm 재시작 시: `bash scripts/multipass.sh -r`
2. lightweight-kubernetes (k3s) 설치
   - `bash scripts/k3s.sh -i`
     - teardown: `TBD (지금은 k3s 내리는 것보다, multipass에서 teardown이 더 확실하고 빠름)`
3. ingress-nginx package 설치
   - `bash packages/ingress-nginx/helm.sh -i`
     - teardown: `bash packages/ingress-nginx/helm.sh -u`
4. kubernetes dashboard package 설치
   - `bash packages/kubernetes-dashboard/helm.sh -i`
     - teardown: `bash packages/kubernetes-dashboard/helm.sh -u`
     - open dashboard: `bash packages/kubernetes-dashboard/helm.sh --open`
     - get login token: `bash packages/kubernetes-dashboard/helm.sh --token`

# Tips

1. 쉘 스크립트의 실행시간/리소스사용결과 확인: `time bash {shellscripts}`
   - ex1. `time bash scripts/multipass.sh -i`
   - result-ex1) `bash scripts/multipass.sh -i  12.10s user 34.59s system 30% cpu 2:31.43 total`