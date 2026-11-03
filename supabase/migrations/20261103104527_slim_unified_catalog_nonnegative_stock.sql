-- Scoped to the operational Saúde Slim workspace; no synthetic stock receipts.
SET LOCAL lock_timeout = '10s';
LOCK TABLE public.products, public.product_catalogs IN SHARE ROW EXCLUSIVE MODE;

CREATE TABLE IF NOT EXISTS private.slim_catalog_organization_audit (
 operation text PRIMARY KEY,
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 snapshot jsonb NOT NULL
);
ALTER TABLE private.slim_catalog_organization_audit ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.slim_catalog_organization_audit FROM PUBLIC, anon, authenticated;

INSERT INTO private.slim_catalog_organization_audit(operation,snapshot)
SELECT 'unified-catalog-20261103',jsonb_build_object(
 'products',(SELECT jsonb_agg(to_jsonb(p)) FROM public.products p WHERE workspace_id='c49945db-1960-461a-9339-a43b8403bdd9'),
 'catalogs',(SELECT jsonb_agg(to_jsonb(c)) FROM public.product_catalogs c WHERE workspace_id='c49945db-1960-461a-9339-a43b8403bdd9'))
ON CONFLICT(operation) DO NOTHING;

CREATE SEQUENCE IF NOT EXISTS private.slim_product_sku_seq;
REVOKE ALL ON SEQUENCE private.slim_product_sku_seq FROM PUBLIC, anon;
GRANT USAGE ON SEQUENCE private.slim_product_sku_seq TO authenticated,service_role;

CREATE OR REPLACE FUNCTION private.slim_product_family(_name text, _catalog text DEFAULT '')
RETURNS text LANGUAGE sql IMMUTABLE SET search_path='' AS $family$
 SELECT CASE
 WHEN lower(_name) ~ '(reta|^r[.]t)' OR lower(_catalog) LIKE '%retatrutida%' THEN 'Retatrutida'
 WHEN lower(_name) ~ '(tirze|mounjaro|gluconex|lipoland|lipoless|^tg( |$))' OR lower(_catalog) IN ('tg','tirzec','lipoless') THEN 'Tirzepatida'
 WHEN lower(_name) ~ '(agua bact|água bact|seringa)' OR lower(_catalog)='insumos' THEN 'Insumos'
 WHEN lower(_name) ~ '(landerlan|cooper pharma|masteron|primobolan|turinabolic)' OR lower(_catalog)='landerlan' THEN 'Hormonais'
 WHEN lower(_name) ~ '(ghk|glow|cjc|ipamorelin|klow|mots|tb.?500|bpc|pt-141|semax|ss-31|tesamorelin|slu-pp)' THEN 'Peptídeos'
 WHEN lower(_name) ~ '(dysport|linederm|cbl.?514)' THEN 'Estética'
 WHEN lower(_name) ~ '(vitamina|pill food)' THEN 'Vitaminas e suplementos'
 WHEN lower(_name) LIKE '%roacutan%' THEN 'Dermatológicos'
 ELSE 'Ampolas a identificar' END;
