create or replace view MI_JUSTIFICATION_PT as 
select id_drug_justification as id_justification, pk_translation.get_translation(1, code_drug_justification) justification_descr, 'PT' vers
from drug_justification;