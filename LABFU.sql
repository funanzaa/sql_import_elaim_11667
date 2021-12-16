--LABFU 16/12/64 v.1.0
select q.hcode,q.hn,q.person_id,q.date_serv,q.seq,q.an,q.labtest,case when q.LABTEST <> '' then q.LABRESULT else '' end as LABRESULT
from (
	select base_site.base_site_id as HCODE
	,v.hn as HN
	,patient.pid as PERSON_ID --รหัสประจำตัวประชาชนตามสำนักทะเบียนราษฎร
	,to_char(v.visit_date::date,'yyyymmdd') as DATE_SERV
	,v.vn as SEQ
	,v.an as AN 
	,case when order_item.item_id = 'labitems_3001' then '01' --Glucose
	      when order_item.item_id = 'labitems_52' then '03'  --Dexto
	      when order_item.item_id = 'labitems_48' then '05'  --HbA1C
	      when order_item.item_id = 'labitems_3006' then '06' -- Triglyceride
	      when order_item.item_id = 'labitems_3005' then '07' -- Cholesterol
	      when order_item.item_id = 'labitems_3007' then '08' -- HDL-Cholesterol
	      when order_item.item_id = 'labitems_596' then '09' --LDL - Chol
	      when order_item.item_id = 'labitems_173' then '10'  -- BUN
	      when order_item.item_id = 'labitems_3003' then '11' -- Creatinine
	      when order_item.item_id = 'tg000000064' then '12' -- Microalbuminuria
	      when order_item.item_id = '111092821040111901' then '15' -- Estimated GFR
	      when order_item.item_id = '110090409083922001' then '18' -- Potassium (Serum)
	      when order_item.item_id = '217090109082564001' then '20' -- PHOSPHORUS
	      when order_item.item_id = '201308211715001180' then '19' -- Electrolytes - Na, K, Cl, CO2
	      else '' end as LABTEST
	,lab_test.value as LABRESULT
	--,lab_result.*
	--,order_item.*
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
	left join patient on v.patient_id = patient.patient_id -- ข้อมูลทั่วไปผู้ป่วย
	inner join order_item on v.visit_id = order_item.visit_id 
	inner join lab_result on order_item.order_item_id = lab_result.order_item_id 
	inner join lab_test on lab_result.lab_result_id = lab_test.lab_result_id and lab_test.active = '1'
	,base_site
	where v.visit_date::date >= '2021-09-01' 
	and v.visit_date::date <= '2021-09-02'
	and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
	and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
	and order_item.fix_item_type_id = '1' -- lab
	--and v.fix_visit_type_id = '1' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
	--and v.visit_id = '121090107185617001'
	order by v.vn 
)	q


