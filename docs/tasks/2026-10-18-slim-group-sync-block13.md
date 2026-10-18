# Saúde Slim | Bloco 13: sincronização da Central de Grupos e aceite final

## Estado atual: 🟢 publicado, sincronizado e conferido em produção
Versão final 5e24b2da48a21a1011c6a3894c1454c5ffa0a141; Railway 85d5c964-6b15-408b-831d-0302bfb03b7b SUCCESS, healthcheck 1/1 e quatro serviços online. A sessão autenticada sincronizou 40 grupos reais e confirmou catálogo, regras, contexto de SalesBots e seletor da conta conectada. Funcionário na empresa operacional correta; checkout e comprovante aceitos. O encerramento ao final deste arquivo prevalece sobre os checkpoints históricos abaixo.

## Status inicial: 🟡 em execução, antes da implementação
Registro de 18/10/2026. Fonte de verdade exclusiva: GitHub ruanmeloandrade-alt/saude-slim, produção restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza, empresa c49945db-1960-461a-9339-a43b8403bdd9. Base funcional eb9ca08e8edc7e16158fbc8c51a34d3d48100d94; documentação consolidada em 396af5b514504dbd5e74e4335c6ab2ab7e489c60. Railway 2c72ee70-bd81-486f-94f9-74d0389f7a95 continua SUCCESS na consulta inicial.

## Requisitos do usuário
- Os grupos já aparecem no Inbox, mas não em Automações → Grupos, Regras e SalesBots de grupo. Sincronizar para permitir a configuração das regras.
- Localizar, somente em leitura, o teste real de texto “oi” enviado anteriormente pelo usuário a um grupo.
- Checkout aceito como concluído pelo usuário.
- Conta de funcionário criada pelo usuário e acesso em navegador anônimo confirmado por ele. Conferir os registros disponíveis e encerrar o aceite de acesso, sem confundir esse teste com uso de convite por link.
- Concluir e publicar as correções validadas sem esperar outra autorização. Manter o semáforo com emojis.

## Dentro do escopo
1. Corrigir a ligação entre histórico do Inbox e catálogo da Central de Grupos, preservando empresa, sessão de origem e JID.
2. Sincronização idempotente de metadados existentes, sem criar grupos no WhatsApp, apagar mensagens ou substituir regras, atribuições de bot e nomes já configurados sem evidência do provedor.
3. Conferir e corrigir seleção de grupos em Regras e SalesBots, estado vazio, erros e retorno da sincronização.
4. Limitar chamadas de leitura de metadados à Evolution por prazo, volume e concorrência. Falhas não podem apagar o catálogo nem parecer lista vazia confirmada.
5. Testes isolados dos contratos afetados, compilação completa, versionamento, migration aditiva se necessária, publicação Railway e conferência operacional.
6. Atualizar docs/OPERATION_STATUS.md com aceites e evidência real, distinguindo código validado e cenário real efetivamente observado.

## Fora do escopo
Atendimento autônomo de IA nos grupos permanece retirado por decisão do usuário. Não criar nem iniciar bots, gatilhos, campanhas, mensagens, vendas, convites ou contas reais para QA. Não alterar senhas, fatores, sessões, permissões de funcionários ou dados comerciais. Não tocar Cora, MKTOn, Harpia, Lovable, Vercel ou GitHub Actions; instruções legadas referentes a outros projetos não substituem este recorte autorizado. NF-e real segue fora do escopo, comprovante comercial aceito. Segurança do bloco 12 e todas as regressões anteriores devem ser preservadas.

## Critérios de aceite
- Grupos históricos autorizados ficam disponíveis com identidade persistida utilizável pelas regras, sem duplicar a mesma combinação de sessão/JID.
- Sincronizar novamente preserva regras, bot ativo, dados anteriores e mensagens; falhas e catálogos vazios têm tratamento explícito.
- Usuário, empresa e sessão incorretos são recusados; nenhuma nova abertura de RLS, RPC ou acesso anônimo.
- Regras e SalesBots usam os mesmos grupos da aba Grupos; IA de grupos não volta à interface.
- Teste real “oi” e acesso de funcionário registrados somente conforme os dados encontrados e o relato do usuário.
- Build, testes relevantes e healthcheck aprovados; produção conferida antes de declarar correção concluída.

