# Manual permanente — criação e revisão de SalesBots

Este documento é a referência obrigatória para qualquer criação, alteração, revisão ou geração de arquivo JSON de SalesBot/bot utilizado no ecossistema do owner.

Antes de criar um bot novo, o agente/programador deve:

1. Ler este documento.
2. Ler os bots de exemplo fornecidos pelo owner para aquele trabalho.
3. Quando houver dúvida de schema, consultar a implementação atual da plataforma/repositório antes de inventar qualquer propriedade.
4. Preservar nomes, grafias, pipelines, etapas, tags, campos e regras de negócio exatamente como recebidos.

---

## 1. Regra principal: usar o schema real

Bots devem ser montados a partir do formato real exportado/aceito pela plataforma.

- Reutilizar os tipos de bloco, propriedades, nomes de campos e estruturas observados em bots de exemplo válidos.
- Não inventar `kind`, propriedade, enum, ação, formato de pausa, validação ou configuração apenas porque parece plausível.
- Se um bloco necessário não estiver presente nos exemplos recebidos, consultar o código atual da plataforma antes de definir seu schema.
- Manter IDs únicos por bloco/opção/pausa/ação conforme o padrão do export.
- Manter `startBlockId` apontando para o início efetivo do fluxo.
- Validar todos os `nextBlockId` antes de entregar o JSON.

## 2. Mudança de etapa/status do lead

Sempre que a regra de negócio disser que o lead deve mudar de etapa, o bot deve conter explicitamente uma ação `mudar-status-lead`.

### Quando a etapa é conhecida

Preencher normalmente o destino usando o nome de pipeline e etapa informados pelo owner ou confirmados no sistema.

### Quando a etapa precisa ser escolhida manualmente depois

Não omitir a ação.

O correto é:

1. Adicionar o bloco de ação `mudar-status-lead` no ponto exato do fluxo em que a movimentação deve acontecer.
2. Deixar a configuração de destino pendente apenas no que não puder ser determinado sem acesso ao sistema.
3. Criar um bloco de **nota** solto, sem necessidade de conexão com o fluxo, posicionado visualmente acima ou próximo dessa ação.
4. A nota deve dizer claramente o que o owner precisa selecionar ao revisar/importar o bot.

Exemplo de conteúdo da nota:

> CONFIGURAR ESTA AÇÃO: mover o lead para `Comercial – Venda e Locação → Em Contato`.

Se o owner tiver informado somente a etapa, registrar exatamente essa informação. Não adivinhar pipeline.

### Regra de segurança

Nunca deixar de mover o lead apenas porque a seleção do destino não pode ser pré-configurada. A ação deve existir para impedir que a necessidade passe despercebida na revisão.

## 3. Bloco de nota

O bloco de nota é um recurso visual/documental do editor e pode ficar desacoplado do fluxo.

Usos recomendados:

- indicar etapa/pipeline que precisa ser selecionada manualmente;
- registrar configuração externa obrigatória;
- sinalizar dependência que não pode ser serializada no export;
- destacar um ponto de revisão humana antes da ativação.

A nota não deve substituir uma ação real. Quando existe uma ação necessária, criar **ação + nota**, não apenas a nota.

Ao gerar JSON, usar o schema real do bloco de nota observado na versão atual da plataforma. Se ele não estiver presente nos bots de exemplo, consultar o código da plataforma antes de gerar esse bloco.

## 4. Layout visual dos bots

Não desenhar bots complexos como uma única linha horizontal longa.

O layout deve se aproximar de um **organograma**, priorizando leitura e manutenção.

### Diretrizes

- Fluxo principal pode avançar da esquerda para a direita.
- Ramificações de resposta, erro, timeout ou classificação devem abrir para cima/baixo.
- Agrupar visualmente blocos que pertencem ao mesmo momento da jornada.
- Após uma sequência longa, quebrar o desenho em uma nova linha/faixa em vez de continuar indefinidamente no eixo X.
- Ações internas e tarefas podem ficar abaixo da mensagem correspondente quando isso melhorar a leitura.
- Notas devem ficar próximas do ponto que explicam, sem cobrir conexões.
- Deixar espaçamento suficiente entre ramos para o editor continuar legível em zoom normal.
- Em cadências longas, pensar em “fases” visuais: abertura, pressão inicial, meio da régua, recuperação, fechamento.

