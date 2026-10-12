# Kit de App Review — Meta global MKTOn

Data: 2026-08-11
Status: material preparado para uso pelo owner; preencher a Meta **um cartão por vez**.
Task principal: `docs/tasks/2026-08-11-meta-global-production-config.md`

## Regra de uso
Este arquivo é material de apoio para não reescrever justificativas em novos chats. Ele NÃO significa que a revisão foi enviada ou aprovada. Antes de colar qualquer texto, confirmar que a permissão continua na solicitação e que a tela da Meta pede aquele campo.

Não reintroduzir permissões removidas. Não migrar para `instagram_business_*` sem uma task específica de migração do fluxo atual de Facebook Login.

---

## 1. `pages_show_list`

### Como a MKTOn usa
A MKTOn usa `pages_show_list` para apresentar ao usuário autenticado a lista de Páginas do Facebook que ele administra. O usuário escolhe explicitamente quais Páginas deseja conectar ao workspace da MKTOn; a plataforma não seleciona nem conecta Páginas sem essa autorização.

### Como o revisor testa
1. Entrar na MKTOn com a conta de teste.
2. Abrir Integrações → Meta.
3. Iniciar o OAuth Meta.
4. Autorizar a conta Facebook de teste.
5. Voltar à MKTOn e abrir o seletor de ativos.
6. Confirmar que as Páginas administradas pela conta aparecem para seleção.

### Screencast
Mostrar login → Integrações → Meta → OAuth → retorno à MKTOn → lista de Páginas → seleção de uma Página.

---

## 2. `pages_read_engagement`

### Como a MKTOn usa
A MKTOn usa `pages_read_engagement` para consultar informações e dados de interação das Páginas que o próprio usuário autorizou, necessários aos módulos de Social Media, relatórios e atendimento. A leitura fica limitada aos ativos selecionados pelo workspace.

### Como o revisor testa
1. Conectar uma Página no fluxo Meta.
2. Abrir uma área da MKTOn que exiba dados da Página/engajamento.
3. Confirmar que os dados correspondem à Página conectada.

### Screencast
Pode reutilizar o vídeo de Pages/Social Media, desde que mostre os dados lidos após a conexão.

---

## 3. `pages_manage_posts`

### Como a MKTOn usa
A MKTOn usa a permissão `pages_manage_posts` para permitir que usuários autorizados publiquem e gerenciem conteúdos nas próprias Páginas do Facebook que conectaram voluntariamente à plataforma. Essa permissão é utilizada no módulo de Social Media da MKTOn para criar, programar, editar e publicar posts em ativos administrados pelo próprio cliente.

### Como o revisor testa
1. Acesse a MKTOn e faça login na conta de teste fornecida.
2. Vá até Integrações e conecte uma conta Meta/Facebook.
3. Autorize uma Página administrada pela conta de teste.
4. Acesse o módulo Social Media.
5. Crie uma publicação para a Página conectada.
6. Publique ou programe o conteúdo.
7. Confirme que o conteúdo foi criado na Página autorizada.

### Screencast
Mostrar o fluxo completo acima, incluindo o conteúdo aparecendo na Página de teste.

---

## 4. `pages_manage_metadata`

### Como a MKTOn usa
A MKTOn usa `pages_manage_metadata` para vincular as Páginas autorizadas ao aplicativo da MKTOn e assinar os eventos de webhook necessários aos recursos de Messenger, Lead Ads e interações suportadas. A assinatura é realizada somente nas Páginas selecionadas pelo usuário.

### Como o revisor testa
1. Conectar a Página pela integração Meta.
2. Selecionar a Página no picker da MKTOn.
3. Concluir a sincronização.
4. Enviar um evento suportado para a Página de teste, como uma mensagem no Messenger.
5. Confirmar que o evento chega à MKTOn.

### Screencast
Pode ser demonstrada junto do vídeo de Messenger, mostrando Página conectada e recebimento de evento após a assinatura.

