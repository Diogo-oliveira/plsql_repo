CREATE OR REPLACE PROCEDURE inactive_triage_ended_episodes IS

    l_count NUMBER;

    -- <DENORM_EPISODE_JOSE_BRITO>
    CURSOR cs(id_inst institution.id_institution%TYPE) IS
        SELECT e.*
          FROM episode e
         WHERE e.flg_status = 'A'
           AND e.id_epis_type IN (9, 2)
           AND current_timestamp - e.dt_begin_tstz >= numtodsinterval(1, 'DAY')
           AND e.id_institution = id_inst;

    l_rows  table_varchar;
    l_error t_error_out;
    l_prof  profissional;

    l_lang language.id_language%TYPE;
    l_table_inst table_number;
BEGIN
    BEGIN
        SELECT DISTINCT id_institution BULK COLLECT
          INTO l_table_inst
          FROM sys_config sc
         WHERE sc.id_sys_config = 'INACTIVE_TRIAGE_ENDED_EPISODES'
           AND sc.value = pk_alert_constant.g_yes
           AND sc.id_institution <> 0;
    EXCEPTION
        WHEN no_data_found THEN
            l_table_inst := table_number();
    END;

    FOR i IN 1 .. l_table_inst.count
    LOOP
        l_count := 0;
        l_prof  := profissional(0, l_table_inst(i), pk_episode.get_soft_by_epis_type(2, l_table_inst(i)));
    l_lang := pk_sysconfig.get_config('LANGUAGE', l_prof);

        FOR rs IN cs(id_inst => l_table_inst(i))
    LOOP
    
        /* <DENORM Fábio> */
        ts_episode.upd(id_episode_in  => rs.id_episode,
                       flg_status_in  => 'I',
                       dt_end_tstz_in => current_timestamp,
                       rows_out       => l_rows);
    
            t_data_gov_mnt.process_update(0,
                                          profissional(0, l_table_inst(i), 0),
                                          'EPISODE',
                                          l_rows,
                                          l_error,
                                          table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
        
        UPDATE visit a
           SET a.flg_status = 'I', a.dt_end_tstz = current_timestamp
         WHERE id_visit = rs.id_visit;
    
        UPDATE grid_task_lab
           SET flg_status_epis = 'I'
         WHERE id_episode = rs.id_episode;
    
        UPDATE grid_task_img
           SET flg_status_epis = 'I'
         WHERE id_episode = rs.id_episode;
    
        UPDATE grid_task_oth_exm
           SET flg_status_epis = 'I'
         WHERE id_episode = rs.id_episode;
    
        IF NOT pk_advanced_directives.cancel_adv_dir_recurr_plans(i_lang    => NULL,
                                                                  i_prof    => profissional(0, 0, 0),
                                                                  i_patient => rs.id_patient,
                                                                  i_episode => rs.id_episode,
                                                                  o_error   => l_error)
        THEN
            pk_alertlog.log_fatal(text => 'CALL PK_ADVANCED_DIRECTIVES.CANCEL_ADV_DIR_RECURR_PLANS');
        END IF;
    
        IF NOT pk_adt.set_discharge_adt(i_lang          => l_lang,
                                        i_prof          => l_prof,
                                        i_id_discharge  => NULL,
                                        i_id_episode    => rs.id_episode,
                                        i_id_visit      => rs.id_visit,
                                        i_dt_admin_tstz => current_timestamp,
                                        i_notes         => NULL,
                                        o_error         => l_error)
        THEN
                pk_alertlog.log_warn('ERROR ON pk_adt.set_discharge_adt');
            ROLLBACK;
            EXIT;
        
        END IF;
    
        l_count := l_count + 1;
    
    END LOOP;

    dbms_output.put_line(l_count || ' rows updated! ');

    COMMIT;
    END LOOP;

END inactive_triage_ended_episodes;
/
