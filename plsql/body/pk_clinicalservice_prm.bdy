/*-- Last Change Revision: $Rev: 1999605 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2021-10-21 15:40:17 +0100 (qui, 21 out 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_clinicalservice_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_CLINICALSERVICE_PRM';

    -- g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_clinical_service_def
    (
        i_lang       IN language.id_language%TYPE,
        i_id_content IN table_varchar DEFAULT table_varchar(),
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('CLINICAL_SERVICE.code_CLINICAL_SERVICE.');
        l_cnt_count        NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('LOAD_CLINICAL_SERVICE_DEF');
    
        INSERT INTO clinical_service
            (id_clinical_service, code_clinical_service, id_clinical_service_parent, rank, id_content)
            SELECT seq_clinical_service.nextval,
                   l_code_translation || seq_clinical_service.currval,
                   NULL,
                   10,
                   def_data.id_content
              FROM (SELECT decode(l_cnt_count,
                                  0,
                                  ad_cs.id_content,
                                  nvl((SELECT ad_cs1.id_content
                                        FROM ad_clinical_service ad_cs1
                                       WHERE ad_cs1.id_content = ad_cs.id_content
                                         AND ad_cs1.flg_available = ad_cs.flg_available
                                         AND ad_cs1.flg_available = g_flg_available
                                         AND ad_cs1.id_content IN
                                             (SELECT /*+ opt_estimate(p rows = 10)*/
                                               column_value
                                                FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                      0)) id_content
                      FROM ad_clinical_service ad_cs
                     WHERE ad_cs.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM clinical_service a_cs
                             WHERE a_cs.id_content = ad_cs.id_content
                               AND a_cs.flg_available = g_flg_available)) def_data
             WHERE def_data.id_content != '0';
    
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
    END load_clinical_service_def;
    -- searcheable loader method

-- frequent loader method

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, NAME => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_clinicalservice_prm;
/
