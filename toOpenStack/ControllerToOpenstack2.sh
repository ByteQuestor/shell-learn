# 执行各个安装脚本
iaas-install-mysql.sh &&
iaas-install-keystone.sh && 
source /etc/keystone/admin-openrc.sh &&
iaas-install-glance.sh && 
iaas-install-placement.sh && 
iaas-install-nova-controller.sh && 
iaas-install-neutron-controller.sh && 
iaas-install-dashboard.sh && 
iaas-install-swift-controller.sh && 
iaas-install-cinder-controller.sh
# 检查脚本执行状态
if [ $? -eq 0 ]; then
    echo "Controller 所有安装脚本成功执行"
else
    echo "有安装脚本执行失败"
fi

for i in {1..5}
do
  echo "可以进行调优了!"
done

echo "source /etc/keystone/admin-openrc.sh" >> ~/.bashrc