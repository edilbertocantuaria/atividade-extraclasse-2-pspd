# 🚀 GUIA RÁPIDO - Testes B1 Hadoop

## ✅ SOLUÇÃO DEFINITIVA - SEM ERROS DE XML!

### Problema Resolvido:
❌ **Antes:** Script usava `sed` que criava XMLs inválidos  
✅ **Agora:** Usa arquivos XML pré-configurados (sempre válidos)

---

## 🎯 EXECUÇÃO EM 3 PASSOS

### 1️⃣ Verificar Ambiente
```bash
cd ~/pspd/atividade-extraclasse-2-pspd
chmod +x *.sh scripts/*.sh
./verificar_ambiente.sh
```

### 2️⃣ Executar Testes
```bash
./executar_testes_limpo.sh
```

### 3️⃣ Ver Resultados
```bash
cat resultados/B1/resumo_comparativo.txt
```

---

## 📊 O Que os Testes Fazem

| Teste | Configuração | O Que Testa |
|-------|-------------|-------------|
| **Teste 1** | `memory-mb=1024` | Impacto da memória YARN |
| **Teste 2** | `replication=1` | Fator de replicação HDFS |
| **Teste 3** | `blocksize=64MB` | Tamanho do bloco HDFS |
| **Teste 4** | `reduces=4` | Número de reducers MapReduce |

---

## 📁 Resultados Gerados

```
resultados/B1/
├── teste1_memoria/
│   ├── resumo.txt           ← Resumo completo
│   ├── relatorio.txt        ← Métricas detalhadas
│   ├── job_output.txt       ← Output MapReduce
│   └── yarn_logs.txt        ← Logs YARN
├── teste2_replicacao/
├── teste3_blocksize/
├── teste4_reducers/
├── relatorio_consolidado.txt   ← TODOS os testes
└── resumo_comparativo.txt      ← Tabela comparativa
```

---

## 🐛 Solução de Problemas

### Erro: Containers não encontrados
```bash
cd hadoop
docker compose up -d
sleep 15
cd ..
```

### Erro: XMLs inválidos
```bash
./scripts/validar_config_xml.sh
# Se houver erro, o problema está nos arquivos em hadoop/master/, worker1/, worker2/
# Corrija manualmente ou restaure do backup
```

### Erro: Processos presos
```bash
./scripts/limpar_processos.sh
```

### Reset completo
```bash
cd hadoop
docker compose down -v
docker compose up -d
sleep 15
cd ..
./executar_testes_limpo.sh
```

---

## 📚 Documentação Completa

- `SOLUCAO_DEFINITIVA.md` - Explicação técnica da solução
- `COMO_EXECUTAR_TESTES.md` - Guia detalhado
- `CORRECOES_REALIZADAS.md` - Histórico de correções

---

## ✅ Garantias

- ✅ XMLs sempre válidos (pré-configurados)
- ✅ Sem uso de `sed` (sem corrupção)
- ✅ Validação automática antes de executar
- ✅ Pode executar múltiplas vezes sem problemas
- ✅ Relatórios detalhados automáticos

---

**Versão:** 3.0 - Definitiva  
**Status:** ✅ Pronto para produção
