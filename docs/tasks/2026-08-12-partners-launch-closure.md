# Partners — fechamento de lançamento

Data: 2026-08-12
Status do código deste bloco: 7/7 concluído

## Regra canônica consolidada

1. Cadastro de Afiliado/Partner libera acesso imediatamente.
2. Não existe confirmação de e-mail como gate inicial de entrada no programa.
3. Aprovação comercial continua separada do acesso: enquanto `pending`, a pessoa entra na plataforma, mas não divulga nem recebe comissões.
4. Super admin possui Central Partners própria e pode visualizar Área de Afiliado e Área de Partner sem perder um papel comercial real que também possua.
5. Afiliado aprovado vê e pode copiar/testar o link real de indicação.
6. Simulador público atende Afiliado e Partner.
7. Validações sensíveis ficam concentradas no Financeiro: sessão autenticada + CPF/CNPJ, titular e PIX verificados antes de solicitar pagamento.

## Implementação deste bloco

### Cadastro imediato

`src/routes/api/public/partners/register.ts`
- substituído `inviteUserByEmail` por criação direta de usuário;
- cadastro recebe senha;
- conta é criada para acesso imediato;
- papel comercial nasce `pending`;
- código de indicação nasce inativo até aprovação;
- nenhuma instrução de ativação por e-mail é enviada pelo fluxo de Partners.

`src/routes/partners.tsx`
- senha + confirmação de senha no cadastro;
- login automático após cadastro;
- redirecionamento para `/contas`;
- fallback para login caso a sessão não seja criada automaticamente.

### Simulador

`src/routes/partners.tsx`
- alternância Afiliado / Partner;
- Afiliado: 50% primeira venda + 15% recorrência;
- Partner: faixa-base 35% primeira venda + 35% recorrência;
- texto explica que a recorrência do Partner acompanha sua faixa vigente;
- períodos: mensal, trimestral, semestral e anual.

### Financeiro

`src/routes/api/partners/request-payout.ts`
- nova barreira server-side para solicitação de pagamento;
- exige sessão válida;
- exige perfil de pagamento com `verification_status = verified`;
- somente depois chama `partner_program_request_payout` com contexto autenticado do usuário.

`src/routes/partners.financeiro.tsx`
- saque passa pela rota server-side;
- documento/PIX não bloqueiam o uso normal da plataforma;
- UI deixa claro que a validação é necessária somente para receber valores.

## Itens já fechados nos blocos imediatamente anteriores

- Copiloto + modo implementação não aparecem em Partners/cadastro/rotas externas.
- papel comercial real do super admin tem prioridade sobre preview automático.
- `/contas` mostra Central Partners para super admin e Áreas de Afiliado/Partner conforme papel/preview.
- Afiliado aprovado possui link real com ações de copiar e testar.
- nomenclatura pública usa `Afiliado` em português.

## Validação

Teste dedicado: `src/lib/partners-launch-closure.test.ts`.

O teste protege:
- ausência de `inviteUserByEmail` no cadastro Partners;
- login imediato após criação;
- separação entre acesso e aprovação comercial;
- simulador dos dois papéis e percentuais vigentes;
- saque protegido no servidor por sessão + perfil financeiro verificado;
- manutenção da Central/preview de super admin.

GitHub Actions só é considerado validado quando houver execução real de steps. Runner vazio/`steps: []` continua classificado como bloqueio externo e não como teste verde.

## Produção / ambiente

- Este bloco não cria DDL nem migration nova.
- `PARTNER_PROGRAM_ENCRYPTION_KEY` continua sendo requisito operacional para salvar CPF/CNPJ e PIX com criptografia.
- A publicação hospedada deve ser confirmada separadamente do merge na `main`.

## Reconciliação histórica de migrations

As migrations-base históricas do programa já existem no banco de produção, porém parte da sequência antiga ainda precisa permanecer reconciliada no repositório sem risco de reaplicação. Essa reconciliação é de fonte/histórico e não deve executar SQL retroativo em produção.
