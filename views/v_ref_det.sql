-- CHANGED BY: João Almeida
-- CHANGED DATE: 2009-SEP-29
-- CHANGED REASON: ALERT-46872
CREATE OR REPLACE VIEW V_REF_DET AS
SELECT pd.id_external_request, pd.id_detail, pd.flg_type, pd.text
  FROM p1_detail pd
 WHERE pd.flg_type in ('0','1','2','3','4','5','6')
 AND pd.flg_status = 'A';
-- CHANGE END: João Almeida
