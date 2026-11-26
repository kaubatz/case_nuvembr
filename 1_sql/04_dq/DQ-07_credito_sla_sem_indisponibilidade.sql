-- DQ-07: créditos SLA concedidos para tickets que não são de indisponibilidade.
USE NuvemBR;
SELECT t.categoria,
       COUNT(*)                                 AS creditos,
       SUM(TRY_CAST(cr.valor AS DECIMAL(14,2))) AS valor
FROM raw.creditos cr
JOIN raw.tickets t ON t.ticket_id = RIGHT(cr.descricao, 8)
WHERE cr.tipo = 'SLA'
GROUP BY t.categoria;
