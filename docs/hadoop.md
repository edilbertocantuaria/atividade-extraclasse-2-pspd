# Documentação Técnica - Hadoop

> 🚀 **Para instruções de execução**, consulte **[como_executar.md](../como_executar.md)**

> Esta documentação contém detalhes técnicos sobre arquitetura e configurações Hadoop.

## 🏗️ Arquitetura

### Topologia do Cluster

```
┌─────────────────┐
│  hadoop-master  │
│  - NameNode     │
│  - ResourceMgr  │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼──┐  ┌──▼───┐
│worker1│  │worker2│
│DataNode│ │DataNode│
│NodeMgr │ │NodeMgr │
└───────┘  └───────┘
```

### Componentes

- **1 Master Node**: 
  - HDFS NameNode (gerencia metadados)
  - YARN ResourceManager (orquestração de jobs)

- **2 Worker Nodes**:
  - HDFS DataNode (armazenamento)
  - YARN NodeManager (execução de tasks)

- **Rede**: `hadoop-net` (bridge)

## ⚙️ Configurações

### core-site.xml
```xml
<property>
  <name>fs.defaultFS</name>
  <value>hdfs://master:9000</value>
</property>
```

### hdfs-site.xml
```xml
<property>
  <name>dfs.replication</name>
  <value>2</value>
</property>
<property>
  <name>dfs.blocksize</name>
  <value>134217728</value> <!-- 128MB -->
</property>
```

### mapred-site.xml
```xml
<property>
  <name>mapreduce.framework.name</name>
  <value>yarn</value>
</property>
```

### yarn-site.xml
```xml
<property>
  <name>yarn.nodemanager.aux-services</name>
  <value>mapreduce_shuffle</value>
</property>
<property>
  <name>yarn.resourcemanager.hostname</name>
  <value>master</value>
</property>
<property>
  <name>yarn.nodemanager.resource.memory-mb</name>
  <value>2048</value>
</property>
```

## 🔧 Operações Comuns

### Iniciar Cluster
```bash
./scripts/setup.sh
```

### Verificar Status
```bash
# Via web UI
http://localhost:9870  # HDFS
http://localhost:8088  # YARN

# Via linha de comando
docker exec hadoop-master hdfs dfsadmin -report
docker exec hadoop-master yarn node -list
```

### Comandos HDFS Úteis
```bash
# Listar arquivos
docker exec hadoop-master hdfs dfs -ls /

# Upload de arquivo
docker exec hadoop-master hdfs dfs -put /local/file /hdfs/path

# Download de arquivo
docker exec hadoop-master hdfs dfs -get /hdfs/path /local/file

# Ver conteúdo
docker exec hadoop-master hdfs dfs -cat /hdfs/file

# Remover arquivo/diretório
docker exec hadoop-master hdfs dfs -rm -r /hdfs/path
```

### Executar Job MapReduce
```bash
docker exec hadoop-master hadoop jar \
  /home/hadoop/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
  wordcount \
  /user/hadoop/input \
  /user/hadoop/output
```

## 🧪 Testes de Configuração

O projeto inclui 4 testes automatizados que avaliam o impacto de diferentes configurações:

### Teste 1: Memória YARN
- **Configuração**: `yarn.nodemanager.resource.memory-mb = 1024`
- **Objetivo**: Avaliar impacto da redução de memória
- **Arquivo**: `config/teste1_memoria/yarn-site.xml`

### Teste 2: Replicação HDFS
- **Configuração**: `dfs.replication = 1`
- **Objetivo**: Avaliar performance sem redundância
- **Arquivo**: `config/teste2_replicacao/hdfs-site.xml`

### Teste 3: Block Size
- **Configuração**: `dfs.blocksize = 67108864` (64MB)
- **Objetivo**: Avaliar impacto de blocos menores
- **Arquivo**: `config/teste3_blocksize/hdfs-site.xml`

### Teste 4: Número de Reducers
- **Configuração**: `mapreduce.job.reduces = 4`
- **Objetivo**: Avaliar paralelização na fase de reduce
- **Arquivo**: `config/teste4_reducers/mapred-site.xml`

## 🔍 Troubleshooting

### Cluster não inicia
```bash
# Verificar logs
docker logs hadoop-master
docker logs hadoop-worker1

# Reiniciar contêineres
./scripts/cleanup.sh
./scripts/setup.sh
```

### NameNode não formata
```bash
# Limpar dados antigos
docker exec hadoop-master rm -rf /tmp/hadoop-hadoop/dfs/name/*
docker exec hadoop-master hdfs namenode -format -force
```

### DataNode não conecta
```bash
# Verificar cluster ID
docker exec hadoop-master cat /tmp/hadoop-hadoop/dfs/name/current/VERSION
docker exec hadoop-worker1 cat /tmp/hadoop-hadoop/dfs/data/current/VERSION

# Se diferentes, limpar datanodes
docker exec hadoop-worker1 rm -rf /tmp/hadoop-hadoop/dfs/data/*
docker exec hadoop-worker2 rm -rf /tmp/hadoop-hadoop/dfs/data/*
```

### Job fica travado
```bash
# Verificar recursos YARN
docker exec hadoop-master yarn node -list
docker exec hadoop-master yarn application -list

# Matar job
docker exec hadoop-master yarn application -kill <application_id>
```

## 📊 Monitoramento

### HDFS Health
```bash
docker exec hadoop-master hdfs dfsadmin -report
```

Verifique:
- Live datanodes (deve ser 2)
- DFS Used%
- Block pool used

### YARN Resources
```bash
docker exec hadoop-master yarn node -list
```

Verifique:
- Node state (RUNNING)
- Available memory
- Available vcores

## 🔐 Segurança

Este cluster é configurado para **desenvolvimento/testes apenas**:
- Sem autenticação
- Sem criptografia
- Portas expostas localmente

Para produção, configure:
- Kerberos
- SSL/TLS
- Firewall
- ACLs

## 📚 Referências

- [Hadoop Documentation](https://hadoop.apache.org/docs/)
- [HDFS Architecture](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html)
- [YARN Architecture](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/YARN.html)
