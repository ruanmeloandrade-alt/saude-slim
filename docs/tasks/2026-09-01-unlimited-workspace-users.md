# Alteração — Usuários ilimitados por workspace

## Objetivo
Permitir que o cliente final adicione quantos usuários/funcionários forem necessários, inclusive parceiros/técnicos, sem consumir assentos do plano.

## Regra comercial
- Usuários e funcionários: ilimitados em todos os planos.
- Parceiros/técnicos: ilimitados.
- Números de WhatsApp: continuam sujeitos ao limite do plano e à contratação de WhatsApp Extra exatamente como hoje.

## Escopo
- Remover bloqueios de criação/convite baseados em `workspace_seat_limit`.
- Remover o limite de apenas 1 parceiro técnico.
- Manter papéis e permissões individuais existentes.
- Atualizar benefícios dos planos para exibir `Usuários ilimitados`.
- Remover mensagens que vendam `Usuário Extra` ou associem adicional de WhatsApp a assento de usuário.
- Não alterar `max_whatsapp_instances` nem `extra_whatsapp_connections`.

## Validação
- Criação de funcionário não deve consultar/recusar por limite de assentos.
- Convite de usuário e parceiro técnico não deve consultar/recusar por limite de assentos.
- Benefícios dos planos devem exibir usuários ilimitados.
- Limite de WhatsApp deve continuar inalterado.
