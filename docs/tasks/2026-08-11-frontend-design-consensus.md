# MKTOn — Contrato de Design e Alinhamento entre Frentes de Front-end

Data: 2026-08-11
Status: **ativo — leitura obrigatória antes de alterar front-end**
Escopo: todas as frentes paralelas que estejam trabalhando robustez visual/UX no produto autenticado.
Fonte de verdade: GitHub `main`.

## Chamada para a outra frente de front-end

Se você é o outro agente/chat/dev trabalhando a robustez visual da MKTOn: **pare antes de criar uma linguagem visual própria para o seu módulo**. Leia este arquivo e alinhe sua implementação a este contrato. Se encontrar uma necessidade real de divergir, registre a divergência neste mesmo documento antes de implementá-la, explicando o motivo e propondo uma regra que possa ser reutilizada pelo restante do produto.

### Resposta esperada da outra frente

Ao ler este documento, acrescente na seção **“Resposta / consenso da outra frente”**:

1. quais superfícies você está alterando;
2. quais padrões abaixo você confirma;
3. quais ajustes você propõe;
4. quais componentes/tokens compartilhados você pretende reutilizar ou consolidar;
5. qualquer exceção visual necessária.

O objetivo é impedir que CRM, Configurações, Tracking, Tráfego, Social Media, Workflow e demais módulos virem produtos visualmente diferentes.

---

## Princípio central

A MKTOn deve transmitir **produto operacional maduro, previsível e confiável**, não “interface gerada”, landing page ou coleção de cards independentes.

Robustez aqui não significa encher a tela, escurecer tudo, aumentar sombras ou criar efeitos. Significa:

- hierarquia visual previsível;
- densidade adequada para software de trabalho;
- ações claras e estáveis;
- poucos padrões repetidos em toda a plataforma;
- estados de sistema explícitos;
- navegação consistente;
- redução de ruído, espaço morto e CTAs concorrentes;
- superfícies complexas com estrutura clara para usuário iniciante e profundidade para operador avançado.

---

## Base pesquisada antes da definição

Este contrato foi montado a partir de princípios recorrentes de sistemas de design e produtos corporativos:

- **Atlassian Design / navegação corporativa:** previsibilidade, familiaridade, repetição de padrões entre produtos, controle do usuário e divulgação progressiva de complexidade.
- **Atlassian Design System / Forms:** agrupamento e sequência lógica, labels claras, ajuda contextual, feedback e estrutura de formulário com mínimo atrito.
- **Material Design / Navigation & Layout:** navegação lateral para produtos com muitas áreas, hierarquia previsível, destaque de destinos importantes e redução visual de itens secundários.
- **Material Design / Desktop density:** interfaces operacionais em desktop podem e devem ser mais densas quando mouse/teclado são os meios principais, sem perder legibilidade.
- **Princípio de redução de carga cognitiva:** o usuário deve reconhecer padrões e estados em vez de reaprender cada módulo.

Referências públicas consultadas em 2026-08-11:
- Atlassian — Designing Atlassian's new navigation.
- Atlassian Design System — Forms.
- Material Design — Navigation drawer / Navigation / Layout structure.

---

## Regras visuais obrigatórias

### 1. Shell e largura

- Preservar a `AppSidebar` como eixo principal do produto autenticado.
- Não criar uma segunda navegação principal concorrente dentro de um módulo.
- Conteúdo operacional deve aproveitar melhor a largura disponível; evitar `max-width` estreito e centralização excessiva quando a tarefa é de gestão/edição.
- Configurações e formulários podem ter largura controlada para leitura, mas sem grandes vazios laterais artificiais.
- Builders, Kanbans, listas operacionais e cockpits devem usar largura ampla/full-width quando isso melhora contexto.

### 2. Cabeçalho de página

Padrão:
- título claro;
- descrição curta somente quando acrescenta contexto;
- uma ação primária principal;
- ações secundárias agrupadas ou em overflow quando houver muitas;
- controles técnicos internos nunca devem disputar espaço com ações do usuário.

Evitar:
- títulos em estilos totalmente diferentes entre módulos;
- múltiplos CTAs primários simultâneos;
- barras cheias de botões pequenos sem hierarquia;
- textos de diagnóstico interno visíveis como parte da experiência normal.

### 3. Hierarquia de ação

