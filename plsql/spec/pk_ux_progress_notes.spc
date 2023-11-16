/*-- Last Change Revision: $Rev: 2014855 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-05-23 15:40:02 +0100 (seg, 23 mai 2022) $*/

CREATE OR REPLACE PACKAGE pk_ux_progress_notes IS

    /**
    * Similar to PK_SYSDOMAIN.GET_DOMAINS for domain DIAGNOSIS.FLG_TYPE.
    * Marks one option as default.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_domains      cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.?
    * @since                2009/05/20
    */
    FUNCTION get_diag_types
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

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

    /**
    * Retrieve detailed info on previous encounter.
    * Information is SOAP oriented.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param o_soap_blocks  soap blocks
    * @param o_data_blocks  data blocks
    * @param o_simple_text  simple text blocks structure
    * @param o_doc_reg      documentation registers
    * @param o_doc_val      documentation values
    * @param o_free_text    free text records
    * @param o_rea_visit    reason for visit records
    * @param o_app_type     appointment type
    * @param o_prof_rec     author and date of last change
    * @param o_nur_data     previous encounter nursing data
    * @param o_addendums_list addendums list    
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5
    * @since                2010/12/20
    */
    FUNCTION get_prev_encounter_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        o_soap_blocks    OUT pk_types.cursor_type,
        o_data_blocks    OUT pk_types.cursor_type,
        o_simple_text    OUT pk_types.cursor_type,
        o_doc_reg        OUT pk_types.cursor_type,
        o_doc_val        OUT pk_types.cursor_type,
        o_free_text      OUT pk_types.cursor_type,
        o_rea_visit      OUT pk_types.cursor_type,
        o_app_type       OUT pk_types.cursor_type,
        o_prof_rec       OUT VARCHAR2,
        o_nur_data       OUT pk_types.cursor_type,
        o_addendums_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieve summarized descriptions on all previous encounters.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param i_flg_type     {*} 'A' All Specialities {*} 'M' With me {*} 'S' My speciality    
    * @param o_enc_info     previous contacts descriptions
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2009/04/27
    */
    FUNCTION get_prev_enc_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2,
        o_enc_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get current appointment type.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_parent       parent type of appointment identifier
    * @param o_data         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION get_appointment_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_id_dcs   OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_desc_dcs OUT pk_translation.t_desc_translation,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get appointment types. Considers parenting.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_parent       parent type of appointment identifier
    * @param o_data         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION get_appointment_types
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_parent  IN clinical_service.id_clinical_service_parent%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get appointment types.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_data         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION get_appointment_types
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set appointment type.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_dcs          appointment identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION set_appointment_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_dcs     IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get complaints for current episode's type of appointment.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_user_query   user query
    * @param o_complaints   complaints cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_complaints_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_user_query IN VARCHAR2,
        o_complaints OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get complaints for given type of appointment.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_dcs          appointment identifier
    * @param o_complaints   complaints cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_complaints_dcs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_complaints OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get complaints for all types of appointment.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_user_query   user query
    * @param o_complaints   complaints cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_complaints_all
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_user_query IN VARCHAR2,
        o_complaints OUT pk_types.cursor_type,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_error      OUT t_error_out
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
    * @since                    21/09/2010
    ********************************************************************************************/
    FUNCTION get_prog_notes_blocks
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_soap_blocks        OUT pk_types.cursor_type,
        o_data_blocks        OUT pk_types.cursor_type,
        o_button_blocks      OUT pk_types.cursor_type,
        o_simple_text        OUT pk_types.cursor_type,
        o_doc_reg            OUT pk_types.cursor_type,
        o_doc_val            OUT pk_types.cursor_type,
        o_free_text          OUT pk_types.cursor_type,
        o_rea_visit          OUT pk_types.cursor_type,
        o_app_type           OUT pk_types.cursor_type,
        o_screen_det         OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
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
    * Get free text records of a given area.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_soap_block   block identifier
    * @param i_inc_cancel   include cancelled records? Y/N
    * @param o_free_text    detail cursor
    * @param o_warning      user warning
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_free_text_area
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_inc_cancel IN VARCHAR2,
        o_free_text  OUT pk_types.cursor_type,
        o_warning    OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Stores user input from free text data blocks.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_soap_blocks  block identifiers list
    * @param i_records      record identifiers list
    * @param i_texts        texts list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/04
    */
    FUNCTION set_free_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_cat    IN category.flg_type%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_soap_blocks IN table_number,
        i_records     IN table_number,
        i_texts       IN table_clob,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels record from free text data blocks.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_soap_block   block identifier
    * @param i_record       record identifier
    * @param i_reason       cancel reason identifier
    * @param i_notes        cancel notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/04
    */
    FUNCTION set_free_text_cancel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_record     IN NUMBER,
        i_reason     IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes      IN cancel_info_det.notes_cancel_long%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Stores user input from reason for visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_text         text
    * @param i_complaints   complaint identifiers list
    * @param o_id_per       created record identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/04
    */
    FUNCTION set_reason_for_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_record     IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_text       IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_complaints IN table_number,
        o_id_per     OUT pn_epis_reason.id_pn_epis_reason%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Stores user input from reason for visit and coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_text         text
    * @param i_complaints   complaint identifiers list
    * @param i_diags        diagnoses identifiers list
    * @param o_id_per       created record identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Alves
    * @version               2.6.4.1
    * @since                2014/08/27
    */
    FUNCTION set_reason_for_visit_coding
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_record     IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_text       IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_complaints IN table_number,
        i_flg_rep_by IN epis_complaint.flg_reported_by%TYPE,
        i_diags      IN table_number,
        o_id_per     OUT pn_epis_reason.id_pn_epis_reason%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels record from reason for visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_reason       cancel reason identifier
    * @param i_notes        cancel notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/22
    */
    FUNCTION set_reason_for_visit_cancel
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_record   IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_reason   IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes    IN cancel_info_det.notes_cancel_long%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Stores user input from reported by field.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_flg_rep_by   complaint reported by
    * @param o_id_per       created record identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/22
    */
    FUNCTION set_reported_by
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_record     IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_flg_rep_by IN epis_complaint.flg_reported_by%TYPE,
        o_id_per     OUT pn_epis_reason.id_pn_epis_reason%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Stores user input from coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_soap_block   block identifier
    * @param i_record       record identifier
    * @param i_diags        diagnoses identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/22
    */
    FUNCTION set_coding
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_record     IN NUMBER,
        i_diags      IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get information transfer default data.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_default
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get information transfer data for current visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_this_visit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get information transfer data for current user.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_my_visits
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get information transfer data for current specialty.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_this_spec
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get information transfer data for all visits.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_all_visits
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get soap note blocks.
    *
    * @param i_lang               language identifier
    * @param i_prof               logged professional structure
    * @param i_episode            episode identifier
    * @param i_patient            patient identifier
    * @param i_id_pn_note_type    note type identifier
    * @param i_epis_pn_work       soap note identifier
    * @param i_filter_search      pass the type (pn_data_block) (F - free text) (D - template)
    * @param o_soap_block         soap blocks cursor
    * @param o_data_block         data blocks cursor
    * @param o_button_block       button blocks cursor
    * @param o_error              error
    *
    * @return                     false if errors occur, true otherwise
    *
    * @author                     Ant? Neto
    * @version                    2.6.1.2
    * @since                      27-Jul-2011
    */
    FUNCTION get_soap_note_blocks
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_epis_pn_work    IN epis_pn.id_epis_pn%TYPE,
        i_filter_search   IN table_varchar DEFAULT NULL,
        o_soap_block      OUT pk_types.cursor_type,
        o_data_block      OUT pk_types.cursor_type,
        o_button_block    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the actions to be displayed in the 'ADD' button in the History and Physician screen.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_episode                    episode identifier
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null
    * @param i_flg_status_note            Selected note status.
    *                                     If no note is selected this param should be null
    * @param i_area                       Area internal name
    * @param o_actions      actions data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_actions_add_button
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        i_flg_status_note IN epis_pn.flg_status%TYPE,
        i_area            IN pn_area.internal_name%TYPE,
        o_actions         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the actions to be displayed in the 'ACTIONS' button when an addendum is selected
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure
    * @param i_area                    Area name: 
    *                                       HP - histoy and physician
    *                                       PN-Progress Note
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
        i_area                IN pn_area.id_pn_area%TYPE,
        i_flg_status_addendum IN epis_addendum.flg_status%TYPE,
        i_id_epis_addendum    IN epis_addendum.id_epis_addendum%TYPE,
        o_actions             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the actions to be displayed in the 'ACTIONS' button when a note is selected.
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure
    * @param i_area                    Area type
    *                                       HP - histoy and physician
    *                                       PN-Progress Note
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
        i_area            IN pn_area.internal_name%TYPE,
        i_flg_status_note IN epis_pn.flg_status%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_actions         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
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
    * @return                        Returns TRUE if success, otherwise returns FALSE
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
    * get_epis_prog_notes_count          Get number of all notes of the given type associated with the current episode.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param i_area                   Area internal name (HP,PN,...)
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
    FUNCTION get_epis_prog_notes_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area        IN pn_area.internal_name%TYPE,
        i_search      IN VARCHAR2,
        i_filter      IN VARCHAR2,
        o_num_epis_pn OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_prog_notes_count          Get number of all notes of the given type associated with the current episode.
    *                                    Function to the slide over
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param i_id_patient             patient identifier
    * @param i_flg_scope              E-episode; P-patient
    * @param i_area                   Area internal name (HP,PN,...)
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
    FUNCTION get_epis_prog_notes_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area        IN pn_area.internal_name%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_flg_scope   IN VARCHAR2,
        i_search      IN VARCHAR2,
        i_filter      IN VARCHAR2,
        o_num_epis_pn OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the notes to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note    
    * @param I_START_RECORD           Paging - initial record number
    * @param I_NUM_RECORDS            Paging - number of records to display
    * @param I_SEARCH                 keyword to Search for
    * @param I_FILTER                 Filter by a listed interval of dates
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note
    * @param o_addendums              Addendums data
    * @param o_area_configs           Configs associated to the area
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
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_pn         IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area               IN VARCHAR2,
        i_search             IN VARCHAR2,
        i_filter             IN VARCHAR2,
        i_start_record       IN NUMBER,
        i_num_records        IN NUMBER,
        o_data               OUT pk_types.cursor_type,
        o_notes_texts        OUT pk_types.cursor_type,
        o_addendums          OUT pk_types.cursor_type,
        o_comments           OUT pk_types.cursor_type,
        o_area_configs       OUT NOCOPY pk_types.cursor_type,
        o_doc_reg            OUT NOCOPY pk_types.cursor_type,
        o_doc_val            OUT NOCOPY pk_types.cursor_type,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_flg_is_arabic_note OUT VARCHAR2,
        o_error              OUT t_error_out
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
        o_data        OUT pk_types.cursor_type,
        o_notes_texts OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the notes to the summary grid.
    * Function to the slide over screen
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_patient             patient identifier
    * @param i_flg_scope              E-episode; P-patient
    * @param i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note    
    * @param I_START_RECORD           Paging - initial record number
    * @param I_NUM_RECORDS            Paging - number of records to display
    * @param I_SEARCH                 keyword to Search for
    * @param I_FILTER                 Filter by a listed interval of dates
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note
    * @param o_addendums              Addendums data
    * @param o_area_configs           Configs associated to the area
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
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_pn         IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area               IN VARCHAR2,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_scope          IN VARCHAR2,
        i_search             IN VARCHAR2,
        i_filter             IN VARCHAR2,
        i_start_record       IN NUMBER,
        i_num_records        IN NUMBER,
        o_data               OUT pk_types.cursor_type,
        o_notes_texts        OUT pk_types.cursor_type,
        o_addendums          OUT pk_types.cursor_type,
        o_comments           OUT pk_types.cursor_type,
        o_area_configs       OUT NOCOPY pk_types.cursor_type,
        o_doc_reg            OUT NOCOPY pk_types.cursor_type,
        o_doc_val            OUT NOCOPY pk_types.cursor_type,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_flg_is_arabic_note OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the notes to the summary grid.
    * Function to the slide over screen
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_patient             patient identifier             
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note
    * @param o_addendums              Addendums data
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_epis_prog_notes_res
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_notes_texts OUT pk_types.cursor_type,
        o_addendums   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the last note to the summary grid.
    * Function to the slide over screen
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_patient             patient identifier             
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note
    * @param o_addendums              Addendums data
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                01-11-2013
    */
    FUNCTION get_last_prog_notes_res
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_area        IN pn_area.internal_name%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_notes_texts OUT pk_types.cursor_type,
        o_addendums   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_last_prog_notes_res
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_area        IN pn_area.internal_name%TYPE,
        i_flg_category IN VARCHAR2,
        o_data        OUT pk_types.cursor_type,
        o_notes_texts OUT pk_types.cursor_type,
        o_addendums   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Create/update a Progress Notes Addendum
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_epis_pn             Progress Notes ID
    * @param   i_id_epis_pn_addendum Addendum ID
    * @param   i_pn_addendum         Progress Notes Addendum (text)
    * @param   i_area                Screen flg_type
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
        i_id_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_pn_addendum         IN epis_pn_addendum.pn_addendum%TYPE,
        i_area                IN VARCHAR2,
        o_epis_pn_addendum    OUT epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Create/update a Progress Notes Addendum
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
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
    * @param i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
    * @param   i_epis_pn_addendum      Progress Notes ID
    * @param   i_cancel_reason  Cancel reason ID
    * @param   i_notes_cancel Cancel notes
    *
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
        i_area             IN VARCHAR2,
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
    * @param i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
    * @param   i_epis_pn             Progress Notes ID    
    * @param   i_epis_pn_addendum    Addendum to signoff
    * @param   i_pn_addendum         Progress Notes Addendum (text)
    * @param   i_dt_signoff          Sign-off date
    * @param   i_flg_just_save       Just Save flag (Y- Just Save, N- Sign-off
    * @param   i_flg_edited          Edited addentum? (Y- Yes, N- No)
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
        i_area             IN VARCHAR2,
        i_id_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        i_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_pn_addendum      IN epis_pn_addendum.pn_addendum%TYPE,
        i_dt_signoff       IN VARCHAR2,
        i_flg_just_save    IN VARCHAR2,
        i_flg_edited       IN VARCHAR2,
        i_flg_hist         IN VARCHAR2 DEFAULT 'Y',
        o_epis_pn_addendum OUT epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

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
        o_addendum         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Saves work data into progress notes tables
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis_pn      Progress note identifier
    * @param   i_epis_pn_work Progress note identifier in work table
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
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel progress note
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
    * @param   i_epis_pn        Progress note identifier
    * @param   i_cancel_reason  Cancel reason identifier
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
        i_area          IN VARCHAR2,
        i_epis_pn       IN NUMBER,
        i_cancel_reason IN NUMBER,
        i_notes_cancel  IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sign off a progress note
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_area                      Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
    * @param   i_epis_pn                   Progress note identifier
    * @param   i_flg_edited                Indicate if the SOAP block was edited
    * @param   i_pn_soap_block             Soap Block array with ids
    * @param   i_pn_signoff_note           Notes array
    * @param   i_flg_just_save             Indicate if its just to save or to signoff
    * @param   i_flg_showed_just_save      Indicates if just save screen showed or not
    *
    * @param   o_error                     Error information
    *
    * @value   i_flg_just_save             {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_showed_just_save      {*} 'Y'- screen was showed to Professional {*} 'N'- screen didn't showed to Professional
    *
    * @return                              Returns TRUE if success, otherwise returns FALSE
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
        i_area                 IN VARCHAR2,
        i_epis_pn              IN epis_pn.id_epis_pn%TYPE,
        i_flg_edited           IN table_varchar,
        i_pn_soap_block        IN table_number,
        i_pn_signoff_note      IN table_clob,
        i_flg_just_save        IN VARCHAR2,
        i_flg_showed_just_save IN VARCHAR2,
        o_error                OUT t_error_out
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
        o_num_records OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the note detail or history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
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
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_flg_screen IN VARCHAR2,
        o_data       OUT pk_types.cursor_type,
        o_values     OUT table_clob,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the note detail or history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
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
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
        i_flg_screen   IN VARCHAR2,
        i_start_record IN NUMBER,
        i_num_records  IN NUMBER,
        o_data         OUT pk_types.cursor_type,
        o_values       OUT table_clob,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the note detail or history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param o_data                   notes data (cursor with labels, format types, note id,...)
    * @param o_values                 Clobs values list    
    * @param o_note_type_desc         Note type desc
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_notes_history
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE,
        i_start_record   IN NUMBER,
        i_num_records    IN NUMBER,
        o_data           OUT pk_types.cursor_type,
        o_values         OUT table_clob,
        o_note_type_desc OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the note detail or history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param o_data                   notes data (cursor with labels, format types, note id,...)
    * @param o_values                 Clobs values list    
    * @param o_note_type_desc         Note type desc
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_notes_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE,
        o_data           OUT pk_types.cursor_type,
        o_values         OUT table_clob,
        o_note_type_desc OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the note detail or history for arabic free text note.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param o_data                   notes data (cursor with labels, format types, note id,...)
    * @param o_values                 Clobs values list    
    * @param o_note_type_desc         Note type desc
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Vítor Sá
    * @version               2.7.4.6
    * @since                03-Dec-2018
    */
    FUNCTION get_notes_arabic
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn     IN table_number,
        o_data           OUT pk_types.cursor_type,
        o_values         OUT table_clob,
        o_arabic_field   OUT table_clob,
        o_note_type_desc OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the notes to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn_work        Note identifier
    * @param i_id_pn_note_type        Note type id. 3-Progress Note; 4-Prolonged Progress Note; 5-Intensive Care Note; 2-History and Physician Note
    * @param i_flg_definitive         Save PN in the definitive model (Y- YES, N- NO)
    * @param i_id_epis_pn_det_task    Task Ids that have to be syncronized
    * @param i_id_pn_soap_block       Soap block id
    * @param o_data                   notes data
    * @param o_text_blocks            Texts that compose the note
    * @param o_text_comments          Comments cursor
    * @param o_suggested              Texts that compose the note with the suggested records    
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
    FUNCTION get_work_notes_core
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_pn_work     IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type     IN epis_pn.id_pn_note_type%TYPE,
        i_flg_definitive      IN VARCHAR2,
        i_id_epis_pn_det_task IN table_number,
        i_id_pn_soap_block    IN table_number,
        o_data                OUT pk_types.cursor_type,
        o_text_blocks         OUT pk_types.cursor_type,
        o_text_comments       OUT pk_types.cursor_type,
        o_suggested           OUT pk_types.cursor_type,
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
    * Update all data block's content for a PN. If the data doesn't exists yet, the record will be created.
    * the IN parameter Type allow for select if append or update should be done to the text.
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_episode              Episode ID
    * @param   i_epis_pn              Progress note ID
    * @param   i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
    * @param   i_flg_action           C-Create; U-update
    * @param   i_dt_pn_date           Progress Note date Array
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
    *                                 Identified by id_task (id_analysis/id_exam) + i_id_task_aggregator
    * @param   i_dt_task              Task dates
    * @param   i_id_task_parent       Parent task identifier for comments functionality
    * @param   i_flg_task_parent      Flag tells where i_id_task_parent is a taskid or id_epis_pn_det_task
    * @param   i_id_multichoice       Array of tasks identifiers for cases that have more than one parameter (multichoice on exam results)
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
    FUNCTION set_all_data_block_work
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_pn            IN epis_pn.id_epis_pn%TYPE,
        i_area               IN VARCHAR2,
        i_flg_action         IN VARCHAR2,
        i_flg_definitive     IN VARCHAR2,
        i_dt_pn_date         IN table_varchar,
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
        o_id_epis_pn         OUT epis_pn.id_epis_pn%TYPE,
        o_flg_reload         OUT VARCHAR2,
        o_dt_finished        OUT VARCHAR2,
        o_error              OUT t_error_out
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
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_error      OUT t_error_out
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
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the notes to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_patient                Patient identifier
    * @param i_id_pn_note_type        Note type Identifier
    * @param i_id_epis_pn             Note type Identifier
    * @param o_data_1                 Grid data level 1
    * @param o_data_2                 Grid data level 2
    * @param o_data_3                 Grid data level 3
    * @param o_data_4                 Grid data level 4
    * @param o_data_5                 Grid data level 5
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Ant? Neto
    * @version                        2.6.1.2
    * @since                          27-Jul-2011
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

    /********************************************************************************************
    * Returns the list of configs to the given note type.
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PN_NOTE_TYPE       Note Type Identifier 
    * @param I_ID_EPISODE            Episode Identifier 
    * @param O_CONFIGS               Cursor with all the configs for the note type
    * @param o_note_type_desc         Note type desc
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
        o_configs         OUT pk_types.cursor_type,
        o_note_type_desc  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Return cursor with records for touch option area
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID
    * @param i_epis_doc               Table number with id_epis_documentation
    * @param i_epis_anamn             Table number with id_epis_anamnesis
    * @param i_epis_rev_sys           Table number with id_epis_review_systems
    * @param i_epis_obs               Table number with id_epis_observation
    * @param i_epis_past_fsh          Table number with id_pat_fam_soc_hist
    * @param i_epis_recomend          Table number with id_epis_recomend
    *
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/17                                
    **************************************************************************/
    FUNCTION get_import_epis_documentation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_epis_doc           IN table_number,
        i_epis_anamn         IN table_number,
        i_epis_rev_sys       IN table_number,
        i_epis_obs           IN table_number,
        i_epis_past_fsh      IN table_number,
        i_epis_recomend      IN table_number,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
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
    FUNCTION import_data_block
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
        i_id_pn_group         IN pn_group.id_pn_group%TYPE DEFAULT NULL,
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
        o_flg_just_save OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
        o_doc_area_register     OUT pk_types.cursor_type,
        o_doc_area_val          OUT pk_types.cursor_type,
        o_template_layouts      OUT pk_types.cursor_type,
        o_doc_area_component    OUT pk_types.cursor_type,
        o_id_doc_area           OUT NUMBER,
        o_error                 OUT t_error_out
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
        o_text        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
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
        i_id_epis_pn            IN epis_pn.id_epis_pn%TYPE,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

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
        o_area_max_notes OUT PLS_INTEGER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_flg_viewer_type IN pn_note_type.flg_viewer_type%TYPE,
        o_data            OUT pk_types.cursor_type,
        o_title           OUT sys_message.desc_message%TYPE,
        o_screen_name     OUT pn_area.screen_name%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

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
    FUNCTION get_task_detailed_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_type  IN table_number,
        i_id_task       IN table_number,
        i_id_episode    IN table_number,
        i_dt_register   IN table_varchar,
        i_prof_register IN table_number,
        i_id_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        o_description   OUT table_clob,
        o_signature     OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
    FUNCTION get_work_suggest_records
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
        o_flg_validated OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the flash service name for the multichoice in the comments functionality
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
        o_data       OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets the note history in case the note was automatically saved in the last time.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
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
        i_area    IN VARCHAR2,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_error   OUT t_error_out
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
    * Get current timetamp when there is a jump out of single page
    *
    * @param         i_lang                  Language ID for translations
    * @param         i_prof                  Professional vector of information (professional ID, institution ID, software ID)
    *
    * @param         o_dt_jump               jump date
    * @param         o_error                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Vanessa Barsottelli
    * @since                                 15-07-2014
    * @version                               2.6.4
    ********************************************************************************************/
    FUNCTION get_jump_datetime
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_dt_jump OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get all reason for visit by episode
    *
    * @param         i_lang                  Language ID for translations
    * @param         i_prof                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         i_episode               Episode ID
    *
    * @param         o_rea_visit             All reason for visit
    * @param         o_error                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Vanessa Barsottelli
    * @since                                 25-07-2014
    * @version                               2.6.4
    ********************************************************************************************/
    FUNCTION get_reason_for_visit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_rea_visit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Returns the last note to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_patient             patient identifier             
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note
    * @param o_addendums              Addendums data
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Paulo Teixeira
    * @version               2.6.4.2
    * @since                2014/07/31
    */
    FUNCTION get_last_prog_notes_res
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        o_data            OUT pk_types.cursor_type,
        o_notes_texts     OUT pk_types.cursor_type,
        o_addendums       OUT pk_types.cursor_type,
        o_id_sys_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error           OUT t_error_out
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

    FUNCTION set_pn_free_text
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_pn_area    IN pn_area.internal_name%TYPE,
        i_dt_pn_date IN table_varchar,
        i_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_pn_note    IN table_clob,
        o_id_epis_pn OUT epis_pn.id_epis_pn%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    ---
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

    FUNCTION get_doc_status_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
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
        i_id_doc_area     IN doc_area.id_doc_area%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a selection list  with the attending physicians names that took patient
    * responsability along the episode.
    *
    * @param i_lang         language identifier
    * @param i_prof         profissional
    * @param i_id_episode   id of current episode
    * @param o_sql          cursor returning list of attending professionals
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Carlos Ferreira
    * @version              2.7.2
    * @since                2017/11/15
    */
    FUNCTION get_epis_att_profs
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER,
        o_sql        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * submit for review of progress note
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
    FUNCTION set_submit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /****************************************************************************
    ****************************************************************************/
    FUNCTION set_submit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_submit_reason IN epis_pn.id_submit_reason%TYPE,
        i_notes_submit     IN epis_pn.notes_submit%TYPE,
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

    /******************************************************************************
    ******************************************************************************/
    FUNCTION get_iss_diag_validation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
        i_check_origin IN VARCHAR2 DEFAULT 'N', -- N: Submit in note; A: Submit in action
        o_return_flag  OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    ******************************************************************************/
    FUNCTION get_iss_diag_val_params
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_return_flag     IN VARCHAR2,
        o_msg_box_desc    OUT VARCHAR2,
        o_msg_box_options OUT pk_types.cursor_type,
        o_include_reasons OUT VARCHAR2, -- Y/N
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    * Set the comments for some note
    *
    * @param  i_lang                  IN   language.id_language%TYPE                   Language id
    * @param  i_prof                  IN   profissional                                Professional structure
    * @param  i_id_epis_pn            IN   epis_pn.id_epis_pn%TYPE                     Note id
    * @param  i_id_epis_pn_addendum   IN   epis_pn_addendum.id_epis_pn_addendum%TYPE   Comment id
    * @param  i_pn_addendum           IN   epis_pn_addendum.pn_addendum%TYPE           Comment text
    * @param  o_epis_pn_addendum      OUT  epis_pn_addendum.id_epis_pn_addendum%TYPE   Comment id
    * @param  o_error                 OUT  t_error_out
    *
    * @return   BOOLEAN   TRUE if succeeds, FALSE otherwise
    *
    * @author   rui.mendonca
    * @version  2.7.2.2
    * @since    14/12/2017
    ***************************************************************************************************************/
    FUNCTION set_pn_comments
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_pn_addendum         IN epis_pn_addendum.pn_addendum%TYPE,
        o_epis_pn_addendum    OUT epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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

    /******************************************************************************
    ******************************************************************************/
    FUNCTION get_note_review_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ids_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_current_details  OUT CLOB,
        o_previous_details OUT CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get all note list
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_area                   pn_area
    * @param i_id_episode             Episode ID
    * @param i_begin_date             Get note list begin date
    * @param i_end_date               Get note list end date
    *
    * @param o_note_lists             cursor with all note in current week
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_all_note_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_area       IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE, --CALERT-1265
        i_begin_date IN VARCHAR2, --CALERT-1265
        i_end_date   IN VARCHAR2, --CALERT-1265
        o_note_lists OUT pk_types.cursor_type,
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
        i_current_date          IN VARCHAR2 DEFAULT NULL,
        o_calendar_period       OUT VARCHAR2,
        o_begin_date            OUT VARCHAR2,
        o_end_date              OUT VARCHAR2,
        o_current_date_num      OUT NUMBER,
        o_calendar_dates        OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_area                   pn_area
    * @param i_id_episode             Episode ID
    * @param i_begin_date             Get note list begin date
    * @param i_end_date               Get note list end date
    *
    * @param o_notes                  All note summary
    * @param o_notes_det              All note detail
    * @param o_area_configs           For cancle reason
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_calendar_view_note
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_area         IN VARCHAR2,
        i_id_episode   IN episode.id_episode%TYPE,
        i_begin_date   IN VARCHAR2,
        i_end_date     IN VARCHAR2,
        o_notes        OUT pk_types.cursor_type,
        o_notes_det    OUT pk_types.cursor_type,
        o_area_configs OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the notes to the summary grid.
    * Base on original get_work_notes_core and create one input parameter 
    * for calendar view
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             episode identifier
    * @param i_id_epis_pn_work        Note identifier
    * @param i_id_pn_note_type        Note type id. 3-Progress Note; 4-Prolonged Progress Note; 5-Intensive Care Note; 2-History and Physician Note
    * @param i_flg_definitive         Save PN in the definitive model (Y- YES, N- NO)
    * @param i_id_epis_pn_det_task    Task Ids that have to be syncronized
    * @param i_id_pn_soap_block       Soap block id
    * @param o_data                   notes data
    * @param o_text_blocks            Texts that compose the note
    * @param o_text_comments          Comments cursor
    * @param o_suggested              Texts that compose the note with the suggested records
    * @param o_configs                Dynamic configs: flg_import_available; flg_editable
    * @param o_data_blocks            Dynamic data blocks (date data blocks)
    * @param o_buttons                Dynamic buttons (template records)
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author  Amanda Lee
    * @version 2.7.2
    * @since   12-18-2017
    **************************************************************************/
    FUNCTION get_work_notes_core
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_pn_work     IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type     IN epis_pn.id_pn_note_type%TYPE,
        i_flg_definitive      IN VARCHAR2,
        i_id_epis_pn_det_task IN table_number,
        i_id_pn_soap_block    IN table_number,
        i_dt_proposed         IN VARCHAR2,
        o_data                OUT pk_types.cursor_type,
        o_text_blocks         OUT pk_types.cursor_type,
        o_text_comments       OUT pk_types.cursor_type,
        o_suggested           OUT pk_types.cursor_type,
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
    * Update all data block's content for a PN. If the data doesn't exists yet, the record will be created.
    * the IN parameter Type allow for select if append or update should be done to the text.
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_episode              Episode ID
    * @param   i_epis_pn              Progress note ID
    * @param   i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note
    * @param   i_flg_action           C-Create; U-update
    * @param   i_dt_pn_date           Progress Note date Array
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
    *                                 Identified by id_task (id_analysis/id_exam) + i_id_task_aggregator
    * @param   i_dt_task              Task dates
    * @param   i_id_task_parent       Parent task identifier for comments functionality
    * @param   i_flg_task_parent      Flag tells where i_id_task_parent is a taskid or id_epis_pn_det_task
    * @param   i_id_multichoice       Array of tasks identifiers for cases that have more than one parameter (multichoice on exam results)
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
    ***************************************************************************/
    FUNCTION set_all_data_block_work
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_pn            IN epis_pn.id_epis_pn%TYPE,
        i_area               IN VARCHAR2,
        i_flg_action         IN VARCHAR2,
        i_flg_definitive     IN VARCHAR2,
        i_dt_pn_date         IN table_varchar,
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
        i_dt_proposed        IN VARCHAR2 DEFAULT NULL, --CALERT-1265
        o_id_epis_pn         OUT epis_pn.id_epis_pn%TYPE,
        o_flg_reload         OUT VARCHAR2,
        o_dt_finished        OUT VARCHAR2,
        o_error              OUT t_error_out
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
        o_scores          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summ_sections_exclude
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_doc_category IN doc_category.id_doc_category%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_prog_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_pn         IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area               IN VARCHAR2,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_scope          IN VARCHAR2,
        i_search             IN VARCHAR2,
        i_filter             IN VARCHAR2,
        i_start_record       IN NUMBER,
        i_num_records        IN NUMBER,
        i_request            IN NUMBER,
        o_data               OUT pk_types.cursor_type,
        o_notes_texts        OUT pk_types.cursor_type,
        o_addendums          OUT pk_types.cursor_type,
        o_comments           OUT pk_types.cursor_type,
        o_area_configs       OUT NOCOPY pk_types.cursor_type,
        o_doc_reg            OUT NOCOPY pk_types.cursor_type,
        o_doc_val            OUT NOCOPY pk_types.cursor_type,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_flg_is_arabic_note OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_prog_notes_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area        IN pn_area.internal_name%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_flg_scope   IN VARCHAR2,
        i_search      IN VARCHAR2,
        i_filter      IN VARCHAR2,
        i_request     IN NUMBER,
        o_num_epis_pn OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ux_progress_notes;
/
