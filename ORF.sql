--ORF 07/10/64 v.1.1
--มาตรฐานแฟ้มข้อมูลผู้ป่วยนอกที่ต้องส่งต่อ (ORF)
--1.1 ปรับ login type 0
select v.hn as HN
,to_char(v.visit_date::date,'yyyymmdd') as DATEOPD
,'00100' as CLINIC -- default
,case when LENGTH(regexp_replace(only_type0.description, '\D','','g')) = 5 then regexp_replace(only_type0.description, '\D','','g')  
else '' end as REFER --check รหัสหน่วยบริการปฐมภูมิ
,'1' as REFERTYPE -- มีแค่เฉพาะรับเข้า
,v.vn as SEQ
,to_char(v.visit_date::date,'yyyymmdd') as REFERDATE -- REFERDATE วันเดียวกับ visit_date
from (						
		select get_plan.*
		,case when LENGTH(regexp_replace(get_plan.description, '\D','','g')) = 5 and get_plan.description not ilike '%กัน%' then '0' else '' end as op_type 
		from (
		select visit_payment.visit_id, plan.description
		from visit_payment 
		inner join plan on visit_payment.plan_id  = plan.plan_id
		where priority = '1'
		) get_plan	
		) only_type0 -- get only type0
left join visit v on only_type0.visit_id = v.visit_id 
where v.visit_date::date >= '2021-09-01' 
and v.visit_date::date <= '2021-09-02'
and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
and only_type0.op_type = '0'
order by v.vn 