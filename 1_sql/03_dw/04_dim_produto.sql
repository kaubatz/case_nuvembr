/* =====================================================================
   Script : 03_dw/04_dim_produto.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por produto
   Origem : stg.consumo_diario (unidade TB convertida para GB na stg)

   categoria: criada pela descricao dos produtos "computação, armazenamento, banco de dados e Kubernetes"
   ===================================================================== */
USE NuvemBR;
GO

-- drop table if exists dw.dim_produto
-- go

CREATE TABLE dw.dim_produto (
    produto_sk      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    produto         NVARCHAR(100) NOT NULL UNIQUE,
    categoria       NVARCHAR(50)  NOT NULL,
    unidade_base    NVARCHAR(50)  NULL,
    preco_unitario  DECIMAL(12,6) NULL
);

SET IDENTITY_INSERT dw.dim_produto ON;
INSERT INTO dw.dim_produto (produto_sk, produto, categoria) VALUES (-1, 'N/D', 'Não identificado');
SET IDENTITY_INSERT dw.dim_produto OFF;

INSERT INTO dw.dim_produto (produto, categoria, unidade_base, preco_unitario)
SELECT produto,
       CASE produto
            WHEN 'VM_COMPUTE'     THEN 'Computação'
            WHEN 'KUBERNETES'     THEN 'Kubernetes'
            WHEN 'BLOCK_STORAGE'  THEN 'Armazenamento'
            WHEN 'OBJECT_STORAGE' THEN 'Armazenamento'
            WHEN 'DATABASE'       THEN 'Banco de dados'
            WHEN 'EGRESS'         THEN 'Rede'
            ELSE 'Outros' END,
       unidade, preco_unitario
FROM stg.consumo_diario
GROUP BY produto,unidade, preco_unitario
GO
