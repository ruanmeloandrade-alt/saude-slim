# Saúde Slim | Mídias históricas carregadas sob demanda

Checkpoint 16/10/2026, exclusivamente Saúde Slim. Código funcional `d30552fb353f7e6686e7f1285392d43095b7f37f`, branch `restauracao/sistema-completo-20261014`. Railway deploy `f6914a53-fe54-4341-bb95-195d73ec19fe` SUCCESS, um container online, zero travados, healthcheck 1/1 aprovado. Supabase SQL continuou respondendo após publicação.

## Problema

Existem 33 atividades de conversa com `payload.media_url` como data URL em base64 e arquivos históricos de até aproximadamente 4,56 MB. A leitura anterior da conversa aberta fazia `select id,type,payload,occurred_at` em até 50 registros a cada 25 segundos enquanto a aba estava visível, carregando vários anexos por vez. A tela de detalhes do lead com includeActivities=true também retornava payload completo. A lista geral de prévias já havia recebido otimização na entrega anterior.

## Entrega

- `src/lib/slim-inbox-lazy-media.core.ts` projeta metadata JSONB sem `payload.media_url` e converte atividades preservando tipo, nome, MIME, duração, texto, indicadores de leitura/exclusão e reações.
- `listLeadActivities` e `getLeadDetail` com histórico utilizam essa projeção, sem anexar base64 ao resultado inicial.
- `loadSlimLeadActivityMedia`, nova ação de leitura autenticada, exige IDs do lead e da atividade mais workspace ativo, checa tipo e exclusão e devolve apenas uma URL armazenada permitida (HTTPS/HTTP ou data URL de mídia com limite de tamanho), sem expor os outros campos da atividade. Não há inserções, updates ou deletes nessa ação.
- O Inbox desenha o botão **Abrir mídia** apenas quando é necessário resolver o anexo. Uma ação manual única usa mutation sem retry automático. Figurinha sem URL armazenada conserva a opção de resolução existente, mas apenas após clique.
- Eventos Realtime são normalizados para não guardar uma data URL inline no estado React; hot/cold cache legado também é sanitizado na leitura. Links já existentes em conversa de grupos continuam inalterados. Áudios e PDFs deixam de ser baixados todos ao abrir uma conversa.
- A seleção de preview leve, os limites de 160 atividades/4s, o polling de 25 segundos somente com aba visível, os gatilhos do Funil e todos os demais caminhos anteriores continuam publicados.

## Validação

20 verificações focadas aprovadas: projeção de metadata; texto, áudio, documento, reação, deleção e transcrição; URLs seguras, formatos e cache; funcionamento do botão somente ao clique; compatibilidade de TS/TSX e aplicação idempotente; extração e execução do endpoint real com banco substituído para confirmar workspace, lead, atividade, mensagem apagada e URL inválida. As regressões anteriores, build Vite de cliente/servidor e healthcheck Railway também passaram.

O banco real foi apenas consultado após deploy e manteve os 33 anexos inline existentes, zero eventos de movimentação e zero jobs automáticos no momento observado. **Não foi testado o download real ou reprodução de arquivo na sessão autenticada do usuário, nem foi feita transmissão real via WhatsApp.**

## Limites e continuidade

Arquivos permanecem no armazenamento de origem; não houve migração para bucket, remoção, deduplicação ou alteração dos anexos antigos. Mídia sem URL acessível ainda pode apresentar erro após o clique; URL externa assinada que venceu continua sujeita às regras do provedor. Eventos Realtime ainda podem transportar JSONB completo antes da sanitização no cliente. Fica pendente a homologação autenticada e revisão posterior dessa entrega em transportes e de eventuais URLs expiradas.

Separado deste escopo, mini-Inbox da ficha do Funil, exclusão/edição de pedidos e outras migrações previamente recusadas não foram tentadas ou contornadas. A configuração por prompt dos agentes de grupos permanece, sem executor automático implementado nesta rodada.

Rollback via novo commit que reverta a integração frontend/API, sem force-push e sem mexer no banco. Todos os dados foram preservados.
