/* =====================================================================
   Script : 01_raw/02_carga_raw.sql
   Engine : SQL Server 2019+
   Objetivo: carregar os 7 CSVs na camada RAW 

   ANTES DE RODAR:
   - Ajuste @pasta para o caminho dos CSVs NA MÁQUINA DO SQL SERVER

   Observações:
   - FORMAT = 'CSV' (SQL Server 2017+) trata campos entre aspas, ex.:
     razão social com vírgula dentro.
   - ROWTERMINATOR = '0x0a' (LF). Se o arquivo for CRLF, a última coluna
     de cada linha vai vir com CHAR(13) no fim. Não corrijo aqui:
     a stg faz TRIM/REPLACE(CHAR(13)) e isso fica documentado.
   - CODEPAGE = '65001' = UTF-8 (acentos em razão social/descrição).
   ===================================================================== */

USE NuvemBR;
GO

DECLARE @pasta NVARCHAR(400) = N'C:\dados\';  
DECLARE @sep   NVARCHAR(5)   = N',';          
DECLARE @sql   NVARCHAR(MAX);
DECLARE @inicio DATETIME2(0) = SYSDATETIME();  -- marca o início desta execução

-- Tabela-guia: arquivo, tabela de destino e linhas esperadas (do enunciado).
DECLARE @arquivos TABLE (arquivo NVARCHAR(100), tabela SYSNAME, esperado INT);
INSERT INTO @arquivos VALUES
    (N'crm_clientes.csv',           N'crm_clientes',              90),
    (N'crm_segmento_historico.csv', N'crm_segmento_historico',    98),
    (N'billing_contas.csv',         N'billing_contas',            93),
    (N'consumo_diario.csv',         N'consumo_diario',         91396),
    (N'faturas.csv',                N'faturas',                  785),
    (N'creditos.csv',               N'creditos',                  80),
    (N'tickets.csv',                N'tickets',                  371);

DECLARE @arquivo NVARCHAR(100), @tabela SYSNAME, @esperado INT, @qtd INT;

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT arquivo, tabela, esperado FROM @arquivos;
OPEN c;
FETCH NEXT FROM c INTO @arquivo, @tabela, @esperado;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Carga idempotente: limpa e recarrega (raw é sempre o espelho do arquivo).
    SET @sql = N'TRUNCATE TABLE raw.' + QUOTENAME(@tabela) + N';
    BULK INSERT raw.' + QUOTENAME(@tabela) + N'
    FROM ''' + @pasta + @arquivo + N'''
    WITH (
        FORMAT          = ''CSV'',
        FIELDQUOTE      = ''"'',
        FIELDTERMINATOR = ''' + @sep + N''',
        ROWTERMINATOR   = ''0x0a'',
        FIRSTROW        = 2,
        CODEPAGE        = ''65001'',
        TABLOCK
    );';
    EXEC sys.sp_executesql @sql;

    SET @sql = N'SELECT @qtd = COUNT(*) FROM raw.' + QUOTENAME(@tabela) + N';';
    EXEC sys.sp_executesql @sql, N'@qtd INT OUTPUT', @qtd = @qtd OUTPUT;

    FETCH NEXT FROM c INTO @arquivo, @tabela, @esperado;
END

CLOSE c;
DEALLOCATE c;