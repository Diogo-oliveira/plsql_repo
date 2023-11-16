/*-- Last Change Revision: $Rev: 2047035 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-10-10 11:07:27 +0100 (seg, 10 out 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_vital_signs IS

    --
    -- PRIVATE SUBTYPES
    -- 

    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    SUBTYPE t_stmt IS VARCHAR2(32000 CHAR);

    --
    -- PRIVATE CONSTANTS
    -- 

    -- Package info
    --c_package_owner CONSTANT obj_name := 'ALERT';
    c_package_name CONSTANT obj_name := pk_alertlog.who_am_i();

    --
    -- PRIVATE FUNCTIONS
    -- 

    FUNCTION exists_active_prev_vsr
    (
        i_episode         IN episode.id_episode%TYPE,
        i_vital_sign      IN vital_sign_read.id_vital_sign%TYPE,
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_previous_vsr    OUT vital_sign_read%ROWTYPE
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'EXISTS_ACTIVE_PREV_VSR';
        l_dbg_msg debug_msg;
    
        TYPE tva_prev_vsr IS TABLE OF vital_sign_read%ROWTYPE;
        va_prev_vsr tva_prev_vsr;
    
    BEGIN
        l_dbg_msg := 'GET PREVIOUS VITAL SIGNS READ';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT t.*
          BULK COLLECT
          INTO va_prev_vsr
          FROM (SELECT *
                  FROM vital_sign_read vsr
                 WHERE i_episode IS NULL
                   AND vsr.id_vital_sign = i_vital_sign
                   AND vsr.id_vital_sign_read != i_vital_sign_read
                   AND vsr.flg_state = pk_alert_constant.g_active
                UNION
                SELECT *
                  FROM vital_sign_read vsr
                 WHERE (i_episode IS NOT NULL AND vsr.id_episode = i_episode)
                   AND vsr.id_vital_sign = i_vital_sign
                   AND vsr.id_vital_sign_read != i_vital_sign_read
                   AND vsr.flg_state = pk_alert_constant.g_active) t
         ORDER BY t.dt_vital_sign_read_tstz DESC;
    
        IF SQL%ROWCOUNT > 0
        THEN
            o_previous_vsr := va_prev_vsr(1);
            RETURN TRUE;
        END IF;
    
        RETURN FALSE;
    
    END exists_active_prev_vsr;

    --

    FUNCTION exists_current_vsr_ea
    (
        i_episode         IN episode.id_episode%TYPE,
        i_vital_sign      IN vital_sign_read.id_vital_sign%TYPE,
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'EXISTS_CURRENT_VSR_EA';
        l_dbg_msg debug_msg;
        l_return  PLS_INTEGER := 0;
    BEGIN
        l_dbg_msg := 'GET IF VITAL SIGNS READ EXISTS IN TABLE VITAL_SIGNS_EA';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        BEGIN
            SELECT 1
              INTO l_return
              FROM vital_signs_ea vea
             WHERE vea.id_vital_sign = i_vital_sign
                  --    AND vea.id_episode = i_episode;
               AND vea.id_vital_sign_read = i_vital_sign_read;
        EXCEPTION
            WHEN no_data_found THEN
                l_return := 0;
        END;
    
        RETURN sys.diutil.int_to_bool(l_return);
    
    END exists_current_vsr_ea;

    --

    PROCEDURE delete_vital_sign_ea(i_vital_sign_read_row IN vital_sign_read%ROWTYPE) IS
        c_function_name CONSTANT obj_name := 'DELETE_VITAL_SIGN_EA';
        l_dbg_msg debug_msg;
    
    BEGIN
        -- REMOVE O REGISTO COM O MESMO ID_VITAL_SIGN PARA O PACIENTE E EPISODIO
        l_dbg_msg := 'DELETE VITAL_SIGN_READ FROM EASY_ACCESS';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        DELETE FROM vital_signs_ea vsea
         WHERE vsea.id_vital_sign = i_vital_sign_read_row.id_vital_sign
           AND vsea.id_patient = i_vital_sign_read_row.id_patient
           AND vsea.id_episode = i_vital_sign_read_row.id_episode;
    
    END delete_vital_sign_ea;

    --
    -- PUBLIC FUNCTIONS
    -- 
    PROCEDURE clean_ea_tbls
    (
        i_patient      IN vital_sign_read.id_patient%TYPE,
        i_real_patient IN vital_sign_read.id_patient%TYPE
    ) IS
        stmt t_stmt;
    
    BEGIN
        -- Cleaning ea tables
        stmt := 'DELETE vs_patient_ea vea' || --
                ' WHERE vea.id_patient = :1';
        EXECUTE IMMEDIATE stmt
            USING i_patient;
        -- clean records related to original patient, as they will be calculated later when the ea is processed for the temporary patient. This is only done if the id is received
        IF i_real_patient IS NOT NULL
        THEN
            stmt := 'DELETE vs_patient_ea vea' || --
                    ' WHERE vea.id_patient = :1';
            EXECUTE IMMEDIATE stmt
                USING i_real_patient;
        END IF;
        stmt := 'DELETE vs_visit_ea vea' || --
                ' WHERE EXISTS (SELECT 1' || --
                '          FROM visit v' || --
                '         WHERE v.id_visit = vea.id_visit' || --
                '           AND v.id_patient = :1)';
        EXECUTE IMMEDIATE stmt
            USING i_patient;
        stmt := 'DELETE vital_signs_ea vea' || --
                ' WHERE vea.id_patient = :1';
        EXECUTE IMMEDIATE stmt
            USING i_patient;
    
    END clean_ea_tbls;

    --

    PROCEDURE upd_vs_ea_tbls
    (
        i_patient         IN vital_sign_read.id_patient%TYPE,
        i_tmp_patient_id  IN vital_sign_read.id_patient%TYPE DEFAULT NULL,
        i_tmp_episode_id  IN vital_sign_read.id_episode%TYPE DEFAULT NULL,
        i_real_episode_id IN vital_sign_read.id_episode%TYPE DEFAULT NULL
    ) IS
        --
        -- 
        PROCEDURE populate_tmp_tbl(i_patient IN vital_sign_read.id_patient%TYPE) IS
        
                       PROCEDURE insert_tmp_glasgow(i_patient IN vital_sign_read.id_patient%TYPE) IS
                PRAGMA AUTONOMOUS_TRANSACTION;
            
                stmt t_stmt;
            
            BEGIN
                stmt := 'DELETE FROM vs_ea_tmp';
                EXECUTE IMMEDIATE stmt;
                -- Insert the glasgow total values in the temporary table
                stmt := 'INSERT /*+append*/' || --
                        '  INTO vs_ea_tmp' || --
                        '    SELECT tg.id_vital_sign_read,' || --
                        '           tg.id_vital_sign,' || --
                        '           tg.value,' || --
                        '           :1 AS id_unit_measure,' || --
                        '           NULL AS id_vital_sign_scales,' || --
                        '           tg.id_patient,' || --
                        '           tg.id_visit,' || --
                        '           tg.id_episode,' || --
                        '           tg.id_institution_read,' || --
                        '           tg.dt_vital_sign_read_tstz,' || --
                        '           tg.id_software_read' || --
                        '      FROM (SELECT vsr.id_vital_sign_read,' || --
                        '                   vrel.id_vital_sign_parent AS id_vital_sign,' || --
                        '                   rank() over(PARTITION BY vsr.dt_vital_sign_read_tstz ORDER BY vsr.id_vital_sign_read ASC) AS rank,' || --
                        '                   SUM(vsd.value) over(PARTITION BY vsr.dt_vital_sign_read_tstz) AS VALUE,' || --
                        '                   vsr.id_patient,' || --
                        '                   e.id_visit,' || --
                        '                   vsr.id_episode,' || --
                        '                   vsr.id_institution_read,' || --
                        '                   vsr.dt_vital_sign_read_tstz,' || --
                        '                   vsr.id_software_read' || --
                        '              FROM vital_sign_read vsr' || --
                        '             INNER JOIN vital_sign_relation vrel ON vsr.id_vital_sign = vrel.id_vital_sign_detail' || --
                        '             INNER JOIN vital_sign_desc vsd ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc' || --
                        '              LEFT OUTER JOIN episode e ON vsr.id_episode = e.id_episode' || --
                        '             WHERE vsr.flg_state = :2' || --
                        '               AND vrel.relation_domain = :3' || --
                        '               AND (vsr.id_episode IS NULL OR e.flg_status != :4)' || --
                        '               AND vsr.id_patient = :5) tg' || --
                        '     WHERE tg.rank = 1';
            
                EXECUTE IMMEDIATE stmt
                    USING --
                pk_vital_sign.c_without_um, --
                pk_alert_constant.g_active, --
                pk_alert_constant.g_vs_rel_sum, --
                pk_alert_constant.g_cancelled, --
                i_patient;
            
                COMMIT;
            END insert_tmp_glasgow;
            --
            PROCEDURE insert_tmp_bp(i_patient IN vital_sign_read.id_patient%TYPE) IS
                PRAGMA AUTONOMOUS_TRANSACTION;
            
                stmt t_stmt;
            
            BEGIN
                -- Insert the blood pressures values in the temporary table
                stmt := 'INSERT /*+append*/' || --
                        '  INTO vs_ea_tmp' || --
                        '    SELECT bp.id_vital_sign_read,' || --
                        '           bp.id_vital_sign,' || --
                        '           NULL AS VALUE,' || --
                        '           nvl(bp.id_unit_measure, :1) AS id_unit_measure,' || --
                        '           NULL AS id_vital_sign_scales,' || --
                        '           bp.id_patient,' || --
                        '           bp.id_visit,' || --
                        '           bp.id_episode,' || --
                        '           bp.id_institution_read,' || --
                        '           bp.dt_vital_sign_read_tstz,' || --
                        '           bp.id_software_read' || --
                        '      FROM (SELECT vsr.id_vital_sign_read,' || --
                        '                   vrel.id_vital_sign_parent AS id_vital_sign,' || --
                        '                   vsr.id_unit_measure,' || --
                        '                   rank() over(PARTITION BY vsr.dt_vital_sign_read_tstz ORDER BY vsr.id_vital_sign_read ASC) AS rank,' || --
                        '                   vsr.id_patient,' || --
                        '                   e.id_visit,' || --
                        '                   vsr.id_episode,' || --
                        '                   vsr.id_institution_read,' || --
                        '                   vsr.dt_vital_sign_read_tstz,' || --
                        '                   vsr.id_software_read' || --
                        '              FROM vital_sign_read vsr' || --
                        '             INNER JOIN vital_sign_relation vrel ON vsr.id_vital_sign = vrel.id_vital_sign_detail' || --
                        '              LEFT OUTER JOIN episode e ON vsr.id_episode = e.id_episode' || --
                        '             WHERE vsr.flg_state = :2' || --
                        '               AND vrel.relation_domain = :3' || --
                        '               AND (vsr.id_episode IS NULL OR e.flg_status != :4)' || --
                        '               AND vsr.id_patient = :5) bp' || --
                        '     WHERE bp.rank = 1';
            
                EXECUTE IMMEDIATE stmt
                    USING --
                pk_vital_sign.c_without_um, --
                pk_alert_constant.g_active, --
                pk_alert_constant.g_vs_rel_conc, --
                pk_alert_constant.g_cancelled, --
                i_patient;
            
                COMMIT;
            END insert_tmp_bp;
            --
            PROCEDURE insert_tmp_scales(i_patient IN vital_sign_read.id_patient%TYPE) IS
                PRAGMA AUTONOMOUS_TRANSACTION;
            
                stmt t_stmt;
            
            BEGIN
            
                -- Insert the vital sign scales values in the temporary table
                stmt := 'INSERT /*+append*/' || --
                        '  INTO vs_ea_tmp' || --
                        '    SELECT vsr.id_vital_sign_read,' || --
                        '           vsr.id_vital_sign,' || --
                        '           vsse.value AS VALUE,' || --
                        '           nvl(vsse.id_unit_measure, :1) AS id_unit_measure,' || --
                        '           vss.id_vital_sign_scales,' || --
                        '           vsr.id_patient,' || --
                        '           e.id_visit,' || --
                        '           vsr.id_episode,' || --
                        '           vsr.id_institution_read,' || --
                        '           vsr.dt_vital_sign_read_tstz,' || --
                        '           vsr.id_software_read' || --
                        '      FROM vital_sign_read vsr' || --
                        '     INNER JOIN vital_sign_scales vss ON vsr.id_vital_sign = vss.id_vital_sign' || --
                        '     INNER JOIN vital_sign_scales_element vsse ON vsr.id_vs_scales_element = vsse.id_vs_scales_element' || --
                        '                                              AND vss.id_vital_sign_scales = vsse.id_vital_sign_scales' || --
                        '      LEFT OUTER JOIN episode e ON vsr.id_episode = e.id_episode' || --
                        '     WHERE vsr.flg_state = :2' || --
                        '       AND (vsr.id_episode IS NULL OR e.flg_status != :3)' || --
                        '       AND vsr.id_patient = :4';
            
                EXECUTE IMMEDIATE stmt
                    USING --
                pk_vital_sign.c_without_um, --
                pk_alert_constant.g_active, --
                pk_alert_constant.g_cancelled, --
                i_patient;
            
                COMMIT;
            END insert_tmp_scales;
            --
            PROCEDURE insert_tmp_mc(i_patient IN vital_sign_read.id_patient%TYPE) IS
                PRAGMA AUTONOMOUS_TRANSACTION;
            
                stmt t_stmt;
            
            BEGIN
                -- Insert the vital sign multichoices values in the temporary table
                stmt := 'INSERT /*+append*/' || --
                        '  INTO vs_ea_tmp' || --
                        '    SELECT vsr.id_vital_sign_read,' || --
                        '           vsr.id_vital_sign,' || --
                        '           vsd.order_val AS VALUE,' || --
                        '           :1 AS id_unit_measure,' || --
                        '           NULL AS id_vital_sign_scales,' || --
                        '           vsr.id_patient,' || --
                        '           e.id_visit,' || --
                        '           vsr.id_episode,' || --
                        '           vsr.id_institution_read,' || --
                        '           vsr.dt_vital_sign_read_tstz,' || --
                        '           vsr.id_software_read' || --
                        '      FROM vital_sign_read vsr' || --
                        '     INNER JOIN vital_sign_desc vsd ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc' || --
                        '                                   AND vsr.id_vital_sign = vsd.id_vital_sign' || --
                        '      LEFT OUTER JOIN episode e ON vsr.id_episode = e.id_episode' || --
                        '     WHERE vsr.flg_state = :2' || --
                        '       AND (vsr.id_episode IS NULL OR e.flg_status != :3)' || --
                        '       AND EXISTS (SELECT 1' || --
                        '              FROM vital_sign vs' || --
                        '             WHERE vsr.id_vital_sign = vs.id_vital_sign' || --
                        '               AND vs.flg_fill_type = :4)' || --
                        '       AND NOT EXISTS (SELECT 1' || --
                        '              FROM vital_sign_relation vrel' || --
                        '             WHERE vsr.id_vital_sign = vrel.id_vital_sign_detail' || --
                        '               AND vrel.relation_domain = :5)' || --
                        '       AND vsr.id_patient = :6';
            
                EXECUTE IMMEDIATE stmt
                    USING --
                pk_vital_sign.c_without_um, --
                pk_alert_constant.g_active, --
                pk_alert_constant.g_cancelled, --
                pk_alert_constant.g_vs_ft_multichoice, --
                pk_alert_constant.g_vs_rel_sum, --
                i_patient;
            
                COMMIT;
            
            END insert_tmp_mc;
            --
            PROCEDURE insert_tmp_numeric(i_patient IN vital_sign_read.id_patient%TYPE) IS
                PRAGMA AUTONOMOUS_TRANSACTION;
            
                stmt t_stmt;
            
            BEGIN
                -- Insert the vital sign numeric values in the temporary table
                stmt := 'INSERT /*+append*/' || --
                        '  INTO vs_ea_tmp' || --
                        '    SELECT vsr.id_vital_sign_read,' || --
                        '           vsr.id_vital_sign,' || --
                        '           vsr.value,' || --
                        '           nvl(vsr.id_unit_measure, :1) AS id_unit_measure,' || --
                        '           NULL AS id_vital_sign_scales,' || --
                        '           vsr.id_patient,' || --
                        '           e.id_visit,' || --
                        '           vsr.id_episode,' || --
                        '           vsr.id_institution_read,' || --
                        '           vsr.dt_vital_sign_read_tstz,' || --
                        '           vsr.id_software_read' || --
                        '      FROM vital_sign_read vsr' || --
                        '      LEFT OUTER JOIN episode e ON vsr.id_episode = e.id_episode' || --
                        '     WHERE vsr.flg_state = :2' || --
                        '       AND (vsr.id_episode IS NULL OR e.flg_status != :3)' || --
                        '       AND vsr.id_vs_scales_element IS NULL' || --
                        '       AND vsr.id_vital_sign_desc IS NULL' || --
                        '       AND EXISTS (SELECT 1' || --
                        '              FROM vital_sign vs' || --
                        '             WHERE vsr.id_vital_sign = vs.id_vital_sign' || --
                        '               AND vs.flg_fill_type = :4)' || --
                        '       AND NOT EXISTS (SELECT 1' || --
                        '              FROM vital_sign_relation vrel' || --
                        '             WHERE vsr.id_vital_sign = vrel.id_vital_sign_detail' || --
                        '               AND vrel.relation_domain IN (:5, :6))' || --
                        '       AND vsr.id_patient = :7';
            
                EXECUTE IMMEDIATE stmt
                    USING --
                pk_vital_sign.c_without_um, --
                pk_alert_constant.g_active, --
                pk_alert_constant.g_cancelled, --
                pk_alert_constant.g_vs_ft_keypad, --
                pk_alert_constant.g_vs_rel_sum, --
                pk_alert_constant.g_vs_rel_conc, --
                i_patient;
            
                COMMIT;
            
            END insert_tmp_numeric;
            --
        BEGIN
            -- Start populating temporary table
            insert_tmp_glasgow(i_patient => i_patient);
            insert_tmp_bp(i_patient => i_patient);
            insert_tmp_scales(i_patient => i_patient);
            insert_tmp_mc(i_patient => i_patient);
            insert_tmp_numeric(i_patient => i_patient);
        
        END populate_tmp_tbl;
        --
        PROCEDURE convert_tmp_um IS
            PRAGMA AUTONOMOUS_TRANSACTION;
            TYPE t_vsea IS REF CURSOR;
            cur_vs_ea t_vsea;
        
            stmt_c t_stmt;
            stmt_u t_stmt;
        
            l_vital_sign       vital_sign_read.id_vital_sign%TYPE;
            l_unit_measure     vital_sign_read.id_unit_measure%TYPE;
            l_institution_read vital_sign_read.id_institution_read%TYPE;
            l_id_software_read vital_sign_read.id_software_read%TYPE;
            l_vs_um_inst       unit_measure.id_unit_measure%TYPE;
        
        BEGIN
            -- Start converting temporary table unit measures
            stmt_c := 'SELECT DISTINCT vtmp.id_vital_sign, vtmp.id_unit_measure, vtmp.id_institution_read, vtmp.ID_SOFTWARE_READ' || --
                      '  FROM vs_ea_tmp vtmp' || --
                      ' WHERE vtmp.value IS NOT NULL' || --
                      '   AND vtmp.id_unit_measure IS NOT NULL' || --
                      '   AND vtmp.id_vital_sign_scales IS NULL';
        
            OPEN cur_vs_ea FOR stmt_c;
        
            stmt_u := 'UPDATE vs_ea_tmp vtmp' || --
                      '   SET vtmp.value = pk_unit_measure.get_unit_mea_conversion(vtmp.value,' || --
                      '                                                            vtmp.id_unit_measure,' || --
                      '                                                            :1),' || --
                      '       vtmp.id_unit_measure = :2' || --
                      ' WHERE vtmp.id_vital_sign = :3' || --
                      '   AND vtmp.id_unit_measure = :4' || --
                      '   AND vtmp.id_institution_read = :5' || --
                      '   AND vtmp.id_software_read = :6';
        
            LOOP
                FETCH cur_vs_ea
                    INTO l_vital_sign, l_unit_measure, l_institution_read, l_id_software_read;
                EXIT WHEN cur_vs_ea%NOTFOUND;
            
                l_vs_um_inst := pk_vital_sign.get_vs_um_inst(i_vital_sign  => l_vital_sign,
                                                             i_institution => l_institution_read,
                                                             i_software    => l_id_software_read);
            
                IF l_unit_measure != l_vs_um_inst
                   AND pk_unit_measure.are_convertible(i_unit_meas => l_unit_measure, i_unit_meas_def => l_vs_um_inst)
                THEN
                    EXECUTE IMMEDIATE stmt_u
                        USING --
                    l_vs_um_inst, --
                    l_vs_um_inst, --
                    l_vital_sign, --
                    l_unit_measure, --
                    l_institution_read, --
                    l_id_software_read;
                
                    COMMIT;
                
                END IF;
            
            END LOOP;
        
            CLOSE cur_vs_ea;
            COMMIT;
        END convert_tmp_um;
        --
        PROCEDURE populate_ea_tbls(i_patient IN vital_sign_read.id_patient%TYPE) IS
            --
            PROCEDURE populate_vs_patient_ea_tbl IS
                stmt t_stmt;
            
            BEGIN
                -- Start populating vs_patient_ea table
                stmt := 'INSERT INTO vs_patient_ea' || --
                        '    (id_patient,' || --
                        '     id_vital_sign,' || --
                        '     id_unit_measure,' || --
                        '     n_records,' || --
                        '     id_first_vsr,' || --
                        '     id_min_vsr,' || --
                        '     id_max_vsr,' || --
                        '     id_last_1_vsr,' || --
                        '     id_last_2_vsr,' || --
                        '     id_last_3_vsr)' || --
                        '    SELECT v2.id_patient,' || --
                        '           v2.id_vital_sign,' || --
                        '           v2.id_unit_measure,' || --
                        '           MAX(v2.n_records) AS n_records,' || --
                        '           MAX(v2.id_first_vsr) AS id_first_vsr,' || --
                        '           MAX(v2.id_min_vsr) AS id_min_vsr,' || --
                        '           MAX(v2.id_max_vsr) AS id_max_vsr,' || --
                        '           MAX(v2.id_last_1_vsr) AS id_last_1_vsr,' || --
                        '           MAX(v2.id_last_2_vsr) AS id_last_2_vsr,' || --
                        '           MAX(v2.id_last_3_vsr) AS id_last_3_vsr' || --
                        '      FROM (SELECT v.id_patient,' || --
                        '                   v.id_vital_sign,' || --
                        '                   v.id_unit_measure,' || --
                        '                   v.cnt                  AS n_records,' || --
                        '                   NULL                   AS id_first_vsr,' || --
                        '                   NULL                   AS id_min_vsr,' || --
                        '                   NULL                   AS id_max_vsr,' || --
                        '                   NULL                   AS id_last_1_vsr,' || --
                        '                   NULL                   AS id_last_2_vsr,' || --
                        '                   NULL                   AS id_last_3_vsr' || --
                        '              FROM (SELECT vt.id_patient,' || --
                        '                           vt.id_vital_sign,' || --
                        '                           vt.id_unit_measure,' || --
                        '                           COUNT(1) over(PARTITION BY vt.id_patient, vt.id_vital_sign, vt.id_unit_measure) AS cnt' || --
                        '                      FROM vs_ea_tmp vt) v' || --
                        '            UNION ALL' || --
                        '            SELECT v.id_patient,' || --
                        '                   v.id_vital_sign,' || --
                        '                   v.id_unit_measure,' || --
                        '                   NULL                   AS n_records,' || --
                        '                   v.id_vital_sign_read   AS id_first_vsr,' || --
                        '                   NULL                   AS id_min_vsr,' || --
                        '                   NULL                   AS id_max_vsr,' || --
                        '                   NULL                   AS id_last_1_vsr,' || --
                        '                   NULL                   AS id_last_2_vsr,' || --
                        '                   NULL                   AS id_last_3_vsr' || --
                        '              FROM (SELECT vt.id_vital_sign_read,' || --
                        '                           vt.id_patient,' || --
                        '                           vt.id_vital_sign,' || --
                        '                           vt.id_unit_measure,' || --
                        '                           row_number() over(PARTITION BY vt.id_patient, vt.id_vital_sign, vt.id_unit_measure ORDER BY vt.dt_vital_sign_read_tstz) AS rk' || --
                        '                      FROM vs_ea_tmp vt) v' || --
                        '             WHERE rk = 1' || --
                        '            UNION ALL' || --
                        '            SELECT v.id_patient,' || --
                        '                   v.id_vital_sign,' || --
                        '                   v.id_unit_measure,' || --
                        '                   NULL                   AS n_records,' || --
                        '                   NULL                   AS id_first_vsr,' || --
                        '                   v.id_vital_sign_read   AS id_min_vsr,' || --
                        '                   NULL                   AS id_max_vsr,' || --
                        '                   NULL                   AS id_last_1_vsr,' || --
                        '                   NULL                   AS id_last_2_vsr,' || --
                        '                   NULL                   AS id_last_3_vsr' || --
                        '              FROM (SELECT vt.id_vital_sign_read,' || --
                        '                           vt.id_patient,' || --
                        '                           vt.id_vital_sign,' || --
                        '                           vt.id_unit_measure,' || --
                        '                           row_number() over(PARTITION BY vt.id_patient, vt.id_vital_sign, vt.id_unit_measure ORDER BY vt.value ASC, vt.dt_vital_sign_read_tstz ASC) AS rk' || --
                        '                      FROM vs_ea_tmp vt' || --
                        '                     WHERE vt.value IS NOT NULL) v' || --
                        '             WHERE rk = 1' || --
                        '            UNION ALL' || --
                        '            SELECT v.id_patient,' || --
                        '                   v.id_vital_sign,' || --
                        '                   v.id_unit_measure,' || --
                        '                   NULL                   AS n_records,' || --
                        '                   NULL                   AS id_first_vsr,' || --
                        '                   NULL                   AS id_min_vsr,' || --
                        '                   v.id_vital_sign_read   AS id_max_vsr,' || --
                        '                   NULL                   AS id_last_1_vsr,' || --
                        '                   NULL                   AS id_last_2_vsr,' || --
                        '                   NULL                   AS id_last_3_vsr' || --
                        '              FROM (SELECT vt.id_vital_sign_read,' || --
                        '                           vt.id_patient,' || --
                        '                           vt.id_vital_sign,' || --
                        '                           vt.id_unit_measure,' || --
                        '                           row_number() over(PARTITION BY vt.id_patient, vt.id_vital_sign, vt.id_unit_measure ORDER BY vt.value DESC, vt.dt_vital_sign_read_tstz ASC) AS rk' || --
                        '                      FROM vs_ea_tmp vt' || --
                        '                     WHERE vt.value IS NOT NULL) v' || --
                        '             WHERE rk = 1' || --
                        '            UNION ALL' || --
                        '            SELECT v1.id_patient,' || --
                        '                   v1.id_vital_sign,' || --
                        '                   v1.id_unit_measure,' || --
                        '                   NULL AS n_records,' || --
                        '                   NULL AS id_first_vsr,' || --
                        '                   NULL AS id_min_vsr,' || --
                        '                   NULL AS id_max_vsr,' || --
                        '                   MAX(v1.id_last_1_vsr) AS id_last_1_vsr,' || --
                        '                   MAX(v1.id_last_2_vsr) AS id_last_2_vsr,' || --
                        '                   MAX(v1.id_last_3_vsr) AS id_last_3_vsr' || --
                        '              FROM (SELECT v.id_patient,' || --
                        '                           v.id_vital_sign,' || --
                        '                           v.id_unit_measure,' || --
                        '                           CASE' || --
                        '                                WHEN rk = 1 THEN' || --
                        '                                 v.id_vital_sign_read' || --
                        '                                ELSE' || --
                        '                                 NULL' || --
                        '                            END AS id_last_1_vsr,' || --
                        '                           CASE' || --
                        '                                WHEN rk = 2 THEN' || --
                        '                                 v.id_vital_sign_read' || --
                        '                                ELSE' || --
                        '                                 NULL' || --
                        '                            END AS id_last_2_vsr,' || --
                        '                           CASE' || --
                        '                                WHEN rk = 3 THEN' || --
                        '                                 v.id_vital_sign_read' || --
                        '                                ELSE' || --
                        '                                 NULL' || --
                        '                            END AS id_last_3_vsr' || --
                        '                      FROM (SELECT vt.id_vital_sign_read,' || --
                        '                                   vt.id_patient,' || --
                        '                                   vt.id_vital_sign,' || --
                        '                                   vt.id_unit_measure,' || --
                        '                                   row_number() over(PARTITION BY vt.id_patient, vt.id_vital_sign, vt.id_unit_measure ORDER BY vt.dt_vital_sign_read_tstz DESC) AS rk' || --
                        '                              FROM vs_ea_tmp vt) v' || --
                        '                     WHERE rk <= 3) v1' || --
                        '             GROUP BY id_patient, id_vital_sign, id_unit_measure) v2' || --
                        '     GROUP BY id_patient, id_vital_sign, id_unit_measure';
            
                EXECUTE IMMEDIATE stmt;
            
            END populate_vs_patient_ea_tbl;
            --
            PROCEDURE populate_vs_visit_ea_tbl IS
                stmt t_stmt;
            
            BEGIN
                -- Start populating vs_visit_ea table
                stmt := 'INSERT INTO vs_visit_ea' || --
                        '    (id_visit,' || --
                        '     id_vital_sign,' || --
                        '     id_unit_measure,' || --
                        '     n_records,' || --
                        '     id_first_vsr,' || --
                        '     id_min_vsr,' || --
                        '     id_max_vsr,' || --
                        '     id_last_1_vsr,' || --
                        '     id_last_2_vsr,' || --
                        '     id_last_3_vsr)' || --
                        '    SELECT v2.id_visit,' || --
                        '           v2.id_vital_sign,' || --
                        '           v2.id_unit_measure,' || --
                        '           MAX(v2.n_records) AS n_records,' || --
                        '           MAX(v2.id_first_vsr) AS id_first_vsr,' || --
                        '           MAX(v2.id_min_vsr) AS id_min_vsr,' || --
                        '           MAX(v2.id_max_vsr) AS id_max_vsr,' || --
                        '           MAX(v2.id_last_1_vsr) AS id_last_1_vsr,' || --
                        '           MAX(v2.id_last_2_vsr) AS id_last_2_vsr,' || --
                        '           MAX(v2.id_last_3_vsr) AS id_last_3_vsr' || --
                        '      FROM (SELECT v.id_visit,' || --
                        '                   v.id_vital_sign,' || --
                        '                   v.id_unit_measure,' || --
                        '                   v.cnt                  AS n_records,' || --
                        '                   NULL                   AS id_first_vsr,' || --
                        '                   NULL                   AS id_min_vsr,' || --
                        '                   NULL                   AS id_max_vsr,' || --
                        '                   NULL                   AS id_last_1_vsr,' || --
                        '                   NULL                   AS id_last_2_vsr,' || --
                        '                   NULL                   AS id_last_3_vsr' || --
                        '              FROM (SELECT vt.id_visit,' || --
                        '                           vt.id_vital_sign,' || --
                        '                           vt.id_unit_measure,' || --
                        '                           COUNT(1) over(PARTITION BY vt.id_visit, vt.id_vital_sign, vt.id_unit_measure) AS cnt' || --
                        '                      FROM vs_ea_tmp vt' || --
                        '                     WHERE vt.id_visit IS NOT NULL) v' || --
                        '            UNION ALL' || --
                        '            SELECT v.id_visit,' || --
                        '                   v.id_vital_sign,' || --
                        '                   v.id_unit_measure,' || --
                        '                   NULL                   AS n_records,' || --
                        '                   v.id_vital_sign_read   AS id_first_vsr,' || --
                        '                   NULL                   AS id_min_vsr,' || --
                        '                   NULL                   AS id_max_vsr,' || --
                        '                   NULL                   AS id_last_1_vsr,' || --
                        '                   NULL                   AS id_last_2_vsr,' || --
                        '                   NULL                   AS id_last_3_vsr' || --
                        '              FROM (SELECT vt.id_vital_sign_read,' || --
                        '                           vt.id_visit,' || --
                        '                           vt.id_vital_sign,' || --
                        '                           vt.id_unit_measure,' || --
                        '                           row_number() over(PARTITION BY vt.id_visit, vt.id_vital_sign, vt.id_unit_measure ORDER BY vt.dt_vital_sign_read_tstz) AS rk' || --
                        '                      FROM vs_ea_tmp vt' || --
                        '                     WHERE vt.id_visit IS NOT NULL) v' || --
                        '             WHERE rk = 1' || --
                        '            UNION ALL' || --
                        '            SELECT v.id_visit,' || --
                        '                   v.id_vital_sign,' || --
                        '                   v.id_unit_measure,' || --
                        '                   NULL                   AS n_records,' || --
                        '                   NULL                   AS id_first_vsr,' || --
                        '                   v.id_vital_sign_read   AS id_min_vsr,' || --
                        '                   NULL                   AS id_max_vsr,' || --
                        '                   NULL                   AS id_last_1_vsr,' || --
                        '                   NULL                   AS id_last_2_vsr,' || --
                        '                   NULL                   AS id_last_3_vsr' || --
                        '              FROM (SELECT vt.id_vital_sign_read,' || --
                        '                           vt.id_visit,' || --
                        '                           vt.id_vital_sign,' || --
                        '                           vt.id_unit_measure,' || --
                        '                           row_number() over(PARTITION BY vt.id_visit, vt.id_vital_sign, vt.id_unit_measure ORDER BY vt.value ASC, vt.dt_vital_sign_read_tstz ASC) AS rk' || --
                        '                      FROM vs_ea_tmp vt' || --
                        '                     WHERE vt.id_visit IS NOT NULL' || --
                        '                       AND vt.value IS NOT NULL) v' || --
                        '             WHERE rk = 1' || --
                        '            UNION ALL' || --
                        '            SELECT v.id_visit,' || --
                        '                   v.id_vital_sign,' || --
                        '                   v.id_unit_measure,' || --
                        '                   NULL                   AS n_records,' || --
                        '                   NULL                   AS id_first_vsr,' || --
                        '                   NULL                   AS id_min_vsr,' || --
                        '                   v.id_vital_sign_read   AS id_max_vsr,' || --
                        '                   NULL                   AS id_last_1_vsr,' || --
                        '                   NULL                   AS id_last_2_vsr,' || --
                        '                   NULL                   AS id_last_3_vsr' || --
                        '              FROM (SELECT vt.id_vital_sign_read,' || --
                        '                           vt.id_visit,' || --
                        '                           vt.id_vital_sign,' || --
                        '                           vt.id_unit_measure,' || --
                        '                           row_number() over(PARTITION BY vt.id_visit, vt.id_vital_sign, vt.id_unit_measure ORDER BY vt.value DESC, vt.dt_vital_sign_read_tstz ASC) AS rk' || --
                        '                      FROM vs_ea_tmp vt' || --
                        '                     WHERE vt.id_visit IS NOT NULL' || --
                        '                       AND vt.value IS NOT NULL) v' || --
                        '             WHERE rk = 1' || --
                        '            UNION ALL' || --
                        '            SELECT v1.id_visit,' || --
                        '                   v1.id_vital_sign,' || --
                        '                   v1.id_unit_measure,' || --
                        '                   NULL AS n_records,' || --
                        '                   NULL AS id_first_vsr,' || --
                        '                   NULL AS id_min_vsr,' || --
                        '                   NULL AS id_max_vsr,' || --
                        '                   MAX(v1.id_last_1_vsr) AS id_last_1_vsr,' || --
                        '                   MAX(v1.id_last_2_vsr) AS id_last_2_vsr,' || --
                        '                   MAX(v1.id_last_3_vsr) AS id_last_3_vsr' || --
                        '              FROM (SELECT v.id_visit,' || --
                        '                           v.id_vital_sign,' || --
                        '                           v.id_unit_measure,' || --
                        '                           CASE' || --
                        '                                WHEN rk = 1 THEN' || --
                        '                                 v.id_vital_sign_read' || --
                        '                                ELSE' || --
                        '                                 NULL' || --
                        '                            END AS id_last_1_vsr,' || --
                        '                           CASE' || --
                        '                                WHEN rk = 2 THEN' || --
                        '                                 v.id_vital_sign_read' || --
                        '                                ELSE' || --
                        '                                 NULL' || --
                        '                            END AS id_last_2_vsr,' || --
                        '                           CASE' || --
                        '                                WHEN rk = 3 THEN' || --
                        '                                 v.id_vital_sign_read' || --
                        '                                ELSE' || --
                        '                                 NULL' || --
                        '                            END AS id_last_3_vsr' || --
                        '                      FROM (SELECT vt.id_vital_sign_read,' || --
                        '                                   vt.id_visit,' || --
                        '                                   vt.id_vital_sign,' || --
                        '                                   vt.id_unit_measure,' || --
                        '                                   row_number() over(PARTITION BY vt.id_visit, vt.id_vital_sign, vt.id_unit_measure ORDER BY vt.dt_vital_sign_read_tstz DESC) AS rk' || --
                        '                              FROM vs_ea_tmp vt' || --
                        '                             WHERE vt.id_visit IS NOT NULL) v' || --
                        '                     WHERE rk <= 3) v1' || --
                        '             GROUP BY id_visit, id_vital_sign, id_unit_measure) v2' || --
                        '     GROUP BY id_visit, id_vital_sign, id_unit_measure';
            
                EXECUTE IMMEDIATE stmt;
            
            END populate_vs_visit_ea_tbl;
            --
            PROCEDURE populate_vital_signs_ea_tbl(i_patient IN vital_sign_read.id_patient%TYPE) IS
                stmt t_stmt;
            
            BEGIN
                -- Start populating vital_signs_ea table
                stmt := 'INSERT INTO vital_signs_ea' || --
                        '    (id_vital_sign,' || --
                        '     id_vital_sign_read,' || --
                        '     id_vital_sign_desc,' || --
                        '     VALUE,' || --
                        '     id_unit_measure,' || --
                        '     dt_vital_sign_read,' || --
                        '     id_prof_read,' || --
                        '     id_prof_cancel,' || --
                        '     notes_cancel,' || --
                        '     flg_state,' || --
                        '     dt_cancel,' || --
                        '     flg_available,' || --
                        '     id_institution_read,' || --
                        '     flg_status_epis,' || --
                        '     id_visit,' || --
                        '     id_episode,' || --
                        '     id_patient,' || --
                        '     relation_domain,' || --
                        '     id_epis_triage,' || --
                        '     id_vs_scales_element,
                        flg_pain)' || --
                        '    SELECT vsr.id_vital_sign,' || --
                        '           vsr.id_vital_sign_read,' || --
                        '           vsr.id_vital_sign_desc,' || --
                        '           vsr.value,' || --
                        '           vsr.id_unit_measure,' || --
                        '           vsr.dt_vital_sign_read_tstz AS dt_vital_sign_read,' || --
                        '           vsr.id_prof_read,' || --
                        '           vsr.id_prof_cancel,' || --
                        '           vsr.notes_cancel,' || --
                        '           vsr.flg_state,' || --
                        '           vsr.dt_cancel_tstz AS dt_cancel,' || --
                        '           (SELECT vs.flg_available' || --
                        '              FROM vital_sign vs' || --
                        '             WHERE vs.id_vital_sign = vsr.id_vital_sign) AS flg_available,' || --
                        '           vsr.id_institution_read,' || --
                        '           e.flg_status AS flg_status_epis,' || --
                        '           e.id_visit,' || --
                        '           vsr.id_episode,' || --
                        '           vsr.id_patient,' || --
                        '           (SELECT vrel.relation_domain' || --
                        '              FROM vital_sign_relation vrel' || --
                        '             WHERE vsr.id_vital_sign = vrel.id_vital_sign_detail' || --
                        '               AND vrel.relation_domain IN (''' || pk_alert_constant.g_vs_rel_sum || ''' , ''' ||
                        pk_alert_constant.g_vs_rel_conc || ''')) AS relation_domain,' || --
                        '           vsr.id_epis_triage,' || --
                        '           vsr.id_vs_scales_element, ' || --
                        ' decode(vsr.id_vs_scales_element,null,null, ''Y'') ' ||
                        '      FROM (SELECT v.id_vital_sign_read' || --
                        '              FROM (SELECT vt.id_vital_sign_read,' || --
                        '                           row_number() over(PARTITION BY vt.id_episode, vt.id_vital_sign ORDER BY vt.dt_vital_sign_read_tstz DESC) AS rk' || --
                        '                      FROM vs_ea_tmp vt' || --
                        '                     WHERE vt.id_episode IS NOT NULL) v' || --
                        '             WHERE rk = 1) vl' || --
                        '     INNER JOIN vital_sign_read vsr ON vl.id_vital_sign_read = vsr.id_vital_sign_read' || --
                        '     INNER JOIN episode e ON vsr.id_episode = e.id_episode';
            
                EXECUTE IMMEDIATE stmt;
            
                -- add glasgow coma scale parameters to vital_signs_ea
                INSERT INTO vital_signs_ea
                    (id_vital_sign,
                     id_vital_sign_read,
                     id_vital_sign_desc,
                     VALUE,
                     id_unit_measure,
                     dt_vital_sign_read,
                     id_prof_read,
                     id_prof_cancel,
                     notes_cancel,
                     flg_state,
                     dt_cancel,
                     flg_available,
                     id_institution_read,
                     flg_status_epis,
                     id_visit,
                     id_episode,
                     id_patient,
                     relation_domain,
                     id_epis_triage,
                     id_vs_scales_element)
                    SELECT DISTINCT vsr.id_vital_sign,
                                    vsr.id_vital_sign_read,
                                    vsr.id_vital_sign_desc,
                                    vsr.value,
                                    vsr.id_unit_measure,
                                    vsr.dt_vital_sign_read_tstz AS dt_vital_sign_read,
                                    vsr.id_prof_read,
                                    vsr.id_prof_cancel,
                                    vsr.notes_cancel,
                                    vsr.flg_state,
                                    vsr.dt_cancel_tstz AS dt_cancel,
                                    (SELECT vs.flg_available
                                       FROM vital_sign vs
                                      WHERE vs.id_vital_sign = vsr.id_vital_sign) AS flg_available,
                                    vsr.id_institution_read,
                                    e.flg_status AS flg_status_epis,
                                    e.id_visit,
                                    vsr.id_episode,
                                    vsr.id_patient,
                                    vr1.relation_domain,
                                    vsr.id_epis_triage,
                                    vsr.id_vs_scales_element
                      FROM vital_sign_read vsr
                      LEFT OUTER JOIN episode e
                        ON vsr.id_episode = e.id_episode
                     INNER JOIN vital_sign_relation vr1
                        ON vsr.id_vital_sign = vr1.id_vital_sign_detail
                       AND vr1.relation_domain IN (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                     INNER JOIN (SELECT vea.id_vital_sign_read,
                                        vea.dt_vital_sign_read,
                                        vea.id_patient,
                                        vea.id_episode,
                                        vr2.relation_domain,
                                        vr2.id_vital_sign_parent
                                   FROM vital_signs_ea vea
                                  INNER JOIN vital_sign_relation vr2
                                     ON vea.id_vital_sign = vr2.id_vital_sign_detail
                                    AND vr2.relation_domain IN
                                        (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)) vea
                        ON vr1.relation_domain = vea.relation_domain
                       AND vr1.id_vital_sign_parent = vea.id_vital_sign_parent
                       AND vsr.dt_vital_sign_read_tstz = vea.dt_vital_sign_read
                       AND vsr.id_patient = vea.id_patient
                       AND ((vsr.id_episode IS NULL AND vea.id_episode IS NULL) OR vsr.id_episode = vea.id_episode)
                     WHERE vsr.id_patient = i_patient
                       AND NOT EXISTS (SELECT 1
                              FROM vital_signs_ea ea
                             WHERE vsr.id_vital_sign_read = ea.id_vital_sign_read);
            
            END populate_vital_signs_ea_tbl;
            --
        BEGIN
            -- Start populating ea tables
            populate_vs_patient_ea_tbl;
            populate_vs_visit_ea_tbl;
            populate_vital_signs_ea_tbl(i_patient => i_patient);
        
        END populate_ea_tbls;
    
        PROCEDURE merge_ea_tmp IS
            PRAGMA AUTONOMOUS_TRANSACTION;
            l_visit      visit.id_visit%TYPE;
            l_id_patient patient.id_patient%TYPE;
            stmt_u       t_stmt;
        BEGIN
            IF (i_real_episode_id <> i_tmp_episode_id AND i_real_episode_id IS NOT NULL)
            THEN
                SELECT id_visit, id_patient
                  INTO l_visit, l_id_patient
                  FROM episode
                 WHERE id_episode = i_real_episode_id;
                stmt_u := 'UPDATE vs_ea_tmp vtmp' || --
                          '   SET vtmp.id_episode =  ' || i_real_episode_id || ' , id_visit = ' || l_visit ||
                          ' ,id_patient =' || l_id_patient || ' WHERE id_episode = ' || i_tmp_episode_id;
                dbms_output.put_line('stmt_u:' || stmt_u);
                EXECUTE IMMEDIATE stmt_u;
            ELSIF (i_tmp_patient_id <> i_patient AND i_tmp_patient_id IS NOT NULL)
            THEN
                stmt_u := 'UPDATE vs_ea_tmp vtmp' || --
                          '   SET vtmp.id_patient =' || i_patient || ' WHERE id_patient = ' || i_tmp_patient_id;
                dbms_output.put_line('stmt:' || stmt_u);
                EXECUTE IMMEDIATE stmt_u;
            END IF;
            COMMIT;
        END merge_ea_tmp;
        --
    BEGIN
    
        populate_tmp_tbl(i_patient => i_patient);
        convert_tmp_um;
        merge_ea_tmp;
        clean_ea_tbls(i_patient => i_patient, i_real_patient => NULL);
        populate_ea_tbls(i_patient => i_patient);
    END upd_vs_ea_tbls;

    --

    PROCEDURE upd_vsr_patient
    (
        i_tmp_patient_id  IN vital_sign_read.id_patient%TYPE,
        i_real_patient_id IN vital_sign_read.id_patient%TYPE,
        o_rows_out        OUT table_varchar
    ) IS
    
    BEGIN
    
        ts_vital_sign_read.upd(id_patient_in => i_real_patient_id,
                               where_in      => 'id_patient = ' || i_tmp_patient_id,
                               rows_out      => o_rows_out);
    
    END upd_vsr_patient;

    --

    PROCEDURE upd_vsr_episode
    (
        i_tmp_episode_id  IN vital_sign_read.id_episode%TYPE,
        i_real_episode_id IN vital_sign_read.id_episode%TYPE,
        i_real_patient_id IN vital_sign_read.id_patient%TYPE,
        o_rows_out        OUT table_varchar
    ) IS
    
    BEGIN
    
        ts_vital_sign_read.upd(id_episode_in => i_real_episode_id,
                               id_patient_in => i_real_patient_id,
                               where_in      => 'id_episode = ' || i_tmp_episode_id,
                               rows_out      => o_rows_out);
    
    END upd_vsr_episode;

    --

    /**********************************************************************************************
    * This procedure has the business logic for the management of the VITAL_SIGNS_EA table.
    *
    * @param         i_lang                   language id
    * @param         i_prof                   profissional type
    * @param         i_event_type             type of the event (insert | update | delete)
    * @param         i_rowids                 list of the affected rowids 
    * @param         i_source_table_name      source table name
    * @param         i_list_columns           list of the affected columns
    * @param         i_dg_table_name          easy access table name
    *
    * @author        Thiago Brito
    * @since         2008-09-17
    **********************************************************************************************/
    PROCEDURE set_vital_signs_ea
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
    
        c_proc_name CONSTANT obj_name := 'SET_VITAL_SIGNS_EA';
        l_dbg_msg debug_msg;
        l_delete_event_excp    EXCEPTION;
        l_delete_event_excp_ea EXCEPTION;
    
        TYPE t_vital_sign_read_row IS TABLE OF vital_sign_read%ROWTYPE;
        vital_sign_read_row t_vital_sign_read_row;
    
        l_flg_available    vital_sign.flg_available%TYPE;
        l_flg_status_epis  episode.flg_status%TYPE;
        l_id_visit         episode.id_visit%TYPE;
        l_relation_domain  vital_sign_relation.relation_domain%TYPE;
        l_flg_pain         vital_signs_ea.flg_pain%TYPE := pk_alert_constant.g_no;
        l_ea_dt_vs_read    vital_signs_ea.dt_vital_sign_read%TYPE;
        l_vsr_to_insert_ea VARCHAR2(1char);
    
        previous_vsr vital_sign_read%ROWTYPE;
    
    BEGIN
    
        l_dbg_msg := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'VITAL_SIGN_READ',
                                                 i_expected_dg_table_name => 'VITAL_SIGNS_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => i_list_columns)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        CASE i_event_type
            WHEN t_data_gov_mnt.g_event_insert THEN
                -- IT WAS TRIGGERED BY AN INSERT EVENT
            
                l_dbg_msg := 'INSERT EVENT - GET VITAL SIGNS READ';
                pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
                SELECT /*+rule*/
                 *
                  BULK COLLECT
                  INTO vital_sign_read_row
                  FROM vital_sign_read vsr
                 WHERE ROWID IN (SELECT column_value
                                   FROM TABLE(i_rowids));
            
                l_dbg_msg := 'vital_sign_read_row.count = ' || vital_sign_read_row.count;
                pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
                IF vital_sign_read_row.count > 0
                THEN
                    -- 1) we need to delete the vital sign read for the
                    --    episode from VITAL_SIGNS_EA table
                    l_dbg_msg := 'INSERT EVENT - DELETE VITAL SIGN READ FROM VITAL_SIGNS_EA';
                    pk_alertlog.log_info(text            => l_dbg_msg,
                                         object_name     => c_package_name,
                                         sub_object_name => c_proc_name);
                    FOR i IN vital_sign_read_row.first .. vital_sign_read_row.last
                    LOOP
                        BEGIN
                            SELECT t.dt_vital_sign_read
                              INTO l_ea_dt_vs_read
                              FROM (SELECT vsea.dt_vital_sign_read
                                      FROM vital_signs_ea vsea
                                     WHERE vsea.id_patient = vital_sign_read_row(i).id_patient
                                       AND vsea.id_episode = vital_sign_read_row(i).id_episode
                                       AND vsea.flg_state <> pk_alert_constant.g_cancelled
                                       AND vsea.id_vital_sign = vital_sign_read_row(i).id_vital_sign
                                    UNION
                                    SELECT vsea.dt_vital_sign_read
                                      FROM vital_signs_ea vsea
                                     WHERE vsea.id_patient = vital_sign_read_row(i).id_patient
                                       AND (vsea.id_episode IS NULL AND vital_sign_read_row(i).id_episode IS NULL)
                                       AND vsea.flg_state <> pk_alert_constant.g_cancelled
                                       AND vsea.id_vital_sign = vital_sign_read_row(i).id_vital_sign) t;
                        
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_ea_dt_vs_read := vital_sign_read_row(i).dt_vital_sign_read_tstz;
                            
                            WHEN OTHERS THEN
                                RAISE l_delete_event_excp_ea;
                        END;
                    
                        IF vital_sign_read_row(i).dt_vital_sign_read_tstz >= l_ea_dt_vs_read
                        THEN
                            delete_vital_sign_ea(i_vital_sign_read_row => vital_sign_read_row(i));
                        
                            -- 2) now, we can insert the new row into the
                            --    VITAL_SIGNS_EA table
                        
                            -- we are going to get the FLG_AVAILABLE from VITAL_SIGN table
                            l_dbg_msg := 'INSERT EVENT - GET FLG_AVAILABLE FROM VITAL_SIGN';
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                            SELECT vs.flg_available
                              INTO l_flg_available
                              FROM vital_sign vs
                             WHERE vs.id_vital_sign = vital_sign_read_row(i).id_vital_sign;
                        
                            -- we are going to get the FLG_STATUS and ID_VISIT from EPISODE table
                            l_dbg_msg := 'INSERT EVENT - GET FLG_STATUS AND ID_VISIT FROM EPISODE';
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                            IF vital_sign_read_row(i).id_episode IS NOT NULL
                            THEN
                                SELECT e.flg_status, e.id_visit
                                  INTO l_flg_status_epis, l_id_visit
                                  FROM episode e
                                 WHERE e.id_episode = vital_sign_read_row(i).id_episode;
                            ELSE
                                l_flg_status_epis := NULL;
                                l_id_visit        := NULL;
                            END IF;
                        
                            -- we are going to get the RELATION_DOMAIN from VITAL_SIGN_RELATION
                            l_dbg_msg := 'INSERT EVENT - GET RELATION_DOMAIN FROM VITAL_SIGN_RELATION';
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                            BEGIN
                                SELECT rel.relation_domain
                                  INTO l_relation_domain
                                  FROM vital_sign_relation rel
                                 WHERE rel.id_vital_sign_detail = vital_sign_read_row(i).id_vital_sign
                                   AND rel.flg_available = pk_alert_constant.g_yes
                                   AND rel.relation_domain IN
                                       (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc);
                            EXCEPTION
                                WHEN no_data_found THEN
                                    l_relation_domain := NULL;
                            END;
                        
                            IF vital_sign_read_row(i).id_vs_scales_element IS NOT NULL
                            THEN
                                l_flg_pain := pk_alert_constant.g_yes;
                            END IF;
                        
                            -- we are going to INSERT into VITAL_SIGNS_EA table
                            l_dbg_msg := 'INSERT EVENT - INSERT INTO VITAL_SIGNS_EA';
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                        
                            ts_vital_signs_ea.ins(id_vital_sign_read_in   => vital_sign_read_row(i).id_vital_sign_read,
                                                  id_vital_sign_in        => vital_sign_read_row(i).id_vital_sign,
                                                  id_vital_sign_desc_in   => vital_sign_read_row(i).id_vital_sign_desc,
                                                  value_in                => vital_sign_read_row(i).value,
                                                  id_unit_measure_in      => vital_sign_read_row(i).id_unit_measure,
                                                  dt_vital_sign_read_in   => vital_sign_read_row(i).dt_vital_sign_read_tstz,
                                                  flg_pain_in             => l_flg_pain,
                                                  id_prof_read_in         => vital_sign_read_row(i).id_prof_read,
                                                  id_prof_cancel_in       => vital_sign_read_row(i).id_prof_cancel,
                                                  notes_cancel_in         => vital_sign_read_row(i).notes_cancel,
                                                  flg_state_in            => vital_sign_read_row(i).flg_state,
                                                  dt_cancel_in            => vital_sign_read_row(i).dt_cancel_tstz,
                                                  id_institution_read_in  => vital_sign_read_row(i).id_institution_read,
                                                  id_episode_in           => vital_sign_read_row(i).id_episode,
                                                  id_patient_in           => vital_sign_read_row(i).id_patient,
                                                  id_epis_triage_in       => vital_sign_read_row(i).id_epis_triage,
                                                  flg_available_in        => l_flg_available,
                                                  flg_status_epis_in      => l_flg_status_epis,
                                                  id_visit_in             => l_id_visit,
                                                  relation_domain_in      => l_relation_domain,
                                                  id_vs_scales_element_in => vital_sign_read_row(i).id_vs_scales_element);
                        
                        END IF;
                    END LOOP;
                END IF;
            
            WHEN t_data_gov_mnt.g_event_update THEN
                -- IT WAS TRIGGERED BY AN UPDATE EVENT
            
                l_dbg_msg := 'UPDATE EVENT - GET VITAL SIGNS READ';
                pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
                SELECT /*+rule*/
                 *
                  BULK COLLECT
                  INTO vital_sign_read_row
                  FROM vital_sign_read vsr
                 WHERE ROWID IN (SELECT column_value
                                   FROM TABLE(i_rowids));
            
                l_dbg_msg := 'vital_sign_read_row.count = ' || vital_sign_read_row.count;
                pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
            
                IF vital_sign_read_row.count > 0
                THEN
                    FOR i IN vital_sign_read_row.first .. vital_sign_read_row.last
                    LOOP
                        -- we are going to get the FLG_AVAILABLE from VITAL_SIGN table
                        l_dbg_msg := 'UPDATE EVENT - GET FLG_AVAILABLE FROM VITAL_SIGN FOR id_vital_sign_read = ' || --
                                     vital_sign_read_row(i).id_vital_sign_read;
                        pk_alertlog.log_info(text            => l_dbg_msg,
                                             object_name     => c_package_name,
                                             sub_object_name => c_proc_name);
                        SELECT vs.flg_available
                          INTO l_flg_available
                          FROM vital_sign vs
                         WHERE vs.id_vital_sign = vital_sign_read_row(i).id_vital_sign;
                    
                        -- we are going to get the FLG_STATUS and ID_VISIT from EPISODE table
                        l_dbg_msg := 'UPDATE EVENT - GET FLG_STATUS AND ID_VISIT FROM EPISODE';
                        pk_alertlog.log_info(text            => l_dbg_msg,
                                             object_name     => c_package_name,
                                             sub_object_name => c_proc_name);
                        IF vital_sign_read_row(i).id_episode IS NOT NULL
                        THEN
                            SELECT e.flg_status, e.id_visit
                              INTO l_flg_status_epis, l_id_visit
                              FROM episode e
                             WHERE e.id_episode = vital_sign_read_row(i).id_episode;
                        ELSE
                            l_flg_status_epis := NULL;
                            l_id_visit        := NULL;
                        END IF;
                    
                        -- we are going to get the RELATION_DOMAIN from VITAL_SIGN_RELATION
                        l_dbg_msg := 'UPDATE EVENT - GET RELATION_DOMAIN FROM VITAL_SIGN_RELATION';
                        pk_alertlog.log_info(text            => l_dbg_msg,
                                             object_name     => c_package_name,
                                             sub_object_name => c_proc_name);
                        BEGIN
                            SELECT rel.relation_domain
                              INTO l_relation_domain
                              FROM vital_sign_relation rel
                             WHERE rel.id_vital_sign_detail = vital_sign_read_row(i).id_vital_sign
                               AND rel.relation_domain IN
                                   (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                               AND rel.flg_available = pk_alert_constant.g_yes;
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_relation_domain := NULL;
                        END;
                    
                        IF vital_sign_read_row(i).id_vs_scales_element IS NOT NULL
                        THEN
                            l_flg_pain := pk_alert_constant.g_yes;
                        END IF;
                    
                        -- For update statement we have three possible approaches to follow to
                        -- 1) the record was cancelled and THERE IS another active one
                        --    a) remove the record from vital_signs_ea
                        --       - This remove will only happen if cancelled vital sign is present in easy_acces table
                        --    b) insert the active record from vital_sign_read into vital_signs_ea
                        --       - This insert will only happen if cancelled vital sign is present in easy_acces table
                        -- 2) the record was cancelled and THERE ISN'T another active one
                        --    a) update the vital_signs_ea and cancel the record
                        -- 3) the record remains active after update
                        --    a) update the vital_signs_ea
                        --
                        -- The first approache is contempled in the "THEN" code of the following IF;
                        -- The other ones are contempled by the "ELSE" code of the following IF.
                        --
                        IF vital_sign_read_row(i).flg_state = pk_alert_constant.g_cancelled
                            AND exists_active_prev_vsr(i_episode         => vital_sign_read_row(i).id_episode,
                                                       i_vital_sign      => vital_sign_read_row(i).id_vital_sign,
                                                       i_vital_sign_read => vital_sign_read_row(i).id_vital_sign_read,
                                                       o_previous_vsr    => previous_vsr) -- there are another active registers in vital_sign_read
                        THEN
                            l_dbg_msg := 'LMAIA: CALL TO exists_active_prev_vsr vital_sign_read_row(i).id_episode:' || vital_sign_read_row(i).id_episode;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                        
                            IF exists_current_vsr_ea(i_episode         => vital_sign_read_row(i).id_episode,
                                                     i_vital_sign      => vital_sign_read_row(i).id_vital_sign,
                                                     i_vital_sign_read => vital_sign_read_row(i).id_vital_sign_read)
                            THEN
                                l_vsr_to_insert_ea := pk_alert_constant.g_yes;
                                l_dbg_msg          := 'l_vsr_to_insert_ea = ''Y''';
                            ELSE
                                l_vsr_to_insert_ea := pk_alert_constant.g_no;
                                l_dbg_msg          := 'l_vsr_to_insert_ea = ''N''';
                            END IF;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                        
                            -- in this case we are going to remove the register for vital_signs_ea
                            IF ((l_relation_domain IS NULL OR l_relation_domain <> pk_alert_constant.g_vs_rel_sum OR
                               l_relation_domain <> pk_alert_constant.g_vs_rel_conc) AND
                               l_vsr_to_insert_ea = pk_alert_constant.g_yes)
                            THEN
                                l_dbg_msg := 'CALL TO delete_vital_sign_ea with id_vital_sign_read = ' || --
                                             vital_sign_read_row(i).id_vital_sign_read;
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                            
                                delete_vital_sign_ea(i_vital_sign_read_row => vital_sign_read_row(i));
                            ELSE
                                l_dbg_msg := 'l_relation_domain = ' || l_relation_domain || --
                                             ' AND l_vsr_to_insert_ea = ' || l_vsr_to_insert_ea;
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                            END IF;
                        
                            -- and then make an insert with the last active register from vital_sign_read (previous_vsr)
                            -- IT will only insert new vital sign in easy_access table if the original vital_sign_read was deleted.
                            IF l_vsr_to_insert_ea = pk_alert_constant.g_yes
                            THEN
                                l_dbg_msg := 'INSERT EVENT - INSERT INTO VITAL_SIGNS_EA with id_vital_sign_read = ' ||
                                             previous_vsr.id_vital_sign_read;
                                pk_alertlog.log_info(text            => l_dbg_msg,
                                                     object_name     => c_package_name,
                                                     sub_object_name => c_proc_name);
                            
                                ts_vital_signs_ea.ins(id_vital_sign_read_in   => previous_vsr.id_vital_sign_read,
                                                      id_vital_sign_in        => previous_vsr.id_vital_sign,
                                                      id_vital_sign_desc_in   => previous_vsr.id_vital_sign_desc,
                                                      value_in                => previous_vsr.value,
                                                      id_unit_measure_in      => previous_vsr.id_unit_measure,
                                                      dt_vital_sign_read_in   => previous_vsr.dt_vital_sign_read_tstz,
                                                      flg_pain_in             => l_flg_pain,
                                                      id_prof_read_in         => previous_vsr.id_prof_read,
                                                      id_prof_cancel_in       => previous_vsr.id_prof_cancel,
                                                      notes_cancel_in         => previous_vsr.notes_cancel,
                                                      flg_state_in            => previous_vsr.flg_state,
                                                      dt_cancel_in            => previous_vsr.dt_cancel_tstz,
                                                      id_institution_read_in  => previous_vsr.id_institution_read,
                                                      id_episode_in           => previous_vsr.id_episode,
                                                      id_patient_in           => previous_vsr.id_patient,
                                                      id_epis_triage_in       => previous_vsr.id_epis_triage,
                                                      flg_available_in        => l_flg_available,
                                                      flg_status_epis_in      => l_flg_status_epis,
                                                      id_visit_in             => l_id_visit,
                                                      relation_domain_in      => l_relation_domain,
                                                      id_vs_scales_element_in => previous_vsr.id_vs_scales_element);
                            END IF;
                        
                        ELSE
                            -- in this case we only need to update the register
                        
                            -- we are going to UPDATE de VITAL_SIGNS_EA table
                            l_dbg_msg := 'UPDATE EVENT - UPDATE VITAL_SIGNS_EA';
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => c_package_name,
                                                 sub_object_name => c_proc_name);
                        
                            ts_vital_signs_ea.upd(id_vital_sign_read_in   => vital_sign_read_row(i).id_vital_sign_read,
                                                  id_vital_sign_in        => vital_sign_read_row(i).id_vital_sign,
                                                  id_vital_sign_desc_in   => vital_sign_read_row(i).id_vital_sign_desc,
                                                  value_in                => vital_sign_read_row(i).value,
                                                  id_unit_measure_in      => vital_sign_read_row(i).id_unit_measure,
                                                  dt_vital_sign_read_in   => vital_sign_read_row(i).dt_vital_sign_read_tstz,
                                                  flg_pain_in             => l_flg_pain,
                                                  id_prof_read_in         => vital_sign_read_row(i).id_prof_read,
                                                  id_prof_cancel_in       => vital_sign_read_row(i).id_prof_cancel,
                                                  notes_cancel_in         => vital_sign_read_row(i).notes_cancel,
                                                  flg_state_in            => vital_sign_read_row(i).flg_state,
                                                  dt_cancel_in            => vital_sign_read_row(i).dt_cancel_tstz,
                                                  id_institution_read_in  => vital_sign_read_row(i).id_institution_read,
                                                  id_episode_in           => vital_sign_read_row(i).id_episode,
                                                  id_patient_in           => vital_sign_read_row(i).id_patient,
                                                  id_epis_triage_in       => vital_sign_read_row(i).id_epis_triage,
                                                  flg_available_in        => l_flg_available,
                                                  flg_status_epis_in      => l_flg_status_epis,
                                                  id_visit_in             => l_id_visit,
                                                  relation_domain_in      => l_relation_domain,
                                                  id_vs_scales_element_in => vital_sign_read_row(i).id_vs_scales_element);
                        END IF;
                    END LOOP;
                END IF;
            
            WHEN t_data_gov_mnt.g_event_delete THEN
                l_dbg_msg := 'process delete event';
                pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_proc_name);
                RAISE l_delete_event_excp;
            ELSE
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END CASE;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.raise_error(error_name_in => 'Invalid arguments');
        
        WHEN l_delete_event_excp THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.raise_error(error_name_in => 'Delete events aren''t supported');
        
        WHEN l_delete_event_excp_ea THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.raise_error(error_name_in => 'Data problems in easy_access tables. Please run SET_PAT_REBUILD_EA_TBLS please.');
        
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
        
    END set_vital_signs_ea;

    --

    PROCEDURE set_pat_rebuild_ea_tbls_patient(i_patient IN vital_sign_read.id_patient%TYPE) IS
    BEGIN
        IF i_patient IS NULL
        THEN
            RETURN;
        END IF;
    
        -- Cleaning ea tables
        clean_ea_tbls(i_patient => i_patient, i_real_patient => NULL);
    
        --Rebuild easy_access tables
        upd_vs_ea_tbls(i_patient => i_patient);
    
    END set_pat_rebuild_ea_tbls_patient;

    --

    /**********************************************************************************************
    * This procedure correct all duplicated collumns in table VITAL_SIGNS_EA
    *
    * @author        Luís Maia
    * @version       2.5.1
    * @since         16-Nov-2011
    **********************************************************************************************/
    PROCEDURE set_pat_rebuild_ea_tbls IS
        CURSOR c_problems IS
            SELECT DISTINCT id_patient
              FROM (SELECT vsea.id_vital_sign, vsea.id_episode, vsea.id_patient, COUNT(1)
                      FROM vital_signs_ea vsea
                     GROUP BY vsea.id_vital_sign, vsea.id_episode, vsea.id_patient
                    HAVING COUNT(1) > 1) vs;
    BEGIN
        --LOOP
        FOR c_p IN c_problems
        LOOP
            set_pat_rebuild_ea_tbls_patient(c_p.id_patient);
        END LOOP;
    END set_pat_rebuild_ea_tbls;

    --

    /**********************************************************************************************
    * Populates Vital Signs by Patient Easy Access table
    *
    * @param        i_tmp_patient_id         Temporary patient id
    * @param        i_real_patient_id        Real patient id
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Luís Maia
    * @version      2.5.1
    * @since        16-Nov-2011
    **********************************************************************************************/
    PROCEDURE merge_vs_patient
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        
        i_tmp_patient_id  IN vital_sign_read.id_patient%TYPE,
        i_real_patient_id IN vital_sign_read.id_patient%TYPE,
        o_rows_out        OUT table_varchar
    ) IS
        l_nrecs PLS_INTEGER;
        t_error t_error_out;
    BEGIN
        IF i_tmp_patient_id IS NULL
           OR i_real_patient_id IS NULL
        THEN
            RETURN;
        END IF;
    
        SELECT COUNT(1)
          INTO l_nrecs
          FROM vital_sign_read vsr
         WHERE vsr.id_patient = i_tmp_patient_id;
    
        IF l_nrecs < 1
        THEN
            RETURN;
        END IF;
    
        upd_vsr_patient(i_tmp_patient_id  => i_tmp_patient_id,
                        i_real_patient_id => i_real_patient_id,
                        o_rows_out        => o_rows_out);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'VITAL_SIGN_READ',
                                      i_rowids     => o_rows_out,
                                      o_error      => t_error);
        clean_ea_tbls(i_patient => i_tmp_patient_id, i_real_patient => NULL);
    
        upd_vs_ea_tbls(i_patient => i_real_patient_id, i_tmp_patient_id => i_tmp_patient_id);
    
    END merge_vs_patient;

    --

    /**********************************************************************************************
    * Populates Vital Signs by Patient Easy Access table
    *
    * @param        i_tmp_episode_id         Temporary episode id
    * @param        i_tmp_patient_id         Temporary patient id
    * @param        i_real_episode_id        Real episode id
    * @param        i_real_patient_id        Real patient id
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Luís Maia
    * @version      2.5.1
    * @since        16-Nov-2011
    **********************************************************************************************/
    PROCEDURE merge_vs_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tmp_episode_id  IN vital_sign_read.id_episode%TYPE,
        i_tmp_patient_id  IN vital_sign_read.id_patient%TYPE,
        i_real_episode_id IN vital_sign_read.id_episode%TYPE,
        i_real_patient_id IN vital_sign_read.id_patient%TYPE,
        o_rows_vsr_out    OUT table_varchar
    ) IS
        l_nrecs PLS_INTEGER;
        l_error t_error_out;
    BEGIN
        IF i_tmp_episode_id IS NULL
           OR i_real_episode_id IS NULL
        THEN
            RETURN;
        END IF;
    
        SELECT COUNT(1)
          INTO l_nrecs
          FROM vital_sign_read vsr
         WHERE vsr.id_episode = i_tmp_episode_id;
    
        IF l_nrecs < 1
        THEN
            RETURN;
        END IF;
    
        upd_vsr_episode(i_tmp_episode_id  => i_tmp_episode_id,
                        i_real_episode_id => i_real_episode_id,
                        i_real_patient_id => i_real_patient_id,
                        o_rows_out        => o_rows_vsr_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'VITAL_SIGN_READ',
                                      i_rowids     => o_rows_vsr_out,
                                      o_error      => l_error);
    
        clean_ea_tbls(i_patient => i_tmp_patient_id, i_real_patient => NULL);
        --      set_pat_rebuild_ea_tbls_int(I_PATIENT=>i_real_patient_id);
    
        clean_ea_tbls(i_patient => i_real_patient_id, i_real_patient => NULL);
        upd_vs_ea_tbls(i_patient         => i_real_patient_id,
                       i_tmp_patient_id  => i_tmp_patient_id,
                       i_tmp_episode_id  => i_tmp_episode_id,
                       i_real_episode_id => i_real_episode_id);
    
    END merge_vs_episode;

--
-- INITIALIZATION SECTION
-- 

BEGIN
    -- Initializes log context
    pk_alertlog.log_init(object_name => c_package_name);

END pk_ea_vital_signs;
/
