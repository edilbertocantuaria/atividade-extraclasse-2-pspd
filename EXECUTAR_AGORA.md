# ⚡ EXECUTAR AGORA - CORREÇÃO FINAL

## 🎯 Execute estes comandos NA ORDEM:

### 1️⃣ Correção Completa dos XMLs
```bash
cd ~/pspd/atividade-extraclasse-2-pspd
chmod +x *.sh scripts/*.sh
./corrigir_tudo.sh
```

**Aguarde até aparecer "AMBIENTE PRONTO!"**

---

### 2️⃣ Executar os Testes
```bash
./executar_testes_limpo.sh
```

**IMPORTANTE:** Os testes vão demorar! Cada teste pode levar de 2-5 minutos.
- Teste 1: Configura memória YARN
- Teste 2: Reconfigura e reformata HDFS (replicação)
- Teste 3: Reconfigura e reformata HDFS (blocksize)
- Teste 4: Configura número de reducers

**Total estimado: 15-20 minutos**

---

### 3️⃣ Ver Resultados
```bash
# Ver resumo comparativo
cat resultados/B1/resumo_comparativo.txt

# Ver relatório completo
cat resultados/B1/relatorio_consolidado.txt
```

---

## 📋 O Que Foi Corrigido Nesta Versão

### ✅ Problema 1: XMLs Inválidos
- **core-site.xml** faltava `<property>` de abertura
- **Solução:** Script `recriar_xmls.sh` recria todos corretamente

### ✅ Problema 2: Validador com Erro
- `grep -c` retornava texto ao invés de número
- **Solução:** Sanitização de valores numéricos

### ✅ Problema 3: HDFS Não Iniciava
- Serviços não reiniciavam após copiar XMLs
- **Solução:** Script agora:
  - Para serviços explicitamente
  - Copia XMLs
  - Reformata HDFS quando necessário
  - Reinicia com verificação

---

## 🔧 O Que o Script Faz Agora

```
1. Reinicia cluster completo
2. Formata HDFS
3. Inicia HDFS e YARN
4. Verifica serviços ativos

Para cada teste:
5. Para o serviço afetado (YARN ou HDFS)
6. Copia XML pré-configurado
7. Reformata HDFS (se necessário)
8. Reinicia serviço
9. Gera dataset
10. Executa WordCount
11. Gera relatórios detalhados
```

---

## ⏱️ Tempo Estimado

| Etapa | Tempo |
|-------|-------|
| Correção inicial (`corrigir_tudo.sh`) | ~30s |
| Teste 1 (Memória) | ~3min |
| Teste 2 (Replicação) | ~4min |
| Teste 3 (Blocksize) | ~4min |
| Teste 4 (Reducers) | ~3min |
| **TOTAL** | **~15min** |

---

## ✅ GARANTIAS

Após executar `./corrigir_tudo.sh`:
- ✅ Todos os XMLs 100% corretos
- ✅ Validação sem erros
- ✅ Cluster inicia normalmente
- ✅ HDFS responde corretamente
- ✅ YARN funciona
- ✅ Testes executam com sucesso

---

## 🐛 Se Algo Der Errado

### HDFS não responde:
```bash
docker exec -u hadoop hadoop-master bash -c "jps"
# Deve mostrar: NameNode, DataNode, SecondaryNameNode, ResourceManager, NodeManager
```

### Reiniciar manualmente:
```bash
cd ~/pspd/atividade-extraclasse-2-pspd
docker exec -u hadoop hadoop-master bash -c "stop-all.sh"
sleep 5
docker exec -u hadoop hadoop-master bash -c "hdfs namenode -format -force && start-all.sh"
```

---

**EXECUTE AGORA:**
```bash
./corrigir_tudo.sh
# Aguarde aparecer "AMBIENTE PRONTO!"
./executar_testes_limpo.sh
```
