# Frente 05 — Tracking, Gestor de Tráfego e Social Media — MKTOn

Status: **🔴 NÃO INICIADA**
Chave canônica: `MKTON-F05-TRACKING-MIDIA`
Gatilho legado aceito: `Inicie a Frente 05 da MKTOn.`
Dependência: Frente 01 🟢; Frente 00 homologada o suficiente para Meta/Google reais.

Ao receber somente a chave, ler `FRONT_KEYS.md`, `AGENTS.md`, `PROJECT_STATUS.md`, Plano Mestre e este arquivo; continuar do último checkpoint sem pedir contexto repetido ao owner.

## Papel do chat
Atue como especialista sênior em tracking, atribuição, paid media, Meta/Google Ads, social media, UTMs, conversões, analytics e engenharia de dados. Preserve tudo que já funciona e corrija somente gaps comprovados. Nenhuma métrica comercial pode ser inferida sem vínculo determinístico.

## Escopo
### Tracking — visual e performance
- preservar core funcional;
- reorganizar `Outras fontes conectadas` e mostrar somente conectadas;
- paginação de eventos 10/20/50;
- melhorar leitura sem reescrever o motor.

### Tracking — contratos críticos
- fechar incompatibilidade entre modelo UTM do Tracking e CRM;
- unificar atribuição hoje fragmentada entre Meta Lead Events, custom_data/UTM e outras fontes;
- materializar/corrigir runtime necessário para atribuição Social quando comprovadamente ausente;
- validar identidade anon -> lead;
- validar UTMs Meta/Google/orgânico ponta a ponta;
- eventos personalizados: criação, instrução/token/snippet, recebimento e correlação;
- conversões: definição + ocorrência real;
- testador ao vivo: URL -> navegação -> eventos em tempo real;
- diagnóstico geral e distribuição de tracking com dados reais.

### Central de Criativos — contrato compartilhado
- identidade única do criativo na MKTOn;
- criativo compartilhável entre Tráfego e Social;
- aplicação automática de identificação/UTM ao usar o criativo;
- contexto pago/orgânico muda a distribuição, não a identidade-base;
- fechar caminho criativo -> uso -> clique/evento -> lead -> conversão/receita.

### Gestor de Tráfego
- relatório PDF gera download imediato; envio WhatsApp/e-mail/texto/PDF é opção separada;
- sincronização de estado/métricas precisa refletir provider real com política de atualização clara;
- corrigir estados stale como anúncio ativo quando já pausado/sem verba;
- edição de campanha/conjunto/anúncio deve exibir apenas campos realmente editáveis naquele objeto/estado/API;
- reorganizar navegação: Públicos absorve Públicos Meta + Personas + Estratégias;
- Comparativo de Criativos IA vai para Central de Criativos;
- Automações Executáveis permanece separada e erro `Forbidden` deve ser diagnosticado;
- automações manuais existentes: validar condições/ações reais;
- IA de automações: prompt próprio + refinar prompt, mantendo regras executáveis.

### Social Media
- usuário final não vê Ideogram/motores internos nem mensagens sobre ausência de geração;
- admin pode manter capacidades experimentais específicas conforme feature/role;
- agendamento real para formatos suportados: Feed, Story, Reels, carrossel, imagem, vídeo;
- **gestão de posts agendados:** qualquer post agendado exibido no calendário/listagem precisa ser clicável e abrir seus detalhes; permitir **editar** os campos ainda alteráveis antes da publicação e **excluir/cancelar** o agendamento, com confirmação explícita, atualização imediata da UI e sincronização do estado persistido/provider quando aplicável; validar se a ausência atual é regressão ou funcionalidade nunca concluída, mas o comportamento final é requisito obrigatório;
- `Planejamento do mês` -> `Planejamento`, período configurável;
- planejamento gera rascunho/proposta, nunca agenda/publica sem aprovação;
- impedir datas retroativas;
- corrigir item do calendário que não abre (`This page is disallowed`);
- remover agendamentos indevidos do owner somente quando execução desta frente identificar com segurança os registros gerados pelo planejador;
- múltiplas marcas por workspace;
- Campanha Orgânica: remover superfícies atuais de Arte Estratégica/Ideogram, aumentar mídia, manter título interno/legenda/hashtags/primeiro comentário e IA auxiliar por campo;
- geração experimental para admin: uma imagem por vez e formato conforme destino, nunca carrossel inteiro de uma vez;
- Banco de Ideias: preservar estrutura e aplicar mesma regra unitária de imagem quando habilitada;
- Novo Post: validar fluxo real;
- Chat Mídia: UI simples; KPIs configuráveis;
- Copiloto: respostas úteis sobre plataforma e ordenação cronológica correta.

## Regras de atribuição
- Meta/Google/Social não recebem crédito de venda por nome parecido, filename ou heurística fraca.
- Sem chave determinística/UTM/evento confiável, mostrar `sem atribuição comprovada`.
- Receita/ROAS/CAC só quando spend e resultado comercial estiverem vinculados de forma defensável.

## Critérios de aceite
Testes com eventos reais/simulados controlados, consultas de runtime, contrato de UTM/conversão, regressão dos painéis e smoke de provider quando disponível. Não chamar cache stale de real-time sem definir SLA de atualização. GitHub Actions não é gate; seguir validação direta de `AGENTS.md`/`FRONT_KEYS.md`.

Para Social Media, o aceite inclui obrigatoriamente um smoke CRUD do agendamento: criar/agendar -> localizar no calendário/listagem -> abrir -> editar -> persistir alteração -> excluir/cancelar -> confirmar remoção no runtime/UI, sem deixar publicação órfã ou estado divergente no provider.

## Handoff
Atualizar este arquivo, Plano Mestre e `PROJECT_STATUS.md`; documentar o contrato final de atribuição para Frente 03 e Frente 06.