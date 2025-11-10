#!/bin/bash

echo "🔧 Recriando TODOS os arquivos XML com configuração correta..."
echo ""

HADOOP_DIR="$(dirname "$0")/../hadoop"

# Função para criar XML correto
criar_core_site() {
    local node=$1
    cat > "$HADOOP_DIR/$node/core-site.xml" << 'EOF'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://master:9000</value>
    </property>
</configuration>
EOF
    echo "✅ $node/core-site.xml"
}

criar_hdfs_site() {
    local node=$1
    cat > "$HADOOP_DIR/$node/hdfs-site.xml" << 'EOF'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
</configuration>
EOF
    echo "✅ $node/hdfs-site.xml"
}

criar_mapred_site() {
    local node=$1
    cat > "$HADOOP_DIR/$node/mapred-site.xml" << 'EOF'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
EOF
    echo "✅ $node/mapred-site.xml"
}

criar_yarn_site() {
    local node=$1
    cat > "$HADOOP_DIR/$node/yarn-site.xml" << 'EOF'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>master</value>
    </property>
</configuration>
EOF
    echo "✅ $node/yarn-site.xml"
}

echo "Recriando arquivos do MASTER..."
criar_core_site "master"
criar_hdfs_site "master"
criar_mapred_site "master"
criar_yarn_site "master"

echo ""
echo "Recriando arquivos do WORKER1..."
criar_core_site "worker1"
criar_hdfs_site "worker1"
criar_mapred_site "worker1"
criar_yarn_site "worker1"

echo ""
echo "Recriando arquivos do WORKER2..."
criar_core_site "worker2"
criar_hdfs_site "worker2"
criar_mapred_site "worker2"
criar_yarn_site "worker2"

echo ""
echo "✅ Todos os arquivos XML foram recriados com sucesso!"
echo ""
echo "Execute a validação:"
echo "  ./scripts/validar_config_xml.sh"
