#!/bin/bash
# Parameters configuration
PROXY_MODE=${1}
MONITOR_USER=${2}
MONITOR_PASS=${3}

PROXYADMIN_USER=proxy_admin
PROXYSQL_ID=$(($RANDOM))

### generate root passwd #####
passwd="$PROXYADMIN_USER-$PROXYSQL_ID"
touch /tmp/$passwd
echo $passwd > /tmp/$passwd
hash=`md5sum  /tmp/$passwd | awk '{print $1}' | sed -e 's/^[[:space:]]*//' | tr -d '/"/'`
hash=`echo ${hash:0:8} | tr  '[a-z]' '[A-Z]'`${hash:8}
hash=$hash\!\$
PROXYADMIN_PASS=$hash

### generate the user file on root linux account #####
echo "[client]
user            = $PROXYADMIN_USER
password        = $PROXYADMIN_PASS
socket          = /var/lib/proxysql/proxysql_admin.sock

[mysql]
user            = $PROXYADMIN_USER
password        = $PROXYADMIN_PASS
socket          = /var/lib/proxysql/proxysql_admin.sock
prompt          = '(\u@\h) Admin>\_'
" > /root/.my.cnf

chmod 400 /root/.my.cnf

# create directories for mysql datadir
DATA_DIR="/var/lib/mysql/datadir"
if [ ! -d ${DATA_DIR} ]; then
    mkdir -p ${DATA_DIR}
    chmod 755 ${DATA_DIR}
    chown -Rf proxysql: ${DATA_DIR}
else
    chown -Rf proxysql: ${DATA_DIR}
fi

