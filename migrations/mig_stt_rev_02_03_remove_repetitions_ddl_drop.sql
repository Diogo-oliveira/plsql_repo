DECLARE
    next_id alert.sample_text_type_cat.id_sample_text_type_cat%TYPE;

    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ' ||
                                 i_sql || ';');
    END run_ddl;
BEGIN
    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_REP_MASTER');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_REP_MASTER');
  	run_ddl('DROP TABLE stt_rev_aux_rep_master');
		
    run_ddl('DROP SEQUENCE SEQ_STTC_REV_AUX');
END;
/



