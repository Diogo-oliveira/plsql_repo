create or replace view MI_REGULATION_PT as 
select id.diploma_id as regulation_id, id.descr as regulation_descr, 'PT' vers  
from drug_diploma id;