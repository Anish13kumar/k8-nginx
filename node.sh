#!/bin/bash

set -e  # Exit on error

echo "📁 Creating directory for APT keyrings..."
sudo mkdir -p /etc/apt/keyrings

echo "🔑 Downloading Kubernetes APT key and saving it as a GPG keyring..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

echo "📦 Adding Kubernetes APT repository to sources.list..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

echo "🔄 Updating APT package index..."
sudo apt-get update

echo "📥 Installing kubelet, kubeadm, and kubectl..."
sudo apt-get install -y kubelet kubeadm kubectl

echo "🧩 Loading kernel modules for Kubernetes networking..."
sudo modprobe overlay
sudo modprobe br_netfilter
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sudo sh /tmp/get-docker.sh
echo "📁 Creating containerd configuration directory..."
sudo mkdir -p /etc/containerd

echo "⚙️  Generating default containerd configuration..."
containerd config default | sudo tee /etc/containerd/config.toml

echo "🛠️  Enabling systemd cgroup driver in containerd config..."
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

echo "🔁 Restarting containerd service..."
sudo systemctl restart containerd