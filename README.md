
# prerequisite
- multipass
- kubectl, helm

# QuickStart

[진또배기 퀵스타트](https://velog.io/@ryuni/Multipass%EB%A5%BC-%ED%99%9C%EC%9A%A9%ED%95%9C-kubernetes-%ED%81%B4%EB%9F%AC%EC%8A%A4%ED%84%B0-%EA%B5%AC%EC%B6%95-%EB%B0%A9%EB%B2%95) 

**NEW QUICKSTART**
-> `./boot.sh`

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
5. longhorn package 설치
   - `bash packages/longhorn/helm.sh -i`
     - teardown: `bash packages/longhorn/helm.sh -u`
     - open dashboard: `bash packages/longhorn/helm.sh --open`
6. prometheus+grafana package 설치
   - `bash packages/prometheus/helm.sh -i`
     - teardown: `bash packages/prometheus/helm.sh -u`
     - open dashboard(prometheus): `bash packages/prometheus/helm.sh --open prom`
     - open dashboard(grafana): `bash packages/prometheus/helm.sh --open grafana`


# Tips

1. 쉘 스크립트의 실행시간/리소스사용결과 확인: `time bash {shellscripts}`
   - ex1. `time bash scripts/multipass.sh -i`
   - result-ex1) `bash scripts/multipass.sh -i  12.10s user 34.59s system 30% cpu 2:31.43 total`


# TODO
- [ ] Istio 적용: https://m.blog.naver.com/freepsw/221919196101 
  - [ ] 참고1: https://itnext.io/traffic-management-using-istio-b49663da3e8d
  - [ ] 참고2 (공식doc): https://istio.io/latest/docs/
  - [ ] 참고3: https://www.redhat.com/en/topics/microservices/what-is-a-service-mesh
  - [ ] 
- [ ] 예거 트레이싱 적용: https://github.com/jaegertracing/jaeger
- [x] prometheus+grafana 적용
- [ ] Kubernetes Resource를 이해하기 위한 좋은 포스팅
  - [ ] https://shonlevran.medium.com/kubernetes-resources-under-the-hood-part-1-4f2400b6bb96
  - [ ] https://shonlevran.medium.com/kubernetes-resources-under-the-hood-part-2-6eeb50197c44
  - [ ] https://shonlevran.medium.com/kubernetes-resources-under-the-hood-part-3-6ee7d6015965
