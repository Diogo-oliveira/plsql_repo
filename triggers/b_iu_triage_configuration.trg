CREATE OR REPLACE TRIGGER b_iu_triage_configuration
    BEFORE INSERT OR UPDATE ON triage_configuration
    FOR EACH ROW
BEGIN
    IF (:new.flg_buttons = 'N' AND :new.flg_check_vital_sign IN ('N', 'O') and :new.id_triage_type<>23)
       OR (:new.id_triage_type NOT IN ( 6, 23) AND :new.flg_default_view = 'V0')
       OR (:new.id_triage_type NOT IN ( 17, 19) AND :new.flg_default_view = 'V5')
       OR (:new.id_triage_type NOT IN (1, 7, 9, 12, 13, 14, 15, 16, 20,21) AND :new.flg_id_board = 'Y')
       OR (:new.id_triage_type = 6 AND :new.flg_check_vital_sign <> 'O')
       OR (:new.id_triage_type = 6 AND :new.flg_change_color <> 'Y')
       OR (:new.id_triage_type <> 16 AND :new.flg_triage_res_grids = 'Y')
       OR (:new.id_triage_type <> 16 AND :new.flg_filter_flowchart = 'Y')
       OR (:new.id_triage_type in( 16) AND :new.flg_default_view != 'V6')
       OR (:new.id_triage_type not in( 16) AND :new.flg_default_view = 'V6')
       OR (:new.id_triage_type not in (20,21) AND :new.flg_default_view = 'V7')
       OR (:new.id_triage_type = 16 AND nvl(:new.flg_complaint, 'N') != 'Y')
    THEN
        raise_application_error(-20001, 'ERROR: Configuration not supported.');
    END IF;

    -- Avoid changes to default parameterization
    IF (:old.id_institution = 0 AND :old.id_software = 0)
    THEN
        raise_application_error(-20001, 'ERROR: Default parameterization should not be modified.');
    END IF;
END;
/
