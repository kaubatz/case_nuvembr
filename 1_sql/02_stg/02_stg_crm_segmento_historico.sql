/* =====================================================================
   Script : 02_stg/02_stg_crm_segmento_historico.sql
   Engine : SQL Server 2019+ | Camada: stg
   Origem : raw.crm_segmento_historico
   
   - Converte valido_de e valido_ate para DATE.
   - valido_ate nulo = cria valido_ate_fim = '9999-12-31'
   - is_vigente = 1 no período atual.
   ===================================================================== */

USE NuvemBR;
GO

CREATE OR ALTER VIEW stg.crm_segmento_historico AS
SELECT
    cliente_id,
    segmento,
    TRY_CAST(valido_de AS DATE) AS valido_de,
    TRY_CAST(NULLIF(valido_ate, '') AS DATE) AS valido_ate,
    COALESCE(TRY_CAST(NULLIF(valido_ate, '') AS DATE),
             CAST('9999-12-31' AS DATE)) AS valido_ate_fim,
    CASE WHEN NULLIF(valido_ate, '') IS NULL THEN 1 ELSE 0 END AS is_vigente
FROM raw.crm_segmento_historico;
GO
