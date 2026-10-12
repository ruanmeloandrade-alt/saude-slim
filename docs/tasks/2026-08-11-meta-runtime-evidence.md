# Meta global — evidência real do runtime

Data: 2026-08-11
Task principal: `docs/tasks/2026-08-11-meta-global-production-config.md`
PR técnica: #134 — merge `90c667e7a370acaa29998732ee2ec64197dfc0ee`
Status: **evidência somente leitura; confirma fronteira entre correção técnica concluída e gate externo Meta**

## Consulta realizada
Consulta somente leitura ao banco Supabase conectado pelo projeto Lovable. Nenhum dado foi alterado e nenhum secret foi lido/exposto.

## Estado encontrado
A tabela `integrations` possui:
- provider `meta` com status `connected`;
- duas integrações `meta_page_*` com status `connected`.

Páginas sincronizadas encontradas:
- `RBMidia` — page id `1145699401969123`;
- `MKTOn` — page id `1209270538931050`.

## Evidência do gap corrigido
Nas duas linhas de `meta_pages`, `messaging_subscribed_at` estava `null` e `messaging_error` registrava HTTP 403 da Graph API informando que, para assinar o field `messages`, era necessária a permissão `pages_messaging`.

Isso confirma que a inclusão de `pages_messaging` no OAuth da PR #134 não foi cosmética: ela corrige exatamente o bloqueio real observado no runtime.

Como o token Meta atualmente armazenado foi emitido antes dessa correção/Advanced Access, ele não passa a ter a nova permissão automaticamente. Após a Meta liberar a permissão necessária, o owner deve **reautorizar/reconectar a Meta pela MKTOn** para emitir token com o novo scope e então reassinar Messenger.

## Instagram
A conta Instagram sincronizada encontrada:
- username `rbmidia_`;
- instagram id `17841409134477005`;
- vinculada à page id `1145699401969123`.

`messaging_subscribed_at` estava `null` e o erro registrado era HTTP 400 / OAuthException code 3: `Application does not have the capability to make this API call.`

Esse erro é compatível com um gate de capability/permissão/App Review do aplicativo Meta. Não há evidência aqui de falta de handler no backend da MKTOn; os handlers e subscriptions já foram auditados na task principal.

## O que isso muda no próximo passo
Não abrir nova investigação de código para esses dois erros sem antes cumprir os gates externos abaixo:
1. concluir App Review/Advanced Access das permissões mantidas;
2. reautorizar a integração Meta pela MKTOn depois da liberação;
3. sincronizar/reassinar Página e Instagram;
4. conferir `messaging_subscribed_at` e `messaging_error` novamente;
5. só abrir bug técnico se continuar falhando depois de token novo com permission/capability aprovada.

## Encryption key
A existência de integrações Meta e `meta_page_*` persistidas mostra que o caminho criptografado de integração funcionou no runtime em execuções anteriores. O conector utilizado não permite listar o valor/nome efetivamente carregado de `INTEGRATION_ENCRYPTION_KEY` no processo atual, portanto não afirmar que o secret atual foi lido. A confirmação final deve ocorrer no reconnect/smoke sem expor o valor.

## Google Maps
A task `docs/tasks/2026-08-11-google-maps-production-key.md` permanece **5/5 encerrada administrativamente**, PR #92 mergeada, sem pendência de código conhecida. Não reabrir Maps sem reprodução concreta de falha.
