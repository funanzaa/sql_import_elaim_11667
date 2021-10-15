--IRF 15/10/64 v.1.1
-- มาตรฐานแฟ้มข้อมูลผู้ป่วยในที่ต้องส่งต่อ (IRF)
--1.1 แก้ไขดึงเฉพาะสิทธิ์ ใน excel
select v.an as AN
,regexp_replace(only_type0.description, '\D','','g') as REFER
, '1' as REFERTYPE
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
				select * from cte1 where cte1.chk_plan is not null 
	) v -- visit ที่เป็นสิทธิ์ UC ตาม Excel
left join (
		select get_plan.*
		,case when LENGTH(regexp_replace(get_plan.description, '\D','','g')) = 5 and get_plan.description not ilike '%กัน%' then '0' else '' end as op_type  
		from (
		select visit_payment.visit_id, plan.description
		from visit_payment 
		inner join plan on visit_payment.plan_id  = plan.plan_id
		where priority = '1') get_plan -- get priority
		) only_type0 on v.visit_id = only_type0.visit_id -- get only type0
where v.visit_date::date >= '2021-09-01'
and v.visit_date::date <= '2021-09-02'
and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
and v.fix_visit_type_id = '1' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
and only_type0.op_type = '0'
