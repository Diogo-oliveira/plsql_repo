CREATE OR REPLACE VIEW V_TECH_IMG_SCHED_REQ_01 AS
SELECT t.SEL_TYPE,
       t.EVENT_TYPE,
       t.ID_EVENT_TYPE,
       t.ID_PATIENT,
       t.AGE,
       t.NUM_CLIN_RECORD,
       t.ID_EPISODE,
       t.ID_DEPT,
       t.ID_CLINICAL_SERVICE,
       t.ID_PROFESSIONAL,
       t.ID_EXAM_CAT,
       t.ID_EXAM,
       t.DT_SCHEDULE_TSTZ,
       t.NOTES,
       t.DT_BEGIN_TSTZ,
       t.ID_EXAM_REQ,
       t.ID_EXAM_REQ_DET,
       t.FLG_STATUS_REQ_DET,
       t.DT_REQ_TSTZ,
       t.ID_PROF_REQ,
       t.ID_INSTITUTION,
       t.ID_SCHEDULE,
       t.FLG_REQ_ORIGIN_MODULE,
       t.GENDER,
       t.NAME,
       t.ID_ROOM,
       t.COMB_NAME,
       ce.ID_COMBINATION_SPEC,
       ce.id_combination_events,
       ce.rank,
       cs.dt_suggest_begin,
       cs.flg_single_visit
  FROM v_tech_img_sched_req_00 t
  LEFT JOIN combination_events ce
    ON t.id_event_type = ce.id_future_event_type
   AND ce.id_event = t.id_exam_req_det
   AND ce.flg_status = 'A'
  LEFT JOIN combination_spec cs
    ON ce.id_combination_spec = cs.id_combination_spec
   AND cs.flg_status = 'A';
