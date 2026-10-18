# Saúde Slim: bloco 5 de Públicos e comprovantes de disparo

## Estado: 🟢 implementação, testes e compilação completa; 🟡 publicação

Base d2a41dc462c26a4b00da5484333e2d5665de82ec. Branch de trabalho fix/slim-audience-receipts-block5-20261017. Produção restauracao/sistema-completo-20261014, repositório ruanmeloandrade-alt/saude-slim. Supabase vyzvfcgpjjzvcjegzzza, empresa c49945db-1960-461a-9339-a43b8403bdd9. Somente Saúde Slim.

## Orientação atual e objetivo

Em 17/10 às 21:38 de Brasília, o usuário pediu para seguir a produção enquanto testa, sem esperar seu retorno. Isso substitui as pausas anteriores entre blocos. Manter entregas coesas, comunicar o semáforo com emojis e publicar somente após validação. Copiloto, gatilho do Funil e passagem do SalesBot para IA individual permanecem aceitos. Checkout já publicado fica em conferência com o usuário.

Às 21:45, o usuário reforçou a ficha completa ao clicar no lead do Funil, incluindo dados do cliente e Mini-Inbox. Essa entrega permanece no escopo geral e deve ser integrada; o código atual apenas navega ao Inbox. Auditoria da pendência corre em paralelo, sem reaplicar a escrita anteriormente recusada. Este bloco implementa somente Públicos/Disparos.

## Falhas reproduzidas

- noMessageForDays usa lead.updated_at, confundindo edição de cadastro com data de mensagem. Esse limite já aparecia no escopo de 15/10.
- Se o WhatsApp retorna um ID e a gravação do histórico falha, o core retorna LOCAL_PERSISTENCE_FAILED sem o ID recebido.
- Um ID contendo somente espaços é aceito como confirmação e chega à persistência.

## Dentro do bloco

- O filtro de inatividade passa a considerar mensagens reais vinculadas ao contato, usando metadados mínimos de atividades e mensagens WhatsApp, com isolamento por empresa e identidade comprovada. Não ler corpos, payloads integrais nem base64 para calcular o público.
- Preservar updatedWithinDays como filtro de alteração do cadastro. Sem histórico, contar a espera desde created_at; um contato novo não satisfaz imediatamente N dias sem contato. Erro, paginação incompleta ou identidade ambígua não podem ampliar silenciosamente o público.
- Consultar somente as fontes necessárias quando o filtro estiver ativo, com paginação e limites explícitos. Preservar a mesma seleção em prévia e enfileiramento.
- Normalizar o ID recebido do WhatsApp, rejeitar vazio/espaços e conservar o comprovante quando apenas o histórico falhar. A confirmação do provedor continua distinta da entrega/leitura pelo destinatário.
- Exibir aviso compreensível de histórico pendente, sem sugerir repetição de um envio confirmado. Preservar envio único, cancelamento, opt-out, sessão autorizada e comportamento de SalesBots.

## Fora do bloco

Nenhum disparo, campanha, bot, contato, pedido ou movimento de QA em produção. Sem replay de mensagens ou correção retroativa de recibos antigos. Sem migration, alteração de RLS, grants, credenciais, DNS ou infraestrutura. Não reaplicar os pacotes anteriormente recusados de Editar/Excluir pedidos, Mini-Inbox, segurança/convites ou unicidade global. Cora congelado. IA autônoma em grupos retirada do escopo; SalesBots e gatilhos preservados. Sem outras empresas, Lovable, Vercel ou GitHub Actions.

## Áreas e critérios de aceite

src/lib/slim-audience.core.ts, helpers necessários, src/lib/slim-audience-delivery.core.ts, painel SlimAudienceQueue e testes focados. O worker só será ajustado se necessário para conservar o resultado já confirmado; não será executado manualmente contra produção.

Testes locais sintéticos cobrem cadastro editado com conversa antiga, conversa recente com cadastro antigo, ausência de histórico, limite temporal, fontes paginadas, isolamento de empresa/sessão/identidade, falha de leitura, comprovante vazio, normalização e persistência local falhando depois de uma única chamada ao provedor. Regressões existentes permanecem. Uma compilação final completa em cópia isolada e uma publicação no Railway, seguida de SUCCESS, healthcheck e estado dos serviços. Testes técnicos não substituem a conferência autenticada nem constituem envio real.

## Bloqueios históricos apurados

Editar/Excluir pedidos: apply_migration slim_order_reviewed_edit_delete recusado; integração transacional não entregue. Mini-Inbox: escrita de integração do Funil/ChatThread recusada, quatro módulos preparados no WIP d6d84a5a7579c64d284a7266124ec013d7a7492c. Segurança/convites: slim_restore_settings_security_and_invitations recusado. Unicidade global: slim_contact_identity e slim_active_contact_phone_identity não instalados. As fontes registram recusas anteriores das ferramentas, mas não preservam os respectivos motivos técnicos específicos. A autorização do usuário já existia; nenhuma nova recusa ocorreu neste diagnóstico. Fontes: escopos de 16/10 slim-inbox-resumption, slim-prompt-only, slim-lead-identity-only e de 15/10 slim-settings-dashboard-continuation.