$family$;
REVOKE ALL ON FUNCTION private.slim_product_family(text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.slim_product_family(text,text) TO authenticated,service_role;

CREATE OR REPLACE FUNCTION private.slim_organize_product()
RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $organize$
DECLARE family text; prefix text; origin text;
BEGIN
 IF NEW.workspace_id <> 'c49945db-1960-461a-9339-a43b8403bdd9'::uuid THEN RETURN NEW; END IF;
 SELECT name INTO origin FROM public.product_catalogs WHERE id=NEW.catalog_id AND workspace_id=NEW.workspace_id;
 family:=private.slim_product_family(NEW.name,coalesce(origin,''));
 IF nullif(btrim(NEW.category),'') IS NULL THEN NEW.category:=family; END IF;
 IF nullif(btrim(NEW.sku),'') IS NULL THEN
  prefix:=CASE family WHEN 'Tirzepatida' THEN 'TIR' WHEN 'Retatrutida' THEN 'RET'
   WHEN 'Insumos' THEN 'INS' WHEN 'Hormonais' THEN 'HOR' WHEN 'Peptídeos' THEN 'PEP'
   WHEN 'Estética' THEN 'EST' WHEN 'Vitaminas e suplementos' THEN 'VIT'
   WHEN 'Dermatológicos' THEN 'DER' ELSE 'AMP' END;
  NEW.sku:='SS-'||prefix||'-'||to_char(nextval('private.slim_product_sku_seq'),'FM000000');
 END IF;
 NEW.catalog_id:='e62a4920-937a-422a-8aa6-5aba1badb539';
 RETURN NEW;
END;
$organize$;
REVOKE ALL ON FUNCTION private.slim_organize_product() FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS slim_organize_product ON public.products;
CREATE TRIGGER slim_organize_product BEFORE INSERT OR UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION private.slim_organize_product();

DO $backfill$
DECLARE p record;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.product_catalogs WHERE id='e62a4920-937a-422a-8aa6-5aba1badb539' AND workspace_id='c49945db-1960-461a-9339-a43b8403bdd9') THEN
  RAISE EXCEPTION 'Catálogo principal operacional não encontrado.';
 END IF;
 FOR p IN SELECT id FROM public.products WHERE workspace_id='c49945db-1960-461a-9339-a43b8403bdd9' ORDER BY lower(name),id LOOP
  UPDATE public.products SET stock=CASE WHEN stock<0 THEN 0 ELSE stock END,
   stock_known=CASE WHEN stock<0 THEN true ELSE stock_known END WHERE id=p.id;
 END LOOP;
 DELETE FROM public.product_catalogs WHERE workspace_id='c49945db-1960-461a-9339-a43b8403bdd9'
  AND id<>'e62a4920-937a-422a-8aa6-5aba1badb539'
  AND NOT EXISTS(SELECT 1 FROM public.products WHERE catalog_id=product_catalogs.id);
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='slim_products_nonnegative_stock' AND conrelid='public.products'::regclass) THEN
  ALTER TABLE public.products ADD CONSTRAINT slim_products_nonnegative_stock CHECK(workspace_id<>'c49945db-1960-461a-9339-a43b8403bdd9'::uuid OR (stock IS NOT NULL AND stock>=0));
 END IF;
END;
$backfill$;

CREATE UNIQUE INDEX IF NOT EXISTS slim_products_unique_sku ON public.products(workspace_id,lower(btrim(sku)))
 WHERE workspace_id='c49945db-1960-461a-9339-a43b8403bdd9' AND nullif(btrim(sku),'') IS NOT NULL;

ALTER TABLE public.slim_stock_movements DROP CONSTRAINT IF EXISTS slim_stock_movements_kind_check;
ALTER TABLE public.slim_stock_movements ADD CONSTRAINT slim_stock_movements_kind_check
 CHECK(kind IN ('sale','reversal','sale_entry'));

-- Internal helper, called only after order validation and within the order transaction.
-- This is a documented stock assumption from a completed sale, not a supplier purchase.
CREATE OR REPLACE FUNCTION private.slim_supply_sale_stock(_workspace uuid,_order uuid,_product uuid,_quantity integer,_actor uuid)
RETURNS void LANGUAGE plpgsql SET search_path='' AS $supply$
DECLARE current_stock integer; missing integer;
BEGIN
 IF _workspace<>'c49945db-1960-461a-9339-a43b8403bdd9'::uuid THEN RETURN; END IF;
 IF _quantity NOT BETWEEN 1 AND 999999 THEN RAISE EXCEPTION 'Quantidade inválida.' USING ERRCODE='22023';END IF;
 SELECT stock INTO STRICT current_stock FROM public.products WHERE id=_product AND workspace_id=_workspace FOR UPDATE;
 missing:=greatest(_quantity-current_stock,0);
 IF missing>0 THEN
  INSERT INTO public.slim_stock_movements(workspace_id,order_id,product_id,kind,quantity,balance_after,actor_id)
   VALUES(_workspace,_order,_product,'sale_entry',missing,current_stock+missing,_actor);
  UPDATE public.products SET stock=current_stock+missing,stock_known=true WHERE id=_product AND workspace_id=_workspace;
 END IF;
END;
$supply$;
REVOKE ALL ON FUNCTION private.slim_supply_sale_stock(uuid,uuid,uuid,integer,uuid) FROM PUBLIC,anon,authenticated;

