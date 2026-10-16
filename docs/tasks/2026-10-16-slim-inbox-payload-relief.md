# Saúde Slim | Leitura leve de anexos do Inbox, 16/10/2026

**Objetivo:** evitar que o servidor faça download repetido de anexos PDF/áudio em base64 só para exibir a lista de conversas.

Constatação read-only (nenhuma alteração nos registros): `335` atividades, `33` com `payload.media_url` inline `data:`, `18` atividades com `payload` acima de 64KB, máxima ~4.56MB. 160 atividades mais recentes somam ~11,226,455 bytes de payload integral, contra ~3,948 bytes para os textos, tipos e nomes de arquivo usados pelas prévias. Também foi encontrado `salesbot_runs.last_error` com ~1.05MB de conteúdo inline. Isso mostra uma fonte concreta de carga, mas não comprova que o arquivo PDF específico causou os 15 minutos de indisponibilidade.

Correção `2ae0b9ef07f6c02d6821bd6e7e79731240582da7`: `scripts/apply-slim-inbox-db-relief.mjs` projeta JSONB `payload->>text`, `payload->>media_type`, `payload->>file_name`, mais lead/type/time, sem transferir `media_url` no resultado agregado. Algoritmos anteriores de preview e não lidas preservados. Consulta mantém limite de 160 linhas e timeout de quatro segundos. Quando a leitura falha, não declara falsamente que a conversa foi lida.

No chat aberto, polling cai de cinco para 25 segundos e não roda com aba oculta, mantendo eventos Realtime. Arquivos/histórico não são editados. É uma mitigação: histórico de conversa ainda pode baixar inline base64 na abertura e exige futura leitura sob demanda. Não declarar proteção completa de anexos nem E2E até usuário testar.

Regressões de código e build no Railway, nenhuma chamada real de WhatsApp, nenhum envio de PDF/áudio durante os testes.
