#!/bin/bash -eux

yum remove -y mapr-metrics

INSTALL_CMD="yum install -y"
SCRIPTS_PATH=/opt/startup

#Passwordless ssh
ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
restorecon -R -v /root/.ssh

#Disable SELinux
sed -i 's|SELINUX=enforcing|SELINUX=disabled|g' /etc/selinux/config

yum clean all

enabled ()
{
  if [ "$1" == "0" ]; then
    return 1
  else
    return 0
  fi
}

drill_enabled ()
{
  enabled "${MAPR_DRILL_VERSION:-}"
  return $?
}

drill_install ()
{
 drill_enabled
 if [ $? -eq 0 ]; then
   PKG="mapr-drill"
   if [ ! -z "${MAPR_DRILL_VERSION}" ]; then
     PKG="mapr-drill-${MAPR_DRILL_VERSION}"
   fi

   service mapr-warden stop
   sleep 5
   service mapr-warden start
   
   i=0
   while [ "$i" -le "180" ]
   do
     maprcli node cldbmaster 2> /dev/null
     if [ $? -eq 0 ]; then
        if [ -d /mapr/demo.mapr.com ]; then
		break
        else
	   echo "waiting for /mapr to mount"
	   mount
        fi
     fi

     echo "Waiting for CLDB to start up ($i seconds elapsed)..."
     sleep 5
     i=$[i+5]
   done

   #If hue is enabled and drill is enabled, then we are building a second sandbox, where we don't care about the drill sample data. Install the default drill release.
   #hue_enabled
   #if [ $? -eq 0 ]; then
   #	${INSTALL_CMD} ${PKG}
   #	cp -f /opt/startup/drill-override.conf /opt/mapr/drill/drill-0.5.0/conf
   #	sed -r -i 's/8G/2G/' /opt/mapr/drill/drill-0.5.0/conf/drill-env.sh
   #	sed -r -i 's/4G/1G/' /opt/mapr/drill/drill-0.5.0/conf/drill-env.sh
   #
   #     return 0
   #fi

   #mkdir -p /opt/mapr/drill/drill-0.7.0/conf
   #cp /opt/startup/bootstrap-storage-plugins.json /opt/mapr/drill/drill-0.7.0/conf 
   ${INSTALL_CMD} git mapr-drill
   chmod 755 -R /opt/mapr/drill/drill-0.7.0/logs
   touch /opt/mapr/drill/drill-0.7.0/logs/sqlline.log
   chmod 766 /opt/mapr/drill/drill-0.7.0/logs/sqlline.log
   pushd .
   cd /mapr/demo.mapr.com
   #git clone https://github.com/andypern/drill-beta-demo
   git clone https://github.com/supr/drill-beta-demo
   cd drill-beta-demo
   bash scripts/setup.sh
   cd /opt/startup/
   #jar uf /opt/mapr/drill/drill-0.5.0/jars/drill-java-exec-0.5.0-incubating-SNAPSHOT-rebuffed.jar bootstrap-storage-plugins.json
   popd

   cp -f /opt/startup/drill-override.conf /opt/mapr/drill/drill-0.7.0/conf

   sed -r -i 's/8G/2G/' /opt/mapr/drill/drill-0.7.0/conf/drill-env.sh
   sed -r -i 's/4G/1G/' /opt/mapr/drill/drill-0.7.0/conf/drill-env.sh

   maprcli node services -name drill-bits -action start -filter '[csvc==drill-bits]'
   while ! nc -vz localhost 8047; do sleep 1; done
   echo "Drill Bit REST API UP!"
   for cfg in hive maprdb cp dfs; do
	curl -H "Content-Type: application/json" --data @/opt/startup/${cfg}.json http://localhost:8047/storage/${cfg}.json
   done
   true
 fi
}

hive_enabled ()
{
  enabled "${MAPR_HIVE_VERSION:-}"
  return $?
}

