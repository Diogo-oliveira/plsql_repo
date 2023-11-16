/*-- Last Change Revision: $Rev: 2028894 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_prog_notes_grids IS
  
    -- Author  : SOFIA.MENDES
    -- Created : 26-01-2011 15:52:22
    -- Purpose : Progress notes functions relation with transactional modal

    -- Public type declarations 

    -- Public constant declarations

    -- Public function and procedure declarations    
    TYPE t_rec_epis_pn_hist IS RECORD(
        id_epis_pn          epis_pn_hist.id_epis_pn%TYPE,
        dt_hist             epis_pn_hist.dt_epis_pn_hist%TYPE,
        id_episode          epis_pn_hist.id_episode%TYPE,
        flg_status          epis_pn_hist.flg_status%TYPE,
        id_note_type        epis_pn_hist.id_pn_note_type%TYPE,
        id_dep_clin_serv    epis_pn_hist.id_dep_clin_serv%TYPE,
        dt_pn_date          epis_pn_hist.dt_pn_date%TYPE,
        id_prof_create      epis_pn_hist.id_prof_create%TYPE,
        dt_create           epis_pn_hist.dt_create%TYPE,
        dt_last_update      epis_pn_hist.dt_last_update%TYPE,
        id_prof_last_update epis_pn_hist.id_prof_last_update%TYPE,
        id_prof_signoff     epis_pn.id_prof_signoff%TYPE,
        dt_signoff          epis_pn.dt_signoff%TYPE,
        id_prof_cancel      epis_pn_hist.id_prof_cancel%TYPE,
        dt_cancel           epis_pn_hist.dt_cancel%TYPE,
        id_cancel_reason    epis_pn_hist.id_cancel_reason%TYPE,
        cancel_notes        epis_pn_hist.notes_cancel%TYPE,
        flg_history         VARCHAR2(1),
        flg_note            VARCHAR2(1),
        id_dictation_report epis_pn_hist.id_dictation_report%TYPE,
        max_records_nr      PLS_INTEGER,
        --addendums related fields
        id_epis_pn_addendum epis_pn_addendum_hist.id_epis_pn_addendum%TYPE,
        pn_addendum         epis_pn_addendum_hist.pn_addendum%TYPE,
        flg_record_type     VARCHAR2(1), --indicates if it is a note or an addendum
        id_software         epis_pn_hist.id_software%TYPE,
        id_prof_reviewed    epis_pn.id_prof_reviewed%TYPE,
        dt_reviewed         epis_pn.dt_reviewed%TYPE,
        id_prof_submit      epis_pn.id_prof_submit%TYPE,
        dt_submit           epis_pn.dt_submit%TYPE);

    TYPE tab_epis_pn_hist IS TABLE OF t_rec_epis_pn_hist;

    TYPE t_rec_note_blocks_descs IS RECORD(
        id_block   epis_pn_signoff.id_pn_soap_block%TYPE,
        block_text epis_pn_signoff.pn_signoff_note%TYPE);

    TYPE tab_note_blocks_desc IS TABLE OF t_rec_note_blocks_descs;

    TYPE t_rec_notes IS RECORD(
        id_epis_pn               epis_pn.id_epis_pn%TYPE,
        note_short_date          pk_translation.t_desc_translation,
        note_short_hour          pk_translation.t_desc_translation,
        id_pn_note_type          pn_note_type.id_pn_note_type%TYPE,
        type_desc                pk_translation.t_desc_translation,
        flg_status               epis_pn.flg_status%TYPE,
        note_flg_status_desc     pk_translation.t_desc_translation,
        prof_signature           pk_translation.t_desc_translation,
        flg_ok                   VARCHAR2(1char),
        flg_cancel               VARCHAR2(1char),
        note_nr_addendums        pk_translation.t_desc_translation,
        flg_editable             VARCHAR2(1char),
        flg_write                pn_note_type_mkt.flg_write%TYPE,
        gender                   pn_note_type_mkt.gender%TYPE,
        age_min                  pn_note_type_mkt.age_min%TYPE,
        age_max                  pn_note_type_mkt.age_max%TYPE,
        flg_expand_sblocks       pn_note_type_mkt.flg_expand_sblocks%TYPE,
        flg_sign_off_login_avail pn_note_type_mkt.flg_sign_off_login_avail%TYPE,
        viewer_category          epis_pn.id_epis_pn%TYPE,
        viewer_category_desc     pk_translation.t_desc_translation);

    /**
    * Returns the actions to be displayed in summary screen paging filter options.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_episode                    episode identifier
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null
    * @param i_area                       Area name. Ex: HP - History and Physician Notes Screen
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
    FUNCTION get_actions_pag_filter
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_area       IN pn_area.internal_name%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)    
    * @param I_ID_EPISODE            Episode identifier
    * @param I_AREA                  Area Internal Name
    * @param O_NUM_RECORDS           number of records per page
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Sofia Mendes
    * @since                         28-Jan-2011
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_num_page_records
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_area        IN pn_area.internal_name%TYPE,
        o_num_records OUT PLS_INTEGER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_pnotes_count          Get number of all notes of the given type associated with the current episode.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_episode             ID_EPISODE identifier
    * @param i_id_patient             patient identifier
    * @param i_flg_scope              E-episode; P-patient
    * @param i_area                   Area internal name
    * @param I_SEARCH                 keyword to Search for
    * @param I_FILTER                 Filter 
    * @param o_num_epis_pn            Returns the number of records for the search criteria
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR    
    
    * 
    * @return                        Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          27-Jan-2011
    *******************************************************************************************************************************************/
    FUNCTION get_epis_pnotes_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_flg_scope   IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_flg_scope_e,
        i_area        IN pn_area.internal_name%TYPE,
        i_search      IN VARCHAR2,
        i_filter      IN VARCHAR2,
        o_num_epis_pn OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
        * Given a term to search, returns the correspondent matches from the tables EPIS_PN_DET, EPIS_PN_SIGNOFF and EPIS_PN_ADDENDUM.
        * @param      i_lang                   Language for translation (not in use)
        * @param      i_search                 The string to be searched
        *
        * @author     Pedro Pinheiro
        * @version    2.6.0.5
        * @since      15-Feb-2011
    */

    FUNCTION search_epis_note
    (
        i_lang       IN language.id_language%TYPE,
        i_search     IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN table_t_epis_note;

    /**
      * Returns the notes to the summary grid.
      *
      * @param i_lang                   language identifier
      * @param i_prof                   logged professional structure
      * @param i_episode                episode identifier. Mandatory
      * @param i_id_patient             patient identifier
      * @param i_flg_scope              E-episode; P-patient
      * @param i_area                   Area name. Ex:
      *                                       HP - histoy and physician
      *                                       PN-Progress Note    
      * @param i_flg_desc_order         Y-Should be used descending order by date. N-Should be read the configuration order
      * @param I_START_RECORD           Paging - initial record number
      * @param I_NUM_RECORDS            Paging - number of records to display
      * @param I_SEARCH                 keyword to Search for
      * @param I_FILTER                 Filter by a listed interval of dates
      * @param o_data                   notes data
      * @param o_notes_texts            Texts that compose the note
      * @param o_addendums              Addendums data
    * @param o_comments         Comments data
      * @param o_error                  error
      *
      * @return                         false if errors occur, true otherwise
      *
      * @author               Sofia Mendes
      * @version               2.6.0.5
      * @since                26-Jan-2011
      */
    FUNCTION get_epis_prog_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_flg_scope      IN VARCHAR2,
        i_area           IN pn_area.internal_name%TYPE,
        i_flg_desc_order IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        --
        i_start_record IN NUMBER,
        i_num_records  IN NUMBER,
        --
        i_search       IN VARCHAR2,
        i_filter       IN VARCHAR2,
        i_flg_category IN VARCHAR2 DEFAULT NULL,
        --
        o_data        OUT NOCOPY pk_types.cursor_type,
        o_notes_texts OUT NOCOPY pk_types.cursor_type,
        o_addendums   OUT NOCOPY pk_types.cursor_type,
        o_comments    OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the note info.
    * Function to the sign-off screen.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn             Note Id     
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_epis_prog_notes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE,
        i_flg_config  IN VARCHAR2 DEFAULT NULL,
        o_data        OUT pk_types.cursor_type,
        o_notes_texts OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns Number of records to display in each page. to be used on the history pagging
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE            Episode Identifier
    * @param I_AREA                  Area internal name description
    * @param O_NUM_RECORDS           number of records per page
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Sofia Mendes
    * @since                         28-Jan-2011
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_num_page_records_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_area        IN pn_area.internal_name%TYPE,
        o_num_records OUT PLS_INTEGER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_notes_history_count          Get number of all records in history associated to a given note.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_epis_pn             Note identifier
    * @param o_num_records            The number of records in history + actual info
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR    
    
    * 
    * @return                        Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          27-Jan-2011
    *******************************************************************************************************************************************/
    FUNCTION get_notes_history_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE,
        o_num_records OUT PLS_INTEGER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the note detail or history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param i_flg_report_type        Report type: C-complete; D-detailed
    * @param i_date_rep_config        Indicates if the title should be shown. T-should be shown the title. 
    *                                                                         B-should be shown the soap block with the date
    *                                                                         A-should be shown the both things (title + date soap block)
    * @param I_START_RECORD           Paging - initial record number
    * @param I_NUM_RECORDS            Paging - number of records to display
    * @param o_data                   notes data (cursor with labels, format types, note id,...)
    * @param o_values                 Clobs values list    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_notes_det_history
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ids_epis_pn       IN table_number,
        i_flg_screen        IN VARCHAR2,
        i_flg_report_type   IN VARCHAR2,
        i_date_rep_config   IN sys_config.value%TYPE DEFAULT pk_prog_notes_constants.g_show_all,
        i_start_record      IN NUMBER DEFAULT NULL,
        i_num_records       IN NUMBER DEFAULT NULL,
        i_pn_soap_block_in  IN table_number DEFAULT NULL,
        i_pn_soap_block_nin IN table_number DEFAULT NULL,
        i_flg_search        IN table_varchar DEFAULT NULL,
        o_data              OUT pk_types.cursor_type,
        o_values            OUT table_clob,
        o_note_ids          OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the concatenated text containing all texts that compose a soap block section.
    * Get the actual data (can not be used for history data).
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             Episode identifier
    * @param i_id_epis_pn             Note id
    * @param i_id_soap_block          Soap block id    
    * @param i_id_pn_note_type        Note type identifier
    * @param i_id_market              Market id
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise 
    *
    * @return                         Clob with the soap block concatenated texts
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          08-Feb-2011
    */
    FUNCTION get_block_concat_txt
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_soap_block   IN epis_pn_det.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_market       IN market.id_market%TYPE,
        i_flg_detail      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dblock_exclude  IN table_number DEFAULT NULL,
        i_bold_dblock     IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_note_dash       IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_flg_search      IN table_varchar DEFAULT NULL
    ) RETURN CLOB;

    /**
    * Returns the concatenated text containing all texts that compose a soap block section.
    * Get the history data (can not be used for actual data).
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_epis_pn             Note id
    * @param i_id_soap_block          Soap block id    
    * @param i_id_pn_note_type        Note type identifier
    * @param i_id_market              Market id
    * @param i_dt_hist                History date
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise 
    *
    * @return                         Clob with the soap block concatenated texts
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          08-Feb-2011
    */
    FUNCTION get_block_concat_txt_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_pn      IN epis_pn_hist.id_epis_pn%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_soap_block   IN epis_pn_det_hist.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_market       IN market.id_market%TYPE,
        i_dt_hist         IN epis_pn_hist.dt_epis_pn_hist%TYPE,
        i_flg_detail      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB;

    /**
    * Returns the concatenated text of all tasks associated to an epis_pn_det, based on a history time.
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
    FUNCTION get_tasks_concat_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn_det IN epis_pn_det_hist.id_epis_pn_det%TYPE,
        i_dt_hist        IN epis_pn_det_task_hist.dt_epis_pn_det_task_hist%TYPE,
        i_flg_detail     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB;

    /**
    * Returns the block texts associated to a note (grouped by soap data block).
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_note_ids               List of notes identifiers
    * @param i_note_status            Notes statuses   
    * @param i_show_title             T-shows the title; B-shows the soap block date; All-shows the both   
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    * @param i_soap_blocks            List of soap blocks to be considered
    *
    * @return                         Texts info
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_note_block_texts
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_note_ids        IN table_number,
        i_note_status     IN table_varchar,
        i_show_title      IN VARCHAR2,
        i_flg_detail      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_soap_blocks     IN table_number DEFAULT NULL,
        i_soap_blocks_nin IN table_number DEFAULT NULL,
        i_flg_search      IN table_varchar DEFAULT NULL
    ) RETURN t_table_rec_pn_texts;

    /**
    * Returns the block texts associated to a note (grouped by soap data block) in the history tables.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_note_id                Note identifier
    * @param i_dt_hist                History date
    * @param i_show_title             T-shows the title; B-shows the soap block date; All-shows the both
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise     
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_note_block_texts_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_note_id    IN epis_pn_hist.id_epis_pn%TYPE,
        i_dt_hist    IN epis_pn_hist.dt_epis_pn_hist%TYPE,
        i_show_title IN VARCHAR2,
        i_flg_detail IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_rec_pn_texts;

    /**
    * Get the notes history or detail.
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_epis_pn                Note id
    * @param   i_scope                     id_patient if i_flg_scope = 'P'
    *                                      id_visit if i_flg_scope = 'V'
    *                                      id_episode if i_flg_scope = 'E'
    * @param   i_flg_report_type           Report type: C-complete report; D-forensic report
    * @param   i_start_date                Start date to be considered
    * @param   i_end_date                  End date to be considered
    * @param   i_area                      Area name: HN: History and Physical notes; PN: Progress 
    * @param   o_data                      Data cursor. Labels, format types and status
    * @param   o_values                    Texts/contents
    * @param   o_note_ids                  Note identifiers
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version 2.6.0.5
    * @since   02-02-2011
    */
    FUNCTION get_rep_progress_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_pn        IN epis_pn.id_epis_pn%TYPE,
        i_flg_scope         IN VARCHAR2,
        i_scope             IN NUMBER,
        i_flg_report_type   IN VARCHAR2,
        i_start_date        IN VARCHAR2,
        i_end_date          IN VARCHAR2,
        i_area              IN pn_area.internal_name%TYPE,
        i_pn_soap_block_in  IN table_number,
        i_pn_note_type_in   IN table_number,
        i_pn_soap_block_nin IN table_number,
        i_pn_note_type_nin  IN table_number,
        i_flg_search        IN table_varchar DEFAULT NULL,
        i_num_records       IN NUMBER DEFAULT NULL,
        o_data              OUT NOCOPY pk_types.cursor_type,
        o_values            OUT NOCOPY table_clob,
        o_note_ids          OUT NOCOPY table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the block texts associated to a note (grouped by soap data block). 
    * Returns an unsorted collection.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_note_ids               List of notes identifiers
    * @param i_note_status            Notes statuses   
    * @param i_market                 id market
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise 
    * @param i_soap_blocks            List of soap blocks to be considered
    *
    * @return                         Texts info
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_note_block_texts_unsorted
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_note_ids       IN table_number,
        i_note_status    IN table_varchar,
        i_market         IN market.id_market%TYPE,
        i_flg_detail     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_soap_blocks    IN table_number DEFAULT NULL,
        i_dblock_exclude IN table_number DEFAULT NULL,
        i_bold_dblock    IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_note_dash      IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_flg_search     IN table_varchar DEFAULT NULL
    ) RETURN t_table_rec_pn_texts;

    /**
    * Returns the description of the nr of addendums of a note.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_nr_addendums           Nr of addendums. It only gets the descrptive if the nr of addendums had already been calculated    
    * @param i_id_epis_pn             note id       
    *
    * @return                         description
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                14-Feb-2011
    */
    FUNCTION get_nr_addendums_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_nr_addendums   IN PLS_INTEGER DEFAULT NULL,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_flg_has_status IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * This functions receives the note text and if the data block refers to one that has parents concatenates
    * the data block desc and indent the note text
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_data_block          Data block id
    * @param i_pn_note                Note text 
    * @param i_id_pn_soap_block       soap block id
    * @param i_market                 Market id
    * @param i_pos_nr                 Position nr
    * @param i_id_pn_note             Note id
    * @param i_id_episode             Episode id
    * @param i_id_dep_clin_serv       Dep_clin_serv id
    * @param i_id_department          Department id
    * @param i_id_episode             Episode id
    * @param i_id_software            Software id
    *
    * @return                         Clob with the soap block concatenated texts
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since               08-Feb-2011
    */
    FUNCTION get_data_blocks_txt
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_data_block    IN epis_pn_det.id_pn_data_block%TYPE,
        i_pn_note          IN epis_pn_det.pn_note%TYPE,
        i_id_pn_soap_block IN epis_pn_det.id_pn_soap_block%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_pos_nr           IN PLS_INTEGER,
        i_id_pn_note       IN epis_pn.id_epis_pn%TYPE,
        i_id_dep_clin_serv IN epis_pn.id_dep_clin_serv%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_software      IN software.id_software%TYPE,
        i_bold_dblock      IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_flg_search       IN table_varchar DEFAULT NULL
    ) RETURN CLOB;

    /**************************************************************************
    * Check data block type
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_episode                Episode ID
    * @param i_id_pn_note_type        Note Type Identifier
    * @param i_id_pn_soap_block       Soap block ID
    * 
    * return                          If data block is current date type (Y) or not (N)                        
    *                                                                        
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/23                               
    **************************************************************************/
    FUNCTION check_data_block_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns the note info for sign-off functionality when there is no just save screen
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_id_epis_pn             Note identifier
    *
    * @param      o_flg_edited             Indicate if the SOAP block was edited
    * @param      o_pn_soap_block          Soap Block array with ids
    * @param      o_pn_signoff_note        Notes array
    * @param      o_error                  error information
    *
    * @return                              false if errors occur, true otherwise
    *
    * @author                              ANTONIO.NETO
    * @version                             2.6.2
    * @since                               19-Apr-2012
    */
    FUNCTION get_signoff_note_text
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_flg_edited      OUT table_varchar,
        o_pn_soap_block   OUT table_number,
        o_pn_signoff_note OUT table_clob,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the last note info for edis summary grids
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_id_epis_pn             Note identifier
    *
    * @param      o_flg_edited             Indicate if the SOAP block was edited
    * @param      o_pn_soap_block          Soap Block array with ids
    * @param      o_pn_signoff_note        Notes array
    * @param      o_error                  error information
    *
    * @return                              false if errors occur, true otherwise
    *
    * @author                              Sofia Mendes
    * @version                             2.6.2
    * @since                               23-Jul-2013
    */
    FUNCTION get_last_note_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_software IN software.id_software%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_pn_area  IN pn_area.id_pn_area%TYPE,
        o_note        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_notes_dashboard
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_title           OUT pk_types.cursor_type,
        o_note            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    -----------
    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_ordered_list_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /* *
    * Returns shifts summary notes for the 24h
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_start_date             initial date
    * @param i_end_date               final date
    * @param i_tbl_episode            list of episode
    *
    * @return                         description
    *
    * @author               Carlos FErreira
    * @version              2.7.1
    * @since                28-04-2017
    */
    FUNCTION get_rep_pn_24h
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_start_date  IN VARCHAR2,
        i_end_date    IN VARCHAR2,
        i_tbl_episode IN table_number,
        o_data        OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_note_review_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ids_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_current_details  OUT CLOB,
        o_previous_details OUT CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_rep_progress_notes
    (
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_patient              IN patient.id_patient%TYPE,
        i_id_visit                IN visit.id_visit%TYPE,
        i_flg_scope               VARCHAR2,
        i_area                    IN pn_area.internal_name%TYPE,
        i_pn_soap_block_in_count  IN NUMBER,
        i_pn_soap_block_in        IN table_number,
        i_pn_soap_block_nin_count IN NUMBER,
        i_pn_soap_block_nin       IN table_number,
        i_pn_note_type_in_count   IN NUMBER,
        i_pn_note_type_in         IN table_number,
        i_pn_note_type_nin_count  IN NUMBER,
        i_pn_note_type_nin        IN table_number,
        i_start_date              IN TIMESTAMP WITH TIME ZONE,
        i_end_date                IN TIMESTAMP WITH TIME ZONE,
        i_num_records             IN NUMBER
    ) RETURN table_number;

    -- Public variable declarations
    g_report_scope VARCHAR2(1) := pk_alert_constant.g_no;

    g_error         VARCHAR2(2000 CHAR);
    g_package_owner VARCHAR2(200 CHAR);
    g_package_name  VARCHAR2(200 CHAR);
    g_package       VARCHAR2(200 CHAR);
    g_owner         VARCHAR2(200 CHAR);
    g_sysdate       DATE;
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_found         BOOLEAN;
    g_exception EXCEPTION;

END pk_prog_notes_grids;
/