### Objetivo

Uma pessoa deve conseguir abrir o bot e entender rapidamente:

- onde começa;
- qual é o caminho principal;
- onde o cliente pode responder;
- onde o corretor precisa agir;
- onde o lead muda de etapa;
- onde o bot termina.

## 5. Pausas e interrupção por resposta

Quando uma régua aguarda o cliente e também possui continuidade automática por tempo, preferir uma pausa com as duas saídas quando suportado pelo schema real:

- `msg-recebida` → caminho de resposta/reativação;
- `cronometro` → continuidade da régua.

Em follow-up, reaquecimento e pós-atendimento, uma resposta do lead normalmente deve interromper a sequência automática para evitar que o bot continue enviando mensagens enquanto um humano já retomou a conversa.

Depois da resposta, aplicar as ações necessárias, como:

- tag de reativação;
- tarefa urgente para o responsável;
- mudança de etapa/status;
- encerramento da régua automática.

## 6. Bots comerciais não devem ser apenas mensagens

Quando o objetivo é melhorar performance comercial, pensar no bot como **orquestração de operação**, não somente automação de WhatsApp.

Avaliar em cada fase se faz sentido criar tarefas para o corretor/atendente, por exemplo:

- ligar para o lead;
- mandar e-mail;
- mandar áudio personalizado;
- revisar histórico do contato;
- separar imóveis/opções;
- preparar proposta;
- revisar documentação;
- retornar imediatamente após reativação;
- fazer última tentativa humana antes de encerrar a régua.

Não criar tarefas aleatórias. A tarefa deve complementar a mensagem e aumentar a chance de conversão naquele momento específico.

## 7. Cadência de reaquecimento/follow-up

Não interpretar “15 dias de cadência” como “15 mensagens” ou “uma mensagem por dia”.

A distribuição deve respeitar o objetivo comercial:

- maior pressão nos primeiros dias;
- intervalos variáveis;
- dias sem mensagem;
- possibilidade de mais de um toque no mesmo dia quando fizer sentido;
- redução ou mudança de abordagem conforme o lead esfria;
- ações humanas inseridas nos momentos de maior valor.

Sempre encerrar ou desviar a régua quando o lead responder.

## 8. Horário comercial e cálculo dos intervalos

Cadências baseadas em horas precisam preservar uma janela comercial plausível. Não basta somar pausas de 2h, 3h, 4h, 18h etc. de forma cega, porque a soma acumulada pode deslocar mensagens para madrugada ou horários inadequados.

### Premissa padrão para leads de anúncio

Quando o briefing não disser o contrário, considerar que:

- os anúncios que originam o lead rodam em horário comercial;
- portanto, o primeiro contato do lead aconteceu dentro de uma janela comercial;
- se o lead sumiu, o primeiro reaquecimento deve acontecer rapidamente, normalmente dentro de aproximadamente 1 a 2 horas, ainda dentro da mesma lógica de horário comercial.

### Como desenhar a cadência

Ao combinar pausas em horas:

1. imaginar uma hora realista de entrada do lead dentro do horário comercial;
2. calcular o horário acumulado dos próximos disparos, e não somente a duração isolada de cada pausa;
3. verificar se cada mensagem/tarefa automática ainda cairá em horário comercial;
4. se o próximo disparo projetado cair à noite, madrugada ou fora da janela definida, deslocá-lo para a próxima janela comercial adequada;
5. manter a irregularidade da cadência sem permitir que a irregularidade destrua a qualidade do horário de contato.

### Exemplo de raciocínio

Se um lead entrou às 14h e o bot fará um toque 2h depois, o contato às 16h é coerente. Se a sequência posterior somar um intervalo que levaria a mensagem para 01h da manhã, o correto não é disparar à 01h: a cadência deve ser reorganizada para retomar em horário comercial no dia seguinte.

