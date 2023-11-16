-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
CREATE OR REPLACE VIEW V_SCHEDULE_OUTP AS
SELECT s.id_schedule           id_schedule, -- Schedule identifier
        so.id_schedule_outp     id_schedule_outp, -- Schedule Outp identifier
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
        so.id_software          id_software, -- Software identifier
        so.id_epis_type         id_epis_type, -- Episode type identifier
        s.dt_request_tstz         dt_request, -- Date when the schedule was requested
        s.dt_schedule_tstz        dt_schedule, -- Date when the schedule was created
        s.dt_begin_tstz           dt_begin, -- Begin date for the schedule
        s.dt_end_tstz             dt_end, -- End date for the schedule
        s.dt_cancel_tstz          dt_cancel, -- Date when the schedule was cancelled,
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
        so.flg_state            flg_state, -- Schedule state: Estado: A - agendado, R - requisitado, E - efectivado, D - alta médica, M - alta administrativa, C - espera corredor, N - atendimento enfermagem pré-consulta, P - atendimento enfermagem pós-consulta, T - consulta
        so.flg_sched            flg_sched, -- N - 1ª enfermagem, F - subsequente enfermagem, I - internamento, S - internamento para cirurgia, V - tratamento feridas, T - administração medicamentos, I - informações, D - primeira médica; M - subsequente médica; P - primeira de especialidade; Q - subsequente especialidade
        so.flg_type             flg_type, -- P - primeira consulta, S - subsequente
        s.schedule_notes        schedule_notes, -- Schedule notes
        s.schedule_cancel_notes schedule_cancel_notes, -- Schedule cancellation notes.
        s.id_sch_consult_vacancy id_sch_consult_vacancy,  -- vacancy id . Can be null
        s.flg_request_type      flg_request_type,     -- request type, ex schedule_outp.flg_sched_request_type
        s.id_multidisc           id_multidisc,
        s.id_sch_combi_detail    id_sch_combi_detail,
        s.flg_reason_type        flg_reason_type
   FROM schedule      s,
        schedule_outp so
  WHERE s.id_schedule = so.id_schedule;
-- CHANGE END: Telmo