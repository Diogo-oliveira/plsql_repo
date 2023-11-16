CREATE OR REPLACE PACKAGE pk_progress_notes IS

    -- type flags for free text data blocks
    g_type_reason_visit   CONSTANT epis_anamnesis.flg_type%TYPE := 'C';
    g_type_subjective     CONSTANT epis_recomend.flg_type%TYPE := 'S';
    g_type_objective      CONSTANT epis_recomend.flg_type%TYPE := 'B';
    g_type_assessment     CONSTANT epis_recomend.flg_type%TYPE := 'A';
    g_type_plan           CONSTANT epis_recomend.flg_type%TYPE := 'L';
    g_type_user_defined   CONSTANT VARCHAR2(1 CHAR) := 'U';
    g_context_single_page CONSTANT VARCHAR2(2 CHAR) := 'SP';

    g_dictation_area_plan CONSTANT dictation_report.id_work_type%TYPE := 10;

    g_config_def_diag_type CONSTANT sys_config.id_sys_config%TYPE := 'PROGRESS_NOTES_DEFAULT_DIAGNOSE_CODING';
    g_config_exc_diag_type CONSTANT sys_config.id_sys_config%TYPE := 'PROGRESS_NOTES_NURSE_EXCLUDE_DIAG_TYPE';
    g_config_edit_app_type CONSTANT sys_config.id_sys_config%TYPE := 'PROGRESS_NOTES_EDIT_TYPE_APPOINTMENT';
    g_config_default_it    CONSTANT sys_config.id_sys_config%TYPE := 'PROGRESS_NOTES_DEFAULT_IT';
    g_config_sign_mode     CONSTANT sys_config.id_sys_config%TYPE := 'PROGRESS_NOTES_SIGNATURE_MODE';

    /**
    * Get the episode's current DEP_CLIN_SERV identifier.
    *
    * @param i_episode      episode identifier
    *
    * @return               DEP_CLIN_SERV identifier
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/21
    */
    FUNCTION get_dep_clin_serv(i_episode IN epis_info.id_episode%TYPE) RETURN epis_info.id_dep_clin_serv%TYPE;

    /**
    * Get record signature, integrating Progress notes signature mode.
    * Similar to PK_TOOLS.GET_PROF_DESCRIPTION.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_id      professional identifier
    * @param i_date         record date
    * @param i_episode      episode identifier
    *
    * @return               reported by flag
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/10
    */
    FUNCTION get_signature
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN pk_translation.t_desc_translation;

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
    * Retrieve all vital sign and monitorization records for the given episode.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_order        'N' to order by name, 'D' to order by date
    * @param o_enc_info     cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.7
    * @since                2010/01/06
    */
    FUNCTION get_epis_vs_all
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_order   IN VARCHAR2,
        o_vs_data OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Turns a collection of INFO into a TABLE_VARCHAR.
    *
    * @param i_info_coll    INFO collection
    *
    * @return               TABLE_VARCHAR
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/15
    */
    FUNCTION get_table_varchar(i_info_coll IN table_info) RETURN table_varchar;

    /**
    * Gets the descriptions of a collection of INFO into a TABLE_VARCHAR.
    *
    * @param i_info_coll    INFO collection
    *
    * @return               TABLE_VARCHAR
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/09
    */
    FUNCTION get_info_desc(i_info_coll IN table_info) RETURN table_varchar;

    /**
    * Gets the identifiers of a collection of INFO into a TABLE_NUMBER.
    *
    * @param i_info_coll    INFO collection
    *
    * @return               TABLE_NUMBER
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/09
    */
    FUNCTION get_info_id(i_info_coll IN table_info) RETURN table_number;

    /**
    * Concatenates INFO collection descriptions.
    *
    * @param i_info_coll    INFO collection
    *
    * @return               concatenated descriptions
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/15
    */
    FUNCTION get_desc_concat(i_info_coll IN table_info) RETURN VARCHAR2;

    /**
    * Get epis_complaint record coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_ec        episode complaint identifier
    *
    * @return               coding collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_coding_ec
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_id_ec IN epis_complaint.id_epis_complaint%TYPE
    ) RETURN table_info;

    /**
    * Get epis_anamnesis record coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_ea        episode anamnesis identifier
    *
    * @return               coding collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_coding_ea
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_id_ea IN epis_anamnesis.id_epis_anamnesis%TYPE
    ) RETURN table_info;

    /**
    * Get epis_recomend record coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_er        episode recomend identifier
    *
    * @return               coding collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_coding_er
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_id_er IN epis_recomend.id_epis_recomend%TYPE
    ) RETURN table_info;

    /**
    * Get epis_prog_notes record coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_epn       episode progress notes identifier
    *
    * @return               coding collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_coding_epn
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_epn IN epis_prog_notes.id_epis_prog_notes%TYPE
    ) RETURN table_info;

    /**
    * Checks of a clinical service has "children".
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_clin_serv    parent type of appointment identifier
    *
    * @return               'Y' if "children" exist, 'N' otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION exist_dcs_child
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_clin_serv IN clinical_service.id_clinical_service_parent%TYPE
    ) RETURN VARCHAR2;

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
    * @since                2010/09/28
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
        o_complaints OUT t_tbl_complaint,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get epis_complaint record complaints.
    *
    * @param i_lang         language identifier
    * @param i_id_ec        epis_complaint record identifier
    *
    * @return               complaints collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_complaints_ec
    (
        i_lang  IN language.id_language%TYPE,
        i_id_ec IN epis_complaint.id_epis_complaint%TYPE
    ) RETURN table_info;

    /**
    * Get list of free text records.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_blk_info     blocks to retrieve records from
    * @param o_free_text    cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_free_text
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_blk_info  IN t_coll_soap_block,
        o_free_text OUT pk_types.cursor_type,
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
    * Get list of reason for visit records.
    * Used in pk_prev_encounter.
    *
    * @param i_lang         language identifier
    * @param i_episode      episode identifier
    * @param o_rea_visit    cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_reason_for_visit
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        o_rea_visit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Internal function to open o_rea_visit.
    * Used in the reports layer as well.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_show_block   show reason for visit block? Y/N
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
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_show_block     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_show_cancelled IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_rea_visit      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get list of reason for visit records.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_blk_info     blocks to retrieve records from
    * @param o_rea_visit    cursor
    * @param o_app_type     cursor
    * @param o_prof_rec     author and date of last change
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_reason_for_visit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_blk_info  IN t_coll_soap_block,
        o_rea_visit OUT pk_types.cursor_type,
        o_app_type  OUT pk_types.cursor_type,
        o_prof_rec  OUT pk_translation.t_desc_translation,
        o_error     OUT t_error_out
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

    /**
    * Returns the template id associated to a single page note type.
    *
    * @param i_lang         language identifier
    * @param i_id_episode   episode id
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
    * Updates episode templates.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_id_ec        episode complaint root identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/10
    */
    PROCEDURE set_templates
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_id_ec   IN epis_complaint.id_epis_complaint%TYPE,
        o_error   OUT t_error_out
    );

END pk_progress_notes;
/
