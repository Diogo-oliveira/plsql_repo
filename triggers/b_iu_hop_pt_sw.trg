CREATE OR REPLACE TRIGGER "B_IU_HOP_PT_SW"
    BEFORE INSERT OR UPDATE ON alert.HANDOFF_PERMISSION_INST
    FOR EACH ROW
DECLARE
    l_id_software_req software.id_software%TYPE;
		l_id_software_dest software.id_software%TYPE;
BEGIN
    SELECT id_software
      INTO l_id_software_req
      FROM profile_template pt
     WHERE pt.id_profile_template = :NEW.id_profile_template_req;

     SELECT id_software
      INTO l_id_software_dest
      FROM profile_template pt
     WHERE pt.id_profile_template = :NEW.id_profile_template_dest;

    IF (l_id_software_req <> l_id_software_dest)
    THEN
        raise_application_error(-20001, 'ID_SOFTWARE of profiles do not match');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        raise_application_error(-20001, 'Unknown error');
END b_iu_hop_pt_sw;
/