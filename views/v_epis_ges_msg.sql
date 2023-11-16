CREATE OR REPLACE VIEW V_EPIS_GES_MSG AS
SELECT egm.id_epis_ges_msg,
       egm.id_episode,
       d.id_diagnosis,
       d.code_icd,
       d.flg_type,
       d.code_diagnosis,
       d.mdm_coding,
       d.id_content,
       egm.id_epis_diagnosis id_context,
       egm.flg_origin flg_context,
       ed.flg_status flg_context_status,
       ed.flg_type flg_context_type,
       ed.flg_final_type flg_context_final_type,
       CASE ed.flg_status
           WHEN 'A' THEN -- This state is not used
            NULL
           WHEN 'D' THEN
            ed.id_professional_diag
           WHEN 'C' THEN
            ed.id_professional_cancel
           WHEN 'F' THEN
            ed.id_prof_confirmed
           WHEN 'R' THEN
            ed.id_prof_rulled_out
           WHEN 'B' THEN
            ed.id_prof_base
           ELSE
            NULL
       END id_context_prof_create,
       CASE ed.flg_status
           WHEN 'A' THEN -- This state is not used
            NULL
           WHEN 'D' THEN
            ed.dt_epis_diagnosis_tstz
           WHEN 'C' THEN
            ed.dt_cancel_tstz
           WHEN 'F' THEN
            ed.dt_confirmed_tstz
           WHEN 'R' THEN
            ed.dt_rulled_out_tstz
           WHEN 'B' THEN
            ed.dt_base_tstz
           ELSE
            NULL
       END dt_context_create
  FROM epis_ges_msg egm
  JOIN epis_diagnosis ed ON ed.id_epis_diagnosis = egm.id_epis_diagnosis
  JOIN diagnosis d ON d.id_diagnosis = ed.id_diagnosis
 WHERE egm.flg_status = 'A'
   AND egm.flg_msg_status = 'S'
UNION ALL
SELECT egm.id_epis_ges_msg,
       egm.id_episode,
       d.id_diagnosis,
       d.code_icd,
       d.flg_type,
       d.code_diagnosis,
       d.mdm_coding,
       d.id_content,
       egm.id_pat_history_diagnosis id_context,
       egm.flg_origin flg_context,
       phd.flg_status flg_context_status,
       phd.flg_type flg_context_type,
       NULL flg_context_final_type,
       CASE phd.flg_status
           WHEN 'C' THEN
            phd.id_prof_cancel
           ELSE
            phd.id_professional
       END id_context_prof_create,
       CASE phd.flg_status
           WHEN 'C' THEN
            phd.dt_cancel
           ELSE
            phd.dt_pat_history_diagnosis_tstz
       END dt_context_create
  FROM epis_ges_msg egm
  JOIN pat_history_diagnosis phd ON phd.id_pat_history_diagnosis = egm.id_pat_history_diagnosis
                                AND phd.flg_recent_diag = 'Y'
  JOIN diagnosis d ON d.id_diagnosis = phd.id_diagnosis
 WHERE egm.flg_status = 'A'
   AND egm.flg_msg_status = 'S';