---

## 5. `pages_manage_engagement`

### Como a MKTOn usa
A MKTOn usa `pages_manage_engagement` para permitir que usuários autorizados tratem interações relacionadas ao conteúdo das próprias Páginas conectadas, como comentários e respostas, dentro dos fluxos de Social Media/CRM suportados pela plataforma.

### Como o revisor testa
1. Conectar uma Página de teste.
2. Gerar uma interação em um conteúdo dessa Página.
3. Abrir a interação na MKTOn.
4. Executar a ação de gerenciamento disponível no produto e confirmar o resultado na Página.

### Screencast
Mostrar a interação sendo gerada fora da MKTOn e tratada dentro da plataforma.

---

## 6. `pages_messaging`

### Como a MKTOn usa
A MKTOn é uma plataforma SaaS de CRM, automação e atendimento omnichannel. A permissão `pages_messaging` é usada para permitir que empresas que conectam voluntariamente suas Páginas do Facebook à MKTOn recebam e respondam mensagens do Messenger dentro da caixa de entrada unificada da plataforma. A MKTOn não acessa Páginas sem autorização do administrador e utiliza os dados para disponibilizar atendimento, histórico de conversa, automações e CRM ao próprio negócio conectado.

### Como o revisor testa
1. Acesse a MKTOn com a conta de teste.
2. Vá em Integrações → Meta e conecte a Página de teste.
3. De outra conta, envie uma mensagem para essa Página pelo Messenger.
4. Abra o Inbox da MKTOn e confirme a mensagem recebida.
5. Responda pela MKTOn.
6. Confirme a resposta no Messenger.

### Screencast
Vídeo dedicado recomendado: Página conectada → mensagem externa → Inbox MKTOn → resposta → Messenger.

---

## 7. `instagram_basic`

### Como a MKTOn usa
A MKTOn usa `instagram_basic` para identificar a conta profissional do Instagram vinculada à Página autorizada e carregar as informações básicas necessárias para que o usuário selecione e conecte essa conta ao próprio workspace.

### Como o revisor testa
1. Conectar uma Página que possua conta profissional do Instagram vinculada.
2. Concluir a sincronização Meta.
3. Confirmar que a conta Instagram aparece identificada na MKTOn.

### Screencast
Pode ser o início do vídeo de Instagram, mostrando conexão e identificação da conta profissional.

---

## 8. `instagram_manage_comments`

### Como a MKTOn usa
A MKTOn usa `instagram_manage_comments` para receber e tratar comentários relacionados aos conteúdos das contas profissionais de Instagram autorizadas, permitindo registrar a interação no CRM e executar os fluxos de atendimento/automação disponibilizados ao próprio negócio conectado.

### Como o revisor testa
1. Conectar a conta Instagram profissional de teste.
2. Criar um comentário em uma publicação dessa conta por outro usuário.
3. Confirmar a entrada da interação na MKTOn.
4. Executar a ação suportada de tratamento/resposta, quando disponível.

### Screencast
Mostrar comentário externo → interação na MKTOn → tratamento/resposta suportada.

---

## 9. `instagram_manage_messages`

### Como a MKTOn usa
A MKTOn usa `instagram_manage_messages` para permitir que empresas conectem voluntariamente suas contas profissionais do Instagram e centralizem mensagens do Instagram Direct no Inbox da plataforma. As mensagens são usadas para atendimento, histórico do CRM e automações configuradas pelo próprio negócio conectado.

### Como o revisor testa
1. Conectar a conta profissional do Instagram de teste.
2. De outra conta, enviar uma DM para o Instagram conectado.
3. Confirmar que a DM aparece no Inbox da MKTOn.
4. Responder pela MKTOn.
5. Confirmar a resposta no Instagram Direct.

### Screencast
Vídeo dedicado recomendado: Instagram conectado → DM externa → Inbox → resposta → Direct.

