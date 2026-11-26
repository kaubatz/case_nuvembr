@echo off
REM =====================================================================
REM  executar_pipeline.bat - roda o run_all.sql pela linha de comando
REM  e grava o log em logs\pipeline_AAAAMMDD_HHMM.log
REM
REM  Uso manual: duplo clique, ou no cmd: executar_pipeline.bat
REM  Agendamento diario: Agendador de Tarefas do Windows -> Criar Tarefa
REM    Disparador: Diariamente | Acao: Iniciar programa -> este arquivo
REM
REM  -S .\SQLEXPRESS  instancia do SQL Server (ajuste se for outra)
REM  -E               login do Windows (para login SQL: -U usuario -P senha)
REM  -b               para no primeiro erro e devolve codigo de erro
REM  -I               QUOTED_IDENTIFIER ligado (padrao do SSMS)
REM =====================================================================
cd /d "%~dp0"
if not exist logs mkdir logs

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmm"') do set DATAHORA=%%i
set LOG=logs\pipeline_%DATAHORA%.log

echo Executando pipeline... log em %LOG%
sqlcmd -S .\SQLEXPRESS -E -b -I -i "run_all.sql" -o "%LOG%"

if %ERRORLEVEL% NEQ 0 (
    echo FALHOU. Veja o log: %LOG%
    exit /b 1
)
echo OK. Pipeline concluido. Log: %LOG%
exit /b 0
