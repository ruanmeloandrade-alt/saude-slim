# Saúde Slim: bloco 12 de segurança e liberação para conferência final

## Estado: 🟢 publicado, conferido e liberado para o aceite final do usuário

Pedido de 18/10/2026 às 14h28 de Brasília: o usuário esclareceu que o documento de venda deve ser apenas um comprovante comercial, retirou a necessidade de emissão fiscal autorizada e pediu finalizar a segurança do sistema e liberá-lo para testar tudo e encerrar o projeto.

## Fonte de verdade e autorização

Repositório exclusivo ruanmeloandrade-alt/saude-slim, Supabase vyzvfcgpjjzvcjegzzza, domínio slimesaude.com. Base documental 349e89c168cd237f869b2fd98fef347b3e17cbdf, árvore b6180682402718f81a8029290a18424b5499c709; código publicado f7f75c69bef8aa6af0f5b1e3c5b57396e6a1893b, produção restauracao/sistema-completo-20261014. Branch deste bloco fix/slim-security-release-20261018.

AGENTS.md foi lido; as referências históricas a MKTOn/Lovable e outros projetos não se aplicam à Saúde Slim independente. Proibição de Lovable, Vercel e GitHub Actions mantida. Cora congelado. PROJECT_STATUS.md ausente; OPERATION_STATUS.md e os escopos da Slim são a referência. Publicação automática após validação autorizada pelo usuário, sem aguardar sua conferência.

Produção confirmada online no começo: Railway fe2bfd76 SUCCESS, quatro serviços online, nenhuma operação pendente. Supabase ACTIVE_HEALTHY, PostgreSQL 17. Consulta agregada encontrou uma conta, uma sessão nativa e zero fatores verificados. Nenhuma identidade, segredo, senha, token ou fator será lido ou alterado para QA.

## Fiscal: 🟢 encerrado conforme decisão do usuário

Comprovante comercial é a entrega final desejada. Emissão real de NF-e foi retirada e não é bloqueio da entrega. Preservar o PDF comercial já implementado, sem emissor, contratação ou operação fiscal.

## Regra de segurança desta entrega

- Login real por e-mail/senha e autorização por conta/empresa continuam sendo a base de acesso.
- Cadastro de autenticador permanece uma escolha explícita do usuário. Quando houver qualquer fator nativo verificado, a aplicação exige uma sessão confirmada em dois fatores antes de liberar operações privadas. Fator apenas pendente não bloqueia o acesso convencional.
- A regra deve existir no navegador, nas funções/APIs do servidor e no banco. Uma tela de desafio sozinha não encerra esta frente.
- Não cadastrar fator, alterar senha, encerrar sessão ou enviar código/e-mail de QA para a conta real. Preservar a sessão existente, dado que ela não possui fator verificado.
- O estado de segurança deve vir de sessão/claims verificadas e fatores nativos, nunca user_metadata, preferências locais ou flags que ignoram falhas.
- Métodos e controles avançados sem implementação completa não devem aparecer como proteção ativa nem poder retornar sucesso fictício. O recorte entregue é autenticação, autorização existente, sessão e TOTP aplicado; SMS, passkeys, recuperação por códigos, aprovação de dispositivos, lista de IPs e políticas administrativas extras não serão apresentados como recursos implementados por inferência.
- Falha ao verificar segurança mantém operações privadas bloqueadas com orientação clara. Não criar bypass ou fallback que libere acesso.

## Frente A: entrada, recuperação e desafio

AuthGate só pode montar consumidores privados depois de confirmar sessão e regra de MFA. Reutilizar o controller nativo com proteção de import SSR. Com fator verificado e AAL1, exibir desafio de seis números para fator existente; sem cadastro/remoção no gate. Conta sem fator ou AAL2 confirmado entra normalmente. Fator de tipo não suportado gera bloqueio claro, sem alternativa falsa.

Tratar erro, prazo, tentativa incerta, clique repetido, mudança de conta/sessão e renovação na mesma sessão. Reconsultas dos eventos do SDK devem acontecer fora de seu callback síncrono. Manter o fluxo de recuperação de senha e impedir redirecionamento antecipado de PASSWORD_RECOVERY ou mode=recovery; recuperação não remove nem contorna MFA. Preservar páginas públicas, links de convite, navegação/retorno seguro e anchors dos transforms existentes.

