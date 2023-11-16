CREATE OR REPLACE TRIGGER a_iud_reason_soft_inst
    AFTER INSERT OR UPDATE OR DELETE ON cancel_rea_soft_inst
    FOR EACH ROW
DECLARE
    l_count              NUMBER;
    l_id_institution     institution.id_institution%TYPE;
    l_id_cancel_rea_area cancel_rea_soft_inst.id_cancel_rea_area%TYPE;
    l_intern_name        cancel_rea_area.intern_name%TYPE;
BEGIN

    IF inserting
       OR updating
    THEN
        l_id_institution     := :new.id_institution;
        l_id_cancel_rea_area := :new.id_cancel_rea_area;
    ELSIF deleting
    THEN
        l_id_institution     := :old.id_institution;
        l_id_cancel_rea_area := :old.id_cancel_rea_area;
    END IF;

    BEGIN
        SELECT COUNT(*), upper(cra.intern_name)
          INTO l_count, l_intern_name
          FROM cancel_reason cr
          LEFT JOIN reason_synonym_inst rsi
            ON rsi.id_reason = cr.id_cancel_reason
           AND rsi.id_institution = l_id_institution
          JOIN reason_action_relation rar
            ON rar.id_reason = cr.id_cancel_reason
          JOIN reason_action ra
            ON ra.id_action = rar.id_action
           AND ra.flg_type = 'C'
          JOIN cancel_rea_area cra
            ON cra.id_cancel_rea_area = l_id_cancel_rea_area
         WHERE upper(cra.intern_name) IN
               (upper('PATIENT_NO_SHOW'), upper('HHC_VISITS_REA_APPROVAL'), upper('HHC_VISITS_REA_UNDO'))
         GROUP BY cra.intern_name;
    EXCEPTION
        WHEN no_data_found THEN
            l_count := 0;
    END;
    
    IF l_count > 0
    THEN
        IF inserting
        THEN
            pk_ia_event_backoffice.sch_reason_soft_inst_new(:new.id_cancel_reason,
                                                            :new.id_profile_template,
                                                            :new.id_software,
                                                            :new.id_institution,
                                                            :new.id_cancel_rea_area);
        ELSIF updating
        THEN
            pk_ia_event_backoffice.sch_reason_soft_inst_update(:new.id_cancel_reason,
                                                               :new.id_profile_template,
                                                               :new.id_software,
                                                               :new.id_institution,
                                                               :new.id_cancel_rea_area);
        ELSIF deleting
        THEN
            pk_ia_event_backoffice.sch_reason_soft_inst_delete(:old.id_cancel_reason,
                                                               :old.id_profile_template,
                                                               :old.id_software,
                                                               :old.id_institution,
                                                               :old.id_cancel_rea_area,
                                                               l_intern_name);
        END IF;
    END IF;

END a_iud_reason_soft_inst;
/