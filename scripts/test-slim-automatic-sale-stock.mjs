import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {randomUUID} from 'node:crypto';
import {PGlite} from '@electric-sql/pglite';
import {pgcrypto} from '@electric-sql/pglite/contrib/pgcrypto';
import {calculateCheckout} from '../src/lib/slim-checkout.core.ts';
import {buildStockMovements} from '../src/lib/slim-stock-view.core.ts';
const db=new PGlite({extensions:{pgcrypto}}),root=new URL('../',import.meta.url),read=p=>readFileSync(new URL(p,root),'utf8');
const W='c49945db-1960-461a-9339-a43b8403bdd9',C='e62a4920-937a-422a-8aa6-5aba1badb539',actor=randomUUID(),viewer=randomUUID(),lead=randomUUID();
const scalar=async(sql,args=[])=>Object.values((await db.query(sql,args)).rows[0])[0];
await db.exec(read('scripts/fixtures/slim-legacy-isolated-schema.sql'));
await db.exec('ALTER TABLE products ADD COLUMN promo_price numeric; CREATE TABLE slim_checkout_attempt_closures(workspace_id uuid,request_id uuid);');
await db.exec(read('supabase/migrations/20261015115919_slim_restore_audiences_fields_stage_automations.sql').split('CREATE TABLE public.crm_lead_audiences')[0]);
await db.exec(read('scripts/fixtures/slim-confirm-order-live-contract.sql'));
await db.exec(read('scripts/fixtures/slim-legacy-cancel-contract.sql'));
await db.exec(read('supabase/migrations/20261018001819_slim_checkout_delivery_freight.sql'));
await db.exec(`ALTER TABLE products ADD COLUMN stock_known boolean NOT NULL DEFAULT true,ADD COLUMN category text DEFAULT '',ADD COLUMN catalog_id uuid;
 CREATE TABLE product_catalogs(id uuid primary key,workspace_id uuid,name text);
 GRANT SELECT ON products,product_catalogs TO authenticated;`);
