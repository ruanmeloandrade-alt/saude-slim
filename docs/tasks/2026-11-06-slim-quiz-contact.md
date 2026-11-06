# Quiz Saúde Slim — imagens e contato direto

Escopo: substituir imagens geradas por arquivos enviados pelo usuário em etapas selecionadas; manter sete perguntas e preços; apresentar protocolo, acompanhamento e PDFs; resultado sem repetição das respostas, com grupo e vendedor abaixo, mensagem contendo origem e oferta escolhida.
Fora: CRM, backend, automações, banco, autenticação e alterações globais. Sem dependências novas.
Base: origin/migrate/saude-slim-owner-20261030 (75ef92c), branch isolada.
Aceite: ambas as ofertas geram mensagem correta; opção de dúvidas não inventa oferta; fotos completas e responsivas; grupo preservado; resultado sem resumo pessoal.
Pendente: número do vendedor solicitado ao usuário; validação local e publicação.

Ajuste adicional: remover revisão das respostas e frase do rodapé; privacidade discreta no rodapé.

Mobile: ocultar cabeçalho durante as perguntas; começar pelo indicador e percentual. Fotos sem recorte, altura máxima 310px no mobile.

Validação: node --check aprovado; percurso das sete perguntas no navegador interno; links das duas ofertas e opção dúvidas conferidos sem envio; cinco imagens carregadas; resultado sem resumo/revisão; mobile sem cabeçalho e sem overflow. Verificador local aprovou mensagens, imagens, paridade dos dois HTML e ordem dos CTAs. Build completo em execução. Número de destino segue o final 9669 identificado no contrato de roteamento existente e confirmado pelo usuário como destino.
