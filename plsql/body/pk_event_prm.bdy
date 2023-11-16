/*-- Last Change Revision: $Rev: 1647481 $*/
/*-- Last Change by: $Author: luis.r.silva $*/
/*-- Date of last change: $Date: 2014-10-17 15:24:42 +0100 (sex, 17 out 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_event_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_Event_prm';
    pos_soft        NUMBER := 1;
    -- g_table_name    t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_event_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_code_translation translation.code_translation%TYPE := upper('event.code_event.');
    BEGIN
        INSERT INTO event
            (id_event, flg_group, id_event_group, id_group, flg_most_freq, id_sample_type)
            SELECT seq_event.nextval, flg_group, id_event_group, id_group, flg_most_freq, id_sample_type
              FROM (SELECT temp_data.flg_group,
                           temp_data.id_event_group,
                           temp_data.id_group,
                           temp_data.flg_most_freq,
                           temp_data.id_sample_type,
                           row_number() over(PARTITION BY temp_data.flg_group, temp_data.id_event_group, temp_data.id_sample_type, temp_data.id_group ORDER BY temp_data.l_row) records_count
                      FROM (SELECT e.rowid l_row,
                                   e.flg_group,
                                   e.id_event_group,
                                   decode(e.flg_group,
                                          'A',
                                          nvl((SELECT ext_a.id_analysis
                                                FROM alert_default.analysis def_a
                                               INNER JOIN alert_default.analysis_sample_type def_ast
                                                  ON (def_ast.id_analysis = def_a.id_analysis AND
                                                     def_ast.flg_available = g_flg_available)
                                               INNER JOIN analysis ext_a
                                                  ON (ext_a.id_content = def_a.id_content AND
                                                     ext_a.flg_available = g_flg_available)
                                               WHERE def_a.flg_available = g_flg_available
                                                 AND def_a.id_analysis = e.id_group
                                                 AND def_ast.id_sample_type = e.id_sample_type),
                                              0),
                                          'H',
                                          nvl((SELECT ext_h.id_habit
                                                FROM alert_default.habit def_h
                                               INNER JOIN habit ext_h
                                                  ON (ext_h.id_content = def_h.id_content AND
                                                     ext_h.flg_available = g_flg_available)
                                               WHERE def_h.flg_available = g_flg_available
                                                 AND def_h.id_habit = e.id_group),
                                              0),
                                          'I',
                                          nvl((SELECT ext_e.id_exam
                                                FROM alert_default.exam def_e
                                               INNER JOIN exam ext_e
                                                  ON (ext_e.id_content = def_e.id_content AND
                                                     ext_e.flg_available = g_flg_available)
                                               WHERE def_e.flg_available = g_flg_available
                                                 AND def_e.flg_type = 'I'
                                                 AND def_e.id_exam = e.id_group),
                                              0),
                                          'E',
                                          nvl((SELECT ext_e.id_exam
                                                FROM alert_default.exam def_e
                                               INNER JOIN exam ext_e
                                                  ON (ext_e.id_content = def_e.id_content AND
                                                     ext_e.flg_available = g_flg_available)
                                               WHERE def_e.flg_available = g_flg_available
                                                 AND def_e.flg_type = 'E'
                                                 AND def_e.id_exam = e.id_group),
                                              0),
                                          e.id_group) id_group,
                                   e.flg_most_freq,
                                   decode(e.flg_group,
                                          'A',
                                          (nvl((SELECT ext_st.id_sample_type
                                                 FROM sample_type ext_st
                                                INNER JOIN alert_default.sample_type def_st
                                                   ON (def_st.id_content = ext_st.id_content)
                                                WHERE def_st.id_sample_type = e.id_sample_type
                                                  AND ext_st.flg_available = g_flg_available),
                                               0)),
                                          NULL) id_sample_type
                              FROM alert_default.event e
                             INNER JOIN event_group eg
                                ON (eg.id_event_group = e.id_event_group)) temp_data
                     WHERE (temp_data.id_group != 0 OR temp_data.id_group IS NULL)
                       AND (temp_data.id_sample_type != 0 OR temp_data.id_sample_type IS NULL)) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM event ext_ev
                     WHERE ext_ev.flg_group = def_data.flg_group
                       AND ext_ev.id_event_group = def_data.id_event_group
                       AND (ext_ev.id_sample_type = def_data.id_sample_type OR
                           (ext_ev.id_sample_type IS NULL AND def_data.id_sample_type IS NULL))
                       AND (ext_ev.id_group = def_data.id_group OR
                           (ext_ev.id_group IS NULL AND def_data.id_group IS NULL)));
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
    END load_event_def;
    -- searcheable loader method
    FUNCTION set_event_group_si_search
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
        g_func_name := upper('set_event_group_si_search');
        INSERT INTO event_group_soft_inst
            (id_event_group_soft_inst, id_event_group, id_institution, id_software)
        
            SELECT seq_event_group_soft_inst.nextval, def_data.id_event_group, i_institution, i_software(pos_soft)
              FROM (SELECT temp_data.id_event_group,
                           row_number() over(PARTITION BY temp_data.id_event_group
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT egsi.id_event_group, egsi.id_software, egsi.id_market, egsi.version
                            -- decode FKS to dest_vals
                              FROM alert_default.event_group_soft_inst egsi
                             WHERE egsi.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND egsi.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND egsi.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM event_group_soft_inst egsi1
                     WHERE egsi1.id_event_group = id_event_group
                       AND egsi1.id_institution = i_institution
                       AND egsi1.id_software = i_software(pos_soft));
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
    END set_event_group_si_search;

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
END pk_event_prm;
/