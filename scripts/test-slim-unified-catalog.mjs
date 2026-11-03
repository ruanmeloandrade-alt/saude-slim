import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
const db=new PGlite();
const W='c49945db-1960-461a-9339-a43b8403bdd9',C='e62a4920-937a-422a-8aa6-5aba1badb539';
const O='00000000-0000-4000-8000-000000000001',OC='00000000-0000-4000-8000-000000000002';
const migration=readFileSync(new URL('../supabase/migrations/20261103104527_slim_unified_catalog_nonnegative_stock.sql',import.meta.url),'utf8').split('-- Existing authorization')[0];
const scalar=async(q,args=[])=>Object.values((await db.query(q,args)).rows[0])[0];
await db.exec(`CREATE ROLE authenticated;CREATE ROLE anon;CREATE ROLE service_role;CREATE SCHEMA private;
CREATE TABLE product_catalogs(id uuid primary key,workspace_id uuid,name text,description text,cover text,created_at timestamptz,updated_at timestamptz);
CREATE TABLE products(id uuid primary key,workspace_id uuid,catalog_id uuid references product_catalogs(id) on delete cascade,
 name text,sku text,category text,stock integer,stock_known boolean default true,image text,price numeric,promo_price numeric,description text,active boolean,
 cost_price numeric,minimum_stock integer,unit text,import_snapshot jsonb,created_at timestamptz,updated_at timestamptz);
CREATE TABLE slim_stock_movements(id uuid primary key default gen_random_uuid(),workspace_id uuid,order_id uuid,product_id uuid,kind text,quantity integer,balance_after integer,actor_id uuid,unique(order_id,product_id,kind));
GRANT USAGE ON SCHEMA public,private TO authenticated,service_role;
GRANT SELECT,INSERT,UPDATE ON products,product_catalogs TO authenticated;
INSERT INTO product_catalogs(id,workspace_id,name) VALUES('${C}','${W}','Catalogo principal'),('${OC}','${O}','Other');`);
const names=['TG 05MG','Reta Gen Health 120mg','AGUA BACT. 10ML','OXANDROLONA LANDERLAN 5MG','GHK CU 100MG','DYSPORT 500 U','VITAMINA B12','ROACUTAN 20MG','AMPOLAS UNITARIAS'];
for(const [i,name] of names.entries()) await db.query(`INSERT INTO products(id,workspace_id,catalog_id,name,sku,category,stock,stock_known,image,price)
 VALUES(gen_random_uuid(),$1,$2,$3,'','',$4,true,'unchanged.jpg',299.99)`,[W,C,name,i===0?-10:10]);
await db.query(`INSERT INTO products(id,workspace_id,catalog_id,name,sku,category,stock) VALUES(gen_random_uuid(),$1,$2,'Other','','',-2)`,[O,OC]);
// Optionally verify all current real products without committing client data.
if(process.argv[2]){
 const s=readFileSync(process.argv[2],'utf8'),d=JSON.parse(s.slice(0,s.lastIndexOf('}')+1)).rows[0].inspection;
 await db.exec(`DELETE FROM products WHERE workspace_id='${W}';DELETE FROM product_catalogs WHERE workspace_id='${W}';`);
 await db.query('INSERT INTO product_catalogs SELECT * FROM jsonb_populate_recordset(null::product_catalogs,$1)',[JSON.stringify(d.catalogs.filter(c=>c.workspace_id===W))]);
 await db.query('INSERT INTO products SELECT * FROM jsonb_populate_recordset(null::products,$1)',[JSON.stringify(d.products)]);
}
const before=(await db.query('SELECT to_jsonb(p) data FROM products p WHERE workspace_id=$1 ORDER BY id',[W])).rows.map(r=>r.data);
await db.exec('BEGIN');await db.exec(migration);await db.exec('COMMIT');
const after=(await db.query('SELECT to_jsonb(p) data FROM products p WHERE workspace_id=$1 ORDER BY id',[W])).rows.map(r=>r.data);
assert.equal(after.length,before.length);
for(let i=0;i<before.length;i++){
 const b=before[i],a=after[i];assert.equal(a.catalog_id,C);assert(a.category);assert.match(a.sku,/^SS-[A-Z]{3}-\d{6}$/);
 assert.equal(a.stock,Math.max(0,b.stock));assert.equal(a.stock_known,b.stock<0?true:b.stock_known);
 for(const key of Object.keys(b).filter(k=>!['catalog_id','category','sku','stock','stock_known','updated_at'].includes(k))) assert.deepEqual(a[key],b[key],key);
}
assert.equal(new Set(after.map(p=>p.sku)).size,after.length);
assert.equal(await scalar('SELECT count(*)::int FROM product_catalogs WHERE workspace_id=$1',[W]),1);
assert.equal(await scalar('SELECT stock FROM products WHERE workspace_id=$1',[O]),-2);
assert.equal(await scalar('SELECT jsonb_array_length(snapshot->\'products\') FROM private.slim_catalog_organization_audit'),before.length);
const negative=after.find(p=>!p.stock_known);
await assert.rejects(()=>db.query('UPDATE products SET stock=-1 WHERE id=$1',[after[0].id]));
const positive=after.find(p=>p.stock>0&&p.stock_known);
await db.query('UPDATE products SET stock=stock-1 WHERE id=$1',[positive.id]);
assert.equal(await scalar('SELECT stock FROM products WHERE id=$1',[positive.id]),positive.stock-1);
await assert.rejects(()=>db.query('UPDATE products SET sku=$1 WHERE id=$2',[after[0].sku,after[1].id]),/duplicate/);
const saleProduct=after.find(p=>p.stock===0);
if(saleProduct){
 const order='00000000-0000-4000-8000-000000000003';
 await db.query('SELECT private.slim_supply_sale_stock($1,$2,$3,2,$4)',[W,order,saleProduct.id,O]);
 assert.equal(await scalar('SELECT stock FROM products WHERE id=$1',[saleProduct.id]),2);
 assert.equal(await scalar("SELECT quantity FROM slim_stock_movements WHERE order_id=$1 AND kind='sale_entry'",[order]),2);
 await db.query('UPDATE products SET stock=stock-2 WHERE id=$1',[saleProduct.id]);
 assert.equal(await scalar('SELECT stock FROM products WHERE id=$1',[saleProduct.id]),0);
}
await db.exec('SET ROLE authenticated');
const added=(await db.query(`INSERT INTO products(id,workspace_id,catalog_id,name,sku,category,stock) VALUES(gen_random_uuid(),$1,$2,'Tirzec novo','','',5) RETURNING *`,[W,C])).rows[0];
assert.equal(added.category,'Tirzepatida');assert.match(added.sku,/^SS-TIR-/);assert.equal(added.catalog_id,C);
await assert.rejects(()=>db.query('SELECT * FROM private.slim_catalog_organization_audit'),/permission/);
await db.exec('RESET ROLE');
const skus=await scalar('SELECT jsonb_object_agg(id,sku) FROM products');
await db.exec('BEGIN');await db.exec(migration);await db.exec('COMMIT');
assert.deepEqual(await scalar('SELECT jsonb_object_agg(id,sku) FROM products'),skus);
console.log(`PASS: ${before.length} products preserved; one catalog, complete categories, unique/stable SKUs, negatives audited, workspace isolation, automatic sale entry, stock guard, authenticated insert, audit privacy, repeat migration.`);
console.log((await db.query('SELECT category,count(*)::int n FROM products WHERE workspace_id=$1 GROUP BY category ORDER BY category',[W])).rows);
await db.close();
