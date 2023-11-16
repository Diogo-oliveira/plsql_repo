/*-- Last Change Revision: $Rev: 1905124 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-06 14:57:52 +0100 (qui, 06 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_unit_measure_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_unit_measure_prm';
    pos_soft        NUMBER := 1;

    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_unit_mea_si_search
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
        g_func_name := upper('set_unit_mea_si_search');
        INSERT INTO unit_mea_soft_inst
            (id_unit_mea_soft_inst, id_unit_measure, flg_available, flg_prescription, id_institution, id_software)
            SELECT seq_unit_mea_soft_inst.nextval,
                   def_data.id_unit_measure,
                   def_data.flg_available,
                   def_data.flg_prescription,
                   i_institution,
                   i_software(pos_soft)
              FROM (SELECT temp_data.id_unit_measure,
                           temp_data.flg_available,
                           temp_data.flg_prescription,
                           row_number() over(PARTITION BY temp_data.id_unit_measure
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT umsi.id_unit_measure,
                                   umsi.flg_available,
                                   umsi.flg_prescription,
                                   umsi.id_software,
                                   umsi.id_market,
                                   umsi.version
                            -- decode FKS to dest_vals
                              FROM alert_default.unit_mea_soft_inst umsi
                             WHERE umsi.flg_available = g_flg_available
                               AND umsi.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND umsi.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND umsi.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
                  
               AND NOT EXISTS (SELECT 0
                      FROM unit_mea_soft_inst umsi1
                     WHERE umsi1.id_unit_measure = def_data.id_unit_measure
                       AND umsi1.id_institution = i_institution
                       AND umsi1.flg_available = g_flg_available
                       AND umsi1.id_software = i_software(pos_soft));
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
    END set_unit_mea_si_search;
    -- frequent loader method

    FUNCTION del_unit_mea_si_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete unit_mea_soft_inst';
        g_func_name := upper('del_unit_mea_si_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM unit_mea_soft_inst umsi
             WHERE umsi.id_institution = i_institution
               AND umsi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM unit_mea_soft_inst umsi
             WHERE umsi.id_institution = i_institution;
        
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
    END del_unit_mea_si_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_unit_measure_prm;
/