CREATE OR REPLACE PACKAGE pk_todo_list IS
    --
    g_error   VARCHAR2(4000);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    --
    g_pending   CONSTANT VARCHAR2(1) := 'P';
    g_depending CONSTANT VARCHAR2(1) := 'D';
    --
    g_prof_cat_d CONSTANT VARCHAR2(1) := 'D';
    g_prof_cat_n CONSTANT VARCHAR2(1) := 'N';
    g_prof_cat_a CONSTANT VARCHAR2(1) := 'A';
    g_prof_cat_o CONSTANT VARCHAR2(1) := 'O';
    --
    g_flg_ehr_n CONSTANT VARCHAR2(1) := 'N';
    --
    g_soft_care  CONSTANT NUMBER(6) := 3;
    g_soft_edis  CONSTANT NUMBER(6) := 8;
    g_soft_inp   CONSTANT NUMBER(6) := 11;
    g_soft_oris  CONSTANT NUMBER(6) := 2;
    g_soft_outp  CONSTANT NUMBER(6) := 1;
    g_soft_pp    CONSTANT NUMBER(6) := 12;
    g_soft_ubu   CONSTANT NUMBER(6) := 29;
    g_soft_nutri CONSTANT NUMBER(6) := 43;
    g_soft_adt   CONSTANT NUMBER(6) := 39;
    --
    g_task_a   CONSTANT VARCHAR2(2) := 'A';
    g_task_ad  CONSTANT VARCHAR2(2) := 'AD';
    g_task_b   CONSTANT VARCHAR2(2) := 'B';
    g_task_br  CONSTANT VARCHAR2(2) := 'BR';
    g_task_co  CONSTANT VARCHAR2(2) := 'CO';
    g_task_dp  CONSTANT VARCHAR2(2) := 'DP';
    g_task_e   CONSTANT VARCHAR2(2) := 'E';
    g_task_ft  CONSTANT VARCHAR2(2) := 'FT';
    g_task_h   CONSTANT VARCHAR2(2) := 'H';
    g_task_ht  CONSTANT VARCHAR2(2) := 'HT';
    g_task_i   CONSTANT VARCHAR2(2) := 'I';
    g_task_ie  CONSTANT VARCHAR2(2) := 'IE';
    g_task_io  CONSTANT VARCHAR2(2) := 'IO';
    g_task_it  CONSTANT VARCHAR2(2) := 'IT';
    g_task_m   CONSTANT VARCHAR2(2) := 'M';
    g_task_mt  CONSTANT VARCHAR2(2) := 'MT';
    g_task_pe  CONSTANT VARCHAR2(2) := 'PE';
    g_task_po  CONSTANT VARCHAR2(2) := 'PO';
    g_task_pr  CONSTANT VARCHAR2(2) := 'PR';
    g_task_pt  CONSTANT VARCHAR2(2) := 'PT';
    g_task_r   CONSTANT VARCHAR2(2) := 'R';
    g_task_so  CONSTANT VARCHAR2(2) := 'SO';
    g_task_fu  CONSTANT todo_task.flg_task%TYPE := 'FU';
    g_task_as  CONSTANT VARCHAR2(2) := 'AS';
    g_task_ref CONSTANT VARCHAR2(2) := 'P1';
    g_task_tr  CONSTANT VARCHAR2(2) := 'TR';
    g_task_nr  CONSTANT VARCHAR2(2) := 'NR';
    g_task_pn  CONSTANT todo_task.flg_task%TYPE := 'PN';
    g_task_hp  CONSTANT todo_task.flg_task%TYPE := 'HP';
    g_task_cr  CONSTANT todo_task.flg_task%TYPE := 'CR'; -- CONSULT REQUEST
    g_task_rh  CONSTANT todo_task.flg_task%TYPE := 'RH';

    -- therapeutic decision
    g_task_td CONSTANT VARCHAR2(2) := 'TD';
    --
    g_flg_time_e CONSTANT VARCHAR2(1) := 'E';
    --
    g_epis_active   CONSTANT VARCHAR2(1) := 'A';
    g_epis_inactive CONSTANT VARCHAR2(1) := 'I';
    g_epis_pending  CONSTANT VARCHAR2(1) := 'P';
    --
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';
    --
    g_flg_available CONSTANT VARCHAR2(1) := 'Y';
    --
    g_profile_pa CONSTANT profile_template.id_profile_template%TYPE := 505;
    g_profile_md CONSTANT profile_template.id_profile_template%TYPE := 35;

    g_co_sign_drug_desc CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_co_sign_drug_time CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_signature_signoff CONSTANT VARCHAR2(10 CHAR) := 'SIGNOFF';
    g_signature_submit  CONSTANT VARCHAR2(20 CHAR) := 'SUBMIT_REVIEW';

    -- Author  : JOSE.BRITO
    -- Created : 19-05-2008 17:16:54
    -- Purpose : Used to list all pending and depending tasks on "To-Do List".

    /******************************************************************************
    * Returns pending and depending tasks to show on To-Do List.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_pending         All pending tasks ("my pending tasks")
    * @param o_depending       All tasks depending on others
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
        o_pending OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --

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
    ) RETURN BOOLEAN;

    FUNCTION get_prof_tasks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_mode          IN VARCHAR2,
        i_prof_cat      IN category.flg_type%TYPE,
        i_flg_type      IN todo_task.flg_type%TYPE,
        i_flg_show_ai   IN VARCHAR2,
        i_hand_off_type IN sys_config.value%TYPE,
        o_tasks         OUT t_todo_list_tbl,
        o_count         OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
    --
    --
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
    ) RETURN NUMBER;
    --
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
    ) RETURN NUMBER;
    --
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
    ) RETURN BOOLEAN;
    --

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
    ) RETURN BOOLEAN;
    --
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
    ) RETURN VARCHAR2;

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
    );

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
    ) RETURN NUMBER;
    --

    --
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
    ) RETURN BOOLEAN;
    --
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
    ) RETURN BOOLEAN;

    FUNCTION get_todo_list_base
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_mode  IN VARCHAR2,
        o_rows  OUT t_todo_list_tbl,
        o_count OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_task_base01
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_flg_type IN todo_task.flg_type%TYPE
    ) RETURN todo_list_01_tbl;

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
    ) RETURN NUMBER;

    FUNCTION get_prof_tasks_transform
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_flg_type IN todo_task.flg_type%TYPE,
        --i_flg_show_ai   IN VARCHAR2,
        i_hand_off_type IN sys_config.value%TYPE,
        i_tbl_data      IN todo_list_01_tbl
    ) RETURN t_todo_list_tbl;

    FUNCTION get_prof_task_base02
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_flg_type IN todo_task.flg_type%TYPE
    ) RETURN todo_list_01_tbl;


END pk_todo_list;
/
