/* =====================================================================
   Script : 03_dw/02_dim_cliente.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por cliente x período do segmento 
   Origem : stg.crm_segmento_historico e stg.crm_clientes 

   guarda o historico de segmento do cliente

   - cliente_sk: chave primaria
   - cliente_id: chave unica da tabela origem
   - valido_ate = 31/12/9999 na versão vigente
   ===================================================================== */
USE NuvemBR;
GO

-- drop table if exists dw.dim_cliente
-- go

CREATE TABLE dw.dim_cliente (
    cliente_sk     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    cliente_id     NVARCHAR(50)  NOT NULL,
    razao_social   NVARCHAR(300) NOT NULL,
    cnpj_raiz      NVARCHAR(50)  NULL,
    canal          NVARCHAR(100) NULL,
    uf             NVARCHAR(10)  NULL,
    data_inicio    DATE          NULL,
    segmento       NVARCHAR(100) NOT NULL,
    valido_de      DATE          NOT NULL,
    valido_ate     DATE          NOT NULL,
    is_vigente     BIT           NOT NULL
);

SET IDENTITY_INSERT dw.dim_cliente ON;
INSERT INTO dw.dim_cliente (cliente_sk, cliente_id, razao_social, segmento, valido_de, valido_ate, is_vigente)
VALUES (-1, 'N/D', 'Não identificado', 'Não identificado', '1900-01-01', '9999-12-31', 1);
SET IDENTITY_INSERT dw.dim_cliente OFF;

INSERT INTO dw.dim_cliente
       (cliente_id, razao_social, cnpj_raiz, canal, uf, data_inicio,
        segmento, valido_de, valido_ate, is_vigente)
SELECT h.cliente_id, c.razao_social, c.cnpj_raiz, c.canal, c.uf, c.data_inicio,
       h.segmento, h.valido_de, h.valido_ate_fim, h.is_vigente
FROM stg.crm_segmento_historico h
JOIN stg.crm_clientes c ON c.cliente_id = h.cliente_id
ORDER BY h.cliente_id, h.valido_de;

CREATE INDEX ix_dim_cliente_vigencia ON dw.dim_cliente (cliente_id, valido_de, valido_ate);
GO
