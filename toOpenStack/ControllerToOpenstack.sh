#!/bin/bash
# 节点说明
# controller 192.168.100.10 且root目录下有CentOS-7-x86_64-DVD-2009.iso、chinaskills_cloud_iaas_v2.0.3.iso
# controller 192.168.100.20
hostnamectl set-hostname controller
# 确保 controller 和 compute 都保持开启
echo '192.168.100.10 controller' >> /etc/hosts
echo '192.168.100.20 compute' >> /etc/hosts
echo "映射文件已配置"

# 停止并禁用 firewalld
systemctl stop firewalld
systemctl disable firewalld
echo "防火墙关闭完成"

# 将 SELinux 设置为宽松模式
setenforce 0
# 修改 SELINUX 设置为 permissive
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
echo "SELinux已禁止"

# 配置yum源
# 删除原来的yum源
rm -rf /etc/yum.repos.d/*
mkdir /opt/{centos,iaas}
mount CentOS-7-x86_64-DVD-2009.iso /mnt/
echo "复制centos"
cp -rf /mnt/* /opt/centos/
umount /mnt/
mount chinaskills_cloud_iaas_v2.0.3.iso /mnt/
echo "复制iaas"
cp -rf /mnt/* /opt/iaas/
umount /mnt/
cat <<EOF > /etc/yum.repos.d/local.repo
[centos]
name=centos
baseurl=file:///opt/centos
gpgcheck=0
enabled=1
[iaas]
name=centos
baseurl=file:///opt/iaas/iaas-repo
gpgcheck=0
enabled=1
EOF
echo "YUM 源配置成功"

# 配置vsftpd服务器
yum install -y vsftpd openstack-iaas
echo "anon_root=/opt/" >> /etc/vsftpd/vsftpd.conf
systemctl restart vsftpd
systemctl enable vsftpd
echo "vsftpd服务配置完毕 && openstack已安装"

# 删除指定文件的每一行
sed -i 's/^.//' /etc/openstack/openrc.sh
# 添加配置
# 快速替换密码
sed -i 's/PASS=/PASS=000000/g' /etc/openstack/openrc.sh
# 填充
sed -i 's/^HOST_IP=.*/HOST_IP=192.168.100.10/' /etc/openstack/openrc.sh
sed -i 's/^HOST_NAME=.*/HOST_NAME=controller/' /etc/openstack/openrc.sh
# 填充
sed -i 's/^HOST_IP_NODE=.*/HOST_IP_NODE=192.168.100.20/' /etc/openstack/openrc.sh
sed -i 's/^HOST_PASS_NODE=.*/HOST_PASS_NODE=000000/' /etc/openstack/openrc.sh
sed -i 's/^HOST_NAME_NODE=.*/HOST_NAME_NODE=compute/' /etc/openstack/openrc.sh
# 填充
sed -i 's/^network_segment_IP=.*/network_segment_IP=192.168.100.0\/24/' /etc/openstack/openrc.sh
sed -i 's/^RABBIT_USER=.*/RABBIT_USER=openstack/' /etc/openstack/openrc.sh
sed -i 's/^DOMAIN_NAME=.*/DOMAIN_NAME=demo/' /etc/openstack/openrc.sh
sed -i 's/^METADATA_SECRET=.*/METADATA_SECRET=000000/' /etc/openstack/openrc.sh
sed -i 's/^INTERFACE_NAME=.*/INTERFACE_NAME=eth1/' /etc/openstack/openrc.sh
sed -i 's/^Physical_NAME=.*/Physical_NAME=provider/' /etc/openstack/openrc.sh
sed -i 's/^minvlan=.*/minvlan=101/' /etc/openstack/openrc.sh
sed -i 's/^maxvlan=.*/maxvlan=200/' /etc/openstack/openrc.sh
sed -i 's/^BLOCK_DISK=.*/BLOCK_DISK=sdb1/' /etc/openstack/openrc.sh
sed -i 's/^OBJECT_DISK=.*/OBJECT_DISK=sdb2/' /etc/openstack/openrc.sh
sed -i 's/^STORAGE_LOCAL_NET_IP=.*/STORAGE_LOCAL_NET_IP=192.168.100.20/' /etc/openstack/openrc.sh
sed -i 's/^SHARE_DISK=.*/SHARE_DISK=sdb3/' /etc/openstack/openrc.sh
echo "openrc.sh配置完毕"

iaas-pre-host.sh 
echo "重连后执行   bash ControllerToOpenstack2.sh "