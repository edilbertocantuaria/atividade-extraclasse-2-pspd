# 🚀 GUIA DE EXECUÇÃO - TESTES B1

## ⚠️ IMPORTANTE: Problema Resolvido!

**Correção aplicada:** Incompatibilidade de clusterID dos DataNodes  
**Commit:** `b4dd2c0` - fix(hadoop): corrigir incompatibilidade de clusterID dos DataNodes  
**Status:** ✅ Pronto para executar

---

## 📋 Pré-requisitos

Certifique-se de que o repositório está atualizado com os últimos commits:

```bash
git pull
# Deve estar no commit b4dd2c0 ou posterior
```

---

## 🔧 Opção 1: Execução Completa Automática (Recomendado)

```bash
cd ~/pspd/atividade-extraclasse-2-pspd

# Tornar scripts executáveis
chmod +x *.sh scripts/*.sh

# 1. Corrigir ambiente (recrear XMLs, validar, reiniciar cluster)
./corrigir_tudo.sh

# 2. Executar todos os 4 testes B1 (~15-20 minutos)
./executar_testes_limpo.sh
```

---

## 🧪 Opção 2: Teste Rápido de Validação (5 minutos)

Para verificar se o cluster está funcionando corretamente:

```bash
./teste_rapido.sh
```

Este script vai:
1. Reiniciar o cluster
2. Formatar o NameNode
3. **Limpar os DataNodes (correção do clusterID)**
4. Iniciar HDFS/YARN
5. Verificar que 2 DataNodes estão ativos
6. Testar upload de arquivo para HDFS

**Saída esperada:**
```
Live datanodes (2):  ✅
Found 1 items
-rw-r--r--   2 hadoop supergroup ... /user/hadoop/teste/teste.txt
```

---

## 📊 Opção 3: Executar Testes Individuais

```bash
cd ~/pspd/atividade-extraclasse-2-pspd

# Inicializar cluster
./corrigir_tudo.sh

# Executar script de testes (modificar para rodar 1 teste apenas)
# Editar scripts/rodar_testes_b1_v2.sh e comentar os testes que não deseja
./executar_testes_limpo.sh
```

---

## 🔍 Verificando Resultados

### Durante a Execução

Monitore os logs em tempo real:

```bash
# Em outro terminal
docker logs -f hadoop-master
```

### Após a Execução

Os resultados ficam salvos em:

```
resultados/B1/
├── teste1_memoria/
│   ├── relatorio.txt
│   ├── resumo.txt
│   └── output.log
├── teste2_replicacao/
├── teste3_blocksize/
├── teste4_reducers/
├── relatorio_consolidado.txt
└── resumo_comparativo.txt
```

---

## ❌ Troubleshooting

### Problema: "0 datanode(s) running"

**Solução:** A correção do clusterID já está aplicada!

Se ainda ocorrer:
```bash
# Limpar manualmente os DataNodes
./scripts/limpar_datanodes.sh

# Reiniciar HDFS
docker exec -u hadoop hadoop-master bash -c "stop-dfs.sh && start-dfs.sh"

# Aguardar 15 segundos
sleep 15

# Verificar
docker exec hadoop-master jps
# Deve mostrar: NameNode, DataNode, SecondaryNameNode
```

### Problema: "Unable to kill PID"

**Causa:** Processos Java não param gracefully  
**Solução:** Já está tratado automaticamente com `pkill -9 java`

```bash
# Forçar limpeza manual se necessário
./scripts/limpar_processos.sh
```

### Problema: "XML parsing error"

**Solução:** Recrear todos os XMLs:

```bash
./scripts/recriar_xmls.sh
./scripts/validar_config_xml.sh
```

---

## 📈 Testes Executados

| Teste | Configuração | Parâmetro |
|-------|-------------|-----------|
| **Teste 1** | Memória YARN | 1024MB |
| **Teste 2** | Replicação HDFS | fator=1 |
| **Teste 3** | Block Size HDFS | 64MB |
| **Teste 4** | Número de Reducers | 4 reducers |

---

## ✅ Checklist de Execução

- [ ] Repositório atualizado (git pull)
- [ ] Scripts com permissão de execução (chmod +x)
- [ ] Docker rodando
- [ ] `./corrigir_tudo.sh` executado com sucesso
- [ ] `./teste_rapido.sh` mostra 2 DataNodes ativos
- [ ] `./executar_testes_limpo.sh` finalizado
- [ ] Resultados em `resultados/B1/`

---

## 📚 Documentação Adicional

- **CORRECAO_CLUSTERID.md** - Detalhes técnicos da correção
- **SOLUCAO_DEFINITIVA.md** - Arquitetura do sistema de testes
- **COMO_EXECUTAR_TESTES.md** - Guia completo original
- **CORRECOES_REALIZADAS.md** - Histórico de todas as correções

---

**Última atualização:** 10/11/2025  
**Versão:** 2.0 - Com correção de clusterID  
**Status:** ✅ Funcionando