## Execução

Escopo preparado antes de qualquer alteração de runtime. Implementação e evidências serão acrescentadas neste mesmo documento. A ficha do Funil continua sendo entrega pendente explícita, sem ser confundida com o gatilho do Funil já aprovado.

## 🟢 Implementação e validação local

Escopo versionado antes do código no commit a5b65e0ec4ac2940022bc26412bc85e25084ae2b. O filtro agora lê a janela de atividades message_in/message_out e mensagens WhatsApp originais. Usa apenas metadados escalares, sem corpo, raw ou payload integral. Considera aliases canônicos existentes, sessão de origem e LID com número alternativo comprovado; não converte LID ou grupo em telefone. LID recente sem vínculo suficiente interrompe o cálculo com explicação. Sem sessão no cadastro, tráfego recente do mesmo telefone impede declarar silêncio. Contatos novos só satisfazem o prazo depois de N dias desde created_at. updatedWithinDays continua independente.

Paginação usa a janela temporal solicitada, com máximo de 100 mil linhas por fonte, oito segundos por requisição e dez segundos totais por fonte. O prazo restante limita cada página e é conferido novamente depois da resposta. Falha ou inconsistência de qualquer fonte impede devolver um público parcial. Mensagens de saída pendentes ou incertas também impedem declarar silêncio, de forma conservadora. Com o filtro desligado, não há essas consultas adicionais.

O comprovante é normalizado e preservado quando o WhatsApp aceita o envio, mesmo se o histórico local falhar. Nesse caso a fila registra sent, message_id e LOCAL_PERSISTENCE_FAILED; a interface explica a pendência. ID vazio, somente espaços ou tipo inválido retorna confirmação incerta sem persistir. O worker já conserva os três campos e não precisou mudar. Não há repetição automática nem alteração retroativa de registros anteriores.

- node --experimental-strip-types scripts/test-slim-audience-core.mjs: 41/41, incluindo os 13 anteriores e 28 novos. Repetido após o ajuste final do orçamento de leitura.
- node --experimental-strip-types scripts/test-slim-audience-delivery.mjs: 19/19, incluindo os 16 anteriores e três novos.
- Renderização local do componente real da fila: três cenários aprovados, confirmação com histórico pendente, ausência de comprovante e SalesBot iniciado.
- Typecheck estrito dos módulos de público e git diff --check aprovados.

Total de 60 verificações focadas nos dois scripts, com 31 novas, além das três renderizações locais. Testes usam dados e transportes sintéticos, sem contato com clientes. Documentação oficial de select/in/gte/range e changelog Supabase consultados, preservando os métodos da dependência existente.

## Produção antes da publicação

Em 18/10 às 00:56:09 UTC, leitura do Supabase confirmou zero campanhas e zero destinatários na fila de Públicos/Disparos, além de 261 atividades de mensagem. São contagens, sem leitura de conteúdo de conversas. Railway confirmou quatro serviços online, nenhuma falha e nenhuma operação pendente. Nenhuma campanha ou mensagem foi criada para testar.

## Ficha do Funil mantida na sequência

A rota atual e o código transformado do último build confirmado usam handleLeadClick para navegar ao Inbox, tanto no Kanban quanto na lista. O WIP anterior contém quatro módulos, mas importa SlimEmbeddedChatThread, export ainda ausente. A integração precisa incorporar os estados reais de rascunho, envio, gravação e transcrição, além de corrigir a projeção do campo source na leitura autenticada. A nova ordem explícita do usuário mantém a entrega completa autorizada. Preparar uma integração revista e submetê-la ao fluxo normal de revisão; não presumir causa da recusa antiga nem trocar mecanismo para contornar qualquer recusa atual.

## 🟢 Compilação completa e liberação

npm run build terminou com código zero na cópia isolada, preservando todos os gates anteriores. O ajuste final do orçamento de leitura passou novamente nos 41 testes focados e está presente no bundle servidor. Os seis arquivos de runtime/testes conferem byte a byte com os arquivos da cópia compilada. Nenhum transform foi executado no checkout compartilhado. Sem instalação de dependências ou GitHub Actions.

Publicar este bloco em uma única atualização da branch de produção. Confirmar SUCCESS, healthcheck e os serviços antes de declarar publicação concluída. Nenhuma migration ou escrita de negócio é necessária. Resultado operacional será registrado no próximo checkpoint de trabalho e comunicado em chat, sem deploy documental separado. A implementação da ficha do Funil seguirá em escopo próprio, sem aguardar os testes do usuário.
