--PAT 06/10/64 v.1.0
-- มาตรฐานแฟ้มข้อมูลผู้ป่วยกลาง (PAT)
select base_site.base_site_id 
,p.hn 
,'' as CHANGWAT
, '' as AMPHUR
,to_char(p.birthdate::date,'ddmmyyyy') as DOB
,gender.fix_gender_id as SEX
,case when marriage.fix_marriage_id = '5' then '3' -- imed 5 = หม้าย , nhso 3 = หม้าย
 	  when marriage.fix_marriage_id = '3' then '5' -- imed 3 = แยกกันอยู่ (ร้าง) , nhso 5 = แยกกันอยู
 	  else marriage.fix_marriage_id end as MARRIAGE 
 	  ,p.patient_id 
 ,occupation.fix_occupation_id as OCCUPA
 ,nationality.fix_nationality_id as NATION
 ,p.pid as PERSON_ID
 --,char_length(p.firstname||' '||p.lastname||','||p.prename) as NAMEPAT
 ,case when char_length(p.firstname||' '||p.lastname||','||p.prename) > 36 then substring(p.firstname||' '||p.lastname||','||p.prename,1,36) else p.firstname||' '||p.lastname||','||p.prename end as NAMEPAT -- check over 36
,p.prename as TITLE
,p.firstname as FNAME
,p.lastname as LNAME
,case when p.pid <> '' then '1' else '' end as IDTYPE
 from visit v
left join patient p on v.patient_id = p.patient_id 
left join fix_gender gender on p.fix_gender_id = gender.fix_gender_id -- sex
left join fix_marriage marriage on p.fix_marriage_id = marriage.fix_marriage_id 
left join fix_occupation occupation on p.fix_occupation_id = occupation.fix_occupation_id 
left join fix_nationality nationality on p.fix_nationality_id = nationality.fix_nationality_id 
,base_site
where v.visit_date::date >= '2021-09-01' 
and v.visit_date::date <= '2021-09-01'
and v.financial_discharge = '1' --จำหน่ายทางการเงินแล้ว
and v.doctor_discharge = '1' --จำหน่ายทางการแพทย์แล้ว
order by v.vn 
--and v.visit_id = '121090107433621501'
