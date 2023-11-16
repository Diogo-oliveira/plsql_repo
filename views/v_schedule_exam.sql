CREATE OR REPLACE VIEW V_SCHEDULE_EXAM AS
SELECT s.id_schedule           id_schedule, -- Schedule identifier
       se.id_schedule_exam id_schedule_exam, -- Schedule exam identifier
       s.id_schedule_ref       id_schedule_ref, -- Schedule reference identification. It can be used to store a cancelled schedule id used in the reschedule functionality
       s.id_instit_requests    id_instit_requests, -- Institution that requested the schedule
       s.id_instit_requested   id_instit_requested, -- Institution that is requested for the schedule
       s.id_dcs_requests       id_dcs_requests, -- Department-Clinical Service that requested the schedule
       s.id_dcs_requested      id_dcs_requested, -- Department-Clinical Service that is requested for the schedule
       s.id_prof_requests      id_prof_requests, -- Professional that requested the schedule
       s.id_prof_schedules     id_prof_schedules, -- Professional that created the schedule
       s.id_prof_cancel        id_prof_cancel, -- Professional that cancelled the schedule
       s.id_cancel_reason      id_cancel_reason, -- Reason for cancellation
       s.id_lang_translator    id_lang_translator, -- Translator's language
       s.id_lang_preferred     id_lang_preferred, -- Preferred language
       s.id_sch_event          id_sch_event, -- Event identifier
       s.id_reason             id_reason, -- Reason identifier
       s.id_origin             id_origin, -- Origin identifier
       s.id_room               id_room, -- Room identifier
       se.id_exam              id_exam, -- Exam identifier
       se.id_exam_req              id_exam_req, -- Exam identifier
       s.dt_request_tstz         dt_request, -- Date when the schedule was requested
       s.dt_schedule_tstz        dt_schedule, -- Date when the schedule was created
       s.dt_begin_tstz           dt_begin, -- Begin date for the schedule
       s.dt_end_tstz             dt_end, -- End date for the schedule
       s.dt_cancel_tstz          dt_cancel, -- Date when the schedule was cancelled
       s.dt_request_tstz         dt_request_tstz, -- Date when the schedule was requested
       s.dt_schedule_tstz        dt_schedule_tstz, -- Date when the schedule was created
       s.dt_begin_tstz           dt_begin_tstz, -- Begin date for the schedule
       s.dt_end_tstz             dt_end_tstz, -- End date for the schedule
       s.dt_cancel_tstz          dt_cancel_tstz, -- Date when the schedule was cancelled
       s.flg_status            flg_status, -- Schedule status 'A' (scheduled), 'P' (pending)
       s.flg_urgency           flg_urgency, -- Urgency flag: 'Y' or 'N'
       s.flg_notification      flg_notification, -- Whether or not a notification was already sent to the patient. Possible values : 'N'otified or 'P'ending notification
       s.flg_vacancy           flg_vacancy, -- Type of vacancy occupied: 'R' routine, 'U' urgent, 'V' unplanned
       s.flg_sch_type          flg_sch_type, -- Type of schedule: exam (E), analysis (A), outpatient (C), surgery room (S)
       se.flg_preparation      flg_preparation, -- Whether or not the exam requires preparation instructions. 'Y' or 'N'
       s.schedule_notes        schedule_notes, -- Schedule notes
       s.schedule_cancel_notes schedule_cancel_notes, -- Schedule cancellation notes.
       s.id_sch_consult_vacancy id_sch_consult_vacancy, -- vacancy id. Can be null
       s.id_schedule_recursion id_schedule_recursion,
       s.id_sch_combi_detail   id_sch_combi_detail
  FROM schedule      s,
       schedule_exam se
 WHERE s.id_schedule = se.id_schedule;
/
