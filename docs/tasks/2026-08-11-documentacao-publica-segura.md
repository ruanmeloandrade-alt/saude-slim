# Documentação pública segura — 2026-08-11

## Objetivo
Transformar `/documentacao` em manual operacional para clientes, sem expor arquitetura, governança, regras internas ou material de implementação da MktOn.

## Escopo público aprovado
Somente estes guias ficam visíveis publicamente:
1. Bots, Automações e SalesBot
2. Agentes IA
3. Tracking
4. Gestor de Tráfego
5. Social Media
6. Fluxo de Trabalho
7. Notas

## Removido da superfície pública
- catálogo administrativo;
- documentação de arquitetura interna;
- Conexões como seção pública;
- Receitas de implementação;
- Diagnóstico técnico;
- relações internas entre módulos;
- troubleshooting técnico detalhado;
- módulos fora do escopo operacional acima.

## Padrão de cada artigo
Cada guia público deve responder somente:
- o que é;
- para que serve;
- onde acessar;
- o que o usuário consegue fazer;
- o que precisa antes de começar;
- como configurar e usar, passo a passo;
- exemplos de uso;
- cuidados antes de ativar.

## Segurança
O catálogo público é separado do catálogo técnico/administrativo. Novos artigos não entram na documentação pública por padrão; precisam ser adicionados explicitamente em `documentation-public-catalog.ts`.

## Validação
Regressão versionada em `src/lib/documentation-public-safety.test.ts` impede reintrodução de catálogo admin, Receitas, Diagnóstico e Conexões na superfície pública.

## Status
Implementação: concluída em código. Publicação depende de merge da PR desta frente.
