-- CHANGED BY: Telmo
-- CHANGED DATE: 02-01-2015
-- CHANGED REASON: ALERT-303513
create or replace type t_rec_sch_exam_daily_apps as object
(
   id_schedule                          number(24),
   id_patient                           number(24),
   id_inst_requests                     number(24),
   dt_begin                             TIMESTAMP(6) WITH LOCAL TIME ZONE,
   flg_status                           varchar2(1),
   id_exam                              number(24),
   id_exam_req                          number(24),
   no_show                              varchar2(1)
);
--CHANGE END: Telmo
/
