CREATE OR REPLACE TRIGGER a_iu_ref_dest_institution_spec
    AFTER INSERT OR UPDATE ON ref_dest_institution_spec
    FOR EACH ROW
DECLARE
    -- Variables
    l_new_row      ref_dest_institution_spec%ROWTYPE;
    l_old_row      ref_dest_institution_spec%ROWTYPE;
    l_trigger_name VARCHAR2(200 CHAR);
    l_event        PLS_INTEGER;
BEGIN
    -- initializing vars
    l_trigger_name := 'REF_DEST_INSTITUTION_SPEC';

    CASE
        WHEN inserting THEN
            l_event := pk_ref_constant.g_insert_event;
        WHEN updating THEN
            l_event := pk_ref_constant.g_update_event;
        ELSE
            pk_alertlog.log_error(l_trigger_name || ' invalid event');
    END CASE;

    -- old
    l_old_row.id_dest_institution_spec := :old.id_dest_institution_spec;
    l_old_row.id_dest_institution      := :old.id_dest_institution;
    l_old_row.id_speciality            := :old.id_speciality;
    l_old_row.flg_available            := :old.flg_available;
    l_old_row.flg_inside_ref_area      := :old.flg_inside_ref_area;
		l_old_row.flg_ref_line             := :old.flg_ref_line;

    -- new
    l_new_row.id_dest_institution_spec := :new.id_dest_institution_spec;
    l_new_row.id_dest_institution      := :new.id_dest_institution;
    l_new_row.id_speciality            := :new.id_speciality;
    l_new_row.flg_available            := :new.flg_available;
    l_new_row.flg_inside_ref_area      := :new.flg_inside_ref_area;
		l_new_row.flg_ref_line             := :new.flg_ref_line;

    pk_api_ref_event.set_ref_dest_institution_spec(i_event => l_event, i_old_row => l_old_row, i_new_row => l_new_row);

EXCEPTION
    WHEN OTHERS THEN
        pk_alertlog.log_error('ERROR IN ' || l_trigger_name || ' / new id_dest_institution_spec=' ||
                              :new.id_dest_institution_spec || ' old id_dest_institution_spec=' ||
                              :old.id_dest_institution_spec || ' / SQLERRM=' || SQLERRM);
END;
/