---

## 10. `instagram_manage_insights`

### Como a MKTOn usa
A MKTOn usa `instagram_manage_insights` para consultar métricas das contas e conteúdos de Instagram autorizados e apresentar esses dados nos dashboards e relatórios do próprio cliente.

### Como o revisor testa
1. Conectar uma conta Instagram profissional com dados disponíveis.
2. Abrir a área de métricas/Social Media da MKTOn.
3. Selecionar a conta conectada.
4. Confirmar a apresentação de métricas reais da conta autorizada.

### Screencast
Mostrar seleção da conta e painel de métricas alimentado pela conta de teste.

---

## 11. `instagram_content_publish`

### Como a MKTOn usa
A MKTOn usa `instagram_content_publish` para permitir que usuários autorizados criem e publiquem conteúdo nas próprias contas profissionais do Instagram conectadas, usando o módulo Social Media da plataforma.

### Como o revisor testa
1. Conectar a conta Instagram profissional de teste.
2. Abrir Social Media.
3. Criar conteúdo para a conta conectada.
4. Publicar/programar conforme o fluxo disponível.
5. Confirmar o conteúdo na conta Instagram de teste.

### Screencast
Mostrar criação na MKTOn → publicação → conteúdo visível na conta de teste.

---

## 12. `ads_read`

### Como a MKTOn usa
A MKTOn usa `ads_read` para consultar contas de anúncios, campanhas, conjuntos de anúncios, anúncios e métricas das contas Meta Ads que o usuário conecta voluntariamente. Os dados alimentam o módulo Gestor de Tráfego e seus dashboards de desempenho.

### Como o revisor testa
1. Conectar uma conta Meta com acesso à conta de anúncios de teste.
2. Selecionar a conta de anúncios na MKTOn.
3. Abrir o Gestor de Tráfego.
4. Confirmar a listagem de campanhas/conjuntos/anúncios e métricas.

### Screencast
Pode ser combinado com `ads_management` e `read_insights`.

---

## 13. `ads_management`

### Como a MKTOn usa
A MKTOn usa `ads_management` para permitir que usuários autorizados executem ações de gestão sobre campanhas, conjuntos e anúncios das próprias contas Meta Ads conectadas, incluindo as ações efetivamente disponibilizadas no Gestor de Tráfego da MKTOn. Nenhuma ação é executada em uma conta que não tenha sido previamente autorizada e selecionada pelo usuário.

### Como o revisor testa
1. Conectar e selecionar a conta de anúncios de teste.
2. Abrir Gestor de Tráfego.
3. Selecionar uma campanha/objeto de teste.
4. Executar uma ação de gestão suportada, como pausar/reativar.
5. Confirmar o novo estado no Meta Ads.

### Screencast
Mostrar antes/depois da ação na MKTOn e confirmação do estado no ativo de teste.

---

## 14. `business_management`

### Como a MKTOn usa
A MKTOn usa `business_management` para identificar os Business Managers e ativos empresariais que o usuário autenticado administra, permitindo vincular corretamente Páginas, contas de anúncios, catálogos e demais ativos autorizados ao workspace do próprio cliente.

### Como o revisor testa
1. Iniciar o OAuth Meta.
2. Autorizar a conta de teste que administra um Business Manager.
3. Retornar à MKTOn.
4. Confirmar que os ativos empresariais autorizados podem ser descobertos/selecionados pela integração.

### Screencast
Pode ser combinado com o vídeo de OAuth + Ads.

---

## 15. `leads_retrieval`

### Como a MKTOn usa
A MKTOn usa `leads_retrieval` para importar os dados de leads gerados por formulários instantâneos de anúncios Meta pertencentes às Páginas/contas autorizadas pelo cliente. Os leads recebidos são enviados ao CRM do próprio workspace para organização comercial e automações configuradas pelo usuário.

