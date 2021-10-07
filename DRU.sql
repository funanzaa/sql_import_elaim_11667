--DRU 07/10/64 v.1.1
select  base_site.base_site_id as HCODE
,v.hn as HN
,'' as AN --พิ่มฟิลด์ตามโครงสร้าง หลัก e-Claim OPD เป็นค่าว่าง
,'' as CLINIC --รหัส5หลักตามภาคผนวก
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
from visit v -- ข้อมูลการเข้ารับบริการ
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
