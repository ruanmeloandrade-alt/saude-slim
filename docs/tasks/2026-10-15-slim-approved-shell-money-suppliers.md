# Saúde Slim: execução do escopo aprovado

Checkpoint: código f352e12141f2e6f508f109200b5de239d7c7943b publicado, incluindo eef0379. Deployment 3d080296-25c1-45d6-83bc-34bb563f5606 SUCCESS, healthcheck 2026-10-15T14:33:21Z; estado Online/uma réplica em execução conferidos após publicação.
Base desta retomada: 32df473164ce9fe03f734d822dbf0606b52a603d. Branch fix/slim-approved-shell-money-suppliers-20261015, destino restauracao/sistema-completo-20261014. Repositório exclusivo ruanmeloandrade-alt/saude-slim; Supabase vyzvfcgpjjzvcjegzzza; serviço saude-slim-web.

A criação deste escopo em 15a5433 ocorreu antes do código. A escrita no GitHub voltou a estar disponível nesta sessão. Não pedir outra aprovação; usuário já aprovou e pediu continuidade.

## Ordem aprovada e situação

1. Modais/drawers/seletores sobrepostos, menu recolhível junto a Operação Saúde Slim, Gestão ERP, Disparo imediatamente após Inbox e Cérebro sem margem duplicada: código publicado; interface autenticada ainda não homologada.
2. Centavos em cadastro/edição/leitura/promoção/custos: código publicado e sonda autenticada de persistência passou. Checkout/documento ainda precisam usar o contrato.
3. Fornecedores sem fonte MktOn externa: corrigido e publicado; sonda banco passou, tela não homologada integralmente.
4. Checkout operacional e pedido/histórico/Dashboard/estoque: próxima implementação, não realizado neste lote. Reconciliar venda anterior apenas com evidência.
5. Copiloto: erro is_workspace_member identificado e consumidor corrigido, publicado sem alterar chaves/permissões. Resposta real do provedor ainda não testada.
6. Métricas/relatórios de SalesBots: pendentes, sem percentuais inventados.
7. Documento PDF e integração fiscal real; envio WhatsApp somente após confirmação: pendentes.
8. Identidade visível Saúde Slim: parcial nos textos tocados, varredura global pendente.
9. Bloqueios anteriores de segurança/convites, avançados e homologação preservados.

## Diagnóstico confirmado

Interface: sidebar anterior usava z80 e diálogos compartilhados z50; produto possui wrappers personalizados fora de Radix. Cérebro somava spacer de menu com margem adicional de 272px.
Produtos: input number convertia a cada tecla e não preservava edição com vírgula; listagem importava formatador compartilhado não específico. Adaptador não validava representação decimal. Banco já é numeric com duas casas, portanto nenhuma alteração de tipo ou preço histórico foi necessária.
Fornecedores: companies.functions procurava apenas provider mkton, mas o banco próprio possui origem padrão manual. companies.crm_source_id é nullable. Não é necessário criar duplicados de origem ou apontar ao projeto original.
Copiloto: AiAgentChat utiliza /api/ai-agent/chat com bearer da sessão. A rota chama assertWorkspaceMember em ai-agent/auth-bearer.server.ts, que consultava a função pública is_workspace_member. Catálogo do banco confirmou EXECUTE revogado para authenticated nessa função. Políticas RLS usam helper privado separado.

## Implementação

AppSidebar e helper de preferência foram atualizados diretamente, preservando 15 destinos e quatro itens desabilitados de Fase 2. Largura 272/72px de sidebar/spacer usa o mesmo estado; preferência segura em localStorage e sincronização por evento; botão apenas com ícone, título/aria; mobile com fechamento/foco/teclado. CSS novo importado pelo componente, sem reescrever toda a folha herdada.

Camadas da interface: sidebar 40, modal/overlay 1000, elementos flutuantes 1100, notificações 1200. Overlay/content no mesmo plano preservam ordem DOM de portais aninhados. Altura disponível e rolagem em diálogos/painéis; wrappers personalizados de Produtos marcados. Retirada da margem duplicada do Cérebro sem remover recursos.

