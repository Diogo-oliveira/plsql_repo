create or replace view v_all_pat_bab_aux1 as
select 
bab.ID_BMNG_ALLOCATION_BED,bab.ID_EPISODE,bab.ID_PATIENT,bab.ID_BED,bab.ALLOCATION_NOTES,bab.ID_ROOM,bab.ID_PROF_CREATION,bab.DT_CREATION,bab.ID_PROF_RELEASE,bab.DT_RELEASE,bab.FLG_OUTDATED,bab.CREATE_USER,bab.CREATE_TIME,bab.CREATE_INSTITUTION,bab.UPDATE_USER,bab.UPDATE_TIME,bab.UPDATE_INSTITUTION,bab.ID_EPIS_NCH
    from bmng_allocation_bed bab
    JOIN bed b ON b.id_bed = bab.id_bed
    JOIN room r ON r.id_room = b.id_room
    JOIN department d1 ON d1.id_department = r.id_department
    JOIN department d2 ON d2.id_department = d1.id_department
    JOIN dep_clin_serv dcs2 ON dcs2.id_department = d2.id_department
    JOIN prof_dep_clin_serv pdcs ON pdcs.id_dep_clin_serv = dcs2.id_dep_clin_serv
    where pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_id_prof')
    AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution')
    AND pdcs.flg_default = 'Y'
	;
