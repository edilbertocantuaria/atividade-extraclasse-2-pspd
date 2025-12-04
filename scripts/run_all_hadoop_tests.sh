#!/bin/bash
#############################################################
# Script Unificado de Testes Hadoop
# Aplica cada configuração (teste0-baseline até teste5),
# executa wordcount, coleta métricas e salva resultados
#############################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$BASE_DIR/config"
RESULTADOS_DIR="$BASE_DIR/resultados/B1"
HADOOP_DIR="$BASE_DIR/hadoop"
WORDCOUNT_DIR="$BASE_DIR/wordcount"

# Dataset
DATASET_SIZE="${DATASET_SIZE:-500MB}"
INPUT_HDFS="/user/hadoop/input/large_dataset.txt"
JAR_FILE="$WORDCOUNT_DIR/target/wordcount.jar"

# Testes a executar
TESTS=("teste0_baseline" "teste1_memoria" "teste2_replicacao" "teste3_blocksize" "teste4_reducers" "teste5_speculative")

#############################################################
# Funções auxiliares
#############################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verifica se o cluster está rodando
check_cluster() {
    log_info "Verificando status do cluster..."
    
    if ! docker-compose -f "$HADOOP_DIR/docker-compose.yml" ps | grep -q "Up"; then
        log_error "Cluster não está rodando. Execute: cd hadoop && docker-compose up -d"
        exit 1
    fi
    
    log_success "Cluster está rodando"
}

# Compila o WordCount
compile_wordcount() {
    log_info "Compilando WordCount..."
    
    cd "$WORDCOUNT_DIR"
    
    if [ ! -f "pom.xml" ]; then
        log_error "pom.xml não encontrado em $WORDCOUNT_DIR"
        exit 1
    fi
    
    docker-compose -f "$HADOOP_DIR/docker-compose.yml" exec -T master bash -c "
        cd /opt/wordcount
        mvn clean package -DskipTests
    " || {
        log_error "Falha ao compilar WordCount"
        exit 1
    }
    
    log_success "WordCount compilado com sucesso"
}

# Gera dataset grande
generate_large_dataset() {
    log_info "Gerando dataset de $DATASET_SIZE..."
    
    "$SCRIPT_DIR/generate_large_dataset.sh" "$DATASET_SIZE"
    
    log_info "Carregando dataset no HDFS..."
    
    docker-compose -f "$HADOOP_DIR/docker-compose.yml" exec -T master bash -c "
        hdfs dfs -rm -r -f /user/hadoop/input 2>/dev/null || true
        hdfs dfs -mkdir -p /user/hadoop/input
        hdfs dfs -put -f /opt/wordcount/input/large_dataset.txt $INPUT_HDFS
        hdfs dfs -ls /user/hadoop/input/
    "
    
    log_success "Dataset carregado no HDFS"
}

