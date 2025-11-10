#!/bin/bash

# Configurações
INPUT_DIR="/user/hadoop/wordcount/input"
OUTPUT_DIR="/user/hadoop/wordcount/output"
RESULTADOS_DIR="/home/hadoop/wordcount/resultados"

echo "Executando teste de WordCount..."

# Entrar no container master
docker exec -u hadoop hadoop-master bash -c "
    # Criar diretório para resultados
    mkdir -p \$RESULTADOS_DIR

    # Remover diretório de saída anterior se existir
    hdfs dfs -rm -r -f \$OUTPUT_DIR

    # Executar WordCount com medição de tempo
    echo 'Executando WordCount...'
    /usr/bin/time -v hadoop jar \$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \\
        wordcount \$INPUT_DIR \$OUTPUT_DIR \\
        2> \$RESULTADOS_DIR/time_stats.txt

    # Salvar resultado do wordcount
    echo 'Salvando resultados...'
    hdfs dfs -cat \${OUTPUT_DIR}/part-r-* > \$RESULTADOS_DIR/wordcount_output.txt

    # Salvar logs do YARN
    yarn logs -applicationId \$(yarn application -list -appStates FINISHED | grep 'wordcount' | tail -1 | cut -f1) \\
        > \$RESULTADOS_DIR/yarn_logs.txt

    # Mostrar estatísticas básicas
    echo 'Estatísticas do job:'
    echo 'Tempo total:' 
    grep 'Elapsed (wall clock) time' \$RESULTADOS_DIR/time_stats.txt
    echo 'Uso de memória:'
    grep 'Maximum resident set size' \$RESULTADOS_DIR/time_stats.txt
    echo 'Número de palavras únicas:'
    wc -l \$RESULTADOS_DIR/wordcount_output.txt
"

echo "Teste do WordCount concluído!"
