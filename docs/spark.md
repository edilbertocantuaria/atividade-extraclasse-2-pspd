# Documentação Técnica - Spark

> 🚀 **Para instruções de execução**, consulte **[como_executar.md](../como_executar.md)**

> Esta documentação contém detalhes técnicos sobre arquitetura e configurações Spark Streaming.

## 🏗️ Arquitetura

### Componentes do Ambiente

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Producer   │────▶│    Kafka     │────▶│    Spark     │
│   (Python)   │     │   (Broker)   │     │  (Streaming) │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                                                  ▼
                                         ┌─────────────────┐
                                         │ Elasticsearch   │
                                         └────────┬────────┘
                                                  │
                                                  ▼
                                         ┌─────────────────┐
                                         │     Kibana      │
                                         └─────────────────┘
```

### Containers

| Serviço | Porta | Função |
|---------|-------|--------|
| **Zookeeper** | 2181 | Coordenação Kafka |
| **Kafka** | 9092 | Message broker |
| **Elasticsearch** | 9200, 9300 | Armazenamento e busca |
| **Kibana** | 5601 | Visualização |
| **Spark Master** | 7077, 8080 | Coordenação cluster Spark |
| **Spark Worker** | - | Execução de tasks |

## ⚙️ Configurações

### Docker Compose

O ambiente completo é orquestrado via `docker-compose.yml`:

```yaml
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

  kafka:
    image: confluentinc/cp-kafka:latest
    ports:
      - "9092:9092"
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    ports:
      - "9200:9200"
    environment:
      discovery.type: single-node
      xpack.security.enabled: false

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    ports:
      - "5601:5601"

  spark-master:
    build: .
    ports:
      - "8080:8080"
      - "7077:7077"
    command: /opt/spark/bin/spark-class org.apache.spark.deploy.master.Master
```

### Spark Streaming

Configuração do streaming (micro-batches de 5 segundos):

```python
from pyspark import SparkContext
from pyspark.streaming import StreamingContext
from pyspark.streaming.kafka import KafkaUtils

sc = SparkContext(appName="WordCount")
ssc = StreamingContext(sc, 5)  # 5 segundos

# Conectar ao Kafka
kafkaStream = KafkaUtils.createDirectStream(
    ssc,
    ["input-topic"],
    {"bootstrap.servers": "kafka:9092"}
)
```

## 🚀 Uso

### Iniciar Ambiente

```bash
cd spark
docker compose up -d
```

### Verificar Status

```bash
# Verificar containers
docker compose ps

# Logs
docker compose logs -f spark-master
docker compose logs -f kafka
```

### Acessar Interfaces

- **Spark UI**: http://localhost:8080
- **Kibana**: http://localhost:5601
- **Elasticsearch**: http://localhost:9200
- **Jupyter** (se configurado): http://localhost:8888

### Executar Aplicação Spark

```bash
# Dentro do container
docker exec -it spark-master bash

# Submeter job
spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.spark:spark-streaming-kafka-0-10_2.12:3.5.0 \
  /opt/spark_app/wordcount_streaming.py
```

### Produzir Mensagens Kafka

```bash
# Via Python producer
docker exec -it spark-master python3 /opt/spark_app/producer.py

# Via Kafka console
docker exec -it kafka kafka-console-producer \
  --broker-list localhost:9092 \
  --topic input-topic
```

## 🧪 Testes

### 1. Teste de Conectividade

```bash
# Testar Kafka
docker exec kafka kafka-topics \
  --list \
  --bootstrap-server localhost:9092

# Testar Elasticsearch
curl http://localhost:9200/_cluster/health

# Testar Kibana
curl http://localhost:5601/api/status
```

### 2. Teste de Streaming

```bash
# Terminal 1: Iniciar aplicação Spark
docker exec -it spark-master spark-submit /opt/spark_app/wordcount_streaming.py

# Terminal 2: Enviar dados
docker exec -it spark-master python3 /opt/spark_app/producer.py

# Terminal 3: Verificar Elasticsearch
curl "http://localhost:9200/wordcount/_search?pretty"
```

### 3. Visualização no Kibana

1. Acesse http://localhost:5601
2. Management → Index Patterns → Create
3. Index pattern: `wordcount*`
4. Discover → Ver dados em tempo real
5. Visualize → Criar gráficos

## 📊 Monitoramento

### Spark

```bash
# Verificar workers ativos
curl http://localhost:8080/json/

# Aplicações rodando
curl http://localhost:8080/api/v1/applications
```

### Kafka

```bash
# Consumer groups
docker exec kafka kafka-consumer-groups \
  --list \
  --bootstrap-server localhost:9092

# Offset lag
docker exec kafka kafka-consumer-groups \
  --describe \
  --group spark-streaming \
  --bootstrap-server localhost:9092
```

### Elasticsearch

```bash
# Índices
curl http://localhost:9200/_cat/indices?v

# Contar documentos
curl http://localhost:9200/wordcount/_count

# Buscar documentos
curl "http://localhost:9200/wordcount/_search?pretty&size=10"
```

## 🔧 Troubleshooting

### Spark não conecta ao Kafka

```bash
# Verificar conectividade
docker exec spark-master ping kafka

# Verificar tópicos
docker exec kafka kafka-topics \
  --list \
  --bootstrap-server localhost:9092

# Criar tópico manualmente
docker exec kafka kafka-topics \
  --create \
  --topic input-topic \
  --bootstrap-server localhost:9092 \
  --partitions 1 \
  --replication-factor 1
```

### Elasticsearch inacessível

```bash
# Verificar logs
docker logs elasticsearch

# Verificar saúde
curl http://localhost:9200/_cluster/health

# Reiniciar
docker compose restart elasticsearch
```

### Job Spark falha

```bash
# Ver logs detalhados
docker logs spark-master
docker logs spark-worker

# Verificar recursos
docker stats

# Limpar checkpoints (se necessário)
docker exec spark-master rm -rf /tmp/checkpoint
```

### Kibana não carrega dados

```bash
# Verificar índice existe
curl http://localhost:9200/_cat/indices?v

# Refresh index pattern no Kibana
# Management → Index Patterns → wordcount* → Refresh field list
```

## 📁 Estrutura do Projeto Spark

```
spark/
├── docker-compose.yml        # Orquestração
├── Dockerfile                # Imagem Spark customizada
├── testar_ambiente.sh        # Script de validação
├── spark_app/
│   ├── wordcount_streaming.py  # Aplicação principal
│   ├── producer.py             # Produtor Kafka
│   └── requirements.txt        # Dependências Python
├── notebooks/                # Jupyter notebooks (opcional)
└── elastic/
    └── kibana_dashboards/    # Dashboards exportados
```

## 🔐 Considerações de Segurança

**Configuração atual é para desenvolvimento:**
- Elasticsearch sem autenticação
- Kafka sem SSL
- Portas expostas localmente

**Para produção:**
- Habilitar X-Pack Security (Elasticsearch)
- SSL/TLS no Kafka
- Autenticação e autorização
- Network policies

## 📚 Referências

- [Spark Streaming Guide](https://spark.apache.org/docs/latest/streaming-programming-guide.html)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Elasticsearch Guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Guide](https://www.elastic.co/guide/en/kibana/current/index.html)
