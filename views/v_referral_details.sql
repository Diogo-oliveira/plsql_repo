CREATE OR REPLACE VIEW V_REFERRAL_DETAILS AS
SELECT pd.id_external_request, pd.id_detail, pd.flg_type detail_type, pd.text detail_text, pd.dt_insert_tstz DT_INSERT
  FROM p1_detail pd
 WHERE pd.flg_type IN ('0', '1', '2', '3', '4', '5', '6')
   AND pd.flg_status = 'A'
UNION ALL
SELECT ptd.id_external_request,
       NULL id_detail,
       50 detail_type,
       pk_translation.get_translation(1, pt.code_task) detail_text,
       ptd.dt_inserted_tstz dt_insert
  FROM p1_task_done ptd
  JOIN p1_task pt ON pt.id_task = ptd.id_task
 WHERE ptd.flg_type = 'C';
 
COMMENT ON TABLE V_REFERRAL_DETAILS IS 'Referral clinical data'
/

COMMENT ON COLUMN V_REFERRAL_DETAILS.ID_EXTERNAL_REQUEST IS 'Referral identifier'
/

COMMENT ON COLUMN V_REFERRAL_DETAILS.ID_DETAIL IS 'Detail identifier'
/

COMMENT ON COLUMN V_REFERRAL_DETAILS.DETAIL_TYPE IS 'Detail type: 0 - Reason, 1 - Symptomatology, 2 - Progress, 3 - History, 4 - Family history, 5 - Objective exam, 6 - Diagnostic exams, 50- appointment task type'
/

COMMENT ON COLUMN V_REFERRAL_DETAILS.DETAIL_TEXT IS 'Detail text'
/

COMMENT ON COLUMN V_REFERRAL_DETAILS.DT_INSERT IS 'Creation date'
/