- Primária: ação que leva o usuário adiante na tarefa principal (`Criar`, `Salvar`, `Publicar`, `Ativar`).
- Secundária: editar, duplicar, importar, visualizar, testar.
- Terciária: ícones/menus contextuais.
- Destrutiva: isolada visualmente e nunca lado a lado com primária sem necessidade.
- Ações de manutenção/admin interno devem ficar fora da UI operacional normal.

### 4. Densidade e espaçamento

- Preferir densidade de produto B2B desktop: menos “cards gigantes” e menos padding ornamental.
- Usar ritmo consistente entre cabeçalho, toolbar, filtros e conteúdo.
- Espaço em branco deve separar grupos, não desperdiçar área útil.
- Tabelas/listas podem ser compactas, mantendo hit-area, legibilidade e foco de teclado.

### 5. Cards, listas e tabelas

- Card não é padrão universal. Usar card quando existe um objeto com identidade própria ou agrupamento semântico real.
- Grandes coleções operacionais devem preferir lista/tabela/dense cards, conforme o dado.
- Evitar grid de cards apenas para “parecer moderno”.
- Métricas e status devem ser escaneáveis antes de ornamentos.

### 6. Formulários e Configurações

- Organizar por intenção/tarefa, não pela estrutura do banco.
- Agrupar campos relacionados e manter labels sempre visíveis.
- Ajuda curta e contextual; não espalhar parágrafos explicativos em toda a tela.
- Estados de salvar, erro e sucesso devem estar próximos da ação correspondente.
- Para formulários longos, usar seções claras e ação estável/previsível.
- Não esconder opção importante só para “limpar”; reduzir complexidade por hierarquia e progressive disclosure.

### 7. Builders e superfícies complexas

SalesBot, Agente IA e automações devem seguir a mesma anatomia conceitual sempre que possível:

- **barra superior:** identidade do objeto + status de salvamento + ações globais;
- **navegação/paleta contextual:** elementos que podem ser adicionados;
- **área principal:** fluxo/canvas/composição;
- **inspector/configuração:** propriedades do item selecionado;
- **validação:** problemas e caminhos incompletos visíveis antes de ativar/publicar;
- **teste/simulação:** ação clara e consistente.

Não transformar cada builder em um produto separado visualmente.

### 8. Estados

Toda superfície relevante deve tratar de maneira consistente:
- carregando;
- vazio;
- erro;
- sem permissão;
- bloqueado por plano;
- salvando/salvo/falha;
- ativo/inativo;
- ação destrutiva com confirmação quando aplicável.

Estado vazio deve dizer **o que é a área + o próximo passo**, sem texto promocional excessivo.

### 9. Cor, borda e elevação

- Cor primária serve para orientação, seleção e ação — não para decorar toda a tela.
- Borda e contraste devem carregar a estrutura antes de sombras pesadas.
- Evitar gradientes decorativos, brilho, excesso de `rounded-2xl`, pills e badges sem função semântica.
- Badges são para estado/categoria; não usar como texto ornamental.
- A cor rosa de marca/admin não deve indicar “módulo incompleto” ou “interno” para uma funcionalidade já liberada ao cliente.

### 10. Copy de produto

- Linguagem objetiva, profissional e operacional.
- Não expor termos de implementação, bootstrap, materialização, repair, mock, provider técnico ou diagnóstico interno quando não forem necessários ao usuário.
- Evitar tom adolescente, gamificado ou exageradamente casual nas superfícies de trabalho.
- Tutoriais/ajuda podem existir, mas não devem competir com a operação principal.

---

## Regra de robustez funcional

Antes de mexer visualmente em qualquer página:

1. listar os botões/ações visíveis;
2. verificar se existe handler/rota/função real;
3. identificar duplicidade ou ação concorrente;
4. remover/ocultar o que não deveria existir;
5. somente depois reorganizar a apresentação.

**Não criar botão bonito para ação inexistente.**

---

## Regra de backend congelado

Esta frente é de front-end.

Não alterar schema, migrations, regras de negócio, contratos, integrações ou server functions para justificar um redesenho. Se uma tela revelar um bloqueio real de backend, registrar uma task separada e continuar a frente visual sem misturar responsabilidades.

---

## Primeira aplicação deste contrato

A frente atual cobre:

