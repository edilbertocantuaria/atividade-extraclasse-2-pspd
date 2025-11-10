#!/bin/bash

echo "Gerando dataset para teste do WordCount..."

# Etapa 1: Criar arquivo base
echo "Criando arquivo base..."
docker exec -u hadoop hadoop-master bash -c "echo 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia.' > /home/hadoop/base.txt"

# Etapa 2: Verificar se o arquivo base foi criado
echo "Verificando arquivo base..."
docker exec -u hadoop hadoop-master ls -l /home/hadoop/base.txt

# Etapa 3: Gerar arquivo grande
echo "Gerando arquivo grande..."
docker exec -u hadoop hadoop-master bash -c "for i in \$(seq 1 2000); do cat /home/hadoop/base.txt >> /home/hadoop/big.txt; done"

# Etapa 4: Verificar tamanho do arquivo grande
echo "Verificando arquivo grande..."
docker exec -u hadoop hadoop-master ls -lh /home/hadoop/big.txt

# Etapa 5: Criar diretório no HDFS
echo "Criando diretório no HDFS..."
docker exec -u hadoop hadoop-master hdfs dfs -mkdir -p /user/hadoop/wordcount/input

# Etapa 6: Copiar para HDFS
echo "Copiando para HDFS..."
docker exec -u hadoop hadoop-master hdfs dfs -put -f /home/hadoop/big.txt /user/hadoop/wordcount/input/

# Etapa 7: Verificar no HDFS
echo "Verificando arquivo no HDFS..."
docker exec -u hadoop hadoop-master hdfs dfs -ls /user/hadoop/wordcount/input/

# Etapa 8: Limpar arquivos temporários
echo "Limpando arquivos temporários..."
docker exec -u hadoop hadoop-master rm -f /home/hadoop/base.txt /home/hadoop/big.txt

echo "Dataset gerado com sucesso!"
