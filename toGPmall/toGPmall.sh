#!/bin/bash
###
 # @Author: 【闲鱼】混吃等死真君 【Github】Bytequestor
 # @Date: 2024-11-25 12:35:27
 # @LastEditTime: 2024-11-25 16:33:43
 # @FilePath: \shell-learn\toGPmall\toGPmall.sh
 # @Description: 
 # 
 # Copyright (c) 2024 by 茉莉花工作室/troml1788, All Rights Reserved. 
### 
mall_ip=192.168.100.10
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
# 配置主机映射
echo "$mall_ip mall" >> /etc/hosts
echo "$mall_ip kafka.mall" >> /etc/hosts
echo "$mall_ip mysql.mall" >> /etc/hosts
echo "$mall_ip redis.mall" >> /etc/hosts
echo "$mall_ip zookeeper.mall" >> /etc/hosts
# 设置selinux策略
setenforce 0
sed -i "s/SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config
# 删除自带的yum源 & 配置本地源
rm -rf /etc/yum.repos.d/*
cat >> /etc/yum.repos.d/local.repo << EOF
[mall]
name=mall
gpgcheck=0
enabled=1
baseurl=file:///opt/gpmall
EOF

# 解压资源包
rm -rf /opt/*
tar -zxvf GPMall.tar.gz
tar -zxvf gpmall/gpmall.tar -C /opt/
ls /opt/

# 验证yum源
yum clean all && yum repolist

# 安装java环境
yum install -y java-*

# 安装 zookeeper
tar -zxvf /root/gpmall/zookeeper-3.4.14.tar.gz
mv zookeeper-3.4.14/conf/zoo_sample.cfg zookeeper-3.4.14/conf/zoo.cfg
/root/zookeeper-3.4.14/bin/zkServer.sh start &
sleep 8 # 可通过 ./zkCli.sh -server 192.168.100.10:2181 手工验证
# 安装kafaka
tar -zxvf /root/gpmall/kafka_2.11-1.1.1.tgz
/root/kafka_2.11-1.1.1/bin/kafka-server-start.sh -daemon /root/kafka_2.11-1.1.1/config/server.properties &
sleep 8
# 安装数据库
# 可添加 skip-grant-tables 绕过密码登录
yum install -y mariadb-server
mysql_install_db --user=root
mysqld_safe --user=root &
sleep 8
mysqladmin -u root password '123456'
# 设置root用户权限 为 root 用户授予从任何主机 (%) 连接时对所有数据库的所有权限
mysql -uroot -p123456 -e "grant all on *.* to 'root'@'%' identified by '123456'; flush privileges"
mysql -uroot -p123456 -e "create database gpmall; use gpmall; source /root/gpmall/gpmall.sql;"

systemctl enable mariadb

# 安装redis
yum install -y redis
sed -i "s/protected-mode yes/protected-mode no/g" /etc/redis.conf
sed -i "s/bind 127.0.0.1/#bind /g" /etc/redis.conf
systemctl enable --now redis

# 安装nginx
yum install -y nginx
cat > "/etc/nginx/conf.d/default.conf" <<EOL
server {
    listen 80;
    server_name example.com;  
    location / {
        root /usr/share/nginx/html/;
        index index.html;
    }
    location /user {
        proxy_pass http://127.0.0.1:8082;
    }
    location /shopping {
        proxy_pass http://127.0.0.1:8081;
    }
    location /cashier {
        proxy_pass http://127.0.0.1:8083;
    }
}
EOL
# 前端
rm -rf /usr/share/nginx/html/*
tar -zxvf gpmall/dist.tar -C /usr/share/nginx/html/

systemctl enable --now nginx
# 后端
# 探针启动【有问题，这些服务还需要手工运行才可以】
nohup java -jar /root/gpmall/shopping-provider-0.0.1-SNAPSHOT.jar & 
nohup java -jar /root/gpmall/user-provider-0.0.1-SNAPSHOT.jar & 
nohup java -jar /root/gpmall/gpmall-shopping-0.0.1-SNAPSHOT.jar & 
nohup java -jar /root/gpmall/gpmall-user-0.0.1-SNAPSHOT.jar & 

jobs

tail -f nohup.out