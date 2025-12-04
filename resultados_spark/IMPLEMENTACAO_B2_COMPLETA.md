# Implementação B2 - Spark Structured Streaming (COMPLETA)

**Data:** 29 de Novembro de 2025  
**Disciplina:** PSPD - Programação para Sistemas Paralelos e Distribuídos  
**Atividade:** Extra-Classe 2 - Parte B2

---

## ✅ Status: IMPLEMENTAÇÃO COMPLETA

Todos os requisitos da parte B2 foram implementados no notebook autocontido:

📓 **Arquivo:** `spark/notebooks/B2_SPARK_STREAMING_COMPLETO.ipynb`

---

## 📋 Checklist de Requisitos

### ✅ 1. Entrada via Rede Social com Kafka

#### ✅ 1.1 Justificativa para Alternativa ao Discord
- **Localização:** Seção 1 do notebook (células 1-2)
- **Conteúdo:**
  - Explicação detalhada das limitações técnicas do Discord
  - Razões de inviabilidade: OAuth complexo, WebSocket persistente, rate limits
  - Alternativa escolhida: Producer Python com geração sintética
  - Vantagens da alternativa: reprodutibilidade, controle total, sem dependências externas

#### ✅ 1.2 Producer Kafka Implementado
- **Localização:** Seção 3 do notebook (células 11-17)
- **Classe:** `SocialMediaProducer`
- **Funcionalidades:**
  - Geração de mensagens JSON simulando rede social
  - Campos: `user`, `text`, `timestamp`, `platform`, `message_id`
  - Dataset sintético com 15 mensagens realistas sobre Big Data
  - Taxa configurável (padrão: 3 msgs/seg)
  - Execução em background thread
  - Contador de mensagens enviadas

#### ✅ 1.3 Documentação da Implementação
- **Localização:** Seção 1 e 3 do notebook
- **Conteúdo:**
  - Código completo do producer comentado
  - Explicação do formato JSON das mensagens
  - Instruções de execução
  - Teste de envio de amostra (20 mensagens)
  - Verificação de mensagens no tópico Kafka

---

### ✅ 2. Pipeline Spark Structured Streaming

#### ✅ 2.1 Configuração e Leitura do Stream
- **Localização:** Seção 4 do notebook (células 19-23)
- **Implementação:**
  - Sessão Spark com suporte Kafka (pacote `spark-sql-kafka-0-10`)
  - Schema JSON definido para mensagens de entrada
  - Leitura do tópico `social-input`
  - Deserialização JSON com `from_json()`

#### ✅ 2.2 Processamento Word Count
- **Localização:** Seção 4.4 do notebook (célula 24)
- **Pipeline:**
  1. Extração de palavras com `split()` e `explode()`
  2. Normalização: lowercase e remoção de pontuação
  3. Agregação com janelas temporais (30s, slide 10s)
  4. Watermark de 1 minuto para eventos atrasados
  5. Contagem por palavra e janela

#### ✅ 2.3 Publicação no Tópico de Saída
- **Localização:** Seção 4.5 do notebook (célula 25)
- **Implementação:**
  - Conversão para JSON com `to_json(struct())`
  - Escrita no tópico `wordcount-output`
  - Checkpoint para recuperação de falhas
  - Output mode: `update`

#### ✅ 2.4 Visualização Debug
- **Localização:** Seção 4.6 do notebook (célula 26)
- **Funcionalidade:**
  - Query adicional para console (debug)
  - Mostra top 20 word counts em tempo real
  - Útil para validação durante desenvolvimento

---

### ✅ 3. Consumer Elasticsearch

#### ✅ 3.1 Criação do Índice
- **Localização:** Seção 6.1 do notebook (célula 37)
- **Configuração:**
  - Índice: `wordcount-realtime`
  - Mapping otimizado:
    - `word`: keyword (para agregações)
    - `count`: integer
    - `window_start`: date
    - `window_end`: date
    - `indexed_at`: date (timestamp de indexação)

#### ✅ 3.2 Consumer Kafka → Elasticsearch
- **Localização:** Seção 6.2 do notebook (célula 38)
- **Classe:** `ElasticsearchConsumer`
- **Funcionalidades:**
  - Consumo do tópico `wordcount-output`
  - Deserialização JSON automática
  - Indexação em batch (30 documentos por vez)
  - Execução em background thread
  - Contador de documentos indexados
  - Tratamento de erros e cleanup

