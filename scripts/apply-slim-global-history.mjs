import fs from 'node:fs';
const root=new URL('../',import.meta.url),mark='// SLIM_GLOBAL_HISTORY_V1',plans=[];
function edit(path,run){let code=fs.readFileSync(new URL(path,root),'utf8');if(code.includes(mark))return;function once(from,to){if(code.split(from).length!==2)throw new Error(`[Global/history] ${path}: missing exact anchor ${from.slice(0,100)}`);code=code.replace(from,()=>to);}run(once);plans.push([path,code+'\n'+mark+'\n']);}
edit('src/routes/__root.tsx',once=>{
 once('        {!migratedRoute && <ConditionalSupportRobot />}\n','');
 once('<CheckoutCompatibilityGuard><AuthGate><Outlet />','<CheckoutCompatibilityGuard><AuthGate><ConditionalSupportRobot /><Outlet />');
});
edit('src/components/SupportRobot.tsx',once=>{
 once('import { AiAgentChat } from "./ai-agent/AiAgentChat";','import { AiAgentChat } from "./ai-agent/AiAgentChat";\nimport {getSlimErpIdentity} from "@/lib/slim-erp-release.functions";');
 once('export function SupportRobot() {',`export function SupportRobot() {
  const identify=useServerFn(getSlimErpIdentity);
  const location=useLocation();
  const identity=useQuery({queryKey:['slim-erp-identity'],queryFn:()=>identify(),staleTime:0,retry:1,refetchInterval:5000,refetchOnWindowFocus:true});
  useEffect(()=>{void identity.refetch();},[location.pathname]);
  if(identity.error||!identity.data)return null;
  return <ScopedSupportRobot key={identity.data.workspaceId+':'+identity.data.actorId} workspaceId={identity.data.workspaceId} actorId={identity.data.actorId}/>;
}
function ScopedSupportRobot({workspaceId,actorId}:{workspaceId:string;actorId:string}) {`);
 once('queryKey: ["support-robot-context", location.href]','queryKey: ["support-robot-context", workspaceId, actorId]');
 once('  const ctx = contextQuery.data;', '  const ctx = !contextQuery.error && contextQuery.data?.active && contextQuery.data.workspaceId===workspaceId && contextQuery.data.actorId===actorId ? contextQuery.data : null;');
 once('  useEffect(() => {\n    setIsOpen(false);\n    setChatWorkspaceId(null);\n    setShowGreeting(false);\n  }, [location.href]);','  // Internal navigation preserves the mounted chat; identity changes remount the scoped instance.');
 once('<AiAgentChat workspaceId={chatWorkspaceId} module="support_robot" fullscreen hideActions />','<AiAgentChat workspaceId={chatWorkspaceId} module="support_robot" fullscreen hideActions contextPayload={{page:location.pathname,approvalRequired:true}} />');
});
edit('src/lib/support-robot.functions.ts',once=>{once('active: true as const,','active: true as const,\n      actorId: userId,');});
edit('src/components/erp/SlimErpWorkspace.tsx',once=>{
 once("import {SlimLegacyOrdersReview} from './SlimLegacyOrdersReview';",'// Historical source data retained; no reconciliation block in the sales list.');
 once("{mode==='history'&&<SlimLegacyOrdersReview workspaceId={workspaceId} actorId={actorId}/>",'{/* One sales list. Historical source data is not deleted. */}');
});
edit('scripts/test-slim-legacy-contract.mjs',once=>{
 once("test('history route exposes legacy review',()=>assert(before[0].includes(\"mode==='history'&&<SlimLegacyOrdersReview\")));","test('history has one sales list without the removed reconciliation panel',()=>{assert(!before[0].includes('<SlimLegacyOrdersReview'));assert(before[0].includes('<SlimOrderHistory'));});");
});
for(const[path,code]of plans)fs.writeFileSync(new URL(path,root),code);
console.log(`[Global/history] ${plans.length} sources updated. No business data was changed.`);
