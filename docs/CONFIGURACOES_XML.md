# Documentação de Arquivos de Configuração Hadoop

## Visão Geral

Este documento detalha todos os arquivos de configuração XML utilizados no cluster Hadoop, explicando o papel de cada arquivo e os parâmetros alterados nos testes.

---

## 1. Arquivos de Configuração Base (hadoop/master/ e hadoop/worker*)

### 1.1 core-site.xml

**Papel**: Configurações centrais do Hadoop, incluindo URI do HDFS e diretórios temporários.

**Parâmetros Principais**:

| Parâmetro | Valor Padrão | Descrição | Impacto |
|-----------|--------------|-----------|---------|
| `fs.defaultFS` | `hdfs://master:9000` | URI do NameNode HDFS | Define onde o HDFS está localizado |
| `hadoop.tmp.dir` | `/opt/hadoop/tmp` | Diretório temporário base | Armazena dados temporários de jobs |
| `io.file.buffer.size` | `131072` (128KB) | Buffer para operações I/O | Maior = melhor performance, mais RAM |

**Exemplo**:
```xml
<property>
    <name>fs.defaultFS</name>
    <value>hdfs://master:9000</value>
    <description>URI do NameNode HDFS</description>
</property>
```

**Quando Alterar**:
- Mudar porta do HDFS
- Ajustar tamanho de buffer para otimizar I/O

---

### 1.2 hdfs-site.xml

**Papel**: Configurações específicas do HDFS (replicação, block size, diretórios de dados).

**Parâmetros Principais**:

| Parâmetro | Valor Baseline | Descrição | Impacto |
|-----------|----------------|-----------|---------|
| `dfs.replication` | `2` | Fator de replicação de blocos | Maior = mais redundância, mais espaço usado |
| `dfs.blocksize` | `134217728` (128MB) | Tamanho dos blocos HDFS | Maior = menos map tasks, menos metadata |
| `dfs.namenode.name.dir` | `file:///opt/hadoop/data/namenode` | Diretório do NameNode | Metadados do HDFS |
| `dfs.datanode.data.dir` | `file:///opt/hadoop/data/datanode` | Diretório dos DataNodes | Blocos de dados |
| `dfs.permissions.enabled` | `false` | Permissões POSIX no HDFS | false simplifica testes |

**Exemplo**:
```xml
<property>
    <name>dfs.replication</name>
    <value>2</value>
    <description>Cada bloco é replicado em 2 DataNodes</description>
</property>

<property>
    <name>dfs.blocksize</name>
    <value>134217728</value>
    <description>Blocos de 128MB</description>
</property>
```

**Quando Alterar**:
- **Replicação**: Clusters pequenos (usar 1-2), clusters grandes (usar 3+)
- **Block Size**: Arquivos grandes (256MB+), arquivos pequenos (64MB)

**Variações nos Testes**:
- `config/teste2_replicacao/`: `dfs.replication = 1`
- `config/teste3_blocksize/`: `dfs.blocksize = 268435456` (256MB)

---

### 1.3 yarn-site.xml

**Papel**: Configurações do ResourceManager e NodeManagers (gerenciamento de recursos).

**Parâmetros Principais**:

| Parâmetro | Valor Baseline | Descrição | Impacto |
|-----------|----------------|-----------|---------|
| `yarn.resourcemanager.hostname` | `master` | Hostname do ResourceManager | Define onde o RM está |
| `yarn.nodemanager.resource.memory-mb` | `2048` | Memória total do NodeManager | Limita RAM disponível para containers |
| `yarn.scheduler.maximum-allocation-mb` | `2048` | Máximo de RAM por container | Containers não podem exceder |
| `yarn.scheduler.minimum-allocation-mb` | `512` | Mínimo de RAM por container | Granularidade de alocação |
| `yarn.nodemanager.resource.cpu-vcores` | `2` | VCores disponíveis | Paralelismo de tasks |
| `yarn.nodemanager.aux-services` | `mapreduce_shuffle` | Serviço auxiliar para shuffle | Necessário para MapReduce |

**Exemplo**:
```xml
<property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>2048</value>
    <description>2GB de RAM disponível para containers</description>
</property>

<property>
    <name>yarn.scheduler.maximum-allocation-mb</name>
    <value>2048</value>
    <description>Container pode alocar até 2GB</description>
</property>
```

**Quando Alterar**:
- **Memória**: Aumentar se máquina tem mais RAM (4GB, 8GB)
- **VCores**: Ajustar conforme CPUs disponíveis

