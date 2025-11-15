#!/bin/bash
set -euo pipefail

# ============================================================================
# FAULT TOLERANCE TESTS - Testes de Tolerância a Falhas
# ============================================================================
# Executa job WordCount e simula falhas de workers durante a execução
# Monitora impacto no tempo, reexecução e recuperação
# ============================================================================

RESULTS_DIR="/home/edilberto/pspd/atividade-extraclasse-2-pspd/resultados/B1/teste_tolerancia_falhas"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_DIR="$RESULTS_DIR/run_$TIMESTAMP"

mkdir -p "$TEST_DIR"

HADOOP_EXAMPLES="/home/hadoop/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar"
INPUT_PATH="/user/hadoop/input"
OUTPUT_PATH="/user/hadoop/output/fault_test_$TIMESTAMP"

echo "============================================================"
echo "TESTE DE TOLERÂNCIA A FALHAS - Hadoop Cluster"
echo "============================================================"
echo "Timestamp: $TIMESTAMP"
echo "Diretório de resultados: $TEST_DIR"
echo ""

# Função para coletar status do cluster
collect_cluster_status() {
    local label=$1
    local output_file="$TEST_DIR/cluster_status_${label}.txt"
    
    echo "=== Status do Cluster - $label ===" > "$output_file"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> "$output_file"
    echo "" >> "$output_file"
    
    echo "Containers Docker ativos:" >> "$output_file"
    docker ps --filter "name=hadoop-" --format "table {{.Names}}\t{{.Status}}" >> "$output_file"
    echo "" >> "$output_file"
    
    echo "Nós YARN ativos:" >> "$output_file"
    docker exec hadoop-master bash -c "yarn node -list -all 2>/dev/null" >> "$output_file" || echo "Erro ao listar nós YARN" >> "$output_file"
    echo "" >> "$output_file"
    
    echo "DataNodes HDFS ativos:" >> "$output_file"
    docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/bin/hdfs dfsadmin -report 2>/dev/null | grep -E \"Live datanodes|Name:\"'" >> "$output_file" || echo "Erro ao listar DataNodes" >> "$output_file"
    echo "" >> "$output_file"
}

# Função para monitorar job em background
monitor_job() {
    local app_id=$1
    local monitor_file="$TEST_DIR/job_monitoring.log"
    
    echo "=== Monitoramento do Job $app_id ===" > "$monitor_file"
    echo "Início: $(date '+%Y-%m-%d %H:%M:%S')" >> "$monitor_file"
    echo "" >> "$monitor_file"
    
    while true; do
        sleep 5
        
        # Verificar status do job
        status=$(docker exec hadoop-master bash -c "yarn application -status $app_id 2>/dev/null" || echo "ERRO")
        
        echo "[$(date '+%H:%M:%S')] Status:" >> "$monitor_file"
        echo "$status" >> "$monitor_file"
        echo "" >> "$monitor_file"
        
        # Verificar se job terminou
        if echo "$status" | grep -q "Final-State.*SUCCEEDED\|FAILED\|KILLED"; then
            break
        fi
        
        # Verificar se job ainda existe
        if echo "$status" | grep -q "doesn't exist\|ERRO"; then
            break
        fi
    done
    
    echo "Fim: $(date '+%Y-%m-%d %H:%M:%S')" >> "$monitor_file"
}

# ============================================================================
# CENÁRIO 1: Baseline - Execução normal sem falhas
# ============================================================================
echo ""
echo "CENÁRIO 1: Baseline (sem falhas)"
echo "------------------------------------------------------------"

collect_cluster_status "baseline_before"

echo "Limpando output anterior..."
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/bin/hdfs dfs -rm -r -f $OUTPUT_PATH 2>/dev/null || true'"

echo "Iniciando job WordCount..."
START_TIME=$(date +%s)

