import {normalizeInternationalPhone} from './whatsapp-identity';
import type {ChatConversation} from './inbox-mock';
export type FunnelInteractionState={dirty:boolean;pending:boolean};
export const CLEAN_FUNNEL_INTERACTION:FunnelInteractionState={dirty:false,pending:false};
export type FunnelLeadSnapshot={
 workspaceId:string;actorId:string;requestedLeadId:string;
 lead:{id:string;name:string;email:string|null;phone:string|null;value:number;status:string;stageName:string|null;pipelineName:string|null;sourceName:string|null;responsibleName:string|null;createdAt:string;updatedAt:string;tags:string[];fields:Array<{id:string;name:string;value:string}>;whatsappWebUrl:string|null};
 conversation:ChatConversation;warnings:string[];
};
export function whatsappWebContactUrl(phone:unknown,normalized?:unknown):string|null{
 let p=normalizeInternationalPhone(phone);
 if(!p.ok&&typeof normalized==='string'){
  const trusted=normalizeInternationalPhone(normalized,{allowTrustedBare:true});
  const plain=typeof phone==='string'?phone.replace(/[\s().-]/g,''):'';
  if(trusted.ok&&plain===trusted.digits)p=trusted;
 }
 return p.ok?`https://web.whatsapp.com/send?phone=${encodeURIComponent(p.digits)}`:null;
}
export function describeField(value:unknown):string{
 if(value===null||value===undefined)return '';
 if(Array.isArray(value))return value.map(describeField).filter(Boolean).join(', ');
 if(typeof value==='object'){
  const v=value as Record<string,unknown>;
  if(v.display!==undefined)return describeField(v.display);
  if(v.raw!==undefined)return describeField(v.raw);
  return JSON.stringify(value);
 }
 return String(value);
}
export function normalizeContactTags(value:unknown):string[]{
 if(!Array.isArray(value))return [];
 return [...new Set(value.map(v=>typeof v==='string'?v:v&&typeof v==='object'&&typeof v.name==='string'?v.name:'').map(v=>v.trim()).filter(Boolean))];
}
export function funnelCloseDecision(state:FunnelInteractionState):'close'|'confirm-discard'|'wait'{return state.pending?'wait':state.dirty?'confirm-discard':'close';}
export function assertFunnelSnapshotScope(snapshot:FunnelLeadSnapshot,expected:{workspaceId:string;actorId:string;leadId:string}):FunnelLeadSnapshot{
 if(!snapshot||snapshot.workspaceId!==expected.workspaceId||snapshot.actorId!==expected.actorId||snapshot.requestedLeadId!==expected.leadId||!snapshot.lead?.id||snapshot.conversation?.id!==snapshot.lead.id||snapshot.conversation.leadId!==snapshot.lead.id||snapshot.conversation.channel!=='leads'||snapshot.conversation.isGroup)throw new Error('A ficha não corresponde ao contato e à empresa selecionados. Reabra o painel.');
 return snapshot;
}
