#!/bin/bash
# Parameters configuration

verify_proxysql=`rpm -qa | grep proxysql`
if [[ $verify_proxysql == "proxysql"* ]]
then
echo "$verify_proxysql is installed!"
else
   ##### FIREWALLD DISABLE #########################
   systemctl disable firewalld
   systemctl stop firewalld
   ######### SELINUX ###############################
   sed -ie 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
   # disable selinux on the fly
   /usr/sbin/setenforce 0

   ### clean yum cache ###
   rm -rf /etc/yum.repos.d/MariaDB.repo
   rm -rf /etc/yum.repos.d/mariadb.repo
   rm -rf /etc/yum.repos.d/mysql-community.repo
   rm -rf /etc/yum.repos.d/mysql-community-source.repo
   rm -rf /etc/yum.repos.d/percona-original-release.repo
   yum clean headers
   yum clean packages
   yum clean metadata

   # configure user
   adduser proxysql
   chsh -s /bin/bash proxysql

   ####### PACKAGES ###########################
   # -------------- For RHEL/CentOS 7 --------------
   yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

   ### install pre-packages ####
   yum -y install screen nload bmon openssl libaio rsync snappy net-tools wget nmap htop dstat sysstat

   ### ProxySQL Setup ####
   echo "[proxysql_repo]
name=ProxySQL YUM repository
baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.0.x/centos/latest
gpgcheck=1
gpgkey=https://repo.proxysql.com/ProxySQL/repo_pub_key" > /etc/yum.repos.d/proxysql.repo

   ### Installation ProxySQL via yum ###
   yum -y install proxysql

   ### Installation MARIADB via yum ####
   curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
   yum -y install MariaDB-client

   ### Percona #####
   ### https://www.percona.com/doc/percona-server/LATEST/installation/yum_repo.html
   yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm -y
   yum -y install percona-toolkit sysbench

   ##### CONFIG PROFILE #############
   check_profile=$(cat /etc/profile | grep '# proxysql-pre-reqs' | wc -l)
   if [ "$check_profile" == "0" ]; then
   echo ' ' >> /etc/profile
   echo '# proxysql-pre-reqs' >> /etc/profile
   echo 'if [ $USER = "proxysql" ]; then' >> /etc/profile
   echo '  if [ $SHELL = "/bin/bash" ]; then' >> /etc/profile
   echo '    ulimit -u 65536 -n 65536' >> /etc/profile
   echo '  else' >> /etc/profile
   echo '    ulimit -u 65536 -n 65536' >> /etc/profile
   echo '  fi' >> /etc/profile
   echo 'fi' >> /etc/profile
   else
   echo "ProxySQL Pre-reqs for /etc/profile is already in place!"
   fi

   #####  ProxySQL LIMITS ###########################
   check_limits=$(cat /etc/security/limits.conf | grep '# proxysql-pre-reqs' | wc -l)
   if [ "$check_limits" == "0" ]; then
   echo ' ' >> /etc/security/limits.conf
   echo '# proxysql-pre-reqs' >> /etc/security/limits.conf
   echo 'proxysql              soft    nproc   102400' >> /etc/security/limits.conf
   echo 'proxysql              hard    nproc   102400' >> /etc/security/limits.conf
   echo 'proxysql              soft    nofile  102400' >> /etc/security/limits.conf
   echo 'proxysql              hard    nofile  102400' >> /etc/security/limits.conf
   echo 'proxysql              soft    stack   102400' >> /etc/security/limits.conf
   echo 'proxysql              soft    core unlimited' >> /etc/security/limits.conf
   echo 'proxysql              hard    core unlimited' >> /etc/security/limits.conf
   echo '# all_users' >> /etc/security/limits.conf
   echo '* soft nofile 102400' >> /etc/security/limits.conf
   echo '* hard nofile 102400' >> /etc/security/limits.conf
   else
   echo "ProxySQL Pre-reqs for /etc/security/limits.conf is already in place!"
   fi

   mkdir -p /etc/systemd/system/proxysql.service.d/
   echo ' ' > /etc/systemd/system/proxysql.service.d/limits.conf
   echo '# proxysql' >> /etc/systemd/system/proxysql.service.d/limits.conf
   echo '[Service]' >> /etc/systemd/system/proxysql.service.d/limits.conf
   echo 'LimitNOFILE=102400' >> /etc/systemd/system/proxysql.service.d/limits.conf
   systemctl daemon-reload
fi
