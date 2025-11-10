FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME=/home/hadoop/hadoop
ENV PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

RUN apt-get update && \
    apt-get install -y openssh-server openssh-client openjdk-8-jdk wget && \
    mkdir /run/sshd

RUN useradd -m -s /bin/bash hadoop && \
    echo "hadoop:hadoop" | chpasswd && \
    adduser hadoop sudo

RUN mkdir -p /home/hadoop/hadoop && \
    wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && \
    tar -xzf hadoop-3.3.6.tar.gz -C /home/hadoop/hadoop --strip-components=1 && \
    rm hadoop-3.3.6.tar.gz

RUN chown -R hadoop:hadoop /home/hadoop/hadoop

# Configurar JAVA_HOME no hadoop-env.sh
RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh && \
    echo 'export HADOOP_HOME=/home/hadoop/hadoop' >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh && \
    echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh && \
    chown hadoop:hadoop /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh

USER hadoop
RUN ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

USER root
RUN mkdir -p /tmp/hadoop-hadoop/dfs/name && \
    mkdir -p /tmp/hadoop-hadoop/dfs/data && \
    chown -R hadoop:hadoop /tmp/hadoop-hadoop

CMD ["/usr/sbin/sshd", "-D"]
