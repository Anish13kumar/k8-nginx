
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
# 🛜 Get wg0 IP address
echo "🌐 Detecting wg0 interface IP address..."
WG0_IP=$(ip -4 addr show wg0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if [ -z "$WG0_IP" ]; then
  echo "❌ Error: Could not find IP address for wg0 interface."
  exit 1
fi

echo "✅ Found wg0 IP address: $WG0_IP"

# ✏️ Set KUBELET_EXTRA_ARGS
echo "⚙️ Setting KUBELET_EXTRA_ARGS in /etc/default/kubelet..."
echo "KUBELET_EXTRA_ARGS=--node-ip=$WG0_IP" | sudo tee /etc/default/kubelet > /dev/null

echo "🔁 Reloading systemd and restarting kubelet..."

sudo systemctl daemon-reload
sudo systemctl restart kubelet

echo "🚀 Initializing Kubernetes control plane..."

sudo kubeadm init --control-plane-endpoint=10.5.0.185 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.5.0.185

echo "📁 Setting up kubeconfig for user 'node1'..."
sudo -u node1 mkdir -p /home/node1/.kube
sudo cp /etc/kubernetes/admin.conf /home/node1/.kube/config
sudo chown node1:node1 /home/node1/.kube/config
sudo chown node1:node1 /etc/kubernetes/admin.conf
sudo chmod 644 /etc/kubernetes/admin.conf

echo "🌐 Deploying Flannel CNI network plugin..."
sudo -u node1 kubectl apply -f  https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo "🌐 (Optional) Deploying Calico CNI network plugin..."
sudo -u node1 kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "🔐 Generating join command and saving to token.txt..."
kubeadm token create --print-join-command > /home/node1/k8-nginx/token.txt
sudo chown node1:node1 /home/node1/k8-nginx/token.txt

echo "📦 Deploying MetalLB in native mode..."
sudo -u node1 kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml

echo "❌ Removing MetalLB webhook validation to avoid issues..."
sudo -u node1 kubectl delete validatingwebhookconfigurations metallb-webhook-configuration

echo "⚙️  Applying MetalLB address pool configuration..."
sudo -u node1 kubectl apply -f metallb-config.yaml

echo "🧩 Enabling kubectl bash completion for user 'node1'..."
sudo apt-get install bash-completion -y
sudo -u node1 bash -c 'echo "source <(kubectl completion bash)" >> ~/.bashrc'
sudo -u node1 bash -c 'echo "alias k=kubectl" >> ~/.bashrc'
sudo -u node1 bash -c 'echo "complete -o default -F __start_kubectl k" >> ~/.bashrc'

echo "📦 Installing Helm..."
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | \
    sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm -y
