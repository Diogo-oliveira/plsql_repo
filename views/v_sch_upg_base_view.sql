-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
CREATE OR REPLACE VIEW V_SCH_UPG_BASE_VIEW AS
SELECT t.*, 
        (SELECT cast(collect(sr.id_professional) AS table_number24) FROM sch_resource sr WHERE sr.id_schedule = t.id_schedule) prof_ids,
        (SELECT cast(collect(sg.id_patient) AS table_number24) FROM sch_group sg WHERE sg.id_schedule = t.id_schedule) patient_ids
FROM(
      SELECT s."ID_SCHEDULE",
              s."ID_INSTIT_REQUESTS",
              s."ID_INSTIT_REQUESTED",
              s."ID_DCS_REQUESTS",
              s."ID_DCS_REQUESTED",
              s."ID_PROF_REQUESTS",
              s."ID_PROF_SCHEDULES",
              s."FLG_URGENCY",
              s."FLG_STATUS",
              s."ID_PROF_CANCEL",
              s."SCHEDULE_NOTES",
              s."ID_CANCEL_REASON",
              s."ID_LANG_TRANSLATOR",
              s."ID_SCH_EVENT",
              s."ID_REASON",
              s."ID_ORIGIN",
              s."ID_ROOM",
              s."SCHEDULE_CANCEL_NOTES",
              s."FLG_NOTIFICATION",
              s."FLG_VACANCY",
              s."FLG_SCH_TYPE",
              s."REASON_NOTES",
              s."DT_BEGIN_TSTZ",
              s."DT_CANCEL_TSTZ",
              s."DT_END_TSTZ",
              s."DT_REQUEST_TSTZ",
              s."DT_SCHEDULE_TSTZ",
              s."FLG_SCHEDULE_VIA",
              s."ID_SCH_CONSULT_VACANCY",
              s."FLG_NOTIFICATION_VIA",
              s."ID_PROF_NOTIFICATION",
              s."DT_NOTIFICATION_TSTZ",
              s."FLG_REQUEST_TYPE",
              s."CREATE_USER",
              s."CREATE_TIME",
              s."CREATE_INSTITUTION",
              dcs.id_department, 
              dcs.id_clinical_service, 
              d.id_institution, 
              cs.id_content id_content_clinical_service,
              NVL(s.dt_end_tstz, 
                   NVL((SELECT NVL(dt_end_tstz, s.dt_begin_tstz + interval '30' minute) FROM sch_consult_vacancy WHERE id_sch_consult_vacancy = s.id_sch_consult_vacancy),
                       (s.dt_begin_tstz + interval '30' minute))) best_dt_end,
              s.flg_reason_type
       FROM alert.schedule s
         JOIN alert.dep_clin_serv dcs ON s.id_dcs_requested = dcs.id_dep_clin_serv
         JOIN alert.department d ON dcs.id_department = d.id_department
         JOIN alert.clinical_service cs ON dcs.id_clinical_service = cs.id_clinical_service
       WHERE s.flg_status IN ('A', 'T')
         AND NOT EXISTS (SELECT 1 FROM alert.sch_api_map_ids m WHERE m.id_schedule_pfh = s.id_schedule)
         AND s.id_schedule <> -1
         AND s.flg_sch_type <> 'PM'
      UNION
        SELECT s."ID_SCHEDULE",
          s."ID_INSTIT_REQUESTS",
          s."ID_INSTIT_REQUESTED",
          s."ID_DCS_REQUESTS",
          s."ID_DCS_REQUESTED",
          s."ID_PROF_REQUESTS",
          s."ID_PROF_SCHEDULES",
          s."FLG_URGENCY",
          s."FLG_STATUS",
          s."ID_PROF_CANCEL",
          s."SCHEDULE_NOTES",
          s."ID_CANCEL_REASON",
          s."ID_LANG_TRANSLATOR",
          s."ID_SCH_EVENT",
          s."ID_REASON",
          s."ID_ORIGIN",
          s."ID_ROOM",
          s."SCHEDULE_CANCEL_NOTES",
          s."FLG_NOTIFICATION",
          s."FLG_VACANCY",
          s."FLG_SCH_TYPE",
          s."REASON_NOTES",
          s."DT_BEGIN_TSTZ",
          s."DT_CANCEL_TSTZ",
          s."DT_END_TSTZ",
          s."DT_REQUEST_TSTZ",
          s."DT_SCHEDULE_TSTZ",
          s."FLG_SCHEDULE_VIA",
          s."ID_SCH_CONSULT_VACANCY",
          s."FLG_NOTIFICATION_VIA",
          s."ID_PROF_NOTIFICATION",
          s."DT_NOTIFICATION_TSTZ",
          s."FLG_REQUEST_TYPE",
          s."CREATE_USER",
          s."CREATE_TIME",
          s."CREATE_INSTITUTION",
          dcs.id_department, 
          dcs.id_clinical_service, 
          d.id_institution, 
          cs.id_content id_content_clinical_service,
          NVL(s.dt_end_tstz,
             NVL((SELECT NVL(dt_end_tstz, s.dt_begin_tstz + interval '30' minute) FROM sch_consult_vacancy WHERE id_sch_consult_vacancy = s.id_sch_consult_vacancy),
                 (s.dt_begin_tstz + interval '30' minute))) best_dt_end,
          s.flg_reason_type
       FROM alert.schedule s
             LEFT JOIN alert.schedule s2 ON s.id_Schedule = s2.id_schedule_ref
             JOIN alert.dep_clin_serv dcs ON s.id_dcs_requested = dcs.id_dep_clin_serv
             JOIN alert.department d ON dcs.id_department = d.id_department
             JOIN alert.clinical_service cs ON dcs.id_clinical_service = cs.id_clinical_service
       WHERE s.flg_status = 'C'
         AND NOT EXISTS (SELECT 1 FROM alert.sch_api_map_ids m WHERE m.id_schedule_pfh = s.id_schedule)
         AND s.id_schedule <> -1
         AND s.id_schedule_ref IS NULL
         AND s2.id_schedule_ref IS NULL
         AND s.flg_sch_type <> 'PM'
     ) t;
-- CHANGE END: Telmo