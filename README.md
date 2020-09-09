# Apache Cluster for Big Data

> Репозиторий для описания процесса установки кластера для продуктов Apache Big Data


# Содержание


### Состав тестового кластера

**IP адрес** | **Имя узла** | **Роли**
:-----------:|:------------:|:-----------------------------
10.0.0.2     | cnt-cls-m1       | NameNode, ResourceManager
10.0.0.3     | cnt-cls-s1       | SecondaryNameNode, DataNode, NodeManager
10.0.0.4     | cnt-cls-s2       | DataNode
10.0.0.5     | cnt-cls-s3       | DataNode

* каждый узел на Linux Centos 7
* имеет внешней IP (префикс узла pub-) и внутренний адрес (10.0.0.0)
* Java 8, Scala 12, Python3.6


> Изменить hostname ```hostnamectl set-hostname cnt-cls-m1``` (для всех узлов)
> Добавить адреса в hosts ```echo '10.0.0.2 cnt-cls-m1' >> /etc/hosts``` (для всех узлов)

## Подготовительная работа

1. Выключаем SELinux
```bash
$ sudo setenforce 0
```
В файле `/etc/selinux/config` меняем конфигурацию `SELINUX=disabled` и перезагружаем систему
```bash
shutdown -r now
```

2. Устанавливаем нужное допольнительное ПО
```bash
yum install -y net-tools openssh-server wget epel-release
yum install ntp ntpdate ntp-doc -y
yum install openssl
yum install -y zookeeper
yum install -y zookeeper-server
```
ntp - нужен для синхронизации внутренних часов [ntp на вики wiki](https://ru.wikipedia.org/wiki/NTP) и [ntp попробовать написать самому](https://habr.com/ru/post/448060/#:~:text=NTP%20%E2%80%93%20%D0%BF%D1%80%D0%BE%D1%82%D0%BE%D0%BA%D0%BE%D0%BB%20%D0%B2%D0%B7%D0%B0%D0%B8%D0%BC%D0%BE%D0%B4%D0%B5%D0%B9%D1%81%D1%82%D0%B2%D0%B8%D1%8F%20%D1%81%20%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0%D0%BC%D0%B8,%D1%81%D1%83%D1%89%D0%B5%D1%81%D1%82%D0%B2%D1%83%D0%B5%D1%82%205%20%D0%B2%D0%B5%D1%80%D1%81%D0%B8%D0%B9%20NTP%20%D0%BF%D1%80%D0%BE%D1%82%D0%BE%D0%BA%D0%BE%D0%BB%D0%B0.)


3. Устанавливаем **Java**
```bash
yum install -y java-1.8.0-openjdk.x86_64 java-1.8.0-openjdk-devel.x86_64
# создать файл /etc/profile.d/java.sh и добавить
export JAVA_HOME=/usr/lib/jvm/java-openjdk
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=$JAVA_HOME/lib:.
export PATH=$PATH:$JAVA_HOME/bin
```

4. Устанавливаем Scala
```bash
wget http://www.scala-lang.org/files/archive/scala-2.12.11.tgz
tar -xvf scala-2.12.11.tgz
mv scala-2.12.11 /usr/lib
ln -s /usr/lib/scala-2.12.11 /usr/lib/scala
```

5. Нужно сделать `ssh ключ` и копировать его публичную часть на все узлы
```bash
ssh-keygen -t rsa -b 4096
ssh-copy-id *имя узла*
```

6. Для работы с Hadoop (его запуска) нужен новый пользователь, так как root не рекомендуемый пользователь.
> `Из hadoop tutorial`: The user who owns the Hadoop instances will need to have read and write access to each of these directories. It is not necessary for all users to have access to these directories. Set permissions with chmod as appropriate. In a large-scale environment, it is recommended that you create a user named "hadoop" on each node for the express purpose of owning and running Hadoop tasks. For a single individual's machine, it is perfectly acceptable to run Hadoop under your own username. It is not recommended that you run Hadoop as root.
```bash
sudo groupadd hadoop
sudo useradd -d /home/hadoop -g hadoop hadoop
sudo passwd hadoop
```


7. Спорный шаг, но для первого и быстро запуска это сделать можно (потом надо будет настраивать правила)
```bash
# отключаем firewall
sudo systemctl stop firewalld.service
sudo systemctl disable firewalld.service
# если у вас iptables
disable ip table
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
```


## Установка Hadoop

1. Переходим в созданного пользователь ```su - hadoop```

2. Скачиваем Hadoop
```bash
cd /opt
wget http://mirror.linux-ia64.org/apache/hadoop/common/hadoop-3.2.1/hadoop-3.2.1.tar.gz
tar -xvf hadoop-3.2.1.tar.gz
rm hadoop-3.2.1.tar.gz
mv hadoop-3.2.1 /opt/hadoop3
chmod 775 hadoop3
```


3.Добавляем переменные среды в `.bashrc` $HADOOP_HOME
```bash
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
```

4. Редактируем файлы в /opt/hadoop3/etc/hadoop/
* core-site.xml
* hdfs-site.xml
* mapred-site.xml
* yarn-site.xml

5. Добавляем имена хостов в файл `workers` (в hadoop2: masters, slaves)
```
cnt-cls-m1> $HADOOP_HOME/etc/hadoop/workers
cnt-cls-m2> $HADOOP_HOME/etc/hadoop/workers
cnt-cls-m3> $HADOOP_HOME/etc/hadoop/workers
cnt-cls-m4> $HADOOP_HOME/etc/hadoop/workers
```

6. Создайте директории, которые мы указали в настройках Hadoop:
```bash
mkdir -p $HADOOP_HOME/tmp
mkdir -p $HADOOP_HOME/hdfs/name
mkdir -p $HADOOP_HOME/hdfs/data
```

7. Скопируйте дерево Hadoop и файлы параметров окружения на узлы:
```bash
scp ~/.bashrc cnt-cls-m2:~/ #(для всех 2, 3, 4)
scp -r /opt/hadoop3/etc/hadoop/ cnt-cls-m2:/opt/hadoop3/etc/ #(для всех 2, 3, 4)
```

--------------------------------

## Расположение всех параметров с их базовыми портами

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



--------------------------------
## Запуск кластера Hadoop

1. Отформатируйте HDFS (не root пользователем, мы работаем c пользователем hadoop)
```bush
hdfs namenode -format
```

2. Запустите распределенную файловую систему DFS:
```
start-dfs.sh
```

3. Запустите распределенную вычислительную систему YARN:
```
start-yarn.sh
```

4. Проверим состояния кластера. На каждом узле запустите команду jps. Надо убедиться, что возвращается успешный ответ.
* Успешный ответ jps на узле cnt-cls-m1:
-- NameNode
-- Jps
-- ResourceManager
* На остальных узлах:
-- DataNode
-- NodeManager

5. Для детального мониторинга состояния кластера воспользуйтесь веб-интерфейсами Hadoop:
* pub-cnt-cls-m1:50070 — для просмотра состояния хранилища HDFS.
* pub-cnt-cls-m1:8088 — для просмотра ресурсов YARN и состояния приложений.


> Для остановки кластера Hadoop выполните: ```stop-yarn.sh``` и  ```stop-dfs.sh```

-----------------------------------


## Spark

1. Скачиваем Spark
```bash
cd /opt
wget https://archive.apache.org/dist/spark/spark-3.0.0/spark-3.0.0-bin-hadoop3.2.tgz
tar -xzf spark-3.0.0-bin-hadoop3.2.tgz
rm spark-3.0.0-bin-hadoop3.2.tar.gz
mv spark-3.0.0-bin-hadoop3.2 /opt/spark3
chmod 775 spark3
```

2. Добавляем переменные среды в `.bashrc`
```bash
export SPARK_HOME=/opt/spark3
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
export SPARK_DIST_CLASSPATH=$(/opt/hadoop3/bin/hadoop classpath)
```

3. Устанавливаем pyspark2
```bash
pip3 install pyspark
pip3 install py4j
```


4. Lобавляем переменные среды  в `.bashrc`
```bash
PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.8.1-src.zip
```

5. Создаем файл в spark - /opt/spark3/conf/spark-env.sh
```bash
SPARK_LOCAL_IP=cnt-cls-m1
SPARK_MASTER_IP=pub-cnt-cls-m1
SPARK_MASTER_HOST=cnt-cls-m1
SPARK_MASTER_PORT=7070
PYSPARK_PYTHON=/usr/bin/python3
PYSPARK_DRIVER_PYTHON=/usr/bin/python3
```


--------------------

## запускаем spark
* `start-master.sh`
* `start-slave.sh spark://cnt-cls-m1:7070`  (выполнить на каждой ноде)
* Для тестирования работоспособноси можно запустить в командной строке pyspark

------------------

## jupyterhub

1. Устанавливаем [jupyterhub](https://jupyterhub.readthedocs.io/en/latest/installation-guide.html). [Здесь](https://habr.com/ru/company/yandex/blog/353546/) можно посмотреть информацию о его использовании
```bash
yum install install npm nodejs-legacy
pip3 install jupyterhub
npm install -g configurable-http-proxy
```

2. Cоздаем конфиг:
```bash
jupyterhub --generate-config
```

3. Добавляем параметры (их надо избавить от комментов, так как мы уже создали шаблон) в файл jupyterhub_config.py
```python
# базовый путь и публичный IP адрес для хаба
c.JupyterHub.base_url = '/'
c.JupyterHub.bind_url = 'http://pub-cnt-cls-m1:8765'
# если планируется использование более чем для 1 пользователя
c.JupyterHub.spawner_class = 'jupyterhub.spawner.SimpleLocalProcessSpawner'
c.Spawner.args = ['--allow-root', '--debug', '--profile=PHYS131']
# пользователь в linux- это пользователь в jupyterhub
c.Authenticator.admin_users = {'добавляем админов кластера',}
c.Authenticator.whitelist = {список пользователей Linux, которые будут заходить на jupyterhub}
# так как у нас кластер на внутренней сети, то добавляем параметр прокси
# localhost (127.0.0.1) меняем на внутрению сеть
c.ConfigurableHTTPProxy.api_url='http://10.0.0.2:8108'
c.JupyterHub.proxy_api_ip = '10.0.0.2'
c.JupyterHub.proxy_api_port = 5678
c.JupyterHub.hub_ip = '10.0.0.2'
c.JupyterHub.hub_port = 5678
# переменные серды для spark окружения в jupyterhub
c.YarnSpawner.environment = {
    'PYTHONPATH': 'opt/spark3/python',
    'SPARK_CONF_DIR': '/opt/spark3/conf'
        }
```

> Дополнение. Если вы хотите использовать Ipython в виде кластреа, то вы можете разобраться с **ipyparallel**, ознакомьтесь с [Ipython](https://github.com/ipython/ipyparallel)



## kernel в jupyterhub для pyspark

1. Найдите расположение `kernels`. В нашей установке это путь `/usr/share/jupyter/kernels/`

2. Создайте новую папку и файл `pyspark3/kernel.json`

3. Заполните `kernel.json`
```json
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
    "SPARK_HOME": "/opt/spark3",
    "HADOOP_CONF_DIR": "/etc/spark3/conf/yarn-conf",
    "HADOOP_CLIENT_OPTS": "-Xmx2147483648 -XX:MaxPermSize=512M -Djava.net.preferIPv4Stack=true",
    "PYTHONPATH": "/opt/spark3/python/lib/py4j-0.10.4-src.zip:/opt/spark3/python/",
    "PYTHONSTARTUP": "/opt/spark3/python/pyspark/shell.py",
    "PYSPARK_SUBMIT_ARGS": " --master yarn --deploy-mode client pyspark-shell"
  }
}
```

4. Параметры, которые вы можете передать в ARGS:
* `--master MASTER_URL` - в формате spark://host:port, где указан ваш адрес master
* `--deploy-mode DEPLOY_MODE` - (если локальный запуск - client, если внутри кластера - cluster
* `--properties-file FILE` - передать файл с дополнительным конфигом (пример в conf/spark-defaults.conf)
* `--driver-memory MEM` - установить количество ОЗУ для драйвера (в базе 1G)
* `--executor-memory MEM` - установить количество ОЗУ для экзекьютора (в базе 1G)
* `--driver-cores NUM` - установить кол-во ядер для драйвера (в базе 1)
* `--executor-cores NUM` - установить кол-во ядер для экзекьютора (работает в yarn)
* `--total-executor-cores NUM` - установить максимальное кол-во ядер для экзекьюторов (работает локально и в mesos)
* `--num-executors` - установить кол-во экзекьюторов (работает в yarn)
* `--queue QUEUE_NAME` - определяет имя очереди в которой будет данный джоб.

------------------------------

## Команды

Можно написать себе команды для быстрого старта - перезагрузки, по примеру

```bash
# stop all services
for service in /etc/init.d/hadoop-hdfs-*;
   do
      $service stop;
   done;
# clear cache from cache directory
rm -rf /opt/hadoop3/hdfs/cache/*
# reformat name node
hdfs hdfs namenode -format
#start all services
for service in /etc/init.d/hadoop-hdfs-*;
  do
    $service start;
  done;
#check status
for service in /etc/init.d/hadoop-hdfs-*;
   do
      $service status;
   done;
```
