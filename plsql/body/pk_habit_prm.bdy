/*-- Last Change Revision: $Rev: 1940428 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-03-16 10:39:51 +0000 (seg, 16 mar 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_habit_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_Habit_prm';

    g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_habit_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('habit.code_habit.');
    
    BEGIN
        INSERT INTO habit
            (id_habit, code_habit, rank, flg_available, id_content)
            SELECT seq_habit.nextval, l_code_translation || seq_habit.currval, rank, g_flg_available, id_content
            FROM   (SELECT ad_h.id_content, ad_h.rank
                    FROM   ad_habit ad_h
                    WHERE  ad_h.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT 0
                            FROM   habit a_h
                            WHERE  a_h.id_content = ad_h.id_content
                                   AND a_h.flg_available = g_flg_available)) def_data;
    
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
    END load_habit_def;

    FUNCTION ld_habit_characterization_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('habit_characterization.code_habit_characterization.');
    
    BEGIN
        INSERT INTO habit_characterization
            (id_habit_characterization, code_habit_characterization, flg_available, rank, id_content)
            SELECT seq_habit_characterization.nextval,
                   l_code_translation || seq_habit_characterization.currval,
                   g_flg_available,
                   rank,
                   id_content
            FROM   (SELECT ad_hc.id_habit_characterization, ad_hc.rank, ad_hc.id_content
                    FROM   ad_habit_characterization ad_hc
                    WHERE  ad_hc.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT 0
                            FROM   habit_characterization a_hc
                            WHERE  a_hc.id_content = ad_hc.id_content
                                   AND a_hc.flg_available = g_flg_available)) def_data;
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
    END ld_habit_characterization_def;
    -- searcheable loader method

    FUNCTION set_habit_inst_search
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
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('set_habit_inst_search');
    
        INSERT INTO habit_inst
            (id_habit, flg_available, id_institution)
            SELECT def_data.id_habit, g_flg_available, i_institution
            FROM   (SELECT temp_data.id_habit,
                           row_number() over(PARTITION BY temp_data.id_habit ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_h1.id_habit
                                              FROM   habit a_h1
                                              WHERE  a_h1.flg_available = g_flg_available
                                                     AND a_h1.id_content = ad_h.id_content),
                                              0),
                                          nvl((SELECT a_h1.id_habit
                                              FROM   habit a_h1
                                              WHERE  a_h1.flg_available = g_flg_available
                                                     AND a_h1.id_content = ad_h.id_content
                                                     AND ad_h.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                          FROM   TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_habit,
                                   ad_hmv.id_market,
                                   ad_hmv.version
                            -- decode FKS to dest_vals
                            FROM   ad_habit_mrk_vrs ad_hmv
                            INNER  JOIN ad_habit ad_h
                            ON     ad_h.id_habit = ad_hmv.id_habit
                            WHERE  ad_h.flg_available = g_flg_available
                                   AND
                                   ad_hmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                         column_value
                                                        FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND
                                   ad_hmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                      FROM   TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
            WHERE  def_data.records_count = 1
                   AND id_habit > 0
                   AND NOT EXISTS (SELECT 0
                    FROM   habit_inst hi
                    WHERE  hi.id_habit = def_data.id_habit
                           AND hi.id_institution = i_institution
                           AND hi.flg_available = g_flg_available);
    
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
    END set_habit_inst_search;

    FUNCTION del_habit_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete habit_inst';
        g_func_name := upper('del_habit_inst_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_sw_list
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_sw_list.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE FROM habit_inst hi
             WHERE hi.id_institution = i_institution;
        
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
    END del_habit_inst_search;

    FUNCTION set_habit_charact_rel_search
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
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('SET_HABIT_CHARACT_REL_SEARCH');
    
        INSERT INTO habit_charact_relation
            (id_habit_characterization, id_habit, flg_available)
            SELECT def_data.id_habit_characterization, def_data.id_habit, g_flg_available
            FROM   (SELECT temp_data.id_habit,
                           temp_data.id_habit_characterization,
                           row_number() over(PARTITION BY temp_data.id_habit, temp_data.id_habit_characterization ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_h1.id_habit
                                              FROM   habit a_h1
                                              WHERE  a_h1.id_content = ad_h.id_content
                                                     AND a_h1.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_h1.id_habit
                                              FROM   habit a_h1
                                              WHERE  a_h1.id_content = ad_h.id_content
                                                     AND a_h1.flg_available = g_flg_available
                                                     AND a_h1.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                          FROM   TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_habit,
                                   (nvl((SELECT a_hc1.id_habit_characterization
                                        FROM   habit_characterization a_hc1
                                        WHERE  a_hc1.id_content = ad_hc.id_content
                                               AND a_hc1.flg_available = g_flg_available),
                                        0)) id_habit_characterization,
                                   ad_hmv.id_market,
                                   ad_hmv.version
                            -- decode FKS to dest_vals
                            FROM   ad_habit_charact_relation ad_hcr
                            INNER  JOIN ad_habit ad_h
                            ON     ad_h.id_habit = ad_hcr.id_habit
                            INNER  JOIN ad_habit_mrk_vrs ad_hmv
                            ON     ad_hmv.id_habit = ad_h.id_habit
                            INNER  JOIN ad_habit_characterization ad_hc
                            ON     ad_hc.id_habit_characterization = ad_hcr.id_habit_characterization
                            INNER  JOIN ad_habit_charac_mrk_vrs ad_hcmv
                            ON     ad_hcmv.id_habit_characterization = ad_hc.id_habit_characterization
                            WHERE  ad_hcr.flg_available = g_flg_available
                                   AND ad_h.flg_available = g_flg_available
                                   AND ad_hc.flg_available = g_flg_available
                                   AND ad_hcmv.id_market IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                         column_value
                                        FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND
                                   ad_hcmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                        column_value
                                                       FROM   TABLE(CAST(i_vers AS table_varchar)) p)
                                   AND
                                   ad_hmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                         column_value
                                                        FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND
                                   ad_hmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                      FROM   TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
            WHERE  def_data.records_count = 1
                   AND def_data.id_habit > 0
                   AND def_data.id_habit_characterization > 0
                   AND NOT EXISTS
             (SELECT 0
                    FROM   habit_charact_relation a_hcr1
                    WHERE  a_hcr1.id_habit = def_data.id_habit
                           AND a_hcr1.id_habit_characterization = def_data.id_habit_characterization);
    
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
    END set_habit_charact_rel_search;

    -- frequent loader method

    FUNCTION del_habit_charact_rel_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete habit_inst';
        g_func_name := upper('del_habit_charact_rel_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_sw_list
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_sw_list.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE FROM habit_charact_relation hcr
             WHERE EXISTS (SELECT 1
                      FROM habit_inst hi
                     WHERE hi.id_habit = hcr.id_habit
                       AND hi.id_institution = i_institution);
        
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
    END del_habit_charact_rel_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_habit_prm;
/