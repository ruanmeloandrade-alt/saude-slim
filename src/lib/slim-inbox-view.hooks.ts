import {useEffect,useState} from 'react';
const views=new Map<string,string>();
function read(key:string|null,fallback:string){if(!key)return fallback;try{return views.get(key)??sessionStorage.getItem(key)??fallback;}catch{return views.get(key)??fallback;}}
/** Navigation remounts the Inbox; retain the selected view, isolated by actor/company. */
export function useInboxViewValue(key:string|null,fallback:string):[string,(value:string)=>void]{
 const [state,setState]=useState(()=>({key,value:read(key,fallback)}));
 useEffect(()=>{setState({key,value:read(key,fallback)});},[key,fallback]);
 return [state.key===key?state.value:read(key,fallback),(value:string)=>{if(key){views.set(key,value);try{sessionStorage.setItem(key,value);}catch{/* Session memory remains available. */}}setState({key,value});}];
}
