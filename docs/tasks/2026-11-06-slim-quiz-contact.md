# Quiz Saúde Slim — imagens e contato direto

Escopo: substituir imagens geradas por arquivos enviados pelo usuário em etapas selecionadas; manter sete perguntas e preços; apresentar protocolo, acompanhamento e PDFs; resultado sem repetição das respostas, com grupo e vendedor abaixo, mensagem contendo origem e oferta escolhida.
Fora: CRM, backend, automações, banco, autenticação e alterações globais. Sem dependências novas.
Base: origin/migrate/saude-slim-owner-20261030 (75ef92c), branch isolada.
Aceite: ambas as ofertas geram mensagem correta; opção de dúvidas não inventa oferta; fotos completas e responsivas; grupo preservado; resultado sem resumo pessoal.
Destino confirmado pelo usuário: WhatsApp Saúde Slim final 9669. Pendente: conclusão do build e publicação.

Ajuste adicional: remover revisão das respostas e frase do rodapé; privacidade discreta no rodapé.

Mobile: ocultar cabeçalho durante as perguntas; começar pelo indicador e percentual. Fotos sem recorte, altura máxima 310px no mobile.

Validação: node --check aprovado; percurso das sete perguntas no navegador interno; links das duas ofertas e opção dúvidas conferidos sem envio; cinco imagens carregadas; resultado sem resumo/revisão; mobile sem cabeçalho e sem overflow. Verificador local aprovou mensagens, imagens, paridade dos dois HTML e ordem dos CTAs. Build completo em execução. Número de destino segue o final 9669 identificado no contrato de roteamento existente e confirmado pelo usuário como destino.

Ajuste: etapas sem foto em card centralizado, altura natural sem min-height herdado; espaçamento compacto e rodapé próximo em desktop/mobile.

Correção final do usuário: remover rodapé inteiro do quiz (copyright e privacidade), sem reposicioná-lo. Listener do botão removido para evitar erro de inicialização.

Revisão de todas as etapas: min-height removido, cards consistentes com/sem foto, espaçamentos menores; fotos móveis até 240px; resultado móvel sem cabeçalho grande.

Validação final: npm run build e build final Vite aprovados. Nova conferência móvel com fotos/sem fotos, ausência de rodapé, cabeçalho oculto e zero overflow lateral. Verificador das três mensagens e paridade HTML aprovado. Arquivos gerados incidentalmente pelo prebuild restaurados; somente dez arquivos do escopo integram a PR #51. Publicação em andamento.

Ajuste adicional: remover texto auxiliar ao lado de Voltar; manter apenas orientação imediatamente abaixo da pergunta. Legendas inferiores das fotos já estavam removidas.
