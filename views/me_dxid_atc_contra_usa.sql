create or replace view ME_DXID_ATC_CONTRA_USA as
select distinct a.DXID,xp.medid as emb_id,B.DDXCN_SN,B.DDXCN_SL, f.atc, f.atc_desc, 'USA' as vers
FROM rfmldx_dxid a,
		rddcmma_contra_mstr b,
		rddcmgc_contra_gcnseqno_link c,
		rgcnseq_gcnseqno_mstr d,
		ratcgc_atc_gcnseqno_link e,
		ratcd_atc_desc f,
    RMIID_MED xp
WHERE a.dxid = b.dxid
AND a.DXID_STATUS = 0 --( 0 - Live , 1 - Replaced,2 - Retired)
AND b.ddxcn = c.ddxcn
AND c.gcn_seqno = d.gcn_seqno
AND d.gcn_seqno = e.gcn_seqno
AND e.atc = f.atc
AND xp.gcn_seqno = c.gcn_seqno;