-- Existing authorization, locks, idempotency and financial validation preserved.
CREATE OR REPLACE FUNCTION private.slim_confirm_order(_workspace_id uuid, _request_id uuid, _quote jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 actor uuid:=auth.uid(); customer_uuid uuid; old public.slim_orders; product public.products;
 customer_row public.leads; issuer public.workspaces; line jsonb; entry record;
 ids uuid[]; products_count integer; qty integer; unit_cents bigint; sub bigint; discount bigint;
 total numeric:=0; remaining bigint; calculated_items jsonb:='[]'; allocated_items jsonb:='[]';
 payment jsonb; note text; new_id uuid:=gen_random_uuid(); num bigint; confirmed timestamptz:=clock_timestamp(); full_snapshot jsonb;
 shipping bigint:=0; final_total numeric; has_delivery boolean; fulfillment jsonb; delivery jsonb; delivery_field record; delivery_text text;
BEGIN
 IF actor IS NULL OR NOT private.slim_workspace_access(_workspace_id,'operator') THEN RAISE EXCEPTION 'Sem permissão para finalizar pedidos nesta empresa.' USING ERRCODE='42501';END IF;
 IF _request_id IS NULL OR jsonb_typeof(_quote) IS DISTINCT FROM 'object' OR (_quote->>'workspaceId')::uuid IS DISTINCT FROM _workspace_id THEN RAISE EXCEPTION 'Pedido ou empresa inválidos.' USING ERRCODE='22023';END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(_workspace_id::text||_request_id::text,0));
 IF EXISTS(SELECT 1 FROM public.slim_checkout_attempt_closures c WHERE c.workspace_id=_workspace_id AND c.request_id=_request_id) THEN
  RAISE EXCEPTION 'Tentativa encerrada sem pedido. Revise os itens e inicie uma nova confirmação.' USING ERRCODE='22023';
 END IF;
 SELECT * INTO old FROM public.slim_orders WHERE workspace_id=_workspace_id AND request_id=_request_id;
 IF FOUND THEN
  IF old.created_by<>actor OR old.request_payload IS DISTINCT FROM _quote THEN RAISE EXCEPTION 'Referência já utilizada por outro conteúdo ou operador.' USING ERRCODE='22023';END IF;
  RETURN jsonb_build_object('requestId',old.request_id,'workspaceId',old.workspace_id,'orderId',old.id,'number','SL-'||lpad(old.order_number::text,8,'0'),'status',old.status,'totalCents',old.total_cents);
 END IF;
 has_delivery:=_quote ? 'fulfillment' OR _quote ? 'shippingCents';
 IF has_delivery THEN
  IF NOT (_quote ? 'fulfillment' AND _quote ? 'shippingCents')
   OR jsonb_typeof(_quote->'fulfillment') IS DISTINCT FROM 'object'
   OR jsonb_typeof(_quote->'shippingCents') IS DISTINCT FROM 'number'
   OR (_quote->>'shippingCents') !~ '^[0-9]+$'
   OR (_quote->>'shippingCents')::numeric>99999999999999 THEN
   RAISE EXCEPTION 'Modalidade de entrega e frete inválidos.' USING ERRCODE='22023';
  END IF;
  shipping:=(_quote->>'shippingCents')::bigint;
  fulfillment:=_quote->'fulfillment';
  IF fulfillment->>'mode'='pickup' THEN
   IF fulfillment IS DISTINCT FROM jsonb_build_object('mode','pickup') OR shipping<>0 THEN
    RAISE EXCEPTION 'Retirada não permite endereço ou cobrança de frete.' USING ERRCODE='22023';
   END IF;
   delivery:=jsonb_build_object('mode','pickup');
  ELSIF fulfillment->>'mode'='delivery' THEN
   IF fulfillment-ARRAY['mode','recipient','phone','postalCode','street','number','complement','neighborhood','city','state','notes']::text[]<>'{}'::jsonb THEN
    RAISE EXCEPTION 'Campo de entrega não reconhecido.' USING ERRCODE='22023';
   END IF;
   delivery:=jsonb_build_object('mode','delivery');
   FOR delivery_field IN SELECT * FROM (VALUES
    ('recipient',160,true),('phone',40,true),('postalCode',9,true),('street',200,true),
    ('number',30,true),('complement',120,false),('neighborhood',100,true),('city',100,true),('state',2,true),('notes',500,false)
   ) AS fields(name,maximum,required) LOOP
    IF jsonb_typeof(fulfillment->delivery_field.name) IS DISTINCT FROM 'string' THEN
     RAISE EXCEPTION 'Campo de entrega inválido: %.',delivery_field.name USING ERRCODE='22023';
    END IF;
    delivery_text:=fulfillment->>delivery_field.name;
    IF delivery_text ~ U&'[\0001-\001F\007F-\009F]' THEN
     RAISE EXCEPTION 'Campo de entrega contém caracteres inválidos: %.',delivery_field.name USING ERRCODE='22023';
    END IF;
    -- Match ECMAScript trim and string.length (UTF-16), including non-BMP text.
    delivery_text:=btrim(delivery_text,U&'\0009\000A\000B\000C\000D\0020\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000\FEFF');
    IF length(delivery_text)+length(regexp_replace(delivery_text,U&'[\0001-\FFFF]','','g'))>delivery_field.maximum
     OR (delivery_field.required AND delivery_text='') THEN
     RAISE EXCEPTION 'Preencha o campo de entrega dentro do limite: %.',delivery_field.name USING ERRCODE='22023';
    END IF;
    delivery:=delivery||jsonb_build_object(delivery_field.name,delivery_text);
   END LOOP;
   IF (delivery->>'phone') !~ '^[+()0-9 .-]+$' THEN
    RAISE EXCEPTION 'Telefone de entrega inválido.' USING ERRCODE='22023';
   END IF;
   delivery_text:=regexp_replace(delivery->>'phone','[^0-9]','','g');
   IF length(delivery_text) NOT BETWEEN 10 AND 15 THEN
    RAISE EXCEPTION 'Telefone de entrega deve conter entre 10 e 15 dígitos.' USING ERRCODE='22023';
   END IF;
   delivery:=jsonb_set(delivery,'{phone}',to_jsonb(delivery_text));
   IF (delivery->>'postalCode') !~ '^[0-9]{5}-?[0-9]{3}$' THEN
    RAISE EXCEPTION 'CEP de entrega inválido.' USING ERRCODE='22023';
   END IF;
   delivery:=jsonb_set(delivery,'{postalCode}',to_jsonb(replace(delivery->>'postalCode','-','')));
   delivery_text:=upper(delivery->>'state');
   IF delivery_text NOT IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO') THEN
    RAISE EXCEPTION 'UF de entrega inválida.' USING ERRCODE='22023';
   END IF;
   delivery:=jsonb_set(delivery,'{state}',to_jsonb(delivery_text));
  ELSE
   RAISE EXCEPTION 'Escolha retirada ou entrega.' USING ERRCODE='22023';
  END IF;
 END IF;
 IF jsonb_typeof(_quote->'items') IS DISTINCT FROM 'array' OR jsonb_array_length(_quote->'items') NOT BETWEEN 1 AND 100 THEN RAISE EXCEPTION 'Inclua entre 1 e 100 produtos.' USING ERRCODE='22023';END IF;
 SELECT array_agg((x->>'productId')::uuid) INTO ids FROM jsonb_array_elements(_quote->'items') x;
 IF cardinality(ids)<>(SELECT count(DISTINCT x) FROM unnest(ids) x) THEN RAISE EXCEPTION 'Produto repetido. Ajuste a quantidade na mesma linha.' USING ERRCODE='22023';END IF;
 PERFORM p.id FROM public.products p WHERE p.workspace_id=_workspace_id AND p.id=ANY(ids) ORDER BY p.id FOR UPDATE;
 GET DIAGNOSTICS products_count=ROW_COUNT;
 IF products_count<>cardinality(ids) THEN RAISE EXCEPTION 'Produto não pertence à empresa.' USING ERRCODE='42501';END IF;
 FOR line IN SELECT * FROM jsonb_array_elements(_quote->'items') LOOP
  SELECT * INTO STRICT product FROM public.products WHERE workspace_id=_workspace_id AND id=(line->>'productId')::uuid;
  IF (line->>'quantity') IS NULL OR (line->>'quantity') !~ '^[0-9]+$' THEN RAISE EXCEPTION 'Quantidade inválida.' USING ERRCODE='22023';END IF;
  qty:=(line->>'quantity')::integer;
  IF qty NOT BETWEEN 1 AND 999999 OR NOT product.active OR (_workspace_id<>'c49945db-1960-461a-9339-a43b8403bdd9'::uuid AND product.stock<qty) THEN RAISE EXCEPTION 'Produto inativo ou estoque insuficiente: %',product.name USING ERRCODE='22023';END IF;
  unit_cents:=(coalesce(product.promo_price,product.price)*100)::bigint;
  IF unit_cents<0 OR unit_cents IS DISTINCT FROM (line->>'unitPriceCents')::bigint THEN RAISE EXCEPTION 'O preço mudou. Revise o pedido antes de confirmar.' USING ERRCODE='22023';END IF;
  IF length(product.name)>500 OR length(product.description)>10000 OR length(product.sku)>200 THEN RAISE EXCEPTION 'Cadastro do produto excede o limite do documento.' USING ERRCODE='22023';END IF;
  IF unit_cents::numeric*qty>99999999999999 THEN RAISE EXCEPTION 'Subtotal acima do limite.' USING ERRCODE='22023';END IF;
  sub:=unit_cents*qty;total:=total+sub;
  calculated_items:=calculated_items||jsonb_build_array(jsonb_build_object('productId',product.id,'name',product.name,'description',product.description,'sku',product.sku,'quantity',qty,'unitPriceCents',unit_cents,'subtotalCents',sub));
 END LOOP;
 IF total>99999999999999 OR (_quote->>'discountCents') IS NULL OR (_quote->>'discountCents') !~ '^[0-9]+$' THEN RAISE EXCEPTION 'Total ou desconto inválido.' USING ERRCODE='22023';END IF;
 discount:=(_quote->>'discountCents')::bigint;
 final_total:=total-discount+shipping;
 IF discount>total OR final_total>99999999999999 OR final_total IS DISTINCT FROM (_quote->>'totalCents')::numeric OR total IS DISTINCT FROM (_quote->>'subtotalCents')::numeric THEN RAISE EXCEPTION 'Totais divergentes. Revise o pedido.' USING ERRCODE='22023';END IF;
 IF total=0 THEN
  SELECT jsonb_agg(x||jsonb_build_object('discountCents',0,'totalCents',0)) INTO allocated_items FROM jsonb_array_elements(calculated_items) x;
 ELSE
  WITH portions AS (SELECT x,ord,floor((x->>'subtotalCents')::numeric*discount/total)::bigint AS base,mod((x->>'subtotalCents')::numeric*discount,total) AS remainder FROM jsonb_array_elements(calculated_items) WITH ORDINALITY t(x,ord)),
  ranked AS (SELECT *,row_number() OVER(ORDER BY remainder DESC,ord) AS rank,discount-sum(base) OVER() AS left_over FROM portions)
  SELECT jsonb_agg(x||jsonb_build_object('discountCents',base+CASE WHEN rank<=left_over THEN 1 ELSE 0 END,'totalCents',(x->>'subtotalCents')::bigint-base-CASE WHEN rank<=left_over THEN 1 ELSE 0 END) ORDER BY ord) INTO allocated_items FROM ranked;
 END IF;
 payment:=_quote->'payment';note:=coalesce(_quote->>'notes','');
 IF jsonb_typeof(payment) IS DISTINCT FROM 'object' OR coalesce(payment->>'method','') NOT IN ('pix','cash','debit_card','credit_card','bank_transfer','boleto','other') OR coalesce(payment->>'status','') NOT IN ('paid','pending') OR coalesce(payment->>'installments','') !~ '^[0-9]+$' THEN RAISE EXCEPTION 'Pagamento inválido.' USING ERRCODE='22023';END IF;
 IF (payment->>'installments')::integer NOT BETWEEN 1 AND 24 OR (payment->>'method'<>'credit_card' AND (payment->>'installments')::integer<>1) OR length(note)>2000 THEN RAISE EXCEPTION 'Parcelamento ou observações inválidos.' USING ERRCODE='22023';END IF;
 IF _quote#>>'{customer,kind}'='existing' THEN
  customer_uuid:=(_quote#>>'{customer,id}')::uuid;
  SELECT * INTO customer_row FROM public.leads WHERE id=customer_uuid AND workspace_id=_workspace_id AND merged_into_id IS NULL AND status NOT IN ('deleted','archived','merged');
  IF NOT FOUND THEN RAISE EXCEPTION 'Cliente não disponível nesta empresa.' USING ERRCODE='42501';END IF;
 ELSIF _quote#>>'{customer,kind}'='new' THEN
  IF length(btrim(coalesce(_quote#>>'{customer,name}',''))) NOT BETWEEN 1 AND 160 OR length(coalesce(_quote#>>'{customer,email}',''))>254 OR length(coalesce(_quote#>>'{customer,phone}',''))>40 THEN RAISE EXCEPTION 'Dados do cliente inválidos.' USING ERRCODE='22023';END IF;
  IF coalesce(_quote#>>'{customer,email}','')<>'' AND (_quote#>>'{customer,email}') !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' THEN RAISE EXCEPTION 'E-mail inválido.' USING ERRCODE='22023';END IF;
  IF length(regexp_replace(coalesce(_quote#>>'{customer,phone}',''),'[^0-9]','','g'))>0 THEN
   PERFORM pg_advisory_xact_lock(hashtextextended(_workspace_id::text||regexp_replace(_quote#>>'{customer,phone}','[^0-9]','','g'),1));
   IF EXISTS(SELECT 1 FROM public.leads l WHERE l.workspace_id=_workspace_id AND l.merged_into_id IS NULL AND regexp_replace(coalesce(l.phone,''),'[^0-9]','','g')=regexp_replace(_quote#>>'{customer,phone}','[^0-9]','','g')) THEN RAISE EXCEPTION 'Telefone já cadastrado. Selecione o cliente existente.' USING ERRCODE='22023';END IF;
  END IF;
  INSERT INTO public.leads(workspace_id,name,email,phone,status,source) VALUES(_workspace_id,btrim(_quote#>>'{customer,name}'),nullif(btrim(_quote#>>'{customer,email}'),''),nullif(btrim(_quote#>>'{customer,phone}'),''),'active','erp_checkout') RETURNING * INTO customer_row;
  customer_uuid:=customer_row.id;
 ELSE RAISE EXCEPTION 'Selecione um cliente ou cadastre um novo.' USING ERRCODE='22023';END IF;
 SELECT * INTO STRICT issuer FROM public.workspaces WHERE id=_workspace_id;
 full_snapshot:=jsonb_build_object('version',1,'workspaceId',_workspace_id,'orderId',new_id,'requestId',_request_id,'status','confirmed','confirmedAt',confirmed,'cancelledAt',NULL,'cancellationReason',NULL,
 'customer',jsonb_build_object('id',customer_uuid,'name',customer_row.name,'email',coalesce(customer_row.email,''),'phone',coalesce(customer_row.phone,'')),
 'issuer',jsonb_build_object('name',issuer.name,'legalName',coalesce(issuer.legal_name,''),'document',coalesce(issuer.cnpj,'')),
 'items',allocated_items,'subtotalCents',total,'discountCents',discount,'totalCents',final_total,
 'payment',jsonb_build_object('method',payment->>'method','status',payment->>'status','installments',(payment->>'installments')::integer),'notes',btrim(note));
 IF has_delivery THEN full_snapshot:=full_snapshot||jsonb_build_object('fulfillment',delivery,'shippingCents',shipping);END IF;
 INSERT INTO public.slim_orders(id,workspace_id,request_id,request_payload,created_by,customer_id,subtotal_cents,discount_cents,shipping_cents,total_cents,snapshot,confirmed_at)
 VALUES(new_id,_workspace_id,_request_id,_quote,actor,customer_uuid,total,discount,shipping,final_total,full_snapshot,confirmed) RETURNING order_number INTO num;
 UPDATE public.slim_orders SET snapshot=snapshot||jsonb_build_object('number','SL-'||lpad(num::text,8,'0')) WHERE id=new_id;
 FOR line IN SELECT * FROM jsonb_array_elements(allocated_items) LOOP
  PERFORM private.slim_supply_sale_stock(_workspace_id,new_id,(line->>'productId')::uuid,(line->>'quantity')::integer,actor);
  UPDATE public.products SET stock=stock-(line->>'quantity')::integer WHERE workspace_id=_workspace_id AND id=(line->>'productId')::uuid RETURNING stock INTO remaining;
  INSERT INTO public.slim_stock_movements(workspace_id,order_id,product_id,kind,quantity,balance_after,actor_id) VALUES(_workspace_id,new_id,(line->>'productId')::uuid,'sale',(line->>'quantity')::integer,remaining,actor);
 END LOOP;
 RETURN jsonb_build_object('requestId',_request_id,'workspaceId',_workspace_id,'orderId',new_id,'number','SL-'||lpad(num::text,8,'0'),'status','confirmed','totalCents',final_total);
END;$function$
;
CREATE OR REPLACE FUNCTION private.slim_reconcile_legacy_sale(_workspace_id uuid, _lead_id uuid, _fingerprint text, _stock_mode text, _payment jsonb, _approved boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE l public.leads;o public.slim_orders;w public.workspaces;p public.products;s jsonb;i jsonb;items jsonb:='[]';total numeric:=0;unit bigint;qty integer;at_time timestamptz;ids uuid[];order_id uuid:=gen_random_uuid();num bigint;snapshot jsonb;balance integer;note text;
BEGIN
 IF _approved IS DISTINCT FROM true OR NOT private.slim_workspace_access(_workspace_id,'operator') THEN RAISE EXCEPTION 'A regularização exige aprovação do operador.' USING ERRCODE='42501';END IF;
 IF _stock_mode IS NULL OR _stock_mode NOT IN ('apply_missing','already_accounted') THEN RAISE EXCEPTION 'Informe se a baixa de estoque ainda falta ou já foi realizada.' USING ERRCODE='22023';END IF;
 IF jsonb_typeof(_payment) IS DISTINCT FROM 'object' OR coalesce(_payment->>'method','') NOT IN ('pix','cash','debit_card','credit_card','bank_transfer','boleto','other') OR coalesce(_payment->>'status','') NOT IN ('paid','pending') OR coalesce(_payment->>'installments','') !~ '^[0-9]+$' THEN RAISE EXCEPTION 'Informe os dados de pagamento revisados.' USING ERRCODE='22023';END IF;
 IF (_payment->>'installments')::integer NOT BETWEEN 1 AND 24 OR (_payment->>'method'<>'credit_card' AND (_payment->>'installments')::integer<>1) THEN RAISE EXCEPTION 'Parcelamento inválido.' USING ERRCODE='22023';END IF;
 SELECT * INTO l FROM public.leads WHERE id=_lead_id AND workspace_id=_workspace_id AND source='pedido_saude_slim' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Registro anterior não pertence à empresa.' USING ERRCODE='42501';END IF;
 SELECT * INTO o FROM public.slim_orders WHERE workspace_id=_workspace_id AND legacy_lead_id=_lead_id;
 IF FOUND THEN RETURN jsonb_build_object('orderId',o.id,'number',o.snapshot->>'number','status',o.status,'reused',true);END IF;
 IF l.merged_into_id IS NOT NULL OR l.status IN ('archived','deleted','merged','lost') THEN RAISE EXCEPTION 'Registro arquivado, mesclado ou perdido exige revisão individual.' USING ERRCODE='22023';END IF;
 PERFORM x.id FROM public.lead_products x WHERE x.workspace_id=_workspace_id AND x.lead_id=_lead_id FOR UPDATE;
 SELECT array_agg(x.product_id ORDER BY x.product_id) INTO ids FROM public.lead_products x WHERE x.workspace_id=_workspace_id AND x.lead_id=_lead_id AND x.kind='comprou';
 IF ids IS NULL OR cardinality(ids) NOT BETWEEN 1 AND 100 OR cardinality(ids)<>(SELECT count(DISTINCT id) FROM unnest(ids) id) THEN RAISE EXCEPTION 'Faltam itens válidos ou há produtos repetidos. Nada foi regularizado.' USING ERRCODE='22023';END IF;
 PERFORM p1.id FROM public.products p1 WHERE p1.workspace_id=_workspace_id AND p1.id=ANY(ids) ORDER BY p1.id FOR UPDATE;
 s:=private.slim_legacy_sale_source(_workspace_id,_lead_id);
 IF _fingerprint IS DISTINCT FROM encode(extensions.digest(s::text,'sha256'),'hex') THEN RAISE EXCEPTION 'Os dados ou o estoque mudaram. Atualize a conferência antes de aprovar.' USING ERRCODE='22023';END IF;
 at_time:=l.created_at;
 FOR i IN SELECT * FROM jsonb_array_elements(s->'items') LOOP
  IF coalesce(i->>'quantity','') !~ '^[0-9]+([.]0+)?$' OR i->>'unitPrice' IS NULL THEN RAISE EXCEPTION 'Quantidade ou preço original não registrados.' USING ERRCODE='22023';END IF;
  qty:=(i->>'quantity')::numeric::integer;
  IF qty NOT BETWEEN 1 AND 999999 OR (i->>'unitPrice')::numeric<0 OR (i->>'unitPrice')::numeric*100<>trunc((i->>'unitPrice')::numeric*100) THEN RAISE EXCEPTION 'Preço ou quantidade original inválidos.' USING ERRCODE='22023';END IF;
  unit:=((i->>'unitPrice')::numeric*100)::bigint;
  IF unit::numeric*qty>99999999999999 THEN RAISE EXCEPTION 'Valor acima do limite.' USING ERRCODE='22023';END IF;
  SELECT * INTO p FROM public.products WHERE id=(i->>'productId')::uuid AND workspace_id=_workspace_id;
  IF NOT FOUND OR p.stock IS NULL OR p.stock<0 THEN RAISE EXCEPTION 'Produto ou saldo não disponível.' USING ERRCODE='22023';END IF;
  IF _stock_mode='apply_missing' AND _workspace_id<>'c49945db-1960-461a-9339-a43b8403bdd9'::uuid AND p.stock<qty THEN RAISE EXCEPTION 'Saldo insuficiente para registrar a baixa pendente.' USING ERRCODE='22023';END IF;
  IF i->>'soldAt' IS NULL OR (i->>'soldAt')::timestamptz>clock_timestamp() THEN RAISE EXCEPTION 'Data da compra não registrada ou inválida.' USING ERRCODE='22023';END IF;
  at_time:=greatest(at_time,(i->>'soldAt')::timestamptz);
  items:=items||jsonb_build_array(jsonb_build_object('productId',p.id,'name',p.name,'description','Descrição histórica não registrada; produto identificado pelo cadastro atual.','sku',coalesce(p.sku,''),'quantity',qty,'unitPriceCents',unit,'subtotalCents',unit*qty,'discountCents',0,'totalCents',unit*qty));
  total:=total+unit::numeric*qty;
 END LOOP;
 IF l.value IS NULL OR total>99999999999999 OR total IS DISTINCT FROM l.value::numeric*100 THEN RAISE EXCEPTION 'Total do registro diverge dos itens. É necessária conferência individual.' USING ERRCODE='22023';END IF;
 SELECT * INTO STRICT w FROM public.workspaces WHERE id=_workspace_id;
 note:='Regularização do registro anterior '||_lead_id::text||'. Valores líquidos dos vínculos originais; desconto original não discriminado. Pagamento informado pelo operador na regularização. '||CASE WHEN _stock_mode='apply_missing' THEN 'Operador confirmou que a baixa ainda faltava; saldo reduzido agora.' ELSE 'Operador declarou que o saldo atual já incluía esta venda; nenhuma nova baixa aplicada.' END;
 snapshot:=jsonb_build_object('version',1,'workspaceId',_workspace_id,'orderId',order_id,'requestId',order_id,'status','confirmed','confirmedAt',at_time,'cancelledAt',NULL,'cancellationReason',NULL,'customer',jsonb_build_object('id',l.id,'name',l.name,'email',coalesce(l.email,''),'phone',coalesce(l.phone,'')),'issuer',jsonb_build_object('name',w.name,'legalName',coalesce(w.legal_name,''),'document',coalesce(w.cnpj,'')),'items',items,'subtotalCents',total,'discountCents',0,'totalCents',total,'payment',_payment,'notes',note,'legacy',jsonb_build_object('leadId',_lead_id,'sourceFingerprint',_fingerprint,'stockMode',_stock_mode,'reviewedAt',clock_timestamp(),'reviewedBy',auth.uid()));
 INSERT INTO public.slim_orders(id,workspace_id,request_id,request_payload,created_by,customer_id,subtotal_cents,discount_cents,total_cents,snapshot,confirmed_at,legacy_lead_id) VALUES(order_id,_workspace_id,order_id,jsonb_build_object('source',s,'payment',_payment,'stockMode',_stock_mode),auth.uid(),l.id,total,0,total,snapshot,at_time,_lead_id) RETURNING order_number INTO num;
 UPDATE public.slim_orders AS saved SET snapshot=saved.snapshot||jsonb_build_object('number','SL-'||lpad(num::text,8,'0')) WHERE saved.id=order_id;
 FOR i IN SELECT * FROM jsonb_array_elements(items) LOOP
  IF _stock_mode='apply_missing' THEN
   PERFORM private.slim_supply_sale_stock(_workspace_id,order_id,(i->>'productId')::uuid,(i->>'quantity')::integer,auth.uid());
   UPDATE public.products SET stock=stock-(i->>'quantity')::integer WHERE id=(i->>'productId')::uuid AND workspace_id=_workspace_id RETURNING stock INTO balance;
  ELSE SELECT stock INTO balance FROM public.products WHERE id=(i->>'productId')::uuid AND workspace_id=_workspace_id;END IF;
  INSERT INTO public.slim_stock_movements(workspace_id,order_id,product_id,kind,quantity,balance_after,actor_id) VALUES(_workspace_id,order_id,(i->>'productId')::uuid,'sale',(i->>'quantity')::integer,balance,auth.uid());
 END LOOP;
 RETURN jsonb_build_object('orderId',order_id,'number','SL-'||lpad(num::text,8,'0'),'status','confirmed','reused',false);
END;$function$
;
