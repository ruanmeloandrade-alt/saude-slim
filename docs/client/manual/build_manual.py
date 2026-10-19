#!/usr/bin/env python3
"""Build the client manual from the reviewed, self-contained content manifest."""
import argparse
import html
import json
import re
from pathlib import Path

from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph,
    Spacer, PageBreak, FrameBreak, NextPageTemplate, Flowable, Table, TableStyle,
    KeepTogether)

W,H=landscape(A4)
M=46
GAP=28
CW=(W-2*M-GAP)/2
FW=W-2*M
FOREST=colors.HexColor('#173b36')
GREEN=colors.HexColor('#2d735d')
MINT=colors.HexColor('#b9e5c7')
PAPER=colors.HexColor('#fbfcf9')
INK=colors.HexColor('#20362f')
MUTED=colors.HexColor('#60736b')
LINE=colors.HexColor('#dce6de')
PALE=colors.HexColor('#eff5ef')

FONT_DIR=Path('/usr/share/fonts/truetype/dejavu')
pdfmetrics.registerFont(TTFont('SlimSans',str(FONT_DIR/'DejaVuSans.ttf')))
pdfmetrics.registerFont(TTFont('SlimSans-Bold',str(FONT_DIR/'DejaVuSans-Bold.ttf')))
pdfmetrics.registerFontFamily('SlimSans',normal='SlimSans',bold='SlimSans-Bold',italic='SlimSans',boldItalic='SlimSans-Bold')
pdfmetrics.registerFont(TTFont('SlimSerif',str(FONT_DIR/'DejaVuSerif.ttf')))

STYLES={
 'body':ParagraphStyle('Body',fontName='SlimSans',fontSize=10.6,leading=14.3,textColor=INK,spaceAfter=6,allowWidows=0,allowOrphans=0),
 'lead':ParagraphStyle('Lead',fontName='SlimSans',fontSize=11.2,leading=16,textColor=MUTED),
 'h2':ParagraphStyle('H2',fontName='SlimSans-Bold',fontSize=13.1,leading=17,textColor=FOREST,spaceBefore=9,spaceAfter=6,keepWithNext=True),
 'h3':ParagraphStyle('H3',fontName='SlimSans-Bold',fontSize=11.2,leading=15,textColor=GREEN,spaceBefore=7,spaceAfter=5,keepWithNext=True),
 'step':ParagraphStyle('Step',fontName='SlimSans',fontSize=10.6,leading=14.3,textColor=INK,spaceAfter=6,leftIndent=18,firstLineIndent=-18,allowWidows=0,allowOrphans=0),
 'bullet':ParagraphStyle('Bullet',fontName='SlimSans',fontSize=10.6,leading=14.3,textColor=INK,spaceAfter=6,leftIndent=12,firstLineIndent=-12,allowWidows=0,allowOrphans=0),
 'cell':ParagraphStyle('Cell',fontName='SlimSans',fontSize=9.4,leading=13,textColor=INK),
 'cellhead':ParagraphStyle('CellHead',fontName='SlimSans-Bold',fontSize=9.3,leading=13,textColor=FOREST),
 'small':ParagraphStyle('Small',fontName='SlimSans',fontSize=8.8,leading=12.4,textColor=MUTED,spaceAfter=7),
 'toc':ParagraphStyle('Toc',fontName='SlimSans-Bold',fontSize=10.8,leading=15,textColor=FOREST),
 'tocdesc':ParagraphStyle('TocDesc',fontName='SlimSans',fontSize=9.1,leading=12.7,textColor=MUTED),
}

def clean(s):
    return s.replace('—',':').replace(' – ',' a ').replace('\u00a0',' ')

def inline(s):
    s=html.escape(clean(s),quote=False)
    s=re.sub(r'\*\*(.+?)\*\*',r'<b>\1</b>',s)
    s=re.sub(r'`([^`]+)`',r'<font name="SlimSans-Bold">\1</font>',s)
    s=re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',r'<link href="\2" color="#2d735d">\1</link>',s)
    return s

def para(s,kind='body'):
    return Paragraph(inline(s),STYLES[kind])

def brand_mark(c,x,y,size=42):
    c.saveState()
    c.translate(x,y); c.scale(size/64,size/64)
    c.setFillColor(FOREST); c.roundRect(0,0,64,64,16,stroke=0,fill=1)
    c.setStrokeColor(MINT); c.setLineWidth(5); c.setLineCap(1)
    p=c.beginPath();p.moveTo(13,29);p.curveTo(13,39.5,21.5,48,32,48);p.curveTo(42.5,48,51,39.5,51,29);c.drawPath(p)
    c.setStrokeColor(colors.white); c.setLineWidth(5.5);c.setLineJoin(1)
    p=c.beginPath();p.moveTo(43,42);p.curveTo(40,45,36,46,31,46);p.curveTo(24,46,19,43,19,37);p.curveTo(19,24,44,32,44,19);p.curveTo(44,13,39,9,31,9);p.curveTo(25,9,19,11,15,16);c.drawPath(p)
    c.restoreState()

