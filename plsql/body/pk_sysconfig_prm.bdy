/*-- Last Change Revision: $Rev: 1905056 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-06 11:20:59 +0100 (qui, 06 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_sysconfig_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_sysconfig_prm';

    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_sysconfig_search
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
        g_func_name := upper('set_sysconfig_search');
        INSERT INTO sys_config
            (id_sys_config,
             id_institution,
             id_software,
             id_market,
             VALUE,
             desc_sys_config,
             fill_type,
             client_configuration,
             internal_configuration,
             global_configuration,
             flg_schema)
            SELECT def_data.id_sys_config,
                   def_data.id_institution,
                   def_data.id_software,
                   def_data.id_market,
                   def_data.value,
                   def_data.desc_sys_config,
                   def_data.fill_type,
                   def_data.client_configuration,
                   def_data.internal_configuration,
                   def_data.global_configuration,
                   def_data.flg_schema
              FROM (SELECT temp_data.id_sys_config,
                           i_institution id_institution,
                           temp_data.id_software,
                           temp_data.id_market,
                           temp_data.value,
                           temp_data.desc_sys_config,
                           temp_data.fill_type,
                           temp_data.client_configuration,
                           temp_data.internal_configuration,
                           temp_data.global_configuration,
                           temp_data.flg_schema,
                           row_number() over(PARTITION BY temp_data.id_sys_config
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC) records_count
                      FROM (SELECT src_tbl.id_sys_config,
                                   nvl(nvl(src_tbl.value, pk_utils.query_to_string(src_tbl.value_qry, '|')), 0) VALUE,
                                   src_tbl.desc_sys_config,
                                   src_tbl.fill_type,
                                   src_tbl.client_configuration,
                                   src_tbl.internal_configuration,
                                   src_tbl.global_configuration,
                                   'A' flg_schema,
                                   src_tbl.id_software,
                                   src_tbl.id_market
                            -- decode FKS to dest_vals
                              FROM alert_default.sys_config src_tbl
                             WHERE src_tbl.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND src_tbl.id_market IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM sys_config dest_tbl
                     WHERE dest_tbl.id_sys_config = def_data.id_sys_config
                       AND dest_tbl.id_institution = def_data.id_institution
                       AND dest_tbl.id_software = def_data.id_software
                       AND dest_tbl.id_market = def_data.id_market);
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
    END set_sysconfig_search;
    -- frequent loader method
	
	FUNCTION del_sysconfig_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete sys_config';
        g_func_name := upper('del_sysconfig_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM sys_config sc
             WHERE sc.id_institution = i_institution
               AND sc.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                       column_value
                                        FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM sys_config sc
             WHERE sc.id_institution = i_institution;
        
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
    END del_sysconfig_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_sysconfig_prm;
/