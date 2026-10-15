# Saúde Slim: retomada da correção IA

Base: e386fa4416e8bf5bbf80dca333f720a5e0522b4b. Branch operacional restauracao/sistema-completo-20261014. Somente repositório saude-slim e Supabase vyzvfcgpjjzvcjegzzza. Main, Evolution, DNS, Harpia e MktOn original não foram alterados.

## Diagnóstico confirmado

O log de produção mostrou set_integration_secret inexistente no banco. A implementação da tela valida a chave OpenAI antes dessa chamada. As funções get/set e a tabela integrations faltavam. O resolvedor descartava erros das RPCs, confundindo falha de infraestrutura com ausência de chave. Também faltavam ai_agent_settings, ai_agent_conversations e support_robot_messages.

## Banco já aplicado e validado

As migrations 20261015024506 e 20261015025453 restauram cofre criptografado, metadados e persistência de IA. Nesta retomada sua presença foi reconfirmada. Todas as tabelas públicas continuam com RLS habilitada.

A validação anterior efetivamente executou, sob authenticated e service_role, gravação, leitura, atualização sem duplicação, rejeição de chave incorreta, isolamento de workspace, bloqueio anônimo e rollback. Para IA, testou configuração, histórico, criação/edição/ativação/desativação/exclusão do agente e reset, com rollback integral. Não enviou WhatsApp nem consumiu a API OpenAI.

## Código desta publicação

Restaura o trabalho pendente de workspace-ai-key.server.ts e integration-vault.ts, junto das duas migrations. Erros do cofre são explícitos e não provocam fallback. A Saúde Slim não usa a chave de conta MktOn/Lovable herdada. Logs do cofre não imprimem payloads, respostas brutas ou segredos. Mensagem identificada como Saúde Slim.

Os nove testes de regressão do resolvedor usam seu código real e respostas de transporte controladas. Passaram localmente em Node 22.16 no trabalho anterior. Agora são executados também antes do build junto dos testes existentes de Inbox e salvamento manual/120 segundos. Nenhuma versão de dependência foi alterada.

## Auditoria do menu

O script audit-saude-slim-menu.mjs percorre as 16 frentes operacionais na ordem recebida, comparando referências estáticas a tabelas/RPCs com o snapshot do banco. Não utiliza dados pessoais, chaves ou rede. Referências transitivas incluem recursos opcionais e precisam de análise do ponto de chamada; não equivalem a erros obrigatórios em toda tela. A lista inicial e a ordem estão no arquivo saude-slim-ia-menu-audit-20261015.md.

## Limites de aceite

Na última consulta, nenhuma integração real tinha sido salva. A tentativa anterior falhou antes da persistência. Não declarar resposta OpenAI ou atendimento WhatsApp IA homologados sem teste real autorizado. Banco, testes de código, build e HTTP não substituem navegação autenticada nem homologação integral dos módulos. A publicação e seu resultado devem ser conferidos no Railway antes de reportar sucesso.
