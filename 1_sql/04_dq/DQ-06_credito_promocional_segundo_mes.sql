-- DQ-06 (descartada): promocional no 2º mês do cliente; padrão regular da campanha, não anomalia.
USE NuvemBR;
SELECT CASE WHEN cr.competencia = LEFT(cl.data_inicio, 7) THEN '1º mês' ELSE '2º mês' END AS mes_do_cliente,
       COUNT(*)                                  AS creditos,
       SUM(TRY_CAST(cr.valor AS DECIMAL(14,2)))  AS valor
FROM raw.creditos cr
JOIN raw.billing_contas b ON b.conta_id   = cr.conta_id
JOIN raw.crm_clientes  cl ON cl.cliente_id = b.cliente_id
WHERE cr.tipo = 'PROMOCIONAL'
GROUP BY CASE WHEN cr.competencia = LEFT(cl.data_inicio, 7) THEN '1º mês' ELSE '2º mês' END;

-- Regra dos 2 meses: toda conta com promocional tem exatamente 2 créditos, em meses seguidos.
SELECT COUNT(*) AS contas,
       SUM(CASE WHEN creditos = 2 AND DATEDIFF(MONTH, primeiro_mes, ultimo_mes) = 1 THEN 1 ELSE 0 END) AS contas_2_meses_seguidos
FROM (
    SELECT conta_id,
           COUNT(*)                                     AS creditos,
           MIN(TRY_CAST(competencia + '-01' AS DATE))   AS primeiro_mes,
           MAX(TRY_CAST(competencia + '-01' AS DATE))   AS ultimo_mes
    FROM raw.creditos
    WHERE tipo = 'PROMOCIONAL'
    GROUP BY conta_id
) p;

-- Valor do promocional: faixa fixa por mês (300, 1.500 ou 6.000), limitada ao bruto da fatura.
SELECT CASE WHEN TRY_CAST(c.valor AS DECIMAL(14,2)) IN (300, 1500, 6000) THEN 'faixa fixa'
            WHEN ABS(TRY_CAST(c.valor AS DECIMAL(14,2)) - TRY_CAST(f.valor_bruto AS DECIMAL(14,2))) <= 0.01 THEN 'limitado ao bruto'
            ELSE 'fora da regra' END AS regra,
       COUNT(*) AS creditos
FROM raw.creditos c
JOIN raw.faturas f
  ON f.conta_id = c.conta_id
 AND f.competencia = c.competencia
 AND f.status <> 'CANCELADA'
WHERE c.tipo = 'PROMOCIONAL'
GROUP BY CASE WHEN TRY_CAST(c.valor AS DECIMAL(14,2)) IN (300, 1500, 6000) THEN 'faixa fixa'
              WHEN ABS(TRY_CAST(c.valor AS DECIMAL(14,2)) - TRY_CAST(f.valor_bruto AS DECIMAL(14,2))) <= 0.01 THEN 'limitado ao bruto'
              ELSE 'fora da regra' END;