#### ✅ 3.3 Execução e Validação
- **Localização:** Seções 6.3 e 6.4 do notebook (células 39-41)
- **Funcionalidades:**
  - Inicialização do consumer em thread separada
  - Aguardar 90s para acumular dados
  - Verificação da contagem de documentos
  - Amostra dos top 10 word counts indexados

---

### ✅ 4. Dashboard Kibana

#### ✅ 4.1 Instruções Detalhadas para Tag Cloud
- **Localização:** Seção 7.1 do notebook (célula 42)
- **Passo a Passo Completo:**

**Passo 1: Acessar Kibana**
- URL: http://localhost:5601
- Aguardar carregamento

**Passo 2: Criar Index Pattern**
- Stack Management → Data Views → Create data view
- Name: `WordCount Real-Time`
- Index pattern: `wordcount-realtime*`
- Timestamp field: `window_start`

**Passo 3: Criar Visualização Tag Cloud**
- Visualize Library → Create visualization
- Tipo: Tag Cloud
- Configuração:
  - Buckets → Tags:
    - Aggregation: `Terms`
    - Field: `word.keyword`
    - Order By: `Metric: Count`
    - Order: `Descending`
    - Size: `50` (top 50 palavras)
  - Metrics:
    - Aggregation: `Sum`
    - Field: `count`
- Update e Save: `Word Cloud - Social Media Stream`

**Passo 4: Criar Dashboard**
- Dashboard → Create dashboard
- Adicionar visualizações:
  - Word Cloud principal
  - Vertical Bar: Count por janela temporal
  - Data Table: Top 20 palavras
  - Metric: Total de palavras únicas
- Auto-refresh: 10 segundos
- Save: `B2 - Real-Time Word Count Analytics`

#### ✅ 4.2 Alternativas ao Tag Cloud
- **Localização:** Seção 7.2 do notebook (célula 42)
- **3 Alternativas Documentadas:**

**Opção A: Horizontal Bar Chart**
- Tipo: `Horizontal Bar`
- Y-axis: `word.keyword` (Terms, top 30)
- X-axis: `count` (Sum)
- Uso: Palavras mais frequentes em barras horizontais

**Opção B: Data Table**
- Tipo: `Data Table`
- Rows: `word.keyword` (Terms, top 50)
- Metrics: `count` (Sum)
- Uso: Tabela ordenada por contagem

**Opção C: Treemap**
- Tipo: `Treemap`
- Groups: `word.keyword` (Terms, top 40)
- Size: `count` (Sum)
- Uso: Blocos proporcionais à frequência

#### ✅ 4.3 Instruções para Screenshots
- **Localização:** Seção 7.3 do notebook (célula 42)
- **Ação Manual Requerida:**
  1. Capturar screenshot do dashboard completo
  2. Salvar: `resultados_spark/kibana_dashboard_wordcloud.png`
  3. Capturar Tag Cloud isolada
  4. Salvar: `resultados_spark/kibana_tagcloud_detail.png`

#### ✅ 4.4 Verificação via API
- **Localização:** Seção 7.4 do notebook (célula 43)
- **Funcionalidades:**
  - Verificação de status do Kibana
  - Estatísticas do índice Elasticsearch
  - Contagem de documentos
  - Tamanho em disco

---

## 🏗️ Arquitetura Implementada

```
┌─────────────────────┐
│  Producer Python    │  (Seção 3)
│  SocialMedia        │  - Geração sintética
│  Simulator          │  - 3 msgs/seg
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Kafka Topic        │
│  social-input       │  (Seção 2.4)
│  (3 partitions)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Spark Streaming    │  (Seção 4)
│  - Read Stream      │  - Window 30s/10s
│  - Word Count       │  - Watermark 1min
│  - Aggregation      │
└──────┬──────┬───────┘
       │      │
       │      ▼
       │   ┌─────────────────┐
       │   │  Console Debug  │  (Seção 4.6)
       │   │  (20 rows)      │
       │   └─────────────────┘
       │
       ▼
┌─────────────────────┐
│  Kafka Topic        │
│  wordcount-output   │  (Seção 4.5)
│  (3 partitions)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  ES Consumer        │  (Seção 6)
│  - Batch indexing   │  - Batch size: 30
│  - Background       │  - Duration: 120s
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Elasticsearch      │  (Seção 6.1)
│  Index:             │
│  wordcount-realtime │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Kibana Dashboard   │  (Seção 7)
│  - Tag Cloud        │  - Instruções completas
│  - Metrics          │  - 3 alternativas
│  - Time Series      │  - Screenshots pending
└─────────────────────┘
```

