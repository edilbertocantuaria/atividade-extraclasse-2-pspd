#!/bin/bash

# Verificar se os argumentos foram fornecidos
if [ $# -ne 2 ]; then
    echo "Uso: $0 <diretório_entrada> <diretório_saída>"
    exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR=$2

# Remover diretório de saída se existir
hdfs dfs -rm -r -f $OUTPUT_DIR

# Executar o programa WordCount
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount $INPUT_DIR $OUTPUT_DIR

# Mostrar os resultados
echo "Resultados do WordCount:"
hdfs dfs -cat ${OUTPUT_DIR}/part-r-*