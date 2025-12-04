#!/bin/bash
#############################################################
# Gera Relatório Comparativo dos Testes Hadoop
# Consolida resultados de todos os testes (teste0-teste5)
# Extrai KPIs e gera visualizações
#############################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$BASE_DIR/resultados/B1"
OUTPUT_FILE="$RESULTS_DIR/RELATORIO_COMPARATIVO_FINAL.md"

# Cores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

extract_execution_time() {
    local test_dir=$1
    if [ -f "$test_dir/execution_time.txt" ]; then
        grep "EXECUTION_TIME_SECONDS" "$test_dir/execution_time.txt" | cut -d'=' -f2
    else
        echo "N/A"
    fi
}

extract_counters() {
    local test_dir=$1
    local counter_name=$2
    
    if [ -f "$test_dir/job_counters.txt" ]; then
        grep "$counter_name" "$test_dir/job_counters.txt" | head -1 | grep -oP '\d+' || echo "N/A"
    else
        echo "N/A"
    fi
}

log_info "Gerando relatório comparativo..."

cat > "$OUTPUT_FILE" << 'EOF'
# Relatório Comparativo - Testes Hadoop B1

**Data de Geração**: $(date '+%Y-%m-%d %H:%M:%S')

## 1. Sumário Executivo

Este relatório consolida os resultados de 6 configurações diferentes de cluster Hadoop testadas com a aplicação WordCount sobre um dataset grande (500MB+).

### Testes Realizados

| Teste | Descrição | Configuração Alterada |
|-------|-----------|----------------------|
| teste0_baseline | Configuração padrão de referência | Nenhuma (baseline) |
| teste1_memoria | Variação de memória YARN | yarn.scheduler.maximum-allocation-mb |
| teste2_replicacao | Variação de fator de replicação HDFS | dfs.replication |
| teste3_blocksize | Variação de tamanho de bloco HDFS | dfs.blocksize |
| teste4_reducers | Variação de número de reducers | mapreduce.job.reduces |
| teste5_speculative | Execução especulativa ativada | mapred.map.tasks.speculative.execution |

## 2. Resultados Consolidados

### 2.1 Tempos de Execução

| Teste | Tempo (segundos) | Tempo Formatado | Variação vs Baseline |
|-------|------------------|-----------------|---------------------|
EOF

# Extrai tempos de execução
baseline_time=$(extract_execution_time "$RESULTS_DIR/teste0_baseline")

for test in teste0_baseline teste1_memoria teste2_replicacao teste3_blocksize teste4_reducers teste5_speculative; do
    if [ -d "$RESULTS_DIR/$test" ]; then
        time_sec=$(extract_execution_time "$RESULTS_DIR/$test")
        
        if [ "$time_sec" != "N/A" ]; then
            time_fmt=$(printf '%02d:%02d:%02d' $((time_sec/3600)) $((time_sec%3600/60)) $((time_sec%60)))
            
            if [ "$baseline_time" != "N/A" ] && [ "$test" != "teste0_baseline" ]; then
                variation=$(awk "BEGIN {printf \"%.1f%%\", (($time_sec - $baseline_time) / $baseline_time) * 100}")
            else
                variation="-"
            fi
        else
            time_fmt="N/A"
            variation="N/A"
        fi
        
        echo "| $test | $time_sec | $time_fmt | $variation |" >> "$OUTPUT_FILE"
    fi
done

cat >> "$OUTPUT_FILE" << 'EOF'

### 2.2 Métricas MapReduce

#### Map Tasks

| Teste | Map Tasks Launched | Map Input Records | Map Output Records |
|-------|-------------------|-------------------|-------------------|
EOF

for test in teste0_baseline teste1_memoria teste2_replicacao teste3_blocksize teste4_reducers teste5_speculative; do
    if [ -d "$RESULTS_DIR/$test" ]; then
        map_launched=$(extract_counters "$RESULTS_DIR/$test" "Launched map tasks")
        map_input=$(extract_counters "$RESULTS_DIR/$test" "Map input records")
        map_output=$(extract_counters "$RESULTS_DIR/$test" "Map output records")
        
        echo "| $test | $map_launched | $map_input | $map_output |" >> "$OUTPUT_FILE"
    fi
done

cat >> "$OUTPUT_FILE" << 'EOF'

#### Reduce Tasks

| Teste | Reduce Tasks Launched | Reduce Input Records | Reduce Output Records |
|-------|----------------------|---------------------|----------------------|
EOF

