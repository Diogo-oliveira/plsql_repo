/*-- Last Change Revision: $Rev: 1904835 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-05 09:32:58 +0100 (qua, 05 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_calculator_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_CALCULATOR_prm';
    soft_pos        NUMBER := 1;
    -- g_table_name    t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_calc_soft_inst_search
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
        g_func_name := upper('set_calc_soft_inst_search');
        INSERT INTO calc_soft_inst
            (id_calculator, id_software, id_institution, flg_available)
            SELECT def_data.id_calculator, i_software(soft_pos), i_institution, def_data.flg_available
              FROM (SELECT temp_data.id_calculator,
                           temp_data.flg_available,
                           row_number() over(PARTITION BY temp_data.id_calculator ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT csi.id_calculator, csi.flg_available, csi.id_software, cmv.id_market, cmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.calc_mrk_vrs cmv
                             INNER JOIN alert_default.calc_soft_inst csi
                                ON csi.id_calculator = cmv.id_calculator
                            
                             WHERE csi.flg_available = g_flg_available
                               AND csi.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND cmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND cmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM calc_soft_inst csi1
                     WHERE csi1.id_calculator = def_data.id_calculator
                       AND csi1.id_software = i_software(soft_pos)
                       AND csi1.flg_available = g_flg_available
                       AND csi1.id_institution = i_institution);
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
    END set_calc_soft_inst_search;

    FUNCTION del_calc_soft_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete calc_soft_inst';
        g_func_name := upper('del_calc_soft_inst_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM calc_soft_inst csi
             WHERE csi.id_institution = i_institution
               AND csi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM calc_soft_inst csi
             WHERE csi.id_institution = i_institution;
        
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
    END del_calc_soft_inst_search;

    FUNCTION set_calc_field_si_search
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
    
        g_func_name := upper('set_calc_field_si_search');
        INSERT INTO calc_field_soft_inst
            (id_calculator, id_calc_field, id_unit_measure, format, id_institution, id_software)
        
            SELECT def_data.id_calculator,
                   def_data.id_calc_field,
                   def_data.id_unit_measure,
                   def_data.format,
                   i_institution,
                   i_software(soft_pos)
              FROM (SELECT temp_data.id_calculator,
                           temp_data.id_calc_field,
                           temp_data.id_unit_measure,
                           temp_data.format,
                           row_number() over(PARTITION BY temp_data.id_calculator, temp_data.id_calc_field
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT csfi.id_calculator,
                                   csfi.id_calc_field,
                                   csfi.id_unit_measure,
                                   csfi.format,
                                   csfi.id_software,
                                   cfmv.id_market,
                                   cfmv.version
                            
                            -- decode FKS to dest_vals
                              FROM alert_default.calc_field_mrk_vrs cfmv
                             INNER JOIN alert_default.calc_field_soft_inst csfi
                                ON csfi.id_calc_field = cfmv.id_calc_field
                               AND csfi.version = cfmv.version
                               AND csfi.id_market = cfmv.id_market
                             WHERE csfi.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND cfmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND cfmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM calc_field_soft_inst cfsi1
                     WHERE cfsi1.id_calculator = def_data.id_calculator
                       AND cfsi1.id_software = i_software(soft_pos)
                       AND cfsi1.id_unit_measure = id_unit_measure
                       AND cfsi1.id_institution = i_institution);
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
    END set_calc_field_si_search;

    FUNCTION del_calc_field_si_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete calc_field_soft_inst';
        g_func_name := upper('del_calc_field_si_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM calc_field_soft_inst cfsi
             WHERE cfsi.id_institution = i_institution
               AND cfsi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM calc_field_soft_inst cfsi
             WHERE cfsi.id_institution = i_institution;
        
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
    END del_calc_field_si_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_calculator_prm;
/