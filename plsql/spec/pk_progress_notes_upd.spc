/*-- Last Change Revision: $Rev: 2015583 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-05-31 16:22:18 +0100 (ter, 31 mai 2022) $*/

CREATE OR REPLACE PACKAGE pk_progress_notes_upd IS

    -- Author  : PEDRO.TEIXEIRA
    -- Created : 15-09-2010 14:56:53
    -- Purpose : Handle progress notes functionality restructuration

    /**
    * Reset session context variables.
    *
    * @param i_prof             logged professional structure
    * @param i_episode          episode identifier
    * @param i_id_pn_note_type  soap note type
    * @param i_epis_pn          soap note identifier
    * @param i_id_dep_clin_serv Dep clin serv id
    *
    * @author                   Sofia Mendes
    * @version                  2.6.2.2
    * @since                    18-Jun-2012
    */
    FUNCTION reset_ctx
    (
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN pk_prog_notes_types.t_configs_ctx;

    /********************************************************************************************
    * returns profile_template permissions for a given area
    *
    * @param IN   i_lang           Language ID
    * @param IN   i_prof           Professional ID
    * @param IN   i_doc_area       Doc Area
    *
    * @param OUT  o_flg_write      Flg Write
    * @param OUT  o_flg_no_changes Flg No Changes
    *
    * @author                      Pedro Teixeira
    * @since                       01/10/2010
    ********************************************************************************************/
    FUNCTION get_doc_area_permissions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_flg_write      OUT summary_page_access.flg_write%TYPE,
        o_flg_no_changes OUT summary_page_access.flg_no_changes%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Internal function for template retrieval.
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_patient           patient identifier
    * @param i_episode           episode identifier
    * @param i_doc_area_desc     documentation area internal description
    * @param o_doc_reg           documentation register data
    * @param o_doc_val           documentation values
    * @param o_error             error
    *
    * @author                    Pedro Carneiro
    * @version                    2.5.0.7
    * @since                     2009/11/03
    ********************************************************************************************/
    PROCEDURE get_templates
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area_desc      IN VARCHAR2,
        o_doc_reg            OUT pk_types.cursor_type,
        o_doc_val            OUT pk_types.cursor_type,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_error              OUT t_error_out
    );

    /********************************************************************************************
    * calculate flag values
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_doc_area        Doc Area
    * @param IN   i_flg_status      Flag Status
    * @param IN   i_professional    Record Professional
    * @param IN   i_data_area       Data Area
    *
    * @param OUT  o_flg_write       flg write
    * @param OUT  o_flg_cancel      flg cancel
    * @param OUT  o_flg_no_changes  flg no changes
    * @param OUT  o_flg_mode        flg mode
    * @param OUT  o_flg_switch_mode flg switch mode
    *
    * @author                       Pedro Teixeira
    * @since                        01/10/2010
    ********************************************************************************************/
    FUNCTION get_flags_permission
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_flg_status      IN epis_documentation.flg_status%TYPE,
        i_professional    IN professional.id_professional%TYPE,
        i_flg_origin      IN VARCHAR2,
        i_data_area       IN pn_data_block.data_area%TYPE,
        o_flg_write       OUT summary_page_access.flg_write%TYPE,
        o_flg_cancel      OUT summary_page_access.flg_write%TYPE,
        o_flg_no_changes  OUT summary_page_access.flg_no_changes%TYPE,
        o_flg_mode        OUT VARCHAR2,
        o_flg_switch_mode OUT VARCHAR2
    ) RETURN BOOLEAN;

    /**
    * Get application file name.
    *
    * @param i_app_file     application file identifier
    *
    * @return               file name (with extension)
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/25
    */
    FUNCTION get_app_file(i_app_file IN application_file.id_application_file%TYPE) RETURN application_file.file_name%TYPE;

    /**
    * Get free text data block information.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soap_block   free text data block identifier
    *
    * @return               free text data block info
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/13
    */
    FUNCTION get_freetext_block_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN t_rec_soap_block;

    /**
    * Get free text data block information.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_soap_block   free text data block info
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Teixeira
    * @version               2.6.0.4
    * @since                2010/10/26
    */
    FUNCTION get_freetext_block_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_soap_block OUT t_coll_soap_block,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get block sample text
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_sample_text Code sample text
    *
    * @return                   table with sample text structure
    *
    * @author                   Pedro Teixeira
    * @since                    19/10/2010
    ********************************************************************************************/
    FUNCTION get_block_sample_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_sample_text IN pn_soap_block.sample_text_code%TYPE
    ) RETURN table_varchar;

    /**
    * Can this profile edit the free text field? Y/N
    *
    * @param i_prof         logged professional structure
    * @param i_profile      logged professional profile
    * @param i_category     logged professional category
    * @param i_market       market identifier
    * @param i_data_block   data block identifier
    *
    * @return               'Y' has write access, 'N' doesn't
    *
    * @author               Pedro Teixeira
    * @version               2.6.0.4
    * @since                2010/11/26
    */
    FUNCTION get_prof_freetext_permission
    (
        i_prof       IN profissional,
        i_profile    IN profile_template.id_profile_template%TYPE,
        i_category   IN category.id_category%TYPE,
        i_market     IN market.id_market%TYPE,
        i_data_block IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN pn_free_text_mkt.flg_write%TYPE;

    /********************************************************************************************
    * get professional approach (S: SOAP; D: Default) -> to be passed to PK_ACCESS
    *
    * @param IN   i_prof        Professional ID
    *
    * @return                   Flag Approach
    *
    * @author                   Pedro Teixeira
    * @since                    30/11/2010
    ********************************************************************************************/
    FUNCTION get_prof_approach(i_prof IN profissional) RETURN profile_template.flg_approach%TYPE;

    /**
    * Get data block "mandatory" description.
    *
    * @param flg_mandatory     data block mandatory flag
    *
    * @return               data block "mandatory" description
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/02/15
    */
    FUNCTION get_mandatory_desc(i_flg_mandatory IN pn_dblock_mkt.flg_mandatory%TYPE) RETURN VARCHAR2;

    /**
    * Get the current soap note ID_CONTEXT_2 identifier.
    * This is to be used as an additional filter when searching for templates.
    *
    * @return               current soap note ID_CONTEXT_2 identifier
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/02/16
    */
    FUNCTION get_soap_note RETURN doc_template_context.id_context_2%TYPE;

    /**
    * Get the number of immediate children of a button.
    *
    * @param i_button       button identifier
    * @param i_pn_soap_block soap block identifier
    *
    * @return               number of children
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/02/24
    */
    FUNCTION get_child_count
    (
        i_button        IN conf_button_block.id_conf_button_block%TYPE,
        i_pn_soap_block pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN PLS_INTEGER;

    /********************************************************************************************
    * returns the soap block information for reports
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_soap_blocks Main cursor with SOAP Blocks
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

    /********************************************************************************************
    * returns the soap block associated with the institution / software / clinical_service
    *
    * @param IN   i_lang          Language ID
    * @param IN   i_prof          Professional ID
    * @param IN   i_patient       Patient ID
    * @param IN   i_episode       Espisode ID
    * @param OUT  o_soap_blocks   Main cursor with SOAP Blocks
    * @param OUT  o_data_blocks   Data blocks
    * @param OUT  o_button_blocks Button Blocks with button configuration
    * @param OUT  o_simple_text   Simple Text blocks structure
    * @param OUT  o_doc_reg       Doccumentation registers
    * @param OUT  o_doc_val       Doccumentation registers values
    * @param OUT  o_free_text     Free text records cursor
    * @param OUT  o_rea_visit     Reason for visit records cursor
    * @param OUT  o_app_type      Appointment type records cursor
    * @param OUT  o_prof_rec      Author and date of last change
    * @param OUT  o_error         Error structure
    *
    * @author                     Pedro Teixeira
    * @since                      21/09/2010
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

    /********************************************************************************************
    * returns the soap block associated with the institution / software / clinical_service, without buttons
    *
    * @param IN   i_lang          Language ID
    * @param IN   i_prof          Professional ID
    * @param IN   i_patient       Patient ID
    * @param IN   i_episode       Espisode ID
    * @param OUT  o_soap_blocks   Main cursor with SOAP Blocks
    * @param OUT  o_data_blocks   Data blocks
    * @param OUT  o_simple_text   Simple Text blocks structure
    * @param OUT  o_doc_reg       Doccumentation registers
    * @param OUT  o_doc_val       Doccumentation registers values
    * @param OUT  o_free_text     Free text records cursor
    * @param OUT  o_rea_visit     Reason for visit records cursor
    * @param OUT  o_app_type      Appointment type records cursor
    * @param OUT  o_prof_rec      Author and date of last change
    * @param OUT  o_error         Error structure
    *
    * @author                     Pedro Carneiro
    * @since                      20/12/2010
    ********************************************************************************************/
    FUNCTION get_prog_notes_blocks_no_btn
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_soap_blocks OUT pk_types.cursor_type,
        o_data_blocks OUT pk_types.cursor_type,
        o_simple_text OUT pk_types.cursor_type,
        o_doc_reg     OUT pk_types.cursor_type,
        o_doc_val     OUT pk_types.cursor_type,
        o_free_text   OUT pk_types.cursor_type,
        o_rea_visit   OUT pk_types.cursor_type,
        o_app_type    OUT pk_types.cursor_type,
        o_prof_rec    OUT pk_translation.t_desc_translation,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns SOAP Blocks
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     patient identifier
    * @param IN   i_retrieve_st retrieve predefined texts? Y/N
    * @param IN   i_trans_dn    translate deepnav titles? Y/N
    * @param OUT  o_soap_blocks Main cursor with SOAP Blocks
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_soap_blocks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_retrieve_st IN VARCHAR2,
        i_trans_dn    IN VARCHAR2,
        i_filter_search IN table_varchar DEFAULT NULL,
        o_blocks      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get values parametrizations for a Data Block Area Type to define on KeyPad's
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_SCOPE                 Scope Identifier (for E-Episode Identifier, for V-Visit Identifier and for P-Patient Identifier
    * @param         I_SCOPE_TYPE            Scope type
    * @param         I_DBLOCKS               Data Blocks structure
    *
    * @value         I_SCOPE_TYPE            {*} 'E'- Episode {*} 'V'- Visit {*} 'P'- Patient
    *
    * @return                                A table function with the parametrizations by Data Block Area Type
    *
    * @author                                António Neto
    * @since                                 13-Feb-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION tf_keypad_param
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_dblocks    IN t_coll_dblock,
        i_task_types  IN t_coll_dblock_task_type,
		i_dt_purposed IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN t_coll_keypad_param;

    /********************************************************************************************
    * returns data blocks
    *
    * @param IN   i_lang          Language ID
    * @param IN   i_prof          Professional ID
    * @param IN   i_patient       Patient ID
    * @param IN   i_episode       Espisode ID
    * @param OUT  o_data_blocks   Data blocks
    * @param OUT  o_simple_text   Simple Text blocks structure
    * @param OUT  o_doc_reg       Doccumentation registers
    * @param OUT  o_doc_val       Doccumentation registers values
    * @param OUT  o_error         Error structure
    *
    * @author                     Pedro Teixeira
    * @since                      17/09/2010
    ********************************************************************************************/
    FUNCTION get_data_blocks
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_soap_list          IN tab_soap_blocks,
        o_data_blocks        OUT pk_types.cursor_type,
        o_simple_text        OUT pk_types.cursor_type,
        o_doc_reg            OUT pk_types.cursor_type,
        o_doc_val            OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns associated blocks
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_free_text   Free text records cursor
    * @param OUT  o_rea_visit   Reason for visit records cursor
    * @param OUT  o_app_type    Appointment type records cursor
    * @param OUT  o_prof_rec    Author and date of last change
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_assoc_blocks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_soap_list IN tab_soap_blocks,
        o_free_text OUT pk_types.cursor_type,
        o_rea_visit OUT pk_types.cursor_type,
        o_app_type  OUT pk_types.cursor_type,
        o_prof_rec  OUT pk_translation.t_desc_translation,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the button blocks associated with SOAP Blocks List
    *
    * @param IN   i_lang          Language ID
    * @param IN   i_prof          Professional ID
    * @param IN   i_patient       Patient ID
    * @param IN   i_episode       Espisode ID
    * @param IN   i_soap_list     List of SOAP Block ID's
    *
    * @param OUT  o_button_blocks Button blocks structure
    * @param OUT  o_error         Error structure
    *
    * @author                     Pedro Teixeira
    * @since                      17/09/2010
    ********************************************************************************************/
    FUNCTION get_button_blocks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_soap_list     IN tab_soap_blocks,
        o_button_blocks OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks based on the data_area
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    * @param IN   i_data_area   Data Area list to retrieve associated simple text blocks
    *
    * @param OUT  o_simple_text Simple Text blocks structure
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_block_simple_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_data_area   IN table_varchar,
        o_simple_text OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns documentation blocks based on the data_area
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    * @param IN   i_data_area   Data Area list to retrieve associated documentation blocks
    *
    * @param OUT  o_doc_reg     Doccumentation registers
    * @param OUT  o_doc_val     Doccumentation registers values
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_block_documentation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_data_area          IN table_varchar,
        o_doc_reg            OUT pk_types.cursor_type,
        o_doc_val            OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for medication
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_rm -- Reported Medication
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for Vital Signs
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_vs -- Vital Signs
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for Exams
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_e -- Exams
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for Analysis
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_a -- Analysis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for Problems
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_p -- Problems
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for Diagnosis
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_d -- Diagnosis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for Medication for Current Episode
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_mce -- Medication for Current Episode
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for medication
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_me -- Reported Medication
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for Guidelines and Protocols
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_gp -- Guidelines and Protocols
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    
    /**
    * Returns the CITS: Medical disability certificate information.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_simple_text  block data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.3.6
    * @since                01-06-2013
    */
    FUNCTION get_simpletext_ct
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for Patient Instructions
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_pi -- Patient Instructions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for Means for Complementary Diagnosis
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_mcd -- Means for Complementary Diagnosis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns simple text blocks for Dictaphone
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_di -- Dictaphone
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns dictaphone simple text block data (long version).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_simple_text  block data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/11
    */
    FUNCTION get_simpletext_dih
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns schedule reason simple text block data.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_simple_text  block data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.8.4
    * @since                2012/06/11
    */
    FUNCTION get_simpletext_sr
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Returns schedule reason simple text block data.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_simple_text  block data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.8.4
    * @since                2012/06/11
    */
    FUNCTION get_simpletext_gn
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Get configured soap and data blocks ordered collection.
    *
    * @param i_prof         logged professional structure
    * @param i_market       market identifier
    * @param i_department   service identifier
    * @param i_dcs          service/specialty identifier
    * @param i_id_pn_note_type     Note type identifier
    * @param i_id_episode          Episode identifier
    * @param i_id_pn_data_block    Data Block Identifier
    * @param i_software          Software ID
    *
    * @return               configured soap and data blocks ordered collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/01/27
    */
    FUNCTION tf_data_blocks
    (
        i_prof             IN profissional,
        i_market           IN market.id_market%TYPE,
        i_department       IN department.id_department%TYPE,
        i_dcs              IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE DEFAULT NULL,
        i_software         IN software.id_software%TYPE,
        i_flg_search       IN table_varchar DEFAULT NULL
    ) RETURN t_coll_dblock;

    /**
    * Get configured soap and button blocks ordered collection.
    *
    * @param i_prof                logged professional structure
    * @param i_profile             logged professional profile
    * @param i_category            logged professional category
    * @param i_market              market identifier
    * @param i_department          service identifier
    * @param i_dcs                 service/specialty identifier
    * @param i_id_pn_note_type     soap note type identifier
    * @param i_software            Software ID
    *
    * @return               configured soap and button blocks ordered collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/01/27
    */
    FUNCTION tf_button_blocks
    (
        i_prof            IN profissional,
        i_profile         IN profile_template.id_profile_template%TYPE,
        i_category        IN category.id_category%TYPE,
        i_market          IN market.id_market%TYPE,
        i_department      IN department.id_department%TYPE,
        i_dcs             IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_software        IN software.id_software%TYPE
    ) RETURN t_coll_button;

    /**
    * Get configured soap blocks ordered collection.
    * Based on tf_soap_blocks, filtering by id_department and id_dep_clin_serv
    *
    * @param i_prof         logged professional structure
    * @param i_id_episode      episode identifier
    * @param i_market       market identifier
    * @param i_department   service identifier
    * @param i_dcs          service/specialty identifier
    * @param i_id_pn_note_type Note type ID
    * @param i_software          Software ID
    *
    * @return               configured soap blocks ordered collection
    *
    * @author               António Neto
    * @version              2.6.1.2
    * @since                03-Aug-2011
    */
    FUNCTION tf_sblock
    (
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_market          IN market.id_market%TYPE,
        i_department      IN department.id_department%TYPE DEFAULT NULL,
        i_dcs             IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_software        IN software.id_software%TYPE
    ) RETURN tab_soap_blocks;

    /**
    * Get soap note blocks.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_id_pn_note_type     note type identifier
    * @param i_epis_pn_work soap note identifier
    * @param o_soap_block   soap blocks cursor
    * @param o_data_block   data blocks cursor
    * @param o_button_block button blocks cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/02/14
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
    * Get importable data blocks.
    *
    * @param i_lang                language identifier
    * @param i_prof                logged professional structure
    * @param i_id_pn_note_type     note type identifier
    * @param i_flg_search          Specify the type of search: 
    *                              I: importable dta blocks
    *                              A: auto-populated and auto-syncronizable data blocks
    * @param i_dblocks_list        List of data blocks to be considered in the auto-syncronizable data blocks
    * @param i_sblocks_list        List of soap blocks to be considered in the auto-syncronizable soap blocks
    * @param i_confgs_ctx             Configs context structure  
    * @param i_id_pn_soap_block       Soap blocks ID
    * @param o_data_block          data blocks collection
    * @param o_error               error
    *
    * @return                      false if errors occur, true otherwise
    *
    * @author                      Pedro Carneiro
    * @version                     2.6.0.5.2
    * @since                       2011/02/07
    */
    FUNCTION get_import_dblocks
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_search       IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_importable_dblocks_i,
        i_dblocks_list     IN table_number DEFAULT table_number(),
        i_sblocks_list     IN table_number DEFAULT table_number(),
        i_configs_ctx      IN pk_prog_notes_types.t_configs_ctx DEFAULT NULL,
        i_id_pn_soap_block IN table_number,
        o_data_block       OUT t_coll_data_blocks,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get soap note blocks.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_id_pn_note_type     note type identifier    
    * @param i_id_epis_pn   note id
    * @param o_soap_blocks   soap blocks cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5.2
    * @since                21-Feb-2011
    */
    FUNCTION get_soap_blocks_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_soap_blocks     OUT tab_soap_blocks,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get data block type for a soap block ID
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID
    * @param i_id_pn_note_type        Note Type Identifier
    * @param i_id_pn_soap_block       Soap block ID
    * 
    * return  data block flg_type                       
    *                                                                        
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/23                               
    **************************************************************************/

    FUNCTION get_soap_blocks_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN table_varchar;

    /**
    * Returns the description of a soap block.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_soap_block       soap block identifier  
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_soap_block_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Returns the description of a soap block to the history screen: Ex. New Assessment.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_soap_block       soap block identifier  
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_soap_block_desc_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Returns the description of a data area.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_data_block       data block identifier  
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                11-Feb-2011
    */
    FUNCTION get_block_area_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Returns the description of a data area to the history. Ex. New diagnosis
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_data_block       data block identifier  
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                11-Feb-2011
    */
    FUNCTION get_block_area_desc_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Get the episode's current DEPARTMENT identifier (service).
    *
    * @param i_episode      episode identifier
    * @param i_epis_pn      note id
    *
    * @return               DEPARTMENT identifier (service).
    *
    * @author               Pedro Teixeira
    * @version               2.6.0.4
    * @since                2010/10/01
    */
    FUNCTION get_department
    (
        i_episode IN episode.id_episode%TYPE,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN episode.id_department%TYPE;

    /**
    * Get the soap note's current DEP_CLIN_SERV identifier.
    * If no soap note is specified, it gets the episode's.
    *
    * @param i_episode      episode identifier
    * @param i_epis_pn      soap note identifier
    *
    * @return               DEP_CLIN_SERV identifier
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/02/21
    */
    FUNCTION get_dep_clin_serv
    (
        i_episode IN epis_info.id_episode%TYPE,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN epis_info.id_dep_clin_serv%TYPE;

    /**
    * Returns the doc_areas list associated to the notes buttons or areas
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_data_block       data block identifier 
    *
    * @param OUT  o_doc_areas         Doc areas list
    * @param OUT  o_error             Error structure 
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                11-Feb-2011
    */
    FUNCTION get_doc_areas
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_doc_areas OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if the id_soap_block (i_search) exists in the list of soap blocks
    *
    * @param i_table                  Soap blocks info list
    * @param i_search                 Soap block id to be searched
    * @param i_id_pn_data_block       data block identifier 
    *    
    *
    * @return                        -1: soap block not found; Otherwise: index of the soap block in the given list
    *
    * @author               Sofia Mendes
    * @version               2.6.1.3
    * @since                14-Oct-2011
    */
    FUNCTION search_tab_soap_blocks
    (
        i_table  IN tab_soap_blocks,
        i_search IN NUMBER
    ) RETURN NUMBER;

    /********************************************************************************************
    * Gets the permission from EHR Access Rules
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_EPISODE            Episode Identifier
    * @param         I_ID_TL_TASK            Task Type Identifier
    * @param         I_EHR_ACCESS_AREA       EHR Access Area code
    *
    * @return                                Active (A) when having permissions to change the area. Inactive (I) otherwise
    *
    * @author                                António Neto
    * @since                                 29-Feb-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION get_ehr_access_area
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_tl_task      IN tl_task.id_tl_task%TYPE,
        i_ehr_access_area IN tl_task.ehr_access_area%TYPE,
        i_pn_group        IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the Configurations of a task type in a data block
    *
    * @param   i_lang                      Language identifier
    * @param   i_prof                      Professional Identification
    * @param   i_episode                   Episode identifier
    * @param   i_id_market                 Market identifier
    * @param   i_id_department             Service identifier
    * @param   i_id_dep_clin_serv          Service/specialty identifier
    * @param   i_id_pn_note_type           Note type ID
    * @param   i_software                  Software ID
    * @param   i_id_task_type              Task type ID
    * @param   i_id_pn_data_block          Data block ID
    * @param   i_id_pn_soap_block          Soap block ID
    *                        
    * @return                              Returns the Area Configurations related to the specified profile
    * 
    * @author                              Sofia Mendes
    * @version                             2.6.2.1
    * @since                               18-Mai-2012
    **********************************************************************************************/
    FUNCTION tf_dblock_task_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_software         IN software.id_software%TYPE,
        i_id_task_type     IN pn_dblock_ttp_mkt.id_task_type%TYPE DEFAULT NULL,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE DEFAULT NULL,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE DEFAULT NULL
    ) RETURN t_coll_dblock_task_type;

    /********************************************************************************************
    * Gets the Configurations of a task type in a data block
    *
    * @param   i_lang                      Language identifier
    * @param   i_prof                      Professional Identification
    * @param   i_episode                   Episode identifier
    * @param   io_id_department            Service identifier
    * @param   io_id_dep_clin_serv         Service/specialty identifier
    * @param   io_episode_software         Software ID associated to the episode
    *                        
    * @return                              Returns the Area Configurations related to the specified profile
    * 
    * @author                              Sofia Mendes
    * @version                             2.6.2.1
    * @since                               18-Mai-2012
    **********************************************************************************************/
    FUNCTION get_epis_vars
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        io_id_department    IN OUT department.id_department%TYPE,
        io_id_dep_clin_serv IN OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        io_episode_software IN OUT software.id_software%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get configured soap, data and button blocks ordered collections,
    * and set them in context.
    *
    * @param i_prof         logged professional structure
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/01/27
    */
    PROCEDURE get_all_blocks
    (
        i_prof         IN profissional,
        io_configs_ctx IN OUT pk_prog_notes_types.t_configs_ctx
    );

    /**
    * Get configured soap and data blocks ordered collections,
    * and set them in context.
    *
    * @param i_prof         logged professional structure
    *
    * @author               Sofia Mendes
    * @version               2.6.2
    * @since                2011/01/27
    */
    PROCEDURE get_sblocks_dblocks
    (
        i_prof         IN profissional,
        io_configs_ctx IN OUT pk_prog_notes_types.t_configs_ctx
    );

    /**
    * Open the soap data blocks cursor.    
    * Returns the dynamic data blocks only.
    *
    * @param    i_lang          Language ID
    * @param    i_prof          Professional structure identifiers
    * @param    i_episode       Espisode Identifier
    * @param    i_data_blocks   Data blocks list
    * @param    i_task_types    Task types list
    * @param    o_data_blocks   soap data blocks cursor
    *
    * @author               Sofia Mendes
    * @version               2.6.2
    * @since                01-Ock-2012
    */
    PROCEDURE get_dynamic_data_blocks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_data_blocks IN t_coll_dblock,
        i_task_types  IN t_coll_dblock_task_type,
        i_dt_purposed IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_data_blocks OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Returns the button blocks associated with SOAP Blocks List
    *
    * @param IN   i_lang          Language ID
    * @param IN   i_prof          Professional ID
    * @param IN   i_patient       Patient ID
    * @param IN   i_episode       Espisode ID
    * @param IN   i_buttons       Buttons list
    *
    * @param OUT  o_button_blocks Button blocks structure
    * @param OUT  o_error         Error structure
    *
    * @author                     Sofia Mendes
    * @since                      01-Oct-2012
    ********************************************************************************************/
    FUNCTION get_dynamic_buttons
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_market     IN market.id_market%TYPE,
        io_buttons      IN OUT t_coll_button,
        i_id_epis_pn    IN NUMBER DEFAULT NULL,
        o_button_blocks OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the button blocks associated with SOAP Blocks List
    *
    * @param IN   i_lang          Language ID
    * @param IN   i_prof          Professional ID
    * @param IN   i_patient       Patient ID
    * @param IN   i_episode       Espisode ID
    * @param IN   i_soap_list     List of SOAP Block ID's
    *
    * @param OUT  o_button_blocks Button blocks structure
    * @param OUT  o_error         Error structure
    *
    * @author                     Sofia Mendes
    * @since                      01-Oct-2012
    ********************************************************************************************/
    FUNCTION get_static_buttons
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_buttons       IN t_coll_button,
        o_button_blocks OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    
    /**
    * Check if a button should be active or inactive
    *
    * @param i_lang               language ID
    * @param i_prof               professional info
    * @param i_id_episode         episode ID
    * @param i_id_visit           visit ID
    * @param i_id_patient         patient ID
    * @param i_id_pn_task_type    Task type ID
    * @param i_flg_activation      Flag to indicate if some rule should be applied
    *
    * @return                         id_prof_signoff
    *
    * @author               Sofia Mendes
    * @version               2.6.3.6
    * @since               8-Jul-2013
    */
    FUNCTION check_button_active
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_visit        IN visit.id_visit%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_pn_task_type IN tl_task.id_tl_task%TYPE,
        i_flg_activation  IN pn_button_mkt.flg_activation%TYPE,
        i_doc_area        IN doc_area.id_doc_area%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Check if shortcuts button shoud be available for the soap block
    *
    * @param i_lang             language ID
    * @param i_prof             professional
    * @param i_pn_soap_block    Task type ID
    *
    * @return                   Y/N
    *
    * @author                   Vanessa Barsottelli
    * @version                  2.6.4,1
    * @since                    01-Jul-2014
    */
    FUNCTION get_soap_shortcuts_available
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_datepad_param
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_value  IN VARCHAR2,
        i_days_period IN NUMBER,
        i_id_episode IN NUMBER,
        i_dt_purposed IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_format     OUT VARCHAR2,
        o_value      OUT VARCHAR2
    ) RETURN BOOLEAN;
    
    --********************************************************************************************
    --********************************************************************************************
    ---------
    g_yes           CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no            CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_flg_cancel    CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_soap_approach CONSTANT profile_template.flg_approach%TYPE := 'S';

    ---------
    g_soap_block_contact_reas CONSTANT pn_soap_block.flg_type%TYPE := 'C';
    g_soap_block_subjective   CONSTANT pn_soap_block.flg_type%TYPE := 'S';
    g_soap_block_objective    CONSTANT pn_soap_block.flg_type%TYPE := 'B';
    g_soap_block_avaliation   CONSTANT pn_soap_block.flg_type%TYPE := 'A';
    g_soap_block_plan         CONSTANT pn_soap_block.flg_type%TYPE := 'L';
    g_soap_block_unclassified CONSTANT pn_soap_block.flg_type%TYPE := 'U';

    --------- simple text
    g_simpletext_rm  CONSTANT pn_data_block.data_area%TYPE := 'RM'; -- Reported Medication
    g_simpletext_a   CONSTANT pn_data_block.data_area%TYPE := 'A'; -- Analysis
    g_simpletext_e   CONSTANT pn_data_block.data_area%TYPE := 'E'; -- Exams
    g_simpletext_vs  CONSTANT pn_data_block.data_area%TYPE := 'VS'; -- Vital Signs
    g_simpletext_p   CONSTANT pn_data_block.data_area%TYPE := 'P'; -- Problems
    g_simpletext_d   CONSTANT pn_data_block.data_area%TYPE := 'D'; -- Diagnosis
    g_simpletext_mce CONSTANT pn_data_block.data_area%TYPE := 'MCE'; -- Medication for Current Episode
    g_simpletext_me  CONSTANT pn_data_block.data_area%TYPE := 'ME'; -- Medication for Exterior
    g_simpletext_gp  CONSTANT pn_data_block.data_area%TYPE := 'GP'; -- Guidelines and Protocols
    g_simpletext_cp  CONSTANT pn_data_block.data_area%TYPE := 'CP'; -- Care Plans
    g_simpletext_pi  CONSTANT pn_data_block.data_area%TYPE := 'PI'; -- Patient Instructions
    g_simpletext_mcd CONSTANT pn_data_block.data_area%TYPE := 'MCD'; -- Means for Complementary Diagnosis
    g_simpletext_di  CONSTANT pn_data_block.data_area%TYPE := 'DI'; -- Means for Complementary Diagnosis
    g_simpletext_sr  CONSTANT pn_data_block.data_area%TYPE := 'SCH_R'; -- Schedule reason
    g_simpletext_gn  CONSTANT pn_data_block.data_area%TYPE := 'GN'; -- Schedule reason
    g_simpletext_ct  CONSTANT pn_data_block.data_area%TYPE := 'CT'; -- CITS: Medical disability certificate

    g_di_shortcut CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 619100; -- Shortcut para á²¥a dictafone

    --------- documentation
    g_documentation_hpi CONSTANT pn_data_block.data_area%TYPE := 'HPI'; -- History of Present Illness
    g_documentation_rs  CONSTANT pn_data_block.data_area%TYPE := 'RS'; -- Review of Systems
    g_documentation_pe  CONSTANT pn_data_block.data_area%TYPE := 'PE'; -- Physical Exam
    g_documentation_pa  CONSTANT pn_data_block.data_area%TYPE := 'PA'; -- Physical Assessment
    g_documentation_oe  CONSTANT pn_data_block.data_area%TYPE := 'OE'; -- Ophthalmological Exam
    g_documentation_gpa CONSTANT pn_data_block.data_area%TYPE := 'GPA'; -- General Pediatric Assessment
    g_documentation_at  CONSTANT pn_data_block.data_area%TYPE := 'AT'; -- Assessment Tools
    g_documentation_pl  CONSTANT pn_data_block.data_area%TYPE := 'PL'; -- Plan

    --------- conf button actions
    g_button_action_load_screen  CONSTANT conf_button_block.action%TYPE := 'S';
    g_button_action_screen_tmpl  CONSTANT conf_button_block.action%TYPE := 'NS';
    g_button_action_new_templ    CONSTANT conf_button_block.action%TYPE := 'N';
    g_button_action_search_templ CONSTANT conf_button_block.action%TYPE := 'A';
    g_button_action_shortcut     CONSTANT conf_button_block.action%TYPE := 'T';
    g_button_action_codification CONSTANT conf_button_block.action%TYPE := 'C';
    g_button_action_document     CONSTANT conf_button_block.action%TYPE := 'D';
    g_button_action_sub_menu     CONSTANT conf_button_block.action%TYPE := 'M';
    g_button_action_external_app CONSTANT conf_button_block.action%TYPE := 'L';
    g_button_action_root         CONSTANT conf_button_block.action%TYPE := 'R';
    g_button_action_static_templ CONSTANT conf_button_block.action%TYPE := 'E';
    g_button_action_static_doc_cat CONSTANT conf_button_block.action%TYPE := 'SC';

    -- get templates of areas via progress notes
    FUNCTION get_epis_pn_doc_template
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_epis_pn IN NUMBER
    ) RETURN t_coll_template;
    -- get specific template for an intervention via progress notes
    FUNCTION get_interv_template
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_epis_pn IN NUMBER
    ) RETURN t_coll_template;

    FUNCTION union_distinct_coll_template
    (
        i_tbl1 IN t_coll_template,
        i_tbl2 IN t_coll_template
    ) RETURN t_coll_template;

END pk_progress_notes_upd;
/