# Aplica configuração específica do teste
apply_test_config() {
    local test_name=$1
    log_info "Aplicando configuração do $test_name..."
    
    # Copia configurações específicas se existirem
    if [ -d "$CONFIG_DIR/$test_name" ]; then
        docker-compose -f "$HADOOP_DIR/docker-compose.yml" exec -T master bash -c "
            # Backup das configs atuais
            cp -r /opt/hadoop/etc/hadoop /opt/hadoop/etc/hadoop.backup
            
            # Aplica novas configs
            cp /opt/config/$test_name/*.xml /opt/hadoop/etc/hadoop/ 2>/dev/null || true
            
            # Reinicia serviços YARN para aplicar mudanças
            /opt/hadoop/sbin/stop-yarn.sh
            sleep 5
            /opt/hadoop/sbin/start-yarn.sh
            sleep 10
        "
        log_success "Configuração aplicada. Aguardando estabilização..."
        sleep 15
    else
        log_warning "Configuração $test_name não encontrada, usando baseline"
    fi
}

# Coleta métricas antes da execução
collect_pre_metrics() {
    local test_name=$1
    local output_dir=$2
    
    log_info "Coletando métricas pré-execução..."
    
    docker-compose -f "$HADOOP_DIR/docker-compose.yml" exec -T master bash -c "
        echo '=== Cluster Status ===' > /tmp/pre_metrics.txt
        echo '' >> /tmp/pre_metrics.txt
        
        echo '--- YARN Nodes ---' >> /tmp/pre_metrics.txt
        yarn node -list 2>&1 >> /tmp/pre_metrics.txt
        echo '' >> /tmp/pre_metrics.txt
        
        echo '--- HDFS Report ---' >> /tmp/pre_metrics.txt
        hdfs dfsadmin -report 2>&1 >> /tmp/pre_metrics.txt
        echo '' >> /tmp/pre_metrics.txt
        
        echo '--- JPS (Java Processes) ---' >> /tmp/pre_metrics.txt
        jps 2>&1 >> /tmp/pre_metrics.txt
        echo '' >> /tmp/pre_metrics.txt
        
        cat /tmp/pre_metrics.txt
    " > "$output_dir/pre_metrics.txt"
    
    log_success "Métricas pré-execução coletadas"
}

# Executa WordCount
run_wordcount() {
    local test_name=$1
    local output_dir=$2
    local output_hdfs="/user/hadoop/output/$test_name"
    
    log_info "Executando WordCount para $test_name..."
    
    # Remove output anterior se existir
    docker-compose -f "$HADOOP_DIR/docker-compose.yml" exec -T master bash -c "
        hdfs dfs -rm -r -f $output_hdfs 2>/dev/null || true
    "
    
    # Executa WordCount e mede tempo
    local start_time=$(date +%s)
    
    docker-compose -f "$HADOOP_DIR/docker-compose.yml" exec -T master bash -c "
        hadoop jar /opt/wordcount/target/wordcount.jar \
            br.unb.cic.pspd.wordcount.WordCountDriver \
            $INPUT_HDFS \
            $output_hdfs
    " 2>&1 | tee "$output_dir/job_output.txt"
    
    local exit_code=${PIPESTATUS[0]}
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "EXECUTION_TIME_SECONDS=$duration" > "$output_dir/execution_time.txt"
    echo "START_TIME=$(date -d @$start_time '+%Y-%m-%d %H:%M:%S')" >> "$output_dir/execution_time.txt"
    echo "END_TIME=$(date -d @$end_time '+%Y-%m-%d %H:%M:%S')" >> "$output_dir/execution_time.txt"
    echo "DURATION_FORMATTED=$(printf '%02d:%02d:%02d' $((duration/3600)) $((duration%3600/60)) $((duration%60)))" >> "$output_dir/execution_time.txt"
    
    if [ $exit_code -eq 0 ]; then
        log_success "WordCount concluído em ${duration}s ($(printf '%02d:%02d:%02d' $((duration/3600)) $((duration%3600/60)) $((duration%60))))"
    else
        log_error "WordCount falhou com código $exit_code"
        return $exit_code
    fi
    
    # Extrai informações do job dos logs
    grep -E "(map.*reduce|Counters|File System Counters|Job Counters|Map-Reduce Framework)" "$output_dir/job_output.txt" > "$output_dir/job_counters.txt" || true
}

# Coleta métricas após execução
collect_post_metrics() {
    local test_name=$1
    local output_dir=$2
    
    log_info "Coletando métricas pós-execução..."
    
    docker-compose -f "$HADOOP_DIR/docker-compose.yml" exec -T master bash -c "
        echo '=== Post-Execution Metrics ===' > /tmp/post_metrics.txt
        echo '' >> /tmp/post_metrics.txt
        
        echo '--- YARN Applications ---' >> /tmp/post_metrics.txt
        yarn application -list -appStates FINISHED 2>&1 | tail -20 >> /tmp/post_metrics.txt
        echo '' >> /tmp/post_metrics.txt
        
        echo '--- HDFS Usage ---' >> /tmp/post_metrics.txt
        hdfs dfs -du -h /user/hadoop/ 2>&1 >> /tmp/post_metrics.txt
        echo '' >> /tmp/post_metrics.txt
        
        cat /tmp/post_metrics.txt
    " > "$output_dir/post_metrics.txt"
    
    # Captura logs do ResourceManager
    docker-compose -f "$HADOOP_DIR/docker-compose.yml" exec -T master bash -c "
        tail -100 /opt/hadoop/logs/yarn-*.log 2>/dev/null || echo 'Logs não disponíveis'
    " > "$output_dir/yarn_logs.txt"
    
    log_success "Métricas pós-execução coletadas"
}

# Gera relatório do teste
generate_test_report() {
    local test_name=$1
    local output_dir=$2
    
    log_info "Gerando relatório do $test_name..."
    
    cat > "$output_dir/REPORT.md" << EOF
# Relatório: $test_name

## Informações Gerais
- **Data/Hora**: $(date '+%Y-%m-%d %H:%M:%S')
- **Teste**: $test_name
- **Dataset**: $DATASET_SIZE ($INPUT_HDFS)

## Tempos de Execução
\`\`\`
$(cat "$output_dir/execution_time.txt")
\`\`\`

## Configurações Aplicadas
EOF

    if [ -d "$CONFIG_DIR/$test_name" ]; then
        echo "" >> "$output_dir/REPORT.md"
        echo "### Arquivos de Configuração" >> "$output_dir/REPORT.md"
        echo "\`\`\`" >> "$output_dir/REPORT.md"
        ls -lh "$CONFIG_DIR/$test_name/" >> "$output_dir/REPORT.md"
        echo "\`\`\`" >> "$output_dir/REPORT.md"
    fi

    cat >> "$output_dir/REPORT.md" << EOF

## Métricas do Cluster

### Pré-Execução
\`\`\`
$(cat "$output_dir/pre_metrics.txt")
\`\`\`

### Pós-Execução
\`\`\`
$(cat "$output_dir/post_metrics.txt")
\`\`\`

## Counters do Job
\`\`\`
$(cat "$output_dir/job_counters.txt" 2>/dev/null || echo "Counters não disponíveis")
\`\`\`

## Output do Job
\`\`\`
$(tail -50 "$output_dir/job_output.txt")
\`\`\`
EOF

    log_success "Relatório gerado: $output_dir/REPORT.md"
}

# Restaura configuração original
restore_config() {
    log_info "Restaurando configuração original..."
    
    docker-compose -f "$HADOOP_DIR/docker-compose.yml" exec -T master bash -c "
        if [ -d /opt/hadoop/etc/hadoop.backup ]; then
            rm -rf /opt/hadoop/etc/hadoop
            mv /opt/hadoop/etc/hadoop.backup /opt/hadoop/etc/hadoop
            
            /opt/hadoop/sbin/stop-yarn.sh
            sleep 5
            /opt/hadoop/sbin/start-yarn.sh
            sleep 10
        fi
    "
    
    log_success "Configuração restaurada"
}

#############################################################
# Função principal
#############################################################

run_single_test() {
    local test_name=$1
    local output_dir="$RESULTADOS_DIR/$test_name"
    
    echo ""
    log_info "=========================================="
    log_info "  Executando: $test_name"
    log_info "=========================================="
    echo ""
    
    # Cria diretório de saída
    mkdir -p "$output_dir"
    
    # Aplica configuração
    apply_test_config "$test_name"
    
    # Coleta métricas pré
    collect_pre_metrics "$test_name" "$output_dir"
    
    # Executa WordCount
    if run_wordcount "$test_name" "$output_dir"; then
        # Coleta métricas pós
        collect_post_metrics "$test_name" "$output_dir"
        
        # Gera relatório
        generate_test_report "$test_name" "$output_dir"
        
        log_success "$test_name concluído com sucesso!"
    else
        log_error "$test_name falhou!"
        return 1
    fi
    
    # Aguarda antes do próximo teste
    sleep 10
}

main() {
    echo ""
    log_info "=========================================="
    log_info "  Script Unificado de Testes Hadoop"
    log_info "=========================================="
    echo ""
    
    # Verifica cluster
    check_cluster
    
    # Compila WordCount
    compile_wordcount
    
    # Gera dataset
    generate_large_dataset
    
    # Cria diretório de resultados
    mkdir -p "$RESULTADOS_DIR"
    
    # Executa cada teste
    local failed_tests=()
    
    for test in "${TESTS[@]}"; do
        if ! run_single_test "$test"; then
            failed_tests+=("$test")
        fi
    done
    
    # Restaura configuração original
    restore_config
    
    # Resumo final
    echo ""
    log_info "=========================================="
    log_info "  Resumo da Execução"
    log_info "=========================================="
    echo ""
    
    if [ ${#failed_tests[@]} -eq 0 ]; then
        log_success "Todos os testes foram executados com sucesso!"
    else
        log_warning "Testes com falha: ${failed_tests[*]}"
    fi
    
    log_info "Resultados salvos em: $RESULTADOS_DIR"
    
    # Gera relatório comparativo
    "$SCRIPT_DIR/generate_comparative_report.sh"
}

# Executa
main "$@"
