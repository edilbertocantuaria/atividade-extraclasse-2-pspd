#!/bin/bash
set -euo pipefail

# ============================================================================
# METRICS COLLECTOR - Sistema de Coleta de Métricas Padronizado
# ============================================================================
# Coleta métricas detalhadas de jobs Hadoop: tempo, throughput, fases, recursos
# ============================================================================

# Uso: ./collect_metrics.sh <app_id> <output_dir> [dataset_size_mb]

APP_ID=${1:-}
OUTPUT_DIR=${2:-}
DATASET_SIZE_MB=${3:-500}

if [ -z "$APP_ID" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Uso: $0 <application_id> <output_dir> [dataset_size_mb]"
    echo ""
    echo "Exemplo: $0 application_1234567890123_0001 ./resultados/teste1 500"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "============================================================"
echo "COLETA DE MÉTRICAS - Application $APP_ID"
echo "============================================================"
echo "Diretório de saída: $OUTPUT_DIR"
echo ""

# ============================================================================
# 1. MÉTRICAS TEMPORAIS
# ============================================================================
echo "Coletando métricas temporais..."

TEMPORAL_FILE="$OUTPUT_DIR/temporal_metrics.txt"

docker exec hadoop-master bash -c "
  yarn application -status $APP_ID 2>/dev/null
" > "$TEMPORAL_FILE" 2>&1 || {
    echo "Erro ao obter status da aplicação"
    exit 1
}

# Extrair timestamps
START_TIME=$(grep "Start-Time" "$TEMPORAL_FILE" | awk '{print $3}' | head -1)
FINISH_TIME=$(grep "Finish-Time" "$TEMPORAL_FILE" | awk '{print $3}' | head -1)

if [ -n "$START_TIME" ] && [ -n "$FINISH_TIME" ] && [ "$FINISH_TIME" != "0" ]; then
    # Converter de ms para segundos
    DURATION_MS=$((FINISH_TIME - START_TIME))
    DURATION_S=$(echo "scale=2; $DURATION_MS / 1000" | bc)
    
    echo "Duração total: ${DURATION_S}s (${DURATION_MS}ms)" | tee "$OUTPUT_DIR/duration.txt"
else
    echo "Aviso: Timestamps não disponíveis"
    DURATION_S="N/A"
fi

# ============================================================================
# 2. MÉTRICAS DE THROUGHPUT
# ============================================================================
echo "Calculando throughput..."

THROUGHPUT_FILE="$OUTPUT_DIR/throughput_metrics.txt"

if [ "$DURATION_S" != "N/A" ] && [ -n "$DATASET_SIZE_MB" ]; then
    # MB/s
    THROUGHPUT_MBS=$(echo "scale=2; $DATASET_SIZE_MB / $DURATION_S" | bc)
    
    # MB/min
    THROUGHPUT_MBMIN=$(echo "scale=2; $THROUGHPUT_MBS * 60" | bc)
    
    # GB/hour
    THROUGHPUT_GBHOUR=$(echo "scale=2; $THROUGHPUT_MBMIN * 60 / 1024" | bc)
    
    cat > "$THROUGHPUT_FILE" << EOF
Dataset Size: ${DATASET_SIZE_MB} MB
Duration: ${DURATION_S}s
Throughput: ${THROUGHPUT_MBS} MB/s
Throughput: ${THROUGHPUT_MBMIN} MB/min
Throughput: ${THROUGHPUT_GBHOUR} GB/hour
EOF

    echo "Throughput: ${THROUGHPUT_MBS} MB/s (${THROUGHPUT_MBMIN} MB/min)" | tee -a "$OUTPUT_DIR/throughput.txt"
else
    echo "Aviso: Throughput não calculável (duração ou tamanho não disponível)"
fi

# ============================================================================
# 3. MÉTRICAS DE FASES (Map/Reduce)
# ============================================================================
echo "Coletando métricas de fases Map/Reduce..."

PHASE_FILE="$OUTPUT_DIR/phase_metrics.txt"

# Tentar obter do JobHistory
docker exec hadoop-master bash -c "
  mapred job -history all $APP_ID 2>/dev/null || \
  yarn logs -applicationId $APP_ID 2>/dev/null | grep -E 'map.*%|reduce.*%' | head -20
" > "$PHASE_FILE" 2>&1 || {
    echo "Aviso: Histórico de fases não disponível" | tee -a "$PHASE_FILE"
}

# Extrair informações de Map/Reduce do status
grep -E "map.*reduce|Total.*tasks|Successful|Failed" "$TEMPORAL_FILE" >> "$PHASE_FILE" 2>/dev/null || true

# ============================================================================
# 4. MÉTRICAS DE RECURSOS
# ============================================================================
echo "Coletando métricas de recursos..."

RESOURCE_FILE="$OUTPUT_DIR/resource_metrics.txt"

cat > "$RESOURCE_FILE" << EOF
=== Alocação de Recursos ===

EOF

# Memória e vCores alocados
grep -E "Allocated|Memory|VCores" "$TEMPORAL_FILE" >> "$RESOURCE_FILE" 2>/dev/null || true

# Estatísticas de containers
docker exec hadoop-master bash -c "
  yarn logs -applicationId $APP_ID 2>/dev/null | grep -E 'Container.*allocated|Container.*released' | wc -l
" > /tmp/container_count.txt 2>&1 || echo "0" > /tmp/container_count.txt

CONTAINER_COUNT=$(cat /tmp/container_count.txt 2>/dev/null || echo "0")
echo "" >> "$RESOURCE_FILE"
echo "Containers utilizados: ~$CONTAINER_COUNT" >> "$RESOURCE_FILE"

# ============================================================================
# 5. MÉTRICAS DE PERFORMANCE
# ============================================================================
echo "Coletando métricas de performance..."