### Regra prática

**Picotar intervalos é permitido e desejável quando melhora a cadência; picotar sem acompanhar o relógio acumulado não é permitido.**

Quando a plataforma oferecer recurso nativo de janela de envio/horário permitido, preferir esse recurso. Quando o export trabalhar apenas com cronômetros relativos, projetar manualmente a cadência para que, a partir da premissa de entrada em horário comercial, os disparos permaneçam em horários adequados.

Tarefas humanas também devem respeitar essa lógica sempre que possível: não criar uma tarefa de “ligar agora” em um ponto da régua que previsivelmente será alcançado de madrugada.

## 9. NPS

Para NPS, usar validação numérica por faixa em vez de criar uma opção individual por nota.

Escala padrão de 0 a 10:

- 0 a 6 → detrator;
- 7 a 8 → neutro;
- 9 a 10 → promotor.

No editor, preferir a validação de número no formato equivalente a **“está entre X e Y”**.

Isso reduz o tamanho do bloco e torna a lógica mais clara e sustentável.

## 10. Validações

Quando a plataforma permitir validar a resposta diretamente, usar o tipo de validação mais específico disponível.

Preferências gerais:

- números/faixas → validação numérica;
- alternativas fechadas → validação correspondente às opções reais;
- texto livre → usar somente quando o fluxo realmente depende de texto livre;
- evitar “contém” quando há um operador mais preciso para o caso.

Sempre prever o que acontece com uma entrada inválida quando o bot depende de resposta estruturada.

## 11. Ações, tags e campos

Usar ações somente com finalidade operacional clara.

Exemplos:

- adicionar/remover tag;
- definir campo personalizado;
- criar tarefa;
- mudar status/etapa do lead;
- iniciar outro SalesBot;
- fechar conversa quando isso fizer parte da regra definida.

Não alterar pipeline/etapa/tag/campo por inferência se o owner não tiver autorizado ou se os exemplos não sustentarem essa decisão.

## 12. Nomes de empresas e copy

A grafia da marca é requisito funcional do bot.

Antes de entregar:

- pesquisar no JSON inteiro por nomes antigos/incorretos;
- confirmar o nome exato informado no briefing;
- preservar acentos e capitalização quando fazem parte da marca;
- não reaproveitar copy de outro cliente sem substituir e revisar todas as referências.

Exemplo registrado em 2026-08-28: **Hárpia Imobiliária**, com H.

## 13. Revisão antes da entrega

Checklist obrigatório:

- [ ] Li este manual.
- [ ] Li os bots de exemplo enviados para a tarefa.
- [ ] Usei somente schema confirmado.
- [ ] `startBlockId` está correto.
- [ ] Todos os `nextBlockId` apontam para blocos existentes.
- [ ] IDs internos não colidem.
- [ ] A copy contém a marca correta.
- [ ] Pausas têm saídas coerentes.
- [ ] Calculei o horário acumulado das pausas e evitei disparos previsíveis fora do horário comercial.
- [ ] Resposta do cliente interrompe a régua quando necessário.
- [ ] Tarefas humanas foram consideradas.
- [ ] Toda mudança de etapa possui bloco `mudar-status-lead`.
- [ ] Se a etapa ficou pendente, existe nota visual informando exatamente o que configurar.
- [ ] O desenho está legível em formato de organograma e não como uma linha reta excessivamente longa.
- [ ] Validações usam o operador mais adequado.
- [ ] O arquivo JSON abre e é sintaticamente válido.

## 14. Fonte de verdade e precedência

Ordem de precedência para criar um bot:

1. instrução explícita mais recente do owner;
2. bots de exemplo enviados para a tarefa;
3. este manual;
4. implementação/schema atual da plataforma;
5. somente depois, inferência técnica mínima e claramente documentada.

Quando uma regra nova for ensinada pelo owner e tiver utilidade recorrente, atualizar este documento para incorporá-la.
