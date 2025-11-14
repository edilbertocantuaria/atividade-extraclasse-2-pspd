# 🚀 Guia de Execução no Google Colab

## Método 1: Upload Direto (Mais Simples)

1. **Acesse o Colab:**
   ```
   https://colab.research.google.com/
   ```

2. **Upload do Notebook:**
   - Clique em `File` → `Upload notebook`
   - Selecione o arquivo `B2_pipeline.ipynb`
   - OU arraste e solte o arquivo na janela

3. **Execute:**
   - `Runtime` → `Run all` (Ctrl+F9)
   - Aguarde ~3-5 minutos para instalação de dependências
   - Visualizações aparecerão automaticamente inline

## Método 2: Direto do GitHub

1. **Link direto:**
   ```
   https://colab.research.google.com/github/edilbertocantuaria/atividade-extraclasse-2-pspd/blob/main/spark/notebooks/B2_pipeline.ipynb
   ```

2. **Ou via interface:**
   - Acesse `https://colab.research.google.com/`
   - Clique na aba `GitHub`
   - Cole a URL: `https://github.com/edilbertocantuaria/atividade-extraclasse-2-pspd`
   - Selecione `B2_pipeline.ipynb`

3. **Execute todas as células:**
   - `Runtime` → `Run all`

## ⏱️ Tempo de Execução Esperado

| Fase | Duração | Descrição |
|------|---------|-----------|
| Instalação | 2-3 min | pip install pyspark, kafka, wordcloud |
| Download Kafka | 1-2 min | Download de ~100MB |
| Inicialização | 30-60s | Spark session + Kafka broker |
| Processamento | 2-3 min | Producer + Streaming + Consumer |
| **TOTAL** | **6-9 min** | Execução completa |

## 📊 O Que Esperar

### Saídas Esperadas:

1. **Mensagens de progresso:**
   ```
   ✅ Dependências Python instaladas
   ✅ Kafka extraído em /tmp/kafka_2.12-3.6.0
   ✅ SparkSession criada com sucesso
   ✅ Tópico social-input criado com 3 partições
   ✅ Producer iniciado
   ✅ Query Spark iniciada: streaming_wordcount
   ```

2. **Visualizações (aparecem automaticamente):**
   - 📊 Gráfico de barras horizontal (Top 20-25 palavras)
   - ☁️ Nuvem de palavras colorida (100-150 termos)
   - 📈 Gráficos atualizados ao longo do tempo

3. **Estatísticas finais:**
   ```
   📊 Estatísticas Finais:
   - Mensagens produzidas: ~120-150
   - Palavras únicas: ~80-100
   - Total de contagens: ~1500-2000
   - Taxa: ~1.2 rows/sec
   ```

## ✅ Checklist de Validação

Execute estas verificações durante a execução:

- [ ] Célula 1-4: Instalações sem erros
- [ ] Célula 8-9: SparkSession criada (sem warnings críticos)
- [ ] Célula 10-11: Kafka broker ativo (porta 9092)
- [ ] Célula 12-13: Producer iniciado e produzindo mensagens
- [ ] Célula 16-20: Query Spark em estado "ACTIVE"
- [ ] Célula 21-26: Visualizações aparecem e atualizam
- [ ] Célula 27-29: Cleanup sem erros

## 🐛 Troubleshooting

### Problema 1: "Java not found"
**Solução:** Google Colab já tem Java instalado. Se aparecer este erro:
```python
# Execute esta célula ANTES de criar SparkSession:
!apt-get install -y openjdk-11-jdk-headless
import os
os.environ["JAVA_HOME"] = "/usr/lib/jvm/java-11-openjdk-amd64"
```

### Problema 2: Kafka não inicia
**Sintoma:** `Connection refused (localhost:9092)`

**Solução:**
```python
# Adicione delays maiores após iniciar Kafka:
import time
time.sleep(10)  # Aumentar de 5s para 10s
```

### Problema 3: Gráficos não aparecem
**Solução:**
```python
# Adicione no início do notebook:
%matplotlib inline
import matplotlib
matplotlib.use('Agg')
```

### Problema 4: "Out of memory"
**Causa:** Spark consumindo muita RAM

**Solução:** Reduzir configurações na célula de SparkSession:
```python
spark = SparkSession.builder \
    .config("spark.driver.memory", "1g") \  # Reduzir de 2g para 1g
    .config("spark.executor.memory", "1g") \
    # ...
```

### Problema 5: Timeout em downloads
**Solução:**
```python
# Usar espelho alternativo do Kafka:
kafka_url = "https://dlcdn.apache.org/kafka/3.6.0/kafka_2.12-3.6.0.tgz"
```

## 🔍 Validação de Resultados

### Como verificar se funcionou:

1. **Producer ativo:**
   ```python
   # Deve imprimir mensagens a cada ~1.5s
   📤 Produzindo mensagem 1/120...
   📤 Produzindo mensagem 2/120...
   ```

2. **Spark processando:**
   ```python
   # Console sink deve mostrar:
   -------------------------------------------
   Batch: 0
   -------------------------------------------
   +----------+-----+
   |word      |count|
   +----------+-----+
   |spark     |15   |
   |dados     |12   |
   |hadoop    |10   |
   +----------+-----+
   ```

3. **Consumer recebendo:**
   ```python
   # WordCloudVisualizer deve imprimir:
   📊 Recebidas 25 palavras únicas
   📊 Recebidas 48 palavras únicas
   ```

4. **Gráficos renderizados:**
   - Barra horizontal com cores gradientes
   - WordCloud com fundo branco e palavras coloridas

## 📝 Dicas de Uso

### Modo Interativo:
- Execute células uma a uma (Shift+Enter) para acompanhar cada etapa
- Útil para debugging e entendimento do pipeline

### Modo Automatizado:
- `Runtime` → `Run all` para execução completa
- Útil para demonstrações e testes rápidos

### Salvar Resultados:
```python
# Adicionar no final do notebook:
from google.colab import files

# Baixar gráficos
files.download('/tmp/wordcloud.png')
files.download('/tmp/barchart.png')
```

### Aumentar Dados:
```python
# Modificar na célula do Producer:
self.num_messages = 200  # Aumentar de 120 para 200
self.interval = 1.0      # Reduzir de 1.5 para 1.0
```

## 🎯 Objetivos de Aprendizado

Ao final da execução, você terá demonstrado:

✅ **Setup de ambiente Big Data** (Spark + Kafka)  
✅ **Streaming em tempo real** (Structured Streaming)  
✅ **Pipeline completo** (Producer → Processing → Consumer)  
✅ **Visualização de dados** (WordCloud + Charts)  
✅ **Monitoramento** (Spark UI, Kafka offsets)  
✅ **Cleanup de recursos** (Stop graceful de serviços)

## 📞 Suporte

Se encontrar problemas não listados acima:

1. Reinicie o runtime: `Runtime` → `Restart runtime`
2. Execute novamente: `Runtime` → `Run all`
3. Verifique os logs de cada célula
4. Consulte o README.md principal para detalhes técnicos

---

**Boa execução! 🚀**
