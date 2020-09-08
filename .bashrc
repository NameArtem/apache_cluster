# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# understandable command line
export PS1="\[\033[36m\]\u\[\033[m\]@[\033[33m\] \[\033[33;1m\]\w\[\033[m\] [\$(git branch 2>/dev/null | grep '^*' | colrm 1 2)]\$"


# new color mc
alias mc='mc -S darkfar'
alias mcedit='mcedit -S darkfar'
alias mcview='mcview -S darkfar'
alias mcdiff='mcdiff -S darkfar'


# npn proxy

export PATH=$PATH:$(pwd)/node_modules/.bin


# jupyterhub
#
alias jupyterhub='jupyterhub -f ~/jupyterhub_config.py'


# hadoop
export HADOOP_HOME=/opt/hadoop3
#export HADOOP_PREFIX=$HADOOP_HOME/libexec
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



# spark
export SPARK_HOME=/opt/spark3
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
export SPARK_DIST_CLASSPATH=$(/opt/hadoop3/bin/hadoop classpath)


# python3
export PYSPARK_PYTHON='/usr/bin/python3'
