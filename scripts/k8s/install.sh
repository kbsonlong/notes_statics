#!/bin/bash

# Install K8S

Init () {
    yum install -y epel-release
yum install -y conntrack ntpdate ntp ipvsadm nfs-utils ipset jq iptables curl sysstat libseccomp wget
## 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
iptables -P FORWARD ACCEPT
## 禁用swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
systemctl stop dnsmasq
systemctl disable dnsmasq
## 加载ipvs模块
mkdir -p  /etc/sysconfig/modules/
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4
## 内核配置
cat > kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0 # 禁止使用 swap 空间，只有当系统 OOM 时才允许使用它
vm.overcommit_memory=1 # 不检查物理内存是否够用
vm.panic_on_oom=0 # 开启 OOM
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
cp kubernetes.conf  /etc/sysctl.d/kubernetes.conf
sysctl -p /etc/sysctl.d/kubernetes.conf
# 调整系统 TimeZone
timedatectl set-timezone Asia/Shanghai
# 将当前的 UTC 时间写入硬件时钟
timedatectl set-local-rtc 0
# 重启依赖于系统时间的服务
systemctl restart rsyslog 
systemctl restart crond
systemctl stop postfix && systemctl disable postfix
# 持久化保存日志的目录
mkdir /var/log/journal 
mkdir /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-prophet.conf <<EOF
[Journal]
# 持久化保存到磁盘
Storage=persistent
# 压缩历史日志
Compress=yes
SyncIntervalSec=5m
RateLimitInterval=30s
RateLimitBurst=1000
# 最大占用空间 10G
SystemMaxUse=10G
# 单日志文件最大 200M
SystemMaxFileSize=200M
# 日志保存时间 2 周
MaxRetentionSec=2week
# 不将日志转发到 syslog
ForwardToSyslog=no
EOF
systemctl restart systemd-journald

}

Install_Docker() {
    # 1.卸载旧版本docker
yum remove docker \
            docker-client \
            docker-client-latest \
            docker-common \
            docker-latest \
            docker-latest-logrotate \
            docker-logrotate \
            docker-selinux \
            docker-engine-selinux \
            docker-engine \
            docker \
            docker-ce \
            docker-ee -y
# 2.安装所需的包
# yum-utils 提供了 yum-config-manager 实用程
# 并且 devicemapper 存储驱动需要 device-mapper-persistent-data 和 lvm2
yum install -y yum-utils device-mapper-persistent-data lvm2
# 3.使用以下命令设置源
#阿里源（建议使用）
yum-config-manager \
--add-repo \
https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# 4.或者安装指定版本
yum list docker-ce --showduplicates | sort -r
#yum install -y docker-ce-18.09.7
yum install -y docker-ce
# 5.配置docker
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "registry-mirrors": ["https://3ksoxp7c.mirror.aliyuncs.com"],
"graph":"/data/docker"
}
EOF
systemctl daemon-reload
systemctl restart docker
yum install conntrack socat -y
}

Install_Kubeadm() {
    ## 安装kubelet kubeadm kubectl
cat << EOF > /etc/yum.repos.d/k8s.repo
[kubernetes]
name=Kubernetes Repository
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
      https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
EOF
yum install kubeadm-1.20.5  kubectl-1.20.5 kubelet-1.20.5  -y
systemctl enable docker.service
systemctl enable kubelet.service
systemctl start kubelet.service

}


Config_Host () {
    cat << EOF >>/etc/hosts
172.17.136.124 k8s-001
172.17.136.125 k8s-002
172.17.136.126 k8s-003
172.17.136.126 lb.alongparty.cn
EOF

}

Init_Master () {
    ## 初始化master
cat << EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.20.5
apiServer:
  certSANs:
  - k8s-001
  - k8s-002
  - k8s-003
  - 172.17.136.125
  - 172.17.136.124
  - 172.17.136.126
  - lb.alongparty.cn
  - 127.0.0.1
  - localhost
controlPlaneEndpoint: "lb.alongparty.cn:6443"
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
etcd:
  local:
    dataDir: /data/server/etcd
networking:
  serviceSubnet: "10.96.0.0/16"
  podSubnet: "10.244.0.0/16"
  dnsDomain: "alongparty.cn"
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
# 1.20.2之后不需要此配置项
#featureGates:
#  SupportIPVSProxyMode: true
mode: ipvs
EOF

kubeadm init --config=kubeadm-config.yaml --upload-certs > token.log
# 配置 kubectl
rm -rf /root/.kube/
mkdir /root/.kube/
cp -i /etc/kubernetes/admin.conf /root/.kube/config
## 命令补全
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
source .bash_profile
## 命令补全
yum -y install bash-completion
source /etc/profile.d/bash_completion.sh
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
}


Install_CNI() {
    curl https://docs.projectcalico.org/v3.10/manifests/calico.yaml -o calico-3.10.yml
    sed 's/# - name: CALICO_IPV4POOL_CIDR/- name: CALICO_IPV4POOL_CIDR/g' calico-3.10.yml -i
    sed 's/#   value: "192.168.0.0\/16"/  value: "10.244.0.0\/16"/g' calico-3.10.yml -i 
    sed 's/value: "192.168.0.0\/16"/value: "10.244.0.0\/16"/g' calico-3.10.yml -i
    kubectl apply -f calico-3.10.yml   
}

Local_Storage() {
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.23/deploy/local-path-storage.yaml
EOF

kubectl create -f storage-class.yml

}

Install_Node() {
    Init
    Config_Host
    Install_Docker
    Install_Kubeadm
}

Install_Master() {
    Install_Node
    Init_Master
    Install_CNI
    Local_Storage
    kubectl taint node `hostname`  node-role.kubernetes.io/master-
}

main() {
case $1 in 
    node)
    Install_Node
    ;;
    master)
    Install_Master
    ;;
esac
}

main $1
