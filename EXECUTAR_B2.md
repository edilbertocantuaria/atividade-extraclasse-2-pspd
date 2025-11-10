# 🚀 Guia de Execução - B2 (Apache Spark Streaming)

## 📋 Visão Geral

Este guia contém todas as instruções para executar o ambiente B2 (Apache Spark + Kafka + Elasticsearch + Kibana) do zero até ficar 100% funcional.

**Tecnologias:** Apache Spark 3.4.1, Kafka, Elasticsearch 8.12, Kibana, Zookeeper

---

## 📦 Pré-requisitos

Antes de começar, certifique-se de ter instalado:

- **Docker** (versão 20.10 ou superior)
- **Docker Compose** (versão 2.0 ou superior)
- **Git** (para clonar o repositório)
- **curl** (para testes)

### Verificar Instalações

```bash
docker --version
docker compose version
git --version
curl --version
```

---

## 📁 Estrutura do Projeto B2

```
atividade-extraclasse-2-pspd/
├── spark/
│   ├── docker-compose.yml          # Orquestração de containers
│   ├── Dockerfile                  # Imagem customizada do Spark
│   ├── testar_ambiente.sh          # Script de validação automática
│   ├── spark_app/
│   │   ├── main.py                 # Aplicação Spark Streaming
│   │   ├── producer.py             # Produtor de mensagens Kafka
│   │   ├── consumer.py             # Consumidor de mensagens Kafka
│   │   ├── requirements.txt        # Dependências Python
│   │   └── utils/
│   │       └── text_source.py      # Gerador de texto aleatório
│   ├── elastic/
│   │   ├── elasticsearch.yml       # Configuração Elasticsearch
│   │   └── kibana.yml              # Configuração Kibana
│   └── notebooks/
│       └── spark_lab.ipynb         # Jupyter Notebook demonstrativo
│
└── resultados_spark/
    ├── VALIDACAO_B2.md             # Checklist de validação detalhado
    ├── testes_kafka.md             # Documentação testes Kafka
    ├── testes_graficos.md          # Documentação visualizações
    ├── erros_resolvidos.md         # Troubleshooting
    └── relatorio_final_spark.md    # Relatório técnico completo
```

---

## 🚀 Passo a Passo para Execução

### PASSO 1: Clonar o Repositório (se necessário)

```bash
git clone https://github.com/edilbertocantuaria/atividade-extraclasse-2-pspd.git
cd atividade-extraclasse-2-pspd
```

### PASSO 2: Navegar para o Diretório Spark

```bash
cd spark
```

### PASSO 3: Subir o Ambiente Completo

```bash
docker compose up -d
```

**Tempo estimado:** 3-5 minutos (primeira execução com download de imagens)

**Saída esperada:**
```
[+] Running 7/7
 ✔ Network spark_spark-network  Created
 ✔ Container zookeeper          Started
 ✔ Container elasticsearch      Started
 ✔ Container kibana             Started
 ✔ Container kafka              Started
 ✔ Container spark-master       Started
 ✔ Container spark-worker       Started
```

### PASSO 4: Verificar Status dos Containers

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Esperado:** 6 containers com status "Up"
- `zookeeper`
- `kafka`
- `elasticsearch`
- `kibana`
- `spark-master`
- `spark-worker`

### PASSO 5: Aguardar Inicialização Completa

Aguarde 30-60 segundos para todos os serviços iniciarem completamente.

**Verificar logs:**
```bash
# Elasticsearch (deve mostrar "GREEN")
docker logs elasticsearch 2>&1 | grep -i "green"

# Kafka (deve mostrar "started")
docker logs kafka 2>&1 | grep -i "started"

# Spark Master
docker logs spark-master 2>&1 | grep -i "started"
```

### PASSO 6: Criar Tópico Kafka

```bash
docker exec -it kafka kafka-topics --create \
  --topic input-topic \
  --bootstrap-server kafka:9092 \
  --replication-factor 1 \
  --partitions 1
```

**Saída esperada:**
```
Created topic input-topic.
```

**Verificar tópico criado:**
```bash
docker exec kafka kafka-topics --list --bootstrap-server kafka:9092
```

