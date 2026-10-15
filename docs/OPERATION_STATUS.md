# Saúde Slim: semáforo de produção

Checkpoint de 15/10/2026. Repositório exclusivo ruanmeloandrade-alt/saude-slim; branch operacional restauracao/sistema-completo-20261014; Supabase vyzvfcgpjjzvcjegzzza; serviço saude-slim-web.
Última versão funcional previamente conferida: c7956c4, com checkpoint documental 5151b45. Nova implementação 022d6ce: aguardando resultado de build/deploy neste checkpoint. Não afirmar que já está publicada.

## Legenda

🟢 Entrega delimitada concluída e verificada. 🟠 Parcial/em validação. 🔴 Bloqueio ou implementação pendente. O verde de uma correção não significa homologação integral do módulo. Testes de código, banco e build não são teste autenticado de interface.

## Prioridade atual solicitada

1. Públicos, Disparos e automações avançadas.
2. Configurações gerais.
3. Ao final: as cinco fontes da Dashboard (Envios de formulários, Campos personalizados, Valores dos campos, Sites de tracking e Indicadores de tracking). Não apenas ocultar o aviso.

## Trabalho novo deste checkpoint

| Recorte | Estado | Realizado | Falta |
|---|---|---|---|
| Público persistente e ações de etapa | 🟠 | Migration 20261015115919 aplicada. Sonda SQL de CRUD, referências e substituição atômica executada e revertida. | Publicação do código e homologação da interface. |
| Filtros de Públicos | 🟠 | Código corrige tags JSON, filtros combinados e corte anterior à filtragem; 13 testes locais passaram. | Build e teste autenticado. O filtro legado de silêncio ainda usa atualização do lead, não histórico real de mensagens. |
| Fila de disparos/reativação | 🟠 | Migration 20261015120218 aplicada; código de processamento/progresso/cancelamento preparado; 16 testes locais da orquestração passaram. | Teste real da fila e do envio não comprovados; sonda SQL da fila foi bloqueada pela segurança da ferramenta. Não contabilizar como teste aprovado. |
| Automações de etapa | 🟠 | Persistência restaurada, reserva atômica e processamento pelo servidor preparados; bloqueio de visualizador antes de cliente privilegiado. | Build, execução real controlada e contratos avançados de grupos/workflow/Meta. |
| Configurações gerais | 🔴 | Código prepara erros explícitos onde antes havia sucesso/default falso. | Migration de segurança/equipe/convites bloqueada pela ferramenta e NÃO aplicada. Tabela workspace_security_settings segue ausente. |
| Dashboard: campos e valores | 🟠 | Duas estruturas restauradas por serem dependências de Públicos; gravação/releitura incluídas na sonda. | Homologação da UI e indicadores. |
| Dashboard: envios e tracking | 🔴 | Mantidos no final da fila conforme solicitação. | Estruturas, ingestão, agregação e validação real. |

## Semáforo completo dos módulos

| Área | Estado | Feito e pendências |
|---|---|---|
| Agentes IA | 🟠 | Cofre/persistência corrigidos e publicados anteriormente. Falta resposta real com chave própria e agente cadastrado. |
| Home: Histórico de Vendas | 🟠 | Paginação/status corrigidos e publicados; falta homologação integral dos filtros/detalhes. |
| Home: Dashboard detalhada | 🟠 | Carregamento comercial corrigido/publicado. Fontes extras agora têm tarefa explícita no fim da fila. |
| Pedidos | 🟠 | Diagnóstico documentado: gravação não atômica, cliente existente/novo lead, desconto integral e valores; sem correção neste bloco. |
| Fornecedores | 🟠 | CRUD/custo testados no banco anteriormente; interface ainda não homologada. |
| Estoque | 🟠 | Cadastro/edição básica verificados; baixa e histórico por pedido pendentes. |
| Produtos | 🟠 | Catálogo/produto verificados no banco; interface/vínculos completos pendentes. |
| Disparo em massa | 🟠 | Nova fila e código em validação; não declarar entrega WhatsApp pronta. |
| CRM: Funil | 🟠 | Contrato de automações restaurado; execução integrada e interface pendentes. |
| CRM: Clientes | 🟠 | Operações básicas verificadas; cenários completos de filtros/deduplicação/permissões pendentes. |
| CRM: Inbox | 🟠 | SalesBot enviado pelo teste do usuário e controles publicados anteriormente; IA/anexos/cenários completos pendentes. |
| CRM: Automações | 🟠 | Contrato de etapa novo em validação; grupos/workflow/integrações avançadas continuam pendentes. |
| CRM: Cérebro IA | 🟠 | Fontes/chunks/termos existentes; ingestão/recuperação/resposta real pendentes. |
| CRM: Públicos | 🟠 | Persistência aplicada e filtros corrigidos no código; publicar/validar interface. Meta/exportação não homologados. |
| Configurações: Geral | 🔴 | Bloqueio explícito de ferramenta no pacote de banco. Não afirmar que apenas atualizar o site resolverá. |
| Configurações: Integrações | 🟠 | Cofre IA corrigido anteriormente; credenciais próprias e demais contratos ainda exigem validação. |

## Entregas delimitadas anteriores preservadas

🟢 Cofre IA e persistência: migrations 20261015024506/20261015025453, nove testes de chave no build.
🟢 Leitura do Histórico: 28c8a5a, sete regressões de paginação/status.
🟢 Carregamento comercial da Dashboard: c7956c4, 16 testes de dados e oito verificações de integração no build, oito consultas autenticadas no banco.
🟢 Varredura estrutural: 16 frentes/444 arquivos/147 rotas; não equivale a homologação funcional integral.
🟢 Semáforo exclusivo da Saúde Slim substitui definitivamente o status herdado da MktOn.

## Evidências e bloqueios desta execução

Somente as migrations 20261015115919 e 20261015120218 foram aplicadas nesta retomada. O pacote slim_restore_settings_security_and_invitations foi bloqueado e não foi executado nem colocado em implantação automática.
O teste inicial da fila falhou por local_id obrigatório no bot temporário e foi revertido. O teste corrigido foi bloqueado, não executado. Nenhuma tentativa de contornar o bloqueio por outra identidade ou serviço.
Consulta somente leitura posterior: zero campanhas, destinatários, públicos e ações de teste; zero tabelas públicas com RLS desabilitada.
Advisors de segurança: permanecem quatro avisos preexistentes das funções do Inbox e proteção contra senhas vazadas desativada; nenhuma aprovação ampla de segurança é declarada.
Testes locais: 13 de Públicos e 16 de orquestração de entrega realmente passaram. Novos testes de contrato/autorização ainda aguardam os logs de build. Nenhuma mensagem real enviada durante testes, nenhum usuário criado, nenhuma chave lida/rotacionada.

## Próximo checkpoint

Conferir build/deploy da implementação 022d6ce e atualizar este arquivo com resultados reais. Manter Configurações bloqueadas e Dashboard extras na posição solicitada, sem declarar todos os módulos concluídos. A última frente trabalhada não significa execução do assistente em segundo plano.
Escopo detalhado: docs/tasks/2026-10-15-slim-publicos-config-dashboard.md. Preservar os escopos anteriores de Pedidos e Dashboard.
Sem alterações em main, DNS, Evolution, Harpia, MCP, MktOn original ou GitHub Actions. Sem Lovable.
