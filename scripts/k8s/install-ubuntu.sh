cat << EOF >> /etc/hosts
10.0.16.2 master01
10.0.16.2 lb.alongparty.cn
EOF

Init_Node() {

  # 关闭Swap
  swapoff -a
  sed -i '/swap/s/^/#/' /etc/fstab

  systemctl disable --now swap.img.swap
  systemctl mask swap.target


  # 配置时间同步
  apt-get -y install chrony
  chronyc sources -v

  # 设置成东八区时区
  timedatectl set-timezone Asia/Shanghai


  # 禁用默认配置的iptables防火墙服务
  ufw disable
  ufw status


  # 加载模块
  cat > /etc/modules-load.d/k8s.conf <<EOF
  overlay
  br_netfilter
EOF

  # 手动加载模块
  modprobe overlay && modprobe br_netfilter

  # 设置所需的sysctl参数，参数在重新启动后保持不变
  cat > /etc/sysctl.d/k8s.conf  <<EOF
  net.bridge.bridge-nf-call-iptables  = 1
  net.bridge.bridge-nf-call-ip6tables = 1
  net.ipv4.ip_forward                 = 1
EOF

  # 应用 sysctl 参数而不重新启动
  sysctl --system


  # 安装ipset和ipvsadm：
  apt install -y ipset ipvsadm

  # 配置加载模块
  cat > /etc/modules-load.d/ipvs.conf << EOF
  modprobe -- ip_vs
  modprobe -- ip_vs_rr
  modprobe -- ip_vs_wrr
  modprobe -- ip_vs_sh
  modprobe -- nf_conntrack
EOF


  # 临时加载
  modprobe -- ip_vs
  modprobe -- ip_vs_rr
  modprobe -- ip_vs_wrr
  modprobe -- ip_vs_sh

  # 开机加载配置，将ipvs相关模块加入配置文件中
  cat >> /etc/modules <<EOF
  ip_vs_sh
  ip_vs_wrr
  ip_vs_rr
  ip_vs
  nf_conntrack
EOF
}




Install_Container() {
  # 1. 更新本地ca证书
  sudo apt-get update
  sudo apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg \
     lsb-release \
     software-properties-common

  # 2. 设置阿里云镜像源
  curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -
  add-apt-repository -y "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
  cat /etc/apt/sources.list.d/archive_uri-https_mirrors_aliyun_com_docker-ce_linux_ubuntu-jammy.list

  # 3. 更新软件
  sudo apt update -y

  # 4. 安装Docker
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  # 5. 配置docker
  mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    },
    "registry-mirrors": [
        "https://ec8tbfzf.mirror.aliyuncs.com"
    ],
    "data-root": "/data/docker"
}
EOF

  # 6. 启动docker
  sudo systemctl enable docker
  sudo systemctl start docker

  # 7. 配置containerd
  # 生成containerd默认配置文件
  cp /etc/containerd/config.toml /etc/containerd/config.toml.bak
  containerd config default | tee /etc/containerd/config.toml
  
  # sandbox_image镜像源设置为阿里云google_containers镜像源
  sed -i "s#k8s.gcr.io/pause:3.6#registry.aliyuncs.com/google_containers/pause:3.8#g"  /etc/containerd/config.toml

  # 修改Systemdcgroup
  sed -i 's#SystemdCgroup = false#SystemdCgroup = true#g' /etc/containerd/config.toml

  # 添加 endpoint加速器
  sed -i '/registry.mirrors]/a\ \ \ \ \ \ \ \ [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]' /etc/containerd/config.toml
  sed -i '/registry.mirrors."docker.io"]/a\ \ \ \ \ \ \ \ \ \ endpoint = ["https://ul2pzi84.mirror.aliyuncs.com"]' /etc/containerd/config.toml

  # 8. 重新加载并重启containerd
  systemctl daemon-reload && systemctl restart containerd
  systemctl status containerd
  
  # 9. 安装docker-compose
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose

}


Install_Kubeadm() {
  # 配置阿里云镜像站点
  curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
  cat >/etc/apt/sources.list.d/kubernetes.list <<EOF
  deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
  EOF

  apt-get update

  # 查看版本
  apt-cache madison kubeadm|head

  # 安装指定版本
  apt-get install kubernetes-cni=1.2.0-00 kubelet=1.26.1-00 kubectl=1.26.1-00  cri-tools=1.26.0-00 kubeadm=1.26.1-00  -y

  # 设置crictl
  cat > /etc/crictl.yaml << EOF
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10 
debug: false
EOF



}

Init_Master() {

  # 使用国内阿里云镜像站点，查看所需镜像
  kubeadm config images list \
  --image-repository registry.aliyuncs.com/google_containers \
  --kubernetes-version=v1.26.1

  # 指定版本下载
  kubeadm config images pull \
  --kubernetes-version=v1.26.1 \
  --image-repository registry.aliyuncs.com/google_containers

  # 查看镜像
  crictl images


  # 生成默认配置，便于修改
  kubeadm config print init-defaults > kubeadm.yaml

  cat << EOF > kubeadm.yaml
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: tupbjm.avx20bcrz2zd2h58 # 可以自定义，正则([a-z0-9]{6}).([a-z0-9]{16})
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 10.0.16.2 # 修改成节点ip
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: master01 # 节点的hostname
  taints: null
---
apiServer:
  timeoutForControlPlane: 4m0s
  certSANs: # 主节点IP
  - 127.0.0.1
  - localhost
  - 10.0.16.2
  - lb.alongparty.cn
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers # 国内源
kind: ClusterConfiguration
kubernetesVersion: 1.26.1 # 指定版本
controlPlaneEndpoint: "10.0.16.2:6443" # 设置高可用地址
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16 # 增加指定pod的网段
  serviceSubnet: 10.96.0.0/12
scheduler: {}
---
# 使用ipvs
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
---
# 指定cgroup
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF


  # 初始化集群并将控制平面证书上传到 kubeadm-certs Secret
  kubeadm init \
  --config /root/kubeadm.yaml \
  --ignore-preflight-errors=SystemVerification \
  --upload-certs
}


Install_CNI() {
  # 使用calico
  curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/calico.yaml -O calico-3-24-1.yaml
  kubectl apply -f calico-3-24-1.yaml
}

Init_Node
Install_Container
Install_Kubeadm
Init_Master
Install_CNI

#https://blog.51cto.com/belbert/5872146


