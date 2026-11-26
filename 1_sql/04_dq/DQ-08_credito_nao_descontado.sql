-- DQ-08: crédito concedido e não descontado na fatura.
USE NuvemBR;
WITH creditos AS (
    SELECT conta_id, competencia, SUM(TRY_CAST(valor AS DECIMAL(14,2))) AS concedido
    FROM raw.creditos
    GROUP BY conta_id, competencia
)
SELECT f.fatura_id, f.conta_id, f.competencia,
       c.concedido,
       TRY_CAST(f.valor_creditos AS DECIMAL(14,2))               AS descontado,
       c.concedido - TRY_CAST(f.valor_creditos AS DECIMAL(14,2)) AS valor_nao_descontado
FROM raw.faturas f
JOIN creditos c ON c.conta_id = f.conta_id AND c.competencia = f.competencia
WHERE f.status <> 'CANCELADA'
  AND ABS(c.concedido - TRY_CAST(f.valor_creditos AS DECIMAL(14,2))) > 0.01;
