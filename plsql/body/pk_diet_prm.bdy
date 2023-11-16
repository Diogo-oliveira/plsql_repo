/*-- Last Change Revision: $Rev: 1904835 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-05 09:32:58 +0100 (qua, 05 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_diet_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_diet_prm';
    pos_soft        NUMBER := 1;
    -- g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_diet_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('diet.code_diet.');
        l_level_array      table_number := table_number();
    BEGIN
    
        SELECT DISTINCT LEVEL BULK COLLECT
          INTO l_level_array
          FROM alert_default.diet d
         WHERE d.flg_available = g_flg_available
         START WITH d.id_diet_parent IS NULL
        CONNECT BY PRIOR d.id_diet = d.id_diet_parent
         ORDER BY LEVEL ASC;
    
        FORALL c_level IN 1 .. l_level_array.count
        
            INSERT INTO diet
                (id_diet,
                 code_diet,
                 id_diet_parent,
                 flg_available,
                 adw_last_update,
                 rank,
                 id_diet_type,
                 id_content,
                 quantity_default,
                 id_unit_measure,
                 energy_quantity_value,
                 id_unit_measure_energy)
                SELECT seq_diet.nextval,
                       l_code_translation || seq_diet.currval,
                       id_diet_parent,
                       g_flg_available,
                       SYSDATE,
                       rank,
                       id_diet_type,
                       id_content,
                       quantity_default,
                       id_unit_measure,
                       energy_quantity_value,
                       id_unit_measure_energy
                  FROM (SELECT d.id_diet,
                               d.id_content,
                               decode(d.id_diet_parent,
                                      NULL,
                                      NULL,
                                      nvl((SELECT dd.id_diet
                                            FROM diet dd
                                            JOIN alert_default.diet ad
                                              ON dd.id_content = ad.id_content
                                           WHERE ad.id_diet = d.id_diet_parent
                                             AND dd.flg_available = g_flg_available
                                             AND ad.flg_available = g_flg_available),
                                          -1)) id_diet_parent,
                               d.rank,
                               d.id_diet_type,
                               d.quantity_default,
                               d.id_unit_measure,
                               d.energy_quantity_value,
                               d.id_unit_measure_energy,
                               LEVEL lvl
                          FROM alert_default.diet d
                         WHERE d.flg_available = g_flg_available
                        
                         START WITH d.id_diet_parent IS NULL
                        CONNECT BY PRIOR d.id_diet = d.id_diet_parent) def_data
                 WHERE def_data.lvl = l_level_array(c_level)
                   AND NOT EXISTS (SELECT 0
                          FROM diet dest_tbl
                         WHERE dest_tbl.id_content = def_data.id_content
                           AND dest_tbl.flg_available = g_flg_available)
                   AND (def_data.id_diet_parent > 0 OR def_data.id_diet_parent IS NULL);
    
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
    END load_diet_def;
    -- searcheable loader method
    FUNCTION set_diet_instit_soft_search
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
        g_func_name := upper('set_diet_instit_soft_search');
        INSERT INTO diet_instit_soft
            (id_diet, flg_available, id_software, id_institution)
            SELECT def_data.i_diet, g_flg_available, i_software(pos_soft), i_institution
              FROM (SELECT temp_data.i_diet,
                           row_number() over(PARTITION BY temp_data.i_diet
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT dis.rowid l_row,
                                   (nvl((SELECT da.id_diet
                                          FROM diet da
                                         WHERE da.id_content = d.id_content
                                           AND da.flg_available = g_flg_available),
                                        0)) i_diet,
                                   dis.id_software,
                                   dmv.id_market,
                                   dmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.diet_mrk_vrs dmv
                             INNER JOIN alert_default.diet_instit_soft dis
                                ON dis.id_diet = dmv.id_diet
                             INNER JOIN alert_default.diet d
                                ON d.id_diet = dis.id_diet
                             WHERE dis.flg_available = g_flg_available
                                  
                               AND d.flg_available = g_flg_available
                               AND dis.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND dmv.id_market IN (SELECT /*+ dynamic_sampling(p 2) */
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND dmv.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND i_diet != 0
               AND NOT EXISTS (SELECT 0
                      FROM diet_instit_soft dis1
                     WHERE dis1.id_diet = def_data.i_diet
                       AND dis1.id_institution = i_institution
                       AND dis1.id_software = i_software(pos_soft)
                       AND dis1.flg_available = g_flg_available);
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
    END set_diet_instit_soft_search;

-- frequent loader method

	FUNCTION del_diet_instit_soft_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete diet_instit_soft';
        g_func_name := upper('del_diet_instit_soft_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM diet_instit_soft dis
             WHERE dis.id_institution = i_institution
               AND dis.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM diet_instit_soft dis
             WHERE dis.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
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
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_diet_instit_soft_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_diet_prm;
/