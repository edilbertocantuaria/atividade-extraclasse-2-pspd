# 🔍 Guia de Validação - B2 (Spark Streaming)

## Como Saber se B2 Está Funcionando?

Este guia fornece um checklist passo a passo para validar se todo o ambiente está operacional.

---

## ✅ Checklist de Validação

### ETAPA 1: Subir o Ambiente

```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd/spark
docker compose up -d
```

**Validação:**
```bash
docker ps
```

**Esperado:** 6 containers rodando:
- ✅ zookeeper
- ✅ kafka
- ✅ elasticsearch
- ✅ kibana
- ✅ spark-master
- ✅ spark-worker

---

### ETAPA 2: Verificar Logs dos Containers

```bash
# Verificar cada container
docker logs zookeeper
docker logs kafka
docker logs elasticsearch
docker logs kibana
docker logs spark-master
docker logs spark-worker
```

**Esperado:**
- ❌ Nenhum erro crítico
- ✅ Mensagens de inicialização completa

---

### ETAPA 3: Testar Conectividade

```bash
# Do Spark para Kafka
docker exec -it spark-master ping -c 3 kafka

# Do Spark para Elasticsearch
docker exec -it spark-master ping -c 3 elasticsearch

# Verificar portas abertas
curl http://localhost:9200  # Elasticsearch
curl http://localhost:5601  # Kibana
```

**Esperado:**
- ✅ Ping bem-sucedido
- ✅ Elasticsearch retorna JSON com informações do cluster
- ✅ Kibana retorna HTML

---

### ETAPA 4: Criar Tópico Kafka

```bash
docker exec -it kafka kafka-topics.sh \
  --create \
  --topic input-topic \
  --bootstrap-server kafka:9092 \
  --replication-factor 1 \
  --partitions 1
```

**Validação:**
```bash
docker exec -it kafka kafka-topics.sh \
  --list \
  --bootstrap-server kafka:9092
```

**Esperado:**
- ✅ `input-topic` aparece na lista

---

### ETAPA 5: Testar Producer (Produtor de Mensagens)

```bash
# Rodar producer em background
docker exec -d spark-master python3 /opt/spark_app/producer.py
```

**Validação:**
```bash
# Verificar se mensagens estão sendo enviadas
docker logs spark-master
```

**Esperado:**
```
[1] Enviado: python spark bigdata
[2] Enviado: kafka docker cluster
[3] Enviado: streaming data analytics
...
```

---

### ETAPA 6: Testar Consumer (Consumidor de Mensagens)

```bash
# Em um novo terminal, rodar consumer
docker exec -it spark-master python3 /opt/spark_app/consumer.py
```

**Esperado:**
```
Consumer iniciado. Aguardando mensagens...
Recebido: python spark bigdata
Recebido: kafka docker cluster
...
```

**Se funcionar:** ✅ Kafka está OK!

---

### ETAPA 7: Iniciar Spark Streaming

```bash
docker exec -it spark-master spark-submit \
  --packages org.apache.spark:spark-streaming-kafka-0-10_2.12:3.5.0 \
  /opt/spark_app/main.py
```

**Esperado:**
```
-------------------------------------------
Time: 2025-11-09 22:00:00
-------------------------------------------
(python, 5)
(spark, 4)
(bigdata, 3)
...
Enviado ao ES: python -> 5
Enviado ao ES: spark -> 4
```

**Se aparecer:** ✅ Spark Streaming está processando!

---

### ETAPA 8: Verificar Dados no Elasticsearch

```bash
# Listar índices
curl http://localhost:9200/_cat/indices?v

# Buscar dados no índice wordcount
curl http://localhost:9200/wordcount/_search?pretty
```

**Esperado:**
```json
{
  "hits": {
    "total": { "value": 100 },
    "hits": [
      {
        "_source": {
          "word": "spark",
          "count": 15
        }
      }
    ]
  }
}
```

**Se retornar dados:** ✅ Elasticsearch está recebendo!

---

### ETAPA 9: Acessar Kibana

1. Abrir navegador: http://localhost:5601

2. **Criar Data View:**
   - Stack Management → Data Views
   - Create data view
   - Name: `wordcount*`
   - Save

3. **Visualizar Dados:**
   - Analytics → Discover
   - Selecionar `wordcount*`
   - Deve aparecer lista de palavras e contagens

4. **Criar Visualização:**
   - Analytics → Visualize Library
   - Create visualization
   - Tipo: Tag Cloud
   - Configure:
     - Buckets: Terms
     - Field: `word.keyword`
     - Metric: Sum of `count`

5. **Criar Dashboard:**
   - Analytics → Dashboard
   - Add visualization
   - Configurar auto-refresh (10s)

**Se visualizar:** ✅ Kibana funcionando!

---

### ETAPA 10: Validar Fluxo Completo

**Teste End-to-End:**

1. Producer envia "teste teste teste" → Kafka
2. Spark processa → conta 3 ocorrências de "teste"
3. Elasticsearch armazena → {"word": "teste", "count": 3}
4. Kibana exibe → palavra "teste" aparece no dashboard

**Comando de teste:**
```bash
# Enviar mensagem específica
docker exec -it kafka kafka-console-producer.sh \
  --broker-list kafka:9092 \
  --topic input-topic
# Digite: teste teste teste
# Pressione Ctrl+D

# Aguardar 5-10 segundos
# Verificar no Elasticsearch
curl "http://localhost:9200/wordcount/_search?q=word:teste&pretty"
```

---

## 🚨 Troubleshooting Rápido

### Problema: Container não sobe
```bash
docker compose down
docker compose up -d
docker logs <container-name>
```

### Problema: Porta já em uso
```bash
sudo lsof -i :<porta>
sudo kill -9 <PID>
```

### Problema: Spark não conecta ao Kafka
```bash
# Verificar rede
docker network inspect spark_spark-network

# Recriar containers
docker compose down
docker compose up -d
```

### Problema: Elasticsearch sem memória
```bash
# Aumentar memória no docker-compose.yml
ES_JAVA_OPTS=-Xms2g -Xmx2g
```

---

## 📊 Resumo de Portas

| Serviço | Porta | URL |
|---------|-------|-----|
| Kafka | 9092 | - |
| Zookeeper | 2181 | - |
| Elasticsearch | 9200 | http://localhost:9200 |
| Kibana | 5601 | http://localhost:5601 |
| Spark Master UI | 8080 | http://localhost:8080 |
| Spark Master | 7077 | - |

---

## ✅ Checklist Final

- [ ] Todos os 6 containers estão rodando
- [ ] Não há erros nos logs
- [ ] Conectividade entre containers OK
- [ ] Tópico Kafka criado
- [ ] Producer enviando mensagens
- [ ] Consumer recebendo mensagens
- [ ] Spark processando e imprimindo resultados
- [ ] Elasticsearch contém dados do índice wordcount
- [ ] Kibana acessível e exibindo dados
- [ ] Dashboard atualiza em tempo real

**Se todos checados:** 🎉 **B2 está 100% funcional!**

---

## 📸 Evidências Esperadas

1. Screenshot do `docker ps` com 6 containers
2. Screenshot do Spark UI (localhost:8080)
3. Screenshot do output do Spark Streaming
4. Screenshot do curl do Elasticsearch
5. Screenshot do Kibana Dashboard com Word Cloud

---

**Última atualização:** Novembro 2025
