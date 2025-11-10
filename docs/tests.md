# Metodologia de Testes

## 🎯 Objetivos dos Testes

Os testes foram projetados para avaliar o impacto de diferentes configurações no desempenho do cluster Hadoop, especificamente:

1. **Recursos de memória** (YARN)
2. **Replicação de dados** (HDFS)
3. **Tamanho de blocos** (HDFS)
4. **Paralelização** (MapReduce)

## 🧪 B1 - Testes Hadoop

### Dataset

- **Tamanho**: 10.000 linhas
- **Conteúdo**: Texto aleatório com palavras técnicas
- **Palavras**: hadoop, mapreduce, yarn, hdfs, spark, distributed, computing, big, data, cluster, node, worker, master, java, processing
- **Geração**: Automática via script `generate_dataset.sh`

### Aplicação de Teste

**WordCount** - Aplicação MapReduce clássica que conta a frequência de palavras.

**Por quê WordCount?**
- Carga balanceada entre Map e Reduce
- Uso intensivo de I/O (HDFS)
- Fácil validação de resultados
- Comportamento previsível

### Testes Realizados

#### Teste 1: Memória YARN

**Configuração Alterada:**
```xml
<property>
  <name>yarn.nodemanager.resource.memory-mb</name>
  <value>1024</value>  <!-- Padrão: 2048 -->
</property>
```

**Hipótese:** Reduzir a memória disponível deve aumentar o tempo de execução devido a:
- Menos containers simultâneos
- Maior uso de swap/disco
- Possível throttling de tasks

**Métricas Observadas:**
- Tempo total de execução
- Número de containers
- Tempo de Map
- Tempo de Reduce
- Utilização de memória

#### Teste 2: Replicação HDFS

**Configuração Alterada:**
```xml
<property>
  <name>dfs.replication</name>
  <value>1</value>  <!-- Padrão: 2 -->
</property>
```

**Hipótese:** Reduzir replicação deve:
- ✅ Diminuir tempo de escrita
- ✅ Reduzir uso de disco
- ❌ Aumentar risco de perda de dados
- ❓ Impacto variável no tempo de leitura

**Métricas Observadas:**
- Tempo de escrita no HDFS
- Tempo de leitura no HDFS
- Espaço em disco usado
- Tempo total do job

#### Teste 3: Block Size

**Configuração Alterada:**
```xml
<property>
  <name>dfs.blocksize</name>
  <value>67108864</value>  <!-- 64MB, Padrão: 128MB -->
</property>
```

**Hipótese:** Blocos menores devem resultar em:
- ✅ Mais tasks Map (melhor paralelização)
- ❌ Mais overhead de metadados
- ❌ Maior uso de memória no NameNode
- ❓ Impacto variável no tempo total

**Métricas Observadas:**
- Número de blocos criados
- Número de Map tasks
- Tempo de Map
- Tempo total do job

#### Teste 4: Número de Reducers

**Configuração Alterada:**
```xml
<property>
  <name>mapreduce.job.reduces</name>
  <value>4</value>  <!-- Padrão: 1 -->
</property>
```

**Hipótese:** Mais reducers devem:
- ✅ Melhor paralelização da fase Reduce
- ✅ Reduzir tempo de Reduce
- ❌ Mais shuffle de dados
- ❓ Pode não ter impacto se dataset for pequeno

**Métricas Observadas:**
- Número de Reduce tasks
- Tempo de Shuffle
- Tempo de Reduce
- Tempo total do job

### Processo de Execução

Para cada teste:

1. **Preparação**
   ```bash
   # Parar processos
   # Limpar datanodes
   # Copiar configuração específica
   ```

2. **Inicialização**
   ```bash
   # Formatar NameNode
   # Iniciar HDFS e YARN
   # Verificar nodes ativos
   ```

3. **Execução**
   ```bash
   # Gerar dataset
   # Copiar para HDFS
   # Executar WordCount
   # Coletar métricas
   ```

4. **Coleta de Resultados**
   ```bash
   # Extrair logs do job
   # Salvar métricas YARN/HDFS
   # Gerar resumo
   ```

