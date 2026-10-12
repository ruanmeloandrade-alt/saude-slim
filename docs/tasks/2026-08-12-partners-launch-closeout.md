# Partners / Afiliados — fechamento de lançamento

Data: 2026-08-12
Status de código: concluído na `main`
PR final de acesso: #156
Merge funcional: `92f5bb06af299e84455b63671d324091019eef72`

## Regra canônica

- Cadastro de Afiliado ou Partner libera acesso imediato à plataforma.
- Confirmação de e-mail/2FA/aprovação de dispositivo não bloqueia o acesso inicial desses papéis.
- Status `pending` permite entrar na própria área, Faculdade Partners e Comunidade Partners.
- Aprovação administrativa controla link de indicação, comissões, benefícios comerciais e vínculos comerciais.
- Saque/recebimento continua sujeito à validação financeira e documental específica do Financeiro.

## Escopo final concluído

1. Gate global de dispositivo não bloqueia usuários com papel `affiliate` ou `partner` em `pending`/`approved`.
2. Área de Afiliado aceita `pending` e mostra a experiência normal com aviso de análise; link/comissões ficam bloqueados.
3. Área de Partner aceita `pending` e libera estudo/comunidade/plataforma; link/benefícios comerciais ficam bloqueados.
4. Comunidade Partners aceita `pending` e `approved`.
5. Faculdade Partners aceita `pending` e `approved` via RPCs reconciliados.
6. Menu interno do sistema, logo abaixo de Faculdade MKTOn:
   - Afiliado: `Acessar área de Afiliado`;
   - Partner: `Acessar área Partners`;
   - super admin: os dois atalhos + `Central Partners`;
   - usuário comum: nenhum desses atalhos.
7. Conta do dono/super admin reconciliada em produção com papéis `affiliate` e `partner` aprovados, sem necessidade de cadastro manual.
8. CI path-scoped criado para regressão desse fluxo + build de produção.

## Inventário confirmado como pronto no programa Partners/Afiliados

### Entrada e navegação

- Página pública `/partners` com escolha entre Afiliado e Partner.
- Cadastro com senha e acesso imediato, sem convite de ativação como requisito de entrada.
- Login automático pós-cadastro com destino para `/contas`.
- `/contas` não avança automaticamente e permite escolher conta/área.
- Área de Afiliado, Área de Partner e Central Partners são rotas distintas.
- Super admin tem acesso às duas experiências e à Central Partners.
- Copiloto/robô de implementação não aparece em Partners, cadastro, autenticação ou seletor de contas.

### Afiliado

- Área própria em `/partners/afiliado`.
- Comissão base: 50% na primeira venda elegível + 15% nas renovações.
- Link real de indicação disponível somente após aprovação.
- Ações de copiar e testar link real quando aprovado.
- Pending acessa a área, Faculdade e Comunidade, mas não recebe link/comissão comercial.

### Partner

- Área própria em `/partners/parceiro`.
- Faixa inicial de 35% e recorrência acompanhando a mesma faixa vigente.
- Acesso técnico a workspaces formalmente vinculados sem transformar Partner em owner/admin.
- Pending acessa a área, Faculdade, Comunidade e plataforma limitada; benefícios comerciais continuam dependentes de aprovação.

### Simulador público

- Simulação de ganhos para Afiliado e Partner.
- Períodos: mensal, trimestral, semestral e anual.
- Preços reais dos planos Start, Growth, Performance e Scale usados no simulador.

### Administração do dono

- Central Partners em `/partners/admin`.
- Aprovar, rejeitar e bloquear Afiliados e Partners.
- Gestão de payouts manuais e auditoria.
- Regras administrativas de comissão e vínculo formal Partner ↔ cliente em `/partners/admin/regras`.
- Conta do dono confirmada com `super_admin`, `affiliate` e `partner` aprovados.

### Comunidade e Faculdade

- Comunidade Partners funcional, com posts, comentários, audiência por papel e moderação administrativa.
- Afiliados/Partners em `pending` ou `approved` podem entrar na comunidade.
- Faculdade Partners ligada ao backend real de cursos, módulos, aulas, progresso e certificação.
- Pending/approved podem acessar e concluir aulas.
- Não existe conteúdo fictício inserido pela aplicação.

### Financeiro

- Perfil de pagamento server-side com dados sensíveis criptografados.
- CPF/CNPJ, PIX e titular não são expostos em texto aberto no cliente.
- Verificação manual administrativa do perfil de pagamento.
- Solicitação de payout protegida pelo fluxo financeiro.
- Aprovação de acesso ao programa não equivale a aprovação para saque.
- Payout continua manual; Stripe Connect/split automático permanece fora desta fase.

### Fonte / banco

- 15/15 migrations-base históricas preservadas no repositório como referência não executável, sem risco de reaplicação retroativa.
- PR antiga de backend #99 fechada como superseded.
- Migration atual de acesso pending versionada em `supabase/migrations/20260812143000_partner_program_pending_access.sql`.

## Produção / banco confirmado

Aplicado no projeto de produção MktOn (`47369245-434e-4f46-a9b5-ee1cec604309`):

- `partner_program_join_community`: pending/approved podem entrar na comunidade.
- `partner_program_my_academy_progress`: pending/approved podem acessar progresso acadêmico.
- `partner_program_complete_academy_lesson`: pending/approved podem concluir aulas.
- Conta do super admin confirmada com `super_admin` e papéis comerciais `affiliate` + `partner` aprovados.

## Segurança preservada

- Acesso inicial não equivale a aprovação comercial.
- Link de indicação não é liberado durante `pending`.
- Saque não é liberado apenas por ter acesso à plataforma.
- Verificação de perfil financeiro/documental permanece no fluxo de payout.

## Validação e build

Teste dedicado: `src/lib/partners-access-flow-release.test.ts`.
Workflow path-scoped: `.github/workflows/partners-access-ci.yml`.

PR #156 estava mergeável e foi mergeada na `main` no SHA `92f5bb06af299e84455b63671d324091019eef72`.

O GitHub Actions foi disparado, porém o job terminou com `runner_id=0`, runner vazio e `steps=[]`. Portanto:

- o workflow/build foi solicitado;
- nenhum step chegou a executar;
- não existe build verde para declarar;
- também não existe teste de código falhando nesse run;
- o estado é bloqueio externo do runner do GitHub Actions.

## Pendências operacionais, não de implementação deste bloco

- Confirmar `PARTNER_PROGRAM_ENCRYPTION_KEY` no ambiente hospedado antes de homologar payout real.
- Publicar conteúdo real da Faculdade; o backend está pronto, mas a base pode continuar sem cursos publicados.
- Fazer homologação E2E real de cadastro → pending → aprovação → link → atribuição → financeiro → payout quando o ambiente hospedado estiver no SHA atual.
- Confirmar que o hosting puxou a `main`; merge no GitHub e deploy hospedado são estados separados.
