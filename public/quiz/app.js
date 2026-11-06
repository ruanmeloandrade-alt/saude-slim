'use strict';

// Respostas locais; o contato externo ocorre somente pela escolha do visitante.
const STORAGE_KEY = 'slim-saude-quiz:v5';
const WHATSAPP_GROUP_URL = 'https://chat.whatsapp.com/K8tkGBnE5IYKzHVfK6XXBc?s=cl&p=i&mlu=4&ilr=4&iam=2';
const state = { view: 'intro', step: 0, answers: {}, busy: false };
const main = document.querySelector('main');
const dialog = document.querySelector('#info-dialog');
const dialogContent = document.querySelector('#dialog-content');
const arrow = '';
const waIcon = '<svg class="wa-icon" aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M20.5 11.6a8.5 8.5 0 0 1-12.7 7.5L3 20.5l1.4-4.7A8.5 8.5 0 1 1 20.5 11.6Z"/><path d="M8.1 7.5c.5 4 2.9 6.5 6.9 7l1.1-1.8-2.2-1.1-1 1c-1.5-.6-2.6-1.8-3.2-3.2l1-1-1-2.1-1.6 1.2Z" stroke-linejoin="round"/></svg>';
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
function questions() { return SlimQuizFlow.questions(state.answers); }
function escapeHtml(value) { return String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function answerLabel(id) { const q=questions().find(q=>q.id===id); return q?.options.find(o=>o[0]===state.answers[id])?.[1] || ''; }
function focusTitle() { const heading=main.querySelector('h1'); if(heading) { heading.tabIndex=-1; heading.focus({preventScroll:true}); } }
function saveProgress(){try{sessionStorage.setItem(STORAGE_KEY,JSON.stringify({view:state.view,step:state.step,answers:state.answers}));}catch{}}
function navigate(view,step=0,replace=false) { clearTimeout(state.timer);state.view=view;state.step=step;state.busy=false;saveProgress();const hash=view==='intro'?'#inicio':view==='result'?'#resultado':`#pergunta-${step+1}`;history[replace?'replaceState':'pushState']({view,step},'',hash);render();window.scrollTo({top:0,behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'instant':'smooth'});focusTitle(); }
function render() { if(state.view==='quiz') renderQuestion(); else if(state.view==='result') renderResult(); else renderIntro(); }
function renderIntro() {
  main.innerHTML=`<section class="intro-simple enter"><div class="intro-simple-panel"><h1>Quer emagrecer e <br><em>voltar a se sentir bem com seu corpo?</em></h1><p>Responda algumas perguntas para dar o primeiro passo no seu protocolo de emagrecimento saudável.</p><button class="primary" data-start>Acessar meu protocolo agora ${arrow}</button></div></section>`;
  main.querySelector('[data-start]').onclick=()=>navigate('quiz');
}
function renderQuestion() {
  const list=questions(); const q=list[state.step]; const number=state.step+1;
  const visual=stepImages[q.id];
  const photo=visual ? `<img src="assets/${visual.src}" alt="${visual.alt}" width="600" height="750">` : '';
  main.innerHTML=`<section class="quiz-wrap enter ${visual?'has-photo':'text-only'} ${q.id==='offer'?'offer-step':q.id==='readiness'?'readiness-step':''} ${SlimQuizFlow.ids.indexOf(q.id)<7?'profile-step':''}">${visual?`<aside class="quiz-aside"><div class="aside-image">${photo}</div></aside>`:''}<div class="quiz-panel"><div class="progress-meta"><span>Pergunta <strong>${number} de ${list.length}</strong></span><span>${Math.round(number/list.length*100)}% do questionário</span></div><div class="progress" role="progressbar" aria-label="Progresso do questionário" aria-valuemin="0" aria-valuemax="${list.length}" aria-valuenow="${number}"><span style="width:${number/list.length*100}%"></span></div><h1 class="question-title">${escapeHtml(q.title)}</h1><p class="question-help">${escapeHtml(q.help)}</p>${visual?`<div class="question-photo">${photo}</div>`:''}${q.id==='offer'?supportCopy:''}${q.type==='input'?`<form class="profile-form" data-profile-form novalidate><label for="quiz-profile-input">${escapeHtml(q.fieldLabel)}</label><input id="quiz-profile-input" name="${q.id}" inputmode="${q.inputMode}" autocomplete="${q.id==='name'?'given-name':'off'}" maxlength="${q.id==='name'?40:12}" placeholder="${escapeHtml(q.placeholder)}" value="${escapeHtml(state.answers[q.id]??'')}" required><p class="field-error" data-profile-error role="alert"></p><button class="primary" type="submit">Continuar</button></form>`:''}<div class="options" role="group" aria-label="Alternativas">${q.options.map(([id,text],i)=>`<button class="option ${state.answers[q.id]===id?'selected':''} ${q.id==='offer'&&id!=='questions'?'offer-option':''}" data-answer="${id}" aria-pressed="${state.answers[q.id]===id}"><span class="option-number" aria-hidden="true">${state.answers[q.id]===id?'✓':String(i+1).padStart(2,'0')}</span><span class="option-title">${q.id==='offer'&&id!=='questions'?`<span class="offer-name">${offers[id].name}</span><span class="offer-price">${offers[id].price} <small>no Pix</small></span>`:escapeHtml(text)}</span></button>`).join('')}</div><div class="question-bottom"><button class="back" data-back>${state.step===0?'Voltar ao início':'Voltar'}</button></div></div></section>`;
  const form=main.querySelector('[data-profile-form]');if(form)form.onsubmit=event=>{event.preventDefault();const input=main.querySelector('#quiz-profile-input');if(!SlimQuizFlow.choose(state.answers,q.id,input.value)){main.querySelector('[data-profile-error]').textContent=q.error;input.focus();return;}saveProgress();navigate('quiz',state.step+1);};
  main.querySelectorAll('[data-answer]').forEach(button=>button.onclick=()=>selectAnswer(q,button.dataset.answer));
  main.querySelector('[data-back]').onclick=()=>state.step===0?navigate('intro'):navigate('quiz',state.step-1);
}
function selectAnswer(q,value) {
  if(state.busy||!SlimQuizFlow.choose(state.answers,q.id,value))return;
  if(q.id==='confirm'&&value==='edit'){saveProgress();navigate('quiz',SlimQuizFlow.ids.indexOf('name'));return;}
  state.busy=true;
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
  if(SlimQuizFlow.firstMissing(state.answers)!==-1) { const missing=SlimQuizFlow.firstMissing(state.answers);navigate('quiz',Math.max(0,missing),true);return; }
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
window.addEventListener('popstate',event=>{clearTimeout(state.timer);const view=event.state?.view||'intro';const requested=event.state?.step||0;if(view==='quiz'){const firstMissing=SlimQuizFlow.firstMissing(state.answers);state.step=firstMissing<0?requested:Math.min(requested,firstMissing);}state.view=view;state.busy=false;saveProgress();render();focusTitle();});
document.addEventListener('keydown',event=>{if(dialog.open||state.view!=='quiz'||state.busy||event.altKey||event.ctrlKey||event.metaKey)return;if(['INPUT','TEXTAREA','SELECT'].includes(event.target?.tagName)||event.target?.isContentEditable)return;const index=Number(event.key)-1;const q=questions()[state.step];if(/^[1-5]$/.test(event.key)&&q.options[index]){event.preventDefault();selectAnswer(q,q.options[index][0]);}});
try{const saved=JSON.parse(sessionStorage.getItem(STORAGE_KEY)||'null');if(saved&&['intro','quiz','result'].includes(saved.view)){const raw=saved.answers||{};state.answers=SlimQuizFlow.restore(raw);state.view=saved.view;const firstMissing=SlimQuizFlow.firstMissing(state.answers);state.step=Math.max(0,Math.min(Number(saved.step)||0,firstMissing<0?questions().length-1:firstMissing));}}catch{}
navigate(state.view,state.step,true);
