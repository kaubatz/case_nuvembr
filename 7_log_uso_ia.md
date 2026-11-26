# Log de uso de IA

## Ferramenta
Claude (Anthropic), usado em conversa durante todo o case. 
- Fiz um prompt explicando o caso de estudo
- enviei os arquivos de dados brutos
- ele gerou alguns arquivos SQL para carregar, validar e limpar os dados
- rodei a carga inicial conferindo tudo, quantidade, campos etc
- continuei pedindo para me auxiliar em cada etapa
-- limpeza
-- qualidade
-- validações
- validei todos os scripts gerados, rodando na minha base de dados e conferindo o script e resultados

## Prompt principal
```
Aja como analista de dados sênior especialista em SQL server. Quero que me ajude a resolver uma demanda de dados onde vai checar, corrigir, documentar e modelar uma base de dados. 

Tenho 7 arquivos csv com os dados brutos e as regras a seguir 

Arquivos:
crm_clientes.csv: CRM; 1 linha por cliente (segmento atual); 90 linhas.
crm_segmento_historico.csv: CRM; 1 linha por cliente e período de vigência do segmento; 98 linhas.
billing_contas.csv: Billing; 1 linha por conta de faturamento; 93 linhas.
consumo_diario.csv: Medição (pipeline diário); dia × conta × produto × lote de carga; 91.396 linhas.
faturas.csv: Billing; 1 linha por fatura emitida; 785 linhas.
creditos.csv: Billing; 1 linha por crédito concedido; 80 linhas.
tickets.csv: Suporte; 1 linha por chamado; 371 linhas.

Regras de origem

Cliente × conta: um cliente do CRM pode ter mais de uma conta de faturamento. O vínculo billing_contas.cliente_id é preenchido manualmente pelo time comercial.

Receita de consumo: quantidade × preco_unitario. O preço é sempre por unidade-base do produto (vCPU-hora, GB-dia, nó-hora, instância-hora ou GB).

Pipeline de medição: roda diariamente e grava o lote em lote_id e o horário da carga em carregado_em.

Faturas: valor_liquido = valor_bruto − valor_creditos. Faturas podem ser canceladas e reemitidas.

Créditos: PROMOCIONAL (campanha para clientes novos), SLA (compensação por indisponibilidade) ou COMERCIAL (desconto negociado).

Tickets: exportados pela ferramenta de suporte.

Preciso fazer as seguintes etapas
- carregar os dados em tabelas 
- checar e limpar os dados
- salvar os dados normalizados em uma nova camada 
- modelar em star schema uma camada de consumo para o BI, com fatos e dimensões que vou consumir no Power BI
- conciliar o faturamento: consumo medido - créditos e faturado
- encontrar e documentar anomalias
- elaborar o dicionário e linhagem das métricas elaboradas 
- documentar decisões de regras e modelagem

Quebre tudo em tarefas pequenas para fazer e validar uma de cada vez.
```

*O que ele devolveu*
- scripts de carregamento das tabelas (bulk insert) 
-- validei e aceitei

- script de checagem de tipos de dados, quantidades, dados nulos 
-- validei e aceitei

## Modelagem do DW
- Prompt: 
```
Agora preciso criar a camada de consumo no Power BI, gere um diagrama de tabelas e relacionamentos explicando a granularidade
```
- ele gerou a imagem, eu validei e aceitei

- prompt: 
*Me auxilie na modelagem das tabelas fato e dimensão de acordo com os dados de cada tabela*
- ele gerou os scripts das tabelas e nessa parte foi onde gastei mais tempo, rodei todos, conferi os dados carregados
- li todos os scripts validando algumas regras no chat, perguntei o motivo de algumas decisões
- comentei os pontos de calculo que achei mais importantes
- eliminei alguns campos que achei desnecessários
- escrevi os comentários de campos calculados ou derivados

## Visualização e Documentação
- depois de gerar meu arquivo do power BI, pedi para ele fazer criticas e sugestões de melhoria
- aceitei algumas, descartei outras, priorizei mostrar os principais KPIs

- depois de gerar o texto do documento executivo, pedi para gerar um pdf, usando a imagem de um grafico do proprio power bi que criei
- pedi ainda para incluir itens que encontramos nas validações de dados que não foram priorizados mas eram importantes
- validei o que foi escrito e aceitei

- pedi para gerar o README.md, validei e aceitei
- dicionario de dados.md, validei e aceitei com várias modificações, principalmente pedindo textos mais sucintos e direto ao ponto
- excel com todas as anomalias, validei, resumi e aceitei
