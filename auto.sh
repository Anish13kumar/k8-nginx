
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

echo "📁 Creating containerd configuration directory..."
sudo mkdir -p /etc/containerd

echo "⚙️  Generating default containerd configuration..."
containerd config default | sudo tee /etc/containerd/config.toml

echo "🛠️  Enabling systemd cgroup driver in containerd config..."
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

echo "🔁 Restarting containerd service..."
sudo systemctl restart containerd

echo "🚀 Initializing Kubernetes control plane..."
sudo kubeadm init --control-plane-endpoint=10.5.0.8 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.5.0.8

echo "📁 Setting up kubeconfig for user 'ubuntu'..."
sudo -u ubuntu mkdir -p /home/ubuntu/.kube
sudo cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /etc/kubernetes/admin.conf
sudo chmod 644 /etc/kubernetes/admin.conf

echo "🌐 Deploying Flannel CNI network plugin..."
sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

echo "🌐 (Optional) Deploying Calico CNI network plugin..."
sudo -u ubuntu kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo "🔐 Generating join command and saving to token.txt..."
kubeadm token create --print-join-command > /home/ubuntu/k8-nginx/token.txt
sudo chown ubuntu:ubuntu /home/ubuntu/k8-nginx/token.txt

echo "📦 Deploying MetalLB in native mode..."
sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml

echo "❌ Removing MetalLB webhook validation to avoid issues..."
sudo -u ubuntu kubectl delete validatingwebhookconfigurations metallb-webhook-configuration

echo "⚙️  Applying MetalLB address pool configuration..."
sudo -u ubuntu kubectl apply -f /home/ubuntu/k8-nginx/metallb-config.yaml

echo "🧩 Enabling kubectl bash completion for user 'ubuntu'..."
sudo apt-get install bash-completion -y
sudo -u ubuntu bash -c 'echo "source <(kubectl completion bash)" >> ~/.bashrc'
sudo -u ubuntu bash -c 'echo "alias k=kubectl" >> ~/.bashrc'
sudo -u ubuntu bash -c 'echo "complete -o default -F __start_kubectl k" >> ~/.bashrc'

echo "📦 Installing Helm..."
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | \
    sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm -y