### PASSO 7: Testar Conectividade

```bash
# Elasticsearch
curl http://localhost:9200
# Deve retornar JSON com informações do cluster

# Kibana
curl http://localhost:5601
# Deve retornar HTML

# Spark Master UI
curl http://localhost:8080
# Deve retornar HTML
```

### PASSO 8: Executar Validação Automática

```bash
chmod +x testar_ambiente.sh
./testar_ambiente.sh
```

**Saída esperada:**
```
✅ Containers rodando
✅ Elasticsearch acessível
✅ Tópico input-topic existe
✅ Producer iniciado
✅ Consumer recebendo mensagens
✅ Spark UI acessível
✅ Kibana acessível
```

---

## 🧪 Testando o Pipeline Completo

### TESTE 1: Producer (Produtor de Mensagens)

**Iniciar producer em background:**
```bash
docker exec -d spark-master python3 /opt/spark_app/producer.py
```

**Verificar mensagens sendo enviadas:**
```bash
docker logs spark-master 2>&1 | grep "Enviado:"
```

**Saída esperada:**
```
[1] Enviado: spark kafka bigdata
[2] Enviado: python docker cluster
[3] Enviado: elasticsearch kibana streaming
...
```

### TESTE 2: Consumer (Consumidor de Mensagens)

**Em um novo terminal, rodar consumer:**
```bash
docker exec -it spark-master python3 /opt/spark_app/consumer.py
```

**Saída esperada:**
```
Consumer iniciado. Aguardando mensagens...
Recebido: spark kafka bigdata
Recebido: python docker cluster
Recebido: elasticsearch kibana streaming
...
```

**Pressione Ctrl+C para parar o consumer**

✅ **Se chegou até aqui:** Kafka está funcionando perfeitamente!

### TESTE 3: Spark Streaming (WordCount em Tempo Real)

**Iniciar aplicação Spark Streaming:**
```bash
docker exec -it spark-master spark-submit \
  --packages org.apache.spark:spark-streaming-kafka-0-10_2.12:3.4.1 \
  /opt/spark_app/main.py
```

**Saída esperada (a cada 5 segundos):**
```
-------------------------------------------
Time: 2025-11-10 01:45:00
-------------------------------------------
(spark, 15)
(kafka, 12)
(python, 10)
(bigdata, 8)
...
Enviado ao ES: spark -> 15
Enviado ao ES: kafka -> 12
```

✅ **Se aparecer essa saída:** Spark Streaming está processando!

**Deixe rodando por 2-3 minutos para acumular dados**

### TESTE 4: Verificar Dados no Elasticsearch

**Em outro terminal:**
```bash
# Listar índices
curl http://localhost:9200/_cat/indices?v

# Buscar dados do índice wordcount
curl "http://localhost:9200/wordcount/_search?pretty&size=20"
```

**Saída esperada:**
```json
{
  "hits": {
    "total": { "value": 150 },
    "hits": [
      {
        "_source": {
          "word": "spark",
          "count": 15
        }
      },
      {
        "_source": {
          "word": "kafka",
          "count": 12
        }
      }
    ]
  }
}
```

✅ **Se retornar dados:** Elasticsearch está recebendo!

### TESTE 5: Visualizar no Kibana

**1. Acessar Kibana:**
```
http://localhost:5601
```

**2. Criar Data View:**
- Clicar em ☰ (menu hamburger) → Stack Management
- Data Views → Create data view
- **Name:** `wordcount*`
- **Index pattern:** `wordcount*`
- **Timestamp field:** Selecionar "I don't want to use the time filter"
- Click "Save data view to Kibana"

**3. Visualizar Dados:**
- ☰ → Analytics → Discover
- Selecionar data view `wordcount*`
- Você deve ver a lista de palavras e contagens

**4. Criar Visualização (Word Cloud):**
- ☰ → Analytics → Visualize Library
- Create visualization → Lens
- Drag & drop:
  - **Vertical axis:** `count` (Sum)
  - **Horizontal axis:** `word.keyword` (Top 20)
- Escolher tipo de gráfico: Bar chart ou Table
- Save: "WordCount Real-Time"

