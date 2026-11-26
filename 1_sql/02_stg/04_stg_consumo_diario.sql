/* =====================================================================
   Script : 02_stg/04_stg_consumo_diario.sql
   Engine : SQL Server 2019+ | Camada: stg
   Origem : raw.consumo_diario
   
   - 1 linha por dia x conta x produto x região (sem lote)
   - o dia 14/05/2026 foi carregado em 2 lotes - mantive só o lote de carregado_em mais recente 
   - OBJECT_STORAGE vem em TB-dia a partir de jul/2026 com preço por GB-dia. Converti para GB-dia (quantidade x 1024).    
   - Converte tipos e calcula receita = quantidade (unidade-base) x preço.
   ===================================================================== */

USE NuvemBR;
GO

CREATE OR ALTER VIEW stg.consumo_diario AS

WITH tipado AS (
    SELECT TRY_CAST(data AS DATE) AS data,
        conta_id,
        produto,
        regiao,
        TRY_CAST(quantidade AS DECIMAL(18,4)) AS quantidade_original,
        unidade AS unidade_original,
        TRY_CAST(preco_unitario AS DECIMAL(12,6)) AS preco_unitario,
        lote_id,
        TRY_CAST(carregado_em AS DATETIME2(0)) AS carregado_em,
        ROW_NUMBER() OVER ( PARTITION BY data, conta_id, produto, regiao ORDER BY TRY_CAST(carregado_em AS DATETIME2(0)) DESC) AS rn_lote
    FROM raw.consumo_diario
),
convertido AS (
    SELECT
        data, conta_id, produto, regiao,
        quantidade_original, unidade_original,
        CASE WHEN unidade_original = 'TB-dia'
             THEN quantidade_original * 1024
             ELSE quantidade_original END AS quantidade,
        CASE WHEN unidade_original = 'TB-dia'
             THEN 'GB-dia'
             ELSE unidade_original END AS unidade,
        CASE WHEN unidade_original = 'TB-dia'
             THEN 1 ELSE 0 END AS flag_unidade_convertida,
        preco_unitario, lote_id, carregado_em
    FROM tipado
    WHERE rn_lote = 1   
)
SELECT
    data,
    conta_id,
    produto,
    regiao,
    quantidade,
    unidade,
    preco_unitario,
    quantidade * preco_unitario  AS receita,
    quantidade_original,
    unidade_original,
    flag_unidade_convertida,
    lote_id,
    carregado_em
FROM convertido;
GO