**Variações nos Testes**:
- `config/teste1_memoria/`: 
  - `yarn.nodemanager.resource.memory-mb = 4096`
  - `yarn.scheduler.maximum-allocation-mb = 4096`

---

### 1.4 mapred-site.xml

**Papel**: Configurações do MapReduce (memória de tasks, reducers, execução especulativa).

**Parâmetros Principais**:

| Parâmetro | Valor Baseline | Descrição | Impacto |
|-----------|----------------|-----------|---------|
| `mapreduce.framework.name` | `yarn` | Framework de execução | Usar YARN para gerenciar jobs |
| `mapreduce.map.memory.mb` | `1024` | Memória para map tasks | Maior = menos OOM, mais RAM usado |
| `mapreduce.reduce.memory.mb` | `1024` | Memória para reduce tasks | Idem |
| `mapreduce.map.java.opts` | `-Xmx800m` | Opções JVM para maps | Heap size da JVM |
| `mapreduce.reduce.java.opts` | `-Xmx800m` | Opções JVM para reduces | Heap size da JVM |
| `mapreduce.job.reduces` | Automático | Número de reducers | Fixar para controlar paralelismo |
| `mapred.map.tasks.speculative.execution` | `false` | Execução especulativa de maps | true = duplica tasks lentas |
| `mapred.reduce.tasks.speculative.execution` | `false` | Execução especulativa de reduces | true = usa mais recursos |

**Exemplo**:
```xml
<property>
    <name>mapreduce.map.memory.mb</name>
    <value>1024</value>
    <description>1GB para cada map task</description>
</property>

<property>
    <name>mapreduce.job.reduces</name>
    <value>-1</value>
    <description>-1 = automático (baseado em tamanho de input)</description>
</property>
```

**Quando Alterar**:
- **Memória de tasks**: Aumentar se tasks falham com OOM
- **Reducers**: Fixar para controlar número de arquivos de saída
- **Speculative**: Ativar em clusters heterogêneos (nós com velocidades diferentes)

**Variações nos Testes**:
- `config/teste4_reducers/`: `mapreduce.job.reduces = 4`
- `config/teste5_speculative/`:
  - `mapred.map.tasks.speculative.execution = true`
  - `mapred.reduce.tasks.speculative.execution = true`

---

### 1.5 capacity-scheduler.xml

**Papel**: Configurações do escalonador de capacidade YARN (filas, limites de recursos).

**Parâmetros Principais**:

| Parâmetro | Valor | Descrição | Impacto |
|-----------|-------|-----------|---------|
| `yarn.scheduler.capacity.root.queues` | `default` | Filas disponíveis | Permite múltiplas filas |
| `yarn.scheduler.capacity.root.default.capacity` | `100` | Capacidade da fila default | % de recursos alocados |
| `yarn.scheduler.capacity.root.default.maximum-capacity` | `100` | Capacidade máxima | Limite elástico |

**Exemplo**:
```xml
<property>
    <name>yarn.scheduler.capacity.root.queues</name>
    <value>default</value>
    <description>Apenas fila 'default'</description>
</property>
```

**Quando Alterar**:
- Criar múltiplas filas para diferentes usuários/aplicações
- Definir limites de recursos por fila

**Variações nos Testes**: Não alterado (usa configuração padrão)

---

## 2. Configurações por Teste

### Teste 0 - Baseline (Referência)

**Diretório**: `hadoop/master/` e `hadoop/worker*/`

**Propósito**: Configuração padrão e balanceada para servir como referência.

**Valores Chave**:
- Memória YARN: 2048MB
- Replicação HDFS: 2
- Block Size: 128MB
- Reducers: Automático
- Speculative: Desabilitado

---

### Teste 1 - Variação de Memória YARN

**Diretório**: `config/teste1_memoria/`

**Arquivo Alterado**: `yarn-site.xml`

**Parâmetros Modificados**:

```xml
<property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>4096</value>
    <description>Dobrou de 2048MB para 4096MB</description>
</property>

<property>
    <name>yarn.scheduler.maximum-allocation-mb</name>
    <value>4096</value>
    <description>Container pode alocar até 4GB</description>
</property>
```

**Hipótese**: Mais memória permite mais containers simultâneos ou containers maiores.

**Esperado**:
- ✓ Mais map/reduce tasks paralelas
- ✓ Menos tempo de execução se houver RAM suficiente
- ✗ OOM se nó não tiver 4GB físicos disponíveis