class ChapterHeader(Flowable):
    def __init__(self,ch):
        Flowable.__init__(self); self.ch=ch; self.width=FW;self.height=104
    def draw(self):
        c=self.canv;ch=self.ch
        c.setFillColor(MUTED);c.setFont('SlimSans-Bold',8.2)
        c.drawString(0,96,f"CAPÍTULO {ch['num']:02d}   /   {ch['kicker'].upper()}")
        c.setFillColor(FOREST);c.setFont('SlimSans-Bold',25)
        c.drawString(0,64,ch['title'])
        p=para(ch['lead'],'lead');pw,ph=p.wrap(FW-68,42);p.drawOn(c,0,50-ph)
        c.setStrokeColor(LINE);c.line(0,0,FW,0)

class Journey(Flowable):
    def __init__(self,width=CW):
        Flowable.__init__(self);self.width=width;self.height=92
    def draw(self):
        c=self.canv;seg=self.width/4
        labels=[('01','Contato'),('02','Conversa'),('03','Oportunidade'),('04','Pedido')]
        c.setStrokeColor(MINT);c.setLineWidth(2);c.line(14,57,self.width-14,57)
        for i,(n,t) in enumerate(labels):
            x=seg*i+seg/2
            c.setFillColor(FOREST);c.circle(x,57,13,stroke=0,fill=1)
            c.setFillColor(colors.white);c.setFont('SlimSans-Bold',8);c.drawCentredString(x,54,n)
            c.setFillColor(INK);c.setFont('SlimSans-Bold',8);c.drawCentredString(x,32,t)
        p=para('Uma jornada comercial. Cada etapa depende da ação da equipe ou de uma automação configurada.','small')
        _,h=p.wrap(self.width,30);p.drawOn(c,0,20-h)

class FlexibleKeepTogether(KeepTogether):
    splitAtTop=True

