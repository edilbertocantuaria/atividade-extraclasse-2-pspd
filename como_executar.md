# Como Executar o Projeto - Atividade Extraclasse 2

> **Guia completo e objetivo** para executar do zero as implementações B1 (Hadoop) e B2 (Spark Streaming) + extensão ML (análise de sentimentos)

---

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Pré-requisitos](#pré-requisitos)
- [B1: Apache Hadoop - WordCount Distribuído](#b1-apache-hadoop---wordcount-distribuído)
- [B2: Apache Spark Streaming - Processamento em Tempo Real](#b2-apache-spark-streaming---processamento-em-tempo-real)
- [Extensão ML: Análise de Sentimentos (Opcional)](#extensão-ml-análise-de-sentimentos-opcional)
- [Troubleshooting](#troubleshooting)
- [Estrutura de Resultados](#estrutura-de-resultados)

---

## Visão Geral

Este projeto implementa **processamento distribuído de dados** utilizando dois frameworks Apache:

### **B1 - Hadoop MapReduce**
- WordCount em cluster distribuído (1 master + 2 workers)
- 5 configurações diferentes testadas
- Testes de tolerância a falhas e concorrência
- Dataset massivo (500MB+) para execução realística (3-4 minutos)

### **B2 - Spark Streaming**
- Pipeline de streaming em tempo real com Kafka
- Processamento de mensagens sociais simuladas
- Indexação em Elasticsearch
- Dashboard Kibana para visualização

### **Extensão ML (Opcional)**
- Análise de sentimentos com VADER
- Classificação automática (positivo/negativo/neutro)
- Métricas de polaridade e subjetividade

---

## Pré-requisitos

### Hardware Mínimo
- **RAM**: 8GB (recomendado: 16GB)
- **Disco**: 20GB livres
- **CPU**: 4 cores (recomendado: 8 cores)

### Software Necessário
```bash
# Verificar Docker
docker --version  # Versão 20.10+
docker-compose --version  # Versão 1.29+

# Verificar Python
python3 --version  # Python 3.8+

# Verificar portas disponíveis
# Hadoop: 8088, 9870, 9000
# Spark: 8080, 4040, 7077
# Kafka: 9092, 2181
# Elasticsearch: 9200
# Kibana: 5601
netstat -tuln | grep -E '8088|9870|8080|9092|9200|5601'
# Se algo aparecer, essas portas já estão em uso
```

### Clonar/Acessar Projeto
```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd
```

---

## B1: Apache Hadoop - WordCount Distribuído

### 🎯 Objetivo
Executar algoritmo WordCount em cluster Hadoop com diferentes configurações para análise comparativa de desempenho.

### 📝 Passo a Passo

#### **1. Iniciar Cluster Hadoop (3 nós)**
```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd/hadoop
docker-compose up -d
sleep 10  # Aguardar containers iniciarem
```

**Iniciar serviços Hadoop:**
```bash
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/sbin/start-all.sh'"
sleep 30  # Aguardar serviços HDFS + YARN iniciarem
```

**Verificar status:**
```bash
# Verificar containers
docker ps --filter "name=hadoop-"
# Deve mostrar 3 containers UP: hadoop-master, hadoop-worker1, hadoop-worker2

# Verificar processos Java (deve mostrar 3 ou mais)
docker exec hadoop-master bash -c "ps aux | grep java | grep -v grep | wc -l"
```

**Interfaces web disponíveis:**
- **YARN ResourceManager**: http://localhost:8088
- **HDFS NameNode**: http://localhost:9870

> ✅ **Testar acesso:** Abra as URLs no navegador. Você deve ver as interfaces do Hadoop.

#### **2. Gerar Dataset Massivo**
```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd
./scripts/generate_large_dataset.sh 500
# Gera 500MB de dados textuais (ajustar se necessário)
```

**Verificar upload no HDFS:**
```bash
docker exec hadoop-master hdfs dfs -ls -h /user/hadoop/input
# Deve mostrar ~500MB em 10 arquivos
```

#### **3. Executar Todos os Testes Automaticamente**
```bash
./scripts/run_all_tests.sh
```

⏱️ **Duração estimada:** 30-40 minutos

**O que esse script faz:**
- Teste baseline (configuração padrão)
- Teste 1: Alteração de memória YARN
- Teste 2: Alteração de replicação HDFS
- Teste 3: Alteração de block size
- Teste 4: Alteração de número de reducers
- Teste 5: Alteração de speculative execution
- Coleta de métricas padronizadas
- Geração de relatório consolidado

#### **4. (Opcional) Testes Avançados**

**Teste de Tolerância a Falhas:**
```bash
./scripts/test_fault_tolerance.sh
# Testa comportamento ao remover/adicionar workers durante execução
# Duração: ~15-20 minutos por cenário (4 cenários = 60-80 minutos total)
```

> ⏱️ **Importante**: Este teste é **longo** e executa 4 cenários sequencialmente:
> - Cenário 1 (Baseline): ~15-20 min
> - Cenário 2 (Falha 1 worker): ~20-30 min (mais lento devido à redução de recursos)
> - Cenário 3 (Falha 2 workers): ~30-40 min (muito mais lento)
> - Cenário 4 (Adição de worker): ~15-20 min
>
> **Monitorar progresso** em outro terminal:
> ```bash
> # Ver jobs em execução
> watch -n 5 'docker exec hadoop-master yarn application -list -appStates RUNNING'
> 
> # Ver progresso do job atual (substitua APPLICATION_ID)
> watch -n 10 'docker exec hadoop-master yarn application -status APPLICATION_ID | grep Progress'
> ```

**Teste de Concorrência:**
```bash
./scripts/test_concurrency.sh
# Testa 2, 3 e 4 jobs simultâneos
# Duração: ~10-15 minutos total
```

> ⏱️ **Importante**: Executa 3 testes em sequência:
> - Teste 1: 2 jobs simultâneos (~3-5 min)
> - Teste 2: 3 jobs simultâneos (~4-6 min)
> - Teste 3: 4 jobs simultâneos (~5-8 min)
>
> **Monitorar jobs simultâneos**:
> ```bash
> watch -n 5 'docker exec hadoop-master yarn application -list -appStates RUNNING'
> ```

#### **5. Analisar Resultados**
```bash
# Ver relatório final consolidado
cat resultados/B1/RELATORIO_FINAL_COMPLETO.md

# Ver todos os tempos de execução
for dir in resultados/B1/teste*/; do
  test_name=$(basename "$dir")
  duration=$(cat "$dir/time_stats.txt" 2>/dev/null || echo "N/A")
  echo "$test_name: ${duration}s"
done
```

#### **6. Parar Cluster**
```bash
# Parar serviços Hadoop
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/sbin/stop-all.sh'"

# Parar containers
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd/hadoop
docker-compose down
```

### ✅ Checklist B1

- [ ] Cluster Hadoop iniciado (3 containers ativos)
- [ ] Dataset massivo gerado (500MB+)
- [ ] 5 configurações diferentes testadas
- [ ] Métricas coletadas (tempo, throughput, variação %)
- [ ] Testes de falhas executados (opcional)
- [ ] Testes de concorrência executados (opcional)
- [ ] Relatório final gerado
- [ ] Screenshots das interfaces web (YARN, HDFS)

---

## B2: Apache Spark Streaming - Processamento em Tempo Real

### 🎯 Objetivo
Implementar pipeline de streaming que processa mensagens de rede social simulada, realiza contagem de palavras em janelas deslizantes e indexa resultados em Elasticsearch para visualização em Kibana.

### 📝 Passo a Passo

#### **1. Iniciar Infraestrutura Docker**
```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd/spark
docker-compose up -d
sleep 30  # Aguardar serviços iniciarem
```

**Verificar serviços:**
```bash
docker-compose ps
# Deve mostrar 6 containers ATIVOS:
# - zookeeper
# - kafka
# - spark-master
# - spark-worker
# - elasticsearch
# - kibana
```

**Interfaces web disponíveis:**
- **Spark Master**: http://localhost:8080
- **Elasticsearch**: http://localhost:9200
- **Kibana**: http://localhost:5601

> ⚠️ **Nota**: Elasticsearch pode levar até 2 minutos para iniciar, e Kibana até 3 minutos. Aguarde antes de acessar.

#### **2. Abrir Notebook Jupyter**
```bash
# No VS Code, abrir arquivo:
spark/notebooks/B2_SPARK_STREAMING_COMPLETO.ipynb
```

**Selecionar kernel Python:**
- Clicar em "Select Kernel" (canto superior direito)
- Escolher Python 3.8+ do sistema

#### **3. Executar Células do Notebook Sequencialmente**

**IMPORTANTE:** Executar células na ordem 1 → 50 (não pular nenhuma)

**Seções principais:**

**Seção 1 - Justificativa Discord (células 1-2)**
- Explicação sobre não uso do Discord API (substituído por simulação)
- Executar células 1 e 2

**Seção 2 - Setup Kafka (células 3-9)**
- Instalar dependências Python (`kafka-python`, `elasticsearch`)
- Criar tópicos Kafka (`social-input`, `wordcount-output`)
- Executar células 3 a 9
- ⏱️ ~2 minutos

**Seção 3 - Producer Kafka (células 10-18)**
- Configurar producer de mensagens
- Gerar dados sintéticos (mensagens sociais simuladas)
- Testar envio
- Executar células 10 a 18
- ⏱️ ~2 minutos

**Seção 4 - Pipeline Spark Streaming (células 19-35)**
- Configurar SparkSession
- Conectar ao Kafka
- Implementar transformações (split, contagem)
- Aplicar windowing (30s tumbling)
- Escrever resultados de volta ao Kafka
- Executar células 19 a 35
- ⏱️ ~3 minutos

**Seção 5 - Execução Background (células 36-39)**
- Iniciar producer em background (3 minutos, 3 msgs/seg)
- Iniciar streaming queries
- Executar células 36 a 39
- ⏱️ ~1 minuto (setup), depois continua rodando

**Seção 6 - Consumer Elasticsearch (células 40-45)**
- Criar índice Elasticsearch
- Configurar consumer que lê do Kafka
- Indexar documentos no ES
- Executar células 40 a 45
- ⏱️ ~2 minutos

**Seção 7 - Dashboard Kibana (células 46-48)**
- Acessar Kibana: http://localhost:5601
- Criar data view `wordcount-realtime`
- Criar visualização Tag Cloud
- Criar dashboard
- Executar células 46 a 48 (instruções detalhadas)
- ⏱️ ~5 minutos

**Seção 8 - Finalização (células 49-50)**
- Parar streaming queries
- Ver estatísticas finais
- Cleanup
- Executar células 49 a 50
- ⏱️ ~1 minuto

#### **4. Criar Dashboard Kibana**

**Acessar Kibana:**
```
http://localhost:5601
```

**Criar Data View:**
1. Menu → Stack Management → Data Views
2. Clicar "Create data view"
3. Name: `wordcount-realtime`
4. Index pattern: `wordcount-realtime`
5. Timestamp field: `timestamp`
6. Save

**Criar Visualização Tag Cloud:**
1. Menu → Visualize Library → Create visualization
2. Tipo: "Tag cloud"
3. Data view: `wordcount-realtime`
4. Configurar:
   - Bucket: Tags
   - Aggregation: Terms
   - Field: `word.keyword`
   - Size: 50
   - Order by: Metric (Count)
5. Metrics: Count
6. Save: "WordCount Tag Cloud"

**Criar Dashboard:**
1. Menu → Dashboard → Create dashboard
2. Add visualization: "WordCount Tag Cloud"
3. Ajustar tamanho
4. Configurar auto-refresh: 10s (canto superior direito)
5. Save dashboard: "Real-time WordCount"

#### **5. Capturar Screenshots**

Salvar em `resultados_spark/`:
- `kibana_dashboard_wordcloud.png` - Dashboard completo
- `kibana_tagcloud_detail.png` - Tag Cloud em detalhe
- `spark_webui_streaming.png` - Spark Master mostrando queries ativas

#### **6. Parar Infraestrutura**
```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd/spark
docker-compose down
```

### ✅ Checklist B2

- [ ] Infraestrutura Docker iniciada (6 containers ativos)
- [ ] Notebook executado célula por célula (1 → 50)
- [ ] Tópicos Kafka criados (`social-input`, `wordcount-output`)
- [ ] Producer enviou ~540 mensagens (3 msgs/seg × 180s)
- [ ] Spark queries processaram janelas de 30s
- [ ] Consumer indexou documentos no Elasticsearch
- [ ] Data view criado no Kibana
- [ ] Dashboard com Tag Cloud funcionando
- [ ] Auto-refresh configurado (10s)
- [ ] Screenshots capturados
- [ ] Justificativa Discord documentada

---

## Extensão ML: Análise de Sentimentos (Opcional)

### 🎯 Objetivo
Adicionar camada de Machine Learning ao pipeline B2 para classificar sentimentos das mensagens (positivo/negativo/neutro).

### 📝 Passo a Passo

#### **1. Pré-requisitos**
- Infraestrutura B2 em execução
- Notebook `B2_SPARK_STREAMING_COMPLETO.ipynb` executado até célula 50

#### **2. Executar Seção 8.4 - Extensão ML (células 51-65)**

**Células 51-55: Instalação e Import**
- Instalar `vaderSentiment`
- Importar bibliotecas necessárias
- ⏱️ ~1 minuto

**Células 56-58: Análise de Sentimentos**
- Configurar VADER analyzer
- Aplicar análise às mensagens
- Calcular scores (positivo, negativo, neutro, composto)
- ⏱️ ~2 minutos

**Células 59-61: Classificação**
- Categorizar mensagens baseado em score composto:
  - `>= 0.05`: Positivo
  - `<= -0.05`: Negativo
  - `-0.05 a 0.05`: Neutro
- ⏱️ ~1 minuto

**Células 62-64: Indexação e Visualização**
- Indexar dados enriquecidos no Elasticsearch (índice `wordcount-sentiments`)
- Criar visualizações no Kibana:
  - Pie chart: Distribuição de sentimentos
  - Bar chart: Top palavras por sentimento
  - Line chart: Evolução temporal de sentimentos
- ⏱️ ~5 minutos

**Célula 65: Estatísticas Finais**
- Ver métricas agregadas
- Validar classificação
- ⏱️ ~1 minuto

#### **3. Criar Visualizações no Kibana**

**Criar Data View para Sentimentos:**
1. Stack Management → Data Views → Create
2. Name: `wordcount-sentiments`
3. Index pattern: `wordcount-sentiments`
4. Timestamp: `timestamp`
5. Save

**Visualização 1 - Pie Chart (Distribuição):**
1. Visualize → Create → Pie
2. Data view: `wordcount-sentiments`
3. Slice by: Terms → `sentiment.keyword`
4. Save: "Sentiment Distribution"

**Visualização 2 - Bar Chart (Top Palavras):**
1. Visualize → Create → Bar vertical
2. X-axis: Terms → `word.keyword` (top 10)
3. Split series: Terms → `sentiment.keyword`
4. Save: "Top Words by Sentiment"

**Visualização 3 - Line Chart (Timeline):**
1. Visualize → Create → Line
2. X-axis: Date Histogram → `timestamp`
3. Y-axis: Count
4. Split series: Terms → `sentiment.keyword`
5. Save: "Sentiment Timeline"

**Dashboard ML:**
1. Dashboard → Create
2. Adicionar 3 visualizações criadas
3. Save: "Sentiment Analysis Dashboard"

#### **4. Capturar Screenshots**

Salvar em `resultados_spark/`:
- `kibana_sentiment_pie.png`
- `kibana_sentiment_bars.png`
- `kibana_sentiment_timeline.png`
- `kibana_dashboard_ml.png`

### ✅ Checklist ML

- [ ] VADER instalado e configurado
- [ ] Scores de sentimento calculados (pos, neg, neu, compound)
- [ ] Classificação aplicada (positivo/negativo/neutro)
- [ ] Dados indexados no Elasticsearch (`wordcount-sentiments`)
- [ ] 3 visualizações criadas no Kibana
- [ ] Dashboard ML completo
- [ ] Screenshots capturados
- [ ] Referências acadêmicas citadas (VADER paper)

---

## Troubleshooting

### Problemas Comuns B1 (Hadoop)

#### Cluster não inicia ou interfaces web não respondem
```bash
# 1. Verificar se containers estão rodando
docker ps --filter "name=hadoop-"

# 2. Verificar se processos Java estão ativos
docker exec hadoop-master bash -c "ps aux | grep java | grep -v grep"

# 3. Se não houver processos Java, iniciar serviços manualmente
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/sbin/start-all.sh'"
sleep 30

# 4. Verificar logs se ainda houver problema
docker logs hadoop-master --tail 100
docker logs hadoop-worker1 --tail 50

# 5. Reiniciar completo (última opção)
cd hadoop
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/sbin/stop-all.sh'"
docker-compose down -v
docker-compose up -d
sleep 10
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/sbin/start-all.sh'"
sleep 30

# 6. Testar acesso às interfaces
curl -I http://localhost:8088 2>/dev/null | head -1  # YARN
curl -I http://localhost:9870 2>/dev/null | head -1  # HDFS
```

#### Job muito rápido (< 3 minutos)
```bash
# Gerar dataset maior
./scripts/generate_large_dataset.sh 1000  # 1GB
# ou
./scripts/generate_large_dataset.sh 2000  # 2GB
```

#### Workers não conectam
```bash
# Ver nós ativos no YARN
docker exec hadoop-master yarn node -list

# Verificar se DataNodes estão registrados
docker exec hadoop-master hdfs dfsadmin -report

# Reiniciar workers
docker restart hadoop-worker1 hadoop-worker2
sleep 30
```

#### Sem espaço em disco
```bash
# Limpar outputs antigos
docker exec hadoop-master hdfs dfs -rm -r -f /user/hadoop/output/*

# Limpar Docker
docker system prune -a
```

### Problemas Comuns B2 (Spark)

#### Container não inicia
```bash
# Ver logs específicos
docker logs kafka --tail 100
docker logs elasticsearch --tail 100
docker logs spark-master --tail 100

# Reiniciar serviço específico
cd spark
docker-compose restart <service-name>
```

#### Elasticsearch não aceita conexões
```bash
# Verificar saúde
curl http://localhost:9200/_cluster/health?pretty

# Aguardar inicialização (pode levar 2 minutos)
watch -n 5 'curl -s http://localhost:9200 | grep cluster_name'
```

#### Kafka não recebe mensagens
```bash
# Verificar broker
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092

# Verificar tópicos
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

# Ver mensagens no tópico
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic social-input \
  --from-beginning \
  --max-messages 10
```

#### Spark query não processa
```bash
# Verificar Spark Web UI
firefox http://localhost:8080

# Verificar no notebook se query está ativa
print(query_kafka.isActive)
print(query_kafka.status)

# Ver logs do worker
docker logs spark-worker --tail 100
```

#### Kibana não carrega
```bash
# Verificar conexão com Elasticsearch
docker exec kibana curl http://elasticsearch:9200

# Aguardar mais tempo (pode levar 3 minutos após ES)
docker logs kibana --tail 100
```

#### Erro ao instalar pacotes Python
```bash
# No notebook, instalar manualmente
!pip install kafka-python elasticsearch vaderSentiment

# Verificar instalação
!pip list | grep -E 'kafka|elastic|vader'
```

### Problemas Comuns ML

#### VADER não instala
```bash
# No notebook
!pip install --upgrade pip
!pip install vaderSentiment

# Verificar
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
```

#### Scores sempre neutros
```bash
# Verificar idioma das mensagens (VADER é otimizado para inglês)
# Garantir que mensagens têm palavras com carga emocional
# Ver exemplos na célula 56 do notebook
```

---

## Estrutura de Resultados

```
atividade-extraclasse-2-pspd/
├── resultados/B1/                          # Resultados Hadoop
│   ├── RELATORIO_FINAL_COMPLETO.md         # Relatório consolidado B1
│   ├── teste0_baseline/                    # Configuração padrão
│   │   ├── job_output.txt
│   │   ├── time_stats.txt
│   │   ├── metrics_summary.csv
│   │   └── throughput_metrics.txt
│   ├── teste1_memoria/                     # Teste memória
│   ├── teste2_replicacao/                  # Teste replicação
│   ├── teste3_blocksize/                   # Teste block size
│   ├── teste4_reducers/                    # Teste reducers
│   ├── teste5_speculative/                 # Teste speculative execution
│   ├── teste_tolerancia_falhas/            # Testes de falhas
│   │   └── run_TIMESTAMP/
│   │       └── relatorio_tolerancia_falhas.md
│   └── teste_concorrencia/                 # Testes de concorrência
│       └── run_TIMESTAMP/
│           └── relatorio_concorrencia.md
│
├── resultados_spark/                       # Resultados Spark
│   ├── IMPLEMENTACAO_B2_COMPLETA.md        # Documentação detalhada B2
│   ├── VALIDACAO_B2_DETALHADA.md           # Checklist de validação
│   ├── EXTENSAO_ML_SENTIMENTOS.md          # Documentação ML
│   ├── kibana_dashboard_wordcloud.png      # Screenshots
│   ├── kibana_tagcloud_detail.png
│   ├── kibana_sentiment_pie.png
│   └── kibana_dashboard_ml.png
│
└── spark/notebooks/
    └── B2_SPARK_STREAMING_COMPLETO.ipynb   # Notebook completo (65 células)
```

---

## Referências

### B1 - Hadoop
- [Apache Hadoop Documentation](https://hadoop.apache.org/docs/current/)
- [YARN Architecture](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.html)
- [HDFS Design](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html)

### B2 - Spark
- [Spark Structured Streaming](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html)
- [Spark-Kafka Integration](https://spark.apache.org/docs/latest/structured-streaming-kafka-integration.html)
- [Elasticsearch Python Client](https://elasticsearch-py.readthedocs.io/)

### ML
- **VADER**: Hutto, C.J. & Gilbert, E.E. (2014). VADER: A Parsimonious Rule-based Model for Sentiment Analysis of Social Media Text. *Eighth International Conference on Weblogs and Social Media (ICWSM-14)*.
- [VADER GitHub](https://github.com/cjhutto/vaderSentiment)

---

## 📞 Suporte

Para dúvidas ou problemas:

1. Consultar seções de Troubleshooting acima
2. Verificar logs dos containers (`docker logs <container>`)
3. Consultar documentação detalhada:
   - B1: `resultados/B1/RELATORIO_FINAL_COMPLETO.md`
   - B2: `resultados_spark/IMPLEMENTACAO_B2_COMPLETA.md`
   - ML: `resultados_spark/EXTENSAO_ML_SENTIMENTOS.md`

---

**Última atualização:** 29/11/2025  
**Versão:** 1.0  
**Arquivo:** `/home/edilberto/pspd/atividade-extraclasse-2-pspd/como_executar.md`
