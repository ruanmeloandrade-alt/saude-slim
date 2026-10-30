'use strict';

// Execução local, sem integração externa. Valores reaproveitados da referência para revisão comercial.
const STORAGE_KEY = 'slim-saude-quiz:v2';
const WHATSAPP_GROUP_URL = 'https://chat.whatsapp.com/K8tkGBnE5IYKzHVfK6XXBc?s=cl&p=i&mlu=4&ilr=4&iam=2';
const state = { view: 'intro', step: 0, answers: {}, busy: false };
const main = document.querySelector('main');
const dialog = document.querySelector('#info-dialog');
const dialogContent = document.querySelector('#dialog-content');
const arrow = '<span class="arrow" aria-hidden="true">↗</span>';
const waIcon = '<svg class="wa-icon" aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M20.5 11.6a8.5 8.5 0 0 1-12.7 7.5L3 20.5l1.4-4.7A8.5 8.5 0 1 1 20.5 11.6Z"/><path d="M8.1 7.5c.5 4 2.9 6.5 6.9 7l1.1-1.8-2.2-1.1-1 1c-1.5-.6-2.6-1.8-3.2-3.2l1-1-1-2.1-1.6 1.2Z" stroke-linejoin="round"/></svg>';
const coreQuestions = [
  { id: 'goal', label: 'O QUE VOCÊ QUER MUDAR', title: 'O que mais incomoda você no seu peso hoje?', help: 'Marque o que mais faz você querer mudar essa situação.', options: [
    ['comfort', 'Não me sinto bem quando visto minhas roupas'], ['health', 'Tenho adiado o cuidado com a minha saúde'], ['energy', 'Sinto falta de fôlego e disposição no dia a dia'], ['regain', 'Emagreço, mas depois ganho tudo de novo'], ['confidence', 'Não me sinto bem quando me olho no espelho'] ] },
  { id: 'pain', label: 'O QUE ESTÁ TRAVANDO VOCÊ', title: 'O que mais faz você travar na hora de emagrecer?', help: 'Marque o obstáculo que mais se repete com você.', options: [
    ['hunger', 'A fome e a vontade de comer atrapalham meu planejamento'], ['snacking', 'Como fora das refeições e me frustro por sair do que planejei'], ['routine', 'Começo bem, mas acabo abandonando a rotina'], ['regain', 'Vejo o peso baixar e depois voltar de novo'], ['start', 'Tenho medo de gastar e me frustrar mais uma vez'] ] },
  { id: 'history', label: 'AS SUAS TENTATIVAS', title: 'Quantas vezes você já decidiu emagrecer e acabou voltando ao mesmo ponto?', help: 'Escolha a resposta que melhor descreve sua experiência.', options: [
    ['many', 'Várias vezes. Cansei de viver esse ciclo'], ['regained', 'Já emagreci, mas ganhei peso de novo'], ['alone', 'Tento por conta própria e não consigo manter a constância'], ['first', 'É a primeira vez que vou buscar um caminho estruturado'], ['stalled', 'Já estou tentando, mas não vejo o progresso que gostaria'] ] },
  { id: 'doubt', label: 'O QUE FALTA PARA DECIDIR', title: 'O que ainda impede você de decidir pelo tratamento?', help: 'Marque o ponto que precisa ser resolvido antes da compra.', options: [
    ['support', 'Ainda não sei como funciona o tratamento e o acompanhamento'], ['safety', 'Preciso entender as opções e como funciona a avaliação'], ['cost', 'Quero saber o preço e tudo o que está incluído'], ['routine', 'Preciso saber como encaixar o tratamento na minha rotina'], ['trust', 'Tenho receio de gastar e me frustrar de novo'] ] },
  { id: 'readiness', label: 'VAMOS DAR O PRÓXIMO PASSO', title: 'Agora que você conhece os valores, qual é a sua decisão?', help: 'Escolha como você quer seguir com a Lobo Paraguaio.', options: [
    ['now', 'Quero começar e entender como fechar meu tratamento'], ['soon', 'Quero me organizar para começar nas próximas semanas'], ['research', 'Quero esclarecer algumas dúvidas antes de decidir'] ] }
];
const offerQuestion = { id:'offer', label:'AGORA, VAMOS FALAR DO TRATAMENTO', title:'Qual opção você quer conhecer melhor?', help:'Conheça as condições iniciais e escolha o que faz sentido para o seu planejamento.', options:[['initial','Tratamento de 6 semanas · a partir de R$350'],['complete','Tratamento completo · a partir de R$1.200'],['questions','Quero entender as condições antes de escolher']] };
const offers = { initial:{name:'Tratamento de 6 semanas',price:'R$350'},complete:{name:'Tratamento completo',price:'R$1.200'},questions:{name:'Opções de tratamento',price:'R$350'} };
const stepImages = {
  goal:{src:'objetivo-masculino.webp',alt:'Homem adulto em um momento de reflexão em casa',title:'O que você quer mudar na sua vida?',caption:'Seu objetivo é o ponto de partida.'},
  pain:{src:'desafio-editorial.webp',alt:'Mulher à mesa em casa em um momento de reflexão',title:'Qual obstáculo você quer deixar para trás?',caption:'Identifique o que mais atrapalha seus planos.'},
  history:{src:'historia-editorial.webp',alt:'Mulher escolhendo uma camisa em seu guarda-roupa',title:'Você quer sair do ciclo de tentativas.',caption:'O que precisa ser diferente desta vez?'},
  context:{src:'rotina-editorial.webp',alt:'Mulher organizando sua refeição e a rotina do dia',title:'O que precisa mudar na sua rotina?',caption:'Escolha a dificuldade que mais se repete.'},
  doubt:{src:'conversa-editorial.webp',alt:'Duas mulheres em uma conversa',title:'Informação para decidir. Condições para começar.',caption:'Esclareça o que falta para a sua decisão.'},
  offer:{src:'tratamentos-referencia.webp',alt:'Fotografia de embalagens de medicamentos',title:'Conheça o tratamento e as condições para começar.',caption:'Informação clara antes da sua escolha.',product:true},
  readiness:{src:'proximo-passo-masculino.webp',alt:'Homem adulto caminhando ao ar livre em um parque',title:'É hora de transformar intenção em decisão.',caption:'Conheça as condições para começar.'}
};
const contexts = {
  hunger: { title: 'Em qual momento a fome mais atrapalha seu planejamento?', help: 'Identifique a situação que mais se repete.', options: [['evening','No fim do dia'],['after-meals','Pouco tempo depois de comer'],['outside','Quando estou fora de casa'],['varies','Varia de um dia para o outro'],['planning','Quando fico muito tempo sem me alimentar']] },
  snacking: { title: 'Em qual situação você mais come fora do que planejou?', help: 'Marque o momento que mais atrapalha sua tentativa de emagrecer.', options: [['work','Durante o trabalho ou as tarefas do dia'],['evening','Depois do jantar'],['busy','Quando fico sem uma rotina definida'],['varies','Em vários momentos do dia'],['social','Quando saio ou encontro outras pessoas']] },
  routine: { title: 'O que faz você abandonar a rotina que começou?', help: 'Escolha a dificuldade que mais precisa mudar.', options: [['time','Falta de tempo para me organizar'],['changes','Meus horários mudam muito'],['food','Organizar a alimentação no dia a dia'],['support','Falta de apoio e de um caminho claro'],['followup','Começo sem saber como acompanhar meu progresso']] },
  regain: { title: 'Quando o peso volta, o que mais te frustra?', help: 'Marque o que mais faz você querer sair desse ciclo.', options: [['effort','Sentir que todo o esforço ficou para trás'],['restart','Ter que começar tudo de novo'],['maintenance','Não entender como manter o progresso'],['fear','Ficar com receio de tentar outra vez'],['alone','Sentir que estou enfrentando isso sem apoio']] },
  start: { title: 'O que falta para você decidir com confiança?', help: 'Escolha a informação que mais pesa na sua decisão.', options: [['steps','Entender como funcionam os primeiros passos'],['support','Saber quem acompanha e como é o suporte'],['cost','Ter clareza sobre opções e valores'],['questions','Poder perguntar antes de decidir'],['trust','Entender se posso confiar no serviço e no acompanhamento']] }
};
const goalCopy = { comfort: 'voltar a vestir suas roupas com confiança', health: 'parar de adiar o cuidado com sua saúde', energy: 'ter mais fôlego e disposição para viver o dia', regain: 'parar de perder peso e ganhar tudo de novo', confidence: 'voltar a se sentir bem ao se olhar no espelho' };
const painCopy = {
  hunger: { title: 'Você quer que a fome pare de atrapalhar seus planos.', body: 'A fome apareceu como um dos principais obstáculos nas suas respostas. Seu próximo passo é conhecer as opções de tratamento, esclarecer suas dúvidas e entender as condições para começar.', theme: 'Fome e vontade de comer' },
  snacking: { title: 'Você quer retomar o controle da sua alimentação.', body: 'Você contou que comer fora do que planejou acaba atrapalhando suas tentativas. Conheça as opções de tratamento e leve essa dificuldade para a conversa com a equipe Lobo Paraguaio.', theme: 'Comer fora do que planejou' },
  routine: { title: 'Você quer parar de começar e abandonar.', body: 'Você contou que manter a constância é a parte difícil. Conheça como funciona o tratamento e quais são as condições para começar com mais informação sobre os próximos passos.', theme: 'Constância e rotina' },
  regain: { title: 'Você não quer viver mais um ciclo de perder e recuperar.', body: 'Recuperar o peso foi a frustração que você apontou. O próximo passo é entender as opções de tratamento e esclarecer suas dúvidas sobre continuidade antes de decidir.', theme: 'Manter o progresso' },
  start: { title: 'Você quer decidir sem cair em mais uma frustração.', body: 'Você quer mudar, mas precisa confiar no que está contratando. Veja as condições do tratamento e esclareça o que falta para decidir com a equipe Lobo Paraguaio.', theme: 'Começar com confiança' }
};
function questions() { return [...coreQuestions.slice(0,3), { id:'context', label:'ONDE ESTÁ O OBSTÁCULO', ...contexts[state.answers.pain || 'start'] }, coreQuestions[3], offerQuestion, coreQuestions[4]]; }
function escapeHtml(value) { return String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function answerLabel(id) { const q=questions().find(q=>q.id===id); return q?.options.find(o=>o[0]===state.answers[id])?.[1] || ''; }
function focusTitle() { const heading=main.querySelector('h1'); if(heading) { heading.tabIndex=-1; heading.focus({preventScroll:true}); } }
function saveProgress(){try{sessionStorage.setItem(STORAGE_KEY,JSON.stringify({view:state.view,step:state.step,answers:state.answers}));}catch{}}
function navigate(view,step=0,replace=false) { clearTimeout(state.timer);state.view=view;state.step=step;state.busy=false;saveProgress();const hash=view==='intro'?'#inicio':view==='result'?'#resultado':`#pergunta-${step+1}`;history[replace?'replaceState':'pushState']({view,step},'',hash);render();window.scrollTo({top:0,behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'instant':'smooth'});focusTitle(); }
function render() { if(state.view==='quiz') renderQuestion(); else if(state.view==='result') renderResult(); else renderIntro(); }
function renderIntro() {
  main.innerHTML=`<section class="intro-simple enter"><div class="intro-simple-panel"><h1>Cansou de tentar e<br><em>começar tudo de novo?</em></h1><p>Responda 7 perguntas e conheça as opções de tratamento da Lobo Paraguaio.</p><button class="primary" data-start>Começar ${arrow}</button></div></section>`;
  main.querySelector('[data-start]').onclick=()=>navigate('quiz');
}
function renderQuestion() {
  const list=questions(); const q=list[state.step]; const number=state.step+1;
  const visual=stepImages[q.id];
  const photo=`<img src="assets/${visual.src}" alt="${visual.alt}" width="600" height="750">`;
  main.innerHTML=`<section class="quiz-wrap enter ${visual.product?'commercial-step':''}"><aside class="quiz-aside"><span class="aside-label">${q.id==='offer'?'Opções de tratamento':'Lobo Paraguaio'}</span><h2>${visual.title}</h2><div class="aside-image ${visual.product?'product-image':''}">${photo}</div><p class="aside-reassurance">${visual.caption}</p></aside><div class="quiz-panel"><div class="progress-meta"><span>Pergunta <strong>${number} de ${list.length}</strong></span><span>${Math.round(number/list.length*100)}% do questionário</span></div><div class="progress" role="progressbar" aria-label="Progresso do questionário" aria-valuemin="0" aria-valuemax="${list.length}" aria-valuenow="${number}"><span style="width:${number/list.length*100}%"></span></div><p class="step-label">${q.label}</p><h1 class="question-title">${q.title}</h1><p class="question-help">${q.help}</p><div class="question-photo ${visual.product?'product-image':''}">${photo}</div>${q.id==='context'?`<div class="question-context">Você contou: <strong>${escapeHtml(answerLabel('pain'))}</strong>.</div>`:''}<div class="options" role="group" aria-label="Alternativas">${q.options.map(([id,text],i)=>`<button class="option ${state.answers[q.id]===id?'selected':''} ${q.id==='offer'&&id!=='questions'?'offer-option':''}" data-answer="${id}" aria-pressed="${state.answers[q.id]===id}"><span class="option-number" aria-hidden="true">${state.answers[q.id]===id?'✓':String(i+1).padStart(2,'0')}</span><span class="option-title">${q.id==='offer'&&id!=='questions'?`<span class="offer-name">${offers[id].name}</span><span class="offer-price"><small>a partir de</small> ${offers[id].price}</span>`:escapeHtml(text)}</span><span class="option-arrow" aria-hidden="true">→</span></button>`).join('')}</div><div class="question-bottom"><button class="back" data-back>← ${state.step===0?'Voltar ao início':'Voltar'}</button><small>Escolha uma opção para continuar.<br>Você pode voltar e revisar.</small></div></div></section>`;
  main.querySelectorAll('[data-answer]').forEach(button=>button.onclick=()=>selectAnswer(q,button.dataset.answer));
  main.querySelector('[data-back]').onclick=()=>state.step===0?navigate('intro'):navigate('quiz',state.step-1);
}
function selectAnswer(q,value) {
  if(state.busy)return; state.busy=true;
  if(q.id==='pain' && state.answers.pain!==value)delete state.answers.context;
  state.answers[q.id]=value;
  saveProgress();
  main.querySelectorAll('[data-answer]').forEach(button=>{button.disabled=true;button.classList.toggle('selected',button.dataset.answer===value);button.setAttribute('aria-pressed',String(button.dataset.answer===value));});
  const next=state.step+1;
  state.timer=setTimeout(()=>{if(next<questions().length)navigate('quiz',next);else showSummaryTransition();},matchMedia('(prefers-reduced-motion: reduce)').matches?0:180);
}
function showSummaryTransition() {
  main.innerHTML='<section class="processing" aria-live="polite"><div class="pulse" aria-hidden="true">✳</div><h1>Vamos reunir o que você contou.</h1><p>Seu objetivo e suas dúvidas dão contexto ao próximo passo.</p></section>';
  state.timer=setTimeout(()=>navigate('result'),650);
}
function renderResult() {
  if(!questions().every(q=>state.answers[q.id])) { const missing=questions().findIndex(q=>!state.answers[q.id]);navigate('quiz',Math.max(0,missing),true);return; }
  const profile=painCopy[state.answers.pain];
  const goal=goalCopy[state.answers.goal];
  const ready=state.answers.readiness;
  const nextText=ready==='research'?'Falta esclarecer algumas dúvidas antes de decidir. Entre no grupo da Lobo Paraguaio para conhecer as informações sobre o tratamento e as condições para começar.':ready==='soon'?'Você quer se organizar para começar nas próximas semanas. Entre no grupo da Lobo Paraguaio e conheça as condições para planejar seu tratamento.':'Você quer começar. Entre no grupo da Lobo Paraguaio para conhecer as condições e os próximos passos para fechar seu tratamento.';
  const title=ready==='research'?'Tire suas dúvidas e conheça as condições.':ready==='soon'?'Organize seu próximo passo com a Lobo Paraguaio.':'Vamos dar o próximo passo para o seu tratamento?';
  const selectedOffer=offers[state.answers.offer]||offers.questions;
  main.innerHTML=`<section class="result"><div class="result-top"><p class="eyebrow">O que você contou importa</p><h1>${profile.title}</h1><p>${profile.body}</p></div><div class="result-grid"><article class="summary"><h2>Seu ponto de partida</h2><div class="summary-row"><small>O que você deseja</small><p>Você quer ${escapeHtml(goal)}.</p></div><div class="summary-row"><small>O que mais dificulta hoje</small><p>${escapeHtml(answerLabel('pain'))}.</p></div><div class="summary-row"><small>Sua experiência até aqui</small><p>${escapeHtml(answerLabel('history'))}.</p></div><div class="summary-row"><small>O que você quer esclarecer</small><p>${escapeHtml(answerLabel('doubt'))}.</p></div><div class="summary-row"><small>Um detalhe importante para a conversa</small><p>${escapeHtml(answerLabel('context'))}.</p></div><div class="summary-row"><small>Tratamento que você quer conhecer</small><p>${escapeHtml(answerLabel('offer'))}.</p></div></article><article class="next-step"><p class="step-label">Seu tratamento · Lobo Paraguaio</p><h2>${title}</h2><p>${nextText}</p><div class="result-product"><img src="assets/tratamentos-referencia.webp" width="600" height="750" alt="Produtos apresentados na referência de tratamentos"></div><div class="selected-offer"><span>${selectedOffer.name}</span><strong><small>a partir de</small> ${selectedOffer.price}</strong></div><ul class="group-details"><li>Conheça as condições do tratamento.</li><li>Esclareça suas dúvidas para começar.</li><li>Receba as informações sobre a compra no grupo.</li></ul><a class="primary group-cta" data-group href="${escapeHtml(WHATSAPP_GROUP_URL)}" target="_blank" rel="noopener noreferrer">${waIcon}<span>Quero entrar no grupo Lobo Paraguaio</span>${arrow}</a></article></div><div class="result-reassurance"><span>Seu objetivo merece um próximo passo.</span><button class="restart" data-restart>Revisar minhas respostas</button></div></section>`;
  main.querySelector('[data-group]').onclick=animateGroupButton;
  main.querySelector('[data-restart]').onclick=()=>navigate('quiz');
}
function showDialog(content) { dialogContent.innerHTML=content;dialog.showModal();dialogContent.querySelector('[data-close]')?.addEventListener('click',()=>dialog.close()); }
function animateGroupButton(event) {
  const button=event.currentTarget; if(button.querySelector('.ripple'))return;
  const ripple=document.createElement('span');ripple.className='ripple';ripple.style.left=`${button.clientWidth/2-110}px`;ripple.style.top=`${button.clientHeight/2-110}px`;button.append(ripple);
  button.classList.add('cta-activated');
  setTimeout(()=>{ripple.remove();button.classList.remove('cta-activated');},650);
}
document.querySelector('[data-home]').onclick=event=>{event.preventDefault();navigate('intro');};
document.querySelector('[data-privacy]').onclick=()=>showDialog('<h2 id="dialog-title">Sua privacidade</h2><p>Suas escolhas ajudam a organizar seu objetivo e as opções que você quer conhecer. As respostas ficam apenas nesta aba do navegador e não são enviadas a um servidor por este questionário.</p><p>Não solicitamos nome, telefone ou dados de pagamento nesta etapa.</p><button class="primary" data-close>Entendi</button>');
document.querySelector('.dialog-close').onclick=()=>dialog.close();
dialog.addEventListener('click',event=>{if(event.target===dialog){const r=dialog.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)dialog.close();}});
window.addEventListener('popstate',event=>{clearTimeout(state.timer);const view=event.state?.view||'intro';const requested=event.state?.step||0;if(view==='quiz'){const firstMissing=questions().findIndex(q=>!state.answers[q.id]);state.step=firstMissing<0?requested:Math.min(requested,firstMissing);}state.view=view;state.busy=false;saveProgress();render();focusTitle();});
document.addEventListener('keydown',event=>{if(dialog.open||state.view!=='quiz'||state.busy||event.altKey||event.ctrlKey||event.metaKey)return;const index=Number(event.key)-1;const q=questions()[state.step];if(/^[1-5]$/.test(event.key)&&q.options[index]){event.preventDefault();selectAnswer(q,q.options[index][0]);}});
try{const saved=JSON.parse(sessionStorage.getItem(STORAGE_KEY)||'null');if(saved&&['intro','quiz','result'].includes(saved.view)){const raw=saved.answers||{};for(const id of ['goal','pain','history','context','doubt','offer','readiness']){const q=questions().find(item=>item.id===id);if(q?.options.some(option=>option[0]===raw[id]))state.answers[id]=raw[id];}state.view=saved.view;const firstMissing=questions().findIndex(q=>!state.answers[q.id]);state.step=Math.max(0,Math.min(Number(saved.step)||0,firstMissing<0?questions().length-1:firstMissing));}}catch{}
navigate(state.view,state.step,true);
