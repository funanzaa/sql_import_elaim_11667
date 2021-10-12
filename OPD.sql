--OPD 05/10/64 v.1.2
-- v.1.2 แก้ไข tab
select q.*
from (
		select v.hn as HN,'' as "CLINIC",to_char(visit_date::date,'yyyymmdd') as DATEOPD
	,replace(left(visit_time,5),':','') as TIMEOPD
	,v.vn as SEQ
	,'1' as UUC -- การใช้สิทธิ (เพิ่มเติม) 1 ใช้สิทธิ, 2 ไมใช้สิทธิ
	,case when char_length(trim(dup_vital_sign_extend.main_symptom)) > 255 then substring(regexp_replace(trim(dup_vital_sign_extend.main_symptom),'\s+','','g'),1,255)
		else regexp_replace(trim(dup_vital_sign_extend.main_symptom),'\s+','','g') end as DETAIL -- check over 255
--	,regexp_replace(trim(dup_vital_sign_extend.main_symptom),'\s+','','g') as test 
	--,to_number(case when v_vital_sign_opd.temperature is null or v_vital_sign_opd.temperature = '' then '0' else v_vital_sign_opd.temperature end,'99D99') as BTEMP -- อุณหภูมิร่างกาย
	,v_vital_sign_opd.temperature as BTEMP -- อุณหภูมิร่างกาย
	,v_vital_sign_opd.pressure_max as SBP --ความดันโลหิตค่าตัวบน
	,v_vital_sign_opd.pressure_min as DBP --ความดันโลหิตค่าตัวล่าง
	,v_vital_sign_opd.pulse as PR --อัตราการเต้นหัวใจ
	,v_vital_sign_opd.respiration as RR --อัตราการหายใจ
	--type 7
	,case
	    when TRIM(get_plan.description) = 'นัดรับยา(บัตรทอง)' or TRIM(get_plan.description) = 'ปฐมภูมิUC'  or TRIM(get_plan.description) = 'UC บัตร ท. [ผู้มีรายได้น้อย]' or
	    TRIM(get_plan.description) = 'UC บัตรผู้พิการ /ยกเว้นค่าธรรมเนียม 30 บาท' or TRIM(get_plan.description) = 'UC บัตร ท. ภิกษุ/ผู้นำศาสนา /ยกเว้นค่าธรรมเนียม 30 บาท'  or TRIM(get_plan.description) = 'UC บัตร ท. [ครอบครัวทหารผ่านศึก]' or
	    TRIM(get_plan.description) = 'UC บัตรผู้นำชุมชน /ยกเว้นค่าธรรมเนียม 30 บาท' or TRIM(get_plan.description) = 'UC บัตร ท. [บัตร อสม]'  or TRIM(get_plan.description) = 'UC ท. สิทธิ์ว่าง' or
	    TRIM(get_plan.description) = 'UC ในเครือข่าย /ยกเว้นค่าธรรมเนียม 30 บาท' or TRIM(get_plan.description) = 'UC ฉุกเฉิน /ยกเว้นค่าธรรมเนียม 30 บาท (ต่างจังหวัด)'  or TRIM(get_plan.description) = 'บัตรทอง ช่วงอายุ 12-59 ปี' or
	    TRIM(get_plan.description) = 'บัตรทอง อายุมากกว่า 60 ปี' or TRIM(get_plan.description) = 'บัตรทอง อายุไม่เกิน 12 ปีบริบูรณ์'  or TRIM(get_plan.description) = 'นักศึกษา - บัตรทอง ช่วงอายุ 12-59 ปี' then '7'
	--type 3 = AE นอกบัญชีเครือข่าย
	    when TRIM(get_plan.description) = 'UC สิทธิอื่นใน กทม. (Model 5)' or TRIM(get_plan.description) = 'UC นอกเครือข่าย /ยกเว้นค่าธรรมเนียม 30 บาท' then '3'
	--type 2 = AE ในบัญชีเครือข่าย
	    when TRIM(get_plan.description) = 'UC ฉุกเฉินในเครือข่าย (model 5)' or TRIM(get_plan.description) = 'UC ฉุกเฉิน /ยกเว้นค่าธรรมเนียม 30 บาท(กทม.)' then '3'
	--type 0 = Refer ในบัญชีเครือข่ายเดียวกัน
	    when TRIM(get_plan.description) = 'ศูนย์บริการสาธารณสุข 59 ทุ่งครุ(13702)' or TRIM(get_plan.description) = 'รักษ์ศิริคลินิกเวชกรรม สาขาทุ่งครุ (41864)' or TRIM(get_plan.description) = 'ศูนย์บริการสาธารณสุข 58 ล้อม-พิมเสน ฟักอุดม(13701)' or
	         TRIM(get_plan.description) = 'สรรธนาคลินิกเวชกรรม (42097)' or TRIM(get_plan.description) = 'สิริยาสหคลินิก (15185)' or TRIM(get_plan.description) = 'ศูนย์บริการสาธารณสุข 39 ราษฎร์บูรณะ (13684)' then '0'
	--type 4 = OP พิการ
	    when TRIM(get_plan.description) = 'UC บัตรผู้พิการ /ยกเว้นค่าธรรมเนียม 30 บาท ในกรุงเทพ' or TRIM(get_plan.description) = 'UC บัตรผู้พิการ /ยกเว้นค่าธรรมเนียม 30 บาท ต่างจังหวัด' then '4'
	    else  '' end as OPTYPE --ประเภทการให้บริการ
	--,TRIM(get_plan.description) as test_OPTYPE
	,case when v.fix_coming_type is null then '0' else '1' end as TYPEIN --ประเภทการมารับบริการ
	,case when doctor_discharge_opd.fix_opd_discharge_status_id = '51' then '1' -- จำหน่ายกลับบ้าน
		when doctor_discharge_opd.fix_opd_discharge_status_id = '52' then '4' -- เสียชีวิต
		when doctor_discharge_opd.fix_opd_discharge_status_id = '53' then 'consult'
		when doctor_discharge_opd.fix_opd_discharge_status_id = '54' then '3' --Refer ต่อ
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
	left join (
		select visit_payment.visit_id, plan.description
		from visit_payment
		inner join plan on visit_payment.plan_id  = plan.plan_id
		where priority = '1'
	) get_plan on v.visit_id = get_plan.visit_id -- ดึง plan ใน visit_payment
	where v.visit_date::date >= '2021-09-01'
	and v.visit_date::date <= '2021-09-02'
	and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
	and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
	and v.fix_visit_type_id = '0' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
	--and v.vn ='6409010008'
	order by v.vn
) q
where q.optype <> '' -- ไม่เข้าเงื่อนไข optype