create or replace view MI_ROUTE_PT as 
select id_drug_route as route_id, 
pk_translation.get_translation(1, 'DRUG_ROUTE.CODE_DRUG_ROUTE.' || id_drug_route) as route_descr,
gender,
age_min,
age_max,
flg_available,
'PT' vers
from drug_route;