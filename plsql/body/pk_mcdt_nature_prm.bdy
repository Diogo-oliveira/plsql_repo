/*-- Last Change Revision: $Rev:$*/ 
/*-- Last Change by: $Author:$*/
/*-- Date of last change: $Date:$*/

CREATE OR REPLACE PACKAGE BODY pk_mcdt_nature_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'pk_mcdt_nature_prm';

    /**
    * Load mcdt_nature ("Convencionados")
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.0.0
    * @since                       2021/03/19
    */

    FUNCTION load_mcdt_nature
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Delete all that were removed from default
        DELETE FROM mcdt_nature a_mn
         WHERE NOT EXISTS (SELECT 1
                  FROM ad_mcdt_nature ad_mn1
                 WHERE ad_mn1.flg_mcdt = a_mn.flg_mcdt
                   AND ad_mn1.flg_nature = a_mn.flg_nature
                   AND ad_mn1.flg_available = g_flg_available
                   AND a_mn.id_mcdt IN (SELECT nvl(decode(ad_mn.flg_mcdt,
                                                          'P',
                                                          nvl((SELECT a_e.id_intervention
                                                                FROM intervention a_e
                                                                JOIN ad_intervention ad_e
                                                                  ON a_e.id_content = ad_e.id_content
                                                               WHERE ad_e.id_intervention = ad_mn.id_mcdt
                                                                 AND a_e.flg_status = g_active
                                                                 AND ad_e.flg_status = g_active),
                                                              0),
                                                          'A',
                                                          nvl((SELECT a_e.id_analysis
                                                                FROM analysis a_e
                                                                JOIN ad_analysis ad_e
                                                                  ON a_e.id_content = ad_e.id_content
                                                               WHERE ad_e.id_analysis = ad_mn.id_mcdt
                                                                 AND a_e.flg_available = g_flg_available
                                                                 AND ad_e.flg_available = g_flg_available),
                                                              0),
                                                          'E',
                                                          nvl((SELECT a_e.id_exam
                                                                FROM exam a_e
                                                                JOIN ad_exam ad_e
                                                                  ON a_e.id_content = ad_e.id_content
                                                               WHERE ad_e.id_exam = ad_mn.id_mcdt
                                                                 AND a_e.flg_available = g_flg_available
                                                                 AND ad_e.flg_available = g_flg_available),
                                                              0),
                                                          'I',
                                                          nvl((SELECT a_e.id_exam
                                                                FROM exam a_e
                                                                JOIN ad_exam ad_e
                                                                  ON a_e.id_content = ad_e.id_content
                                                               WHERE ad_e.id_exam = ad_mn.id_mcdt
                                                                 AND a_e.flg_available = g_flg_available
                                                                 AND ad_e.flg_available = g_flg_available),
                                                              0),
                                                          'F',
                                                          nvl((SELECT a_e.id_intervention
                                                                FROM intervention a_e
                                                                JOIN ad_intervention ad_e
                                                                  ON a_e.id_content = ad_e.id_content
                                                               WHERE ad_e.id_intervention = ad_mn.id_mcdt
                                                                 AND a_e.flg_status = g_active
                                                                 AND ad_e.flg_status = g_active),
                                                              0)),
                                                   0)
                                          FROM ad_mcdt_nature ad_mn
                                         WHERE ad_mn.id_mcdt = ad_mn1.id_mcdt
                                           AND ad_mn1.flg_mcdt = ad_mn.flg_mcdt
                                           AND ad_mn1.flg_nature = ad_mn.flg_nature
                                           AND ad_mn1.flg_available = ad_mn.flg_available));
    
        --Insert missing reccords
        INSERT INTO mcdt_nature
            (id_mcdt, flg_mcdt, flg_nature, flg_available)
            SELECT def_data.id_mcdt, def_data.flg_mcdt, def_data.flg_nature, def_data.flg_available
              FROM (SELECT tem_data.id_mcdt, tem_data.flg_mcdt, tem_data.flg_nature, tem_data.flg_available
                      FROM (SELECT decode(ad_mn.flg_mcdt,
                                          'P',
                                          nvl((SELECT a_e.id_intervention
                                                FROM intervention a_e
                                                JOIN ad_intervention ad_e
                                                  ON a_e.id_content = ad_e.id_content
                                               WHERE ad_e.id_intervention = ad_mn.id_mcdt
                                                 AND a_e.flg_status = g_active
                                                 AND ad_e.flg_status = g_active),
                                              0),
                                          'A',
                                          nvl((SELECT a_e.id_analysis
                                                FROM analysis a_e
                                                JOIN ad_analysis ad_e
                                                  ON a_e.id_content = ad_e.id_content
                                               WHERE ad_e.id_analysis = ad_mn.id_mcdt
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ad_e.flg_available = g_flg_available),
                                              0),
                                          'E',
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON a_e.id_content = ad_e.id_content
                                               WHERE ad_e.id_exam = ad_mn.id_mcdt
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ad_e.flg_available = g_flg_available),
                                              0),
                                          'I',
                                          nvl((SELECT a_e.id_exam
                                                FROM exam a_e
                                                JOIN ad_exam ad_e
                                                  ON a_e.id_content = ad_e.id_content
                                               WHERE ad_e.id_exam = ad_mn.id_mcdt
                                                 AND a_e.flg_available = g_flg_available
                                                 AND ad_e.flg_available = g_flg_available),
                                              0),
                                          'F',
                                          nvl((SELECT a_e.id_intervention
                                                FROM intervention a_e
                                                JOIN ad_intervention ad_e
                                                  ON a_e.id_content = ad_e.id_content
                                               WHERE ad_e.id_intervention = ad_mn.id_mcdt
                                                 AND a_e.flg_status = g_active
                                                 AND ad_e.flg_status = g_active),
                                              0)) id_mcdt,
                                   ad_mn.flg_mcdt,
                                   ad_mn.flg_nature,
                                   ad_mn.flg_available
                              FROM ad_mcdt_nature ad_mn
                             WHERE ad_mn.flg_available = g_flg_available) tem_data
                     WHERE tem_data.id_mcdt > 0) def_data
             WHERE NOT EXISTS (SELECT 1
                      FROM mcdt_nature a_mn
                     WHERE a_mn.id_mcdt = def_data.id_mcdt
                       AND a_mn.flg_mcdt = def_data.flg_mcdt
                       AND a_mn.flg_nature = def_data.flg_nature);
    
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
        
    END load_mcdt_nature;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;

END pk_mcdt_nature_prm;
/
