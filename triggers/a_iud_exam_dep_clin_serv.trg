CREATE OR REPLACE TRIGGER a_iud_exam_dep_clin_serv
    AFTER INSERT OR UPDATE OR DELETE ON exam_dep_clin_serv
    FOR EACH ROW

BEGIN

    IF inserting
    THEN
        IF (:new.id_institution IS NOT NULL AND :new.id_software IS NOT NULL AND :new.flg_type = 'P')
        THEN
            pk_ia_event_backoffice.exam_dep_clin_serv_new(:new.id_exam_dep_clin_serv, :new.id_institution);
        END IF;
    ELSIF updating
    THEN
        IF (:new.id_institution IS NOT NULL AND :new.id_software IS NOT NULL AND :new.flg_type = 'P' AND
           :old.flg_type != 'P')
        THEN
            pk_ia_event_backoffice.exam_dep_clin_serv_new(:new.id_exam_dep_clin_serv, :new.id_institution);
        END IF;
    ELSIF deleting
    THEN
    
        IF (:old.id_institution IS NOT NULL AND :old.id_software IS NOT NULL AND :old.flg_type = 'P' AND
           pk_backoffice_mcdt.check_exam_config(:old.id_exam, :old.id_institution, :old.flg_type) = 1)
        THEN
            pk_ia_event_backoffice.exam_dep_clin_serv_delete(:old.id_exam_dep_clin_serv,
                                                             :old.id_exam,
                                                             :old.id_institution);
        END IF;
    END IF;

END a_iud_exam_dep_clin_serv;
