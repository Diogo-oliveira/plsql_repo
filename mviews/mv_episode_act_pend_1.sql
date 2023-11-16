
drop materialized view mv_episode_act_pend_1;

create materialized view mv_episode_act_pend_1
TABLESPACE TABLE_L
build DEFERRED
refresh force on demand
disable query rewrite
as
--visit
SELECT v.id_visit,
       v.dt_begin_tstz dt_begin_tstz_v,
       v.dt_end_tstz dt_end_tstz_v,
       v.flg_status flg_status_v,
       id_external_cause,
       v.id_patient,
       v.id_origin,
       v.id_institution,
       v.barcode barcode_v,
       --episode
       e.id_episode,
       id_clinical_service,
       e.dt_begin_tstz dt_begin_tstz_e,
       e.dt_end_tstz dt_end_tstz_e,
       e.flg_status flg_status_e,
       e.id_epis_type,
       e.companion companion_e,
       e.barcode barcode_e,
       id_prof_cancel,
       dt_cancel_tstz,
       flg_type,
       id_prev_episode,
			 id_fast_track,
       flg_ehr,
       --epis_info
       id_bed,
       ei.id_room,
       ei.id_professional,
       norton,
       flg_hydric,
       flg_wound,
       ei.companion companion_ei,
       flg_unknown,
       desc_info,
       id_schedule,
       id_first_nurse_resp,
       ei.flg_status flg_status_ei,
       id_dep_clin_serv,
       id_first_dep_clin_serv,
			 e.id_department,
       dt_first_obs_tstz,
       dt_first_nurse_obs_tstz,
       dt_first_inst_obs_tstz,
			 triage_acuity,
			 triage_color_text,
			 triage_rank_acuity,
			 triage_flg_letter,
			 id_triage_color,
       --epis_type
       intern_name_epis_type,
       code_epis_type,
       ety.flg_available flg_available_ety,
       ety.rank rank_ety,
       id_software,
       --rowids
       e.ROWID   episode_rowid,
       ei.ROWID  epis_info_rowid,
       v.ROWID   visit_rowid,
       ety.ROWID epis_type_rowid
  FROM episode e, epis_info ei, visit v, epis_type ety
 WHERE e.id_episode = ei.id_episode
   AND v.id_visit = e.id_visit
   AND ety.id_epis_type = e.id_epis_type
   AND e.flg_status IN ('A', 'P');
   
--CHANGE END

comment on materialized view mv_episode_act_pend_1 is 'Materialized view para conter episódios activos e pendentes';

