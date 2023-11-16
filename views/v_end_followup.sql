create or replace view v_end_followup as 
SELECT 
 profissional(
 alert_context('i_prof_id'),
 alert_context('i_prof_institution'),
 alert_context('i_prof_software')
 ) lprof
,cr.code_cancel_reason
,mfu.dt_next_encounter
,mfu.dt_next_enc_precision
,mfu.dt_register
,mfu.dt_start
,mfu.flg_end_followup
,mfu.flg_status
,mfu.id_episode
,mfu.id_opinion_type
,mfu.id_management_follow_up
,mfu.id_professional 
,mfu.notes
,mfu.time_spent
FROM management_follow_up mfu
LEFT JOIN unit_measure um  ON mfu.id_unit_time = um.id_unit_measure
LEFT JOIN cancel_reason cr ON mfu.id_cancel_reason = cr.id_cancel_reason
;