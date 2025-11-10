# Teste 3 - Alteração de Blocksize HDFS

## Objetivo
Avaliar o impacto da alteração do tamanho de bloco HDFS no desempenho e armazenamento de dados distribuídos.

## Parâmetro Alterado
- **Arquivo**: `hdfs-site.xml`
- **Parâmetro**: `dfs.blocksize`
- **Valor Original**: 134217728 (128 MB - padrão Hadoop)
- **Novo Valor**: 67108864 (64 MB)

## Hipótese
Reduzir o tamanho do bloco de 128MB para 64MB resultará em:
- ✅ Maior número de blocos para o mesmo arquivo
- ✅ Maior paralelismo no MapReduce (mais mappers)
- ⚠️ Possível aumento no overhead de metadados no NameNode
- ⚠️ Tempo de execução pode variar dependendo do balanceamento

## Configuração Aplicada

### hdfs-site.xml (Master e Workers)
```xml
<property>
    <name>dfs.blocksize</name>
    <value>67108864</value> <!-- 64 MB -->
    <description>Tamanho de bloco HDFS reduzido para teste de paralelismo</description>
</property>
```

## Procedimento de Teste

### 1. Backup da Configuração Original
```bash
# Salvar configuração original
docker exec hadoop-master cat /opt/hadoop/etc/hadoop/hdfs-site.xml > hdfs-site.xml.backup
```

### 2. Aplicar Nova Configuração
```bash
# Alterar dfs.blocksize para 64MB nos arquivos:
# - hadoop/master/hdfs-site.xml
# - hadoop/worker1/hdfs-site.xml
# - hadoop/worker2/hdfs-site.xml
```

### 3. Reiniciar HDFS
```bash
cd hadoop
docker compose restart

# Aguardar containers iniciarem
sleep 10

# Reiniciar serviços HDFS
docker exec hadoop-master bash -c "stop-dfs.sh && start-dfs.sh"
```

### 4. Limpar e Reenviar Dataset
```bash
# Remover dataset anterior
docker exec -u hadoop hadoop-master hdfs dfs -rm -r /user/hadoop/wordcount/input

# Gerar e enviar novo dataset
cd ../scripts
./gerar_dataset_v2.sh
```

### 5. Verificar Número de Blocos
```bash
# Verificar informações de blocos do arquivo
docker exec -u hadoop hadoop-master hdfs fsck /user/hadoop/wordcount/input -files -blocks -locations
```

**Saída esperada com 128MB:**
```
Total blocks: ~X blocos
```

**Saída esperada com 64MB:**
```
Total blocks: ~2X blocos (aproximadamente o dobro)
```

### 6. Executar WordCount e Medir Tempo
```bash
# Limpar output anterior
docker exec -u hadoop hadoop-master hdfs dfs -rm -r -f /user/hadoop/wordcount/output_test3

# Executar com medição de tempo
docker exec -u hadoop hadoop-master bash -c "
    /usr/bin/time -v hadoop jar \$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
        wordcount \
        /user/hadoop/wordcount/input \
        /user/hadoop/wordcount/output_test3 \
    2>&1 | tee /home/hadoop/test3_output.log
"
```

### 7. Coletar Logs e Métricas YARN
```bash
# Obter Application ID
APP_ID=$(docker exec -u hadoop hadoop-master yarn application -list -appStates FINISHED | grep wordcount | tail -1 | awk '{print $1}')

# Extrair métricas do job
docker exec -u hadoop hadoop-master yarn logs -applicationId $APP_ID > test3_yarn_logs.txt
```

## Resultados

### Configuração com Blocksize 128MB (Baseline)

#### Informações do Dataset
```bash
# Executar antes do teste:
# docker exec -u hadoop hadoop-master hdfs dfs -du -h /user/hadoop/wordcount/input
```

- **Tamanho total do arquivo**: _[PREENCHER]_ MB
- **Número de blocos**: _[PREENCHER]_
- **Replicação**: 2

#### Métricas de Performance
- **Tempo total de execução**: _[PREENCHER]_ segundos
- **Número de Map tasks**: _[PREENCHER]_
- **Número de Reduce tasks**: _[PREENCHER]_
- **Memória máxima utilizada**: _[PREENCHER]_ MB
- **Throughput**: _[PREENCHER]_ MB/s

#### Comando executado:
```bash
# [COLAR COMANDO E OUTPUT DO TIME]
```

---

### Configuração com Blocksize 64MB (Teste)