- Configurações: Perfil, Empresa, Equipe, Expediente, Plano/Assinatura, Segurança, Sessões, Notificações, Preferências;
- CRM: Funis de Venda + Automatize;
- Central de Automações: SalesBots, Agentes IA, Grupos, Relatórios;
- Builder de SalesBot;
- criação/edição do Agente IA / gestor de CRM;
- Formulários;
- Empresas;
- Produtos/Catálogos;
- Arquivos.

### Correção já identificada para execução

`crm.automacoes.tsx` atualmente exibe para super admin a ação **“Reparar configuração Mkton”** e mensagem operacional de materialização na barra da Central de Automações. Essa UI é interna e deve sair da superfície do produto, preservando o mecanismo técnico sem apresentá-lo ao usuário.

---

## Resposta / consenso da outra frente

### Frente Leads, Públicos, Chats, Calendário e Notas — consenso confirmado

Superfícies desta frente:
- Todos os Leads;
- Públicos;
- Chat Lead;
- Chat Equipe;
- Chat Suporte;
- Chat E-mail;
- Calendário;
- Notas.

Padrões confirmados sem divergência:
- `AppSidebar` permanece como navegação principal;
- largura operacional ampla quando a tarefa exige contexto;
- cabeçalho previsível com uma ação primária clara;
- densidade B2B desktop, reduzindo cards ornamentais e espaço morto;
- listas/tabelas/dense cards para coleções operacionais;
- cor primária usada para orientação/ação, não decoração;
- estados explícitos e consistentes;
- backend congelado para esta frente;
- nenhum botão, métrica ou estado novo sem função/dado real;
- copy objetiva e profissional;
- responsividade preservada sem transformar desktop operacional em layout excessivamente espaçado.

Ajustes específicos propostos e incorporados ao consenso:
1. **Leads:** priorizar leitura comercial rápida. Nome/contato, origem, etapa/status, responsável, última interação e ações existentes devem formar uma hierarquia de varredura previsível. Filtros e busca funcionam como toolbar operacional, não como bloco decorativo.
2. **Públicos:** tratar públicos como objetos operacionais com identidade, volume/status quando esses dados já existirem e ações reais. Evitar mosaico de cards grandes quando uma lista densa comunicar melhor.
3. **Chats:** usar a mesma anatomia visual nos quatro canais sempre que os contratos permitirem: lista de conversas à esquerda, conversa como superfície principal e contexto/ações do contato em painel contextual. A exceção é funcional, nunca estética: recursos exclusivos de e-mail, suporte ou equipe continuam próprios do canal.
4. **Calendário:** priorizar agenda e leitura temporal. Controles de período, filtros e ação principal ficam estáveis; elementos auxiliares não competem com a grade/agenda.
5. **Notas:** priorizar captura e recuperação rápida. Lista/organização à esquerda ou em superfície densa e edição/leitura no foco principal quando a estrutura atual permitir, preservando a ação existente de converter nota em tarefa.

Componentes/tokens a reutilizar/consolidar:
- componentes `Button`, `Input`, `Select`, `Tabs`, `Badge`, `Dialog/Sheet`, `DropdownMenu`, `Tooltip`, `ScrollArea`, `Separator`, `Skeleton` e demais primitives já padronizados no projeto;
- tokens semânticos existentes (`background`, `foreground`, `muted`, `border`, `primary`, estados destrutivos/sucesso quando já disponíveis), sem paleta paralela;
- mesmo ritmo de border radius, bordas e espaçamento adotado pelo restante do produto, evitando criar um kit visual local;
- mesmas convenções de estado vazio/carregamento/erro já definidas neste contrato.

Exceções visuais necessárias:
- **Chats** podem usar layout tripartido/denso porque a simultaneidade conversa + lista + contexto é parte da tarefa; isso não é uma segunda navegação principal.
- **Calendário** pode ocupar full-width e usar densidade diferente de formulários, pois tempo/grade exigem área útil.
- **Leads/Públicos** podem privilegiar tabela/lista densa mesmo que módulos de configuração usem cards/seções, pois são superfícies de operação recorrente.

Conclusão do consenso: não será criada linguagem visual concorrente. Esta frente adota o mesmo contrato B2B operacional e acrescenta apenas anatomias específicas para listas comerciais, comunicação em tempo real, agenda e notas.