/*-- Last Change Revision: $Rev: 2026848 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_care_plans_api_db IS

    FUNCTION get_care_plan_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN care_plan.id_patient%TYPE,
        o_care_plan OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_LIST';
        OPEN o_care_plan FOR
            SELECT cp.id_care_plan,
                   cp.name,
                   pk_translation.get_translation(i_lang, 'CARE_PLAN_TYPE.CODE_CARE_PLAN_TYPE.' || cp.id_care_plan_type) care_plan_type
              FROM care_plan cp
             WHERE cp.id_patient = i_patient
               AND cp.flg_status IN (pk_care_plans.g_pending, pk_care_plans.g_inprogress, pk_care_plans.g_suspended)
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_care_plan);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_care_plan_summary;

    FUNCTION get_care_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_status IN guideline_process.flg_status%TYPE,
        o_care_plan  OUT t_cur_care_plan,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_CARE_PLAN CURSOR';
        OPEN o_care_plan FOR
            SELECT cp.name,
                   cp.dt_begin,
                   cp.id_prof,
                   cp.dt_care_plan,
                   cp.id_care_plan,
                   cp.dt_care_plan AS dt_last_update
              FROM care_plan cp
             WHERE cp.id_patient = i_id_patient
               AND cp.flg_status NOT IN (pk_care_plans.g_interrupted, pk_care_plans.g_canceled)
               AND cp.flg_status = nvl(i_flg_status, cp.flg_status);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN',
                                              o_error);
            pk_types.open_my_cursor(o_care_plan);
            RETURN FALSE;
    END get_care_plan;

    FUNCTION get_care_plan_tasks
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_care_plan    IN care_plan.id_care_plan%TYPE,
        o_care_plan_tasks OUT t_cur_care_plan_tasks,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_CARE_PLAN_TASKS CURSOR';
        OPEN o_care_plan_tasks FOR
            SELECT cp.name,
                   pk_date_utils.date_char_tsz(i_lang, cp.dt_begin, i_prof.institution, i_prof.software) dt_begin,
                   cp.goals,
                   cp.id_prof,
                   cp.dt_care_plan,
                   pk_care_plans.get_desc_translation(i_lang, i_prof, cpt.id_item, cpt.id_task_type) task_name,
                   pk_care_plans.get_instructions_format(i_lang,
                                                         i_prof,
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_begin,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         pk_date_utils.to_char_insttimezone(i_prof,
                                                                                            cpt.dt_end,
                                                                                            'YYYYMMDDHH24MISS'),
                                                         cpt.num_exec,
                                                         cpt.interval,
                                                         cpt.id_unit_measure) task_instructions,
                   cpt.notes
              FROM care_plan cp
             INNER JOIN care_plan_task_link cptl
                ON cptl.id_care_plan = cp.id_care_plan
             INNER JOIN care_plan_task cpt
                ON cpt.id_care_plan_task = cptl.id_care_plan_task
             WHERE cp.id_care_plan = i_id_care_plan
               AND cp.flg_status NOT IN (pk_care_plans.g_interrupted, pk_care_plans.g_canceled)
               AND cpt.flg_status NOT IN (pk_care_plans.g_interrupted, pk_care_plans.g_canceled);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CARE_PLAN_TASKS',
                                              o_error);
            pk_types.open_my_cursor(o_care_plan_tasks);
            RETURN FALSE;
    END get_care_plan_tasks;

    FUNCTION reset_care_plans
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_care_plan      table_number;
        l_care_plan_task table_number;
    
    BEGIN
    
        -- checks if the delete process can be executed
        IF i_patient.count = 0
           AND i_episode.count = 0
        THEN
            g_error := 'EMPTY ARRAYS FOR I_PATIENT AND I_EPISODE';
            RETURN FALSE;
        END IF;
    
        g_error := 'ID_CARE_PLAN BULK COLLECT ERROR';
        SELECT cp.id_care_plan
          BULK COLLECT
          INTO l_care_plan
          FROM care_plan cp
         WHERE cp.id_episode IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                   FROM TABLE(i_episode) t)
            OR (cp.id_episode IS NULL AND
               cp.id_patient IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                    FROM TABLE(i_patient) t));
    
        g_error := 'ID_CARE_PLAN_TASK BULK COLLECT ERROR';
        SELECT cptl.id_care_plan_task
          BULK COLLECT
          INTO l_care_plan_task
          FROM care_plan_task_link cptl
         WHERE cptl.id_care_plan IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                       FROM TABLE(l_care_plan) t);
    
        g_error := 'CARE_PLAN_HIST DELETE ERROR';
        DELETE FROM care_plan_hist cph
         WHERE cph.id_episode IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                    FROM TABLE(i_episode) t)
            OR (cph.id_episode IS NULL AND
               cph.id_patient IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                     FROM TABLE(i_patient) t));
    
        g_error := 'CARE_PLAN_TASK_LINK DELETE ERROR';
        DELETE FROM care_plan_task_link cptl
         WHERE cptl.id_care_plan IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                       FROM TABLE(l_care_plan) t);
    
        g_error := 'CARE_PLAN_TASK_COUNT DELETE ERROR';
        DELETE FROM care_plan_task_count cptc
         WHERE cptc.id_care_plan IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                       FROM TABLE(l_care_plan) t);
    
        g_error := 'CARE_PLAN_TASK_REQ DELETE ERROR';
        DELETE FROM care_plan_task_req cptr
         WHERE cptr.id_care_plan_task IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                            FROM TABLE(l_care_plan_task) t);
    
        g_error := 'CARE_PLAN_TASK_HIST DELETE ERROR';
        DELETE FROM care_plan_task_hist cpth
         WHERE cpth.id_care_plan_task IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                            FROM TABLE(l_care_plan_task) t);
    
        g_error := 'CARE_PLAN_TASK DELETE ERROR';
        DELETE FROM care_plan_task cpt
         WHERE cpt.id_care_plan_task IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                           FROM TABLE(l_care_plan_task) t);
    
        g_error := 'CARE_PLANDELETE ERROR';
        DELETE FROM care_plan cp
         WHERE cp.id_episode IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                   FROM TABLE(i_episode) t)
            OR (cp.id_episode IS NULL AND
               cp.id_patient IN (SELECT * /*+opt_estimate (table t rows=1)*/
                                    FROM TABLE(i_patient) t));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'RESET_CARE_PLANS',
                                              o_error);
            RETURN FALSE;
    END reset_care_plans;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