#### Informações do Dataset
```bash
# Executar após aplicar configuração:
# docker exec -u hadoop hadoop-master hdfs fsck /user/hadoop/wordcount/input -files -blocks
```

- **Tamanho total do arquivo**: _[PREENCHER]_ MB
- **Número de blocos**: _[PREENCHER]_
- **Replicação**: 2
- **Aumento no número de blocos**: _[PREENCHER]_ %

#### Métricas de Performance
- **Tempo total de execução**: _[PREENCHER]_ segundos
- **Número de Map tasks**: _[PREENCHER]_
- **Número de Reduce tasks**: _[PREENCHER]_
- **Memória máxima utilizada**: _[PREENCHER]_ MB
- **Throughput**: _[PREENCHER]_ MB/s

#### Comando executado:
```bash
# [COLAR COMANDO E OUTPUT DO TIME]
```

---

## Comparação de Resultados

| Métrica | Blocksize 128MB | Blocksize 64MB | Variação | Impacto |
|---------|-----------------|----------------|----------|---------|
| Tamanho arquivo | _[PREENCHER]_ MB | _[PREENCHER]_ MB | 0% | Sem mudança |
| Número de blocos | _[PREENCHER]_ | _[PREENCHER]_ | _[PREENCHER]_ % | Aumento esperado |
| Map tasks | _[PREENCHER]_ | _[PREENCHER]_ | _[PREENCHER]_ % | Mais paralelismo |
| Tempo execução | _[PREENCHER]_ s | _[PREENCHER]_ s | _[PREENCHER]_ % | _[POSITIVO/NEGATIVO]_ |
| Memória máxima | _[PREENCHER]_ MB | _[PREENCHER]_ MB | _[PREENCHER]_ % | _[ANÁLISE]_ |
| Throughput | _[PREENCHER]_ MB/s | _[PREENCHER]_ MB/s | _[PREENCHER]_ % | _[ANÁLISE]_ |

## Análise dos Resultados

### Impacto Observado

#### Número de Blocos
- _[DESCREVER: O arquivo foi dividido em aproximadamente X blocos com 128MB e Y blocos com 64MB, confirmando a relação esperada de 2:1]_

#### Paralelismo
- _[DESCREVER: O número de Map tasks aumentou proporcionalmente ao número de blocos, permitindo maior paralelismo no processamento]_

#### Tempo de Execução
- _[DESCREVER: O tempo total foi X% maior/menor com blocos menores devido a...]_

#### Uso de Memória
- _[DESCREVER: A memória utilizada foi semelhante/diferente porque...]_

#### Overhead de Metadados
- _[DESCREVER: Com mais blocos, o NameNode precisa gerenciar mais metadados, mas o impacto foi...]_

### Vantagens do Blocksize Menor (64MB)
- ✅ _[LISTAR vantagens observadas]_
- ✅ Maior paralelismo (mais mappers)
- ✅ Melhor distribuição de carga entre workers

### Desvantagens do Blocksize Menor (64MB)
- ❌ _[LISTAR desvantagens observadas]_
- ❌ Maior overhead de metadados no NameNode
- ❌ Mais arquivos pequenos para gerenciar

## Conclusões

### Recomendação
_[PREENCHER: Com base nos resultados, para o tipo de workload testado (wordcount), o blocksize de XXX MB é mais adequado porque...]_

### Casos de Uso
- **Blocksize 128MB (padrão)**: Ideal para _[DESCREVER cenários]_
- **Blocksize 64MB (menor)**: Ideal para _[DESCREVER cenários]_

### Observações Adicionais
- _[LISTAR observações importantes do teste]_
- Em ambientes de produção, o blocksize deve ser escolhido com base no tamanho típico dos arquivos
- Arquivos muito menores que o blocksize desperdiçam espaço
- Arquivos muito maiores com blocksize pequeno aumentam overhead de metadados

## Comandos para Reverter

```bash
# Restaurar configuração original (128MB)
# Editar hdfs-site.xml em master, worker1 e worker2
# Alterar dfs.blocksize de volta para 134217728

# Reiniciar HDFS
docker exec hadoop-master bash -c "stop-dfs.sh && start-dfs.sh"

# Reenviar dataset com configuração original
docker exec -u hadoop hadoop-master hdfs dfs -rm -r /user/hadoop/wordcount/input
cd scripts && ./gerar_dataset_v2.sh
```

---

**Data do teste**: _[PREENCHER]_  
**Executado por**: _[PREENCHER]_  
**Status**: ⏳ Pendente de execução
