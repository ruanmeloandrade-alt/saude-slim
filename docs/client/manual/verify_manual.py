"""Validate navigation, text boundaries and client-safe output of the manual."""
import json,re,sys
from pathlib import Path
import fitz
from pypdf import PdfReader

f=Path(sys.argv[1]);d=fitz.open(f);reader=PdfReader(f)
manifest=json.loads(f.with_suffix('.manifest.json').read_text())
limits=[]
for i,p in enumerate(d):
    for b in p.get_text('dict')['blocks']:
        for line in b.get('lines',[]):
            for s in line['spans']:
                x0,y0,x1,y1=s['bbox']
                if x0<0 or y0<0 or x1>p.rect.width+.3 or y1>p.rect.height+.3:
                    limits.append([i+1,s['text']])
text=re.sub(r'\s+',' ',' '.join(p.get_text() for p in d))
outline=d.get_toc();chapters=[x for x in outline if x[0]==1]
assert len(chapters)==16
assert all(chapters[i][2]==manifest['chapters'][str(i+1)] for i in range(16))
page_ids={p.indirect_reference.idnum:i+1 for i,p in enumerate(reader.pages)}
dests=[]
for ref in reader.pages[1].get('/Annots',[]):
    dest=ref.get_object().get('/Dest')
    if dest:dests.append(page_ids[dest[0].idnum])
assert sorted(set(dests))==sorted(manifest['chapters'].values())
assert not limits,limits
assert not re.search(r'(?i)(@SS\w+|gmail|hotmail|conversation_read|supabase|railway|mkt[ -]?on|\.server|/tmp/|/workspace/|e33b287|evidências técnicas|placeholder|�|{{page:|—)',text)
for term in ['SalesBot','Mini-Inbox','Relatório detalhado','comprovante comercial','Prompt do sistema','Encerrar pendentes','8 a 128','Conectar e gerar QR Code']:
    assert term.lower() in text.lower(),term
report={'pages':len(d),'chapters':len(chapters),'outline_entries':len(outline),'links':sum(len(p.get_links()) for p in d),'toc_destinations':sorted(set(dests)),'out_of_bounds':limits,'words_extracted':len(text.split()),'bytes':f.stat().st_size,'landscape_a4':all(p.rect.width>p.rect.height for p in d),'privacy_scan':'PASS','critical_topics':'PASS','toc_and_bookmarks':'PASS'}
print(json.dumps(report,ensure_ascii=False,indent=2))
