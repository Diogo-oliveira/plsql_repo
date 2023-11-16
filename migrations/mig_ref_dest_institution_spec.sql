DECLARE
    l_count             PLS_INTEGER;
    l_aux               PLS_INTEGER;
    g_retval            BOOLEAN;
    g_error             VARCHAR2(1000 CHAR);
    l_id_professional   professional.id_professional%TYPE;
    o_error             t_error_out;
    l_lang              language.id_language%TYPE;
    l_prof              profissional;
    l_ref_external_inst sys_config.value%TYPE;

    TYPE t_coll_num_order IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(200 CHAR);
    l_num_order_tab t_coll_num_order;
BEGIN
    -- 0- fazer backup da tabela
    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'P1_DEST_INSTITUTION_276022',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'DPC');

    SELECT COUNT(1)
      INTO l_aux
      FROM user_tables t
     WHERE t.table_name = 'P1_DEST_INSTITUTION_276022';

    IF l_aux = 0
    THEN
        EXECUTE IMMEDIATE 'CREATE TABLE P1_DEST_INSTITUTION_276022 AS SELECT * FROM P1_DEST_INSTITUTION where FLG_REF_LINE IS NOT NULL';
    END IF;

    -- 1- fazer script de migracao (default coloca valor '1')
    UPDATE (SELECT nvl(pdi.flg_ref_line, '1') pdi_flg_ref_line, rdis.flg_ref_line rdis_flg_ref_line
              FROM p1_dest_institution pdi
              JOIN ref_dest_institution_spec rdis
                ON rdis.id_dest_institution = pdi.id_dest_institution)
       SET rdis_flg_ref_line = pdi_flg_ref_line;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line(g_error || ' / ' || SQLERRM);
END;
/
