/* =====================================================================
   Script : 04_dq/00_perfil_raw.sql
   Engine : SQL Server 2019+
   Objetivo: PERFILAR a camada raw antes de escrever a stg.
             Responde: em que formato os dados realmente chegaram?
             Onde estão os primeiros sinais de anomalia?

   Como usar: rode BLOCO A BLOCO (selecione e F5) e anote os achados.
   Cada achado confirmado vira uma regra na stg e uma linha no relatório
   de anomalias (DQ-xx).

   Truque usado: TRANSLATE troca todo dígito por '9' e toda letra
   comum por 'A'. Assim '2026-03-15' vira '9999-99-99' e '15/03/2026'
   vira '99/99/9999': dá para contar quantos FORMATOS diferentes existem
   numa coluna de data sem olhar linha a linha.
   ===================================================================== */

USE NuvemBR;
GO

/* ---------------------------------------------------------------------
   BLOCO 0 – Fim de linha: os campos da última coluna vêm com CHAR(13)?
   Se sim, a stg precisa de REPLACE(col, CHAR(13), '').
   --------------------------------------------------------------------- */
SELECT 'consumo_diario.carregado_em' AS coluna,
       SUM(CASE WHEN carregado_em LIKE '%' + CHAR(13) THEN 1 ELSE 0 END) AS com_cr
FROM raw.consumo_diario
UNION ALL
SELECT 'faturas.fatura_substituta_id',
       SUM(CASE WHEN fatura_substituta_id LIKE '%' + CHAR(13) THEN 1 ELSE 0 END)
FROM raw.faturas
UNION ALL
SELECT 'tickets.categoria',
       SUM(CASE WHEN categoria LIKE '%' + CHAR(13) THEN 1 ELSE 0 END)
FROM raw.tickets;
GO

/* ---------------------------------------------------------------------
   BLOCO 1 – Formatos de DATA por coluna.
   Mais de um padrão por coluna = formatos misturados (anomalia).
   --------------------------------------------------------------------- */
WITH datas AS (
    SELECT 'consumo.data'  AS coluna, 
	data          AS valor FROM raw.consumo_diario
    UNION ALL SELECT 'consumo.carregado_em', carregado_em FROM raw.consumo_diario
    UNION ALL SELECT 'faturas.data_emissao', data_emissao FROM raw.faturas
    UNION ALL SELECT 'faturas.competencia',  competencia  FROM raw.faturas
    UNION ALL SELECT 'creditos.competencia', competencia  FROM raw.creditos
    UNION ALL SELECT 'tickets.aberto_em',    aberto_em    FROM raw.tickets
    UNION ALL SELECT 'tickets.resolvido_em', resolvido_em FROM raw.tickets
    UNION ALL SELECT 'clientes.data_inicio', data_inicio  FROM raw.crm_clientes
    UNION ALL SELECT 'contas.data_criacao',  data_criacao FROM raw.billing_contas
    UNION ALL SELECT 'seg_hist.valido_de',   valido_de    FROM raw.crm_segmento_historico
    UNION ALL SELECT 'seg_hist.valido_ate',  valido_ate   FROM raw.crm_segmento_historico
)
SELECT coluna,
       COALESCE(TRANSLATE(REPLACE(valor, CHAR(13), ''),
                          '0123456789', '9999999999'), '<NULL>') AS padrao,
       COUNT(*)   AS linhas,
       MAX(valor) AS exemplo
FROM datas
GROUP BY coluna,
         COALESCE(TRANSLATE(REPLACE(valor, CHAR(13), ''), '0123456789', '9999999999'), '<NULL>')
ORDER BY coluna, linhas DESC;
GO

/* ---------------------------------------------------------------------
   BLOCO 2 – NÚMEROS: quantos valores NÃO convertem para decimal?
   Causa comum: vírgula decimal ('12,50'), espaço, texto.
   --------------------------------------------------------------------- */