hive_install ()
{
  hive_enabled
  if [ $? -eq 0 ]; then
    PKG="mapr-hive mapr-hivemetastore mapr-hiveserver2"
    # Test if we were passed a blank string, whichcase we install latest
    if [ ! -z "${MAPR_HIVE_VERSION}" ]; then
      PKG="mapr-hive-${MAPR_HIVE_VERSION} mapr-hivemetastore-${MAPR_HIVE_VERSION} mapr-hiveserver2-${MAPR_HIVE_VERSION}"
    fi

    #${INSTALL_CMD} ${PKG}
    ${INSTALL_CMD} http://yum.qa.lab/opensource/mapr-hive-0.13.201505011621-1.noarch.rpm http://yum.qa.lab/opensource/mapr-hivemetastore-0.13.201505011621-1.noarch.rpm http://yum.qa.lab/opensource/mapr-hiveserver2-0.13.201505011621-1.noarch.rpm

    if [ -f "/opt/mapr/hive/hive-${MAPR_HIVE_VERSION_SU}/conf/hive-site.xml" ]; then
	cp -rf $SCRIPTS_PATH/hive-site.xml /opt/mapr/hive/hive-${MAPR_HIVE_VERSION_SU}/conf/hive-site.xml
    	cp /opt/mapr/hive/hive-${MAPR_HIVE_VERSION_SU}/conf/warden.hivemeta.conf /opt/mapr/conf/conf.d/warden.hivemeta.conf
    fi

  fi
}

spark_enabled ()
{
 enabled "${MAPR_SPARK_VERSION:-}"
 return $?
}

spark_install ()
{
 spark_enabled
 if [ $? -eq 0 ]; then
    PKG="mapr-spark mapr-spark-historyserver"
    if [ ! -z "${MAPR_SPARK_VERSION:-}" ]; then
        PKG="mapr-spark-${MAPR_SPARK_VERSION} mapr-spark-historyserver-${MAPR_SPARK_VERSION}"
    fi

    ${INSTALL_CMD} ${PKG}

    hadoop fs -mkdir /apps/spark && hadoop fs -chmod 777 /apps/spark
 fi
}

sqoop_enabled ()
{
 enabled "${MAPR_SQOOP_VERSION:-}"
 return $?
}

sqoop_install ()
{
  sqoop_enabled
  if [ $? -eq 0 ]; then
	PKG="mapr-sqoop2-server mapr-sqoop2-client"
	${INSTALL_CMD} ${PKG}
  fi
}

hbase_enabled ()
{
  enabled "${MAPR_HBASE_VERSION:-}"
  return $?
}

hbase_install ()
{
  hbase_enabled
  if [ $? -eq 0 ]; then
    PKG="mapr-hbase"
    if [ ! -z "${MAPR_HBASE_VERSION:-}" ]; then
      PKG="mapr-hbase-${MAPR_HBASE_VERSION}"
    fi

    #${INSTALL_CMD} http://package.qa.lab/releases/ecosystem/redhat/mapr-hbasethrift-0.94.21.26758-1.noarch.rpm 
    ${INSTALL_CMD} ${PKG} mapr-hbasethrift
  fi
}

pig_enabled ()
{
  enabled "${MAPR_PIG_VERSION:-}"
  return $?
}

pig_install ()
{
  pig_enabled
  if [ $? -eq 0 ]; then
    PKG="mapr-pig"
    if [ ! -z "${MAPR_PIG_VERSION:-}" ]; then
      PKG="mapr-pig-${MAPR_PIG_VERSION}"
    fi

  ${INSTALL_CMD} ${PKG}
  #TODO: Remove when not needed.
  #${INSTALL_CMD} http://package.mapr.com/releases/ecosystem-4.x/redhat/mapr-pig-0.12.27259-1.noarch.rpm
  fi
}

hue_enabled ()
{
  enabled "${MAPR_HUE_VERSION:-}"
  return $?
}

