#!/bin/bash

# Install Istio

Install_Istio() {
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.15.0 sh -
    cd istio-1.15.0
    export PATH=$PWD/bin:$PATH
    istioctl install --set profile=demo -y
}

Deploy_Bookinfo() {
    kubectl label namespace default istio-injection=enabled
    kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
    kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
}

Deploy_Obs() {
    kubectl apply -f samples/addons
    kubectl rollout status deployment/kiali -n istio-system
}

main() {
    Install_Istio
    Deploy_Bookinfo
    Deploy_Obs
}

main