WITH nums AS (
    SELECT 'consumo.quantidade'     AS coluna, quantidade     AS valor FROM raw.consumo_diario
    UNION ALL SELECT 'consumo.preco_unitario', preco_unitario FROM raw.consumo_diario
    UNION ALL SELECT 'faturas.valor_bruto',    valor_bruto    FROM raw.faturas
    UNION ALL SELECT 'faturas.valor_creditos', valor_creditos FROM raw.faturas
    UNION ALL SELECT 'faturas.valor_liquido',  valor_liquido  FROM raw.faturas
    UNION ALL SELECT 'creditos.valor',         valor          FROM raw.creditos
)
SELECT coluna,
       COUNT(*) AS linhas,
       SUM(CASE WHEN valor IS NULL OR valor = '' THEN 1 ELSE 0 END) AS nulos_ou_vazios,
       SUM(CASE WHEN valor <> '' AND TRY_CAST(valor AS DECIMAL(18,6)) IS NULL
                THEN 1 ELSE 0 END)                                  AS nao_convertem,
       SUM(CASE WHEN TRY_CAST(valor AS DECIMAL(18,6)) < 0 THEN 1 ELSE 0 END) AS negativos,
       MIN(TRY_CAST(valor AS DECIMAL(18,6))) AS minimo,
       MAX(TRY_CAST(valor AS DECIMAL(18,6))) AS maximo
FROM nums
GROUP BY coluna;
GO

/* ---------------------------------------------------------------------
   BLOCO 3 – DOMÍNIOS: valores distintos das colunas categóricas.
   Procure variações de grafia ('SMB', 'smb', 'Smb ', 'PME').
   --------------------------------------------------------------------- */
SELECT 'clientes.segmento' AS coluna, segmento AS valor, COUNT(*) AS linhas FROM raw.crm_clientes GROUP BY segmento
UNION ALL SELECT 'seg_hist.segmento', segmento, COUNT(*) FROM raw.crm_segmento_historico GROUP BY segmento
UNION ALL SELECT 'clientes.canal',    canal,    COUNT(*) FROM raw.crm_clientes GROUP BY canal
UNION ALL SELECT 'clientes.uf',       uf,       COUNT(*) FROM raw.crm_clientes GROUP BY uf
UNION ALL SELECT 'consumo.regiao',    regiao,   COUNT(*) FROM raw.consumo_diario GROUP BY regiao
UNION ALL SELECT 'faturas.status',    status,   COUNT(*) FROM raw.faturas GROUP BY status
UNION ALL SELECT 'creditos.tipo',     tipo,     COUNT(*) FROM raw.creditos GROUP BY tipo
UNION ALL SELECT 'tickets.severidade',severidade, COUNT(*) FROM raw.tickets GROUP BY severidade
UNION ALL SELECT 'tickets.categoria', categoria,  COUNT(*) FROM raw.tickets GROUP BY categoria
ORDER BY coluna, linhas DESC;
GO

/* ---------------------------------------------------------------------
   BLOCO 4 – PRODUTO x UNIDADE x PREÇO.
   O preço é sempre por unidade-base. Um produto com 2 unidades
   (ex.: GB e MB) ou com preço muito fora da mediana indica erro de escala.
   --------------------------------------------------------------------- */
SELECT produto,
       unidade,
       COUNT(*)                                          AS linhas,
       COUNT(DISTINCT preco_unitario)                    AS precos_distintos,
       MIN(TRY_CAST(preco_unitario AS DECIMAL(18,6)))    AS preco_min,
       MAX(TRY_CAST(preco_unitario AS DECIMAL(18,6)))    AS preco_max,
       MIN(TRY_CAST(quantidade AS DECIMAL(18,4)))        AS qtd_min,
       MAX(TRY_CAST(quantidade AS DECIMAL(18,4)))        AS qtd_max
FROM raw.consumo_diario
GROUP BY produto, unidade
ORDER BY produto, unidade;
GO

/* ---------------------------------------------------------------------
   BLOCO 5 – CHAVES PRIMÁRIAS DO DDL: existem duplicatas?
   --------------------------------------------------------------------- */
SELECT 'crm_clientes.cliente_id' AS chave, COUNT(*) - COUNT(DISTINCT cliente_id) AS duplicadas FROM raw.crm_clientes
UNION ALL SELECT 'billing_contas.conta_id', COUNT(*) - COUNT(DISTINCT conta_id)   FROM raw.billing_contas
UNION ALL SELECT 'faturas.fatura_id',       COUNT(*) - COUNT(DISTINCT fatura_id)  FROM raw.faturas
UNION ALL SELECT 'creditos.credito_id',     COUNT(*) - COUNT(DISTINCT credito_id) FROM raw.creditos
UNION ALL SELECT 'tickets.ticket_id',       COUNT(*) - COUNT(DISTINCT ticket_id)  FROM raw.tickets;
GO
--
SELECT 'cliente_id' AS chave, COUNT(*) AS nulos FROM raw.crm_clientes   WHERE cliente_id IS NULL
UNION ALL SELECT 'conta_id',   COUNT(*) FROM raw.billing_contas WHERE conta_id   IS NULL
UNION ALL SELECT 'fatura_id',  COUNT(*) FROM raw.faturas        WHERE fatura_id  IS NULL
UNION ALL SELECT 'credito_id', COUNT(*) FROM raw.creditos       WHERE credito_id IS NULL
UNION ALL SELECT 'ticket_id',  COUNT(*) FROM raw.tickets        WHERE ticket_id  IS NULL;
go
/* ---------------------------------------------------------------------
   BLOCO 6 – CONSUMO EM MAIS DE UM LOTE (suspeita nº 1).
   Se o mesmo dia x conta x produto x região aparece em 2+ lotes, o
   pipeline reprocessou o dia e a receita está somada em dobro.
   --------------------------------------------------------------------- */