---

## 📊 Parâmetros de Configuração

| Componente | Parâmetro | Valor | Localização |
|------------|-----------|-------|-------------|
| **Producer** | Taxa de mensagens | 3 msgs/seg | Seção 5.1, célula 31 |
| **Producer** | Duração | 180 segundos | Seção 5.1, célula 31 |
| **Producer** | Dataset | 15 mensagens + 8 usuários | Seção 3.2, célula 13 |
| **Kafka Input** | Tópico | `social-input` | Seção 2.4, célula 9 |
| **Kafka Input** | Partições | 3 | Seção 2.4, célula 9 |
| **Kafka Output** | Tópico | `wordcount-output` | Seção 2.4, célula 9 |
| **Kafka Output** | Partições | 3 | Seção 2.4, célula 9 |
| **Spark** | Janela temporal | 30 segundos | Seção 4.4, célula 24 |
| **Spark** | Slide | 10 segundos | Seção 4.4, célula 24 |
| **Spark** | Watermark | 1 minuto | Seção 4.4, célula 24 |
| **Spark** | Output mode | update | Seção 4.5, célula 25 |
| **ES Consumer** | Batch size | 30 documentos | Seção 6.2, célula 38 |
| **ES Consumer** | Duração | 120 segundos | Seção 6.3, célula 39 |
| **Elasticsearch** | Índice | `wordcount-realtime` | Seção 6.1, célula 37 |
| **Kibana** | Auto-refresh | 10 segundos | Seção 7.1, célula 42 |

---

## 🔧 Tecnologias e Versões

| Tecnologia | Versão | Uso |
|------------|--------|-----|
| Apache Spark | 3.5.0 | Processamento de streaming |
| PySpark | 3.5.0 | API Python para Spark |
| Apache Kafka | 7.5.0 (Confluent) | Sistema de mensageria |
| Elasticsearch | 8.12.0 | Indexação e busca |
| Kibana | 8.12.0 | Visualização de dados |
| kafka-python | latest | Cliente Kafka para Python |
| elasticsearch-py | latest | Cliente ES para Python |
| Docker Compose | - | Orquestração de containers |

---

## 🎯 Diferenciais da Implementação

### 1. Execução 100% Autocontida
- ✅ Todas as operações em células do notebook
- ✅ Nenhuma dependência de scripts externos
- ✅ Setup de infraestrutura via células Python
- ✅ Producer e Consumer em threads dentro do notebook
- ✅ Monitoramento e estatísticas integrados

### 2. Justificativa Técnica Robusta
- ✅ Análise detalhada das limitações do Discord
- ✅ Comparação entre alternativas
- ✅ Referências oficiais (Discord API, Kafka Docs)
- ✅ Explicação das vantagens da solução escolhida

### 3. Pipeline Completo Kafka → Spark → ES
- ✅ Producer sintético realista
- ✅ Processamento com janelas temporais
- ✅ Watermark para eventos atrasados
- ✅ Consumer otimizado com batch indexing
- ✅ Queries múltiplas (output + debug)

### 4. Instruções Kibana Detalhadas
- ✅ Passo a passo com screenshots mencionados
- ✅ 3 alternativas ao Tag Cloud
- ✅ Configuração de dashboard completo
- ✅ Auto-refresh para tempo real
- ✅ Verificação via API

### 5. Monitoramento e Validação
- ✅ Verificação de saúde de todos os serviços
- ✅ Contadores de mensagens e documentos
- ✅ Estatísticas finais consolidadas
- ✅ Top 20 palavras mais frequentes
- ✅ Visualização de amostra

---

## 📝 Como Executar

### Pré-requisitos
```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd/spark
docker-compose up -d
```

### Execução do Notebook
1. Abrir: `spark/notebooks/B2_SPARK_STREAMING_COMPLETO.ipynb`
2. Executar células sequencialmente (Shift+Enter)
3. Aguardar 3-4 minutos para acumular dados
4. Acessar Kibana: http://localhost:5601
5. Seguir instruções da Seção 7 para criar dashboard
6. Capturar screenshots

