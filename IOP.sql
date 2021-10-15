--IOP 15/10/64 v.1.1
-- มาตรฐานแฟ้มข้อมูลหัตถการผู้ป่วยใน (IOP)
--1.2 แก้ไขดึงเฉพาะสิทธิ์ ใน excel
with cte1 as (
	select v.an as AN
	,replace(icd9.icd9_code,'.','') as OPER
	,icd9.fix_operation_type_id as OPTYPE
	,case when length(regexp_replace(trim(emp.profession_code), '\D','','g')) > 6 then substring(regexp_replace(trim(emp.profession_code), '\D','','g'),1,6) 
		else regexp_replace(trim(emp.profession_code), '\D','','g') end as DROPID --check length 6
	,to_char(case when icd9.date_in <> '' then icd9.date_in::date else icd9.modify_date::date end,'yyyymmdd') as DATEIN 
	,to_char(case when icd9.time_in <> '' then icd9.time_in::time else icd9.modify_time::time end,'HH24MI') as TIMEIN 
	,'' as DATEOUT 
	,'' as TIMEOUT 
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
	left join diagnosis_icd9 icd9 on v.visit_id = icd9.visit_id 
	left join patient p on v.patient_id = p.patient_id 
	left join employee emp on icd9.doctor_eid = emp.employee_code
	where v.visit_date::date >= '2021-08-01' 
	and v.visit_date::date <= '2021-09-02'
	and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
	and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
	and v.fix_visit_type_id = '1' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
	--and icd9.fix_operation_type_id = '1'
)
select  * 
from cte1
where cte1.oper is not null  -- ลบ เลือกเฉพาะ ไม่ null icd9