**5. Criar Dashboard:**
- ☰ → Analytics → Dashboard
- Create dashboard
- Add from library → Selecionar "WordCount Real-Time"
- Configurar auto-refresh: (ícone de relógio) → 10 seconds
- Save dashboard: "Spark Streaming Dashboard"

✅ **Dashboard atualiza a cada 10 segundos automaticamente!**

---

## 🌐 Portas e Acessos

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **Spark Master UI** | http://localhost:8080 | Interface do Spark (jobs, workers) |
| **Kibana** | http://localhost:5601 | Dashboard e visualizações |
| **Elasticsearch** | http://localhost:9200 | API REST do Elasticsearch |
| **Kafka** | localhost:9092 | Broker Kafka (interno) |
| **Zookeeper** | localhost:2181 | Coordenação Kafka (interno) |

---

## ✅ Checklist de Validação Completa

Use este checklist para garantir que tudo está funcionando:

- [ ] 6 containers rodando (`docker ps`)
- [ ] Elasticsearch retorna JSON em http://localhost:9200
- [ ] Kibana acessível em http://localhost:5601
- [ ] Spark UI acessível em http://localhost:8080
- [ ] Tópico `input-topic` criado no Kafka
- [ ] Producer enviando mensagens
- [ ] Consumer recebendo mensagens
- [ ] Spark Streaming imprimindo WordCount a cada 5s
- [ ] Elasticsearch contém índice `wordcount` com dados
- [ ] Kibana exibe dados do índice `wordcount`
- [ ] Dashboard Kibana atualiza automaticamente

**Se todos marcados:** 🎉 **B2 está 100% funcional!**

---

## 🛑 Parar e Limpar o Ambiente

### Parar Containers (mantém dados)
```bash
docker compose stop
```

### Parar e Remover Containers
```bash
docker compose down
```

### Limpar Completamente (incluindo volumes)
```bash
docker compose down -v
docker system prune -f
```

### Reiniciar do Zero
```bash
docker compose down -v
docker compose up -d
# Repetir PASSO 6 em diante
```

---

## 🐛 Troubleshooting (Resolução de Problemas)

### Problema 1: Container não sobe

**Sintoma:** `docker compose up -d` falha

**Solução:**
```bash
# Ver logs de erro
docker compose logs

# Reconstruir imagens
docker compose build --no-cache
docker compose up -d
```

### Problema 2: Porta já em uso

**Sintoma:** `Error: port is already allocated`

**Solução:**
```bash
# Identificar processo usando a porta
sudo lsof -i :9200  # Substituir pelo número da porta

# Matar processo
sudo kill -9 <PID>

# Ou alterar porta no docker-compose.yml
```

### Problema 3: Elasticsearch não inicia (memória)

**Sintoma:** Elasticsearch morre constantemente

**Solução:**
```bash
# Aumentar memória no docker-compose.yml
# Alterar de -Xms1g -Xmx1g para -Xms2g -Xmx2g
```

### Problema 4: Kafka não conecta

**Sintoma:** Producer ou Consumer não conseguem conectar

**Solução:**
```bash
# Verificar se tópico existe
docker exec kafka kafka-topics --list --bootstrap-server kafka:9092

# Recriar tópico
docker exec kafka kafka-topics --delete --topic input-topic --bootstrap-server kafka:9092
docker exec kafka kafka-topics --create --topic input-topic --bootstrap-server kafka:9092 --replication-factor 1 --partitions 1
```

### Problema 5: Spark não processa mensagens

**Sintoma:** Spark inicia mas não mostra WordCount

**Solução:**
```bash
# Verificar se producer está rodando
docker logs spark-master 2>&1 | grep "Enviado"

# Reiniciar producer
docker exec -d spark-master python3 /opt/spark_app/producer.py

# Verificar logs do Spark
docker logs spark-master
```

### Problema 6: Kibana não mostra dados

**Sintoma:** Data view vazio

**Solução:**
```bash
# Verificar se dados estão no Elasticsearch
curl "http://localhost:9200/wordcount/_count"

# Se retornar count: 0, reiniciar Spark Streaming
# Se retornar count > 0, recriar data view no Kibana
```

