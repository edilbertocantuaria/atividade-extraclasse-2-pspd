# Testes Kafka

## Objetivo
Validar a comunicação entre Producer e Consumer através do Apache Kafka.

## Configuração
- **Zookeeper**: Porta 2181
- **Kafka Broker**: Porta 9092
- **Tópico**: input-topic
- **Replication Factor**: 1
- **Partitions**: 1

## Testes Realizados

### 1. Criação do Tópico
```bash
docker exec -it kafka kafka-topics.sh --create --topic input-topic --bootstrap-server kafka:9092 --replication-factor 1 --partitions 1
```

**Resultado esperado**: Tópico criado com sucesso

### 2. Listar Tópicos
```bash
docker exec -it kafka kafka-topics.sh --list --bootstrap-server kafka:9092
```

**Resultado esperado**: input-topic deve aparecer na lista

### 3. Teste do Producer
```bash
docker exec -it spark-master python3 /opt/spark_app/producer.py
```

**Métricas a observar**:
- Mensagens enviadas por segundo
- Latência de envio
- Erros de conexão

### 4. Teste do Consumer
```bash
docker exec -it spark-master python3 /opt/spark_app/consumer.py
```

**Validações**:
- [ ] Consumer recebe todas as mensagens enviadas
- [ ] Mensagens chegam na ordem correta
- [ ] Não há perda de mensagens

## Resultados

_A ser preenchido após execução dos testes_

| Teste | Status | Observações |
|-------|--------|-------------|
| Criação do tópico | | |
| Producer funcionando | | |
| Consumer recebendo | | |
| Latência | | |

## Problemas Encontrados

_Documentar aqui qualquer erro ou problema durante os testes_

## Conclusões

_Análise dos resultados e próximos passos_
