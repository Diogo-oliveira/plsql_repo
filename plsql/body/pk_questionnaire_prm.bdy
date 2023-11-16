/*-- Last Change Revision: $Rev: 1898529 $*/
/*-- Last Change by: $Author: rui.dagoberto $*/
/*-- Date of last change: $Date: 2019-03-28 14:14:06 +0000 (qui, 28 mar 2019) $*/

CREATE OR REPLACE PACKAGE BODY ALERT.pk_questionnaire_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_questionnaire_prm';

    --  g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_questionnaire_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('questionnaire.code_questionnaire.');
    BEGIN
        g_func_name := upper('load_questionnaire_def');
        INSERT INTO questionnaire
            (id_questionnaire, code_questionnaire, id_content, flg_available, gender, age_max, age_min)
            SELECT seq_questionnaire.nextval,
                   l_code_translation || seq_questionnaire.currval,
                   def_data.id_content,
                   def_data.flg_available,
                   def_data.gender,
                   def_data.age_max,
                   def_data.age_min
              FROM (SELECT source_tbl.id_content,
                           source_tbl.flg_available,
                           source_tbl.gender,
                           source_tbl.age_max,
                           source_tbl.age_min
                      FROM alert_default.questionnaire source_tbl
                     WHERE source_tbl.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM questionnaire dest_tbl
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
    END load_questionnaire_def;

    FUNCTION load_response_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('response.code_response.');
    BEGIN
        g_func_name := upper('load_response_def');
        INSERT INTO response
            (id_response, code_response, id_content, flg_available, flg_free_text, gender, age_max, age_min)

            SELECT seq_response.nextval,
                   l_code_translation || seq_response.currval,
                   def_data.id_content,
                   flg_available,
                   nvl(def_data.flg_free_text, 'N'),
                   def_data.gender,
                   def_data.age_max,
                   def_data.age_min

              FROM (SELECT source_tbl.id_content,
                           source_tbl.flg_available,
                           source_tbl.flg_free_text,
                           source_tbl.gender,
                           source_tbl.age_max,
                           source_tbl.age_min
                      FROM alert_default.response source_tbl
                     WHERE source_tbl.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM response dest_tbl
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
    END load_response_def;
    -- searcheable loader method

    FUNCTION set_quest_resp_search
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
        g_func_name := upper('set_quest_resp_search');
        INSERT INTO questionnaire_response
            (id_questionnaire,
             id_response,
             id_content,
             rank,
             flg_available,
             id_questionnaire_parent,
             id_response_parent)
            SELECT def_data.i_questionnaire,
                   def_data.i_response,
                   def_data.id_content,
                   def_data.rank,
                   def_data.flg_available,
                   id_questionnaire_parent,
                   id_response_parent
              FROM (SELECT temp_data.i_questionnaire,
                           temp_data.i_response,
                           temp_data.id_content,
                           temp_data.rank,
                           temp_data.flg_available,
                           id_questionnaire_parent,
                           id_response_parent,
                           row_number() over(PARTITION BY temp_data.i_questionnaire, temp_data.i_response, temp_data.id_content ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT q1.id_questionnaire
                                         FROM questionnaire q1
                                        WHERE q1.id_content = q.id_content
                                          AND q1.flg_available = g_flg_available),
                                       0) i_questionnaire,
                                   nvl((SELECT r1.id_response
                                         FROM response r1
                                        WHERE r1.id_content = r.id_content
                                          AND r1.flg_available = g_flg_available),
                                       0) i_response,
                                   qr.id_content,
                                   qr.rank,
                                   qr.flg_available,
                                   decode(qr.id_questionnaire_parent,
                                          NULL,
                                          NULL,
                                          nvl((SELECT q1.id_questionnaire
                                                FROM questionnaire q1
                                               INNER JOIN alert_default.questionnaire qx
                                                  ON (qx.id_content = q1.id_content)
                                               WHERE qx.id_questionnaire = qr.id_questionnaire_parent
                                                 AND q1.flg_available = g_flg_available
                                                 AND qx.flg_available = g_flg_available),
                                              0)) id_questionnaire_parent,
                                   decode(qr.id_response_parent,
                                          NULL,
                                          NULL,
                                          nvl((SELECT r1.id_response
                                                FROM response r1
                                               INNER JOIN alert_default.response rx
                                                  ON (rx.id_content = r1.id_content)
                                               WHERE rx.id_response = qr.id_response_parent
                                                 AND r1.flg_available = g_flg_available
                                                 AND rx.flg_available = g_flg_available),
                                              0)) id_response_parent,
                                   qmv.id_market,
                                   qmv.version

                            -- decode FKS to dest_vals
                              FROM alert_default.questionnaire_response qr
                              JOIN alert_default.questionnaire q
                                ON q.id_questionnaire = qr.id_questionnaire

                              JOIN alert_default.questionnaire_mrk_vrs qmv
                                ON qmv.id_questionnaire = qr.id_questionnaire
                              JOIN alert_default.response r
                                ON r.id_response = qr.id_response

                              JOIN alert_default.response_mrk_vrs rmv
                                ON rmv.id_response = qr.id_response 
                               AND (rmv.id_market = qmv.id_market or rmv.id_market = '0'  or qmv.id_market = '0' )
                               AND rmv.version = qmv.version

                             WHERE qr.flg_available = g_flg_available
                               AND r.flg_available = g_flg_available
                               AND q.flg_available = g_flg_available
                               AND qr.id_content IS NOT NULL
                               AND qmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)

                               AND qmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.i_questionnaire > 0
               AND def_data.i_response > 0
               AND (def_data.id_response_parent IS NULL OR def_data.id_response_parent > 0)
               AND (def_data.id_questionnaire_parent IS NULL OR def_data.id_questionnaire_parent > 0)
               AND (EXISTS (SELECT 0
                              FROM questionnaire_response dest_tbl
                             WHERE (dest_tbl.id_questionnaire = def_data.id_questionnaire_parent)
                               AND (dest_tbl.id_response = def_data.id_response_parent)) OR
                    (def_data.id_questionnaire_parent IS NULL AND def_data.id_response_parent IS NULL))
               AND NOT EXISTS (SELECT 0
                      FROM questionnaire_response qr1
                     WHERE qr1.id_questionnaire = def_data.i_questionnaire
                       AND qr1.id_response = def_data.i_response
                       AND qr1.id_content = def_data.id_content
                       AND qr1.flg_available = g_flg_available);
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
    END set_quest_resp_search;

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
END pk_questionnaire_prm;

/
