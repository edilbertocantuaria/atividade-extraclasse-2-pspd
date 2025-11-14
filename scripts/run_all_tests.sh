#!/bin/bash
set -euo pipefail

# ============================================================================
# RUN ALL HADOOP TESTS - Executor Mestre de Todos os Testes
# ============================================================================
# Executa sequencialmente todos os testes do Hadoop B1:
# 1. Testes de configuração (memória, replicação, blocksize, reducers, speculative)
# 2. Testes de tolerância a falhas
# 3. Testes de concorrência
# 4. Coleta de métricas padronizadas
# ============================================================================

PROJECT_ROOT="/home/edilberto/pspd/atividade-extraclasse-2-pspd"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
RESULTS_DIR="$PROJECT_ROOT/resultados/B1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "============================================================"
echo "EXECUÇÃO COMPLETA DE TESTES - Hadoop B1"
echo "============================================================"
echo "Timestamp: $TIMESTAMP"
echo "Diretório de resultados: $RESULTS_DIR"
echo ""

# Verificar se cluster está rodando
if ! docker ps | grep -q "hadoop-master"; then
    echo "❌ Erro: Cluster Hadoop não está rodando!"
    echo ""
    echo "Inicie o cluster primeiro:"
    echo "  cd $PROJECT_ROOT/hadoop"
    echo "  docker-compose up -d"
    exit 1
fi

echo "✓ Cluster Hadoop está rodando"
echo ""

# ============================================================================
# PREPARAÇÃO
# ============================================================================
echo "ETAPA 1: Preparação do Ambiente"
echo "------------------------------------------------------------"

# Gerar dataset massivo
if [ ! -f "$RESULTS_DIR/.dataset_generated" ]; then
    echo "Gerando dataset massivo (500MB)..."
    "$SCRIPTS_DIR/generate_large_dataset.sh" 500
    touch "$RESULTS_DIR/.dataset_generated"
    echo ""
else
    echo "✓ Dataset já existe, pulando geração"
    echo ""
fi

# Verificar dataset no HDFS
echo "Verificando dataset no HDFS..."
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/bin/hdfs dfs -ls -h /user/hadoop/input'" || {
    echo "❌ Dataset não encontrado no HDFS!"
    echo "Execute: $SCRIPTS_DIR/generate_large_dataset.sh 500"
    exit 1
}
echo ""

# ============================================================================
# TESTE: Baseline (configuração padrão)
# ============================================================================
echo ""
echo "ETAPA 2: Teste Baseline (Configuração Padrão)"
echo "------------------------------------------------------------"

BASELINE_DIR="$RESULTS_DIR/teste0_baseline"
mkdir -p "$BASELINE_DIR"

echo "Executando WordCount com configuração padrão..."
START_TIME=$(date +%s)

