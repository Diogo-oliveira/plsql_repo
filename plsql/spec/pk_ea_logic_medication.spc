/*-- Last Change Revision: $Rev: 2028639 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_medication IS

    -- Author  : João Ribeiro
    -- Created : 02/07/2009 12:00:00 AM
    -- Purpose : Easy access for medication

    /********************************************************************************
    ********************************************************************************/
    PROCEDURE set_presc_task_time_line
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Process insert/update events on PRESC_NOTES_ITEM into TASK_TIMELINE_EA
    * (prescription comment tasks).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/05/02
    */
    PROCEDURE set_presc_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    );

    /********************************************************************************************
    * Procedure to update task_timeline_ea with information regarding reconciliation information
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EPISODE               The episode id
    * @param   I_ID_PATIENT               The patient id
    * @param   O_ERROR                    error information
    *
    * @RETURN                             true or false, if error wasn't found or not
    *
    * @author                             Pedro Teixeira
    * @version                            2.6.2
    *
    **********************************************************************************************/
    FUNCTION update_task_tl_recon
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN episode.id_patient%TYPE,
        i_id_presc        IN NUMBER,
        i_dt_req          IN episode.dt_begin_tstz%TYPE,
        i_id_prof_req     IN episode.id_prof_cancel%TYPE,
        i_id_institution  IN episode.id_institution%TYPE,
        i_event_type      IN VARCHAR2,
        i_id_tl_task      IN NUMBER,
        i_id_prev_tl_task IN NUMBER DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************
    * Name:                           UPDATE_PRESC_LIST_JOBS
    * Description:                    Updates presc_list_jobs for the cancelled prescriptions
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Pedro Teixeira
    * @since                          17/11/2014
    ********************************************************************************/
    PROCEDURE update_presc_list_jobs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /********************************************************************************
    * Name:                           UPDATE_LIST_JOB_PRESCS
    * Description:                    Updates prescription group for terminated presc_list_jobs
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Pedro Teixeira
    * @since                          20/10/2014
    ********************************************************************************/
    PROCEDURE update_list_job_prescs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /********************************************************************************
    * Get new print arguments to the reports that need to be regenerated
    * Used by reports (pk_print_tool) when sending report to the printer (after selecting print button)    
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   io_print_arguments          Json string to be printed
    * @param   o_flg_regenerate_report     Flag indicating if the report needs to be regenerated or not
    * @param   o_error                     Error information
    *
    * @value   o_flg_regenerate_report     {*} Y- report needs to be regenerated {*} N- otherwise
    *
    * @RETURN  boolean                     TRUE if sucess, FALSE otherwise
    *
    * @author  Pedro teixeira
    * @since   29-10-2014
    ********************************************************************************/
    FUNCTION get_print_args_to_regen_report
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        io_print_arguments      IN OUT print_list_job.print_arguments%TYPE,
        o_flg_regenerate_report OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Package name */
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Current timestamp */
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;
    g_excp_invalid_data       EXCEPTION;

    g_flg_n VARCHAR2(1) := 'N';
    g_flg_y VARCHAR2(1) := 'Y';

END pk_ea_logic_medication;
/
