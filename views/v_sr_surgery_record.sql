-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 23/03/2010 11:12
-- CHANGE REASON: [ALERT-82859] Versioning of views for Java Entities generation
CREATE OR REPLACE view v_sr_surgery_record AS
 SELECT id_surgery_record,
id_schedule_sr,
id_sr_intervention,
id_prof_team,
id_patient,
flg_pat_status,
flg_state,
flg_surg_nat,
flg_surg_type,
flg_urgency,
id_anesthesia_type,
id_clinical_service,
notes,
id_prof_cancel,
notes_cancel,
id_institution,
dt_anest_start_tstz,
dt_anest_end_tstz,
dt_sr_entry_tstz,
dt_sr_exit_tstz,
dt_room_entry_tstz,
dt_room_exit_tstz,
dt_rcv_entry_tstz,
dt_rcv_exit_tstz,
dt_cancel_tstz,
id_episode,
flg_priority,
flg_sr_proc,
dt_flg_sr_proc
 FROM sr_surgery_record;
-- CHANGE END: Gustavo Serrano