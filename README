# Kubernetes Installation Guide

## Setup Kubernetes

```sh
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

sudo apt-get install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl

sudo modprobe overlay

sudo modprobe br_netfilter
```

## Completion of Kubernetes Installation

## Configure Docker for Kubernetes

```sh
sudo mkdir -p /etc/containerd

containerd config default | sudo tee /etc/containerd/config.toml

sudo nano /etc/containerd/config.toml
```

Find this line:
```sh
SystemdCgroup = false
```
and change it to:
```sh
SystemdCgroup = true
```

Restart containerd:
```sh
sudo systemctl restart containerd

sudo systemctl status containerd
```

## Completion of Docker Configuration for Kubernetes

## Initialize kubeadm

```sh
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube

sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

sudo chown $(id -u):$(id -g) /etc/kubernetes/admin.conf

sudo chmod 644 /etc/kubernetes/admin.conf
```

Apply network plugins:
```sh
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

Generate join token for nodes:
```sh
kubeadm token create --print-join-command

kubectl get nodes
```

## Finish Connecting Multiple Servers in kubeadm

## Configure MetalLB to Expose Services on Public IP

```sh
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml

kubectl delete validatingwebhookconfigurations metallb-webhook-configuration

kubectl apply -f metallb-config.yaml
```

## Done Configuring MetalLB for Public Service Exposure

## Set Auto Completion for kubectl

```sh
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

echo 'alias k=kubectl' >>~/.bashrc

echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
```

## Done

## Expose Nginx in Kubernetes

```sh
kubectl apply -f nginx-deployment.yaml 

kubectl apply -f nginx-service.yaml 
```

## End of Nginx Deployment Exposure

## Install Helm

```sh
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## End of Helm Installation