class ManualDoc(BaseDocTemplate):
    def __init__(self,path,total_pages=None,toc_pages=None):
        super().__init__(str(path),pagesize=(W,H),leftMargin=M,rightMargin=M,topMargin=58,bottomMargin=51,title='Saúde Slim | Manual completo da plataforma',author='Saúde Slim',subject='Configuração, operação, rotinas e trilha de videoaulas. Edição v1.0, outubro de 2026.',pageCompression=1)
        self.total_pages=total_pages;self.toc_pages=toc_pages or {};self.found={};self.section_count=0;self.active='Guia de operação';self.keepTogetherClass=FlexibleKeepTogether
        def f(x,y,w,h,id):return Frame(x,y,w,h,id=id,leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)
        body=[f(M,54,CW,H-122,'left'),f(M+CW+GAP,54,CW,H-122,'right')]
        first=[f(M,H-166,FW,110,'intro'),f(M,54,CW,H-232,'left'),f(M+CW+GAP,54,CW,H-232,'right')]
        first_wide=[f(M,H-166,FW,110,'intro'),f(M,54,FW,H-232,'wide')]
        wide=[f(M,54,FW,H-122,'wide')]
        self.addPageTemplates([
          PageTemplate(id='Cover',frames=[f(M,54,FW,H-108,'cover')],onPage=self.cover),
          PageTemplate(id='Contents',frames=wide,onPageEnd=self.furniture),
          PageTemplate(id='First',frames=first,onPageEnd=self.furniture,autoNextPageTemplate='Body'),
          PageTemplate(id='Body',frames=body,onPageEnd=self.furniture),
          PageTemplate(id='FirstWide',frames=first_wide,onPageEnd=self.furniture,autoNextPageTemplate='Wide'),
          PageTemplate(id='Wide',frames=wide,onPageEnd=self.furniture),
        ])
    def afterFlowable(self,flowable):
        if isinstance(flowable,ChapterHeader):
            ch=flowable.ch;key=f"chapter-{ch['num']}";self.found[ch['num']]=self.page;self.active=ch['title']
            self.canv.bookmarkPage(key);self.canv.addOutlineEntry(f"{ch['num']:02d}  {ch['title']}",key,level=0,closed=False)
        elif getattr(flowable,'manual_heading',None):
            self.section_count+=1;key=f"section-{self.section_count}"
            self.canv.bookmarkPage(key);self.canv.addOutlineEntry(flowable.manual_heading,key,level=1,closed=False)
    def furniture(self,c,d):
        c.saveState();c.setFillColor(FOREST);c.setFont('SlimSans-Bold',9.1);c.drawString(M,H-31,'SAÚDE SLIM')
        c.setFillColor(MUTED);c.setFont('SlimSans',8);c.drawRightString(W-M,H-31,'MANUAL DA PLATAFORMA  •  V1.0')
        c.setStrokeColor(LINE);c.setLineWidth(.65);c.line(M,41,W-M,41)
        c.setFont('SlimSans',7.7);c.setFillColor(MUTED);c.drawString(M,26,self.active)
        c.drawCentredString(W/2,26,'slimesaude.com  |  Outubro de 2026')
        c.linkURL('https://slimesaude.com',(W/2-87,22,W/2+3,34),relative=0,thickness=0)
        c.setFont('SlimSans-Bold',8.1);c.setFillColor(FOREST);label=f'{d.page:02d}'
        if self.total_pages:label+=f' / {self.total_pages:02d}'
        c.drawRightString(W-M,26,label)
        c.restoreState()
    def cover(self,c,d):
        c.saveState();c.setFillColor(PAPER);c.rect(0,0,W,H,stroke=0,fill=1)
        right=567;c.setFillColor(FOREST);c.rect(right,0,W-right,H,stroke=0,fill=1)
        brand_mark(c,M,H-95,44)
        c.setFillColor(FOREST);c.setFont('SlimSans-Bold',15);c.drawString(M+56,H-70,'SAÚDE SLIM')
        c.setFont('SlimSans',8.5);c.setFillColor(MUTED);c.drawString(M+56,H-87,'ATENDIMENTO E GESTÃO COMERCIAL')
        c.setFillColor(FOREST);c.setFont('SlimSerif',41)
        for i,line in enumerate(['Manual completo','da plataforma']):c.drawString(M,H-185-i*52,line)
        p=para('Configuração, atendimento, vendas e automações. Um guia para a equipe operar com clareza e consultar quando precisar.','lead')
        _,h=p.wrap(453,90);p.drawOn(c,M,H-290-h)
        c.setStrokeColor(LINE);c.line(M,179,right-42,179)
        c.setFont('SlimSans-Bold',10);c.setFillColor(GREEN);c.drawString(M,155,'PASSO A PASSO  +  CONSULTA RÁPIDA  +  VIDEOAULAS')
        c.setFont('SlimSans',9.2);c.setFillColor(MUTED);c.drawString(M,127,'Edição v1.0  |  Outubro de 2026')
        c.setFont('SlimSans-Bold',10.5);c.setFillColor(FOREST);c.drawString(M,69,'slimesaude.com')
        c.linkURL('https://slimesaude.com',(M,63,M+120,81),relative=0,thickness=0)
        c.setFillColor(MINT);c.setFont('SlimSans-Bold',8.5);c.drawString(right+30,H-74,'DO PRIMEIRO ACESSO À ROTINA')
        phases=[('01','Preparar','Acesso, equipe e conexões.'),('02','Atender','Clientes, Funil e Inbox.'),('03','Automatizar','Bots, públicos e IA.'),('04','Gerenciar','Pedidos, estoque e resultados.')]
        for i,(n,title,sub) in enumerate(phases):
            y=H-153-i*94
            c.setFont('SlimSans',10);c.setFillColor(MINT);c.drawString(right+30,y,n)
            c.setFont('SlimSans-Bold',19);c.setFillColor(colors.white);c.drawString(right+62,y-1,title)
            p=Paragraph(sub,ParagraphStyle('CoverSub',fontName='SlimSans',fontSize=9.1,leading=13,textColor=MINT));_,h=p.wrap(184,35);p.drawOn(c,right+62,y-18-h)
            if i<3:c.setStrokeColor(colors.HexColor('#42645b'));c.line(right+30,y-50,W-29,y-50)
        c.setFont('SlimSans',8);c.setFillColor(MINT);c.drawString(right+30,35,'DOCUMENTAÇÃO PARA A EQUIPE SAÚDE SLIM')
        c.restoreState()

