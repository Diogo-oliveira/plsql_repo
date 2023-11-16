CREATE OR REPLACE view v_episode_act_pend AS
    SELECT gea."ID_VISIT",
           gea."ID_PATIENT",
           gea."ID_INSTITUTION",
           gea."ID_EPISODE",
           gea."ID_CLINICAL_SERVICE",
           gea.dt_begin_tstz"DT_BEGIN_TSTZ_E",
           gea.dt_end_tstz"DT_END_TSTZ_E",
           gea.episode_flg_status"FLG_STATUS_E",
           gea."ID_EPIS_TYPE",
           gea.episode_companion "COMPANION_E",
           gea.barcode"BARCODE_E",
           gea."ID_PROF_CANCEL",
           gea."DT_CANCEL_TSTZ",
           gea."FLG_TYPE",
           gea."ID_PREV_EPISODE",
           gea."ID_FAST_TRACK",
           gea."FLG_EHR",
           gea."ID_BED",
           gea."ID_ROOM",
           gea."ID_PROFESSIONAL",
           gea."NORTON",
           gea."FLG_HYDRIC",
           gea."FLG_WOUND",
           gea.epis_info_companion "COMPANION_EI",
           gea."FLG_UNKNOWN",
           gea."DESC_INFO",
           gea."ID_SCHEDULE",
           gea."ID_FIRST_NURSE_RESP",
           gea.epis_info_flg_status "FLG_STATUS_EI",
           gea."ID_DEP_CLIN_SERV",
           gea."ID_FIRST_DEP_CLIN_SERV",
					 gea."ID_DEPARTMENT",
           gea."ID_SOFTWARE",
		 	pk_episode.get_epis_dt_first_obs(gea.id_episode, gea.dt_first_obs_tstz, gea.flg_has_stripes) "DT_FIRST_OBS_TSTZ",
           gea."DT_FIRST_NURSE_OBS_TSTZ" dt_first_nurse_obs_tstz,
           gea."DT_FIRST_INST_OBS_TSTZ" dt_first_inst_obs_tstz,
					 gea.id_triage_color,
           gea.triage_acuity,
           gea.triage_color_text,
           gea.triage_rank_acuity,
					 gea.triage_flg_letter
      FROM grids_ea gea
     WHERE gea.episode_flg_status IN ('A', 'P')
       AND gea.flg_ehr != 'E'
          --Possible values of id_announced_arrival: -1 - episode has no associated announced_arrival;
          --                                         NULL - there is one associated announced_arrival but it's not to be displayed
          --                                         id_announced_arrival
       AND gea.id_announced_arrival IS NOT NULL;
/
