-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
CREATE OR REPLACE VIEW V_SCH_UPG_APPS AS
SELECT v.*, a.id_appointment id_content_app, cr.id_consult_req external_id, 'R' req_flg_type
FROM V_SCH_UPG_BASE_VIEW v
  LEFT JOIN alert.appointment a ON a.id_clinical_service = v.id_clinical_service AND a.id_sch_event = v.id_sch_event
  LEFT JOIN consult_req cr ON v.id_schedule = cr.id_schedule -- safe join - one-to-one
WHERE v.FLG_SCH_TYPE IN ('C', 'N', 'U', 'AS');
--CHANGE END: Telmo
