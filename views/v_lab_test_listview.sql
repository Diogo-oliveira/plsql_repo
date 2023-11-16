CREATE OR REPLACE VIEW v_lab_test_listview AS
SELECT DISTINCT lte.id_analysis_req,
                lte.id_analysis_req_det,
                lte.id_ard_parent,
                lte.id_analysis,
                lte.id_sample_type,
                lte.flg_status_req,
                lte.flg_status_det,
                lte.flg_referral,
                lte.flg_time_harvest,
                lte.flg_notes,
                lte.notes,
                dbms_lob.substr(lte.notes_patient, 3800) notes_patient,
                lte.notes_technician,
                --dbc.code_desc,
                --dbc.flg_status,
                lte.flg_doc,
                lte.flg_req_origin_module,
                lte.flg_relevant,
                lte.flg_priority,
                lte.dt_req,
                lte.dt_pend_req,
                lte.dt_target,
                lte.status_str,
                lte.status_msg,
                lte.status_icon,
                lte.status_flg,
                lte.id_analysis_codification,
                lte.id_task_dependency,
                lte.id_exec_institution,
                e.id_episode,
                lte.id_episode_origin,
                e.id_epis_type,
                e.id_visit,
                lte.id_patient,
                nvl(lte.id_prof_order, lte.id_prof_writes) id_prof_order,
                lte.flg_status_harvest
  FROM lab_tests_ea lte,
       episode e/*,
       (SELECT dbc.code, dbc.code_desc, dbc.flg_status, el.activity_key
          FROM alert_adtcod.dbc_selected_activities dsa, alert_adtcod.dbc dbc, alert_adtcod.episode_lines el
         WHERE dsa.id_episode_line = el.id_episode_lines
           AND dsa.id_dbc = dbc.id_dbc
           AND el.activity_entity = 'VAnalysisRequestDetail') dbc*/
 WHERE lte.id_patient = sys_context('ALERT_CONTEXT', 'i_patient')
   AND ((lte.id_episode = e.id_episode AND lte.id_episode = sys_context('ALERT_CONTEXT', 'i_episode')) OR
       (lte.id_episode_origin = e.id_episode AND lte.id_episode_origin = sys_context('ALERT_CONTEXT', 'i_episode')) OR
       (nvl(lte.id_episode, lte.id_episode_origin) = e.id_episode AND nvl(lte.id_episode, 0) != sys_context('ALERT_CONTEXT', 'i_episode') AND
       nvl(lte.id_episode_origin, 0) != sys_context('ALERT_CONTEXT', 'i_episode')))
   AND lte.flg_time_harvest != 'R'
   AND lte.flg_status_det != 'DF'
   AND (lte.flg_orig_analysis IS NULL OR lte.flg_orig_analysis NOT IN ('M', 'O', 'S'));
--   AND lte.id_analysis_req_det = dbc.activity_key(+);
