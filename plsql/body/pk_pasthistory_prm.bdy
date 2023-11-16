/*-- Last Change Revision: $Rev: 1647481 $*/
/*-- Last Change by: $Author: luis.r.silva $*/
/*-- Date of last change: $Date: 2014-10-17 15:24:42 +0100 (sex, 17 out 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_pasthistory_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_pasthistory_prm';
    pos_soft        NUMBER := 1;
    -- Private Methods

    -- content loader method

    -- searcheable loader method

    -- frequent loader method
    FUNCTION set_clin_serv_ad_freq
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
        g_func_name := upper('set_clin_serv_ad_freq');
        INSERT INTO clin_serv_alert_diagnosis
            (id_clin_serv_alert_diagnosis,
             id_clinical_service,
             id_alert_diagnosis,
             flg_available,
             id_profile_template,
             id_adiag_inst_owner,
             id_institution,
             id_software)
            SELECT seq_clin_serv_alert_diagnosis.nextval,
                   i_clin_serv_out,
                   def_data.id_alert_diagnosis,
                   g_flg_available,
                   def_data.id_profile_template,
                   0,
                   i_institution,
                   i_software(pos_soft)
            
              FROM (SELECT temp_data.id_alert_diagnosis,
                           
                           temp_data.id_profile_template,
                           row_number() over(PARTITION BY temp_data.id_alert_diagnosis, temp_data.id_profile_template
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT alert_ad.id_alert_diagnosis
                                         FROM alert_diagnosis alert_ad
                                        WHERE alert_ad.id_alert_diagnosis = csad.id_alert_diagnosis
                                          AND alert_ad.flg_available = g_flg_available),
                                       -100) id_alert_diagnosis,
                                   
                                   decode(csad.id_profile_template,
                                          NULL,
                                          NULL,
                                          0,
                                          0,
                                          nvl((SELECT alert_pt.id_profile_template
                                                FROM profile_template alert_pt
                                               WHERE alert_pt.id_profile_template = csad.id_profile_template
                                                 AND alert_pt.flg_available = g_flg_available),
                                              -100)) id_profile_template,
                                   csad.id_software,
                                   admv.id_market,
                                   admv.version
                              FROM alert_default.clin_serv_alert_diagnosis csad
                             INNER JOIN alert_default.alert_diagnosis_mrk_vrs admv
                                ON admv.id_alert_diagnosis = csad.id_alert_diagnosis
                             WHERE csad.flg_available = g_flg_available
                               AND csad.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND csad.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)
                               AND admv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND admv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)
                            
                            ) temp_data
                     WHERE (temp_data.id_profile_template > -100 OR temp_data.id_profile_template IS NULL)
                          
                       AND temp_data.id_alert_diagnosis > -100) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS
             (SELECT 0
                      FROM clin_serv_alert_diagnosis alert_csad
                     WHERE alert_csad.id_alert_diagnosis = def_data.id_alert_diagnosis
                       AND alert_csad.id_clinical_service = i_clin_serv_out
                       AND alert_csad.flg_available = g_flg_available
                       AND alert_csad.id_software = i_software(pos_soft)
                       AND (alert_csad.id_profile_template = def_data.id_profile_template OR
                           (alert_csad.id_profile_template IS NULL AND def_data.id_profile_template IS NULL)
                           
                           ));
    
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
    END set_clin_serv_ad_freq;
    -- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_pasthistory_prm;
/