DECLARE
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ' ||
                                 i_sql || ';');
    END run_ddl;
BEGIN
    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_SW_DISTINCT');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_SW_DISTINCT');
    run_ddl(i_sql => 'DROP TABLE stt_rev_aux_sw_distinct');

    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_SW_ALL');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_SW_ALL');
    run_ddl(i_sql => 'DROP TABLE stt_rev_aux_sw_all');

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/
