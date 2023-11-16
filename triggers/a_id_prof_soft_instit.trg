CREATE OR REPLACE TRIGGER a_id_prof_soft_instit
    AFTER INSERT OR DELETE ON prof_soft_inst
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        pk_ia_event_backoffice.prof_soft_inst_new(:new.id_prof_soft_inst, :new.id_institution);
    ELSIF deleting
    THEN
        pk_ia_event_backoffice.prof_soft_inst_delete(:old.id_prof_soft_inst,
                                                     :old.id_institution,
                                                     :old.id_professional,
                                                     :old.id_software);
    END IF;
END a_id_prof_soft_instit;
