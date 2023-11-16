/*-- Last Change Revision: $Rev: 2028892 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_prog_notes_core IS

    -- Author  : SOFIA.MENDES
    -- Created : 26-01-2011 15:52:22
    -- Purpose : Progress notes functions relation with transactional modal

    -- Public variable declarations
    g_error         VARCHAR2(2000 CHAR);
    g_package_owner VARCHAR2(200 CHAR);
    g_package_name  VARCHAR2(200 CHAR);
    g_sysdate       DATE;
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_found         BOOLEAN;
    g_exception EXCEPTION;

    -- Public type declarations

    -- Public constant declarations

    -- Public function and procedure declarations

    /**
    * Create/update a Progress Notes Addendum
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_flg_type            Type of addendum
    * @param   i_epis_pn             Progress Notes ID
    * @param   i_id_epis_pn_addendum Addendum ID
    * @param   i_pn_addendum         Progress Notes Addendum (text)
    *  
    * @param   o_epis_pn_addendum    PN Addendum ID created or updated
    * @param   o_error               Error information
    *
    * @return  Boolean               True: Sucess, False: Fail
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   31-01-2011
    */
    FUNCTION set_pn_addendum
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_flg_type            IN epis_pn_addendum.flg_type%TYPE,
        i_id_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_pn_addendum         IN epis_pn_addendum.pn_addendum%TYPE,
        o_epis_pn_addendum    OUT epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel a Progress Notes Addendum
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis_pn_addendum      Progress Notes ID
    * @param   i_cancel_reason  Cancel reason ID
    * @param   i_notes_cancel Cancel notes
    *
    * @param   o_epis_pn      Progress note ID  (null if non-existent)  
    * @param   o_error        Error information
    *
    * @return  Boolean        True: Sucess, False: Fail
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   31-01-2011
    */
    FUNCTION cancel_pn_addendum
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN epis_pn_addendum.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sign-Off an addendum
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_epis_pn             Progress Notes ID    
    * @param   i_epis_pn_addendum    Addendum to signoff
    * @param   i_pn_addendum         Progress Notes Addendum (text)
    * @param   i_dt_signoff          Sign-off date
    * @param   i_flg_just_save       Just Save flag (Y- Just Save, N- Sign-off
    * @param   i_flg_edited          Edited addentum? (Y- Yes, N- No)
    * @param   i_flg_hist            Must generate history record? (Y- Yes, N- No)
    *
    * @param   o_epis_pn_addendum    PN Addendum ID created or updated
    * @param   o_error        Error information
    *
    * @return  Boolean        True: Sucess, False: Fail
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   01-02-2011
    */
    FUNCTION set_signoff_addendum
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        i_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_pn_addendum      IN epis_pn_addendum.pn_addendum%TYPE,
        i_dt_signoff       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_just_save    IN VARCHAR2,
        i_flg_edited       IN VARCHAR2,
        i_flg_hist         IN VARCHAR2 DEFAULT 'Y',
        o_epis_pn_addendum OUT epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Create/update a Progress Notes Addendum
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_epis_pn             Progress Notes ID
    * @param   i_flg_type            Type of addendum
    * @param   i_id_epis_pn_addendum Addendum ID
    * @param   i_pn_addendum         Progress Notes Addendum (text)
    * @param   i_dt_addendum         Addendum date
    *  
    * @param   o_error               Error information
    *
    * @return  Boolean               True: Sucess, False: Fail
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   31-01-2011
    */
    FUNCTION set_pn_addendum_internal
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_flg_type            IN epis_pn_addendum.flg_type%TYPE DEFAULT pk_prog_notes_constants.g_epa_flg_type_addendum,
        i_id_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_pn_addendum         IN epis_pn_addendum.pn_addendum%TYPE,
        i_dt_addendum         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_last_update_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_epis_pn_addendum    OUT epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Saves work data into progress notes tables
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_epis_pn         Progress note identifier
    * @param   i_epis_pn_work    Progress note identifier in work table
    * @param   i_id_pn_area      Pn area id
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   31-01-2011
    */
    FUNCTION set_save_work_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_pn      IN NUMBER,
        i_epis_pn_work IN NUMBER,
        i_id_pn_area   IN pn_area.id_pn_area%TYPE DEFAULT NULL,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel progress note
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_epis_pn        Progress note identifier
    * @param   i_cancel_reason  Cancel reason identifier
    * @param   i_notes_cancel   Cancel notes
    * @param   i_dt_cancel      Cancelation date
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   01-02-2011
    */
    FUNCTION cancel_progress_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pn       IN NUMBER,
        i_cancel_reason IN NUMBER,
        i_notes_cancel  IN VARCHAR2,
        i_dt_cancel     IN epis_pn_hist.dt_cancel%TYPE DEFAULT current_timestamp,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sign off a progress note
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_pn                   Progress note identifier
    * @param   i_flg_edited                Indicate if the SOAP block was edited
    * @param   i_pn_soap_block             Soap Block array with ids
    * @param   i_pn_signoff_note           Notes array
    * @param   i_flg_just_save             Indicate if its just to save or to signoff
    * @param   i_flg_showed_just_save      Indicates if just save screen showed or not
    *
    * @param   o_error                     Error information
    *
    * @return                              Returns TRUE if success, otherwise returns FALSE
    *
    * @value   i_flg_just_save             {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_showed_just_save      {*} 'Y'- screen was showed to Professional {*} 'N'- screen didn't showed to Professional
    *
    * @author                              RUI.SPRATLEY
    * @version                             2.6.0.5
    * @since                               02-02-2011
    *
    * @author                              ANTONIO.NETO
    * @version                             2.6.2
    * @since                               19-Apr-2012
    */
    FUNCTION set_sign_off
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_epis_pn              IN epis_pn.id_epis_pn%TYPE,
        i_flg_edited           IN table_varchar,
        i_pn_soap_block        IN table_number,
        i_pn_signoff_note      IN table_clob,
        i_flg_just_save        IN VARCHAR2,
        i_flg_showed_just_save IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the notes to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn             Note identifier
    * @param i_id_pn_note_type        Note type id. 3-Progress Note; 4-Prolonged Progress Note; 5-Intensive Care Note; 2-History and Physician Note
    * @param i_id_epis_pn_det_task    Task Ids that have to be syncronized
    * @param i_id_pn_soap_block       Soap block id
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note            
    * @param o_text_comments          Comments cursor
    * @param o_configs                Dynamic configs: flg_import_available; flg_editable                                 
    * @param o_data_blocks            Dynamic data blocks (date data blocks)
    * @param o_buttons                Dynamic buttons (template records)
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   04-02-2011
    */

    FUNCTION get_notes_core
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type     IN epis_pn.id_pn_note_type%TYPE,
        i_id_epis_pn_det_task IN table_number,
        i_id_pn_soap_block    IN table_number,
        i_dt_proposed         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_data                OUT NOCOPY pk_types.cursor_type,
        o_text_blocks         OUT NOCOPY pk_types.cursor_type,
        o_text_comments       OUT NOCOPY pk_types.cursor_type,
        o_suggested           OUT NOCOPY pk_types.cursor_type,
        o_configs             OUT NOCOPY pk_types.cursor_type,
        o_data_blocks         OUT NOCOPY pk_types.cursor_type,
        o_buttons             OUT NOCOPY pk_types.cursor_type,
        o_cancelled           OUT NOCOPY pk_types.cursor_type,
        o_doc_reg             OUT NOCOPY pk_types.cursor_type,
        o_doc_val             OUT NOCOPY pk_types.cursor_type,
        o_template_layouts    OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component  OUT NOCOPY pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * sincronize note records. When a record is created througth the help save. It is necessary to syncronize the record
    * to synch it (the data block can be configured to be not synch).
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn             Note identifier
    * @param i_id_pn_note_type        Note type id. 3-Progress Note; 4-Prolonged Progress Note; 5-Intensive Care Note; 2-History and Physician Note
    * @param i_id_epis_pn_det_task    Task Ids that have to be syncronized
    * @param i_id_pn_soap_block       Soap block id    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author  Sofia Mendes
    * @version 2.6.0.5
    * @since   04-02-2011
    */

    FUNCTION set_note_synch
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type     IN epis_pn.id_pn_note_type%TYPE,
        i_id_epis_pn_det_task IN table_number,
        i_id_pn_soap_block    IN table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update one data block's content. If the data doesn't exists yet, the record will be created.
    * the IN parameter Type allow for select if append or update should be done to the text.
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_episode              Episode ID
    * @param   i_id_patient           Patient Identifier
    * @param   i_id_visit             Visit Identifier
    * @param   i_epis_pn              Progress note ID
    * @param   i_dt_pn_date           Progress Note date
    * @param   i_flg_action           C-Create; U-update; I-import
    * @param   i_date_type            DH- Date hour; D-Date
    * @param   i_pn_soap_block        SOAP Block ID
    * @param   i_pn_data_block        Data Block ID
    * @param   i_id_task              Task ID
    * @param   i_dep_clin_serv        Clinical Service ID
    * @param   i_epis_pn_det          Progress note detail ID
    * @param   i_pn_note              Progress note detail text 
    * @param   i_flg_add_remove       Add or remove block from note. A R-Removed block is like a canceled one.
    * @param   i_id_pn_note_type      Progress Note type id (P-progress note; L-prolonged progress note; CC-intensive care note; H-history and physician note) 
    * @param   i_flg_app_upd          Type of operation: A-Append, U-Update
    * @param   i_epis_pn_det_task     Array of PN task details
    * @param   i_pn_note_task         Array of PN task descriptions
    * @param   i_flg_add_rem_task     Array of task status (A- Active, R- Removed)
    * @param   i_flg_table_origin     Flag origin table for documentation ( D - documentation, A - Anamnesis, S - Review of system)
    * @param   i_id_task_aggregator   For analysis and exam recurrences, an imported registry will only be uniquely 
    *                                 identified by id_task (id_analysis/id_exam) + i_id_task_aggregator
    * @param   i_flg_synchronized     Data Block info if is to be synchronized with the directed areas, other than templates
    * @param   i_dt_task              Task dates
    * @param   i_id_task_parent       Parent task identifier for comments functionality
    * @param   i_flg_task_parent      Flag tells where i_id_task_parent is a taskid or id_epis_pn_det_task
    * @param   i_id_multichoice       Array of tasks identifiers for cases that have more than one parameter (multichoice on exam results)
    * @param   i_rank_task            Rank of the tasks
    * @param   i_prof_task            Professional that created the tasks
    * @param   i_dblock_cfgs          Data block configs record
    * @param   i_id_group_table       Id Group (vital sign id): vital signs table row id
    *
    * @param   io_id_task_type        Task type Identifiers
    *
    * @param   o_id_epis_pn           ID of the PN created
    * @param   o_flg_reload           Tells UX layer it It's needed the reload screen or not
    * @param   o_error                Error information
    *
    * @return  Boolean                True: Sucess, False: Fail
    *
    * @value   i_flg_task_parent      {*} 'Y'- Passed in i_id_task_parent the id_epis_pn_det_task {*} 'N'- Passed in i_id_task_parent the taskid
    *
    * @author                         RUI.BATISTA
    * @version                        <2.6.0.5>
    * @since                          04-02-2011
    */
    FUNCTION set_data_block
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_patient            IN patient.id_patient%TYPE DEFAULT NULL,
        i_epis_pn            IN epis_pn.id_epis_pn%TYPE,
        i_dt_pn_date         IN VARCHAR2,
        i_flg_action         IN VARCHAR2,
        i_date_type          IN VARCHAR2,
        i_pn_soap_block      IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block      IN pn_data_block.id_pn_data_block%TYPE,
        i_id_task            IN table_number,
        i_epis_pn_det        IN epis_pn_det.id_epis_pn_det%TYPE,
        i_pn_note            IN epis_pn_det.pn_note%TYPE,
        i_flg_status         IN epis_pn_det.flg_status%TYPE,
        i_flg_app_upd        IN VARCHAR2,
        i_epis_pn_det_task   IN table_number,
        i_pn_note_task       IN table_clob,
        i_flg_add_rem_task   IN table_varchar,
        i_flg_table_origin   IN table_varchar DEFAULT NULL,
        i_id_task_aggregator IN table_number,
        i_dt_task            IN table_varchar,
        i_id_task_parent     IN table_number,
        i_flg_task_parent    IN VARCHAR2 DEFAULT 'N',
        i_id_multichoice     IN table_number,
        i_rank_task          IN table_number,
        i_prof_task          IN table_number,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dblock_cfgs        IN t_rec_dblock,
        i_dblock_task_type   IN t_coll_dblock_task_type DEFAULT NULL,
        i_id_group_table     IN table_number,
        i_flg_related        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        io_note_struct       IN OUT pk_prog_notes_types.t_note_struct,
        io_id_task_type      IN OUT table_number,
        io_timezone          IN OUT VARCHAR2,
        o_id_epis_pn         OUT epis_pn.id_epis_pn%TYPE,
        o_flg_reload         OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update all data block's content for a PN. If the data doesn't exists yet, the record will be created.
    * the IN parameter Type allow for select if append or update should be done to the text.
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_episode              Episode ID
    * @param   i_epis_pn              Progress note ID
    * @param   i_dt_pn_date           Progress Note date Array
    * @param   i_flg_action           C-Create; U-update
    * @param   i_date_type            DH- Date hour; D-Date
    * @param   i_pn_soap_block        SOAP Block ID
    * @param   i_pn_data_block        Data Block ID
    * @param   i_id_task              Array of task IDs
    * @param   i_id_task_type         Array of task type IDs
    * @param   i_dep_clin_serv        Clinical Service ID
    * @param   i_epis_pn_det          Progress note detail ID
    * @param   i_pn_note              Progress note detail text 
    * @param   i_flg_add_remove       Add or remove block from note. A R-Removed block is like a canceled one.
    * @param   i_id_pn_note_type      Progress Note type (P-progress note; L-prolonged progress note; CC-intensive care note; H-history and physician note) 
    * @param   i_flg_app_upd          Type of operation: A-Append, U-Update
    * @param   i_flg_definitive       Save PN in the definitive model (Y- YES, N- NO)
    * @param   i_epis_pn_det_task     Array of PN task details
    * @param   i_pn_note_task         Array of PN task descriptions
    * @param   i_flg_add_rem_task     Array of task status (A- Active, R- Removed)
    * @param   i_flg_table_origin     Flag origin table for documentation ( D - documentation, A - Anamnesis, S - Review of system)
    * @param   i_id_task_aggregator   For analysis and exam recurrences, an imported registry will only be uniquely 
    *                                 identified by id_task (id_analysis/id_exam) + i_id_task_aggregator
    * @param   i_dt_task              Task dates
    * @param   i_id_task_parent       Parent task identifier for comments functionality
    * @param   i_flg_task_parent      Flag tells where i_id_task_parent (Y) is a taskid or id_epis_pn_det_task
    * @param   i_id_multichoice       Array of tasks identifiers for cases that have more than one parameter (multichoice on exam results)
    * @param   i_id_group_table       Id Group (vital sign id): vital signs table row id
    *
    * @param   o_id_epis_pn           ID of the PN created
    * @param   o_flg_reload           Tells UX layer it It's needed the reload screen or not
    * @param   o_error                Error information
    *
    * @return  Boolean                True: Sucess, False: Fail
    *
    * @value   o_flg_reload           {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_task_parent      {*} 'Y'- Passed in i_id_task_parent the id_epis_pn_det_task {*} 'N'- Passed in i_id_task_parent the taskid
    *
    * @author                         RUI.BATISTA
    * @version                        <2.6.0.5>
    * @since                          04-02-2011
    */
    FUNCTION set_all_data_block
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_pn            IN epis_pn.id_epis_pn%TYPE,
        i_dt_pn_date         IN table_varchar,
        i_flg_action         IN VARCHAR2,
        i_date_type          IN table_varchar,
        i_pn_soap_block      IN table_number,
        i_pn_data_block      IN table_number,
        i_id_task            IN table_table_number,
        i_id_task_type       IN table_table_number,
        i_dep_clin_serv      IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_epis_pn_det        IN table_number,
        i_pn_note            IN table_clob,
        i_flg_add_remove     IN table_varchar,
        i_id_pn_note_type    IN epis_pn.id_pn_note_type%TYPE,
        i_flg_app_upd        IN VARCHAR2,
        i_flg_definitive     IN VARCHAR2,
        i_epis_pn_det_task   IN table_table_number,
        i_pn_note_task       IN table_table_clob,
        i_flg_add_rem_task   IN table_table_varchar,
        i_flg_table_origin   IN table_table_varchar DEFAULT NULL,
        i_id_task_aggregator IN table_table_number,
        i_dt_task            IN table_table_varchar,
        i_id_task_parent     IN table_table_number,
        i_flg_task_parent    IN VARCHAR2,
        i_id_multichoice     IN table_table_number,
        i_id_group_table     IN table_table_number,
        i_dt_proposed        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_id_epis_pn         OUT epis_pn.id_epis_pn%TYPE,
        o_flg_reload         OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the notes to the import screen
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_pn_note_type        Note type identifier
    * @param i_id_epis_pn             Note identifier
    * @param o_data_1                 Grid data level 1
    * @param o_data_2                 Grid data level 2
    * @param o_data_3                 Grid data level 3
    * @param o_data_4                 Grid data level 4
    * @param o_data_5                 Grid data level 5
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Rui Spratley
    * @version              2.6.0.5
    * @since                07-02-2011
    */

    FUNCTION get_import_data
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_data_1          OUT pk_types.cursor_type,
        o_data_2          OUT pk_types.cursor_type,
        o_data_3          OUT pk_types.cursor_type,
        o_data_4          OUT pk_types.cursor_type,
        o_data_5          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get imported data from temporary tables to be edited in Progress Notes
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_episode           Episode ID
    * @param   i_patient           Patient ID
    * @param   i_id_pn_note_type   Note type Identifier 
    * @param   i_pn_note_type_cfg  Configs associated to the note type 
    * @param   i_id_epis_pn             Note ID
    *
    * @param   o_data_import_list
    * @param   o_data_block
    * @param   o_data
    * @param   o_error             Error information
    *
    * @return  Boolean             True: Sucess, False: Fail
    *
    * @author                      Ant? Neto
    * @version                     2.6.1.2
    * @since                       27-Jul-2011
    */
    FUNCTION get_data_import
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_pn_note_type_cfg IN t_rec_note_type,
        i_id_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        o_data_import_list OUT pk_types.cursor_type,
        o_data_block       OUT t_coll_data_blocks,
        o_data             OUT t_coll_pn_work_data,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Saves a progress note in the definitive tables
    * This function does not support the removal of id_documentation in the note updates
    *
    * @param   i_lang                         Professional preferred language
    * @param   i_prof                         Professional identification and its context (institution and software)
    * @param   i_epis_pn                      Progress note identifier
    * @param   i_id_dictation_report          Dictation report identifier
    * @param   i_id_episode                   Episode identifier
    * @param   i_pn_flg_status                Note flag status
    * @param   i_id_pn_note_type              Note type id
    * @param   i_dt_pn_date                   Note date
    * @param   i_id_dep_clin_serv             Episode dep_clin_serv id
    * @param   i_id_pn_data_block             Pn data block id
    * @param   i_id_pn_soap_block             Pn soap block id
    * @param   i_id_task                      Task ids
    * @param   i_id_task_type                 Task type ids
    * @param   i_pn_note                      Note text
    * @param   i_id_professional              Professional that created/updates the note
    * @param   i_dt_execution                 Date in which the note is being created/updated
    * @param   i_dt_sent_to_hist              Date in which the note was updated
    * @param   i_dt_sent_to_hist              Date in which the note was updated
    * @param   i_id_prof_sign_off             Professional that signed-off the note
    *                                         Mandatory field when creating Signed-off or Migrated records
    * @param   i_dt_sign_off                  Date in which it was performed the sign off
    *                                         Mandatory field when creating Signed-off or Migrated records
    * @param   o_id_epis_pn                   Created/updated note id
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.6.0.5
    * @since  15-Feb-2011
    */
    FUNCTION set_save_def_note
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis_pn             IN epis_pn.id_epis_pn%TYPE,
        i_id_dictation_report IN epis_pn.id_dictation_report%TYPE,
        i_id_episode          IN epis_pn.id_episode%TYPE,
        i_pn_flg_status       IN epis_pn.flg_status%TYPE,
        i_id_pn_note_type     IN pn_note_type.id_pn_note_type%TYPE,
        i_dt_pn_date          IN epis_pn.dt_pn_date%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_data_block    IN table_number,
        i_id_pn_soap_block    IN table_number,
        i_id_task             IN table_number,
        i_id_task_type        IN table_number,
        i_pn_note             IN table_clob,
        i_id_professional     IN professional.id_professional%TYPE,
        i_dt_last_update      IN epis_pn.dt_last_update%TYPE DEFAULT NULL,
        i_dt_create           IN epis_pn.dt_create%TYPE DEFAULT NULL,
        i_dt_sent_to_hist     IN epis_pn_signoff_hist.dt_epis_pn_signoff_hist%TYPE,
        i_id_prof_sign_off    IN epis_pn.id_prof_signoff%TYPE,
        i_dt_sign_off         IN epis_pn.dt_signoff%TYPE,
        i_flg_handle_error    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_pn_area          IN NUMBER DEFAULT NULL,
        o_id_epis_pn          OUT epis_pn.id_epis_pn%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the data blocks configs needed to perform the import of the data to the data block.
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_episode               Episode ID
    * @param   i_patient               Patient ID
    * @param   i_id_visit              visit ID
    * @param   i_begin_date            Date begin
    * @param   i_end_date              Date end
    * @param   i_flg_synch_note        Y-this note type should be synchronized. Should opens directly the edit screen. N-otherwise
    * @param   i_import_screen         Y- We are in the import screen: we . Should opens directly the edit screen. N-otherwize
    * @param   i_action                A-Auto-population; I-import
    * @param   i_data_blocks           t_rec_data_blocks
    * @param   i_id_epis_pn            epis_pn ID
    * @param   i_id_pn_note_type       pn_note_type ID
    * @param   i_id_epis_pn_det_task   epis_pn_det_task ID
    * @param   i_dt_proposed           note proposed date
    * @param   o_begin_date            Import start date
    * @param   o_end_date              Import end date
    * @param   o_scope                 Scope id (pateitn id, episode id or visit id)    
    * @param   o_error                 Error information
    *
    * @return  Boolean                 True: Sucess, False: Fail
    *
    * @value   i_scope_type            {*} 'E'- Episode {*} 'V'- Visit {*} 'P'- Patient
    * @value   i_flg_synch_note        {*} 'Y'- Yes {*} 'N'- no
    * @value   i_flg_data_removable    {*} 'N'- Not applicable {*} 'I'- Imported data {*} 'P'- Auto Populated
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.2
    * @since                           07-09-2011
    */
    FUNCTION get_data_block_configs
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_id_visit            IN visit.id_visit%TYPE DEFAULT NULL,
        i_begin_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_synch_note      IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_import_screen       IN VARCHAR2,
        i_action              IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_flg_action_import,
        i_data_blocks         IN t_rec_data_blocks,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type     IN pn_note_type.id_pn_note_type%TYPE,
        i_id_epis_pn_det_task IN table_number,
        i_dt_proposed         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_note_date           OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_begin_date          OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_end_date            OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_scope               OUT NUMBER,
        o_error               IN OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get imported data from temporary tables to be edited in Progress Notes (internal function)
    * related to one task type
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_episode               Episode ID
    * @param   i_patient               Patient ID
    * @param   i_pn_soap_block         SOAP block ID
    * @param   i_pn_data_block         Data block ID
    * @param   i_id_pn_note_type       Note type Identifier     
    * @param   i_begin_date            Date begin
    * @param   i_end_date              Date end
    * @param   i_scope_type            Scope (E- Episode, V- Visit, P- Patient)
    * @param   i_flg_block_type        Block Type (D- Documentation, T- Free Text)
    * @param   i_pn_task_type          Task type id   
    * @param   i_flg_import_date       Y-record date should be imported; N-otherwise 
    * @param   i_flg_group_on_import   D-records grouped by date
    * @param   i_flg_ongoing           O-auto-populate the ongoing tasks. F-auto-populate the finalized tasks. N-otherwize
    * @param   i_dblock_flg_type       Data block flg_Type
    * @param   i_flg_filter             Filter to apply
    *
    * @param   o_data_import_list      Data to return
    * @param   o_error                 Error information
    *
    * @return  Boolean                 True: Sucess, False: Fail
    *
    * @value   i_flg_finalized         {*} 'F'- auto-populate the finalized tasks {*} 'N'- otherwise
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.2
    * @since                           07-09-2011
    */
    FUNCTION get_import_task
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_pn_soap_block       IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block       IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_scope_type          IN VARCHAR2,
        i_scope               IN NUMBER,
        i_pn_task_type        IN epis_pn_det_task.id_task_type%TYPE,
        i_outside_period      IN VARCHAR2,
        i_flg_import_date     IN pn_dblock_mkt.flg_import_date%TYPE,
        i_flg_group_on_import IN pn_dblock_mkt.flg_group_on_import%TYPE,
        i_flg_ongoing         IN VARCHAR2,
        i_dblock_flg_type     IN pn_data_block.flg_type%TYPE,
        i_flg_synchronized    IN VARCHAR2,
        i_flg_filter          IN VARCHAR2,
        i_flg_view            IN vs_soft_inst.flg_view%TYPE,
        i_flg_first_record    IN VARCHAR2,
        i_only_autopop        IN VARCHAR2,
        i_flg_description       IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL,        
        o_data_import         IN OUT t_coll_data_import,
        o_error               IN OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Save an imported data block to a progress note
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_episode            Episode ID
    * @param   i_patient            Patient ID
    * @param   i_id_pn_note_type    Progress Note type (P-progress note; L-prolonged progress note; CC-intensive care note; H-history and physician note) 
    * @param   i_epis_pn            Progress note ID
    * @param   i_epis_pn_det        Progress note detail ID
    * @param   i_dep_clin_serv      Clinical Service ID
    * @param   i_pn_soap_block      SOAP Block ID
    * @param   i_pn_data_block      Data Block ID
    * @param   i_dt_begin           Start date to filter
    * @param   i_dt_end             End date to filter
    * @param   i_id_task_type       Array of task type ids
    * @param   i_id_pn_group        Group identifier
    * @param   i_id_epis_pn_det_task Epis_pn_det_task ID. To be used in templates when performing the copy and edit action, 
    *                                to replace the previous record (if configured to behave like that)
    * @param   o_flg_imported       Flg indicating data imported Y/N
    * @param   o_id_epis_pn        Id of the created note
    * @param   o_error              Error information
    *
    * @return  Boolean        True: Sucess, False: Fail
    * 
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   16-02-2011
    */
    FUNCTION set_import_data_block
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_id_pn_note_type     IN epis_pn.id_pn_note_type%TYPE,
        i_epis_pn             IN epis_pn.id_epis_pn%TYPE,
        i_epis_pn_det         IN epis_pn_det.id_epis_pn_det%TYPE,
        i_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_soap_block          IN epis_pn_det.id_pn_soap_block%TYPE,
        i_data_block          IN epis_pn_det.id_pn_data_block%TYPE,
        i_dt_begin            IN VARCHAR2,
        i_dt_end              IN VARCHAR2,
        i_id_task_type        IN epis_pn_det_task.id_task_type%TYPE,
        i_id_pn_group         IN pn_group.id_pn_group%TYPE,
        i_id_epis_pn_det_task IN epis_pn_det_task.id_epis_pn_det_task%TYPE,
        o_flg_imported        OUT VARCHAR2,
        o_id_epis_pn          OUT epis_pn.id_epis_pn%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Delete work tables
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis_pn      Progress note identifier
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   31-01-2011
    */
    FUNCTION delete_work_tables
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_pn IN NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Create a copy of an existing template.
    *
    * @param   i_lang             Professional preferred language
    * @param   i_prof             Professional identification and its context (institution and software)
    * @param   i_episode          Episode ID
    * @param   i_prof_cat_type    Professional category type    
    * @param   i_id_task          Array of task IDs
    *
    * @param   o_epis_documentation         The epis_documentation ID created
    * @param   o_id_epis_scales_score       The epis_scales_score ID created
    * @param   o_error                      Error information
    *
    * @return  Boolean        True: Sucess, False: Fail
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   27-09-2011
    */
    FUNCTION set_copy_template
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        o_id_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update one data block's content. If the data doesn't exists yet, the record will be created.
    * the IN parameter Type allow for select if append or update should be done to the text.
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_id_episode           Episode ID
    * @param   i_flg_action           C-Create; U-update; I-import
    * @param   i_prof_cat_type        Prof category type
    * @param   i_epis_pn_det          Progress note detail ID
    * @param   i_id_task              Task IDs
    * @param   i_id_task_aggregator   For analysis and exam recurrences, an imported registry will only be uniquely 
    *                                 identified by id_task (id_analysis/id_exam) + i_id_task_aggregator
    * @param   i_epis_pn_det_task     Array of PN task details
    * @param   i_pn_note_task         Array of PN task descriptions
    * @param   i_flg_add_rem_task     Array of task status (A- Active, R- Removed)
    * @param   i_flg_table_origin     Flag origin table for documentation ( D - documentation, A - Anamnesis, S - Review of system)
    * @param   i_dt_task              Task dates
    * @param   i_id_task_parent       Parent task identifier for comments functionality
    * @param   i_flg_task_parent      Flag tells where i_id_task_parent is a taskid or id_epis_pn_det_task
    * @param   i_id_multichoice       Array of tasks identifiers for cases that have more than one parameter (multichoice on exam results)
    * @param   i_rank_task            Rank of the tasks
    * @param   i_prof_task            Professional that created the tasks
    * @param   i_id_group_table       Id Group (vital sign id): vital signs table row id
    * @param   i_dblock_cfgs          Data block configs record
    * @param   i_id_patient           Patient id
    * @param   i_dt_pn_date           Progress Note date
    * @param   i_date_type            DH- Date hour; D-Date
    * @param   i_dblock_type          Data block type
    *
    * @param   io_id_task_type        Array of PN task types
    *
    * @param   O_FLG_RELOAD            Tells UX layer it It's needed the reload screen or not
    * @param   o_error                Error information
    *
    * @return  Boolean                True: Sucess, False: Fail
    *
    * @author                         RUI.BATISTA
    * @version                        <2.6.0.5>
    * @since                          04-02-2011
    */
    FUNCTION set_data_block_task
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_action         IN VARCHAR2,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_epis_pn_det        IN epis_pn_det.id_epis_pn_det%TYPE,
        i_id_task            IN table_number,
        i_id_task_aggregator IN table_number,
        i_epis_pn_det_task   IN table_number,
        i_pn_note_task       IN table_clob,
        i_flg_add_rem_task   IN table_varchar,
        i_flg_table_origin   IN table_varchar DEFAULT NULL,
        i_dt_task            IN table_varchar,
        i_id_task_parent     IN table_number,
        i_flg_task_parent    IN VARCHAR2,
        i_id_multichoice     IN table_number,
        i_rank_task          IN table_number,
        i_prof_task          IN table_number,
        i_id_group_table     IN table_number,
        i_dblock_cfgs        IN t_rec_dblock,
        i_dblock_task_type   IN t_coll_dblock_task_type DEFAULT NULL,
        i_id_patient         IN patient.id_patient%TYPE,
        i_dt_pn_date         IN VARCHAR2,
        i_date_type          IN VARCHAR2,
        i_dblock_type        IN pn_data_block.flg_type%TYPE,
        i_flg_related        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_group_type     IN VARCHAR2 DEFAULT NULL,
        io_id_task_type      IN OUT table_number,
        o_tbl_tasks          OUT pk_prog_notes_types.t_table_tasks,
        o_flg_reload         OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns a set of records done in a touch-option area for a specific id_epis_documentation
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID
    * @param i_id_epis_documentation  Epis documentation ID
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    *
    * @param   o_doc_area_register    Cursor with the doc area info register
    * @param   o_doc_area_val         Cursor containing the completed info for episode
    * @param   o_template_layouts     Cursor containing the layout for each template used
    * @param   o_doc_area_component   Cursor containing the components for each template used 
    * @param   o_id_doc_area          Documentation area ID       
    * @param   o_error                Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/03/03                                 
    **************************************************************************/
    FUNCTION get_epis_document_area_value
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_scope                 NUMBER,
        i_scope_type            IN VARCHAR2,
        o_doc_area_register     OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val          OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts      OUT pk_types.cursor_type,
        o_doc_area_component    OUT pk_types.cursor_type,
        o_id_doc_area           OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * SET_MATCH_SINGLE_PAGE                 This function rebuilds the single pages after an episode merge.
    *                                       it has to be called in the end of the merge.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.2
    * @since                                 29-Mar-2012
    **********************************************************************************************/
    FUNCTION set_match_single_page
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * SET_MATCH_PROG_NOTES                   This function make "match" of progress notes between episodes
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.0.5
    * @since                                 07-Apr-2011
    **********************************************************************************************/
    FUNCTION set_match_prog_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Review tasks
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_id_episode          Episode ID    
    * @param   i_id_task             tasks ids    
    * @param   i_id_task_type        task type ids
    * @param   i_flg_auto            reviewed automatically (Y/N)
    * @param   i_flg_review          (x): Indicates for each task if it is to be performed the review
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
    FUNCTION set_review_tasks
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_task      IN table_number,
        i_id_task_type IN table_number,
        i_flg_auto     IN review_detail.flg_auto%TYPE,
        i_flg_review   IN table_varchar,
        i_id_patient   IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the flag that indicates if should be performed a copy of the template in the import
    *
    * @param i_flg_cp_edit_import     Y-should be performed the copy    
    *
    * @return                 C-should be performed the copy of the task. A- should be added the current record to the note        
    *
    * @author               Sofia Mendes
    * @version              2.6.1.2
    * @since                29-09-2011
    */
    FUNCTION get_cp_no_changes_flg(i_flg_cp_edit_import IN pn_dblock_mkt.flg_cp_no_changes_import%TYPE) RETURN VARCHAR2;

    /**
    * Get the flag that indicates if the registry should be dimmed:
    * the reference to the original record is imported and the record had already been imported in the current note
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_episode         Episode identifier
    * @param   i_id_epis_pn         Note identifier
    * @param   i_id_task            Task identifier
    * @param   i_id_task_type            Task type identifier
    * @param   i_id_pn_data_block        Data block id
    * @param   i_id_pn_soap_block        Soap block id
    * @param   i_flg_cp_edit_import     Y-should be performed the copy   
    *
    * @return                 C-should be performed the copy of the task. A- should be added the current record to the note        
    *
    * @author               Sofia Mendes
    * @version              2.6.1.2
    * @since                29-09-2011
    */
    FUNCTION get_dimmed_flg
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_epis_pn             IN epis_pn.id_epis_pn%TYPE,
        i_id_task                IN epis_pn_det_task.id_task%TYPE,
        i_id_task_aggregator     IN epis_pn_det_task.id_task_aggregator%TYPE,
        i_id_task_type           IN epis_pn_det_task.id_task_type%TYPE,
        i_id_pn_data_block       IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block       IN pn_soap_block.id_pn_soap_block%TYPE,
        i_flg_import             IN pn_dblock_mkt.flg_import%TYPE,
        i_flg_previouly_imported IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Get the flag_select that indicates if the registry should be selected by default in the import screen.
    * If the record had already been imported it should not be selected even though it is configured to be selected by default.
    *
    * @param i_flg_selected                Y-Record configured to be selected by default. N-otherwise
    * @param i_flg_previously_imported     Y-Record that had already been imported. N-otherwise
    * @param i_flg_status                  Y-Record status. O -ongoing; F - finalized; I - inactive
    *
    * @return                 A-record selected by default. N-otherwise     
    *
    * @author               Sofia Mendes
    * @version              2.6.1.2
    * @since                29-09-2011
    */
    FUNCTION get_selected_flg
    (
        i_flg_selected            IN pn_dblock_ttp_mkt.flg_selected%TYPE,
        i_flg_previously_imported IN VARCHAR2,
        i_flg_status              IN task_timeline_ea.flg_ongoing%TYPE
    ) RETURN VARCHAR2;

    /**
    * Check if a parent of a comment is also in the importation list.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_epis_pn             Note id
    * @param i_id_parent_task         Id parent task   
    * @param i_id_parent_task_type    Parent task type
    * @param i_id_pn_data_block       Data block ID
    * @param i_id_pn_soap_block       Soap block ID
    * @param i_imported_data          Data to be imported   
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                10-May-2012
    */

    FUNCTION check_has_parent
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_parent_task      IN epis_pn_det_task.id_task%TYPE,
        i_id_parent_task_type IN epis_pn_det_task.id_task_type%TYPE,
        i_id_pn_data_block    IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_imported_data       IN t_coll_data_import
    ) RETURN VARCHAR2;

    /**
    * checks if the record should be reviewed by the general review mechanism.
    *
    * @param i_current_episode             Current episode ID
    * @param i_imported_episode            Episode in which was created the imported task
    * @param i_flg_review                  Y - the review is available on page/note. N-otherwise 
    * @param i_flg_review_avail            Y - the review is configured to be available to the current task type. N-otherwise
    * @param i_flg_auto_populated          Y-The data block is filled automatically with the existing info. N-otherwise       
    * @param i_flg_reviewed_epis           Y -The task had already been reviewed in the current episode
    * @param i_review_context              Context of revision. If it is filled the task requires revision.
    * @param i_id_task_type                Task type Id
    * @param i_flg_suggest_concept         Concept to determine the suggested records.
    * @param i_flg_editable                Y-Editable record; N-otherwise
    * @param i_flg_status                  Record flg status
    *
    * @return                 Y-The record must be auto-suggested to the user. N-otherwise     
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                13-04-2012
    */
    FUNCTION get_review_flg
    (
        i_current_episode     IN episode.id_episode%TYPE,
        i_imported_episode    IN episode.id_episode%TYPE,
        i_flg_review          IN pn_note_type_mkt.flg_review_all%TYPE,
        i_flg_review_avail    IN pn_dblock_ttp_mkt.flg_review_avail%TYPE,
        i_flg_auto_populated  IN pn_dblock_ttp_mkt.flg_auto_populated%TYPE,
        i_flg_reviewed_epis   IN VARCHAR2,
        i_review_context      IN tl_task.review_context%TYPE,
        i_id_task_type        IN tl_task.id_tl_task%TYPE,
        i_flg_suggest_concept IN pn_note_type_mkt.flg_suggest_concept%TYPE,
        i_flg_editable        IN pn_dblock_mkt.flg_editable%TYPE,
        i_flg_status          IN epis_pn_det_task.flg_status%TYPE
    ) RETURN VARCHAR2;

    /**
    * checks if all the tasks of this type should be selected when one of the tasks is selected (it works in a group)
    *
    * @param i_flg_review_all              Y-the review is available. N-otherwise
    * @param i_id_task_type                Task type Id
    *
    * @return                 Y-The record must be selected in group. N-otherwise     
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                15-03-2012
    */
    FUNCTION get_flg_select_in_group
    (
        i_flg_review_all IN pn_note_type_mkt.flg_review_all%TYPE DEFAULT pk_alert_constant.g_yes,
        i_id_task_type   IN tl_task.id_tl_task%TYPE
    ) RETURN VARCHAR2;

    /**
    * checks if all the tasks of this type should be selected when one of the tasks is selected (it works in a group)
    *
    * @param i_flg_data_removal       Indicates the data that can be removed. Configuration. 
    * @param i_flg_suggested          Y - suggested record. N-otherwise
    * @param i_flg_editable           A-Editable note. T-Not editable except free texts N-Otherwise
    * @param i_flg_action             I-record imported by import screen; A - record auto-populated; S- record created by shortcut
    *
    * @return                 Y-The record must be selected in group. N-otherwise     
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                15-03-2012
    */
    FUNCTION get_flg_remove
    (
        i_flg_data_removal IN pn_dblock_mkt.flg_data_removable%TYPE,
        i_flg_suggested    IN VARCHAR2,
        i_flg_editable     IN VARCHAR2,
        i_flg_action       IN epis_pn_det_task.flg_action%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns the suggested records for the episode
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_episode                episode identifier
    * @param      i_id_pn_note_type        Note type identifier
    * @param      i_id_epis_pn             Note identifier
    * @param      o_suggested              Texts that compose the note with the suggested records
    *
    * @param      o_error                  error information
    *
    * @return                              false if errors occur, true otherwise
    *
    * @author                              ANTONIO.NETO
    * @version                             2.6.2
    * @since                               08-Mar-2012
    */
    FUNCTION get_suggest_records
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN epis_pn.id_pn_note_type%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_suggested       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the suggested records for the episode. 
    * To be used in the discharge screen: only suggestes records to the physician professionals
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_episode                episode identifier
    * @param      i_id_pn_note_type        Note type identifier
    * @param      i_id_epis_pn             Note identifier
    * @param      o_suggested              Texts that compose the note with the suggested records
    *
    * @param      o_error                  error information
    *
    * @return                              false if errors occur, true otherwise
    *
    * @author                              Sofia Mendes
    * @version                             2.6.3.1
    * @since                               17-Jan-2012
    */
    FUNCTION get_suggest_records_disch
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN epis_pn.id_pn_note_type%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_suggested       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the parent registration date.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_cursor_pn_data         Imported data
    * @param i_id_task_parent         Parent task ID
    * @param i_id_task_type_parent    Parent task type    
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                09-Mai-2012
    */

    FUNCTION get_parent_date
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_cursor_pn_data      IN t_coll_pn_work_data,
        i_id_task_parent      IN epis_pn_det_task.id_task%TYPE,
        i_id_task_type_parent IN epis_pn_det_task.id_task_type%TYPE
    ) RETURN epis_pn_det_task.dt_task%TYPE;

    /**
    * Insert and update a set or records in the epis_pn_det_task table.
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_id_episode           Episode ID
    * @param   i_note_struct          Note info
    * @param   i_dt_last_update       Last update date    
    * @param   i_flg_synchronized     Y-Single note. N- single page
    * @param   i_flg_upd_note         Y-update the note header. N- do not update the note header
    * @param   i_tasks_descs_by_type  Group description not assigned yet to the note struct
    *
    * @param   o_error                Error information
    *
    * @return  Boolean                True: Sucess, False: Fail
    *
    * @author                         Sofia Mendes
    * @version                        2.6.2
    * @since                          20-Jun-2012
    */
    FUNCTION ins_upd_pn_note
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_note_struct         IN pk_prog_notes_types.t_note_struct,
        i_dt_last_update      IN epis_pn.dt_last_update%TYPE,
        i_flg_synchronized    IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_flg_sign_off        IN pn_note_type_mkt.flg_sign_off%TYPE,
        i_flg_submit          IN pn_note_type_mkt.flg_submit%TYPE,
        i_flg_upd_note        IN VARCHAR2,
        i_tasks_descs_by_type IN pk_prog_notes_types.t_tasks_descs_by_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets the note history in case the note was automatically saved in the last time.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis_pn      Progress note identifier
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.6.2
    * @since   26-Jul-2012
    */
    FUNCTION set_note_history
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the aggregated text.
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)         *                                 
    * @param   i_id_epis_pn_det       Epis_pn_det ID
    * @param   o_text                 Aggregated text
    * @param   o_error                Error information
    *
    * @return  Boolean                True: Sucess, False: Fail
    *
    * @author                         Sofia Mendes
    * @version                        2.6.2
    * @since                          20-Jun-2012
    */
    FUNCTION get_aggregated_text
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn_det IN epis_pn_det.id_epis_pn_det%TYPE,
        i_note_dash      IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
         i_flg_group_type IN VARCHAR2 DEFAULT NULL,
        o_text           OUT NOCOPY CLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_aggregated_text_clob
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn_det IN epis_pn_det.id_epis_pn_det%TYPE,
        i_note_dash      IN VARCHAR2 DEFAULT pk_alert_constant.get_no
    ) RETURN CLOB;
    /**
    * Update the task ranks to the vital signs table.
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)         *                                 
    * @param   i_id_episode           Episode ID
    * @param   i_id_visit             Visit ID
    * @param   i_id_patient           Patient ID
    * @param   i_note_struct          Note info
    * @param   o_error                Error information
    *
    * @return  Boolean                True: Sucess, False: Fail
    *
    * @author                         Sofia Mendes
    * @version                        2.6.2
    * @since                          20-Jun-2012
    */
    FUNCTION update_aggregations
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_visit    IN episode.id_visit%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_note_struct IN pk_prog_notes_types.t_note_struct,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * DELETE_NOTE         Deletes a note.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_epis_pn                    Note identifier
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.2
    * @since                                 29-Mar-2012
    **********************************************************************************************/
    FUNCTION delete_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update all patients notes for viewer_ehr_ea
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    *
    * @author  Vanessa Barsottelli
    * @version 2.6.3
    * @since   28-Feb-2014
    */
    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    );

    FUNCTION set_pn_group_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes      IN epis_pn_det.pn_note%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pn_free_text
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_dt_pn_date IN table_varchar,
        i_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_pn_note    IN table_clob,
        o_id_epis_pn OUT epis_pn.id_epis_pn%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * generic function to save review/submit progress note
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_pn                   Progress note identifier
    *
    * @param   o_error                     Error information
    *
    * @return                              Returns TRUE if success, otherwise returns FALSE
    *
    *
    * @author                              Carlos ferreira
    * @version                             2.7.2
    * @since                               2017-11-17
    */
    FUNCTION set_submit_review
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_review      IN NUMBER,
        i_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_flg_status       IN VARCHAR2,
        i_id_submit_reason IN epis_pn.id_submit_reason%TYPE DEFAULT NULL,
        i_notes_submit     IN epis_pn.notes_submit%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * function to save a "for review" progress note
    *
    */
    FUNCTION set_for_review
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_review IN NUMBER,
        i_epis_pn     IN epis_pn.id_epis_pn%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * function to to save a "submit" progress note
    *
    */
    FUNCTION set_submit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_submit_reason IN epis_pn.id_submit_reason%TYPE DEFAULT NULL,
        i_notes_submit     IN epis_pn.notes_submit%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION process_flg_submit
    (
        i_prof        IN profissional,
        i_flg_signoff IN VARCHAR2,
        i_flg_submit  IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_status_epis_pn(i_pk IN NUMBER) RETURN VARCHAR2;

    /*****************************************************************************
    * Get the comments for some note
    * 
    * @param  i_lang        IN   language.id_language%TYPE  Language id
    * @param  i_prof        IN   profissional               Professional structure
    * @param  i_id_epis_pn  IN   epis_pn.id_epis_pn%TYPE    Note id
    * @param  o_pn_comments OUT  pk_types.cursor_type
    * @param  o_error       OUT  t_error_out
    *
    * @return   BOOLEAN   TRUE if succeeds, FALSE otherwise
    *
    * @author   rui.mendonca
    * @version  2.7.2.2
    * @since    14/12/2017
    *****************************************************************************/
    FUNCTION get_pn_comments
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE,
        o_pn_comments OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_pn_area                pn_area table ID
    *
    * @param o_note_lists             cursor with the information for timeline
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @sincte                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_all_note_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pn_area_inter_name IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE,
        i_begin_date         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date           IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_note_lists         OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_calendar_date_control  UX calendar previous or next
    * @param i_current_date           UX calendar date
    *
    * @param o_calendar_period        calendar period
    * @param o_begin_date             calendar begin date
    * @param o_end_date               calendar end date
    * @param o_current_date_num       calendar current date num
    * @param o_calendar_dates         cursor with all date in current week
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_calendar_view_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_area       IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_begin_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_notes      OUT pk_types.cursor_type,
        o_notes_det  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get task related
    *
    * @param i_lang                   Language ID
    * @param i_id_pn_data_block       Data block identifier
    * @param i_id_pn_soap_block       Soap block identifier
    * @param i_id_pn_note_type        Note type identifier
    * @param i_id_task_type           Task type ID
    *
    * @param o_id_task_related        Task type identifier to be autopopulated with the informatition related
    *
    * @return                 TRUE if succeeds, FALSE otherwise
    *
    * @raises                 PL/SQL generic error "OTHERS"
    *
    * @author               Webber Chiou
    * @version              2.7.4.0
    * @since                2018-09-11
    */
    FUNCTION get_task_related
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pn_data_block IN pn_dblock_ttp_mkt.id_pn_data_block%TYPE,
        i_id_pn_soap_block IN pn_dblock_ttp_mkt.id_pn_soap_block%TYPE,
        i_id_pn_note_type  IN pn_dblock_ttp_mkt.id_pn_note_type%TYPE,
        i_id_task_type     IN table_number,
        o_id_task_related  OUT table_number
    ) RETURN BOOLEAN;    
    FUNCTION get_id_epis_pn
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_tbl_pn_note_type IN table_varchar,
        o_id_epis_pn       OUT NUMBER,
        o_id_pn_note_type  OUT NUMBER
    ) RETURN BOOLEAN;
    
END pk_prog_notes_core;
/