## Áreas previstas
src/lib/whatsapp-groups.functions.ts, whatsapp-group-sync-robust.functions.ts e helpers focados; src/components/automations/CentralDeGrupos.tsx e integração de ações; scripts de transformação/testes; migration e teste SQL se necessários; documentação deste bloco e semáforo.

## Diagnóstico inicial e decisões
A listagem do Inbox usa list_inbox_group_conversations_page, capaz de recuperar conversas do histórico. A Central lê somente whatsapp_groups via listWorkspaceGroups; suas ações exigem UUID persistido. A causa precisa ser resolvida no catálogo e no contrato de sincronização, não apenas renderizando grupos virtuais sem destino para salvar regras. Consultas reais e desenho final em andamento.
## Adendo de aceite do funcionário, conferido antes da correção
A leitura real de 18/10 às 19:04 UTC confirmou funcionário criado às 18:44:59 UTC, login às 18:45:38 UTC, conta e vínculo ativos e uma sessão nativa válida. O perfil estava selecionando a empresa vazia criada automaticamente para essa nova identidade, em vez da operação Saúde Slim. A leitura de 19:06 UTC encontrou 26 leads e três bots individuais na Slim operacional, e zero leads/grupos/bots na empresa inicial do funcionário.

O código explica o resultado: handle_new_user cria empresa e preenche o perfil; createEmployee confirma o vínculo com a Slim, mas só seleciona a empresa contratante quando o perfil está nulo. O login não oferece troca de empresa na navegação atual. Esse defeito impede considerar o acesso operacional concluído somente pelo login.

Recorte adicional autorizado pelo pedido de conferir/finalizar a conta: selecionar a empresa contratante após o provisionamento de uma identidade nova, confirmando a escrita, e preservar a escolha prévia de identidades reutilizadas. Corrigir somente o campo de empresa ativa da conta de funcionário recém-criada e identificada, sob condições de vínculo ativo, origem na empresa pessoal vazia e seleção anterior conferida. Não modificar conta Auth, senha, sessão, fatores, permissões, memberships ou empresas; não excluir a empresa vazia. A restrição anterior sobre contas refere-se a ações de QA e não impede este reparo concreto do contexto operacional.

A correção será testada com dados sintéticos, versionada antes da operação administrativa e incluída na mesma publicação dos grupos. O aceite do login real é verde; o acesso à empresa operacional será registrado após a correção verificada.

## Implementação integrada e evidência antes da publicação
- RPC invoker slim_sync_group_catalog recupera pares sessão/JID autorizados por INSERT...ON CONFLICT DO NOTHING, sem alterar configurações existentes. Migration 20261018185403_slim_group_catalog_recovery.sql; instalação ainda pendente neste checkpoint.
- listWorkspaceGroups usa catálogo persistido e recupera somente metadados visíveis ao operador; visualizador consulta sem inserir. Nenhuma chamada à Evolution ao abrir a lista.
- Sincronização explícita consulta a Evolution uma vez, GET com prazo de 18 s e até 2 MB, sem redirecionamento/retry/consultas extras de foto. Operação total até 30 s. Histórico permanece configurável quando o provedor falha; nomes/participantes só constam atualizados após resposta válida.
- Central compartilha empresa/sessão e catálogo entre Grupos, Regras e SalesBots. Todas as sessões funciona, erros não viram lista vazia, consulta/agendamento são invalidados juntos. Rascunhos por grupo são preservados e o salvamento exige recibo. Ações de bots usam UUID da linha.
- Agendamento mantém sessão/JID originais, exige operador e grava regras com o cliente sujeito a RLS antes de acessar o runtime interno. Prazo incerto orienta conferência, sem prometer rollback.
- Novo funcionário recebe a empresa contratante após vínculo confirmado; identidade reutilizada mantém seleção prévia. Resultado comparado com perfil observado, prazo de 10 s e sem repetição.
- Operações administrativas parametrizadas em supabase/operations recuperam somente os metadados da Slim e corrigem somente a empresa ativa do funcionário identificado. Serão executadas após versionamento da versão validada; não alteram permissões, Auth, mensagens ou contas comerciais.

