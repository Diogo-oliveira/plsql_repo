/*-- Last Change Revision: $Rev: 1647481 $*/
/*-- Last Change by: $Author: luis.r.silva $*/
/*-- Date of last change: $Date: 2014-10-17 15:24:42 +0100 (sex, 17 out 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_externalcause_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_EXTERNALCAUSE_prm';

    g_table_name t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_external_cause_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('external_cause.code_external_cause.');
    
    BEGIN
        g_func_name := upper('set_external_cause_search');
        INSERT INTO external_cause
            (id_external_cause, code_external_cause, id_content, rank, flg_available)
            SELECT seq_external_cause.nextval,
                   l_code_translation || seq_external_cause.currval,
                   def_data.id_content,
                   def_data.rank,
                   def_data.flg_available
              FROM (SELECT temp_data.id_content,
                           
                           temp_data.rank,
                           temp_data.flg_available,
                           row_number() over(PARTITION BY temp_data.id_content
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT ec.rank, ec.flg_available, ec.id_content, ecmv.id_market, ecmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.external_cause_mrk_vrs ecmv
                             INNER JOIN alert_default.external_cause ec
                                ON ecmv.id_external_cause = ec.id_external_cause
                            
                             WHERE ec.flg_available = g_flg_available
                                  
                               AND ecmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND ecmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM external_cause ec1
                     WHERE ec1.id_content = def_data.id_content
                       AND ec1.flg_available = g_flg_available);
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
    END set_external_cause_search;
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
END pk_externalcause_prm;
/