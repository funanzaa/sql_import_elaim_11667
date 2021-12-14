--LVD 14/12/64 v.1.0
select v.vn as SEQLVD
,v.an as AN 
,to_char(doctor_discharge_ipd.discharge_date::date,'yyyymmdd') as DATEOUT
,replace(left(doctor_discharge_ipd.discharge_time,5),':','') as TIMEOUT
,to_char(v.visit_date::date,'yyyymmdd') as DATEIN
,replace(left(v.visit_time,5),':','') as TIMEIN
--,DATE_PART('day', (doctor_discharge_ipd.discharge_date||' '||doctor_discharge_ipd.discharge_time)::timestamp - (v.visit_date||' '||v.visit_time)::timestamp) as QTYDAY --Count time
,DATE_PART('day',(doctor_discharge_ipd.discharge_date::timestamp - v.visit_date::timestamp)) as QTYDAY
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
inner join doctor_discharge_ipd on v.visit_id = doctor_discharge_ipd.visit_id 
where v.visit_date::date >= '2021-09-01' 
and v.visit_date::date <= '2021-09-02'
and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
and v.fix_visit_type_id = '1' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
order by v.vn 
--and v.visit_id = '121090107433621501'