### Como o revisor testa
1. Conectar Página/conta de anúncios de teste que possua Instant Form.
2. Enviar um Lead Ad de teste.
3. Aguardar o webhook `leadgen`.
4. Abrir o CRM da MKTOn.
5. Confirmar que o lead foi criado/atualizado com os dados do formulário autorizado.

### Screencast
Vídeo recomendado: Lead Ads Test Tool/lead de teste → webhook → CRM MKTOn com o novo lead.

---

## 16. `read_insights`

### Como a MKTOn usa
A MKTOn usa `read_insights` para consultar métricas e desempenho dos ativos Meta autorizados e exibir essas informações nos relatórios, dashboards e superfícies analíticas disponibilizadas ao próprio cliente.

### Como o revisor testa
1. Conectar uma conta/ativo Meta com dados de desempenho.
2. Abrir o dashboard ou Gestor de Tráfego.
3. Selecionar o período/ativo.
4. Confirmar métricas provenientes do ativo autorizado.

### Screencast
Pode ser reutilizado junto do vídeo de Ads/Insights se a Meta permitir o mesmo arquivo e a evidência estiver clara.

---

## 17. `catalog_management`

### Consumo real auditado
O callback OAuth da MKTOn consulta os catálogos dos Business Managers autorizados por `${businessId}/owned_product_catalogs`, coleta `id`, `name`, `product_count` e `vertical` e registra a lista na metadata da integração. A UI da integração Meta expõe o recurso `Catálogo Commerce` para o usuário selecionar como parte da conexão.

### Como a MKTOn usa
A MKTOn usa `catalog_management` para descobrir e disponibilizar ao usuário os catálogos Commerce pertencentes aos negócios Meta que ele autorizou, permitindo que esses ativos sejam associados aos recursos de catálogo/campanhas dinâmicas suportados pela plataforma. A MKTOn não acessa catálogos de negócios não autorizados.

### Como o revisor testa
1. Usar uma conta de teste com Business Manager e catálogo Commerce.
2. Conectar a Meta pela MKTOn.
3. Habilitar/selecionar `Catálogo Commerce` na integração.
4. Confirmar que o catálogo autorizado é descoberto pela integração.
5. Se a revisão exigir uma operação adicional de catálogo, demonstrar apenas a ação que estiver realmente disponível na UI atual; não inventar uma ação inexistente.

### Screencast
Mostrar OAuth → seleção/ativação de Catálogo Commerce → catálogo pertencente ao negócio autorizado aparecendo na integração. Se a Meta exigir criação/edição de produto e essa operação não existir na UI, revisar a necessidade dessa permissão antes de submeter evidência artificial.

---

## 18. `Marketing API Access Tier`

### Uso
A MKTOn utiliza a Marketing API para listar contas de anúncios autorizadas, campanhas, conjuntos, anúncios, métricas e executar as ações reais de gestão expostas pelo módulo Gestor de Tráfego.

### Evidência sugerida
Usar o mesmo vídeo de `ads_read` + `ads_management`, mostrando:
1. OAuth;
2. seleção da conta;
3. campanhas/conjuntos/anúncios reais;
4. métricas;
5. uma ação real de gestão em ativo de teste.

---

# Roteiros mínimos de screencast

## Vídeo A — OAuth + Pages + Social Media
Cobertura potencial: `pages_show_list`, `pages_read_engagement`, `pages_manage_posts`, `pages_manage_metadata`, `pages_manage_engagement`.

Roteiro:
1. entrar na MKTOn;
2. Integrações → Meta;
3. OAuth;
4. selecionar Página;
5. abrir Social Media;
6. criar/publicar conteúdo;
7. confirmar conteúdo na Página;
8. mostrar interação/engajamento quando aplicável.

## Vídeo B — Messenger
Cobertura: `pages_messaging`.

