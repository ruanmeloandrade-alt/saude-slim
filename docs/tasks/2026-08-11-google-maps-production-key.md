# Task — Google Maps em domínio próprio

Data: 2026-08-11
Branch atual: `fix/google-maps-own-key-only-v4`
PRs anteriores: #92 e #148 já mergeadas; não reescrever histórico.
Status: **reaberto — correção v4 pronta para publicação/smoke; não encerrar sem runtime verde**

## Objetivo
Fazer o Google Maps funcionar de verdade no ambiente publicado da MKTOn e no domínio próprio `mkton.io`, usando exclusivamente a browser key própria da MKTOn no runtime do mapa.

## Motivo da reabertura
O owner reproduziu novamente em produção a mensagem da plataforma de hospedagem: “O Google Maps não vai carregar... funciona automaticamente na sua URL lovable.app. Para usar no seu próprio domínio, conecte sua própria chave da API do Google Maps.” Esse texto não existe no repositório MKTOn, indicando gate externo da integração gerenciada pela Lovable.

## Causa técnica identificada
Mesmo após a PR #148, o runtime ainda referenciava `VITE_LOVABLE_CONNECTOR_GOOGLE_MAPS_BROWSER_KEY` / `VITE_LOVABLE_CONNECTOR_GOOGLE_MAPS_TRACKING_ID` como fallback. Isso mantinha o mapa associado ao conector Google Maps gerenciado pela Lovable e permitia que a plataforma aplicasse o gate de domínio próprio.

## Escopo fechado — 7 verificações
1. [x] Confirmar consumidor real: `src/components/meta/MapLocationSelector.tsx`.
2. [x] Confirmar `.env.production` com `VITE_GOOGLE_MAPS_BROWSER_KEY` própria da MKTOn.
3. [x] Confirmar que o aviso reproduzido pelo owner não existe no código MKTOn.
4. [x] Confirmar que o runtime ainda carregava configuração do conector Lovable como fallback.
5. [x] Remover do resolver de runtime toda dependência de `VITE_LOVABLE_CONNECTOR_GOOGLE_MAPS_*`; manter somente `VITE_GOOGLE_MAPS_BROWSER_KEY` e `VITE_GOOGLE_MAPS_TRACKING_ID` opcional.
6. [ ] Mergear/publicar a correção v4 e confirmar que a Lovable sincronizou o merge correto.
7. [ ] Smoke real: mapa + Places + seleção/pino no ambiente publicado; só então encerrar e atualizar handoff/status.

## Configuração externa já entregue pelo owner
- domínio: `mkton.io`;
- referrers configurados/orientados:
  - `https://mkton.io/*`
  - `https://www.mkton.io/*`;
- APIs esperadas: Maps JavaScript API, Places API e Places API (New);
- browser key própria já está em `.env.production`.

Não pedir nova chave nem nova configuração ao owner sem erro concreto do Google após esta correção.

## Correção v4
- `src/lib/google-maps-browser-config.ts` agora resolve somente a chave própria da MKTOn;
- nenhuma variável `VITE_LOVABLE_CONNECTOR_GOOGLE_MAPS_*` participa do runtime do mapa;
- teste contratual atualizado para garantir independência do conector de hospedagem;
- `MapLocationSelector` continua carregando diretamente `https://maps.googleapis.com/maps/api/js` com a chave resolvida;
- `vite.config.ts` permanece sem override de chave Google Maps.

## Regra de execução
- Código/configuração versionada: somente GitHub.
- Lovable pode ser usada para leitura/publicação/deploy e acesso passivo ao runtime, sem `send_message`/chat do agente.
- Não encerrar administrativamente sem smoke real.

## Critérios de aceite
- mapa carrega no ambiente publicado aplicável;
- busca Places funciona;
- escolha de endereço posiciona pino;
- clique/drag do pino funciona;
- nenhuma mensagem/gate da Lovable sobre chave Google Maps aparece no domínio próprio;
- se houver novo erro, registrar o erro concreto do Google (referrer/API/billing/chave) e agir sobre essa evidência.