Áreas: routes/__root.tsx, auth.tsx, login.tsx e componentes/helpers focais de entrada. Movimentar consumidores operacionais para dentro do gate sem iniciar bots ou ações durante renderização.

## Frente B: regra no banco

Implementar predicado privado de sessão/MFA, com privilégios mínimos e search_path fixo. Verificar a sessão nativa e o usuário do JWT e exigir AAL2 quando existir fator verificado. Contas sem fator permanecem com acesso convencional.

Contrato para o servidor: public.slim_assert_session_security(), sem argumentos, SECURITY INVOKER, retorno boolean true somente quando autorizado. Erro 42501/SLIM_MFA_REQUIRED para fator exigido e 42501/SLIM_SESSION_INVALID para sessão inválida. Não aceitar IDs arbitrários do cliente.

Cobrir chamadas diretas de Data API e RPCs SECURITY DEFINER por mecanismo central compatível, preservando qualquer pre-request anterior. Cobrir Storage/Realtime com políticas restritivas onde aplicável; não tratar o pre-request de PostgREST como proteção desses serviços. Inspecionar funções expostas e privilégios reais antes de escolher o menor conjunto suficiente. Não bloquear workers service_role nem fluxos públicos legítimos. Não alterar dados comerciais, contas, fatores ou sessões. Nenhuma política aditiva pode ampliar acesso.

Criar migration pelo CLI conforme capacidade disponível, testar em PostgreSQL/PGlite isolado e versionar antes da instalação. Conferir políticas, funções, grants, dados agregados/hashes e advisors antes/depois. Instalar somente pelo root após integração validada.

## Frente C: funções/APIs

Depois de validar o JWT, chamar a regra central com cliente publishable portando o JWT original, antes de executar lógica privada ou acessar service role. Aplicar no middleware comum, no validador bearer e nos poucos endpoints com validação manual encontrados. Nunca aplicar uma regra de usuário globalmente ao cliente service role de workers/webhooks.

RPC deve confirmar data === true. Prazo finito, sem repetição automática; distinguir desafio exigido de sessão inválida e indisponibilidade, sem expor payloads de erro ou dados sensíveis. Preservar contexto de usuário/empresa, permissões, preços e transportes existentes.

## Root: integração, apresentação e entrega

Revisar a apresentação/handlers de controles de segurança não implementados para impedir falso sucesso. Integrar testes focados aos gates atuais sem remover verificações. Conferir a configuração observável do Auth e registrar qualquer recurso dependente de plano/provedor sem contratá-lo por conta própria.

Baseline de advisors: quatro INFO de ledgers privados com RLS sem política deliberadamente fechados, quatro WARN de RPCs Inbox DEFINER autenticadas e um WARN de proteção contra senhas vazadas desabilitada. Não tratar essas mensagens como prova de brecha ou resolver só silenciando o advisor.

## Critérios de aceite e publicação

- Sem sessão, sessão inválida/revogada ou MFA exigido sem confirmação: nenhum dado/efeito privado é liberado pelos caminhos abrangidos.
- Sem fator verificado: login/sessão existentes continuam funcionando. Com fator confirmado: AAL1 bloqueia e AAL2 correto libera, preservando as regras de empresa e papel.
- Testes reais dos handlers e SQL em ambiente isolado, incluindo atores/empresas diferentes, erro de leitura, claims alteradas, RPC DEFINER, Storage/Realtime conforme políticas e service worker.
- Compilação completa isolada com transforms; revisar componentes reais em computador/celular com dados sintéticos. Nenhum teste de cliente real, convite, mensagem, bot, conta, fator ou venda.
- Versionar arquivos completos, validar igualdade de fontes, instalar migration validada e promover por CAS sem reescrever história. Observar Railway SUCCESS, healthcheck e domínio.
- Atualizar o semáforo com comprovante concluído, segurança com o recorte/evidências efetivamente entregue e conferência final do usuário em amarelo. Recursos fora do recorte devem permanecer descritos honestamente, sem chamar todo o sistema de invulnerável.

## Implementação e validação direta

