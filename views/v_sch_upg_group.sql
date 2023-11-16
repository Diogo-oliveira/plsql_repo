-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
CREATE OR REPLACE VIEW v_sch_upg_group ( 
    id_schedule, 
    id_instit_requests, 
    id_instit_requested, 
    id_dcs_requests, 
    id_dcs_requested, 
    id_prof_requests, 
    id_prof_schedules, 
    flg_urgency, 
    flg_status, 
    id_prof_cancel, 
    schedule_notes, 
    id_cancel_reason, 
    id_lang_translator, 
    id_lang_preferred, 
    id_sch_event, 
    id_reason, 
    id_origin, 
    id_room, 
    schedule_cancel_notes, 
    flg_notification, 
    id_schedule_ref, 
    flg_vacancy, 
    flg_sch_type, 
    reason_notes, 
    dt_begin_tstz, 
    dt_cancel_tstz, 
    dt_end_tstz, 
    dt_request_tstz, 
    dt_schedule_tstz, 
    flg_schedule_via, 
    flg_instructions, 
    id_sch_consult_vacancy, 
    flg_notification_via, 
    id_prof_notification, 
    dt_notification_tstz, 
    flg_request_type, 
    id_episode, 
    id_schedule_recursion, 
    create_user, 
    create_time, 
    create_institution, 
    update_user, 
    update_time, 
    update_institution, 
    id_sch_combi_detail, 
    flg_present, 
    id_multidisc, 
    id_department, 
    id_clinical_service, 
    id_institution, 
    id_content_clinical_service, 
    id_group, 
    id_patient, 
    id_cs_requests, 
    id_content_cs_requests, 
    id_inst_cs_requests, 
    person_present,
    flg_reason_type
  ) AS 
  SELECT v."ID_SCHEDULE",v."ID_INSTIT_REQUESTS",v."ID_INSTIT_REQUESTED",v."ID_DCS_REQUESTS",v."ID_DCS_REQUESTED",v."ID_PROF_REQUESTS",v."ID_PROF_SCHEDULES",v."FLG_URGENCY",
  v."FLG_STATUS",v."ID_PROF_CANCEL",v."SCHEDULE_NOTES",v."ID_CANCEL_REASON",v."ID_LANG_TRANSLATOR",v."ID_LANG_PREFERRED",v."ID_SCH_EVENT",v."ID_REASON",v."ID_ORIGIN",v."ID_ROOM",
  v."SCHEDULE_CANCEL_NOTES",v."FLG_NOTIFICATION",v."ID_SCHEDULE_REF",v."FLG_VACANCY",v."FLG_SCH_TYPE",v."REASON_NOTES",v."DT_BEGIN_TSTZ",v."DT_CANCEL_TSTZ",v."DT_END_TSTZ",
  v."DT_REQUEST_TSTZ",v."DT_SCHEDULE_TSTZ",v."FLG_SCHEDULE_VIA",v."FLG_INSTRUCTIONS",v."ID_SCH_CONSULT_VACANCY",v."FLG_NOTIFICATION_VIA",v."ID_PROF_NOTIFICATION",
  v."DT_NOTIFICATION_TSTZ",v."FLG_REQUEST_TYPE",v."ID_EPISODE",v."ID_SCHEDULE_RECURSION",v."CREATE_USER",v."CREATE_TIME",v."CREATE_INSTITUTION",v."UPDATE_USER",v."UPDATE_TIME",
  v."UPDATE_INSTITUTION",v."ID_SCH_COMBI_DETAIL",v."FLG_PRESENT",v."ID_MULTIDISC",v."ID_DEPARTMENT",v."ID_CLINICAL_SERVICE",v."ID_INSTITUTION",v."ID_CONTENT_CLINICAL_SERVICE", 
  sg.id_group, sg.id_patient, cs2.id_clinical_service id_cs_requests, cs2.id_content id_content_cs_requests, d2.id_institution id_inst_cs_requests, v.FLG_REASON_TYPE,
          NVL((SELECT 'Y' 
            FROM epis_info ei JOIN episode e ON ei.id_episode = e.id_episode 
            WHERE ei.id_schedule = v.id_schedule 
              AND nvl(e.flg_ehr, 'ZIP') <> 'E' 
              AND rownum = 1), 'N') person_present 
    FROM v_sch_upg_schedules v JOIN sch_group sg ON v.id_schedule = sg.id_schedule 
      LEFT JOIN alert.dep_clin_serv dcs2 ON v.id_dcs_requests = dcs2.id_dep_clin_serv 
      LEFT JOIN alert.department d2 ON dcs2.id_department = d2.id_department 
      LEFT JOIN alert.clinical_service cs2 ON dcs2.id_clinical_service = cs2.id_clinical_service;
-- CHANGE END: Telmo