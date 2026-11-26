-- DQ-02: OBJECT_STORAGE medido em TB-dia com preço por GB-dia (valor 1024x menor).
USE NuvemBR;
SELECT COUNT(*) AS linhas,
       ROUND(SUM(TRY_CAST(quantidade AS DECIMAL(18,4)) * TRY_CAST(preco_unitario AS DECIMAL(12,6))), 2)        AS valor_como_veio,
       ROUND(SUM(TRY_CAST(quantidade AS DECIMAL(18,4)) * 1024 * TRY_CAST(preco_unitario AS DECIMAL(12,6))), 2) AS valor_corrigido
FROM raw.consumo_diario
WHERE produto = 'OBJECT_STORAGE' AND unidade = 'TB-dia';

-- Erro só na medição: a fatura bate com o consumo x1024 (as 4 linhas que não batem são da B-00059, Kubernetes da DQ-03).
WITH consumo AS (
    SELECT conta_id,
           LEFT(data, 7) AS competencia,
           SUM(TRY_CAST(quantidade AS DECIMAL(18,4)) * TRY_CAST(preco_unitario AS DECIMAL(12,6))) AS sem_conversao,
           SUM(TRY_CAST(quantidade AS DECIMAL(18,4)) * CASE WHEN unidade = 'TB-dia' THEN 1000 ELSE 1 END * TRY_CAST(preco_unitario AS DECIMAL(12,6))) AS x1000,
           SUM(TRY_CAST(quantidade AS DECIMAL(18,4)) * CASE WHEN unidade = 'TB-dia' THEN 1024 ELSE 1 END * TRY_CAST(preco_unitario AS DECIMAL(12,6))) AS x1024
    FROM raw.consumo_diario
    WHERE data >= '2026-07-01'
    GROUP BY conta_id, LEFT(data, 7)
    HAVING SUM(CASE WHEN unidade = 'TB-dia' THEN 1 ELSE 0 END) > 0
)
SELECT COUNT(*) AS contas_mes,
       SUM(CASE WHEN ABS(c.sem_conversao - TRY_CAST(f.valor_bruto AS DECIMAL(14,2))) <= 0.05 THEN 1 ELSE 0 END) AS fatura_bate_sem_conversao,
       SUM(CASE WHEN ABS(c.x1000         - TRY_CAST(f.valor_bruto AS DECIMAL(14,2))) <= 0.05 THEN 1 ELSE 0 END) AS fatura_bate_x1000,
       SUM(CASE WHEN ABS(c.x1024         - TRY_CAST(f.valor_bruto AS DECIMAL(14,2))) <= 0.05 THEN 1 ELSE 0 END) AS fatura_bate_x1024
FROM consumo c
JOIN raw.faturas f
  ON f.conta_id = c.conta_id
 AND f.competencia = c.competencia
 AND f.status <> 'CANCELADA';