As três frentes estão integradas ao gate existente, sem retirar testes anteriores. Gate de entrada: 27 casos; APIs/middleware: 34; troca de senha: 17; apresentação de Segurança: 10; PostgreSQL/PGlite: 12. Os 100 casos específicos são isolados/sintéticos. As regressões existentes de autenticação (11) e gestão MFA (39) também passaram antes da compilação completa.

A reconsulta em foco/renovação preserva a árvore React já autorizada da mesma conta/sessão e o rascunho; troca de conta/sessão, falha ou desafio remove essa autorização. Primeiro acesso nunca monta conteúdo privado antes da confirmação. O teste Chromium com filho stateful comprovou um único mount durante foco e TOKEN_REFRESHED, descarte ao trocar de conta e bloqueio no logout. A recuperação de senha mantém sua intenção depois de PASSWORD_RECOVERY e tem contraste legível.

O painel de Segurança monta somente senha nativa, aplicativo autenticador e preferência local de inatividade. A senha usa um único PUT nativo com publishable/JWT, valida ator/sub/session_id antes do envio, prazo total de 8 segundos e corpo limitado a 128 KiB; recibo divergente ou falha incerta não declara sucesso. Os handlers antigos de MFA por e-mail/flags e códigos de recuperação ficam explicitamente indisponíveis, sem envios ou gravações. A página Sessões monta somente a sessão deste navegador e saída nativa scope local, sem apresentar o ledger antigo de heartbeat como sessões nativas. A inatividade também encerra somente a sessão local.

Migration gerada pelo CLI Supabase 2.45.0: supabase/migrations/20261018175307_slim_session_security_enforcement.sql. Ela não altera contas, fatores, sessões ou registros comerciais. Confere auth.sessions id/user_id/not_after, banimento/exclusão do usuário e qualquer fator verificado. O preflight protege hook anterior e schema esperado. Políticas restritivas complementam o pre-request nas tabelas com RLS, Storage e Realtime; regras originais de empresa e papel permanecem obrigatórias.

Baseline remoto imediatamente anterior: 1 usuário, 1 sessão, 0 fatores, 26 leads, 2 pedidos, 0 cadastros de grupos, 125 políticas em public/storage/realtime e hash de políticas originais e04ec8703e39f50408b2c714f07246e0. O catálogo confirmou as colunas nativas e nenhuma configuração pgrst.* em pg_db_role_setting. Uma consulta agrupada inicial da frente B ficou travada por 1.060 segundos e foi interrompida sem resultado; consultas curtas independentes obtiveram o catálogo necessário. Nenhuma mutação de dados foi usada como alternativa.

## Limites do recorte entregue

O cadastro de autenticador não é obrigatório para todas as contas. Quando confirmado, o fator é exigido pelos caminhos protegidos. SMS, passkeys, códigos de recuperação, aprovação de dispositivos, políticas administrativas extras e lista/revogação nativa de outros dispositivos não foram habilitados. O plano Supabase da organização é Free; o advisor de senha vazada permanece porque o recurso nativo exige Pro ou superior, conforme https://supabase.com/docs/guides/auth/password-security. Nenhuma assinatura ou configuração paga foi contratada.

URLs de mídia já assinadas permanecem válidas até sua expiração e a autorização de canais Realtime já estabelecidos segue o cache do serviço. A verificação instalada controla novos acessos/autorização e não afirma revogação retroativa instantânea desses portadores. Workers service_role e fluxos públicos legítimos permanecem com seus contratos existentes.

Não houve login real, mudança de senha, cadastro de fator, revogação de sessão, convite, pedido, bot ou envio de mensagem pela equipe durante este bloco. Os testes autenticados finais pertencem ao usuário. A conclusão de emissão fiscal significa aceite do comprovante comercial existente, sem alegação de nota autorizada.

## Instalação do banco e promoção da versão

Código funcional versionado em eb9ca08e8edc7e16158fbc8c51a34d3d48100d94, árvore 802cb3cd8827f72118ecf6cd374bed4f8a8d3900. São 32 arquivos alterados/novos. A compilação completa npm run build em cópia isolada passou na primeira execução, com 1.314 fontes não documentais byte a byte iguais às enviadas ao GitHub. Os gates anteriores continuam ativos.