PERF_FILE="$OUTPUT_DIR/performance_metrics.txt"

cat > "$PERF_FILE" << EOF
=== Métricas de Performance ===

Application ID: $APP_ID
Start Time: $(date -d @$((START_TIME / 1000)) '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "N/A")
Finish Time: $(date -d @$((FINISH_TIME / 1000)) '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "N/A")
Duration: ${DURATION_S}s

Dataset Size: ${DATASET_SIZE_MB} MB
Throughput: ${THROUGHPUT_MBS:-N/A} MB/s

Status Final: $(grep "Final-State" "$TEMPORAL_FILE" | awk '{print $3}' | head -1)
Progress: $(grep "Progress" "$TEMPORAL_FILE" | awk '{print $3}' | head -1)

EOF

# Contadores do job (se disponíveis)
echo "" >> "$PERF_FILE"
echo "=== Contadores do Job ===" >> "$PERF_FILE"

docker exec hadoop-master bash -c "
  mapred job -counter $APP_ID 2>/dev/null
" >> "$PERF_FILE" 2>&1 || echo "Contadores não disponíveis" >> "$PERF_FILE"

# ============================================================================
# 6. MÉTRICAS COMPARATIVAS (se baseline existir)
# ============================================================================
echo "Calculando métricas comparativas..."

COMPARATIVE_FILE="$OUTPUT_DIR/comparative_metrics.txt"

BASELINE_DURATION_FILE="/home/edilberto/pspd/atividade-extraclasse-2-pspd/resultados/B1/teste1_memoria/time_stats.txt"

if [ -f "$BASELINE_DURATION_FILE" ]; then
    BASELINE_DURATION=$(grep -oP '\d+' "$BASELINE_DURATION_FILE" | head -1 || echo "")
    
    if [ -n "$BASELINE_DURATION" ] && [ "$DURATION_S" != "N/A" ]; then
        VARIATION=$(echo "scale=2; ($DURATION_S - $BASELINE_DURATION) / $BASELINE_DURATION * 100" | bc)
        
        cat > "$COMPARATIVE_FILE" << EOF
=== Comparação com Baseline ===

Baseline Duration: ${BASELINE_DURATION}s
Current Duration: ${DURATION_S}s
Variation: ${VARIATION}%

EOF
        
        if (( $(echo "$VARIATION > 0" | bc -l) )); then
            echo "Performance: ${VARIATION}% mais lento que baseline" >> "$COMPARATIVE_FILE"
        else
            IMPROVEMENT=$(echo "scale=2; -1 * $VARIATION" | bc)
            echo "Performance: ${IMPROVEMENT}% mais rápido que baseline" >> "$COMPARATIVE_FILE"
        fi
        
        echo "Variação: ${VARIATION}%" | tee -a "$OUTPUT_DIR/variation.txt"
    fi
else
    echo "Baseline não encontrado para comparação" > "$COMPARATIVE_FILE"
fi

# ============================================================================
# 7. CONSOLIDAR EM CSV
# ============================================================================
echo "Gerando CSV consolidado..."

CSV_FILE="$OUTPUT_DIR/metrics_summary.csv"

cat > "$CSV_FILE" << EOF
Metric,Value,Unit
Application_ID,$APP_ID,
Start_Time,$START_TIME,ms
Finish_Time,$FINISH_TIME,ms
Duration,$DURATION_S,s
Dataset_Size,$DATASET_SIZE_MB,MB
Throughput_MBS,${THROUGHPUT_MBS:-N/A},MB/s
Throughput_MBMin,${THROUGHPUT_MBMIN:-N/A},MB/min
Throughput_GBHour,${THROUGHPUT_GBHOUR:-N/A},GB/h
Variation_vs_Baseline,${VARIATION:-N/A},%
Final_State,$(grep "Final-State" "$TEMPORAL_FILE" | awk '{print $3}' | head -1),
EOF

# ============================================================================
# 8. RELATÓRIO RESUMIDO
# ============================================================================
echo "Gerando relatório resumido..."

SUMMARY_FILE="$OUTPUT_DIR/metrics_summary.txt"

cat > "$SUMMARY_FILE" << EOF
============================================================
RESUMO DE MÉTRICAS - Application $APP_ID
============================================================

TEMPORAL
--------
Duração Total: ${DURATION_S}s
Início: $(date -d @$((START_TIME / 1000)) '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "N/A")
Fim: $(date -d @$((FINISH_TIME / 1000)) '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "N/A")

THROUGHPUT
----------
Dataset: ${DATASET_SIZE_MB} MB
Taxa: ${THROUGHPUT_MBS:-N/A} MB/s
Taxa: ${THROUGHPUT_MBMIN:-N/A} MB/min

COMPARATIVO
-----------
Variação vs Baseline: ${VARIATION:-N/A}%

STATUS
------
Estado Final: $(grep "Final-State" "$TEMPORAL_FILE" | awk '{print $3}' | head -1)
Progresso: $(grep "Progress" "$TEMPORAL_FILE" | awk '{print $3}' | head -1)

ARQUIVOS GERADOS
----------------
- metrics_summary.txt (este arquivo)
- metrics_summary.csv (formato CSV)
- temporal_metrics.txt (métricas temporais)
- throughput_metrics.txt (throughput)
- phase_metrics.txt (fases Map/Reduce)
- resource_metrics.txt (recursos alocados)
- performance_metrics.txt (performance geral)
- comparative_metrics.txt (comparação)

============================================================
Data: $(date '+%Y-%m-%d %H:%M:%S')
============================================================
EOF

cat "$SUMMARY_FILE"

echo ""
echo "✅ Coleta de métricas concluída!"
echo "Arquivos salvos em: $OUTPUT_DIR"
echo ""