hue_install ()
{
  hue_enabled
  if [ $? -eq 0 ]; then
    PKG="mapr-hue"
    if [ ! -z "${MAPR_HUE_VERSION:-}" ]; then
      HUE_PKG_VERSION=`echo ${MAPR_HUE_VERSION} | awk -F. '{printf("%s.%s.%s", $1, $2, $3); }'`
      PKG="mapr-hue-${HUE_PKG_VERSION}*"
    fi

    ${INSTALL_CMD} mapr-hue mapr-httpfs

    #Install Hue dependencies
    oozie_enabled
    if [ $? -eq 0 ]; then
      MAPR_OOZIE_VERSION=""
      oozie_install
    fi

    pig_enabled
    if [ $? -eq 0 ]; then
      MAPR_PIG_VERSION=""
      pig_install
    fi
  fi
}

flume_enabled ()
{
  enabled "${MAPR_FLUME_VERSION:-}"
  return $?
}

flume_install ()
{
  flume_enabled
  if [ $? -eq 0 ]; then
    PKG="mapr-flume"
    if [ ! -z "${MAPR_FLUME_VERSION:-}" ]; then
      PKG="mapr-flume-${MAPR_FLUME_VERSION}"
    fi
  
  ${INSTALL_CMD} ${PKG}
  fi
}

hcatalog_enabled ()
{
  enabled "${MAPR_HCATALOG_VERSION:-}"
  return $?
}

hcatalog_install ()
{
  hcatalog_enabled
  if [ $? -eq 0 ]; then
    PKG="mapr-hcatalog"
    if [ ! -z "${MAPR_HCATALOG_VERSION:-}" ]; then
      PKG="mapr-hcatalog-${MAPR_HCATALOG_VERSION}"
    fi

  ${INSTALL_CMD} ${PKG}
  fi
}

oozie_enabled ()
{
  enabled "${MAPR_OOZIE_VERSION:-}"
  return $?
}

oozie_install ()
{
  oozie_enabled
  if [ $? -eq 0 ]; then
    PKG="mapr-oozie"
    if [ ! -z "${MAPR_OOZIE_VERSION:-}" ]; then
      PKG="mapr-oozie-${MAPR_OOZIE_VERSION}"
    fi

  ${INSTALL_CMD} ${PKG}
  fi
}

mahout_enabled ()
{
  enabled "${MAPR_MAHOUT_VERSION:-}"
  return $?
}

mahout_install ()
{
  mahout_enabled
  if [ $? -eq 0 ]; then
    PKG="mapr-mahout"
    if [ ! -z "${MAPR_MAHOUT_VERSION:-}" ]; then
      PKG="mapr-mahout-${MAPR_MAHOUT_VERSION}"
    fi
  
  ${INSTALL_CMD} ${PKG}
  fi
}

if [ "${MAPR_OOZIE_VERSION}" = "0" ]; then
 MAPR_OOZIE_VERSION_SU=4.0.0
else
 MAPR_OOZIE_VERSION_SU=`echo "${MAPR_OOZIE_VERSION:-4.0.0}" | awk -F. '{ printf("%s.%s.%s", $1,$2,$3); }'`
fi

if [ "${MAPR_HUE_VERSION}" = "0" ]; then
 MAPR_HUE_VERSION_SU=2.5.0
else
 MAPR_HUE_VERSION_SU=`echo "${MAPR_HUE_VERSION:-3.6.0}" | awk -F. '{ printf("%s.%s.%s", $1,$2,$3); }'`
fi

if [ "${MAPR_HIVE_VERSION}" = "0" ]; then
 MAPR_HIVE_VERSION_SU=0.13
else
 MAPR_HIVE_VERSION_SU=`echo "${MAPR_HIVE_VERSION:-0.13}" | awk -F. '{ printf("%s.%s", $1,$2); }'`
fi

install_packages ()
{
 hive_install
 hbase_install
 hue_install
 pig_install
 flume_install
 hcatalog_install
 oozie_install
 mahout_install
 drill_install
 spark_install
 sqoop_install
}

yum --enablerepo=MapR_Ecosystem clean metadata
tar -xvzf /tmp/startup.tar.gz -C /opt
chown root:root /opt/startup -R

cp /opt/startup/start-tty* /etc/init
cp /opt/startup/etc_sysconfig_init /etc/sysconfig/init
cp /opt/startup/container-executor.cfg /opt/mapr/hadoop/hadoop-${HADOOP_VERSION:-2.5.1}/etc/hadoop
#cp /opt/startup/yarn-site.xml /opt/mapr/hadoop/hadoop-2.4-1/etc/hadoop/yarn-site.xml

