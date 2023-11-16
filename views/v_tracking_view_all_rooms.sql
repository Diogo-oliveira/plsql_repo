CREATE OR REPLACE VIEW v_tracking_view_all_rooms AS
SELECT v.*
  FROM v_tracking_view_all_pat v
UNION ALL
--empty rooms
SELECT NULL id_episode,
       NULL id_visit,
       NULL id_patient,
       NULL gender,
       NULL dt_birth,
       NULL dt_deceased,
       NULL age,
       --
       NULL              dt_begin_tstz,
       NULL              id_professional,
       dt.id_institution,
       NULL              dt_first_obs_tstz,
       NULL              id_epis_type,
       NULL              id_department,
       NULL              id_software,
       NULL              id_disch_reas_dest,
       NULL              flg_dsch_status,
       NULL              flg_has_stripes,
       NULL              id_nurse_resp,
       NULL              id_prof_resp,
       NULL              id_fast_track,
       NULL              id_triage_color,
       NULL              rowid_tbea,
       NULL              transp_delay,
       NULL              transp_ongoing,
       NULL              dt_begin,
       --
       NULL                     desc_bed,
       NULL                     code_bed,
       r.desc_room_abbreviation,
       r.code_abbreviation,
       r.code_room,
       r.desc_room,
       NULL id_room,
       tc.color                 triage_acuity,
       tc.color                 triage_color_text,
       NULL                     triage_rank_acuity,
       NULL                     triage_flg_letter,
       --
       NULL flg_interv_prescription,
       NULL flg_nurse_activity_req,
       NULL monitorization,
       NULL drug_presc
  FROM software_dept sd
  JOIN department dt
    ON dt.id_dept = sd.id_dept
  JOIN room r
    ON (r.id_department = dt.id_department AND r.flg_available = 'Y')
  JOIN triage_color tc
    ON (tc.flg_type = 'S' AND tc.flg_available = 'Y' AND
       tc.id_triage_type IN
       (SELECT *
           FROM TABLE(pk_edis_triage.tf_get_inst_triag_types(sys_context('ALERT_CONTEXT', 'i_id_institution')))))
 WHERE NOT EXISTS (SELECT 1
          FROM tracking_board_ea tbea
         WHERE tbea.id_room = r.id_room)
   AND sd.id_software = 8;
