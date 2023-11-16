CREATE OR REPLACE PROCEDURE automatic_disch_admin
(
    i_id_institution institution.id_institution%TYPE,
    i_num_hours      NUMBER,
    i_id_epis_type   epis_type.id_epis_type%TYPE
) IS

    /******************************************************************************
       OBJECTIVO:  Fechar os episódios com alta médica á mais de x horas e sem alta administrativa .
       PARAMETROS:
    
      CRIAÇÃO: SF 2007/06/01
      NOTAS:
    *********************************************************************************/

    l_rowids1     table_varchar;
    l_rowids2     table_varchar;
    l_rowids_epis table_varchar;
    l_rowids_ei   table_varchar;

    l_sysdate_tstz TIMESTAMP
        WITH LOCAL TIME ZONE;

    l_prof    profissional;
    l_error   t_error_out;
    l_lang    language.id_language%TYPE;
    l_id_prof professional.id_professional%TYPE;

    l_notes sys_message.desc_message%TYPE;

    CURSOR c_id_episode IS
        SELECT e.id_episode, e.id_visit id_visit, d.id_discharge id_discharge
          FROM discharge d, episode e
         WHERE d.id_episode = e.id_episode
           AND d.id_prof_med IS NOT NULL
           AND e.flg_status IN ('A', 'P')
           AND e.id_epis_type = i_id_epis_type
           AND d.id_prof_admin IS NULL
           AND d.flg_status IN ('A', 'P')
           AND e.id_institution = i_id_institution
           AND e.id_episode NOT IN (SELECT e1.id_prev_episode
                                      FROM episode e1
                                     WHERE e1.id_prev_episode = e.id_episode
                                       AND e1.flg_status IN ('A', 'P'))
           AND current_timestamp - d.dt_med_tstz >= numtodsinterval((i_num_hours / 24), 'DAY');

BEGIN

    l_sysdate_tstz := current_timestamp;

    l_rowids_epis := table_varchar();
    l_rowids_ei   := table_varchar();

    l_prof := profissional(0, i_id_institution, pk_episode.get_soft_by_epis_type(i_id_epis_type, i_id_institution));
    l_lang := pk_sysconfig.get_config('LANGUAGE', l_prof);

    l_id_prof := pk_sysconfig.get_config('ID_PROF_ALERT', l_prof);
    l_notes   := pk_message.get_message(i_lang => l_lang, i_code_mess => 'DISCHARGE_T013');
    FOR i IN c_id_episode
    LOOP
    
        l_rowids1 := table_varchar();
        l_rowids2 := table_varchar();
    
        UPDATE discharge
           SET id_prof_admin = nvl(l_id_prof, '1'), ---- COLOCAR  UM ID DO ALERT do local
               dt_admin_tstz = l_sysdate_tstz,
               notes_admin   = l_notes
         WHERE id_discharge = i.id_discharge;
    
        ts_episode.upd(flg_status_in   => 'I',
                       dt_end_tstz_in  => l_sysdate_tstz,
                       dt_end_tstz_nin => FALSE,
                       where_in        => 'id_visit = ' || i.id_visit || ' and flg_status in (''A'', ''P'')',
                       rows_out        => l_rowids1);
    
        ts_epis_info.upd(flg_status_in => 'A', where_in => 'id_episode =' || i.id_episode, rows_out => l_rowids2);
    
        UPDATE visit
           SET dt_end_tstz = current_timestamp, flg_status = 'I'
         WHERE id_visit = i.id_visit;
    
        l_rowids_epis := l_rowids_epis MULTISET UNION l_rowids1;
        l_rowids_ei   := l_rowids_ei MULTISET UNION l_rowids2;
    
        UPDATE grid_task_lab
           SET flg_status_epis = 'I'
         WHERE id_episode = i.id_episode;
    
        UPDATE grid_task_img
           SET flg_status_epis = 'I'
         WHERE id_episode = i.id_episode;
    
        UPDATE grid_task_oth_exm
           SET flg_status_epis = 'I'
         WHERE id_episode = i.id_episode;
    
        IF NOT pk_adt.set_discharge_adt(i_lang          => l_lang,
                                        i_prof          => l_prof,
                                        i_id_discharge  => i.id_discharge,
                                        i_id_episode    => i.id_episode,
                                        i_id_visit      => i.id_visit,
                                        i_dt_admin_tstz => l_sysdate_tstz,
                                        i_notes         => l_notes,
                                        o_error         => l_error)
        THEN
            pk_alertlog.log_warn('ERROR ON pk_adt.set_discharge_adt');
            ROLLBACK;
            EXIT;
        END IF;
    
    END LOOP;

    IF l_rowids_epis.count > 0
    THEN
        t_data_gov_mnt.process_update(i_lang         => l_lang,
                                      i_prof         => l_prof,
                                      i_table_name   => 'EPISODE',
                                      i_rowids       => l_rowids_epis,
                                      o_error        => l_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
    END IF;

    IF l_rowids_ei.count > 0
    THEN
        t_data_gov_mnt.process_update(i_lang         => l_lang,
                                      i_prof         => l_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rowids_ei,
                                      o_error        => l_error,
                                      i_list_columns => table_varchar('FLG_STATUS'));
    END IF;

    COMMIT;

END;
/