### Evidência real consultada
Em 18/10 às 19:04/19:06 UTC, havia 95 mensagens de quatro grupos (85 recebidas e dez enviadas), zero cadastros de grupos e três SalesBots, todos de scope individual. O catálogo vazio de SalesBots de grupo é real; nenhum bot de grupo foi inventado ou criado para QA.

O envio real encontrado é o texto “Teste”, registro df7af0d7, em 18/10 às 15:34:45 UTC (12:34:45 de Brasília), from_me=true, com message_id do provedor, sessão de origem 33ecf991 e grupo de sufixo 467105. A consulta exata de “oi” não retornou mensagem enviada; o aceite de envio está fundamentado no teste localizado e no relato do usuário, sem afirmar entrega ou leitura do destinatário.

Funcionário d1811cad: criado às 18:44:59 UTC, login às 18:45:38 UTC, e-mail confirmado, conta ativa, vínculo member/funcionario ativo e uma sessão nativa válida. O perfil apontava para sua empresa inicial vazia (zero leads, bots e grupos), distinta da Slim operacional com 26 leads. Não foi lida senha/token nem executado login de QA. Checkout e comprovante comercial estão aceitos pelo usuário.

### Validação disponível
71 casos novos portáteis aprovados: SQL do catálogo 12, runtime do catálogo/provedor 23, UI 8, agendamento 16 e empresa inicial 12. Mais 8 interações Chromium com componentes reais e dados sintéticos. A compilação integrada e recaptura com CSS final estão em andamento; nenhum PASS de produção é antecipado.

Baseline de segurança às 19:13:25 UTC: 192 políticas, hash 3c1767d874321020684cfbafc8ec5460, corpo do guard slim_assert_session_security com hash cea919fe8a00fd3be21482665196f997. Baseline do histórico dos grupos: 95 mensagens, hash projetado 108fd3b0f4d299ef9eec89470ad8b198. Produção funcional permanece eb9ca08 neste checkpoint.

## 🟢 Compilação integrada aprovada antes da publicação
npm run build terminou com exit 0 na primeira tentativa em /tmp/slim-block13-build-io0qgev9. As 1.326 fontes não documentais copiadas conservaram os hashes até a conferência posterior. Todos os gates anteriores e 71 casos novos passaram. Não houve alteração em dependências ou uso de GitHub Actions. Operação parametrizada de empresa inicial é SQL administrativo separado, sem alteração no artefato compilado.

A sessão autenticada do dono foi acessada pelo Browser conectado somente em leitura: Configurações mostrava dois membros ativos e nenhum convite pendente. A conferência interativa da Central será feita após a publicação, sem iniciar bot ou mensagem. Recaptura Chromium com CSS final em andamento. Instalação da RPC, reparos administrativos e deployment ainda não concluídos neste checkpoint.

## Adendo do seletor de sessão, antes da correção focal
A conferência autenticada durante a primeira implantação mostrou os quatro grupos após a recuperação, mas a consulta legada de canais retornou lista de sessões vazia. A inspeção do handler encontrou projeção de push_name em whatsapp_web_sessions, coluna ausente no schema versionado, e descarte de wa.error. A Central nova já mantém uma opção recuperada dos session_id do histórico, permitindo continuidade, mas o seletor deve também carregar normalmente a conta WhatsApp conectada.

