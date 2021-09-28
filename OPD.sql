--OPD
select null as "CLINIC",v.hn as HN,to_char(visit_date::date,'yyyyddmm') as DATEOPD
,replace(left(visit_time,5),':','') as TIMEOPD
,v.vn as SEQ 
,'1' as UUC -- การใช้สิทธิ (เพิ่มเติม) 1 ใช้สิทธิ, 2 ไมใช้สิทธิ
,dup_vital_sign_extend.main_symptom as DETAIL
from visit v -- ข้อมูลการเข้ารับบริการ
inner join (select vital_sign_extend.visit_id,vital_sign_extend.main_symptom 
				from vital_sign_extend 
				inner join ( 
						SELECT vital_sign_extend_id,
				         ROW_NUMBER() OVER( PARTITION BY visit_id
				        ORDER BY  vital_sign_extend_id desc ) AS row_num
				        FROM vital_sign_extend
				        ) count_vital_sign_extend on count_vital_sign_extend.vital_sign_extend_id = vital_sign_extend.vital_sign_extend_id
				where count_vital_sign_extend.row_num = 1 ) dup_vital_sign_extend on dup_vital_sign_extend.visit_id = v.visit_id  --อาการสำคัญ(ตัด table vital_sign_extend เอา อาการสำคัญ ที่ล่าสุด)
where v.visit_date = '2021-09-01'
and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
and v.fix_visit_type_id = '0' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
