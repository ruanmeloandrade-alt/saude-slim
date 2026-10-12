# Social Media — Log incremental de execução

Este arquivo registra o início e o fechamento de cada task para reduzir perda de contexto e retrabalho entre chats/devs. O escopo fechado continua em `docs/SOCIAL-MEDIA-EXECUTION-SCOPE.md`.

## T1 — Cofre de integrações

### Início — 2026-08-11
Status: **EM ANDAMENTO**

Objetivo desta rodada:
- localizar todos os usos de `INTEGRATION_ENCRYPTION_KEY` no Social Media e na infraestrutura compartilhada;
- revisar leitura e gravação via `get_integration_secret` / `set_integration_secret`;
- corrigir divergências de mensagem/erro que sejam problema de código;
- separar claramente correção implementável no repositório de dependência de secret no runtime;
- executar regressão relevante antes de encerrar.

Progresso geral ao iniciar: **14/15 tarefas concluídas (93%)**.

Critério para liberar teste funcional: código do cofre auditado/corrigido, CI verde e instrução clara sobre qualquer configuração externa ainda necessária.

### Fechamento técnico — 2026-08-11
Status: **CÓDIGO CONCLUÍDO — QA FUNCIONAL DO RUNTIME PENDENTE**

Resultado:
- criada uma mensagem centralizada e segura para indisponibilidade do cofre em `src/lib/integration-vault.ts`;
- `set_integration_secret` e `get_integration_secret` deixaram de expor erro bruto do RPC ao usuário nos caminhos auditados;
- `generate-image` agora devolve erro HTTP 503 claro quando o cofre não pode ser acessado;
- `refine-content` agora transforma falha de leitura do cofre em resposta controlada, em vez de deixar o erro escapar pelo handler;
- o refinamento de briefing da Campanha passou a usar o mesmo tratamento seguro;
- o fluxo de salvar/retestar Ideogram em `integrations.functions.ts` deixou o endpoint legado `/generate` V2 e foi alinhado ao endpoint V3 usado pela geração real: `/v1/ideogram-v3/generate`, com `Api-Key` e `FormData`;
- dívida de lint legada no tipo de acesso Supabase foi explicitamente isolada, sem ampliar a refatoração;
- workflow temporário de auditoria removido; o gate normal do Social Media ficou responsável pela regressão.

Auditoria/validação:
- primeira rodada detectou uma dívida de lint existente em `integrations.functions.ts`; ela foi corrigida antes do fechamento;
- GitHub Actions `Social Media CI`, run `31457861853`, head `e4abcd74890f092fc2461d58116bfda94f0dc6b6`: Social publishing tests, campaign rules, post channel rules, Home regression, lints e Production build concluídos com sucesso;
- PR #64 permaneceu aberta, draft e mergeável.

Dependência externa que continua real:
- o repositório não consegue provar qual valor está configurado no runtime de produção;
- `INTEGRATION_ENCRYPTION_KEY` precisa existir no runtime e precisa ser o mesmo segredo usado para criptografar as integrações já salvas;
- não gerar, trocar nem hardcodar uma chave aleatória para “resolver” o erro, porque isso impediria descriptografar credenciais existentes;
- a T1 só será marcada 100% concluída no escopo geral depois do teste funcional no ambiente real confirmar leitura das credenciais e geração com OpenAI/Ideogram.

Progresso geral ao fechar a parte técnica: **14/15 tarefas concluídas (93%)**; T1 está pronta para QA funcional do runtime.

Roteiro de QA do usuário:
1. Integrações → OpenAI → `Re-testar chave salva` (ou salvar/testar uma chave válida).
2. Integrações → Ideogram → `Re-testar chave salva` (ou salvar/testar uma chave válida).
3. Social Media → Banco de Ideias → usar `Aprimorar prompt`; deve somente melhorar o briefing.
4. Depois clicar em `Gerar ideias`; texto deve ser gerado pelo provider conectado.
5. Gerar uma arte simples com Ideogram e confirmar imagem real.
6. Gerar um carrossel e confirmar imagem real em cada slide.

Se aparecer a mensagem de cofre indisponível, registrar a mensagem exata: nesse cenário o código já está tratando a falha corretamente e o próximo passo é corrigir a configuração do secret no runtime, não alterar novamente a lógica do Social Media.

## Publicação para QA funcional

### Início — 2026-08-11
Status: **EM ANDAMENTO**

Objetivo desta rodada:
- levar a PR #64, hoje validada na branch `agent/social-media-finalization`, para a `main` para permitir publicação no ambiente usado pelo usuário;
- confirmar o CI do head antes do merge;
- manter a PR rastreável e registrar o SHA final que entrar na `main`;
- não marcar a T1 como 15/15 até o teste funcional real de OpenAI/Ideogram.

Estado verificado antes da publicação:
- PR #64 aberta, draft, mergeável e apontando para `main`;
- CI do head anterior `cbff6334d77745b8ab52684e5d4d30fef798b208`, run `31457987603`, concluído com sucesso;
- esta atualização é documental e inicia formalmente a etapa de publicação para QA.

### Fechamento — 2026-08-11
Status: **PUBLICADO NA MAIN — PRONTO PARA O USUÁRIO PUBLICAR/TESTAR**

Resultado:
- PR #64 marcada como pronta para revisão e integrada à `main`;
- head publicado: `7fd20d77a40e3a23a3a80192344a30fce166b8b8`;
- CI final do head antes do merge: `Social Media CI` run `31458302103`, concluído com sucesso;
- merge commit na `main`: `c167ff211a618d157368fa90bb78cab60f66b232`;
- GitHub confirmou: `Pull Request successfully merged`;
- a versão do Social Media finalizada agora está na `main`, permitindo que o ambiente conectado à `main` seja publicado e usado no QA funcional.

Próximo passo:
- publicar/sincronizar o ambiente que consome a `main`;
- executar o roteiro de QA da T1 acima;
- somente após o teste real de OpenAI/Ideogram marcar o escopo geral como 15/15.