Roteiro:
1. Página de teste conectada;
2. outra conta envia Messenger;
3. Inbox MKTOn recebe;
4. responder pela MKTOn;
5. resposta chega ao Messenger.

## Vídeo C — Instagram
Cobertura potencial: `instagram_basic`, `instagram_manage_comments`, `instagram_manage_messages`, `instagram_manage_insights`, `instagram_content_publish`.

Roteiro:
1. conta profissional conectada;
2. identificar conta na MKTOn;
3. DM externa → Inbox → resposta;
4. comentário externo → tratamento suportado;
5. abrir insights;
6. publicar conteúdo e confirmar no Instagram.

## Vídeo D — Ads + Lead Ads
Cobertura potencial: `ads_read`, `ads_management`, `business_management`, `leads_retrieval`, `read_insights`, `Marketing API Access Tier`.

Roteiro:
1. OAuth Meta;
2. selecionar conta de anúncios;
3. abrir Gestor de Tráfego;
4. mostrar campanhas/conjuntos/anúncios + métricas;
5. pausar/reativar ativo de teste;
6. enviar Lead Ad de teste;
7. mostrar lead entrando no CRM.

## Vídeo E — Catálogo, somente se solicitado
Cobertura: `catalog_management`.

Roteiro:
1. usar negócio de teste com catálogo;
2. conectar Meta;
3. habilitar Catálogo Commerce;
4. mostrar catálogo descoberto pela MKTOn;
5. demonstrar apenas operações de catálogo realmente existentes na interface.

---

# Instruções gerais ao revisor — rascunho

A MKTOn é uma plataforma SaaS de CRM, atendimento omnichannel, Social Media e gestão de tráfego. O usuário conecta voluntariamente a própria conta Meta por OAuth e escolhe quais Páginas, contas profissionais do Instagram e contas de anúncios deseja vincular ao seu workspace. Credenciais técnicas do aplicativo ficam no servidor e não são solicitadas ao cliente final. Durante a análise, utilizar os ativos e a conta de teste fornecidos e seguir os passos específicos de cada permissão.

URL de produção: `https://mkton.io`.
OAuth callback: `https://mkton.io/api/public/oauth/meta/callback`.

Não colocar App Secret, Verify Token, access token ou `INTEGRATION_ENCRYPTION_KEY` nas instruções do revisor.

---

# Tratamento de dados — fatos técnicos que podem ser usados nas respostas

Usar somente quando a pergunta da Meta corresponder ao fato abaixo; não transformar este bloco em declaração jurídica genérica.

- A autorização é iniciada pelo próprio usuário autenticado da MKTOn.
- A integração é vinculada a um `workspace_id`.
- Tokens de integração são armazenados server-side e cifrados usando `INTEGRATION_ENCRYPTION_KEY`.
- `META_APP_SECRET` e `META_WEBHOOK_VERIFY_TOKEN` são server-only e não devem ser enviados ao navegador/cliente final.
- Webhook POST valida `X-Hub-Signature-256` com HMAC antes de processar payload.
- A seleção de contas/Páginas é feita pelo usuário; a MKTOn não deve escolher ativos aleatórios quando existem múltiplos recursos.
- O disconnect da integração remove credencial Meta e caches técnicos de Páginas, Instagram, contas de anúncios, pixels e eventos/tabelas Meta conforme o backend atual.
- Leads que já viraram registros comerciais do CRM podem possuir ciclo de vida próprio do workspace; não afirmar que desconectar Meta apaga todo o CRM.

Questões jurídicas/empresariais que dependam de controlador legal, política de retenção formal, subprocessadores, países de tratamento ou contatos de privacidade devem ser respondidas com dados reais da empresa/políticas do owner, não inventadas pelo programador.

---

# Ponto de retomada
O owner parou no cartão `pages_manage_posts` porque a Meta solicitou screencast. Ao retomar, entregar o material **um cartão por vez**, mesmo que todos os textos já estejam preparados neste arquivo.
