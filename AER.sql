	--AER 25/10/64 v.1.1
	select q.hn,q.an,q.dateopd,q.authae
		--,q.plan_code
--		,q.optype
	, '' as AEDATE
	,'' as AETIME
	,'' as AETYPE
	,case when q.an = ''  then 'TEMP:'||q.seq else '' end as REFER_NO -- an = '' then ''
	,case when q.optype = '0' or q.optype = '1' then 
		  (case when LENGTH(regexp_replace(q.description, '\D','','g')) = 5 and q.description not ilike '%กัน%' then regexp_replace(q.description, '\D','','g') else '' end) -- hcode refer
		  else ''  end as REFMAINI -- optype 0,1 then AN
	,case when q.an = '' then '1100' else '1110' end as ireftype --opd = 1100 , ipd = 1110
	, '' as REFMAINO
	, '' as OREFTYPE
	,'' as UCAE
	, '' as EMTYPE
	,q.seq as SEQ
	, '' as AESTATUS
	, '' as DALERT
	, '' as TALERT
	--	,q.visit_id
	--	,q.base_department_id
		from (
			select  v.hn as hn
		,v.vn  as SEQ
		,v.an as AN
		,to_char(v.visit_date::date,'yyyymmdd') as DATEOPD
		,visit_payment.card_id as AUTHAE
	    ,attending_physician.base_department_id
	    ,v.plan_code
	    ,v.description
	    ,v.visit_id
		,case
			    when TRIM(v.description) = 'นัดรับยา(บัตรทอง)' or TRIM(v.description) = 'ปฐมภูมิUC'  or TRIM(v.description) = 'UC บัตร ท. [ผู้มีรายได้น้อย]' or
			    TRIM(v.description) = 'UC บัตรผู้พิการ /ยกเว้นค่าธรรมเนียม 30 บาท' or TRIM(v.description) = 'UC บัตร ท. ภิกษุ/ผู้นำศาสนา /ยกเว้นค่าธรรมเนียม 30 บาท'  or TRIM(v.description) = 'UC บัตร ท. [ครอบครัวทหารผ่านศึก]' or
			    TRIM(v.description) = 'UC บัตรผู้นำชุมชน /ยกเว้นค่าธรรมเนียม 30 บาท' or TRIM(v.description) = 'UC บัตร ท. [บัตร อสม]'  or TRIM(v.description) = 'UC ท. สิทธิ์ว่าง' or
			    TRIM(v.description) = 'UC ในเครือข่าย /ยกเว้นค่าธรรมเนียม 30 บาท' or TRIM(v.description) = 'UC ฉุกเฉิน /ยกเว้นค่าธรรมเนียม 30 บาท (ต่างจังหวัด)'  or TRIM(v.description) = 'บัตรทอง ช่วงอายุ 12-59 ปี' or
			    TRIM(v.description) = 'บัตรทอง อายุมากกว่า 60 ปี' or TRIM(v.description) = 'บัตรทอง อายุไม่เกิน 12 ปีบริบูรณ์'  or TRIM(v.description) = 'นักศึกษา - บัตรทอง ช่วงอายุ 12-59 ปี' then '7'
			--type 3 = AE นอกบัญชีเครือข่าย
			    when TRIM(v.description) = 'UC สิทธิอื่นใน กทม. (Model 5)' or TRIM(v.description) = 'UC นอกเครือข่าย /ยกเว้นค่าธรรมเนียม 30 บาท' then '3'
			--type 2 = AE ในบัญชีเครือข่าย
			    when TRIM(v.description) = 'UC ฉุกเฉินในเครือข่าย (model 5)' or TRIM(v.description) = 'UC ฉุกเฉิน /ยกเว้นค่าธรรมเนียม 30 บาท(กทม.)' then '2'
			--type 0 = Refer ในบัญชีเครือข่ายเดียวกัน
			    when LENGTH(regexp_replace(v.description, '\D','','g')) = 5 and v.description not ilike '%กัน%' then '0'
			--type 4 = OP พิการ
			    when TRIM(v.description) = 'UC บัตรผู้พิการ /ยกเว้นค่าธรรมเนียม 30 บาท ในกรุงเทพ' or TRIM(v.description) = 'UC บัตรผู้พิการ /ยกเว้นค่าธรรมเนียม 30 บาท ต่างจังหวัด' then '4'
			    --1 = Refer นอกบัญชีเครือข่าย
			    else  '1' end as OPTYPE -- ประเภทการให้บริการ
	--	,v.visit_id
		from (
					with cte1 as 
						(
							select q.*
							,case when q.base_plan_group_code in ('CHECKUP') and q.plan_code in ('PCP006') then 'UC'  -- check CHECKUP => PCP006 
								  when q.base_plan_group_code in ('Model5','UC') then 'UC' end as chk_plan -- check 'Model5','UC' => UC
							from (
								select v.*,base_plan_group.base_plan_group_code,plan.plan_code,plan.description 
								from visit v 
								left join visit_payment on v.visit_id = visit_payment.visit_id and visit_payment.priority = '1'
								left join base_plan_group on visit_payment.base_plan_group_id = base_plan_group.base_plan_group_id and base_plan_group.base_plan_group_code in ('Model5','UC','CHECKUP') -- สิทธิ์ UC
								left join plan on visit_payment.plan_id = plan.plan_id 
							) q
							where q.base_plan_group_code is not null 
						)
						select * from cte1 where cte1.chk_plan is not null -- visit ที่เป็นสิทธิ์ UC ตาม Excel
						and cte1.plan_code in ('MD504','MD505','UC0005','UC0019') 
			) v --เฉพาะ visit ที่เป็นสิทธิ์ UC ตาม Excel
			left join visit_payment on v.visit_id = visit_payment.visit_id and visit_payment.priority = '1' 
			left join attending_physician on v.visit_id = attending_physician.visit_id  AND attending_physician.priority = '1' and base_department_id in ('D0002')
			where v.visit_date::date >= '2021-09-01'
			and v.visit_date::date <= '2021-09-02'
			and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
			and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
			and v.financial_discharge <> '0' --ค้างชำระ
		) q
	where q.base_department_id is not null

	
	



	


	