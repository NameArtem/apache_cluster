# apache_cluster
This repository is dedicated to installation and configuration cluster with Apache products


!Note. Я подразумеваю, что у вас уже установлен python3.6 и выше + pip3


состав кластера
#########

IP адрес | Имя узла | Роли
---------|----------|-----------------------------
10.0.0.2 | master   | NameNode, ResourceManager
10.0.0.3 | slave1   | SecondaryNameNode, DataNode, NodeManager
10.0.0.4 | slave2   | DataNode
10.0.0.5 | slave3   | DataNode




## Pre configuration

Disable SELinux
$ sudo setenforce 0
The above command will disable SELinux for the session i.e. until next reboot – to permanently disable it set SELINUX=disabled in /etc/selinux/config file.


yum install -y net-tools openssh-server wget epel-release


называем хостнейм
hostnamectl set-hostname master


добавляем все хотя в /etc/hosts
echo '192.168.171.132 master' >> /etc/hosts
echo '192.168.171.133 slave1' >> /etc/hosts
echo '192.168.171.134 slave2' >> /etc/hosts


#ssh-key
ssh-keygen -t rsa -b 4096
ssh-copy-id cnt-cls-m2


ntp (для синхронизации внутренних часов)
[wiki](https://ru.wikipedia.org/wiki/NTP)

[попробовать самому написать](https://habr.com/ru/post/448060/#:~:text=NTP%20%E2%80%93%20%D0%BF%D1%80%D0%BE%D1%82%D0%BE%D0%BA%D0%BE%D0%BB%20%D0%B2%D0%B7%D0%B0%D0%B8%D0%BC%D0%BE%D0%B4%D0%B5%D0%B9%D1%81%D1%82%D0%B2%D0%B8%D1%8F%20%D1%81%20%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0%D0%BC%D0%B8,%D1%81%D1%83%D1%89%D0%B5%D1%81%D1%82%D0%B2%D1%83%D0%B5%D1%82%205%20%D0%B2%D0%B5%D1%80%D1%81%D0%B8%D0%B9%20NTP%20%D0%BF%D1%80%D0%BE%D1%82%D0%BE%D0%BA%D0%BE%D0%BB%D0%B0.)

yum install ntp ntpdate ntp-doc -y

yum install openssl


# Java
yum install -y java-1.8.0-openjdk.x86_64 java-1.8.0-openjdk-devel.x86_64

создать файл /etc/profile.d/java.sh и добавить
export JAVA_HOME=/usr/lib/jvm/java-openjdk
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=$JAVA_HOME/lib:.
export PATH=$PATH:$JAVA_HOME/bin


#Scala
wget http://www.scala-lang.org/files/archive/scala-2.12.11.tgz
tar -xvf scala-2.12.11.tgz
mv scala-2.12.11 /usr/lib
ln -s /usr/lib/scala-2.12.11 /usr/lib/scala


zookeeprer
yum install -y zookeeper
yum install -y zookeeper-server


пользователь для работы
sudo groupadd hadoop
sudo useradd -d /home/hadoop -g hadoop hadoop
sudo passwd hadoop


########################
отключаем firewall
sudo systemctl stop firewalld.service
sudo systemctl disable firewalld.service



# disable ip table
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT


########################



# hadoop installation

su - hadoop


cd /opt
wget http://mirror.linux-ia64.org/apache/hadoop/common/hadoop-3.2.1/hadoop-3.2.1.tar.gz
tar -xvf hadoop-3.2.1.tar.gz
rm hadoop-3.2.1.tar.gz
mv hadoop-3.2.1 /opt/hadoop3
chmod 775 hadoop3



# расширяем .bashrc $HADOOP_HOME

export HADOOP_HOME=/opt/hadoop3
export HADOOP_INSTALL=$HADOOP_HOME
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export YARN_HOME=$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin
export HADOOP_ROOT_LOGGERi=INFO,console
export HADOOP_SECURITY_LOGGER=INFO,NullAppender
export HADOOP_INSTALL=$HADOOP_HOME
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_PREFIX=$HADOOP_HOME
export HADOOP_LIBEXEC_DIR=$HADOOP_HOME/libexec
export JAVA_LIBRARY_PATH=$HADOOP_HOME/lib/native:$JAVA_LIBRARY_PATH
export HADOOP_YARN_HOME=$HADOOP_HOME


редактируем файлы в /opt/hadoop3/etc/hadoop/

core-site.xml

<configuration>
<property>
    <name>fs.defaultFS</name>
    <value>hdfs://master:9000/</value>
    <description>namenode settings</description>
</property>
<property>
    <name>hadoop.tmp.dir</name>
    <value>/home/hadoop/hadoop-2.7.7/tmp/hadoop-${user.name}</value>
    <description> temp folder </description>
</property>  
<property>
    <name>hadoop.proxyuser.hadoop.hosts</name>
    <value>*</value>
</property>
<property>
    <name>hadoop.proxyuser.hadoop.groups</name>
    <value>*</value>
</property>
</configuration>




hdfs-site.xml
<configuration>  
    <property>  
        <name>dfs.namenode.http-address</name>  
        <value>master:50070</value>  
        <description> fetch NameNode images and edits </description>  
    </property>
    <property>  
        <name>dfs.namenode.secondary.http-address</name>  
        <value>slave1:50090</value>  
        <description> fetch SecondNameNode fsimage </description>  
    </property>
    <property>
        <name>dfs.replication</name>
        <value>2</value>
        <description> replica count </description>
    </property>
    <property>  
        <name>dfs.namenode.name.dir</name>  
        <value>file:///home/hadoop/hadoop-2.7.7/hdfs/name</value>  
        <description> namenode </description>  
    </property>  
    <property>  
        <name>dfs.datanode.data.dir</name>
        <value>file:///home/hadoop/hadoop-2.7.7/hdfs/data</value>  
        <description> DataNode </description>  
    </property>  
    <property>  
        <name>dfs.namenode.checkpoint.dir</name>  
        <value>file:///home/hadoop/hadoop-2.7.7/hdfs/namesecondary</value>  
        <description>  check point </description>  
    </property>
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>dfs.stream-buffer-size</name>
        <value>131072</value>
        <description> buffer </description>
    </property>
    <property>  
        <name>dfs.namenode.checkpoint.period</name>  
        <value>3600</value>  
        <description> duration </description>  
    </property>
    <property>
        <name>dfs.permissions</name>
        <value>false</value>
        <description>Если требуется отключить проверки безопасности в Hadoop, что часто используется при разработке, добавьте в файл следующую секцию </description>
    </property>
</configuration>



mapred-site.xml

<configuration>  
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
        </property>
    <property>
        <name>mapreduce.jobtracker.address</name>
        <value>hdfs://trucy:9001</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>master:10020</value>
        <description>MapReduce JobHistory Server host:port, default port is 10020.</description>
    </property>
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>master:19888</value>
        <description>MapReduce JobHistory Server Web UI host:port, default port is 19888.</description>
    </property>
</configuration>



yarn-site.xml
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>master</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>master:8032</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address</name>
        <value>master:8030</value>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address</name>
        <value>master:8031</value>
    </property>
    <property>
        <name>yarn.resourcemanager.admin.address</name>
        <value>master:8033</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>master:8088</value>
    </property>
</configuration>



cnt-cls-m2> $HADOOP_HOME/etc/hadoop/workers



Создайте директории, необходимые Hadoop:

mkdir -p $HADOOP_HOME/tmp
mkdir -p $HADOOP_HOME/hdfs/name
mkdir -p $HADOOP_HOME/hdfs/data
Скопируйте дерево Hadoop и файлы параметров окружения на slave-узлы:

scp ~/.bashrc slave1:~/
scp ~/.bashrc slave2:~/

scp -r ~/hadoop-2.7.7 slave1:~/
scp -r ~/hadoop-2.7.7 slave2:~/


Запуск кластера Hadoop
Отформатируйте HDFS:

hdfs namenode -format
Запустите распределенную файловую систему DFS:

start-dfs.sh
Запустите распределенную вычислительную систему YARN:

start-yarn.sh
Для остановки кластера Hadoop выполните:

stop-yarn.sh
stop-dfs.sh


Проверка состояния кластера
На каждом узле запустите команду jps. Убедитесь, что возвращается успешный ответ.

Успешный ответ jps на узле master:

# jps
32967 NameNode
33225 Jps
32687 ResourceManager
На узле slave1:

# jps
28227 SecondaryNameNode
28496 Jps
28179 DataNode
28374 NodeManager
На узле slave2:

# jps
27680 DataNode
27904 Jps
27784 NodeManager
Для детального мониторинга состояния кластера воспользуйтесь веб-интерфейсами Hadoop:

192.168.171.132:50070 — для просмотра состояния хранилища HDFS.
192.168.171.132:8088 — для просмотра ресурсов YARN и состояния приложений.




Service |	Servers |	Default Ports Used |	Protocol |	Description |	Need End User Access? |	Configuration Parameters
:------:|:-------:|:------------------:|:---------:|:------------:|:---------------------:|:-----------------------:
NameNode WebUI |	Master Nodes (NameNode / NameNodes) |	50070 / 50470 |	http / https |	Web UI для просмотра статуса HDFS |	Да (обычно для администраторов / разработчиков / группы поддержки) |	dfs.http.address / dfs.https.address
NameNode metadata service |	Master Nodes (NameNode / NameNodes) |	8020/9000 |	IPC |	Операции над файловой системой |	Да (для всех пользователей) |	fs.default.name
DataNode | All Nodes |	50075 / 50475 |	http / https |	DataNode WebUI для доступа к статусам и логам |	Да (обычно для администраторов / разработчиков / группы поддержки) |	dfs.datanode.http.address / dfs.datanode.https.address
DataNode | All Nodes |	50010 |	 |	Трансфер данных |	 |	dfs.datanode.address
DataNode | All Nodes | 50020 |	IPC |	Операции с данными / метаданными |	Нет |	dfs.datanode.ipc.address
Secondary NameNode | Secondary NameNode / Secondary NameNode | 50090 | http | Checkpoint для NameNode | Нет | dfs.secondary.http.address
JobTracker | WebUI Master Nodes | 50030 | http | Web UI для JobTracker | Да | mapred.job.tracker.http.address
JobTracker | Master Nodes | 8021 | IPC | Для обзора джобов | Да ( для все клиентов, кто запускает MapReduce jobs (включая Hive, Hive server, Pig)) | mapred.job.tracker
Task­Tracker | Web UI и Shuffle | 50060 | http | DataNode Web UI для доступа к статусам и логам |	Да (обычно для администраторов / разработчиков / группы поддержки) | mapred.task.tracker.http.address
History Server WebUI | | 51111 | http | Web UI для Job History | Да | mapreduce.history.server.http.address
Hive Server2 | Hive Server machine | 10000 | thrift | Сервис для соединения к Hive | Да (для тех, кто хочет подсоединиться к Hive по UI SQL используя JDBC) | переменная среды HIVE_PORT
Hive | Metastore | 9083 | thrift |  | Да | hive.metastore.uris





# Spark

cd /opt
wget https://archive.apache.org/dist/spark/spark-3.0.0/spark-3.0.0-bin-hadoop3.2.tgz
tar -xzf spark-3.0.0-bin-hadoop3.2.tgz
rm spark-3.0.0-bin-hadoop3.2.tar.gz
mv spark-3.0.0-bin-hadoop3.2 /opt/spark3
chmod 775 spark3


# добавляем переменные среды
export SPARK_HOME=/opt/spark3
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
export SPARK_DIST_CLASSPATH=$(/opt/hadoop3/bin/hadoop classpath)


#pyspark2
pip3 install pyspark
pip3 install py4j

добавляем переменные среды
PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.8.1-src.zip



# запускаем
start-master.sh

start-slave.sh spark://cnt-cls-m1:7070



# jupyterhub

устанавливаем [jupyterhub](https://jupyterhub.readthedocs.io/en/latest/installation-guide.html)
[infa](https://habr.com/ru/company/yandex/blog/353546/)


yum install install npm nodejs-legacy

pip3 install jupyterhub
npm install -g configurable-http-proxy


создаем конфиг:
jupyterhub --generate-config

добавляем параметры

## The base URL of the entire application.
c.JupyterHub.base_url = '/'

c.JupyterHub.bind_url = 'http://78.47.61.181:8765'

## The class to use for spawning single-user servers.

#  Currently installed:
#    - default: jupyterhub.spawner.LocalProcessSpawner
#    - localprocess: jupyterhub.spawner.LocalProcessSpawner
#    - simple: jupyterhub.spawner.SimpleLocalProcessSpawner
c.JupyterHub.spawner_class = 'jupyterhub.spawner.SimpleLocalProcessSpawner'


## Extra arguments to be passed to the single-user server.
#
#  Some spawners allow shell-style expansion here, allowing you to use
#  environment variables here. Most, including the default, do not. Consult the
#  documentation for your spawner to verify!
c.Spawner.args = ['--allow-root', '--debug', '--profile=PHYS131']

c.Authenticator.admin_users = {'добавляем админов кластера',}
c.Authenticator.whitelist = {список пользователей Linux, которые будут заходить на jupyterhub}

c.ConfigurableHTTPProxy.api_url='http://10.0.0.2:8108'

c.JupyterHub.proxy_api_ip = '10.0.0.2'
c.JupyterHub.proxy_api_port = 5678
c.JupyterHub.hub_ip = '10.0.0.2'
c.JupyterHub.hub_port = 5678


c.YarnSpawner.environment = {
    'PYTHONPATH': 'opt/spark2/python',
        'SPARK_CONF_DIR': '/opt/spark2/conf'
        }


# вишинка
кластер Ipython
https://github.com/ipython/ipyparallel



# создаем kernel в jupyterhub для pyspark

### This gist explains how to connect jupyterhub with Spark2 on CDH 5.13 Cluster.
/usr/share/jupyter/kernels/pyspark2/kernel.json

    {
      "argv": [
        "python3.6",
        "-m",
        "ipykernel_launcher",
        "-f",
        "{connection_file}"
      ],
      "display_name": "Python3.6 + Pyspark(Spark 3.0)",
      "language": "python",
      "env": {
        "PYSPARK_PYTHON": "/usr/bin/python3.6",
        "SPARK_HOME": "/opt/cloudera/parcels/SPARK2/lib/spark2",
        "HADOOP_CONF_DIR": "/etc/spark2/conf/yarn-conf",
        "HADOOP_CLIENT_OPTS": "-Xmx2147483648 -XX:MaxPermSize=512M -Djava.net.preferIPv4Stack=true",
        "PYTHONPATH": "/opt/cloudera/parcels/SPARK2/lib/spark2/python/lib/py4j-0.10.4-src.zip:/opt/cloudera/parcels/SPARK2/lib/spark2/python/",
        "PYTHONSTARTUP": "/opt/cloudera/parcels/SPARK2/lib/spark2/python/pyspark/shell.py",
        "PYSPARK_SUBMIT_ARGS": " --master yarn --deploy-mode client pyspark-shell"
      }
    }


    --master MASTER_URL         spark://host:port, mesos://host:port, yarn,
                                  k8s://https://host:port, or local (Default: local[*]).
      --deploy-mode DEPLOY_MODE   Whether to launch the driver program locally ("client") or
                                  on one of the worker machines inside the cluster ("cluster")
                                  (Default: client).
      --class CLASS_NAME          Your application's main class (for Java / Scala apps).
      --name NAME                 A name of your application.
      --jars JARS                 Comma-separated list of jars to include on the driver
                                  and executor classpaths.
      --packages                  Comma-separated list of maven coordinates of jars to include
                                  on the driver and executor classpaths. Will search the local
                                  maven repo, then maven central and any additional remote
                                  repositories given by --repositories. The format for the
                                  coordinates should be groupId:artifactId:version.
      --exclude-packages          Comma-separated list of groupId:artifactId, to exclude while
                                  resolving the dependencies provided in --packages to avoid
                                  dependency conflicts.
      --repositories              Comma-separated list of additional remote repositories to
                                  search for the maven coordinates given with --packages.
      --py-files PY_FILES         Comma-separated list of .zip, .egg, or .py files to place
                                  on the PYTHONPATH for Python apps.
      --files FILES               Comma-separated list of files to be placed in the working
                                  directory of each executor. File paths of these files
                                  in executors can be accessed via SparkFiles.get(fileName).

      --conf, -c PROP=VALUE       Arbitrary Spark configuration property.
      --properties-file FILE      Path to a file from which to load extra properties. If not
                                  specified, this will look for conf/spark-defaults.conf.

      --driver-memory MEM         Memory for driver (e.g. 1000M, 2G) (Default: 1024M).
      --driver-java-options       Extra Java options to pass to the driver.
      --driver-library-path       Extra library path entries to pass to the driver.
      --driver-class-path         Extra class path entries to pass to the driver. Note that
                                  jars added with --jars are automatically included in the
                                  classpath.

      --executor-memory MEM       Memory per executor (e.g. 1000M, 2G) (Default: 1G).

      --proxy-user NAME           User to impersonate when submitting the application.
                                  This argument does not work with --principal / --keytab.

      --help, -h                  Show this help message and exit.
      --verbose, -v               Print additional debug output.
      --version,                  Print the version of current Spark.

     Cluster deploy mode only:
      --driver-cores NUM          Number of cores used by the driver, only in cluster mode
                                  (Default: 1).

     Spark standalone or Mesos with cluster deploy mode only:
      --supervise                 If given, restarts the driver on failure.
      --kill SUBMISSION_ID        If given, kills the driver specified.
      --status SUBMISSION_ID      If given, requests the status of the driver specified.

     Spark standalone and Mesos only:
      --total-executor-cores NUM  Total cores for all executors.

     Spark standalone and YARN only:
      --executor-cores NUM        Number of cores per executor. (Default: 1 in YARN mode,
                                  or all available cores on the worker in standalone mode)

     YARN-only:
      --queue QUEUE_NAME          The YARN queue to submit to (Default: "default").
      --num-executors NUM         Number of executors to launch (Default: 2).
                                  If dynamic allocation is enabled, the initial number of
                                  executors will be at least NUM.
      --archives ARCHIVES         Comma separated list of archives to be extracted into the
                                  working directory of each executor.
      --principal PRINCIPAL       Principal to be used to login to KDC, while running on
                                  secure HDFS.
      --keytab KEYTAB             The full path to the file that contains the keytab for the
                                  principal specified above. This keytab will be copied to
                                  the node running the Application Master via the Secure
                                  Distributed Cache, for renewing the login tickets and the
                                  delegation tokens periodically.



команды

# stop all services: for service in /etc/init.d/hadoop-hdfs-*; do $service stop; done;
clear cache from cache directory: sudo rm -rf /var/lib/hadoop-hdfs/cache/*
reformat name node: sudo -u hdfs hdfs namenode -format
start all services: for service in /etc/init.d/hadoop-hdfs-*; do $service start; done;
check status: for service in /etc/init.d/hadoop-hdfs-*; do $service status; done;
