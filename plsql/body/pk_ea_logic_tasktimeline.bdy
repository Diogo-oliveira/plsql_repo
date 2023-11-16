/*-- Last Change Revision: $Rev: 2027067 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_tasktimeline IS

    -- This package provides Easy Access logic procedures to maintain TASK TIMELINE EA table.
    -- @version 2.5.0.4

    /*******************************************************************************************************************************************
    * Name:                           REOPEN_EPIS_TL_TASKS
    * Description:                    Function that populate Task Timeline Easy Access table (task_timeline_ea) with all tasks
    *                                 because episode was reopen from administrative discharge
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             ID_EPISODE of taks that should be inserted in Task_Timeline_EA table
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/02
    *******************************************************************************************************************************************/
    FUNCTION reopen_epis_tl_tasks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN task_timeline_ea.id_episode%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_proc_name VARCHAR2(30) := 'REOPEN_EPIS_TL_TASKS';
    BEGIN
        --
        g_error := 'admin_all_task_tl_tables';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_data_gov_admin.admin_all_task_tl_tables(i_patient                => NULL,
                                                          i_episode                => i_id_episode,
                                                          i_schedule               => NULL,
                                                          i_external_request       => NULL,
                                                          i_institution            => i_prof.institution,
                                                          i_start_dt               => NULL,
                                                          i_end_dt                 => NULL,
                                                          i_validate_table         => FALSE,
                                                          i_output_invalid_records => TRUE,
                                                          i_recreate_table         => TRUE,
                                                          i_commit_step            => NULL)
        THEN
            RAISE value_error;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_proc_name,
                                              o_error);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END reopen_epis_tl_tasks;

    /*******************************************************************************************************************************************
    * Name:                           SET_EPISODE
    * Description:                    Upates tables: task_timeline_ea. To be used on match functionality
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EPISODE_TEMP           ID_EPISODE of the temporary episode
    * @param I_EPISODE                ID_EPISODE of the definitive episode
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.7
    * @since                          2009/11/05
    *******************************************************************************************************************************************/
    FUNCTION set_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN task_timeline_ea.id_task_refid%TYPE,
        i_episode      IN task_timeline_ea.id_task_refid%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids  table_varchar;
        l_tte_tc  task_timeline_ea%ROWTYPE;
        l_tte_tc2 ts_task_timeline_ea.task_timeline_ea_tc;
        l_tte_tc3 ts_task_timeline_ea.task_timeline_ea_tc;
        l_vis     episode.id_visit%TYPE;
        l_pat     episode.id_patient%TYPE;
    BEGIN
        g_error := 'SELECT TASK_TIMELINE_EA with episode_temp = ' || i_episode_temp;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT tte.*
              INTO l_tte_tc
              FROM task_timeline_ea tte
             WHERE tte.id_task_refid = i_episode_temp
               AND tte.id_tl_task = pk_prog_notes_constants.g_task_schedule_inp;
        EXCEPTION
            WHEN no_data_found THEN
                l_tte_tc.id_task_refid := NULL;
                l_tte_tc.id_tl_task    := NULL;
        END;
    
        IF (l_tte_tc.id_task_refid IS NOT NULL AND l_tte_tc.id_tl_task IS NOT NULL)
        THEN
            g_error := 'CALL TS_TASK_TIMELINE.DEL with episode_temp = ' || i_episode_temp;
            pk_alertlog.log_debug(g_error);
            ts_task_timeline_ea.del(id_task_refid_in => i_episode_temp,
                                    id_tl_task_in    => l_tte_tc.id_tl_task,
                                    rows_out         => l_rowids);
        
            --
            BEGIN
                SELECT epi.id_visit, epi.id_patient
                  INTO l_vis, l_pat
                  FROM episode epi
                 WHERE epi.id_episode = i_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_vis := NULL;
                    l_pat := NULL;
            END;
            --   
        
            l_tte_tc.id_task_refid := i_episode;
            l_tte_tc.id_visit      := l_vis;
            l_tte_tc.id_patient    := l_pat;
        
            g_error := 'CALL TS_TASK_TIMELINE.INS';
            pk_alertlog.log_debug(g_error);
            ts_task_timeline_ea.ins(rec_in => l_tte_tc, rows_out => l_rowids);
        END IF;
    
        --
        --
        g_error := 'SELECT TASK_TIMELINE_EA with episode_temp = ' || i_episode_temp;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT tte.*
              BULK COLLECT
              INTO l_tte_tc2
              FROM task_timeline_ea tte
             WHERE tte.id_episode = i_episode_temp;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF l_tte_tc2.exists(1)
           AND l_tte_tc2.count > 0
        THEN
        
            SELECT epi.id_visit, epi.id_patient
              INTO l_vis, l_pat
              FROM episode epi
             WHERE epi.id_episode = i_episode;
        
            FOR i IN l_tte_tc2.first .. l_tte_tc2.last
            LOOP
                g_error := 'CALL TS_TASK_TIMELINE.DEL with episode_temp = ' || i_episode_temp;
                pk_alertlog.log_debug(g_error);
                ts_task_timeline_ea.del(id_task_refid_in => l_tte_tc2(i).id_task_refid,
                                        id_tl_task_in    => l_tte_tc2(i).id_tl_task,
                                        rows_out         => l_rowids);
            
                l_tte_tc2(i).id_episode := i_episode;
                l_tte_tc2(i).id_visit := l_vis;
                l_tte_tc2(i).id_patient := l_pat;
            
                g_error := 'CALL TS_TASK_TIMELINE.INS';
                pk_alertlog.log_debug(g_error);
                ts_task_timeline_ea.ins(rec_in => l_tte_tc2(i), rows_out => l_rowids);
            END LOOP;
        END IF;
        --
        --other visit episodes
        BEGIN
            SELECT tte.*
              BULK COLLECT
              INTO l_tte_tc3
              FROM task_timeline_ea tte
             WHERE tte.id_visit IN (SELECT epis.id_visit
                                      FROM episode epis
                                     WHERE epis.id_episode = i_episode_temp)
               AND tte.id_episode <> i_episode_temp;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF l_tte_tc3.exists(1)
           AND l_tte_tc3.count > 0
        THEN
        
            SELECT epi.id_visit, epi.id_patient
              INTO l_vis, l_pat
              FROM episode epi
             WHERE epi.id_episode = i_episode;
        
            FOR i IN l_tte_tc3.first .. l_tte_tc3.last
            LOOP
                g_error := 'CALL TS_TASK_TIMELINE.DEL with id_visit in ' || i_episode_temp;
                pk_alertlog.log_debug(g_error);
                ts_task_timeline_ea.del(id_task_refid_in => l_tte_tc3(i).id_task_refid,
                                        id_tl_task_in    => l_tte_tc3(i).id_tl_task,
                                        rows_out         => l_rowids);
            
                l_tte_tc3(i).id_visit := l_vis;
                l_tte_tc3(i).id_patient := l_pat;
            
                g_error := 'CALL TS_TASK_TIMELINE.INS';
                pk_alertlog.log_debug(g_error);
                ts_task_timeline_ea.ins(rec_in => l_tte_tc3(i), rows_out => l_rowids);
            END LOOP;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPISODE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_episode;

    /*******************************************************************************************************************************************
    * Name:                           CLEAN_EPIS_TL_TASKS
    * Description:                    Function that clean Task Timeline tasks (task_timeline_ea) that are episodes references
    *                                 (Inpatient and Oris) with begin date bigger than today.
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.7.6
    * @since                          2009/12/23
    *******************************************************************************************************************************************/
    PROCEDURE clean_epis_tl_tasks IS
    BEGIN
        --
        g_error := 'CALL TO pk_data_gov_admin.admin_epi_task_tl_tables';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_data_gov_admin.admin_epi_task_tl_tables(i_patient                => NULL,
                                                          i_episode                => NULL,
                                                          i_schedule               => NULL,
                                                          i_external_request       => NULL,
                                                          i_institution            => NULL,
                                                          i_start_dt               => NULL,
                                                          i_end_dt                 => NULL,
                                                          i_validate_table         => FALSE,
                                                          i_output_invalid_records => TRUE,
                                                          i_recreate_table         => TRUE,
                                                          i_commit_step            => 500)
        THEN
            RAISE value_error;
        END IF;
        --
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END clean_epis_tl_tasks;

    /********************************************************************************************
    * Dynamic delete records from task_timeline_ea
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author   Sofia Mendes
    * @version  2.6.3
    * @since    11-Jul-2013
    ********************************************************************************************/
    FUNCTION delete_task_timeline
    (
        i_patient     IN NUMBER := NULL,
        i_episode     IN NUMBER := NULL,
        i_institution IN NUMBER := NULL,
        i_start_dt    IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt      IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_id_tl_task  IN table_number
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'DELETE_TASK_TIMELINE';
        l_error         t_error_out;
        l_where         pk_translation.t_desc_translation;
        l_count_tl_task PLS_INTEGER;
    BEGIN
    
        l_where := ' id_tl_task IN ( ';
    
        l_count_tl_task := i_id_tl_task.count;
        FOR i IN 1 .. l_count_tl_task
        LOOP
            l_where := l_where || i_id_tl_task(i) || CASE
                           WHEN i <> l_count_tl_task THEN
                            ','
                           ELSE
                            ')'
                       END;
        
        END LOOP;
    
        IF (i_patient IS NOT NULL)
        THEN
            l_where := l_where || ' AND id_patient = ' || i_patient;
        END IF;
    
        IF (i_episode IS NOT NULL)
        THEN
            l_where := l_where || ' AND id_episode = ' || i_episode;
        END IF;
    
        IF (i_institution IS NOT NULL)
        THEN
            l_where := l_where || ' AND id_institution = ' || i_institution;
        END IF;
    
        /*IF (i_start_dt IS NOT NULL)
        THEN
            l_where := l_where || ' AND dt_req >= ' || i_institution;
        END IF;*/
    
        IF i_patient IS NULL
           AND i_episode IS NULL
           AND i_institution IS NULL
        THEN
            EXECUTE IMMEDIATE 'DELETE /*+ index(ttea ttea_ttk_fk_idx) */ FROM task_timeline_ea ttea WHERE ' || l_where;
        ELSE
            ts_task_timeline_ea.del_by(where_clause_in => l_where);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => 2,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            dbms_output.put_line(SQLERRM);
        
            RETURN FALSE;
    END delete_task_timeline;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ea_logic_tasktimeline;
/
