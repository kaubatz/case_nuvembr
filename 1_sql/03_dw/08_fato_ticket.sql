/* =====================================================================
   Script : 03_dw/08_fato_ticket.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por CHAMADO
   Origem : stg.tickets (fuso corrigido)

   Medida : horas_resolucao
   
   Marcações:
   - flag_ticket_antes_da_conta: aberto (horário de Brasília) antes da criação da conta. 
   - tem_credito_sla: o chamado é citado por algum crédito tipo SLA
   ===================================================================== */
USE NuvemBR;
GO

--drop table if exists dw.fato_ticket
--go

CREATE TABLE dw.fato_ticket (
    ticket_id                   NVARCHAR(50)  NOT NULL PRIMARY KEY,
    abertura_key                INT           NOT NULL REFERENCES dw.dim_data (data_key),
    conta_sk                    INT           NOT NULL REFERENCES dw.dim_conta (conta_sk),
    cliente_sk                  INT           NOT NULL REFERENCES dw.dim_cliente (cliente_sk),
    aberto_em                   DATETIME2(0)  NOT NULL,
    resolvido_em                DATETIME2(0)  NULL,
    horas_resolucao             DECIMAL(10,2) NULL,
    severidade                  NVARCHAR(20)  NOT NULL,
    severidade_nivel            TINYINT       NOT NULL,
    categoria                   NVARCHAR(100) NOT NULL,
    flag_ticket_antes_da_conta  BIT           NOT NULL,
    tem_credito_sla             BIT           NOT NULL
);

INSERT INTO dw.fato_ticket
SELECT s.ticket_id,
       YEAR(s.aberto_em) * 10000 + MONTH(s.aberto_em) * 100 + DAY(s.aberto_em),
       COALESCE(dc.conta_sk, -1),
       COALESCE(cli.cliente_sk, -1),
       s.aberto_em,
       s.resolvido_em,
       s.horas_resolucao,
       s.severidade,
       s.severidade_nivel,
       s.categoria,
       CASE WHEN CAST(s.aberto_em AS DATE) < dc.data_criacao THEN 1 ELSE 0 END,
       CASE WHEN EXISTS (SELECT 1 FROM stg.creditos cr
                         WHERE cr.tipo = 'SLA' AND cr.ticket_id = s.ticket_id)
            THEN 1 ELSE 0 END
FROM stg.tickets s
LEFT JOIN dw.dim_conta dc ON dc.conta_id = s.conta_id
OUTER APPLY (SELECT TOP 1 c.cliente_sk
             FROM dw.dim_cliente c
             WHERE c.cliente_id = dc.cliente_id
             ORDER BY CASE WHEN CAST(s.aberto_em AS DATE) BETWEEN c.valido_de AND c.valido_ate
                           THEN 0 ELSE 1 END,
                      c.valido_de) cli;
GO
