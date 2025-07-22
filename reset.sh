#!/bin/bash

echo "🔄 Resetting Kubernetes cluster..."
sudo kubeadm reset -f

echo "🛑 Stopping kubelet service..."
sudo systemctl stop kubelet
sudo systemctl disable kubelet

echo "🧹 Removing Kubernetes directories..."
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/etcd
sudo rm -rf /var/lib/kubelet
sudo rm -rf /var/lib/cni/
sudo rm -rf /etc/cni/
sudo rm -rf /opt/cni/
sudo rm -rf $HOME/.kube

echo "🔥 Flushing iptables..."
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X

echo "🧯 Removing CNI interfaces if exist..."
sudo ip link delete cni0 2>/dev/null
sudo ip link delete flannel.1 2>/dev/null

echo "📦 Removing all Docker/Containerd containers and images (if present)..."
if command -v crictl &> /dev/null; then
    sudo crictl rmp -fa
    sudo crictl rmi -a
fi

if command -v docker &> /dev/null; then
    sudo docker rm -f $(docker ps -aq) 2>/dev/null
    sudo docker rmi -f $(docker images -q) 2>/dev/null
fi

echo "❌ Uninstalling Kubernetes packages..."
sudo apt-get purge -y kubeadm kubectl kubelet kubernetes-cni kube*
sudo apt-get autoremove -y

echo "✅ Kubernetes has been removed. Consider rebooting your system."