slim-money.core.ts converte entrada monetária em centavos inteiros via parsing decimal/BigInt, rejeitando negativo, NaN, notação exponencial e casas excedentes. Serializa números do cadastro/importação como decimal com duas casas; preserva zero e promoção ausente de forma distinta. Campos da tela usam rascunho textual e validam ao salvar; valores exibidos com dois centavos. Limites respeitam numeric(14,2) de produto e numeric(12,2) de custo. Precisão do checkout/documento completo fica para a frente de Pedidos.

slim-company-source.core.ts seleciona somente origem local apropriada, priorizando manual padrão. Sem fonte compatível retorna null permitido pelo schema; falha de consulta não vira ausência legítima. Não cria origem nem acessa outro banco. Confirmar registro alterado na edição do fornecedor; verificar produto e fornecedor da mesma empresa antes de salvar custo.

Copiloto: mantém verificação do bearer com auth.getUser(token), usa o mesmo cliente autenticado para ler operação/vínculo sob RLS, valida identidade, empresa e expiração. Não altera GRANT, não liga bypass e não usa service-role como substituto. Nenhuma chave de IA foi consultada/rotacionada.

## Integração do lote local

O ZIP saude-slim-lote-01 foi revisado e seus testes locais reexecutados. A entrega atual aproveita o contrato/layout, mas não afirma aplicação byte a byte do pacote. A integração final segue o mecanismo de transformações já existente no repositório: scripts/apply-slim-approved-ui-commerce.mjs verifica todas as âncoras antes de escrever dez fontes, é idempotente e fica no prebuild. Sidebar, helpers e CSS são arquivos diretos. Scripts não executam SQL, chamam serviços externos ou leem credenciais.

## Testes e evidências

### Build final

66 verificações novas aprovadas nos logs: 33 monetárias/origem, 20 contrato de fontes/interface e 13 autenticação/membership. As rotinas anteriores de IA, Inbox, manual/120s, histórico, Dashboard, Públicos, segurança e tracking continuam no prebuild. Build Vite concluído; publicação e healthcheck aprovados.

### Banco

Sonda com authenticated inseriu catálogo/produto temporário, gravou/releu 0.01, 19.99, 1234.56 e promoção 0.01, criou fornecedor com fonte manual própria, editou/releu, vinculou custo 19.99 e comprovou origem nullable. Subtransação revertida e ausência dos registros verificada. Nenhum pedido, estoque real ou mensagem alterado.
Leituras de metadados confirmaram os tipos monetários, origem local e permissões da RPC antiga do chat.
A sonda adicional de consultas de autorização do Copiloto foi bloqueada pela ferramenta. NÃO executou/NÃO passou. Não foi repetida ou contornada. Testes locais do guard não substituem essa validação nem uma resposta real da IA.

### Local e limitações

26 testes do pacote anterior, duas verificações de sintaxe e 65 verificações geométricas em Chromium isolado foram executados nesta retomada. Fixture é da base preparada, não navegador real autenticado com React/Radix/Supabase e CSS integral do sistema. Não confundir com E2E ou somar como testes novos da publicação final.
Container não conseguiu resolver GitHub por DNS; não houve checkout integral/local build ou sessão de navegador autenticada. Build final ocorreu no Railway com testes da fonte efetiva. Não houve chamada OpenAI ou entrega WhatsApp real.

### Falha recuperada

Build fb0c346e-bdab-431e-ba19-78da16c5e577 falhou por um erro de chaves no transporte simulado do novo teste monetário. Nenhuma versão defeituosa foi publicada. Corrigido em f352e12, testes repetidos e build 3d080296 aprovado. Versão anterior permaneceu ativa até a nova ficar saudável.

## Continuidade e preservações

Atualizado o semáforo canônico docs/OPERATION_STATUS.md com entregas técnicas verdes e frentes funcionais amarelas ou vermelhas conforme pendência. Próximo bloco: checkout e consistência de pedido/histórico/Dashboard/estoque. Nenhum dado histórico de preço/pedido foi corrigido por inferência.
Não houve migration neste lote. Não contornar bloqueios anteriores de segurança. Sem alteração de main, DNS, Evolution, MktOn original, Harpia, MCP, credenciais, GitHub Actions, Vercel ou agente Lovable. Preservar manual/120s dos bots.
