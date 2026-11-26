/* =====================================================================
   Script : 02_stg/03_stg_billing_contas.sql
   Engine : SQL Server 2019+ | Camada: stg
   Origem : raw.billing_contas (+ raw.crm_clientes como tabela de consulta)

   - O cliente é recuperado pelo CNPJ na crm_clientes
   - Remove pontos do cnpj_raiz 
   - Converte data_criacao para DATE.
   ===================================================================== */

USE NuvemBR;
GO

CREATE OR ALTER VIEW stg.billing_contas AS
SELECT
    b.conta_id,
    COALESCE(NULLIF(b.cliente_id, ''), c.cliente_id) AS cliente_id,
    REPLACE(b.cnpj_raiz, '.', '') AS cnpj_raiz,
    TRY_CAST(b.data_criacao AS DATE) AS data_criacao
FROM raw.billing_contas b
LEFT JOIN raw.crm_clientes c
       ON  c.cnpj_raiz = REPLACE(b.cnpj_raiz, '.', '')
       AND NULLIF(b.cliente_id, '') IS NULL;   
GO