for test in teste0_baseline teste1_memoria teste2_replicacao teste3_blocksize teste4_reducers teste5_speculative; do
    if [ -d "$RESULTS_DIR/$test" ]; then
        reduce_launched=$(extract_counters "$RESULTS_DIR/$test" "Launched reduce tasks")
        reduce_input=$(extract_counters "$RESULTS_DIR/$test" "Reduce input records")
        reduce_output=$(extract_counters "$RESULTS_DIR/$test" "Reduce output records")
        
        echo "| $test | $reduce_launched | $reduce_input | $reduce_output |" >> "$OUTPUT_FILE"
    fi
done

cat >> "$OUTPUT_FILE" << 'EOF'

### 2.3 I/O HDFS

| Teste | HDFS Bytes Read | HDFS Bytes Written | File Bytes Read |
|-------|----------------|-------------------|-----------------|
EOF

for test in teste0_baseline teste1_memoria teste2_replicacao teste3_blocksize teste4_reducers teste5_speculative; do
    if [ -d "$RESULTS_DIR/$test" ]; then
        hdfs_read=$(extract_counters "$RESULTS_DIR/$test" "HDFS: Number of bytes read")
        hdfs_written=$(extract_counters "$RESULTS_DIR/$test" "HDFS: Number of bytes written")
        file_read=$(extract_counters "$RESULTS_DIR/$test" "FILE: Number of bytes read")
        
        echo "| $test | $hdfs_read | $hdfs_written | $file_read |" >> "$OUTPUT_FILE"
    fi
done

cat >> "$OUTPUT_FILE" << 'EOF'

## 3. Análise Detalhada por Teste

### 3.1 Teste 0 - Baseline (Referência)

**Configuração**:
- Memória YARN: Padrão (2048MB)
- Replicação HDFS: 2
- Block Size: 128MB
- Reducers: Automático
- Speculative Execution: Desabilitado

**Objetivo**: Estabelecer linha de base para comparações

**Resultados**:
EOF

if [ -f "$RESULTS_DIR/teste0_baseline/REPORT.md" ]; then
    grep -A 5 "Tempos de Execução" "$RESULTS_DIR/teste0_baseline/REPORT.md" >> "$OUTPUT_FILE" || true
fi

cat >> "$OUTPUT_FILE" << 'EOF'

**Conclusão**: Esta configuração serve como referência (100%) para todas as métricas.

---

### 3.2 Teste 1 - Variação de Memória YARN

**Configuração Alterada**:
- `yarn.scheduler.maximum-allocation-mb`: Aumentado para 4096MB (vs 2048MB baseline)
- `yarn.nodemanager.resource.memory-mb`: Aumentado para 4096MB

**Hipótese**: Mais memória disponível permite containers maiores e potencialmente menos overhead de troca de contexto

**Resultados**:
EOF

if [ -f "$RESULTS_DIR/teste1_memoria/REPORT.md" ]; then
    grep -A 5 "Tempos de Execução" "$RESULTS_DIR/teste1_memoria/REPORT.md" >> "$OUTPUT_FILE" || true
fi

cat >> "$OUTPUT_FILE" << 'EOF'

**Análise**:
- Impacto no tempo de execução: [CALCULAR VARIAÇÃO]
- Tasks simultâneas: [ANALISAR]
- Throughput: [COMPARAR]

**Conclusão**: 
- ✓ Vantagem: Permite executar mais tasks em paralelo se houver RAM suficiente
- ✗ Desvantagem: Pode causar OOM se nó não tiver memória física correspondente

---

### 3.3 Teste 2 - Variação de Replicação HDFS

**Configuração Alterada**:
- `dfs.replication`: Reduzido para 1 (vs 2 baseline)

**Hipótese**: Menor replicação = menos escrita no HDFS = execução mais rápida, mas menor tolerância a falhas

**Resultados**:
EOF

if [ -f "$RESULTS_DIR/teste2_replicacao/REPORT.md" ]; then
    grep -A 5 "Tempos de Execução" "$RESULTS_DIR/teste2_replicacao/REPORT.md" >> "$OUTPUT_FILE" || true
fi

cat >> "$OUTPUT_FILE" << 'EOF'

**Análise**:
- HDFS Bytes Written: [COMPARAR - deve ser ~50% do baseline]
- Tempo total: [ANALISAR GANHO]
- Localidade de dados: [VERIFICAR]

**Conclusão**:
- ✓ Vantagem: Economia de espaço em disco (50%), escrita mais rápida
- ✗ Desvantagem: Sem redundância - perda de 1 DataNode = perda de dados

---

### 3.4 Teste 3 - Variação de Block Size

**Configuração Alterada**:
- `dfs.blocksize`: Aumentado para 256MB (vs 128MB baseline)

**Hipótese**: Blocos maiores = menos map tasks = menos overhead de inicialização, mas menor paralelismo

**Resultados**:
EOF

if [ -f "$RESULTS_DIR/teste3_blocksize/REPORT.md" ]; then
    grep -A 5 "Tempos de Execução" "$RESULTS_DIR/teste3_blocksize/REPORT.md" >> "$OUTPUT_FILE" || true
fi

cat >> "$OUTPUT_FILE" << 'EOF'

**Análise**:
- Número de Map Tasks: [COMPARAR - deve ser ~50% do baseline]
- Tempo por task: [ANALISAR]
- Paralelismo: [AVALIAR]

**Conclusão**:
- ✓ Vantagem: Menos overhead de NameNode (menos metadados)
- ✗ Desvantagem: Menor paralelismo em clusters grandes

---

### 3.5 Teste 4 - Variação de Reducers

**Configuração Alterada**:
- `mapreduce.job.reduces`: Fixado em 4 (vs automático baseline)

**Hipótese**: Número otimizado de reducers pode melhorar balanceamento e paralelismo da fase reduce

**Resultados**:
EOF

if [ -f "$RESULTS_DIR/teste4_reducers/REPORT.md" ]; then
    grep -A 5 "Tempos de Execução" "$RESULTS_DIR/teste4_reducers/REPORT.md" >> "$OUTPUT_FILE" || true
fi

cat >> "$OUTPUT_FILE" << 'EOF'

**Análise**:
- Reduce Tasks Launched: [VERIFICAR = 4]
- Tempo de fase reduce: [COMPARAR]
- Balanceamento de carga: [ANALISAR distribuição]

**Conclusão**:
- ✓ Vantagem: Controle explícito sobre paralelismo
- ✗ Desvantagem: Número fixo pode ser subótimo para diferentes datasets

---

### 3.6 Teste 5 - Execução Especulativa

**Configuração Alterada**:
- `mapred.map.tasks.speculative.execution`: true
- `mapred.reduce.tasks.speculative.execution`: true

**Hipótese**: Tasks especulativas podem compensar stragglers (tasks lentas)

**Resultados**:
EOF

if [ -f "$RESULTS_DIR/teste5_speculative/REPORT.md" ]; then
    grep -A 5 "Tempos de Execução" "$RESULTS_DIR/teste5_speculative/REPORT.md" >> "$OUTPUT_FILE" || true
fi

cat >> "$OUTPUT_FILE" << 'EOF'

**Análise**:
- Total tasks vs launched tasks: [VERIFICAR duplicação]
- Tempo total: [COMPARAR]
- Recursos utilizados: [ANALISAR overhead]

**Conclusão**:
- ✓ Vantagem: Reduz impacto de nós lentos/sobrecarregados
- ✗ Desvantagem: Usa mais recursos (executa tasks redundantes)

---

## 4. Comparação de Desempenho

### 4.1 Ranking por Tempo de Execução

```
[ORDENAR TESTES DO MAIS RÁPIDO PARA MAIS LENTO]
1. [teste_X] - XXX segundos
2. [teste_Y] - YYY segundos
...
```

### 4.2 Análise de Trade-offs

| Teste | Desempenho | Uso de Recursos | Tolerância a Falhas | Recomendação |
|-------|------------|----------------|---------------------|--------------|
| Baseline | Referência (100%) | Balanceado | Boa (repl=2) | Produção geral |
| Memoria+ | [ANALISAR] | Alto (RAM) | Boa | Cargas intensivas |
| Repl=1 | [ANALISAR] | Baixo (Disco) | Ruim | Apenas dev/test |
| BlockSize+ | [ANALISAR] | Baixo (Metadata) | Boa | Arquivos grandes |
| Reducers=4 | [ANALISAR] | Moderado | Boa | WordCount específico |
| Speculative | [ANALISAR] | Alto (CPU/Mem) | Boa | Clusters heterogêneos |

## 5. Conclusões Gerais

### 5.1 Escalabilidade

**Observações**:
- Adição de workers durante execução (ver teste de tolerância a falhas) demonstrou:
  - ✓ Novo worker integrado ao YARN
  - ⚠️ Benefício limitado (tasks já alocadas não migram)
  - ✓ Útil para jobs longos com múltiplas waves

**Conclusão**: Hadoop escala horizontalmente, mas com benefício marginal para jobs já em andamento.

### 5.2 Tolerância a Falhas

**Observações** (referência: resultados de test_fault_tolerance_advanced.sh):
- Perda de 1 worker (50% capacidade): ✓ Job completa, ~50% mais lento
- Perda de 2 workers (100%): ✗ Job falha ou aguarda indefinidamente
- Restauração de worker: ✓ Reintegração automática

