/*-- Last Change Revision: $Rev: 1905124 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-06 14:57:52 +0100 (qui, 06 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_transfer_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_TRANSFER_prm';

    -- g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_transfer_option_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('TRANSFER_OPTION.code_TRANSFER_OPTION.');
    BEGIN
        g_func_name := upper('load_TRANSFER_OPTION_def');
        INSERT INTO transfer_option
            (id_transfer_option, code_transfer_option, flg_available, id_content)
        
            SELECT seq_transfer_option.nextval,
                   l_code_translation || seq_transfer_option.currval,
                   def_data.flg_available,
                   def_data.id_content
              FROM (SELECT source_tbl.flg_available, source_tbl.id_content
                      FROM alert_default.transfer_option source_tbl
                     WHERE source_tbl.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM transfer_option dest_tbl
                             WHERE dest_tbl.id_content = source_tbl.id_content
                               AND dest_tbl.flg_available = g_flg_available)) def_data;
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
    END load_transfer_option_def;
    -- searcheable loader method

    -- frequent loader method
    FUNCTION set_transfer_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_Transfer_freq');
        INSERT INTO transfer_opt_dcs
            (id_transfer_option, id_dep_clin_serv)
            SELECT def_data.alert_topt, i_dep_clin_serv_out
              FROM (SELECT temp_data.alert_topt,
                           row_number() over(PARTITION BY temp_data.alert_topt
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) frecords_count
                      FROM (SELECT nvl((SELECT topt1.id_transfer_option
                                         FROM transfer_option topt1
                                        WHERE topt1.id_content = topt.id_content
                                          AND topt1.flg_available = g_flg_available),
                                       0) alert_topt,
                                   tomv.id_market,
                                   tomv.version
                              FROM alert_default.transfer_opt_clin_serv tocs
                             INNER JOIN alert_default.transfer_option topt
                                ON (topt.id_transfer_option = tocs.id_transfer_option)
                             INNER JOIN alert_default.transfer_option_mrk_vrs tomv
                                ON (tomv.id_transfer_option = tocs.id_transfer_option AND
                                   tomv.id_market IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                                        column_value
                                                         FROM TABLE(CAST(i_mkt AS table_number)) p) AND
                                   tomv.version IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p))
                             WHERE tocs.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)
                               AND topt.flg_available = g_flg_available) temp_data
                     WHERE temp_data.alert_topt > 0) def_data
             WHERE def_data.frecords_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM transfer_opt_dcs tod
                     WHERE tod.id_dep_clin_serv = i_dep_clin_serv_out
                       AND tod.id_transfer_option = def_data.alert_topt);
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
    END set_transfer_freq;

    FUNCTION del_transfer_freq
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
        o_dcs_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete transfer_opt_dcs';
        g_func_name := upper('del_transfer_freq');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            SELECT dcs.id_dep_clin_serv
              BULK COLLECT
              INTO o_dcs_list
              FROM dep_clin_serv dcs
             INNER JOIN department d
                ON (d.id_department = dcs.id_department)
             INNER JOIN dept dp
                ON (dp.id_dept = d.id_dept)
             INNER JOIN software_dept sd
                ON (sd.id_dept = dp.id_dept)
             WHERE dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND d.id_institution = i_institution
               AND d.id_institution = dp.id_institution
               AND dcs.id_clinical_service != 0
               AND sd.id_software IN (SELECT /*+ opt_estimate(area_list rows = 2)*/
                                       column_value
                                        FROM TABLE(CAST(i_software AS table_number)) sw_list);
        ELSE
            SELECT dcs.id_dep_clin_serv
              BULK COLLECT
              INTO o_dcs_list
              FROM dep_clin_serv dcs
             INNER JOIN department d
                ON (d.id_department = dcs.id_department)
             INNER JOIN dept dp
                ON (dp.id_dept = d.id_dept)
             INNER JOIN software_dept sd
                ON (sd.id_dept = dp.id_dept)
             WHERE dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND d.id_institution = i_institution
               AND d.id_institution = dp.id_institution
               AND dcs.id_clinical_service != 0;
        END IF;
    
        DELETE FROM transfer_opt_dcs todcs
         WHERE todcs.id_dep_clin_serv IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(o_dcs_list AS table_number)) p);
    
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
    END del_transfer_freq;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_transfer_prm;
/
