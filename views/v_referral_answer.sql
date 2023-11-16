CREATE OR REPLACE VIEW V_REFERRAL_ANSWER AS
SELECT pd.id_external_request id_external_request,
       pd.id_detail           id_detail,
       pd.flg_type            detail_type,
       pd.text                detail_text,
       pd.dt_insert_tstz      dt_insert
  FROM p1_detail pd
 WHERE pd.flg_type IN (13, 14, 15, 16)
   AND pd.flg_status = 'A';
 
COMMENT ON TABLE V_REFERRAL_ANSWER IS 'Referral answer details'
/

COMMENT ON COLUMN V_REFERRAL_ANSWER.ID_EXTERNAL_REQUEST IS 'Referral identifier'
/

COMMENT ON COLUMN V_REFERRAL_ANSWER.ID_DETAIL IS 'Detail identifier'
/

COMMENT ON COLUMN V_REFERRAL_ANSWER.DETAIL_TYPE IS 'Detail type: 13 - Observation summary, 14 - Treatment proposal, 15 - New exams proposal, 16 - Conclusion'
/

COMMENT ON COLUMN V_REFERRAL_ANSWER.DETAIL_TEXT IS 'Detail text'
/

COMMENT ON COLUMN V_REFERRAL_ANSWER.DT_INSERT IS 'Detail creation date'
/


