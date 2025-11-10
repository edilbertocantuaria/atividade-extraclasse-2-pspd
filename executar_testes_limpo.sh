#!/bin/bash

# Script para limpar processos Hadoop antes de executar testes

echo "================================================"
echo "  EXECUÇÃO DOS TESTES B1 - VERSÃO DEFINITIVA"
echo "================================================"
echo ""

cd ~/pspd/atividade-extraclasse-2-pspd

echo "🧹 Passo 1: Limpando processos Java do Hadoop..."
./scripts/limpar_processos.sh

echo ""
echo "� Passo 2: Validando arquivos XML..."
./scripts/validar_config_xml.sh || {
  echo "❌ Erro na validação. Verifique os arquivos XML."
  exit 1
}

echo ""
echo "�🚀 Passo 3: Executando testes com configurações pré-definidas..."
echo "   (Usando XMLs estáticos ao invés de modificações com sed)"
echo ""
./scripts/rodar_testes_b1_v2.sh
