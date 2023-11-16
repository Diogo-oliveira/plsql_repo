-- CHANGED BY: Telmo
-- CHANGE DATE: 15-10-2010
-- CHANGE REASON: ALERT-126053
create or replace trigger A_IUD_SCH_RESCH_REAS_SOFT_INST
  after insert or update or delete on sch_resched_reason_soft_inst  
  for each row
DECLARE

BEGIN
    IF inserting
    THEN
        pk_ia_event_backoffice.sch_resc_reas_soft_inst_new(i_id_reschedule_reason => :NEW.id_resched_reason,
                                                           i_id_software          => :NEW.id_software,
                                                           i_id_institution       => :NEW.id_institution);
    ELSIF updating
    THEN
        pk_ia_event_backoffice.sch_resc_reas_soft_inst_update(i_id_reschedule_reason => :NEW.id_resched_reason,
                                                              i_id_software          => :NEW.id_software,
                                                              i_id_institution       => :NEW.id_institution);
    ELSIF deleting
    THEN
        pk_ia_event_backoffice.sch_resc_reas_soft_inst_delete(i_id_reschedule_reason => :OLD.id_resched_reason,
                                                              i_id_software          => :OLD.id_software,
                                                              i_id_institution       => :OLD.id_institution);
    END IF;
END a_iud_sch_resch_reas_soft_inst;
-- CHANGE END: Telmo