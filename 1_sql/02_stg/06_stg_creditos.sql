/* =====================================================================
   Script : 02_stg/06_stg_creditos.sql
   Engine : SQL Server 2019+ | Camada: stg
   Origem : raw.creditos
   
   - Converte valor para DECIMAL e competencia para DATE
   - Extrai o ticket da descrição dos créditos SLA
   ===================================================================== */

USE NuvemBR;
GO

CREATE OR ALTER VIEW stg.creditos AS
SELECT
    credito_id,
    conta_id,
    competencia,
    TRY_CAST(competencia + '-01' AS DATE) AS competencia_data,
    tipo,
    TRY_CAST(valor AS DECIMAL(14,2)) AS valor,
    descricao,
    CASE WHEN CHARINDEX('TK-', descricao) > 0
         THEN SUBSTRING(descricao, CHARINDEX('TK-', descricao), 8)
    END AS ticket_id
FROM raw.creditos;
GO