### Problema 7: Permissões negadas

**Sintoma:** `Permission denied`

**Solução:**
```bash
# Dar permissão ao script
chmod +x testar_ambiente.sh

# Ou rodar com sudo
sudo docker compose up -d
```

---

## 📊 Comandos Úteis

### Logs em Tempo Real
```bash
# Todos os containers
docker compose logs -f

# Container específico
docker logs -f spark-master
docker logs -f kafka
docker logs -f elasticsearch
```

### Entrar em um Container
```bash
docker exec -it spark-master bash
docker exec -it kafka bash
```

### Verificar Recursos
```bash
# CPU e memória dos containers
docker stats

# Espaço em disco
docker system df
```

### Limpar Dados do Elasticsearch
```bash
# Deletar índice wordcount
curl -X DELETE "http://localhost:9200/wordcount"

# Recriar do zero
# (Spark vai recriar automaticamente quando processar dados)
```

---

## 📚 Arquivos de Documentação

Para mais detalhes técnicos, consulte:

- **`resultados_spark/VALIDACAO_B2.md`** - Guia detalhado de validação passo a passo
- **`resultados_spark/testes_kafka.md`** - Documentação completa dos testes Kafka
- **`resultados_spark/testes_graficos.md`** - Como criar visualizações no Kibana
- **`resultados_spark/erros_resolvidos.md`** - Erros comuns e suas soluções
- **`resultados_spark/relatorio_final_spark.md`** - Relatório técnico completo

---

## 🎓 Entendendo o Fluxo de Dados

```
┌─────────────┐
│  Producer   │  1. Gera frases aleatórias com palavras técnicas
│  (Python)   │  2. Envia para tópico Kafka "input-topic"
└──────┬──────┘
       │
       v
┌─────────────┐
│   Kafka     │  3. Armazena mensagens em fila
│  (Broker)   │  4. Distribui para consumidores
└──────┬──────┘
       │
       v
┌─────────────┐
│   Spark     │  5. Consome mensagens a cada 5 segundos (micro-batch)
│  Streaming  │  6. Faz WordCount (conta palavras)
└──────┬──────┘  7. Agrega contagens
       │
       v
┌──────────────┐
│Elasticsearch│  8. Armazena resultados no índice "wordcount"
│   (Index)   │  9. Indexa para busca rápida
└──────┬───────┘
       │
       v
┌─────────────┐
│   Kibana    │  10. Visualiza dados em dashboard
│ (Dashboard) │  11. Atualiza automaticamente a cada 10s
└─────────────┘
```

---

## 🎯 Objetivos de Aprendizado

Ao executar este projeto, você aprende:

- ✅ Orquestração multi-container com Docker Compose
- ✅ Mensageria com Apache Kafka
- ✅ Processamento de streaming com Apache Spark
- ✅ Armazenamento e busca com Elasticsearch
- ✅ Visualização de dados com Kibana
- ✅ Integração de componentes Big Data
- ✅ Troubleshooting de sistemas distribuídos

---

## 📝 Notas Importantes

1. **Primeira execução é mais lenta** devido ao download das imagens Docker (~2-3 GB)
2. **Requer ~4-6 GB de RAM** disponível para rodar todos os containers
3. **Producer roda indefinidamente** até ser parado manualmente
4. **Dados são perdidos** ao fazer `docker compose down -v`
5. **Kibana demora ~1 minuto** para inicializar completamente
6. **Elasticsearch requer vm.max_map_count configurado** em alguns sistemas Linux:
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   ```

---

## ✨ Créditos

**Disciplina:** Programação para Sistemas Paralelos e Distribuídos (PSPD)  
**Instituição:** Universidade de Brasília (UnB)  
**Data:** Novembro 2025  

---

## 📧 Suporte

Para dúvidas ou problemas:

1. Consulte a seção **Troubleshooting** acima
2. Verifique os logs: `docker compose logs`
3. Consulte `resultados_spark/erros_resolvidos.md`
4. Abra uma issue no repositório GitHub

---

**🚀 Bom aprendizado!**
