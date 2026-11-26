-- DQ-05: contas sem cliente_id no billing (receita fica sem segmento).
USE NuvemBR;
SELECT COUNT(DISTINCT b.conta_id)                    AS contas,
       COUNT(*)                                      AS faturas,
       SUM(TRY_CAST(f.valor_bruto AS DECIMAL(14,2))) AS valor_bruto
FROM raw.billing_contas b
JOIN raw.faturas f ON f.conta_id = b.conta_id 
AND f.status <> 'CANCELADA'
WHERE NULLIF(b.cliente_id, '') IS NULL;
