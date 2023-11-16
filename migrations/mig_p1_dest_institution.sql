-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 08/01/2015 14:37
-- CHANGE REASON: [ALERT-280039] 
DECLARE
    l_id_inst             p1_dest_institution.id_inst_dest%TYPE;
    l_id_inst_prev        p1_dest_institution.id_inst_dest%TYPE;
    l_id_dest_institution p1_dest_institution.id_dest_institution%TYPE;
    l_aux                 PLS_INTEGER;
BEGIN
    -- 0- fazer backup da tabela
    SELECT COUNT(1)
      INTO l_aux
      FROM user_tables t
     WHERE t.table_name = 'V_REF_HOSP_ENTRANCE_262716';

    IF l_aux = 0
    THEN
    
        pk_frmw_objects.insert_into_frmw_objects(i_owner            => 'ALERT',
                                                 i_obj_name         => 'V_REF_HOSP_ENTRANCE_262716',
                                                 i_obj_type         => 'TABLE',
                                                 i_flg_category     => 'DPC',
                                                 i_responsible_team => 'REFERRAL');
    
        EXECUTE IMMEDIATE 'CREATE TABLE V_REF_HOSP_ENTRANCE_262716 AS SELECT distinct v.id_inst_orig, v.id_institution, v.id_speciality FROM v_ref_hosp_entrance v';
    END IF;

    FOR rec IN (SELECT DISTINCT v.id_institution, v.id_speciality, v.flg_ref_line
                  FROM v_ref_hosp_entrance v
                 ORDER BY 1, 2)
    LOOP
    
        l_id_inst := rec.id_institution;
    
        IF l_id_inst_prev IS NULL
           OR l_id_inst_prev != l_id_inst
        THEN
            -- entidade externa (id_inst_orig=0)            
            l_id_dest_institution := NULL;
        
            BEGIN
                SELECT id_dest_institution
                  INTO l_id_dest_institution
                  FROM p1_dest_institution
                 WHERE id_inst_orig = 0
                   AND id_inst_dest = rec.id_institution
                   AND flg_type = 'C'
                   AND flg_net_type = 'P';
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_dest_institution := NULL;
            END;
        
            IF l_id_dest_institution IS NULL
            THEN
                --dbms_output.put_line('INSERT INTO p1_dest_institution(id_inst_orig=0, id_inst_dest=' || l_id_inst || ')');
                INSERT INTO p1_dest_institution
                    (id_dest_institution, id_inst_orig, id_inst_dest, flg_default, flg_type, flg_net_type)
                VALUES
                    (seq_p1_dest_institution.nextval, 0, rec.id_institution, 'Y', 'C', 'P')
                RETURNING id_dest_institution INTO l_id_dest_institution;
            END IF;
        END IF;
    
        -- especialidades disponiveis para entidade externa
        SELECT COUNT(1)
          INTO l_aux
          FROM ref_dest_institution_spec rdis
         WHERE rdis.id_dest_institution = l_id_dest_institution
           AND rdis.id_speciality = rec.id_speciality;
    
        IF l_aux = 0
        THEN
            --dbms_output.put_line('INSERT INTO ref_dest_institution_spec(('||l_id_dest_institution||'),id_inst_orig=0, id_inst_dest=' || l_id_inst ||' id_spec=' || rec.id_speciality || ')');
            INSERT INTO ref_dest_institution_spec
                (id_dest_institution_spec,
                 id_dest_institution,
                 id_speciality,
                 flg_available,
                 flg_inside_ref_area,
                 flg_ref_line)
            VALUES
                (seq_ref_dest_institution_spec.nextval,
                 l_id_dest_institution,
                 rec.id_speciality,
                 'Y',
                 'N',
                 rec.flg_ref_line);
        END IF;
    
        l_id_inst_prev := l_id_inst;
    END LOOP;
END;
/
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 08/01/2015 15:15
-- CHANGE REASON: [ALERT-280039] 
BEGIN
    UPDATE p1_dest_institution
       SET flg_net_type = 'A'
     WHERE flg_net_type IS NULL;
END;
/
-- CHANGE END: Ana Monteiro