if [ "$PROXY_MODE" == "0" ]; then

  echo "datadir=\"/var/lib/proxysql\"
  errorlog=\"/var/lib/proxysql/proxysql.log\"

  admin_variables=
  {
      admin_credentials=\"$PROXYADMIN_USER:$PROXYADMIN_PASS\"
      mysql_ifaces=\"0.0.0.0:6032;/var/lib/proxysql/proxysql_admin.sock\"
      refresh_interval=2000
      web_enabled=true
      web_port=6080
      stats_credentials=\"proxy_stats:$PROXYADMIN_PASS\"
  }

  mysql_variables=
  {
      threads=4
      max_connections=2048
      default_query_delay=0
      default_query_timeout=36000000
      have_compress=true
      poll_timeout=2000
      interfaces=\"0.0.0.0:3306;/var/lib/mysql/mysql.sock\"
      default_schema=\"information_schema\"
      stacksize=1048576
      server_version=\"5.7.12\"
      connect_timeout_server=10000
      monitor_history=60000
      monitor_connect_interval=200000
      monitor_ping_interval=200000
      ping_interval_server_msec=10000
      ping_timeout_server=200
      commands_stats=true
      sessions_sort=true
      monitor_username=\"$MONITOR_USER\"
      monitor_password=\"$MONITOR_PASS\"
      monitor_galera_healthcheck_interval=2
      monitor_galera_healthcheck_timeout=10
  }

  mysql_galera_hostgroups =
  (
      {
          writer_hostgroup=10
          backup_writer_hostgroup=20
          reader_hostgroup=30
          offline_hostgroup=9999
          max_writers=1
          writer_is_also_reader=2
          max_transactions_behind=100
          active=1
      }
  )

  mysql_servers =
  (
      { address=\"dbnode01.cluster.local\" , port=3306 , hostgroup=10, max_connections=300, weight=51 },
      { address=\"dbnode02.cluster.local\" , port=3306 , hostgroup=20, max_connections=300, weight=45 },
      { address=\"dbnode03.cluster.local\" , port=3306 , hostgroup=30, max_connections=300, weight=40 }
  )

  mysql_query_rules =
  (
      {
          rule_id=100
          active=1
          match_pattern=\"^SELECT.*FOR UPDATE\"
          destination_hostgroup=10
          apply=1
      },
      {
          rule_id=101
          active=1
          match_pattern=\"^SELECT.*@@\"
          destination_hostgroup=30
          apply=1
      },
      {
          rule_id=200
          active=1
          match_pattern=\"^SELECT .*\"
          destination_hostgroup=30
          apply=1
      },
      {
          rule_id=300
          active=1
          match_pattern=\".*\"
          destination_hostgroup=10
          apply=1
      }
  )

  mysql_users =
  (
      { username = \"wordpress\", password = \"test123\", default_hostgroup = 10, transaction_persistent = 0, active = 1 },
      { username = \"app_user\", password = \"test123\", default_hostgroup = 10, transaction_persistent = 0, active = 1 }
  )
  " > /etc/proxysql.cnf

elif [[ "$PROXY_MODE" == "1" ]]; then

  echo "datadir=\"/var/lib/proxysql\"
  errorlog=\"/var/lib/proxysql/proxysql.log\"

  admin_variables=
  {
      admin_credentials=\"$PROXYADMIN_USER:$PROXYADMIN_PASS\"
      mysql_ifaces=\"0.0.0.0:6032;/var/lib/proxysql/proxysql_admin.sock\"
      refresh_interval=2000
      web_enabled=true
      web_port=6080
      stats_credentials=\"proxy_stats:$PROXYADMIN_PASS\"
  }

  mysql_variables=
  {
      threads=4
      max_connections=2048
      default_query_delay=0
      default_query_timeout=36000000
      have_compress=true
      poll_timeout=2000
      interfaces=\"0.0.0.0:3306;/var/lib/mysql/mysql.sock\"
      default_schema=\"information_schema\"
      stacksize=1048576
      server_version=\"5.7.12\"
      connect_timeout_server=10000
      monitor_history=60000
      monitor_connect_interval=200000
      monitor_ping_interval=200000
      ping_interval_server_msec=10000
      ping_timeout_server=200
      commands_stats=true
      sessions_sort=true
      monitor_username=\"$MONITOR_USER\"
      monitor_password=\"$MONITOR_PASS\"
  }

  mysql_replication_hostgroups =
  (
    { writer_hostgroup=10 , reader_hostgroup=20 }
  )

  mysql_servers =
  (
      { address=\"primary.replication.local\" , port=3306 , hostgroup=10, max_connections=300 , max_replication_lag = 5, weight=51 },
      { address=\"primary.replication.local\" , port=3306 , hostgroup=20, max_connections=300 , max_replication_lag = 5, weight=10 },
      { address=\"replica1.replication.local\" , port=3306 , hostgroup=20, max_connections=300 , max_replication_lag = 5, weight=45 },
      { address=\"replica2.replication.local\" , port=3306 , hostgroup=20, max_connections=300 , max_replication_lag = 5, weight=45 }
  )

  mysql_query_rules =
  (
      {
          rule_id=100
          active=1
          match_pattern=\"^SELECT.*FOR UPDATE\"
          destination_hostgroup=10
          apply=1
      },
      {
          rule_id=101
          active=1
          match_pattern=\"^SELECT.*@@\"
          destination_hostgroup=20
          apply=1
      },
      {
          rule_id=200
          active=1
          match_pattern=\"^SELECT .*\"
          destination_hostgroup=20
          apply=1
      },
      {
          rule_id=300
          active=1
          match_pattern=\".*\"
          destination_hostgroup=10
          apply=1
      }
  )

  mysql_users =
  (
      { username = \"wordpress\", password = \"test123\", default_hostgroup = 10, transaction_persistent = 0, active = 1 },
      { username = \"app_user\", password = \"test123\", default_hostgroup = 10, transaction_persistent = 0, active = 1 }
  )
  " > /etc/proxysql.cnf

fi

### restart proxysql service to apply new config file generate in this stage ###
pid_proxysql=$(pidof proxysql)
if [[ $pid_proxysql != "" ]]
then
  for pid in $pid_proxysql
  do
   kill -15 $pid_proxysql
  done
  cd /var/lib/proxysql
  rm -rf *
fi
sleep 3

### initialize proxysql config fresh and clean ###
proxysql --initial

### restart proxysql service to apply new config file generate in this stage ###
pid_proxysql=$(pidof proxysql)
if [[ $pid_proxysql != "" ]]
then
  for pid in $pid_proxysql
  do
   kill -15 $pid_proxysql
  done
fi
sleep 3

### privs proxysql ####
chown -Rf proxysql: /var/lib/proxysql

systemctl enable proxysql
systemctl restart proxysql
