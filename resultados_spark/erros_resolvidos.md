# Erros Encontrados e Resolvidos

## Registro de Problemas e Soluções

### 1. Container Elasticsearch não inicia

**Erro:**
```
elasticsearch exited with code 78
```

**Causa:** 
- Configurações de segurança padrão do Elasticsearch 8.x
- Falta de configuração de memória adequada

**Solução:**
```yaml
environment:
  - xpack.security.enabled=false
  - ES_JAVA_OPTS=-Xms1g -Xmx1g
```

---

### 2. Kafka não aceita conexões do Spark

**Erro:**
```
Failed to connect to kafka:9092
```

**Causa:**
- Listeners não configurados corretamente
- Containers em redes diferentes

**Solução:**
- Adicionar todos os containers à mesma rede Docker
- Configurar `KAFKA_ADVERTISED_LISTENERS` corretamente

---

### 3. Spark não encontra pacotes Kafka

**Erro:**
```
java.lang.ClassNotFoundException: org.apache.spark.streaming.kafka.KafkaUtils
```

**Causa:**
- Dependências Kafka não incluídas no Spark

**Solução:**
```python
spark = SparkSession.builder \
    .config("spark.jars.packages", "org.apache.spark:spark-streaming-kafka-0-10_2.12:3.5.0") \
    .getOrCreate()
```

---

### 4. ElasticSearch rejeita conexões do Spark

**Erro:**
```
ConnectionError: Connection refused
```

**Causa:**
- ElasticSearch ainda não estava pronto quando o Spark tentou conectar

**Solução:**
- Adicionar retry logic
- Usar depends_on no docker-compose
- Adicionar healthcheck

---

### 5. Kibana não encontra índice wordcount

**Erro:**
```
No matching indices found
```

**Causa:**
- Producer não enviou dados ainda
- Spark não processou mensagens

**Solução:**
1. Verificar se o producer está rodando
2. Verificar logs do Spark
3. Confirmar que dados estão no ElasticSearch:
```bash
curl http://localhost:9200/wordcount/_search?pretty
```

---

### 6. Tópico Kafka não existe

**Erro:**
```
org.apache.kafka.common.errors.UnknownTopicOrPartitionException
```

**Causa:**
- Tópico `input-topic` não foi criado

**Solução:**
```bash
docker exec -it kafka kafka-topics.sh --create \
  --topic input-topic \
  --bootstrap-server kafka:9092 \
  --replication-factor 1 \
  --partitions 1
```

---

## Boas Práticas Identificadas

1. **Sempre verificar logs:** `docker logs <container-name>`
2. **Testar conectividade:** `docker exec -it spark-master ping kafka`
3. **Validar cada componente separadamente** antes de integrar
4. **Usar variáveis de ambiente** para facilitar configuração
5. **Implementar tratamento de erros** no código Python

---

**Última atualização:** _Pendente_
