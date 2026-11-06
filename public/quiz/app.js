'use strict';

// Respostas locais; o contato externo ocorre somente pela escolha do visitante.
const STORAGE_KEY = 'slim-saude-quiz:v2';
const WHATSAPP_GROUP_URL = 'https://chat.whatsapp.com/K8tkGBnE5IYKzHVfK6XXBc?s=cl&p=i&mlu=4&ilr=4&iam=2';
const state = { view: 'intro', step: 0, answers: {}, busy: false };
const main = document.querySelector('main');
const dialog = document.querySelector('#info-dialog');
const dialogContent = document.querySelector('#dialog-content');
const arrow = '';
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
  { id: 'readiness', label: 'VAMOS DAR O PRÓXIMO PASSO', title: 'Agora que você conhece os valores, qual é a sua decisão?', help: 'Escolha como você quer seguir com a Saúde Slim.', options: [
    ['now', 'Quero começar meu tratamento agora'], ['support', 'Quero entender como funciona o acompanhamento'], ['soon', 'Quero me organizar para começar nas próximas semanas'], ['conditions', 'Quero esclarecer as condições da oferta'], ['research', 'Quero tirar minhas dúvidas com um vendedor'] ] }
];
const offerQuestion = { id:'offer', label:'AGORA, VAMOS FALAR DO TRATAMENTO', title:'Qual opção você quer conhecer melhor?', help:'Conheça as condições iniciais e escolha o que faz sentido para o seu planejamento.', options:[['initial','1 ampola · R$250,00 no Pix'],['complete','Caixa com 4 ampolas · R$850,00 no Pix'],['questions','Quero entender as condições antes de escolher']] };
const offers = { initial:{name:'1 ampola',price:'R$250,00'},complete:{name:'Caixa com 4 ampolas',price:'R$850,00'},questions:{name:'Opções da oferta',price:'R$250,00'} };
const stepImages = {
  offer:{src:'oferta-saude-slim.jpg',alt:'Oferta Saúde Slim: uma ampola por R$250,00 ou caixa com quatro por R$850,00 no Pix'},
  goal:{src:'transformacao-corporal.png',alt:'Comparação corporal enviada para o quiz Saúde Slim'},
  history:{src:'transformacao-praia.png',alt:'Comparação antes e depois na praia'},
  doubt:{src:'transformacao-comparacao.png',alt:'Comparação corporal com rostos desfocados'},
  readiness:{src:'progresso-fitness.png',alt:'Registro de progresso corporal em quatro meses'}
};
const supportCopy = '<section class="treatment-support"><h2>Como a Saúde Slim acompanha você</h2><p><strong>Protocolo de tratamento:</strong> nossa equipe explica as etapas e esclarece suas dúvidas antes de começar.</p><p><strong>Acompanhamento:</strong> suporte ao longo da jornada para orientar os próximos passos.</p><p><strong>PDFs de apoio:</strong> materiais para ajudar na organização da rotina e em hábitos de emagrecimento saudável em casa.</p></section>';
function sellerUrl() {
  const offer=offers[state.answers.offer];
  const message=state.answers.offer==='questions' ? 'Olá! Vim do Quiz da Saúde Slim e quero tirar dúvidas sobre as ofertas e o acompanhamento.' : 'Olá! Vim do Quiz da Saúde Slim e escolhi a oferta: '+offer.name+' por '+offer.price+' no Pix. Quero falar com um vendedor sobre os próximos passos.';
  return 'https://wa.me/559286309669?text='+encodeURIComponent(message);
}
const contexts = {
  hunger: { title: 'Em qual momento a fome mais atrapalha seu planejamento?', help: 'Identifique a situação que mais se repete.', options: [['evening','No fim do dia'],['after-meals','Pouco tempo depois de comer'],['outside','Quando estou fora de casa'],['varies','Varia de um dia para o outro'],['planning','Quando fico muito tempo sem me alimentar']] },
  snacking: { title: 'Em qual situação você mais come fora do que planejou?', help: 'Marque o momento que mais atrapalha sua tentativa de emagrecer.', options: [['work','Durante o trabalho ou as tarefas do dia'],['evening','Depois do jantar'],['busy','Quando fico sem uma rotina definida'],['varies','Em vários momentos do dia'],['social','Quando saio ou encontro outras pessoas']] },
  routine: { title: 'O que faz você abandonar a rotina que começou?', help: 'Escolha a dificuldade que mais precisa mudar.', options: [['time','Falta de tempo para me organizar'],['changes','Meus horários mudam muito'],['food','Organizar a alimentação no dia a dia'],['support','Falta de apoio e de um caminho claro'],['followup','Começo sem saber como acompanhar meu progresso']] },
  regain: { title: 'Quando o peso volta, o que mais te frustra?', help: 'Marque o que mais faz você querer sair desse ciclo.', options: [['effort','Sentir que todo o esforço ficou para trás'],['restart','Ter que começar tudo de novo'],['maintenance','Não entender como manter o progresso'],['fear','Ficar com receio de tentar outra vez'],['alone','Sentir que estou enfrentando isso sem apoio']] },
  start: { title: 'O que falta para você decidir com confiança?', help: 'Escolha a informação que mais pesa na sua decisão.', options: [['steps','Entender como funcionam os primeiros passos'],['support','Saber quem acompanha e como é o suporte'],['cost','Ter clareza sobre opções e valores'],['questions','Poder perguntar antes de decidir'],['trust','Entender se posso confiar no serviço e no acompanhamento']] }
};
function questions() { return [...coreQuestions.slice(0,3), { id:'context', label:'ONDE ESTÁ O OBSTÁCULO', ...contexts[state.answers.pain || 'start'] }, coreQuestions[3], offerQuestion, coreQuestions[4]]; }
function escapeHtml(value) { return String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function answerLabel(id) { const q=questions().find(q=>q.id===id); return q?.options.find(o=>o[0]===state.answers[id])?.[1] || ''; }
function focusTitle() { const heading=main.querySelector('h1'); if(heading) { heading.tabIndex=-1; heading.focus({preventScroll:true}); } }
function saveProgress(){try{sessionStorage.setItem(STORAGE_KEY,JSON.stringify({view:state.view,step:state.step,answers:state.answers}));}catch{}}
function navigate(view,step=0,replace=false) { clearTimeout(state.timer);state.view=view;state.step=step;state.busy=false;saveProgress();const hash=view==='intro'?'#inicio':view==='result'?'#resultado':`#pergunta-${step+1}`;history[replace?'replaceState':'pushState']({view,step},'',hash);render();window.scrollTo({top:0,behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'instant':'smooth'});focusTitle(); }
function render() { if(state.view==='quiz') renderQuestion(); else if(state.view==='result') renderResult(); else renderIntro(); }
function renderIntro() {
  main.innerHTML=`<section class="intro-simple enter"><div class="intro-simple-panel"><h1>Quer emagrecer e <br><em>voltar a se sentir bem com seu corpo?</em></h1><p>Responda 7 perguntas para dar o primeiro passo no seu protocolo de emagrecimento saudável.</p><button class="primary" data-start>Acessar meu protocolo agora ${arrow}</button></div></section>`;
  main.querySelector('[data-start]').onclick=()=>navigate('quiz');
}
function renderQuestion() {
  const list=questions(); const q=list[state.step]; const number=state.step+1;
  const visual=stepImages[q.id];
  const photo=visual ? `<img src="assets/${visual.src}" alt="${visual.alt}" width="600" height="750">` : '';
  main.innerHTML=`<section class="quiz-wrap enter ${visual?'has-photo':'text-only'}">${visual?`<aside class="quiz-aside"><div class="aside-image">${photo}</div></aside>`:''}<div class="quiz-panel"><div class="progress-meta"><span>Pergunta <strong>${number} de ${list.length}</strong></span><span>${Math.round(number/list.length*100)}% do questionário</span></div><div class="progress" role="progressbar" aria-label="Progresso do questionário" aria-valuemin="0" aria-valuemax="${list.length}" aria-valuenow="${number}"><span style="width:${number/list.length*100}%"></span></div><h1 class="question-title">${q.title}</h1><p class="question-help">${q.help}</p>${visual?`<div class="question-photo">${photo}</div>`:''}${q.id==='offer'?supportCopy:''}${q.id==='context'?`<div class="question-context">Você contou: <strong>${escapeHtml(answerLabel('pain'))}</strong>.</div>`:''}<div class="options" role="group" aria-label="Alternativas">${q.options.map(([id,text],i)=>`<button class="option ${state.answers[q.id]===id?'selected':''} ${q.id==='offer'&&id!=='questions'?'offer-option':''}" data-answer="${id}" aria-pressed="${state.answers[q.id]===id}"><span class="option-number" aria-hidden="true">${state.answers[q.id]===id?'✓':String(i+1).padStart(2,'0')}</span><span class="option-title">${q.id==='offer'&&id!=='questions'?`<span class="offer-name">${offers[id].name}</span><span class="offer-price">${offers[id].price} <small>no Pix</small></span>`:escapeHtml(text)}</span></button>`).join('')}</div><div class="question-bottom"><button class="back" data-back>${state.step===0?'Voltar ao início':'Voltar'}</button></div></div></section>`;
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
  main.innerHTML='<section class="processing" aria-live="polite"><div class="pulse" aria-hidden="true">✳</div><h1>Tudo certo para o próximo passo.</h1><p>Escolha como você quer falar com a Saúde Slim.</p></section>';
  state.timer=setTimeout(()=>navigate('result'),650);
}
function renderResult() {
  if(!questions().every(q=>state.answers[q.id])) { const missing=questions().findIndex(q=>!state.answers[q.id]);navigate('quiz',Math.max(0,missing),true);return; }
  main.innerHTML=`<section class="result result-simple"><article class="next-step"><div class="result-content"><div class="result-offer"><img src="assets/oferta-saude-slim.jpg" alt="Oferta Saúde Slim de uma ampola ou caixa com quatro ampolas" width="1122" height="1402"></div><div class="result-actions"><h1>Como você quer continuar?</h1><p>Entre no grupo para acompanhar as informações ou converse diretamente com um vendedor.</p><a class="primary group-cta" data-group href="${escapeHtml(WHATSAPP_GROUP_URL)}" target="_blank" rel="noopener noreferrer">${waIcon}<span>Quero entrar no grupo Saúde Slim</span>${arrow}</a><a class="primary seller-cta" data-seller href="${escapeHtml(sellerUrl())}" target="_blank" rel="noopener noreferrer">${waIcon}<span>Falar Agora com Vendedor Online</span>${arrow}</a><div class="result-proof result-gallery"><img src="assets/transformacao-corporal.png" alt="Comparação corporal"><img src="assets/transformacao-praia.png" alt="Antes e depois na praia"><img src="assets/transformacao-comparacao.png" alt="Comparação com rostos desfocados"><img src="assets/progresso-fitness.png" alt="Registro de progresso em quatro meses"></div></div></div></article></section>`;

  main.querySelector('[data-group]').onclick=animateGroupButton;
}
function showDialog(content) { dialogContent.innerHTML=content;dialog.showModal();dialogContent.querySelector('[data-close]')?.addEventListener('click',()=>dialog.close()); }
function animateGroupButton(event) {
  const button=event.currentTarget; if(button.querySelector('.ripple'))return;
  const ripple=document.createElement('span');ripple.className='ripple';ripple.style.left=`${button.clientWidth/2-110}px`;ripple.style.top=`${button.clientHeight/2-110}px`;button.append(ripple);
  button.classList.add('cta-activated');
  setTimeout(()=>{ripple.remove();button.classList.remove('cta-activated');},650);
}
document.querySelector('[data-home]').onclick=event=>{event.preventDefault();navigate('intro');};
document.querySelector('.dialog-close').onclick=()=>dialog.close();
dialog.addEventListener('click',event=>{if(event.target===dialog){const r=dialog.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)dialog.close();}});
window.addEventListener('popstate',event=>{clearTimeout(state.timer);const view=event.state?.view||'intro';const requested=event.state?.step||0;if(view==='quiz'){const firstMissing=questions().findIndex(q=>!state.answers[q.id]);state.step=firstMissing<0?requested:Math.min(requested,firstMissing);}state.view=view;state.busy=false;saveProgress();render();focusTitle();});
document.addEventListener('keydown',event=>{if(dialog.open||state.view!=='quiz'||state.busy||event.altKey||event.ctrlKey||event.metaKey)return;const index=Number(event.key)-1;const q=questions()[state.step];if(/^[1-5]$/.test(event.key)&&q.options[index]){event.preventDefault();selectAnswer(q,q.options[index][0]);}});
try{const saved=JSON.parse(sessionStorage.getItem(STORAGE_KEY)||'null');if(saved&&['intro','quiz','result'].includes(saved.view)){const raw=saved.answers||{};for(const id of ['goal','pain','history','context','doubt','offer','readiness']){const q=questions().find(item=>item.id===id);if(q?.options.some(option=>option[0]===raw[id]))state.answers[id]=raw[id];}state.view=saved.view;const firstMissing=questions().findIndex(q=>!state.answers[q.id]);state.step=Math.max(0,Math.min(Number(saved.step)||0,firstMissing<0?questions().length-1:firstMissing));}}catch{}
navigate(state.view,state.step,true);
