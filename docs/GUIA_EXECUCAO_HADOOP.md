# Guia de Execução - Testes Hadoop B1

## Visão Geral

Este guia descreve como executar todos os testes práticos do requisito B1 (Apache Hadoop), incluindo:

1. **5 configurações diferentes** (memória, replicação, blocksize, reducers, speculative execution)
2. **Testes de tolerância a falhas** (4 cenários com remoção/adição de nós)
3. **Testes de concorrência** (2, 3 e 4 jobs simultâneos)
4. **Coleta padronizada de métricas** (tempo, throughput, fases, recursos)

## Pré-requisitos

### 1. Cluster Hadoop em execução

```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd/hadoop
docker-compose up -d
```

Aguarde ~30 segundos para os serviços iniciarem completamente.

### 2. Verificar status do cluster

```bash
docker ps | grep hadoop
```

Deve mostrar 3 containers: `hadoop-master`, `hadoop-worker1`, `hadoop-worker2`

### 3. Verificar HDFS

```bash
docker exec hadoop-master hdfs dfsadmin -report
```

## Execução Rápida (Todos os Testes)

Para executar **todos os testes automaticamente** em sequência:

```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd
./scripts/run_all_tests.sh
```

⏱️ **Duração estimada**: 30-40 minutos

Esse script executa:
- Geração de dataset massivo (500MB)
- Teste baseline
- Teste 5 (speculative execution)
- Testes de tolerância a falhas (opcional)
- Testes de concorrência (opcional)
- Geração de relatório consolidado

**Resultados**: Todos em `resultados/B1/`

## Execução Modular (Testes Individuais)

### 1. Gerar Dataset Massivo

**Propósito**: Criar dataset de 500MB para garantir execução de 3-4+ minutos

```bash
cd /home/edilberto/pspd/atividade-extraclasse-2-pspd
./scripts/generate_large_dataset.sh 500
```

Parâmetros:
- `500` = tamanho em MB (ajustar conforme necessário)

**Saída**: 10 arquivos no HDFS em `/user/hadoop/input/`

### 2. Teste de Configuração - Speculative Execution

**Propósito**: 5ª configuração para avaliar impacto de execução especulativa

```bash
# Aplicar configuração
docker cp config/teste5_speculative/mapred-site.xml \
  hadoop-master:/home/hadoop/hadoop/etc/hadoop/mapred-site.xml

# Reiniciar YARN
docker exec hadoop-master bash -c "
  /home/hadoop/hadoop/sbin/stop-yarn.sh
  sleep 5
  /home/hadoop/hadoop/sbin/start-yarn.sh
  sleep 10
"

# Executar WordCount
docker exec hadoop-master bash -c "
  hdfs dfs -rm -r -f /user/hadoop/output/teste5 2>/dev/null || true
  hadoop jar /home/hadoop/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
    wordcount /user/hadoop/input /user/hadoop/output/teste5
"

# Coletar métricas (pegar Application ID do output acima)
./scripts/collect_metrics.sh application_XXXXX_YYYY resultados/B1/teste5_speculative 500
```

### 3. Testes de Tolerância a Falhas

**Propósito**: Avaliar comportamento do Hadoop ao remover/adicionar nós durante execução

```bash
./scripts/test_fault_tolerance.sh
```

⏱️ **Duração**: ~15-20 minutos

**Cenários executados**:
1. Baseline (sem falhas)
2. Falha de 1 worker durante execução
3. Falha de 2 workers durante execução
4. Adição de worker durante execução

**Resultados**: `resultados/B1/teste_tolerancia_falhas/run_TIMESTAMP/`

Arquivos gerados:
- `relatorio_tolerancia_falhas.md` - Relatório completo
- `cluster_status_*.txt` - Status do cluster em cada momento
- `job_output_*.txt` - Logs dos jobs
- `duration_*.txt` - Tempos de execução

### 4. Testes de Concorrência

**Propósito**: Avaliar scheduler YARN com múltiplos jobs simultâneos

```bash
./scripts/test_concurrency.sh
```

⏱️ **Duração**: ~10-15 minutos

**Testes executados**:
1. 2 jobs concorrentes
2. 3 jobs concorrentes
3. 4 jobs concorrentes (stress test)

**Resultados**: `resultados/B1/teste_concorrencia/run_TIMESTAMP/`

Arquivos gerados:
- `relatorio_concorrencia.md` - Relatório completo
- `metrics.csv` - Métricas consolidadas
- `cluster_monitoring.log` - Monitoramento de recursos
- `job_*/` - Diretórios individuais por job

### 5. Coletar Métricas (Manual)

**Propósito**: Extrair métricas detalhadas de qualquer job

```bash
./scripts/collect_metrics.sh <application_id> <output_dir> [dataset_size_mb]
```

Exemplo:
```bash
./scripts/collect_metrics.sh application_1731600000123_0001 resultados/B1/custom_test 500
```

**Métricas coletadas**:
- Temporal: Duração total, timestamps
- Throughput: MB/s, MB/min, GB/hora
- Fases: Map/Reduce
- Recursos: Containers, memória, vCores
- Comparativo: Variação vs baseline

## Estrutura de Resultados

