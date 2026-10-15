# Saúde Slim: Configurações e fontes da Dashboard

## Publicação verificada

Base inicial desta retomada: baf399325ef455d733c157cd8693a747f246a811, já publicado com Públicos/Disparos.
Configurações: 654d92a580d4df8cbadf0f4863b7eb4274f44244, deployment 982e9da0-c8f9-4eca-9d8f-7d345b81dd33 SUCCESS.
Dashboard/tracking final: debbd1e63134d757c1e1b4052b99a934a64c28dd (inclui ca72ab0), deployment b68da748-1ebe-48a9-b9d5-2ca4ea80d893 SUCCESS e healthcheck aprovado em 2026-10-15T13:25:15Z.

Exclusivamente ruanmeloandrade-alt/saude-slim, branch restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza. O semáforo canônico é docs/OPERATION_STATUS.md.

## Configurações: correção efetiva

Os quatro handlers de perfil, preferências, empresa e expediente passam a exigir retorno da linha alterada. Erro de consulta e zero linhas alteradas não retornam mais sucesso. Isso foi implementado no código; não é uma afirmação de teste autenticado desses quatro formulários.

Expediente valida o fuso com Intl e horários entre 00:00 e 23:59 para os sete dias, mantendo intervalos noturnos já possíveis. Cadastro de funcionário valida a presença do setor e a existência do setor selecionado antes de criar a identidade. Não foi reescrito o restante do processo como uma transação completa.

Na tela de segurança, a pontuação anteriormente calculada mesmo com fontes falhando foi removida. Agora há estados explícitos de carregamento, erro e resposta confirmada. Falha não ativa indicadores de proteção; salvamento requer confirmação do servidor e não altera o botão de forma otimista. Controle por administrador e serialização de gravação foram preservados. A preferência local de inatividade permanece disponível. A troca de senha libera o estado de carregamento em falha de transporte. Falha no serviço de códigos de recuperação não vira carregamento infinito.

As alterações preservam os controles e os papéis existentes. Não habilitam MFA/passkeys/convites nem alteram banco de autenticação. Preferência salva não comprova uma proteção aplicada a todos os acessos.

## Dashboard: fontes restauradas

A migration 20261015125725 criou crm_form_submissions, tracking_sites, tracking_events e tracking_conversion_events, com índices, RLS, referências por workspace e o RPC tracking_overview. lead_custom_fields e lead_custom_field_values já haviam sido restaurados na frente de Públicos. O aviso da Dashboard não foi removido; a causa de ausência das fontes foi corrigida.

O agregado usa períodos de 24 horas/sete dias, exclui eventos internos e timestamps futuros, distingue sessões/visitantes por site e não soma moedas diferentes no KPI BRL.

A migration 20261015130340 limita as colunas editáveis dos sites pelo navegador e acrescenta totais completos de receita por moeda e conversões por campanha. A coleta/verificação fica sob responsabilidade do servidor; nenhum evento fictício foi deixado gravado.

O novo carregador de getTrackingOverview mantém a checagem de participação na empresa e passa a usar os agregados completos. Não deriva o total de vendas do tamanho de uma lista de conversões limitada pela API. Sites são paginados, eventos recentes continuam explicitamente limitados a vinte, campanhas com conversão sem sessão também são representadas e agregados incompletos/divergentes são rejeitados. Um teste adicional protege a identidade de grupos com rótulos vazios.

As demais rotas do módulo Tracking e os widgets da Dashboard foram preservados. Não foi declarado que o coletor público/pixel, todas as definições de conversão, atribuição avançada ou filtros gerais do módulo Tracking estão homologados.

## Testes e resultados

### Código

64 verificações novas aprovadas no build final:
- 20 da lógica de Configurações.
- 12 de integração/âncoras/idempotência do código de Configurações.
- 17 da normalização e consistência dos agregados de tracking.
- 8 do carregador com transporte simulado.
- 7 do contrato de integração do overview.

As 20 verificações de lógica de Configurações, 17 de agregação e oito do carregador também foram executadas localmente em Node 22.16.0. Os testes usam a lógica real e dublês de transporte; não fazem chamadas externas. As verificações de contrato são sobre os fontes transformados no prebuild, não navegação de navegador.

Os testes anteriores de IA, Histórico, Dashboard comercial, Públicos, orquestração de entrega, autorização, Inbox e salvamento continuam na cadeia do build. Logs finais reconfirmaram os grupos anteriores 9, 7, 16, 8, 13, 16, 11 e 6, além das novas verificações.

### Banco: sonda executada e revertida

A sonda da primeira migration executou gravação/releitura de envio de formulário, leitura das outras fontes, eventos de dois sites, períodos diferentes, evento interno, timestamp futuro e duas moedas. Foram verificados: totais temporais, sessões/visitantes por site, conversões, receita BRL sem agregar USD, rejeição de período inválido, rejeição de workspace indevido e ausência dos registros após rollback. Nenhuma ação de envio foi executada.

### Banco: leitura final executada

A leitura autenticada posterior consultou as cinco fontes e a versão final de tracking_overview, incluindo os novos campos revenue_by_currency e conversion_by_campaign. A consulta de privilégios confirmou SELECT de envios, UPDATE de nome de site, ausência de UPDATE de verificação/workspace, ausência de INSERT de eventos pelo navegador e ausência de execução anônima do agregado.

### Teste bloqueado, não contabilizado como aprovado

A sonda de mutação da segunda migration foi bloqueada pela ferramenta antes de executar. Não é um teste aprovado. As leituras de catálogo/RPC citadas acima não substituem essa sonda. A migration em si foi aplicada com sucesso e o número foi conferido no histórico.

## Bloqueio de Configurações preservado

O pacote anterior slim_restore_settings_security_and_invitations foi bloqueado e não aplicado. Não foi reexecutado por outro serviço, identidade ou script de deploy. O backend de segurança/convites continua pendente, independentemente das correções de retorno e interface publicadas.

O advisor executado após as migrations de tracking manteve avisos anteriores das quatro funções do Inbox expostas como SECURITY DEFINER e da proteção contra senhas vazadas desativada. As fontes novas não produziram novos avisos nesse resultado; isso não equivale a aprovação ampla da segurança.
Referências de remediação do advisor:
- https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable
- https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## Limites operacionais

Sem teste de navegador autenticado, entrega real de WhatsApp/OpenAI ou coleta real do pixel/formulário no domínio. Nenhuma chave foi lida, publicada ou rotacionada. Nenhum usuário real criado. Não houve alteração de DNS, Evolution, main, MktOn original, Harpia, MCP, Pedidos ou GitHub Actions.

O checkpoint fecha as correções delimitadas de código e de fontes, não toda a auditoria funcional. Os módulos parcialmente validados e o bloqueio de Configurações continuam visíveis no semáforo.