A primeira chamada de instalação retornou Invalid or expired requestState. A reconciliação somente leitura confirmou ausência da função, zero políticas novas e nenhuma migration registrada antes da repetição. A chamada seguinte instalou a migration slim_session_security_enforcement sob versão 20261018180658. O schema cache do PostgREST recebeu reload schema após a instalação; isso é operação de atualização de cache, sem alteração de dados.

A conferência remota confirmou 66 políticas novas, todas RESTRICTIVE, e as 125 políticas anteriores com o mesmo hash e04ec8703e39f50408b2c714f07246e0. As quatro funções têm os mesmos corpos da migration testada, search_path fixo, privilégios mínimos e o contrato INVOKER/DEFINER esperado. O hook public.slim_check_api_request foi instalado preservando as demais configurações do authenticator. Usuários, sessão, fatores, leads, pedidos e cadastro de grupos mantiveram as contagens do baseline. Nenhuma conta precisou de cadastro forçado de MFA.

Advisors às 18:09:33 UTC: os mesmos quatro INFO de ledgers privados deliberadamente fechados, quatro WARN das RPCs Inbox existentes e um WARN de proteção de senha vazada. Não apareceram novos avisos. As RPCs Inbox autenticadas agora passam pela verificação central antes de sua execução; seus guards anteriores de empresa/ator continuam obrigatórios. Nenhum advisor foi silenciado para mudar a cor do semáforo.

A versão foi promovida por CAS à branch restauracao/sistema-completo-20261014, sem reescrever história. Railway iniciou o deployment 2c72ee70-bd81-486f-94f9-74d0389f7a95 em 18/10/2026 às 18:09:19 UTC. O resultado terminal, domínio e healthcheck foram confirmados no encerramento abaixo.

## Revisão final no navegador isolado

Os mesmos componentes reais foram repetidos com o CSS do build final: styles-NNUnQaCy.css, SHA-256 097adcf892fed44acf55c7e03d67810de776d4a9df8e24e1df3d49f4fb6164a7. Desafio/recuperação passaram nos oito casos interativos; Segurança foi renderizada em 1440 e 390 px, com campos vazios/preenchidos; Sessões passou cinco casos com saída local sintética. As dez capturas entre as frentes foram revistas, sem transbordamento, erros JavaScript ou chamadas externas. Senhas permaneceram mascaradas; troca de conta descarta rascunhos antigos e foco/renovação da mesma sessão preservam o trabalho.

As capturas e métricas foram geradas em /tmp/slim-auth-gate-block12-qa e /tmp/slim-security-release-render-20261018, usando autenticação e transporte sintéticos. Os resultados e hashes relevantes ficam registrados neste documento; não representam teste na conta autenticada do usuário.

## 🟢 Publicação e liberação confirmadas

Deployment 2c72ee70-bd81-486f-94f9-74d0389f7a95 concluiu SUCCESS em 18/10/2026 às 18:14:09.294 UTC; healthcheck 1/1 aprovado às 18:14:06.151384376 UTC. Conferência às 18:16:26 UTC: quatro serviços online, uma réplica cada, zero falhas, zero avisos operacionais e pendingWork vazio. A versão funcional publicada é eb9ca08e8edc7e16158fbc8c51a34d3d48100d94.

O smoke HTTP de https://slimesaude.com passou: página raiz HTTP 200 e referência ao estilo final; os quatro CSS são byte a byte iguais aos aprovados. GET sem autenticação em /api/partners/payment-profile e /api/partners/admin/payment-profiles devolveu HTTP 401 com JSON, antes de acesso a dados. Esse smoke não usou a sessão do usuário.

O sistema está liberado para a conferência geral do usuário. Não há pendência de emissor fiscal no escopo aceito; o comprovante comercial existente está concluído. A conferência final de mídia/grupos, checkout/pedidos e convites permanece amarela até aceite real, sem bloquear o acesso às funções publicadas. SalesBots, gatilhos, Públicos/Reativação e Copiloto conservam os aceites reais anteriores. Não foi reintroduzida IA autônoma nos grupos.

Este checkpoint final é documental na branch fix/slim-security-release-20261018; não inicia outro deploy só para trocar o estado do relatório. A versão funcional e o serviço em produção permanecem os confirmados acima.