```
resultados/B1/
├── teste0_baseline/              # Configuração padrão (referência)
├── teste1_memoria/               # Teste memória YARN
├── teste2_replicacao/            # Teste replicação HDFS
├── teste3_blocksize/             # Teste tamanho de bloco
├── teste4_reducers/              # Teste número de reducers
├── teste5_speculative/           # Teste execução especulativa
├── teste_tolerancia_falhas/      # Testes de falhas
│   └── run_TIMESTAMP/
│       ├── relatorio_tolerancia_falhas.md
│       ├── cluster_status_*.txt
│       ├── job_output_*.txt
│       └── ...
├── teste_concorrencia/           # Testes de concorrência
│   └── run_TIMESTAMP/
│       ├── relatorio_concorrencia.md
│       ├── metrics.csv
│       ├── cluster_monitoring.log
│       └── job_*/
└── relatorio_final_completo.md   # Relatório consolidado
```

Cada diretório de teste contém:
- `job_output.txt` - Saída completa do job
- `app_id.txt` - Application ID YARN
- `time_stats.txt` - Tempo de execução
- `config.txt` - Configuração utilizada (XML)
- `metrics_summary.txt` - Resumo de métricas
- `metrics_summary.csv` - Métricas em CSV
- `throughput_metrics.txt` - Métricas de throughput
- `performance_metrics.txt` - Performance detalhada

## Análise de Resultados

### Visualizar relatórios

```bash
# Relatório final consolidado
cat resultados/B1/relatorio_final_completo.md

# Tolerância a falhas
cat resultados/B1/teste_tolerancia_falhas/run_*/relatorio_tolerancia_falhas.md

# Concorrência
cat resultados/B1/teste_concorrencia/run_*/relatorio_concorrencia.md
```

### Comparar métricas

```bash
# Comparar tempos de execução
for dir in resultados/B1/teste*/; do
  echo "$(basename $dir): $(cat $dir/time_stats.txt 2>/dev/null || echo 'N/A')s"
done

# Ver todas as métricas CSV
cat resultados/B1/teste*/metrics_summary.csv
```

### Gerar gráficos (opcional)

```python
import pandas as pd
import matplotlib.pyplot as plt

# Carregar métricas
tests = ['baseline', 'memoria', 'replicacao', 'blocksize', 'reducers', 'speculative']
durations = []

for test in tests:
    with open(f'resultados/B1/teste_{test}/time_stats.txt') as f:
        durations.append(float(f.read().strip()))

# Plot
plt.bar(tests, durations)
plt.xlabel('Configuração')
plt.ylabel('Duração (s)')
plt.title('Comparação de Desempenho - Configurações Hadoop')
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig('resultados/B1/comparison_chart.png')
```

## Troubleshooting

### Cluster não inicia

```bash
# Parar tudo
docker-compose down

# Limpar volumes
docker volume prune

# Reiniciar
docker-compose up -d
```

### Dataset muito pequeno (execução < 3min)

```bash
# Gerar dataset maior (1GB)
./scripts/generate_large_dataset.sh 1000
```

### Jobs falhando

```bash
# Verificar logs YARN
docker exec hadoop-master yarn logs -applicationId application_XXXXX_YYYY

# Verificar ResourceManager
docker logs hadoop-master | grep ResourceManager

# Verificar saúde HDFS
docker exec hadoop-master hdfs dfsadmin -report
```

### Falta de espaço em disco

```bash
# Limpar outputs antigos
docker exec hadoop-master hdfs dfs -rm -r -f /user/hadoop/output/*

# Ver uso do HDFS
docker exec hadoop-master hdfs dfs -df -h
```

## Métricas Importantes

Para atender os requisitos, garantir coleta de:

### 1. Tempo de Execução
- ✅ Tempo total (s)
- ✅ Tempo por fase (Map, Reduce)
- ✅ Timestamps de início/fim

### 2. Throughput
- ✅ MB/s
- ✅ MB/min
- ✅ GB/hora

### 3. Variação Percentual
- ✅ Comparação com baseline
- ✅ Fórmula: `(atual - baseline) / baseline * 100`

### 4. Recursos
- ✅ Containers alocados
- ✅ Memória utilizada
- ✅ vCores utilizados

### 5. Tolerância a Falhas
- ✅ Tempo com/sem falhas
- ✅ Taxa de sucesso
- ✅ Re-escalonamento de tasks

### 6. Concorrência
- ✅ Tempo individual por job
- ✅ Throughput agregado
- ✅ Contenção de recursos

## Checklist de Entrega

- [ ] 5 configurações diferentes testadas
- [ ] Dataset massivo (3-4+ min execução)
- [ ] Testes de falhas (remoção/adição de nós)
- [ ] Testes de concorrência (2+ jobs simultâneos)
- [ ] Métricas padronizadas coletadas
- [ ] Tempos de execução documentados
- [ ] Throughput calculado (MB/min)
- [ ] Variação percentual vs baseline
- [ ] Relatórios consolidados gerados
- [ ] Conclusões sobre vantagens/desvantagens

## Comandos Úteis

```bash
# Ver Application IDs recentes
docker exec hadoop-master yarn application -list -appStates ALL | head -20

# Matar job em execução
docker exec hadoop-master yarn application -kill application_XXXXX_YYYY

# Monitorar job em tempo real
watch -n 5 'docker exec hadoop-master yarn application -list'

# Ver uso de recursos
docker exec hadoop-master yarn node -list -all

# Limpar tudo (reset completo)
./scripts/cleanup.sh
```

## Referências

- [Documentação Hadoop YARN](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.html)
- [MapReduce Tutorial](https://hadoop.apache.org/docs/current/hadoop-mapreduce-client/hadoop-mapreduce-client-core/MapReduceTutorial.html)
- [HDFS Architecture](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html)

---

**Última atualização**: $(date '+%Y-%m-%d')
**Versão**: 1.0