**Link**: [yarn-site.xml](../config/teste1_memoria/yarn-site.xml)

---

### Teste 2 - Variação de Replicação HDFS

**Diretório**: `config/teste2_replicacao/`

**Arquivo Alterado**: `hdfs-site.xml`

**Parâmetros Modificados**:

```xml
<property>
    <name>dfs.replication</name>
    <value>1</value>
    <description>Reduzido de 2 para 1 (sem redundância)</description>
</property>
```

**Hipótese**: Menos replicação = menos escrita no HDFS = execução mais rápida.

**Esperado**:
- ✓ Economia de 50% de espaço em disco
- ✓ Escrita mais rápida (metade das operações)
- ✗ SEM REDUNDÂNCIA - perda de 1 DataNode = perda de dados

**Link**: [hdfs-site.xml](../config/teste2_replicacao/hdfs-site.xml)

---

### Teste 3 - Variação de Block Size

**Diretório**: `config/teste3_blocksize/`

**Arquivo Alterado**: `hdfs-site.xml`

**Parâmetros Modificados**:

```xml
<property>
    <name>dfs.blocksize</name>
    <value>268435456</value>
    <description>Aumentado de 128MB para 256MB</description>
</property>
```

**Hipótese**: Blocos maiores = menos map tasks = menos overhead de inicialização.

**Esperado**:
- ✓ ~50% menos map tasks
- ✓ Menos metadata no NameNode
- ✗ Menor paralelismo
- ✗ Pode ser subótimo para arquivos pequenos

**Link**: [hdfs-site.xml](../config/teste3_blocksize/hdfs-site.xml)

---

### Teste 4 - Variação de Reducers

**Diretório**: `config/teste4_reducers/`

**Arquivo Alterado**: `mapred-site.xml`

**Parâmetros Modificados**:

```xml
<property>
    <name>mapreduce.job.reduces</name>
    <value>4</value>
    <description>Fixado em 4 (vs automático)</description>
</property>
```

**Hipótese**: Número fixo de reducers pode otimizar fase de reduce.

**Esperado**:
- ✓ Controle explícito do paralelismo
- ✓ Exatamente 4 arquivos de saída
- ✗ Pode ser subótimo se dados não balancearem bem

**Link**: [mapred-site.xml](../config/teste4_reducers/mapred-site.xml)

---

### Teste 5 - Execução Especulativa

**Diretório**: `config/teste5_speculative/`

**Arquivo Alterado**: `mapred-site.xml`

**Parâmetros Modificados**:

```xml
<property>
    <name>mapred.map.tasks.speculative.execution</name>
    <value>true</value>
    <description>Ativado (vs false baseline)</description>
</property>

<property>
    <name>mapred.reduce.tasks.speculative.execution</name>
    <value>true</value>
    <description>Ativado</description>
</property>
```

**Hipótese**: Tasks especulativas compensam stragglers (tasks muito lentas).

**Esperado**:
- ✓ Reduz impacto de nós lentos
- ✓ Melhor tempo de execução em clusters heterogêneos
- ✗ Usa mais recursos (executa tasks redundantes)
- ✗ Pode desperdiçar recursos em clusters homogêneos

**Link**: [mapred-site.xml](../config/teste5_speculative/mapred-site.xml)

---

## 3. Guia de Referência Rápida

### 3.1 Onde Encontrar Cada Configuração

| Parâmetro | Arquivo | Localização |
|-----------|---------|-------------|
| URI do HDFS | core-site.xml | `fs.defaultFS` |
| Replicação | hdfs-site.xml | `dfs.replication` |
| Block Size | hdfs-site.xml | `dfs.blocksize` |
| Memória NodeManager | yarn-site.xml | `yarn.nodemanager.resource.memory-mb` |
| Memória Max Container | yarn-site.xml | `yarn.scheduler.maximum-allocation-mb` |
| VCores | yarn-site.xml | `yarn.nodemanager.resource.cpu-vcores` |
| Memória Map Task | mapred-site.xml | `mapreduce.map.memory.mb` |
| Memória Reduce Task | mapred-site.xml | `mapreduce.reduce.memory.mb` |
| Número de Reducers | mapred-site.xml | `mapreduce.job.reduces` |
| Execução Especulativa | mapred-site.xml | `mapred.*.tasks.speculative.execution` |

### 3.2 Relação Entre Parâmetros de Memória

**Hierarquia** (do maior para o menor):

