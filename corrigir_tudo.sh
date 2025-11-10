#!/bin/bash

echo "=========================================="
echo "  CORREÇÃO COMPLETA - PREPARAÇÃO FINAL"
echo "=========================================="
echo ""

cd ~/pspd/atividade-extraclasse-2-pspd

echo "1️⃣  Recriando todos os arquivos XML base..."
./scripts/recriar_xmls.sh

echo ""
echo "2️⃣  Validando XMLs recriados..."
./scripts/validar_config_xml.sh || {
    echo ""
    echo "❌ Erro na validação. Verifique manualmente."
    exit 1
}

echo ""
echo "3️⃣  Reiniciando containers para aplicar configurações..."
cd hadoop
docker compose down -v
docker compose up -d
sleep 15
cd ..

echo ""
echo "=========================================="
echo "✅ AMBIENTE PRONTO!"
echo "=========================================="
echo ""
echo "Execute os testes:"
echo "  ./executar_testes_limpo.sh"
echo ""
