# Compatibilidade do modelo dos agentes

Execução real da Fernanda recebeu HTTP 400 porque o modelo rejeitou temperature=0.7. Omitir temperatura customizada para as famílias OpenAI de raciocínio no runtime compartilhado. Preservar o parâmetro dos demais modelos e manter as regras de ativação. Validar formato e publicação; confirmar mensagem somente pelo histórico.
