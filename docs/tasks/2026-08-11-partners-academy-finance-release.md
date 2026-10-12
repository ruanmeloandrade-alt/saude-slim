# Partners — Faculdade + Financeiro — 2026-08-11

## Objetivo
Fechar duas superfícies ainda presas nas branches antigas do ecossistema Partners, reutilizando o backend já implantado e sem trazer placeholders ou marketplace.

## Escopo deste bloco — 3/3
1. Faculdade Partners conectada ao backend real — concluído.
2. Financeiro Affiliate/Partner conectado a perfil de pagamento seguro e payout manual — concluído.
3. Navegação dos painéis para Faculdade/Financeiro — concluído.

## Faculdade Partners
- rota `/partners/faculdade`;
- lê cursos, módulos e aulas publicados reais;
- lê progresso real via `partner_program_my_academy_progress`;
- conclui aula via `partner_program_complete_academy_lesson`;
- exibe certificado somente quando o backend realmente o emitir;
- banco atual possui 0 cursos publicados, portanto o estado vazio é real e não há conteúdo fictício.

## Financeiro
- rota `/partners/financeiro` para Affiliate e Partner aprovados;
- endpoint server-side `/api/partners/payment-profile`;
- CPF/CNPJ e PIX são enviados ao serviço de criptografia server-side e nunca retornam em claro;
- interface mostra somente tipo/últimos 4 dígitos/status de verificação;
- qualquer alteração dos dados volta para verificação conforme regra do backend;
- solicitação de payout usa `partner_program_request_payout` e permanece manual nesta fase;
- `PARTNER_PROGRAM_ENCRYPTION_KEY` continua sendo requisito obrigatório do ambiente server-side.

## Fora deste bloco
- marketplace continua fora da Fase 2;
- conteúdo pedagógico não é inventado automaticamente;
- payout automático/Stripe Connect não entra nesta fase;
- Central Partners/admin completa será tratada em bloco posterior se ainda não estiver reconciliada na main.

## Regressão
`src/lib/partners-academy-finance-release.test.ts` protege conexão real, ausência de mocks e requisitos de segurança.

## Próximo passo
Publicar este bloco na `main`, verificar o estado do runner e então reconciliar a Central Partners administrativa/painéis restantes da PR visual antiga sem carregar a branch divergente.