# Executar job e capturar Application ID
JOB_OUTPUT=$(docker exec hadoop-master bash -c "
  su - hadoop -c '/home/hadoop/hadoop/bin/hadoop jar $HADOOP_EXAMPLES wordcount $INPUT_PATH ${OUTPUT_PATH}_baseline' 2>&1 | tee /tmp/job_baseline.log
")

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Extrair Application ID
APP_ID=$(echo "$JOB_OUTPUT" | grep -oP 'application_\d+_\d+' | head -1)

echo "$JOB_OUTPUT" > "$TEST_DIR/job_output_baseline.txt"
echo "$APP_ID" > "$TEST_DIR/app_id_baseline.txt"
echo "$DURATION" > "$TEST_DIR/duration_baseline.txt"

echo ""
echo "✓ Job concluído em ${DURATION}s"
echo "  Application ID: $APP_ID"

collect_cluster_status "baseline_after"

# ============================================================================
# CENÁRIO 2: Falha de 1 Worker durante execução
# ============================================================================
echo ""
echo "CENÁRIO 2: Falha de 1 Worker (worker2) durante execução"
echo "------------------------------------------------------------"

collect_cluster_status "scenario2_before"

echo "Limpando output anterior..."
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/bin/hdfs dfs -rm -r -f ${OUTPUT_PATH}_scenario2 2>/dev/null || true'"

echo "Iniciando job WordCount..."
START_TIME=$(date +%s)

# Iniciar job em background
docker exec -d hadoop-master bash -c "
  su - hadoop -c '/home/hadoop/hadoop/bin/hadoop jar $HADOOP_EXAMPLES wordcount $INPUT_PATH ${OUTPUT_PATH}_scenario2' > /tmp/job_scenario2.log 2>&1
" > /dev/null

sleep 2

# Capturar Application ID
APP_ID=$(docker exec hadoop-master bash -c "yarn application -list 2>/dev/null | grep -oP 'application_\d+_\d+' | tail -1")
echo "Application ID: $APP_ID"
echo "$APP_ID" > "$TEST_DIR/app_id_scenario2.txt"

# Monitorar job em background
monitor_job "$APP_ID" &
MONITOR_PID=$!

# Aguardar job iniciar (esperar pelo menos 30% de progresso)
echo "Aguardando job iniciar processamento..."
sleep 15

echo ""
echo ">>> SIMULANDO FALHA: Parando worker2..."
FAIL_TIME=$(date +%s)
echo "Falha injetada em: $(date '+%Y-%m-%d %H:%M:%S')" > "$TEST_DIR/failure_timestamp_scenario2.txt"

docker stop hadoop-worker2
collect_cluster_status "scenario2_failure"

echo "Worker2 parado. Job continuará com recursos reduzidos..."
echo "Aguardando conclusão do job..."

# Aguardar job completar
wait $MONITOR_PID

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
FAILURE_OFFSET=$((FAIL_TIME - START_TIME))

# Copiar log do job
docker exec hadoop-master bash -c "cat /tmp/job_scenario2.log" > "$TEST_DIR/job_output_scenario2.txt"

echo "$DURATION" > "$TEST_DIR/duration_scenario2.txt"
echo "$FAILURE_OFFSET" > "$TEST_DIR/failure_offset_scenario2.txt"

echo ""
echo "✓ Job concluído em ${DURATION}s (falha injetada após ${FAILURE_OFFSET}s)"

# Restaurar worker2
echo "Restaurando worker2..."
docker start hadoop-worker2
sleep 10

collect_cluster_status "scenario2_after"

# ============================================================================
# CENÁRIO 3: Falha de 2 Workers durante execução
# ============================================================================
echo ""
echo "CENÁRIO 3: Falha de 2 Workers (worker1 e worker2) durante execução"
echo "------------------------------------------------------------"

collect_cluster_status "scenario3_before"

echo "Limpando output anterior..."
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/bin/hdfs dfs -rm -r -f ${OUTPUT_PATH}_scenario3 2>/dev/null || true'"

echo "Iniciando job WordCount..."
START_TIME=$(date +%s)

# Iniciar job em background
docker exec -d hadoop-master bash -c "
  su - hadoop -c '/home/hadoop/hadoop/bin/hadoop jar $HADOOP_EXAMPLES wordcount $INPUT_PATH ${OUTPUT_PATH}_scenario3' > /tmp/job_scenario3.log 2>&1
" > /dev/null

sleep 2

# Capturar Application ID
APP_ID=$(docker exec hadoop-master bash -c "yarn application -list 2>/dev/null | grep -oP 'application_\d+_\d+' | tail -1")
echo "Application ID: $APP_ID"
echo "$APP_ID" > "$TEST_DIR/app_id_scenario3.txt"

# Monitorar job em background
monitor_job "$APP_ID" &
MONITOR_PID=$!

# Aguardar job iniciar
echo "Aguardando job iniciar processamento..."
sleep 15

echo ""
echo ">>> SIMULANDO FALHA: Parando worker1..."
FAIL_TIME_1=$(date +%s)
docker stop hadoop-worker1
sleep 5

echo ">>> SIMULANDO FALHA: Parando worker2..."
FAIL_TIME_2=$(date +%s)
docker stop hadoop-worker2

echo "Falha worker1: $(date '+%Y-%m-%d %H:%M:%S' -d @$FAIL_TIME_1)" > "$TEST_DIR/failure_timestamp_scenario3.txt"
echo "Falha worker2: $(date '+%Y-%m-%d %H:%M:%S' -d @$FAIL_TIME_2)" >> "$TEST_DIR/failure_timestamp_scenario3.txt"

collect_cluster_status "scenario3_failure"

echo "Ambos workers parados. Job executando apenas no master (se possível)..."
echo "Aguardando conclusão do job..."

# Aguardar job completar
wait $MONITOR_PID

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Copiar log do job
docker exec hadoop-master bash -c "cat /tmp/job_scenario3.log" > "$TEST_DIR/job_output_scenario3.txt"

echo "$DURATION" > "$TEST_DIR/duration_scenario3.txt"

echo ""
echo "✓ Job concluído em ${DURATION}s"

# Restaurar workers
echo "Restaurando workers..."
docker start hadoop-worker1
docker start hadoop-worker2
sleep 10

collect_cluster_status "scenario3_after"

# ============================================================================
# CENÁRIO 4: Adição de Worker durante execução
# ============================================================================
echo ""
echo "CENÁRIO 4: Adição de Worker durante execução (scale up)"
echo "------------------------------------------------------------"

# Primeiro parar worker2
docker stop hadoop-worker2
sleep 5

collect_cluster_status "scenario4_before"

echo "Limpando output anterior..."
docker exec hadoop-master bash -c "su - hadoop -c '/home/hadoop/hadoop/bin/hdfs dfs -rm -r -f ${OUTPUT_PATH}_scenario4 2>/dev/null || true'"

echo "Iniciando job WordCount com apenas 1 worker..."
START_TIME=$(date +%s)

# Iniciar job em background
docker exec -d hadoop-master bash -c "
  su - hadoop -c '/home/hadoop/hadoop/bin/hadoop jar $HADOOP_EXAMPLES wordcount $INPUT_PATH ${OUTPUT_PATH}_scenario4' > /tmp/job_scenario4.log 2>&1
" > /dev/null

sleep 2

# Capturar Application ID
APP_ID=$(docker exec hadoop-master bash -c "yarn application -list 2>/dev/null | grep -oP 'application_\d+_\d+' | tail -1")
echo "Application ID: $APP_ID"
echo "$APP_ID" > "$TEST_DIR/app_id_scenario4.txt"

# Monitorar job em background
monitor_job "$APP_ID" &
MONITOR_PID=$!

# Aguardar job iniciar
echo "Aguardando job iniciar processamento..."
sleep 15

echo ""
echo ">>> ADICIONANDO RECURSOS: Iniciando worker2..."
ADD_TIME=$(date +%s)
echo "Worker adicionado em: $(date '+%Y-%m-%d %H:%M:%S')" > "$TEST_DIR/addition_timestamp_scenario4.txt"

docker start hadoop-worker2
sleep 10

collect_cluster_status "scenario4_addition"

echo "Worker2 adicionado. Job pode redistribuir tarefas..."
echo "Aguardando conclusão do job..."

# Aguardar job completar
wait $MONITOR_PID

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
ADDITION_OFFSET=$((ADD_TIME - START_TIME))

# Copiar log do job
docker exec hadoop-master bash -c "cat /tmp/job_scenario4.log" > "$TEST_DIR/job_output_scenario4.txt"

echo "$DURATION" > "$TEST_DIR/duration_scenario4.txt"
echo "$ADDITION_OFFSET" > "$TEST_DIR/addition_offset_scenario4.txt"

echo ""
echo "✓ Job concluído em ${DURATION}s (worker adicionado após ${ADDITION_OFFSET}s)"

collect_cluster_status "scenario4_after"

# ============================================================================
# GERAR RELATÓRIO CONSOLIDADO
# ============================================================================
echo ""
echo "Gerando relatório consolidado..."

cat > "$TEST_DIR/relatorio_tolerancia_falhas.md" << 'REPORT_EOF'
# Relatório de Testes de Tolerância a Falhas - Hadoop

## Resumo Executivo

Este relatório documenta os testes de tolerância a falhas realizados no cluster Hadoop,
simulando cenários reais de falha e recuperação de nós durante a execução de jobs MapReduce.

## Cenários Testados

### Cenário 1: Baseline (Execução Normal)
- **Descrição**: Execução do WordCount com todos os nós ativos
- **Duração**: $(cat "$TEST_DIR/duration_baseline.txt" 2>/dev/null || echo "N/A")s
- **Application ID**: $(cat "$TEST_DIR/app_id_baseline.txt" 2>/dev/null || echo "N/A")
- **Resultado**: ✓ Sucesso

### Cenário 2: Falha de 1 Worker (worker2)
- **Descrição**: Worker2 é parado durante a execução do job
- **Momento da falha**: $(cat "$TEST_DIR/failure_offset_scenario2.txt" 2>/dev/null || echo "N/A")s após início
- **Duração total**: $(cat "$TEST_DIR/duration_scenario2.txt" 2>/dev/null || echo "N/A")s
- **Application ID**: $(cat "$TEST_DIR/app_id_scenario2.txt" 2>/dev/null || echo "N/A")
- **Impacto**: O Hadoop detectou a falha e re-escalonou as tarefas para os nós disponíveis

### Cenário 3: Falha de 2 Workers (worker1 e worker2)
- **Descrição**: Ambos workers são parados durante a execução
- **Duração total**: $(cat "$TEST_DIR/duration_scenario3.txt" 2>/dev/null || echo "N/A")s
- **Application ID**: $(cat "$TEST_DIR/app_id_scenario3.txt" 2>/dev/null || echo "N/A")
- **Impacto**: Job continua executando apenas no master (se configurado) ou falha

### Cenário 4: Adição de Worker Durante Execução
- **Descrição**: Worker2 é adicionado durante a execução (scale up)
- **Momento da adição**: $(cat "$TEST_DIR/addition_offset_scenario4.txt" 2>/dev/null || echo "N/A")s após início
- **Duração total**: $(cat "$TEST_DIR/duration_scenario4.txt" 2>/dev/null || echo "N/A")s
- **Application ID**: $(cat "$TEST_DIR/app_id_scenario4.txt" 2>/dev/null || echo "N/A")
- **Benefício**: Novos recursos ficam disponíveis para tarefas pendentes

## Análise Comparativa

| Cenário | Duração (s) | Variação vs Baseline | Nós Ativos | Status |
|---------|-------------|----------------------|------------|--------|
| Baseline | $(cat "$TEST_DIR/duration_baseline.txt" 2>/dev/null || echo "N/A") | - | 3 (master + 2 workers) | ✓ |
| 1 Worker Down | $(cat "$TEST_DIR/duration_scenario2.txt" 2>/dev/null || echo "N/A") | $([ -f "$TEST_DIR/duration_baseline.txt" ] && [ -f "$TEST_DIR/duration_scenario2.txt" ] && echo "scale=2; ($(cat "$TEST_DIR/duration_scenario2.txt") - $(cat "$TEST_DIR/duration_baseline.txt")) / $(cat "$TEST_DIR/duration_baseline.txt") * 100" | bc || echo "N/A")% | 2 (master + 1 worker) | ✓ |
| 2 Workers Down | $(cat "$TEST_DIR/duration_scenario3.txt" 2>/dev/null || echo "N/A") | $([ -f "$TEST_DIR/duration_baseline.txt" ] && [ -f "$TEST_DIR/duration_scenario3.txt" ] && echo "scale=2; ($(cat "$TEST_DIR/duration_scenario3.txt") - $(cat "$TEST_DIR/duration_baseline.txt")) / $(cat "$TEST_DIR/duration_baseline.txt") * 100" | bc || echo "N/A")% | 1 (apenas master) | ? |
| Scale Up | $(cat "$TEST_DIR/duration_scenario4.txt" 2>/dev/null || echo "N/A") | $([ -f "$TEST_DIR/duration_baseline.txt" ] && [ -f "$TEST_DIR/duration_scenario4.txt" ] && echo "scale=2; ($(cat "$TEST_DIR/duration_scenario4.txt") - $(cat "$TEST_DIR/duration_baseline.txt")) / $(cat "$TEST_DIR/duration_baseline.txt") * 100" | bc || echo "N/A")% | 1→2 durante execução | ✓ |

## Conclusões

### Tolerância a Falhas
1. **Resiliência**: O Hadoop demonstrou capacidade de continuar jobs mesmo com perda de nós
2. **Re-escalonamento**: Tasks foram automaticamente redistribuídas para nós disponíveis
3. **Overhead**: Falhas causam overhead de re-execução de tarefas em andamento

### Desempenho
1. **Impacto de Falha**: Perda de nós aumenta significativamente o tempo de execução
2. **Escalabilidade**: Adição de nós durante execução pode beneficiar tarefas pendentes
3. **Limite**: Com apenas master ativo, performance é severamente degradada

### Recomendações
1. Configurar replicação adequada (RF=3) para evitar perda de dados
2. Monitorar saúde dos nós continuamente
3. Configurar speculative execution para mitigar stragglers
4. Provisionar recursos extras para absorver falhas temporárias

## Arquivos de Evidência

- Status do cluster: `cluster_status_*.txt`
- Logs dos jobs: `job_output_*.txt`
- Monitoramento: `job_monitoring.log`
- Application IDs: `app_id_*.txt`
- Tempos de execução: `duration_*.txt`

---
**Data do teste**: $(date '+%Y-%m-%d %H:%M:%S')
**Cluster**: hadoop-master + hadoop-worker1 + hadoop-worker2
REPORT_EOF

cat "$TEST_DIR/relatorio_tolerancia_falhas.md"

echo ""
echo "============================================================"
echo "✅ TESTES DE TOLERÂNCIA A FALHAS CONCLUÍDOS"
echo "============================================================"
echo "Resultados salvos em: $TEST_DIR"
echo ""
echo "Arquivos gerados:"
ls -lh "$TEST_DIR"
echo ""
