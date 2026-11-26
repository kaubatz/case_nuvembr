-- DQ-01: dia de consumo carregado em 2 lotes (linhas duplicadas).
USE NuvemBR;
WITH consumo AS (
    SELECT data,
           conta_id,
           TRY_CAST(quantidade AS DECIMAL(18,4)) * TRY_CAST(preco_unitario AS DECIMAL(12,6)) AS valor,
           ROW_NUMBER() OVER (PARTITION BY data, conta_id, produto, regiao ORDER BY carregado_em DESC) AS rn
    FROM raw.consumo_diario
)
SELECT data, COUNT(*) AS linhas_duplicadas, ROUND(SUM(valor), 2) AS valor_duplicado
FROM consumo
WHERE rn > 1
GROUP BY data;

-- Duplicata só na medição: a fatura de maio bate com o consumo sem a duplicata.
WITH consumo AS (
    SELECT data,
           conta_id,
           TRY_CAST(quantidade AS DECIMAL(18,4)) * TRY_CAST(preco_unitario AS DECIMAL(12,6)) AS valor,
           ROW_NUMBER() OVER (PARTITION BY data, conta_id, produto, regiao ORDER BY carregado_em DESC) AS rn
    FROM raw.consumo_diario
),
por_conta AS (
    SELECT conta_id,
           SUM(valor)                                  AS com_duplicata,
           SUM(CASE WHEN rn = 1 THEN valor ELSE 0 END) AS sem_duplicata
    FROM consumo
    WHERE data LIKE '2026-05%'
      AND conta_id IN (SELECT conta_id FROM consumo WHERE rn > 1)
    GROUP BY conta_id
)
SELECT COUNT(*) AS contas,
       SUM(CASE WHEN ABS(p.sem_duplicata - TRY_CAST(f.valor_bruto AS DECIMAL(14,2))) <= 0.05 THEN 1 ELSE 0 END) AS fatura_bate_sem_duplicata,
       SUM(CASE WHEN ABS(p.com_duplicata - TRY_CAST(f.valor_bruto AS DECIMAL(14,2))) <= 0.05 THEN 1 ELSE 0 END) AS fatura_bate_com_duplicata
FROM por_conta p
JOIN raw.faturas f
  ON f.conta_id = p.conta_id
 AND f.competencia = '2026-05'
 AND f.status <> 'CANCELADA';
