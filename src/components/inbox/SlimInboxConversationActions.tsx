import {useMutation,useQueryClient} from '@tanstack/react-query';
import {useServerFn} from '@tanstack/react-start';
import {CheckCircle2,Clock3,RotateCcw} from 'lucide-react';
import {toast} from 'sonner';
import {setInboxConversationStatus} from '@/lib/slim-inbox-conversation.functions';
export function SlimInboxConversationActions({leadId,status,onClose}:{leadId:string;status?:string;onClose:()=>void}){
 const save=useServerFn(setInboxConversationStatus),client=useQueryClient();
 const mutation=useMutation({mutationFn:(status:'aberta'|'aguardando'|'fechada')=>save({data:{leadId,status}}),onSuccess:()=>{for(const key of ['inbox','slim-funnel-detail','slim-funnel-contact'])void client.invalidateQueries({queryKey:[key]});toast.success('Estado da conversa atualizado.');onClose();},onError:()=>toast.error('Não foi possível atualizar a conversa. Tente novamente.')});
 const actions=[{status:'aguardando' as const,label:'Marcar como aguardando',Icon:Clock3,hide:status==='aguardando'},{status:'fechada' as const,label:'Fechar conversa',Icon:CheckCircle2,hide:status==='resolvido'},{status:'aberta' as const,label:'Reabrir conversa',Icon:RotateCcw,hide:status!=='resolvido'&&status!=='aguardando'}];
 return <>{actions.filter(a=>!a.hide).map(({status,label,Icon})=><button type="button" key={status} disabled={mutation.isPending} onClick={()=>mutation.mutate(status)} className="w-full flex items-center gap-2 px-3 py-2 text-xs hover:bg-white/5 disabled:opacity-40"><Icon className="h-3.5 w-3.5 text-primary"/>{label}</button>)}</>;
}
