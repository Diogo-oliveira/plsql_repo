create or replace view ME_DXID_ATC_CONTRA_PT as
select distinct a.DXID,xp2.emb_id as emb_id,B.DDXCN_SN,B.DDXCN_SL,f.atc, f.atc_desc, 'PT' as vers
FROM rfmldx_dxid a,
		rddcmma_contra_mstr b,
		rddcmgc_contra_gcnseqno_link c,
		rgcnseq_gcnseqno_mstr d,
		ratcgc_atc_gcnseqno_link e,
		ratcd_atc_desc f,
		INF_ATC_LNK  xp,
		INF_EMB xp2
WHERE a.dxid = b.dxid
AND a.DXID_STATUS = 0 --( 0 - Live , 1 - Replaced,2 - Retired)
AND b.ddxcn = c.ddxcn
AND c.gcn_seqno = d.gcn_seqno
AND d.gcn_seqno = e.gcn_seqno
AND e.atc = f.atc
AND xp2.med_id = xp.med_id
AND xp.code = f.atc;