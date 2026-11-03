# Inbox em janela estreita

Branch `fix/slim-inbox-responsive-20261103`, base publicada `e3018aa` / PR #22. A conferência de produção encontrou o cabeçalho espremido em janela estreita e a área de mensagem reduzida pelos controles.

Mudança somente de apresentação: abaixo de 768px, ações do cabeçalho ficam em linha própria; o chat considera os 48px do cabeçalho do aplicativo; campo de mensagem usa uma linha inteira, controles se distribuem abaixo, preservando a posição inicial dos seletores de automação. Cache da folha de marca atualizado. Sem alteração em envio, backend, dados, autenticação ou automações.

Validação: build cliente/SSR/Nitro, inspeção do layout na largura afetada, sem rolagem horizontal e campo de mensagem dentro da altura da janela. Publicação e conferência final em andamento. Arquivos: folha de marca, referência da folha no root, este registro e CODEX_STATUS.md.

Concluído: PR #23 / `88ad40f`, deployment `c4833054-fec0-4082-8658-ca2311e58fd9` SUCCESS. Conferência autenticada em produção: desktop 1280px preservado; 390×844 com campo de 318px, bottom 750px, cabeçalho sem esmagamento, sem excesso horizontal. CSS `20261103-inbox2`. Viewport restaurado. Evidências `Inbox-publicado.jpg`, `Inbox-mobile-publicado.jpg` e `Verificacao-inbox.json` nos outputs da tarefa.
