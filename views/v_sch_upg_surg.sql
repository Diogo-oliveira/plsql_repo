-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
CREATE OR REPLACE VIEW alert.V_SCH_UPG_SURG AS
SELECT v."ID_SCHEDULE",v."ID_INSTIT_REQUESTS",v."ID_INSTIT_REQUESTED",v."ID_DCS_REQUESTS",v."ID_DCS_REQUESTED",v."ID_PROF_REQUESTS",v."ID_PROF_SCHEDULES",v."FLG_URGENCY",
 v."FLG_STATUS",v."ID_PROF_CANCEL",v."SCHEDULE_NOTES",v."ID_CANCEL_REASON",v."ID_LANG_TRANSLATOR",v."ID_SCH_EVENT",v."ID_REASON",v."ID_ORIGIN",v."ID_ROOM",
 v."SCHEDULE_CANCEL_NOTES",v."FLG_NOTIFICATION",v."FLG_VACANCY",v."FLG_SCH_TYPE",v."REASON_NOTES",v."DT_BEGIN_TSTZ",v."DT_CANCEL_TSTZ",v."DT_END_TSTZ",v."DT_REQUEST_TSTZ",
 v."DT_SCHEDULE_TSTZ",v."FLG_SCHEDULE_VIA",v."ID_SCH_CONSULT_VACANCY",v."FLG_NOTIFICATION_VIA",v."ID_PROF_NOTIFICATION",v."DT_NOTIFICATION_TSTZ",v."FLG_REQUEST_TYPE",
 v."CREATE_USER",v."CREATE_TIME",v."CREATE_INSTITUTION",v."ID_DEPARTMENT",v."ID_CLINICAL_SERVICE",v."ID_INSTITUTION",v."ID_CONTENT_CLINICAL_SERVICE",v."BEST_DT_END",v."PROF_IDS",
 v."PATIENT_IDS", si.id_content id_content_surg_proc, si.id_intervention id_sr_intervention, we.id_waiting_list external_id, 'W' req_flg_type,sei.id_episode_context, sr.id_patient, v.FLG_REASON_TYPE
FROM V_SCH_UPG_BASE_VIEW v
  LEFT JOIN schedule_sr sr ON v.id_schedule = sr.id_schedule -- safe join - one-to-one
  LEFT JOIN sr_epis_interv sei ON sr.id_episode = sei.id_episode_context
  LEFT JOIN intervention si ON sei.id_sr_intervention = si.id_intervention
  LEFT JOIN wtl_epis we ON v.id_schedule = we.id_schedule AND we.id_epis_type = 4 AND we.flg_status = 'S' -- safe join - one-to-one
WHERE v.FLG_SCH_TYPE = 'S';
-- CHANGE END: Telmo
