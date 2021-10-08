--ODX 08/10/64 v.1.0
--มาตรฐานแฟ้มข้อมูลวินิจฉัยโรคผู้ป่วยนอก (ODX)
select v.hn as HN
,dx10.diagnosis_date  as DATEDX
,'00100' as CLINIC -- default
,dx10.icd10_code as DIAG
,dx10.fix_diagnosis_type_id as DXTYPE
--,trim(emp.profession_code) as DRDX --รหัส ว
,regexp_replace(trim(emp.profession_code), '\D','','g') as DRDX
,p.pid as PERSON_ID
,v.vn as SEQ
from visit v 
left join diagnosis_icd10 dx10 on v.visit_id = dx10.visit_id  --dx10 
left join employee emp on dx10.doctor_eid = emp.employee_code
left join patient p on v.patient_id = p.patient_id 
where v.visit_date::date >= '2021-09-01' 
and v.visit_date::date <= '2021-09-01'
and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
and v.fix_visit_type_id = '0' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
and dx10.fix_diagnosis_type_id = '1' -- Primary Diagnosis
order by v.vn 