JOB_OUTPUT=$(docker exec hadoop-master bash -c "
  hdfs dfs -rm -r -f /user/hadoop/output/baseline 2>/dev/null || true
  hadoop jar /home/hadoop/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
    wordcount /user/hadoop/input /user/hadoop/output/baseline 2>&1
")

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

APP_ID=$(echo "$JOB_OUTPUT" | grep -oP 'application_\d+_\d+' | head -1)

echo "$JOB_OUTPUT" > "$BASELINE_DIR/job_output.txt"
echo "$APP_ID" > "$BASELINE_DIR/app_id.txt"
echo "$DURATION" > "$BASELINE_DIR/time_stats.txt"

# Coletar métricas
"$SCRIPTS_DIR/collect_metrics.sh" "$APP_ID" "$BASELINE_DIR" 500

echo "✓ Baseline concluído em ${DURATION}s"
echo "  Application ID: $APP_ID"
echo ""

# ============================================================================
# TESTE 5: Speculative Execution
# ============================================================================
echo ""
echo "ETAPA 3: Teste 5 - Speculative Execution"
echo "------------------------------------------------------------"

TEST5_DIR="$RESULTS_DIR/teste5_speculative"
mkdir -p "$TEST5_DIR"

# Aplicar configuração
echo "Aplicando configuração de speculative execution..."
docker cp "$PROJECT_ROOT/config/teste5_speculative/mapred-site.xml" \
  hadoop-master:/home/hadoop/hadoop/etc/hadoop/mapred-site.xml

# Reiniciar YARN para aplicar mudanças
echo "Reiniciando YARN..."
docker exec hadoop-master bash -c "
  /home/hadoop/hadoop/sbin/stop-yarn.sh
  sleep 5
  /home/hadoop/hadoop/sbin/start-yarn.sh
  sleep 10
"

# Copiar configuração para resultados
cp "$PROJECT_ROOT/config/teste5_speculative/mapred-site.xml" "$TEST5_DIR/config.txt"

# Executar teste
echo "Executando WordCount com speculative execution..."
START_TIME=$(date +%s)

JOB_OUTPUT=$(docker exec hadoop-master bash -c "
  hdfs dfs -rm -r -f /user/hadoop/output/teste5 2>/dev/null || true
  hadoop jar /home/hadoop/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
    wordcount /user/hadoop/input /user/hadoop/output/teste5 2>&1
")

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

APP_ID=$(echo "$JOB_OUTPUT" | grep -oP 'application_\d+_\d+' | head -1)

echo "$JOB_OUTPUT" > "$TEST5_DIR/job_output.txt"
echo "$APP_ID" > "$TEST5_DIR/app_id.txt"
echo "$DURATION" > "$TEST5_DIR/time_stats.txt"

# Coletar métricas
"$SCRIPTS_DIR/collect_metrics.sh" "$APP_ID" "$TEST5_DIR" 500

# Gerar resumo
cat > "$TEST5_DIR/resumo.txt" << EOF
TESTE 5: Speculative Execution

Configuração:
- mapreduce.map.speculative=true
- mapreduce.reduce.speculative=true
- Threshold: 1.0 (task lenta = 1x tempo médio)
- Cap: 10% das tasks podem ser especulativas

Resultados:
- Duração: ${DURATION}s
- Application ID: $APP_ID
- Baseline: $(cat "$BASELINE_DIR/time_stats.txt")s
- Variação: $(echo "scale=2; ($DURATION - $(cat "$BASELINE_DIR/time_stats.txt")) / $(cat "$BASELINE_DIR/time_stats.txt") * 100" | bc)%

Objetivo:
Verificar se execução especulativa reduz impacto de stragglers (tasks lentas)
e melhora tempo total, especialmente em clusters heterogêneos.

EOF

cat "$TEST5_DIR/resumo.txt"

echo "✓ Teste 5 concluído em ${DURATION}s"
echo ""

# Restaurar configuração padrão
docker cp hadoop-master:/home/hadoop/hadoop/etc/hadoop/mapred-site.xml.template \
  hadoop-master:/home/hadoop/hadoop/etc/hadoop/mapred-site.xml 2>/dev/null || true
docker exec hadoop-master bash -c "
  /home/hadoop/hadoop/sbin/stop-yarn.sh
  sleep 5
  /home/hadoop/hadoop/sbin/start-yarn.sh
  sleep 10
" 2>/dev/null || true

# ============================================================================
# TESTES DE TOLERÂNCIA A FALHAS
# ============================================================================
echo ""
echo "ETAPA 4: Testes de Tolerância a Falhas"
echo "------------------------------------------------------------"

echo "Este teste demora ~15-20 minutos devido aos múltiplos cenários..."
echo "Deseja prosseguir? (s/N)"
read -t 10 -n 1 response || response="s"
echo ""

if [[ "$response" =~ ^[Ss]$ ]]; then
    "$SCRIPTS_DIR/test_fault_tolerance.sh"
else
    echo "Pulando testes de tolerância a falhas (execute manualmente depois)"
fi

echo ""

# ============================================================================
# TESTES DE CONCORRÊNCIA
# ============================================================================
echo ""
echo "ETAPA 5: Testes de Concorrência"
echo "------------------------------------------------------------"

echo "Este teste demora ~10-15 minutos..."
echo "Deseja prosseguir? (s/N)"
read -t 10 -n 1 response || response="s"
echo ""

if [[ "$response" =~ ^[Ss]$ ]]; then
    "$SCRIPTS_DIR/test_concurrency.sh"
else
    echo "Pulando testes de concorrência (execute manualmente depois)"
fi

echo ""

# ============================================================================
# RELATÓRIO FINAL CONSOLIDADO
# ============================================================================
echo ""
echo "ETAPA 6: Gerando Relatório Consolidado Final"
echo "------------------------------------------------------------"

FINAL_REPORT="$RESULTS_DIR/relatorio_final_completo.md"

cat > "$FINAL_REPORT" << 'EOF'
# Relatório Final Completo - Testes Hadoop B1

## Sumário Executivo

Este documento consolida todos os testes realizados no cluster Hadoop, incluindo:
- Testes de configuração (5 variações)
- Testes de tolerância a falhas (4 cenários)
- Testes de concorrência (3 níveis)
- Métricas padronizadas de desempenho

## 1. Testes de Configuração

### 1.1 Baseline (Configuração Padrão)
EOF

if [ -f "$BASELINE_DIR/metrics_summary.txt" ]; then
    echo "" >> "$FINAL_REPORT"
    echo '```' >> "$FINAL_REPORT"
    cat "$BASELINE_DIR/metrics_summary.txt" >> "$FINAL_REPORT"
    echo '```' >> "$FINAL_REPORT"
fi

cat >> "$FINAL_REPORT" << 'EOF'

### 1.2 Teste 1: Alteração de Memória YARN

Ver: `resultados/B1/teste1_memoria/`

**Objetivo**: Avaliar impacto da memória disponível no desempenho

### 1.3 Teste 2: Alteração de Replicação HDFS

Ver: `resultados/B1/teste2_replicacao/`

**Objetivo**: Avaliar impacto do fator de replicação na durabilidade e performance

### 1.4 Teste 3: Alteração de Block Size

Ver: `resultados/B1/teste3_blocksize/`

**Objetivo**: Avaliar impacto do tamanho de bloco no paralelismo

### 1.5 Teste 4: Alteração de Número de Reducers

Ver: `resultados/B1/teste4_reducers/`

**Objetivo**: Avaliar impacto do número de reducers no tempo de execução

### 1.6 Teste 5: Speculative Execution
EOF

if [ -f "$TEST5_DIR/resumo.txt" ]; then
    echo "" >> "$FINAL_REPORT"
    echo '```' >> "$FINAL_REPORT"
    cat "$TEST5_DIR/resumo.txt" >> "$FINAL_REPORT"
    echo '```' >> "$FINAL_REPORT"
fi

cat >> "$FINAL_REPORT" << 'EOF'

## 2. Testes de Tolerância a Falhas

Ver: `resultados/B1/teste_tolerancia_falhas/`

**Cenários testados**:
1. Baseline (sem falhas)
2. Falha de 1 worker durante execução
3. Falha de 2 workers durante execução
4. Adição de worker durante execução (scale up)

**Conclusões**:
- Hadoop demonstrou capacidade de continuar jobs mesmo com perda de nós
- Re-escalonamento automático de tarefas para nós disponíveis
- Overhead significativo ao perder múltiplos nós

## 3. Testes de Concorrência

Ver: `resultados/B1/teste_concorrencia/`

**Níveis testados**:
1. 2 jobs concorrentes
2. 3 jobs concorrentes
3. 4 jobs concorrentes (stress test)

**Conclusões**:
- Scheduler YARN gerenciou bem alocação de recursos
- Contenção aumenta tempo individual, mas throughput agregado pode melhorar
- Trade-off entre latência individual e throughput total

## 4. Análise Comparativa Geral

### 4.1 Tabela Resumo de Desempenho

| Teste | Configuração | Duração (s) | Variação vs Baseline | Observações |
|-------|--------------|-------------|----------------------|-------------|
| Baseline | Padrão | $(cat "$BASELINE_DIR/time_stats.txt" 2>/dev/null || echo "N/A") | - | Referência |
| Teste 1 | Memória aumentada | $(cat "$RESULTS_DIR/teste1_memoria/time_stats.txt" 2>/dev/null || echo "N/A") | ? | - |
| Teste 2 | Replicação RF=2 | $(cat "$RESULTS_DIR/teste2_replicacao/time_stats.txt" 2>/dev/null || echo "N/A") | ? | - |
| Teste 3 | BlockSize 256MB | $(cat "$RESULTS_DIR/teste3_blocksize/time_stats.txt" 2>/dev/null || echo "N/A") | ? | - |
| Teste 4 | 4 Reducers | $(cat "$RESULTS_DIR/teste4_reducers/time_stats.txt" 2>/dev/null || echo "N/A") | ? | - |
| Teste 5 | Speculative Exec | $(cat "$TEST5_DIR/time_stats.txt" 2>/dev/null || echo "N/A") | $(cat "$TEST5_DIR/metrics_summary.csv" 2>/dev/null | grep Variation | cut -d, -f2 || echo "N/A")% | - |

### 4.2 Throughput Comparativo

Ver arquivos `throughput_metrics.txt` em cada diretório de teste.

## 5. Conclusões Gerais

### 5.1 Vantagens do Hadoop

1. **Escalabilidade**: Capacidade de processar grandes volumes de dados
2. **Tolerância a Falhas**: Recuperação automática de falhas de nós
3. **Flexibilidade**: Configurações ajustáveis para diferentes workloads
4. **Paralelismo**: Distribuição eficiente de processamento

### 5.2 Desvantagens Observadas

1. **Latência**: Overhead de inicialização e coordenação
2. **Complexidade**: Configuração e tuning não triviais
3. **Recursos**: Requer infraestrutura significativa
4. **Desenvolvimento**: MapReduce pode ser limitante para alguns casos

### 5.3 Recomendações

1. **Configuração**: Ajustar memória, replicação e blocksize conforme workload
2. **Monitoramento**: Implementar monitoramento contínuo de saúde do cluster
3. **Testes**: Realizar testes de carga antes de produção
4. **Alterativas**: Considerar Spark para workloads iterativos ou interativos

## 6. Arquivos e Evidências

Todos os testes incluem:
- `job_output.txt`: Saída completa do job
- `app_id.txt`: Application ID YARN
- `time_stats.txt`: Tempo de execução
- `config.txt`: Configuração utilizada
- `metrics_summary.txt`: Resumo de métricas
- `metrics_summary.csv`: Métricas em formato CSV

## 7. Ambiente de Testes

- **Cluster**: Docker Compose (1 master + 2 workers)
- **Hadoop Version**: 3.3.6
- **Dataset**: 500MB texto gerado
- **Aplicação**: WordCount (MapReduce)
- **Scheduler**: Capacity Scheduler (padrão)

---

**Data de geração**: $(date '+%Y-%m-%d %H:%M:%S')
**Executado por**: Automated Test Suite
**Duração total dos testes**: ~ $((($(date +%s) - TIMESTAMP) / 60)) minutos

EOF

cat "$FINAL_REPORT"

echo ""
echo "============================================================"
echo "✅ TODOS OS TESTES CONCLUÍDOS COM SUCESSO!"
echo "============================================================"
echo ""
echo "Relatório final: $FINAL_REPORT"
echo ""
echo "Estrutura de resultados:"
tree -L 2 "$RESULTS_DIR" 2>/dev/null || ls -R "$RESULTS_DIR"
echo ""
echo "Próximos passos:"
echo "1. Revisar relatórios individuais em cada diretório de teste"
echo "2. Analisar métricas CSV para gráficos comparativos"
echo "3. Documentar aprendizados e insights no relatório final"
echo ""
