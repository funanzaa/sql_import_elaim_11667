--DRU 15/10/64 v.1.2
--1.2 แก้ไขดึงเฉพาะสิทธิ์ ใน excel
select  base_site.base_site_id as HCODE
,v.hn as HN
,v.an as AN --พิ่มฟิลด์ตามโครงสร้าง หลัก e-Claim OPD เป็นค่าว่าง
,'00100' as CLINIC -- default --รหัส5หลักตามภาคผนวก
,patient.pid as PERSON_ID --รหัสประจำตัวประชาชนตามสำนักทะเบียนราษฎร
,to_char(visit_date::date,'yyyymmdd') as DATE_SERV
,item.item_id||':'||item.item_code as DID 
,item.common_name as DIDNAME
,order_item.quantity as AMOUNT --จำนวนยาที่จ่าย
,unit_price_sale as DRUGPRICE --ราคาขายต่อหน่วย 
,'' as DRUGCOST -- Don't send
,'' as DIDSTD  -- Waiting..
,base_unit.description_th as UNIT 
, '' as UNIT_PACK
,v.vn as SEQ
,'' as DRUGREMARK
,'' as PA_NO
,'' as TOTCOPAY -- จำนวนเงินรวม หน่วยเป็นบาท ในส่วนที่เบิกไม่ได้
,'' as USE_STATUS -- หมวดรายการยา
,'' as TOTAL
,'' as SIGCODE --รหัสวิธีใช้ยา (ถ้ามี) 
,'' as SIGTEXT -- วิธีใช้ยา (ถ้ามี) 
,'' as PROVIDER --เภสัชกรที่จ่ายยา ตามเลขที่ใบประกอบวิชาชีพเวชกรรม
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
left join patient on v.patient_id = patient.patient_id -- ข้อมูลทั่วไปผู้ป่วย
left join order_item on v.visit_id = order_item.visit_id  
	and fix_item_type_id = '0' --0 = ยา,ประเภทรายการตรวจ/รักษา 
	and fix_order_status_id = '3' -- 3 สถานะการ จ่าย
left join item on order_item.item_id = item.item_id 
left join base_unit on item.base_unit_id = base_unit.base_unit_id --หน่วยนับของยา
,base_site
where v.visit_date::date >= '2021-09-01' 
and v.visit_date::date <= '2021-09-01'
and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
--and v.fix_visit_type_id = '0' --ประเภทการเข้ารับบริการ 0 ผู้ป่วยนอก,1 ผู้ป่วยใน
order by v.vn 
--and v.visit_id = '121090107433621501'
