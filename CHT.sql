--CHT 18/10/64 v.1.1
-- มาตรฐานแฟ้มข้อมูลการเงิน (แบบสรุป) (CHT)
--v.1.1 => changed codeing
with cte2 as (
	select v.hn as hn
	,v.an as AN
	,v.financial_discharge_date as "DATE"
	,unit_price_sale::decimal * quantity::decimal as total
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
	left join order_item on v.visit_id = order_item.visit_id 
	left join patient p on v.patient_id = p.patient_id 
	where v.visit_date::date >= '2021-09-01' 
	and v.visit_date::date <= '2021-09-02'
	and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
	and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
	--and v.fix_visit_type_id = '1' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
	order by v.vn
)
select q.hn,q.an,q."DATE",q.total
,'0' as PAID
,'' as PTTYPE
,q.person_id,q.seq
	,'' as OPD_MEMO 
, '' as INVOICE_NO
,'' as INVOICE_LT
from (
	select hn,cte2.an
	,to_char(cte2."DATE"::date,'yyyymmdd') as "DATE" --วันที่คิดค่ารักษา วันที่จำหน่าย 
	,to_char(sum(cte2.total),'999999999D99') as total
	,cte2.person_id,cte2.seq
	from cte2
	group by hn,cte2.an,cte2."DATE"
	,cte2.person_id,cte2.seq
) q