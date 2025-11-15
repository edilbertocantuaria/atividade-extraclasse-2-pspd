# Teste de Concorrência B1 - 2 Jobs Simultâneos

**Data:** 2025-11-14
**Timestamp:** 20251114_160901
**Configuração:** Speculative execution habilitado

## Resultados

### Job 1 (application_1763130949673_0007)
- **Início:** 16:09:03 (1763147348095)
- **Término:** 16:22:36 (1763147856779)
- **Duração:** 508.68s (8min 28s)
- **Status:** SUCCEEDED ✓

### Job 2 (application_1763130949673_0008)
- **Início:** 16:09:05 (1763147353707)
- **Término:** 16:25:44 (1763147944433)
- **Duração:** 590.73s (9min 50s)
- **Status:** SUCCEEDED ✓

## Análise

- **Tempo médio:** 549.71s (~9min 10s)
- **Diferença entre jobs:** 82.04s (13.9%)
- **Comparação com baseline (sem concorrência):** 
  - Baseline: 2735.15s (45min 35s)
  - Com 2 jobs concorrentes: ~549s médio
  - Overhead de concorrência: ~6.4x mais lento que speculative execution isolado (78s)
  
## Conclusões

1. Com recursos limitados (1GB RAM por NodeManager), a execução concorrente aumenta significativamente o tempo individual de cada job
2. Job 2 levou ~14% mais tempo que Job 1 (provavelmente por competição de recursos)
3. Apesar do overhead, ambos os jobs completaram com sucesso, demonstrando que o YARN gerencia a concorrência adequadamente
4. Tempo total wall-clock: ~16.5 minutos (vs. 90+ minutos se executados sequencialmente)
