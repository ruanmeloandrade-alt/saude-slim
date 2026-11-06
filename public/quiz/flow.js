'use strict';
// Perguntas locais: cada escolha seleciona a continuação correspondente.
(() => {
  const ids = ['goal','pain','history','context','doubt','offer','readiness'];
  const goals = {
    comfort: {
      label:'Não me sinto bem quando visto minhas roupas', focus:'voltar a se sentir bem com suas roupas',
      title:'O que mais incomoda você quando vai se vestir?',
      support:'Seu objetivo é voltar a se vestir com conforto e confiança. O protocolo e o acompanhamento precisam fazer sentido na sua rotina.',
      pdf:'Os PDFs de apoio ajudam a organizar alimentação e hábitos em casa, junto do acompanhamento da equipe.',
      details:[
        ['favorites','Minhas roupas favoritas não servem mais','voltar a usar suas roupas favoritas','O que mais atrapalha você a voltar a usar suas roupas favoritas?'],
        ['shopping','Comprar roupa virou uma frustração','comprar roupas com mais confiança','O que falta para você começar a mudar essa experiência ao comprar roupas?'],
        ['hide','Escolho roupas só para esconder meu corpo','se vestir com mais liberdade','O que mais impede você de se vestir com a liberdade que gostaria?'],
        ['events','Evito eventos por causa das roupas','voltar aos eventos com confiança','O que dificulta dar o primeiro passo para voltar aos eventos com confiança?'],
        ['comfort','Minhas roupas apertam no dia a dia','ter mais conforto ao se vestir','O que mais dificulta cuidar do seu conforto no dia a dia?']
      ]
    },
    health: {
      label:'Tenho adiado o cuidado com a minha saúde', focus:'retomar o cuidado com sua saúde',
      title:'Qual cuidado com a sua saúde você mais tem adiado?',
      support:'Você quer retomar o cuidado com a saúde. A equipe explica as etapas do protocolo e conversa sobre como o acompanhamento se encaixa nos cuidados que você procura.',
      pdf:'Você também pode contar com materiais de apoio para organizar hábitos em casa e levar suas dúvidas ao acompanhamento.',
      details:[
        ['food','Organizar melhor minha alimentação','organizar melhor sua alimentação','O que mais tem impedido você de cuidar da alimentação?'],
        ['routine','Criar uma rotina de cuidados','retomar sua rotina de cuidados','O que faz você deixar sua rotina de cuidados para depois?'],
        ['guidance','Buscar orientação antes de começar','começar com orientação','O que falta para você buscar orientação e começar com confiança?'],
        ['followup','Acompanhar meu progresso com orientação','acompanhar seu progresso com orientação','O que dificulta acompanhar seu progresso de perto?'],
        ['priority','Parar de deixar minha saúde em último lugar','colocar seu cuidado entre as prioridades','O que costuma fazer você deixar seu próprio cuidado por último?']
      ]
    },
    energy: {
      label:'Sinto falta de fôlego e disposição no dia a dia', focus:'ter mais disposição no dia a dia',
      title:'Em qual situação você mais sente falta de disposição?',
      support:'Você quer participar mais do dia a dia. Na conversa com a equipe, explique suas dificuldades e conheça o protocolo e o acompanhamento disponíveis.',
      pdf:'Os materiais de apoio ajudam a organizar hábitos no dia a dia; a equipe esclarece os cuidados e os próximos passos para o seu objetivo.',
      details:[
        ['stairs','Ao subir escadas ou caminhar','retomar suas caminhadas com mais confiança','O que mais atrapalha você a começar uma rotina de cuidado para retomar suas caminhadas?'],
        ['work','Durante o trabalho e as tarefas do dia','cuidar da disposição para suas tarefas','O que dificulta cuidar de você em meio às tarefas do dia?'],
        ['family','Ao acompanhar minha família nos passeios','participar mais dos momentos em família','O que mais impede você de começar a cuidar desse objetivo com sua família?'],
        ['activities','Ao tentar retomar atividades que eu gostava','retomar as atividades de que você gosta','O que mais trava seu primeiro passo para retomar essas atividades?'],
        ['everyday','Em vários momentos, mesmo sem esforço intenso','entender seus próximos passos de cuidado','O que falta para você conversar com uma equipe sobre suas dificuldades e objetivos?']
      ]
    },
    regain: {
      label:'Emagreço, mas depois ganho tudo de novo', focus:'manter seu progresso com mais apoio',
      title:'O que costuma acontecer antes de você recuperar o peso?',
      support:'Seu esforço anterior não precisa ser ignorado. Conheça como a equipe apresenta o protocolo e o acompanhamento para conversar sobre continuidade e dificuldades.',
      pdf:'Os PDFs de apoio entram como material para organizar hábitos em casa e acompanhar sua rotina.',
      details:[
        ['abandon','Acabo abandonando a rotina que comecei','manter uma rotina depois do começo','O que mais faz você abandonar a rotina depois de começar?'],
        ['hunger','A fome e a vontade de comer voltam a atrapalhar','entender o que atrapalha sua alimentação','O que mais dificulta lidar com a alimentação quando você tenta manter o progresso?'],
        ['alone','Paro de ter orientação e tento seguir sozinho','seguir com acompanhamento','O que falta para você continuar com apoio em vez de enfrentar tudo sozinho?'],
        ['strict','Sigo algo muito restritivo e não consigo manter','construir uma rotina que faça sentido para você','O que mais atrapalha você a manter uma rotina sem abandonar tudo?'],
        ['unknown','Não entendo por que o peso volta','esclarecer suas dúvidas sobre continuidade','O que falta para você entender melhor suas dificuldades e próximos passos?']
      ]
    },
    confidence: {
      label:'Não me sinto bem quando me olho no espelho', focus:'se sentir melhor ao se olhar no espelho',
      title:'Em qual momento isso mais mexe com a sua confiança?',
      support:'Seu objetivo merece uma conversa respeitosa. A equipe apresenta o protocolo, o acompanhamento e os próximos passos a partir do que você deseja mudar.',
      pdf:'Os PDFs de apoio ajudam na organização de hábitos em casa, como complemento da conversa e do acompanhamento da equipe.',
      details:[
        ['mirror','Quando me olho no espelho','se olhar no espelho com mais confiança','O que mais impede você de começar a cuidar da mudança que deseja ver no espelho?'],
        ['photos','Quando vejo minhas fotos','se sentir mais à vontade nas fotos','O que mais trava seu primeiro passo para se sentir mais à vontade nas fotos?'],
        ['social','Quando vou encontrar outras pessoas','se sentir mais à vontade nos encontros','O que dificulta começar a cuidar da sua confiança para esses encontros?'],
        ['comparison','Quando comparo meu corpo com o de outras pessoas','focar no seu próprio objetivo','O que mais dificulta focar no seu próprio cuidado sem se comparar?'],
        ['plans','Quando deixo de fazer algo por insegurança','voltar a fazer seus planos com confiança','O que mais impede você de dar um passo para retomar esses planos?']
      ]
    }
  };
  const barrierLabels={
    comfort:['Adio minha rotina de cuidados e as roupas continuam me incomodando','A fome e a vontade de comer dificultam minhas tentativas','Começo, mas desanimo antes de perceber diferença nas roupas','Sinto falta de orientação para começar a cuidar desse objetivo','Tenho receio de investir sem entender o acompanhamento'],
    health:['Minha rotina faz eu deixar o cuidado com a saúde para depois','Tenho dificuldade para organizar a alimentação','Começo a me cuidar, mas logo interrompo a rotina','Não sei por onde começar a buscar acompanhamento','Preciso entender o protocolo e o suporte antes de decidir'],
    energy:['Os horários do dia deixam pouco espaço para cuidar de mim','A alimentação fica desorganizada na correria','Começo a mudar a rotina, mas perco a constância','Quero orientação para conversar sobre minhas dificuldades','Tenho dúvidas sobre como o acompanhamento funciona'],
    regain:['Depois do começo, minha rotina volta a ficar desorganizada','A fome e a vontade de comer voltam a atrapalhar','Uma dificuldade me faz abandonar tudo e recomeçar','Falta alguém para orientar a continuidade','Tenho medo de investir em mais uma tentativa sem entender o serviço'],
    confidence:['Adio os cuidados mesmo querendo me sentir melhor','A alimentação fora do planejado me frustra','Começo com vontade, mas desanimo e paro','Quero um caminho explicado para não enfrentar isso sozinho','Preciso confiar no acompanhamento antes de começar']
  };
  const barriers = {
    planning:{
      label:'Minha rotina fica desorganizada e eu adio os cuidados', question:'o que mais dificulta organizar seus horários?',
      help:'O acompanhamento pode ajudar você a conversar sobre como encaixar as etapas do protocolo na rotina que realmente tem.',
      options:[['work','Os horários do trabalho mudam','Com seus horários de trabalho variando'],['family','Cuido de outras pessoas e me deixo por último','Com tantas responsabilidades com outras pessoas'],['meals','Não consigo organizar minhas refeições','Com dificuldade para organizar as refeições'],['busy','Começo a semana sem planejar meus cuidados','Com a semana começando sem planejamento'],['time','Acho que preciso de muito tempo para começar','Com pouco tempo disponível para começar']]
    },
    hunger:{
      label:'A fome e a vontade de comer atrapalham minhas tentativas',question:'em qual momento a alimentação mais sai do que você planejou?',
      help:'Sua dificuldade com a alimentação pode ser levada à equipe. Conheça as etapas do protocolo e esclareça como funciona o acompanhamento.',
      options:[['night','No fim do dia ou depois do jantar','Quando o fim do dia atrapalha seus planos'],['intervals','Quando fico muito tempo sem me alimentar','Com intervalos longos entre as refeições'],['snacks','Quando começo a comer fora das refeições','Quando comer fora das refeições atrapalha sua rotina'],['outside','Quando estou fora de casa','Com a dificuldade de se organizar fora de casa'],['varies','Isso muda bastante de um dia para o outro','Com dificuldades que mudam de um dia para o outro']]
    },
    constancy:{
      label:'Começo com vontade, mas perco a constância',question:'o que costuma fazer você perder a constância?',
      help:'A proposta é apresentar um caminho com etapas explicadas e acompanhamento, para que você possa conversar sobre as dificuldades de continuar.',
      options:[['results','Desanimo quando não vejo a mudança que esperava','Quando a demora para perceber mudanças desanima'],['setback','Um dia fora da rotina me faz abandonar tudo','Quando um dia difícil interrompe sua rotina'],['strict','Não consigo manter mudanças muito radicais','Quando as mudanças parecem radicais demais'],['alone','Perco o ânimo quando tento seguir sozinho','Quando seguir sozinho faz você perder o ânimo'],['restart','Tenho receio de começar e me frustrar de novo','Com o receio de começar e se frustrar novamente']]
    },
    support:{
      label:'Sinto falta de orientação e de alguém para acompanhar',question:'qual apoio mais faz falta para você continuar?',
      help:'O acompanhamento faz parte da apresentação do serviço: a equipe explica o protocolo, responde às dúvidas e orienta os próximos passos.',
      options:[['steps','Saber quais são os primeiros passos','Com dúvidas sobre os primeiros passos'],['questions','Poder esclarecer dúvidas durante a jornada','Com dúvidas surgindo durante a jornada'],['progress','Entender como acompanhar meu progresso','Com a dificuldade de acompanhar seu progresso'],['routine','Receber orientação para organizar minha rotina','Com a necessidade de organizar sua rotina'],['materials','Ter materiais de apoio para consultar em casa','Com a necessidade de apoio também em casa']]
    },
    trust:{
      label:'Tenho dúvidas e receio de investir sem entender o tratamento',question:'o que você precisa esclarecer para decidir com confiança?',
      help:'Antes de decidir, você pode conhecer o protocolo, o acompanhamento e os materiais incluídos, e levar suas dúvidas à equipe.',
      options:[['protocol','Como funciona o protocolo e suas etapas','Com dúvidas sobre como o protocolo funciona'],['followup','Como funciona o acompanhamento da equipe','Com dúvidas sobre o acompanhamento'],['fit','Como encaixar isso no meu dia a dia','Com dúvidas sobre encaixar o cuidado no dia a dia'],['included','O que está incluído no atendimento','Com dúvidas sobre o que está incluído'],['conversation','Quero conversar com uma pessoa antes de decidir','Preferindo conversar antes de decidir']]
    }
  };
  const supportChoices = [
    ['steps','Um começo organizado, com as etapas explicadas'],
    ['followup','Acompanhamento para esclarecer dúvidas ao longo da jornada'],
    ['routine','Orientação para encaixar os cuidados na minha rotina'],
    ['pdf','PDFs de apoio para consultar e usar em casa'],
    ['talk','Conversar com a equipe e entender tudo antes de decidir']
  ];
  const first = {id:'goal',title:'O que mais incomoda você no seu peso hoje?',help:'Marque o que mais faz você querer mudar essa situação.',options:Object.entries(goals).map(([id,g])=>[id,g.label])};
  function questions(answers={}) {
    const goal=goals[answers.goal]||goals.comfort;
    const detail=goal.details.find(d=>d[0]===answers.pain)||goal.details[0];
    const barrier=barriers[answers.history]||barriers.planning;
    const situation=barrier.options.find(d=>d[0]===answers.context)||barrier.options[0];
    const support=supportChoices.find(d=>d[0]===answers.doubt)||supportChoices[0];
    const supportHelp={steps:'Vamos apresentar as condições para começar com as etapas explicadas.',followup:'Veja as condições para conhecer o protocolo e conversar sobre o acompanhamento.',routine:'Conheça as condições e esclareça com a equipe como o cuidado pode entrar na sua rotina.',pdf:'Os materiais de apoio fazem parte da conversa sobre o protocolo e o acompanhamento. Veja as condições para começar.',talk:'Veja as condições iniciais. Na próxima tela, você pode escolher falar com um vendedor ou entrar no grupo.'};
    const offerName=answers.offer==='complete'?'a caixa com quatro ampolas':answers.offer==='initial'?'uma ampola':'as opções do tratamento';
    return [
      first,
      {id:'pain',title:goal.title,help:'Escolha a situação que melhor representa o que você quer mudar.',options:goal.details.map(d=>[d[0],d[1]])},
      {id:'history',title:detail[3],help:goal.support,options:Object.entries(barriers).map(([id,b],i)=>[id,barrierLabels[answers.goal||'comfort'][i]])},
      {id:'context',title:`Para ${detail[2]}, ${barrier.question}`,help:barrier.help,options:barrier.options.map(d=>[d[0],d[1]])},
      {id:'doubt',title:`${situation[2]}, que apoio ajudaria você a ${detail[2]}?`,help:goal.pdf,options:supportChoices.map(([id,label])=>[id,label])},
      {id:'offer',title:'Qual opção você quer conhecer melhor?',help:supportHelp[support[0]],options:[['initial','1 ampola · R$250,00 no Pix'],['complete','Caixa com 4 ampolas · R$850,00 no Pix'],['questions','Quero entender as condições antes de escolher']]},
      {id:'readiness',title:`Agora que você conhece as condições para ${offerName}, como quer seguir?`,help:'Escolha o seu próximo passo. Depois, você decide entre o grupo e o contato direto com um vendedor.',options:[['now','Quero começar meu tratamento agora'],['support','Quero entender como funciona o acompanhamento'],['soon','Quero me organizar para começar nas próximas semanas'],['conditions','Quero esclarecer as condições da oferta'],['research','Quero tirar minhas dúvidas com um vendedor']]}
    ];
  }
  function choose(answers,id,value){
    const index=ids.indexOf(id);const q=questions(answers)[index];
    if(!q?.options.some(o=>o[0]===value))return false;
    if(answers[id]!==value){for(const next of ids.slice(index+1))delete answers[next];}
    answers[id]=value;return true;
  }
  function restore(raw){
    const answers={};if(!raw||typeof raw!=='object')return answers;
    for(const id of ids){const q=questions(answers).find(q=>q.id===id);if(!q.options.some(o=>o[0]===raw[id]))break;answers[id]=raw[id];}
    return answers;
  }
  globalThis.SlimQuizFlow=Object.freeze({ids,questions,choose,restore});
})();
