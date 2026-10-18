# Saúde Slim: bloco 10 de legibilidade da ficha e do Mini-Inbox

## Estado: 🟡 escopo antes da implementação

Base documental 7213e43d57658a5dc1dd1658526dfa6c231bbe9b; código publicado 4dfbd18c0989ff2d7b79d00c9223d6205319ac6a, Railway 9764d252 SUCCESS. Repositório ruanmeloandrade-alt/saude-slim, produção restauracao/sistema-completo-20261014. Nova branch fix/slim-funnel-inbox-design-20261018. Somente Saúde Slim.

## Pedido e evidência

Em 18/10 às 01:54 de Brasília, o usuário informou que a ficha aberta ao clicar no lead aparenta funcionar, mas o Mini-Inbox parece invisível e o texto é difícil de entender. Pediu finalizar rapidamente o design da ficha e melhorar a legibilidade do Inbox. O anexo 564.PNG foi aberto e inspecionado; não será enviado ao repositório porque contém dados reais. O relato de funcionamento não equivale a homologação integral de todos os envios.

O código confirma duas causas: os tokens --chat-* são declarados apenas em [data-chat-surface], ausente na seção que recebe o thread dentro da ficha; e a regra .slim-funnel-drawer-chat > * aplica flex:1 a cabeçalho, histórico e composer, porque o thread retorna Fragment. Isso apaga a distinção das superfícies e expande áreas que deveriam manter altura própria.

AGENTS.md e os checkpoints anteriores foram consultados. A instrução atual exige Saúde Slim exclusivamente e prevalece sobre referências antigas a MKTOn/Lovable. A autorização de publicar depois da validação permanece válida. Não esperar testes do usuário para executar o trabalho já autorizado.

## Dentro do bloco

- Restaurar o contexto de cores do Mini-Inbox no próprio contêiner montado pelo portal.
- Preservar altura própria do cabeçalho e composer; deixar o histórico ocupar o espaço restante. Manter rolagem independente de dados e mensagens.
- Dar à ficha superfícies, divisórias, textos, rótulos e ações legíveis. Melhorar tamanho e entrelinha dos campos, hierarquia visual e espaçamento sem remover informações.
- Corrigir a apresentação compartilhada do Inbox: fundo real do histórico, metadados legíveis e separação clara entre bolhas recebidas/enviadas e painel, respeitando tema e identidade verde da Slim.
- Preservar abas móveis, foco, Escape, seleção/arraste no Funil, links e edição existente. Rascunho, mídia, gravação, envio, prazos e guardas de saída continuam com o comportamento publicado.
- Priorizar mudanças em src/components/crm/SlimFunnelLeadDrawer.tsx, src/components/crm/slim-funnel-drawer.css e seletores de chat em src/styles.css. Ajustes exclusivamente de classes/atributos de apresentação no thread compartilhado só se necessários.

## Fora do bloco

Nenhuma mudança em RPC, schema, banco, autenticação, conta, bot, worker, transporte, fila, mídia armazenada, pedido ou estoque. Nenhuma mensagem/campanha/convite real para QA. Não iniciar MFA, NF-e, Cora, IA autônoma em grupos, outros projetos, infraestrutura, domínio, credenciais, Lovable, Vercel ou GitHub Actions. Preservar aprovações reais anteriores e demais pendências do semáforo.

## Validação e publicação

Inspecionar o resultado renderizado localmente usando os componentes reais e dados sintéticos: desktop nos temas claro/escuro e celular. Conferir bolhas e entrada opacas, contraste, altura do cabeçalho/composer, espaço do histórico, rolagem e ausência de transbordamento. Usar o render já disponível, sem criar uma extensa bateria nova para uma correção visual.

Executar os gates existentes relevantes da ficha/Mini-Inbox e uma compilação completa em cópia isolada, mantendo os transforms e regressões. Não executar transforms no checkout compartilhado. Versionar o código validado, atualizar a produção por CAS e conferir Railway SUCCESS, healthcheck e serviços. A renderização local será distinguida da conferência na sessão autenticada do usuário. Atualizar este escopo e OPERATION_STATUS.md sem deployment documental separado.

## Execução e divisão

Root registra escopo, revisa, integra e publica. Agente de UI implementa somente os três arquivos de apresentação após confirmação do commit de escopo. Agente de render prepara a verificação visual isolada e informa evidências. Nenhum agente altera código do outro nem realiza operações comerciais. Segurança e NF-e continuam pendentes, sem ampliar esta correção.

## 🟢 Implementação e compilação local em 18/10

Escopo publicado antes do código no commit 7170ce4dafcc85674a58c0cc1bef5640e5f533d6. A implementação altera apenas os três arquivos previstos: atributo de superfície no contêiner do chat, correção de flex/overflow e legibilidade da ficha, paleta/fundo/metadados compartilhados do chat. Revisão independente confirmou a especificidade sobre o Sheet e a preservação das abas móveis. Nenhuma lógica de dados ou transporte foi modificada.

npm run build terminou com exit 0 na primeira tentativa, sessão 77413, em /tmp/slim-funnel-inbox-design-build-u3omvlns, com log /tmp/slim-funnel-inbox-design-build.log. Os gates existentes passaram, incluindo 15 verificações de detalhe, 12 do thread integrado e 21 da ficha. São 48 regressões anteriores, não testes novos. Artefato Nitro e hashes dos três arquivos fonte foram conferidos. Os transforms rodaram somente na cópia isolada. A produção ainda permanece 4dfbd18 neste checkpoint; renderização final e publicação seguem pendentes.
