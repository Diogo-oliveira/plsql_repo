CREATE OR REPLACE TRIGGER b_iu_handoff_permission_inst
    BEFORE INSERT OR UPDATE ON handoff_permission_inst
    FOR EACH ROW
DECLARE
    l_flg_profile_dest profile_template.flg_profile%TYPE;
BEGIN

    SELECT pt.flg_profile
      INTO l_flg_profile_dest
      FROM profile_template pt
     WHERE pt.id_profile_template = :NEW.id_profile_template_dest;

    IF l_flg_profile_dest <> 'S'
       AND :NEW.flg_resp_type = 'O'
    THEN
        raise_application_error(-20001,
                                'ERROR: Invalid configuration: OVERALL responsability only supported in Specialist physicians.');
    END IF;

END b_iu_handoff_permission_inst;
/
