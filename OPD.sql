--OPD 4/10/64
select null as "CLINIC",v.hn as HN,to_char(visit_date::date,'yyyyddmm') as DATEOPD
,replace(left(visit_time,5),':','') as TIMEOPD
,v.vn as SEQ 
,'1' as UUC -- การใช้สิทธิ (เพิ่มเติม) 1 ใช้สิทธิ, 2 ไมใช้สิทธิ
,case when char_length(dup_vital_sign_extend.main_symptom) > 255 then substring(dup_vital_sign_extend.main_symptom,1,255) else dup_vital_sign_extend.main_symptom end as DETAIL -- check over 255
--,to_number(case when v_vital_sign_opd.temperature is null or v_vital_sign_opd.temperature = '' then '0' else v_vital_sign_opd.temperature end,'99D99') as BTEMP -- อุณหภูมิร่างกาย
,v_vital_sign_opd.temperature as BTEMP -- อุณหภูมิร่างกาย
,v_vital_sign_opd.pressure_max as SBP --ความดันโลหิตค่าตัวบน
,v_vital_sign_opd.pressure_min as DBP --ความดันโลหิตค่าตัวล่าง
,v_vital_sign_opd.pulse as PR --อัตราการเต้นหัวใจ
,v_vital_sign_opd.respiration as RR --อัตราการหายใจ
,'' as OPTYPE --ประเภทการให้บริการ
,case when v.fix_coming_type is null then '0' else '1' end as TYPEIN --ประเภทการมารับบริการ
,case when doctor_discharge_opd.fix_opd_discharge_status_id = '51' then '1' -- จำหน่ายกลับบ้าน 
	when doctor_discharge_opd.fix_opd_discharge_status_id = '52' then '4' -- เสียชีวิต
	when doctor_discharge_opd.fix_opd_discharge_status_id = '53' then 'consult' --Refer ต่อ 
	when doctor_discharge_opd.fix_opd_discharge_status_id = '54' then '3' 
	else '' end as TYPEOUT --สถานะผู้ป่วยเมื่อเสร็จสิ้นบริการ
from visit v -- ข้อมูลการเข้ารับบริการ
left join (select vital_sign_extend.visit_id,vital_sign_extend.main_symptom 
				from vital_sign_extend 
				inner join ( 
						SELECT vital_sign_extend_id,
				         ROW_NUMBER() OVER( PARTITION BY visit_id
				        ORDER BY  vital_sign_extend_id desc ) AS row_num
				        FROM vital_sign_extend
				        ) count_vital_sign_extend on count_vital_sign_extend.vital_sign_extend_id = vital_sign_extend.vital_sign_extend_id
				where count_vital_sign_extend.row_num = 1 ) dup_vital_sign_extend on v.visit_id = dup_vital_sign_extend.visit_id --อาการสำคัญ(ตัด table vital_sign_extend เอา อาการสำคัญ ที่ล่าสุด)
left join (
			select vital_sign_opd.*
			from vital_sign_opd
			inner join (
						select vital_sign_opd_id,ROW_NUMBER() OVER( PARTITION BY visit_id ORDER by vital_sign_opd_id desc) as chk_dup
						from vital_sign_opd
				 		) chk_vital_sign_opd on chk_vital_sign_opd.vital_sign_opd_id = vital_sign_opd.vital_sign_opd_id and chk_vital_sign_opd.chk_dup = 1
                 ) v_vital_sign_opd on v.visit_id = v_vital_sign_opd.visit_id-- Vital Sign ผู้ป่วยนอก ดึงเฉพาะ recode ล่าสุด
left join doctor_discharge_opd on v.visit_id = doctor_discharge_opd.visit_id 
where v.visit_date = '2021-09-01'
and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
and v.fix_visit_type_id = '0' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
order by v.vn