sed -i "s/_MAPR_BANNER_NAME_/${MAPR_BANNER_NAME}/g" /opt/startup/welcome.py
sed -i "s/_MAPR_BANNER_NAME_/${MAPR_BANNER_NAME}/g" /opt/startup/error.py
sed -i "s/_MAPR_BANNER_NAME_/${MAPR_BANNER_NAME}/g" /opt/startup/startup_script
sed -i "s/_MAPR_OOZIE_VERSION_/${MAPR_OOZIE_VERSION_SU:-4.0.0}/g" /opt/startup/startup_script
sed -i "s/_MAPR_HUE_VERSION_/${MAPR_HUE_VERSION_SU:-2.5.0}/g" /opt/startup/startup_script
sed -i "s/_MAPR_HIVE_VERSION_/${MAPR_HIVE_VERSION_SU:-0.13}/g" /opt/startup/startup_script
sed -i "s/_MAPR_VERSION_/${MAPR_CORE_VERSION}/g" /opt/startup/startup_script
sed -i "s/_HADOOP_VERSION_/${HADOOP_VERSION:-2.4.1}/g" /opt/startup/startup_script

sed -i "s|_MAPR_BANNER_URL_|${MAPR_BANNER_URL}|g" /opt/startup/welcome.py

sed -i "s/_MAPR_VERSION_/${MAPR_CORE_VERSION}/g" /opt/startup/welcome.py
sed -i "s/_MAPR_VERSION_/${MAPR_CORE_VERSION}/g" /opt/startup/error.py

rm /tmp/startup.tar.gz

service mapr-warden stop
service mapr-zookeeper stop
#[ -f /opt/mapr/initscripts/mapr-warden-patched ] && \
#	cp /opt/mapr/initscripts/mapr-warden-patched /etc/init.d/mapr-warden

rpm -iv /tmp/mapr-patch-*.rpm
rm /tmp/mapr-patch-*.rpm

# Force a simple hostname ... we can't have a "*.local"
hostname maprdemo
sed -i "s/^HOSTNAME.*/HOSTNAME=maprdemo/" /etc/sysconfig/network

/opt/mapr/server/configure.sh -N demo.mapr.com -Z maprdemo -C maprdemo \
	-u mapr -g mapr -M7 --isvm 

/usr/sbin/makewhatis
${INSTALL_CMD}  lsof
${INSTALL_CMD}  python-sh

Conf[0]="service.command.nfs.heapsize.min"
Conf[1]="service.command.nfs.heapsize.max"
Conf[2]="service.command.hbmaster.heapsize.min"
Conf[3]="service.command.hbmaster.heapsize.max"
Conf[4]="service.command.hbregion.heapsize.min"
Conf[5]="service.command.hbregion.heapsize.max"
Conf[6]="service.command.cldb.heapsize.min"
Conf[7]="service.command.cldb.heapsize.max"
Conf[8]="service.command.webserver.heapsize.min"
Conf[9]="service.command.webserver.heapsize.max"
Conf[10]="service.command.mfs.heapsize.min"
Conf[11]="service.command.mfs.heapsize.max"

Val[0]="64"
Val[1]="64"
Val[2]="128"
Val[3]="128"
Val[4]="256"
Val[5]="256"
Val[6]="256"
Val[7]="256"
Val[8]="128"
Val[9]="128"
Val[10]="512"
Val[11]="512"

for i in "${!Conf[@]}"; do
  sed -i s/${Conf[$i]}=.*/${Conf[$i]}=${Val[$i]}/ /opt/mapr/conf/warden.conf
done

service mapr-zookeeper start
service mapr-warden start

mkdir /user

i=0
while [ "$i" -le "180" ]
do
  maprcli node cldbmaster 2> /dev/null
  if [ $? -eq 0 ]; then
    break
  fi

  echo "Waiting for CLDB to start up ($i seconds elapsed)..."
  sleep 5
  i=$[i+5]
done

