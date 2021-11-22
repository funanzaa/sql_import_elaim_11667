--CHT 11/11/64 v.1.3
-- มาตรฐานแฟ้มข้อมูลการเงิน (แบบสรุป) (CHT)
--v.1.1 => changed codeing
--v.1.2 => ไม่ดึงราคาที่ตีดลบ , ค้างชำระ
--v.1.3 => item ไม่มีใน opbkk chad
with cte2 as (
	select v.hn as hn
	,v.an as AN
	,v.financial_discharge_date as "DATE"
	,unit_price_sale::decimal * quantity::decimal as total
	,quantity
	,p.pid as PERSON_ID
	,v.vn  as SEQ
	from (
			with cte1 as 
				(
					select q.*
					,case when q.base_plan_group_code in ('CHECKUP') and q.plan_code in ('PCP006') then 'UC'  -- check CHECKUP => PCP006 
						  when q.base_plan_group_code in ('Model5','UC') then 'UC' end as chk_plan -- check 'Model5','UC' => UC
					from (
						select v.*,base_plan_group.base_plan_group_code,plan.plan_code 
						from visit v 
						left join visit_payment on v.visit_id = visit_payment.visit_id and visit_payment.priority = '1'
						left join base_plan_group on visit_payment.base_plan_group_id = base_plan_group.base_plan_group_id and base_plan_group.base_plan_group_code in ('Model5','UC','CHECKUP') -- สิทธิ์ UC
						left join plan on visit_payment.plan_id = plan.plan_id 
					) q
					where q.base_plan_group_code is not null 
				)
				select * from cte1 where cte1.chk_plan is not null -- visit ที่เป็นสิทธิ์ UC ตาม Excel
	) v --เฉพาะ visit ที่เป็นสิทธิ์ UC ตาม Excel
	left join (
		select order_item_id,visit_id,base_billing_group_id,unit_price_sale,quantity 
		from order_item 
		where quantity not like '-%' and unit_price_sale <> '0'-- GET table order ที่ไม่ติดลบ, unit_price_sale <> '0'
		and item_id not in (select item_code from export_opbkk_chatail) -- ไม่มีใน opbkk chad
		) order_item on v.visit_id = order_item.visit_id 
	left join patient p on v.patient_id = p.patient_id 
	where v.visit_date::date >= '2021-09-01' 
	and v.visit_date::date <= '2021-09-02'
	and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
	and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
	and v.financial_discharge <> '0' --ค้างชำระ
	--and v.fix_visit_type_id = '1' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
	order by v.vn
)
select q.hn,q.an,q."DATE"
--,to_char(q.total,'999999999D99') as total
,q.total::numeric(10,2) as total
,'0' as PAID
,'' as PTTYPE
,q.person_id,q.seq
	,'' as OPD_MEMO 
, '' as INVOICE_NO
,'' as INVOICE_LT
from (
	select hn,cte2.an
	,to_char(cte2."DATE"::date,'yyyymmdd') as "DATE" --วันที่คิดค่ารักษา วันที่จำหน่าย 
	--,to_char(sum(cte2.total),'999999999D99') as total
	, sum(cte2.total) as total
	,cte2.person_id,cte2.seq
	from cte2
	where cte2.total is not null -- ไม่เอา ค่าใช้จ่ายที่ว่าง
	group by hn,cte2.an,cte2."DATE"
	,cte2.person_id,cte2.seq
) q
--where q.SEQ = '6409010080'



--select * from order_item