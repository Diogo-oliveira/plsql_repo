create or replace view ICD9_DXID_PT as
select distinct y.related_DXID as dxid, y.SEARCH_ICD9CM as icd9cm_code,z.ICD9CM_DESC100 as icd9cm_desc, 'PT' as vers
FROM rfmlisr_icd9cm_search y, 
		rfmlinm_icd9cm_name z
WHERE  y. fml_clin_code = '03'
AND y.search_icd9cm = z.icd9cm;