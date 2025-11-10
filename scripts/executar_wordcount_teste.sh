#!/bin/bash

# Configurações
INPUT_DIR="/user/hadoop/wordcount/input"
OUTPUT_DIR="/user/hadoop/wordcount/output"
RESULTADOS_DIR="/home/hadoop/wordcount_resultados"

echo "Executando teste de WordCount..."

# Entrar no container master
docker exec -u hadoop hadoop-master bash -c "
    # Criar diretório para resultados
    mkdir -p $RESULTADOS_DIR
    
    # Limpar resultados anteriores
    rm -f $RESULTADOS_DIR/*

    # Remover diretório de saída anterior se existir
    hdfs dfs -rm -r -f $OUTPUT_DIR

    # Capturar configurações atuais do cluster
    echo '=== CONFIGURAÇÕES DO CLUSTER ===' > $RESULTADOS_DIR/config.txt
    echo 'YARN Memory:' >> $RESULTADOS_DIR/config.txt
    hdfs getconf -confKey yarn.nodemanager.resource.memory-mb >> $RESULTADOS_DIR/config.txt 2>/dev/null || echo 'default' >> $RESULTADOS_DIR/config.txt
    echo 'HDFS Replication:' >> $RESULTADOS_DIR/config.txt
    hdfs getconf -confKey dfs.replication >> $RESULTADOS_DIR/config.txt 2>/dev/null || echo 'default' >> $RESULTADOS_DIR/config.txt
    echo 'HDFS Block Size:' >> $RESULTADOS_DIR/config.txt
    hdfs getconf -confKey dfs.blocksize >> $RESULTADOS_DIR/config.txt 2>/dev/null || echo 'default' >> $RESULTADOS_DIR/config.txt
    echo 'Map Reducers:' >> $RESULTADOS_DIR/config.txt
    hdfs getconf -confKey mapreduce.job.reduces >> $RESULTADOS_DIR/config.txt 2>/dev/null || echo 'default' >> $RESULTADOS_DIR/config.txt
    
    # Obter informações sobre o input
    echo -e '\n=== INFORMAÇÕES DO INPUT ===' >> $RESULTADOS_DIR/config.txt
    hdfs dfs -du -h $INPUT_DIR >> $RESULTADOS_DIR/config.txt 2>&1
    hdfs fsck $INPUT_DIR -files -blocks -locations >> $RESULTADOS_DIR/hdfs_fsck_before.txt 2>&1

    # Executar WordCount com medição de tempo e captura completa de saída
    echo 'Executando WordCount...'
    START_TIME=\$(date +%s)
    
    /usr/bin/time -v hadoop jar /home/hadoop/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \\
        wordcount $INPUT_DIR $OUTPUT_DIR \\
        > $RESULTADOS_DIR/job_output.txt 2> $RESULTADOS_DIR/time_stats.txt
    
    END_TIME=\$(date +%s)
    DURATION=\$((END_TIME - START_TIME))

    # Salvar resultado do wordcount
    echo 'Salvando resultados...'
    hdfs dfs -cat ${OUTPUT_DIR}/part-r-* > $RESULTADOS_DIR/wordcount_output.txt 2>/dev/null || echo 'Erro ao recuperar output' > $RESULTADOS_DIR/wordcount_output.txt

    # Obter Application ID do último job
    APP_ID=\$(grep 'Submitted application' $RESULTADOS_DIR/job_output.txt | tail -1 | grep -oP 'application_[0-9_]+' || echo '')
    
    if [ -z \"\$APP_ID\" ]; then
        APP_ID=\$(yarn application -list -appStates FINISHED 2>/dev/null | grep 'application_' | tail -1 | awk '{print \$1}')
    fi
    
    echo \"Application ID: \$APP_ID\" > $RESULTADOS_DIR/app_id.txt

    # Capturar logs detalhados do YARN
    if [ -n \"\$APP_ID\" ]; then
        echo 'Capturando logs do YARN...'
        yarn logs -applicationId \$APP_ID > $RESULTADOS_DIR/yarn_logs.txt 2>&1 || echo 'Erro ao capturar logs' > $RESULTADOS_DIR/yarn_logs.txt
        
        # Tentar obter estatísticas da aplicação
        yarn application -status \$APP_ID > $RESULTADOS_DIR/app_status.txt 2>&1 || true
    fi

    # Extrair métricas do job output
    echo 'Extraindo métricas...'
    
    # Criar relatório consolidado
    cat > $RESULTADOS_DIR/relatorio.txt << 'EOF'
==================================================
       RELATÓRIO DE EXECUÇÃO - WORDCOUNT
==================================================

EOF

    # Adicionar timestamp
    echo \"Timestamp: \$(date)\" >> $RESULTADOS_DIR/relatorio.txt
    echo \"Duração Total: \${DURATION}s\" >> $RESULTADOS_DIR/relatorio.txt
    echo \"Application ID: \$APP_ID\" >> $RESULTADOS_DIR/relatorio.txt
    echo -e \"\n--- CONFIGURAÇÕES ---\" >> $RESULTADOS_DIR/relatorio.txt
    cat $RESULTADOS_DIR/config.txt >> $RESULTADOS_DIR/relatorio.txt
    
    # Extrair informações dos contadores do MapReduce
    echo -e \"\n--- MÉTRICAS DO JOB ---\" >> $RESULTADOS_DIR/relatorio.txt
    
    if grep -q 'Job Finished' $RESULTADOS_DIR/job_output.txt; then
        echo 'Status: SUCESSO ✓' >> $RESULTADOS_DIR/relatorio.txt
    else
        echo 'Status: FALHA ✗' >> $RESULTADOS_DIR/relatorio.txt
    fi
    
    # Extrair contadores
    grep -A 50 'Counters:' $RESULTADOS_DIR/job_output.txt >> $RESULTADOS_DIR/relatorio.txt 2>/dev/null || echo 'Contadores não disponíveis' >> $RESULTADOS_DIR/relatorio.txt
    
    # Estatísticas de tempo do /usr/bin/time
    echo -e \"\n--- RECURSOS DO SISTEMA ---\" >> $RESULTADOS_DIR/relatorio.txt
    grep 'Elapsed (wall clock) time' $RESULTADOS_DIR/time_stats.txt >> $RESULTADOS_DIR/relatorio.txt 2>/dev/null
    grep 'Maximum resident set size' $RESULTADOS_DIR/time_stats.txt >> $RESULTADOS_DIR/relatorio.txt 2>/dev/null
    grep 'Percent of CPU this job got' $RESULTADOS_DIR/time_stats.txt >> $RESULTADOS_DIR/relatorio.txt 2>/dev/null
    grep 'User time' $RESULTADOS_DIR/time_stats.txt >> $RESULTADOS_DIR/relatorio.txt 2>/dev/null
    grep 'System time' $RESULTADOS_DIR/time_stats.txt >> $RESULTADOS_DIR/relatorio.txt 2>/dev/null
    
    # Resultados do WordCount
    echo -e \"\n--- RESULTADOS ---\" >> $RESULTADOS_DIR/relatorio.txt
    WORD_COUNT=\$(wc -l < $RESULTADOS_DIR/wordcount_output.txt 2>/dev/null || echo '0')
    echo \"Palavras únicas encontradas: \$WORD_COUNT\" >> $RESULTADOS_DIR/relatorio.txt
    echo -e \"\nTop 10 palavras mais frequentes:\" >> $RESULTADOS_DIR/relatorio.txt
    sort -k2 -nr $RESULTADOS_DIR/wordcount_output.txt 2>/dev/null | head -10 >> $RESULTADOS_DIR/relatorio.txt || echo 'N/A' >> $RESULTADOS_DIR/relatorio.txt
    
    # Informações do HDFS após execução
    echo -e \"\n--- INFORMAÇÕES DO OUTPUT (HDFS) ---\" >> $RESULTADOS_DIR/relatorio.txt
    hdfs dfs -du -h $OUTPUT_DIR >> $RESULTADOS_DIR/relatorio.txt 2>&1
    hdfs fsck $OUTPUT_DIR -files -blocks -locations >> $RESULTADOS_DIR/hdfs_fsck_after.txt 2>&1
    
    echo -e \"\n==================================================\" >> $RESULTADOS_DIR/relatorio.txt
    
    # Mostrar relatório no terminal
    cat $RESULTADOS_DIR/relatorio.txt
"

# Copiar resultados para fora do container
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEST_DIR="./resultados/execucao_${TIMESTAMP}"
mkdir -p "$DEST_DIR"

echo "Copiando resultados do container..."
docker cp hadoop-master:/home/hadoop/wordcount_resultados/. "$DEST_DIR/"

echo ""
echo "========================================="
echo "Teste do WordCount concluído!"
echo "Resultados salvos em: $DEST_DIR"
echo "========================================="
