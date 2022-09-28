bash scripts/multipass.sh --install
bash scripts/k3s.sh --install
bash packages/ingress-nginx/helm.sh --install
sleep 10
bash packages/longhorn/helm.sh --install
sleep 20
bash packages/kubernetes-dashboard/helm.sh --install