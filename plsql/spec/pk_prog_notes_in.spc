/*-- Last Change Revision: $Rev: 2052328 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-12-06 15:28:34 +0000 (ter, 06 dez 2022) $*/

CREATE OR REPLACE PACKAGE pk_prog_notes_in IS

    -- Author  : SOFIA.MENDES
    -- Created : 3/23/2012 9:26:01 AM
    -- Purpose : Logic related with calling external APIs

    -- Public type declarations
    -- Public constant declarations   
    -- Public variable declarations
    g_exception EXCEPTION;

    TYPE rec_multichoice IS RECORD(
        label         VARCHAR2(1000 CHAR),
        data          NUMBER(24),
        flg_free_text VARCHAR2(1 CHAR));
    TYPE coll_multichoice IS TABLE OF rec_multichoice;

    -- Public function and procedure declarations
    /********************************************************************************************
    * get all actions of a task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_type               type of the task
    * @param       i_task                    task requisition id
    * @param       i_flg_table_origin        Templates table origin
    * @param       i_task_request            task requisition id
    * @param       o_task_actions            list of task actions 
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 16-Mar-2012
    ********************************************************************************************/
    FUNCTION get_task_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_task_type         IN tl_task.id_tl_task%TYPE,
        i_id_task           IN epis_pn_det_task.id_task%TYPE,
        i_flg_table_origin  IN epis_pn_det_task.flg_table_origin%TYPE,
        i_flg_write         IN VARCHAR2,
        i_last_n_records_nr IN pn_dblock_ttp_mkt.last_n_records_nr%TYPE DEFAULT NULL,
        o_task_actions      OUT t_coll_action,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * When editing some data inserted by template validates
    * if the template was edited since the note creation date.
    * This is used because the physical exam template inserts vital signs values
    * and if the vital signs are edited in the vital signs area the template is updated.
    * However in the H&P appear the values inserted when the template was created. So,
    * when the user edits this template he should be notified that the template had been edited
    * after its insertion in the H&P area.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_epis_documentation  Epis documentation Id
    * @param i_id_epis_pn             Epis Progress Note Id
    * @param o_flg_edited             Y-the template was edited.
    *                                 N-otherwise    
    * @param o_error                  Error message
    *                                                                         
    * @author                         Sofia Mendes                       
    * @version                        2.6.1                                
    * @since                          19-Mai-2011                                
    **************************************************************************/
    FUNCTION check_documentation_edition
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_dt_creation           IN epis_pn_det_task.dt_last_update%TYPE,
        o_flg_show              OUT NOCOPY VARCHAR2,
        o_msg_title             OUT NOCOPY VARCHAR2,
        o_msg                   OUT NOCOPY VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the task detailed description.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             Episode ID
    * @param i_pn_task_type        Task type id
    * @param i_id_task                Task id
    * @param i_universal_description  Free text in the EA table
    * @param i_short_desc             Short descs: sometimes the sort desc is already calculated 
    *                                 and the detailed desc is based on the short desc
    * @param i_code_description       Code translation
    *
    * @return                         Task detailed description
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          25-Aug-2011
    */
    FUNCTION get_detailed_desc_all
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_task_type          IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_universal_description IN task_timeline_ea.universal_desc_clob%TYPE,
        i_short_desc            IN CLOB,
        i_code_description      IN task_timeline_ea.code_description%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB;

    /**
    * Get the exam results descriptions.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_task                Task id
    * @param o_short_desc             Short description to the import last level
    * @param o_detailed_desc          Detailed desc for more info and note
    *
    * @return                         Task detailed description
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          09-Feb-2012
    */
    FUNCTION get_exam_result_descs
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_code_description      IN task_timeline_ea.code_description%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        i_flg_desc_for_dblock   IN pk_types.t_flg_char,
        i_flg_image_exam        IN pk_types.t_flg_char,
        o_short_desc            OUT CLOB,
        o_detailed_desc         OUT CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the task short description.
    *
    * @param       i_lang                   language identifier
    * @param       i_prof                   logged professional structure
    * @param       i_id_episode             Episode identifier
    * @param       i_id_task_type           Task type id
    * @param       i_id_task                Task id
    * @param       i_code_description       Code translation to the task description
    * @param       i_universal_desc_clob    Large Description created by the user
    * @param       i_flg_sos                Flag SOS/PRN
    * @param       i_dt_begin               Begin Date of the task
    * @param       i_id_task_aggregator     Task Aggregator identifier
    * @param       i_id_doc_area            Documentation Area identifier
    * @param       i_flg_status             Status of the task
    * @param       i_code_desc_sample_type  Sample type code description
    *
    * @param       o_short_desc             Short description to the import last level
    * @param       o_detailed_desc          Detailed desc for more info and note
    *
    * @return      Boolean                 Success / Error
    *
    * @author                              Sofia Mendes
    * @version                             2.6.1.2
    * @since                               25-Aug-2011
    */
    FUNCTION get_task_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_task_type          IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_code_description      IN task_timeline_ea.code_description%TYPE,
        i_universal_desc_clob   IN task_timeline_ea.universal_desc_clob%TYPE,
        i_flg_sos               IN task_timeline_ea.flg_sos%TYPE,
        i_dt_begin              IN task_timeline_ea.dt_begin%TYPE,
        i_id_task_aggregator    IN task_timeline_ea.id_task_aggregator%TYPE,
        i_id_doc_area           IN task_timeline_ea.id_doc_area%TYPE,
        i_code_status           IN task_timeline_ea.code_status%TYPE,
        i_flg_status            IN task_timeline_ea.flg_status_req%TYPE,
        i_end_date              IN task_timeline_ea.dt_end%TYPE,
        i_dt_req                IN task_timeline_ea.dt_req%TYPE,
        i_id_task_notes         IN task_timeline_ea.id_task_notes%TYPE,
        i_code_desc_sample_type IN task_timeline_ea.code_desc_sample_type%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        o_short_desc            OUT CLOB,
        o_detailed_desc         OUT CLOB
    ) RETURN BOOLEAN;

    /**
    * Gets the outdated parent tasks.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_task                Task reference id
    * @param i_id_task_type           Task type
    * @param o_parent_tasks           List of outdated parent tasks
    * @param o_error                  Error info
    *
    * @return Boolean                Success / Error
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                09-Feb-2012
    */

    FUNCTION get_outdated_parents
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task      IN task_timeline_ea.id_task_refid%TYPE,
        i_id_task_type IN task_timeline_ea.id_tl_task%TYPE,
        o_parent_tasks OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Verify if a record had already been reviewed in a given episode
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_patient      patient id
    * @param i_id_task         task reference id
    * @param i_id_task_type    Task type id
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param i_review_cat       List of categories flg_types to consider in the check 
    *
    * @return                  Y - the record was reviewed by some professional in the given episode. N-otherwise.    
    *
    * @author                  Sofia Mendes
    * @since                   28-Feb-2012
    * @version                 v2.6.2
    */
    FUNCTION check_reviewed_record
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_task      IN epis_pn_det_task.id_task%TYPE,
        i_id_task_type IN tl_task.id_tl_task%TYPE,
        i_flg_context  IN tl_task.review_context%TYPE,
        i_review_cat   IN pn_dblock_ttp_mkt.review_cat%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * perform an action that does not need to load a screen (only call a BD function).
    * The action to be performed is identified by the id_task_Type and the id_Action.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              episode id
    * @param       i_id_action               action id
    * @param       i_id_task_type            task type ID
    * @param       i_id_task                 task ID    
    * @param       o_flg_validated           validated flag (which indicates if an auxiliary  screen should be loaded or not)
    * @param       o_error                   error message   
    *
    * @value       o_flg_validated           {*} 'Y' validated! no user inputs are needed
    *                                        {*} 'N' not validated! user needs to validare this action
    *
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Sofia Mendes
    * @since                                 23-Mar-2012
    ********************************************************************************************/
    FUNCTION set_action
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_action     IN action.id_action%TYPE,
        i_id_task_type  IN tl_task.id_tl_task%TYPE,
        i_id_task       IN epis_pn_det_task.id_task%TYPE,
        o_flg_validated OUT NOCOPY VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Verify if an aggregated task is active: verifies if all the task that belongs to the agregation 
    * record had already been reviewed in a given episode
    *
    * @param i_lang                  language id
    * @param i_id_task_type          Task type id
    * @param i_id_task_aggregator    Aggregator ID
    *
    * @return                  Y - Active aggregation. N-otherwise.    
    *
    * @author                  Sofia Mendes
    * @since                   28-Feb-2012
    * @version                 v2.6.2
    */
    FUNCTION check_active_aggregation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_task_type       IN tl_task.id_tl_task%TYPE,
        i_id_task_aggregator IN task_timeline_ea.id_task_aggregator%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Sets the expected data for Synchronizable Areas (Expected Discharge Date, Arrival Date Time, etc.)
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_EPISODE            Episode Identifier
    * @param         I_ID_PATIENT            Patient Identifier    
    * @param         I_DT_PN_DATE            Progress Note date
    * @param         I_DATE_TYPE             DH- Date hour; D-Date    
    * @param         I_PN_NOTE_TASK          Task description
    * @param         I_FLG_ADD_REM_TASK      Array of task status (A- Active, R- Removed)
    * @param         I_ID_PN_NOTE_TYPE       Note Type Identifier
    * @param         I_ID_TASK_AGGREGATOR    For analysis and exam recurrences, an imported registry will only be uniquely 
    *                                        identified by id_task (id_analysis/id_exam) + i_id_task_aggregator
    * @param         I_FLG_TASK_PARENT       Flag tells where i_id_task_parent is a taskid or id_epis_pn_det_task
    * @param         I_ID_MULTICHOICE        Array of tasks identifiers for cases that have more than one parameter (multichoice on exam results)
    * @param         i_prof_cat_type         Professional category type
    * @param         i_id_doc_area           Templates doc area ID
    * @param         i_dblock_type          Data block type
    *
    * @param         IO_ID_TASK              Task Identifier
    * @param         IO_ID_TASK_TYPE         Task type Identifier
    * @param         IO_ID_TASK_PARENT       Parent task identifier for comments functionality
    *
    * @param         O_FLG_RELOAD            Tells UX layer it It's needed the reload screen or not
    * @param         O_DT_TASK               Date in which the date was saved
    * @param         O_ERROR                 Error information
    *
    * @return                                True: Sucess, False: Fail
    *
    * @value         O_SAVE_TASK             {*} 'Y'- Yes {*} 'N'- No
    * @value         I_FLG_TASK_PARENT       {*} 'Y'- Passed in i_id_task_parent the id_epis_pn_det_task {*} 'N'- Passed in i_id_task_parent the taskid
    *
    * @author                                Ant? Neto
    * @since                                 06-Mar-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION set_synchronizable_areas
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_dt_pn_date       IN VARCHAR2,
        i_date_type        IN VARCHAR2,
        i_pn_note_task     IN epis_pn_det_task.pn_note%TYPE,
        i_flg_add_rem_task IN VARCHAR2,
        i_flg_task_parent  IN VARCHAR2,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_id_doc_area      IN doc_area.id_doc_area%TYPE,
        i_dblock_type      IN pn_data_block.flg_type%TYPE,
        io_id_task         IN OUT epis_pn_det_task.id_task%TYPE,
        io_id_task_type    IN OUT tl_task.id_tl_task%TYPE,
        io_id_task_parent  IN OUT epis_pn_det_task.id_parent%TYPE,
        o_flg_reload       OUT VARCHAR2,
        o_dt_task          OUT epis_pn_det_task.dt_task%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets in all areas which have comments action
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_EPISODE            Episode Identifier
    * @param         I_ID_EPIS_PN            Progress note detail Identifier
    * @param         I_DATE_TYPE             DH- Date hour; D-Date
    * @param         I_FLG_TASK_PARENT       Flag tells where i_id_task_parent is a taskid or id_epis_pn_det_task
    * @param         I_ID_MULTICHOICE        tasks identifiers for cases that have more than one parameter (multichoice on exam results)
    * @param         i_tbl_tasks             Tasks strucure info
    *
    * @param         IO_ID_TASK              Task Identifier
    * @param         IO_ID_TASK_TYPE         Task type Identifier
    * @param         IO_ID_TASK_PARENT       Parent task identifier for comments functionality
    * @param         IO_PN_NOTE_TASK          Task description
    *
    * @param         O_SAVE_TASK             Flag that returns if task it's to be save on the note
    * @param         O_ERROR                 Error information
    *
    * @value         I_FLG_TASK_PARENT       {*} 'Y'- Passed in i_id_task_parent the id_epis_pn_det_task {*} 'N'- Passed in i_id_task_parent the taskid
    *
    * @return                                True: Sucess, False: Fail
    *
    * @author                                Ant? Neto
    * @since                                 26-Apr-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION set_comment_on_area
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_epis_pn_det  IN epis_pn_det.id_epis_pn_det%TYPE,
        i_flg_task_parent IN VARCHAR2,
        i_id_multichoice  IN NUMBER,
        i_tbl_tasks       IN pk_prog_notes_types.t_table_tasks,
        io_id_task        IN OUT epis_pn_det_task.id_task%TYPE,
        io_id_task_type   IN OUT epis_pn_det_task.id_task_type%TYPE,
        io_id_task_parent IN OUT epis_pn_det_task.id_parent%TYPE,
        io_pn_note_task   IN OUT epis_pn_det_task.pn_note%TYPE,
        o_save_task       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets multichoice options for comments functionality
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_TL_TASK            Task Type Identifier
    *
    * @param         O_DATA                  Multichoice options list
    * @param         O_ERROR                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Ant? Neto
    * @since                                 30-Apr-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION get_comment_multichoice
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_tl_task IN tl_task.id_tl_task%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets multichoice options for comments functionality
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_TL_TASK            Task Type Identifier
    *
    * @return                                Multichoice options
    *
    * @author                                Ant? Neto
    * @since                                 09-May-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION get_comment_multichoice_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_tl_task IN tl_task.id_tl_task%TYPE
    ) RETURN coll_multichoice
        PIPELINED;

    /********************************************************************************************
    * Gets the task type for the parent task of the Comment
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_TASK_TYPE          Comment task type identifier
    *
    * @return                                Parent Task type identifier
    *
    * @author                                Ant? Neto
    * @since                                 07-may-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION get_comment_task_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN epis_pn_det_task.id_task_type%TYPE
    ) RETURN epis_pn_det_task.id_task_type%TYPE;

    /********************************************************************************************
    * Returns if multichoice is needed for type of task
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_TASK_TYPE          Comment task type identifier
    *
    * @return                                Y - Has multichoice, N - otherwise
    *
    * @author                                Ant? Neto
    * @since                                 09-May-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION has_multichoice
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN epis_pn_det_task.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the comment task type for the parent task
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_TASK_TYPE          Parent task type identifier
    *
    * @return                                Comment Task type identifier
    *
    * @author                                ANTONIO.NETO
    * @since                                 10-May-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION get_comment_task_type_parent
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN epis_pn_det_task.id_task_type%TYPE
    ) RETURN epis_pn_det_task.id_task_type%TYPE;

    /**
    * Review tasks
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_id_episode          Episode ID    
    * @param   i_id_record_area      record id
    * @param   i_flg_context         record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param   i_dt_review           date of review
    * @param   i_review_notes        review notes (optional)
    * @param   i_flg_auto            reviewed automatically (Y/N)
    * @param   i_id_task_type        Task type identifier
    * @param   i_id_patient          Patient identifier
    *
    * @param   o_error               Error information
    *
    * @return  Boolean               True: Sucess, False: Fail
    *
    * @author                        Sofia Mendes
    * @version                       2.6.1.2
    * @since                         19-Ago-2011
    */
    FUNCTION set_review_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE,
        i_dt_review      IN review_detail.dt_review%TYPE,
        i_review_notes   IN review_detail.review_notes%TYPE,
        i_flg_auto       IN review_detail.flg_auto%TYPE,
        i_id_task_type   IN epis_pn_det_task.id_task_type%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Gets the tasks descriptions by grouo of tasks.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID   
    * @param i_id_episode             Episode Identifier 
    * @param i_id_patient             Patient ID
    * @param i_tasks_groups_by_type   Lists of tasks by task type
    * @param o_tasks_descs_by_type    Lists of tasks descs by task type
    * @param o_error                  Error
    *
    * @value i_flg_has_notes          {*} 'Y'- Has comments {*} 'N'- otherwise
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_group_descriptions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_tasks_groups_by_type IN pk_prog_notes_types.t_tasks_groups_by_type,
        o_tasks_descs_by_type  OUT pk_prog_notes_types.t_tasks_descs_by_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Get the vital sign ranks to be used on single page. 
    * Rank 1: 1st value
    * Rank 2: penultimate value
    * Rank 3: last value
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        Vital sign read ID
    * @param      i_scope                     Scope ID (Episode ID; Visit ID; Patient ID)
    * @param      i_flg_scope                 Scope (E- Episode, V- Visit, P- Patient)
    * @param      o_id_vital_sign_read        Vital sign read ID
    * @param      o_rank                      Rank
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Sofia Mendes
    * @version    2.6.2
    * @since      24-08-2012
    ***********************************************************************************************************/
    FUNCTION get_table_ranks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_scope IN VARCHAR2,
        i_scope     IN NUMBER,
        i_id_tasks  IN table_number,
        o_id_tasks  OUT NOCOPY table_number,
        o_rank      OUT NOCOPY table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the task description for procedures
    *
    * @param       i_lang                   language identifier
    * @param       i_prof                   logged professional structure
    * @param       i_id_episode             Episode identifier
    * @param       i_id_interv_presc_det    Procedure task ID
    * @param       o_short_desc             Procedure task short description
    * @param       o_long_desc              Procedure task long descripton
    *
    * @return                               sucess/error
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                10-Set-2012
    */
    FUNCTION get_procedures_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_interv_presc_det   IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        o_short_desc            OUT CLOB,
        o_long_desc             OUT CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the task description for patient education
    *
    * @param       i_lang                   language identifier
    * @param       i_prof                   logged professional structure
    * @param       i_id_episode             Episode identifier
    * @param       i_id_interv_presc_det    patient education task ID
    * @param       o_short_desc             patient education task short description
    * @param       o_long_desc              patient education task long descripton
    *
    * @return                               sucess/error
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                10-Set-2012
    */
    FUNCTION get_pat_education_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_nurse_tea_req      IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        o_short_desc            OUT CLOB,
        o_long_desc             OUT CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * get_visit_info_amb
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_episode                episode identifier
    *
    * @return     clob
    *
    * @author     Paulo T
    * @version    2.6.2
    * @since      2012-09-25
    ***********************************************************************************************************/
    FUNCTION get_visit_info_amb
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_description       IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;
    /************************************************************************************************************
    * get_visit_info_inp
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_episode                episode identifier
    *
    * @return     clob
    *
    * @author     Paulo T
    * @version    2.6.2
    * @since      2012-09-25
    ***********************************************************************************************************/
    FUNCTION get_visit_info_inp
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_description       IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;
    /************************************************************************************************************
    * get_visit_info_edis
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_episode                episode identifier
    *
    * @return     clob
    *
    * @author     Paulo T
    * @version    2.6.2
    * @since      2012-09-25
    ***********************************************************************************************************/
    FUNCTION get_visit_info_edis
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_description       IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    /**
    * Get the task short description for Lab and Exam Orders
    *
    * @param       i_lang                   language identifier
    * @param       i_prof                   logged professional structure
    * @param       i_id_task_type           Task type identifier
    * @param       i_id_task                Task identifier
    * @param       i_code_description       Code translation to the task description
    * @param       i_flg_sos                Flag SOS/PRN
    * @param       i_dt_begin               Lab/Exam order begin date
    * @param       i_id_task_aggregator     Task Aggregator identifier
    * @param       i_flg_status             Task flg_status
    * @param       i_code_desc_sample_type  Sample type code description
    *
    * @return                               Lab detailed description
    *
    * @value       i_flg_sos                {*} 'Y'- Yes {*} 'N'- No
    *
    * @author                               Ant? Neto
    * @version                              2.6.2
    * @since                                30-Jan-2012
    */
    FUNCTION get_lab_exam_order_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_task_type          IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_code_description      IN task_timeline_ea.code_description%TYPE,
        i_flg_sos               IN task_timeline_ea.flg_sos%TYPE,
        i_dt_begin              IN task_timeline_ea.dt_begin%TYPE,
        i_id_task_aggregator    IN task_timeline_ea.id_task_aggregator%TYPE,
        i_code_desc_sample_type IN task_timeline_ea.code_desc_sample_type%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB;

    /**************************************************************************
    * Get the macros defined to the list of templates
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID   
    * @param i_templates              Templates list 
    * @param io_coll_macro            Macros list
    * @param o_error                  Error
    *
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.3.1                          
    * @since                          03-Dec-2012                               
    **************************************************************************/
    FUNCTION get_doc_area_macros
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_templates   IN t_coll_template,
        io_coll_macro IN OUT NOCOPY t_coll_macro,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Gets the flash context screens
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         i_flg_context            flag context
    *
    * @param         O_DATA                  screen list
    * @param         O_ERROR                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Paulo teixeira
    * @since                                 06-03-2014
    * @version                               2.6.3
    ********************************************************************************************/
    FUNCTION get_swf_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN pn_context.flg_context%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Review home medication tasks
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_id_episode          Episode ID
    * @param   i_id_patient          Patient identifier
    *
    * @param   o_error               Error information
    *
    * @return  Boolean               True: Sucess, False: Fail
    *
    * @author                        Vanessa Barsottelli
    * @version                       2.6.3
    * @since                         16-04-2014
    */
    FUNCTION set_review_home_med
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a task type record
    *
    * @param         i_lang                  Language ID for translations
    * @param         i_prof                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         i_id_task_type          Task Type ID
    * @param         i_id_task_refid         Record ID
    * @param         i_id_cancel_reason      Cancel Reason ID
    * @param         i_notes_cancel          Cancel notes
    *
    * @param         o_error                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Vanessa Barsottelli
    * @since                                 07-07-2014
    * @version                               2.6.4
    ********************************************************************************************/
    FUNCTION cancel_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_task_type     IN tl_task.id_tl_task%TYPE,
        i_id_task_refid    IN task_timeline_ea.id_task_refid%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN cancel_info_det.notes_cancel_long%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a task type record to be used when a note is deleted, to deleted referenced records on the note
    *
    * @param         i_lang                  Language ID for translations
    * @param         i_prof                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         i_id_task_type          Task Type IDs
    * @param         i_id_task_refid         Record IDs
    *
    * @param         o_error                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Sofia Mendes
    * @since                                 01-09-2017
    * @version                               2.7.1
    ********************************************************************************************/
    FUNCTION set_cancel_task_on_del_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_type  IN table_number,
        i_id_task_refid IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summ_sections_block
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_sblock    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_doc_area     IN doc_area.id_doc_area%TYPE DEFAULT NULL,
        o_sections        OUT pk_summary_page.t_cur_section,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_severity_score_block
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_sblock    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_scores          OUT pk_sev_scores_core.p_sev_scores_param_cur,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diagnosis_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_epis_diagnosis     IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB;

    FUNCTION get_summ_sections_exclude
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_doc_category IN doc_category.id_doc_category%TYPE,
        o_sections        OUT pk_summary_page.t_cur_section,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_identification
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE DEFAULT NULL,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL
    ) RETURN CLOB;

    FUNCTION get_intensity_hhc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_tbl_id_request IN table_number,
        i_flg_report     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_data           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * get_admission_days
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_episode                episode identifier
    *
    * @return     varchar2
    *
    * @author     Ana Moita
    * @version    2.8.0
    * @since      2020-10-16
    */
    FUNCTION get_admission_days
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_templates_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_documentation IN table_number
    ) RETURN pk_prog_notes_types.t_tasks_descs;

    FUNCTION get_template_clinical_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_documentation IN table_number
    ) RETURN pk_prog_notes_types.t_tab_templ_scores;
    g_limit PLS_INTEGER := 1000;

END pk_prog_notes_in;
/
