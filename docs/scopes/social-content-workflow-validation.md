# Validação — Social Content Workflow

Este fechamento usa duas camadas de validação:

- testes focados de matching de automação e contrato de prompts do carrossel;
- build de produção completo via GitHub Actions.

Workflow: `.github/workflows/social-content-workflow-ci.yml`.

Critério de merge: resolver divergência com `main`, build verde e testes verdes. Se o GitHub não iniciar o job por bloqueio externo de billing/spending limit da conta, registrar o bloqueio como infraestrutura e não reportar CI verde.
