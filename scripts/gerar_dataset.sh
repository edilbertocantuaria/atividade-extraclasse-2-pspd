#!/bin/bash

# Configurações
TAMANHO_BASE=1MB
REPETICOES=2000  # Isso gerará ~2GB
DIR_HDFS="/user/hadoop/wordcount/input"
ARQUIVO_BASE="/home/hadoop/base.txt"
ARQUIVO_GRANDE="/home/hadoop/big.txt"

echo "Gerando dataset para teste do WordCount..."

# Entrar no container master
docker exec -u hadoop hadoop-master bash -c "
    # Criar arquivo base com conteúdo variado
    echo 'Gerando arquivo base...'
    cat > \$ARQUIVO_BASE << EOL
Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia.
EOL

    # Gerar arquivo grande
    echo 'Gerando arquivo grande...'
    for i in \$(seq 1 \$REPETICOES); do
        cat \$ARQUIVO_BASE >> \$ARQUIVO_GRANDE
    done

    # Criar diretório no HDFS
    echo 'Criando diretório no HDFS...'
    hdfs dfs -mkdir -p \$DIR_HDFS

    # Copiar arquivo para HDFS
    echo 'Copiando arquivo para HDFS...'
    hdfs dfs -put -f \$ARQUIVO_GRANDE \$DIR_HDFS/

    # Mostrar informações do arquivo
    echo 'Informações do arquivo no HDFS:'
    hdfs dfs -ls \$DIR_HDFS

    # Limpar arquivos temporários
    rm \$ARQUIVO_BASE \$ARQUIVO_GRANDE
"

echo "Dataset gerado com sucesso!"