WITH grupos AS (
    SELECT data, conta_id, produto, regiao,
           COUNT(*)                AS linhas,
           COUNT(DISTINCT lote_id) AS lotes,
           SUM(TRY_CAST(quantidade AS DECIMAL(18,4))
             * TRY_CAST(preco_unitario AS DECIMAL(18,6))) AS receita_total
    FROM raw.consumo_diario
    GROUP BY data, conta_id, produto, regiao
)
SELECT COUNT(*)                                          AS grupos_total,
       SUM(CASE WHEN lotes > 1 THEN 1 ELSE 0 END)        AS grupos_em_mais_de_um_lote,
       SUM(CASE WHEN linhas > lotes THEN 1 ELSE 0 END)   AS grupos_repetidos_no_mesmo_lote,
       SUM(receita_total)                                AS receita_bruta_sem_dedup
FROM grupos;

-- Quais dias foram recarregados? (ajuda a achar a data do incidente)
SELECT data,
       COUNT(DISTINCT lote_id)  AS lotes,
       MIN(carregado_em)        AS primeira_carga,
       MAX(carregado_em)        AS ultima_carga,
       COUNT(*)                 AS linhas
FROM raw.consumo_diario
GROUP BY data
HAVING COUNT(DISTINCT lote_id) > 1
ORDER BY data;
GO

/* ---------------------------------------------------------------------
   BLOCO 7 – FATURAS: cancelamento, reemissão e conta do líquido.
   --------------------------------------------------------------------- */
-- 7a. Status x existência de fatura substituta
SELECT status, CASE WHEN NULLIF(REPLACE(fatura_substituta_id, CHAR(13), ''), '') IS NULL
            THEN 'sem substituta' ELSE 'com substituta' END AS substituta,
       COUNT(*) AS faturas,
       SUM(TRY_CAST(valor_liquido AS DECIMAL(14,2))) AS valor_liquido
FROM raw.faturas
GROUP BY status,
         CASE WHEN NULLIF(REPLACE(fatura_substituta_id, CHAR(13), ''), '') IS NULL
              THEN 'sem substituta' ELSE 'com substituta' END
ORDER BY status;

-- 7b. A substituta apontada existe?
SELECT f.fatura_id, f.status, f.fatura_substituta_id
FROM raw.faturas f
LEFT JOIN raw.faturas s ON s.fatura_id = REPLACE(f.fatura_substituta_id, CHAR(13), '')
WHERE NULLIF(REPLACE(f.fatura_substituta_id, CHAR(13), ''), '') IS NOT NULL
  AND s.fatura_id IS NULL;

-- 7c. Mais de uma fatura NÃO cancelada para a mesma conta x competência
SELECT conta_id, competencia, COUNT(*) AS faturas_validas
FROM raw.faturas
WHERE status <> 'CANCELADA'
GROUP BY conta_id, competencia
HAVING COUNT(*) > 1
ORDER BY faturas_validas DESC;

-- 7d. valor_liquido <> valor_bruto - valor_creditos (tolerância de 1 centavo)
SELECT *, iif(exists(select 1 from raw.faturas b where b.fatura_substituta_id = a.fatura_id),1,0) reemitida,
       TRY_CAST(valor_bruto AS DECIMAL(14,2))
     - TRY_CAST(valor_creditos AS DECIMAL(14,2))
     - TRY_CAST(valor_liquido AS DECIMAL(14,2)) AS diferenca
FROM raw.faturas a
WHERE ABS(  TRY_CAST(valor_bruto AS DECIMAL(14,2))
          - TRY_CAST(valor_creditos AS DECIMAL(14,2))
          - TRY_CAST(valor_liquido AS DECIMAL(14,2))) > 0.01;
GO