Dentro do mesmo bloco, corrigir somente a projeção/mapeamento WhatsApp de src/lib/channels.functions.ts para colunas reais e expor falha de consulta em vez de sucesso vazio. Preservar middleware, workspace ativo, RLS, filtragem/deduplicação, Meta e a ausência de envios. Validar o handler real com transporte sintético e a compilação integrada em cópia isolada. Não criar colunas artificiais nem alterar dados ou credenciais da sessão. Confirmar a sessão conectada e sincronização real de metadados pelo navegador após publicar a correção.

## 🟢 Encerramento do bloco 13 e evidência de produção

### Publicação e causa corrigida
Código principal dca4c0eddbaa6fa02c07d441c5d80584f87eb057, tree 7ab88381391839e112abc035a196c9b34d5908cc, publicado no deployment fe102bac-8a7d-4c13-ae94-e696472f1173, SUCCESS em 18/10 às 19:30:05 UTC. A Central passou a recuperar identidades persistidas do histórico e ofereceu a sessão derivada dos grupos para continuar a operação.

A conferência autenticada encontrou o defeito adicional do seletor: channels.functions.ts selecionava push_name, coluna ausente, e ignorava wa.error. Adendo registrado antes da correção em bca522cb590bbc673f4a216f75a0e0b7c0b8ad83. A projeção passou a usar somente id, phone_number, status, updated_at e metadata, com rótulo pelo telefone disponível e erro explícito sanitizado. Leitura real de information_schema e privilégios confirmou as cinco colunas disponíveis para authenticated e ausência de push_name. Middleware, empresa ativa, RLS, filtragem, deduplicação e comportamento Meta foram preservados.

Versão final 5e24b2da48a21a1011c6a3894c1454c5ffa0a141, tree 200291a992a28c22367a8271cbbe7254b20f708a. Deployment 85d5c964-6b15-408b-831d-0302bfb03b7b SUCCESS às 19:43:20.917 UTC e healthcheck 1/1 às 19:43:17.328 UTC. Conferência final: quatro serviços online, uma réplica por serviço, nenhuma falha, nenhuma operação pendente. Às 19:45:37 UTC, https://slimesaude.com retornou HTTP 200, quatro CSS byte a byte iguais aos validados e GETs anônimos de /api/partners/payment-profile e /api/partners/admin/payment-profiles retornaram 401 com JSON.

### Migração, recuperação e segurança
A RPC invoker foi instalada como migration 20261018191837, nome slim_group_catalog_recovery; fonte versionada supabase/migrations/20261018185403_slim_group_catalog_recovery.sql. Prosrc hash 4d558a350af1388cdbe58b748bc2dac7; SECURITY INVOKER, search_path vazio e lock_timeout 5s confirmados. EXECUTE permitido somente a authenticated entre os papéis públicos conferidos, recusado a anon e service_role.

Executadas as duas operações parametrizadas previamente versionadas: quatro INSERTs de metadados derivados do histórico e um UPDATE de profiles.current_workspace_id para o funcionário identificado. A conferência às 19:23:32 UTC encontrou quatro grupos na Slim e zero na empresa inicial do funcionário; conta e sessão Auth mantiveram os registros, vínculo member/funcionario e validade. Nenhuma empresa, membership, permissão, senha, fator ou sessão foi alterada.

As 192 políticas conservaram o hash 3c1767d874321020684cfbafc8ec5460, e o corpo do guard slim_assert_session_security permaneceu cea919fe8a00fd3be21482665196f997. Advisor sem novos avisos: os quatro INFO de ledgers privados fechados, quatro WARN de RPCs DEFINER existentes e o WARN de proteção contra senha vazada do bloco 12 continuam os mesmos, com seus limites já documentados. Referências: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy ; https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable ; https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection .

### Conferência autenticada de grupos
Pelo navegador conectado, em uma aba de QA separada da aba do usuário, foi selecionada a sessão original dos grupos e acionado Sincronizar uma vez. A Evolution respondeu e a UI confirmou 40 grupos atualizados, zero recuperados nessa chamada e 40 disponíveis. last_synced_at 2026-10-18T19:32:27.313Z. A atualização trouxe nomes e quantidades de participantes; não criou grupos no WhatsApp nem enviou mensagens.

