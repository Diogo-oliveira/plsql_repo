create or replace view MI_MED_ATC_INTERACTION_USA as 
SELECT distinct xp.medid as id_drug, c.atc AS atcd, d.atc_desc AS atcdescd, 
					 a.ddi_codex AS ddi,32000-a.ddi_codex as interddi,
					 e.ddi_des  as ddi_desd, e.ddi_sl as ddi_sld, 'USA' as vers
FROM radimgc_gcnseqno_link a, 
ratcgc_atc_gcnseqno_link c, 
ratcd_atc_desc d,
radimma_mstr e,
RMIID_MED xp
WHERE a.gcn_seqno = c.gcn_seqno
AND c.atc = d.atc
AND a.ddi_codex= e.ddi_codex
AND xp.gcn_seqno= a.gcn_seqno;