--7e
SELECT *, iif(exists(select 1 from raw.faturas b where b.fatura_substituta_id = f.fatura_id),1,0) reemitida, c.tipo,
       CASE WHEN ABS(TRY_CAST(f.valor_bruto AS DECIMAL(14,2))
                   - TRY_CAST(f.valor_creditos AS DECIMAL(14,2))
                   - TRY_CAST(f.valor_liquido AS DECIMAL(14,2))) > 0.01
            THEN 'ERRADA' ELSE 'OK' END AS situacao
FROM raw.faturas f
JOIN raw.creditos c ON c.conta_id = f.conta_id AND c.competencia = f.competencia
WHERE f.competencia = '2026-08'
ORDER BY c.tipo, situacao;

SELECT *
FROM raw.faturas
WHERE fatura_substituta_id = 'NF-000785'
or fatura_id = 'NF-000785';

/* ---------------------------------------------------------------------
   BLOCO 8 – VÍNCULO CONTA x CLIENTE (preenchimento manual).
   --------------------------------------------------------------------- */
SELECT
    SUM(CASE WHEN NULLIF(b.cliente_id, '') IS NULL THEN 1 ELSE 0 END)          AS contas_sem_cliente,
    SUM(CASE WHEN NULLIF(b.cliente_id, '') IS NOT NULL
              AND c.cliente_id IS NULL THEN 1 ELSE 0 END)                       AS cliente_inexistente_no_crm,
    SUM(CASE WHEN c.cliente_id IS NOT NULL
              AND b.cnpj_raiz <> c.cnpj_raiz THEN 1 ELSE 0 END)                 AS cnpj_diverge_do_cliente
FROM raw.billing_contas b
LEFT JOIN raw.crm_clientes c ON c.cliente_id = b.cliente_id;

-- Consumo/faturas de contas que não existem no billing_contas
SELECT 'consumo' AS origem, COUNT(DISTINCT x.conta_id) AS contas_orfas
FROM raw.consumo_diario x
LEFT JOIN raw.billing_contas b ON b.conta_id = x.conta_id
WHERE b.conta_id IS NULL
UNION ALL
SELECT 'faturas', COUNT(DISTINCT x.conta_id)
FROM raw.faturas x
LEFT JOIN raw.billing_contas b ON b.conta_id = x.conta_id
WHERE b.conta_id IS NULL;
GO

SELECT * FROM raw.billing_contas WHERE cliente_id IS NULL;

-- Recupera o cliente das contas sem cliente_id, usando o CNPJ (sem pontos)
SELECT b.conta_id,
       b.cnpj_raiz                       AS cnpj_conta,
       REPLACE(b.cnpj_raiz, '.', '')     AS cnpj_conta_limpo,
       c.cliente_id                      AS cliente_encontrado,
       c.razao_social,
       c.segmento,
       CASE WHEN c.cliente_id IS NULL
            THEN 'NÃO ENCONTRADO' ELSE 'ENCONTRADO' END AS resultado
FROM raw.billing_contas b
LEFT JOIN raw.crm_clientes c
       ON c.cnpj_raiz = REPLACE(b.cnpj_raiz, '.', '')
WHERE b.cliente_id IS NULL
ORDER BY b.conta_id;



/* ---------------------------------------------------------------------
   BLOCO 9 – HISTÓRICO DE SEGMENTO: vigências sobrepostas e
   segmento atual divergente do CRM.
   Obs.: comparação de datas como texto só é segura se o BLOCO 1
   mostrar formato único 'yyyy-mm-dd'. Se não, ajuste com TRY_CONVERT.
   --------------------------------------------------------------------- */
-- 9a. Sobreposição de vigência para o mesmo cliente
SELECT a.cliente_id,
       a.segmento AS seg_a, a.valido_de AS de_a, a.valido_ate AS ate_a,
       b.segmento AS seg_b, b.valido_de AS de_b, b.valido_ate AS ate_b
FROM raw.crm_segmento_historico a
JOIN raw.crm_segmento_historico b
  ON  a.cliente_id = b.cliente_id
  AND a.valido_de  < b.valido_de
  AND COALESCE(NULLIF(REPLACE(a.valido_ate, CHAR(13), ''), ''), '9999-12-31') > b.valido_de;

-- 9b. Segmento vigente no histórico x segmento atual no CRM
SELECT c.cliente_id, c.segmento AS segmento_crm, h.segmento AS segmento_hist_vigente
FROM raw.crm_clientes c
LEFT JOIN raw.crm_segmento_historico h
       ON h.cliente_id = c.cliente_id
      AND NULLIF(REPLACE(h.valido_ate, CHAR(13), ''), '') IS NULL
WHERE h.cliente_id IS NULL OR h.segmento <> c.segmento;
GO