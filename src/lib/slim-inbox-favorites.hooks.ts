import {useQuery,useMutation,useQueryClient} from '@tanstack/react-query';
import {useServerFn} from '@tanstack/react-start';
import {listInboxFavorites,setInboxFavorite} from './slim-inbox-favorites.functions';
import {toast} from 'sonner';
export function useInboxFavorites(workspaceId?:string|null,actorId?:string|null){
 const list=useServerFn(listInboxFavorites),save=useServerFn(setInboxFavorite),client=useQueryClient();
 const key=['inbox','personal-favorites',workspaceId,actorId];
 const query=useQuery({queryKey:key,enabled:Boolean(workspaceId&&actorId),queryFn:()=>list(),staleTime:30_000});
 const toggle=useMutation({mutationFn:(data:{kind:'bot'|'agent'|'lead'|'group';targetId:string;favorite:boolean})=>save({data}),onSuccess:()=>client.invalidateQueries({queryKey:key}),onError:()=>toast.error('Não foi possível salvar o favorito. Tente novamente.')});
 const current=query.data&&query.data.workspaceId===workspaceId&&query.data.actorId===actorId?query.data.favorites:[];
 const ids=(kind:'bot'|'agent'|'lead'|'group')=>new Set(current.filter(row=>row.kind===kind).map(row=>row.target_id));
 return {ids,toggle:toggle.mutate,pending:toggle.isPending,error:query.error};
}
