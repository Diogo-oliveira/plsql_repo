create or replace view MI_DXID_ATC_CONTRA_PT as
select distinct a.DXID,xp4.id_drug as id_drug,B.DDXCN_SN,B.DDXCN_SL,f.atc, f.atc_desc, 'PT' as vers
FROM rfmldx_dxid a,
    rddcmma_contra_mstr b,
    rddcmgc_contra_gcnseqno_link c,
    rgcnseq_gcnseqno_mstr d,
    ratcgc_atc_gcnseqno_link e,
    ratcd_atc_desc f,
    CHNM_ATC_LNK  xp,
    drug_emb xp3,
    drug xp4
WHERE a.dxid = b.dxid
AND a.DXID_STATUS = 0 --( 0 - Live , 1 - Replaced,2 - Retired)
AND b.ddxcn = c.ddxcn
AND c.gcn_seqno = d.gcn_seqno
AND d.gcn_seqno = e.gcn_seqno
AND e.atc = f.atc
AND xp.code = f.atc
AND xp3.med_id = xp.med_id
AND xp4.chnm_id = xp3.chnm_id;