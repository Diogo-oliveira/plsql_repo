/*-- Last Change Revision: $Rev: 2052331 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-12-06 15:34:38 +0000 (ter, 06 dez 2022) $*/
CREATE OR REPLACE PACKAGE pk_prog_notes_utils IS

    -- Author  : SOFIA.MENDES
    -- Created : 7/29/2011 9:51:16 AM
    -- Purpose : The purpose of this package is to contain the progress notes utility packages

    -- Public type declarations
    -- Public constant declarations
    -- Public variable declarations

    TYPE t_rec_actions_list IS RECORD(
        id_action     NUMBER(24),
        id_parent     NUMBER(24),
        level_num     NUMBER(6),
        from_state    VARCHAR2(1 CHAR),
        to_state      VARCHAR2(1 CHAR),
        desc_action   VARCHAR2(200 CHAR),
        icon          VARCHAR2(200 CHAR),
        flg_default   VARCHAR2(1 CHAR),
        flg_active    VARCHAR2(1 CHAR),
        internal_name VARCHAR2(200 CHAR));

    TYPE t_tbl_actions_list IS TABLE OF t_rec_actions_list;

    /**
    * Returns the number of notes in a given status associated to an episode created by a given profesional.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param i_id_prof_create_note   Professional that created the note
    * @param i_flg_statuses          List of Notes statuses. D-draft; S-Signed-off; M-migrated; C-Cancelled; F-Finalized
    * @param i_note_types             Note types
    *
    * @return               nr of notes
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_nr_notes_state
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_flg_statuses IN table_varchar,
        i_note_types   IN table_number
    ) RETURN PLS_INTEGER;

    -- Public function and procedure declarations
    /**
    * Returns the number of addendums in a given status associated to a note.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_epis_pn            Note identifier
    * @param i_id_prof_create        Professional that created the addendums
    * @param i_flg_statuses          List of addendums statuses. D-draft; S-Signed-off; C-Cancelled; F-Finalized
    *
    * @return               Nr of addendums associated to the given note
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_nr_addendums_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE,
        i_id_prof_create IN epis_pn.id_prof_create%TYPE,
        i_flg_statuses   IN table_varchar
    ) RETURN PLS_INTEGER;

    /**
    * Gets the professional that created a note.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_epis_pn            note identifier
    *
    * @return               professional id
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_note_prof
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN epis_pn.id_prof_create%TYPE;

    /**
    * Gets the professional that created the addendum.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_epis_addendum      Addendum identifier
    *
    * @return               professional id
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_addendum_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE
    ) RETURN epis_pn_addendum.id_professional%TYPE;

    /**
    * Get addendum for the sign-off screen
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_epis_pn_addendum   Addendum ID
    *
    * @param   o_addendum           Addendum text
    * @param   o_error              Error information
    *
    * @return  Boolean              True: Sucess, False: Fail
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   11-02-2011
    */
    FUNCTION get_pn_addendum
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_addendum         OUT NOCOPY pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the episode associated to the note.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_epis_pn            note identifier
    * @param i_id_epis_pn_work       Note identifier (from work table)
    *
    * @return               professional id
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_note_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN epis_pn.id_episode%TYPE;

    /**************************************************************************
    * Get the date in wich the note was associated to the task.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_task                Task Id
    * @param i_id_epis_pn             Epis Progress Note Id
    * @param o_dt_creation            Creation date
    * @param o_error                  Error message
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1
    * @since                          19-Mai-2011
    **************************************************************************/
    FUNCTION get_pn_insertion_date
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_task     IN epis_pn_det_task.id_task%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        o_dt_creation OUT NOCOPY epis_pn_det_task.dt_last_update%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the progress notes's id_dep_clin_serv
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_epis_pn            Progress Note ID
    * @param   o_dep_clin_serv      Progress Note id_dep_clin_serv
    * @param   o_error              Error information
    *
    * @return  Boolean        True: Sucess, False: Fail
    *
    * @author  Rui Batista
    * @version 2.6.0.5
    * @since   21-02-2011
    */
    FUNCTION get_pn_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        o_dep_clin_serv OUT NOCOPY dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the Progress Note status
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis_pn      Progress Notes ID
    *
    * @return  Varchar2        Progress Note status
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   31-01-2011
    */
    FUNCTION get_pn_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get just save status
    *
    * @param   i_lang             Professional preferred language
    * @param   i_prof             Professional identification and its context (institution and software)
    * @param   i_epis_pn          Progress note identifier
    *
    * @param   i_flg_just_save    Indicate if there is a just saved record (Y/N)
    * @param   o_error            Error information
    *
    * @return  Boolean
    *
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   22-02-2011
    */
    FUNCTION get_flg_just_save
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        o_flg_just_save OUT NOCOPY VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the actions to be displayed in the 'ADD' button in the progress notes summary screens.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_episode                    episode identifier
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null
    * @param i_flg_status_note            Selected note status.
    *                                     If no note is selected this param should be null
    * @param i_area                       HP - History and Physician Notes Screen
    *                                     PN - Progress Note Screen
    * @param o_actions      actions data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_actions_add_button
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        i_flg_status_note IN epis_pn.flg_status%TYPE,
        i_area            IN pn_area.internal_name%TYPE,
        o_actions         OUT NOCOPY pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the id_dictation report associated to a note.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_epis_pn            note identifier
    *
    * @return               professional id
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_dictation_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN epis_pn.id_dictation_report%TYPE;

    /**
    * Counts the number of child records a parent has
    *
    * @param   i_pn_soap_block    Soap Block id
    * @param   i_pn_data_block    Data Block id
    * @param   i_data_block       Collection of import data
    * @param   i_data             Collection of work data
    *
    * @return                     Number of child records
    *
    * @author               Rui Spratley
    * @version              2.6.0.5
    * @since                14-02-2011
    */

    FUNCTION count_child
    (
        i_pn_soap_block IN epis_pn_det.id_pn_soap_block%TYPE,
        i_pn_data_block IN epis_pn_det.id_pn_data_block%TYPE, --parent
        i_data_block    IN t_coll_data_blocks,
        i_data          IN t_coll_pn_work_data
    ) RETURN PLS_INTEGER;

    /**
    * Counts the number of child records a parent has (a import structrure parent)
    *
    * @param   i_pn_soap_block           Soap Block id
    * @param   i_pn_data_block           Data Block id
    * @param   i_pn_parent_no_struct     Parent Data Block id, not considering the import structure data blocks
    * @param   i_data_block              Collection of import data
    * @param   i_data                    Collection of work data
    *
    * @return                     Number of child records
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-01-2012
    */

    FUNCTION count_child_struct
    (
        i_pn_soap_block IN epis_pn_det.id_pn_soap_block%TYPE,
        i_pn_data_block IN epis_pn_det.id_pn_data_block%TYPE, --parent
        i_data_block    IN t_coll_data_blocks,
        i_data          IN t_coll_pn_work_data
    ) RETURN PLS_INTEGER;

    /**
    * Counts the number of epis_pn_det_task records
    *
    * @param   i_epis_pn          Epis Pn Id
    * @param   i_soap_block       Soap block id
    * @param   i_data_block       Data block id
    *
    * @return                     Epis_pn_det id
    *
    * @author               Rui Spratley
    * @version              2.6.0.5
    * @since                23-02-2011
    */

    FUNCTION get_epispn_det_by_block
    (
        i_epis_pn    IN epis_pn_det.id_epis_pn%TYPE,
        i_soap_block IN epis_pn_det.id_pn_soap_block%TYPE,
        i_data_block IN epis_pn_det.id_pn_data_block%TYPE
    ) RETURN NUMBER;

    /**
    * Counts the number of epis_pn_det_task records
    *
    * @param   i_epis_pn_det      Epis Pn Det Id
    * @param   i_flg_status       Flg_status that should be considered
    *
    * @return                     Number of child records
    *
    * @author               Rui Spratley
    * @version              2.6.0.5
    * @since                23-02-2011
    */

    FUNCTION count_tasks
    (
        i_epis_pn_det IN epis_pn_det.id_epis_pn_det%TYPE,
        i_flg_status  IN table_varchar
    ) RETURN PLS_INTEGER;

    /**
    * Check if it is possible to create more notes in some status/statuses.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_epis_pn                 Note identifier
    * @param i_flg_statuses               Addendums Status list
    * @param o_create_avail               Y-It is possible to create more notes. N-otherwise.
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION check_max_addendums
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
        i_flg_statuses IN table_varchar,
        o_create_avail OUT NOCOPY PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if it is possible to create more notes.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_episode                 Episode identifier
    * @param i_note_type                  Note type id
    * @param o_flg_show                   Y - It is necessary to show the popup.
    *                                     N - otherwise.
    * @param o_msg_title                  Title
    * @param o_msg                        Message text
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                09-Feb-2011
    */
    FUNCTION check_create_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        o_flg_show   OUT NOCOPY VARCHAR2,
        o_msg_title  OUT NOCOPY VARCHAR2,
        o_msg        OUT NOCOPY VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if it is possible to change the note (edit,cancel,sig off)
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure
    * @param i_flg_status_note         Note status: D-draft; S-signed-off; C-Cancelled; F-Finalized
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null
    * @param i_flg_write                  Y-The note type has write permissions. N-otherwise
    * @param i_flg_dictation_editable     Y-It is allowed to edit the dictations on app. N -otherwise
    * @param i_flg_edit_other_prof        Y-The note can be edited by a professional that does not create it. N-otherwise
    *
    * @return               1-the note can be changed; 0-otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                28-Jan-2011
    */
    FUNCTION check_change_note
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_flg_status_note        IN epis_pn.flg_status%TYPE,
        i_id_epis_pn             IN epis_pn.id_epis_pn%TYPE,
        i_flg_write              IN pn_note_type_mkt.flg_write%TYPE,
        i_flg_dictation_editable IN pn_note_type_mkt.flg_dictation_editable%TYPE,
        i_flg_edit_other_prof    IN pn_note_type_mkt.flg_edit_other_prof%TYPE,
        i_flg_submit             IN pn_note_type_mkt.flg_submit%TYPE DEFAULT NULL
    ) RETURN PLS_INTEGER;

    /**
    * Check if it is possible to change the addendum (edit,cancel,sig off)
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure
    * @param i_flg_status_addendum     Addendum status: D-draft; S-signed-off; C-Cancelled; F-Finalized
    * @param i_id_epis_pn_addendum     Selected addendum Id.
    *                                  If no note is selected this param should be null
    *
    * @return               1-the note can be changed; 0-otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                28-Jan-2011
    */
    FUNCTION check_change_addendum
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_status_addendum IN epis_pn_addendum.flg_status%TYPE,
        i_id_epis_addendum    IN epis_pn_addendum.id_epis_pn_addendum%TYPE
    ) RETURN PLS_INTEGER;

    /********************************************************************************************
    * Returns if the import should be available according to the given note type.
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PN_NOTE_TYPE       Note Type Identifier
    * @param I_ID_EPISODE            Episode Identifier
    * @param O_IMPORT_AVAIL          Y- the import is availabel. N-otherwise
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Ant? Neto
    * @since                         27-Jul-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_import_avail_config
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        o_import_avail    OUT NOCOPY pn_note_type_soft_inst.flg_import_first%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the list of configs to the given note type.
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PN_NOTE_TYPE       Note Type Identifier
    * @param I_ID_EPISODE            Episode Identifier
    * @param i_id_epis_pn            Note Identifier
    * @param O_CONFIGS               Cursor with all the configs for the note type
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Ant? Neto
    * @since                         03-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_note_type_configs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        o_configs         OUT NOCOPY pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if it is possible to create more addendums.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_epis_pn                 Note identifier
    * @param o_create_avail               Y-It is possible to create more notes. N-otherwise.
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION check_max_draft_addendums
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
        o_create_avail OUT NOCOPY PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if it is possible to create more notes in some status/statuses.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_episode                 episode identifier
    * @param i_note_type                  Type of note id
    * @param o_create_avail               Y-It is possible to create more notes. N-otherwise.
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION check_max_draft_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_note_type    IN pn_note_type.id_pn_note_type%TYPE,
        o_create_avail OUT NOCOPY PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if it is possible to create more notes in some status/statuses.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_episode                 episode identifier
    * @param i_flg_statuses               Notes Status list
    * @param i_flg_check_draft            Y-check the maximum nr of draft notes. N-check the maximum nr of notes
    * @param i_note_types                 Note types
    * @param o_create_avail               Y-It is possible to create more notes. N-otherwise.
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION check_max_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_flg_statuses    IN table_varchar,
        i_flg_check_draft IN VARCHAR2,
        i_note_type       IN pn_note_type.id_pn_note_type%TYPE,
        o_create_avail    OUT NOCOPY PLS_INTEGER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if it is possible to create more addendums.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_epis_pn                 Note identifier
    * @param o_flg_show                   Y - It is necessary to show the popup.
    *                                     N - otherwise.
    * @param o_msg_title                  Title
    * @param o_msg                        Message text
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                09-Feb-2011
    */
    FUNCTION check_create_addendums
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_flg_show   OUT NOCOPY VARCHAR2,
        o_msg_title  OUT NOCOPY VARCHAR2,
        o_msg        OUT NOCOPY VARCHAR2,
        o_error      OUT t_error_out
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
    FUNCTION check_show_edition_popup
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_epis_pn            IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        o_flg_show              OUT NOCOPY VARCHAR2,
        o_msg_title             OUT NOCOPY VARCHAR2,
        o_msg                   OUT NOCOPY VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the actions to be displayed in the 'ACTIONS' button when a note is selected.
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure
    * @param i_flg_status_note         Note status: D-draft; S-signed-off; C-Cancelled; F-Finalized
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null
    * @param o_actions      actions data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_actions_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_status_note IN epis_pn.flg_status%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_actions         OUT NOCOPY pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the actions to be displayed in the 'ACTIONS' button when an addendum is selected
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure
    * @param i_flg_status_addendum     Addendum status: D-draft; S-signed-off; C-Cancelled; F-Finalized
    * @param i_id_epis_addendum        Addendum Id
    * @param o_actions                 actions data
    * @param o_error                   error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_actions_addendum
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_status_addendum IN epis_pn_addendum.flg_status%TYPE,
        i_id_epis_addendum    IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_actions             OUT NOCOPY pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Return functionality help
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_doc_area            Documentation area ID
    *
    * @param   o_text                 Cursor with functionality help
    * @param   o_error                Error
    *
    * @author                         Filipe Silva
    * @version                        2.6.0.5
    * @since                          2011/03/17
    **************************************************************************/

    FUNCTION get_section_help_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        o_text        OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get the period of time ( begin date and end date) during which a record
    * is available (called by import screen)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode Identifier
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_flg_synchronized       Y-If Data Blocks info is to be synchronized with the directed areas, other than templates. N-otherwise
    * @param i_import_screen          Y- We are in the import screen: we . Should opens directly the edit screen. N-otherwize
    * @param i_action                 A-Auto-population; I-import
    * @param i_data_blocks            Data blocks to be imported
    * @param i_id_epis_pn_det_task    Task Ids that have to be syncronized
    * @param i_id_epis_pn             Note id
    * @param i_id_pn_note_type        Note type id
    * @param i_dt_proposed            note proposed date
    *
    * @param o_begin_date             Begin date
    * @param o_end_date               End date
    * @param o_error                  Error message
    *
    * @value i_flg_synchronized       {*} 'Y'- Yes {*} 'N'- no
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          23/09/2011
    **************************************************************************/
    FUNCTION get_import_dates
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_begin_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_synchronized    IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_import_screen       IN VARCHAR2,
        i_action              IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_flg_action_import,
        i_data_blocks         IN t_rec_data_blocks,
        i_id_epis_pn_det_task IN table_number,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_id_pn_note_type     IN pn_note_type.id_pn_note_type%TYPE,
        i_dt_proposed         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_note_date           OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_begin_date          OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_end_date            OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get detail/history signature line
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_episode                Episode id
    * @param   i_id_prof_create            Professional that created the registry
    * @param   i_dt_create                 Creation date
    * @param   i_id_prof_last_update       Professional id that performed the last change
    * @param   i_dt_last_update            Last update date
    * @param   i_id_prof_sign_off          Professional that signed off
    * @param   i_dt_sign_off               Sign off date
    * @param   i_id_prof_cancel            Professional that cancelled the registry
    * @param   i_dt_cancel                 Cancelation date
    * @param   i_id_dictation_report       Dictation report id
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version v2.6.0.5
    * @since   18-Jan-2011
    */
    FUNCTION get_signature
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_prof_create      IN professional.id_professional%TYPE,
        i_dt_create           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_update IN professional.id_professional%TYPE,
        i_dt_last_update      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_sign_off    IN professional.id_professional%TYPE,
        i_dt_sign_off         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_cancel      IN professional.id_professional%TYPE,
        i_dt_cancel           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_dictation_report IN dictation_report.id_dictation_report%TYPE DEFAULT NULL,
        i_flg_history         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_has_addendums       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_software         IN software.id_software%TYPE DEFAULT NULL,
        i_id_prof_reviewed    IN professional.id_professional%TYPE DEFAULT NULL,
        i_dt_reviewed         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_prof_submit      IN professional.id_professional%TYPE DEFAULT NULL,
        i_dt_submit           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_epis_pn             IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_flg_screen          IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Get note type configs.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_episode                 episode id
    * @param i_id_profile_template        profile template id
    * @param i_id_market                  Market id
    * @param i_id_department              Department id
    * @param i_id_category                Category id
    * @param i_id_dep_clin_serv           Dep_clin_serv id
    * @param i_id_epis_pn                 Note identifier
    * @param i_area                       Area internal name
    * @param i_software          Software ID
    *
    * @return               note type configs
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_note_type_config
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_id_department       IN department.id_department%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_category         IN category.id_category%TYPE DEFAULT NULL,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_id_pn_note_type     IN pn_note_type.id_pn_note_type%TYPE DEFAULT NULL,
        i_software            IN software.id_software%TYPE
    ) RETURN t_rec_note_type;

    /**
    * Get Area configs.
    *
    * @param i_lang                       Language identifier
    * @param i_prof                       Logged professional structure
    * @param i_id_episode                 Episode id
    * @param i_id_market                  Market id
    * @param i_id_department              Department id
    * @param i_id_dep_clin_serv           Dep_clin_serv id
    * @param i_area                       Area internal name
    * @param   i_episode_software          Software ID associated to the episode
    *
    * @return                             Area configs
    *
    * @author                             Ant? Neto
    * @version                            2.6.1.2
    * @since                              28-Jul-2011
    */
    FUNCTION get_area_config
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_area             IN pn_area.internal_name%TYPE,
        i_episode_software IN software.id_software%TYPE
    ) RETURN t_rec_area;

    /**
    * Get the note type description.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_pn_note_type            Note type description
    * @param i_flg_code_note_type         Indicates the desired description
    *
    * @return               note type desc
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_note_type_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_pn_note_type    IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_code_note_type IN VARCHAR2
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Check the note type.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_epis_pn                 Note identifier
    *
    * @return               note type id
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_note_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE DEFAULT NULL
    ) RETURN epis_pn.id_pn_note_type%TYPE;

    /********************************************************************************************
    * Checks if the Progress Note info (for Note Types or Data Blocks) is valid compared with Patient info
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PN_AGE_MIN            PN minimum age accepted
    * @param I_PN_AGE_MAX            PN maximum age accepted
    * @param I_PN_GENDER             PN gender accepted
    * @param I_PAT_AGE               Patient age
    * @param I_PAT_GENDER            Patient gender
    *
    * @return                        Returns 'Y' if validation passed, otherwise returns 'N'
    *
    * @author                        Ant? Neto
    * @since                         04-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION check_pn_with_patient_info
    (
        i_lang       IN language.id_language%TYPE,
        i_pn_age_min IN NUMBER,
        i_pn_age_max IN NUMBER,
        i_pn_gender  IN VARCHAR2,
        i_pat_age    IN patient.age%TYPE,
        i_pat_gender IN patient.gender%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if patient has discharge (in episode) and if note type doesn't allow editions after discharge remove the permissions
    *
    * @param I_EDITABLE_AFTER_DISCHARGE      Flag Edition After Discharge from the note type
    * @param i_is_dicharged                  Y if the Flag Discharge Status is 'A' ou 'P'  and N otherwise 
    *
    * @return                                Returns 'Y' if Flag Edition After Discharge is ON (Y) or patient hasn't discharge, otherwise returns 'N'
    *
    * @author                                Ant? Neto
    * @since                                 05-Aug-2011
    * @version                               2.6.1.2
    ********************************************************************************************/
    FUNCTION get_discharge_note_status
    (
        i_editable_after_discharge IN VARCHAR2,
        i_is_dicharged             IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the Area Description by the Note Type ID or directly by the Area ID
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE            Episode identifier
    * @param I_ID_PN_NOTE_TYPE       Note Type identifier
    * @param I_ID_PN_AREA            Note Area identifier
    *
    * @return                        Area description
    *
    * @author                        Ant? Neto
    * @since                         08-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_area_desc_by_note_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_area      IN pn_area.id_pn_area%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets a summary of PN Notes for a Patient
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PN_AREA            Area Identifier to filter on
    * @param I_SCOPE                 Scope ID
    *                                     E-Episode ID
    *                                     V-Visit ID
    *                                     P-Patient ID
    * @param I_SCOPE_TYPE            Scope type
    *                                     E-Episode
    *                                     V-Visit
    *                                     P-Patient
    * @param I_FLG_SCOPE             Flag to filter the scope
    *                                     S-Summary 1.st level (last Note)
    *                                     D-Detailed 2.nd level (Last Note by each Area)
    *                                     C-Complete 3.rd level (All Notes for Note Type selected)
    * @param I_INTERVAL             Interval to filter
    *                                     D-Last 24H
    *                                     W-Week
    *                                     M-Month
    *                                     A-All
    * @param O_DATA                  Cursor with PN Data to show
    * @param O_TITLE                 Variable that indicates the title that should appear on viewer
    * @param O_SCREEN_NAME           Variable that indicates the Area SWF Screen Name
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Ant? Neto
    * @since                         08-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_viewer_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pn_area      IN pn_area.id_pn_area%TYPE,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_flg_scope       IN VARCHAR2,
        i_interval        IN VARCHAR2,
        i_flg_viewer_type IN pn_note_type.flg_viewer_type%TYPE DEFAULT NULL,
        o_data            OUT NOCOPY pk_types.cursor_type,
        o_title           OUT NOCOPY sys_message.desc_message%TYPE,
        o_screen_name     OUT NOCOPY pn_area.screen_name%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the Configurations of a PN Area
    *
    * @param   i_lang                      Language identifier
    * @param   i_prof                      Professional Identification
    * @param   i_episode                   Episode identifier
    * @param   i_id_market                 Market identifier
    * @param   i_id_department             Service identifier
    * @param   i_id_dep_clin_serv          Service/specialty identifier
    * @param   i_area                      Internal name of the Area to get Configurations
    * @param   i_episode_software          Software ID associated to the episode
    *
    * @return                              Returns the Area Configurations related to the specified profile
    *
    * @author                              Ant? Neto
    * @version                             2.6.1.2
    * @since                               26-Jul-2011
    **********************************************************************************************/
    FUNCTION tf_pn_area
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_area             IN pn_area.internal_name%TYPE,
        i_episode_software IN software.id_software%TYPE
    ) RETURN t_coll_area;

    /********************************************************************************************
    * Gets the Configurations of a PN Note Type
    *
    * @param   i_lang                      Language identifier
    * @param   i_prof                      Professional Identification
    * @param   i_id_profile_template       Logged professional profile
    * @param   i_episode                   Episode identifier
    * @param   i_id_market                 Market identifier
    * @param   i_id_department             Service identifier
    * @param   i_id_dep_clin_serv          Service/specialty identifier
    * @param   i_id_category               Prefessional Category identifier
    * @param   i_area                      Internal name of the Area to get Configurations
    * @param   i_id_note_type              Note Type identifier
    * @param   i_flg_scope                 Scope: A-Area; N-Note Type
    * @param   i_software                  Software ID
    *
    * @return                              Returns the Note Type Configurations related to the specified profile
    *
    * @author                              Ant? Neto
    * @version                             2.6.1.2
    * @since                               26-Jul-2011
    **********************************************************************************************/
    FUNCTION tf_pn_note_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_profile_template IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_id_market           IN market.id_market%TYPE DEFAULT NULL,
        i_id_department       IN department.id_department%TYPE DEFAULT NULL,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_category         IN category.id_category%TYPE DEFAULT NULL,
        i_area                IN table_varchar,
        i_id_note_type        IN pn_note_type.id_pn_note_type%TYPE DEFAULT NULL,
        i_flg_scope           IN VARCHAR2,
        i_software            IN software.id_software%TYPE
    ) RETURN t_coll_note_type
        PIPELINED;

    /**
    * Get the max notes of all the note type of an area.
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_area               Area internal name
    *
    * @param   o_area_max_notes     Area max notes
    * @param   o_error              Error information
    *
    * @return  Boolean              True: Sucess, False: Fail
    *
    * @author  Sofia Mendes
    * @version <2.6.1.2>
    * @since   18-08-2011
    */
    FUNCTION get_area_max_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_area           IN pn_area.internal_name%TYPE,
        o_area_max_notes OUT NOCOPY PLS_INTEGER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the ID_epis_pn_det_task of an imported record
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_episode         Note identifier
    * @param   i_id_epis_pn         Note identifier
    * @param   i_id_task            Task identifier
    * @param   i_id_task_aggregator Aggregator task identifier
    * @param   i_id_task_type            Task type identifier
    * @param   i_id_pn_data_block        Data block id
    * @param   i_id_pn_soap_block        Soap block id
    * @param   i_flg_only_active         Y-check only in the active records. N-check in all the records
    * @param   o_id_epis_pn_det_task     Id epis_pn_det_task
    * @param   o_flg_status              epis_pn_det_task status
    * @param   o_task_text               Text in the note
    * @param   o_dt_last_update_task     Last update date of the task
    * @param   o_dt_review_task          Review date
    * @param   o_rank_task               Task rank
    *
    * @return  Boolean             Success / Error
    *
    * @author  Sofia Mendes
    * @version <2.6.1.2>
    * @since   22-08-2011
    */
    FUNCTION get_imported_record
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_task             IN epis_pn_det_task.id_task%TYPE,
        i_id_task_aggregator  IN epis_pn_det_task.id_task_aggregator%TYPE,
        i_id_task_type        IN epis_pn_det_task.id_task_type%TYPE,
        i_id_pn_data_block    IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_flg_only_active     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_id_epis_pn_det_task OUT NOCOPY epis_pn_det_task.id_epis_pn_det_task%TYPE,
        o_task_text           OUT NOCOPY epis_pn_det_task.pn_note%TYPE,
        o_flg_status          OUT NOCOPY epis_pn_det_task.flg_status%TYPE,
        o_dt_last_update_task OUT NOCOPY epis_pn_det_task.dt_task%TYPE,
        o_dt_review_task      OUT NOCOPY epis_pn_det_task.dt_review%TYPE,
        o_rank_task           OUT NOCOPY epis_pn_det_task.rank_task%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Validates if a record had already been imported.
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_episode         Episode identifier
    * @param   i_id_epis_pn         Note identifier
    * @param   i_id_task            Task identifier
    * @param   i_id_task_type            Task type identifier
    * @param   i_id_pn_data_block        Data block id
    * @param   i_id_pn_soap_block        Soap block id
    * @param   i_flg_only_active         Y-check only in the active records. N-check in all the records
    * @param   i_flg_syncronized         Y-Single page. N-Single note.
    *
    * @return  VARCHAR2             Y- the record had already been imported. N-otherwise.
    *
    * @author  Sofia Mendes
    * @version <2.6.1.2>
    * @since   22-08-2011
    */
    FUNCTION check_imported_record
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_pn         IN epis_pn.id_epis_pn%TYPE,
        i_id_task            IN epis_pn_det_task.id_task%TYPE,
        i_id_task_aggregator IN epis_pn_det_task.id_task_aggregator%TYPE,
        i_id_task_type       IN epis_pn_det_task.id_task_type%TYPE,
        i_id_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_flg_only_active    IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    /**
    * Get the import detail info: description of the task and signature
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_pn_task_type           Task type id
    * @param i_id_task                Task id
    * @param i_id_episode             Episode id: in which the task was requested
    * @param i_dt_register            Task registration date
    * @param i_prof_register          Professional that performed the request
    * @param i_id_data_block          Data block used to get description info
    * @param i_id_soap_block          Soap block used to get description info
    * @param i_id_note_type           Note type used to get description info
    *
    * @param o_task_desc              Task detailed description
    * @param o_signature              Signature
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          29-Set-2011
    */
    FUNCTION get_import_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_type  IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task       IN epis_pn_det_task.id_task%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_dt_register   IN VARCHAR2,
        i_prof_register IN professional.id_professional%TYPE,
        i_id_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        o_task_desc     OUT NOCOPY CLOB,
        o_signature     OUT NOCOPY VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the task descriptions.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_task_type           Task type id
    * @param i_id_task                Task id
    * @param i_code_description       Code translation to the task description
    * @param i_universal_desc_clob    Large Description created by the user
    * @param i_flg_sos                Flag SOS/PRN
    * @param i_dt_begin               Begin Date of the task
    * @param i_id_doc_area            Documentation Area identifier
    * @param i_flg_status             Status of the task
    * @param i_code_desc_sample_type  Sample type code description
    * @param o_short_desc             Short description to the import last level
    * @param o_detailed_desc          Detailed desc for more info and note
    *
    * @return                         Task detailed description
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          09-Feb-2012
    */
    FUNCTION get_task_descs
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
        o_short_desc            OUT NOCOPY CLOB,
        o_detailed_desc         OUT NOCOPY CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the data blocks array from definitive table
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_epis_pn             Note identifier
    * @param i_id_pn_soap_block       Soap blocks ID
    * @param o_data_blocks            Data blocks array
    * @param o_soap_blocks            Soap blocks array
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Rui Spratley
    * @version              2.6.0.5
    * @since                01-03-2011
    */

    FUNCTION get_notes_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_soap_block IN table_number,
        o_data_blocks      OUT NOCOPY table_number,
        o_soap_blocks      OUT NOCOPY table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the child task types associated to the given data block
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             Episode ID
    * @param i_id_market              Market ID
    * @param i_id_department          Department ID
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_data_block       Data block ID
    * @param i_id_pn_soap_block       Soap block ID
    * @param i_id_task_type_prt       Task type parent Id
    * @param i_software               Software ID
    * @param o_task_types             Task types list
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version              2.6.1.2
    * @since                01-09-2011
    */

    FUNCTION get_dblock_task_types
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_software         IN software.id_software%TYPE,
        i_id_task_type_prt IN tl_task.id_parent%TYPE,
        i_id_task_related  IN table_number DEFAULT NULL,
        o_task_types       OUT NOCOPY table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the data block type.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_pn_data_block                 Note identifier
    *
    * @return               note type id
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_data_block_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN pn_data_block.flg_type%TYPE;

    /**
    * Returns the Child tasks from i_id_task_type. If there is no childs it is returned the parent in this list.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_task_type           Task type identifier
    * @param o_task_types             Child tasks from i_id_task_type.
    * @param o_nr_task_types          Nr of task types
    *                                 If there is no childs it is returned the parent in this list.
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                17-Nov-2011
    */

    FUNCTION get_child_task_types
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_type  IN tl_task.id_tl_task%TYPE,
        o_task_types    OUT NOCOPY table_number,
        o_nr_task_types OUT PLS_INTEGER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the parent data block that does not belong to the import structure data block types.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_dblokcs                Data blocks info
    * @param i_id_pn_data_block       Data block to search for parent
    * @param i_id_pn_soap_block       Soap block to search for parent
    *
    * @return                         Parent of the i_id_pn_data_block that does not belong to the import structure type
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                23-Jan-2012
    */

    FUNCTION get_parent_no_struct
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_dblocks          IN t_coll_data_blocks,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN pn_data_block.id_pn_data_block%TYPE;

    /**
    * Returns the nr of childs that a given data block has
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_dblokcs                Data blocks info
    * @param i_id_prt_data_block      Parent Data block to search for nr of childs
    * @param i_id_pn_soap_block       Soap block id
    *
    * @return                         Nr of childs of the given data block
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION get_count_childs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_dblocks           IN t_coll_data_blocks,
        i_id_prt_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block  IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN PLS_INTEGER;

    /**
    * Returns the nr of records childs of the import structure data block
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_data                   Imported data
    * @param i_id_prt_data_block      Parent Data block to search for nr of childs
    * @param i_id_pn_soap_block       Soap block ID
    *
    * @return                         Nr of childs of the given data block
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION get_count_nr_records
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_data              IN t_coll_pn_work_data,
        i_id_prt_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block  IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN PLS_INTEGER;

    /**
    * Calculates the id_data_block to the used when replacing import structure by imported data.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_parent_no_struct    Parent data block (not considering import structure dblocks)
    * @param i_dblock_flg_type        Generic data block type (Date, group or sub-group) to be replaced by import data
    * @param i_id_dblock_parent       Parent data block
    * @param i_id_pn_soap_block       Soap block id
    * @param i_date                   Imported date
    * @param i_id_sub_group           Imported group
    * @param i_id_sub_sub_group       Imported sub-group
    * @param o_id_pn_data_block       Data block ID
    * @param o_id_dblock_no_checksum  String used to generate the data block ID
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION get_id_data_block_imp
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_parent_no_struct   IN pn_data_block.id_pn_data_block%TYPE,
        i_dblock_flg_type       IN pn_data_block.flg_type%TYPE,
        i_id_dblock_parent      IN pk_translation.t_desc_translation,
        i_id_pn_soap_block      IN pn_soap_block.id_pn_soap_block%TYPE,
        i_date                  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_sub_group          IN NUMBER,
        i_id_sub_sub_group      IN NUMBER,
        o_id_pn_data_block      OUT NOCOPY pn_data_block.id_pn_data_block%TYPE,
        o_id_dblock_no_checksum OUT NOCOPY pk_translation.t_desc_translation,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Calculates the id_data_block parent to the used when replacing import structure by imported data.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_parent_dblock       Parent data block (not considering import structure dblocks)
    * @param i_prev_id_data_block     Previsous data block (new parent)
    * @param i_prev_dblock_str        Previsous data block (new parent) in str format
    * @param o_id_parent              Calculated id_pn_data_block
    * @param o_id_parent_str          Calculated id_pn_data_block in str format
    *
    * @return                         Calculated id_pn_data_block
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION get_id_dblock_prt_imp
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_parent_dblock   IN pn_data_block.id_pndb_parent%TYPE,
        i_prev_id_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_prev_dblock_str    IN pk_translation.t_desc_translation,
        o_id_parent          OUT NOCOPY pn_data_block.id_pn_data_block%TYPE,
        o_id_parent_str      OUT NOCOPY pk_translation.t_desc_translation,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if the data block i_id_pn_data_block exists in the list i_dblocks
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_data_block       Data block to search for
    * @param i_id_pn_soap_block       Soap block to search for
    * @param i_id_dblock_parent       Parent Data block
    * @param i_dblokcs                Data blocks info
    
    *
    * @return                         Nr of childs of the given data block
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION check_exists_data_block
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_dblock_parent IN pn_data_block.id_pndb_parent%TYPE,
        i_dblocks          IN t_coll_data_blocks
    ) RETURN PLS_INTEGER;

    /**
    * Gets the description to an import structure data block.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_dblock_flg_type        Generic data block type (Date, group or sub-group) to be replaced by import data
    * @param i_date_desc              Date description
    * @param i_sub_group_title        Sub group description
    * @param i_sub_sub_group_title    Sub sub group description
    *
    * @return                         Import struct data block desc
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION get_imp_dblock_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_dblock_flg_type     IN pn_data_block.flg_type%TYPE,
        i_date_desc           IN pk_translation.t_desc_translation,
        i_sub_group_title     IN pk_translation.t_desc_translation,
        i_sub_sub_group_title IN pk_translation.t_desc_translation
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Checks if the i_data_block exists in the list of data blocks
    *
    * @param i_table                  Data blocks info list
    * @param i_id_pn_data_block       data block identifier
    *
    *
    * @return                        -1: soap block not found; Otherwise: index of the soap block in the given list
    *
    * @author               Sofia Mendes
    * @version               2.6.1.3
    * @since                25-Jan-2012
    */
    FUNCTION search_tab_data_blocks
    (
        i_table      IN t_coll_data_blocks,
        i_data_block IN NUMBER
    ) RETURN NUMBER;

    /**
    * Gets the note ID associated to the given episode and note type
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             Episode ID
    * @param i_id_pn_note_type        Note type ID
    * @param o_id_epis_pn             Note id, if exists one for the given episode and task type
    * @param i_id_pn_note_type        Error info
    *
    * @return                         Note id, if exists one for the given episode and task type
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                09-Feb-2012
    */

    FUNCTION get_note_id
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_id_epis_pn      OUT epis_pn.id_epis_pn%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get the task text to be saved on note. Concats the title and subtitle if they exists
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_group_title            Title
    * @param i_group_sub_title        Sub title
    * @param i_group_sub_sub_title    Sub Sub title
    * @param i_task_desc              Original task description
    *
    * @return                         Final task desc
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          07-Mar-2012
    */
    FUNCTION get_task_text
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_group_title         IN VARCHAR2,
        i_group_sub_title     IN VARCHAR2,
        i_group_sub_sub_title IN VARCHAR2,
        i_task_desc           IN CLOB
    ) RETURN CLOB;

    /**
    * Returns the template name in the templates related tasks.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_coll_dblock_task_type  Data block task types info structure
    * @param i_id_pn_data_block       Data block Id
    *
    * @return                         Y - If the task is to be synchronized immediately with the directed area
    *                                 when is changed in the note. N- otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since               19-Sep-2011
    */
    FUNCTION get_flg_synch_area
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_coll_dblock_task_type IN t_coll_dblock_task_type,
        i_id_pn_data_block      IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN tl_task.flg_synch_area%TYPE;

    /********************************************************************************************
    * get the actions available for a given record.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_id_task_type            Type of the task
    * @param       i_id_task                 Task reference ID
    * @param       i_flg_review              Y-the review action should be available. N-otherwisse
    * @param       i_flg_remove              Y-the remove action should be available. N-otherwisse
    * @param       i_flg_review_all          Y-the review action should be available. N-otherwisse
    * @param       i_flg_table_origin        Table origin from templates
    * @param       i_flg_write               Y-it is allowed to write in the task data block. N-otherwisse
    * @param       i_flg_actions_available   Y-The area actions are available. N-otherwisse
    * @param       i_flg_editable            A-All editable; N-not editable; T-text editable
    * @param       i_flg_dblock_editable     Y- Tis data block has edition permission. N-Otherwise
    * @param       i_id_pn_note_type         Note type Id
    * @param       i_id_pn_data_block        Data block Id
    * @param       i_id_pn_soap_block        Soap block Id
    * @param       o_actions                 list of actions
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 19-Mar-2012
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_id_task_type          IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_flg_review            IN VARCHAR2,
        i_flg_remove            IN VARCHAR2,
        i_flg_review_all        IN pn_note_type_mkt.flg_review_all%TYPE,
        i_flg_table_origin      IN epis_pn_det_task.flg_table_origin%TYPE,
        i_flg_actions_available IN pn_dblock_mkt.flg_actions_available%TYPE,
        i_flg_editable          IN VARCHAR2,
        i_flg_dblock_editable   IN pn_dblock_mkt.flg_editable%TYPE,
        i_id_pn_note_type       IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_data_block      IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block      IN pn_soap_block.id_pn_soap_block%TYPE,
        o_actions               OUT NOCOPY pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the review context of a task type
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_task_type            Type of the task
    * @param       o_review_context          Task type review context
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 12-Abr-2012
    ********************************************************************************************/
    FUNCTION get_task_review_context
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_task_type   IN epis_pn_det_task.id_task_type%TYPE,
        o_review_context OUT NOCOPY tl_task.review_context%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if it is a task with review
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_task_type            Type of the task
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 17-Dec-2012
    ********************************************************************************************/
    FUNCTION check_is_task_with_review
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN epis_pn_det_task.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the configs associated to the area.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_area                    Area internal name
    * @param       o_area_configs            Area configs
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 12-Abr-2012
    ********************************************************************************************/
    FUNCTION get_area_configs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_area         IN pn_area.internal_name%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        o_area_configs OUT NOCOPY pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the name of the note type.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_area                    Area internal name
    * @param       o_desc                    Description of the note type
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 12-Abr-2012
    ********************************************************************************************/
    FUNCTION get_note_type_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_desc            OUT NOCOPY VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the date of the last note of the given note type to the given episode.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_pn_note_type         Note type ID
    * @param       i_id_epis_pn              epis_pn ID
    * @param       o_note_date               Date of the last note
    * @param       o_id_epis_pn              Note Id
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 23-Abr-2012
    ********************************************************************************************/
    FUNCTION get_last_note_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        io_id_epis_pn     IN OUT NOCOPY epis_pn.id_epis_pn%TYPE,
        o_note_date       OUT NOCOPY epis_pn.dt_pn_date%TYPE,
        o_pn_date         OUT NOCOPY epis_pn.dt_pn_date%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the date of the last note of the given note type to the given episode.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_flg_status_available    Y-The status should be available. N-otherwise
    * @param       i_flg_status              Note status
    *
    * @return      varchar2                   Y-The status should be shown. N-otherwise
    *
    * @author                                Sofia Mendes
    * @since                                 23-Abr-2012
    ********************************************************************************************/
    FUNCTION check_has_status
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_flg_status_available IN pn_note_type_mkt.flg_status_available%TYPE,
        i_flg_status           IN epis_pn.flg_status%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if a task has some active action or not.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_flg_import              B-import in block. N-otherwise
    * @param       i_id_pn_note_type         Note type ID
    * @param       i_flg_dblock_type         Data block flg_type
    *
    * @return      varchar2                   Y-There is some action available over the task. N-otherwise
    *
    * @author                                Sofia Mendes
    * @since                                 23-Abr-2012
    ********************************************************************************************/
    FUNCTION get_flg_no_action
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_editable    IN VARCHAR2,
        i_flg_dblock_type IN pn_data_block.flg_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if the given note (i_id_epis_pn) is the most recente note create in the note area.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_epis_pn              Epis pn ID
    *
    * @return      varchar2                   Y-The given note is the most recent one of that area. N-otherwise
    *
    * @author                                Sofia Mendes
    * @since                                 30-Abr-2012
    ********************************************************************************************/
    FUNCTION check_more_recent_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Check if it is possible to edit the note.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_epis_pn              Epis pn ID
    * @param       i_editable_nr_min         Nr of minutes that the professional has to edit the note since its creation.
    * @param       i_flg_synchronized        Y-Single page. N-single note
    * @param       i_id_pn_note_type         Note type ID
    *
    * @return      varchar2                   1-editable. 0-not editable
    *
    * @author                                Sofia Mendes
    * @since                                 30-Abr-2012
    ********************************************************************************************/
    FUNCTION check_time_to_edit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        i_editable_nr_min  IN pn_note_type_mkt.editable_nr_min%TYPE,
        i_flg_synchronized IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE
    ) RETURN PLS_INTEGER;

    /********************************************************************************************
    * Checks if the note is editable.
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_episode            Episode ID
    * @param i_id_epis_pn            Note ID
    * @param i_editable_nr_min       Nr of minutes to edit a note
    * @param i_flg_edit_after_disch  Y-It is allowed to edit the note after the discharge. N-otherwise
    * @param i_flg_synchronized      Y-Single page. N-single note
    * @param i_id_pn_note_type       Note type ID
    * @param i_flg_edit_only_last    Y-only the last active note is editable. N-otherwise
    *
    * @return                        Y-It is allowed to edit the note. N-It is not allowed to edit.
    *                                T-It is not allowed to edit except the free text records.
    *
    * @author                        Sofia Mendes
    * @since                         16-May-2012
    * @version                       2.6.2.1
    ********************************************************************************************/
    FUNCTION get_flg_editable
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_pn           IN epis_pn.id_epis_pn%TYPE,
        i_editable_nr_min      IN pn_note_type_mkt.editable_nr_min%TYPE,
        i_flg_edit_after_disch IN pn_note_type_mkt.flg_edit_after_disch%TYPE,
        i_flg_synchronized     IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_id_pn_note_type      IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_edit_only_last   IN pn_note_type_mkt.flg_edit_only_last%TYPE,
        i_flg_edit_condition   IN pn_note_type_mkt.flg_edit_condition%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get Dep_clin_ser from note or episode.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_epis_pn              Note id
    * @param       o_id_dep_clin_serv        Dep_clin_serv ID
    * @param       o_error                   Error info
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 30-Abr-2012
    ********************************************************************************************/
    FUNCTION get_dep_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        o_id_dep_clin_serv OUT epis_pn.id_dep_clin_serv%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if it is necessary to auto-populate or syncronize the note.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_epis_pn              Epis pn ID
    * @param       i_editable_nr_min         Nr of minutes that the professional has to edit the note since its creation.
    * @param       i_flg_synchronized        Y-Single page. N-single note
    * @param       i_id_pn_note_type         Note type ID
    * @param       i_id_epis_pn_det_task     Epis_pn_det_task ids list
    * @param       o_error                   Error info
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 29-May-2012
    ********************************************************************************************/
    FUNCTION check_synchronization_needed
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_pn           IN epis_pn.id_epis_pn%TYPE,
        i_editable_nr_min      IN pn_note_type_mkt.editable_nr_min%TYPE,
        i_flg_synchronized     IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_id_pn_note_type      IN pn_note_type.id_pn_note_type%TYPE,
        i_id_epis_pn_det_task  IN table_number,
        i_flg_sync_after_disch IN pn_note_type_mkt.flg_sync_after_disch%TYPE DEFAULT pk_alert_constant.g_no,
        o_flg_synch            OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the auto-population type.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_epis_pn              Epis pn ID
    * @param       i_flg_synchronized        Y-Single page. N-single note
    * @param       i_id_epis_pn_det_task     Epis_pn_det_task IDs list
    * @param       i_flg_search_dblock       Types of Data Blocks to search on records
    *
    * @return      varchar2                   R-synchronizing only a record
                                              A-auto-population
                                              C-synchonize all records in the note
    *
    * @author                                Sofia Mendes
    * @since                                 29-May-2012
    ********************************************************************************************/
    FUNCTION get_autopop_type_flg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_flg_synchronized    IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_id_epis_pn_det_task IN table_number,
        i_flg_search_dblock   IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Get the list of tasks and data blocks that should be imported
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_pn_group        Group Id
    * @param   o_id_task_types      Task types associated to the given group
    * @param   o_error              Error information
    *
    * @return  Boolean        True: Sucess, False: Fail
    *
    * @author Sofia Mendes
    * @version 2.6.2
    * @since   01-Jun-2012
    */
    FUNCTION get_task_types_from_group
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pn_group   IN pn_group.id_pn_group%TYPE,
        o_id_task_types OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the id_epis_pn_det_task that corresponds to the given id_task and id_task_type
    * considering the given data strucutre
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_tbl_tasks          Tasks info structure
    * @param   i_id_task_type       Task type id to look for
    * @param   i_id_epis_pn_det     Task type id to look for
    * @param   i_flg_task_parent    Y-id_epis_pn_det_task. N-id_Task
    * @param   o_id_task            Task id
    * @param   o_id_epis_pn_det_task Epis_pn_det_task
    *
    * @return  Boolean        True: Sucess, False: Fail
    *
    * @author Sofia Mendes
    * @version 2.6.2
    * @since   01-Jun-2012
    */
    FUNCTION get_ids_from_struct
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_tbl_tasks           IN pk_prog_notes_types.t_table_tasks,
        i_id_task_type        IN epis_pn_det_task.id_task_type%TYPE,
        i_id_epis_pn_det      IN epis_pn_det.id_epis_pn_det%TYPE,
        i_flg_task_parent     IN VARCHAR2,
        i_id_task_parent      IN epis_pn_det_task.id_epis_pn_det_task%TYPE,
        o_id_task             OUT epis_pn_det_task.id_task%TYPE,
        o_id_epis_pn_det_task OUT epis_pn_det_task.id_epis_pn_det_task%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get task set id to be used as the group of tasks to get the descriptions.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_task_type           Task type ID
    *
    * @value id_task_set            Task set id
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          2011/02/18
    **************************************************************************/
    FUNCTION get_task_set_to_group_descs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN task_timeline_ea.id_tl_task%TYPE
    ) RETURN PLS_INTEGER;

    /**************************************************************************
    * Aggregate the groups of tasks, to use to calculate the descritions in a group
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_task_type           Task type ID
    * @param i_id_task                Task reference ID
    * @param i_id_task_notes          Task associated to the notes field (epis_documentation for procedures
    *                                 executions tasks)
    * @param io_tasks_groups_by_type  Tasks by type structure
    * @param o_grouped_task           Y-Task which description is calculated in group. N-otherwise
    * @param o_error                  Error
    *
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          2011/02/18
    **************************************************************************/
    FUNCTION get_task_groups_by_type
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_task_type          IN task_timeline_ea.id_tl_task%TYPE,
        i_id_task               IN task_timeline_ea.id_task_refid%TYPE,
        i_id_task_notes         IN task_timeline_ea.id_task_notes%TYPE,
        io_tasks_groups_by_type IN OUT NOCOPY pk_prog_notes_types.t_tasks_groups_by_type,
        o_grouped_task          OUT NOCOPY VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the software descrition of the sw associated to the given episode
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE            Episode identifier
    * @param I_DATE                  Last update note date
    *
    * @return                        SW description
    *
    * @author                        Sofia Mendes
    * @since                         13-Jul-2012
    * @version                       2.6.2
    ********************************************************************************************/
    FUNCTION get_epis_sw_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the software descrition (abbreviation) of the sw associated to the given episode
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE            Episode identifier
    * @param I_DATE                  Last update note date
    *
    * @return                        SW description
    *
    * @author                        Sofia Mendes
    * @since                         13-Jul-2012
    * @version                       2.6.2
    ********************************************************************************************/
    FUNCTION get_epis_sw_abbr
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_software software.id_software%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the date description that appears on the notes viewer
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE            Episode identifier
    * @param I_DATE                  Last update note date
    *
    * @return                        Area description
    *
    * @author                        Sofia Mendes
    * @since                         13-Jul-2012
    * @version                       2.6.2
    ********************************************************************************************/
    FUNCTION get_viewer_date_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_date        IN epis_pn.dt_create%TYPE,
        i_id_software software.id_software%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the note date to be considered on viewer. single page: last update date. Single note: note date
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param i_flg_synchronized      Y-Single page; N-Single note
    * @param i_dt_pn_date            Note date
    * @param i_dt_signoff            Signoff date
    * @param i_dt_last_update        Last update date
    * @param i_dt_create
    *
    * @return                        DAte description
    *
    * @author                        Sofia Mendes
    * @since                         17-Jul-2012
    * @version                       2.6.2
    ********************************************************************************************/
    FUNCTION get_note_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_synchronized IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_dt_pn_date       IN epis_pn.dt_pn_date%TYPE,
        i_dt_signoff       IN epis_pn.dt_signoff%TYPE,
        i_dt_last_update   IN epis_pn.dt_last_update%TYPE,
        i_dt_create        IN epis_pn.dt_create%TYPE
    ) RETURN epis_pn.dt_create%TYPE;

    /**
    * Returns the concatenated text of all tasks associated to an epis_pn_det.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_epis_pn_det         PN Detail ID
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise
    *
    * @return                         Clob with the soap block concatenated texts
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since               08-Feb-2011
    */
    FUNCTION get_tasks_concat
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn_det IN epis_pn_det.id_epis_pn_det%TYPE,
        i_flg_detail     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB;

    /**************************************************************************
    * Get the data block configs record
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_dblocks                Data blocks configs
    * @param i_id_pn_data_block       Data block id
    * @param i_id_pn_soap_block       Soap block id
    * @param o_rec_dblock             Data block cfgs record
    *                                 be aggregated in one free text
    * @param o_error                  Error
    *
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          2011/02/18
    **************************************************************************/
    FUNCTION get_dblock_cfgs_rec
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_dblocks          IN t_coll_dblock,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        o_rec_dblock       OUT NOCOPY t_rec_dblock,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get the task type configs record
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_coll_dblock_task_type  Task types configs
    * @param i_id_pn_data_block       Data block id
    * @param i_id_pn_soap_block       Soap block id
    * @param i_id_task_type           Task type ID
    * @param o_rec_dblock             Data block cfgs record
    *                                 be aggregated in one free text
    * @param o_error                  Error
    *
    *
    * @author                         Sofia Mendes
    * @version                        2.6.2
    * @since                          15-Oct-2012
    **************************************************************************/
    FUNCTION get_task_type_cfgs_rec
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_coll_dblock_task_type IN t_coll_dblock_task_type,
        i_id_pn_data_block      IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block      IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_task_type          IN tl_task.id_tl_task%TYPE,
        o_rec_dblock_task_type  OUT NOCOPY t_rec_dblock_task_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get the data used to aggregate the data.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_task_type           Task type ID
    * @param i_id_task                Task ID
    * @param i_id_task_aggregator     Aggregator Id to be used in case of recurrence records
    * @param i_id_patient             Patient Id
    * @param   o_dt_group_import    Aggregation info: Date: 1st aggregation level
    * @param   o_id_group_import    Aggregation info: Group: 2nd aggregation level
    * @param   o_code_desc_group    Aggregation info: Group desc
    * @param   o_id_sub_group_import Aggregation info: Sub-Group: 3rd aggregation level
    * @param   o_code_desc_sub_group Aggregation info: Sub-Group desc
    * @param   o_id_sample_type      Sample type id. Only used for analysis results to join to the sub group desc
    * @param   o_code_desc_sample_type Sample type code desc. Only used for analysis results to join to the sub group desc
    * @param   o_id_prof_task          Professional that performed the task
    * @param o_error                  Error
    *
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          2011/02/18
    **************************************************************************/
    FUNCTION get_aggregation_data_from_ea
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_task_type          IN task_timeline_ea.id_tl_task%TYPE,
        i_id_task               IN task_timeline_ea.id_task_refid%TYPE,
        i_id_task_aggregator    IN task_timeline_ea.id_task_aggregator%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_flg_group_type         IN VARCHAR2 DEFAULT NULL,
        i_dt_task                IN VARCHAR2,
        o_dt_group_import       OUT NOCOPY epis_pn_det_task.dt_group_import%TYPE,
        o_id_group_import       OUT NOCOPY epis_pn_det_task.id_group_import%TYPE,
        o_code_desc_group       OUT NOCOPY epis_pn_det_task.code_desc_group%TYPE,
        o_desc_group            OUT NOCOPY VARCHAR2,
        o_id_sub_group_import   OUT NOCOPY epis_pn_det_task.id_sub_group_import%TYPE,
        o_code_desc_sub_group   OUT NOCOPY epis_pn_det_task.code_desc_sub_group%TYPE,
        o_id_sample_type        OUT NOCOPY epis_pn_det_task.id_sample_type%TYPE,
        o_code_desc_sample_type OUT NOCOPY epis_pn_det_task.code_desc_sample_type%TYPE,
        o_id_prof_task          OUT NOCOPY epis_pn_det_task.id_prof_task%TYPE,
        o_code_desc_group_parent OUT NOCOPY epis_pn_det_task.code_desc_group_parent%TYPE,
        o_instructions_hash      OUT NOCOPY epis_pn_det_task.instructions_hash%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get the vital signs group description to be used in the second level of text aggregation
    * (Hour)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_date                   Record date
    * @param o_desc_group             Hour group desc
    * @param o_error                  Error
    *
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          2011/02/18
    **************************************************************************/
    FUNCTION get_hour_desc_group
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Get the vital signs group ID to the hour level of aggregation.
    * Transforms the hour in a number to be used as the group id.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_date                   Record date
    * @param o_error                  Error
    *
    * @return hour group id
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          2011/02/18
    **************************************************************************/
    FUNCTION get_hour_group_id
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

    /**************************************************************************
    * Get the title to the 1st level of aggregation by date.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_task_type           Task type ID
    * @param i_dt_group_import        Aggregation info: Date: 1st aggregation level
    * @param o_date_title             Aggregation info: Date desc desc
    * @param o_error                  Error
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          2011/02/18
    **************************************************************************/
    FUNCTION get_date_aggr_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_type    IN task_timeline_ea.id_tl_task%TYPE,
        i_dt_group_import IN epis_pn_det_task.dt_group_import%TYPE,
        o_date_title      OUT NOCOPY VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get the description of the 2nd level of aggregation
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_task_type           Task type ID
    * @param i_dt_group_import    Aggregation info: Date: 1st aggregation level
    * @param i_code_desc_group    Aggregation info: Group desc
    *
    * @return         Aggregation info: 2nd level desc
    *
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          2011/02/18
    **************************************************************************/
    FUNCTION get_group_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_type    IN task_timeline_ea.id_tl_task%TYPE,
        i_dt_group_import IN epis_pn_det_task.dt_group_import%TYPE,
        i_code_desc_group        IN epis_pn_det_task.code_desc_group%TYPE,
        i_code_desc_group_parent IN epis_pn_det_task.code_desc_group_parent%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Get the description of the 3rd level of aggregation
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_code_desc_sub_group    Aggregation info: Sub Group desc code translation
    * @param i_code_desc_sample_type  Sample type code desc. Only used for analysis results to join to the sub group desc
    *
    * @return         Aggregation info: 2nd level desc
    *
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          2011/02/18
    **************************************************************************/
    FUNCTION get_sub_group_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_code_desc_sub_group   IN epis_pn_det_task.code_desc_sub_group%TYPE,
        i_code_desc_sample_type IN epis_pn_det_task.code_desc_sample_type%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Separator to separate the different record values in the text aggregations.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_task_type           Task type ID
    * @param i_id_sub_group_import    Sub group id: indicates if the 3rd aggregation level exists
    * @param o_separator              Aggregation info: separator
    * @param o_error                  Error
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          2011/02/18
    **************************************************************************/
    FUNCTION get_txt_aggr_separator
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_task_type        IN task_timeline_ea.id_tl_task%TYPE,
        i_prev_task           IN epis_pn_det_task.pn_note%TYPE,
        i_id_sub_group_import IN epis_pn_det_task.id_sub_group_import%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Get the title to the 1st level of aggregation by date.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_task_type           Task type ID
    * @param o_flg_ea                 Y- Task date comes from EA; N- Task data comes from API
    * @param o_error                  Error
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          19-Sep-2012
    **************************************************************************/
    FUNCTION get_task_flg_ea
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN task_timeline_ea.id_tl_task%TYPE,
        o_flg_ea       OUT NOCOPY tl_task.flg_ea%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the last note to the given area acoording to the given statuses.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_scope                   Scope ID (Patient ID, Visit ID)
    * @param       i_scope_type              Scope type (by patient {P}, by visit {V})
    * @param       i_id_pn_area              PN area ID
    * @param       i_note_status             Notes statuses
    * @param       o_id_epis_pn              Note ID
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 23-Abr-2012
    ********************************************************************************************/
    FUNCTION get_last_note_by_area
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_scope       IN NUMBER,
        i_scope_type  IN VARCHAR2,
        i_id_pn_area  IN pn_area.id_pn_area%TYPE,
        i_note_status IN table_varchar,
        o_id_epis_pn  OUT NOCOPY epis_pn.id_epis_pn%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Calculated if the record was modified in the current data syncronization.
    * In the SPSummary it is always saved permanently in the synch, so it is not
    * needed to mark as modified
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_pn_note                Task text
    * @param i_dt_pn                  Det date
    * @param i_dt_last_update_task    Task last update date in the note
    * @param i_dt_last_update         Last update of the note (update in the current synch)
    * @param i_flg_syncronized        Y-SPSummary; N-SPNote
    * @param o_error                  Error
    *
    * @author                         Sofia Mendes
    * @version                        2.6.2
    * @since                          27-Sep-2012
    **************************************************************************/
    FUNCTION get_flg_modified
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pn_note             IN epis_pn_det_task.pn_note%TYPE,
        i_dt_pn               IN epis_pn_det.dt_pn%TYPE,
        i_dt_last_update_task IN epis_pn_det_task.dt_last_update%TYPE,
        i_dt_last_update      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_syncronized     IN pn_note_type_mkt.flg_synchronized%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the dynamic note type configs. FLG_import_available and flg_editable
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_episode            Episode ID
    * @param i_id_epis_pn            Note id
    * @param i_id_pn_note_type       Note type ID
    * @param i_flg_import_available  Configuration regarding import availability
    * @param i_editable_nr_min       Nr of min to edit the note (if aplicable)
    * @param i_flg_edit_after_disch  Y-Editable after discharge. N-Otherwise
    * @param i_flg_synchronized      Y- SPSummary; N-SPNote
    * @param i_flg_edit_only_last    Y-only the last active note is editable. N-otherwise
    * @param o_flg_editable          Y-It is allowed to edit the note. N-It is not allowed to edit.
    *                                T-It is not allowed to edit except the free text records.
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Sofia Mendes
    * @since                         02-Oct-2012
    * @version                       2.6.2
    ********************************************************************************************/
    FUNCTION get_dynamic_note_type_cfgs
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_pn           IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type      IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_import_available IN pn_note_type_mkt.flg_import_available%TYPE,
        i_editable_nr_min      IN pn_note_type_mkt.editable_nr_min%TYPE,
        i_flg_edit_after_disch IN pn_note_type_mkt.flg_edit_after_disch%TYPE,
        i_flg_synchronized     IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_flg_edit_only_last   IN pn_note_type_mkt.flg_edit_only_last%TYPE,
        o_flg_editable         OUT NOCOPY VARCHAR2,
        o_configs              OUT NOCOPY pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Gets the tasks descriptions by group of tasks.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_tasks_descs_by_type    Task descriptions struct
    * @param i_id_task_type           Task type ID
    * @param i_id_task                Task id
    * @param i_id_task_notes          Task associated to the template notes.
    * @param i_flg_show_sub_title     Y-the sub title should be visible. N-otherwise
    * @param o_error                  Error
    *
    * @value i_flg_has_notes          {*} 'Y'- Has comments {*} 'N'- otherwise
    *
    * @author                         Sofia Mendes
    * @version                        2.6.2
    * @since                          2011/02/18
    **************************************************************************/
    FUNCTION get_import_group_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_tasks_descs_by_type IN pk_prog_notes_types.t_tasks_descs_by_type,
        i_id_task_type        IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task             IN epis_pn_det_task.id_task%TYPE,
        i_id_task_notes       IN task_timeline_ea.id_task_notes%TYPE,
        i_flg_show_sub_title  IN pn_dblock_mkt.flg_show_sub_title%TYPE,
        io_desc               IN OUT NOCOPY CLOB,
        io_desc_long          IN OUT NOCOPY CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Check if the task should stay selected in the import screen when the user selects all
    * the group of tasks, according to the configuration by status.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_flg_task_stauts         Task status
    * @param i_flg_group_select_filter Config that status should appear selected in group selection
    *
    * @return varchar2                 {*} 'Y'- Task selected {*} 'N'- Task unselected
    *
    * @author                         Sofia Mendes
    * @version                        2.6.2
    * @since                          04-Oct-2012
    **************************************************************************/
    FUNCTION get_flg_select_by_status
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_flg_task_stauts         IN task_timeline_ea.flg_ongoing%TYPE,
        i_flg_group_select_filter IN pn_dblock_mkt.flg_group_select_filter%TYPE
    ) RETURN VARCHAR2;

    /**
    * checks if the record should be auto-suggested to the user or it should be saved in the note.
    *
    * @param i_current_episode             Current episode ID
    * @param i_imported_episode            Episode in which was created the imported task
    * @param i_flg_review                  Y - the review is available on page/note. N-otherwise
    * @param i_flg_review_avail            Y - the review is available for the current task type. N-otherwise
    * @param i_flg_auto_populated          Y-The data block is filled automatically with the existing info. N-otherwise
    * @param i_flg_reviewed_epis           Y -The task had already been reviewed in the current episode
    * @param i_review_context              Context of revision. If it is filled the task requires revision.
    * @param i_id_task_type                Task type Id
    * @param i_flg_new                     Y-new record; N-record already in the page/note
    * @param i_flg_import                  T-import in text; B-import in block
    * @param i_flg_synch_db                Y-Synchronizable area. N-othwerwise
    * @param i_flg_suggest_concept         Concept to determine the suggested records.
    * @param i_flg_editable                Y-Editable record; N-otherwise
    * @param i_flg_status                  Record flg status
    *
    * @return                 Y-The record must be auto-suggested to the user. N-otherwise
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                28-02-2012
    */
    FUNCTION get_auto_suggested_flg
    (
        i_current_episode     IN episode.id_episode%TYPE,
        i_imported_episode    IN episode.id_episode%TYPE,
        i_flg_review          IN pn_note_type_mkt.flg_review_all%TYPE,
        i_flg_review_avail    IN pn_dblock_ttp_mkt.flg_review_avail%TYPE,
        i_flg_auto_populated  IN pn_dblock_ttp_mkt.flg_auto_populated%TYPE,
        i_flg_reviewed_epis   IN VARCHAR2,
        i_review_context      IN tl_task.review_context%TYPE,
        i_id_task_type        IN tl_task.id_tl_task%TYPE,
        i_flg_new             IN VARCHAR2,
        i_flg_import          IN pn_dblock_mkt.flg_import%TYPE,
        i_flg_synch_db        IN pn_dblock_ttp_mkt.flg_synchronized%TYPE,
        i_flg_suggest_concept IN pn_note_type_mkt.flg_suggest_concept%TYPE,
        i_flg_editable        IN pn_dblock_mkt.flg_editable%TYPE,
        i_flg_status          IN epis_pn_det_task.flg_status%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Indicates if should be shown the signature in the current record.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_flg_suggested          Y-suggested record. N-definitive record
    * @param i_id_prof_reg            Professional id that registered the record
    * @param i_flg_import_date        Y-should be shown the signature config. N-otherwise
    * @param i_dblock_data_area       Data block area
    * @param i_flg_import             B-block importable. T -text importable
    * @param i_flg_signature          Y-show signature if applicable. N-No show signature
    *
    * @return varchar2                 {*} 'Y'- Record with signature {*} 'N'- Otherwise
    *
    * @author                         Sofia Mendes
    * @version                        2.6.2
    * @since                          23-Oct-2012
    **************************************************************************/
    FUNCTION get_flg_show_signature
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_suggested    IN VARCHAR2,
        i_id_prof_reg      IN professional.id_professional%TYPE,
        i_flg_import_date  IN pn_dblock_mkt.flg_import_date%TYPE,
        i_dblock_data_area IN pn_data_block.data_area%TYPE,
        i_flg_import       IN pn_dblock_mkt.flg_import%TYPE,
        i_flg_signature    IN pn_dblock_mkt.flg_signature%TYPE DEFAULT 'Y'
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Append the elements of one t_table_tasks table to another.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_table_to_append          Table to be appended
    * @param io_total_table             Table with all the appended values
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.2.3
    * @since                           13-Nov-2012
    **********************************************************************************************/
    FUNCTION append_tables_tasks
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_table_to_append IN pk_prog_notes_types.t_table_tasks,
        io_total_table    IN OUT pk_prog_notes_types.t_table_tasks,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get the professional and date of review used to aggregate the data.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_task_type           Task type ID
    * @param i_id_task                Task ID
    * @param   i_id_prof_review     Professional that performed the last review of the record
    * @param   i_dt_review          Date in which was performed the last review of the record
    * @param o_error                  Error
    *
    *
    * @author                         Sofia Mendes
    * @version                        2.6.2.3
    * @since                          13-Nov-2012
    **************************************************************************/
    FUNCTION get_review_data_from_ea
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_task_type   IN task_timeline_ea.id_tl_task%TYPE,
        i_id_task        IN task_timeline_ea.id_task_refid%TYPE,
        o_id_prof_review OUT NOCOPY task_timeline_ea.id_prof_review%TYPE,
        o_dt_review      OUT NOCOPY task_timeline_ea.dt_review%TYPE,
        o_dt_last_update OUT NOCOPY task_timeline_ea.dt_last_update%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Calculates the signature to be shown in the creation/edition screen for each record.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_prof_last_upd       Last update professional
    * @param i_dt_last_upd            Last update date
    * @param i_id_prof_review         Professional that performed the last review of the record
    * @param i_dt_review              Date in which was performed the last review of the record
    * @param i_flg_show_signature     Y-the signature should be shown. N-otherwise
    *
    * @return varchar2                 signature text
    *
    * @author                         Sofia Mendes
    * @version                        2.6.2.3
    * @since                          14-Nov-2012
    **************************************************************************/
    FUNCTION get_signature
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_prof_last_upd   IN professional.id_professional%TYPE,
        i_dt_last_upd        IN epis_pn.dt_last_update%TYPE,
        i_id_prof_review     IN professional.id_professional%TYPE,
        i_dt_review          IN epis_pn.dt_last_update%TYPE,
        i_flg_show_signature IN VARCHAR2,
        i_id_pn_task_type    IN epis_pn_det_task.id_task_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Indicates if the current task type should be synchronized with the original area
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_task_type           Task type ID
    *
    * @return                         Y - If the task is to be synchronized immediately with the directed area
    *                                 when is changed in the note. N- otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.3.2
    * @since               23-Jan-2012
    */
    FUNCTION get_flg_synch_area
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN tl_task.id_tl_task%TYPE
    ) RETURN tl_task.flg_synch_area%TYPE;
    /**
    * get_ds_id_prof_signoff
    *
    * @param i_id_episode             episode ID
    *
    * @return                         id_prof_signoff
    *
    * @author               Paulo Teixeira
    * @version               2.6.3.2
    * @since               5-Fev-2012
    */
    FUNCTION get_ds_id_prof_signoff(i_id_episode IN epis_pn.id_episode%TYPE) RETURN epis_pn.id_prof_signoff%TYPE;
    /**
    * get_single_page_indicators
    *
    * @param i_id_episode             episode ID
    * @param i_id_pn_area             pn_area ID
    * @param i_flg_status             flg_status
    *
    * @return                         Y/N
    *
    * @author               Paulo Teixeira
    * @version               2.6.3.2
    * @since               5-Fev-2012
    */
    FUNCTION get_single_page_indicators
    (
        i_id_episode IN epis_pn.id_episode%TYPE,
        i_id_pn_area epis_pn.id_pn_area%TYPE,
        i_flg_status epis_pn.flg_status%TYPE
    ) RETURN VARCHAR2;
    /**
    * get_ds_dt_signoff
    *
    * @param i_id_episode             episode ID
    *
    * @return                         id_prof_signoff
    *
    * @author               Paulo Teixeira
    * @version               2.6.3.2
    * @since               5-Fev-2012
    */
    FUNCTION get_ds_dt_signoff(i_id_episode IN epis_pn.id_episode%TYPE) RETURN epis_pn.dt_signoff%TYPE;

    /*
    * Function to highlight the searched text
    *
    * @param i_text             Full text to be searched
    * @param i_search           Text to search
    *
    * @return                   Returns the searched text highlighted (bold and italic)
    *
    * @author                   Vanessa Barsottelli
    * @version                  2.6.3
    * @since                    15-Jan-2014
    */
    FUNCTION highlight_searched_text
    (
        i_text   IN CLOB,
        i_search IN VARCHAR2
    ) RETURN CLOB;

    FUNCTION get_pn_episode
    (
        i_table_name user_tables.table_name%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN episode.id_episode%TYPE;

    FUNCTION get_pn_patient
    (
        i_table_name user_tables.table_name%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN patient.id_patient%TYPE;

    /*
    * Function to check if epis_pn exists (if the note was saved)
    *
    * @param i_id_epis_pn       id_epis_pn to search for
    *
    * @return                   Returns 'Y' if exists 'N' if not
    *
    * @author                   Nuno Alves
    * @version                  2.6.4.3
    * @since                    13-Jan-2015
    */
    FUNCTION check_epis_pn(i_id_epis_pn IN epis_pn.id_epis_pn%TYPE) RETURN CHAR;

    /**
    * Returns the actions to be displayed in the 'ACTIONS' button from prof grids
    *
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_actions      actions data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Vanessa Barsottelli
    * @version              2.6.5
    * @since                26-04-2016
    */
    FUNCTION get_prof_grid_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_actions OUT NOCOPY pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the info (labels & sample text) to prof grid popup
    *
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_note_type    note type ID
    * @param o_info         labels for popup
    * @paramo_sample_text   sample text
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Vanessa Barsottelli
    * @version              2.6.5
    * @since                27-04-2016
    */
    FUNCTION get_note_grid_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_note_type   IN pn_note_type.id_pn_note_type%TYPE,
        o_info        OUT pk_types.cursor_type,
        o_data_blocks OUT pk_types.cursor_type,
        o_sample_text OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * check_note_type_free_text
    *
    * @param i_prof                logged professional structure
    * @param i_market              market identifier
    * @param i_department          service identifier
    * @param i_dcs                 service/specialty identifier
    * @param i_id_pn_note_type     Note type identifier
    * @param i_id_episode          Episode identifier
    * @param i_id_pn_data_block    Data Block Identifier
    * @param i_software            Software ID
    *
    * @return                      configured soap and data blocks ordered collection
    *
    * @author                      Pedro Carneiro
    * @version                     2.6.0.5.2
    * @since                       2011/01/27
    */
    FUNCTION check_note_type_free_text
    (
        i_prof             IN profissional,
        i_market           IN market.id_market%TYPE,
        i_department       IN department.id_department%TYPE,
        i_dcs              IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_software         IN software.id_software%TYPE
    ) RETURN VARCHAR2;
    --
    FUNCTION get_bl_epis_documentation_ids(i_pn_note epis_pn_det.pn_note%TYPE) RETURN table_number;
    FUNCTION get_bl_epis_documentation_clob
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pn_note epis_pn_det.pn_note%TYPE
    ) RETURN CLOB;
    -- Public variable declarations
    g_exception EXCEPTION;

    FUNCTION has_soap_mandatory_block
    (
        i_prof            IN profissional,
        i_soap_block      IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_market          IN market.id_market%TYPE,
        i_department      IN department.id_department%TYPE,
        i_dcs             IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_software        IN software.id_software%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_doc_status_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_signature
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_prof_create      IN professional.id_professional%TYPE,
        i_dt_create           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_update IN professional.id_professional%TYPE,
        i_dt_last_update      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_sign_off    IN professional.id_professional%TYPE,
        i_dt_sign_off         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_cancel      IN professional.id_professional%TYPE,
        i_dt_cancel           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_reviewed    IN professional.id_professional%TYPE,
        i_dt_reviewed         IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

    -- ************************************************
    -- If returns N, no button SUBMIT.
    -- if returns R, professional is NOT attending phys of current episode. button SUBMIT ON
    -- if returns S, professional IS attending phys of current episode. button SUBMIT ON
    -- ************************************************
    FUNCTION is_prof_attending_phy
    (
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_dblock_sblock
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_dblocks          IN t_coll_dblock,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN NUMBER;

    FUNCTION get_number_imported_blocks(i_id_epis_pn IN epis_pn.id_epis_pn%TYPE) RETURN NUMBER;

    /**************************************************************************
    **************************************************************************/
    FUNCTION check_iss_diag_validation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_msg_type   OUT VARCHAR2,
        o_error      OUT t_error_out
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
    FUNCTION get_days_in_current_week
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_calendar_date_control IN VARCHAR2 DEFAULT NULL,
        i_current_date          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_calendar_period       OUT VARCHAR,
        o_begin_date            OUT VARCHAR2,
        o_end_date              OUT VARCHAR2,
        o_current_date_num      OUT NUMBER,
        o_calendar_dates        OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the days  between the given two notes to the given note type and episode.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_pn_note_type         Note type ID
    * @param       o_start_date              last note date
    * @param       o_end_date                current note date
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Lillian Lu
    * @since                                 2017/12/10
    ********************************************************************************************/
    FUNCTION get_days_between_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_start_date      OUT epis_pn.dt_create%TYPE,
        o_end_date        OUT epis_pn.dt_create%TYPE,
        o_error           OUT t_error_out
    ) RETURN NUMBER;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_area                   pn_area internal name
    *
    * @param o_def_viewer_parameter   cursor with the information for timeline
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-27
    **************************************************************************/
    FUNCTION get_calendar_def_viewer
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_area                 IN VARCHAR2,
        o_def_viewer_parameter OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get notes proposed date
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_epis_pn             Epis_pn ID
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2018-01-04
    **************************************************************************/
    FUNCTION get_note_dt_proposed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN epis_pn.dt_proposed%TYPE;

    /********************************************************************************************
    * Get the last note to the given note type acoording to the given statuses.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_scope                   Scope ID (Patient ID, Visit ID)
    * @param       i_scope_type              Scope type (by patient {P}, by visit {V})
    * @param       i_id_pn_note_type         PN note type ID
    * @param       i_note_status             Notes statuses
    * @param       o_id_epis_pn              Note ID
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Amanda Lee
    * @since                                 2018-01-08
    ********************************************************************************************/
    FUNCTION get_last_note_by_note_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_note_status     IN table_varchar,
        o_id_epis_pn      OUT NOCOPY epis_pn.id_epis_pn%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get delay time, input i_pn_note_type to get delay time of each pn_note_type
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_pn_note_type           pn_note_type ID
    * @param i_is_in_icu              is this pn_note_type for icu
    *
    * @author                         Kelsey Lai
    * @version                        2.7.2
    * @since                          2017-12-18
    **************************************************************************/
    FUNCTION get_delay_time_by_note
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_is_in_icu    IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    /**************************************************************************
    * get time-to-close of note
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_episode                Episode ID
    * @param i_epis_pn                epis_pn ID
    *
    * @author                         Kelsey Lai
    * @version                        2.7.2
    * @since                          2017-12-18
    **************************************************************************/
    FUNCTION gen_time_to_close
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_pn_note_type IN pn_note_type.id_pn_note_type%TYPE
    ) RETURN INTERVAL DAY TO SECOND;

    /**************************************************************************
    * get this note should be finish time
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_episode                Episode ID
    * @param i_epis_pn                epis_pn ID
    *
    * @author                         Kelsey Lai
    * @version                        2.7.2
    * @since                          2017-12-18
    **************************************************************************/
    FUNCTION get_end_task_time
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /**************************************************************************
     * Returns the blocks related in the note (Used for autopopulate this block)
     *
     * @param i_lang         language identifier
     * @param i_prof         logged professional structure
     * @param i_id_sblock    List of soap block
     * @param i_configs_ctx  Type with all note configurations
     * @param io_sblocks     List os soap blocks
     * @param io_dblocks     List os data blocks
     * @param o_error        error
     *
     * @return               false if errors occur, true otherwise
     *
     * @author               Elisabete Bugalho
     * @version              2.7.2.4
     * @since                02/02/2018
    **************************************************************************/
    FUNCTION get_related_blocks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_sblock   IN table_number,
        i_configs_ctx IN pk_prog_notes_types.t_configs_ctx,
        io_sblocks    IN OUT table_number,
        io_dblocks    IN OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    -- controls action buttns activation
    FUNCTION get_flg_active
    (
        i_prof          IN profissional,
        i_pn_status     IN VARCHAR2,
        i_to_state      IN VARCHAR2,
        i_default_value IN VARCHAR2,
        i_flg_submit    VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    -- to get correct edit translation when in submit mode
    FUNCTION get_edit_submit_desc
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_action   IN NUMBER,
        i_action_name IN VARCHAR2,
        i_desc_action IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_flg_submit_mode(i_prof IN profissional) RETURN VARCHAR2;

    FUNCTION get_flg_cancel
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_pn_status  IN VARCHAR2,
        i_flg_cancel IN VARCHAR2,
        i_flg_submit VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_flg_ok
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_pn_status IN VARCHAR2,
        i_flg_ok    IN VARCHAR2
    ) RETURN VARCHAR2;

    /**************************************************************************
     * Check note, begin/end date
     *
     * @param i_lang                     language identifier
     * @param i_prof                     logged professional structure
     * @param i_id_episode               episode id
     * @param i_flg_filter               date filter condition
     * @param i_id_pn_note_type          pn note type
     * @param i_id_epis_pn               episode pn note id
     * @param i_id_epis_pn_det_task      episode note det task array
     * @param i_dt_proposed              proposed date
     * @param i_days_available_period    available date period
     * @param o_note_date
     * @param o_begin_date
     * @param o_end_date
     * @param o_error                    error
     *
     * @return               false if errors occur, true otherwise
     *
     * @author               Lillian Lu
     * @version              2.7.3.2
     * @since                04/17/2018
    **************************************************************************/
    FUNCTION check_date_filter_base
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_filter            IN pn_dblock_ttp_mkt.flg_auto_populated%TYPE,
        i_id_pn_note_type       IN pn_note_type.id_pn_note_type%TYPE,
        i_id_epis_pn            IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_id_epis_pn_det_task   IN table_number,
        i_dt_proposed           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_days_available_period IN pn_dblock_mkt.days_available_period%TYPE,
        o_begin_date            OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_end_date              OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_note_date             OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
     * Returns the datablock flg_description and description_condition
     *
     * @param i_lang                  language identifier
     * @param i_prof                  logged professional structure
     * @param i_id_note_type          note type id
     * @param i_id_sblock             soap block id
     * @param i_id_dblock             data block id
     * @param i_id_task               task id
     * @param o_flg_description       flg_description
     * @param o_description_condition description_conditionn
     * @param o_error                 error
     *
     * @return               false if errors occur, true otherwise
     *
     * @author               Amanda Lee
     * @version              2.7.3.3
     * @since                2018-05-02
    **************************************************************************/
    FUNCTION get_data_block_desc_condition
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_note_type          IN pn_note_type.id_pn_note_type%TYPE,
        i_id_sblock             IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_dblock             IN pn_data_block.id_pn_data_block%TYPE,
        i_id_task               IN tl_task.id_tl_task%TYPE,
        o_flg_description       OUT pn_dblock_ttp_mkt.flg_description%TYPE,
        o_description_condition OUT pn_dblock_ttp_mkt.description_condition%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * GET Task date from task_timeline_ea by market
    *
    * @param i_lang           Language identifier
    * @param i_prof           Logged professional structure
    * @param i_id_episode     Episode id
    * @param i_id_task        Task id
    * @param i_id_tl_task     Task type id
    * @param i_dt_task_str    Task date configuration string
    *
    * @return                 Task date
    *
    * @raises                 PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.5
    * @since                2018-06-04
    */
    FUNCTION get_pn_dt_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_task     IN v_pn_tasks.id_task%TYPE,
        i_id_tl_task  IN tl_task.id_tl_task%TYPE,
        i_dt_task_str IN VARCHAR2
    ) RETURN v_pn_tasks.dt_task%TYPE;

    FUNCTION ins_prof_access_exception
    (
        i_id_prof_access_exception IN table_number,
        i_id_institution           IN table_number,
        i_id_profile_template      IN profile_template.id_profile_template%TYPE
    ) RETURN BOOLEAN;

    FUNCTION has_arabic_note
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_area      IN VARCHAR2,
        i_flg_scope IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_flg_scope_e
    ) RETURN VARCHAR2;

    PROCEDURE get_arabic_fields
    (
        i_note_ids     IN table_number,
        o_arabic_field OUT table_clob
    );

    PROCEDURE get_arabic_fields_one_cursor
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_note_ids        IN table_number,
        i_flg_report_type IN VARCHAR2 DEFAULT NULL,
        io_values         IN OUT table_clob
    );

    FUNCTION get_note_by_area
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_area IN pn_area.internal_name%TYPE
    ) RETURN table_number;

    FUNCTION get_note_type_by_area
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_area       IN pn_area.internal_name%TYPE DEFAULT NULL,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_note_type_area;
    
    FUNCTION get_dblock_description
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_desc_function IN pn_dblock_mkt.desc_function%TYPE,
        i_id_episode    IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
        
END pk_prog_notes_utils;
/