```
yarn.nodemanager.resource.memory-mb (Total do nó)
  └─> yarn.scheduler.maximum-allocation-mb (Max por container)
       └─> mapreduce.map.memory.mb (Container para map)
            └─> mapreduce.map.java.opts (-Xmx...) (Heap da JVM)
```

**Regra**: Cada nível deve ser ≤ ao nível acima.

**Exemplo Correto**:
- NodeManager: 4096MB
- Max Container: 4096MB
- Map Task: 2048MB
- JVM Heap: -Xmx1600m (1600MB)

**Exemplo INCORRETO** (vai falhar):
- NodeManager: 2048MB
- Max Container: 4096MB ← ERRO! Excede total do nó

### 3.3 Fórmulas Úteis

**Número de Map Tasks**:
```
num_map_tasks = ceil(input_size / block_size)
```

**Número de Reducers (automático)**:
```
num_reducers = 0.95 * num_nodes * num_vcores_per_node
ou
num_reducers = 1.75 * num_nodes * num_vcores_per_node
```

**Memória Necessária para Job**:
```
total_mem_needed = max(
    num_concurrent_maps * map_memory,
    num_concurrent_reduces * reduce_memory
)
```

---

## 4. Comandos para Aplicar Configurações

### 4.1 Aplicar Configuração de Teste

```bash
# Copiar XMLs do teste para os nós
docker-compose -f hadoop/docker-compose.yml exec master bash -c "
  cp /opt/config/teste1_memoria/*.xml /opt/hadoop/etc/hadoop/
"

# Reiniciar serviços YARN para aplicar
docker-compose -f hadoop/docker-compose.yml exec master bash -c "
  /opt/hadoop/sbin/stop-yarn.sh
  sleep 5
  /opt/hadoop/sbin/start-yarn.sh
"
```

### 4.2 Verificar Configuração Aplicada

```bash
# Ver configuração específica
docker-compose -f hadoop/docker-compose.yml exec master bash -c "
  grep -A 2 'dfs.replication' /opt/hadoop/etc/hadoop/hdfs-site.xml
"

# Ver todas as configurações efetivas
docker-compose -f hadoop/docker-compose.yml exec master bash -c "
  hdfs getconf -confKey dfs.replication
  yarn getconf -confKey yarn.nodemanager.resource.memory-mb
"
```

### 4.3 Restaurar Configuração Original

```bash
# Copiar backup
docker-compose -f hadoop/docker-compose.yml exec master bash -c "
  rm -rf /opt/hadoop/etc/hadoop
  mv /opt/hadoop/etc/hadoop.backup /opt/hadoop/etc/hadoop
  
  /opt/hadoop/sbin/stop-yarn.sh
  /opt/hadoop/sbin/start-yarn.sh
"
```

---

## 5. Troubleshooting de Configurações

### Problema: "Heap space" em Map/Reduce Tasks

**Causa**: `mapreduce.*.java.opts` heap menor que necessário

**Solução**:
```xml
<property>
    <name>mapreduce.map.java.opts</name>
    <value>-Xmx1600m</value>  <!-- Aumentar heap -->
</property>
```

### Problema: "Container is running beyond memory limits"

**Causa**: Task usa mais memória que `mapreduce.*.memory.mb`

**Solução**:
```xml
<property>
    <name>mapreduce.map.memory.mb</name>
    <value>2048</value>  <!-- Aumentar limite -->
</property>
```

### Problema: Jobs ficam em ACCEPTED mas não iniciam

**Causa**: Memória solicitada excede disponível no cluster

**Verificar**:
```bash
yarn node -list  # Ver recursos disponíveis
yarn application -status <app_id>  # Ver recursos solicitados
```

**Solução**: Reduzir `mapreduce.*.memory.mb` ou aumentar `yarn.nodemanager.resource.memory-mb`

### Problema: Muitos pequenos arquivos de saída

**Causa**: Muitos reducers

**Solução**:
```xml
<property>
    <name>mapreduce.job.reduces</name>
    <value>2</value>  <!-- Reduzir número -->
</property>
```

---

## 6. Referências

- [Hadoop Configuration Reference](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/core-default.xml)
- [HDFS Configuration](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml)
- [YARN Configuration](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-common/yarn-default.xml)
- [MapReduce Configuration](https://hadoop.apache.org/docs/stable/hadoop-mapreduce-client/hadoop-mapreduce-client-core/mapred-default.xml)

---

*Última atualização: $(date '+%Y-%m-%d')*
