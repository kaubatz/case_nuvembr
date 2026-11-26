/* =====================================================================
   Script : 03_dw/05_fato_consumo_diario.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por DIA x CONTA x PRODUTO x REGIÃO (sem lote)
   Origem : stg.consumo_diario (já sem lote duplicado e com TB -> GB)

   Medidas: quantidade (unidade-base), receita_medida (quantidade x preço).

   cliente_sk: pk do cliente vigente NA DATA do consumo
   Uso: conciliação medido x faturado e consumo por produto/região.
            A receita "oficial" vem da fato_fatura
   ===================================================================== */
USE NuvemBR;
GO

--drop table if exists dw.fato_consumo_diario 
--go

CREATE TABLE dw.fato_consumo_diario (
    data_key                 INT           NOT NULL REFERENCES dw.dim_data (data_key),
    conta_sk                 INT           NOT NULL REFERENCES dw.dim_conta (conta_sk),
    cliente_sk               INT           NOT NULL REFERENCES dw.dim_cliente (cliente_sk),
    produto_sk               INT           NOT NULL REFERENCES dw.dim_produto (produto_sk),
    regiao                   NVARCHAR(100) NOT NULL,
    quantidade               DECIMAL(18,4) NOT NULL,
    receita_medida           DECIMAL(19,6) NOT NULL,
    flag_unidade_convertida  BIT           NOT NULL,
    lote_id                  NVARCHAR(50)  NULL,
    CONSTRAINT pk_fato_consumo PRIMARY KEY (data_key, conta_sk, produto_sk, regiao)
);

INSERT INTO dw.fato_consumo_diario
SELECT YEAR(s.data) * 10000 + MONTH(s.data) * 100 + DAY(s.data)  AS data_key,
       COALESCE(dc.conta_sk, -1) AS conta_sk,
       COALESCE(cli.cliente_sk, -1) AS cliente_sk,
       COALESCE(dp.produto_sk, -1) AS produto_sk,
       s.regiao,
       s.quantidade,
       s.receita,
       s.flag_unidade_convertida,
       s.lote_id
FROM stg.consumo_diario s
LEFT JOIN dw.dim_conta   dc ON dc.conta_id = s.conta_id
LEFT JOIN dw.dim_produto dp ON dp.produto  = s.produto

OUTER APPLY (SELECT TOP 1 c.cliente_sk
             FROM dw.dim_cliente c
             WHERE c.cliente_id = dc.cliente_id
               AND s.data BETWEEN c.valido_de AND c.valido_ate
             ORDER BY c.valido_de DESC) cli;
GO
