type Db={from:(table:string)=>any;rpc:(name:string,args:Record<string,unknown>)=>Promise<{data:any;error:any}>};
type Enqueue=(db:Db,input:any)=>Promise<Array<{ok:boolean;error?:string;skipped?:boolean;queuedFor?:string}>>;
export async function dispatchSlimStageMove(db:Db,event:any,enqueue:Enqueue):Promise<'dispatched'|'skipped'>{
 const r=await db.from('leads').select('id,stage_id,pipeline_id,merged_into_id,status').eq('id',event.lead_id).eq('workspace_id',event.workspace_id).maybeSingle();
 if(r.error)throw new Error('Não foi possível conferir o cliente da movimentação.');
 const lead=r.data;
 if(!lead||lead.merged_into_id||['deleted','archived','merged'].includes(lead.status)||lead.stage_id!==event.to_stage_id||lead.pipeline_id!==event.pipeline_id)return 'skipped';
 const results=await enqueue(db,{workspaceId:event.workspace_id,leadId:event.lead_id,pipelineId:event.pipeline_id,stageId:event.to_stage_id,fromStageId:event.from_stage_id,event:'moved',eventId:'slim-stage-move:'+event.id,deferExecution:true});
 if(!Array.isArray(results)||results.some(r=>!r.ok))throw new Error('O evento foi preservado, mas um dos gatilhos não pôde ser enfileirado.');
 return 'dispatched';
}
export async function processSlimStageMoveEvents(db:Db,enqueue:Enqueue):Promise<number>{
 const stale=new Date(Date.now()-120000).toISOString();
 const list=await db.from('slim_stage_move_events').select('id').or(`status.eq.pending,and(status.eq.dispatching,started_at.lt.${stale})`).lt('attempts',5).order('created_at').limit(4);
 if(list.error)throw new Error('Fila de movimentações indisponível.');let processed=0;
 for(const item of list.data??[]){
  const claim=await db.rpc('slim_claim_stage_move',{_id:item.id});if(claim.error)throw new Error('Não foi possível reservar a movimentação.');const event=claim.data?.[0];if(!event)continue;
  try{
   const state=await dispatchSlimStageMove(db,event,enqueue);
   const saved=await db.from('slim_stage_move_events').update({status:state,finished_at:new Date().toISOString(),last_error:null}).eq('id',event.id).eq('status','dispatching').eq('attempts',event.attempts);
   if(saved.error)throw new Error('Não foi possível confirmar o enfileiramento.');processed++;
  }catch{
   const saved=await db.from('slim_stage_move_events').update({status:event.attempts<5?'pending':'error',last_error:'Enfileiramento não concluído. O evento foi preservado para conferência.'}).eq('id',event.id).eq('status','dispatching').eq('attempts',event.attempts);
   if(saved.error)throw new Error('Não foi possível registrar a tentativa da movimentação.');
  }
 }
 return processed;
}
