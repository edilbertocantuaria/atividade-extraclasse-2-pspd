#!/bin/bash

echo "🔧 Corrigindo arquivos de configuração XML do Hadoop..."
echo ""

HADOOP_DIR="$(dirname "$0")/../hadoop"

# Função para corrigir XML básico
fix_basic_xml() {
    local file="$1"
    local filename=$(basename "$file")
    
    echo "Processando: $filename"
    
    # Fazer backup
    cp "$file" "${file}.backup"
    
    # Remover linhas vazias com apenas <property>
    sed -i '/^[[:space:]]*<property>[[:space:]]*$/d' "$file"
    
    # Garantir que não há tags duplicadas no final
    # (Este é um fix simples, pode precisar de ajustes)
    
    echo "  ✓ Backup criado: ${filename}.backup"
}

echo "Corrigindo arquivos do MASTER:"
for file in "$HADOOP_DIR/master"/{core-site,hdfs-site,mapred-site,yarn-site}.xml; do
    if [ -f "$file" ]; then
        fix_basic_xml "$file"
    fi
done

echo ""
echo "Corrigindo arquivos do WORKER1:"
for file in "$HADOOP_DIR/worker1"/{core-site,hdfs-site,mapred-site,yarn-site}.xml; do
    if [ -f "$file" ]; then
        fix_basic_xml "$file"
    fi
done

echo ""
echo "Corrigindo arquivos do WORKER2:"
for file in "$HADOOP_DIR/worker2"/{core-site,hdfs-site,mapred-site,yarn-site}.xml; do
    if [ -f "$file" ]; then
        fix_basic_xml "$file"
    fi
done

echo ""
echo "✅ Correção básica concluída!"
echo "   Execute o validador para verificar: ./scripts/validar_config_xml.sh"
