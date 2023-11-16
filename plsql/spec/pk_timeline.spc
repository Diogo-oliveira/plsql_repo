/*-- Last Change Revision: $Rev: 2029010 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_timeline IS

    -- Author  : CARLOS.VIEIRA
    -- Created : 15-04-2008 10:24:45
    -- Purpose : Timeline plsql code

    -- Alexandre Santos 05-01-2010 type used by get_timeline_details
    TYPE t_rec_timeline_detail IS RECORD(
        id_episode        episode.id_episode%TYPE,
        id_professional   professional.id_professional%TYPE,
        visit_type        VARCHAR2(4000),
        visit_information VARCHAR2(4000),
        nick_name         VARCHAR2(4000),
        id_report         sys_config.value%TYPE,
        dt_begin          VARCHAR2(30),
        dt_end            VARCHAR2(30),
        dt_begin_tstz     episode.dt_begin_tstz%TYPE,
        dt_end_tstz       episode.dt_end_tstz%TYPE,
        id_software       epis_info.id_software%TYPE,
        desc_timeline     VARCHAR2(4000));

    TYPE t_cur_timeline_detail IS REF CURSOR RETURN t_rec_timeline_detail;

    --- Local Variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_ret           BOOLEAN;
    --
    g_tab_reg_scale     tl_tab_reg_scale := tl_tab_reg_scale(tl_reg_scale(NULL, NULL, NULL, NULL, NULL));
    g_tab_reg_date      tl_tab_reg_date := tl_tab_reg_date(tl_reg_date(NULL, NULL, NULL, NULL));
    g_tab_reg_date_epis tl_tab_reg_date_epis := tl_tab_reg_date_epis(tl_reg_date_epis(NULL,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      NULL));

    --
    g_intersect_interval  tl_intersect_interval;
    g_tab_inters_interval tl_tab_intersect_interval := tl_tab_intersect_interval(tl_intersect_interval(NULL,
                                                                                                       NULL,
                                                                                                       NULL,
                                                                                                       NULL,
                                                                                                       NULL,
                                                                                                       NULL,
                                                                                                       NULL,
                                                                                                       NULL,
                                                                                                       NULL,
                                                                                                       NULL,
                                                                                                       NULL,
                                                                                                       NULL));
    --
    g_days_of_two_dec         CONSTANT NUMBER(5) := 7300;
    g_months_of_dec           CONSTANT NUMBER(3) := -120;
    g_one_second              CONSTANT NUMBER(24, 16) := 0.0000115740740740741;
    g_flg_yes                 CONSTANT VARCHAR2(1) := 'Y';
    g_flg_cancel              CONSTANT VARCHAR2(1) := 'C';
    g_flg_normal              CONSTANT VARCHAR2(1) := 'N';
    g_flg_no                  CONSTANT VARCHAR2(1) := 'N';
    g_yes                     CONSTANT BOOLEAN := TRUE;
    g_no                      CONSTANT BOOLEAN := FALSE;
    g_format_mask_hour        CONSTANT VARCHAR2(12) := 'yyyymmddhh24';
    g_format_mask_complete    CONSTANT VARCHAR2(20) := 'YYYYMMDDHH24MISS';
    g_format_mask_day         CONSTANT VARCHAR2(8) := 'yyyymmdd';
    g_format_mask_month       CONSTANT VARCHAR2(6) := 'yyyymm';
    g_format_mask_year        CONSTANT VARCHAR2(4) := 'yyyy';
    g_format_mask_short_hour  CONSTANT VARCHAR2(4) := 'hh24';
    g_format_mask_task_time   CONSTANT VARCHAR2(8) := 'HH24:MI';
    g_format_mask_short_month CONSTANT VARCHAR2(2) := 'mm';
    g_format_mask_short_day   CONSTANT VARCHAR2(2) := 'dd';
    g_daily_hours             CONSTANT NUMBER(24) := 24;
    --
    g_dummy_big_number   CONSTANT NUMBER(24) := 999999999999999999999999; --Maior episodio possivel
    g_dummy_short_number CONSTANT NUMBER(24) := 0; --Menor episodio possivel
    g_timeline_episode   CONSTANT NUMBER(1) := 1;
    g_date_hour_format   CONSTANT VARCHAR2(16) := 'DATE_HOUR_FORMAT';
    g_tl_report          CONSTANT VARCHAR2(10) := 'TL_REPORT';
    g_software_assist    CONSTANT VARCHAR2(18) := 'SOFTWARE_ID_ASSIST';
    g_catg_surg_resp     CONSTANT category_sub.id_category%TYPE := 1;
    g_cancel             CONSTANT VARCHAR2(1) := 'C';
    g_oris_soft          CONSTANT NUMBER(2) := 2;
    g_outp_soft          CONSTANT NUMBER(2) := 1;
    g_pp_soft            CONSTANT NUMBER(2) := 12;
    g_care_soft          CONSTANT NUMBER(2) := 3;

    --
    g_tl_episodes  CONSTANT NUMBER(2) := 1;
    g_tl_tasks     CONSTANT NUMBER(2) := 2;
    g_tl_lab_tests CONSTANT NUMBER(2) := 3;
    g_tl_docs      CONSTANT NUMBER(2) := 6;
    --
    -- THIS BLOCK OF CODE IS TEMPORARY
    g_epis_posit_plan_flg_e  CONSTANT VARCHAR2(1) := 'E';
    g_epis_posit_plan_flg_f  CONSTANT VARCHAR2(1) := 'F';
    g_epis_posit_plan_flg_i  CONSTANT VARCHAR2(1) := 'I';
    g_epis_posit_plan_flg_r  CONSTANT VARCHAR2(1) := 'R';
    g_epis_posit_flg_statu_e CONSTANT VARCHAR2(1) := 'E';
    g_epis_posit_flg_statu_r CONSTANT VARCHAR2(1) := 'R';
    g_epis_posit_flg_statu_f CONSTANT VARCHAR2(1) := 'F';
    g_epis_posit_flg_statu_i CONSTANT VARCHAR2(1) := 'I';
    g_epis_hidrics_flg_sta_e CONSTANT VARCHAR2(1) := 'E';
    g_epis_hidrics_flg_sta_r CONSTANT VARCHAR2(1) := 'R';
    g_epis_hidrics_flg_sta_i CONSTANT VARCHAR2(1) := 'I';
    g_epis_hidrics_flg_sta_f CONSTANT VARCHAR2(1) := 'F';
    g_image_value            CONSTANT VARCHAR2(1) := 'D';
    g_posit_icon             CONSTANT VARCHAR2(200) := 'PositioningsIcon';
    g_hidrics_icon           CONSTANT VARCHAR2(200) := 'HydricBalanceIcon';
    --
    g_exception EXCEPTION;
    g_error VARCHAR2(4000);
    g_general_error CONSTANT VARCHAR2(16) := 'COMMON_M001';

    --- funções
    /*******************************************************************************************************************************************
    *GET_EPISODES Função que devolve a informação relativa a episodios                                                                         *
    *                                                                                                                                          *
    * @param I_LANG                   ID da linguagem para traduções                                                                           *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    * @param I_PATIENT                Número de blocos de informação pedidos                                                                   *
    * @param O_EPISODE                Info about episodes                                                                                      *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Devolve false em caso de erro e true caso contrário                                                      *
    *                                                                                                                                          *
    * @raises                         Erro genérico de oracle                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/05/26                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_episodes
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN NUMBER,
        id_tl_scale IN NUMBER,
        o_episode   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    *enable_disable_scale Returns a flag to enable or disable scales                                                                           *
    *                                                                                                                                          *
    * @param I_LANG                   ID da linguagem para traduções                                                                           *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    * @param I_DT_BIRTH               birth date                                                                                               *
    * @param   I_ID_SCALE             Scale ID                                                                                                 *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         flag to enable or disable scales                                                                         *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/05/08                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION enable_disable_scale
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_birth IN DATE,
        i_id_scale IN NUMBER
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Nome :                          GET_VERTICAL_AXIS                                                                                        *
    * Descrição:  Return the y axis elements                                                                                                   *
    *                                                                                                                                          *
    * @param I_LANG                   ID da linguagem para traduções                                                                           *
    * @param I_PROF                   ID professional, ID institution and ID software information                                              *
    * @param I_ID_TL_TIMELINE           ID da TIMELINE                                                                                           *
    * @param I_ID_PATIENT               ID patient                                                                                               *
    * @param O_ERROR                  Error return                                                                                             *
    * @param O_CURSOR_OUT             Output cursor                                                                                            *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Return false if an error occurred and true otherowise                                                    *
    * @raises                         Generic oracle error                                                                                     *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/17                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_vertical_axis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        i_id_patient     IN NUMBER,
        o_error          OUT t_error_out,
        o_cursor_out     OUT pk_types.cursor_type
    ) RETURN BOOLEAN;
    /*******************************************************************************************************************************************
    * Nome :                          GET_TIMELINE_SCALE                                                                                       *
    * Descrição:  Função que devolve as escalas temporais, parametrizadas para a timeline em questão                                           *
    *                                                                                                                                          *
    * @param I_LANG                   ID da linguagem para traduções                                                                           *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    * @param I_ID_TL_TIMELINE         ID da timeline que esta a ser executada                                                                  *
    * @param I_ID_PATIENT             ID do paciente                                                                                           *
    * @param I_LIST_VISIT             visit ID from all patients available in current grid                                                     *
    * @param C_GET_SCALE              Cursor que devolve a informação para output                                                              *
    * @param O_ERROR                  Devolução do erro                                                                                        *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Retorna False se der erro e true caso contrário                                                          *
    * @raises                         Erro genérico de plsql                                                                                   *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/16                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_time_scale
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_tl_timeline   IN tl_timeline.id_tl_timeline%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_list_visit       IN table_number DEFAULT NULL,
        c_get_scale        OUT pk_types.cursor_type,
        c_get_patient_info OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Nome :                          GET_TASKS_TIMELINE_SCALE
    * Descrição:                      Function that returns temporal scales parametrized for task timeline
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_VISIT_LIST             TABLE_NUMBER with all ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_EPISODE_LIST           TABLE_NUMBER with all ID_EPISODE that should be searched in Task Timeline information (available episodes in current grid)
    * @param I_PATIENT_LIST           TABLE_NUMBER with all ID_PATIENT that should be searched in Task Timeline information (available patients in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param C_GET_SCALE              Cursor with information about temporal scales parametrized for task timeline
    * @param C_GET_PATIENT_INFO       Cursor with information about the oldest and newest task to stored (presented) in timeline
    * @param O_ERROR                  Error information
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/06/06
    *******************************************************************************************************************************************/
    FUNCTION get_tasks_time_scale
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_tl_timeline   IN tl_timeline.id_tl_timeline%TYPE,
        i_id_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_visit_list       IN table_number DEFAULT NULL,
        i_episode_list     IN table_number DEFAULT NULL,
        i_patient_list     IN table_number DEFAULT NULL,
        i_tl_task_list     IN table_number DEFAULT NULL,
        i_ori_type_list    IN table_number DEFAULT NULL,
        c_get_scale        OUT pk_types.cursor_type,
        c_get_patient_info OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    *GET_MULTICHOICE_DATA Output the multichoice lables and values                                                                             *
    *                                                                                                                                          *
    * @param I_PROF                   Profissional, institution and software ID's                                                              *
    * @param I_LANG                   Language id                                                                                              *
    * @param I_ID_TIMELINE            Timeline ID                                                                                              *
    * @param I_ID_EPISODE             Episode ID                                                                                               *
    * @param I_ID_PATIENT             Patient ID                                                                                               *
    * @param I_ID_TL_SCALE            Scale ID                                                                                               *
    * @param O_DT_PRESENT             Present date                                                                                             *
    * @param O_DT_MOST_RECENT_EPIS    Most recent episode date                                                                                 *
    * @param O_DT_PREVIUS_EPISODE     previus episode date                                                                                     *
    * @param O_DT_NEXT_EPISODE        next episode date                                                                                        *
    * @param O_EPISODE_PREVIOUS       id previous episode                                                                                 *
    * @param O_EPISODE_NEXT           id next episode                                                                                   *
    * @param O_EPISODE_MOST_RECENT    id most recent episode                                                                                     *
    * @param O_ERROR                  output error                                                                                             *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Return false if exist an error and true otherwise                                                        *
    *                                                                                                                                          *
    * @raises                         Raise an exception in generic oracle error                                                               *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/30                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_multichoice_data
    (
        i_prof                IN profissional,
        i_lang                IN language.id_language%TYPE,
        i_id_timeline         IN NUMBER,
        i_id_episode          IN NUMBER,
        i_id_patient          IN NUMBER,
        i_id_tl_scale         IN NUMBER,
        o_dt_present          OUT VARCHAR2,
        o_dt_most_recent_epis OUT VARCHAR2,
        o_dt_previus_episode  OUT VARCHAR2,
        o_dt_next_episode     OUT VARCHAR2,
        o_episode_previous    OUT NUMBER,
        o_episode_next        OUT NUMBER,
        o_episode_most_recent OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /*******************************************************************************************************************************************
    *GET_TIMELINE_DETAILS This function return detail form the timeline data                                                                   *
    *                                                                                                                                          *
    * @param I_LANG                   ID language for translations                                                                             *
    * @param I_PROF                   ID professional, ID institution and ID software information                                              *
    * @param I_TL_TIMELINE            Timeline ID                                                                                              *
    * @param I_PATIENT                Patient id                                                                                               *
    * @param O_X_DATA                 Output cursor data                                                                                       *
    * @param O_ERROR                  Output error                                                                                             *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         False in error case true in other case                                                                   *
    *                                                                                                                                          *
    * @raises                         Genéric oracle error                                                                                     *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/05/09                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_timeline_details
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        o_x_data      OUT pk_timeline.t_cur_timeline_detail,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /*******************************************************************************************************************************************
    * Name:                           GET_TL_TASKS
    * Description:                    Function that return the list of available tasks in table TL_TASK for current timeline and professional
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_ID_TL_TIMELINE         Timeline ID: 1-Episode timeline; 2-Task timeline
    * @param O_TL_TASKS               Cursor with information about available tasks in selected task timeline for current professional
    * @param O_ERROR                  Error information
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_ID_TL_TIMELINE         {*} '1' Episode timeline {*} '2' Task timeline
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/03/27
    *******************************************************************************************************************************************/
    FUNCTION get_tl_tasks
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        o_tl_tasks       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_patients_tasks              Function that returns all the information that should be sent to FLASH concerning TASK TIMELINE functionality (function to be call by FLASH)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE_LIST           TABLE_NUMBER with all ID_EPISODE that should be searched in Task Timeline information (available visits in current grid)
    * @param I_VISIT_LIST             TABLE_NUMBER with all ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_PATIENT_LIST           TABLE_NUMBER with all ID_PATIENT that should be searched in Task Timeline information (available patients in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param I_ID_TL_TIMELINE         Timeline ID (This variable should always be 2 - "Task Timeline")
    * @param I_ID_TL_SCALE            Timeline Scales ID
    * @param O_DATE_SERVER            Parameter that returns current server date as a VARCHAR2
    * @param O_PATIENTS_TASK          Cursor that returns available tasks for current visit's and available tl_task's
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_ID_TL_TIMELINE         {*} '1' Episode timeline {*} '2' Task timeline
    * @value I_ID_TL_SCALE            {*} '7' Shift (variable duration) {*} '5' Day {*} '4' Week
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/02
    *******************************************************************************************************************************************/
    FUNCTION get_patients_tasks
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode_list   IN table_number DEFAULT NULL,
        i_visit_list     IN table_number DEFAULT NULL,
        i_patient_list   IN table_number DEFAULT NULL,
        i_tl_task_list   IN table_number DEFAULT NULL,
        i_id_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        i_id_tl_scale    IN NUMBER,
        o_date_server    OUT VARCHAR2,
        o_patients_tasks OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_patient_tasks              Function that returns all the information that should be sent to FLASH concerning TASK TIMELINE functionality
    *                                  for only one patient (episode and visit)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             ID_EPISODE that should be searched in Task Timeline information (available visits in current grid)
    * @param I_ID_VISIT               ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_ID_PATIENT             ID_PATIENT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param O_DATE_SERVER            Parameter that returns current server date as a VARCHAR2
    * @param O_PATIENTS_TASK          Cursor that returns available tasks for current visit's and available tl_task's
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/14
    *******************************************************************************************************************************************/
    FUNCTION get_patient_tasks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN task_timeline_ea.id_episode%TYPE DEFAULT NULL,
        i_id_visit      IN task_timeline_ea.id_visit%TYPE DEFAULT NULL,
        i_id_patient    IN task_timeline_ea.id_patient%TYPE DEFAULT NULL,
        i_tl_task_list  IN table_number DEFAULT NULL,
        o_date_server   OUT VARCHAR2,
        o_patient_tasks OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_TASKS_SHORTCUTS             Function that returns information about the id_shortcut related with each id_tl_task (task timeline)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_TL_TASKS_SHORTCUTS     Cursor that returns shortcuts (and identifier) for all diferent types of tasks existent in task timeline functionality
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/01
    *******************************************************************************************************************************************/
    FUNCTION get_tasks_shortcuts
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_tl_tasks_shortcuts OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_DATES_DESCRIPTION           Function that returns date information to FLASH in the apropriate format (VARCHAR2)
    *                                 [Example: "12:33h - 14:50h (07-Jan-2009)" (example in portuguese date format)]
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_PARENTESIS             Indicates if day date should appear inside parentesis after hour
    * @param I_DT_BEGIN               Expected start date
    * @param I_DT_END                 Expected end date
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns STRING with date information if success, otherwise returns '' (empty string)
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/14
    *******************************************************************************************************************************************/
    FUNCTION get_dates_description
    (
        i_lang       language.id_language%TYPE,
        i_prof       profissional,
        i_parentesis IN VARCHAR2,
        i_dt_begin   IN VARCHAR2,
        i_dt_end     IN VARCHAR2
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * GET_TOKEN              Function that returns STRING in position X separated by one delimitator Y
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_LIST                   Strings (with an list of strings separated by one delimitator)
    * @param I_INDEX                  Desired position in string
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns DATE STRING in position X of I_LIST
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/19
    *******************************************************************************************************************************************/

    FUNCTION get_token
    (
        i_lang  IN language.id_language%TYPE,
        i_list  IN VARCHAR2,
        i_index IN NUMBER,
        i_delim IN VARCHAR2 DEFAULT ','
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Create for configuration of timeline verticla axis(softwares)
    *
    * @author                                  Rui Duarte
    * @version                                 0.1
    * @since                                   2010/11/09
    ********************************************************************************************/

    FUNCTION insert_into_tl_vertical_axis
    (
        i_tl_software    IN software.id_software%TYPE,
        i_rank           IN tl_va_inst_soft_market.rank%TYPE DEFAULT NULL,
        i_id_institution IN institution.id_institution%TYPE DEFAULT 0,
        i_id_software    IN software.id_software%TYPE DEFAULT 0,
        i_id_market      IN market.id_market%TYPE DEFAULT 0,
        i_flg_available  IN tl_va_inst_soft_market.flg_available%TYPE DEFAULT 'Y',
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_patient_tasks_pdms          Function that returns all the information that should be sent to FLASH concerning TASK TIMELINE functionality
    *                                 for only one patient (episode and visit)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             ID_EPISODE that should be searched in Task Timeline information (available visits in current grid)
    * @param I_ID_VISIT               ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param I_FLG_METHOD             'R' - Filter by requisition date / 'E' - Filter by execution date
    * @param I_DT_START               Date to filter (lower limit)
    * @param I_DT_END                 Date to filter (higher limit)
    * @param O_DATE_SERVER            Parameter that returns current server date as a VARCHAR2
    * @param O_PATIENTS_TASK          Cursor that returns available tasks for current visit's and available tl_task's
    * @param O_CUR_LAST_INFO          Cursor that returns available tasks for current visit's and available tl_task's
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.6.0.4
    * @since                          2010/09/27
    * @dependencies                   PDMS
    *******************************************************************************************************************************************/
    FUNCTION get_patient_tasks_pdms
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN task_timeline_ea.id_episode%TYPE DEFAULT NULL,
        i_id_visit      IN task_timeline_ea.id_visit%TYPE DEFAULT NULL,
        i_tl_task_list  IN table_number DEFAULT NULL,
        i_flg_method    IN VARCHAR2,
        i_dt_start      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        o_date_server   OUT VARCHAR2,
        o_patient_tasks OUT pk_types.cursor_type,
        o_cur_last_info OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_pdms_task_list              Function that returns all the information that should be sent to FLASH concerning TASK TIMELINE functionality
    *                                 for only one patient (episode and visit)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_tl_timeline         Timeline identifier
    * @param O_TASKS                  Cursor that returns the tasks collection
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Rui Teixeira & Miguel Gomes
    * @version                        2.6.3.9
    * @since                          2013/08/28
    * @dependencies                   PDMS
    *******************************************************************************************************************************************/
    FUNCTION get_pdms_task_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_tl_timeline IN tl_task_timeline.id_tl_timeline%TYPE DEFAULT NULL,
        o_tasks          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_prof_epis_type
    (
        i_epis_type    IN NUMBER,
        i_episode      IN NUMBER,
        i_professional IN NUMBER,
        i_nurse        IN NUMBER
    ) RETURN NUMBER;

    -- *****************************************************************
    FUNCTION get_timeline_det_inp_oris
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        o_x_data      OUT pk_timeline.t_cur_timeline_detail,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    
    FUNCTION get_visit_prof_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN VARCHAR2;
END pk_timeline;
/