A consulta das 19:39:18 UTC confirmou 40 pares sessão/JID únicos, todos sincronizados, e os quatro IDs originais preservados. As 95 mensagens, dez delas enviadas, conservaram o hash projetado 108fd3b0f4d299ef9eec89470ad8b198. O catálogo da empresa inicial do funcionário continuou vazio, e o perfil do funcionário apontava para a Slim operacional.

Na interface, Configurar regras no grupo do teste abriu o editor; o mesmo grupo permaneceu selecionado na aba SalesBots. Foram observados os controles de moderação e gatilhos e os 40 grupos disponíveis no seletor. A aba informou corretamente que não existe SalesBot de grupo cadastrado; os três bots existentes são individuais. Após a versão final, o seletor passou a mostrar a conta conectada normalmente, sem depender da opção do histórico. Seleção habilitou Sincronizar e a busca local encontrou um grupo entre os 40, com atualização do WhatsApp identificada. Captura visual final conferida internamente; não incluída no repositório por conter identificadores de contato.

Nenhuma regra, moderação, agendamento, bot ou mensagem foi criado, salvo ou executado para QA em produção. O teste de salvamento e seus recibos foi isolado. Não foram simulados cenários de entrega/leitura de mensagem, envio real de mídia, aceite de convite por link, ações administrativas no WhatsApp ou execução de bot de grupo.

### Validação técnica final
78 testes novos portáteis: catálogo SQL 12, catálogo/provedor 23, UI 8, agendamento 16, empresa inicial 12 e seletor de canais 7. Além deles, oito casos interativos Chromium dos componentes reais com dados sintéticos passaram novamente com o CSS final, sem erros JavaScript ou transbordamento em computador e celular. A recaptura não foi contada como novos testes.

O build completo inicial passou em /tmp/slim-block13-build-io0qgev9, com todos os gates anteriores. Para o ajuste focal, foi criada /tmp/slim-block13-channels-build-b35jp8yo a partir da árvore já transformada e aprovada. Comparação confirmou uma única diferença de runtime, channels.functions.ts, além do novo teste e da integração do gate. O handler real passou 7/7; ./node_modules/.bin/vite build gerou cliente, SSR e Nitro com exit 0. As 1.591 entradas permaneceram intactas durante a compilação, e as fontes ainda coincidiam com o checkout. Nenhum transform/build foi executado no repositório compartilhado. O Railway executou novamente a bateria completa e publicou somente após aprovação.

Hash SHA-256 de channels.functions.ts: 25087be24bd378687086a7240ac9040ce95c7d36308a6b349cabcccf5910a720. CSS final styles-NNUnQaCy.css: 097adcf892fed44acf55c7e03d67810de776d4a9df8e24e1df3d49f4fb6164a7, acompanhado dos mesmos três CSS auxiliares aprovados. Evidência temporária em /tmp/slim-block13-channels-build-meta.json e /tmp/slim-block13-live-smoke.json; resultados essenciais registrados neste arquivo para continuidade.

### Aceite e limites da entrega
🟢 Grupos sincronizados, regras e seleção de gatilhos disponíveis, teste anterior de texto localizado, funcionário com login confirmado e empresa inicial corrigida. 🟢 Checkout e comprovante comercial aceitos pelo usuário. 🟢 Segurança do bloco 12 preservada. ⚪ IA autônoma de grupos e NF-e real continuam fora do escopo.

Não há bloqueio técnico identificado nas correções deste pedido. O sistema está publicado e liberado para conferência final. O login do funcionário foi feito pelo usuário e confirmado pelos registros; não foi realizado novo login de QA em seu nome. O checkpoint de encerramento é somente documental na branch de trabalho, sem gerar outra implantação.
