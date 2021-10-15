--IPD 09/10/64 v.1.1
--แฟ้มข้อมูลผู้ป่วยใน (IPD)
--1.1 แก้ไขดึงเฉพาะสิทธิ์ ใน excel
select v.hn as HN
,v.an as AN
,to_char(v.visit_date::date,'yyyymmdd') as DATEADM
,to_char(v.visit_time::time,'HH24MI') as TIMEADM
,to_char(v.doctor_discharge_date::date,'yyyymmdd') as DATEDSC --วันจำหน่าย บันทึกปีในค่าเป็น ค.ศ
,to_char(v.doctor_discharge_time::time,'HH24MI') as TIMEDSC
,doctor_discharge_ipd.fix_ipd_discharge_status_id as DISCHS --สถานภาพ การจำหน่ายผู้ป่วย
,doctor_discharge_ipd.fix_ipd_discharge_type_id as DISCHT --วิธีการจำหน่ายผู้ป่วย
, '' as WARDDSC --ตึกที่จำหน่ายผู้ป่วยใช้รหัสที่โรงพยาบาลตั้งขึ้น
,'' as DEPT
,v_vital_sign_opd.weight as ADM_W -- น้ำหนักแรกรับ
,'1' as UUC
,'1' as SVCTYPE
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
	) v 
left join (
				select vital_sign_opd.*
				from vital_sign_opd
				inner join (
							select vital_sign_opd_id,ROW_NUMBER() OVER( PARTITION BY visit_id ORDER by vital_sign_opd_id desc) as chk_dup
							from vital_sign_opd
					 		) chk_vital_sign_opd on chk_vital_sign_opd.vital_sign_opd_id = vital_sign_opd.vital_sign_opd_id and chk_vital_sign_opd.chk_dup = 1
	                 ) v_vital_sign_opd on v.visit_id = v_vital_sign_opd.visit_id-- Vital Sign ผู้ป่วยนอก ดึงเฉพาะ recode ล่าสุด
left join doctor_discharge_ipd on v.visit_id = doctor_discharge_ipd.visit_id 
where v.visit_date::date >= '2021-09-01' 
and v.visit_date::date <= '2021-09-01'
and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
and v.fix_visit_type_id = '1' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน