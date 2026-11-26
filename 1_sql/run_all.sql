/* =====================================================================
   run_all.sql – recria o projeto inteiro do zero, na ordem certa
   Engine : SQL Server 2019+

   Como rodar:
   - SSMS: menu Query → SQLCMD Mode (ativar) → F5
   - Linha de comando / agendamento: executar_pipeline.bat (na raiz do repo)

   Caminhos: cada :r usa o caminho COMPLETO da pasta sql/ do repositório.
   Se o repositório mudar de lugar, troque o início dos caminhos
   (Ctrl+H no SSMS). Não usei variável (:setvar) porque o SSMS não resolve
   bem variável dentro de aspas, e as aspas são necessárias porque a
   pasta tem espaço ("dev local"). O caminho dos CSVs fica no 02_carga_raw.sql.

   Comportamento:
   - :on error exit → qualquer erro para tudo (inclusive teste que falhar,
     porque os scripts de teste geram RAISERROR).
   - A stg só é testada depois de criada; o dw só é criado se a stg passar.
   ===================================================================== */

:on error exit

PRINT '=== 1. Setup (banco e schemas) ===';
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\00_setup.sql"

PRINT '=== 2. Camada RAW (tabelas + carga dos CSVs) ===';
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\01_raw\01_create_raw.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\01_raw\02_carga_raw.sql"

PRINT '=== 3. Camada STG (views de limpeza) ===';
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\02_stg\01_stg_crm_clientes.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\02_stg\02_stg_crm_segmento_historico.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\02_stg\03_stg_billing_contas.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\02_stg\04_stg_consumo_diario.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\02_stg\05_stg_faturas.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\02_stg\06_stg_creditos.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\02_stg\07_stg_tickets.sql"

PRINT '=== 4. Testes da STG ===';
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\04_dq\10_testes_stg.sql"

PRINT '=== 5. Camada DW (dimensões, fatos, métricas) ===';
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\00_drop_dw.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\01_dim_data.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\02_dim_cliente.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\03_dim_conta.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\04_dim_produto.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\05_fato_consumo_diario.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\06_fato_fatura.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\07_fato_credito.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\08_fato_ticket.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\09_fato_conciliacao_mensal.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\10_vw_receita_mensal.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\11_vw_cliente_mes.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\12_vw_kpis_mensais.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\13_vw_concentracao_clientes.sql"
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\03_dw\14_vw_suporte_mensal.sql"

PRINT '=== 6. Testes do DW ===';
:r "C:\Users\dev local\Documents\desafio\nuvemBr\1_sql\04_dq\20_testes_dw.sql"

PRINT '=== Concluído: todas as camadas criadas e testadas. ===';
