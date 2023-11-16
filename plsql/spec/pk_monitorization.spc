/*-- Last Change Revision: $Rev: 2028805 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_monitorization AS

    TYPE t_rec_monitorization IS RECORD(
        date_begin        TIMESTAMP(6) WITH LOCAL TIME ZONE,
        date_end          TIMESTAMP(6) WITH LOCAL TIME ZONE,
        desc_interval     VARCHAR2(1000 CHAR),
        desc_vs           CLOB,
        dt_order          TIMESTAMP(6) WITH LOCAL TIME ZONE,
        id_professional   monitorization.id_professional%TYPE,
        id_monitorization monitorization.id_monitorization%TYPE);

    TYPE t_cur_monitorization IS REF CURSOR RETURN t_rec_monitorization;
    TYPE t_tbl_monitorization IS TABLE OF t_rec_monitorization;

    --
    -- PUBLIC FUNCTIONS
    -- 

    FUNCTION create_monitor_req
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN monitorization.id_episode%TYPE,
        i_prof          IN profissional,
        i_dt_begin_str  IN VARCHAR2,
        i_interval      IN VARCHAR2,
        i_dt_end_str    IN VARCHAR2,
        i_notes         IN CLOB,
        i_flg_time      IN monitorization.flg_time%TYPE,
        i_id_vs         IN table_number,
        i_notes_detail  IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_prof_order    IN monitorization_vs.id_prof_order%TYPE := NULL,
        i_dt_order_str  IN VARCHAR2 := NULL,
        i_order_type    IN monitorization_vs.id_order_type%TYPE := NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_monitor_req
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN monitorization.id_episode%TYPE,
        i_prof              IN profissional,
        i_dt_begin_str      IN VARCHAR2,
        i_interval          IN VARCHAR2,
        i_dt_end_str        IN VARCHAR2,
        i_notes             IN CLOB,
        i_flg_time          IN monitorization.flg_time%TYPE,
        i_id_vs             IN table_number,
        i_notes_detail      IN table_varchar,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_prof_order        IN monitorization_vs.id_prof_order%TYPE := NULL,
        i_dt_order_str      IN VARCHAR2 := NULL,
        i_order_type        IN monitorization_vs.id_order_type%TYPE := NULL,
        i_commit_data       IN VARCHAR2,
        o_id_monitorization OUT monitorization.id_monitorization%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_aux_monitor
    (
        i_lang          IN language.id_language%TYPE,
        i_id_monitor_vs IN monitorization_vs.id_monitorization_vs%TYPE,
        i_prof          IN profissional,
        i_dt_first_read IN VARCHAR2,
        o_monitor       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_monitor_req
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_monitor OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Get requests monitoring of vital signs in an episode (Guided for consultation visit)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_SCOPE                  Scope ID (E-Episode ID, V-Visit ID, P-Patient ID)
    * @param I_FLG_SCOPE              Flag Scope (E-Episode ID, V-Visit ID, P-Patient ID)
    * @param I_START_DATE             Start date for temporal filtering
    * @param I_END_DATE               End date for temporal filtering
    * @param I_CANCELLED              Indicates whether the records should be returned canceled ('Y' - Yes, 'N' - No)
    * @param I_CRIT_TYPE              Flag that indicates if the filter time to consider all records or only during the executions ('A' - All, 'E' - Executions, ...)
    * @param I_FLG_REPORT             Flag used to remove formatting ('Y' - Yes, 'N' - No)
    * @param I_ID_EPIS_TYPE           Type of episode
    * @param O_MONITOR                Cursor that returns monitorizations
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_FLG_SCOPE              {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient'
    * @value I_CANCELLED              {*} 'Y' YES {*} 'N' NO
    * @value I_CRIT_TYPE              {*} 'A' All {*} 'R' Requisitions {*} 'E' Executions
    * @value I_FLG_REPORT             {*} 'Y' YES {*} 'N' NO
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                         António Neto
    * @version                        2.6.1.5
    * @since                          07-Nov-2011
    *******************************************************************************************************************************************/
    FUNCTION get_monitor_req
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_scope        IN NUMBER,
        i_flg_scope    IN VARCHAR2,
        i_start_date   IN VARCHAR2,
        i_end_date     IN VARCHAR2,
        i_cancelled    IN VARCHAR2,
        i_crit_type    IN VARCHAR2,
        i_flg_report   IN VARCHAR2,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_flg_status   IN table_varchar DEFAULT NULL,
        o_monitor      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_monitor_req_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        o_flg_status        OUT monitorization.flg_status%TYPE,
        o_status_string     OUT VARCHAR2,
        o_flg_finished      OUT VARCHAR2,
        o_flg_canceled      OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_monitor_vs_req
    (
        i_lang          IN language.id_language%TYPE,
        i_id_monitor_vs IN monitorization_vs.id_monitorization_vs%TYPE,
        i_prof          IN profissional,
        o_monitor       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Get details of a monitoring (Return information related to who requested the procedure - != Who registered)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_MONITOR_VS          ID Vital Sign Monitor request
    * @param I_SCOPE                  Scope ID (E-Episode ID, V-Visit ID, P-Patient ID)
    * @param I_FLG_SCOPE              Flag Scope (E-Episode ID, V-Visit ID, P-Patient ID)
    * @param I_START_DATE             Start date for temporal filtering
    * @param I_END_DATE               End date for temporal filtering
    * @param I_CANCELLED              Indicates whether the records should be returned canceled ('Y' - Yes, 'N' - No)
    * @param I_CRIT_TYPE              Flag that indicates if the filter time to consider all records or only during the executions ('A' - All, 'E' - Executions, ...)
    * @param I_FLG_REPORT             Flag used to remove formatting ('Y' - Yes, 'N' - No)
    * @param O_MONITOR                Cursor that returns request detail
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_FLG_SCOPE              {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient'
    * @value I_CANCELLED              {*} 'Y' YES {*} 'N' NO
    * @value I_CRIT_TYPE              {*} 'A' All {*} 'R' Requisitions {*} 'E' Executions
    * @value I_FLG_REPORT             {*} 'Y' YES {*} 'N' NO
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                         António Neto
    * @version                        2.6.1.5
    * @since                          07-Nov-2011
    *******************************************************************************************************************************************/
    FUNCTION get_monitor_vs_req
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_monitor_vs IN monitorization_vs.id_monitorization_vs%TYPE,
        i_scope         IN NUMBER,
        i_flg_scope     IN VARCHAR2,
        i_start_date    IN VARCHAR2,
        i_end_date      IN VARCHAR2,
        i_cancelled     IN VARCHAR2,
        i_crit_type     IN VARCHAR2,
        i_flg_report    IN VARCHAR2,
        o_monitor       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_monitor_vs_result
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_monitorization_vs IN monitorization_vs.id_monitorization_vs%TYPE,
        i_prof                 IN profissional,
        o_monitor              OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vs_monitor
    (
        i_lang              IN language.id_language%TYPE,
        i_id_monitorization IN monitorization_vs.id_monitorization%TYPE,
        i_prof              IN profissional,
        o_vs                OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_monitor_req
    (
        i_lang              IN language.id_language%TYPE,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        i_prof              IN profissional,
        i_notes             IN monitorization.notes_cancel%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_commit_data       IN VARCHAR2,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * cancel monitorization and vital signs with commit as (Y)es
    *
    * @param i_lang                   preferred language id for this professional
    * @param i_prof                   profissional type
    * @param i_id_monitorization      monitorization id
    * @param i_notes                  notes for cancel
    * @param i_prof_cat_type          profissional category internal flag
    * @param o_error                  error message
    *
    * @return boolean                 true on success, otherwise false
    *
    * @author                         Filipe Machado
    * @version                        2.5.0.7.3
    * @since                          2009/11/26
    **********************************************************************************************/
    FUNCTION cancel_monitor_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        i_notes             IN monitorization.notes_cancel%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_monitor_vs_req
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_monitorization_vs IN monitorization_vs.id_monitorization_vs%TYPE,
        i_prof                 IN profissional,
        i_notes                IN monitorization_vs.notes_cancel%TYPE,
        i_prof_cat_type        IN category.flg_type%TYPE,
        i_id_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Cancelar requisição de monitorização de sinais vitais
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_ID_MONITORIZATION  - ID da requisicao
                     I_PROF - Profissional que faz o cancelamento
                 I_NOTES - Notas de cancelamento
                 I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                           como é retornada em PK_LOGIN.GET_PROF_PREF
                  I_COMMIT_DATA - Flag que indica se a função deve fazer o commit dos dados
                  I_ID_CANCEL_REASON - Id da cancel reason associada
                  I_PROF_ORDERED - Profissional que ordenou oI_PROF_ORDERED
                  I_DT_ORDERED - Data em que ordernou
      I_DT_ORDEREDI_ORDER_TYPE - Qual o tipo de ordem - order type id
              Saida:  O_ERROR - erro
    
      CRIAÇÃO: RB 2005/05/19
    *********************************************************************************/
    FUNCTION cancelmonitorreq
    (
        i_lang              IN language.id_language%TYPE,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        i_prof              IN profissional,
        i_notes             IN monitorization.notes_cancel%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_commit_data       IN VARCHAR2,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_prof_order        IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order          IN co_sign.dt_ordered_by%TYPE,
        i_order_type        IN order_type.id_order_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Registo de SVs atraves da monitorizao
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_prof                   professional, software and institution ids
    * @param i_pat                    patient id
    * @param i_vs_id                  array de IDs de SVs
    * @param i_vs_val                 array de valores lidos (valores registados no keypad, ou ID do descritivo)
    * @param i_id_monit               monitorization id
    * @param i_dt_plan_str            data da proxima leitura. Pode vir NULL, se o keypad for usado.
    * @param i_prof_cat_type          category of professional
    * @param i_prof_performed         professional performed
    * @param i_start_time             start time of execution intervention
    * @param i_end_time               end time of execution intervention
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Claudia Silva
    * @version                        1.0
    * @since                          2005/07/28
    **********************************************************************************************/
    FUNCTION set_monitor_vs_read
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_dt_vs_read         IN table_varchar,
        i_id_monit           IN monitorization.id_monitorization%TYPE,
        i_dt_plan_str        IN VARCHAR2,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_prof_performed     IN monitorization_vs_plan.id_prof_performed%TYPE,
        i_start_time         IN VARCHAR2,
        i_end_time           IN VARCHAR2,
        i_unit_meas_sel      IN table_number,
        i_tbtb_attribute     IN table_table_number,
        i_tbtb_free_text     IN table_table_clob,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_monit_time
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_time  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO: Obter concatenação dos descritivos dos SVs requisitados numa monitorização
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_MONITORIZATION - ID da monitorização
                             I_PROF - profissional
                             i_flg_only_active - Y - Do not return cancelled registries. N - returns records in all status
              Saida: O_DESC - concatenação dos descritivos dos SVs
                         O_ERROR - erro
      CRIAÇÃO: CRS 2006/09/05
      NOTAS:
    *********************************************************************************/
    FUNCTION get_vs_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_monitorization  IN monitorization.id_monitorization%TYPE,
        i_prof            IN profissional,
        i_flg_only_active IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Actualizar o episódio de origem na monitorizacao de sinais vitais bem como as respectivas tabelas de relacao.
      Aquando a passagem de Urgencia para Internamento sera necessario actualizar o ID_EPISODE na monitorizacao de sinais vitais
      com o novo episodio (INP) e o ID_EPISODE_ORIGIN ficara com o episodio de urgencia (EDIS)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          category of professional
    * @param i_episode                episode id
    * @param i_new_episode            new episode id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emilia Taborda
    * @version                        1.0
    * @since                          2007/02/19
    **********************************************************************************************/
    FUNCTION update_monitorization
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_new_episode   IN episode.id_episode%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Detalhe de cada resultado da monitorizacao
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_monitorization_vs_plan Id do plano da monitorizacao a detalhar
    * @param o_monitor_det            array com o detalhe da monitorizacao
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emilia Taborda
    * @version                        1.0
    * @since                          2007/10/16
    **********************************************************************************************/
    FUNCTION get_monitor_vs_result_det
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_monitorization_vs_plan IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        o_monitor_det            OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************************************
    *
    * From now on, these functions were cretead in the CPOE context
    *
    ***********************************************************************************************/

    /**********************************************************************************************
    * create draft task (CPOE purpose)
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_episode                episode id
    * @param       ...                      monitorization 
    * @param       o_draft                  list of created drafts
    * @param       o_error                  error message
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Filipe Machado
    * @version                              2.5.0.7.5
    * @since                                2009/12/14
    **********************************************************************************************/
    FUNCTION create_draft
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN monitorization.id_episode%TYPE,
        i_dt_begin_str  IN VARCHAR2,
        i_interval      IN VARCHAR2,
        i_dt_end_str    IN VARCHAR2,
        i_notes         IN CLOB,
        i_flg_time      IN monitorization.flg_time%TYPE,
        i_id_vs         IN table_number,
        i_notes_detail  IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_prof_order    IN monitorization_vs.id_prof_order%TYPE := NULL,
        i_dt_order_str  IN VARCHAR2 := NULL,
        i_order_type    IN monitorization_vs.id_order_type%TYPE := NULL,
        o_draft         OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * cancel = delete a draft task (CPOE purpose)
    *
    * @param          i_lang                   preferred language id for this professional
    * @param          i_prof                   professional type
    * @param          i_episode                episode id
    * @param          i_draft                  list of draft ids
    * @param          o_error                  error message
    *
    * @return         boolean                  true on success, otherwise false
    *
    * @author                                  Filipe Machado
    * @version                                 2.5.0.7.3
    * @since                                   2009/11/17
    **********************************************************************************************/
    FUNCTION cancel_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * get task parameters (CPOE purpose)
    * in other words, get task parameters needed to fill task edit screens (critical for draft editing)
    *
    * NOTE: this function can be replaced by several functions that returns the required values,  
    *       according to current task workflow edit screens
    *
    * @param           i_lang                   preferred language id for this professional
    * @param           i_prof                   professional type
    * @param           i_episode                episode id
    * @param           i_id_monitorization      monitorization id
    * @param           o_monitor                monitorization cursor info 
    * @param           o_actions                actions cursor info
    * @param           o_error                  error message
    *
    * @return          boolean                  true on success, otherwise false
    *
    * @author                                   Filipe Machado
    * @version                                  2.5.0.7.3
    * @since                                    2009/11/17
    **********************************************************************************************/
    FUNCTION get_task_parameters
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        o_monitor           OUT pk_types.cursor_type,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * set task parameters (CPOE purpose)
    * set task parameters changed in task edit screens (critical for draft editing)
    *   
    * NOTE: this function can be replaced by several functions that update the required values,  
    *       according to current task workflow edit screens 
    *
    * @param          i_lang                   preferred language id for this professional
    * @param          i_prof                   professional type
    * @param          i_episode                episode id
    * ...
    * @param          o_error                  error message
    *
    * @return         boolean                  true on success, otherwise false
    *
    * @author                                  Filipe Machado
    * @version                                 2.5.0.7.5
    * @since                                   2009/12/11
    **********************************************************************************************/
    FUNCTION set_task_parameters
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        i_episode           IN monitorization.id_episode%TYPE,
        i_dt_begin_str      IN VARCHAR2,
        i_interval          IN VARCHAR2,
        i_dt_end_str        IN VARCHAR2,
        i_notes             IN CLOB,
        i_flg_time          IN monitorization.flg_time%TYPE,
        i_id_vs             IN table_number,
        i_notes_detail      IN table_varchar,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_prof_order        IN monitorization_vs.id_prof_order%TYPE := NULL,
        i_dt_order_str      IN VARCHAR2 := NULL,
        i_order_type        IN monitorization_vs.id_order_type%TYPE := NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * get available actions for a requested task 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id 
    * @param       i_task_request            task request id (also used for drafts) 
    * @param       o_actions_list            list of available actions for the task request 
    * @param       o_error                   error message 
    * 
    * @return      boolean                   true on success, otherwise false     
    *
    * @author                                Filipe Machado
    * @version                               2.5.0.7.3
    * @since                                 2009/11/18
    ********************************************************************************************/
    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_actions_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * activate a draft = change status from 'R' to 'A' (CPOE purpose)
    * in other words, activates a set of draft tasks (task goes from draft to active workflow) 
    *
    * @param          i_lang                   preferred language id for this professional
    * @param          i_prof                   professional type
    * @param          i_episode                episode id
    * @param          i_draft                  id monitorizations collection (drafts)
    * @param          i_flg_commit             transaction control
    * @param          o_created_drafts         array of created task requests
    * @param          o_error                  error message
    *
    * @value          i_flg_commit             {*} 'Y' commit/rollback the transaction
    *                                          {*} 'N' transaction control is done outside
    *
    * @return         boolean                  true on success, otherwise false
    *
    * @author                                  Filipe Machado
    * @version                                 2.5.0.7.3
    * @since                                   18-Nov-2009
    *
    * @author                                  Filipe Machado
    * @version                                 2.5.1.1
    * @changed                                 15-Sep-2010 (new parameter, o_created_tasks, was added)
    **********************************************************************************************/
    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * copy task to draft (from an existing active/inactive task) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id (current episode) 
    * @param       i_task_request            task request id (used for active/inactive tasks) 
    * @param       o_draft                   draft id 
    * @param       o_error                   error message 
    * 
    * @return      boolean                   true on success, otherwise false  
    *
    * @author                                Filipe Machado
    * @version                               2.5.0.7.3
    * @since                                 2009/11/18   
    ********************************************************************************************/
    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * CPOE - Computerized physician order entry
    * This function only is used for CPOE feature
    * It retrieves the monitorizations list in order to show in CPOE grid without timing filters
    *
    * @param        i_lang                   the id language
    * @param        i_prof                   professional, software and institution ids
    * @param        i_patient                patient id
    * @param        i_episode                episode id
    * @param        i_task_request           array of task request (if null, return all tasks as usual)
    * @param        i_flg_report             required in all get_task_list APIs
    * @param        o_grid                   array with monitorizations list
    * @param        o_error                  Error message
    *
    * @return       boolean                  TRUE if sucess, FALSE otherwise
    *                        
    * @author                                Filipe Machado
    * @version                               1.0
    * @since                                 2009/11/18
    **********************************************************************************************/
    FUNCTION get_task_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_flg_report   IN VARCHAR2 DEFAULT 'N',
        o_grid         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * CPOE - Computerized physician order entry
    * This function only is used for CPOE feature
    * It retrieves the monitorizations list in order to show in CPOE grid with timing filters
    *
    * @param        i_lang                   the id language
    * @param        i_prof                   professional, software and institution ids
    * @param        i_patient                patient id
    * @param        i_episode                episode id
    * @param        i_task_request           array of task request (if null, return all tasks as usual)
    * @param        i_flg_report             required in all get_task_list APIs
    * @param        o_grid                   array with monitorizations list
    * @param        o_error                  Error message
    *
    * @return       boolean                  TRUE if sucess, FALSE otherwise
    *                        
    * @author                                Filipe Machado
    * @version                               1.0
    * @since                                 12-Jul-2010
    **********************************************************************************************/
    FUNCTION get_task_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        i_flg_report    IN VARCHAR2 DEFAULT 'N',
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_plan_list     OUT pk_types.cursor_type,
        o_grid          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * check conflicts upon created drafts (verify if drafts can be requested or not) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_draft                   draft id 
    * @param       o_flg_conflict            array of draft conflicts indicators 
    * @param       o_msg_title               array of message titles 
    * @param       o_msg_text                array of message texts 
    * @param       o_button                  array of buttons to show (it can have more than one button) 
    * @param       o_error                   error message 
    * 
    * @value       o_flg_conflict            {*} 'Y' the draft has conflicts  
    *                                        {*} 'N' no conflicts found 
    *    
    * @value       o_button                  {*} 'N' NO button is displayed 
    *                                        {*} 'R' READ button is displayed    
    *                                        {*} 'C' CONFIRM button is displayed 
    *                                        {*} Example: 'NC' NO/CONFIRM buttons are displayed 
    *         
    * @return      boolean                   true on success, otherwise false     
    *
    * @author                                Filipe Machado
    * @version                               2.5.0.7.3
    * @since                                 2009/11/18
    ********************************************************************************************/
    FUNCTION check_drafts_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_text     OUT table_varchar,
        o_button       OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * validate the request of the monitorization
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_monit                  monitorization type
    *
    * @return      varchar2                 'Y' on success, otherwise 'N'
    *
    * @author                               Filipe Machado
    * @version                              2.5.0.7.3
    * @since                                2009/11/17
    **********************************************************************************************/
    FUNCTION validate_monitor_req2
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_monitorization IN monitorization.id_monitorization%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Append the monitorization vital signs in a string (used for drafts)
    *
    * @param        i_lang                   the id language
    * @param        i_prof                   professional, software and institution ids
    * @param        i_visit                  visit id
    * @param        i_id_epis_type           episode type id
    * @param        i_monitorization         monitoring id
    * @param        i_task_request           array with drafts id's
    *
    * @return       varchar2                 vital signs string separated by semi-colon
    *                        
    * @author                                Filipe Machado
    * @version                               1.0
    * @since                                 2009/12/10
    **********************************************************************************************/
    FUNCTION concat_monit_vs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_visit          IN visit.id_visit%TYPE,
        l_id_epis_type   IN episode.id_epis_type%TYPE,
        i_monitorization IN monitorization.id_monitorization%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * It retrieves the monitorization VS details (CPOE purpose) 
    *
    * @param        i_lang                   the id language
    * @param        i_prof                   professional, software and institution ids
    * @param        i_monitorization         monitorization id
    * @param        o_monit_vs               array with monitorizations vs list
    * @param        o_error                  Error message
    *
    * @return       boolean                  TRUE if sucess, FALSE otherwise
    *                        
    * @author                                Filipe Machado
    * @version                               2.5.0.7.5
    * @since                                 2009/12/04
    **********************************************************************************************/
    FUNCTION get_monit_vs_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_monitorization IN monitorization.id_monitorization%TYPE,
        o_monit_vs       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * It retrieves the id professional that ordered the monitorization
    *
    * @param        id_monitorization        monitorization ID
    *
    * @return       id_professional          professional ID
    *                        
    * @author                                Filipe Machado
    * @version                               1.0
    * @since                                 11-Mar-2010
    **********************************************************************************************/

    FUNCTION get_prof_ordered_by(id_monit IN monitorization.id_monitorization%TYPE)
        RETURN professional.id_professional%TYPE;

    /**********************************************************************************************
    * It retrieves the monitorization professional ID (the prof order or last prof performeced)
    *
    * @param        id_monitorization        monitorization ID
    *
    * @return       id_professional          professional ID
    *                        
    * @author                                Vanessa Barsottelli
    * @version                               1.0
    * @since                                 01-12-2016
    **********************************************************************************************/
    FUNCTION get_monit_prof(i_id_monitorization IN monitorization.id_monitorization%TYPE)
        RETURN professional.id_professional%TYPE;

    /*
    * Provide list of ongoing tasks for the patient death feature. All the monits in this list must be possible to cancel.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_PATIENT         Patient ID
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   11-MAY-2010
    *
    */
    FUNCTION get_ongoing_tasks_monit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list;

    /*
    * Provide list of MONITORIZATION tasks for a given status
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WF_STATUS          Status for tasks
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_monit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list;

    /*
    * Suspend the ongoing tasks - Monitorization
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_TASK               ID from the corresponding task
    * @param   I_FLG_REASON         Reason for the WF suspension: 'D' (Death)
    * @param   O_MSG_ERROR          Message to send to the UX in case one of the functions has some kind of error
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   13-MAY-2010
    *
    */
    FUNCTION suspend_task_monit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task       IN NUMBER,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Reactivate the ongoing tasks - Monitorization
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_TASK               ID from the corresponding task
    * @param   O_MSG_ERROR          Message to send to the UX in case one of the functions has some kind of error
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   21-MAY-2010
    *
    */
    FUNCTION reactivate_task_monit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task      IN NUMBER,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    *
    * This function only is used for CPOE feature
    * get tasks status based in their request
    *
    * @param        i_lang                   the id language
    * @param        i_prof                   professional, software and institution ids
    * @param        i_episode                episode id
    * @param        i_task_request           array of task request
    * @param        o_task_status            cursor with all requested tast status
    * @param        o_error                  error structure for exception handling
    *
    * @return       boolean                  TRUE if sucess, FALSE otherwise
    *                        
    * @author                                Filipe Machado
    * @version                               1.0
    * @since                                 14-Sep-2010
    **********************************************************************************************/

    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * 
    * This function only is used for CPOE feature
    * cancel all draft tasks
    *
    * @param        i_lang                   the id language
    * @param        i_prof                   professional, software and institution ids
    * @param        i_episode                episode id
    * @param        o_error                  error structure for exception handling
    *
    * @return       boolean                  TRUE if sucess, FALSE otherwise
    *                        
    * @author                                Filipe Machado
    * @version                               1.0
    * @since                                 14-Sep-2010
    **********************************************************************************************/
    FUNCTION cancel_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * expire a requested task 
    * as far as we know, this is not necessary for monitorizations
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id 
    * @param       i_task_request            task request ids 
    * @param       o_error                   error message 
    * 
    * @return      boolean                   true on success, otherwise false     
    *
    * @author                                Nuno Neves
    * @version                               2.6.0.5.1.4
    * @since                                 2011/01/21
    ********************************************************************************************/
    FUNCTION expire_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * 
    * This function only is used for H AND P feature
    * get the the monitoring description
    *
    * @param        i_lang                   the id language
    * @param        i_prof                   professional, software and institution ids
    * @param        i_id_monitorization      Monitoring ID
    * @param        i_flg_only_active        Flg to indicate if only shows the active records
    * @param        o_desc                   Monitoring description
    * @param        o_error                  error structure for exception handling
    *
    * @return       boolean                  TRUE if sucess, FALSE otherwise
    *                        
    * @author                                Sofia Mendes
    * @version                               v2.6.1.2
    * @since                                 20-Set-2011
    **********************************************************************************************/
    FUNCTION get_monitor_description
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        i_flg_only_active   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_desc              OUT CLOB,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the instructions for a procedure request according to the passed format, using 
    * combinations of the following values: T (type), N (requirement date), I (interval), S 
    * (start date), E (end date).
    *
    * @param i_lang                ID language
    * @param i_prof                Professional
    * @param i_id_monit_vs         Moniutorization_vs ID
    * @param i_format              Output string format (optional)
    *
    * @return                      Instructions for this monitoring
    *                        
    * @author                      Filipe Machado
    * @version                     2.5.1.3
    * @since                       02-Feb-2011
    **********************************************************************************************/
    FUNCTION get_instructions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_monit_vs IN monitorization_vs.id_monitorization_vs%TYPE,
        i_format      IN VARCHAR2 DEFAULT 'TNISE'
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the instructions for a monitorization request according to the passed format, using 
    * combinations of the following values: N (requirement date), I (interval), S 
    * (start date), E (end date).
    *
    * @param i_lang                ID language
    * @param i_prof                Professional
    * @param i_id_monit            Monitorization ID
    * @param i_format              Output string format (optional)
    *
    * @return                      Instructions for this monitoring
    *                        
    * @author                      Tiago silva
    * @since                       19-Sep-2014
    **********************************************************************************************/
    FUNCTION get_monit_instructions
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_monit IN monitorization.id_monitorization%TYPE,
        i_format   IN VARCHAR2 DEFAULT 'NISE'
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns information about a given request
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_request            Request ID
    * @param o_description           Description
    * @param o_instructions          Instructions
    * @param o_flg_status            Flg_status
    *                        
    * @author                        Filipe Machado
    * @version                       v2.5.1.3
    * @since                         02-Feb-2011
    **********************************************************************************************/
    PROCEDURE get_therapeutic_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_request   IN NUMBER,
        o_description  OUT VARCHAR2,
        o_instructions OUT VARCHAR2,
        o_flg_status   OUT VARCHAR2
    );

    /**********************************************************************************************
    * It indicates whether a vital_sign has measurements or not
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_monitoring_vs         Monitorization vital sign ID
    *                        
    * @author                        Filipe Machado
    * @version                       v2.6.1.1
    * @since                         28-Jun-2011
    **********************************************************************************************/
    FUNCTION vs_has_measurements
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_monitoring_vs IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Return date interval
    *
    * @param i_lang                   preferred language id for this professional
    * @param i_prof                   Profissional ID
    * @param i_interval               Monotorization's interval
    *
    * @param o_error                  error message
    *
    * @return varchar                 Return format hour/minute interval 
    *
    * @author                         Filipe Silva
    * @version                        2.6.1.2
    * @since                          2011/07/07
    **********************************************************************************************/
    FUNCTION get_format_monit_interval
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_interval IN monitorization.interval%TYPE
    ) RETURN VARCHAR;

    /**********************************************************************************************
    * Return interval description
    *
    * @param i_lang                   preferred language id for this professional
    * @param i_prof                   Profissional ID
    * @param i_id_monitorization      Monitorization ID
    *
    * @return varchar                 Return format hour/minute interval 
    *
    * @author                         Filipe Silva
    * @version                        2.6.1.2
    * @since                          2011/07/07
    **********************************************************************************************/
    FUNCTION get_interval_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN monitorization.id_monitorization%TYPE
    ) RETURN VARCHAR;

    /**********************************************************************************************
    * Format interval (HH:MM) to seconds
    *
    * @param i_lang                   preferred language id for this professional
    * @param i_prof                   Profissional ID
    * @param i_interval               Interval defined with this format (HH:MM)
    *
    * @return number                 Return interval in seconds 
    *
    * @author                         Filipe Silva
    * @version                        2.6.1.2
    * @since                          2011/07/07
    **********************************************************************************************/
    FUNCTION get_format_interval_to_seconds
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_interval IN VARCHAR
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Checks if monitorization has permission to execute 
    *
    * @param        i_lang                  Preferred language id for this professional
    * @param        i_prof                  Profissional ID
    * @param        i_episode               Episode ID
    * @param        i_id_monitorization     Monitorization Episode Identifier
    * @param        i_flg_time              Flag time of monitorization
    * @param        i_flg_status            Flag status of monitorization
    * @param        i_dt_begin_tstz         Begin date of monitorization
    * @param        i_flg_check_actions     Flag whether to check on action permissions or not (Y/N)
    *
    * @return                               Has permission or not (Y/N)
    *                        
    * @author                               António Neto
    * @version                              2.5.1.8.1
    * @since                                19-Oct-2011
    **********************************************************************************************/
    FUNCTION check_exec_monit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        i_flg_time          IN monitorization.flg_time%TYPE,
        i_flg_status        IN monitorization.flg_status%TYPE,
        i_dt_begin_tstz     IN monitorization.dt_begin_tstz%TYPE,
        i_flg_check_actions IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Checks if monitorization has permission to cancel 
    *
    * @param        i_lang                  Preferred language id for this professional
    * @param        i_prof                  Profissional ID
    * @param        i_flg_time              Flag time of monitorization
    * @param        i_flg_status            Flag status of monitorization
    * @param        i_flg_check_actions     Flag whether to check on action permissions or not (Y/N)
    *
    * @return                               Has permission or not (Y/N)
    *                        
    * @author                               António Neto
    * @version                              2.5.1.8.1
    * @since                                20-Oct-2011
    **********************************************************************************************/
    FUNCTION check_cancel_monit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_time          IN monitorization.flg_time%TYPE,
        i_flg_status        IN monitorization.flg_status%TYPE,
        i_flg_check_actions IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Checks if monitorization has permission to see Detail screen 
    *
    * @param        i_flg_status            Flag status of monitorization
    *
    * @return                               Has permission or not (Y/N)
    *                        
    * @author                               António Neto
    * @version                              2.5.1.8.1
    * @since                                20-Oct-2011
    **********************************************************************************************/
    FUNCTION check_detail_monit(i_flg_status IN monitorization.flg_status%TYPE) RETURN VARCHAR2;

    /**********************************************************************************************
    * Check the possibility to be recorded in the system an execution after the task was expired.
    * It was defined that it should be possible to record in the system the last execution made after the task expiration.
    * It should not be possible to record more than one excecution after the task was expired. 
    *
    * @param       i_lang                    Professional preferred language
    * @param       i_prof                    Professional identification and its context (institution and software)
    * @param       i_episode                 Episode ID
    * @param       i_task_request            Task request ID (ID_MONITORIZATION)
    * @param       o_error                   Error information
    *
    * @return                                'Y' An execution is allowed. 'N' No execution is allowed (or the task has not expired).
    *
    * @author                                António Neto
    * @version                               2.5.1.8
    * @since                                 13-Sep-2011
    **********************************************************************************************/
    FUNCTION check_extra_take
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE
    ) RETURN VARCHAR;
    /**********************************************************************************************
    * cancel monitorization and vital signs with commit as (Y)es
    *
    * @param i_lang                   preferred language id for this professional
    * @param i_prof                   profissional type
    * @param i_id_monitorization      monitorization array id
    * @param i_notes                  notes for cancel
    * @param i_prof_cat_type          profissional category internal flag
    * @param o_error                  error message
    *
    * @return boolean                 true on success, otherwise false
    *
    * @author                         Filipe Machado
    * @version                        2.5.0.7.3
    * @since                          2009/11/26
    **********************************************************************************************/
    FUNCTION cancel_monitor_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN table_number,
        i_notes             IN monitorization.notes_cancel%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * cancel monitorization and vital signs with commit as (Y)es
    *
    * @param i_lang                   preferred language id for this professional
    * @param i_prof                   profissional type
    * @param i_id_monitorization      monitorization id
    * @param i_notes                  notes for cancel
    * @param i_prof_cat_type          profissional category internal flag
    * @param i_id_cancel_reason       cancel reason identifier
    * @param i_prof_ordered           Professional that i_prof_orderede monit
    * @param i_dt_ordered             Timestamp that was ordered ted monit
    * @param i_order_type             Type of order identifier
     *@param i_commit_data            Indicates if commit is to be done Y/N
    * @param o_error                  error message
    *
    * @return boolean                 true on success, otherwise false
    *
    * @author                         Pedro Fernandes
    * @version                        2.6.5.0.1
    * @since                          2015/04/22
    **********************************************************************************************/

    FUNCTION cancel_monitor_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN table_number,
        i_notes             IN monitorization.notes_cancel%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_prof_ordered      IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_ordered        IN VARCHAR2,
        i_order_type        IN order_type.id_order_type%TYPE,
        i_commit_data       IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * cancel monitorization and vital signs with commit as (Y)es
    *
    * @param i_lang                   preferred language id for this professional
    * @param i_prof                   profissional type
    * @param i_id_monitorization      monitorization id
    * @param i_notes                  notes for cancel
    * @param i_prof_cat_type          profissional category internal flag
    * @param i_id_cancel_reason       cancel reason identifier
    * @param i_prof_ordered           Professional that was ordered the monit
    * @param i_dt_ordered             Timestamp that was ordered the monit
    * @param i_order_type             Type of order identifier
    * @param o_error                  error message
    *
    * @return boolean                 true on success, otherwise false
    *
    * @author                         Filipe Machado
    * @version                        2.5.0.7.3
    * @since                          2009/11/26
    **********************************************************************************************/

    FUNCTION cancel_monitor_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN table_number,
        i_notes             IN monitorization.notes_cancel%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_prof_ordered      IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_ordered        IN VARCHAR2,
        i_order_type        IN order_type.id_order_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * get the monitoring description
    *
    * @param        i_lang                   the id language
    * @param        i_prof                   professional, software and institution ids
    * @param        i_id_monitorization      Monitoring ID
    *
    * @return       Monitoring description
    *                        
    * @author                                Alexandre Santos
    * @version                               v2.6.4
    * @since                                 23-Dec-2014
    **********************************************************************************************/
    FUNCTION get_monitor_description
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        i_id_co_sign_hist   IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    /**********************************************************************************************
    * get the monitoring description
    *
    * @param        i_lang                   the id language
    * @param        i_prof                   professional, software and institution ids
    * @param        i_id_monitorization      Monitoring ID
    *
    * @return       Monitoring start date
    *                        
    * @author                                Alexandre Santos
    * @version                               v2.6.4
    * @since                                 23-Dec-2014
    **********************************************************************************************/
    FUNCTION get_monitor_start_date
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        i_id_co_sign_hist   IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;
    --
    /**********************************************************************************************
    * get the monitoring instructions
    *
    * @param        i_lang                   the id language
    * @param        i_prof                   professional, software and institution ids
    * @param        i_id_monitorization      Monitoring ID
    *
    * @return       Monitoring instructions
    *                        
    * @author                                Alexandre Santos
    * @version                               v2.6.4
    * @since                                 23-Dec-2014
    **********************************************************************************************/
    FUNCTION get_monitor_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        i_id_co_sign_hist   IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    /**********************************************************************************************
    * get monitorization action description
    *
    * @param        i_lang                   the id language
    * @param        i_prof                   professional, software and institution ids
    * @param        i_id_co_sign             Co-sign ID
    *
    * @return       Monitoring action description
    *                        
    * @author                                Vanessa Barsottelli
    * @version                               v2.6.4
    * @since                                 14-Jan-2015
    **********************************************************************************************/
    FUNCTION get_monitor_action_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        i_id_action         IN action.id_action%TYPE,
        i_id_co_sign_hist   IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2;

    FUNCTION inactivate_monitorztn_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --        
    --timeline for reports (ALERT-196786)
    g_monit_crit_type_exec_e CONSTANT VARCHAR2(1 CHAR) := 'E'; --executions
    g_monit_crit_type_req_r  CONSTANT VARCHAR2(1 CHAR) := 'R'; --requisitions
    g_monit_crit_type_all_a  CONSTANT VARCHAR2(1 CHAR) := 'A'; --All

    g_trs_monit_notes    CONSTANT VARCHAR2(50 CHAR) := 'ALERT.MONITORIZATION.NOTES.';
    g_trs_monit_vs_notes CONSTANT VARCHAR2(50 CHAR) := 'ALERT.MONITORIZATION_VS.NOTES.';
    g_sysdate_tstz monitorization.dt_begin_tstz%TYPE;

    g_order_action          CONSTANT VARCHAR2(1 CHAR) := 'O';
    g_draft_action          CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_cancel_action         CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_activate_draft_action CONSTANT VARCHAR2(1 CHAR) := 'A';

    g_monit_vs_plan_final   CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_monit_vs_plan_pending CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_monit_vs_plan_ongoing CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_monit_status_draft    CONSTANT VARCHAR2(1 CHAR) := 'R';
END pk_monitorization;
/