--chave primária
alter table mv_episode_act_pend_1 add constraint mv_ep_ap_1_pk primary key (id_episode);
--indices dos rowids para refresh
create unique index mv_ep_ap_1_e_rid_uidx on mv_episode_act_pend_1(episode_rowid);
create unique index mv_ep_ap_1_ei_rid_uidx on mv_episode_act_pend_1(epis_info_rowid);
create index mv_ep_ap_1_v_rid_uidx on mv_episode_act_pend_1(visit_rowid);
create index mv_ep_ap_1_ety_rid_uidx on mv_episode_act_pend_1(epis_type_rowid);
--chaves estrangeiras
create index mv_ep_ap_1_pat_fk_idx on mv_episode_act_pend_1(id_patient);
create index mv_ep_ap_1_vis_fk_idx on mv_episode_act_pend_1(id_visit);
create index mv_ep_ap_1_ext_cause_fk on mv_episode_act_pend_1(id_external_cause);
create index mv_ep_ap_1_origin_fk on mv_episode_act_pend_1(id_origin);
create index mv_ep_ap_1_inst_fk on mv_episode_act_pend_1(id_institution);
create index mv_ep_ap_1_software_fk on mv_episode_act_pend_1(id_software);
create index mv_ep_ap_1_clin_serv_fk on mv_episode_act_pend_1(id_clinical_service);
create index mv_ep_ap_1_epis_type_fk on mv_episode_act_pend_1(id_epis_type);
create index mv_ep_ap_1_prof_ccl_fk on mv_episode_act_pend_1(id_prof_cancel);
create index mv_ep_ap_1_prev_epis_fk on mv_episode_act_pend_1(id_prev_episode);
create index mv_ep_ap_1_bed_fk on mv_episode_act_pend_1(id_bed);
create index mv_ep_ap_1_room_fk on mv_episode_act_pend_1(id_room);
create index mv_ep_ap_1_prof_fk on mv_episode_act_pend_1(id_professional);
create index mv_ep_ap_1_schedule_fk on mv_episode_act_pend_1(id_schedule);
create index mv_ep_ap_1_1st_nurse_fk on mv_episode_act_pend_1(id_first_nurse_resp);
create index mv_ep_ap_1_dep_cs_fk on mv_episode_act_pend_1(id_dep_clin_serv);
create index mv_ep_ap_1_1st_dcs_fk on mv_episode_act_pend_1(id_first_dep_clin_serv);
create index mv_ep_ap_1_ft_fk on mv_episode_act_pend_1(id_fast_track);
--chaves multiplas
create index mv_ep_ap_1_sft_rom_idx on mv_episode_act_pend_1(id_software,id_room);
create index mv_ep_ap_1_ins_sft_idx on mv_episode_act_pend_1(id_institution,id_software);
create index mv_ep_ap_1_inssftrom_idx on mv_episode_act_pend_1(id_institution,id_software,id_room);
create index mv_ep_ap_1_inssftbed_idx on mv_episode_act_pend_1(id_institution,id_software,id_bed);
create index mv_ep_ap_1_inssftdoc_idx on mv_episode_act_pend_1(id_institution,id_software,id_professional);
create index mv_ep_ap_1_inssftnrs_idx on mv_episode_act_pend_1(id_institution,id_software,id_first_nurse_resp);

--sinónimo
create or replace synonym mv_episode_act_pend for mv_episode_act_pend_1; 

ALTER INDEX MV_EP_AP_1_BED_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_CLIN_SERV_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_DEP_CS_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_EI_RID_UIDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_EPIS_TYPE_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_E_RID_UIDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_ETY_RID_UIDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_EXT_CAUSE_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INSSFTDOC_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INSSFTDOC_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INSSFTDOC_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INS_SFT_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INS_SFT_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INSSFTNRS_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INSSFTNRS_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INSSFTNRS_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INSSFTROM_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INSSFTROM_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INSSFTROM_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_INST_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_ORIGIN_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_PAT_FK_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_PK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_PREV_EPIS_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_PROF_CCL_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_PROF_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_ROOM_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_SCHEDULE_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_SFT_ROM_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_SFT_ROM_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_SOFTWARE_FK REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_VIS_FK_IDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_V_RID_UIDX REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_1ST_DCS_FK REBUILD TABLESPACE index_L;
ALTER INDEX mv_ep_ap_1_ft_fk REBUILD TABLESPACE index_L;
ALTER INDEX MV_EP_AP_1_1ST_NURSE_FK REBUILD TABLESPACE index_L;

DECLARE
    l_staleness user_mviews.staleness%TYPE;
    l_mv user_mviews.mview_name%type := 'MV_EPISODE_ACT_PEND_2';
BEGIN
    SELECT staleness
      INTO l_staleness
      FROM user_mviews
     WHERE mview_name = upper(l_mv);
    IF l_staleness = 'UNUSABLE'
    THEN
        dbms_output.put_line('Refreshing '||l_mv||'...');
        dbms_mview.refresh(list => l_mv, method => '?');
    END IF;
END;
/

-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 15-01-2009
-- CHANGE REASON: [ALERT-13706] Indexes for TODO List performance improvements
CREATE INDEX MV_EP_AP_1_INS_SFT_DTBGN_IDX ON MV_EPISODE_ACT_PEND_1(id_institution, id_software, dt_begin_tstz_e);
alter index MV_EP_AP_1_INS_SFT_DTBGN_IDX rebuild tablespace INDEX_L;
-- CHANGE END
