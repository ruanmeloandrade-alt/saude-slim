# Cabeçalho do Inbox cortado — 24/10/2026

Alvo exclusivo: ruanmeloandrade-alt/saude-slim, produção restauracao/sistema-completo-20261014, base 58d0593. Branch fix/slim-inbox-header-20261024. Evidência: imagem fornecida pelo usuário, iNBOZ.PNG. Não usar Chrome ou mouse.

Causa: o ChatThread fixa o cabeçalho em h-16 (64 px). A informação adicional LeadWhatsappOrigin inserida durante a geração do código ultrapassa essa altura e é centralizada fora dos limites, cortando o nome e invadindo o histórico.

Escopo: altura mínima com crescimento natural, espaçamento vertical e quebra das ações quando faltar largura. Preservar nome, ticket, status, número de origem, botões, consultas, envio e área de mensagens. Atualizar o teste existente para localizar o cabeçalho por atributo semântico e validar as propriedades de layout.

Aceite: sem altura fixa, cabeçalho permanece shrink-0, conteúdo cabe sem sobreposição vertical, ações podem mudar de linha; navegação normal e Inbox embutido preservados. QA sem interação com navegador. Nenhuma alteração de backend, dados, dependências ou integrações.

Publicação: consulta Railway retornou UNAUTHORIZED, exigindo reautenticação do conector. Não declarar correção publicada até confirmar deploy e artefato público.

Validação: node --experimental-strip-types scripts/test-slim-embedded-inbox.mjs: 13/13 PASS, incluindo renderização do cabeçalho real, crescimento sem altura fixa, wrap das ações, navegação normal/embutida, rascunhos e áudio. git diff --check PASS. Alteração restrita a duas classes e atributo semântico, sem mudança de lógica; build completo não repetido para este ajuste visual. QA visual em navegador não realizado por instrução do usuário. A geração da origem usa âncoras do status, preservadas; a correção permanece no componente fonte.
