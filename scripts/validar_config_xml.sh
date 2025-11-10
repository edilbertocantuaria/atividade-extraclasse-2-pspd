#!/bin/bash

echo "🔍 Validando arquivos de configuração XML do Hadoop..."
echo ""

HADOOP_DIR="$(dirname "$0")/../hadoop"
ERRORS=0

validate_xml() {
    local file="$1"
    local filename=$(basename "$file")
    
    if [ ! -f "$file" ]; then
        echo "⚠️  Arquivo não encontrado: $file"
        return 1
    fi
    
    # Tentar validar XML com xmllint (se disponível) ou com um parser simples
    if command -v xmllint &> /dev/null; then
        if xmllint --noout "$file" 2>/dev/null; then
            echo "✅ $filename - OK"
            return 0
        else
            echo "❌ $filename - ERRO DE SINTAXE"
            xmllint --noout "$file" 2>&1 | head -5
            return 1
        fi
    else
        # Validação básica sem xmllint
        # Verificar tags <property> não fechadas
        local open_tags=$(grep -c '<property>' "$file" 2>/dev/null || echo "0")
        local close_tags=$(grep -c '</property>' "$file" 2>/dev/null || echo "0")
        
        # Garantir que são números
        open_tags=${open_tags//[^0-9]/}
        close_tags=${close_tags//[^0-9]/}
        open_tags=${open_tags:-0}
        close_tags=${close_tags:-0}
        
        if [ "$open_tags" -ne "$close_tags" ]; then
            echo "❌ $filename - ERRO: Tags <property> desbalanceadas"
            echo "   Abertas: $open_tags | Fechadas: $close_tags"
            return 1
        fi
        
        # Verificar tags configuration
        local open_config=$(grep -c '<configuration>' "$file" 2>/dev/null || echo "0")
        local close_config=$(grep -c '</configuration>' "$file" 2>/dev/null || echo "0")
        
        # Garantir que são números
        open_config=${open_config//[^0-9]/}
        close_config=${close_config//[^0-9]/}
        open_config=${open_config:-0}
        close_config=${close_config:-0}
        
        if [ "$open_config" -ne "$close_config" ]; then
            echo "❌ $filename - ERRO: Tags <configuration> desbalanceadas"
            return 1
        fi
        
        echo "✅ $filename - OK (validação básica)"
        return 0
    fi
}

echo "Validando arquivos do MASTER:"
for file in "$HADOOP_DIR/master"/*.xml; do
    validate_xml "$file" || ((ERRORS++))
done

echo ""
echo "Validando arquivos do WORKER1:"
for file in "$HADOOP_DIR/worker1"/*.xml; do
    validate_xml "$file" || ((ERRORS++))
done

echo ""
echo "Validando arquivos do WORKER2:"
for file in "$HADOOP_DIR/worker2"/*.xml; do
    validate_xml "$file" || ((ERRORS++))
done

echo ""
echo "================================================"
if [ $ERRORS -eq 0 ]; then
    echo "✅ Todos os arquivos XML estão válidos!"
    exit 0
else
    echo "❌ Encontrados $ERRORS erro(s) nos arquivos XML"
    echo "   Por favor, corrija os erros antes de executar o cluster"
    exit 1
fi
