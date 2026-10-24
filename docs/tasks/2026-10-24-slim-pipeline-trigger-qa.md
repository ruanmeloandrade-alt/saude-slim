# QA dos gatilhos de pipeline e execução

## Pedido

Corrigir seleção de outras unidades além de minutos e conferir todos os gatilhos de pipeline, modos de execução, o conjunto completo de opções de Executar e Aplicar o gatilho aos leads existentes. Usar o sistema real, sem Chrome ou controle de mouse. Formulários continuam fora do produto; não retomar seus ensaios.

## Escopo e cuidados

Branch `fix/slim-pipeline-trigger-qa-20261024`, baseada na produção `d9ec622`. Mapear UI → salvamento confirmado → job → executor e eventos reais. Exercitar opções apresentadas na interface e filtros/condições/janelas de execução. Corrigir apenas falhas encontradas nesse caminho, preservando bots, contatos e configurações de clientes.

Dados reais de teste serão identificados como QA e isolados em funil próprio. Nenhum disparo em massa sobre contatos do cliente. Aplicar aos existentes será exercitado somente nesse funil, com ações internas sem envio externo. Registrar evidências antes de remover fixtures.

## Aceite

- Minutos/horas/dias selecionáveis e persistidos corretamente.
- Cada opção disponível de Executar respeita seu evento e seu agendamento.
- Modos Sempre/Expediente/Personalizado e regras aplicados de fato.
- Aplicar aos existentes grava, enfileira e confirma o resultado; falha não pode aparecer como sucesso.
- Testes de callbacks reais, banco/fila/executor e build; publicar correções validadas e conferir nova versão.

## Achados e correções

- Unidade era inferida do valor a cada render, desfazendo escolhas como 60 minutos/24 horas. Seletores nativos, unidade persistida e edição vazia sem trocar o gatilho. Fonte tinha dois callbacks de alternância no mesmo clique; usar o item de seleção único. Condição de responsável agora oferece os usuários reais da conta.
- Pronto apenas alterava o rascunho; agora aguarda salvamento, releitura de todas as opções e aplicação solicitada. Rascunho/erro mantidos na falha, editor permanece aberto para correção.
- Aplicar existentes tinha dois caminhos e falhas silenciosas. Um caminho no servidor lê execution.applyToExisting, comando de uso único, ID da tentativa preservado e dedupe por lead/configuração. Paginação substitui teto silencioso de 2000; datas/diário respeitados.
- Diário não se repetia nem cobria automaticamente os leads já presentes. Reconciliação pelo worker existente, dedupe entre eventos/salvamento/ticks, horários no fuso da conta, recuperação na próxima passagem, proteção de etapa/ação/data alteradas. Nenhuma infraestrutura ou migration nova.
- Regras de responsável/fonte/UTM/listas eram ignoradas ou comparadas incompletamente. Corrigidas junto de expediente configurado, fuso e janela noturna. Campo identificado por ID continua funcionando após mudança de nome.
- A reserva atômica de execução já existia no código gerado via slim_claim_stage_job. Foi preservada; não registrar como falha confirmada de produção. O gerador de build também foi ajustado para manter a reconciliação dos timers.
- Mensagem interna da etapa só registrava nota. Agora entrega também alerta privado no Chat da equipe, valida destinatário na mesma empresa e confirma nota/entrega. Falha não confirma sucesso.

## Validação até aqui

`test-slim-pipeline-qa.mjs`: 12/12 PASS, callbacks reais e PostgreSQL isolado, incluindo 2006 leads, falha após 500 e retomada sem duplicação, rascunho preservado na falha, todos os seletores de Executar, regras, recorrência e entrega privada. Dois builds completos PASS. Teste passou nas fontes geradas. Lint do novo núcleo PASS. Bundle SSR final stage-automation-engine.server-kpItLH2L confirmou reconciliação, claim nativo, alerta privado e recibo da nota. Após o build, apenas normalização do nome de campo legado no núcleo foi alinhada e retestada.

RPC real replace_crm_stage_automations testada em transação revertida com sessão nativa de administrador, AAL1 real e RLS: opções de horas/período personalizado preservadas, sessionAllowed=true. Sem enfraquecer autenticação.

Fixtures isoladas preparadas: pipeline 7c33b287-29b3-4ccb-91ef-242610240001, onze etapas e contatos QA sem telefone, campo datetime, bot QA e 17 ações DESATIVADAS. Ativar somente para os testes após publicação; limpar depois de guardar evidências. Nenhuma ação do cliente alterada.

Status: correções e QA técnico aprovados; falta publicação, conferência operacional de produção e limpeza dos fixtures.
