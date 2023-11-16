/*-- Last Change Revision: $Rev: 1921273 $*/
/*-- Last Change by: $Author: nuno.coelho $*/
/*-- Date of last change: $Date: 2019-10-18 16:52:35 +0100 (sex, 18 out 2019) $*/

CREATE OR REPLACE PACKAGE pk_rep_progress_notes IS

    /**
    * Retrieve summarized info on all previous encounters.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param o_enc_info     previous encounters info
    * @param o_enc_data     previous encounters data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2009/03/31
    */
    FUNCTION get_prev_encounter
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_enc_info OUT pk_types.cursor_type,
        o_enc_data OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns the soap block associated with the institution / software / clinical_service
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    *
    * @param OUT  o_free_text   Free text records cursor
    * @param OUT  o_rea_visit   Reason for visit records cursor
    * @param OUT  o_app_type    Appointment type records cursor
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    03/11/2010
    ********************************************************************************************/
    FUNCTION get_rep_prog_notes_blocks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_soap_blocks OUT pk_types.cursor_type,
        o_free_text   OUT pk_types.cursor_type,
        o_rea_visit   OUT pk_types.cursor_type,
        o_app_type    OUT pk_types.cursor_type,
        o_prof_rec    OUT pk_translation.t_desc_translation,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get reason for visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_rea_visit    cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/30
    */
    FUNCTION get_reason_for_visit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_rea_visit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get free text record detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soap_block   block identifier
    * @param i_record       record identifier
    * @param o_detail       detail cursor
    * @param o_history      history cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_free_text_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_record     IN NUMBER,
        o_detail     OUT pk_types.cursor_type,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get free text records complete detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_history      history cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/08
    */
    FUNCTION get_free_text_complete
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_history OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @param   i_flg_type                  Type: HN: History and Physical notes; PN: Progress 
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
        i_flg_type          IN VARCHAR2,
        i_pn_soap_block_in  IN table_number DEFAULT NULL,
        i_pn_note_type_in   IN table_number DEFAULT NULL,
        i_pn_soap_block_nin IN table_number DEFAULT NULL,
        i_pn_note_type_nin  IN table_number DEFAULT NULL,
        i_flg_search        IN table_varchar DEFAULT null,
        i_num_records       IN NUMBER DEFAULT NULL,
        o_data              OUT pk_types.cursor_type,
        o_values            OUT table_clob,
        o_note_ids          OUT table_number,
        o_note OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the notes epis summary.
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_epis_pn                Note id
    * @param i_area                        Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note  
    *                                       DS - Discharge Summary  
    * @param I_FILTER                 Filter by a listed interval of dates (default numm in this case it will be DS)
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note
    * @param o_addendums              Addendums data
    * @param o_error                  error
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Elisabete Bugalho
    * @version 27.1.2
    * @since   03-07-2017
    */
    FUNCTION get_epis_prog_notes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area        IN VARCHAR2,
        i_filter      IN VARCHAR2 DEFAULT NULL,
        o_data        OUT pk_types.cursor_type,
        o_notes_texts OUT pk_types.cursor_type,
        o_addendums   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the template id associated to a single page note type.
    *
    * @param i_lang         language identifier
    * @param i_id_epis_pn   episode id
    * @param o_id_task      id_task 
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Vítor Sá
    * @version               2.7.1.5
    * @since                2017/09/21
    */
    FUNCTION get_id_epis_documentation
    (
        i_lang       IN language.id_language%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_id_task    OUT epis_pn_det_task.id_task%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_note_by_area
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_area  IN pn_area.internal_name%TYPE,
        o_note  OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the template id associated to a single page note type.
    *
    * @param i_lang         language identifier
    * @param i_id_epis_pn   episode id
    * @param o_id_task      id_task 
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Coelho
    * @version              2.8.0.1
    * @since                2019/10/16
    */
    FUNCTION get_id_epis_documentation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_pn.id_episode%TYPE,
        i_id_pn_area IN pn_area.id_pn_area%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

END pk_rep_progress_notes;
/