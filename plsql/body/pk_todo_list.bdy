/*-- Last Change Revision: $Rev: 2052275 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-06 10:12:10 +0000 (ter, 06 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_todo_list IS

    k_todo_list_mode_count CONSTANT VARCHAR2(0100 CHAR) := 'MODE_COUNT';
    k_todo_list_mode_data  CONSTANT VARCHAR2(0100 CHAR) := 'MODE_DATA';

    g_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
    g_epis_min_date     TIMESTAMP WITH LOCAL TIME ZONE;
    g_dt_server         VARCHAR2(4000);
    g_today             TIMESTAMP WITH LOCAL TIME ZONE;
    g_tomorrow          TIMESTAMP WITH LOCAL TIME ZONE;
    g_exception         EXCEPTION;

    /******************************************************************************
    * Returns pending and depending tasks to show on To-Do List.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_pending         All pending tasks ("my pending tasks")
    * @param o_error           Error message
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jose Brito
    * @version                 0.1
    * @since                   2008-May-21
    *
    ******************************************************************************/
    FUNCTION get_todo_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_pending OUT t_todo_list_tbl,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER;
    
    BEGIN
    
        RETURN get_todo_list_base(i_lang  => i_lang,
                                  i_prof  => i_prof,
                                  i_mode  => k_todo_list_mode_data,
                                  o_rows  => o_pending,
                                  o_count => l_count,
                                  o_error => o_error);
    
    END get_todo_list;

    /******************************************************************************
    * Returns tasks of a certain type (pending or depending) to show on To-Do List
    * for the current professional.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Current professional
    * @param i_prof_cat        Professional category
    * @param i_flg_type        Type of tasks: (P) pending or (D) depending
    * @param i_flg_show_ai     (Y) Show active and inactive episodes (N) Show only active and pending episodes
    * @param i_hand_off_type   Type of hand-off (N) Normal (M) Multiple
    * @param o_tasks           All tasks of type 'i_flg_type'
    * @param o_error           Error message
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jose Brito
    * @version                 0.1
    * @since                   2008-May-21
    *
    ******************************************************************************/

    FUNCTION get_opinion_type(i_category IN NUMBER) RETURN NUMBER IS
    
        tbl_list table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT ot.id_opinion_type
          BULK COLLECT
          INTO tbl_list
          FROM opinion_type ot
         WHERE ot.id_category = i_category;
    
        IF tbl_list.count > 0
        THEN
            l_return := tbl_list(1);
        END IF;
    
        RETURN l_return;
    
    END get_opinion_type;

    FUNCTION get_opinion_id_by_cat(i_category IN NUMBER) RETURN NUMBER IS
    
        tbl_return table_number;
        l_return   NUMBER;
    
    BEGIN
    
        SELECT ot.id_opinion_type
          BULK COLLECT
          INTO tbl_return
          FROM opinion_type ot
         WHERE ot.id_category = i_category;
    
        IF tbl_return.count > 0
        THEN
        
            l_return := tbl_return(1);
        
        END IF;
    
        RETURN l_return;
    
    END get_opinion_id_by_cat;

    FUNCTION get_prof_tasks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_mode          IN VARCHAR2, -- k_todo_list_mode_count / k_todo_list_mode_data
        i_prof_cat      IN category.flg_type%TYPE,
        i_flg_type      IN todo_task.flg_type%TYPE,
        i_flg_show_ai   IN VARCHAR2,
        i_hand_off_type IN sys_config.value%TYPE,
        o_tasks         OUT t_todo_list_tbl,
        o_count         OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_inactdisch BOOLEAN := FALSE;
        err_exception    EXCEPTION;
    
        l_handoff_type sys_config.value%TYPE;
        l_type_opinion opinion_type.id_opinion_type%TYPE;
        l_category     category.id_category%TYPE;
    
        tbl_data todo_list_01_tbl := todo_list_01_tbl();
    
    BEGIN
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        -- Define os casos em que a alta medica inactiva os episodios para que o administrativo possa ver tarefas associadas a esses episodios
        -- (nomeadamente necessidade de dar alta administrativa)
        -- Para ja e so o caso do CARE mas podem ser definidos outros casos
        l_flg_inactdisch := (i_prof.software = g_soft_care);
    
        g_error    := 'GET PROF CATEGORY';
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error        := 'OPEN C_TYPE_REQUEST';
        l_type_opinion := get_opinion_id_by_cat(l_category);
    
        IF i_flg_show_ai = g_no
           OR (i_prof_cat = g_prof_cat_a AND NOT l_flg_inactdisch)
        THEN
            -- Para administrativos so interessam episodios activos e pendentes
            -- Menos no caso do Care onde a alta medica inactiva o episodio
        
            g_error := 'GET CURSOR O_TASKS 1';
            -- get data
            tbl_data := pk_todo_list.get_prof_task_base01(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_prof_cat => i_prof_cat,
                                                          i_flg_type => i_flg_type);
        
        ELSIF i_flg_show_ai = g_yes
              OR (i_prof_cat = g_prof_cat_a AND l_flg_inactdisch)
        THEN
            -- Mostrar episodios activos e inactivos
            -- get data
            tbl_data := pk_todo_list.get_prof_task_base02(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_prof_cat => i_prof_cat,
                                                          i_flg_type => i_flg_type);
        
        ELSE
            g_error := 'INVALID ACTION';
            RAISE err_exception;
        END IF;
    
        IF i_mode = k_todo_list_mode_data
        THEN
            o_tasks := pk_todo_list.get_prof_tasks_transform(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_prof_cat      => i_prof_cat,
                                                             i_flg_type      => i_flg_type,
                                                             i_hand_off_type => i_hand_off_type,
                                                             i_tbl_data      => tbl_data);
        ELSE
            o_tasks := NULL;
            o_count := tbl_data.count;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PROF_TASKS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_tasks;

    --
    /******************************************************************************
    * Returns all information about pending or depending tasks of type 'i_flg_task'
    * for an episode 'i_id_epis'.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Current professional
    * @param i_prof_cat        Professional category
    * @param i_flg_task        Type of task
    * @param i_id_epis         Episode ID
    * @param i_id_patient      Patient ID
    * @param i_id_visit        Current visit ID
    * @param i_flg_type        Type of task status: (P) pending or (D) depending
    * @param o_tasks           Detail about the tasks (pending or depending), when 'i_flg_count' = 'N'
    * @param o_error           Error message
    *
    * @return                  Details about pending/depending tasks
    *
    * @author                  Jose Brito
    * @version                 0.1
    * @since                   2008-Sep-03
    *
    ******************************************************************************/
    FUNCTION get_epis_task_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_flg_task   IN todo_task.flg_task%TYPE,
        i_id_epis    IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        i_flg_type   IN todo_task.flg_type%TYPE,
        o_tasks      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_task_count NUMBER(24);
    
    BEGIN
    
        IF NOT get_epis_task_count_internal(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_prof_cat   => i_prof_cat,
                                            i_flg_task   => i_flg_task,
                                            i_id_epis    => i_id_epis,
                                            i_id_patient => i_id_patient,
                                            i_id_visit   => i_id_visit,
                                            i_flg_type   => i_flg_type,
                                            -- Obter o detalhe das tarefas
                                            i_flg_count  => 'N',
                                            o_task_count => l_task_count,
                                            o_tasks      => o_tasks,
                                            o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_tasks);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_EPIS_TASK_COUNT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_task_count;

    /******************************************************************************
    * Returns the number of pending or depending tasks of type 'i_flg_task' for
    * an episode 'i_id_epis'.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Current professional
    * @param i_prof_cat        Professional category
    * @param i_flg_task        Type of task
    * @param i_id_epis         Episode ID
    * @param i_id_patient      Patient ID
    * @param i_id_visit        Current visit ID
    * @param i_flg_type        Type of task status: (P) pending or (D) depending
    *
    * @return                  Number of pending/depending tasks
    *
    * @author                  Jose Brito
    * @version                 0.1
    * @since                   2008-Sep-03
    *
    ******************************************************************************/
    FUNCTION get_epis_task_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_flg_task   IN todo_task.flg_task%TYPE,
        i_id_epis    IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        i_flg_type   IN todo_task.flg_type%TYPE
    ) RETURN NUMBER IS
    
        l_task_count NUMBER(24);
        l_tasks      pk_types.cursor_type;
        l_error      t_error_out;
    
    BEGIN
    
        IF NOT get_epis_task_count_internal(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_prof_cat   => i_prof_cat,
                                            i_flg_task   => i_flg_task,
                                            i_id_epis    => i_id_epis,
                                            i_id_patient => i_id_patient,
                                            i_id_visit   => i_id_visit,
                                            i_flg_type   => i_flg_type,
                                            -- Obter a contagem das tarefas
                                            i_flg_count  => 'Y',
                                            o_task_count => l_task_count,
                                            o_tasks      => l_tasks,
                                            o_error      => l_error)
        THEN
            l_task_count := 0;
        END IF;
    
        RETURN l_task_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN 0;
    END get_epis_task_count;

    /******************************************************************************
    * Returns the number of pending or depending tasks of type 'i_flg_task' for
    * an episode 'i_id_epis'.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Current professional
    * @param i_prof_cat        Professional category
    * @param i_flg_task        Type of task
    * @param i_id_epis         Episode ID
    * @param i_id_patient      Patient ID
    * @param i_id_visit        Current visit ID
    * @param i_flg_type        Type of task status: (P) pending or (D) depending
    * @param i_epis_flg_status Episode status
    *
    * @return                  Number of pending/depending tasks
    *
    * @author                  Alexandre Santos
    * @version                 2.6.1.0.1
    * @since                   2011-May-11
    *
    ******************************************************************************/
    FUNCTION get_epis_task_count
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_flg_task        IN todo_task.flg_task%TYPE,
        i_id_epis         IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_visit        IN visit.id_visit%TYPE,
        i_flg_type        IN todo_task.flg_type%TYPE,
        i_epis_flg_status IN episode.flg_status%TYPE
    ) RETURN NUMBER IS
    
        l_task_count NUMBER(24);
        l_tasks      pk_types.cursor_type;
    
        l_error t_error_out;
    
    BEGIN
    
        IF NOT get_epis_task_count_internal(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_prof_cat   => i_prof_cat,
                                            i_flg_task   => i_flg_task,
                                            i_id_epis    => i_id_epis,
                                            i_id_patient => i_id_patient,
                                            i_id_visit   => i_id_visit,
                                            i_flg_type   => i_flg_type,
                                            -- Obter a contagem das tarefas
                                            i_flg_count       => 'Y',
                                            i_epis_flg_status => i_epis_flg_status,
                                            o_task_count      => l_task_count,
                                            o_tasks           => l_tasks,
                                            o_error           => l_error)
        THEN
            l_task_count := 0;
        END IF;
    
        RETURN l_task_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN 0;
    END get_epis_task_count;

    /******************************************************************************
    * Internal function used to return the number or the detail of pending/depending
    * tasks of the current professional.
    *
    * If 'i_flg_count' = 'Y', returns the number of pending or depending tasks of
    * type 'i_flg_task' for an episode 'i_id_epis'.
    * If 'i_flg_count' = 'N', returns all information about pending or depending
    * tasks of  type 'i_flg_task' for an episode 'i_id_epis'.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Current professional
    * @param i_prof_cat        Professional category
    * @param i_flg_task        Type of task
    * @param i_id_epis         Episode ID
    * @param i_id_patient      Patient ID
    * @param i_id_visit        Current visit ID
    * @param i_flg_type        Type of task status: (P) pending or (D) depending
    * @param i_flg_count       Action: (Y) Calculate number of tasks (N) Return details about the tasks
    * @param i_epis_flg_status Episode status
    * @param o_task_count      Number of tasks (pending or depending), when 'i_flg_count' = 'Y'
    * @param o_tasks           Detail about the tasks (pending or depending), when 'i_flg_count' = 'N'
    * @param o_error           Error message
    *
    * @return                  Number of or details about the pending/depending tasks
    *
    * @author                  Jose Brito
    * @version                 0.1
    * @since                   2008-May-21
    *
    * @alter                   Jose Brito
    * @version                 0.2
    * @since                   2008-Sep-03
    *
    ******************************************************************************/
    FUNCTION get_epis_task_count_internal
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_flg_task        IN todo_task.flg_task%TYPE,
        i_id_epis         IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_visit        IN visit.id_visit%TYPE,
        i_flg_type        IN todo_task.flg_type%TYPE,
        i_flg_count       IN VARCHAR2,
        i_epis_flg_status IN episode.flg_status%TYPE DEFAULT NULL,
        o_task_count      OUT NUMBER,
        o_tasks           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER(6);
    
        l_flg_ftype  VARCHAR2(1);
        l_visit_desc VARCHAR2(200) := NULL; -- To Do: ainda nao esta a ser usado
    
        l_prof_cat     category.flg_type%TYPE;
        l_handoff_type sys_config.value%TYPE;
    
        l_config sys_config.value%TYPE;
    
        l_is_dicharged VARCHAR2(1 CHAR);
    
        l_count_resp           PLS_INTEGER;
        l_is_to_validate_tasks BOOLEAN;
    
    BEGIN
    
        o_task_count := 0;
    
        g_error := 'GET PROF CAT';
        --alertlog.pk_alertlog.log_info(text => g_error);
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET HANDOFF TYPE';
        --alertlog.pk_alertlog.log_info(text => g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        --ALERT-286953 - Remove filter by resp_prof from co-sign tasks
        IF i_flg_task != g_task_co
           AND i_flg_type = g_pending
           AND l_prof_cat IN (g_prof_cat_d, g_prof_cat_n)
        THEN
            IF l_handoff_type = pk_hand_off.g_handoff_multiple
            THEN
                SELECT COUNT(1)
                  INTO l_count_resp
                  FROM epis_multi_prof_resp empr, epis_prof_resp epr
                 WHERE empr.id_episode = i_id_epis
                   AND empr.flg_status = pk_hand_off_core.g_active
                   AND empr.flg_profile IN (SELECT pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL)
                                              FROM dual)
                   AND epr.id_epis_prof_resp = empr.id_epis_prof_resp
                   AND epr.flg_type = i_prof_cat
                   AND epr.flg_status = pk_hand_off.g_hand_off_f
                   AND empr.id_professional = i_prof.id;
            ELSE
                SELECT COUNT(1)
                  INTO l_count_resp
                  FROM epis_info e
                 WHERE e.id_episode = i_id_epis
                   AND decode(i_prof_cat,
                              g_prof_cat_d,
                              e.id_professional,
                              g_prof_cat_n,
                              e.id_first_nurse_resp,
                              i_prof.id) = i_prof.id;
            END IF;
        
            IF l_count_resp > 0
            THEN
                l_is_to_validate_tasks := TRUE;
            ELSE
                l_is_to_validate_tasks := FALSE;
            END IF;
        ELSE
            l_is_to_validate_tasks := TRUE;
        END IF;
    
        IF l_is_to_validate_tasks
        THEN
        
            -- DRUG PRESCRIPTION
            IF i_flg_task = g_task_dp
            THEN
                IF NOT pk_api_pfh_clindoc_in.get_todo_drug_presc(i_lang       => i_lang,
                                                                 i_prof       => i_prof,
                                                                 i_id_epis    => i_id_epis,
                                                                 i_flg_type   => i_flg_type,
                                                                 i_flg_count  => i_flg_count,
                                                                 i_visit_desc => l_visit_desc,
                                                                 i_dt_server  => g_dt_server,
                                                                 o_task_count => l_count,
                                                                 o_tasks      => o_tasks,
                                                                 o_error      => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                -- PROCEDURES
            ELSIF i_flg_task = g_task_pr
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM procedures_ea pea
                     WHERE pea.flg_status_det IN ('D', 'S', 'R')
                       AND pea.id_episode = i_id_epis;
                
                ELSE
                    OPEN o_tasks FOR
                        SELECT pk_procedures_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'INTERVENTION.CODE_INTERVENTION.' ||
                                                                          pea.id_intervention,
                                                                          NULL) task_desc,
                               pk_date_utils.date_chr_extend_tsz(i_lang, pea.dt_begin_req, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, pea.dt_begin_req, i_prof) ||
                               '|I|X|WaitingIcon' event_time,
                               g_dt_server dt_server
                          FROM procedures_ea pea
                         WHERE pea.flg_status_det IN ('D', 'S', 'R')
                           AND pea.id_episode = i_id_epis;
                END IF;
            
                -- ANALYSIS
            ELSIF i_flg_task = g_task_a
            THEN
            
                IF i_flg_type = g_pending
                THEN
                    -- Tarefas de ANALISES pendentes
                    IF i_flg_count = g_yes
                    THEN
                        -- < DESNORM LAMIA 18-10-2008 >
                        SELECT COUNT(*)
                          INTO l_count
                          FROM lab_tests_ea lte, analysis_req ar
                         WHERE lte.id_visit = i_id_visit
                           AND lte.flg_status_det != 'L'
                           AND lte.id_analysis_result IS NOT NULL
                           AND lte.id_analysis_result IN
                               (SELECT MAX(lte2.id_analysis_result)
                                  FROM lab_tests_ea lte2
                                 WHERE lte2.id_analysis = lte.id_analysis
                                   AND lte2.id_analysis_req_det = lte.id_analysis_req_det)
                           AND (lte.flg_status_harvest != 'C' OR lte.flg_status_harvest IS NULL)
                           AND lte.id_prof_writes = i_prof.id
                           AND lte.id_institution = i_prof.institution
                           AND lte.id_analysis_req = ar.id_analysis_req;
                        -- < END DESNORM >
                    
                    ELSE
                        OPEN o_tasks FOR
                        -- < DESNORM LMAIA 18-10-2008 >
                            SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                             i_prof,
                                                                             'A',
                                                                             'ANALYSIS.CODE_ANALYSIS.' ||
                                                                             lte.id_analysis,
                                                                             NULL) task_desc,
                                   pk_date_utils.date_chr_extend_tsz(i_lang, ar.dt_begin_tstz, i_prof) task_date,
                                   l_visit_desc visit_desc,
                                   '|' || pk_date_utils.date_send_tsz(i_lang, ar.dt_begin_tstz, i_prof) ||
                                   '|I|X|WaitingIcon' event_time,
                                   g_dt_server dt_server
                              FROM lab_tests_ea lte, analysis_req ar
                             WHERE i_id_visit = lte.id_visit
                               AND lte.id_analysis_req = ar.id_analysis_req
                               AND lte.flg_status_det != 'L'
                                  --AND a.id_analysis = ard.id_analysis
                               AND lte.id_analysis_result IS NOT NULL --AND ares.id_analysis_req_det = ard.id_analysis_req_det
                               AND lte.id_analysis_result IN
                                   (SELECT MAX(lte2.id_analysis_result)
                                      FROM lab_tests_ea lte2
                                     WHERE lte2.id_analysis = lte.id_analysis
                                       AND lte2.id_analysis_req_det = lte.id_analysis_req_det)
                               AND (lte.flg_status_harvest != 'C' OR lte.flg_status_harvest IS NULL) --g_harvest_canc
                               AND lte.id_prof_writes = i_prof.id
                               AND lte.id_institution = i_prof.institution;
                        -- < END DESNORM >
                    END IF;
                
                ELSIF i_flg_type = g_depending
                THEN
                    IF i_flg_count = g_yes
                    THEN
                        -- < DESNORM LMAIA 18-10-2008 >
                        SELECT COUNT(*)
                          INTO l_count
                          FROM (
                                -- Requisicoes de analises SEM resultados
                                SELECT lte.id_analysis_req_det
                                  FROM lab_tests_ea lte,
                                        analysis_req ar,
                                        (SELECT *
                                           FROM analysis_instit_soft
                                          WHERE id_institution = i_prof.institution
                                            AND flg_available = g_flg_available
                                            AND id_software = i_prof.software) adcs
                                 WHERE lte.id_visit = i_id_visit
                                   AND lte.id_analysis_req = ar.id_analysis_req
                                   AND adcs.id_analysis(+) = lte.id_analysis
                                   AND lte.id_analysis_result IS NULL
                                   AND (lte.flg_status_harvest != 'C' OR lte.flg_status_harvest IS NULL)
                                   AND lte.flg_status_det != 'C'
                                   AND lte.id_prof_writes = i_prof.id
                                   AND lte.id_institution = i_prof.institution
                                UNION ALL
                                -- Resultados de episodios anteriores ainda nao lidos
                                SELECT lte.id_analysis_req_det
                                  FROM lab_tests_ea lte,
                                        analysis_req ar,
                                        (SELECT *
                                           FROM analysis_instit_soft
                                          WHERE id_institution = i_prof.institution
                                            AND flg_available = g_flg_available
                                            AND id_software = i_prof.software) adcs
                                 WHERE lte.id_patient = i_id_patient
                                   AND lte.id_visit != i_id_visit
                                   AND lte.id_prev_episode IS NULL
                                   AND lte.id_analysis_req = ar.id_analysis_req
                                   AND adcs.id_analysis(+) = lte.id_analysis
                                   AND lte.id_analysis_result IS NOT NULL
                                   AND (lte.flg_status_harvest != 'C' OR lte.flg_status_harvest IS NULL)
                                   AND lte.flg_status_det NOT IN ('C', 'L')
                                   AND lte.id_prof_writes = i_prof.id
                                   AND lte.id_institution = i_prof.institution
                                   AND pk_episode.get_epis_type(i_lang, lte.id_episode) <> 2);
                        -- < END DESNORM >
                    
                    ELSE
                        OPEN o_tasks FOR
                        -- < DESNORM LMAIA 18-10-2008 >
                            SELECT pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', t.code_analysis, NULL) task_desc,
                                   pk_date_utils.date_chr_extend_tsz(i_lang, t.dt_begin_tstz, i_prof) task_date,
                                   l_visit_desc visit_desc,
                                   '|' || pk_date_utils.date_send_tsz(i_lang, t.dt_begin_tstz, i_prof) ||
                                   '|I|X|WaitingIcon' event_time,
                                   g_dt_server dt_server
                              FROM (
                                    -- Requisicoes de analises SEM resultados
                                    SELECT concat('ANALYSIS.CODE_ANALYSIS.', lte.id_analysis) code_analysis,
                                            ar.dt_begin_tstz
                                      FROM lab_tests_ea lte,
                                            analysis_req ar,
                                            (SELECT *
                                               FROM analysis_instit_soft
                                              WHERE id_institution = i_prof.institution
                                                AND flg_available = g_flg_available
                                                AND id_software = i_prof.software) adcs
                                     WHERE lte.id_visit = i_id_visit
                                       AND lte.id_analysis_req = ar.id_analysis_req
                                       AND adcs.id_analysis(+) = lte.id_analysis
                                       AND lte.id_analysis_result IS NULL
                                       AND (lte.flg_status_harvest != 'C' OR lte.flg_status_harvest IS NULL)
                                       AND lte.flg_status_det != 'C'
                                       AND lte.id_prof_writes = i_prof.id
                                       AND lte.id_institution = i_prof.institution
                                    UNION ALL
                                    -- Resultados de episodios anteriores ainda nao lidos
                                    SELECT concat('ANALYSIS.CODE_ANALYSIS.', lte.id_analysis) code_analysis,
                                            ar.dt_begin_tstz
                                      FROM lab_tests_ea lte,
                                            analysis_req ar,
                                            (SELECT *
                                               FROM analysis_instit_soft
                                              WHERE id_institution = i_prof.institution
                                                AND flg_available = g_flg_available
                                                AND id_software = i_prof.software) adcs
                                     WHERE lte.id_patient = i_id_patient
                                       AND lte.id_visit != i_id_visit
                                       AND lte.id_prev_episode IS NULL
                                       AND lte.id_analysis_req = ar.id_analysis_req
                                       AND adcs.id_analysis(+) = lte.id_analysis
                                       AND lte.id_analysis_result IS NOT NULL
                                       AND (lte.flg_status_harvest != 'C' OR lte.flg_status_harvest IS NULL)
                                       AND lte.flg_status_det NOT IN ('C', 'L')
                                       AND lte.id_prof_writes = i_prof.id
                                       AND lte.id_institution = i_prof.institution
                                       AND pk_episode.get_epis_type(i_lang, ar.id_episode) <> 2) t;
                        -- < END DESNORM >
                    END IF;
                END IF;
            
                -- HARVEST
            ELSIF i_flg_task = g_task_h
            THEN
            
                IF i_flg_type = g_pending
                THEN
                    l_config := pk_sysconfig.get_config('HARVEST_PENDING_REQ', i_prof);
                
                    IF i_flg_count = g_yes
                    THEN
                        -- < DESNORM LMAIA 18-10-2008 >
                        SELECT COUNT(*)
                          INTO l_count
                          FROM lab_tests_ea lte
                         WHERE nvl(lte.flg_status_harvest, 'X') NOT IN ('H', 'C')
                           AND ((l_config = 'Y' AND lte.flg_status_det IN ('R', 'D')) OR
                                (l_config = 'N' AND lte.flg_status_det = 'R'))
                           AND lte.flg_col_inst = 'Y'
                           AND i_id_visit = lte.id_visit
                           AND (lte.flg_time_harvest = 'E' OR
                                (lte.flg_time_harvest = 'B' AND lte.dt_target BETWEEN g_today AND g_tomorrow))
                           AND lte.id_institution = i_prof.institution;
                        -- < END DESNORM >
                    
                    ELSE
                        OPEN o_tasks FOR
                        -- < DESNORM LMAIA 18-10-2008 >
                        -- Validada troca DT_BEGIN por DT_TARGET pelo Gustavo em 20-10-2008
                            SELECT pk_translation.get_translation(i_lang,
                                                                  'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lte.id_sample_type) task_desc,
                                   pk_date_utils.date_chr_extend_tsz(i_lang, lte.dt_target, i_prof) task_date,
                                   l_visit_desc visit_desc,
                                   '|' || pk_date_utils.date_send_tsz(i_lang, lte.dt_target, i_prof) ||
                                   '|I|X|WaitingIcon' event_time,
                                   g_dt_server dt_server
                              FROM lab_tests_ea lte
                             WHERE nvl(lte.flg_status_harvest, 'X') NOT IN ('H', 'C')
                               AND ((l_config = 'Y' AND lte.flg_status_det IN ('R', 'D')) OR
                                    (l_config = 'N' AND lte.flg_status_det = 'R'))
                               AND lte.flg_col_inst = 'Y'
                               AND i_id_visit = lte.id_visit
                               AND (lte.flg_time_harvest = 'E' OR
                                    (lte.flg_time_harvest = 'B' AND lte.dt_target BETWEEN g_today AND g_tomorrow))
                                  --AND a.id_analysis = ard.id_analysis
                               AND lte.id_institution = i_prof.institution;
                        -- < END DESNORM >
                    END IF;
                END IF;
            
                -- EXAMS / IMAGING EXAMS
            ELSIF i_flg_task IN (g_task_e, g_task_ie)
            THEN
                IF i_flg_task = g_task_e
                THEN
                    l_flg_ftype := 'E';
                ELSE
                    l_flg_ftype := 'I';
                END IF;
            
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM exams_ea eea,
                           -- Jose Brito 20/11/2008 ALERT-8094
                           (SELECT edcs.flg_first_result, edcs.id_exam
                              FROM exam_dep_clin_serv edcs
                             WHERE edcs.id_institution = i_prof.institution
                               AND edcs.id_software = i_prof.software
                               AND edcs.flg_type = 'P') dcs
                     WHERE eea.flg_type = l_flg_ftype
                       AND eea.id_visit = i_id_visit -- Jose Brito 05/03/2010 ALERT-76354
                       AND eea.id_exam = dcs.id_exam
                       AND -- Exames PENDENTES: finalizados OU requisitado e primeiro resultado pelo medico
                           (i_flg_type = g_pending AND (eea.flg_status_det = 'F'
                           --  OR (instr(dcs.flg_first_result, i_prof_cat) > 0 AND                        eea.flg_status_det = 'R')
                           ) OR
                           -- Exames DEPENDENTES de outros profissionais: pendentes, requisitados ou em execucao
                           -- e primeiro resultado nao e permitido pelo medico
                           (i_flg_type = g_depending AND eea.flg_status_det IN ('D', 'R', 'E') AND
                           instr(dcs.flg_first_result, i_prof_cat) = 0));
                ELSE
                    OPEN o_tasks FOR
                        SELECT pk_exams_api_db.get_alias_translation(i_lang,
                                                                     i_prof,
                                                                     'EXAM.CODE_EXAM.' || eea.id_exam,
                                                                     NULL) task_desc,
                               pk_date_utils.date_chr_extend_tsz(i_lang, eea.dt_begin, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, eea.dt_begin, i_prof) || '|I|X|WaitingIcon' event_time,
                               g_dt_server dt_server
                          FROM exams_ea eea,
                               -- Jose Brito 20/11/2008 ALERT-8094
                               (SELECT edcs.flg_first_result, edcs.id_exam
                                  FROM exam_dep_clin_serv edcs
                                 WHERE edcs.id_institution = i_prof.institution
                                   AND edcs.id_software = i_prof.software
                                   AND edcs.flg_type = 'P') dcs
                         WHERE eea.flg_type = l_flg_ftype
                           AND eea.id_visit = i_id_visit
                           AND eea.id_exam = dcs.id_exam
                           AND -- Exames PENDENTES: finalizados OU requisitado e primeiro resultado pelo medico
                               (i_flg_type = g_pending AND (eea.flg_status_det = 'F' --OR
                               --  (instr(dcs.flg_first_result, i_prof_cat) > 0 AND eea.flg_status_det = 'R')
                               ) OR
                               -- Exames DEPENDENTES de outros profissionais: pendentes, requisitados ou em execucao
                               -- e primeiro resultado nao e permitido pelo medico
                               (i_flg_type = g_depending AND eea.flg_status_det IN ('D', 'R', 'E') AND
                               instr(dcs.flg_first_result, i_prof_cat) = 0));
                END IF;
            
                -- PATIENT EDUCATION
            ELSIF i_flg_task = g_task_pe
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM nurse_tea_req n
                     WHERE n.id_episode = i_id_epis
                       AND n.flg_status IN ('A', 'D');
                
                ELSE
                    OPEN o_tasks FOR
                        SELECT n.notes_req task_desc,
                               pk_date_utils.date_chr_extend_tsz(i_lang, n.dt_begin_tstz, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, n.dt_begin_tstz, i_prof) ||
                               '|I|X|WaitingIcon' event_time,
                               g_dt_server dt_server
                          FROM nurse_tea_req n
                         WHERE n.id_episode = i_id_epis
                           AND n.flg_status IN ('A', 'D');
                END IF;
            
                -- RESERVE / BLOOD RESERVE
                --Remove ORIS reserve logic
            ELSIF i_flg_task = g_task_br
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM sr_reserv_req srr, sr_equip se
                     WHERE srr.flg_type = 'R' -- Mostrar so as reservas, pois os consumos nao sao visualizados nas grelhas
                       AND srr.flg_status = 'R'
                       AND i_id_epis IN (srr.id_episode, srr.id_episode_context)
                       AND srr.id_sr_equip = se.id_sr_equip
                       AND se.flg_hemo_yn = pk_alert_constant.g_yes; -- (Y) Reservas de Sangue (N) Reservas de equipamento
                ELSE
                    OPEN o_tasks FOR
                        SELECT pk_translation.get_translation(i_lang, se.code_equip) task_desc,
                               pk_date_utils.date_chr_extend_tsz(i_lang, srr.dt_req_tstz, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, srr.dt_req_tstz, i_prof) ||
                               '|I|X|WaitingIcon' event_time,
                               g_dt_server dt_server
                          FROM sr_reserv_req srr, sr_equip se
                         WHERE srr.flg_type = 'R' -- Mostrar so as reservas, pois os consumos nao sao visualizados nas grelhas
                           AND srr.flg_status = 'R'
                           AND i_id_epis IN (srr.id_episode, srr.id_episode_context)
                           AND srr.id_sr_equip = se.id_sr_equip
                           AND se.flg_hemo_yn = pk_alert_constant.g_yes; -- (Y) Reservas de Sangue (N) Reservas de equipamento
                END IF;
            
                -- POSITIONING
            ELSIF i_flg_task = g_task_po
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM epis_positioning ep
                     WHERE ep.id_episode = i_id_epis
                       AND ep.flg_status IN ('R');
                
                ELSE
                    OPEN o_tasks FOR
                        SELECT (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                                  FROM positioning p, epis_positioning_det epd1, epis_positioning_plan epp
                                 WHERE p.id_positioning = epd1.id_positioning
                                   AND epd1.id_epis_positioning = ep.id_epis_positioning
                                   AND epd1.id_epis_positioning_det = epp.id_epis_positioning_det
                                   AND epp.flg_status = 'E') || ', ' ||
                               (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                                  FROM positioning p, epis_positioning_det epd1, epis_positioning_plan epp
                                 WHERE p.id_positioning = epd1.id_positioning
                                   AND epd1.id_epis_positioning = ep.id_epis_positioning
                                   AND epd1.id_epis_positioning_det = epp.id_epis_positioning_next
                                   AND epp.flg_status = 'E') task_desc,
                               pk_date_utils.date_chr_extend_tsz(i_lang, ep.dt_creation_tstz, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, ep.dt_creation_tstz, i_prof) ||
                               '|I|X|WaitingIcon' event_time,
                               g_dt_server dt_server
                          FROM epis_positioning ep
                         WHERE ep.id_episode = i_id_epis
                           AND ep.flg_status IN ('R');
                END IF;
            
                -- INTAKE AND OUTPUT
            ELSIF i_flg_task = g_task_io
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM epis_hidrics eh
                     WHERE eh.id_episode IN (SELECT epis.id_episode
                                               FROM episode epis
                                              WHERE epis.id_visit = i_id_visit) -- Jose Brito 05/03/2010 ALERT-76354
                       AND eh.flg_status IN ('R');
                
                ELSE
                    OPEN o_tasks FOR
                        SELECT pk_translation.get_translation(i_lang,
                                                              'HIDRICS_TYPE.CODE_HIDRICS_TYPE.' || eh.id_hidrics_type) task_desc,
                               pk_date_utils.date_chr_extend_tsz(i_lang, eh.dt_creation_tstz, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, eh.dt_creation_tstz, i_prof) ||
                               '|I|X|WaitingIcon' event_time,
                               g_dt_server dt_server
                          FROM epis_hidrics eh
                         WHERE eh.id_episode IN (SELECT epis.id_episode
                                                   FROM episode epis
                                                  WHERE epis.id_visit = i_id_visit) -- Jose Brito 05/03/2010 ALERT-76354
                           AND eh.flg_status IN ('R');
                END IF;
            
                -- MONITORIZATION
            ELSIF i_flg_task = g_task_m
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM monitorizations_ea mea
                     WHERE mea.id_episode = i_id_epis
                       AND mea.flg_status IN ('A', 'D')
                       AND mea.flg_time IN ('E', 'B')
                       AND mea.flg_status_det IN ('A', 'D')
                       AND mea.dt_plan <= current_timestamp;
                ELSE
                    OPEN o_tasks FOR
                        SELECT pk_translation.get_translation(i_lang,
                                                              'VITAL_SIGN.CODE_VITAL_SIGN.' || mea.id_vital_sign) task_desc,
                               pk_date_utils.date_chr_extend_tsz(i_lang, mea.dt_begin, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, mea.dt_begin, i_prof) || '|I|X|WaitingIcon' event_time,
                               g_dt_server dt_server
                          FROM monitorizations_ea mea
                         WHERE mea.id_episode = i_id_epis
                           AND mea.flg_status IN ('A', 'D')
                           AND mea.flg_time IN ('E', 'B')
                           AND mea.flg_status_det IN ('A', 'D')
                           AND mea.dt_plan <= current_timestamp;
                END IF;
            
                -- HARVEST TRANSPORT
            ELSIF i_flg_task = g_task_ht
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM harvest h, analysis_harvest ah, lab_tests_ea lte
                     WHERE h.id_episode = i_id_epis
                       AND h.flg_status = 'H' -- Colhido
                       AND h.id_institution = i_prof.institution
                       AND h.id_harvest = ah.id_harvest
                       AND ah.id_analysis_req_det = lte.id_analysis_req_det
                       AND lte.flg_status_det = 'E';
                
                ELSE
                    OPEN o_tasks FOR
                    -- < DESNORM LMAIA 20-10-2008 >
                    -- Validada troca DT_BEGIN por DT_TARGET pelo Gustavo em 20-10-2008
                        SELECT pk_translation.get_translation(i_lang,
                                                              'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                              ah.id_sample_recipient) task_desc,
                               pk_date_utils.date_chr_extend_tsz(i_lang, lte.dt_target, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, lte.dt_target, i_prof) || '|I|X|WaitingIcon' event_time,
                               g_dt_server dt_server
                          FROM harvest h, analysis_harvest ah, lab_tests_ea lte
                         WHERE h.id_episode = i_id_epis
                           AND h.flg_status = 'H' -- Colhido
                           AND h.id_institution = i_prof.institution
                           AND h.id_harvest = ah.id_harvest
                           AND ah.id_analysis_req_det = lte.id_analysis_req_det
                           AND lte.flg_status_det = 'E';
                    -- < END DESNORM >
                END IF;
            
                -- PATIENT TRANSPORT
            ELSIF i_flg_task = g_task_pt
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM movement mv
                     WHERE mv.id_episode = i_id_epis
                       AND mv.flg_status IN ('R', 'P');
                
                ELSE
                    OPEN o_tasks FOR
                        SELECT (SELECT sd.desc_val
                                  FROM sys_domain sd
                                 WHERE sd.code_domain = 'MOVEMENT.FLG_STATUS'
                                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                                   AND sd.id_language = i_lang
                                   AND sd.val = mv.flg_status) task_desc,
                               pk_date_utils.date_chr_extend_tsz(i_lang, mv.dt_req_tstz, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, mv.dt_req_tstz, i_prof) || '|I|X|WaitingIcon' event_time,
                               g_dt_server dt_server
                          FROM movement mv
                         WHERE mv.id_episode = i_id_epis
                           AND mv.flg_status IN ('R', 'P');
                END IF;
            
                -- CLINICAL FILE TRANSPORT
            ELSIF i_flg_task = g_task_ft
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM cli_rec_req cr, cli_rec_req_det crd, cli_rec_req_mov crm
                     WHERE cr.id_episode = i_id_epis
                       AND cr.id_cli_rec_req = crd.id_cli_rec_req
                       AND crd.id_cli_rec_req_det = crm.id_cli_rec_req_det
                       AND cr.flg_status = 'E'
                       AND crd.flg_status = 'E'
                       AND crm.flg_status = 'O'; -- Pronto para transporte
                
                ELSE
                    OPEN o_tasks FOR
                        SELECT NULL task_desc, -- TO DO: O que colocar no descritivo desta tarefa??
                               pk_date_utils.date_chr_extend_tsz(i_lang, crm.dt_req_transp_tstz, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, crm.dt_req_transp_tstz, i_prof) ||
                               '|I|X|WaitingIcon' event_time,
                               g_dt_server dt_server
                          FROM cli_rec_req cr, cli_rec_req_det crd, cli_rec_req_mov crm
                         WHERE cr.id_episode = i_id_epis
                           AND cr.id_cli_rec_req = crd.id_cli_rec_req
                           AND crd.id_cli_rec_req_det = crm.id_cli_rec_req_det
                           AND cr.flg_status = 'E'
                           AND crd.flg_status = 'E'
                           AND crm.flg_status = 'O'; -- Pronto para transporte
                END IF;
            
                -- ADMINISTRATIVE DISCHARGE
            ELSIF i_flg_task = g_task_ad
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM discharge d
                     WHERE d.id_episode = i_id_epis
                       AND d.flg_status IN ('A', 'P')
                          -- Jose Brito 13/02/2009 ALERT-15882
                          -- Mostrar alta administrativa no CARE
                          --AND d.flg_type = 'F' -- Fim de episodio
                       AND pk_discharge_core.check_admin_discharge(i_lang, i_prof, NULL, d.flg_status_adm) =
                           pk_alert_constant.g_no
                       AND nvl(i_epis_flg_status, pk_alert_constant.g_active) != pk_alert_constant.g_inactive;
                
                ELSE
                    OPEN o_tasks FOR
                        SELECT NULL task_desc, -- TO DO: O que colocar no descritivo desta tarefa??
                               -- Mostra a data da alta medica
                               pk_date_utils.date_chr_extend_tsz(i_lang, d.dt_med_tstz, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, d.dt_med_tstz, i_prof) || '|I|X|WaitingIcon' event_time,
                               g_dt_server dt_server
                          FROM discharge d
                         WHERE d.id_episode = i_id_epis
                           AND d.flg_status IN ('A', 'P')
                              --AND d.flg_type = 'F' -- Fim de episodio
                           AND pk_discharge_core.check_admin_discharge(i_lang, i_prof, NULL, d.flg_status_adm) =
                               pk_alert_constant.g_no
                           AND nvl(i_epis_flg_status, pk_alert_constant.g_active) != pk_alert_constant.g_inactive;
                END IF;
            
                -- CO-SIGN
            ELSIF i_flg_task = g_task_co
            THEN
                -- Private Practice
                IF i_prof.software = g_soft_pp
                THEN
                    IF i_flg_count = g_yes
                    THEN
                        SELECT COUNT(*)
                          INTO l_count
                          FROM epis_sign_off eso,
                               (SELECT id_episode, MAX(dt_event) dt_event
                                  FROM epis_sign_off
                                 GROUP BY id_episode) state
                         WHERE eso.id_episode = i_id_epis
                           AND eso.id_episode = state.id_episode
                           AND eso.dt_event = state.dt_event
                           AND eso.flg_state = 'SC'
                           AND eso.id_professional_dest = i_prof.id
                           AND eso.flg_real <> 'N';
                    ELSE
                        OPEN o_tasks FOR
                            SELECT NULL task_desc, -- TO DO: O que colocar no descritivo desta tarefa??
                                   pk_date_utils.date_chr_extend_tsz(i_lang, eso.dt_event, i_prof) task_date,
                                   l_visit_desc visit_desc,
                                   '|' || pk_date_utils.date_send_tsz(i_lang, eso.dt_event, i_prof) ||
                                   '|I|X|WaitingIcon' event_time,
                                   g_dt_server dt_server
                              FROM epis_sign_off eso,
                                   (SELECT id_episode, MAX(dt_event) dt_event
                                      FROM epis_sign_off
                                     GROUP BY id_episode) state
                             WHERE eso.id_episode = i_id_epis
                               AND eso.id_episode = state.id_episode
                               AND eso.dt_event = state.dt_event
                               AND eso.flg_state = 'SC'
                               AND eso.id_professional_dest = i_prof.id
                               AND eso.flg_real <> 'N';
                    END IF;
                
                ELSE
                    IF i_flg_count = g_yes
                    THEN
                        -- EDIS
                        SELECT COUNT(1)
                          INTO l_count
                          FROM TABLE(pk_co_sign_api.tf_pending_co_sign_tasks(i_lang    => i_lang,
                                                                             i_prof    => i_prof,
                                                                             i_episode => i_id_epis)) c
                         WHERE c.id_prof_ordered_by = i_prof.id;
                        -- Jose Brito 04/12/2008 ALERT-11331
                        -- From now on, any physician can confirm co-sign.
                        -- E.g. if physician 'A' ordered the task, physician 'B' can confirm co-sign.
                        -- Previously, only physician 'A' was allowed to confirm co-sign.
                    ELSE
                        OPEN o_tasks FOR
                            SELECT t.task_lbl task_desc,
                                   pk_date_utils.date_chr_extend_tsz(i_lang, t.task_dt, i_prof) task_date,
                                   l_visit_desc visit_desc,
                                   '|' || pk_date_utils.date_send_tsz(i_lang, t.task_dt, i_prof) || '|I|X|WaitingIcon' event_time,
                                   g_dt_server dt_server
                              FROM (SELECT cst.desc_order task_lbl, cst.dt_ordered_by task_dt
                                      FROM TABLE(pk_co_sign_api.tf_pending_co_sign_tasks(i_lang    => i_lang,
                                                                                         i_prof    => i_prof,
                                                                                         i_episode => i_id_epis)) cst
                                     WHERE cst.id_prof_ordered_by = i_prof.id) t;
                    END IF;
                END IF;
            
                -- SIGN-OFF
            ELSIF i_flg_task = g_task_so
            THEN
            
                IF i_flg_count = g_yes
                THEN
                    BEGIN
                    
                        g_error := 'GET PROF CAT';
                        alertlog.pk_alertlog.log_info(text => g_error);
                        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
                    
                        g_error := 'GET HANDOFF TYPE';
                        alertlog.pk_alertlog.log_info(text => g_error);
                        pk_hand_off_core.get_hand_off_type(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           io_hand_off_type => l_handoff_type);
                    
                        --Esta tarefa so devera aparecer depois da alta
                        IF NOT pk_discharge.get_epis_discharge_state(i_lang      => i_lang,
                                                                     i_prof      => i_prof,
                                                                     i_episode   => i_id_epis,
                                                                     o_discharge => l_is_dicharged,
                                                                     o_error     => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        -- As tarefas de Sign-off so devem surgir para episodios sob a responsabilidade do profissional
                        IF pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                            i_prof,
                                                                                            i_id_epis,
                                                                                            l_prof_cat,
                                                                                            l_handoff_type),
                                                        i_prof.id) != -1
                        THEN
                            --Se nao tem alta, tambem nao aparece a tarefa de SO
                            IF l_is_dicharged = pk_alert_constant.g_no
                            THEN
                                l_count := 0;
                            ELSE
                                SELECT ((SELECT decode(COUNT(*), 0, 1, 0)
                                           FROM epis_sign_off eso
                                          WHERE eso.id_episode = i_id_epis) +
                                       (SELECT COUNT(*)
                                           FROM (SELECT id_episode,
                                                        MAX(dt_event) over(PARTITION BY id_episode) max_dt_event,
                                                        dt_event,
                                                        flg_state,
                                                        flg_real
                                                   FROM epis_sign_off)
                                          WHERE dt_event = max_dt_event
                                            AND flg_state = 'C'
                                            AND id_episode = i_id_epis
                                            AND flg_real = 'N'))
                                  INTO l_count
                                  FROM dual;
                            END IF;
                        ELSE
                            l_count := 0;
                        END IF;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_count := 0;
                    END;
                ELSE
                    -- Na versao 2.4.2. as tarefas de Sign-off nao mostravam nada no Viewer
                    pk_types.open_my_cursor(o_tasks);
                END IF;
            
                -- INSTITUTION TRANSFER
            ELSIF i_flg_task = g_task_it
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM transfer_institution t
                     WHERE ((t.flg_status = 'R' AND t.id_institution_origin = i_prof.institution) OR
                           (t.flg_status = 'T' AND t.id_institution_dest = i_prof.institution))
                       AND t.id_episode = i_id_epis;
                ELSE
                    OPEN o_tasks FOR
                        SELECT t.notes task_desc,
                               pk_date_utils.date_chr_extend_tsz(i_lang, t.dt_creation_tstz, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, t.dt_creation_tstz, i_prof) ||
                               pk_sysdomain.get_img(i_lang, 'TRANSFER_INSTITUTION.FLG_STATUS', t.flg_status) event_time,
                               g_dt_server dt_server
                          FROM transfer_institution t
                         WHERE ((t.flg_status = 'R' AND t.id_institution_origin = i_prof.institution) OR
                               (t.flg_status = 'T' AND t.id_institution_dest = i_prof.institution))
                           AND t.id_episode = i_id_epis;
                END IF;
            
            ELSIF i_flg_task = g_task_td
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM therapeutic_decision t, therapeutic_decision_det td
                     WHERE td.id_professional = i_prof.id
                       AND nvl(td.flg_opinion, 'N') = 'N'
                       AND td.flg_status = 'A'
                       AND td.flg_presence = 'P'
                       AND t.id_therapeutic_decision = td.id_therapeutic_decision
                       AND t.flg_status = 'A'
                       AND t.id_patient = i_id_patient;
                ELSE
                    OPEN o_tasks FOR
                        SELECT *
                          FROM dual;
                END IF;
                -- ADDENDUMS SIGNOFF
            ELSIF i_flg_task = g_task_as
            THEN
                IF i_flg_count = g_yes
                THEN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM epis_addendum ea
                      JOIN epis_sign_off eso
                        ON (ea.id_epis_sign_off = eso.id_epis_sign_off)
                     WHERE ea.flg_status = 'A'
                       AND eso.id_episode = i_id_epis;
                
                ELSE
                    OPEN o_tasks FOR
                        SELECT NULL task_desc,
                               pk_date_utils.date_chr_extend_tsz(i_lang, ea.dt_event, i_prof) task_date,
                               l_visit_desc visit_desc,
                               '|' || pk_date_utils.date_send_tsz(i_lang, ea.dt_event, i_prof) || '|I|X|SignOffIcon' event_time,
                               g_dt_server dt_server
                          FROM epis_addendum ea
                          JOIN epis_sign_off eso
                            ON (ea.id_epis_sign_off = eso.id_epis_sign_off)
                         WHERE ea.flg_status = 'A'
                           AND eso.id_episode = i_id_epis;
                END IF;
            
            ELSE
                l_count := 0;
            END IF;
        END IF;
    
        o_task_count := l_count;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_tasks);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_EPIS_TASK_COUNT_INTERNAL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_task_count_internal;

    /******************************************************************************
    * Returns all options displayed in the views button.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_list            View button options
    * @param o_error           Error message
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jose Brito
    * @version                 0.1
    * @since                   2008-Nov-05
    *
    ******************************************************************************/
    FUNCTION get_todo_list_views
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_profile_template profile_template.id_profile_template%TYPE;
        l_prof_type        profile_template.flg_type%TYPE;
    
        CURSOR c_profile_template IS
            SELECT ppt.id_profile_template, pt.flg_type
              FROM prof_profile_template ppt, profile_template pt, software s
             WHERE ppt.id_professional = i_prof.id
               AND ppt.id_software IN (i_prof.software, 0)
               AND ppt.id_institution IN (i_prof.institution, 0)
               AND ppt.id_profile_template = pt.id_profile_template
               AND pt.id_software = s.id_software
               AND s.flg_viewer = 'N';
    
        l_market market.id_market%TYPE;
        l_market_us CONSTANT market.id_market%TYPE := 2;
    
    BEGIN
    
        l_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        g_error := 'GET PROFILE_TEMPLATE';
        OPEN c_profile_template;
        FETCH c_profile_template
            INTO l_profile_template, l_prof_type;
        CLOSE c_profile_template;
    
        IF i_prof.software = g_soft_pp
           AND l_market = l_market_us
           AND l_prof_type = pk_alert_constant.g_cat_type_doc
        THEN
        
            g_error := 'GET O_LIST';
            OPEN o_list FOR
                SELECT sd.val id_action,
                       NULL id_parent,
                       sd.desc_val desc_action,
                       NULL icon,
                       decode(sd.val,
                              -- "Submitted for co-sign" so deve ser mostrado para o Physician Assistant
                              'S',
                              decode(l_profile_template, g_profile_pa, 'A', 'I'),
                              -- "Waiting for co-sign" so deve ser mostrado para o Medical Doctor
                              'W',
                              decode(l_profile_template, g_profile_md, 'A', 'I'),
                              -- As restantes opcoes sao exibidas para ambos os perfis
                              'A') flg_action
                  FROM sys_domain sd
                 WHERE sd.code_domain = 'TODO_LIST_VIEW'
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND sd.id_language = i_lang
                   AND sd.flg_available = 'Y'
                -- O botao de Views so deve ser exibido nestes dois perfis
                -- Isto deve ser garantido na PROFILE_TEMPL_ACCESS
                --AND l_profile_template IN (g_profile_pa, g_profile_md)
                 ORDER BY rank;
        
        ELSE
            pk_types.open_my_cursor(o_list);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_TODO_LIST_VIEWS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_todo_list_views;

    /******************************************************************************
    * Returns date of submission for co-sign.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param i_episode         Episode ID
    *
    * @return                  Date of submission for co-sign
    *
    * @author                  Jose Brito
    * @version                 0.1
    * @since                   2008-Nov-06
    *
    ******************************************************************************/
    FUNCTION get_submit_cosign_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_submit_cosign_date VARCHAR2(30);
    
    BEGIN
    
        SELECT pk_date_utils.date_send_tsz(i_lang, eso.dt_event, i_prof)
          INTO l_submit_cosign_date
          FROM epis_sign_off eso,
               (SELECT id_episode, MAX(dt_event) dt_event
                  FROM epis_sign_off
                 GROUP BY id_episode) state
         WHERE eso.id_episode = i_episode
           AND eso.id_episode = state.id_episode
           AND eso.dt_event = state.dt_event
           AND eso.flg_state = 'SC'
           AND eso.id_professional_dest = i_prof.id
           AND eso.flg_real <> 'N';
    
        RETURN l_submit_cosign_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_submit_cosign_date;

    /******************************************************************************
    * Copy the task for a given profile for a specific institution
    *
    * @param i_inst_origin      Id institution (origin default 0)
    * @param i_inst_dest        ID institution to configure
    * @param i_profile_template  Id profile to copy
    *
    *
    * @author                  Elisabete Bugalho
    * @version                 0.1
    * @since                   2013-Fev-21
    *
    ******************************************************************************/
    PROCEDURE set_prof_todo_task
    (
        i_inst_origin      IN institution.id_institution%TYPE DEFAULT 0,
        i_inst_dest        IN institution.id_institution%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) IS
    
        t_error t_error_out;
        l_count NUMBER;
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM todo_task
         WHERE id_profile_template = i_profile_template
           AND id_institution = i_inst_dest;
    
        IF l_count = 0
        THEN
            INSERT INTO todo_task
                (flg_task, id_profile_template, flg_type, id_sys_shortcut, icon, flg_icon_type, id_institution)
                SELECT tt.flg_task,
                       tt.id_profile_template,
                       tt.flg_type,
                       tt.id_sys_shortcut,
                       tt.icon,
                       tt.flg_icon_type,
                       i_inst_dest
                  FROM todo_task tt
                 WHERE tt.id_profile_template = i_profile_template
                   AND tt.id_institution = i_inst_origin;
            dbms_output.put_line('Rows :' || SQL%ROWCOUNT);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('no rows inserted' || SQLERRM);
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_PROF_TODO_TASK',
                                              t_error);
            pk_alert_exceptions.reset_error_state;
    END set_prof_todo_task;

    /******************************************************************************
    * Returnsthe configuration variables
    *
    * @param i_prof            Professional executing the action
    * @param i_profile         Id Profile
    *
    * @return                  The id institution
    *
    * @author                  Elisabete Bugalho
    * @version                 0.1
    * @since                   2013-Fev-21
    *
    ******************************************************************************/
    FUNCTION get_config_vars
    (
        i_prof    IN profissional,
        i_profile IN profile_template.id_profile_template%TYPE
    ) RETURN NUMBER IS
    
        l_institution institution.id_institution%TYPE;
    
    BEGIN
    
        SELECT id_institution
          INTO l_institution
          FROM (SELECT tt.id_institution,
                       
                       row_number() over(ORDER BY --
                       decode(tt.id_institution, i_prof.institution, 1, 2)) line_number
                  FROM todo_task tt
                 WHERE tt.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                   AND tt.id_profile_template = i_profile)
         WHERE line_number = 1;
    
        RETURN l_institution;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_config_vars;

    /******************************************************************************
    * Returns pending and depending tasks to show on To-Do List.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_pending         All pending tasks ("my pending tasks")
    * @param o_error           Error message
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Sergio Dias
    * @version                 2.6.4.2.2
    * @since                   27-10-2014
    *
    ******************************************************************************/
    FUNCTION get_todo_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_pending OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pending t_todo_list_tbl;
    
    BEGIN
    
        IF NOT get_todo_list(i_lang => i_lang, i_prof => i_prof, o_pending => l_pending, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        OPEN o_pending FOR
            SELECT *
              FROM TABLE(l_pending);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_TODO_LIST',
                                              o_error);
            RETURN FALSE;
    END get_todo_list;

    /******************************************************************************
    * Returns tasks of a certain type (pending or depending) to show on To-Do List
    * for the current professional.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Current professional
    * @param i_prof_cat        Professional category
    * @param i_flg_type        Type of tasks: (P) pending or (D) depending
    * @param i_flg_show_ai     (Y) Show active and inactive episodes (N) Show only active and pending episodes
    * @param i_hand_off_type   Type of hand-off (N) Normal (M) Multiple
    * @param o_tasks           All tasks of type 'i_flg_type'
    * @param o_error           Error message
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Sergio Dias
    * @version                 2.6.4.2.2
    * @since                   27-10-2014
    *
    ******************************************************************************/
    FUNCTION get_prof_tasks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat      IN category.flg_type%TYPE,
        i_flg_type      IN todo_task.flg_type%TYPE,
        i_flg_show_ai   IN VARCHAR2,
        i_hand_off_type IN sys_config.value%TYPE,
        o_tasks         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tasks t_todo_list_tbl;
        l_count NUMBER;
    
    BEGIN
    
        IF NOT get_prof_tasks(i_lang          => i_lang,
                              i_prof          => i_prof,
                              i_prof_cat      => i_prof_cat,
                              i_mode          => k_todo_list_mode_data,
                              i_flg_type      => i_flg_type,
                              i_flg_show_ai   => i_flg_show_ai,
                              i_hand_off_type => i_hand_off_type,
                              o_tasks         => l_tasks,
                              o_count         => l_count,
                              o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        OPEN o_tasks FOR
            SELECT *
              FROM TABLE(l_tasks);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PROF_TASKS',
                                              o_error);
            RETURN FALSE;
    END get_prof_tasks;

    /******************************************************************************
    * Returns the to-do list task count
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional info
    * @param o_count           Task count
    * @param o_error           Error information
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Sergio Dias
    * @version                 2.6.4.2.2
    * @since                   27-10-2014
    *
    ******************************************************************************/

    FUNCTION get_todo_list_count
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_count OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_pending t_todo_list_tbl;
        l_bool    BOOLEAN := TRUE;
    
        l_todo_list_process_count VARCHAR2(0050 CHAR) := 'N';
    
    BEGIN
    
        l_todo_list_process_count := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_PROCESS_COUNT', i_prof => i_prof);
    
        IF l_todo_list_process_count = 'Y'
        THEN
            l_bool := get_todo_list_base(i_lang  => i_lang,
                                         i_prof  => i_prof,
                                         i_mode  => k_todo_list_mode_count,
                                         o_rows  => o_pending,
                                         o_count => o_count,
                                         o_error => o_error);
        END IF;
    
        RETURN l_bool;
    
    END get_todo_list_count;

    FUNCTION get_prof_tasks_count
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat      IN category.flg_type%TYPE,
        i_flg_type      IN todo_task.flg_type%TYPE,
        i_flg_show_ai   IN VARCHAR2,
        i_hand_off_type IN sys_config.value%TYPE,
        o_count         OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_id         VARCHAR2(1);
        l_flg_inactdisch BOOLEAN := FALSE;
        l_prof_templ     todo_task.id_profile_template%TYPE;
        err_exception    EXCEPTION;
    
        l_config_ti_cats sys_config.value%TYPE;
        l_sysdate_tstz   TIMESTAMP WITH TIME ZONE;
        l_flg_task_ds    todo_task.flg_task%TYPE := 'DS';
        l_prof_cat       category.flg_type%TYPE;
        l_handoff_type   sys_config.value%TYPE;
        l_type_opinion   opinion_type.id_opinion_type%TYPE;
        l_category       category.id_category%TYPE;
        l_institution    institution.id_institution%TYPE;
        l_signoff_type   sys_config.value%TYPE;
    
        l_note_name VARCHAR2(1 CHAR);
    
        CURSOR c_type_request IS
            SELECT ot.id_opinion_type
              FROM opinion_type ot
             WHERE ot.id_category = l_category;
    
    BEGIN
    
        l_sysdate_tstz := current_timestamp;
    
        l_prof_templ := pk_tools.get_prof_profile_template(i_prof => i_prof);
        l_prof_cat   := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        /* Seleccionar tipo de filtro de episodios conforme o perfil e o produto
        * P - Proprios pacientes;
        * S - Pacientes nas salas do profissional;
        * C - Pacientes do tipo de consulta a que o profissional esta associado;
        * H - Pacientes para hoje (nao esta a ser usado);
        * T - Todos os pacientes. Sem filtro.
        */
        l_flg_id := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_' || i_prof_cat, i_prof => i_prof);
    
        IF l_flg_id IS NULL
        THEN
            l_flg_id := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_ALL', i_prof => i_prof);
        END IF;
    
        --define the professional categories that receives the tranfer institution tasks
        --it is used the id_category because of the midwife profiles that has a specific category with the nurse flg_category
        g_error          := 'GET_CONFIG';
        l_config_ti_cats := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_CAT_TRANSF_INST', i_prof => i_prof);
        l_signoff_type   := pk_sysconfig.get_config(i_code_cf => 'NOTE_SIGNATURE_MECHANISM', i_prof => i_prof);
    
        l_note_name := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_NOTE_NAME', i_prof => i_prof);
        -- Define os casos em que a alta medica inactiva os episodios para que o administrativo possa ver tarefas associadas a esses episodios
        -- (nomeadamente necessidade de dar alta administrativa)
        -- Para ja e so o caso do CARE mas podem ser definidos outros casos
        l_flg_inactdisch := CASE i_prof.software
                                WHEN g_soft_care THEN
                                 TRUE
                            END;
    
        /* Seleccionar o tipo de descricao a surgir por baixo do nome do paciente
        * C - Queixa principal;
        * R - Registo clinico;
        * S - Cirurgia proposta;
        * D - Diagnostico;
        * O - Outros.
        */
    
        g_error    := 'GET PROF CATEGORY';
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'OPEN C_TYPE_REQUEST';
        OPEN c_type_request;
        FETCH c_type_request
            INTO l_type_opinion;
        CLOSE c_type_request;
    
        l_institution := get_config_vars(i_prof => i_prof, i_profile => l_prof_templ);
        IF i_flg_show_ai = g_no
           OR (i_prof_cat = g_prof_cat_a AND NOT l_flg_inactdisch)
        THEN
            -- Para administrativos so interessam episodios activos e pendentes
            -- Menos no caso do Care onde a alta medica inactiva o episodio
        
            g_error := 'GET CURSOR O_TASKS 1';
            SELECT /*+ use_nl(p t) */
             COUNT(1)
              INTO o_count
              FROM (SELECT epis.id_patient,
                            epis.id_episode,
                            NULL id_external_request,
                            epis.dt_begin_tstz_e,
                            tt.flg_type,
                            tt.flg_task,
                            tt.icon,
                            tt.flg_icon_type,
                            decode(tt.flg_task,
                                   g_task_a,
                                   decode(awv.flg_analysis_req,
                                          'Y',
                                          pk_todo_list.get_epis_task_count(i_lang,
                                                                           i_prof,
                                                                           i_prof_cat,
                                                                           g_task_a,
                                                                           epis.id_episode,
                                                                           epis.id_patient,
                                                                           epis.id_visit,
                                                                           i_flg_type),
                                          0),
                                   g_task_h,
                                   decode(awv.flg_analysis_req,
                                          'Y',
                                          pk_todo_list.get_epis_task_count(i_lang,
                                                                           i_prof,
                                                                           i_prof_cat,
                                                                           g_task_h,
                                                                           epis.id_episode,
                                                                           epis.id_patient,
                                                                           epis.id_visit,
                                                                           i_flg_type),
                                          0),
                                   g_task_e,
                                   decode(awv.flg_exam_req,
                                          'Y',
                                          pk_todo_list.get_epis_task_count(i_lang,
                                                                           i_prof,
                                                                           i_prof_cat,
                                                                           g_task_e,
                                                                           epis.id_episode,
                                                                           epis.id_patient,
                                                                           epis.id_visit,
                                                                           i_flg_type),
                                          0),
                                   g_task_ie,
                                   decode(awv.flg_exam_req,
                                          'Y',
                                          pk_todo_list.get_epis_task_count(i_lang,
                                                                           i_prof,
                                                                           i_prof_cat,
                                                                           g_task_ie,
                                                                           epis.id_episode,
                                                                           epis.id_patient,
                                                                           epis.id_visit,
                                                                           i_flg_type),
                                          0),
                                   g_task_m,
                                   decode(awv.flg_monitorization,
                                          'Y',
                                          pk_todo_list.get_epis_task_count(i_lang,
                                                                           i_prof,
                                                                           i_prof_cat,
                                                                           g_task_m,
                                                                           epis.id_episode,
                                                                           epis.id_patient,
                                                                           epis.id_visit,
                                                                           i_flg_type),
                                          0),
                                   g_task_dp,
                                   CASE i_flg_type
                                       WHEN g_pending THEN
                                        decode(awv.flg_presc_med,
                                               'Y',
                                               pk_todo_list.get_epis_task_count(i_lang,
                                                                                i_prof,
                                                                                i_prof_cat,
                                                                                g_task_dp,
                                                                                epis.id_episode,
                                                                                epis.id_patient,
                                                                                epis.id_visit,
                                                                                g_pending),
                                               0)
                                       WHEN g_depending THEN
                                        decode(awv.flg_drug_req,
                                               'Y',
                                               pk_todo_list.get_epis_task_count(i_lang,
                                                                                i_prof,
                                                                                i_prof_cat,
                                                                                g_task_dp,
                                                                                epis.id_episode,
                                                                                epis.id_patient,
                                                                                epis.id_visit,
                                                                                g_depending),
                                               0)
                                   END,
                                   g_task_pr,
                                   decode(awe.flg_interv_prescription,
                                          'Y',
                                          pk_todo_list.get_epis_task_count(i_lang,
                                                                           i_prof,
                                                                           i_prof_cat,
                                                                           g_task_pr,
                                                                           epis.id_episode,
                                                                           epis.id_patient,
                                                                           epis.id_visit,
                                                                           i_flg_type),
                                          0),
                                   
                                   g_task_b,
                                   decode(awe.flg_nurse_activity_req,
                                          'Y',
                                          pk_todo_list.get_epis_task_count(i_lang,
                                                                           i_prof,
                                                                           i_prof_cat,
                                                                           g_task_b,
                                                                           epis.id_episode,
                                                                           epis.id_patient,
                                                                           epis.id_visit,
                                                                           i_flg_type),
                                          0),
                                   g_task_mt,
                                   decode(awv.flg_drug_req,
                                          'Y',
                                          pk_todo_list.get_epis_task_count(i_lang,
                                                                           i_prof,
                                                                           i_prof_cat,
                                                                           g_task_mt,
                                                                           epis.id_episode,
                                                                           epis.id_patient,
                                                                           epis.id_visit,
                                                                           i_flg_type),
                                          0),
                                   g_task_ht,
                                   decode(awv.flg_analysis_req,
                                          'Y',
                                          pk_todo_list.get_epis_task_count(i_lang,
                                                                           i_prof,
                                                                           i_prof_cat,
                                                                           g_task_ht,
                                                                           epis.id_episode,
                                                                           epis.id_patient,
                                                                           epis.id_visit,
                                                                           i_flg_type),
                                          0),
                                   pk_todo_list.get_epis_task_count(i_lang,
                                                                    i_prof,
                                                                    i_prof_cat,
                                                                    tt.flg_task,
                                                                    epis.id_episode,
                                                                    epis.id_patient,
                                                                    epis.id_visit,
                                                                    i_flg_type,
                                                                    epis.flg_status_e)) task_count,
                            NULL task,
                            tt.id_sys_shortcut,
                            epis.flg_status_e,
                            epis.id_schedule
                       FROM todo_task tt,
                            (SELECT /*+ use_nl(a e) */
                              a.id_patient,
                              a.id_episode,
                              a.flg_episode,
                              a.flg_pat_allergy,
                              a.flg_pat_habit,
                              a.flg_pat_history_diagnosis,
                              a.flg_vital_sign_read,
                              a.flg_epis_diagnosis,
                              a.flg_interv_prescription,
                              a.flg_nurse_activity_req,
                              a.flg_icnp_epis_diagnosis,
                              a.flg_icnp_epis_intervention,
                              a.flg_pat_pregnancy,
                              a.flg_sys_alert_det,
                              a.flg_presc_med
                               FROM awareness a
                               JOIN episode e
                                 ON a.id_episode = e.id_episode
                              WHERE e.flg_status IN
                                    (pk_alert_constant.g_epis_status_active, pk_alert_constant.g_epis_status_pendent)) awe,
                            (SELECT /*+ use_nl(a e) */
                              a.id_patient,
                              a.id_visit,
                              MAX(flg_analysis_req) flg_analysis_req,
                              MAX(flg_exam_req) flg_exam_req,
                              MAX(flg_monitorization) flg_monitorization,
                              MAX(flg_prescription) flg_prescription,
                              MAX(flg_drug_req) flg_drug_req,
                              MAX(flg_presc_med) flg_presc_med
                               FROM awareness a
                               JOIN episode e
                                 ON a.id_episode = e.id_episode
                              WHERE e.flg_status IN
                                    (pk_alert_constant.g_epis_status_active, pk_alert_constant.g_epis_status_pendent)
                              GROUP BY a.id_visit, a.id_patient) awv,
                            (SELECT e.id_patient,
                                    e.id_episode,
                                    NULL                  id_external_request,
                                    e.id_software,
                                    e.id_visit,
                                    e.id_institution,
                                    e.id_professional,
                                    e.id_first_nurse_resp,
                                    e.dt_begin_tstz_e,
                                    e.flg_status_e,
                                    e.id_epis_type,
                                    e.id_schedule,
                                    NULL                  text
                             -- Usar a view de episodios activos e pendentes
                               FROM v_episode_act_pend e
                              WHERE e.id_institution = i_prof.institution
                                AND e.dt_begin_tstz_e >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                                AND ((l_flg_id = 'C' AND EXISTS
                                     (SELECT 0
                                         FROM prof_dep_clin_serv pdcs, schedule s
                                        WHERE pdcs.id_dep_clin_serv = nvl(e.id_dep_clin_serv, s.id_dcs_requested)
                                          AND s.id_schedule(+) = e.id_schedule
                                          AND pdcs.id_professional = i_prof.id
                                          AND pdcs.flg_status = 'S')) OR l_flg_id != 'C')
                                AND ((l_flg_id = 'S' AND EXISTS (SELECT 0
                                                                   FROM prof_room pr
                                                                  WHERE pr.id_professional = i_prof.id
                                                                    AND e.id_room = pr.id_room)) OR l_flg_id != 'S')
                                AND e.id_software = i_prof.software
                                AND e.id_institution = i_prof.institution
                                AND (SELECT pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
                                       FROM dual) = e.id_software
                                AND e.flg_ehr = g_flg_ehr_n
                             
                             -- Jose Brito 10/11/2008 ALERT-8047 Mostrar na to-do list as transferencias inter-hospitalares
                             -- cuja instituicao de destino seja a do profissional actual. Este caso so se aplica a episodios
                             -- activos do EDIS, pelo que nao e necessario repetir este codigo na query que mostra tarefas
                             -- de episodios inactivos (usada em Outpatient, p.ex.).
                             UNION ALL
                             SELECT e.id_patient,
                                    e.id_episode,
                                    NULL id_external_request,
                                    e.id_software,
                                    e.id_visit,
                                    -- Devolver o ID da instituicao do profissional, para evitar alterar os joins da query principal,
                                    -- trazendo vantagens ao nivel da performance. Nao e necessario devolver o ID da instituicao do episodio.
                                    i_prof.institution    id_institution,
                                    e.id_professional,
                                    e.id_first_nurse_resp,
                                    e.dt_begin_tstz_e,
                                    e.flg_status_e,
                                    e.id_epis_type,
                                    e.id_schedule,
                                    NULL                  text
                               FROM v_episode_act_pend e, transfer_institution ti
                              WHERE e.id_episode = ti.id_episode
                                AND ti.id_institution_dest = i_prof.institution
                                AND ti.flg_status = 'T'
                                AND e.dt_begin_tstz_e >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                                   --it is used a sys_config in order to be possible to configure different categories
                                   --for diferent softwares
                                AND instr(l_config_ti_cats, '|' || to_char(l_category) || '|') != 0
                                AND (SELECT pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
                                       FROM dual) = e.id_software) epis
                      WHERE tt.flg_type = i_flg_type
                        AND awe.id_patient = epis.id_patient
                        AND awe.id_episode = epis.id_episode
                        AND awv.id_patient = epis.id_patient
                        AND awv.id_visit = epis.id_visit
                        AND tt.id_profile_template = l_prof_templ
                        AND tt.id_institution = l_institution
                     -- PENDING ISSUES - ACTIVE EPISODES
                     -- All episodes with pending issues assigned to the current professional
                     UNION ALL
                     SELECT e.id_patient,
                            e.id_episode,
                            NULL id_external_request,
                            e.dt_begin_tstz_e,
                            tt.flg_type,
                            tt.flg_task,
                            tt.icon,
                            tt.flg_icon_type,
                            -- Count number of pending issues assigned to I_PROF
                            (SELECT COUNT(*)
                               FROM pending_issue pi
                              WHERE EXISTS (SELECT pip.id_pending_issue
                                       FROM pending_issue_prof pip
                                      WHERE pip.id_professional = i_prof.id
                                        AND pip.id_pending_issue = pi.id_pending_issue)
                                AND pi.id_patient = e.id_patient
                                AND pi.flg_status NOT IN ('C', 'X')) task_count,
                            NULL task,
                            --
                            tt.id_sys_shortcut,
                            e.flg_status_e,
                            e.id_schedule
                       FROM (SELECT ee.*
                               FROM v_episode_act_pend ee
                              WHERE EXISTS (SELECT 1
                                       FROM pending_issue pi
                                      WHERE pi.id_patient = ee.id_patient)
                                AND ee.id_institution = i_prof.institution
                                AND ee.dt_begin_tstz_e >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                                AND ee.id_software = i_prof.software
                                AND ee.flg_status_e <> 'C') e,
                            todo_task tt
                      WHERE tt.id_profile_template = l_prof_templ
                        AND tt.id_institution = l_institution
                        AND tt.flg_type = i_flg_type
                        AND tt.flg_task = 'I' -- IMPORTANT: PENDING ISSUES ONLY!!
                     -- follow-up requests pending approval
                     UNION ALL
                     SELECT fur.id_patient,
                            fur.id_episode,
                            NULL               id_external_request,
                            fur.dt_begin_tstz  dt_begin_tstz_e,
                            tt.flg_type,
                            tt.flg_task,
                            tt.icon,
                            tt.flg_icon_type,
                            1                  task_count,
                            NULL               task,
                            tt.id_sys_shortcut,
                            fur.flg_status     flg_status_e,
                            fur.id_schedule
                       FROM todo_task tt,
                            (SELECT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                               FROM opinion o
                               JOIN episode e
                                 ON o.id_episode_approval = e.id_episode
                               JOIN epis_info ei
                                 ON e.id_episode = ei.id_episode
                              WHERE o.flg_state = pk_opinion.g_opinion_req
                                AND o.id_opinion_type IS NOT NULL
                                AND o.id_episode_approval IS NOT NULL
                                AND e.id_institution = i_prof.institution
                                AND e.id_epis_type IN
                                    (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient)
                                AND e.flg_status = pk_alert_constant.g_epis_status_active
                                AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                                AND pk_patient.get_prof_resp(i_lang, i_prof, e.id_patient, e.id_episode) = pk_adt.g_true
                                AND ei.id_software = i_prof.software) fur
                      WHERE tt.flg_task = g_task_fu
                        AND tt.flg_type = i_flg_type
                        AND tt.flg_type = g_pending
                        AND tt.id_profile_template = l_prof_templ
                        AND tt.id_institution = l_institution
                     
                     -- FU Requested
                     UNION ALL
                     SELECT fur.id_patient,
                            fur.id_episode,
                            NULL id_external_request,
                            fur.dt_begin_tstz dt_begin_tstz_e,
                            tt.flg_type,
                            tt.flg_task,
                            tt.icon,
                            tt.flg_icon_type,
                            (SELECT COUNT(1)
                               FROM opinion o
                              WHERE o.id_episode = fur.id_episode
                                AND o.id_opinion_type IS NOT NULL
                                AND (o.flg_state = pk_opinion.g_opinion_approved OR
                                    (o.flg_state = pk_opinion.g_opinion_req AND o.id_episode_approval IS NULL))
                                AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending AND
                                    o.id_opinion_type = l_type_opinion) OR
                                    (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) task_count,
                            NULL task,
                            tt.id_sys_shortcut,
                            fur.flg_status flg_status_e,
                            fur.id_schedule
                       FROM todo_task tt,
                            (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                               FROM opinion o
                               JOIN episode e
                                 ON o.id_episode = e.id_episode
                               JOIN epis_info ei
                                 ON e.id_episode = ei.id_episode
                              WHERE o.id_opinion_type IS NOT NULL
                                AND e.id_institution = i_prof.institution
                                AND e.flg_status = pk_alert_constant.g_epis_status_active
                                AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                                AND (o.flg_state = pk_opinion.g_opinion_approved OR
                                    (o.flg_state = pk_opinion.g_opinion_req AND o.id_episode_approval IS NULL))
                                AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending AND
                                    o.id_opinion_type = l_type_opinion) OR
                                    (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending AND
                                    ei.id_software = i_prof.software))) fur
                      WHERE tt.flg_task = g_task_fu
                        AND tt.flg_type = i_flg_type
                        AND tt.id_profile_template = l_prof_templ
                        AND tt.id_institution = l_institution
                     UNION ALL
                     --progress notes and history and physical
                     SELECT pn_notes.id_patient,
                            pn_notes.id_episode,
                            NULL                     id_external_request,
                            pn_notes.dt_begin_tstz   dt_begin_tstz_e,
                            pn_notes.flg_type,
                            pn_notes.flg_task,
                            pn_notes.icon,
                            pn_notes.flg_icon_type,
                            1                        task_count,
                            NULL                     task,
                            pn_notes.id_sys_shortcut,
                            pn_notes.flg_status      flg_status_e,
                            pn_notes.id_schedule
                       FROM (SELECT DISTINCT /*+opt_estimate (table nt rows=1)*/ tt.id_sys_shortcut,
                                             tt.flg_type,
                                             tt.icon,
                                             tt.flg_icon_type,
                                             e.id_patient,
                                             e.id_episode,
                                             e.dt_begin_tstz,
                                             e.flg_status,
                                             ei.id_schedule,
                                             nt.flg_task,
                                             /*                                     decode(nt.flg_task,
                                             'DS',
                                             nvl(pk_discharge.get_discharge_date(i_lang       => i_lang,
                                                                                 i_prof       => i_prof,
                                                                                 i_id_episode => epn.id_episode),
                                                 epn.dt_pn_date) +
                                             numtodsinterval(nvl(nt.time_to_start_docum, 0), 'minute'),
                                             pk_prog_notes_utils.get_end_task_time(i_lang    => i_lang,
                                                                                   i_prof    => i_prof,
                                                                                   i_episode => epn.id_episode,
                                                                                   i_epis_pn => epn.id_epis_pn)) task_end_date,
                                             */
                                             NULL task_end_date,
                                             NULL note_name,
                                             NULL prof_name
                               FROM epis_pn epn
                               JOIN episode e
                                 ON e.id_episode = epn.id_episode
                               JOIN epis_info ei
                                 ON e.id_episode = ei.id_episode
                               JOIN TABLE((SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                                i_prof,
                                                                                epn.id_episode,
                                                                                NULL,
                                                                                NULL,
                                                                                epn.id_dep_clin_serv,
                                                                                NULL,
                                                                                NULL)
                                            FROM dual)) nt
                                 ON nt.id_pn_area = epn.id_pn_area
                               JOIN todo_task tt
                                 ON tt.flg_task = nt.flg_task
                              WHERE tt.flg_type = i_flg_type
                                AND tt.id_profile_template = l_prof_templ
                                AND tt.id_institution = l_institution
                                AND ((epn.flg_status IN
                                    (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                       pk_prog_notes_constants.g_epis_pn_flg_status_t) AND
                                    e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE) AND
                                    epn.id_prof_create = i_prof.id AND l_signoff_type = g_signature_signoff) OR
                                    (epn.flg_status = pk_prog_notes_constants.g_epis_pn_flg_for_review AND
                                    ei.id_professional = i_prof.id AND l_signoff_type = g_signature_submit))
                                AND ((l_signoff_type = g_signature_signoff AND epn.id_prof_create = i_prof.id) OR
                                    (l_signoff_type = g_signature_submit AND ei.id_professional = i_prof.id))
                                AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                                AND e.id_institution = i_prof.institution
                                AND ei.id_software = i_prof.software) pn_notes
                     --begin copy          
                     --admission note is over time-to-close and has not submitted to VS and it's multi-hand off
                    UNION ALL
                    SELECT pn_notes.id_patient,
                           pn_notes.id_episode,
                           NULL                     id_external_request,
                           pn_notes.dt_begin_tstz   dt_begin_tstz_e,
                           pn_notes.flg_type,
                           pn_notes.flg_task,
                           pn_notes.icon,
                           pn_notes.flg_icon_type,
                           1                        task_count,
                           NULL                     task,
                           pn_notes.id_sys_shortcut,
                           pn_notes.flg_status      flg_status_e,
                           pn_notes.id_schedule
                      FROM (SELECT t2.id_sys_shortcut,
                                   t2.flg_type,
                                   NULL icon,
                                   t2.flg_icon_type,
                                   t2.id_patient,
                                   t2.id_episode,
                                   t2.dt_begin_tstz,
                                   t2.flg_status,
                                   t2.id_schedule,
                                   t2.flg_task
                              FROM (SELECT tt.id_sys_shortcut,
                                           tt.flg_type,
                                           NULL icon,
                                           tt.flg_icon_type,
                                           e.id_patient,
                                           e.id_episode,
                                           e.dt_begin_tstz,
                                           e.flg_status,
                                           ei.id_schedule,
                                           tt.flg_task,
                                           e.dt_creation,
                                           
                                           /*        nvl(e.dt_begin_tstz, l_sysdate_tstz) +
                                           pk_prog_notes_utils.gen_time_to_close(i_lang,
                                                                                 i_prof,
                                                                                 e.id_episode,
                                                                                 pk_prog_notes_constants.g_note_type_id_handp_2) task_end_date,
                                           */
                                           NULL task_end_date,
                                           NULL note_name,
                                           NULL prof_name
                                      FROM episode e
                                      LEFT OUTER JOIN (SELECT ep.*
                                                        FROM epis_pn ep
                                                       INNER JOIN episode epis
                                                          ON ep.id_episode = epis.id_episode
                                                       WHERE ep.id_pn_note_type =
                                                             pk_prog_notes_constants.g_note_type_id_handp_2
                                                         AND ep.flg_status <> pk_alert_constant.g_cancelled
                                                         AND epis.id_institution = i_prof.institution
                                                         AND epis.flg_status <> pk_alert_constant.g_cancelled) epn
                                        ON e.id_episode = epn.id_episode
                                      JOIN epis_info ei
                                        ON e.id_episode = ei.id_episode
                                     CROSS JOIN TABLE (SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                                            i_prof,
                                                                                            epn.id_episode,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            pk_prog_notes_constants.g_area_hp,
                                                                                            NULL)
                                                        FROM dual) nt
                                      JOIN todo_task tt
                                        ON tt.flg_task = nt.flg_task
                                     WHERE tt.flg_type = i_flg_type
                                       AND tt.id_profile_template = l_prof_templ
                                       AND tt.id_institution = l_institution
                                       AND (epn.id_episode IS NULL OR
                                           (epn.flg_status IN
                                           (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                              pk_prog_notes_constants.g_epis_pn_flg_status_t)))
                                       AND l_note_name = pk_alert_constant.g_yes
                                       AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                                       AND e.id_institution = i_prof.institution
                                       AND ei.id_software = i_prof.software
                                       AND ei.id_professional = i_prof.id
                                       AND pk_utils.search_table_number((SELECT pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                                   i_prof,
                                                                                                                   e.id_episode,
                                                                                                                   l_prof_cat,
                                                                                                                   l_handoff_type)
                                                                          FROM dual),
                                                                        i_prof.id) != -1
                                       AND rownum > 0) t2
                             WHERE (l_sysdate_tstz - t2.dt_creation >
                                   pk_prog_notes_utils.gen_time_to_close(i_lang,
                                                                          i_prof,
                                                                          t2.id_episode,
                                                                          pk_prog_notes_constants.g_note_type_id_handp_2))
                            
                            ) pn_notes
                    
                    --END copy         
                    UNION ALL
                    --ASantos 21-11-20011
                    --ALERT-195554 - Chile | Ability to interface information regarding management of GES
                    SELECT sae.id_patient,
                           sae.id_episode,
                           NULL id_external_request,
                           sae.dt_record dt_begin_tstz_e,
                           tt.flg_type,
                           tt.flg_task,
                           tt.icon,
                           tt.flg_icon_type,
                           to_number(sae.replace1) task_count,
                           NULL task,
                           tt.id_sys_shortcut,
                           NULL flg_status_e,
                           NULL id_schedule
                      FROM sys_alert_event sae
                      JOIN todo_task tt
                        ON tt.flg_task = pk_epis_er_law_core.g_ges_todo_task
                       AND tt.flg_type = i_flg_type
                       AND tt.id_profile_template = l_prof_templ
                     WHERE sae.id_sys_alert = pk_epis_er_law_core.g_ges_sys_alert
                       AND sae.id_software = i_prof.software
                       AND sae.id_institution = i_prof.institution
                       AND sae.flg_visible = pk_alert_constant.g_yes
                       AND tt.id_institution = l_institution
                    UNION ALL
                    ------------------------------------
                    -- discharge summary
                    ------------------------------------
                    SELECT pn_notes.id_patient,
                           pn_notes.id_episode,
                           NULL                     id_external_request,
                           pn_notes.dt_begin_tstz   dt_begin_tstz_e,
                           pn_notes.flg_type,
                           pn_notes.flg_task,
                           pn_notes.icon,
                           pn_notes.flg_icon_type,
                           1                        task_count,
                           NULL                     task,
                           pn_notes.id_sys_shortcut,
                           pn_notes.flg_status      flg_status_e,
                           pn_notes.id_schedule
                      FROM (SELECT DISTINCT /* +opt_estimate (table nt rows=1)*/ tt.id_sys_shortcut,
                                            tt.flg_type,
                                            tt.icon,
                                            tt.flg_icon_type,
                                            e.id_patient,
                                            e.id_episode,
                                            e.dt_begin_tstz,
                                            e.flg_status,
                                            ei.id_schedule,
                                            nt.flg_task,
                                            NULL               prof_name,
                                            NULL               note_name,
                                            /*                               nvl(d.dt_pend_tstz,
                                                nvl(d.dt_med_tstz,
                                                    nvl(pk_discharge_core.get_dt_admin(i_lang,
                                                                                       i_prof,
                                                                                       NULL,
                                                                                       d.flg_status_adm,
                                                                                       d.dt_admin_tstz),
                                                        l_sysdate_tstz))) +
                                            numtodsinterval(nvl(nt.time_to_start_docum, 0), 'minute') task_end_date*/
                                            NULL task_end_date
                              FROM discharge d
                             CROSS JOIN TABLE((SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                                    i_prof,
                                                                                    d.id_episode,
                                                                                    NULL,
                                                                                    NULL,
                                                                                    NULL,
                                                                                    pk_prog_notes_constants.g_area_ds,
                                                                                    NULL)
                                                FROM dual)) nt
                              JOIN episode e
                                ON e.id_episode = d.id_episode
                              JOIN epis_info ei
                                ON e.id_episode = ei.id_episode
                              JOIN todo_task tt
                                ON tt.flg_task = nt.flg_task
                               AND tt.id_profile_template = l_prof_templ
                               AND tt.id_institution = l_institution
                               AND tt.flg_task = l_flg_task_ds
                             WHERE d.flg_status NOT IN
                                   (pk_discharge.g_disch_flg_status_reopen, pk_discharge.g_disch_flg_status_cancel)
                               AND tt.flg_type = i_flg_type
                               AND pk_utils.search_table_number((SELECT pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                           i_prof,
                                                                                                           ei.id_episode,
                                                                                                           l_prof_cat,
                                                                                                           l_handoff_type)
                                                                  FROM dual),
                                                                i_prof.id) != -1
                               AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                               AND (e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE) OR
                                   l_signoff_type = g_signature_submit) --copy
                               AND e.id_institution = i_prof.institution
                               AND ei.id_software = i_prof.software
                               AND ((NOT EXISTS (SELECT 1
                                                   FROM epis_pn epn
                                                  WHERE epn.id_episode = d.id_episode
                                                    AND epn.id_pn_area = nt.id_pn_area
                                                    AND epn.flg_status IN
                                                        (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                         pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                                         pk_prog_notes_constants.g_epis_pn_flg_status_s)) AND
                                    l_signoff_type = g_signature_signoff))) pn_notes
                    --begin copy
                    --discharge summary over time-to-close and has not submit to vs
                    UNION ALL
                    SELECT pn_notes.id_patient,
                           pn_notes.id_episode,
                           NULL                     id_external_request,
                           pn_notes.dt_begin_tstz   dt_begin_tstz_e,
                           pn_notes.flg_type,
                           pn_notes.flg_task,
                           pn_notes.icon,
                           pn_notes.flg_icon_type,
                           1                        task_count,
                           NULL                     task,
                           pn_notes.id_sys_shortcut,
                           pn_notes.flg_status      flg_status_e,
                           pn_notes.id_schedule
                      FROM (SELECT DISTINCT t1.id_sys_shortcut,
                                            t1.flg_type,
                                            NULL               icon,
                                            t1.flg_icon_type,
                                            t1.id_patient,
                                            t1.id_episode,
                                            t1.dt_begin_tstz,
                                            t1.flg_status,
                                            t1.id_schedule,
                                            t1.flg_task,
                                            t1.id_pn_note_type,
                                            NULL               prof_name,
                                            NULL               note_name,
                                            NULL               task_end_date
                            
                              FROM (SELECT tt.id_sys_shortcut,
                                           tt.flg_type,
                                           tt.flg_icon_type,
                                           e.id_patient,
                                           e.id_episode,
                                           e.dt_begin_tstz,
                                           e.flg_status,
                                           ei.id_schedule,
                                           nt.flg_task,
                                           ep.id_pn_note_type,
                                           ep.id_episode      ep_id_episode,
                                           ep.flg_status      ep_flg_status,
                                           d.dt_pend_tstz,
                                           d.dt_med_tstz,
                                           d.flg_status_adm,
                                           d.dt_admin_tstz
                                      FROM discharge d
                                     CROSS JOIN TABLE (SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                                            i_prof,
                                                                                            d.id_episode,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            pk_prog_notes_constants.g_area_ds,
                                                                                            NULL)
                                                        FROM dual) nt
                                      JOIN episode e
                                        ON e.id_episode = d.id_episode
                                      JOIN epis_info ei
                                        ON e.id_episode = ei.id_episode
                                      LEFT OUTER JOIN (SELECT epn.*
                                                        FROM epis_pn epn
                                                       INNER JOIN episode epis
                                                          ON epis.id_episode = epn.id_episode
                                                       WHERE epis.id_institution = i_prof.institution
                                                         AND epn.id_pn_note_type =
                                                             pk_prog_notes_constants.g_note_type_id_disch_sum_12
                                                         AND epn.flg_status <> pk_alert_constant.g_cancelled
                                                         AND epis.flg_status <> pk_alert_constant.g_cancelled) ep
                                        ON e.id_episode = ep.id_episode
                                      JOIN todo_task tt
                                        ON tt.flg_task = nt.flg_task
                                       AND tt.id_profile_template = l_prof_templ
                                       AND tt.flg_task = l_flg_task_ds
                                       AND tt.id_institution = l_institution
                                     WHERE d.flg_status NOT IN
                                           (pk_discharge.g_disch_flg_status_reopen, pk_discharge.g_disch_flg_status_cancel)
                                       AND tt.flg_type = i_flg_type
                                       AND pk_utils.search_table_number((SELECT pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                                   i_prof,
                                                                                                                   ei.id_episode,
                                                                                                                   l_prof_cat,
                                                                                                                   l_handoff_type)
                                                                          FROM dual),
                                                                        i_prof.id) != -1
                                       AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                                       AND e.id_institution = i_prof.institution
                                       AND ei.id_software = i_prof.software
                                       AND l_note_name = pk_alert_constant.g_yes
                                       AND ei.id_professional = i_prof.id
                                       AND rownum > 0) t1
                             WHERE (t1.ep_id_episode IS NULL OR --has not written discharge summary
                                   (t1.ep_flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_d AND --discharge summary is draft and over time-to-close
                                   (l_sysdate_tstz - (nvl(t1.dt_pend_tstz,
                                                            nvl(t1.dt_med_tstz,
                                                                nvl((SELECT pk_discharge_core.get_dt_admin(i_lang,
                                                                                                          i_prof,
                                                                                                          NULL,
                                                                                                          t1.flg_status_adm,
                                                                                                          t1.dt_admin_tstz)
                                                                      FROM dual),
                                                                    l_sysdate_tstz))))) >
                                   pk_prog_notes_utils.gen_time_to_close(i_lang,
                                                                           i_prof,
                                                                           t1.id_episode,
                                                                           pk_prog_notes_constants.g_note_type_id_disch_sum_12)))
                            
                            ) pn_notes
                    UNION ALL
                    SELECT cr.id_patient,
                           cr.id_episode,
                           NULL id_external_request,
                           cr.dt_begin_tstz dt_begin_tstz_e,
                           tt.flg_type,
                           tt.flg_task,
                           tt.icon,
                           tt.flg_icon_type,
                           (SELECT COUNT(1)
                              FROM opinion o
                             WHERE o.id_episode = cr.id_episode
                               AND o.flg_state = pk_opinion.g_opinion_req
                               AND o.id_opinion_type IS NULL
                               AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending) OR
                                   (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) task_count,
                           NULL task,
                           tt.id_sys_shortcut,
                           cr.flg_status flg_status_e,
                           cr.id_schedule
                      FROM todo_task tt,
                           (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                              FROM opinion o
                              JOIN episode e
                                ON o.id_episode = e.id_episode
                              JOIN epis_info ei
                                ON e.id_episode = ei.id_episode
                             WHERE o.flg_state = pk_opinion.g_opinion_req
                               AND o.id_opinion_type IS NULL
                               AND e.id_institution = i_prof.institution
                               AND e.flg_status = pk_alert_constant.g_epis_status_active
                               AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                               AND ei.id_software = i_prof.software
                               AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending) OR
                                   (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) cr
                     WHERE tt.flg_task = g_task_cr
                       AND tt.flg_type = i_flg_type
                       AND tt.id_profile_template = l_prof_templ
                       AND tt.id_institution = l_institution
                    
                    UNION ALL
                    -- HAND OFF
                    SELECT tr.id_patient,
                           tr.id_episode,
                           NULL id_external_request,
                           tr.dt_begin_tstz dt_begin_tstz_e,
                           tt.flg_type,
                           tt.flg_task,
                           tt.icon,
                           tt.flg_icon_type,
                           (SELECT COUNT(1)
                              FROM epis_prof_resp epr
                             WHERE epr.id_episode = tr.id_episode
                               AND epr.flg_status = pk_hand_off.g_hand_off_r
                               AND ((epr.id_prof_to = i_prof.id AND i_flg_type = g_pending) OR
                                   (epr.id_prof_req = i_prof.id AND i_flg_type = g_depending))) task_count,
                           NULL task,
                           tt.id_sys_shortcut,
                           tr.flg_status flg_status_e,
                           tr.id_schedule
                      FROM todo_task tt,
                           (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                              FROM epis_prof_resp epr
                              JOIN episode e
                                ON epr.id_episode = e.id_episode
                              JOIN epis_info ei
                                ON e.id_episode = ei.id_episode
                             WHERE epr.flg_status = pk_hand_off.g_hand_off_r
                               AND e.id_institution = i_prof.institution
                               AND e.flg_status = pk_alert_constant.g_epis_status_active
                               AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                               AND ei.id_software = i_prof.software
                               AND ((epr.id_prof_to = i_prof.id AND i_flg_type = g_pending) OR
                                   (epr.id_prof_req = i_prof.id AND i_flg_type = g_depending))) tr
                     WHERE tt.flg_task = g_task_tr
                       AND tt.flg_type = i_flg_type
                       AND tt.id_profile_template = l_prof_templ
                       AND tt.id_institution = l_institution
                    ------------------------------------
                    ) t,
                   patient p
            -- Obter apenas os episodios com tarefas pendentes
             WHERE p.id_patient = t.id_patient
               AND t.task_count > 0;
        
        ELSIF i_flg_show_ai = g_yes
              OR (i_prof_cat = g_prof_cat_a AND l_flg_inactdisch)
        THEN
            -- Mostrar episodios activos e inactivos
        
            g_error := 'GET CURSOR O_TASKS 2';
            SELECT /*+ use_nl(p t) */
             COUNT(1)
              INTO o_count
              FROM (SELECT epis.id_patient,
                           epis.id_episode,
                           NULL id_external_request,
                           epis.dt_begin_tstz,
                           tt.flg_type,
                           tt.flg_task,
                           tt.icon,
                           tt.flg_icon_type,
                           decode(tt.flg_task,
                                  g_task_a,
                                  decode(awv.flg_analysis_req,
                                         'Y',
                                         pk_todo_list.get_epis_task_count(i_lang,
                                                                          i_prof,
                                                                          i_prof_cat,
                                                                          g_task_a,
                                                                          epis.id_episode,
                                                                          epis.id_patient,
                                                                          epis.id_visit,
                                                                          i_flg_type),
                                         0),
                                  g_task_h,
                                  decode(awv.flg_analysis_req,
                                         'Y',
                                         pk_todo_list.get_epis_task_count(i_lang,
                                                                          i_prof,
                                                                          i_prof_cat,
                                                                          g_task_h,
                                                                          epis.id_episode,
                                                                          epis.id_patient,
                                                                          epis.id_visit,
                                                                          i_flg_type),
                                         0),
                                  g_task_e,
                                  decode(awv.flg_exam_req,
                                         'Y',
                                         pk_todo_list.get_epis_task_count(i_lang,
                                                                          i_prof,
                                                                          i_prof_cat,
                                                                          g_task_e,
                                                                          epis.id_episode,
                                                                          epis.id_patient,
                                                                          epis.id_visit,
                                                                          i_flg_type),
                                         0),
                                  g_task_ie,
                                  decode(awv.flg_exam_req,
                                         'Y',
                                         pk_todo_list.get_epis_task_count(i_lang,
                                                                          i_prof,
                                                                          i_prof_cat,
                                                                          g_task_ie,
                                                                          epis.id_episode,
                                                                          epis.id_patient,
                                                                          epis.id_visit,
                                                                          i_flg_type),
                                         0),
                                  g_task_m,
                                  decode(awv.flg_monitorization,
                                         'Y',
                                         pk_todo_list.get_epis_task_count(i_lang,
                                                                          i_prof,
                                                                          i_prof_cat,
                                                                          g_task_m,
                                                                          epis.id_episode,
                                                                          epis.id_patient,
                                                                          epis.id_visit,
                                                                          i_flg_type),
                                         0),
                                  g_task_dp,
                                  CASE i_flg_type
                                      WHEN g_pending THEN
                                       decode(awv.flg_presc_med,
                                              'Y',
                                              pk_todo_list.get_epis_task_count(i_lang,
                                                                               i_prof,
                                                                               i_prof_cat,
                                                                               g_task_dp,
                                                                               epis.id_episode,
                                                                               epis.id_patient,
                                                                               epis.id_visit,
                                                                               g_pending),
                                              0)
                                      WHEN g_depending THEN
                                       decode(awv.flg_drug_req,
                                              'Y',
                                              pk_todo_list.get_epis_task_count(i_lang,
                                                                               i_prof,
                                                                               i_prof_cat,
                                                                               g_task_dp,
                                                                               epis.id_episode,
                                                                               epis.id_patient,
                                                                               epis.id_visit,
                                                                               g_depending),
                                              0)
                                  END,
                                  g_task_pr,
                                  decode(awe.flg_interv_prescription,
                                         'Y',
                                         pk_todo_list.get_epis_task_count(i_lang,
                                                                          i_prof,
                                                                          i_prof_cat,
                                                                          g_task_pr,
                                                                          epis.id_episode,
                                                                          epis.id_patient,
                                                                          epis.id_visit,
                                                                          i_flg_type),
                                         0),
                                  
                                  g_task_b,
                                  decode(awe.flg_nurse_activity_req,
                                         'Y',
                                         pk_todo_list.get_epis_task_count(i_lang,
                                                                          i_prof,
                                                                          i_prof_cat,
                                                                          g_task_b,
                                                                          epis.id_episode,
                                                                          epis.id_patient,
                                                                          epis.id_visit,
                                                                          i_flg_type),
                                         0),
                                  g_task_mt,
                                  decode(awv.flg_drug_req,
                                         'Y',
                                         pk_todo_list.get_epis_task_count(i_lang,
                                                                          i_prof,
                                                                          i_prof_cat,
                                                                          g_task_mt,
                                                                          epis.id_episode,
                                                                          epis.id_patient,
                                                                          epis.id_visit,
                                                                          i_flg_type),
                                         0),
                                  g_task_ht,
                                  decode(awv.flg_analysis_req,
                                         'Y',
                                         pk_todo_list.get_epis_task_count(i_lang,
                                                                          i_prof,
                                                                          i_prof_cat,
                                                                          g_task_ht,
                                                                          epis.id_episode,
                                                                          epis.id_patient,
                                                                          epis.id_visit,
                                                                          i_flg_type),
                                         0),
                                  pk_todo_list.get_epis_task_count(i_lang,
                                                                   i_prof,
                                                                   i_prof_cat,
                                                                   tt.flg_task,
                                                                   epis.id_episode,
                                                                   epis.id_patient,
                                                                   epis.id_visit,
                                                                   i_flg_type,
                                                                   epis.flg_status)) task_count,
                           NULL task,
                           tt.id_sys_shortcut,
                           epis.flg_status,
                           epis.id_schedule,
                           NULL text
                      FROM todo_task tt,
                           (SELECT id_patient,
                                   id_episode,
                                   flg_episode,
                                   flg_pat_allergy,
                                   flg_pat_habit,
                                   flg_pat_history_diagnosis,
                                   flg_vital_sign_read,
                                   flg_epis_diagnosis,
                                   flg_interv_prescription,
                                   flg_nurse_activity_req,
                                   flg_icnp_epis_diagnosis,
                                   flg_icnp_epis_intervention,
                                   flg_pat_pregnancy,
                                   flg_sys_alert_det,
                                   flg_presc_med
                              FROM awareness) awe,
                           (SELECT id_patient,
                                   id_visit,
                                   MAX(flg_analysis_req) flg_analysis_req,
                                   MAX(flg_exam_req) flg_exam_req,
                                   MAX(flg_monitorization) flg_monitorization,
                                   MAX(flg_prescription) flg_prescription,
                                   MAX(flg_drug_req) flg_drug_req,
                                   MAX(flg_presc_med) flg_presc_med
                              FROM awareness
                             GROUP BY id_visit, id_patient) awv,
                           prof_profile_template ppt,
                           (SELECT e.id_patient,
                                   e.id_episode,
                                   ei.id_software,
                                   e.id_visit,
                                   e.id_institution,
                                   ei.id_professional,
                                   ei.id_first_nurse_resp,
                                   e.dt_begin_tstz,
                                   e.flg_status,
                                   e.id_epis_type,
                                   ei.id_schedule
                              FROM episode e, epis_info ei
                            -- Devolver resultados de episodios ACTIVOS e INACTIVOS
                             WHERE e.flg_status IN ('A', 'P', 'I')
                               AND e.id_episode = ei.id_episode
                               AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                               AND ((l_flg_id = 'C' AND EXISTS
                                    (SELECT 0
                                        FROM prof_dep_clin_serv pdcs, schedule s
                                       WHERE pdcs.id_dep_clin_serv = nvl(ei.id_dep_clin_serv, s.id_dcs_requested)
                                         AND s.id_schedule(+) = ei.id_schedule
                                         AND pdcs.id_professional = i_prof.id
                                         AND pdcs.flg_status = 'S')) OR l_flg_id != 'C')
                               AND ((l_flg_id = 'S' AND EXISTS (SELECT 0
                                                                  FROM prof_room pr
                                                                 WHERE pr.id_professional = i_prof.id
                                                                   AND ei.id_room = pr.id_room)) OR l_flg_id != 'S')
                                  /*Usado para perfis que queiram ver os episodios agendados para hoje*/
                                  --AND ((l_flg_id = 'H' AND e.flg_ehr = 'S' AND
                                  -- ei.id_schedule IN (SELECT s.id_schedule
                                  -- FROM schedule s, schedule_outp sp
                                  -- WHERE s.id_schedule = sp.id_schedule
                                  -- AND sp.dt_target BETWEEN trunc(current_timestamp) AND
                                  -- trunc(current_timestamp + INTERVAL '1' DAY)
                                  -- AND s.flg_status != 'C')) OR e.flg_ehr = g_flg_ehr_n)
                               AND e.flg_ehr = g_flg_ehr_n) epis
                     WHERE ppt.id_profile_template = tt.id_profile_template
                       AND epis.id_institution = ppt.id_institution
                       AND epis.id_software = ppt.id_software
                       AND (SELECT pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution)
                              FROM dual) = epis.id_software
                       AND ppt.id_professional = i_prof.id
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_software = i_prof.software
                       AND tt.flg_type = i_flg_type
                       AND epis.id_institution = i_prof.institution
                       AND awe.id_patient = epis.id_patient
                       AND awe.id_episode = epis.id_episode
                       AND awv.id_patient = epis.id_patient
                       AND awv.id_visit = epis.id_visit
                       AND tt.id_institution = l_institution
                    -- PENDING ISSUES - ACTIVE AND INACTIVE EPISODES
                    -- All episodes with pending issues assigned to the current professional
                    UNION ALL
                    SELECT e.id_patient,
                           e.id_episode,
                           NULL             id_external_request,
                           e.dt_begin_tstz  dt_begin_tstz_e,
                           tt.flg_type,
                           tt.flg_task,
                           tt.icon,
                           tt.flg_icon_type,
                           -- Count number of pending issues assigned to I_PROF
                           (SELECT COUNT(*)
                              FROM pending_issue pi
                             WHERE EXISTS (SELECT pip.id_pending_issue
                                      FROM pending_issue_prof pip
                                     WHERE pip.id_professional = i_prof.id
                                       AND pip.id_pending_issue = pi.id_pending_issue)
                               AND pi.id_patient = e.id_patient
                               AND pi.flg_status NOT IN ('C', 'X')) task_count,
                           NULL task,
                           --
                           tt.id_sys_shortcut,
                           e.flg_status       flg_status_e,
                           ei.id_schedule,
                           NULL               text
                      FROM (SELECT ee.*
                              FROM episode ee
                             WHERE EXISTS (SELECT 1
                                      FROM pending_issue pi
                                     WHERE pi.id_patient = ee.id_patient)) e,
                           epis_info ei,
                           prof_profile_template ppt,
                           todo_task tt
                     WHERE e.id_episode = ei.id_episode
                       AND ppt.id_institution = e.id_institution
                       AND ppt.id_profile_template = tt.id_profile_template
                       AND ppt.id_professional = i_prof.id
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_software = i_prof.software
                       AND tt.flg_type = i_flg_type
                       AND tt.flg_task = 'I' -- IMPORTANT: PENDING ISSUES ONLY!!
                       AND e.id_institution = i_prof.institution
                       AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                       AND (ei.id_software = i_prof.software OR i_prof.software = g_soft_nutri OR
                           i_prof.software = pk_alert_constant.g_soft_pharmacy)
                       AND e.flg_status <> 'C'
                       AND tt.id_institution = l_institution
                    -- follow-up requests pending approval
                    UNION ALL
                    SELECT fur.id_patient,
                           fur.id_episode,
                           NULL               id_external_request,
                           fur.dt_begin_tstz  dt_begin_tstz_e,
                           tt.flg_type,
                           tt.flg_task,
                           tt.icon,
                           tt.flg_icon_type,
                           1                  task_count,
                           NULL               task,
                           tt.id_sys_shortcut,
                           fur.flg_status     flg_status_e,
                           fur.id_schedule,
                           NULL               text
                      FROM todo_task tt,
                           (SELECT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                              FROM opinion o
                              JOIN episode e
                                ON o.id_episode_approval = e.id_episode
                              JOIN epis_info ei
                                ON e.id_episode = ei.id_episode
                             WHERE o.flg_state = pk_opinion.g_opinion_req
                               AND o.id_opinion_type IS NOT NULL
                               AND o.id_episode_approval IS NOT NULL
                               AND e.id_institution = i_prof.institution
                               AND e.id_epis_type IN
                                   (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient)
                               AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                               AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                               AND pk_patient.get_prof_resp(i_lang, i_prof, e.id_patient, e.id_episode) = pk_adt.g_true
                               AND ei.id_software = i_prof.software) fur
                     WHERE tt.flg_task = g_task_fu
                       AND tt.flg_type = i_flg_type
                       AND tt.flg_type = g_pending
                       AND tt.id_profile_template = l_prof_templ
                       AND tt.id_institution = l_institution
                    -- FU Requested
                    UNION ALL
                    SELECT fur.id_patient,
                           fur.id_episode,
                           NULL id_external_request,
                           fur.dt_begin_tstz dt_begin_tstz_e,
                           tt.flg_type,
                           tt.flg_task,
                           tt.icon,
                           tt.flg_icon_type,
                           (SELECT COUNT(1)
                              FROM opinion o
                             WHERE o.id_episode = fur.id_episode
                               AND o.id_opinion_type IS NOT NULL
                               AND (o.flg_state = pk_opinion.g_opinion_approved OR
                                   (o.flg_state = pk_opinion.g_opinion_req AND o.id_episode_approval IS NULL))
                                  
                               AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending AND
                                   o.id_opinion_type = l_type_opinion) OR
                                   (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) task_count,
                           NULL task,
                           tt.id_sys_shortcut,
                           fur.flg_status flg_status_e,
                           fur.id_schedule,
                           NULL text
                      FROM todo_task tt,
                           (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                              FROM opinion o
                              JOIN episode e
                                ON o.id_episode = e.id_episode
                              JOIN epis_info ei
                                ON e.id_episode = ei.id_episode
                             WHERE o.id_opinion_type IS NOT NULL
                               AND e.id_institution = i_prof.institution
                               AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                               AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                               AND (o.flg_state = pk_opinion.g_opinion_approved OR
                                   (o.flg_state = pk_opinion.g_opinion_req AND o.id_episode_approval IS NULL))
                                  
                               AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending AND
                                   o.id_opinion_type = l_type_opinion) OR
                                   (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending AND
                                   ei.id_software = i_prof.software))) fur
                     WHERE tt.flg_task = g_task_fu
                       AND tt.flg_type = i_flg_type
                       AND tt.id_profile_template = l_prof_templ
                       AND tt.id_institution = l_institution
                    
                    UNION ALL
                    SELECT e.id_patient,
                           e.id_episode,
                           NULL             id_external_request,
                           e.dt_begin_tstz  dt_begin_tstz_e,
                           tt.flg_type,
                           tt.flg_task,
                           tt.icon,
                           tt.flg_icon_type,
                           1                task_count,
                           NULL             task,
                           --
                           tt.id_sys_shortcut,
                           e.flg_status       flg_status_e,
                           ei.id_schedule,
                           NULL               text
                      FROM therapeutic_decision     t,
                           therapeutic_decision_det td,
                           epis_info                ei,
                           episode                  e,
                           todo_task                tt,
                           prof_profile_template    ppt
                     WHERE td.id_professional = i_prof.id
                       AND nvl(td.flg_opinion, 'N') = 'N'
                       AND td.flg_status = 'A'
                       AND td.flg_presence = 'P'
                       AND t.id_therapeutic_decision = td.id_therapeutic_decision
                       AND t.flg_status = 'A'
                       AND t.id_episode = ei.id_episode
                       AND e.id_episode = ei.id_episode
                       AND e.id_institution = i_prof.institution
                       AND e.flg_status <> 'C'
                       AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                       AND tt.flg_type = i_flg_type
                       AND tt.flg_task = g_task_td
                       AND ppt.id_institution = e.id_institution
                       AND ppt.id_profile_template = tt.id_profile_template
                       AND ppt.id_professional = i_prof.id
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_software = i_prof.software
                       AND tt.id_institution = l_institution
                    UNION ALL
                    --progress notes and history and physical
                    SELECT pn_notes.id_patient,
                           pn_notes.id_episode,
                           NULL                   id_external_request,
                           pn_notes.dt_begin_tstz dt_begin_tstz_e,
                           pn_notes.flg_type,
                           pn_notes.flg_task,
                           pn_notes.icon,
                           pn_notes.flg_icon_type,
                           1                      task_count,
                           
                           NULL                     task,
                           pn_notes.id_sys_shortcut,
                           pn_notes.flg_status      flg_status_e,
                           pn_notes.id_schedule,
                           NULL                     text
                      FROM (SELECT /*+opt_estimate (table nt rows=1)*/
                             tt.id_sys_shortcut,
                             tt.flg_type,
                             tt.icon,
                             tt.flg_icon_type,
                             e.id_patient,
                             e.id_episode,
                             e.dt_begin_tstz,
                             e.flg_status,
                             ei.id_schedule,
                             nt.flg_task,
                             /*          to_char(nvl(epn.dt_pn_date, l_sysdate_tstz) +
                             numtodsinterval(nvl(nt.time_to_close_note, 0), 'minute'),
                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr) task_end_date*/
                             NULL task_end_date
                              FROM epis_pn epn
                              JOIN episode e
                                ON e.id_episode = epn.id_episode
                              JOIN epis_info ei
                                ON e.id_episode = ei.id_episode
                              JOIN TABLE((SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                               i_prof,
                                                                               epn.id_episode,
                                                                               NULL,
                                                                               NULL,
                                                                               epn.id_dep_clin_serv,
                                                                               NULL,
                                                                               NULL)
                                           FROM dual)) nt
                                ON nt.id_pn_area = epn.id_pn_area
                              JOIN todo_task tt
                                ON tt.flg_task = nt.flg_task
                             WHERE tt.flg_type = i_flg_type
                               AND tt.id_profile_template = l_prof_templ
                               AND tt.id_institution = l_institution
                               AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                               AND epn.flg_status IN (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                      pk_prog_notes_constants.g_epis_pn_flg_status_t)
                               AND epn.id_prof_create = i_prof.id
                               AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                               AND e.id_institution = i_prof.institution
                               AND ei.id_software = i_prof.software) pn_notes
                    UNION ALL
                    ------------------------------------
                    -- Referral
                    ------------------------------------
                    SELECT t.id_patient,
                           t.id_episode,
                           t.id_external_request,
                           t.dt_begin_tstz_e,
                           t.flg_type,
                           t.flg_task,
                           t.icon,
                           t.flg_icon_type,
                           t.task_count,
                           NULL task,
                           t.id_sys_shortcut,
                           t.flg_status_e,
                           t.id_schedule,
                           t.num_req || ' (' ||
                           pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_status, t.flg_status, i_lang) || ')' text
                      FROM (
                            -- MED
                            SELECT ea.id_patient,
                                    ea.id_episode,
                                    ea.id_external_request,
                                    ea.dt_status_tstz      dt_begin_tstz_e,
                                    tt.flg_type,
                                    tt.flg_task,
                                    tt.icon,
                                    tt.flg_icon_type,
                                    1                      task_count,
                                    tt.id_sys_shortcut,
                                    NULL                   flg_status_e,
                                    ea.id_schedule,
                                    ea.num_req             num_req,
                                    ea.flg_status
                              FROM p1_external_request ea
                              JOIN prof_profile_template ppt
                                ON (ppt.id_institution = ea.id_inst_orig)
                              JOIN todo_task tt
                                ON (tt.id_profile_template = ppt.id_profile_template)
                             WHERE i_prof_cat = g_prof_cat_d
                               AND ea.id_prof_requested = i_prof.id
                               AND ea.id_inst_orig = i_prof.institution
                               AND ea.flg_status IN (pk_ref_constant.g_p1_status_d,
                                                     pk_ref_constant.g_p1_status_y,
                                                     pk_ref_constant.g_p1_status_x)
                               AND tt.flg_type = i_flg_type
                               AND tt.flg_task = g_task_ref
                               AND NOT EXISTS (SELECT 1
                                      FROM p1_tracking t
                                     WHERE t.id_external_request = ea.id_external_request
                                       AND t.flg_type = pk_ref_constant.g_tracking_type_r
                                       AND t.ext_req_status = ea.flg_status
                                       AND t.id_professional = i_prof.id) -- remove from todo if professional has read the referral
                               AND ppt.id_professional = i_prof.id
                               AND ppt.id_institution = i_prof.institution
                               AND ppt.id_software = i_prof.software
                            UNION ALL
                            -- ADM
                            SELECT ea.id_patient,
                                    ea.id_episode,
                                    ea.id_external_request,
                                    ea.dt_status_tstz      dt_begin_tstz_e,
                                    tt.flg_type,
                                    tt.flg_task,
                                    tt.icon,
                                    tt.flg_icon_type,
                                    1                      task_count,
                                    tt.id_sys_shortcut,
                                    NULL                   flg_status_e,
                                    ea.id_schedule,
                                    ea.num_req             num_req,
                                    ea.flg_status
                              FROM p1_external_request ea
                              JOIN prof_profile_template ppt
                                ON (ppt.id_institution = ea.id_inst_orig)
                              JOIN todo_task tt
                                ON (tt.id_profile_template = ppt.id_profile_template)
                             WHERE i_prof_cat = g_prof_cat_a
                               AND ea.flg_status = pk_ref_constant.g_p1_status_b
                               AND ea.id_inst_orig = i_prof.institution
                               AND tt.flg_type = i_flg_type
                               AND tt.flg_task = g_task_ref
                               AND NOT EXISTS (SELECT 1
                                      FROM p1_tracking t
                                     WHERE t.id_external_request = ea.id_external_request
                                       AND t.flg_type = pk_ref_constant.g_tracking_type_r
                                       AND t.ext_req_status = ea.flg_status
                                       AND t.id_professional = i_prof.id) -- remove from todo if professional has read the referral
                               AND ppt.id_professional = i_prof.id
                               AND ppt.id_institution = i_prof.institution
                               AND ppt.id_software = i_prof.software
                            UNION ALL
                            -- ADM (WF=4)
                            SELECT ea.id_patient,
                                    ea.id_episode,
                                    ea.id_external_request,
                                    ea.dt_status_tstz      dt_begin_tstz_e,
                                    tt.flg_type,
                                    tt.flg_task,
                                    tt.icon,
                                    tt.flg_icon_type,
                                    1                      task_count,
                                    tt.id_sys_shortcut,
                                    NULL                   flg_status_e,
                                    ea.id_schedule,
                                    ea.num_req             num_req,
                                    ea.flg_status
                              FROM p1_external_request ea
                              JOIN prof_profile_template ppt
                                ON (ppt.id_institution = ea.id_inst_dest) -- dest institution
                              JOIN todo_task tt
                                ON (tt.id_profile_template = ppt.id_profile_template)
                             WHERE i_prof_cat = g_prof_cat_a
                               AND ea.id_workflow = pk_ref_constant.g_wf_x_hosp
                               AND (ea.id_prof_requested = i_prof.id OR
                                   pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => ea.id_dep_clin_serv) =
                                   pk_alert_constant.g_yes)
                               AND ea.flg_status IN (pk_ref_constant.g_p1_status_d,
                                                     pk_ref_constant.g_p1_status_y,
                                                     pk_ref_constant.g_p1_status_x,
                                                     pk_ref_constant.g_p1_status_b)
                               AND tt.flg_type = i_flg_type
                               AND tt.flg_task = g_task_ref
                               AND NOT EXISTS (SELECT 1
                                      FROM p1_tracking t
                                     WHERE t.id_external_request = ea.id_external_request
                                       AND t.flg_type = pk_ref_constant.g_tracking_type_r
                                       AND t.ext_req_status = ea.flg_status
                                       AND t.id_professional = i_prof.id) -- remove from todo if professional has read the referral
                               AND ppt.id_professional = i_prof.id
                               AND ppt.id_institution = i_prof.institution
                               AND ppt.id_software = i_prof.software) t
                    UNION ALL
                    -- referral hand off pending tasks
                    SELECT t.id_patient,
                           t.id_episode,
                           t.id_external_request,
                           t.dt_created          dt_begin_tstz_e,
                           t.flg_type,
                           t.flg_task,
                           t.icon,
                           t.flg_icon_type,
                           1                     task_count,
                           NULL                  task,
                           t.id_sys_shortcut,
                           NULL                  flg_status_e,
                           t.id_schedule,
                           t.text
                      FROM (SELECT ea.id_patient,
                                   ea.id_episode,
                                   ea.id_external_request,
                                   rtr.dt_created,
                                   tt.flg_type,
                                   tt.flg_task,
                                   tt.icon,
                                   tt.flg_icon_type,
                                   tt.id_sys_shortcut,
                                   ea.id_schedule,
                                   ea.num_req text
                              FROM ref_trans_responsibility rtr
                              JOIN p1_external_request ea
                                ON (rtr.id_external_request = ea.id_external_request)
                              JOIN prof_profile_template ppt
                                ON (ppt.id_institution = rtr.id_inst_orig_tr)
                              JOIN todo_task tt
                                ON (tt.id_profile_template = ppt.id_profile_template)
                             WHERE tt.flg_type = i_flg_type
                               AND tt.flg_type = g_pending -- pending tasks
                               AND tt.flg_task = g_task_rh
                               AND ppt.id_professional = i_prof.id
                               AND ppt.id_institution = i_prof.institution
                               AND ppt.id_software = i_prof.software
                               AND rtr.flg_active = pk_ref_constant.g_yes
                               AND rtr.id_workflow = pk_ref_constant.g_wf_transfresp -- ID_WF=10
                               AND rtr.id_inst_orig_tr = i_prof.institution
                               AND rtr.id_prof_dest = i_prof.id
                               AND pk_workflow.check_status_final(i_id_workflow => rtr.id_workflow,
                                                                  i_id_status   => rtr.id_status) = pk_ref_constant.g_no
                            UNION ALL
                            SELECT ea.id_patient,
                                   ea.id_episode,
                                   ea.id_external_request,
                                   rtr.dt_created,
                                   tt.flg_type,
                                   tt.flg_task,
                                   tt.icon,
                                   tt.flg_icon_type,
                                   tt.id_sys_shortcut,
                                   ea.id_schedule,
                                   ea.num_req text
                              FROM ref_trans_responsibility rtr
                              JOIN p1_external_request ea
                                ON (rtr.id_external_request = ea.id_external_request)
                              JOIN prof_profile_template ppt
                                ON (ppt.id_institution = rtr.id_inst_dest_tr)
                              JOIN todo_task tt
                                ON (tt.id_profile_template = ppt.id_profile_template)
                             WHERE tt.flg_type = i_flg_type
                               AND tt.flg_type = g_pending -- pending tasks
                               AND tt.flg_task = g_task_rh
                               AND ppt.id_professional = i_prof.id
                               AND ppt.id_institution = i_prof.institution
                               AND ppt.id_software = i_prof.software
                               AND rtr.flg_active = pk_ref_constant.g_yes
                               AND rtr.id_workflow = pk_ref_constant.g_wf_transfresp_inst -- ID_WF=11
                               AND rtr.id_inst_dest_tr = i_prof.institution
                               AND pk_workflow.check_status_final(i_id_workflow => rtr.id_workflow,
                                                                  i_id_status   => rtr.id_status) = pk_ref_constant.g_no
                               AND ((rtr.id_prof_dest = i_prof.id) OR
                                   (pk_ref_change_resp.check_func_handoff_app(i_prof) = pk_ref_constant.g_yes AND
                                   rtr.id_status IN
                                   (pk_ref_constant.g_tr_status_inst_app, pk_ref_constant.g_tr_status_declined_inst)))) t
                    UNION ALL
                    -- referral hand off depending tasks
                    SELECT t.id_patient,
                           t.id_episode,
                           t.id_external_request,
                           t.dt_created          dt_begin_tstz_e,
                           t.flg_type,
                           t.flg_task,
                           t.icon,
                           t.flg_icon_type,
                           1                     task_count,
                           NULL                  task,
                           t.id_sys_shortcut,
                           NULL                  flg_status_e,
                           t.id_schedule,
                           t.text
                      FROM (SELECT ea.id_patient,
                                   ea.id_episode,
                                   ea.id_external_request,
                                   rtr.dt_created,
                                   tt.flg_type,
                                   tt.flg_task,
                                   tt.icon,
                                   tt.flg_icon_type,
                                   tt.id_sys_shortcut,
                                   ea.id_schedule,
                                   ea.num_req text
                              FROM ref_trans_responsibility rtr
                              JOIN p1_external_request ea
                                ON (rtr.id_external_request = ea.id_external_request)
                              JOIN prof_profile_template ppt
                                ON (ppt.id_institution = rtr.id_inst_orig_tr)
                              JOIN todo_task tt
                                ON (tt.id_profile_template = ppt.id_profile_template)
                             WHERE tt.flg_type = i_flg_type
                               AND tt.flg_type = g_depending -- depending tasks
                               AND tt.flg_task = g_task_rh
                               AND ppt.id_professional = i_prof.id
                               AND ppt.id_institution = i_prof.institution
                               AND ppt.id_software = i_prof.software
                               AND rtr.flg_active = pk_ref_constant.g_yes
                               AND rtr.id_workflow = pk_ref_constant.g_wf_transfresp -- ID_WF=10
                               AND rtr.id_inst_orig_tr = i_prof.institution
                               AND rtr.id_prof_transf_owner = i_prof.id
                               AND (rtr.id_prof_dest != i_prof.id OR rtr.id_prof_dest IS NULL)
                               AND pk_workflow.check_status_final(i_id_workflow => rtr.id_workflow,
                                                                  i_id_status   => rtr.id_status) = pk_ref_constant.g_no
                            UNION ALL
                            SELECT ea.id_patient,
                                   ea.id_episode,
                                   ea.id_external_request,
                                   rtr.dt_created,
                                   tt.flg_type,
                                   tt.flg_task,
                                   tt.icon,
                                   tt.flg_icon_type,
                                   tt.id_sys_shortcut,
                                   ea.id_schedule,
                                   ea.num_req text
                              FROM ref_trans_responsibility rtr
                              JOIN p1_external_request ea
                                ON (rtr.id_external_request = ea.id_external_request)
                              JOIN prof_profile_template ppt
                                ON (ppt.id_institution = rtr.id_inst_orig_tr)
                              JOIN todo_task tt
                                ON (tt.id_profile_template = ppt.id_profile_template)
                             WHERE tt.flg_type = i_flg_type
                               AND tt.flg_type = g_depending -- depending tasks
                               AND tt.flg_task = g_task_rh
                               AND ppt.id_professional = i_prof.id
                               AND ppt.id_institution = i_prof.institution
                               AND ppt.id_software = i_prof.software
                               AND rtr.flg_active = pk_ref_constant.g_yes
                               AND rtr.id_workflow = pk_ref_constant.g_wf_transfresp_inst -- ID_WF=11
                               AND rtr.id_inst_orig_tr = i_prof.institution
                               AND rtr.id_prof_transf_owner = i_prof.id
                                  --AND (rtr.id_prof_dest != i_prof.id OR rtr.id_prof_dest IS NULL)
                               AND pk_workflow.check_status_final(i_id_workflow => rtr.id_workflow,
                                                                  i_id_status   => rtr.id_status) = pk_ref_constant.g_no) t
                    UNION ALL
                    -- comments not read
                    SELECT t.id_patient,
                           NULL                  id_episode,
                           t.id_external_request,
                           t.dt_begin_tstz_e,
                           t.flg_type,
                           t.flg_task,
                           t.icon,
                           t.flg_icon_type,
                           t.task_count,
                           NULL                  task,
                           t.id_sys_shortcut,
                           NULL                  flg_status_e,
                           t.id_schedule,
                           t.num_req             text
                      FROM (
                            -- clinical comments not read (orig)
                            SELECT ea.id_patient,
                                    ea.id_external_request,
                                    ea.dt_clin_last_comment dt_begin_tstz_e,
                                    tt.flg_type,
                                    tt.flg_task,
                                    tt.icon,
                                    tt.flg_icon_type,
                                    ea.nr_clin_comments     task_count,
                                    tt.id_sys_shortcut,
                                    ea.id_schedule,
                                    ea.num_req
                              FROM prof_profile_template ppt
                              JOIN profile_template pt
                                ON (ppt.id_profile_template = pt.id_profile_template)
                              JOIN todo_task tt
                                ON (tt.id_profile_template = ppt.id_profile_template)
                              JOIN referral_ea ea
                                ON (ppt.id_institution = ea.id_inst_orig)
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution
                               AND tt.flg_type = i_flg_type
                               AND tt.flg_task = g_task_nr
                               AND nvl(ea.nr_clin_comments, 0) > 0
                               AND nvl(ea.id_prof_clin_comment, -1) != i_prof.id
                               AND ea.flg_clin_comm_read = pk_ref_constant.g_no
                               AND pk_ref_core.check_comm_receiver(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_id_cat            => l_category,
                                                                   i_id_workflow       => ea.id_workflow,
                                                                   i_id_prof_requested => ea.id_prof_requested,
                                                                   i_id_inst_orig      => ea.id_inst_orig,
                                                                   i_id_inst_dest      => ea.id_inst_dest,
                                                                   i_id_dcs            => ea.id_dep_clin_serv,
                                                                   i_flg_type_comm     => pk_ref_constant.g_clinical_comment,
                                                                   i_id_inst_comm      => ea.id_inst_clin_comment) =
                                   pk_ref_constant.g_yes
                            UNION -- if professional works at both institutions, comments tasks should not be duplicate
                            -- clinical comments not read (dest)
                            SELECT ea.id_patient,
                                    ea.id_external_request,
                                    ea.dt_clin_last_comment dt_begin_tstz_e,
                                    tt.flg_type,
                                    tt.flg_task,
                                    tt.icon,
                                    tt.flg_icon_type,
                                    ea.nr_clin_comments     task_count,
                                    tt.id_sys_shortcut,
                                    ea.id_schedule,
                                    ea.num_req
                              FROM prof_profile_template ppt
                              JOIN profile_template pt
                                ON (ppt.id_profile_template = pt.id_profile_template)
                              JOIN todo_task tt
                                ON (tt.id_profile_template = ppt.id_profile_template)
                              JOIN referral_ea ea
                                ON (ppt.id_institution = ea.id_inst_dest)
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution
                               AND tt.flg_type = i_flg_type
                               AND tt.flg_task = g_task_nr
                               AND nvl(ea.nr_clin_comments, 0) > 0
                               AND nvl(ea.id_prof_clin_comment, -1) != i_prof.id
                               AND ea.flg_clin_comm_read = pk_ref_constant.g_no
                               AND pk_ref_core.check_comm_receiver(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_id_cat            => l_category,
                                                                   i_id_workflow       => ea.id_workflow,
                                                                   i_id_prof_requested => ea.id_prof_requested,
                                                                   i_id_inst_orig      => ea.id_inst_orig,
                                                                   i_id_inst_dest      => ea.id_inst_dest,
                                                                   i_id_dcs            => ea.id_dep_clin_serv,
                                                                   i_flg_type_comm     => pk_ref_constant.g_clinical_comment,
                                                                   i_id_inst_comm      => ea.id_inst_clin_comment) =
                                   pk_ref_constant.g_yes
                            UNION ALL
                            -- administrative comments not read (orig)
                            SELECT ea.id_patient,
                                    ea.id_external_request,
                                    ea.dt_adm_last_comment dt_begin_tstz_e,
                                    tt.flg_type,
                                    tt.flg_task,
                                    tt.icon,
                                    tt.flg_icon_type,
                                    ea.nr_adm_comments     task_count,
                                    tt.id_sys_shortcut,
                                    ea.id_schedule,
                                    ea.num_req
                              FROM prof_profile_template ppt
                              JOIN profile_template pt
                                ON (ppt.id_profile_template = pt.id_profile_template)
                              JOIN todo_task tt
                                ON (tt.id_profile_template = ppt.id_profile_template)
                              JOIN referral_ea ea
                                ON (ppt.id_institution = ea.id_inst_orig OR ppt.id_institution = ea.id_inst_dest)
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution
                               AND tt.flg_type = i_flg_type
                               AND tt.flg_task = g_task_nr
                               AND nvl(ea.nr_adm_comments, 0) > 0
                               AND nvl(ea.id_prof_adm_comment, -1) != i_prof.id
                               AND ea.flg_adm_comm_read = pk_ref_constant.g_no
                               AND pk_ref_core.check_comm_receiver(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_id_cat            => l_category,
                                                                   i_id_workflow       => ea.id_workflow,
                                                                   i_id_prof_requested => ea.id_prof_requested,
                                                                   i_id_inst_orig      => ea.id_inst_orig,
                                                                   i_id_inst_dest      => ea.id_inst_dest,
                                                                   i_id_dcs            => ea.id_dep_clin_serv,
                                                                   i_flg_type_comm     => pk_ref_constant.g_administrative_comment,
                                                                   i_id_inst_comm      => ea.id_inst_adm_comment) =
                                   pk_ref_constant.g_yes
                            UNION -- if professional works at both institutions, comments tasks should not be duplicate
                            -- administrative comments not read (dest)
                            SELECT ea.id_patient,
                                    ea.id_external_request,
                                    ea.dt_adm_last_comment dt_begin_tstz_e,
                                    tt.flg_type,
                                    tt.flg_task,
                                    tt.icon,
                                    tt.flg_icon_type,
                                    ea.nr_adm_comments     task_count,
                                    tt.id_sys_shortcut,
                                    ea.id_schedule,
                                    ea.num_req
                              FROM prof_profile_template ppt
                              JOIN profile_template pt
                                ON (ppt.id_profile_template = pt.id_profile_template)
                              JOIN todo_task tt
                                ON (tt.id_profile_template = ppt.id_profile_template)
                              JOIN referral_ea ea
                                ON (ppt.id_institution = ea.id_inst_dest)
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution
                               AND tt.flg_type = i_flg_type
                               AND tt.flg_task = g_task_nr
                               AND nvl(ea.nr_adm_comments, 0) > 0
                               AND nvl(ea.id_prof_adm_comment, -1) != i_prof.id
                               AND ea.flg_adm_comm_read = pk_ref_constant.g_no
                               AND pk_ref_core.check_comm_receiver(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_id_cat            => l_category,
                                                                   i_id_workflow       => ea.id_workflow,
                                                                   i_id_prof_requested => ea.id_prof_requested,
                                                                   i_id_inst_orig      => ea.id_inst_orig,
                                                                   i_id_inst_dest      => ea.id_inst_dest,
                                                                   i_id_dcs            => ea.id_dep_clin_serv,
                                                                   i_flg_type_comm     => pk_ref_constant.g_administrative_comment,
                                                                   i_id_inst_comm      => ea.id_inst_adm_comment) =
                                   pk_ref_constant.g_yes) t
                    UNION ALL
                    ------------------------------------
                    -- discharge summary
                    ------------------------------------
                    SELECT pn_notes.id_patient,
                           pn_notes.id_episode,
                           NULL                     id_external_request,
                           pn_notes.dt_begin_tstz   dt_begin_tstz_e,
                           pn_notes.flg_type,
                           pn_notes.flg_task,
                           pn_notes.icon,
                           pn_notes.flg_icon_type,
                           1                        task_count,
                           NULL                     task,
                           pn_notes.id_sys_shortcut,
                           pn_notes.flg_status      flg_status_e,
                           pn_notes.id_schedule,
                           NULL                     text
                      FROM (SELECT /*+opt_estimate (table nt rows=1)*/
                             tt.id_sys_shortcut,
                             tt.flg_type,
                             tt.icon,
                             tt.flg_icon_type,
                             e.id_patient,
                             e.id_episode,
                             e.dt_begin_tstz,
                             e.flg_status,
                             ei.id_schedule,
                             nt.flg_task,
                             /*                             to_char(nvl(d.dt_pend_tstz,
                                 nvl(d.dt_med_tstz,
                                     nvl(pk_discharge_core.get_dt_admin(i_lang,
                                                                        i_prof,
                                                                        NULL,
                                                                        d.flg_status_adm,
                                                                        d.dt_admin_tstz),
                                         l_sysdate_tstz))) +
                             numtodsinterval(nvl(nt.time_to_start_docum, 0), 'minute'),
                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr) task_end_date,*/
                             NULL task_end_date
                              FROM discharge d
                             CROSS JOIN TABLE((SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                                    i_prof,
                                                                                    d.id_episode,
                                                                                    NULL,
                                                                                    NULL,
                                                                                    NULL,
                                                                                    'DS',
                                                                                    NULL)
                                                FROM dual)) nt
                              JOIN episode e
                                ON e.id_episode = d.id_episode
                              JOIN epis_info ei
                                ON e.id_episode = ei.id_episode
                              JOIN todo_task tt
                                ON tt.flg_task = nt.flg_task
                               AND tt.id_profile_template = l_prof_templ
                               AND tt.flg_task = l_flg_task_ds
                               AND tt.id_institution = l_institution
                             WHERE d.flg_status NOT IN
                                   (pk_discharge.g_disch_flg_status_reopen, pk_discharge.g_disch_flg_status_cancel)
                               AND tt.flg_type = i_flg_type
                               AND pk_utils.search_table_number((SELECT pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                           i_prof,
                                                                                                           ei.id_episode,
                                                                                                           l_prof_cat,
                                                                                                           l_handoff_type)
                                                                  FROM dual),
                                                                i_prof.id) != -1
                               AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                               AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                               AND e.id_institution = i_prof.institution
                               AND ei.id_software = i_prof.software
                               AND NOT EXISTS (SELECT 1
                                      FROM epis_pn epn
                                     WHERE epn.id_episode = d.id_episode
                                       AND epn.id_pn_area = nt.id_pn_area
                                       AND epn.flg_status IN
                                           (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                            pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                            pk_prog_notes_constants.g_epis_pn_flg_status_s))) pn_notes
                    UNION ALL
                    SELECT cr.id_patient,
                           cr.id_episode,
                           NULL id_external_request,
                           cr.dt_begin_tstz dt_begin_tstz_e,
                           tt.flg_type,
                           tt.flg_task,
                           tt.icon,
                           tt.flg_icon_type,
                           (SELECT COUNT(1)
                              FROM opinion o
                             WHERE o.id_episode = cr.id_episode
                               AND o.flg_state = pk_opinion.g_opinion_req
                               AND o.id_opinion_type IS NULL
                               AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending) OR
                                   (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) task_count,
                           NULL task,
                           tt.id_sys_shortcut,
                           cr.flg_status flg_status_e,
                           cr.id_schedule,
                           NULL text
                      FROM todo_task tt,
                           (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                              FROM opinion o
                              JOIN episode e
                                ON o.id_episode = e.id_episode
                              JOIN epis_info ei
                                ON e.id_episode = ei.id_episode
                             WHERE o.flg_state = pk_opinion.g_opinion_req
                               AND o.id_opinion_type IS NULL
                               AND e.id_institution = i_prof.institution
                               AND e.flg_status = pk_alert_constant.g_epis_status_active
                               AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                               AND ei.id_software = i_prof.software
                               AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending) OR
                                   (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) cr
                     WHERE tt.flg_task = g_task_cr
                       AND tt.flg_type = i_flg_type
                       AND tt.id_profile_template = l_prof_templ
                       AND tt.id_institution = l_institution
                    
                    UNION ALL
                    -- HAND OFF
                    SELECT tr.id_patient,
                           tr.id_episode,
                           NULL id_external_request,
                           tr.dt_begin_tstz dt_begin_tstz_e,
                           tt.flg_type,
                           tt.flg_task,
                           tt.icon,
                           tt.flg_icon_type,
                           (SELECT COUNT(1)
                              FROM epis_prof_resp epr
                             WHERE epr.id_episode = tr.id_episode
                               AND epr.flg_status = pk_hand_off.g_hand_off_r
                               AND ((epr.id_prof_to = i_prof.id AND i_flg_type = g_pending) OR
                                   (epr.id_prof_req = i_prof.id AND i_flg_type = g_depending))) task_count,
                           NULL task,
                           tt.id_sys_shortcut,
                           tr.flg_status flg_status_e,
                           tr.id_schedule,
                           NULL text
                      FROM todo_task tt,
                           (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                              FROM epis_prof_resp epr
                              JOIN episode e
                                ON epr.id_episode = e.id_episode
                              JOIN epis_info ei
                                ON e.id_episode = ei.id_episode
                             WHERE epr.flg_status = pk_hand_off.g_hand_off_r
                               AND e.id_institution = i_prof.institution
                               AND e.flg_status = pk_alert_constant.g_epis_status_active
                               AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                               AND ei.id_software = i_prof.software
                               AND ((epr.id_prof_to = i_prof.id AND i_flg_type = g_pending) OR
                                   (epr.id_prof_req = i_prof.id AND i_flg_type = g_depending))) tr
                     WHERE tt.flg_task = g_task_tr
                       AND tt.flg_type = i_flg_type
                       AND tt.id_profile_template = l_prof_templ
                       AND tt.id_institution = l_institution) t,
                   patient p
            -- Obter apenas os episodios com tarefas pendentes
             WHERE p.id_patient = t.id_patient
               AND t.task_count > 0;
        
        ELSE
            g_error := 'INVALID ACTION';
            RAISE err_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PROF_TASKS_COUNT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_tasks_count;

    FUNCTION get_todo_list_base
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_mode  IN VARCHAR2,
        o_rows  OUT t_todo_list_tbl,
        o_count OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_prof_cat         category.flg_type%TYPE;
        l_flg_show_actv_inactv VARCHAR2(1);
    
        l_time_interval sys_config.value%TYPE;
        l_hand_off_type sys_config.value%TYPE;
        l_num_format    VARCHAR2(30 CHAR) := '9999.9999';
        l_err_config    EXCEPTION;
    
    BEGIN
    
        -- Verificar se a To-do List mostra episodios ACTIVOS e INACTIVOS
        g_error                := 'GET ACTIVE INACTIVE EPISODES CONFIG';
        l_flg_show_actv_inactv := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_SHOW_ACTIVE_INACTIVE',
                                                          i_prof    => i_prof);
        g_error                := 'GET TYPE OF HAND-OFF';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        -- Categoria do profissional
        g_error := 'GET PROF CAT';
        SELECT c.flg_type
          INTO l_flg_prof_cat
          FROM prof_cat pc
          JOIN category c
            ON pc.id_category = c.id_category
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution;
    
        g_error             := 'SET DATES';
        g_current_timestamp := current_timestamp;
    
        g_error         := 'GET CONFIG TODO_EPISODE_OUTDATE';
        l_time_interval := pk_sysconfig.get_config('TODO_EPISODE_OUTDATE', i_prof);
    
        IF l_time_interval IS NULL
        THEN
            RAISE l_err_config;
        END IF;
    
        -- Jose Brito 15/01/2009 ALERT-13678
        IF to_number(l_time_interval, l_num_format) < 1
        THEN
            -- If 'l_time_interval' is a decimal number, subtract the number of DAYS to the current date.
            -- Example: 0.1 = 3 DAYS; 0.06 = 2 DAYS; 0.03 = 1 DAY; etc.
            g_error         := 'GET TIME INTERVAL - DAYS';
            g_epis_min_date := pk_date_utils.trunc_insttimezone(i_prof,
                                                                current_timestamp -
                                                                numtodsinterval(to_number(l_time_interval, l_num_format) * 30,
                                                                                'DAY'),
                                                                NULL);
        ELSE
            -- If 'l_time_interval' is an integer, subtract the number of MONTHS to the current date.
            -- Using the method 'add_months' allows better precision.
            g_error         := 'GET TIME INTERVAL - MONTHS';
            g_epis_min_date := pk_date_utils.trunc_insttimezone(i_prof,
                                                                add_months(current_timestamp, -l_time_interval),
                                                                NULL);
        END IF;
    
        g_dt_server := pk_date_utils.date_send_tsz(i_lang, g_current_timestamp, i_prof);
        g_today     := pk_date_utils.trunc_insttimezone(i_prof, g_current_timestamp, NULL);
        g_tomorrow  := g_today + INTERVAL '1' DAY;
    
        g_error := 'CALL TO GET_TASKS 1';
        IF NOT get_prof_tasks(i_lang          => i_lang,
                              i_prof          => i_prof,
                              i_mode          => i_mode,
                              i_prof_cat      => l_flg_prof_cat,
                              i_flg_type      => g_pending,
                              i_flg_show_ai   => l_flg_show_actv_inactv,
                              i_hand_off_type => l_hand_off_type,
                              o_tasks         => o_rows,
                              o_count         => o_count,
                              o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_err_config THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_CONFIG_ERROR',
                                              'CONFIGURATION ERROR - TODO_EPISODE_OUTDATE',
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_TODO_LIST_BASE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_TODO_LIST_BASE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_todo_list_base;

    FUNCTION get_prof_task_base01
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_flg_type IN todo_task.flg_type%TYPE
    ) RETURN todo_list_01_tbl IS
    
        l_flg_id         VARCHAR2(0010 CHAR);
        l_category       category.id_category%TYPE;
        l_config_ti_cats sys_config.value%TYPE;
        l_prof_cat       category.flg_type%TYPE;
        l_prof_templ     todo_task.id_profile_template%TYPE;
        l_institution    NUMBER;
        l_type_opinion   opinion_type.id_opinion_type%TYPE;
        l_signoff_type   sys_config.value%TYPE;
        l_prof_name      VARCHAR2(1 CHAR);
        l_note_name      VARCHAR2(1 CHAR);
        l_sysdate_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_handoff_type   sys_config.value%TYPE;
        l_flg_task_ds    todo_task.flg_task%TYPE := 'DS';
    
        tbl_return todo_list_01_tbl := todo_list_01_tbl();
    
    BEGIN
    
        l_sysdate_tstz   := current_timestamp;
        l_flg_id         := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_' || i_prof_cat, i_prof => i_prof);
        l_category       := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_config_ti_cats := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_CAT_TRANSF_INST', i_prof => i_prof);
        l_signoff_type   := pk_sysconfig.get_config(i_code_cf => 'NOTE_SIGNATURE_MECHANISM', i_prof => i_prof);
        l_prof_name      := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_PROF_NAME', i_prof => i_prof);
        l_note_name      := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_NOTE_NAME', i_prof => i_prof);
    
        l_prof_templ  := pk_tools.get_prof_profile_template(i_prof => i_prof);
        l_institution := get_config_vars(i_prof => i_prof, i_profile => l_prof_templ);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        l_type_opinion := get_opinion_type(l_category);
    
        IF l_flg_id IS NULL
        THEN
            l_flg_id := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_ALL', i_prof => i_prof);
        END IF;
    
        SELECT todo_list_01_rec(id_patient          => t.id_patient,
                                id_episode          => t.id_episode,
                                id_visit            => NULL,
                                id_external_request => t.id_external_request,
                                dt_begin_tstz_e     => t.dt_begin_tstz_e,
                                flg_type            => t.flg_type,
                                flg_task            => t.flg_task,
                                icon                => t.icon,
                                flg_icon_type       => t.flg_icon_type,
                                task_count          => t.task_count,
                                task                => t.task,
                                id_sys_shortcut     => t.id_sys_shortcut,
                                flg_status_e        => t.flg_status_e,
                                id_schedule         => t.id_schedule,
                                text                => t.text,
                                prof_name           => t.prof_name,
                                note_name           => t.note_name,
                                time_to_sort        => t.time_to_sort)
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT epis.id_patient,
                        epis.id_episode,
                        NULL id_external_request,
                        epis.dt_begin_tstz_e,
                        tt.flg_type,
                        tt.flg_task,
                        tt.icon,
                        tt.flg_icon_type,
                        pk_todo_list.get_epis_task_count_aux(i_lang                    => i_lang,
                                                             i_prof                    => i_prof,
                                                             i_prof_cat                => i_prof_cat,
                                                             i_id_episode              => epis.id_episode,
                                                             i_id_patient              => epis.id_patient,
                                                             i_id_visit                => epis.id_visit,
                                                             i_flg_type                => i_flg_type,
                                                             i_flg_task                => tt.flg_task,
                                                             i_epis_flg_status         => epis.flg_status_e,
                                                             i_flg_analysis_req        => awv.flg_analysis_req,
                                                             i_flg_exam_req            => awv.flg_exam_req,
                                                             i_flg_monitorization      => awv.flg_monitorization,
                                                             i_flg_presc_med           => awv.flg_presc_med,
                                                             i_flg_drug_req            => awv.flg_drug_req,
                                                             i_flg_interv_prescription => awe.flg_interv_prescription,
                                                             i_flg_nurse_activity_req  => awe.flg_nurse_activity_req) task_count,
                        NULL task,
                        tt.id_sys_shortcut,
                        epis.flg_status_e,
                        epis.id_schedule,
                        NULL text,
                        NULL prof_name,
                        NULL note_name,
                        NULL time_to_sort
                   FROM todo_task tt,
                        (SELECT /*+ use_nl(a e) */
                          a.id_patient,
                          a.id_episode,
                          a.flg_episode,
                          a.flg_pat_allergy,
                          a.flg_pat_habit,
                          a.flg_pat_history_diagnosis,
                          a.flg_vital_sign_read,
                          a.flg_epis_diagnosis,
                          a.flg_interv_prescription,
                          a.flg_nurse_activity_req,
                          a.flg_icnp_epis_diagnosis,
                          a.flg_icnp_epis_intervention,
                          a.flg_pat_pregnancy,
                          a.flg_sys_alert_det,
                          a.flg_presc_med
                           FROM awareness a
                           JOIN episode e
                             ON a.id_episode = e.id_episode
                          WHERE e.flg_status IN
                                (pk_alert_constant.g_epis_status_active, pk_alert_constant.g_epis_status_pendent)) awe,
                        (SELECT /*+ use_nl(a e) */
                          a.id_patient,
                          a.id_visit,
                          MAX(flg_analysis_req) flg_analysis_req,
                          MAX(flg_exam_req) flg_exam_req,
                          MAX(flg_monitorization) flg_monitorization,
                          MAX(flg_prescription) flg_prescription,
                          MAX(flg_drug_req) flg_drug_req,
                          MAX(flg_presc_med) flg_presc_med
                           FROM awareness a
                           JOIN episode e
                             ON a.id_episode = e.id_episode
                          WHERE e.flg_status IN
                                (pk_alert_constant.g_epis_status_active, pk_alert_constant.g_epis_status_pendent)
                          GROUP BY a.id_visit, a.id_patient) awv,
                        (SELECT e.id_patient,
                                e.id_episode,
                                NULL                  id_external_request,
                                e.id_software,
                                e.id_visit,
                                e.id_institution,
                                e.id_professional,
                                e.id_first_nurse_resp,
                                e.dt_begin_tstz_e,
                                e.flg_status_e,
                                e.id_epis_type,
                                e.id_schedule,
                                NULL                  text
                         -- Usar a view de episodios activos e pendentes
                           FROM v_episode_act_pend e
                          WHERE e.id_institution = i_prof.institution
                            AND e.dt_begin_tstz_e >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                            AND ((l_flg_id = 'C' AND EXISTS
                                 (SELECT 0
                                     FROM prof_dep_clin_serv pdcs, schedule s
                                    WHERE pdcs.id_dep_clin_serv = nvl(e.id_dep_clin_serv, s.id_dcs_requested)
                                      AND s.id_schedule(+) = e.id_schedule
                                      AND pdcs.id_professional = i_prof.id
                                      AND pdcs.flg_status = 'S')) OR l_flg_id != 'C')
                            AND ((l_flg_id = 'S' AND EXISTS (SELECT 0
                                                               FROM prof_room pr
                                                              WHERE pr.id_professional = i_prof.id
                                                                AND e.id_room = pr.id_room)) OR l_flg_id != 'S')
                            AND e.id_software = i_prof.software
                            AND e.id_institution = i_prof.institution
                            AND (SELECT pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
                                   FROM dual) = e.id_software
                            AND e.flg_ehr = g_flg_ehr_n
                         
                         -- Jose Brito 10/11/2008 ALERT-8047 Mostrar na to-do list as transferencias inter-hospitalares
                         -- cuja instituicao de destino seja a do profissional actual. Este caso so se aplica a episodios
                         -- activos do EDIS, pelo que nao e necessario repetir este codigo na query que mostra tarefas
                         -- de episodios inactivos (usada em Outpatient, p.ex.).
                         UNION ALL
                         SELECT e.id_patient,
                                e.id_episode,
                                NULL id_external_request,
                                e.id_software,
                                e.id_visit,
                                -- Devolver o ID da instituicao do profissional, para evitar alterar os joins da query principal,
                                -- trazendo vantagens ao nivel da performance. Nao e necessario devolver o ID da instituicao do episodio.
                                i_prof.institution    id_institution,
                                e.id_professional,
                                e.id_first_nurse_resp,
                                e.dt_begin_tstz_e,
                                e.flg_status_e,
                                e.id_epis_type,
                                e.id_schedule,
                                NULL                  text
                           FROM v_episode_act_pend e, transfer_institution ti
                          WHERE e.id_episode = ti.id_episode
                            AND ti.id_institution_dest = i_prof.institution
                            AND ti.flg_status = 'T'
                            AND e.dt_begin_tstz_e >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                               --it is used a sys_config in order to be possible to configure different categories
                               --for diferent softwares
                            AND instr(l_config_ti_cats, '|' || to_char(l_category) || '|') != 0
                            AND (SELECT pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
                                   FROM dual) = e.id_software) epis
                  WHERE tt.flg_type = i_flg_type
                    AND awe.id_patient = epis.id_patient
                    AND awe.id_episode = epis.id_episode
                    AND awv.id_patient = epis.id_patient
                    AND awv.id_visit = epis.id_visit
                    AND tt.id_profile_template = l_prof_templ
                    AND tt.id_institution = l_institution
                 --
                 -- PENDING ISSUES - ACTIVE EPISODES
                 -- All episodes with pending issues assigned to the current professional
                 UNION ALL
                 SELECT e.id_patient,
                        e.id_episode,
                        NULL id_external_request,
                        e.dt_begin_tstz_e,
                        tt.flg_type,
                        tt.flg_task,
                        tt.icon,
                        tt.flg_icon_type,
                        -- Count number of pending issues assigned to I_PROF
                        (SELECT COUNT(*)
                           FROM pending_issue pi
                          WHERE EXISTS (SELECT pip.id_pending_issue
                                   FROM pending_issue_prof pip
                                  WHERE pip.id_professional = i_prof.id
                                    AND pip.id_pending_issue = pi.id_pending_issue)
                            AND pi.id_patient = e.id_patient
                            AND pi.flg_status NOT IN ('C', 'X')) task_count,
                        NULL task,
                        tt.id_sys_shortcut,
                        e.flg_status_e,
                        e.id_schedule,
                        NULL text,
                        NULL prof_name,
                        NULL note_name,
                        NULL time_to_sort
                   FROM (SELECT ee.*
                           FROM v_episode_act_pend ee
                          WHERE EXISTS (SELECT 1
                                   FROM pending_issue pi
                                  WHERE pi.id_patient = ee.id_patient)
                            AND ee.id_institution = i_prof.institution
                            AND ee.dt_begin_tstz_e >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                            AND ee.id_software = i_prof.software
                            AND ee.flg_status_e <> 'C') e,
                        todo_task tt
                  WHERE tt.id_profile_template = l_prof_templ
                    AND tt.id_institution = l_institution
                    AND tt.flg_type = i_flg_type
                    AND tt.flg_task = 'I' -- IMPORTANT: PENDING ISSUES ONLY!!
                 -- follow-up requests pending approval
                 UNION ALL
                 SELECT fur.id_patient,
                        fur.id_episode,
                        NULL               id_external_request,
                        fur.dt_begin_tstz  dt_begin_tstz_e,
                        tt.flg_type,
                        tt.flg_task,
                        tt.icon,
                        tt.flg_icon_type,
                        1                  task_count,
                        NULL               task,
                        tt.id_sys_shortcut,
                        fur.flg_status     flg_status_e,
                        fur.id_schedule,
                        NULL               text,
                        NULL               prof_name,
                        NULL               note_name,
                        NULL               time_to_sort
                   FROM todo_task tt,
                        (SELECT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                           FROM opinion o
                           JOIN episode e
                             ON o.id_episode_approval = e.id_episode
                           JOIN epis_info ei
                             ON e.id_episode = ei.id_episode
                          WHERE o.flg_state = pk_opinion.g_opinion_req
                            AND o.id_opinion_type IS NOT NULL
                            AND o.id_episode_approval IS NOT NULL
                            AND e.id_institution = i_prof.institution
                            AND e.id_epis_type IN
                                (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient)
                            AND e.flg_status = pk_alert_constant.g_epis_status_active
                            AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                            AND pk_patient.get_prof_resp(i_lang, i_prof, e.id_patient, e.id_episode) = pk_adt.g_true
                            AND ei.id_software = i_prof.software) fur
                  WHERE tt.flg_task = g_task_fu
                    AND tt.flg_type = i_flg_type
                    AND tt.flg_type = g_pending
                    AND tt.id_profile_template = l_prof_templ
                    AND tt.id_institution = l_institution
                 -- FU Requested
                 UNION ALL
                 SELECT fur.id_patient,
                        fur.id_episode,
                        NULL id_external_request,
                        fur.dt_begin_tstz dt_begin_tstz_e,
                        tt.flg_type,
                        tt.flg_task,
                        tt.icon,
                        tt.flg_icon_type,
                        (SELECT COUNT(1)
                           FROM opinion o
                          WHERE o.id_episode = fur.id_episode
                            AND o.id_opinion_type IS NOT NULL
                            AND (o.flg_state = pk_opinion.g_opinion_approved OR
                                (o.flg_state = pk_opinion.g_opinion_req AND o.id_episode_approval IS NULL))
                            AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending AND
                                o.id_opinion_type = l_type_opinion) OR
                                (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) task_count,
                        NULL task,
                        tt.id_sys_shortcut,
                        fur.flg_status flg_status_e,
                        fur.id_schedule,
                        NULL text,
                        NULL prof_name,
                        NULL note_name,
                        NULL time_to_sort
                   FROM todo_task tt,
                        (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                           FROM opinion o
                           JOIN episode e
                             ON o.id_episode = e.id_episode
                           JOIN epis_info ei
                             ON e.id_episode = ei.id_episode
                          WHERE o.id_opinion_type IS NOT NULL
                            AND e.id_institution = i_prof.institution
                            AND e.flg_status = pk_alert_constant.g_epis_status_active
                            AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                            AND (o.flg_state = pk_opinion.g_opinion_approved OR
                                (o.flg_state = pk_opinion.g_opinion_req AND o.id_episode_approval IS NULL))
                            AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending AND
                                o.id_opinion_type = l_type_opinion) OR
                                (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending AND
                                ei.id_software = i_prof.software))) fur
                  WHERE tt.flg_task = g_task_fu
                    AND tt.flg_type = i_flg_type
                    AND tt.id_profile_template = l_prof_templ
                    AND tt.id_institution = l_institution
                 UNION ALL
                 --progress notes and history and physical
                 SELECT pn_notes.id_patient,
                        pn_notes.id_episode,
                        NULL id_external_request,
                        pn_notes.dt_begin_tstz dt_begin_tstz_e,
                        pn_notes.flg_type,
                        pn_notes.flg_task,
                        pn_notes.icon,
                        pn_notes.flg_icon_type,
                        1 task_count,
                        CASE
                            WHEN pn_notes.task_end_date IS NOT NULL THEN
                             pk_utils.get_status_string_immediate(i_lang,
                                                                  i_prof,
                                                                  'D', --display_type,
                                                                  'A', --flg_state,
                                                                  NULL, --value_text, 
                                                                  to_char(pn_notes.task_end_date,
                                                                          pk_alert_constant.g_dt_yyyymmddhh24miss_tzr), --value_date,
                                                                  NULL, --value_icon,
                                                                  NULL, --shortcut,
                                                                  NULL, --back_color,
                                                                  NULL, --icon_color,
                                                                  NULL, --message_style,
                                                                  NULL, --message_color,
                                                                  NULL, --flg_text_domain,
                                                                  l_sysdate_tstz) --dt_server
                            ELSE
                             NULL
                        END task,
                        pn_notes.id_sys_shortcut,
                        pn_notes.flg_status flg_status_e,
                        pn_notes.id_schedule,
                        NULL text,
                        pn_notes.prof_name,
                        pn_notes.note_name,
                        decode(pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                               i_date1 => pn_notes.task_end_date,
                                                               i_date2 => l_sysdate_tstz),
                               'G',
                               abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                    i_timestamp_2 => l_sysdate_tstz)),
                               'L',
                               -abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                     i_timestamp_2 => l_sysdate_tstz)),
                               abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                    i_timestamp_2 => l_sysdate_tstz))) time_to_sort
                   FROM (SELECT DISTINCT --/*+opt_estimate (table nt rows=1)
                                         tt.id_sys_shortcut,
                                         tt.flg_type,
                                         tt.icon,
                                         tt.flg_icon_type,
                                         e.id_patient,
                                         e.id_episode,
                                         e.dt_begin_tstz,
                                         e.flg_status,
                                         ei.id_schedule,
                                         nt.flg_task,
                                         decode(nt.flg_task,
                                                'DS',
                                                nvl(pk_discharge.get_discharge_date(i_lang       => i_lang,
                                                                                    i_prof       => i_prof,
                                                                                    i_id_episode => epn.id_episode),
                                                    epn.dt_pn_date) +
                                                numtodsinterval(nvl(nt.time_to_start_docum, 0), 'minute'),
                                                pk_prog_notes_utils.get_end_task_time(i_lang    => i_lang,
                                                                                      i_prof    => i_prof,
                                                                                      i_episode => epn.id_episode,
                                                                                      i_epis_pn => epn.id_epis_pn)) task_end_date,
                                         decode(l_note_name,
                                                pk_alert_constant.g_yes,
                                                pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                                       i_prof               => i_prof,
                                                                                       i_id_pn_note_type    => epn.id_pn_note_type,
                                                                                       i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_desc_d),
                                                pk_alert_constant.g_no,
                                                NULL) note_name,
                                         decode(l_prof_name,
                                                pk_alert_constant.g_yes,
                                                pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => epn.id_prof_create),
                                                pk_alert_constant.g_no,
                                                NULL) prof_name
                           FROM epis_pn epn
                           JOIN episode e
                             ON e.id_episode = epn.id_episode
                           JOIN epis_info ei
                             ON e.id_episode = ei.id_episode
                           JOIN TABLE((SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                            i_prof,
                                                                            epn.id_episode,
                                                                            NULL,
                                                                            NULL,
                                                                            epn.id_dep_clin_serv,
                                                                            NULL,
                                                                            NULL)
                                        FROM dual)) nt
                             ON nt.id_pn_area = epn.id_pn_area
                           JOIN todo_task tt
                             ON tt.flg_task = nt.flg_task
                          WHERE tt.flg_type = i_flg_type
                            AND tt.id_profile_template = l_prof_templ
                            AND tt.id_institution = l_institution
                            AND ((epn.flg_status IN (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                     pk_prog_notes_constants.g_epis_pn_flg_status_t) AND
                                e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE) AND
                                epn.id_prof_create = i_prof.id AND l_signoff_type = g_signature_signoff) OR
                                (epn.flg_status = pk_prog_notes_constants.g_epis_pn_flg_for_review AND
                                ei.id_professional = i_prof.id AND l_signoff_type = g_signature_submit))
                            AND ((l_signoff_type = g_signature_signoff AND epn.id_prof_create = i_prof.id) OR
                                (l_signoff_type = g_signature_submit AND ei.id_professional = i_prof.id))
                            AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                            AND e.id_institution = i_prof.institution
                            AND ei.id_software = i_prof.software) pn_notes
                 --admission note is over time-to-close and has not submitted to VS and it's multi-hand off
                UNION ALL
                SELECT pn_notes.id_patient,
                       pn_notes.id_episode,
                       NULL id_external_request,
                       pn_notes.dt_begin_tstz dt_begin_tstz_e,
                       pn_notes.flg_type,
                       pn_notes.flg_task,
                       pn_notes.icon,
                       pn_notes.flg_icon_type,
                       1 task_count,
                       CASE
                           WHEN pn_notes.task_end_date IS NOT NULL THEN
                            pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 'D', --display_type,
                                                                 'A', --flg_state,
                                                                 NULL, --value_text,
                                                                 to_char(pn_notes.task_end_date,
                                                                         pk_alert_constant.g_dt_yyyymmddhh24miss_tzr), --value_date,
                                                                 NULL, --value_icon,
                                                                 NULL, --shortcut,
                                                                 NULL, --back_color,
                                                                 NULL, --icon_color,
                                                                 NULL, --message_style,
                                                                 NULL, --message_color,
                                                                 NULL, --flg_text_domain,
                                                                 l_sysdate_tstz) --dt_server
                           ELSE
                            NULL
                       END task,
                       pn_notes.id_sys_shortcut,
                       pn_notes.flg_status flg_status_e,
                       pn_notes.id_schedule,
                       NULL text,
                       pn_notes.prof_name,
                       pn_notes.note_name,
                       decode(pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                              i_date1 => pn_notes.task_end_date,
                                                              i_date2 => l_sysdate_tstz),
                              'G',
                              abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                   i_timestamp_2 => l_sysdate_tstz)),
                              'L',
                              -abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                    i_timestamp_2 => l_sysdate_tstz)),
                              abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                   i_timestamp_2 => l_sysdate_tstz))) time_to_sort
                  FROM (SELECT t2.id_sys_shortcut,
                               t2.flg_type,
                               nvl2(t2.id_epis_pn,
                                    pk_sysdomain.get_img(i_lang         => i_lang,
                                                         i_code_dom     => 'EPIS_PN.FLG_STATUS',
                                                         i_val          => t2.pn_flg_status,
                                                         i_domain_owner => 'ALERT'),
                                    NULL) icon,
                               t2.flg_icon_type,
                               t2.id_patient,
                               t2.id_episode,
                               t2.dt_begin_tstz,
                               t2.flg_status,
                               t2.id_schedule,
                               t2.flg_task,
                               nvl(t2.dt_begin_tstz, l_sysdate_tstz) +
                               pk_prog_notes_utils.gen_time_to_close(i_lang,
                                                                     i_prof,
                                                                     t2.id_episode,
                                                                     pk_prog_notes_constants.g_note_type_id_handp_2) task_end_date,
                               decode(l_note_name,
                                      pk_alert_constant.g_yes,
                                      pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                             i_prof               => i_prof,
                                                                             i_id_pn_note_type    => nvl2(t2.id_epis_pn,
                                                                                                          t2.id_pn_note_type,
                                                                                                          pk_prog_notes_constants.g_note_type_id_handp_2),
                                                                             i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_desc_d),
                                      pk_alert_constant.g_no,
                                      NULL) note_name,
                               decode(l_prof_name,
                                      pk_alert_constant.g_yes,
                                      nvl2(t2.id_epis_pn,
                                           pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => t2.id_prof_create),
                                           NULL),
                                      pk_alert_constant.g_no,
                                      NULL) prof_name
                          FROM (SELECT tt.id_sys_shortcut,
                                       tt.flg_type,
                                       epn.id_epis_pn,
                                       epn.flg_status pn_flg_status,
                                       tt.flg_icon_type,
                                       e.id_patient,
                                       e.id_episode,
                                       e.dt_begin_tstz,
                                       e.flg_status,
                                       ei.id_schedule,
                                       tt.flg_task,
                                       epn.id_pn_note_type,
                                       epn.id_prof_create,
                                       e.dt_creation
                                  FROM episode e
                                  LEFT OUTER JOIN (SELECT ep.*
                                                    FROM epis_pn ep
                                                   INNER JOIN episode epis
                                                      ON ep.id_episode = epis.id_episode
                                                   WHERE ep.id_pn_note_type =
                                                         pk_prog_notes_constants.g_note_type_id_handp_2
                                                     AND ep.flg_status <> pk_alert_constant.g_cancelled
                                                     AND epis.id_institution = i_prof.institution
                                                     AND epis.flg_status <> pk_alert_constant.g_cancelled) epn
                                    ON e.id_episode = epn.id_episode
                                  JOIN epis_info ei
                                    ON e.id_episode = ei.id_episode
                                 CROSS JOIN TABLE (SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                                        i_prof,
                                                                                        epn.id_episode,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        pk_prog_notes_constants.g_area_hp,
                                                                                        NULL)
                                                    FROM dual) nt
                                  JOIN todo_task tt
                                    ON tt.flg_task = nt.flg_task
                                 WHERE tt.flg_type = i_flg_type
                                   AND tt.id_profile_template = l_prof_templ
                                   AND tt.id_institution = l_institution
                                   AND (epn.id_episode IS NULL OR
                                       (epn.flg_status IN
                                       (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                          pk_prog_notes_constants.g_epis_pn_flg_status_t)))
                                   AND l_note_name = pk_alert_constant.g_yes
                                   AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                                   AND e.id_institution = i_prof.institution
                                   AND ei.id_software = i_prof.software
                                   AND ei.id_professional = i_prof.id
                                   AND pk_utils.search_table_number((SELECT pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                               i_prof,
                                                                                                               e.id_episode,
                                                                                                               l_prof_cat,
                                                                                                               l_handoff_type)
                                                                      FROM dual),
                                                                    i_prof.id) != -1
                                   AND rownum > 0) t2
                         WHERE (l_sysdate_tstz - t2.dt_creation >
                               pk_prog_notes_utils.gen_time_to_close(i_lang,
                                                                      i_prof,
                                                                      t2.id_episode,
                                                                      pk_prog_notes_constants.g_note_type_id_handp_2))) pn_notes
                UNION ALL
                --ASantos 21-11-20011
                --ALERT-195554 - Chile | Ability to interface information regarding management of GES
                SELECT sae.id_patient,
                       sae.id_episode,
                       NULL id_external_request,
                       sae.dt_record dt_begin_tstz_e,
                       tt.flg_type,
                       tt.flg_task,
                       tt.icon,
                       tt.flg_icon_type,
                       to_number(sae.replace1) task_count,
                       NULL task,
                       tt.id_sys_shortcut,
                       NULL flg_status_e,
                       NULL id_schedule,
                       NULL text,
                       NULL prof_name,
                       NULL note_name,
                       NULL time_to_sort
                  FROM sys_alert_event sae
                  JOIN todo_task tt
                    ON tt.flg_task = pk_epis_er_law_core.g_ges_todo_task
                   AND tt.flg_type = i_flg_type
                   AND tt.id_profile_template = l_prof_templ
                 WHERE sae.id_sys_alert = pk_epis_er_law_core.g_ges_sys_alert
                   AND sae.id_software = i_prof.software
                   AND sae.id_institution = i_prof.institution
                   AND sae.flg_visible = pk_alert_constant.g_yes
                   AND tt.id_institution = l_institution
                UNION ALL
                ------------------------------------
                -- discharge summary
                ------------------------------------
                SELECT pn_notes.id_patient,
                       pn_notes.id_episode,
                       NULL id_external_request,
                       pn_notes.dt_begin_tstz dt_begin_tstz_e,
                       pn_notes.flg_type,
                       pn_notes.flg_task,
                       pn_notes.icon,
                       pn_notes.flg_icon_type,
                       1 task_count,
                       CASE
                           WHEN pn_notes.task_end_date IS NOT NULL THEN
                            pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 'D', --display_type,
                                                                 'A', --flg_state,
                                                                 NULL, --value_text,
                                                                 to_char(pn_notes.task_end_date,
                                                                         pk_alert_constant.g_dt_yyyymmddhh24miss_tzr), --value_date,
                                                                 NULL, --value_icon,
                                                                 NULL, --shortcut,
                                                                 NULL, --back_color,
                                                                 NULL, --icon_color,
                                                                 NULL, --message_style,
                                                                 NULL, --message_color,
                                                                 NULL, --flg_text_domain,
                                                                 l_sysdate_tstz) --dt_server
                           ELSE
                            NULL
                       END task,
                       pn_notes.id_sys_shortcut,
                       pn_notes.flg_status flg_status_e,
                       pn_notes.id_schedule,
                       NULL text,
                       pn_notes.prof_name,
                       pn_notes.note_name,
                       decode(pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                              i_date1 => pn_notes.task_end_date,
                                                              i_date2 => l_sysdate_tstz),
                              'G',
                              abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz)),
                              'L',
                              -abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz)),
                              abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz))) time_to_sort
                  FROM (SELECT DISTINCT -- +opt_estimate (table nt rows=1)
                                        tt.id_sys_shortcut,
                                        tt.flg_type,
                                        tt.icon,
                                        tt.flg_icon_type,
                                        e.id_patient,
                                        e.id_episode,
                                        e.dt_begin_tstz,
                                        e.flg_status,
                                        ei.id_schedule,
                                        nt.flg_task,
                                        NULL prof_name,
                                        NULL note_name,
                                        nvl(d.dt_pend_tstz,
                                            nvl(d.dt_med_tstz,
                                                nvl(pk_discharge_core.get_dt_admin(i_lang,
                                                                                   i_prof,
                                                                                   NULL,
                                                                                   d.flg_status_adm,
                                                                                   d.dt_admin_tstz),
                                                    l_sysdate_tstz))) +
                                        numtodsinterval(nvl(nt.time_to_start_docum, 0), 'minute') task_end_date
                          FROM discharge d
                         CROSS JOIN TABLE((SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                                i_prof,
                                                                                d.id_episode,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                pk_prog_notes_constants.g_area_ds,
                                                                                NULL)
                                            FROM dual)) nt
                          JOIN episode e
                            ON e.id_episode = d.id_episode
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                          JOIN todo_task tt
                            ON tt.flg_task = nt.flg_task
                           AND tt.id_profile_template = l_prof_templ
                           AND tt.flg_task = l_flg_task_ds
                           AND tt.id_institution = l_institution
                         WHERE d.flg_status NOT IN
                               (pk_discharge.g_disch_flg_status_reopen, pk_discharge.g_disch_flg_status_cancel)
                           AND tt.flg_type = i_flg_type
                           AND pk_utils.search_table_number((SELECT pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                       i_prof,
                                                                                                       ei.id_episode,
                                                                                                       l_prof_cat,
                                                                                                       l_handoff_type)
                                                              FROM dual),
                                                            i_prof.id) != -1
                           AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                           AND (e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE) OR
                               l_signoff_type = g_signature_submit)
                           AND e.id_institution = i_prof.institution
                           AND ei.id_software = i_prof.software
                           AND ((NOT EXISTS (SELECT 1
                                               FROM epis_pn epn
                                              WHERE epn.id_episode = d.id_episode
                                                AND epn.id_pn_area = nt.id_pn_area
                                                AND epn.flg_status IN
                                                    (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                     pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                                     pk_prog_notes_constants.g_epis_pn_flg_status_s)) AND
                                l_signoff_type = g_signature_signoff))) pn_notes
                --discharge summary over time-to-close and has not submit to vs
                UNION ALL
                SELECT pn_notes.id_patient,
                       pn_notes.id_episode,
                       NULL id_external_request,
                       pn_notes.dt_begin_tstz dt_begin_tstz_e,
                       pn_notes.flg_type,
                       pn_notes.flg_task,
                       pn_notes.icon,
                       pn_notes.flg_icon_type,
                       1 task_count,
                       CASE
                           WHEN pn_notes.task_end_date IS NOT NULL THEN
                            pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 'D', --display_type,
                                                                 'A', --flg_state,
                                                                 NULL, --value_text,
                                                                 to_char(pn_notes.task_end_date,
                                                                         pk_alert_constant.g_dt_yyyymmddhh24miss_tzr), --value_date,
                                                                 NULL, --value_icon,
                                                                 NULL, --shortcut,
                                                                 NULL, --back_color,
                                                                 NULL, --icon_color,
                                                                 NULL, --message_style,
                                                                 NULL, --message_color,
                                                                 NULL, --flg_text_domain,
                                                                 l_sysdate_tstz) --dt_server
                           ELSE
                            NULL
                       END task,
                       pn_notes.id_sys_shortcut,
                       pn_notes.flg_status flg_status_e,
                       pn_notes.id_schedule,
                       NULL text,
                       pn_notes.prof_name,
                       pn_notes.note_name,
                       decode(pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                              i_date1 => pn_notes.task_end_date,
                                                              i_date2 => l_sysdate_tstz),
                              'G',
                              abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz)),
                              'L',
                              -abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz)),
                              abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz))) time_to_sort
                  FROM (SELECT DISTINCT t1.id_sys_shortcut,
                                        t1.flg_type,
                                        nvl2(t1.id_epis_pn,
                                             pk_sysdomain.get_img(i_lang     => i_lang,
                                                                  i_code_dom => 'EPIS_PN.FLG_STATUS',
                                                                  i_val      => t1.ep_flg_status),
                                             t1.icon) icon,
                                        t1.flg_icon_type,
                                        t1.id_patient,
                                        t1.id_episode,
                                        t1.dt_begin_tstz,
                                        t1.flg_status,
                                        t1.id_schedule,
                                        t1.flg_task,
                                        t1.id_pn_note_type,
                                        decode(l_prof_name,
                                               pk_alert_constant.g_yes,
                                               nvl2(t1.id_prof_create,
                                                    pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => t1.id_prof_create),
                                                    NULL),
                                               pk_alert_constant.g_no,
                                               NULL) prof_name,
                                        decode(l_note_name,
                                               pk_alert_constant.g_yes,
                                               pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                                      i_prof               => i_prof,
                                                                                      i_id_pn_note_type    => nvl2(t1.id_epis_pn,
                                                                                                                   t1.id_pn_note_type,
                                                                                                                   pk_prog_notes_constants.g_note_type_id_disch_sum_12),
                                                                                      i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_desc_d),
                                               pk_alert_constant.g_no,
                                               NULL) note_name,
                                        nvl(t1.dt_pend_tstz,
                                            nvl(t1.dt_med_tstz,
                                                nvl(pk_discharge_core.get_dt_admin(i_lang,
                                                                                   i_prof,
                                                                                   NULL,
                                                                                   t1.flg_status_adm,
                                                                                   t1.dt_admin_tstz),
                                                    l_sysdate_tstz))) +
                                        numtodsinterval(nvl(t1.time_to_start_docum, 0), 'minute') task_end_date
                          FROM (SELECT tt.id_sys_shortcut,
                                       tt.flg_type,
                                       tt.icon,
                                       tt.flg_icon_type,
                                       e.id_patient,
                                       e.id_episode,
                                       e.dt_begin_tstz,
                                       e.flg_status,
                                       ei.id_schedule,
                                       nt.flg_task,
                                       ep.id_epis_pn,
                                       ep.id_pn_note_type,
                                       ep.id_episode          ep_id_episode,
                                       ep.flg_status          ep_flg_status,
                                       d.dt_pend_tstz,
                                       d.dt_med_tstz,
                                       d.flg_status_adm,
                                       d.dt_admin_tstz,
                                       ep.id_prof_create,
                                       nt.time_to_start_docum
                                  FROM discharge d
                                 CROSS JOIN TABLE (SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                                        i_prof,
                                                                                        d.id_episode,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        pk_prog_notes_constants.g_area_ds,
                                                                                        NULL)
                                                    FROM dual) nt
                                  JOIN episode e
                                    ON e.id_episode = d.id_episode
                                  JOIN epis_info ei
                                    ON e.id_episode = ei.id_episode
                                  LEFT OUTER JOIN (SELECT epn.*
                                                    FROM epis_pn epn
                                                   INNER JOIN episode epis
                                                      ON epis.id_episode = epn.id_episode
                                                   WHERE epis.id_institution = i_prof.institution
                                                     AND epn.id_pn_note_type =
                                                         pk_prog_notes_constants.g_note_type_id_disch_sum_12
                                                     AND epn.flg_status <> pk_alert_constant.g_cancelled
                                                     AND epis.flg_status <> pk_alert_constant.g_cancelled) ep
                                    ON e.id_episode = ep.id_episode
                                  JOIN todo_task tt
                                    ON tt.flg_task = nt.flg_task
                                   AND tt.id_profile_template = l_prof_templ
                                   AND tt.flg_task = l_flg_task_ds
                                   AND tt.id_institution = l_institution
                                 WHERE d.flg_status NOT IN
                                       (pk_discharge.g_disch_flg_status_reopen, pk_discharge.g_disch_flg_status_cancel)
                                   AND tt.flg_type = i_flg_type
                                   AND pk_utils.search_table_number((SELECT pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                               i_prof,
                                                                                                               ei.id_episode,
                                                                                                               l_prof_cat,
                                                                                                               l_handoff_type)
                                                                      FROM dual),
                                                                    i_prof.id) != -1
                                   AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                                   AND e.id_institution = i_prof.institution
                                   AND ei.id_software = i_prof.software
                                   AND l_note_name = pk_alert_constant.g_yes
                                   AND ei.id_professional = i_prof.id
                                   AND rownum > 0) t1
                         WHERE (t1.ep_id_episode IS NULL OR --has not written discharge summary
                               (t1.ep_flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_d AND --discharge summary is draft and over time-to-close
                               (l_sysdate_tstz - (nvl(t1.dt_pend_tstz,
                                                        nvl(t1.dt_med_tstz,
                                                            nvl((SELECT pk_discharge_core.get_dt_admin(i_lang,
                                                                                                      i_prof,
                                                                                                      NULL,
                                                                                                      t1.flg_status_adm,
                                                                                                      t1.dt_admin_tstz)
                                                                  FROM dual),
                                                                l_sysdate_tstz))))) >
                               pk_prog_notes_utils.gen_time_to_close(i_lang,
                                                                       i_prof,
                                                                       t1.id_episode,
                                                                       pk_prog_notes_constants.g_note_type_id_disch_sum_12)))) pn_notes
                UNION ALL
                SELECT cr.id_patient,
                       cr.id_episode,
                       NULL id_external_request,
                       cr.dt_begin_tstz dt_begin_tstz_e,
                       tt.flg_type,
                       tt.flg_task,
                       tt.icon,
                       tt.flg_icon_type,
                       (SELECT COUNT(1)
                          FROM opinion o
                         WHERE o.id_episode = cr.id_episode
                           AND o.flg_state = pk_opinion.g_opinion_req
                           AND o.id_opinion_type IS NULL
                           AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending) OR
                               (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) task_count,
                       NULL task,
                       tt.id_sys_shortcut,
                       cr.flg_status flg_status_e,
                       cr.id_schedule,
                       NULL text,
                       NULL prof_name,
                       NULL note_name,
                       NULL time_to_sort
                  FROM todo_task tt,
                       (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                          FROM opinion o
                          JOIN episode e
                            ON o.id_episode = e.id_episode
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                         WHERE o.flg_state = pk_opinion.g_opinion_req
                           AND o.id_opinion_type IS NULL
                           AND e.id_institution = i_prof.institution
                           AND e.flg_status = pk_alert_constant.g_epis_status_active
                           AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                           AND ei.id_software = i_prof.software
                           AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending) OR
                               (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) cr
                 WHERE tt.flg_task = g_task_cr
                   AND tt.flg_type = i_flg_type
                   AND tt.id_profile_template = l_prof_templ
                   AND tt.id_institution = l_institution
                UNION ALL
                -- HAND OFF
                SELECT tr.id_patient,
                       tr.id_episode,
                       NULL id_external_request,
                       tr.dt_begin_tstz dt_begin_tstz_e,
                       tt.flg_type,
                       tt.flg_task,
                       tt.icon,
                       tt.flg_icon_type,
                       (SELECT COUNT(1)
                          FROM epis_prof_resp epr
                         WHERE epr.id_episode = tr.id_episode
                           AND epr.flg_status = pk_hand_off.g_hand_off_r
                           AND ((epr.id_prof_to = i_prof.id AND i_flg_type = g_pending) OR
                               (epr.id_prof_req = i_prof.id AND i_flg_type = g_depending))) task_count,
                       NULL task,
                       tt.id_sys_shortcut,
                       tr.flg_status flg_status_e,
                       tr.id_schedule,
                       NULL text,
                       NULL prof_name,
                       NULL note_name,
                       NULL time_to_sort
                  FROM todo_task tt,
                       (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                          FROM epis_prof_resp epr
                          JOIN episode e
                            ON epr.id_episode = e.id_episode
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                         WHERE epr.flg_status = pk_hand_off.g_hand_off_r
                           AND e.id_institution = i_prof.institution
                           AND e.flg_status = pk_alert_constant.g_epis_status_active
                           AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                           AND ei.id_software = i_prof.software
                           AND ((epr.id_prof_to = i_prof.id AND i_flg_type = g_pending) OR
                               (epr.id_prof_req = i_prof.id AND i_flg_type = g_depending))) tr
                 WHERE tt.flg_task = g_task_tr
                   AND tt.flg_type = i_flg_type
                   AND tt.id_profile_template = l_prof_templ
                   AND tt.id_institution = l_institution) t
        -- Obter apenas os episodios com tarefas pendentes
         WHERE t.task_count > 0;
    
        RETURN tbl_return;
    
    END get_prof_task_base01;

    FUNCTION get_epis_task_count_aux
    (
        i_lang                    IN NUMBER,
        i_prof                    IN profissional,
        i_prof_cat                IN VARCHAR2,
        i_id_episode              IN NUMBER,
        i_id_patient              IN NUMBER,
        i_id_visit                IN NUMBER,
        i_flg_type                IN VARCHAR2,
        i_flg_task                IN VARCHAR2,
        i_epis_flg_status         IN VARCHAR2,
        i_flg_analysis_req        IN VARCHAR2,
        i_flg_exam_req            IN VARCHAR2,
        i_flg_monitorization      IN VARCHAR2,
        i_flg_presc_med           IN VARCHAR2,
        i_flg_drug_req            IN VARCHAR2,
        i_flg_interv_prescription IN VARCHAR2,
        i_flg_nurse_activity_req  IN VARCHAR2
    ) RETURN NUMBER IS
    
        l_bool            BOOLEAN := FALSE;
        l_return          NUMBER := 0;
        l_epis_flg_status VARCHAR2(0100 CHAR);
    
    BEGIN
    
        l_epis_flg_status := NULL;
    
        CASE i_flg_task
            WHEN g_task_a THEN
                l_bool := i_flg_analysis_req = 'Y';
            WHEN g_task_h THEN
                l_bool := i_flg_analysis_req = 'Y';
            WHEN g_task_e THEN
                l_bool := i_flg_exam_req = 'Y';
            WHEN g_task_ie THEN
                l_bool := i_flg_exam_req = 'Y';
            WHEN g_task_m THEN
                l_bool := i_flg_monitorization = 'Y';
            WHEN g_task_dp THEN
                CASE i_flg_type
                    WHEN g_pending THEN
                        l_bool := i_flg_presc_med = 'Y';
                    WHEN g_depending THEN
                        l_bool := i_flg_drug_req = 'Y';
                    ELSE
                        l_bool := FALSE;
                END CASE;
            WHEN g_task_pr THEN
                l_bool := i_flg_interv_prescription = 'Y';
            WHEN g_task_b THEN
                l_bool := i_flg_nurse_activity_req = 'Y';
            WHEN g_task_mt THEN
                l_bool := i_flg_drug_req = 'Y';
            WHEN g_task_ht THEN
                l_bool := i_flg_analysis_req = 'Y';
            
            ELSE
                l_bool            := TRUE;
                l_epis_flg_status := i_epis_flg_status;
        END CASE;
    
        IF l_bool
        THEN
            l_return := get_epis_task_count(i_lang,
                                            i_prof,
                                            i_prof_cat,
                                            i_flg_task,
                                            i_id_episode,
                                            i_id_patient,
                                            i_id_visit,
                                            i_flg_type,
                                            l_epis_flg_status);
        END IF;
    
        RETURN l_return;
    
    END get_epis_task_count_aux;

    FUNCTION get_prof_tasks_transform
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat      IN category.flg_type%TYPE,
        i_flg_type      IN todo_task.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_tbl_data      IN todo_list_01_tbl
    ) RETURN t_todo_list_tbl IS
    
        l_flg_desc VARCHAR2(2 CHAR);
    
        err_exception EXCEPTION;
    
        l_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    
        l_handoff_type sys_config.value%TYPE;
        l_type_opinion opinion_type.id_opinion_type%TYPE;
        l_category     category.id_category%TYPE;
    
        l_display_age VARCHAR2(1 CHAR);
    
        CURSOR c_type_request IS
            SELECT ot.id_opinion_type
              FROM opinion_type ot
             WHERE ot.id_category = l_category;
    
        tbl_return t_todo_list_tbl;
    
    BEGIN
    
        l_sysdate_tstz := current_timestamp;
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        /* Seleccionar tipo de filtro de episodios conforme o perfil e o produto
        * P - Proprios pacientes;
        * S - Pacientes nas salas do profissional;
        * C - Pacientes do tipo de consulta a que o profissional esta associado;
        * H - Pacientes para hoje (nao esta a ser usado);
        * T - Todos os pacientes. Sem filtro.
        */
    
        --define the professional categories that receives the tranfer institution tasks
        --it is used the id_category because of the midwife profiles that has a specific category with the nurse flg_category
        g_error := 'GET_CONFIG';
        --l_config_ti_cats := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_CAT_TRANSF_INST', i_prof => i_prof);
    
        -- Define os casos em que a alta medica inactiva os episodios para que o administrativo possa ver tarefas associadas a esses episodios
        -- (nomeadamente necessidade de dar alta administrativa)
        -- Para ja e so o caso do CARE mas podem ser definidos outros casos
    
        /* Seleccionar o tipo de descricao a surgir por baixo do nome do paciente
        * C - Queixa principal;
        * R - Registo clinico;
        * S - Cirurgia proposta;
        * D - Diagnostico;
        * O - Outros.
        */
        l_flg_desc := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_DESC_TYP', i_prof => i_prof);
    
        g_error    := 'GET PROF CATEGORY';
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'OPEN C_TYPE_REQUEST';
        OPEN c_type_request;
        FETCH c_type_request
            INTO l_type_opinion;
        CLOSE c_type_request;
    
        l_display_age := pk_sysconfig.get_config(i_code_cf => 'DEFAULT_PAT_AGE_DISPLAY', i_prof => i_prof);
    
        g_error := 'GET CURSOR O_TASKS 1';
        SELECT /*+ use_nl(p t) */
         t_todo_list_rec(id_patient          => t.id_patient,
                          id_episode          => t.id_episode,
                          id_external_request => t.id_external_request,
                          id_schedule         => t.id_schedule,
                          gender              => pk_patient.get_gender(i_lang, p.gender),
                          age                 => decode(l_display_age,
                                                        pk_alert_constant.g_no,
                                                        NULL,
                                                        (SELECT pk_patient.get_pat_age(i_lang,
                                                                                       p.dt_birth,
                                                                                       p.age,
                                                                                       i_prof.institution,
                                                                                       i_prof.software)
                                                           FROM dual)),
                          photo               => (SELECT pk_patphoto.get_pat_photo(i_lang,
                                                                                   i_prof,
                                                                                   t.id_patient,
                                                                                   t.id_episode,
                                                                                   t.id_schedule)
                                                    FROM dual),
                          name                => pk_patient.get_pat_name(i_lang, i_prof, t.id_patient, t.id_episode),
                          -- ALERT-102882 Patient name used for sorting
                          name_pat_sort   => pk_patient.get_pat_name_to_sort(i_lang,
                                                                             i_prof,
                                                                             t.id_patient,
                                                                             t.id_episode,
                                                                             t.id_schedule),
                          pat_ndo         => pk_adt.get_pat_non_disc_options(i_lang, i_prof, t.id_patient),
                          pat_nd_icon     => pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, t.id_patient),
                          dt_begin        => pk_date_utils.date_send_tsz(i_lang, t.dt_begin_tstz_e, i_prof),
                          dt_begin_extend => pk_date_utils.date_hour_chr_extend_tsz(i_lang, t.dt_begin_tstz_e, i_prof),
                          -- Descritivo que surge por baixo do nome do paciente. Varia conforme o produto.
                          description => decode(l_flg_desc,
                                                'C',
                                                pk_edis_grid.get_complaint_grid(i_lang, i_prof, t.id_episode),
                                                'R',
                                                (SELECT cr.num_clin_record
                                                   FROM clin_record cr
                                                  WHERE cr.id_patient = t.id_patient
                                                    AND cr.id_institution = i_prof.institution
                                                    AND rownum < 2),
                                                'S',
                                                pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                                         t.id_episode,
                                                                                         i_prof,
                                                                                         pk_alert_constant.g_no),
                                                'D',
                                                pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, t.id_episode),
                                                'O',
                                                NULL),
                          flg_type    => t.flg_type,
                          flg_task    => t.flg_task,
                          task_icon   => t.icon,
                          icon_type   => t.flg_icon_type,
                          task_count  => t.task_count,
                          task        => nvl(t.task,
                                             CASE
                                                 WHEN t.flg_task = 'SO'
                                                      AND i_flg_type = g_pending THEN
                                                  pk_utils.get_status_string_immediate(i_lang,
                                                                                       i_prof,
                                                                                       'D', --display_type,
                                                                                       'A', --flg_state,
                                                                                       NULL, --value_text,
                                                                                       pk_date_utils.date_send_tsz(i_lang, t.dt_begin_tstz_e, i_prof), --value_date,
                                                                                       NULL, --value_icon,
                                                                                       NULL, --shortcut,
                                                                                       NULL, --back_color,
                                                                                       NULL, --icon_color,
                                                                                       NULL, --message_style,
                                                                                       NULL, --message_color,
                                                                                       NULL, --flg_text_domain,
                                                                                       l_sysdate_tstz) --dt_server
                                                 WHEN t.flg_task = 'CO'
                                                      AND i_flg_type = g_pending
                                                      AND i_prof.software = pk_alert_constant.g_soft_private_practice THEN
                                                  pk_utils.get_status_string_immediate(i_lang,
                                                                                       i_prof,
                                                                                       'D', --display_type,
                                                                                       'A', --flg_state,
                                                                                       NULL, --value_text,
                                                                                       pk_todo_list.get_submit_cosign_date(i_lang, i_prof, t.id_episode), --value_date,
                                                                                       NULL, --value_icon,
                                                                                       NULL, --shortcut,
                                                                                       NULL, --back_color,
                                                                                       NULL, --icon_color,
                                                                                       NULL, --message_style,
                                                                                       NULL, --message_color,
                                                                                       NULL, --flg_text_domain,
                                                                                       l_sysdate_tstz) --dt_server
                                                 ELSE
                                                  pk_utils.get_status_string_immediate(i_lang,
                                                                                       i_prof,
                                                                                       'T', --display_type,
                                                                                       'A', --flg_state,
                                                                                       to_char(t.task_count), --value_text,
                                                                                       NULL, --value_date,
                                                                                       NULL, --value_icon,
                                                                                       NULL, --shortcut,
                                                                                       '0xc86464', --back_color,
                                                                                       NULL, --icon_color,
                                                                                       'WorkflowTime', --message_style,
                                                                                       NULL, --message_color,
                                                                                       NULL, --flg_text_domain,
                                                                                       l_sysdate_tstz) --dt_server
                                             END),
                          shortcut    => decode(pk_sign_off.get_epis_sign_off_state(i_lang, i_prof, t.id_episode),
                                                pk_alert_constant.g_no,
                                                t.id_sys_shortcut,
                                                decode(t.flg_task,
                                                       'A',
                                                       pk_sign_off.g_so_ss_lab,
                                                       'E',
                                                       pk_sign_off.g_so_ss_exam,
                                                       'IE',
                                                       pk_sign_off.g_so_ss_imag,
                                                       'I',
                                                       pk_sign_off.g_so_ss_pend_issues,
                                                       pk_sign_off.g_so_addendum)),
                          flg_status  => t.flg_status_e,
                          dt_co_sign  => decode(t.flg_task,
                                                'CO',
                                                decode(i_prof.software,
                                                       g_soft_pp,
                                                       pk_todo_list.get_submit_cosign_date(i_lang, i_prof, t.id_episode),
                                                       NULL),
                                                NULL),
                          dt_server   => g_dt_server,
                          resp_icons  => decode(i_prof_cat,
                                                g_prof_cat_d,
                                                (SELECT pk_hand_off_api.get_resp_icons(i_lang,
                                                                                       i_prof,
                                                                                       t.id_episode,
                                                                                       i_hand_off_type)
                                                   FROM dual),
                                                CAST(NULL AS table_varchar)),
                          --ASantos table_varchar)            --ALERT-195554 - Chile | Ability to interface information regarding management of GES
                          url_ges_ext_app => CASE
                                                 WHEN t.flg_task = pk_epis_er_law_core.g_ges_todo_task THEN
                                                  pk_epis_er_law_api.get_ges_url(i_lang => i_lang, i_prof => i_prof, i_patient => t.id_patient)
                                                 ELSE
                                                  NULL
                                             END,
                          prof_name       => t.prof_name,
                          note_name       => t.note_name,
                          time_to_sort    => t.time_to_sort)
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT *
                  FROM TABLE(i_tbl_data)) t
          JOIN patient p
            ON p.id_patient = t.id_patient
         ORDER BY p.name;
    
        RETURN tbl_return;
    
    END get_prof_tasks_transform;

    FUNCTION get_prof_task_base02
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_flg_type IN todo_task.flg_type%TYPE
    ) RETURN todo_list_01_tbl IS
    
        l_flg_id       VARCHAR2(0010 CHAR);
        l_category     category.id_category%TYPE;
        l_prof_cat     category.flg_type%TYPE;
        l_prof_templ   todo_task.id_profile_template%TYPE;
        l_institution  NUMBER;
        l_type_opinion opinion_type.id_opinion_type%TYPE;
        l_signoff_type sys_config.value%TYPE;
        l_prof_name    VARCHAR2(1 CHAR);
        l_note_name    VARCHAR2(1 CHAR);
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_handoff_type sys_config.value%TYPE;
        l_flg_task_ds  todo_task.flg_task%TYPE := 'DS';
    
        tbl_return todo_list_01_tbl := todo_list_01_tbl();
    
    BEGIN
    
        l_sysdate_tstz := current_timestamp;
    
        l_flg_id   := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_' || i_prof_cat, i_prof => i_prof);
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        l_signoff_type := pk_sysconfig.get_config(i_code_cf => 'NOTE_SIGNATURE_MECHANISM', i_prof => i_prof);
        l_prof_name    := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_PROF_NAME', i_prof => i_prof);
        l_note_name    := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_NOTE_NAME', i_prof => i_prof);
    
        l_prof_templ  := pk_tools.get_prof_profile_template(i_prof => i_prof);
        l_institution := get_config_vars(i_prof => i_prof, i_profile => l_prof_templ);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        l_type_opinion := get_opinion_type(l_category);
    
        IF l_flg_id IS NULL
        THEN
            l_flg_id := pk_sysconfig.get_config(i_code_cf => 'TODO_LIST_ALL', i_prof => i_prof);
        END IF;
    
        SELECT todo_list_01_rec(id_patient          => t.id_patient,
                                id_episode          => t.id_episode,
                                id_visit            => NULL,
                                id_external_request => t.id_external_request,
                                dt_begin_tstz_e     => t.dt_begin_tstz,
                                flg_type            => t.flg_type,
                                flg_task            => t.flg_task,
                                icon                => t.icon,
                                flg_icon_type       => t.flg_icon_type,
                                task_count          => t.task_count,
                                task                => t.task,
                                id_sys_shortcut     => t.id_sys_shortcut,
                                flg_status_e        => t.flg_status,
                                id_schedule         => t.id_schedule,
                                text                => t.text,
                                prof_name           => t.prof_name,
                                note_name           => t.note_name,
                                time_to_sort        => t.time_to_sort)
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT epis.id_patient,
                        epis.id_episode,
                        NULL id_external_request,
                        epis.dt_begin_tstz,
                        tt.flg_type,
                        tt.flg_task,
                        tt.icon,
                        tt.flg_icon_type,
                        pk_todo_list.get_epis_task_count_aux(i_lang                    => i_lang,
                                                             i_prof                    => i_prof,
                                                             i_prof_cat                => i_prof_cat,
                                                             i_id_episode              => epis.id_episode,
                                                             i_id_patient              => epis.id_patient,
                                                             i_id_visit                => epis.id_visit,
                                                             i_flg_type                => i_flg_type,
                                                             i_flg_task                => tt.flg_task,
                                                             i_epis_flg_status         => epis.flg_status,
                                                             i_flg_analysis_req        => awv.flg_analysis_req,
                                                             i_flg_exam_req            => awv.flg_exam_req,
                                                             i_flg_monitorization      => awv.flg_monitorization,
                                                             i_flg_presc_med           => awv.flg_presc_med,
                                                             i_flg_drug_req            => awv.flg_drug_req,
                                                             i_flg_interv_prescription => awe.flg_interv_prescription,
                                                             i_flg_nurse_activity_req  => awe.flg_nurse_activity_req) task_count,
                        NULL task,
                        tt.id_sys_shortcut,
                        epis.flg_status,
                        epis.id_schedule,
                        NULL text,
                        NULL prof_name,
                        NULL note_name,
                        NULL time_to_sort
                   FROM todo_task tt,
                        (SELECT id_patient,
                                id_episode,
                                flg_episode,
                                flg_pat_allergy,
                                flg_pat_habit,
                                flg_pat_history_diagnosis,
                                flg_vital_sign_read,
                                flg_epis_diagnosis,
                                flg_interv_prescription,
                                flg_nurse_activity_req,
                                flg_icnp_epis_diagnosis,
                                flg_icnp_epis_intervention,
                                flg_pat_pregnancy,
                                flg_sys_alert_det,
                                flg_presc_med
                           FROM awareness) awe,
                        (SELECT id_patient,
                                id_visit,
                                MAX(flg_analysis_req) flg_analysis_req,
                                MAX(flg_exam_req) flg_exam_req,
                                MAX(flg_monitorization) flg_monitorization,
                                MAX(flg_prescription) flg_prescription,
                                MAX(flg_drug_req) flg_drug_req,
                                MAX(flg_presc_med) flg_presc_med
                           FROM awareness
                          GROUP BY id_visit, id_patient) awv,
                        prof_profile_template ppt,
                        (SELECT e.id_patient,
                                e.id_episode,
                                ei.id_software,
                                e.id_visit,
                                e.id_institution,
                                ei.id_professional,
                                ei.id_first_nurse_resp,
                                e.dt_begin_tstz,
                                e.flg_status,
                                e.id_epis_type,
                                ei.id_schedule
                           FROM episode e, epis_info ei
                         -- Devolver resultados de episodios ACTIVOS e INACTIVOS
                          WHERE e.flg_status IN ('A', 'P', 'I')
                            AND e.id_episode = ei.id_episode
                            AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                            AND ((l_flg_id = 'C' AND EXISTS
                                 (SELECT 0
                                     FROM prof_dep_clin_serv pdcs, schedule s
                                    WHERE pdcs.id_dep_clin_serv = nvl(ei.id_dep_clin_serv, s.id_dcs_requested)
                                      AND s.id_schedule(+) = ei.id_schedule
                                      AND pdcs.id_professional = i_prof.id
                                      AND pdcs.flg_status = 'S')) OR l_flg_id != 'C')
                            AND ((l_flg_id = 'S' AND EXISTS (SELECT 0
                                                               FROM prof_room pr
                                                              WHERE pr.id_professional = i_prof.id
                                                                AND ei.id_room = pr.id_room)) OR l_flg_id != 'S')
                               /*Usado para perfis que queiram ver os episodios agendados para hoje*/
                               --AND ((l_flg_id = 'H' AND e.flg_ehr = 'S' AND
                               --    ei.id_schedule IN (SELECT s.id_schedule
                               --                         FROM schedule s, schedule_outp sp
                               --                        WHERE s.id_schedule = sp.id_schedule
                               --                          AND sp.dt_target BETWEEN trunc(current_timestamp) AND
                               --                              trunc(current_timestamp + INTERVAL '1' DAY)
                               --                          AND s.flg_status != 'C')) OR e.flg_ehr = g_flg_ehr_n)
                            AND e.flg_ehr = g_flg_ehr_n) epis
                  WHERE ppt.id_profile_template = tt.id_profile_template
                    AND epis.id_institution = ppt.id_institution
                    AND (epis.id_software = ppt.id_software OR i_prof.software = g_soft_adt)
                    AND (SELECT pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution)
                           FROM dual) = epis.id_software
                    AND ppt.id_professional = i_prof.id
                    AND ppt.id_institution = i_prof.institution
                    AND ppt.id_software = i_prof.software
                    AND tt.flg_type = i_flg_type
                    AND epis.id_institution = i_prof.institution
                    AND awe.id_patient = epis.id_patient
                    AND awe.id_episode = epis.id_episode
                    AND awv.id_patient = epis.id_patient
                    AND awv.id_visit = epis.id_visit
                    AND tt.id_institution = l_institution
                 -- PENDING ISSUES - ACTIVE AND INACTIVE EPISODES
                 -- All episodes with pending issues assigned to the current professional
                 UNION ALL
                 SELECT e.id_patient,
                        e.id_episode,
                        NULL             id_external_request,
                        e.dt_begin_tstz  dt_begin_tstz_e,
                        tt.flg_type,
                        tt.flg_task,
                        tt.icon,
                        tt.flg_icon_type,
                        -- Count number of pending issues assigned to I_PROF
                        (SELECT COUNT(*)
                           FROM pending_issue pi
                          WHERE EXISTS (SELECT pip.id_pending_issue
                                   FROM pending_issue_prof pip
                                  WHERE pip.id_professional = i_prof.id
                                    AND pip.id_pending_issue = pi.id_pending_issue)
                            AND pi.id_episode = e.id_episode
                            AND pi.flg_status NOT IN ('C', 'X')) task_count,
                        NULL task,
                        tt.id_sys_shortcut,
                        e.flg_status flg_status_e,
                        ei.id_schedule,
                        NULL text,
                        NULL prof_name,
                        NULL note_name,
                        NULL time_to_sort
                   FROM (SELECT ee.flg_status,
                                ee.id_episode,
                                ee.id_institution,
                                dt_begin_tstz,
                                ee.id_patient,
                                rank() over(PARTITION BY ee.id_episode ORDER BY pi.dt_creation DESC) rn
                           FROM episode ee
                           JOIN pending_issue pi
                             ON pi.id_episode = ee.id_episode
                          WHERE EXISTS (SELECT pip.id_pending_issue
                                   FROM pending_issue_prof pip
                                  WHERE pip.id_professional = i_prof.id
                                    AND pip.id_pending_issue = pi.id_pending_issue)) e,
                        epis_info ei,
                        prof_profile_template ppt,
                        todo_task tt
                  WHERE e.id_episode = ei.id_episode
                    AND ppt.id_institution = e.id_institution
                    AND ppt.id_profile_template = tt.id_profile_template
                    AND ppt.id_professional = i_prof.id
                    AND ppt.id_institution = i_prof.institution
                    AND ppt.id_software = i_prof.software
                    AND tt.flg_type = i_flg_type
                    AND tt.flg_task = 'I' -- IMPORTANT: PENDING ISSUES ONLY!!
                    AND e.id_institution = i_prof.institution
                    AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                    AND (ei.id_software = i_prof.software OR i_prof.software = g_soft_nutri OR
                        i_prof.software = pk_alert_constant.g_soft_pharmacy OR i_prof.software = g_soft_adt)
                    AND e.flg_status <> 'C'
                    AND e.rn = 1
                    AND tt.id_institution = l_institution
                 -- follow-up requests pending approval
                 UNION ALL
                 SELECT fur.id_patient,
                        fur.id_episode,
                        NULL               id_external_request,
                        fur.dt_begin_tstz  dt_begin_tstz_e,
                        tt.flg_type,
                        tt.flg_task,
                        tt.icon,
                        tt.flg_icon_type,
                        1                  task_count,
                        NULL               task,
                        tt.id_sys_shortcut,
                        fur.flg_status     flg_status_e,
                        fur.id_schedule,
                        NULL               text,
                        NULL               prof_name,
                        NULL               note_name,
                        NULL               time_to_sort
                   FROM todo_task tt,
                        (SELECT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                           FROM opinion o
                           JOIN episode e
                             ON o.id_episode_approval = e.id_episode
                           JOIN epis_info ei
                             ON e.id_episode = ei.id_episode
                          WHERE o.flg_state = pk_opinion.g_opinion_req
                            AND o.id_opinion_type IS NOT NULL
                            AND o.id_episode_approval IS NOT NULL
                            AND e.id_institution = i_prof.institution
                            AND e.id_epis_type IN
                                (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient)
                            AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                            AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                            AND pk_patient.get_prof_resp(i_lang, i_prof, e.id_patient, e.id_episode) = pk_adt.g_true
                            AND ei.id_software = i_prof.software) fur
                  WHERE tt.flg_task = g_task_fu
                    AND tt.flg_type = i_flg_type
                    AND tt.flg_type = g_pending
                    AND tt.id_profile_template = l_prof_templ
                    AND tt.id_institution = l_institution
                 -- FU Requested
                 UNION ALL
                 SELECT fur.id_patient,
                        fur.id_episode,
                        NULL id_external_request,
                        fur.dt_begin_tstz dt_begin_tstz_e,
                        tt.flg_type,
                        tt.flg_task,
                        tt.icon,
                        tt.flg_icon_type,
                        (SELECT COUNT(1)
                           FROM opinion o
                          WHERE o.id_episode = fur.id_episode
                            AND o.id_opinion_type IS NOT NULL
                            AND (o.flg_state = pk_opinion.g_opinion_approved OR
                                (o.flg_state = pk_opinion.g_opinion_req AND o.id_episode_approval IS NULL))
                               
                            AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending AND
                                o.id_opinion_type = l_type_opinion) OR
                                (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) task_count,
                        NULL task,
                        tt.id_sys_shortcut,
                        fur.flg_status flg_status_e,
                        fur.id_schedule,
                        NULL text,
                        NULL prof_name,
                        NULL note_name,
                        NULL time_to_sort
                   FROM todo_task tt,
                        (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                           FROM opinion o
                           JOIN episode e
                             ON o.id_episode = e.id_episode
                           JOIN epis_info ei
                             ON e.id_episode = ei.id_episode
                          WHERE o.id_opinion_type IS NOT NULL
                            AND e.id_institution = i_prof.institution
                            AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                            AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                            AND (o.flg_state = pk_opinion.g_opinion_approved OR
                                (o.flg_state = pk_opinion.g_opinion_req AND o.id_episode_approval IS NULL))
                            AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending AND
                                o.id_opinion_type = l_type_opinion) OR
                                (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending AND
                                ei.id_software = i_prof.software))) fur
                  WHERE tt.flg_task = g_task_fu
                    AND tt.flg_type = i_flg_type
                    AND tt.id_profile_template = l_prof_templ
                    AND tt.id_institution = l_institution
                 UNION ALL
                 SELECT e.id_patient,
                        e.id_episode,
                        NULL               id_external_request,
                        e.dt_begin_tstz    dt_begin_tstz_e,
                        tt.flg_type,
                        tt.flg_task,
                        tt.icon,
                        tt.flg_icon_type,
                        1                  task_count,
                        NULL               task,
                        tt.id_sys_shortcut,
                        e.flg_status       flg_status_e,
                        ei.id_schedule,
                        NULL               text,
                        NULL               prof_name,
                        NULL               note_name,
                        NULL               time_to_sort
                   FROM therapeutic_decision     t,
                        therapeutic_decision_det td,
                        epis_info                ei,
                        episode                  e,
                        todo_task                tt,
                        prof_profile_template    ppt
                  WHERE td.id_professional = i_prof.id
                    AND nvl(td.flg_opinion, 'N') = 'N'
                    AND td.flg_status = 'A'
                    AND td.flg_presence = 'P'
                    AND t.id_therapeutic_decision = td.id_therapeutic_decision
                    AND t.flg_status = 'A'
                    AND t.id_episode = ei.id_episode
                    AND e.id_episode = ei.id_episode
                    AND e.id_institution = i_prof.institution
                    AND e.flg_status <> 'C'
                    AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                    AND tt.flg_type = i_flg_type
                    AND tt.flg_task = g_task_td
                    AND ppt.id_institution = e.id_institution
                    AND ppt.id_profile_template = tt.id_profile_template
                    AND ppt.id_professional = i_prof.id
                    AND ppt.id_institution = i_prof.institution
                    AND ppt.id_software = i_prof.software
                    AND tt.id_institution = l_institution
                 UNION ALL
                 --progress notes and history and physical
                 SELECT pn_notes.id_patient,
                        pn_notes.id_episode,
                        NULL id_external_request,
                        pn_notes.dt_begin_tstz dt_begin_tstz_e,
                        pn_notes.flg_type,
                        pn_notes.flg_task,
                        pn_notes.icon,
                        pn_notes.flg_icon_type,
                        1 task_count,
                        CASE
                            WHEN pn_notes.task_end_date IS NOT NULL THEN
                             pk_utils.get_status_string_immediate(i_lang,
                                                                  i_prof,
                                                                  'D', --display_type,
                                                                  'A', --flg_state,
                                                                  NULL, --value_text,
                                                                  to_char(pn_notes.task_end_date,
                                                                          pk_alert_constant.g_dt_yyyymmddhh24miss_tzr), --value_date,
                                                                  NULL, --value_icon,
                                                                  NULL, --shortcut,
                                                                  NULL, --back_color,
                                                                  NULL, --icon_color,
                                                                  NULL, --message_style,
                                                                  NULL, --message_color,
                                                                  NULL, --flg_text_domain,
                                                                  l_sysdate_tstz) --dt_server
                            ELSE
                             NULL
                        END task,
                        pn_notes.id_sys_shortcut,
                        pn_notes.flg_status flg_status_e,
                        pn_notes.id_schedule,
                        NULL text,
                        pn_notes.prof_name,
                        pn_notes.note_name,
                        decode(pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                               i_date1 => pn_notes.task_end_date,
                                                               i_date2 => l_sysdate_tstz),
                               'G',
                               abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                    i_timestamp_2 => l_sysdate_tstz)),
                               'L',
                               -abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                     i_timestamp_2 => l_sysdate_tstz)),
                               abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                    i_timestamp_2 => l_sysdate_tstz))) time_to_sort
                   FROM (SELECT DISTINCT --/*+opt_estimate (table nt rows=1)
                                         tt.id_sys_shortcut,
                                         tt.flg_type,
                                         tt.icon,
                                         tt.flg_icon_type,
                                         e.id_patient,
                                         e.id_episode,
                                         e.dt_begin_tstz,
                                         e.flg_status,
                                         ei.id_schedule,
                                         nt.flg_task,
                                         decode(nt.flg_task,
                                                'DS',
                                                nvl(pk_discharge.get_discharge_date(i_lang       => i_lang,
                                                                                    i_prof       => i_prof,
                                                                                    i_id_episode => epn.id_episode),
                                                    epn.dt_pn_date) +
                                                numtodsinterval(nvl(nt.time_to_start_docum, 0), 'minute'),
                                                pk_prog_notes_utils.get_end_task_time(i_lang    => i_lang,
                                                                                      i_prof    => i_prof,
                                                                                      i_episode => epn.id_episode,
                                                                                      i_epis_pn => epn.id_epis_pn)) task_end_date,
                                         decode(l_note_name,
                                                pk_alert_constant.g_yes,
                                                pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                                       i_prof               => i_prof,
                                                                                       i_id_pn_note_type    => epn.id_pn_note_type,
                                                                                       i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_desc_d),
                                                pk_alert_constant.g_no,
                                                NULL) note_name,
                                         decode(l_prof_name,
                                                pk_alert_constant.g_yes,
                                                pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => epn.id_prof_create),
                                                pk_alert_constant.g_no,
                                                NULL) prof_name
                           FROM epis_pn epn
                           JOIN episode e
                             ON e.id_episode = epn.id_episode
                           JOIN epis_info ei
                             ON e.id_episode = ei.id_episode
                           JOIN TABLE((SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                            i_prof,
                                                                            epn.id_episode,
                                                                            NULL,
                                                                            NULL,
                                                                            epn.id_dep_clin_serv,
                                                                            NULL,
                                                                            NULL)
                                        FROM dual)) nt
                             ON nt.id_pn_area = epn.id_pn_area
                           JOIN todo_task tt
                             ON tt.flg_task = nt.flg_task
                          WHERE tt.flg_type = i_flg_type
                            AND tt.id_profile_template = l_prof_templ
                            AND tt.id_institution = l_institution
                            AND ((epn.flg_status IN (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                     pk_prog_notes_constants.g_epis_pn_flg_status_t) AND
                                e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE) AND
                                epn.id_prof_create = i_prof.id AND l_signoff_type = g_signature_signoff) OR
                                (epn.flg_status = pk_prog_notes_constants.g_epis_pn_flg_for_review AND
                                ei.id_professional = i_prof.id AND l_signoff_type = g_signature_submit))
                            AND ((l_signoff_type = g_signature_signoff AND epn.id_prof_create = i_prof.id) OR
                                (l_signoff_type = g_signature_submit AND ei.id_professional = i_prof.id))
                            AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                            AND e.id_institution = i_prof.institution
                            AND ei.id_software = i_prof.software) pn_notes
                 --admission note is over time-to-close and has not submitted to VS and it's multi-hand off
                UNION ALL
                SELECT pn_notes.id_patient,
                       pn_notes.id_episode,
                       NULL id_external_request,
                       pn_notes.dt_begin_tstz dt_begin_tstz_e,
                       pn_notes.flg_type,
                       pn_notes.flg_task,
                       pn_notes.icon,
                       pn_notes.flg_icon_type,
                       1 task_count,
                       CASE
                           WHEN pn_notes.task_end_date IS NOT NULL THEN
                            pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 'D', --display_type,
                                                                 'A', --flg_state,
                                                                 NULL, --value_text,
                                                                 to_char(pn_notes.task_end_date,
                                                                         pk_alert_constant.g_dt_yyyymmddhh24miss_tzr), --value_date,
                                                                 NULL, --value_icon,
                                                                 NULL, --shortcut,
                                                                 NULL, --back_color,
                                                                 NULL, --icon_color,
                                                                 NULL, --message_style,
                                                                 NULL, --message_color,
                                                                 NULL, --flg_text_domain,
                                                                 l_sysdate_tstz) --dt_server
                           ELSE
                            NULL
                       END task,
                       pn_notes.id_sys_shortcut,
                       pn_notes.flg_status flg_status_e,
                       pn_notes.id_schedule,
                       NULL text,
                       pn_notes.prof_name,
                       pn_notes.note_name,
                       decode(pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                              i_date1 => pn_notes.task_end_date,
                                                              i_date2 => l_sysdate_tstz),
                              'G',
                              abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                   i_timestamp_2 => l_sysdate_tstz)),
                              'L',
                              -abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                    i_timestamp_2 => l_sysdate_tstz)),
                              abs(pk_date_utils.get_timestamp_diff(i_timestamp_1 => pn_notes.task_end_date,
                                                                   i_timestamp_2 => l_sysdate_tstz))) time_to_sort
                  FROM (SELECT t2.id_sys_shortcut,
                               t2.flg_type,
                               nvl2(t2.id_epis_pn,
                                    pk_sysdomain.get_img(i_lang         => i_lang,
                                                         i_code_dom     => 'EPIS_PN.FLG_STATUS',
                                                         i_val          => t2.pn_flg_status,
                                                         i_domain_owner => 'ALERT'),
                                    NULL) icon,
                               t2.flg_icon_type,
                               t2.id_patient,
                               t2.id_episode,
                               t2.dt_begin_tstz,
                               t2.flg_status,
                               t2.id_schedule,
                               t2.flg_task,
                               nvl(t2.dt_begin_tstz, l_sysdate_tstz) +
                               pk_prog_notes_utils.gen_time_to_close(i_lang,
                                                                     i_prof,
                                                                     t2.id_episode,
                                                                     pk_prog_notes_constants.g_note_type_id_handp_2) task_end_date,
                               decode(l_note_name,
                                      pk_alert_constant.g_yes,
                                      pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                             i_prof               => i_prof,
                                                                             i_id_pn_note_type    => nvl2(t2.id_epis_pn,
                                                                                                          t2.id_pn_note_type,
                                                                                                          pk_prog_notes_constants.g_note_type_id_handp_2),
                                                                             i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_desc_d),
                                      pk_alert_constant.g_no,
                                      NULL) note_name,
                               decode(l_prof_name,
                                      pk_alert_constant.g_yes,
                                      nvl2(t2.id_epis_pn,
                                           pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => t2.id_prof_create),
                                           NULL),
                                      pk_alert_constant.g_no,
                                      NULL) prof_name
                          FROM (SELECT tt.id_sys_shortcut,
                                       tt.flg_type,
                                       epn.id_epis_pn,
                                       epn.flg_status pn_flg_status,
                                       tt.flg_icon_type,
                                       e.id_patient,
                                       e.id_episode,
                                       e.dt_begin_tstz,
                                       e.flg_status,
                                       ei.id_schedule,
                                       tt.flg_task,
                                       epn.id_pn_note_type,
                                       epn.id_prof_create,
                                       e.dt_creation
                                  FROM episode e
                                  LEFT OUTER JOIN (SELECT ep.*
                                                    FROM epis_pn ep
                                                   INNER JOIN episode epis
                                                      ON ep.id_episode = epis.id_episode
                                                   WHERE ep.id_pn_note_type =
                                                         pk_prog_notes_constants.g_note_type_id_handp_2
                                                     AND ep.flg_status <> pk_alert_constant.g_cancelled
                                                     AND epis.id_institution = i_prof.institution
                                                     AND epis.flg_status <> pk_alert_constant.g_cancelled) epn
                                    ON e.id_episode = epn.id_episode
                                  JOIN epis_info ei
                                    ON e.id_episode = ei.id_episode
                                 CROSS JOIN TABLE (SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                                        i_prof,
                                                                                        epn.id_episode,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        pk_prog_notes_constants.g_area_hp,
                                                                                        NULL)
                                                    FROM dual) nt
                                  JOIN todo_task tt
                                    ON tt.flg_task = nt.flg_task
                                 WHERE tt.flg_type = i_flg_type
                                   AND tt.id_profile_template = l_prof_templ
                                   AND tt.id_institution = l_institution
                                   AND (epn.id_episode IS NULL OR
                                       (epn.flg_status IN
                                       (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                          pk_prog_notes_constants.g_epis_pn_flg_status_t)))
                                   AND l_note_name = pk_alert_constant.g_yes
                                   AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                                   AND e.id_institution = i_prof.institution
                                   AND ei.id_software = i_prof.software
                                   AND ei.id_professional = i_prof.id
                                   AND pk_utils.search_table_number((SELECT pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                               i_prof,
                                                                                                               e.id_episode,
                                                                                                               l_prof_cat,
                                                                                                               l_handoff_type)
                                                                      FROM dual),
                                                                    i_prof.id) != -1
                                   AND rownum > 0) t2
                         WHERE (l_sysdate_tstz - t2.dt_creation >
                               pk_prog_notes_utils.gen_time_to_close(i_lang,
                                                                      i_prof,
                                                                      t2.id_episode,
                                                                      pk_prog_notes_constants.g_note_type_id_handp_2))) pn_notes
                UNION ALL
                ------------------------------------
                -- Referral
                ------------------------------------
                SELECT t.id_patient,
                       t.id_episode,
                       t.id_external_request,
                       t.dt_begin_tstz_e,
                       t.flg_type,
                       t.flg_task,
                       t.icon,
                       t.flg_icon_type,
                       t.task_count,
                       NULL task,
                       t.id_sys_shortcut,
                       t.flg_status_e,
                       t.id_schedule,
                       t.num_req || ' (' ||
                       pk_sysdomain.get_domain(pk_ref_constant.g_p1_exr_flg_status, t.flg_status, i_lang) || ')' text,
                       NULL prof_name,
                       NULL note_name,
                       NULL time_to_sort
                  FROM (
                        -- MED
                        SELECT ea.id_patient,
                                ea.id_episode,
                                ea.id_external_request,
                                ea.dt_status_tstz      dt_begin_tstz_e,
                                tt.flg_type,
                                tt.flg_task,
                                tt.icon,
                                tt.flg_icon_type,
                                1                      task_count,
                                tt.id_sys_shortcut,
                                NULL                   flg_status_e,
                                ea.id_schedule,
                                ea.num_req             num_req,
                                ea.flg_status
                          FROM p1_external_request ea
                          JOIN prof_profile_template ppt
                            ON (ppt.id_institution = ea.id_inst_orig)
                          JOIN todo_task tt
                            ON (tt.id_profile_template = ppt.id_profile_template)
                         WHERE i_prof_cat = g_prof_cat_d
                           AND ea.id_prof_requested = i_prof.id
                           AND ea.id_inst_orig = i_prof.institution
                           AND ea.flg_status IN (pk_ref_constant.g_p1_status_d,
                                                 pk_ref_constant.g_p1_status_y,
                                                 pk_ref_constant.g_p1_status_x)
                           AND tt.flg_type = i_flg_type
                           AND tt.flg_task = g_task_ref
                           AND NOT EXISTS (SELECT 1
                                  FROM p1_tracking t
                                 WHERE t.id_external_request = ea.id_external_request
                                   AND t.flg_type = pk_ref_constant.g_tracking_type_r
                                   AND t.ext_req_status = ea.flg_status
                                   AND t.id_professional = i_prof.id) -- remove from todo if professional has read the referral
                           AND ppt.id_professional = i_prof.id
                           AND ppt.id_institution = i_prof.institution
                           AND ppt.id_software = i_prof.software
                        UNION ALL
                        -- ADM
                        SELECT ea.id_patient,
                                ea.id_episode,
                                ea.id_external_request,
                                ea.dt_status_tstz      dt_begin_tstz_e,
                                tt.flg_type,
                                tt.flg_task,
                                tt.icon,
                                tt.flg_icon_type,
                                1                      task_count,
                                tt.id_sys_shortcut,
                                NULL                   flg_status_e,
                                ea.id_schedule,
                                ea.num_req             num_req,
                                ea.flg_status
                          FROM p1_external_request ea
                          JOIN prof_profile_template ppt
                            ON (ppt.id_institution = ea.id_inst_orig)
                          JOIN todo_task tt
                            ON (tt.id_profile_template = ppt.id_profile_template)
                         WHERE i_prof_cat = g_prof_cat_a
                           AND ea.flg_status = pk_ref_constant.g_p1_status_b
                           AND ea.id_inst_orig = i_prof.institution
                           AND tt.flg_type = i_flg_type
                           AND tt.flg_task = g_task_ref
                           AND NOT EXISTS (SELECT 1
                                  FROM p1_tracking t
                                 WHERE t.id_external_request = ea.id_external_request
                                   AND t.flg_type = pk_ref_constant.g_tracking_type_r
                                   AND t.ext_req_status = ea.flg_status
                                   AND t.id_professional = i_prof.id) -- remove from todo if professional has read the referral
                           AND ppt.id_professional = i_prof.id
                           AND ppt.id_institution = i_prof.institution
                           AND ppt.id_software = i_prof.software
                        UNION ALL
                        -- ADM (WF=4)
                        SELECT ea.id_patient,
                                ea.id_episode,
                                ea.id_external_request,
                                ea.dt_status_tstz      dt_begin_tstz_e,
                                tt.flg_type,
                                tt.flg_task,
                                tt.icon,
                                tt.flg_icon_type,
                                1                      task_count,
                                tt.id_sys_shortcut,
                                NULL                   flg_status_e,
                                ea.id_schedule,
                                ea.num_req             num_req,
                                ea.flg_status
                          FROM p1_external_request ea
                          JOIN prof_profile_template ppt
                            ON (ppt.id_institution = ea.id_inst_dest) -- dest institution
                          JOIN todo_task tt
                            ON (tt.id_profile_template = ppt.id_profile_template)
                         WHERE i_prof_cat = g_prof_cat_a
                           AND ea.id_workflow = pk_ref_constant.g_wf_x_hosp
                           AND (ea.id_prof_requested = i_prof.id OR
                               pk_ref_dest_reg.validate_dcs(i_prof => i_prof, i_dcs => ea.id_dep_clin_serv) =
                               pk_alert_constant.g_yes)
                           AND ea.flg_status IN (pk_ref_constant.g_p1_status_d,
                                                 pk_ref_constant.g_p1_status_y,
                                                 pk_ref_constant.g_p1_status_x,
                                                 pk_ref_constant.g_p1_status_b)
                           AND tt.flg_type = i_flg_type
                           AND tt.flg_task = g_task_ref
                           AND NOT EXISTS (SELECT 1
                                  FROM p1_tracking t
                                 WHERE t.id_external_request = ea.id_external_request
                                   AND t.flg_type = pk_ref_constant.g_tracking_type_r
                                   AND t.ext_req_status = ea.flg_status
                                   AND t.id_professional = i_prof.id) -- remove from todo if professional has read the referral
                           AND ppt.id_professional = i_prof.id
                           AND ppt.id_institution = i_prof.institution
                           AND ppt.id_software = i_prof.software) t
                UNION ALL
                -- referral hand off pending tasks
                SELECT t.id_patient,
                       t.id_episode,
                       t.id_external_request,
                       t.dt_created          dt_begin_tstz_e,
                       t.flg_type,
                       t.flg_task,
                       t.icon,
                       t.flg_icon_type,
                       1                     task_count,
                       NULL                  task,
                       t.id_sys_shortcut,
                       NULL                  flg_status_e,
                       t.id_schedule,
                       t.text,
                       NULL                  prof_name,
                       NULL                  note_name,
                       NULL                  time_to_sort
                  FROM (SELECT ea.id_patient,
                               ea.id_episode,
                               ea.id_external_request,
                               rtr.dt_created,
                               tt.flg_type,
                               tt.flg_task,
                               tt.icon,
                               tt.flg_icon_type,
                               tt.id_sys_shortcut,
                               ea.id_schedule,
                               ea.num_req text
                          FROM ref_trans_responsibility rtr
                          JOIN p1_external_request ea
                            ON (rtr.id_external_request = ea.id_external_request)
                          JOIN prof_profile_template ppt
                            ON (ppt.id_institution = rtr.id_inst_orig_tr)
                          JOIN todo_task tt
                            ON (tt.id_profile_template = ppt.id_profile_template)
                         WHERE tt.flg_type = i_flg_type
                           AND tt.flg_type = g_pending -- pending tasks
                           AND tt.flg_task = g_task_rh
                           AND ppt.id_professional = i_prof.id
                           AND ppt.id_institution = i_prof.institution
                           AND ppt.id_software = i_prof.software
                           AND rtr.flg_active = pk_ref_constant.g_yes
                           AND rtr.id_workflow = pk_ref_constant.g_wf_transfresp -- ID_WF=10
                           AND rtr.id_inst_orig_tr = i_prof.institution
                           AND rtr.id_prof_dest = i_prof.id
                           AND pk_workflow.check_status_final(i_id_workflow => rtr.id_workflow,
                                                              i_id_status   => rtr.id_status) = pk_ref_constant.g_no
                        UNION ALL
                        SELECT ea.id_patient,
                               ea.id_episode,
                               ea.id_external_request,
                               rtr.dt_created,
                               tt.flg_type,
                               tt.flg_task,
                               tt.icon,
                               tt.flg_icon_type,
                               tt.id_sys_shortcut,
                               ea.id_schedule,
                               ea.num_req text
                          FROM ref_trans_responsibility rtr
                          JOIN p1_external_request ea
                            ON (rtr.id_external_request = ea.id_external_request)
                          JOIN prof_profile_template ppt
                            ON (ppt.id_institution = rtr.id_inst_dest_tr)
                          JOIN todo_task tt
                            ON (tt.id_profile_template = ppt.id_profile_template)
                         WHERE tt.flg_type = i_flg_type
                           AND tt.flg_type = g_pending -- pending tasks
                           AND tt.flg_task = g_task_rh
                           AND ppt.id_professional = i_prof.id
                           AND ppt.id_institution = i_prof.institution
                           AND ppt.id_software = i_prof.software
                           AND rtr.flg_active = pk_ref_constant.g_yes
                           AND rtr.id_workflow = pk_ref_constant.g_wf_transfresp_inst -- ID_WF=11
                           AND rtr.id_inst_dest_tr = i_prof.institution
                           AND pk_workflow.check_status_final(i_id_workflow => rtr.id_workflow,
                                                              i_id_status   => rtr.id_status) = pk_ref_constant.g_no
                           AND ((rtr.id_prof_dest = i_prof.id) OR
                               (pk_ref_change_resp.check_func_handoff_app(i_prof) = pk_ref_constant.g_yes AND
                               rtr.id_status IN
                               (pk_ref_constant.g_tr_status_inst_app, pk_ref_constant.g_tr_status_declined_inst)))) t
                UNION ALL
                -- referral hand off depending tasks
                SELECT t.id_patient,
                       t.id_episode,
                       t.id_external_request,
                       t.dt_created          dt_begin_tstz_e,
                       t.flg_type,
                       t.flg_task,
                       t.icon,
                       t.flg_icon_type,
                       1                     task_count,
                       NULL                  task,
                       t.id_sys_shortcut,
                       NULL                  flg_status_e,
                       t.id_schedule,
                       t.text,
                       NULL                  prof_name,
                       NULL                  note_name,
                       NULL                  time_to_sort
                  FROM (SELECT ea.id_patient,
                               ea.id_episode,
                               ea.id_external_request,
                               rtr.dt_created,
                               tt.flg_type,
                               tt.flg_task,
                               tt.icon,
                               tt.flg_icon_type,
                               tt.id_sys_shortcut,
                               ea.id_schedule,
                               ea.num_req text
                          FROM ref_trans_responsibility rtr
                          JOIN p1_external_request ea
                            ON (rtr.id_external_request = ea.id_external_request)
                          JOIN prof_profile_template ppt
                            ON (ppt.id_institution = rtr.id_inst_orig_tr)
                          JOIN todo_task tt
                            ON (tt.id_profile_template = ppt.id_profile_template)
                         WHERE tt.flg_type = i_flg_type
                           AND tt.flg_type = g_depending -- depending tasks
                           AND tt.flg_task = g_task_rh
                           AND ppt.id_professional = i_prof.id
                           AND ppt.id_institution = i_prof.institution
                           AND ppt.id_software = i_prof.software
                           AND rtr.flg_active = pk_ref_constant.g_yes
                           AND rtr.id_workflow = pk_ref_constant.g_wf_transfresp -- ID_WF=10
                           AND rtr.id_inst_orig_tr = i_prof.institution
                           AND rtr.id_prof_transf_owner = i_prof.id
                           AND (rtr.id_prof_dest != i_prof.id OR rtr.id_prof_dest IS NULL)
                           AND pk_workflow.check_status_final(i_id_workflow => rtr.id_workflow,
                                                              i_id_status   => rtr.id_status) = pk_ref_constant.g_no
                        UNION ALL
                        SELECT ea.id_patient,
                               ea.id_episode,
                               ea.id_external_request,
                               rtr.dt_created,
                               tt.flg_type,
                               tt.flg_task,
                               tt.icon,
                               tt.flg_icon_type,
                               tt.id_sys_shortcut,
                               ea.id_schedule,
                               ea.num_req text
                          FROM ref_trans_responsibility rtr
                          JOIN p1_external_request ea
                            ON (rtr.id_external_request = ea.id_external_request)
                          JOIN prof_profile_template ppt
                            ON (ppt.id_institution = rtr.id_inst_orig_tr)
                          JOIN todo_task tt
                            ON (tt.id_profile_template = ppt.id_profile_template)
                         WHERE tt.flg_type = i_flg_type
                           AND tt.flg_type = g_depending -- depending tasks
                           AND tt.flg_task = g_task_rh
                           AND ppt.id_professional = i_prof.id
                           AND ppt.id_institution = i_prof.institution
                           AND ppt.id_software = i_prof.software
                           AND rtr.flg_active = pk_ref_constant.g_yes
                           AND rtr.id_workflow = pk_ref_constant.g_wf_transfresp_inst -- ID_WF=11
                           AND rtr.id_inst_orig_tr = i_prof.institution
                           AND rtr.id_prof_transf_owner = i_prof.id
                           AND pk_workflow.check_status_final(i_id_workflow => rtr.id_workflow,
                                                              i_id_status   => rtr.id_status) = pk_ref_constant.g_no) t
                UNION ALL
                -- comments not read
                SELECT t.id_patient,
                       NULL                  id_episode,
                       t.id_external_request,
                       t.dt_begin_tstz_e,
                       t.flg_type,
                       t.flg_task,
                       t.icon,
                       t.flg_icon_type,
                       t.task_count,
                       NULL                  task,
                       t.id_sys_shortcut,
                       NULL                  flg_status_e,
                       t.id_schedule,
                       t.num_req             text,
                       NULL                  prof_name,
                       NULL                  note_name,
                       NULL                  time_to_sort
                  FROM (
                        -- clinical comments not read (orig)
                        SELECT ea.id_patient,
                                ea.id_external_request,
                                ea.dt_clin_last_comment dt_begin_tstz_e,
                                tt.flg_type,
                                tt.flg_task,
                                tt.icon,
                                tt.flg_icon_type,
                                ea.nr_clin_comments     task_count,
                                tt.id_sys_shortcut,
                                ea.id_schedule,
                                ea.num_req
                          FROM prof_profile_template ppt
                          JOIN profile_template pt
                            ON (ppt.id_profile_template = pt.id_profile_template)
                          JOIN todo_task tt
                            ON (tt.id_profile_template = ppt.id_profile_template)
                          JOIN referral_ea ea
                            ON (ppt.id_institution = ea.id_inst_orig)
                         WHERE ppt.id_professional = i_prof.id
                           AND ppt.id_software = i_prof.software
                           AND ppt.id_institution = i_prof.institution
                           AND tt.flg_type = i_flg_type
                           AND tt.flg_task = g_task_nr
                           AND nvl(ea.nr_clin_comments, 0) > 0
                           AND nvl(ea.id_prof_clin_comment, -1) != i_prof.id
                           AND ea.flg_clin_comm_read = pk_ref_constant.g_no
                           AND pk_ref_core.check_comm_receiver(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_id_cat            => l_category,
                                                               i_id_workflow       => ea.id_workflow,
                                                               i_id_prof_requested => ea.id_prof_requested,
                                                               i_id_inst_orig      => ea.id_inst_orig,
                                                               i_id_inst_dest      => ea.id_inst_dest,
                                                               i_id_dcs            => ea.id_dep_clin_serv,
                                                               i_flg_type_comm     => pk_ref_constant.g_clinical_comment,
                                                               i_id_inst_comm      => ea.id_inst_clin_comment) =
                               pk_ref_constant.g_yes
                        UNION -- if professional works at both institutions, comments tasks should not be duplicate
                        -- clinical comments not read (dest)
                        SELECT ea.id_patient,
                                ea.id_external_request,
                                ea.dt_clin_last_comment dt_begin_tstz_e,
                                tt.flg_type,
                                tt.flg_task,
                                tt.icon,
                                tt.flg_icon_type,
                                ea.nr_clin_comments     task_count,
                                tt.id_sys_shortcut,
                                ea.id_schedule,
                                ea.num_req
                          FROM prof_profile_template ppt
                          JOIN profile_template pt
                            ON (ppt.id_profile_template = pt.id_profile_template)
                          JOIN todo_task tt
                            ON (tt.id_profile_template = ppt.id_profile_template)
                          JOIN referral_ea ea
                            ON (ppt.id_institution = ea.id_inst_dest)
                         WHERE ppt.id_professional = i_prof.id
                           AND ppt.id_software = i_prof.software
                           AND ppt.id_institution = i_prof.institution
                           AND tt.flg_type = i_flg_type
                           AND tt.flg_task = g_task_nr
                           AND nvl(ea.nr_clin_comments, 0) > 0
                           AND nvl(ea.id_prof_clin_comment, -1) != i_prof.id
                           AND ea.flg_clin_comm_read = pk_ref_constant.g_no
                           AND pk_ref_core.check_comm_receiver(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_id_cat            => l_category,
                                                               i_id_workflow       => ea.id_workflow,
                                                               i_id_prof_requested => ea.id_prof_requested,
                                                               i_id_inst_orig      => ea.id_inst_orig,
                                                               i_id_inst_dest      => ea.id_inst_dest,
                                                               i_id_dcs            => ea.id_dep_clin_serv,
                                                               i_flg_type_comm     => pk_ref_constant.g_clinical_comment,
                                                               i_id_inst_comm      => ea.id_inst_clin_comment) =
                               pk_ref_constant.g_yes
                        UNION ALL
                        -- administrative comments not read (orig)
                        SELECT ea.id_patient,
                                ea.id_external_request,
                                ea.dt_adm_last_comment dt_begin_tstz_e,
                                tt.flg_type,
                                tt.flg_task,
                                tt.icon,
                                tt.flg_icon_type,
                                ea.nr_adm_comments     task_count,
                                tt.id_sys_shortcut,
                                ea.id_schedule,
                                ea.num_req
                          FROM prof_profile_template ppt
                          JOIN profile_template pt
                            ON (ppt.id_profile_template = pt.id_profile_template)
                          JOIN todo_task tt
                            ON (tt.id_profile_template = ppt.id_profile_template)
                          JOIN referral_ea ea
                            ON (ppt.id_institution = ea.id_inst_orig OR ppt.id_institution = ea.id_inst_dest)
                         WHERE ppt.id_professional = i_prof.id
                           AND ppt.id_software = i_prof.software
                           AND ppt.id_institution = i_prof.institution
                           AND tt.flg_type = i_flg_type
                           AND tt.flg_task = g_task_nr
                           AND nvl(ea.nr_adm_comments, 0) > 0
                           AND nvl(ea.id_prof_adm_comment, -1) != i_prof.id
                           AND ea.flg_adm_comm_read = pk_ref_constant.g_no
                           AND pk_ref_core.check_comm_receiver(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_id_cat            => l_category,
                                                               i_id_workflow       => ea.id_workflow,
                                                               i_id_prof_requested => ea.id_prof_requested,
                                                               i_id_inst_orig      => ea.id_inst_orig,
                                                               i_id_inst_dest      => ea.id_inst_dest,
                                                               i_id_dcs            => ea.id_dep_clin_serv,
                                                               i_flg_type_comm     => pk_ref_constant.g_administrative_comment,
                                                               i_id_inst_comm      => ea.id_inst_adm_comment) =
                               pk_ref_constant.g_yes
                        UNION -- if professional works at both institutions, comments tasks should not be duplicate
                        -- administrative comments not read (dest)
                        SELECT ea.id_patient,
                                ea.id_external_request,
                                ea.dt_adm_last_comment dt_begin_tstz_e,
                                tt.flg_type,
                                tt.flg_task,
                                tt.icon,
                                tt.flg_icon_type,
                                ea.nr_adm_comments     task_count,
                                tt.id_sys_shortcut,
                                ea.id_schedule,
                                ea.num_req
                          FROM prof_profile_template ppt
                          JOIN profile_template pt
                            ON (ppt.id_profile_template = pt.id_profile_template)
                          JOIN todo_task tt
                            ON (tt.id_profile_template = ppt.id_profile_template)
                          JOIN referral_ea ea
                            ON (ppt.id_institution = ea.id_inst_dest)
                         WHERE ppt.id_professional = i_prof.id
                           AND ppt.id_software = i_prof.software
                           AND ppt.id_institution = i_prof.institution
                           AND tt.flg_type = i_flg_type
                           AND tt.flg_task = g_task_nr
                           AND nvl(ea.nr_adm_comments, 0) > 0
                           AND nvl(ea.id_prof_adm_comment, -1) != i_prof.id
                           AND ea.flg_adm_comm_read = pk_ref_constant.g_no
                           AND pk_ref_core.check_comm_receiver(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_id_cat            => l_category,
                                                               i_id_workflow       => ea.id_workflow,
                                                               i_id_prof_requested => ea.id_prof_requested,
                                                               i_id_inst_orig      => ea.id_inst_orig,
                                                               i_id_inst_dest      => ea.id_inst_dest,
                                                               i_id_dcs            => ea.id_dep_clin_serv,
                                                               i_flg_type_comm     => pk_ref_constant.g_administrative_comment,
                                                               i_id_inst_comm      => ea.id_inst_adm_comment) =
                               pk_ref_constant.g_yes) t
                UNION ALL
                ------------------------------------
                -- discharge summary
                ------------------------------------
                SELECT pn_notes.id_patient,
                       pn_notes.id_episode,
                       NULL id_external_request,
                       pn_notes.dt_begin_tstz dt_begin_tstz_e,
                       pn_notes.flg_type,
                       pn_notes.flg_task,
                       pn_notes.icon,
                       pn_notes.flg_icon_type,
                       1 task_count,
                       CASE
                           WHEN pn_notes.task_end_date IS NOT NULL THEN
                            pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 'D', --display_type,
                                                                 'A', --flg_state,
                                                                 NULL, --value_text,
                                                                 to_char(pn_notes.task_end_date,
                                                                         pk_alert_constant.g_dt_yyyymmddhh24miss_tzr), --value_date,
                                                                 NULL, --value_icon,
                                                                 NULL, --shortcut,
                                                                 NULL, --back_color,
                                                                 NULL, --icon_color,
                                                                 NULL, --message_style,
                                                                 NULL, --message_color,
                                                                 NULL, --flg_text_domain,
                                                                 l_sysdate_tstz) --dt_server
                           ELSE
                            NULL
                       END task,
                       pn_notes.id_sys_shortcut,
                       pn_notes.flg_status flg_status_e,
                       pn_notes.id_schedule,
                       NULL text,
                       pn_notes.prof_name,
                       pn_notes.note_name,
                       decode(pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                              i_date1 => pn_notes.task_end_date,
                                                              i_date2 => l_sysdate_tstz),
                              'G',
                              abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz)),
                              'L',
                              -abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz)),
                              abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz))) time_to_sort
                  FROM (SELECT DISTINCT -- +opt_estimate (table nt rows=1)
                                        tt.id_sys_shortcut,
                                        tt.flg_type,
                                        tt.icon,
                                        tt.flg_icon_type,
                                        e.id_patient,
                                        e.id_episode,
                                        e.dt_begin_tstz,
                                        e.flg_status,
                                        ei.id_schedule,
                                        nt.flg_task,
                                        NULL prof_name,
                                        NULL note_name,
                                        nvl(d.dt_pend_tstz,
                                            nvl(d.dt_med_tstz,
                                                nvl(pk_discharge_core.get_dt_admin(i_lang,
                                                                                   i_prof,
                                                                                   NULL,
                                                                                   d.flg_status_adm,
                                                                                   d.dt_admin_tstz),
                                                    l_sysdate_tstz))) +
                                        numtodsinterval(nvl(nt.time_to_start_docum, 0), 'minute') task_end_date
                          FROM discharge d
                         CROSS JOIN TABLE((SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                                i_prof,
                                                                                d.id_episode,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                pk_prog_notes_constants.g_area_ds,
                                                                                NULL)
                                            FROM dual)) nt
                          JOIN episode e
                            ON e.id_episode = d.id_episode
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                          JOIN todo_task tt
                            ON tt.flg_task = nt.flg_task
                           AND tt.id_profile_template = l_prof_templ
                           AND tt.flg_task = l_flg_task_ds
                           AND tt.id_institution = l_institution
                         WHERE d.flg_status NOT IN
                               (pk_discharge.g_disch_flg_status_reopen, pk_discharge.g_disch_flg_status_cancel)
                           AND tt.flg_type = i_flg_type
                           AND pk_utils.search_table_number((SELECT pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                       i_prof,
                                                                                                       ei.id_episode,
                                                                                                       l_prof_cat,
                                                                                                       l_handoff_type)
                                                              FROM dual),
                                                            i_prof.id) != -1
                           AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                           AND (e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE) OR
                               l_signoff_type = g_signature_submit)
                           AND e.id_institution = i_prof.institution
                           AND ei.id_software = i_prof.software
                           AND ((NOT EXISTS (SELECT 1
                                               FROM epis_pn epn
                                              WHERE epn.id_episode = d.id_episode
                                                AND epn.id_pn_area = nt.id_pn_area
                                                AND epn.flg_status IN
                                                    (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                     pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                                     pk_prog_notes_constants.g_epis_pn_flg_status_s)) AND
                                l_signoff_type = g_signature_signoff))) pn_notes
                --discharge summary over time-to-close and has not submit to vs
                UNION ALL
                SELECT pn_notes.id_patient,
                       pn_notes.id_episode,
                       NULL id_external_request,
                       pn_notes.dt_begin_tstz dt_begin_tstz_e,
                       pn_notes.flg_type,
                       pn_notes.flg_task,
                       pn_notes.icon,
                       pn_notes.flg_icon_type,
                       1 task_count,
                       CASE
                           WHEN pn_notes.task_end_date IS NOT NULL THEN
                            pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 'D', --display_type,
                                                                 'A', --flg_state,
                                                                 NULL, --value_text,
                                                                 to_char(pn_notes.task_end_date,
                                                                         pk_alert_constant.g_dt_yyyymmddhh24miss_tzr), --value_date,
                                                                 NULL, --value_icon,
                                                                 NULL, --shortcut,
                                                                 NULL, --back_color,
                                                                 NULL, --icon_color,
                                                                 NULL, --message_style,
                                                                 NULL, --message_color,
                                                                 NULL, --flg_text_domain,
                                                                 l_sysdate_tstz) --dt_server
                           ELSE
                            NULL
                       END task,
                       pn_notes.id_sys_shortcut,
                       pn_notes.flg_status flg_status_e,
                       pn_notes.id_schedule,
                       NULL text,
                       pn_notes.prof_name,
                       pn_notes.note_name,
                       decode(pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                              i_date1 => pn_notes.task_end_date,
                                                              i_date2 => l_sysdate_tstz),
                              'G',
                              abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz)),
                              'L',
                              -abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz)),
                              abs(pk_date_utils.get_timestamp_diff(pn_notes.task_end_date, l_sysdate_tstz))) time_to_sort
                  FROM (SELECT DISTINCT t1.id_sys_shortcut,
                                        t1.flg_type,
                                        nvl2(t1.id_epis_pn,
                                             pk_sysdomain.get_img(i_lang     => i_lang,
                                                                  i_code_dom => 'EPIS_PN.FLG_STATUS',
                                                                  i_val      => t1.ep_flg_status),
                                             t1.icon) icon,
                                        t1.flg_icon_type,
                                        t1.id_patient,
                                        t1.id_episode,
                                        t1.dt_begin_tstz,
                                        t1.flg_status,
                                        t1.id_schedule,
                                        t1.flg_task,
                                        t1.id_pn_note_type,
                                        decode(l_prof_name,
                                               pk_alert_constant.g_yes,
                                               nvl2(t1.id_prof_create,
                                                    pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => t1.id_prof_create),
                                                    NULL),
                                               pk_alert_constant.g_no,
                                               NULL) prof_name,
                                        decode(l_note_name,
                                               pk_alert_constant.g_yes,
                                               pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                                      i_prof               => i_prof,
                                                                                      i_id_pn_note_type    => nvl2(t1.id_epis_pn,
                                                                                                                   t1.id_pn_note_type,
                                                                                                                   pk_prog_notes_constants.g_note_type_id_disch_sum_12),
                                                                                      i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_desc_d),
                                               pk_alert_constant.g_no,
                                               NULL) note_name,
                                        nvl(t1.dt_pend_tstz,
                                            nvl(t1.dt_med_tstz,
                                                nvl(pk_discharge_core.get_dt_admin(i_lang,
                                                                                   i_prof,
                                                                                   NULL,
                                                                                   t1.flg_status_adm,
                                                                                   t1.dt_admin_tstz),
                                                    l_sysdate_tstz))) +
                                        numtodsinterval(nvl(t1.time_to_start_docum, 0), 'minute') task_end_date
                          FROM (SELECT tt.id_sys_shortcut,
                                       tt.flg_type,
                                       tt.icon,
                                       tt.flg_icon_type,
                                       e.id_patient,
                                       e.id_episode,
                                       e.dt_begin_tstz,
                                       e.flg_status,
                                       ei.id_schedule,
                                       nt.flg_task,
                                       ep.id_epis_pn,
                                       ep.id_pn_note_type,
                                       ep.id_episode          ep_id_episode,
                                       ep.flg_status          ep_flg_status,
                                       d.dt_pend_tstz,
                                       d.dt_med_tstz,
                                       d.flg_status_adm,
                                       d.dt_admin_tstz,
                                       ep.id_prof_create,
                                       nt.time_to_start_docum
                                  FROM discharge d
                                 CROSS JOIN TABLE (SELECT pk_prog_notes_utils.tf_pn_area(i_lang,
                                                                                        i_prof,
                                                                                        d.id_episode,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        pk_prog_notes_constants.g_area_ds,
                                                                                        NULL)
                                                    FROM dual) nt
                                  JOIN episode e
                                    ON e.id_episode = d.id_episode
                                  JOIN epis_info ei
                                    ON e.id_episode = ei.id_episode
                                  LEFT OUTER JOIN (SELECT epn.*
                                                    FROM epis_pn epn
                                                   INNER JOIN episode epis
                                                      ON epis.id_episode = epn.id_episode
                                                   WHERE epis.id_institution = i_prof.institution
                                                     AND epn.id_pn_note_type =
                                                         pk_prog_notes_constants.g_note_type_id_disch_sum_12
                                                     AND epn.flg_status <> pk_alert_constant.g_cancelled
                                                     AND epis.flg_status <> pk_alert_constant.g_cancelled) ep
                                    ON e.id_episode = ep.id_episode
                                  JOIN todo_task tt
                                    ON tt.flg_task = nt.flg_task
                                   AND tt.id_profile_template = l_prof_templ
                                   AND tt.flg_task = l_flg_task_ds
                                   AND tt.id_institution = l_institution
                                 WHERE d.flg_status NOT IN
                                       (pk_discharge.g_disch_flg_status_reopen, pk_discharge.g_disch_flg_status_cancel)
                                   AND tt.flg_type = i_flg_type
                                   AND pk_utils.search_table_number((SELECT pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                               i_prof,
                                                                                                               ei.id_episode,
                                                                                                               l_prof_cat,
                                                                                                               l_handoff_type)
                                                                      FROM dual),
                                                                    i_prof.id) != -1
                                   AND e.flg_status != pk_alert_constant.g_epis_status_cancel
                                   AND e.id_institution = i_prof.institution
                                   AND ei.id_software = i_prof.software
                                   AND l_note_name = pk_alert_constant.g_yes
                                   AND ei.id_professional = i_prof.id
                                   AND rownum > 0) t1
                         WHERE (t1.ep_id_episode IS NULL OR --has not written discharge summary
                               (t1.ep_flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_d AND --discharge summary is draft and over time-to-close
                               (l_sysdate_tstz - (nvl(t1.dt_pend_tstz,
                                                        nvl(t1.dt_med_tstz,
                                                            nvl((SELECT pk_discharge_core.get_dt_admin(i_lang,
                                                                                                      i_prof,
                                                                                                      NULL,
                                                                                                      t1.flg_status_adm,
                                                                                                      t1.dt_admin_tstz)
                                                                  FROM dual),
                                                                l_sysdate_tstz))))) >
                               pk_prog_notes_utils.gen_time_to_close(i_lang,
                                                                       i_prof,
                                                                       t1.id_episode,
                                                                       pk_prog_notes_constants.g_note_type_id_disch_sum_12)))) pn_notes
                
                UNION ALL
                SELECT cr.id_patient,
                       cr.id_episode,
                       NULL id_external_request,
                       cr.dt_begin_tstz dt_begin_tstz_e,
                       tt.flg_type,
                       tt.flg_task,
                       tt.icon,
                       tt.flg_icon_type,
                       (SELECT COUNT(1)
                          FROM opinion o
                         WHERE o.id_episode = cr.id_episode
                           AND o.flg_state = pk_opinion.g_opinion_req
                           AND o.id_opinion_type IS NULL
                           AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending) OR
                               (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) task_count,
                       NULL task,
                       tt.id_sys_shortcut,
                       cr.flg_status flg_status_e,
                       cr.id_schedule,
                       NULL text,
                       NULL prof_name,
                       NULL note_name,
                       NULL time_to_sort
                  FROM todo_task tt,
                       (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                          FROM opinion o
                          JOIN episode e
                            ON o.id_episode = e.id_episode
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                         WHERE o.flg_state = pk_opinion.g_opinion_req
                           AND o.id_opinion_type IS NULL
                           AND e.id_institution = i_prof.institution
                           AND e.flg_status = pk_alert_constant.g_epis_status_active
                           AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                           AND ei.id_software = i_prof.software
                           AND ((o.id_prof_questioned = i_prof.id AND i_flg_type = g_pending) OR
                               (o.id_prof_questions = i_prof.id AND i_flg_type = g_depending))) cr
                 WHERE tt.flg_task = g_task_cr
                   AND tt.flg_type = i_flg_type
                   AND tt.id_profile_template = l_prof_templ
                   AND tt.id_institution = l_institution
                UNION ALL
                -- HAND OFF
                SELECT tr.id_patient,
                       tr.id_episode,
                       NULL id_external_request,
                       tr.dt_begin_tstz dt_begin_tstz_e,
                       tt.flg_type,
                       tt.flg_task,
                       tt.icon,
                       tt.flg_icon_type,
                       (SELECT COUNT(1)
                          FROM epis_prof_resp epr
                         WHERE epr.id_episode = tr.id_episode
                           AND epr.flg_status = pk_hand_off.g_hand_off_r
                           AND ((epr.id_prof_to = i_prof.id AND i_flg_type = g_pending) OR
                               (epr.id_prof_req = i_prof.id AND i_flg_type = g_depending))) task_count,
                       NULL task,
                       tt.id_sys_shortcut,
                       tr.flg_status flg_status_e,
                       tr.id_schedule,
                       NULL text,
                       NULL prof_name,
                       NULL note_name,
                       NULL time_to_sort
                  FROM todo_task tt,
                       (SELECT DISTINCT e.id_patient, e.id_episode, e.dt_begin_tstz, e.flg_status, ei.id_schedule
                          FROM epis_prof_resp epr
                          JOIN episode e
                            ON epr.id_episode = e.id_episode
                          JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                         WHERE epr.flg_status = pk_hand_off.g_hand_off_r
                           AND e.id_institution = i_prof.institution
                           AND e.flg_status = pk_alert_constant.g_epis_status_active
                           AND e.dt_begin_tstz >= CAST(g_epis_min_date AS TIMESTAMP WITH LOCAL TIME ZONE)
                           AND ei.id_software = i_prof.software
                           AND ((epr.id_prof_to = i_prof.id AND i_flg_type = g_pending) OR
                               (epr.id_prof_req = i_prof.id AND i_flg_type = g_depending))) tr
                 WHERE tt.flg_task = g_task_tr
                   AND tt.flg_type = i_flg_type
                   AND tt.id_profile_template = l_prof_templ
                   AND tt.id_institution = l_institution) t
         WHERE t.task_count > 0;
    
        RETURN tbl_return;
    
    END get_prof_task_base02;

BEGIN

    pk_alertlog.log_init(pk_alertlog.who_am_i);

END pk_todo_list;
/