**Nível de tolerância suportado**: Até 50% de perda de workers com degradação graciosa.

### 5.3 Otimizações Recomendadas

Com base nos testes:

1. **Para WordCount específico**:
   - Block size: 128-256MB (depende do tamanho médio dos arquivos)
   - Reducers: 2-4 (para clusters de 2 workers)
   - Memória: Aumentar se disponível (permite mais tasks paralelas)

2. **Para produção geral**:
   - Replicação: Manter ≥2 para redundância
   - Speculative execution: Ativar em clusters heterogêneos
   - Monitoramento: Essencial para identificar bottlenecks

3. **Para desenvolvimento/testes**:
   - Replicação: 1 é aceitável (economiza disco)
   - Memória: Padrão (2GB) suficiente
   - Logs: Habilitar modo detalhado

### 5.4 Vantagens vs Desvantagens Hadoop

**Vantagens identificadas**:
- ✓ Escalabilidade horizontal comprovada
- ✓ Tolerância a falhas funcional (até certo limite)
- ✓ Flexibilidade de configuração permite otimização
- ✓ Modelo MapReduce adequado para processamento batch
- ✓ HDFS distribui dados eficientemente

**Desvantagens identificadas**:
- ✗ Overhead significativo para datasets pequenos (<100MB)
- ✗ Configuração complexa (muitos parâmetros interdependentes)
- ✗ Escalabilidade dinâmica limitada (não move tasks)
- ✗ Tempo de startup de jobs relativamente alto
- ✗ Latência não é ideal para processamento real-time

## 6. Artefatos Gerados

### Estrutura de Resultados

```
resultados/B1/
├── teste0_baseline/
│   ├── REPORT.md
│   ├── execution_time.txt
│   ├── job_counters.txt
│   ├── pre_metrics.txt
│   └── post_metrics.txt
├── teste1_memoria/
├── teste2_replicacao/
├── teste3_blocksize/
├── teste4_reducers/
├── teste5_speculative/
├── teste_tolerancia_falhas_avancado/
│   └── FAULT_TOLERANCE_REPORT.md
└── evidencias_cluster/
    └── VALIDATION_REPORT.md
```

### Comandos para Reprodução

1. **Setup inicial**:
   ```bash
   cd hadoop
   docker-compose up -d
   ./scripts/validate_cluster.sh
   ```

2. **Executar todos os testes**:
   ```bash
   ./scripts/run_all_hadoop_tests.sh
   ```

3. **Testes de tolerância a falhas**:
   ```bash
   ./scripts/test_fault_tolerance_advanced.sh
   ```

4. **Gerar relatório comparativo**:
   ```bash
   ./scripts/generate_comparative_report.sh
   ```

## 7. Referências

- Documentação oficial Apache Hadoop: https://hadoop.apache.org/docs/stable/
- Configurações testadas: `config/teste*/`
- Logs completos: `resultados/B1/teste*/`
- Evidências do cluster: `resultados/B1/evidencias_cluster/`

---

**Relatório gerado automaticamente** em $(date '+%Y-%m-%d %H:%M:%S')  
**Script**: `scripts/generate_comparative_report.sh`
EOF

log_success "Relatório comparativo gerado: $OUTPUT_FILE"

# Gera CSV para análise em planilha
CSV_FILE="$RESULTS_DIR/comparative_data.csv"
log_info "Gerando CSV de dados comparativos..."

echo "Teste,TempoSegundos,MapTasks,ReduceTasks,HDFSBytesRead,HDFSBytesWritten" > "$CSV_FILE"

for test in teste0_baseline teste1_memoria teste2_replicacao teste3_blocksize teste4_reducers teste5_speculative; do
    if [ -d "$RESULTS_DIR/$test" ]; then
        time_sec=$(extract_execution_time "$RESULTS_DIR/$test")
        map_tasks=$(extract_counters "$RESULTS_DIR/$test" "Launched map tasks")
        reduce_tasks=$(extract_counters "$RESULTS_DIR/$test" "Launched reduce tasks")
        hdfs_read=$(extract_counters "$RESULTS_DIR/$test" "HDFS: Number of bytes read")
        hdfs_written=$(extract_counters "$RESULTS_DIR/$test" "HDFS: Number of bytes written")
        
        echo "$test,$time_sec,$map_tasks,$reduce_tasks,$hdfs_read,$hdfs_written" >> "$CSV_FILE"
    fi
done

log_success "CSV gerado: $CSV_FILE"

echo ""
log_success "Relatório comparativo completo!"
log_info "Markdown: $OUTPUT_FILE"
log_info "CSV: $CSV_FILE"
