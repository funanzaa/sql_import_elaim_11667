--CHA 11/11/64 v.1.0
select v.hn as hn
,v.an as AN
,to_char(v.visit_date::date,'yyyymmdd')as "DATE"
,case when base_billing_group.map_chrgitem_opd = '' then base_billing_group.map_chrgitem_ipd else base_billing_group.map_chrgitem_opd end as CHRGITEM 
,((order_item.unit_price_sale::decimal * order_item.quantity::decimal))::numeric(12,2) as total
,p.pid as PERSON_ID
,v.vn  as SEQ
--,v.visit_id 
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
	where quantity not like '-%' and unit_price_sale <> '0') order_item on v.visit_id = order_item.visit_id -- GET table order ที่ไม่ติดลบ, unit_price_sale <> '0'
left join base_billing_group on order_item.base_billing_group_id = base_billing_group.base_billing_group_id 
left join patient p on v.patient_id = p.patient_id 
where v.visit_date::date >= '2021-09-01' 
and v.visit_date::date <= '2021-09-02'
and v.financial_discharge <> '0' --ค้างชำระ
--and v.vn = '6409010080'
--and v.visit_id = '221090218185837601' 
--and order_item.base_billing_group_id = '01.02.01.05.00.00'



