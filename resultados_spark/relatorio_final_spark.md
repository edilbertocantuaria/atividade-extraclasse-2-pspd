# Relatório Final - B2 (Apache Spark Streaming)

## 📋 Sumário Executivo

Este relatório documenta a implementação e validação de um ambiente completo de processamento de dados em tempo real utilizando **Apache Spark Streaming**, **Apache Kafka**, **Elasticsearch** e **Kibana**.

---

## 🎯 Objetivos

1. ✅ Configurar ambiente distribuído com Spark + Kafka + Elasticsearch + Kibana
2. ✅ Implementar processamento de streaming (WordCount)
3. ✅ Visualizar resultados em tempo real via dashboard
4. ✅ Documentar arquitetura e testes realizados

---

## 🏗️ Arquitetura Implementada

```
┌─────────────┐
│  Producer   │ ──(mensagens)──> ┌─────────┐
│  (Python)   │                   │  Kafka  │
└─────────────┘                   └────┬────┘
                                       │
                                       v
                              ┌─────────────────┐
                              │  Spark Streaming│
                              │   (WordCount)   │
                              └────────┬────────┘
                                       │
                                       v
                              ┌─────────────────┐
                              │ Elasticsearch   │
                              └────────┬────────┘
                                       │
                                       v
                              ┌─────────────────┐
                              │     Kibana      │
                              │   (Dashboard)   │
                              └─────────────────┘
```

---

## 🐳 Containers e Serviços

| Serviço | Container | Porta | Status |
|---------|-----------|-------|--------|
| Zookeeper | zookeeper | 2181 | ⏳ Pendente |
| Kafka | kafka | 9092 | ⏳ Pendente |
| Elasticsearch | elasticsearch | 9200, 9300 | ⏳ Pendente |
| Kibana | kibana | 5601 | ⏳ Pendente |
| Spark Master | spark-master | 7077, 8080 | ⏳ Pendente |
| Spark Worker | spark-worker | - | ⏳ Pendente |

---

## 📝 Instalações e Configurações

### 1. Docker Compose
- 6 containers orquestrados
- Rede bridge compartilhada
- Volumes para persistência

### 2. Apache Kafka
- Broker único
- Tópico: `input-topic`
- Replication factor: 1
- Partitions: 1

### 3. Apache Spark
- Modo cluster (master + worker)
- Streaming com micro-batches de 5 segundos
- Integração com Kafka via KafkaUtils

### 4. Elasticsearch
- Modo single-node
- Índice: `wordcount`
- Segurança desabilitada (desenvolvimento)

### 5. Kibana
- Dashboard em tempo real
- Visualização: Word Cloud / Bar Chart

---

## 🧪 Testes Realizados

### Teste 1: Conectividade entre Containers
```bash
docker exec -it spark-master ping kafka
docker exec -it spark-master ping elasticsearch
```
**Status:** ⏳ Pendente

### Teste 2: Produção de Mensagens Kafka
```bash
docker exec -it spark-master python3 /opt/spark_app/producer.py
```
**Status:** ⏳ Pendente

### Teste 3: Consumo de Mensagens
```bash
docker exec -it spark-master python3 /opt/spark_app/consumer.py
```
**Status:** ⏳ Pendente

### Teste 4: Processamento Spark Streaming
```bash
docker exec -it spark-master spark-submit /opt/spark_app/main.py
```
**Status:** ⏳ Pendente

### Teste 5: Dados no Elasticsearch
```bash
curl http://localhost:9200/wordcount/_search?pretty
```
**Status:** ⏳ Pendente

### Teste 6: Visualização no Kibana
- URL: http://localhost:5601
- Dashboard: WordCount Real-Time
**Status:** ⏳ Pendente

---

## 📊 Métricas de Performance

### Throughput
- Mensagens/segundo produzidas: _Pendente_
- Mensagens/segundo processadas: _Pendente_
- Latência média: _Pendente_

### Recursos
- CPU Spark Master: _Pendente_
- Memória Spark Master: _Pendente_
- CPU Spark Worker: _Pendente_
- Memória Spark Worker: _Pendente_

---

## 🖼️ Screenshots

### 1. Spark UI (http://localhost:8080)
_Pendente_

### 2. Kibana Dashboard (http://localhost:5601)
_Pendente_

### 3. Elasticsearch Indices
_Pendente_

---

## 🔍 Principais Erros e Correções

Ver arquivo detalhado: [erros_resolvidos.md](erros_resolvidos.md)

---

## 💡 Conclusões

### Benefícios do Spark Streaming em Big Data

1. **Processamento em Tempo Real**
   - Latência baixa (segundos)
   - Ideal para análise de dados contínuos

2. **Escalabilidade Horizontal**
   - Fácil adicionar workers
   - Distribuição automática de carga

3. **Integração com Ecossistema**
   - Kafka para ingestão
   - Elasticsearch para persistência
   - Kibana para visualização

4. **Tolerância a Falhas**
   - Checkpointing automático
   - Reprocessamento em caso de falhas

5. **API de Alto Nível**
   - Abstrações simples (map, reduce, filter)
   - Código Python conciso

### Limitações Identificadas

- Setup inicial complexo
- Múltiplas dependências
- Requer conhecimento de várias tecnologias
- Overhead de rede em ambientes distribuídos

### Aplicações Práticas

- Monitoramento de redes sociais
- Análise de logs em tempo real
- Detecção de fraudes
- IoT e sensores
- Sistemas de recomendação

---

## 📚 Referências

- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Elasticsearch Guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [PySpark Streaming](https://spark.apache.org/docs/latest/streaming-programming-guide.html)

---

**Data:** Novembro 2025  
**Curso:** Programação para Sistemas Paralelos e Distribuídos  
**Instituição:** Universidade de Brasília (UnB)
