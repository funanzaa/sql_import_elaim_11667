--ORF 07/10/64 v.1.0
--มาตรฐานแฟ้มข้อมูลผู้ป่วยนอกที่ต้องส่งต่อ (ORF)
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
		,case when TRIM(get_plan.description) = 'ศูนย์บริการสาธารณสุข 59 ทุ่งครุ(13702)' or
			TRIM(get_plan.description) = 'รักษ์ศิริคลินิกเวชกรรม สาขาทุ่งครุ (41864)' or 
			TRIM(get_plan.description) = 'ศูนย์บริการสาธารณสุข 58 ล้อม-พิมเสน ฟักอุดม(13701)' or
		    TRIM(get_plan.description) = 'สรรธนาคลินิกเวชกรรม (42097)' or 
		    TRIM(get_plan.description) = 'สิริยาสหคลินิก (15185)' or 
		    TRIM(get_plan.description) = 'ศูนย์บริการสาธารณสุข 39 ราษฎร์บูรณะ (13684)' then '0'
	    else '' end op_type 
		from (
		select visit_payment.visit_id, plan.description
		from visit_payment 
		inner join plan on visit_payment.plan_id  = plan.plan_id
		where priority = '1') get_plan
		) only_type0 -- get only type0
left join visit v on only_type0.visit_id = v.visit_id 
where v.visit_date::date >= '2021-09-01' 
and v.visit_date::date <= '2021-09-01'
and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
and only_type0.op_type = '0'
order by v.vn 