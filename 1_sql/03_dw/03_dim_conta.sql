/* =====================================================================
   Script : 03_dw/03_dim_conta.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por conta de faturamento 

   Origem : stg.billing_contas (cliente_id recuperado pelo CNPJ)
   ===================================================================== */
USE NuvemBR;
GO
CREATE TABLE dw.dim_conta (
    conta_sk               INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    conta_id               NVARCHAR(50) NOT NULL UNIQUE,
    cliente_id             NVARCHAR(50) NULL,
    cnpj_raiz              NVARCHAR(50) NULL,
    data_criacao           DATE         NULL
);

SET IDENTITY_INSERT dw.dim_conta ON;
INSERT INTO dw.dim_conta (conta_sk, conta_id) VALUES (-1, 'N/D');
SET IDENTITY_INSERT dw.dim_conta OFF;

INSERT INTO dw.dim_conta (conta_id, cliente_id, cnpj_raiz, data_criacao)
SELECT conta_id, cliente_id, cnpj_raiz, data_criacao
FROM stg.billing_contas
ORDER BY conta_id;
GO
