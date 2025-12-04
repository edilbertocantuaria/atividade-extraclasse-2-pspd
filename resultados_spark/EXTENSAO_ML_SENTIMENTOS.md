# Extensão Opcional: Análise de Sentimentos (ML) - B2

**Data:** 29 de Novembro de 2025  
**Localização:** Notebook B2 - Seção 8.4

---

## 📊 Visão Geral

Esta extensão opcional adiciona **análise de sentimentos** ao pipeline B2, enriquecendo a análise de word count com contexto emocional das mensagens.

### Por que Análise de Sentimentos?

- Classifica mensagens como positivas, neutras ou negativas
- Identifica tendências de sentimento em tempo real
- Permite alertas para sentimentos extremos
- Complementa word count com dimensão emocional

---

## 🎓 Fundamentação Teórica

### Biblioteca: VADER

**VADER (Valence Aware Dictionary and sEntiment Reasoner)**

**Características:**
- Desenvolvido especificamente para **textos de redes sociais**
- Modelo léxico (não requer treinamento)
- Considera contexto: negação, intensificadores, pontuação, emojis
- Retorna 4 scores: positivo, negativo, neutro, composto (-1 a +1)

**Referência Principal:**
> Hutto, C.J. & Gilbert, E.E. (2014). VADER: A Parsimonious Rule-based Model for Sentiment Analysis of Social Media Text. *Eighth International Conference on Weblogs and Social Media (ICWSM-14)*. Ann Arbor, MI, June 2014.
> 
> 📄 [Paper Original](http://comp.social.gatech.edu/papers/icwsm14.vader.hutto.pdf)

**Por que VADER e não outras bibliotecas?**

| Biblioteca | Vantagens | Desvantagens | Adequação |
|------------|-----------|--------------|-----------|
| **VADER** | Otimizado para redes sociais, sem treinamento, rápido | Menos preciso que DL | ✅ **IDEAL** |
| TextBlob | Simples, fácil | Genérico, menos preciso | ⚠️ Básico demais |
| NLTK | Configurável | Requer corpus, treinamento | ⚠️ Complexo |
| BERT/Transformers | Muito preciso | Requer GPU, lento | ❌ Overhead alto |

---

## 🔧 Implementação

### Componentes Adicionados ao Notebook

#### 1. Instalação e Teste (Células 51-53)
```python
!pip install -q vaderSentiment
```

**Teste com 5 mensagens exemplo:**
- "Apache Spark is amazing!" → POSITIVO (compound: 0.622)
- "I hate configuration files" → NEGATIVO (compound: -0.571)
- "Kafka provides streaming" → NEUTRO (compound: 0.000)

#### 2. Producer com Sentimentos Variados (Célula 55)
```python
class SentimentProducer(SocialMediaProducer)
```

**Dataset balanceado:**
- 6 mensagens positivas (ex: "I absolutely love working with Spark!")
- 5 mensagens neutras (ex: "Apache Spark processes data...")
- 5 mensagens negativas (ex: "Configuration is frustrating...")
- 3 mensagens mistas (ex: "Powerful but challenging...")

**Total:** 18 templates

#### 3. Consumer com Análise ML (Célula 56)
```python
class SentimentElasticsearchConsumer
```

**Funcionalidades:**
- Analisa sentimento de cada mensagem em tempo real
- Classifica baseado no score composto:
  - `compound >= 0.05` → Positivo
  - `compound <= -0.05` → Negativo
  - `-0.05 < compound < 0.05` → Neutro
- Indexa no Elasticsearch com scores completos
- Mantém estatísticas de distribuição

#### 4. Índice Elasticsearch (Célula 58)
```json
{
  "mappings": {
    "properties": {
      "sentiment_classification": {"type": "keyword"},
      "sentiment_compound": {"type": "float"},
      "sentiment_pos": {"type": "float"},
      "sentiment_neu": {"type": "float"},
      "sentiment_neg": {"type": "float"}
    }
  }
}
```

#### 5. Execução Opcional (Células 59-62)
Células comentadas para execução sob demanda:
- Criar tópico `sentiment-input`
- Iniciar producer com sentimentos (120s, 2 msgs/seg)
- Iniciar consumer com análise VADER (120s, batch=20)

---

## 📈 Visualizações Kibana

### Dashboard de Sentimentos Sugerido

#### 1. Pie Chart - Distribuição
**Configuração:**
- Tipo: Pie Chart
- Metric: Count
- Buckets: Terms by `sentiment_classification.keyword`

**Mostra:** Proporção de mensagens positivas/neutras/negativas

#### 2. Line Chart - Temporal
**Configuração:**
- Tipo: Line
- X-axis: Date Histogram on `timestamp`
- Y-axis: Average of `sentiment_compound`
- Split: Terms by `sentiment_classification.keyword`

**Mostra:** Evolução dos sentimentos ao longo do tempo

#### 3. Data Table - Estatísticas
**Configuração:**
- Rows: Terms by `sentiment_classification.keyword`
- Metrics: Count, Avg/Min/Max of `sentiment_compound`

**Mostra:** Métricas detalhadas por categoria

---

## 🎯 Diferencial deste Trabalho

### 1. Integração com Streaming (Não Batch)
- VADER aplicado em **tempo real** durante indexação
- Não requer processamento batch posterior
- Análise sincronizada com word count

### 2. Pipeline 100% em Notebook
- Todas as operações em células
- Reproduzível sem scripts externos
- Fácil experimentação e ajustes

### 3. Dataset Balanceado
- Mensagens cuidadosamente selecionadas
- Representação equilibrada de sentimentos
- Contextos realistas de Big Data

### 4. Indexação Enriquecida
- Word count + sentimento no mesmo pipeline
- Permite análises multidimensionais
- Correlação entre palavras e sentimentos

---

## 📚 Referências Científicas

### Primárias

1. **Hutto, C.J. & Gilbert, E.E. (2014)**  
   VADER: A Parsimonious Rule-based Model for Sentiment Analysis of Social Media Text.  
   *ICWSM-14*, Ann Arbor, MI.  
   🔗 [Paper](http://comp.social.gatech.edu/papers/icwsm14.vader.hutto.pdf)

2. **Liu, B. (2015)**  
   Sentiment Analysis: Mining Opinions, Sentiments, and Emotions.  
   *Cambridge University Press*.

3. **Medhat, W., Hassan, A., & Korashy, H. (2014)**  
   Sentiment analysis algorithms and applications: A survey.  
   *Ain Shams Engineering Journal*, 5(4), 1093-1113.

### Implementação

4. **vaderSentiment GitHub**  
   🔗 https://github.com/cjhutto/vaderSentiment

5. **Documentation**  
   🔗 https://github.com/cjhutto/vaderSentiment#about-the-scoring

---

## 💡 Exemplos de Uso

### Caso 1: Monitoramento de Satisfação
```
Positivas > 70% → Sistema está bem recebido
Negativas > 30% → Investigar problemas
```

### Caso 2: Alertas em Tempo Real
```
IF sentiment_compound < -0.7 THEN
  trigger_alert("Sentimento extremamente negativo detectado")
```

### Caso 3: Análise de Tendência
```
Comparar sentimento médio entre janelas temporais
Detectar mudanças abruptas no humor
```

---

## 🔬 Métricas de Validação

### Score VADER

**Compound Score (-1 a +1):**
- Fórmula: Normalização de scores individuais
- Threshold padrão: ±0.05
- Interpretação:
  - `> 0.05`: Positivo
  - `< -0.05`: Negativo
  - `-0.05 a 0.05`: Neutro

**Scores Individuais (0 a 1):**
- `pos + neu + neg = 1.0` (normalizado)
- Independentes do compound
- Úteis para análise granular

### Validação do Dataset

**Distribuição Esperada (18 mensagens):**
- Positivas: ~33% (6 mensagens)
- Neutras: ~28% (5 mensagens)
- Negativas: ~28% (5 mensagens)
- Mistas: ~11% (3 mensagens, classificação varia)

---

## 🚀 Como Executar

### Opção 1: Apenas Teste (Recomendado)

Executar células **51-56** do notebook:
1. Instalar VADER
2. Testar com 5 mensagens exemplo
3. Ver implementação de Producer/Consumer

**Tempo:** 2-3 minutos

### Opção 2: Pipeline Completo (Opcional)

Descomentar e executar células **59-62**:
1. Criar tópico `sentiment-input`
2. Iniciar producer (120s)
3. Iniciar consumer (120s)
4. Criar visualizações no Kibana

**Tempo:** ~15 minutos

---

## 📊 Resultados Esperados

### Após Execução Completa

**Elasticsearch:**
- Índice `social-sentiment` com ~240 documentos
- Cada documento com 5 campos de sentimento
- Distribuição balanceada de classificações

**Kibana:**
- Pie Chart mostrando ~33% positivo, ~28% neutro/negativo
- Line Chart com variação temporal
- Data Table com estatísticas agregadas

---

## 🎓 Contribuição Acadêmica

### Originalidade

1. **Integração Streaming + ML**  
   Maioria dos trabalhos usa batch processing

2. **Autocontido em Notebook**  
   Reproduzível sem infraestrutura complexa

3. **Análise Multidimensional**  
   Word count + sentimento simultaneamente

### Possíveis Extensões Futuras

- Comparar VADER vs TextBlob vs BERT
- Análise de sentimento por tópico (LDA + VADER)
- Detecção de anomalias em sentimentos
- Predição de tendências baseada em sentimentos históricos

---

**Implementado por:** Edilberto Cantuaria  
**Data:** 29 de Novembro de 2025  
**Status:** ✅ OPCIONAL - IMPLEMENTADO E DOCUMENTADO