#	Done automatically by latest installer 
# echo "localhost:/mapr /mapr soft,intr,nolock" >> /opt/mapr/conf/mapr_fstab
# mount localhost:/mapr /mapr
mkdir -p /user
echo "localhost:/mapr/demo.mapr.com/user /user soft,intr,nolock" >> /opt/mapr/conf/mapr_fstab
mount localhost:/mapr/demo.mapr.com/user /user

chmod a+r /opt/mapr/conf/mapr_fstab


maprcli config save -values "{cldb.restart.wait.time.sec:5}"
maprcli config save -values "{cldb.volumes.default.replication:1}"
maprcli config save -values "{cldb.volumes.default.min.replication:1}"
VOLUMES=$(maprcli volume list -columns volumename | tail -n +2)
for volume in ${VOLUMES}; do
  maprcli volume modify -name ${volume} -minreplication 1 -replication 1
  if [ $? -ne 0 ]; then
    echo "Warning: unable to set replication factor for volume: ${volume} to 1"
  fi
done

maprcli acl edit -type cluster -user mapr:fc
maprcli volume create -name tables -replication 1 -path /tables
maprcli acl edit -type volume -name tables -user mapr:fc

yum install -y acpid
install_packages

# ${INSTALL_CMD} mapr-metrics

hadoop fs -mkdir /user/root

oozie_enabled
if [ $? -eq 0 ]; then
  hadoop fs -mkdir -p /oozie/share/lib
  hadoop fs -mkdir -p /oozie/examples
  tar -xvzf /opt/mapr/oozie/oozie-*/oozie-sharelib-*-mapr-*.tar.gz -C /tmp
  hadoop fs -put /tmp/share/lib/* /oozie/share/lib/
  tar -xvzf /opt/mapr/oozie/oozie-*/oozie-examples.tar.gz -C /tmp
  hadoop fs -put /tmp/examples/* /oozie/examples/

  hadoop fs -chown -R mapr:mapr /oozie
  hadoop fs -chmod -R 777 /oozie

  #The following is manadatory for Oozie to talk to RM's
  for A in /mapr/demo.mapr.com/oozie/examples/apps/*; do
	sed -i 's/jobTracker=.*/jobTracker=maprdemo:8032/' $A/job.properties
  done 
fi

hue_enabled
if [ $? -eq 0 ]; then
  cp /opt/mapr/hue/hue-*/desktop/libs/hadoop/java-lib/hue-plugins-*.jar /opt/mapr/hadoop/hadoop*/lib/
  grep "<url-pattern>/mcs/\*</url-pattern>" /opt/mapr/adminuiapp/webapp/WEB-INF/web.xml > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    sed -i -e "s#<url-pattern>/index/\*</url-pattern>#<url-pattern>/mcs/*</url-pattern>\
   </servlet-mapping>\
   <servlet-mapping>\
       <servlet-name>com.mapr.adminuiapp.http.vm_jsp</servlet-name>\
       <url-pattern>/index/*</url-pattern>#" /opt/mapr/adminuiapp/webapp/WEB-INF/web.xml
  fi

  sed -i -e "s/mapr.webui.https.port=8443/mapr.webui.http.port=8443/g" /opt/mapr/conf/web.conf
  hadoop fs -mkdir -p /user/hive/warehouse
  hadoop fs -chmod -R 777 /user/hive/warehouse
  sed -i -e 's/self == top/true/g' /opt/mapr/hue/hue-*/desktop/core/src/desktop/templates/common_header.mako
  #rm -f /opt/mapr/roles/drill-bits
  # Uncomment the below line if we need to remove drill from the Hue(Traditional) Sandbox.
  #rm -f /opt/mapr/conf/conf.d/warden.drill-bits.conf
fi

for user in user01 user02 hbaseuser mruser; do
  useradd -d /user/$user -p `openssl passwd -1 mapr` -g mapr -m $user
done

#Mark this as off, to prevent Races
chkconfig mapr-warden off

echo "Stopping Warden!!!!"
service mapr-warden stop
echo "Stopping Zookeeper!!!!"
service mapr-zookeeper stop