### Métricas Coletadas

De cada execução, são extraídas:

**Do Job MapReduce:**
- Job ID
- Start time / End time
- Elapsed time
- Map tasks (total, successful, failed)
- Reduce tasks (total, successful, failed)
- Map time
- Reduce time
- Shuffle time

**Do HDFS:**
- Bytes read
- Bytes written
- HDFS read operations
- HDFS write operations

**Do YARN:**
- Memory allocated
- VCores allocated
- Container preemptions

### Estrutura de Resultados

```
resultados/B1/
├── teste1_memoria/
│   ├── resumo.txt              # Resumo do teste
│   ├── job_output.txt          # Output completo do MapReduce
│   └── relatorio.txt           # Métricas detalhadas
├── teste2_replicacao/
│   └── ...
├── teste3_blocksize/
│   └── ...
├── teste4_reducers/
│   └── ...
├── resumo_comparativo.txt      # Comparação entre todos
└── relatorio_consolidado.txt   # Análise consolidada
```

## 🧪 B2 - Testes Spark

### Objetivo

Implementar e validar um pipeline de streaming completo:

**Producer** → **Kafka** → **Spark Streaming** → **Elasticsearch** → **Kibana**

### Fluxo de Dados

1. **Producer Python** gera mensagens (frases aleatórias)
2. **Kafka** armazena mensagens no tópico `input-topic`
3. **Spark Streaming** consome, processa (WordCount) e envia para Elasticsearch
4. **Kibana** visualiza resultados em tempo real

### Testes de Validação

#### 1. Conectividade

```bash
# Zookeeper ↔ Kafka
# Kafka ↔ Spark
# Spark ↔ Elasticsearch
# Kibana ↔ Elasticsearch
```

#### 2. Produção/Consumo Kafka

```bash
# Criar tópico
# Produzir mensagens
# Consumir mensagens
# Verificar offset
```

#### 3. Processamento Spark

```bash
# Submit job
# Verificar streaming ativo
# Monitorar logs
# Validar output
```

#### 4. Armazenamento Elasticsearch

```bash
# Verificar índice criado
# Contar documentos
# Validar estrutura
```

#### 5. Visualização Kibana

```bash
# Criar index pattern
# Visualizar em Discover
# Criar dashboard
```

### Métricas Observadas

- **Latência**: Tempo entre produção e visualização
- **Throughput**: Mensagens/segundo processadas
- **Disponibilidade**: Uptime dos serviços
- **Escalabilidade**: Comportamento sob carga

## 📊 Análise de Resultados

### Comparação de Desempenho

Para cada teste B1, compare:

```
Baseline (configuração padrão) vs Teste Modificado

Métricas:
- Δ Tempo Total (%)
- Δ Tempo Map (%)
- Δ Tempo Reduce (%)
- Δ Uso de Memória (%)
- Δ I/O HDFS (%)
```

### Interpretação

**Melhoria (verde):** Configuração reduziu tempo/recursos
**Degradação (vermelho):** Configuração aumentou tempo/recursos
**Neutro (amarelo):** Impacto desprezível (<5%)

### Recomendações

Com base nos resultados, determinar:

1. **Configuração ótima** para o workload específico
2. **Trade-offs** entre desempenho e confiabilidade
3. **Escalabilidade** com aumento de dados/nodes

## 📝 Documentação

Cada teste gera:

1. **resumo.txt**: Overview do teste
2. **job_output.txt**: Log completo do MapReduce
3. **relatorio.txt**: Métricas detalhadas

O relatório consolidado compara todos os testes e fornece análise final.

## 🔄 Reprodutibilidade

Todos os testes são:
- **Automatizados**: Via scripts shell
- **Determinísticos**: Mesmo dataset, mesmas configurações
- **Documentados**: Logs completos preservados
- **Versionados**: Configurações em Git

Para reproduzir:

```bash
./scripts/verify.sh       # Validar ambiente
./scripts/run_tests.sh    # Executar todos os testes
cat resultados/B1/resumo_comparativo.txt  # Ver resultados
```
