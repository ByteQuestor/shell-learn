echo "执行安装"
yum install openstack-ceilometer-compute -y
yum install lvm2 device-mapper-persistent-data  openstack-cinder targetcli python-keystone -y
yum -y install openstack-manila-share python2-PyMySQL libtalloc python-manilaclient MySQL-python
yum -y install lvm2 nfs-utils nfs4-acl-tools portmap targetcli
yum install -y openstack-neutron-linuxbridge ebtables ipset
yum install openstack-nova-compute -y
yum install xfsprogs rsync openstack-swift-account openstack-swift-container openstack-swift-object -y
yum install -y yum-utils device-mapper-persistent-data lvm2
yum makecache fast
yum install docker-ce python-pip git kuryr-libnetwork openstack-zun-compute -y

echo "必须等Controller节点全部安装后"
read -p "按下回车继续..."

# 执行脚本
iaas-install-nova-compute.sh &&
iaas-install-neutron-compute.sh &&
iaas-install-swift-compute.sh &&
iaas-install-cinder-compute.sh

# 检查脚本执行状态
if [ $? -eq 0 ]; then
    echo "Compute 所有安装脚本成功执行"
else
    echo "有安装脚本执行失败"
fi

for i in {1..5}
do
  echo "可以进行调优了!"
done