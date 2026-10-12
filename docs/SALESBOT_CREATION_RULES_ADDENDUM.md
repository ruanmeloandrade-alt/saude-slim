# Adendo obrigatório — regras ensinadas pelo owner para SalesBots

Este arquivo complementa `docs/SALESBOT_CREATION_RULES.md` e deve ser lido junto com o manual principal antes de criar ou revisar SalesBots.

Atualizado em 2026-08-31.

## 1. Proibido criar pausa intermediária “até iniciar expediente” sem necessidade real

Não inserir automaticamente uma pausa `até iniciar expediente` depois de uma pausa de cronômetro apenas como proteção de horário.

Quando a cadência já tiver sido planejada para horário adequado, o padrão correto é:

`mensagem → pausa com (msg-recebida OU cronometro) → próximo bloco`

A saída do `cronometro` deve apontar diretamente para a próxima mensagem/ação prevista.

Só usar janela/expediente se:

1. houver necessidade real;
2. o schema estiver confirmado;
3. houver entrada e saída completamente conectadas;
4. o recurso não criar uma ponta morta.

## 2. Nenhuma ponta solta

Antes da entrega, validar todas as saídas de:

- `pausar`;
- `condicao`;
- `validacao`;
- `round-robin`;
- `iniciar-salesbot`;
- `iniciar-ia`;
- ações de mudança de etapa/status.

Somente um bloco terminal intencional pode ficar sem `nextBlockId`.

Todo caminho que inicia outro SalesBot ou Agente IA deve continuar para um bloco `encerrar-bot` no bot atual, salvo se a implementação real da plataforma exigir explicitamente outra semântica e isso tiver sido confirmado no código.

## 3. Toda espera por resposta precisa prever não resposta

Sempre que o bot aguardar uma mensagem do cliente e existir continuidade automática:

- `msg-recebida` → trata a resposta;
- `cronometro` → segue a régua/timeout.

Nunca deixar o lead parado indefinidamente em uma pausa sem saída de timeout.

## 4. Primeiro atendimento deve ser curto

Bots de recepção/primeiro atendimento devem ficar, como regra prática, em **3 a 4 interações relevantes** antes de encaminhar para humano ou IA.

Não transformar o primeiro atendimento em uma entrevista longa.

## 5. Copy comercial não expõe operação interna

Em bots imobiliários, escrever como corretor/vendedor.

Não falar para o cliente sobre:

- distribuição interna;
- usuário responsável;
- contexto salvo;
- tags;
- funil;
- etapa;
- automação;
- lógica do CRM.

## 6. Regra de revisão estrutural

Além de validar se todos os IDs referenciados existem, revisar visualmente se cada ramo efetivamente chega a um destino operacional.

Checklist mínimo:

- [ ] zero referências quebradas;
- [ ] zero pontas soltas;
- [ ] zero pausas intermediárias sem função real;
- [ ] toda resposta tem destino;
- [ ] todo timeout tem destino;
- [ ] todo caminho termina ou é explicitamente encaminhado;
- [ ] o bot é legível no editor como organograma.
