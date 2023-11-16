/*-- Last Change Revision: $Rev: 2053881 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-30 11:32:32 +0000 (sex, 30 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_exam_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_exam_prm';

    g_cfg_done t_low_char;
    -- Private Methods
    pos_soft NUMBER := 1;
    -- content loader method
    /********************************************************************************************
    * Set Default Exam Complaint association
    *
    * @param i_lang                Prefered language ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/16
    ********************************************************************************************/
    FUNCTION load_exam_complaint_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('LOAD_EXAM_COMPLAINT_DEF');
        g_error     := 'OPEN CONFIGURATION CURSOR';
    
        INSERT INTO exam_complaint
            (id_exam, id_complaint, flg_available)
            SELECT def_data.id_exam, def_data.id_complaint, g_flg_available
              FROM (SELECT temp_data.id_exam,
                           temp_data.id_complaint,
                           row_number() over(PARTITION BY temp_data.id_exam, temp_data.id_complaint ORDER BY temp_data.l_row) records_count
                      FROM (SELECT ad_ec.rowid l_row,
                                   nvl((SELECT a_e.id_exam
                                         FROM exam a_e
                                        WHERE a_e.id_content = ad_e.id_content
                                          AND a_e.flg_available = g_flg_available),
                                       0) id_exam,
                                   nvl((SELECT a_c.id_complaint
                                         FROM complaint a_c
                                         JOIN ad_complaint ad_c
                                           ON ad_c.id_content = a_c.id_content
                                        WHERE ad_c.id_complaint = ad_ec.id_complaint
                                          AND a_c.flg_available = g_flg_available),
                                       0) id_complaint
                              FROM ad_exam_complaint ad_ec
                              JOIN ad_exam ad_e
                                ON ad_e.id_exam = ad_ec.id_exam
                               AND ad_e.flg_available = g_flg_available
                             WHERE ad_ec.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_exam > 0
                       AND temp_data.id_complaint > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM exam_complaint a_ac
                     WHERE a_ac.flg_available = g_flg_available
                       AND a_ac.id_exam = def_data.id_exam
                       AND a_ac.id_complaint = def_data.id_complaint);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END load_exam_complaint_def;

    FUNCTION load_exam_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('exam.code_exam.');
    
    BEGIN
    
        INSERT INTO exam
            (id_exam,
             code_exam,
             flg_available,
             rank,
             flg_type,
             age_min,
             age_max,
             gender,
             id_exam_cat,
             id_content,
             flg_technical)
            SELECT seq_exam.nextval,
                   l_code_translation || seq_exam.currval,
                   g_flg_available,
                   0,
                   flg_type,
                   age_min,
                   age_max,
                   gender,
                   id_exam_cat,
                   id_content,
                   flg_technical
              FROM (SELECT ad_e.id_content,
                           ad_e.flg_type,
                           ad_e.age_min,
                           ad_e.age_max,
                           ad_e.gender,
                           nvl((SELECT a_ec.id_exam_cat
                                 FROM exam_cat a_ec
                                 JOIN ad_exam_cat ad_ec
                                   ON a_ec.id_content = ad_ec.id_content
                                WHERE ad_ec.id_exam_cat = ad_e.id_exam_cat
                                  AND a_ec.flg_available = g_flg_available
                                  AND ad_ec.flg_available = g_flg_available),
                               0) id_exam_cat,
                           ad_e.flg_technical
                      FROM ad_exam ad_e
                     WHERE ad_e.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM exam a_e
                             WHERE a_e.id_content = ad_e.id_content
                               AND a_e.flg_available = g_flg_available)) def_data
             WHERE def_data.id_exam_cat > 0;
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END load_exam_def;

    FUNCTION set_exam_group_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pattern_trl VARCHAR2(200) := 'EXAM_GROUP.CODE_EXAM_GROUP.';
        l_level_array table_number := table_number();
    
    BEGIN
    
        g_func_name := upper('SET_EXAM_GROUP_DEF');
    
        SELECT DISTINCT LEVEL
          BULK COLLECT
          INTO l_level_array
          FROM ad_exam_group ad_eg
         WHERE ad_eg.flg_available = g_flg_available
         START WITH ad_eg.id_group_parent IS NULL
        CONNECT BY PRIOR ad_eg.id_exam_group = ad_eg.id_group_parent
         ORDER BY LEVEL ASC;
    
        g_error := 'Bulk insert ' || l_level_array.count || ' levels';
        dbms_output.put_line(g_error);
    
        FORALL c_level IN 1 .. l_level_array.count
            INSERT INTO exam_group
                (id_exam_group,
                 code_exam_group,
                 rank,
                 adw_last_update,
                 gender,
                 age_min,
                 age_max,
                 id_group_parent,
                 id_content)
                SELECT seq_exam_group.nextval,
                       l_pattern_trl || seq_exam_group.currval,
                       def_data.rank,
                       SYSDATE,
                       def_data.gender,
                       def_data.age_min,
                       def_data.age_max,
                       def_data.id_group_parent,
                       def_data.id_content
                  FROM (SELECT LEVEL lvl,
                               ad_eg.rank,
                               ad_eg.gender,
                               ad_eg.age_min,
                               ad_eg.age_max,
                               decode(ad_eg.id_group_parent,
                                      NULL,
                                      NULL,
                                      nvl((SELECT a_eg.id_exam_group
                                            FROM exam_group a_eg
                                            JOIN ad_exam_group ad_eg1
                                              ON (ad_eg1.id_content = a_eg.id_content)
                                           WHERE ad_eg1.flg_available = 'Y'
                                             AND ad_eg1.id_exam_group = ad_eg.id_group_parent),
                                          0)) id_group_parent,
                               ad_eg.id_content
                          FROM ad_exam_group ad_eg
                         WHERE ad_eg.flg_available = 'Y'
                         START WITH ad_eg.id_group_parent IS NULL
                        CONNECT BY PRIOR ad_eg.id_exam_group = ad_eg.id_group_parent) def_data
                 WHERE def_data.lvl = l_level_array(c_level)
                   AND (def_data.id_group_parent IS NULL OR def_data.id_group_parent > 0)
                   AND NOT EXISTS (SELECT 0
                          FROM exam_group dest_tbl
                         WHERE dest_tbl.id_content = def_data.id_content);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_exam_group_def;

    -- searcheable loader method
    FUNCTION set_exams_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(5);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_EXAMS_SEARCH');
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        --insert of exams
        INSERT INTO exam_dep_clin_serv
            (id_exam_dep_clin_serv,
             id_exam,
             flg_type,
             id_institution,
             id_software,
             rank,
             flg_first_result,
             flg_mov_pat,
             id_external_sys,
             flg_execute,
             flg_timeout,
             flg_result_notes,
             flg_first_execute,
             flg_chargeable)
            SELECT seq_exam_dep_clin_serv.nextval,
                   def_data.id_exam,
                   flg_type,
                   i_institution,
                   i_software(pos_soft),
                   def_data.rank,
                   def_data.flg_first_result,
                   def_data.flg_mov_pat,
                   def_data.id_external_sys,
                   def_data.flg_execute,
                   def_data.flg_timeout,
                   def_data.flg_result_notes,
                   def_data.flg_first_execute,
                   def_data.flg_chargeable
              FROM (SELECT temp_data.id_exam,
                           temp_data.flg_type,
                           temp_data.rank,
                           temp_data.flg_first_result,
                           temp_data.flg_mov_pat,
                           temp_data.id_external_sys,
                           temp_data.flg_execute,
                           temp_data.flg_timeout,
                           temp_data.flg_result_notes,
                           temp_data.flg_first_execute,
                           temp_data.flg_chargeable,
                           row_number() over(PARTITION BY temp_data.id_exam, temp_data.flg_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON ad_e.id_content = a_e.id_content
                                               WHERE ad_e.id_exam = ad_ecs.id_exam
                                                 AND ad_e.flg_available = a_e.flg_available
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                     (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                              0),
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON ad_e.id_content = a_e.id_content
                                               WHERE ad_e.id_exam = ad_ecs.id_exam
                                                 AND ad_e.flg_available = a_e.flg_available
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ad_e.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)
                                                 AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                     (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                              0)) id_exam,
                                   ad_ecs.flg_type,
                                   ad_ecs.flg_first_result,
                                   ad_ecs.flg_mov_pat,
                                   ad_ecs.id_external_sys,
                                   ad_ecs.id_software,
                                   ad_emv.id_market,
                                   ad_emv.version,
                                   nvl(ad_ecs.rank, 0) rank,
                                   ad_ecs.flg_execute,
                                   ad_ecs.flg_timeout,
                                   ad_ecs.flg_result_notes,
                                   ad_ecs.flg_first_execute,
                                   ad_ecs.flg_chargeable
                            -- decode FKS to dest_vals
                              FROM ad_exam_clin_serv ad_ecs
                              JOIN ad_exam_mrk_vrs ad_emv
                                ON ad_emv.id_exam = ad_ecs.id_exam
                             WHERE ad_ecs.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_emv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_emv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_ecs.flg_type NOT IN ('A', 'M')
                               AND ad_ecs.id_clinical_service IS NULL) temp_data
                     WHERE temp_data.id_exam > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM exam_dep_clin_serv a_edcs
                     WHERE a_edcs.id_exam = def_data.id_exam
                       AND a_edcs.id_institution = i_institution
                       AND a_edcs.flg_type = def_data.flg_type
                       AND a_edcs.id_software = i_software(pos_soft));
    
        o_result_tbl := SQL%ROWCOUNT;
    
        --insert of groups
        INSERT INTO exam_dep_clin_serv
            (id_exam_dep_clin_serv,
             id_exam_group,
             flg_type,
             id_institution,
             id_software,
             rank,
             flg_first_result,
             flg_mov_pat,
             id_external_sys,
             flg_execute,
             flg_timeout,
             flg_result_notes,
             flg_first_execute,
             flg_chargeable)
            SELECT seq_exam_dep_clin_serv.nextval,
                   def_data.id_exam_group,
                   flg_type,
                   i_institution,
                   i_software(pos_soft),
                   def_data.rank,
                   def_data.flg_first_result,
                   def_data.flg_mov_pat,
                   def_data.id_external_sys,
                   def_data.flg_execute,
                   def_data.flg_timeout,
                   def_data.flg_result_notes,
                   def_data.flg_first_execute,
                   def_data.flg_chargeable
              FROM (SELECT temp_data.id_exam_group,
                           temp_data.flg_type,
                           temp_data.rank,
                           temp_data.flg_first_result,
                           temp_data.flg_mov_pat,
                           temp_data.id_external_sys,
                           temp_data.flg_execute,
                           temp_data.flg_timeout,
                           temp_data.flg_result_notes,
                           temp_data.flg_first_execute,
                           temp_data.flg_chargeable,
                           row_number() over(PARTITION BY temp_data.id_exam_group, temp_data.flg_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_e.id_exam_group
                                         FROM exam_group a_e
                                         JOIN ad_exam_group ad_e
                                           ON ad_e.id_content = a_e.id_content
                                        WHERE ad_e.id_exam_group = ad_ecs.id_exam_group
                                          AND ad_e.id_exam_group = ad_emv.id_exam_group
                                          AND ad_e.flg_available = ad_emv.flg_available
                                          AND ad_emv.flg_available = g_flg_available),
                                       0) id_exam_group,
                                   ad_ecs.flg_type,
                                   ad_ecs.flg_first_result,
                                   ad_ecs.flg_mov_pat,
                                   ad_ecs.id_external_sys,
                                   ad_ecs.id_software,
                                   ad_emv.id_market,
                                   ad_emv.version,
                                   nvl(ad_ecs.rank, 0) rank,
                                   ad_ecs.flg_execute,
                                   ad_ecs.flg_timeout,
                                   ad_ecs.flg_result_notes,
                                   ad_ecs.flg_first_execute,
                                   ad_ecs.flg_chargeable
                            -- decode FKS to dest_vals
                              FROM ad_exam_clin_serv ad_ecs
                              JOIN ad_exam_egp ad_emv
                                ON ad_emv.id_exam_group = ad_ecs.id_exam_group
                               AND ad_emv.flg_available = g_flg_available
                             WHERE ad_ecs.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_emv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_emv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_ecs.flg_type NOT IN ('A', 'M')
                               AND ad_ecs.id_clinical_service IS NULL) temp_data
                     WHERE temp_data.id_exam_group > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM exam_dep_clin_serv a_edcs
                     WHERE a_edcs.id_exam_group = def_data.id_exam_group
                       AND a_edcs.id_institution = i_institution
                       AND a_edcs.flg_type = def_data.flg_type
                       AND a_edcs.id_software = i_software(pos_soft));
    
        o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
    
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_exams_search;

    FUNCTION del_exams_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete exam_dep_clin_serv';
        g_func_name := upper('del_exams_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM alert.ref_exam_orig_dest reod
             WHERE EXISTS (SELECT 1
                      FROM exam_dep_clin_serv a_edcs
                     WHERE (a_edcs.id_exam_dep_clin_serv = reod.id_exam_dcs_orig OR
                           a_edcs.id_exam_dep_clin_serv = reod.id_exam_dcs_dest)
                       AND a_edcs.id_institution = i_institution
                       AND a_edcs.id_software IN
                           (SELECT /*+ dynamic_sampling(2)*/
                             column_value
                              FROM TABLE(CAST(i_software AS table_number)) p));
        
            DELETE FROM exam_room er
             WHERE EXISTS (SELECT 1
                      FROM exam_dep_clin_serv a_edcs
                     WHERE a_edcs.id_exam_dep_clin_serv = er.id_exam_dep_clin_serv
                       AND a_edcs.id_institution = i_institution
                       AND a_edcs.id_software IN
                           (SELECT /*+ dynamic_sampling(2)*/
                             column_value
                              FROM TABLE(CAST(i_software AS table_number)) p));
        
            DELETE FROM exam_dep_clin_serv a_edcs
             WHERE a_edcs.id_institution = i_institution
               AND a_edcs.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM alert.ref_exam_orig_dest reod
             WHERE EXISTS (SELECT 1
                      FROM exam_dep_clin_serv a_edcs
                     WHERE (a_edcs.id_exam_dep_clin_serv = reod.id_exam_dcs_orig OR
                           a_edcs.id_exam_dep_clin_serv = reod.id_exam_dcs_dest)
                       AND a_edcs.id_institution = i_institution);
        
            DELETE FROM exam_room er
             WHERE EXISTS (SELECT 1
                      FROM exam_dep_clin_serv a_edcs
                     WHERE a_edcs.id_exam_dep_clin_serv = er.id_exam_dep_clin_serv
                       AND a_edcs.id_institution = i_institution);
        
            DELETE FROM exam_dep_clin_serv a_edcs
             WHERE a_edcs.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_exams_search;

    FUNCTION set_exam_type_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(5);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_EXAM_TYPE_SEARCH');
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT INTO exam_type_group
            (id_exam_type_group, id_exam_type, id_exam, id_software, id_institution, flg_bypass_validation)
            SELECT seq_exam_type_group.nextval,
                   def_data.id_exam_type,
                   def_data.id_exam,
                   i_software(pos_soft),
                   i_institution,
                   def_data.flg_bypass_validation
              FROM (SELECT temp_data.id_exam_type,
                           temp_data.id_exam,
                           temp_data.flg_bypass_validation,
                           row_number() over(PARTITION BY temp_data.id_exam_type, temp_data.id_exam ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT ad_etg.id_exam_type,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON ad_e.id_content = a_e.id_content
                                               WHERE ad_e.id_exam = ad_etg.id_exam
                                                 AND ad_e.flg_available = a_e.flg_available
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                     (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                              0),
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON ad_e.id_content = a_e.id_content
                                               WHERE ad_e.id_exam = ad_etg.id_exam
                                                 AND ad_e.flg_available = a_e.flg_available
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ad_e.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)
                                                 AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                     (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                              0)) id_exam,
                                   ad_etg.flg_bypass_validation,
                                   ad_etg.id_software,
                                   ad_emv.id_market,
                                   ad_emv.version
                            -- decode FKS to dest_vals
                              FROM ad_exam_type_group ad_etg
                              JOIN ad_exam_mrk_vrs ad_emv
                                ON ad_emv.id_exam = ad_etg.id_exam
                             WHERE ad_etg.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_emv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_emv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_exam > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM exam_type_group a_etg
                     WHERE a_etg.id_exam_type = def_data.id_exam_type
                       AND a_etg.id_exam = def_data.id_exam
                       AND a_etg.id_software = i_software(pos_soft)
                       AND a_etg.id_institution = i_institution);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_exam_type_search;

    FUNCTION del_exam_type_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete exam_type_group';
        g_func_name := upper('del_exam_type_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM exam_type_group etg
             WHERE etg.id_institution = i_institution
               AND etg.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM exam_type_group etg
             WHERE etg.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_exam_type_search;

    FUNCTION set_exam_type_vs_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('SET_EXAM_TYPE_VS_SEARCH');
    
        INSERT INTO exam_type_vs
            (id_exam_type_vs, id_exam_type, id_vital_sign_unit_measure, flg_available)
            SELECT seq_exam_type_vs.nextval, def_data.id_exam_type, def_data.i_vital_sign_unit_measure, g_flg_available
              FROM (SELECT temp_data.id_exam_type,
                           temp_data.i_vital_sign_unit_measure,
                           row_number() over(PARTITION BY temp_data.id_exam_type, temp_data.i_vital_sign_unit_measure ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(ad_vsum.id_unit_measure,
                                          NULL,
                                          (SELECT a_vsum1.id_vital_sign_unit_measure
                                             FROM vital_sign_unit_measure a_vsum1
                                            WHERE a_vsum1.id_institution = i_institution
                                              AND a_vsum1.id_software = i_software(pos_soft)
                                              AND a_vsum1.id_unit_measure IS NULL
                                              AND a_vsum1.id_vital_sign = ad_vsum.id_vital_sign
                                              AND a_vsum1.age_min IS NULL
                                              AND rownum = 1),
                                          (SELECT a_vsum1.id_vital_sign_unit_measure
                                             FROM vital_sign_unit_measure a_vsum1
                                            WHERE a_vsum1.id_institution = i_institution
                                              AND a_vsum1.id_software = i_software(pos_soft)
                                              AND a_vsum1.id_unit_measure = ad_vsum.id_unit_measure
                                              AND a_vsum1.id_vital_sign = ad_vsum.id_vital_sign
                                              AND a_vsum1.age_min IS NULL
                                              AND rownum = 1)) i_vital_sign_unit_measure,
                                   -- decode FKS to dest_vals
                                   ad_vsum.id_vital_sign,
                                   ad_vsum.id_unit_measure,
                                   ad_etv.id_exam_type,
                                   ad_vsum.id_software,
                                   ad_vsum.id_market,
                                   ad_vsum.version
                              FROM ad_vital_sign_unit_measure ad_vsum
                              JOIN ad_exam_type_vs ad_etv
                                ON ad_etv.id_vital_sign_unit_measure = ad_vsum.id_vital_sign_unit_measure
                             WHERE ad_etv.flg_available = g_flg_available
                               AND ad_vsum.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_vsum.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_vsum.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.i_vital_sign_unit_measure > 0
               AND NOT EXISTS (SELECT 0
                      FROM exam_type_vs a_etv1
                     WHERE a_etv1.id_exam_type = def_data.id_exam_type
                       AND a_etv1.id_vital_sign_unit_measure = def_data.i_vital_sign_unit_measure
                       AND a_etv1.flg_available = g_flg_available);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_exam_type_vs_search;

    FUNCTION del_exam_type_vs_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete exam_type_vs';
        g_func_name := upper('del_exam_type_vs_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM exam_type_vs etvs
             WHERE EXISTS
             (SELECT 1
                      FROM vital_sign_unit_measure vsum
                     WHERE etvs.id_vital_sign_unit_measure = vsum.id_vital_sign_unit_measure
                       AND vsum.id_institution = i_institution
                       AND vsum.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                 column_value
                                                  FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM exam_type_vs etvs
             WHERE EXISTS (SELECT 1
                      FROM vital_sign_unit_measure vsum
                     WHERE etvs.id_vital_sign_unit_measure = vsum.id_vital_sign_unit_measure
                       AND vsum.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_exam_type_vs_search;

    FUNCTION set_exam_body_structure_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(5);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_EXAM_BODY_STRUCTURE_SEARCH');
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT INTO exam_body_structure
            (id_exam, id_body_structure, flg_available, flg_main_laterality)
            SELECT def_data.id_exam, def_data.id_body_structure, g_flg_available, def_data.flg_main_laterality
              FROM (SELECT temp_data.id_body_structure,
                           temp_data.id_exam,
                           temp_data.flg_main_laterality,
                           row_number() over(PARTITION BY temp_data.id_body_structure, temp_data.id_exam ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_bs.id_body_structure
                                         FROM body_structure a_bs
                                         JOIN ad_body_structure ad_bs
                                           ON a_bs.id_content = ad_bs.id_content
                                        WHERE ad_bs.id_body_structure = ad_ebs.id_body_structure
                                          AND ad_bs.flg_available = g_flg_available
                                          AND a_bs.flg_available = g_flg_available
                                          AND rownum = 1),
                                       0) id_body_structure,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON ad_e.id_content = a_e.id_content
                                               WHERE ad_e.id_exam = ad_ebs.id_exam
                                                 AND ad_e.flg_available = a_e.flg_available
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                     (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                              0),
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON ad_e.id_content = a_e.id_content
                                               WHERE ad_e.id_exam = ad_ebs.id_exam
                                                 AND ad_e.flg_available = a_e.flg_available
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ad_e.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)
                                                 AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                     (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                              0)) id_exam,
                                   ad_ebs.flg_main_laterality,
                                   ad_bsmv.id_market,
                                   ad_bsmv.version
                              FROM ad_exam_body_structure ad_ebs
                              JOIN ad_body_structure_mrk_vrs ad_bsmv
                                ON ad_bsmv.id_body_structure = ad_ebs.id_body_structure
                              JOIN ad_exam_mrk_vrs ad_emv
                                ON ad_emv.id_exam = ad_ebs.id_exam
                               AND ad_emv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_emv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                             WHERE ad_bsmv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_bsmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_body_structure > 0
                       AND temp_data.id_exam > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM exam_body_structure a_ebs
                     WHERE a_ebs.id_exam = def_data.id_exam
                       AND a_ebs.id_body_structure = def_data.id_body_structure
                       AND a_ebs.flg_available = g_flg_available);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_exam_body_structure_search;

    FUNCTION set_exam_questionnaire_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(5);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_EXAM_QUESTIONNAIRE_SEARCH');
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT INTO exam_questionnaire
            (id_exam_questionnaire,
             id_exam,
             id_questionnaire,
             flg_type,
             flg_mandatory,
             rank,
             flg_available,
             flg_time,
             id_exam_group,
             id_response,
             flg_copy,
             flg_validation,
             flg_exterior,
             id_unit_measure,
             id_institution)
            SELECT seq_exam_questionnaire.nextval,
                   def_data.id_exam,
                   def_data.id_questionnaire,
                   def_data.flg_type,
                   def_data.flg_mandatory,
                   def_data.rank,
                   def_data.flg_available,
                   def_data.flg_time,
                   def_data.id_exam_group,
                   def_data.id_response,
                   def_data.flg_copy,
                   def_data.flg_validation,
                   def_data.flg_exterior,
                   def_data.id_unit_measure,
                   i_institution
              FROM (SELECT temp_data.id_exam,
                           temp_data.id_questionnaire,
                           temp_data.flg_type,
                           temp_data.flg_mandatory,
                           temp_data.rank,
                           temp_data.flg_available,
                           temp_data.flg_time,
                           temp_data.id_response,
                           temp_data.id_exam_group,
                           temp_data.flg_copy,
                           temp_data.flg_validation,
                           temp_data.flg_exterior,
                           temp_data.id_unit_measure,
                           row_number() over(PARTITION BY temp_data.id_exam, temp_data.id_questionnaire, temp_data.id_exam_group, temp_data.flg_time, temp_data.id_response ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(ad_eq.id_exam,
                                          NULL,
                                          NULL,
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT a_e.id_exam
                                                       FROM exam a_e
                                                       JOIN ad_exam ad_e
                                                         ON ad_e.id_content = a_e.id_content
                                                      WHERE ad_e.id_exam = ad_eq.id_exam
                                                        AND ad_e.flg_available = a_e.flg_available
                                                        AND a_e.flg_available = g_flg_available
                                                        AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                            (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                                     0),
                                                 nvl((SELECT a_e.id_exam
                                                       FROM exam a_e
                                                       JOIN ad_exam ad_e
                                                         ON ad_e.id_content = a_e.id_content
                                                      WHERE ad_e.id_exam = ad_eq.id_exam
                                                        AND ad_e.flg_available = a_e.flg_available
                                                        AND a_e.flg_available = g_flg_available
                                                        AND ad_e.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(i_id_content AS table_varchar)) p)
                                                        AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                            (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                                     0))) id_exam,
                                   nvl((SELECT a_q.id_questionnaire
                                         FROM questionnaire a_q
                                         JOIN ad_questionnaire ad_q
                                           ON a_q.id_content = ad_q.id_content
                                        WHERE ad_q.id_questionnaire = ad_eq.id_questionnaire
                                          AND ad_q.flg_available = g_flg_available
                                          AND a_q.flg_available = g_flg_available),
                                       0) id_questionnaire,
                                   ad_eq.flg_type,
                                   ad_eq.flg_mandatory,
                                   ad_eq.rank,
                                   ad_eq.flg_available,
                                   ad_eq.flg_time,
                                   decode(ad_eq.id_response,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_r.id_response
                                                FROM response a_r
                                                JOIN ad_response ad_r
                                                  ON ad_r.id_content = a_r.id_content
                                               WHERE a_r.flg_available = g_flg_available
                                                 AND ad_r.flg_available = g_flg_available
                                                 AND ad_r.id_response = ad_eq.id_response),
                                              0)) id_response,
                                   decode(ad_eq.id_exam_group,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_eg.id_exam_group
                                                FROM exam_group a_eg
                                                JOIN ad_exam_group ad_eg
                                                  ON ad_eg.id_content = a_eg.id_content
                                               WHERE ad_eg.flg_available = g_flg_available
                                                 AND ad_eg.id_exam_group = ad_eq.id_exam_group),
                                              0)) id_exam_group,
                                   ad_eq.flg_copy,
                                   ad_eq.flg_validation,
                                   ad_eq.flg_exterior,
                                   decode(ad_eq.id_unit_measure,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_ums.id_unit_measure_subtype
                                                FROM unit_measure_subtype a_ums
                                               WHERE a_ums.id_unit_measure_subtype = ad_eq.id_unit_measure),
                                              0)) id_unit_measure,
                                   ad_eq.id_market,
                                   ad_eq.version
                            -- decode FKS to dest_vals
                              FROM ad_exam_questionnaire ad_eq
                             WHERE ad_eq.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_eq.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND (def_data.id_exam > 0 OR def_data.id_exam IS NULL)
               AND (def_data.id_exam_group > 0 OR def_data.id_exam_group IS NULL)
               AND (def_data.id_response > 0 OR def_data.id_response IS NULL)
               AND (def_data.id_unit_measure > 0 OR def_data.id_unit_measure IS NULL)
               AND def_data.id_questionnaire > 0
               AND EXISTS (SELECT 0
                      FROM questionnaire_response a_qr
                     WHERE a_qr.id_questionnaire = def_data.id_questionnaire
                       AND (a_qr.id_response = def_data.id_response OR
                           (a_qr.id_response IS NULL AND def_data.id_response IS NULL)))
               AND NOT EXISTS
             (SELECT 0
                      FROM exam_questionnaire a_eq
                     WHERE (a_eq.id_exam = def_data.id_exam OR (a_eq.id_exam IS NULL AND def_data.id_exam IS NULL))
                       AND (a_eq.id_exam_group = def_data.id_exam_group OR
                           (a_eq.id_exam_group IS NULL AND def_data.id_exam_group IS NULL))
                       AND (a_eq.id_response = def_data.id_response OR
                           (a_eq.id_response IS NULL AND def_data.id_response IS NULL))
                       AND a_eq.id_questionnaire = id_questionnaire
                       AND a_eq.id_institution = i_institution
                       AND a_eq.flg_time = def_data.flg_time
                       AND a_eq.flg_available = g_flg_available);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_exam_questionnaire_search;

    FUNCTION del_exam_questionnaire_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete exam_questionnaire';
        g_func_name := upper('del_exam_questionnaire_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE FROM exam_questionnaire eq
             WHERE eq.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_exam_questionnaire_search;

    FUNCTION set_exam_egp_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(5);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_EXAM_EGP_SEARCH');
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT INTO exam_egp
            (id_exam_egp, id_exam_group, id_exam, rank)
            SELECT seq_exam_egp.nextval, def_data.id_exam_group, def_data.id_exam, def_data.rank
              FROM (SELECT temp_data.id_exam,
                           temp_data.id_exam_group,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_exam, temp_data.id_exam_group ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_eg.id_exam_group
                                         FROM exam_group a_eg
                                         JOIN ad_exam_group ad_eg
                                           ON ad_eg.id_content = a_eg.id_content
                                        WHERE ad_eg.flg_available = g_flg_available
                                          AND ad_eg.id_exam_group = ad_ee.id_exam_group),
                                       0) id_exam_group,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON ad_e.id_content = a_e.id_content
                                               WHERE ad_e.id_exam = ad_ee.id_exam
                                                 AND ad_e.flg_available = a_e.flg_available
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                     (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                              0),
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON ad_e.id_content = a_e.id_content
                                               WHERE ad_e.id_exam = ad_ee.id_exam
                                                 AND ad_e.flg_available = a_e.flg_available
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ad_e.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)
                                                 AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                     (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                              0)) id_exam,
                                   ad_ee.rank,
                                   ad_ee.id_market,
                                   ad_ee.version
                              FROM ad_exam_egp ad_ee
                             WHERE ad_ee.flg_available = g_flg_available
                               AND ad_ee.id_market IN (SELECT /*+dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_ee.version IN (SELECT /*+dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_exam > 0
                       AND temp_data.id_exam_group > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM exam_egp a_ee
                     WHERE a_ee.id_exam_group = def_data.id_exam_group
                       AND a_ee.id_exam = def_data.id_exam);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_exam_egp_search;

    -- frequent loader method
    FUNCTION set_exams_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_id_content        IN table_varchar DEFAULT table_varchar(),
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(5);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_func_name := upper('SET_EXAMS_FREQ');
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        --insert of exams
        INSERT INTO exam_dep_clin_serv
            (id_exam_dep_clin_serv,
             id_exam,
             id_dep_clin_serv,
             flg_type,
             rank,
             adw_last_update,
             id_software,
             id_institution,
             flg_first_result,
             flg_mov_pat,
             id_external_sys,
             flg_execute,
             flg_timeout,
             flg_result_notes,
             flg_first_execute,
             flg_chargeable)
            SELECT seq_exam_dep_clin_serv.nextval,
                   def_data.id_exam,
                   i_dep_clin_serv_out,
                   def_data.flg_type,
                   def_data.rank,
                   SYSDATE,
                   i_software(pos_soft),
                   i_institution,
                   def_data.flg_first_result,
                   def_data.flg_mov_pat,
                   def_data.id_external_sys,
                   def_data.flg_execute,
                   def_data.flg_timeout,
                   def_data.flg_result_notes,
                   def_data.flg_first_execute,
                   def_data.flg_chargeable
              FROM (SELECT temp_data.id_exam,
                           temp_data.flg_type,
                           temp_data.flg_first_result,
                           temp_data.flg_mov_pat,
                           temp_data.id_external_sys,
                           temp_data.flg_execute,
                           temp_data.flg_timeout,
                           temp_data.flg_result_notes,
                           temp_data.flg_first_execute,
                           temp_data.flg_chargeable,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_exam, temp_data.flg_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON ad_e.id_content = a_e.id_content
                                               WHERE ad_e.id_exam = ad_ecs.id_exam
                                                 AND ad_e.flg_available = a_e.flg_available
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                     (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                              0),
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON ad_e.id_content = a_e.id_content
                                               WHERE ad_e.id_exam = ad_ecs.id_exam
                                                 AND ad_e.flg_available = a_e.flg_available
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ad_e.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)
                                                 AND ((l_flg_type IS NULL AND a_e.flg_type = a_e.flg_type) OR
                                                     (l_flg_type IS NOT NULL AND a_e.flg_type = l_flg_type))),
                                              0)) id_exam,
                                   ad_ecs.flg_type,
                                   ad_ecs.flg_first_result,
                                   ad_ecs.flg_mov_pat,
                                   ad_ecs.id_external_sys,
                                   ad_ecs.id_software,
                                   ad_emv.id_market,
                                   ad_emv.version,
                                   nvl(ad_ecs.rank, 0) rank,
                                   ad_ecs.flg_execute,
                                   ad_ecs.flg_timeout,
                                   ad_ecs.flg_result_notes,
                                   ad_ecs.flg_first_execute,
                                   ad_ecs.flg_chargeable
                              FROM ad_exam_clin_serv ad_ecs
                              JOIN ad_exam_mrk_vrs ad_emv
                                ON (ad_emv.id_exam = ad_ecs.id_exam AND
                                   ad_emv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                      column_value
                                       FROM TABLE(CAST(i_mkt AS table_number)) p) AND
                                   ad_emv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p))
                             WHERE ad_ecs.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_ecs.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
                     WHERE temp_data.id_exam > 0) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM exam_dep_clin_serv edcs
                     WHERE edcs.id_exam = def_data.id_exam
                       AND edcs.flg_type = 'P'
                       AND edcs.id_institution = i_institution
                       AND edcs.id_software = i_software(pos_soft))
               AND NOT EXISTS (SELECT 0
                      FROM exam_dep_clin_serv edcs
                     WHERE edcs.id_exam = def_data.id_exam
                       AND edcs.id_dep_clin_serv = i_dep_clin_serv_out
                       AND edcs.flg_type = def_data.flg_type
                       AND edcs.id_software = i_software(pos_soft));
    
        o_result_tbl := SQL%ROWCOUNT;
    
        --insert of groups
    
        INSERT INTO exam_dep_clin_serv
            (id_exam_dep_clin_serv,
             id_exam_group,
             id_dep_clin_serv,
             flg_type,
             rank,
             adw_last_update,
             id_software,
             id_institution,
             flg_first_result,
             flg_mov_pat,
             id_external_sys,
             flg_execute,
             flg_timeout,
             flg_result_notes,
             flg_first_execute,
             flg_chargeable)
            SELECT seq_exam_dep_clin_serv.nextval,
                   def_data.id_exam_group,
                   i_dep_clin_serv_out,
                   def_data.flg_type,
                   def_data.rank,
                   SYSDATE,
                   i_software(pos_soft),
                   i_institution,
                   def_data.flg_first_result,
                   def_data.flg_mov_pat,
                   def_data.id_external_sys,
                   def_data.flg_execute,
                   def_data.flg_timeout,
                   def_data.flg_result_notes,
                   def_data.flg_first_execute,
                   def_data.flg_chargeable
              FROM (SELECT temp_data.id_exam_group,
                           temp_data.flg_type,
                           temp_data.flg_first_result,
                           temp_data.flg_mov_pat,
                           temp_data.id_external_sys,
                           temp_data.flg_execute,
                           temp_data.flg_timeout,
                           temp_data.flg_result_notes,
                           temp_data.flg_first_execute,
                           temp_data.flg_chargeable,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_exam_group, temp_data.flg_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_e.id_exam_group
                                         FROM exam_group a_e
                                         JOIN ad_exam_group ad_e
                                           ON ad_e.id_content = a_e.id_content
                                        WHERE ad_e.id_exam_group = ad_ecs.id_exam_group
                                          AND ad_e.id_exam_group = ad_emv.id_exam_group
                                          AND ad_e.flg_available = ad_emv.flg_available
                                          AND ad_emv.flg_available = g_flg_available),
                                       0) id_exam_group,
                                   ad_ecs.flg_type,
                                   ad_ecs.flg_first_result,
                                   ad_ecs.flg_mov_pat,
                                   ad_ecs.id_external_sys,
                                   ad_ecs.id_software,
                                   ad_emv.id_market,
                                   ad_emv.version,
                                   nvl(ad_ecs.rank, 0) rank,
                                   ad_ecs.flg_execute,
                                   ad_ecs.flg_timeout,
                                   ad_ecs.flg_result_notes,
                                   ad_ecs.flg_first_execute,
                                   ad_ecs.flg_chargeable
                              FROM ad_exam_clin_serv ad_ecs
                            --used as mkt_vrs
                              JOIN ad_exam_egp ad_emv
                                ON ad_emv.id_exam_group = ad_ecs.id_exam_group
                               AND ad_emv.flg_available = g_flg_available
                               AND ad_emv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_emv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                             WHERE ad_ecs.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_ecs.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
                     WHERE temp_data.id_exam_group > 0) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM exam_dep_clin_serv edcs
                     WHERE edcs.id_exam_group = def_data.id_exam_group
                       AND edcs.flg_type = 'P'
                       AND edcs.id_institution = i_institution
                       AND edcs.id_software = i_software(pos_soft))
               AND NOT EXISTS (SELECT 0
                      FROM exam_dep_clin_serv edcs
                     WHERE edcs.id_exam_group = def_data.id_exam_group
                       AND edcs.id_dep_clin_serv = i_dep_clin_serv_out
                       AND edcs.flg_type = def_data.flg_type
                       AND edcs.id_software = i_software(pos_soft));
    
        o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END set_exams_freq;

    -- global vars

    PROCEDURE reset_cfg_done IS
    
    BEGIN
        g_cfg_done := 'FALSE';
    END reset_cfg_done;

    FUNCTION get_cfg_done RETURN VARCHAR2 IS
    
    BEGIN
        RETURN g_cfg_done;
    END get_cfg_done;

BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);
    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;
    g_array_size    := 100;
    g_array_size1   := 10000;
    g_cfg_done      := 'FALSE';
END pk_exam_prm;
/
