DECLARE
    CURSOR c_old_dais_1051 IS
        SELECT dais.id_doc_area_inst_soft
          FROM doc_area_inst_soft dais
         WHERE dais.id_doc_area = 1051;

    CURSOR c_old_dais_1050 IS
        SELECT dais.id_doc_area_inst_soft
          FROM doc_area_inst_soft dais
         WHERE dais.id_doc_area = 1050;

    CURSOR c_old_dtc_1050 IS
        SELECT dtc.id_doc_template_context
          FROM alert.doc_template_context dtc
         WHERE dtc.flg_type = 'D'
           AND dtc.id_context = 1050;

    CURSOR c_old_dtc_1051 IS
        SELECT dtc.id_doc_template_context
          FROM alert.doc_template_context dtc
         WHERE dtc.flg_type = 'D'
           AND dtc.id_context = 1051;

    r_old_dais_1050 doc_area_inst_soft.id_doc_area_inst_soft%TYPE;
    r_old_dais_1051 doc_area_inst_soft.id_doc_area_inst_soft%TYPE;
    r_old_dtc_1050  doc_template_context.id_doc_template_context%TYPE;
    r_old_dtc_1051  doc_template_context.id_doc_template_context%TYPE;
BEGIN
    --migrate doc_area transactional data
    UPDATE epis_documentation ed
       SET ed.id_doc_area = 48
     WHERE ed.id_doc_area = 1050;

    UPDATE epis_documentation ed
       SET ed.id_doc_area = 52
     WHERE ed.id_doc_area = 1051;

    -- migrate doc_area configurations
    UPDATE documentation e
       SET e.id_doc_area = 48
     WHERE e.id_doc_area = 1050;

    UPDATE documentation e
       SET e.id_doc_area = 52
     WHERE e.id_doc_area = 1051;

    OPEN c_old_dtc_1050;
    LOOP
        FETCH c_old_dtc_1050
            INTO r_old_dtc_1050;
        EXIT WHEN c_old_dtc_1050%NOTFOUND;
    
        BEGIN
            UPDATE doc_template_context dtc
               SET dtc.id_context = 48
             WHERE dtc.id_doc_template_context = r_old_dtc_1050;
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                DELETE FROM doc_template_context dtc
                 WHERE dtc.id_doc_template_context = r_old_dtc_1050;
        END;
    END LOOP;

    OPEN c_old_dtc_1051;
    LOOP
        FETCH c_old_dtc_1051
            INTO r_old_dtc_1051;
        EXIT WHEN c_old_dtc_1051%NOTFOUND;
    
        BEGIN
            UPDATE doc_template_context dtc
               SET dtc.id_context = 52
             WHERE dtc.id_doc_template_context = r_old_dtc_1051;
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                DELETE FROM doc_template_context dtc
                 WHERE dtc.id_doc_template_context = r_old_dtc_1051;
        END;
    END LOOP;

    OPEN c_old_dais_1051;
    LOOP
        FETCH c_old_dais_1051
            INTO r_old_dais_1051;
        EXIT WHEN c_old_dais_1051%NOTFOUND;
    
        BEGIN
            UPDATE doc_area_inst_soft dais
               SET dais.id_doc_area = 52
             WHERE dais.id_doc_area_inst_soft = r_old_dais_1051;
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                DELETE FROM doc_area_inst_soft dais
                 WHERE dais.id_doc_area_inst_soft = r_old_dais_1051;
        END;
    END LOOP;

    OPEN c_old_dais_1050;
    LOOP
        FETCH c_old_dais_1050
            INTO r_old_dais_1050;
        EXIT WHEN c_old_dais_1050%NOTFOUND;
    
        BEGIN
            UPDATE doc_area_inst_soft dais
               SET dais.id_doc_area = 48
             WHERE dais.id_doc_area_inst_soft = r_old_dais_1050;
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                DELETE FROM doc_area_inst_soft dais
                 WHERE dais.id_doc_area_inst_soft = r_old_dais_1050;
        END;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line(SQLERRM);
END;