await db.query('INSERT INTO auth.users(id) VALUES($1),($2)',[actor,viewer]);
await db.query("INSERT INTO workspaces(id,owner_id,name) VALUES($1,$2,'Synthetic')",[W,actor]);
await db.query("INSERT INTO workspace_members(workspace_id,user_id,role_type) VALUES($1,$2,'visualizador')",[W,viewer]);
await db.query("INSERT INTO leads(id,workspace_id,name) VALUES($1,$2,'Synthetic customer')",[lead,W]);
await db.query("INSERT INTO product_catalogs VALUES($1,$2,'Principal')",[C,W]);
await db.exec('BEGIN');await db.exec(read('supabase/migrations/20261103104527_slim_unified_catalog_nonnegative_stock.sql'));await db.exec('COMMIT');
let passed=0;
async function test(name,fn){await db.exec('BEGIN');try{await fn();passed++;console.log('PASS '+name);}finally{await db.exec('ROLLBACK');}}
async function identity(id=actor){await db.query("SELECT set_config('request.jwt.claim.sub',$1,true)",[id]);}
async function seed(stock=0,quantity=1,known=true){
 const id=randomUUID();await db.query("INSERT INTO products(id,workspace_id,name,price,stock,active,stock_known) VALUES($1,$2,'TG synthetic',10,$3,true,$4)",[id,W,stock,known]);
 const quote={workspaceId:W,customer:{kind:'existing',id:lead},items:[{productId:id,quantity,unitPriceCents:1000}],subtotalCents:quantity*1000,discountCents:0,totalCents:quantity*1000,payment:{method:'pix',status:'pending',installments:1},notes:'',shippingCents:0,fulfillment:{mode:'pickup'}};
 await identity();return {id,quote};
}
const confirm=(q,req=randomUUID())=>scalar('SELECT private.slim_confirm_order($1,$2,$3)',[W,req,q]);
const balance=id=>scalar('SELECT stock FROM products WHERE id=$1',[id]);
const entries=id=>scalar("SELECT coalesce(sum(quantity),0)::int FROM slim_stock_movements WHERE product_id=$1 AND kind='sale_entry'",[id]);
await test('zero stock: automatic entry and sale leave zero',async()=>{const s=await seed(0,2);const r=await confirm(s.quote);assert.equal(await balance(s.id),0);assert.equal(await entries(s.id),2);const movements=(await db.query('SELECT * FROM slim_stock_movements WHERE order_id=$1',[r.orderId])).rows;const snapshot=await scalar('SELECT snapshot FROM slim_orders WHERE id=$1',[r.orderId]);const rows=buildStockMovements(W,movements.map(m=>({...m,created_at:new Date(m.created_at).toISOString()})),[{id:r.orderId,workspace_id:W,snapshot}]).movements;assert.deepEqual(rows.map(r=>[r.kind,r.quantity,r.balanceBefore,r.balanceAfter]).sort(),[['sale',2,2,0],['sale_entry',2,0,2]].sort());});
await test('repeated sales at zero each record entry and exit',async()=>{const s=await seed();await confirm(s.quote);await confirm(s.quote);assert.equal(await balance(s.id),0);assert.equal(await entries(s.id),2);assert.equal(await scalar('SELECT count(*)::int FROM slim_stock_movements WHERE product_id=$1',[s.id]),4);});
await test('partial stock receives only missing quantity',async()=>{const s=await seed(2,5);await confirm(s.quote);assert.equal(await entries(s.id),3);assert.equal(await balance(s.id),0);});
await test('sufficient stock has no automatic entry',async()=>{const s=await seed(5,2);await confirm(s.quote);assert.equal(await entries(s.id),0);assert.equal(await balance(s.id),3);});
await test('same request twice does not duplicate either movement',async()=>{const s=await seed(),req=randomUUID();const a=await confirm(s.quote,req),b=await confirm(s.quote,req);assert.deepEqual(a,b);assert.equal(await entries(s.id),1);assert.equal(await scalar('SELECT count(*)::int FROM slim_stock_movements WHERE product_id=$1',[s.id]),2);});
await test('unknown zero stock is supported by a sale entry',async()=>{const s=await seed(0,1,false);await confirm(s.quote);assert.equal(await balance(s.id),0);assert.equal(await entries(s.id),1);});
await test('cancel twice returns sold stock once',async()=>{const s=await seed();const r=await confirm(s.quote);await scalar("SELECT private.slim_cancel_order($1,$2,'Cancelled')",[W,r.orderId]);await scalar("SELECT private.slim_cancel_order($1,$2,'Cancelled')",[W,r.orderId]);assert.equal(await balance(s.id),1);assert.equal(await entries(s.id),1);assert.equal(await scalar("SELECT count(*)::int FROM slim_stock_movements WHERE order_id=$1 AND kind='reversal'",[r.orderId]),1);});
await test('invalid price rolls back entry, sale and order',async()=>{const s=await seed();s.quote.items[0].unitPriceCents=1;await db.exec('SAVEPOINT bad');await assert.rejects(()=>confirm(s.quote));await db.exec('ROLLBACK TO SAVEPOINT bad');assert.equal(await entries(s.id),0);assert.equal(await balance(s.id),0);});
await test('viewer cannot invoke sale entry helper or sell',async()=>{const s=await seed();await identity(viewer);await db.exec('SET LOCAL ROLE authenticated;SAVEPOINT denied');await assert.rejects(()=>scalar('SELECT private.slim_supply_sale_stock($1,$2,$3,1,$4)',[W,randomUUID(),s.id,viewer]));await db.exec('ROLLBACK TO SAVEPOINT denied');await assert.rejects(()=>confirm(s.quote));});
await test('domain permits sale above current stock for operational workspace',async()=>{const s=await seed();const q=calculateCheckout(W,{customer:{kind:'existing',id:lead},items:[{productId:s.id,quantity:2}],discount:{kind:'amount',cents:0},payment:s.quote.payment,notes:'',fulfillment:{mode:'pickup'},shippingCents:0},[{id:s.id,workspaceId:W,name:'TG',description:'',sku:'',priceCents:1000,stock:0,active:true}]);assert.equal(q.totalCents,2000);});
console.log(`${passed}/${passed} automatic sale stock scenarios passed. All business writes rolled back.`);await db.close();
