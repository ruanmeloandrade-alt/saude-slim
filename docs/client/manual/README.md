# Manual do cliente Saúde Slim

Edição v1.0, outubro de 2026. Esta pasta versiona a fonte editorial do manual e o gerador do PDF entregue ao cliente.

- `manual_cliente.md`: conteúdo consolidado com referências de página da edição entregue.
- `manual_content.json`: capítulos, cabeçalhos e conteúdo para diagramação; referências de página são resolvidas em dois passes.
- `build_manual.py`: ReportLab, Python 3 e fontes DejaVu Sans/Serif; gera PDF A4 horizontal, sumário clicável e marcadores.
- `verify_manual.py`: verificação de conteúdo, páginas, links e limites com PyMuPDF e pypdf.

Execução no ambiente de documentação:

```bash
python3 build_manual.py --output Saude_Slim_Manual_Completo_da_Plataforma.pdf
python3 verify_manual.py Saude_Slim_Manual_Completo_da_Plataforma.pdf
pdftoppm -r 120 -png Saude_Slim_Manual_Completo_da_Plataforma.pdf pagina
```

A revisão visual de todas as páginas faz parte da entrega. O PDF final tem 34 páginas, 16 capítulos e trilha sugerida de 18 videoaulas. Esta documentação não altera o aplicativo nem requer publicação de runtime.
