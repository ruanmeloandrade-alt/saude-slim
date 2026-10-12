# F2 — MKTOn Telegram MCP — Telegram Gateway e Multimodal

Chave: `MKTON-TELEGRAM-MCP-F2-TELEGRAM-GATEWAY`  
Branch: `work/telegram-mcp-f2-telegram-gateway`  
Bot oficial: `@mktoncontrol_bot`  
Status inicial: 🟡 ESCOPO CRIADO / PRONTA PARA EXECUÇÃO

## Objetivo

Implementar a interface única do Telegram, responsável por receber updates, baixar/validar mídias, normalizar entradas, encaminhar ao backend e devolver respostas sem conter regra de autorização ou negócio.

## Dentro do escopo

- webhook de produção;
- validação de origem/secret de webhook quando suportado;
- deduplicação por `telegram_update_id`;
- suporte a texto;
- áudio/voice;
- foto/imagem;
- vídeo;
- documentos/anexos;
- callbacks/botões;
- comandos operacionais mínimos: `/start`, `/help`, `/status`, `/cancel`;
- fluxo de pareamento iniciado por deep link/código recebido;
- normalização para o Request Envelope canônico;
- download temporário de mídia com limites de tamanho/tipo;
- limpeza/expiração de temporários;
- resposta longa fracionada de forma segura;
- mensagens de erro sem expor stack/secret;
- retry controlado de envio;
- correlation id;
- UX para “processando”, confirmação e erro;
- locale PT-BR como padrão, sem impedir futura internacionalização.

## Fora do escopo

- decidir se usuário tem acesso;
- selecionar workspace;
- guardar API keys;
- executar ferramenta;
- decidir risco;
- transcrever/interpretar semanticamente áudio/imagem;
- regra de CRM.

## Contrato com F3/F4

F2 envia Request Envelope.  
F3 resolve identidade/sessão/workspace/permissões.  
F4 interpreta a solicitação e executa via Executor/MCP.  
F2 apenas apresenta o resultado ao Telegram.

## Regras obrigatórias

- não aceitar bot alternativo por cliente;
- token do bot somente por secret;
- update duplicado jamais pode criar duas execuções;
- arquivo recebido nunca vira comando de shell;
- mídia deve ser tratada como conteúdo não confiável;
- falha downstream deve gerar resposta controlada, não loop;
- nenhum secret em mensagens/logs.

## Critérios de aceite

- `/start` responde;
- webhook aceita update legítimo;
- update repetido é idempotente;
- todos os tipos de mídia do escopo são normalizados;
- cancelamento propaga `request_id`;
- callback de confirmação carrega referência inequívoca da ação;
- respostas não vazam stack trace/secret;
- gateway funciona com mocks de F3/F4.

## Testes mínimos

- texto;
- voice/audio;
- foto;
- vídeo;
- documento;
- callback;
- update duplicado;
- arquivo grande/unsupported;
- timeout downstream;
- retry de envio;
- cancelamento;
- payload malformado.

## Handoff para F5

Entregar contratos, fixtures de updates, mocks usados, limites aplicados, comandos de teste e evidência dos casos acima.