def markdown_flow(md,width=CW,section_prefix=''):
    lines=clean(md).strip().splitlines();out=[];i=0
    while i<len(lines):
        line=lines[i].strip()
        if not line or line=='---':i+=1;continue
        if line==':::journey':out.append(Journey(width));out.append(Spacer(1,5));i+=1;continue
        if line.startswith('|'):
            raw=[]
            while i<len(lines) and lines[i].strip().startswith('|'):
                row=[x.strip() for x in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r'[:\- ]+',x or '-') for x in row):raw.append(row)
                i+=1
            cols=len(raw[0]);ratios={2:[.31,.69],3:[.09,.30,.61],4:[.07,.28,.49,.16]}.get(cols,[1/cols]*cols)
            data=[[para(cell,'cellhead' if n==0 else 'cell') for cell in row] for n,row in enumerate(raw)]
            table=Table(data,colWidths=[width*r for r in ratios],repeatRows=1,hAlign='LEFT')
            table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),PALE),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),8),('RIGHTPADDING',(0,0),(-1,-1),8),('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7),('LINEBELOW',(0,0),(-1,0),.8,LINE),('LINEBELOW',(0,1),(-1,-1),.45,LINE)]))
            out.extend([table,Spacer(1,10)]);continue
        match=re.match(r'^(#{1,4})\s+(.+)$',line)
        if match:
            level=len(match[1]);title=re.sub(r'^\d+\.\s*','',match[2]);kind='h2' if level<=2 else 'h3'
            p=para(title,kind)
            if level<=2:p.manual_heading=title
            out.append(p);i+=1;continue
        if re.match(r'^\d+\.\s',line):
            n,rest=line.split('.',1);out.append(para(f'**{n}.** {rest.strip()}','step'));i+=1;continue
        if line.startswith('- '):out.append(para('• '+line[2:],'bullet'));i+=1;continue
        parts=[line];i+=1
        while i<len(lines) and lines[i].strip() and not re.match(r'^(#|\||\d+\.\s|- |:::)',lines[i].strip()):
            parts.append(lines[i].strip());i+=1
        out.append(para(' '.join(parts)))
    return out

def contents(chapters,pages):
    story=[para('Seu guia de consulta','h2'),para('Use o sumário clicável ou os marcadores do leitor de PDF. Os capítulos acompanham a operação e podem ser consultados separadamente.','lead'),Spacer(1,19)]
    rows=[]
    for ch in chapters:
        num=ch['num'];title=html.escape(ch['title']);page=pages.get(num,'••')
        rows.append([Paragraph(f'<link href="#chapter-{num}">{num:02d}</link>',STYLES['toc']),Paragraph(f'<link href="#chapter-{num}">{title}</link>',STYLES['toc']),Paragraph(f'<link href="#chapter-{num}">{page}</link>',STYLES['toc'])])
    t=Table(rows,colWidths=[37,FW-80,43]);t.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'MIDDLE'),('LEFTPADDING',(0,0),(-1,-1),0),('RIGHTPADDING',(0,0),(-1,-1),0),('TOPPADDING',(0,0),(-1,-1),3),('BOTTOMPADDING',(0,0),(-1,-1),3),('LINEBELOW',(0,0),(-1,-1),.4,LINE)]))
    story += [t,Spacer(1,15),para('Acesso da plataforma: [slimesaude.com](https://slimesaude.com). As aulas sugeridas ao final têm objetivos e referências de capítulo; não há links de vídeos ainda não disponibilizados.','small')]
    return story

def make_story(manifest,pages):
    chapters=manifest['chapters']
    story=[Spacer(1,1),NextPageTemplate('Contents'),PageBreak()]
    story += contents(chapters,pages)
    for ch in chapters:
        wide=ch.get('layout')=='wide';typ='FirstWide' if wide else 'First'
        story += [NextPageTemplate(typ),PageBreak(),ChapterHeader(ch),FrameBreak()]
        md=ch['body']
        # Page references are resolved only after the first layout pass.
        for num in range(1,len(chapters)+1):md=md.replace(f'{{{{page:{num}}}}}',str(pages.get(num,'00')))
        story += markdown_flow(md,FW if wide else CW)
    return story

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--content',default=str(Path(__file__).with_name('manual_content.json')));ap.add_argument('--output',default='Saude_Slim_Manual_Completo_da_Plataforma.pdf');args=ap.parse_args()
    manifest=json.loads(Path(args.content).read_text())
    out=Path(args.output);out.parent.mkdir(parents=True,exist_ok=True)
    draft=out.with_suffix('.layout.pdf')
    d1=ManualDoc(draft);d1.build(make_story(manifest,{}))
    d2=ManualDoc(out,total_pages=d1.page,toc_pages=d1.found);d2.build(make_story(manifest,d1.found))
    if d1.page!=d2.page or d1.found!=d2.found:raise RuntimeError(f'Pagination changed: {d1.page} -> {d2.page}; {d1.found} -> {d2.found}')
    report={'pages':d2.page,'chapters':d2.found,'bytes':out.stat().st_size,'output':str(out)}
    out.with_suffix('.manifest.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
    draft.unlink()
    print(json.dumps(report,ensure_ascii=False))

if __name__=='__main__':main()
