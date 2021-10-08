--OOP 08/10/64 v.1.0
--มาตรฐานแฟ้มข้อมูลหัตถการผู้ป่วยนอก (OOP)
select v.hn as HN
,to_char(v.visit_date::date,'yyyymmdd') as DATEOPD
,'00100' as CLINIC -- default
,icd9.icd9_code as OPER
,'' as DROPID
,p.pid as PERSON_ID
,v.vn as SEQ
,'' as SERVPRICE -- ราคาค่าบริการหัตถการ Y/N
from visit v 
left join diagnosis_icd9 icd9 on v.visit_id = icd9.visit_id 
left join patient p on v.patient_id = p.patient_id 
where v.visit_date::date >= '2021-09-01' 
and v.visit_date::date <= '2021-09-01'
and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
and v.fix_visit_type_id = '0' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
--and icd9.fix_operation_type_id = '1'