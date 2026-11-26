/* =====================================================================
   Script : 02_stg/01_stg_crm_clientes.sql
   Engine : SQL Server 2019+ | Camada: stg
   Origem : raw.crm_clientes

   - Converte data_inicio para DATE 
   - Remove pontos do cnpj_raiz
   ===================================================================== */

USE NuvemBR;
GO

CREATE OR ALTER VIEW stg.crm_clientes AS
SELECT
    cliente_id,
    razao_social,
    REPLACE(cnpj_raiz, '.', '') AS cnpj_raiz,
    segmento AS segmento_atual,
    canal,
    uf,
    TRY_CAST(data_inicio AS DATE) AS data_inicio
FROM raw.crm_clientes;
GO
