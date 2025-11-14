# B2 - Apache Spark: Pipeline de Processamento Streaming

## 📋 Visão Geral

Este notebook implementa um pipeline completo de processamento de stream usando **Apache Spark Structured Streaming** com integração **Kafka** para entrada e saída de dados, conforme especificação do laboratório B2.

## 🎯 Objetivo

Criar um sistema de WordCount em tempo real que:
- Consome mensagens de um stream (simulando rede social)
- Processa com Spark Structured Streaming
- Gera visualizações dinâmicas dos resultados

## 📦 Arquivo Principal

- **`B2_pipeline.ipynb`**: Notebook Jupyter auto-contido com todas as etapas

## 🚀 Como Executar

### Opção 1: Google Colab (Recomendado)

1. Fazer upload do notebook `B2_pipeline.ipynb` no Google Colab
2. Executar células sequencialmente (`Runtime > Run all`)
3. Aguardar instalação automática de dependências (~2-3 minutos)
4. Visualizar gráficos inline

### Opção 2: Jupyter Local

```bash
# 1. Instalar dependências
pip install pyspark==3.5.0 kafka-python wordcloud matplotlib pandas numpy jupyter

# 2. Garantir Java instalado (necessário para Spark)
java -version  # Deve ser Java 8 ou 11

# 3. Iniciar Jupyter
jupyter notebook

# 4. Abrir B2_pipeline.ipynb e executar células
```

## 📊 Estrutura do Notebook

### 1. Inicializações
- Detecção de ambiente (Colab/Local)
- Instalação de dependências Python
- Download e setup do Apache Kafka

### 2. Configuração de Visualização
- Preparação de diretórios de trabalho
- Imports de bibliotecas de plots

### 3. Setup do Apache Spark
- Criação de SparkSession com suporte Kafka
- Configuração de checkpoints e memória

### 4. Setup do Kafka
- Inicialização de Zookeeper e Kafka broker
- Criação de tópicos `social-input` e `wordcount-output`

### 5. Producer (Entrada)
**⚠️ Adaptação:** Gerador de texto ao invés de Discord

- **Motivo:** APIs de redes sociais exigem tokens, configurações externas e não são reproduzíveis facilmente
- **Solução:** `SocialMediaSimulator` gera mensagens automáticas simulando posts sobre Big Data
- **Vantagens:** Reprodutível, sem dependências externas, controle total do fluxo

### 6. Configuração de Saída Gráfica
**⚠️ Adaptação:** WordCloud inline ao invés de ElasticSearch/Kibana

- **Motivo:** ELK requer >4GB RAM, Docker complexo e não é viável no Colab
- **Solução:** `WordCloudVisualizer` consome do Kafka e plota inline com matplotlib
- **Vantagens:** Leve, rápido, funciona em qualquer ambiente Python

### 7. Processamento Spark Streaming
- Leitura do tópico Kafka `social-input`
- Tokenização e limpeza (remoção de stopwords PT + EN)
- WordCount com agregação contínua
- Publicação de resultados no tópico `wordcount-output`

### 8. Visualização de Resultados
- Gráfico de barras (Top N palavras)
- Nuvem de palavras dinâmica
- Atualizações near-real-time

### 9. Validação
- Status das queries Spark
- Offsets dos tópicos Kafka
- Estatísticas de mensagens processadas
- Amostras de resultados

### 10. Finalização
- Parada de streams e producers
- Cleanup automático de recursos
- Relatório final de execução

## ⚙️ Tecnologias Utilizadas

| Componente | Versão | Função |
|------------|--------|--------|
| Apache Spark | 3.5.0 | Processamento distribuído |
| Apache Kafka | 3.6.0 | Message broker |
| Scala | 2.12 | Binários Spark/Kafka |
| Zookeeper | (bundled) | Coordenação Kafka |
| Python | 3.x | Linguagem principal |
| kafka-python | latest | Cliente Kafka |
| wordcloud | latest | Visualização |
| matplotlib | latest | Plots |

## 📈 Resultados Esperados

Ao final da execução, o notebook exibirá:

1. **Estatísticas:**
   - Número de mensagens produzidas
   - Palavras únicas processadas
   - Total de contagens acumuladas

2. **Visualizações:**
   - Gráfico de barras horizontal (Top 20-25 palavras)
   - Nuvem de palavras colorida (100-150 palavras)

3. **Monitoramento:**
   - Status das queries Spark Streaming
   - Offsets dos tópicos Kafka
   - Taxa de processamento (rows/sec)

## 🔧 Troubleshooting

### Erro: "No module named 'pyspark'"
```bash
pip install pyspark==3.5.0
```

### Erro: "Kafka failed to start"
- Verificar se porta 9092 está disponível
- No Colab, reiniciar runtime e executar novamente

### Erro: "Java not found"
```bash
# Ubuntu/Debian
sudo apt-get install openjdk-11-jdk

# macOS
brew install openjdk@11
```

### Visualizações não aparecem
- Executar `%matplotlib inline` no início do notebook
- Reiniciar kernel e rodar novamente

## 📝 Justificativas de Adaptações

### 1. Discord → Gerador Automático

**Especificação original:** "Substituir entrada por método de coleta de palavras a partir de rede social como Discord"

**Adaptação implementada:** Gerador automático de mensagens simulando posts de rede social

**Justificativa:**
- Discord exige criação de bot, token API, permissions, webhooks
- Google Colab não suporta serviços persistentes externos
- Complexidade de configuração desvia o foco pedagógico
- **Solução mantém conceito:** stream contínuo de mensagens via Kafka
- **Vantagens:** Reprodutibilidade total, sem dependências externas

### 2. ElasticSearch/Kibana → WordCloud Inline

**Especificação original:** "Substituir saída por gráfico de nuvens usando ElasticSearch e Kibana"

**Adaptação implementada:** Consumer Kafka + visualização inline com `wordcloud` + matplotlib

**Justificativa:**
- ELK requer >4GB RAM e setup Docker complexo
- Kibana não é scriptável via notebook (exige configuração manual)
- Google Colab tem limitações de memória e processos externos
- **Solução mantém conceito:** Dashboard visual de nuvem de palavras
- **Vantagens:** Leve, rápido, atualização near-real-time, totalmente inline

## 🎓 Conceitos Demonstrados

✅ **Spark Structured Streaming:** Processamento contínuo de dados  
✅ **Kafka Integration:** Consumo e produção de mensagens  
✅ **WordCount Distribuído:** Agregação em tempo real  
✅ **Checkpointing:** Tolerância a falhas  
✅ **Visualização Dinâmica:** Gráficos atualizados  
✅ **Pipeline Completo:** Entrada → Processamento → Saída

## 📚 Referências

- [Apache Spark Structured Streaming Guide](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html)
- [Spark-Kafka Integration](https://spark.apache.org/docs/latest/structured-streaming-kafka-integration.html)
- [kafka-python Documentation](https://kafka-python.readthedocs.io/)
- [WordCloud for Python](https://amueller.github.io/word_cloud/)

---

**Desenvolvido para:** Laboratório de Processamento de Dados  
**Data:** Novembro 2025  
**Status:** ✅ Completo e testado
