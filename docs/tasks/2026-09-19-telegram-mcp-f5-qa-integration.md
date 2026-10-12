# F5 — MKTOn Telegram MCP — Integração, QA, Hardening e Release

Chave: `MKTON-TELEGRAM-MCP-F5-QA-INTEGRACAO`  
Branch: `work/telegram-mcp-f5-qa-integration`  
Status inicial: 🟡 ESCOPO CRIADO / AGUARDA ARTEFATOS, MAS PODE PREPARAR QA

## Objetivo

Integrar F1–F4, resolver gaps reais entre contratos, executar QA ponta a ponta, hardening, observabilidade, deploy na nova VPS Hetzner e smoke operacional. Esta é a única frente autorizada a declarar o ciclo inteiro pronto.

## Responsabilidades

- acompanhar contratos das F1–F4 sem bloquear preparação;
- preparar matriz E2E desde o início;
- integrar branches sem apagar trabalho;
- resolver conflitos preservando responsabilidades;
- validar migrations e runtime;
- validar webhook real do `@mktoncontrol_bot`;
- validar identidade multi-tenant;
- validar Hermes + Executor + MCP;
- validar GitHub, Supabase e MKTOn;
- validar mídia;
- validar confirmação;
- validar retries/idempotência;
- validar revogação;
- observabilidade;
- métricas de fila/erro/latência;
- alertas mínimos;
- runbook;
- backup/restore;
- deploy;
- smoke pós-deploy;
- documentação final e handoff.

## Regra de integração

F5 não deve reimplementar F1–F4 por preferência pessoal. Só corrige:
- bug reproduzível;
- quebra de contrato;
- falha de segurança;
- incompatibilidade de integração;
- requisito do master não atendido.

## Matriz E2E obrigatória

1. `/start` usuário não vinculado;
2. pareamento por código/deep link;
3. replay do código;
4. usuário vinculado com um workspace;
5. usuário com múltiplos workspaces;
6. troca autorizada de workspace;
7. tentativa cross-workspace;
8. leitura MKTOn;
9. escrita reversível MKTOn;
10. leitura GitHub;
11. escrita GitHub autorizada;
12. consulta Supabase autorizada;
13. escrita Supabase permitida por tool específica;
14. ação HIGH_IMPACT sem confirmação;
15. ação HIGH_IMPACT com confirmação;
16. confirmação expirada/replay;
17. texto;
18. áudio;
19. foto/imagem;
20. vídeo;
21. documento;
22. update duplicado Telegram;
23. retry downstream;
24. timeout;
25. cancelamento;
26. conector offline;
27. restart de serviço;
28. restart da VPS;
29. revogação de usuário;
30. rotação de secret;
31. tentativa de prompt injection;
32. tentativa de pedir/exfiltrar secret;
33. tentativa de shell/SQL arbitrário;
34. logs sem segredo;
35. auditoria completa por correlation id.

## Gates para verde final

- todas as quatro frentes em verde técnico próprio ou gaps absorvidos e documentados pela F5;
- migrations aplicadas somente no Supabase canônico;
- build/testes necessários aprovados;
- zero secret versionado;
- zero falha crítica de isolamento;
- zero execução destrutiva sem confirmação;
- deploy real na nova VPS;
- webhook real funcional;
- smoke pós-deploy aprovado;
- runbook e rollback documentados;
- status atualizado em `PROJECT_STATUS.md`.

## Resultado final esperado

Usuário autorizado envia mensagem ao `@mktoncontrol_bot`, o sistema resolve sua identidade e workspace, Hermes entende a intenção, o Executor aplica segurança/permissões, chama a tool MCP correta, registra toda a execução e devolve uma resposta útil no Telegram — sem vazar segredos, cruzar clientes ou duplicar efeitos.
