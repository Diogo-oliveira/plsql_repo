create or replace view ME_MED_ATC_INTERACTION_PT as 
SELECT distinct xp2.emb_id as emb_id, c.atc AS atcd, d.atc_desc AS atcdescd, 
					 a.ddi_codex AS ddi,32000-a.ddi_codex as interddi,
					 e.ddi_des  as ddi_desd, e.ddi_sl as ddi_sld, 'PT' as vers
FROM radimgc_gcnseqno_link a, 
ratcgc_atc_gcnseqno_link c, 
ratcd_atc_desc d,
radimma_mstr e,
INF_ATC_LNK  xp,
INF_EMB xp2
WHERE a.gcn_seqno = c.gcn_seqno
AND c.atc = d.atc
AND a.ddi_codex= e.ddi_codex
AND xp.code= c.atc	
AND xp2.med_id = xp.med_id;