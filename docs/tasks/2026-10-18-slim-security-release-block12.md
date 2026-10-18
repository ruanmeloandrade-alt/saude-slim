# Saúde Slim: bloco 12 de segurança e liberação para conferência final

## Estado: 🟡 escopo registrado antes da implementação

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
