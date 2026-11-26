/* =====================================================================
   Script : 02_stg/05_stg_faturas.sql
   Engine : SQL Server 2019+ | Camada: stg
   Origem : raw.faturas

   - Recalcula valor_liquido = valor_bruto − valor_creditos para todas, guarda o líquido original 
   e marca flag_liquido_recalculado = 1 onde havia diferença.
   - faturas canceladas marcadas com is_valida = 0
   - is_reemissao = 1 na fatura que substitui uma cancelada
   - competencia_data gerada pela competencia
   ===================================================================== */

USE NuvemBR;
GO

CREATE OR ALTER VIEW stg.faturas AS
WITH tipado AS (
    SELECT
        fatura_id,
        conta_id,
        competencia,
        TRY_CAST(competencia + '-01' AS DATE)          AS competencia_data,
        TRY_CAST(valor_bruto    AS DECIMAL(14,2))      AS valor_bruto,
        TRY_CAST(valor_creditos AS DECIMAL(14,2))      AS valor_creditos,
        TRY_CAST(valor_liquido  AS DECIMAL(14,2))      AS valor_liquido_original,
        status,
        TRY_CAST(data_emissao AS DATE)                 AS data_emissao,
        NULLIF(fatura_substituta_id, '')               AS fatura_substituta_id
    FROM raw.faturas
)
SELECT
    t.fatura_id,
    t.conta_id,
    t.competencia,
    t.competencia_data,
    t.valor_bruto,
    t.valor_creditos,
    t.valor_bruto - t.valor_creditos AS valor_liquido, 
    t.valor_liquido_original,
    CASE WHEN ABS(t.valor_liquido_original - (t.valor_bruto - t.valor_creditos)) > 0.01
         THEN 1 ELSE 0 END AS flag_liquido_recalculado,
    t.status,
    CASE WHEN t.status = 'CANCELADA' THEN 0 ELSE 1 END AS is_valida,
    t.data_emissao,
    t.fatura_substituta_id,
    CASE WHEN EXISTS (SELECT 1 FROM raw.faturas s
                      WHERE s.fatura_substituta_id = t.fatura_id)
         THEN 1 ELSE 0 END AS is_reemissao
FROM tipado t;
GO