### Ordem de Execução
1. **Seção 1-2:** Leitura e contexto (markdown)
2. **Seção 2:** Configuração e inicialização Docker
3. **Seção 3:** Teste do producer (20 mensagens)
4. **Seção 4:** Setup do pipeline Spark
5. **Seção 5:** Iniciar producer em background
6. **Seção 6:** Criar índice ES e iniciar consumer
7. **Seção 7:** Criar visualizações no Kibana
8. **Seção 8:** Parar queries e gerar estatísticas

### Tempo Estimado
- Setup inicial: 2-3 minutos (Docker + Kafka + ES/Kibana)
- Execução pipeline: 3-4 minutos (producer + streaming + indexing)
- Criação dashboard Kibana: 5-7 minutos (manual)
- **Total:** ~15 minutos

---

## 🎓 Conclusões

### Objetivos Alcançados

✅ **Entrada via Kafka com Justificativa**
- Alternativa ao Discord implementada e justificada tecnicamente
- Producer sintético realista e configurável
- Documentação completa da implementação

✅ **Pipeline Spark Structured Streaming**
- Leitura, processamento e escrita em Kafka
- Agregações com janelas temporais
- Watermark para eventos atrasados

✅ **Saída com Elasticsearch**
- Consumer implementado com batch indexing
- Índice otimizado com mapping correto
- Validação de documentos indexados

✅ **Dashboard Kibana**
- Instruções detalhadas para Tag Cloud
- 3 alternativas documentadas
- Configuração de dashboard completo
- Verificação via API

✅ **Execução Autocontida**
- 100% das operações em células do notebook
- Nenhum script externo necessário
- Infraestrutura gerenciada via Docker

### Próximos Passos

**Único item pendente:**
- [ ] Capturar screenshots do dashboard Kibana (ação manual)
  - `resultados_spark/kibana_dashboard_wordcloud.png`
  - `resultados_spark/kibana_tagcloud_detail.png`

### Extensão Implementada: Análise de Sentimentos (ML)

✅ **Seção 8.4 do Notebook - OPCIONAL**

**Biblioteca:** VADER (Valence Aware Dictionary and sEntiment Reasoner)

**Referência Principal:**
> Hutto, C.J. & Gilbert, E.E. (2014). VADER: A Parsimonious Rule-based Model for Sentiment Analysis of Social Media Text. Eighth International Conference on Weblogs and Social Media (ICWSM-14).

**Funcionalidades Implementadas:**
- Instalação e teste de VADER
- Producer com mensagens de sentimento variado (positivo, neutro, negativo)
- Consumer que analisa sentimento em tempo real
- Indexação no Elasticsearch com scores de sentimento
- Instruções para visualizações no Kibana (Pie Chart, Line Chart)

**Diferencial:**
- Integração nativa com Kafka Streaming (não batch)
- Análise em tempo real durante indexação
- Pipeline 100% em notebook
- Dataset balanceado com 18 mensagens de sentimentos variados

**Como Executar:** 
Descomente as células da Seção 8.4.6 do notebook para testar análise de sentimentos.

### Melhorias Futuras Adicionais

- Filtro de stop words (the, and, is, etc.)
- Agregações por usuário e período do dia
- Alertas no Kibana para palavras ou sentimentos específicos
- Kafka com replicação para HA
- Modelos deep learning (BERT/Transformers)

---

## 📚 Referências

1. [Apache Spark Structured Streaming Programming Guide](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html)
2. [Kafka Documentation - Streams](https://kafka.apache.org/documentation/streams/)
3. [Elasticsearch Python Client](https://elasticsearch-py.readthedocs.io/)
4. [Kibana Visualizations Guide](https://www.elastic.co/guide/en/kibana/current/dashboard.html)
5. [Discord Developer Documentation - Rate Limits](https://discord.com/developers/docs/topics/rate-limits)
6. [PySpark SQL Functions](https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/functions.html)

---

**Implementado por:** Edilberto Cantuaria  
**Data:** 29 de Novembro de 2025  
**Disciplina:** PSPD - UnB  
**Status:** ✅ COMPLETO (pendente apenas screenshots manuais)
