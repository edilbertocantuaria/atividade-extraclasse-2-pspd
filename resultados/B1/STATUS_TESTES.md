# Status dos Testes B1 - Hadoop MapReduce

**Última Atualização:** 2025-11-14 16:30

## Testes Completos ✅

### 1. Teste 0: Baseline (sem otimizações)
- **Status:** Concluído ✓
- **Duração:** 2735.15s (45min 35s)
- **Throughput:** 0.03 MB/s
- **Application ID:** application_1763130949673_0005

### 2. Teste 5: Speculative Execution
- **Status:** Concluído ✓
- **Duração:** 78.63s (1min 18s)
- **Throughput:** 1.27 MB/s
- **Melhoria:** 97.1% mais rápido que baseline
- **Application ID:** application_1763130949673_0006

### 3. Teste de Concorrência (2 Jobs Simultâneos)
- **Status:** Concluído ✓
- **Data:** 2025-11-14 16:09-16:26
- **Resultados:**
  - Job 1: 508.68s (8min 28s) - application_1763130949673_0007
  - Job 2: 590.73s (9min 50s) - application_1763130949673_0008
  - Tempo médio: 549.71s
  - Overhead vs. speculative isolado: 6.4x
- **Diretório:** `resultados/B1/teste_concorrencia/run_20251114_160901/`

## Testes em Andamento 🔄

### 4. Teste de Tolerância a Falhas
- **Status:** EM EXECUÇÃO (iniciado 16:29)
- **Cenários planejados:**
  1. Baseline (sem falhas)
  2. 1 worker down durante execução
  3. 2 workers down durante execução
  4. Scale up (recuperação de worker)
- **Estimativa:** 1-2 horas
- **Diretório:** `resultados/B1/teste_tolerancia_falhas/run_20251114_162939/`

## Configurações Testadas

| Config | Teste | Status |
|--------|-------|--------|
| **Memória** | Redução 1536→512MB | ✅ Crítico para funcionamento |
| **Replicação** | HDFS replication=3 | ⏳ Planejado |
| **Block Size** | 128MB padrão | ⏳ Planejado |
| **Reducers** | 4 reducers | ✅ Aplicado em todos |
| **Speculative** | Habilitado | ✅ 97.1% melhoria |

## Métricas Consolidadas

| Teste | Duração | Throughput | Maps | Reduces | Status |
|-------|---------|------------|------|---------|--------|
| Baseline | 2735s | 0.03 MB/s | 10 | 5 (2 killed) | ✅ |
| Speculative | 79s | 1.27 MB/s | 10 | 7 (3 killed) | ✅ |
| Concurrent J1 | 509s | 0.20 MB/s | 10 | ? | ✅ |
| Concurrent J2 | 591s | 0.17 MB/s | 10 | ? | ✅ |

## Próximos Passos

1. ⏳ Aguardar conclusão do teste de tolerância a falhas (~1-2h)
2. 📊 Consolidar todos os resultados no RELATORIO_COMPARATIVO_B1.md
3. 📝 Atualizar RESUMO_FINAL_B1.md com tabelas e gráficos
4. 🔄 Commitar resultados finais
