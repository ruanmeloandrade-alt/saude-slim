import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { PGlite } from "@electric-sql/pglite";
const db = new PGlite();
await db.exec(`
create role anon; create role authenticated; create role service_role bypassrls;
create table workspaces(id uuid primary key, owner_id uuid);
create table workspace_members(workspace_id uuid,user_id uuid,role_type text,access_expires_at timestamptz);
create table pipelines(id uuid primary key,workspace_id uuid);
create table pipeline_stages(id uuid primary key,workspace_id uuid,pipeline_id uuid);
create table leads(id uuid primary key,workspace_id uuid,pipeline_id uuid,stage_id uuid,updated_at timestamptz,status text,merged_into_id uuid,active_conversation_agent_id uuid);
create table lead_activities(workspace_id uuid,lead_id uuid,type text,payload jsonb,occurred_at timestamptz default now());
create table salesbot_runs(workspace_id uuid,lead_id uuid,status text);
grant all on all tables in schema public to service_role;
`);
for (const file of ["20261104143823_slim_crm_manager_settings.sql", "20261104160000_crm_manager_scans.sql"]) {
 await db.exec(readFileSync("supabase/migrations/" + file, "utf8"));
}
const id = (n) => "00000000-0000-4000-8000-" + String(n).padStart(12, "0");
const [ws, p, a, b, lead, actor, rev] = [1,2,3,4,5,6,7].map(id);
await db.exec(`
insert into workspaces values ('${ws}','${actor}');
insert into pipelines values ('${p}','${ws}');
insert into pipeline_stages values ('${a}','${ws}','${p}'),('${b}','${ws}','${p}');
insert into leads values ('${lead}','${ws}','${p}','${a}','2026-11-04','active',null,null);
insert into crm_manager_scans(pipeline_id,workspace_id,revision,job,lease_until) values ('${p}','${ws}','${rev}','{}',now()+interval '1 minute');
`);
const move = async (revision) => (await db.query("select apply_crm_manager_scan_move($1,$2,$3,$4,$5,'2026-11-04',$6,'test','{}',$7,'2026-11-04') as moved", [revision,ws,p,lead,a,b,actor])).rows[0].moved;
await db.exec("set role authenticated");
await assert.rejects(db.query("select * from crm_manager_scans"), /permission denied/);
await assert.rejects(move(rev), /permission denied/);
await db.exec("set role service_role");
assert.equal(await move(id(8)), false);
await db.query("insert into salesbot_runs values ($1,$2,'running')",[ws,lead]);
assert.equal(await move(rev), false);
await db.exec("delete from salesbot_runs");
await db.query("update leads set active_conversation_agent_id=$1",[id(9)]);
assert.equal(await move(rev), false);
await db.exec("update leads set active_conversation_agent_id=null");
await db.query("update crm_manager_scans set revision=$1,lease_until=null,job=job||'{\"done\":true,\"cancelled\":true}'::jsonb",[id(10)]);
assert.equal(await move(rev), false);
assert.equal(await move(id(10)), false);
await db.query("update crm_manager_scans set revision=$1,lease_until=now()+interval '1 minute',job='{}'",[rev]);
assert.equal(await move(rev), true);
assert.equal(await move(rev), false);
assert.equal((await db.query("select count(*)::int n from lead_activities")).rows[0].n, 1);
console.log("PostgreSQL: permissões, lease, bot e agente ativos, movimentação única e auditoria passaram.");
await db.close();
