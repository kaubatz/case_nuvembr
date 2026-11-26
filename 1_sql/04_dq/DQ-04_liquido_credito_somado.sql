-- DQ-04: faturas com o crédito somado ao bruto em vez de subtraído (líquido inflado).
USE NuvemBR;
SELECT competencia, status,
       COUNT(*) AS faturas,
       SUM(TRY_CAST(valor_liquido AS DECIMAL(14,2))
         - (TRY_CAST(valor_bruto AS DECIMAL(14,2)) - TRY_CAST(valor_creditos AS DECIMAL(14,2)))) AS valor_a_mais
FROM raw.faturas
WHERE ABS(TRY_CAST(valor_bruto AS DECIMAL(14,2)) - TRY_CAST(valor_creditos AS DECIMAL(14,2))
        - TRY_CAST(valor_liquido AS DECIMAL(14,2))) > 0.01
GROUP BY competencia, status;
