/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_advanced_input_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_advanced_input_prm';
    pos_soft        NUMBER := 1;
    -- g_table_name    t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_ad_inp_soft_inst_search
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
        g_func_name := upper('set_ad_inp_soft_inst_search');
        INSERT INTO advanced_input_soft_inst
            (id_advanced_input_soft_inst,
             id_advanced_input,
             id_advanced_input_field,
             flg_active,
             error_message,
             rank,
             id_market,
             id_institution,
             id_software)
            SELECT seq_advanced_input_soft_inst.nextval,
                   def_data.id_advanced_input,
                   def_data.id_advanced_input_field,
                   def_data.flg_active,
                   def_data.error_message,
                   def_data.rank,
                   def_data.id_market,
                   i_institution,
                   i_software(pos_soft)
            
              FROM (SELECT temp_data.id_advanced_input,
                           temp_data.id_advanced_input_field,
                           temp_data.flg_active,
                           temp_data.error_message,
                           temp_data.rank,
                           temp_data.id_market,
                           
                           row_number() over(PARTITION BY temp_data.id_advanced_input, temp_data.id_advanced_input_field
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT aisi.rowid l_row,
                                   aisi.id_advanced_input,
                                   aisi.id_advanced_input_field,
                                   aisi.flg_active,
                                   aisi.error_message,
                                   aisi.rank,
                                   aisi.id_market,
                                   aisi.id_software,
                                   aimv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.advanced_input_mrk_vrs aimv
                             INNER JOIN alert_default.advanced_input_soft_inst aisi
                                ON aisi.id_advanced_input = aimv.id_advanced_input
                               AND aisi.id_market = aimv.id_market
                             WHERE aisi.flg_active = g_active
                               AND aisi.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND aimv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND aimv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM advanced_input_soft_inst aisi1
                     WHERE aisi1.id_advanced_input = def_data.id_advanced_input
                       AND aisi1.id_advanced_input_field = def_data.id_advanced_input_field
                       AND aisi1.id_institution = i_institution
                       AND aisi1.id_software = i_software(pos_soft)
                       AND aisi1.flg_active = g_active);
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
    END set_ad_inp_soft_inst_search;
    -- frequent loader method

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_advanced_input_prm;
/