/* g_yes := 'Y';
    g_no  := 'N';

    g_relevant_disease := 'R';
    g_diagnosis        := 'D';
    g_allergy          := 'A';

    g_appointments          := 'PS';
    g_spec_appointments     := 'PZ';
    g_followup_appointments := 'PF';
    g_opinions              := 'O';
    g_analysis              := 'A';
    g_group_analysis        := 'AG';
    g_exams                 := 'E';
    g_imaging_exams         := 'EI';
    g_other_exams           := 'EO';
    g_procedures            := 'OP';
    g_patient_education     := 'ED';
    g_medication            := 'M';
    g_ext_medication        := 'ME';
    g_int_medication        := 'ML';
    g_pharm_medication      := 'MF';
    g_ivfluids_medication   := 'MP';
    g_diets                 := 'DP';

    g_doctor       := 'D';
    g_nurse        := 'N';
    g_social       := 'S';
    g_case_manager := 'Q';

    g_active   := 'A';
    g_inactive := 'I';

    g_pending     := 'P';
    g_ordered     := 'R';
    g_inprogress  := 'E';
    g_suspended   := 'S';
    g_finished    := 'F';
    g_interrupted := 'I';
    g_canceled    := 'C';

    g_day   := 1039;
    g_week  := 10375;
    g_month := 1127;
    g_year  := 10373;*/

END pk_care_plans_api_db;
/
