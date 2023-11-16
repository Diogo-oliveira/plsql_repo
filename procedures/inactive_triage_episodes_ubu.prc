CREATE OR REPLACE PROCEDURE inactive_triage_episodes_ubu IS

    l_count NUMBER := 1;

    CURSOR cs IS
        SELECT e.*
          FROM episode e
         WHERE e.flg_status = 'A'
           AND e.id_epis_type = 9
           AND current_timestamp - e.dt_begin_tstz >= numtodsinterval(1, 'DAY');

    l_rows  table_varchar;
    l_error t_error_out;
BEGIN

    FOR rs IN cs
    LOOP
    
        /* <DENORM Fábio> */
        ts_episode.upd(id_episode_in  => rs.id_episode,
                       flg_status_in  => 'I',
                       dt_end_tstz_in => current_timestamp,
                       rows_out       => l_rows);
    
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
    
        IF NOT pk_adt.set_discharge_adt(i_lang          => 1,
                                        i_prof          => profissional(0, rs.id_institution, 29),
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

    t_data_gov_mnt.process_update(0,
                                  profissional(0, 0, 0),
                                  'EPISODE',
                                  l_rows,
                                  l_error,
                                  table_varchar('FLG_STATUS', 'DT_END_TSTZ'));

    dbms_output.put_line(l_count || ' rows updated! ');

    COMMIT;

END inactive_triage_episodes_ubu;
/
