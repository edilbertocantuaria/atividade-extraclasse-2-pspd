#!/bin/bash

echo "================================================"
echo "  VERIFICAÇÃO DO AMBIENTE - TESTES B1"
echo "================================================"
echo ""

cd ~/pspd/atividade-extraclasse-2-pspd

error_count=0

# 1. Verificar containers
echo "1. Verificando containers Docker..."
if docker ps | grep -q hadoop-master; then
    echo "   ✅ Containers Hadoop rodando"
else
    echo "   ❌ Containers não encontrados"
    echo "      Execute: cd hadoop && docker compose up -d"
    ((error_count++))
fi
echo ""

# 2. Verificar arquivos de configuração pré-configurados
echo "2. Verificando arquivos de configuração pré-configurados..."
configs=(
    "config/teste1_memoria/yarn-site.xml"
    "config/teste2_replicacao/hdfs-site.xml"
    "config/teste3_blocksize/hdfs-site.xml"
    "config/teste4_reducers/mapred-site.xml"
)

for config in "${configs[@]}"; do
    if [ -f "$config" ]; then
        echo "   ✅ $config"
    else
        echo "   ❌ $config não encontrado"
        ((error_count++))
    fi
done
echo ""

# 3. Validar XMLs
echo "3. Validando sintaxe dos XMLs..."
if ./scripts/validar_config_xml.sh > /dev/null 2>&1; then
    echo "   ✅ Todos os XMLs válidos"
else
    echo "   ❌ Erros encontrados nos XMLs"
    echo "      Execute: ./scripts/validar_config_xml.sh"
    ((error_count++))
fi
echo ""

# 4. Verificar scripts
echo "4. Verificando scripts..."
scripts=(
    "executar_testes_limpo.sh"
    "scripts/rodar_testes_b1_v2.sh"
    "scripts/limpar_processos.sh"
    "scripts/validar_config_xml.sh"
    "scripts/gerar_dataset_v2.sh"
    "scripts/executar_wordcount_teste.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo "   ✅ $script (executável)"
    elif [ -f "$script" ]; then
        echo "   ⚠️  $script (sem permissão de execução)"
        chmod +x "$script"
        echo "      → Permissão adicionada"
    else
        echo "   ❌ $script não encontrado"
        ((error_count++))
    fi
done
echo ""

# 5. Verificar conectividade com containers
echo "5. Verificando conectividade com containers..."
if docker exec hadoop-master echo "OK" > /dev/null 2>&1; then
    echo "   ✅ Master acessível"
else
    echo "   ❌ Master não acessível"
    ((error_count++))
fi

if docker exec hadoop-worker1 echo "OK" > /dev/null 2>&1; then
    echo "   ✅ Worker1 acessível"
else
    echo "   ❌ Worker1 não acessível"
    ((error_count++))
fi

if docker exec hadoop-worker2 echo "OK" > /dev/null 2>&1; then
    echo "   ✅ Worker2 acessível"
else
    echo "   ❌ Worker2 não acessível"
    ((error_count++))
fi
echo ""

# Resultado final
echo "================================================"
if [ $error_count -eq 0 ]; then
    echo "✅ AMBIENTE OK - PRONTO PARA EXECUTAR TESTES!"
    echo ""
    echo "Execute:"
    echo "  ./executar_testes_limpo.sh"
    echo ""
    exit 0
else
    echo "❌ ENCONTRADOS $error_count ERRO(S)"
    echo ""
    echo "Corrija os problemas acima antes de executar os testes."
    echo ""
    exit 1
fi
