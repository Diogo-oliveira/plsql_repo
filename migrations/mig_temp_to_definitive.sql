DECLARE
    i_lang  language.id_language%TYPE := 2;
    i_prof  alert.profissional := profissional(0, 0, 0);
    o_error t_error_out;

    l_rows table_varchar := table_varchar();

    g_error VARCHAR2(2000);
BEGIN
    -- Actualiza registos temporários da tabela EPIS_OBSERVATION
    g_error := 'UPD EPIS_OBSERVATION';

    UPDATE epis_observation
       SET flg_temp = 'D'
     WHERE flg_temp = 'T';

    -- Actualiza registos temporários da tabela EPIS_OBS_EXAM
    g_error := 'UPD EPIS_OBS_EXAM';

    UPDATE epis_obs_exam
       SET flg_temp = 'D'
     WHERE flg_temp = 'T';

    -- Actualiza registos temporários da tabela EPIS_ANAMNESIS
    g_error := 'UPD EPIS_ANAMNESIS';
    l_rows  := table_varchar();
    ts_epis_anamnesis.upd(flg_temp_in => 'D',
                          where_in    => 'FLG_TYPE IN(''C'',''A'') AND FLG_TEMP = ''T''',
                          rows_out    => l_rows);

    IF l_rows.count > 0
    THEN
        g_error := 't_data_gov_mnt.process_update ts_epis_anamnesis';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ANAMNESIS',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_TEMP'));
    END IF;

    l_rows := table_varchar();
    -- Actualiza registos temporários da tabela EPIS_RECOMEND
    g_error := 'UPD EPIS_RECOMEND P';
    l_rows  := table_varchar();
    g_error := 'CALL ts_epis_recomend.upd';
    ts_epis_recomend.upd(flg_temp_in => 'D',
                         where_in    => 'FLG_TYPE IN (''P'', ''D'', ''A'', ''L'', ''S'', ''B'') AND FLG_TEMP = ''T''',
                         rows_out    => l_rows);

    --call process update for all rows updated for epis_recomend
    IF l_rows.count > 0
    THEN
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_RECOMEND',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_TEMP'));
    END IF;

    -- Actualiza registos temporários da tabela NURSE_DISCHARGE
    g_error := 'UPD NURSE_DISCHARGE';

    UPDATE nurse_discharge
       SET flg_temp = 'D'
     WHERE flg_temp = 'T';

EXCEPTION
    WHEN OTHERS THEN
        pk_alert_exceptions.process_error(i_lang     => i_lang,
                                          i_sqlcode  => SQLCODE,
                                          i_sqlerrm  => SQLERRM,
                                          i_message  => g_error,
                                          i_owner    => 'ALERT',
                                          i_package  => 'MIG',
                                          i_function => 'MIG',
                                          o_error    => o_error);
END;
/
