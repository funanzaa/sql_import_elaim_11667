--ADP 14/12/64 v.1.0
with cte1 as (
		select v.hn as hn
		,v.an as AN
		,to_char(v.visit_date::date,'yyyymmdd') as dateopd
		--,base_billing_group.map_chrgitem_opd
		--,base_billing_group.map_chrgitem_ipd
		--covert ADP Type
		,case when base_billing_group.map_chrgitem_opd = '11' then '10' --ค่าห้อง/ค่าอาหาร
			  when base_billing_group.map_chrgitem_opd = '21' then '2'  --Instrument 
			  when base_billing_group.map_chrgitem_opd = '51' then '11' -- เวชภัณฑ์ที่ไม่ใช่ยา
			  when base_billing_group.map_chrgitem_opd = '61' then '14' -- บริการโลหิตและส่วนประกอบของโลหิต
			  when base_billing_group.map_chrgitem_opd = '71' then '15' -- ตรวจวินิจฉัยทางเทคนิคการแพทย์และพยาธิวิทยา
		      when base_billing_group.map_chrgitem_opd = '81' then '16' -- ค่าตรวจวินิจฉัยและรักษาทางรังสีวิทยา
		      when base_billing_group.map_chrgitem_opd = '91' then '9' -- ตรวจวินิจฉัยด้วยวิธีพิเศษอื่นๆ
			  when base_billing_group.map_chrgitem_opd = 'A1' then '18' -- อุปกรณ์และเครื่องมือทางการแพทย์
			  when base_billing_group.map_chrgitem_opd = 'B1' then '19' --  ทำหัตถการและวิสัญญี
			  when base_billing_group.map_chrgitem_opd = 'C1' then '17' --  ค่าบริการทางการพยาบาล
			  when base_billing_group.map_chrgitem_opd = 'D1' then '12' --  ค่าบริการทันตกรรม
			  when base_billing_group.map_chrgitem_opd = 'E1' then '20' --  ค่าบริการทางกายภาพบำบัดและเวชกรรมฟื้นฟู
			  when base_billing_group.map_chrgitem_opd = 'F1' then '13' --  ค่าบริการฝังเข็ม
			  else '' end as "type"
		,'' as code
		,order_item.quantity as qty -- หน่วยนับ เป็นจำนวนครั้งหรือจำนวนเม็ด ของอุปกรณ์บำบัดรักษา และจำนวนยาที่ใช
		,order_item.unit_price_sale as rate --ราคาต่อหน่วย
		,v.vn  as SEQ
		,'' as CAGCODE -- กรณี Type = 7 UCS/SSS/SSI
		,order_item.quantity  || ' ' || order_item.base_unit_id  as DOSE --ขนาด SSS/SSI
		,'' as CA_TYPE --ประเภทการรักษามะเร็ง SSS/SSI
		,'' as SERIALNO --หมายเลข Serial Number ของอวัยวะ เทียม/อุปกรณ์บำบัดรักษา (Instrument) UCS
		, '' as TOTCOPAY --จำนวนเงินรวม เป็นบาท ในส่วนที่เบิกไม่ได้
		,order_item.take_home as USE_STATUS --กรณีที่ Type = 11 (เวชภัณฑ์ที่ไม่ใช่ยา) จะต้องกำหนดค่าดังกล่าวนี้ 1 = ใช้ในโรงพยาบาล , 2 = ใช้ที่บ้าน (OFC/LGO)
		, '' as TOTAL --จำนวนเงินรวมที่ขอเบิกของรายการนั้น 
		,'' as QTYDAY --จำนวนวันที่ขอเบิก สำหรับสิทธิ UC ใช้ใน กรณีที่ Type = 3 (ค่าบริการอื่นๆ ที่ยังไม่ได้จัดหมวด) และมีการเบิกรายการ Morphine หรือ Oxygen (UCS)
		,'' as TMLTCODE -- รหัสการตรวจ ตามบัญชีรายการ TMLT ที่ประกาศโดย สมสท (OFC)
		, '' as STATUS1  --ผลการตรวจ LAB COVID 1 = Positive , 0 = Negative
		,'' as BI --ค่า Barthel ADL Index 
		, '' as CLINIC --รหัสคลินิกที่ให้บริการ
		, '' as ITEMSRC --ประเภทรหัส: 1 = รหัสหน่วยบริการ, 2 =รหัสกรมบัญชีกลาง/รหัสที่สปสช.กำหนด
		,'' as PROVIDER --ผู้ให้บริการที่เกี่ยวข้อง ตามเลขที่ใบประกอบวิชาชีพเวชกรรม *PROVIDER รหัสผู้ให้บริการ กรณีที่ไม่มีข้อมูลให้ละเป็นค่าว่างได
		,case when TRIM(get_plan.description) = 'นัดรับยา(บัตรทอง)' or TRIM(get_plan.description) = 'ปฐมภูมิUC'  or TRIM(get_plan.description) = 'UC บัตร ท. [ผู้มีรายได้น้อย]' or
	    TRIM(get_plan.description) = 'UC บัตรผู้พิการ /ยกเว้นค่าธรรมเนียม 30 บาท' or TRIM(get_plan.description) = 'UC บัตร ท. ภิกษุ/ผู้นำศาสนา /ยกเว้นค่าธรรมเนียม 30 บาท'  or TRIM(get_plan.description) = 'UC บัตร ท. [ครอบครัวทหารผ่านศึก]' or
	    TRIM(get_plan.description) = 'UC บัตรผู้นำชุมชน /ยกเว้นค่าธรรมเนียม 30 บาท' or TRIM(get_plan.description) = 'UC บัตร ท. [บัตร อสม]'  or TRIM(get_plan.description) = 'UC ท. สิทธิ์ว่าง' or
	    TRIM(get_plan.description) = 'UC ในเครือข่าย /ยกเว้นค่าธรรมเนียม 30 บาท' or TRIM(get_plan.description) = 'UC ฉุกเฉิน /ยกเว้นค่าธรรมเนียม 30 บาท (ต่างจังหวัด)'  or TRIM(get_plan.description) = 'บัตรทอง ช่วงอายุ 12-59 ปี' or
	    TRIM(get_plan.description) = 'บัตรทอง อายุมากกว่า 60 ปี' or TRIM(get_plan.description) = 'บัตรทอง อายุไม่เกิน 12 ปีบริบูรณ์'  or TRIM(get_plan.description) = 'นักศึกษา - บัตรทอง ช่วงอายุ 12-59 ปี' then '7'
	--type 3 = AE นอกบัญชีเครือข่าย
	    when TRIM(get_plan.description) = 'UC สิทธิอื่นใน กทม. (Model 5)' or TRIM(get_plan.description) = 'UC นอกเครือข่าย /ยกเว้นค่าธรรมเนียม 30 บาท' then '3'
	--type 2 = AE ในบัญชีเครือข่าย
	    when TRIM(get_plan.description) = 'UC ฉุกเฉินในเครือข่าย (model 5)' or TRIM(get_plan.description) = 'UC ฉุกเฉิน /ยกเว้นค่าธรรมเนียม 30 บาท(กทม.)' then '2'
	--type 0 = Refer ในบัญชีเครือข่ายเดียวกัน
	    when LENGTH(regexp_replace(get_plan.description, '\D','','g')) = 5 and get_plan.description not ilike '%กัน%' then '0'
	--type 4 = OP พิการ
	    when TRIM(get_plan.description) = 'UC บัตรผู้พิการ /ยกเว้นค่าธรรมเนียม 30 บาท ในกรุงเทพ' or TRIM(get_plan.description) = 'UC บัตรผู้พิการ /ยกเว้นค่าธรรมเนียม 30 บาท ต่างจังหวัด' then '4'
	    else  '' end as OPTYPE --ประเภทการให้บริการ
	    , get_plan.description
			from (
					with cte1 as 
						(select q.*
							,case when q.base_plan_group_code in ('CHECKUP') and q.plan_code in ('PCP006') then 'UC'  -- check CHECKUP => PCP006 
								  when q.base_plan_group_code in ('Model5','UC') then 'UC' end as chk_plan -- check 'Model5','UC' => UC
							from (
								select v.*,base_plan_group.base_plan_group_code,plan.plan_code 
								from visit v 
								left join visit_payment on v.visit_id = visit_payment.visit_id and visit_payment.priority = '1'
								left join base_plan_group on visit_payment.base_plan_group_id = base_plan_group.base_plan_group_id and base_plan_group.base_plan_group_code in ('Model5','UC','CHECKUP') -- สิทธิ์ UC
								left join plan on visit_payment.plan_id = plan.plan_id 
							) q
							where q.base_plan_group_code is not null )
						select * from cte1 where cte1.chk_plan is not null -- visit ที่เป็นสิทธิ์ UC ตาม Excel
			) v --เฉพาะ visit ที่เป็นสิทธิ์ UC ตาม Excel
		left join (
			select order_item_id,visit_id,base_billing_group_id,unit_price_sale,quantity,base_unit_id ,item_id,take_home
			from order_item 
			where quantity not like '-%' and unit_price_sale <> '0') order_item on v.visit_id = order_item.visit_id -- GET table order ที่ไม่ติดลบ, unit_price_sale <> '0'
		left join (
			select visit_payment.visit_id, plan.description
			from visit_payment
			inner join plan on visit_payment.plan_id  = plan.plan_id
			where priority = '1') get_plan on v.visit_id = get_plan.visit_id -- ดึง plan ใน visit_payment
		left join base_billing_group on order_item.base_billing_group_id = base_billing_group.base_billing_group_id 
		left join patient p on v.patient_id = p.patient_id 
		where v.visit_date::date >= '2021-09-01' 
		and v.visit_date::date <= '2021-09-02'
		--and v.vn = '6409010040'
and v.financial_discharge <> '0' --ค้างชำระ	
)
select cte1.hn
,cte1.an
,cte1.dateopd
,cte1."type"
,cte1.code
,case when cte1."type" = '' then '' else cte1.qty end as qty
,case when cte1."type" = '' then '' else cte1.rate end as rate
,cte1.seq
,case when cte1."type" = '' then '' else cte1.cagcode end as cagcode
,case when cte1."type" = '' then '' else cte1.dose end as dose
,cte1.ca_type
,cte1.serialno
,cte1.totcopay
--,cte1.use_status
,case when cte1."type" = '11' then cte1.use_status else '' end as use_status
--, cte1.total
,case when cte1."type" <> '' then to_char(cte1.qty::decimal * cte1.rate::decimal,'FM999999990.00') else'' end as total
,cte1.qtyday
,cte1.tmltcode
,cte1.status1
,cte1.bi
,cte1.clinic
,cte1.itemsrc
,cte1.provider 
from cte1