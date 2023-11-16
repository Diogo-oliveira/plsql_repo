create or replace view MI_MED_ATC_INTERACTION_PT as 
SELECT distinct xp4.id_drug as id_drug, c.atc AS atcd, d.atc_desc AS atcdescd, 
           a.ddi_codex AS ddi,32000-a.ddi_codex as interddi,
           e.ddi_des  as ddi_desd, e.ddi_sl as ddi_sld, 'PT' as vers
FROM radimgc_gcnseqno_link a, 
ratcgc_atc_gcnseqno_link c, 
ratcd_atc_desc d,
radimma_mstr e,
CHNM_ATC_LNK  xp,
drug_emb xp3,
drug xp4
WHERE a.gcn_seqno = c.gcn_seqno
AND c.atc = d.atc
AND a.ddi_codex= e.ddi_codex
AND xp.code= c.atc  
AND xp3.med_id = xp.med_id
AND xp4.chnm_id = xp3.chnm_id;