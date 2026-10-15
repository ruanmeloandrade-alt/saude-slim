# Saúde Slim: Públicos, Disparos, Automações e Configurações

Status inicial: 🟠 diagnóstico direcionado. Base 5151b45. Branch fix/slim-publicos-config-20261015. Destino operacional restauracao/sistema-completo-20261014, repositório ruanmeloandrade-alt/saude-slim. Banco exclusivo vyzvfcgpjjzvcjegzzza.

## Ordem solicitada pelo usuário

1. Públicos, Disparos e automações avançadas.
2. Configurações gerais.
3. No FINAL da fila, resolver as cinco fontes da Dashboard: Envios de formulários, Campos personalizados, Valores dos campos, Sites de tracking e Indicadores de tracking. Esta terceira tarefa foi adicionada por interrupção explícita. Não apenas esconder o aviso nem marcar fonte vazia como corrigida.

## Continuidade e limites

Preservar as correções publicadas de IA, Inbox, SalesBot manual/120s, Histórico e Dashboard. Não alterar Pedidos neste bloco, nem main, DNS, Evolution, Harpia, MCP, MktOn original ou executar GitHub Actions. Não usar agente Lovable. O escopo de Fase 2 só se amplia no recorte de fontes da Dashboard explicitamente pedido agora; não ativar campanhas ou integrações externas sem credenciais do próprio workspace.

## Diagnóstico já disponível

Faltam estruturas de segmentos CRM, campos, tarefas, jobs de automações e configurações de segurança, além de RPCs de convites/administração. Auditar os contratos de cada consumidor antes de criar estruturas. A tabela vazia isoladamente não comprova o módulo; validar filtro, persistência, execução, autorização e retorno de erros.

## Aceite

Públicos persistentes com filtros corretos e isolamento. Disparos sem lista truncada, duplicação silenciosa ou envio para sessão/empresa errada; nenhum teste em cliente real. Automações agendadas com fila, cancelamento e proteção contra concorrência conforme o runtime existente. Configurações e convites restritos ao administrador, sem mudança de privilégios pelo membro comum. Não dizer que MFA/segurança funciona só porque uma preferência foi salva.

Executar testes determinísticos e consultas/sondas de banco com rollback. Versionar migrations e código; confirmar build e deploy antes de declarar publicado. Separar testes de banco, código, HTTP e navegador autenticado. Atualizar docs/OPERATION_STATUS.md em cada checkpoint com entrega, evidência, bloqueio e próximo item. Este registro não promete execução em segundo plano.
