--OPD
select  v.vn as SEQ ,v.hn  
from visit v -- ข้อมูลการเข้ารับบริการ
where v.visit_date = '2021-09-01'