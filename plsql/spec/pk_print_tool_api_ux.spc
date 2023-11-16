/*-- Last Change Revision: $Rev: 2046329 $*/
/*-- Last Change by: $Author: andre.silva $*/
/*-- Date of last change: $Date: 2022-09-28 16:54:58 +0100 (qua, 28 set 2022) $*/

CREATE OR REPLACE PACKAGE pk_print_tool_api_ux AS

    /**
    * Overload function to allow showing or not the virtual sections. Used by Reports (java) only.
    *
    * @param   I_EPISODE            ID do episódio
    * @param   I_PATIENT            ID do paciente
    * @param   I_REPORTS            ID do report que é um grupo
    *
    * @param   O_SECTION            Array com a lista de secções do report
    * @param   O_ERROR              Descrição do erro
    *
    * @param i_lang language id
    * @param i_prof professional type
    * @param i_episode episode's ID
    * @param i_reports report's ID array
    * @param i_show_visible flag indicating whether virtual sections should also be returned ('A' = All, 'Y' = Visible, 'N' = Invisible)
    *
    * @param o_section cursor with section information
    * @param o_error error message
    *
    * @return true (success), false (error)
    *
    * @author Gonçalo Almeida, 2011/May/19
    * @version 2.6.1.0.2
    * @since 2011/May/19
    */
    FUNCTION get_invisible_section_list_rep
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_reports            IN reports.id_reports%TYPE,
        i_section_visibility IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_section            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets some metadata about the report sections.
    *
    * @param i_lang language id
    * @param i_prof professional type
    * @param i_epis_report generated report id
    * @param i_id_rep_section table of section id
    * @param i_cardinality section table of records number
    * @param i_flg_scope table of section orientation
    * @param i_id_rep_layout table of section layout
    * @param i_elapsed_time table of elapsed time
    * @param i_java_time table of java time
    * @param i_database_time table of database time
    * @param i_remote_service_time table of remote service time
    * @param i_database_requests table of database requests
    * @param i_remote_service_requests table of remote service requests
    * @param i_jasper_time table of jasper time
    * @param o_error error message
    *
    * @return true (success), false (error)
    *
    * @author Jorge Matos, 2011/Jun/06
    * @version 2.6.1.1
    * @since 2011/Jun/06
    */

    FUNCTION set_epis_rep_sections_metadata
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_epis_report             IN epis_report_section.id_epis_report%TYPE,
        i_id_rep_section          IN table_number,
        i_cardinality             IN table_number,
        i_flg_scope               IN table_varchar,
        i_id_rep_layout           IN table_varchar,
        i_elapsed_time            IN table_number,
        i_java_time               IN table_number,
        i_database_time           IN table_number,
        i_remote_service_time     IN table_number,
        i_database_requests       IN table_number,
        i_remote_service_requests IN table_number,
        i_jasper_time             IN table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_presc_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        o_inst_info       OUT pk_types.cursor_type,
        o_prof_info       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_report_ctx_grid
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_context             IN epis_report.id_episode%TYPE,
        i_reports             IN reports.id_reports%TYPE,
        i_sections            IN table_number,
        i_flg_status          IN epis_report.flg_status%TYPE,
        i_flg_edit            IN epis_report.flg_edit%TYPE,
        i_rep_binary_file     IN epis_report.rep_binary_file%TYPE,
        i_flg_confidential    IN epis_report.flg_confidential%TYPE,
        i_dt_begin_report     IN VARCHAR2,
        i_dt_end_report       IN VARCHAR2,
        i_flg_date_filters    IN epis_report.flg_date_filters%TYPE,
        i_flg_disclosure      IN epis_report.flg_disclosure%TYPE,
        i_dt_request          IN VARCHAR2,
        i_dt_disclosure       IN VARCHAR2,
        i_disclosure_to       IN epis_report_disclosure.disclosure_recipient%TYPE,
        i_recipient_address   IN epis_report_disclosure.recipient_address%TYPE,
        i_sample_text         IN epis_report_disclosure.id_sample_text%TYPE,
        i_free_text_purp_disc IN epis_report_disclosure.free_text_purp_disc%TYPE,
        i_notes               IN epis_report_disclosure.notes%TYPE,
        i_flg_disc_recipient  IN epis_report_disclosure.flg_disc_recipient%TYPE,
        i_id_professional_req IN professional.id_professional%TYPE,
        i_flg_share_grid      IN VARCHAR2,
        i_flg_report_origin   IN VARCHAR2,
        i_flg_saved_outside   IN VARCHAR2,
        o_id_doc_external     OUT epis_report.id_doc_external%TYPE,
        o_id_epis_report      IN OUT epis_report.id_epis_report%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_report_ctx
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_context             IN epis_report.id_episode%TYPE,
        i_reports             IN reports.id_reports%TYPE,
        i_sections            IN table_number,
        i_flg_status          IN epis_report.flg_status%TYPE,
        i_flg_edit            IN epis_report.flg_edit%TYPE,
        i_rep_binary_file     IN epis_report.rep_binary_file%TYPE,
        i_flg_confidential    IN epis_report.flg_confidential%TYPE,
        i_dt_begin_report     IN VARCHAR2,
        i_dt_end_report       IN VARCHAR2,
        i_flg_date_filters    IN epis_report.flg_date_filters%TYPE,
        i_flg_disclosure      IN epis_report.flg_disclosure%TYPE,
        i_dt_request          IN VARCHAR2,
        i_dt_disclosure       IN VARCHAR2,
        i_disclosure_to       IN epis_report_disclosure.disclosure_recipient%TYPE,
        i_recipient_address   IN epis_report_disclosure.recipient_address%TYPE,
        i_sample_text         IN epis_report_disclosure.id_sample_text%TYPE,
        i_free_text_purp_disc IN epis_report_disclosure.free_text_purp_disc%TYPE,
        i_notes               IN epis_report_disclosure.notes%TYPE,
        i_flg_disc_recipient  IN epis_report_disclosure.flg_disc_recipient%TYPE,
        i_id_professional_req IN professional.id_professional%TYPE,
        i_flg_saved_outside   IN VARCHAR2,
        o_id_epis_report      IN OUT epis_report.id_epis_report%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Modifica os estado de um relatório gerado
    *
    * @param i_lang id da lingua
    * @param i_prof obj do utilizador
    * @param i_epis_report id do relatório gerado
    * @param i_flg_status estado
    * @param o_error var com mensagem de erro
    *
    * @return true (successo), false (erro)
    *
    * @author João Eiras, 26-09-2007
    * @version 1.0
    * @since 2.4.0
    */

    FUNCTION set_epis_report_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_report IN epis_report.id_epis_report%TYPE,
        i_flg_status  IN epis_report.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Modifica a origem da geração de um relatório: no momento da alta ou atrave´s da print tool
    *
    * @param i_lang id da lingua
    * @param i_prof obj do utilizador
    * @param i_epis_report id do relatório gerado
    * @param i_flg_status estado
    * @param o_error var com mensagem de erro
    *
    * @return true (successo), false (erro)
    *
    * @author Carlos Guilherme, 22-12-2010
    * @version 1.0
    * @since 2.6.0.5
    */

    FUNCTION set_epis_report_origin
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_report       IN epis_report.id_epis_report%TYPE,
        i_flg_report_origin IN epis_report.flg_report_origin%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Deve retornar um FLG_AUTH e um PRINTER_NAME consoante o profissional e o relatório em causa.
    * Deve verificar quais os valores destas flags, associados ao seu perfil (REP_PROFILE_TEMPLATE),
    * assim como possíveis excepções.
    *
    * @param i_lang               - identificador da linguagem
    * @param i_prof               - objecto com dados do utilizador
    * @param i_id_reports         - identificador do report
    *
    * @return
    * @author     Marco Freire
    * @since      2009/05/08
    * @version    2.5
    */

    FUNCTION get_rep_auth_print
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_reports IN reports.id_reports%TYPE,
        o_reports    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * @usage Obtém o valor da flag signed da tabela epis_report e configurações relativas à assinatura digital.
    *
    * @param   I_ID_EPIS_REPORT     Epis Report identifier
    *
    * @param   I_LANG               Língua registada como preferência do profissional
    * @param   I_PROF               ID do profissional, instituição e software
    * @param   O_DIG_SIG_TYPE       Tipo de assinatura digital que este report tem (pode não ser nenhuma)
    * @param   O_DIG_SIG            epis_report.flg_signed
    * @param   O_SHOW_DIG_SIG       show digital signature? Y for show, N for hide.
    * @param   O_DIG_SIG_PARAMS     digital signature parameters
    * @param   O_ERROR              Descrição do erro
    *
    * @return     Boolean
    * @author     Thiago Brito, Luís Gaspar
    * @version    2.4.3  2008/05/28, 2008/08/12
    */

    FUNCTION get_dig_sig_flg
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_report        IN epis_report.id_epis_report%TYPE,
        o_dig_sig_type          OUT epis_report.dig_sig_type%TYPE,
        o_dig_sig               OUT epis_report.flg_signed%TYPE,
        o_show_dig_sig          OUT reports_inst_soft.flg_digital_signature%TYPE,
        o_dig_sig_param         OUT reports.flg_digital_signature_format%TYPE,
        o_flg_dig_sig_save_file OUT reports_inst_soft.flg_dig_sig_save_file%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets some metadata about the report.
    *
    * @param i_lang language id
    * @param i_prof professional type
    * @param i_epis_report generated report id
    * @param i_json_params service call params
    * @param i_elapsed_time elapsed time
    * @param o_error error message
    *
    * @return true (success), false (error)
    *
    * @author Gonçalo Almeida, 2011/Feb/04
    * @version 2.6.0.5
    * @since 2011/Feb/04
    */

    FUNCTION set_epis_report_metadata
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_report  IN epis_report.id_epis_report%TYPE,
        i_json_params  IN epis_report.json_params%TYPE,
        i_elapsed_time IN epis_report.elapsed_time%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * GET_TIMEFRAME_SECTIONS          Returns sections time frame filter availability
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_report              Report to be verified
    * @param i_sections               Sections to be verified
    * @param o_sections_date_filter   Sections and time frame filter availability
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    **********************************************************************************************/

    FUNCTION get_timeframe_sections
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_report            IN reports.id_reports%TYPE,
        i_sections             IN table_number,
        o_sections_date_filter OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Gets the parameters for HIE
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_report              ID REPORT
     *
     * @param o_parameters             List of parameters
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Ruben Araujo
     * @version                         1.0
     * @since                           2016/05/18
    **********************************************************************************************/

    FUNCTION get_hie_parameters
    (
        i_lang       IN language.id_language%TYPE,
        i_id_report  IN NUMBER,
        o_parameters OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_report_header
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_desc_type OUT VARCHAR2,
        o_desc      OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the report configurations for a market, institution and software
    *
    * @param   i_lang                      The id language
    * @param   i_professional              The professional identifier(id,institution,software)
    * @param   i_episode                   The id episode
    * @param   i_id_report                 The id reports
    * @param   o_logos                     Cursor with the logos for that market,institution,softoware and report
    * @param   o_result                    Returns if the report has been printed or not
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  25-02-2015
    
    */

    FUNCTION get_institution_logos
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN profissional,
        i_id_reports   IN reports.id_reports%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_logos        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the report logos for a market, institution and software by default method
    *
    * @param   i_lang                      The id language
    * @param   i_professional              The professional identifier(id,institution,software)
    * @param   i_episode                   The id episode
    * @param   i_id_report                 The id reports
    * @param   o_logos                     Cursor with the logos for that market,institution,softoware and report
    * @param   o_result                    Returns if the report has been printed or not
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  25-02-2015
    
    */

    FUNCTION get_institution_logos_det
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution_logo IN institution_logo.id_institution_logo%TYPE,
        o_inst_logo           OUT institution_logo.img_logo%TYPE,
        o_inst_banner         OUT institution_logo.img_banner%TYPE,
        o_inst_banner_small   OUT institution_logo.img_banner_small%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the report logos for a market, institution and software by configuration table´s method
    *
    * @param   i_lang                      The id language
    * @param   i_professional              The professional identifier(id,institution,software)
    * @param   i_episode                   The id episode
    * @param   i_id_report                 The id reports
    * @param   o_logos                     Cursor with the logos for that market,institution,softoware and report
    * @param   o_result                    Returns if the report has been printed or not
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  25-02-2015
    
    */

    FUNCTION get_inst_logos_by_config_table
    (
        i_lang        IN language.id_language%TYPE,
        i_id_rep_logo IN rep_logos.id_rep_logos%TYPE,
        o_logo        OUT rep_logos.image_logo%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_img_banners
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        o_inst_logo           OUT institution_logo.img_logo%TYPE,
        o_inst_banner         OUT institution_logo.img_banner%TYPE,
        o_inst_banner_small   OUT institution_logo.img_banner_small%TYPE,
        o_inst_name           OUT VARCHAR2,
        o_id_institution_logo OUT institution_logo.id_institution_logo%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_img_logo
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_inst_logo OUT institution_logo.img_logo%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_presc_rep_info
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        id_prof     IN professional.id_professional%TYPE,
        o_inst_info OUT pk_types.cursor_type,
        o_prof_info OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_report_thumbnail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_report        IN epis_report.id_epis_report%TYPE,
        i_epis_report_thumbnail IN epis_report.epis_report_thumbnail%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_report
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_epis_report               IN epis_report.id_epis_report%TYPE,
        o_epis_report                  OUT pk_types.cursor_type,
        o_rep_binary_file              OUT BLOB,
        o_signed_binary_file           OUT BLOB,
        o_temporary_signed_binary_file OUT BLOB,
        o_epis_report_thumbnail        OUT BLOB,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * @usage Saves an encrypted report (zip)
    *
    * @param   I_LANG                            Língua registada como preferência do profissional
    * @param   I_PROF                            ID do profissional, instituição e software
    * @param   I_ID_EPIS_REPORT                  ID do registo na EPIS_REPORT
    * @param   I_ENCRYPTED_BINARY_FILE           Ficheiro do relatorio encriptado
    * @param   O_ERROR                           Descrição do erro
    *
    * @return     Boolean
    * @author     goncalo.almeida
    * @version    2.6.1
    * @since      2012/01/24
    */

    FUNCTION set_report_bin_encrypted_file
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_report        IN epis_report.id_epis_report%TYPE,
        i_encrypted_binary_file IN epis_report.rep_binary_encrypted_file%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * @usage Guarda o relatório assinado neste episodio.
    *
    * @param   I_LANG                  Língua registada como preferência do profissional
    * @param   I_PROF                  ID do profissional, instituição e software
    * @param   I_ID_EPIS_REPORT        ID do registo na EPIS_REPORT
    * @param   I_SIGNED_BINARY_FILE    Ficheiro do relatorio assinado
    * @param   I_DIG_SIG_TYPE
    * @param   O_ERROR                 Descrição do erro
    *
    * @return     Boolean
    * @author     Rui Spratley
    * @version    2.4.3
    * @since      2008/06/16
    */

    FUNCTION set_report_bin_signed_file
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_report     IN epis_report.id_epis_report%TYPE,
        i_signed_binary_file IN epis_report.signed_binary_file%TYPE,
        i_dig_sig_type       IN epis_report.dig_sig_type%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get new print arguments to the reports that need to be regenerated
    *
    * @param   i_lang                      Preferred language id for this professional
    * @param   i_prof                      Professional id structure
    * @param   i_print_list_job            Array of print list job identifiers
    * @param   i_print_list_area           Array of print list area identifiers
    * @param   i_epis_report               Array of epis report identifiers
    * @param   i_print_arguments           Array of print arguments
    * @param   o_print_list_job            Array of print list job identifiers
    * @param   o_print_list_area           Array of print list area identifiers
    * @param   o_epis_report               Array of epis report identifiers
    * @param   o_print_arguments           Array of print arguments
    * @param   o_flg_regenerate_report     Array of flags indicating if the reports need to be regenerated or not
    * @param   o_error                     Error information
    *
    * @value   o_flg_regenerate_report     {*} Y- report needs to be regenerated {*} N- otherwise
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   27-10-2014
    */

    FUNCTION get_print_args_to_regen_report
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_print_list_job        IN table_number,
        i_print_list_area       IN table_number,
        i_epis_report           IN table_number,
        i_print_arguments       IN table_varchar,
        o_print_list_job        OUT table_number,
        o_print_list_area       OUT table_number,
        o_epis_report           OUT table_number,
        o_print_arguments       OUT table_varchar,
        o_flg_regenerate_report OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Verifica se um relatório é para ser gerado localmente ou remotamente
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param i_id_reports                    Report ID
    *
    * @return                                Report will be generated in local instance (TRUE) or remote instance (FALSE)
    *
    * @author                                Tiago Lourenço
    * @version                               2.6.1
    * @since                                 1-Feb-2011
    */

    FUNCTION is_local_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_reports IN reports.id_reports%TYPE
    ) RETURN BOOLEAN;

    /**
    * Modifica o conteúdo do CLOB de um report
    *
    * @param i_lang id da lingua
    * @param i_prof obj do utilizador
    * @param i_epis_report id do relatório gerado
    * @param i_binary_file blob do report
    * @param o_error var com mensagem de erro
    *
    * @return true (successo), false (erro)
    *
    * @author Jorge Costa, 12-12-2013
    * @since 2.6.3
    */

    FUNCTION set_epis_report_binary_file
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_report IN epis_report.id_epis_report%TYPE,
        i_binary_file IN epis_report.rep_binary_file%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Obtém a lista de reports disponíveis para o profissional em determinado ecrã.
    * @param    I_LANG               Língua registada como preferência do profissional
    * @param    I_PROF               objecto com dados do utilizador
    * @param    I_EPISODE            ID do episódio actual
    * @param    I_AREA_REPORT        área na qual será alocado o relatório. Valores possíveis:
    *                                    {*} 'R' Reports
    *                                    {*} 'OD' Ongoing Documents
    *                                    {*} 'C' Consents
    *                                    {*} 'CR' Certificates
    *                                    {*} 'F' Forms
    *                                    {*} 'L' Lables
    *                                    {*} 'SR' Screen Reports
    * @param    I_SCREEN_NAME        Nome do ecrã onde a função é chamada
    * @param    I_SYS_BUTTON_PROP    ID do deepnav selecionado (If this value is null then it will be valid for all screen instances)
    *
    * @param    O_REPORTS            Array com a lista de reports
    * @param    O_ERROR              Descrição do erro
    *
    * @return     true (tudo ok), false (erro)
    * @author     RB
    * @version    1.0       2007/01/25
    * @change     RS 20100602 allow I_SYS_BUTTON_PROP to be NULL
    *
    * @author     João Reis
    * @version    2.6.1.2       2011/07/21
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    */
    FUNCTION get_reports_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_area_report     IN rep_profile_template_det.flg_area_report%TYPE,
        i_screen_name     IN rep_screen.screen_name%TYPE,
        i_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        o_reports         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reports_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_area_report     IN rep_profile_template_det.flg_area_report%TYPE,
        i_screen_name     IN rep_screen.screen_name%TYPE,
        i_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        i_task_type       IN table_number,
        i_context         IN table_varchar,
        o_reports         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Obtém a lista de reports dispon¿veis para o grupo a que o profissional tenha acesso.
    *
    * @param  I_LANG               L¿ngua registada como preferência do profissional
    * @param  I_PROF               ID do profissional, instituiçãoo e software
    * @param  I_REPORTS            ID do report que é um grupo
    *
    * @param  O_REPORTS            Array com a lista de reports
    * @param  O_ERROR              Descrição do erro
    *
    * @return     Boolean
    * @author     RB
    * @version    1.0  2007/01/26
    *
    * @author     João Reis
    * @version    2.6.1.2       2011/07/21
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    */
    FUNCTION get_reports_group
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_reports IN reports_group.id_reports_master%TYPE,
        o_reports OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Obtém a lista de conteúdos de um relatório, aplicando um filtro.
    *
    * @param   I_LANG               Língua registada como preferência do profissional
    * @param   I_PROF               ID do profissional, instituição e software
    * @param   I_EPISODE            ID do epis¿dio
    * @param   I_REPORTS            ID do report que é um grupo
    *
    * @param   O_LIST               Array com a lista
    * @param   O_ERROR              Descrição do erro
    *
    * @return     Boolean
    * @author     RB
    * @version    1.0  2007/02/01
    */
    FUNCTION get_filter_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_reports IN reports.id_reports%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Obtém a lista de secções de um report, disponíveis para impressão.
    *
    * @param   I_LANG               Língua registada como preferência do profissional
    * @param   I_PROF               ID do profissional, instituição e software
    * @param   I_EPISODE            ID do episódio
    * @param   I_PATIENT            ID do paciente
    * @param   I_REPORTS            ID do report que é um grupo
    *
    * @param   O_SECTION            Array com a lista de secções do report
    * @param   O_ERROR              Descrição do erro
    *
    * @return     Boolean
    * @author     RB
    * @version    1.0   2007/02/01
    */
    FUNCTION get_section_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_reports IN table_number,
        o_section OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Obtém a lista de secções de um report, disponíveis para impressão.
    *
    * @param   I_LANG               Língua registada como preferência do profissional
    * @param   I_PROF               ID do profissional, instituição e software
    * @param   I_EPISODE            ID do episódio
    * @param   I_PATIENT            ID do paciente
    * @param   I_REPORTS            ID do report que é um grupo
    * @param   I_WL_MACHINE_NAME    ID do hostname
    *
    * @param   O_SECTION            Array com a lista de secções do report
    * @param   O_ERROR              Descrição do erro
    *
    * @return     Boolean
    */
    FUNCTION get_section_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_reports         IN table_number,
        i_wl_machine_name IN wl_machine.machine_name%TYPE,
        o_section         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * @usage Obtém a lista de relatórios impressos para um paciente.
    *
    * @param   I_LANG               Língua registada como preferência do profissional
    * @param   I_PROF               ID do profissional, instituição e software
    * @param   I_EPISODE            ID do episódio
    * @param   I_PATIENT            ID do paciente
    *
    * @param   O_ARCHIVE            Array com os dados do Archive
    * @param   O_ERROR              Descrição do erro
    *
    * @return     Boolean
    * @author     RB
    * @version    1.0  2007/02/17
    */

    FUNCTION get_archive_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_archive OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_edit_reports_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_reports         IN reports.id_reports%TYPE,
        i_text            IN CLOB,
        o_rep_edit_report OUT rep_edit_report.id_rep_edit_report%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retorna o multichoice com os valore possiveis para a coluna REPORTS_GEN_PARAMN.FLG_TIME_FRACTION
    *
    * @param i_lang id_da lingua
    * @param i_prof
    * @param o_mchoice cursor com o mchoice
    * @param o_error mensagem de erro, caso aplicável
    * @return true (tudo ok), false (erro)
    *
    * @author João Eiras, 26-09-2007
    * @since 2.4.0.*
    * @version 1.0
    */

    FUNCTION get_time_fraction_mchoice
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_mchoice OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retorna a lista de profissionais disponíveis para a geração deste relatório
    *
    * @param i_lang id_da lingua
    * @param i_prof objecto do utilizador
    * @param i_reports id do relatório
    * @param i_dt_begin data de inicio do período, do qual se podem escolher profissionais
    * @param i_dt_end data de fim do período, do qual se podem escolher profissionais
    * @param o_profs cursor com os profissionais
    * @param o_error mensagem de erro, caso aplicável
    * @return true (tudo ok), false (erro)
    *
    * @author João Eiras, 27-09-2007
    * @since 2.4.0.*
    * @version 1.0
    */

    FUNCTION get_reports_prof_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_reports  IN reports.id_reports%TYPE,
        i_dt_begin IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        o_profs    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Grava um conjunto de parametros para a geração de um relatório
    * para possibilitar a geração deste
    *
    * @param i_lang id_da lingua
    * @param i_prof objecto do utilizador
    * @param i_dt_begin array com datas de inicio do período, do qual se podem escolher profissionais
    * @param i_dt_end array com datas de fim do período, do qual se podem escolher profissionais
    * @param i_ids_profs array com ids de profissionais
    * @param i_flg_time_fraction fracção da escala do tempo
    * @param o_id_reports_gen_param id de saída da tabela reports_gen_param onde ficaram gravados os parametros
    * @param o_error mensagem de erro, caso aplicável
    * @return true (tudo ok), false (erro)
    *
    * @author João Eiras, 27-09-2007
    * @since 2.4.0.*
    * @version 1.0
    */

    FUNCTION set_reports_gen_parameters
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_dt_begin             IN table_varchar,
        i_dt_end               IN table_varchar,
        i_ids_profs            IN table_number,
        i_flg_time_fraction    IN reports_gen_param.flg_time_fraction%TYPE,
        o_id_reports_gen_param OUT reports_gen_param.id_reports_gen_param%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * This function returs the exam types cursor
    *
    * @param i_lang                          Language ID
    * @param i_id_episode                    Episode ID
    * @param o_exam_type_list                Exam type list cursor
    * @param o_error                         Error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/05/25
    **********************************************************************************************/

    FUNCTION get_exam_type_list
    (
        i_lang           IN language.id_language%TYPE,
        o_exam_type_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * This function returs the labs for current visit according i_exam_type
    *
    * @param i_lang                          Language ID
    * @param i_id_episode                    Episode ID
    * @param i_id_exam_type                  Exam type ID
    * @param o_lab_list                      Lab list
    * @param o_error                         Error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/05/25
    **********************************************************************************************/

    FUNCTION get_lab_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_exam_type IN rep_order_type.id_rep_order_type%TYPE,
        o_lab_list     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * This function returs the tests for current visit and selected lab
    *
    * @param i_lang                          Language ID
    * @param i_id_episode                    Episode ID
    * @param i_id_exam_type                  Exam type ID
    * @param i_id_room                       Romm ID (Lab ID)
    * @param o_exam_list                     Exam list
    * @param o_error                         Error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/05/25
    **********************************************************************************************/

    FUNCTION get_exam_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_exam_type IN rep_order_type.id_rep_order_type%TYPE,
        i_id_room      IN room.id_room%TYPE,
        o_exam_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * GET_TIMEFRAME_SCREEN_REP        Returns necessary information for loading timeframe report screen
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param i_id_report              Report ID
    * @param o_title                  Returns the lable for current report
    * @param o_rep_options            Returns all information for available optins in this screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4
    * @since                          07-Feb-2011
    **********************************************************************************************/

    FUNCTION get_timeframe_screen_rep
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_report   IN timeframe_rep.id_report%TYPE,
        o_title       OUT VARCHAR2,
        o_rep_options OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * GET_TIMEFRAME_SCREEN_REP_OPTION Returns addtional information for loading timeframe report screen for specific option
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param i_id_report              Report ID
    * @param i_id_option              Id timeframe option
    * @param i_param                  Additional parameter 
    * @param o_option_list            Returns list of values for specific options in this screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4
    * @since                          07-Feb-2011
    **********************************************************************************************/
    FUNCTION get_timeframe_screen_rep_option
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_report   IN timeframe_rep.id_report%TYPE,
        i_id_option   IN timeframe_option.id_timeframe_option%TYPE,
        i_param       IN VARCHAR2,
        o_option_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Checks if profile template of the current logged user has access to disclosure reports
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param i_screen_name                   Screen name
    * @param o_has_disc_report               Has at least one disclosure report?
    *
    * @value o_has_disc_report   {*} 'Y' Yes {*} 'N' No
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    ***********************************************************************************************/

    FUNCTION check_disclosure_report
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_screen_name     IN rep_screen.screen_name%TYPE,
        i_flg_area_report IN rep_profile_template_det.flg_area_report%TYPE,
        o_has_disc_report OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the professional name used when creating a new disclosure report
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param o_prof_name                     Professional name
    * @param o_error                         error message
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    **********************************************************************************************/

    FUNCTION get_prof_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_name OUT professional.name%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get current epis report detail data
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param i_epis_report                   Epis report id
    * @param o_report_detail                 Epis report detail data
    * @param o_error                         error message
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    **********************************************************************************************/

    FUNCTION get_epis_rep_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_report   IN epis_report.id_epis_report%TYPE,
        o_report_detail OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get epis report history data
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param i_epis_report                   Epis report id
    * @param o_report_detail                 Epis report detail data
    * @param o_error                         error message
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    **********************************************************************************************/

    FUNCTION get_epis_rep_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_report   IN epis_report.id_epis_report%TYPE,
        o_report_detail OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert the request of a report generation in the intf_alert queue
    *
    * @param i_id_episode                       Episode id
    * @param i_id_patient                       Patient id
    * @param i_id_institution                   Institution id
    * @param i_id_language                      Language id
    * @param i_id_report_type                   Report type id
    * @param i_id_professional                  Professional id
    * @param i_id_software                      Software id
    * @param i_flag_report_origin               Flag report origin
    *
    * @author PEDRO.MAIA
    * @version 1.0
    * @since 05-01-2011
    ********************************************************************************************/

    FUNCTION request_gen_report
    (
        i_id_episode         IN v_episode.id_episode%TYPE,
        i_id_patient         IN v_patient.id_patient%TYPE,
        i_id_institution     IN v_episode.id_institution%TYPE,
        i_id_language        IN v_institution.id_institution_language%TYPE,
        i_id_report_type     IN NUMBER,
        i_id_sections        IN VARCHAR2,
        i_id_professional    IN v_episode.id_professional%TYPE,
        i_id_software        IN v_episode.id_software%TYPE,
        i_flag_report_origin IN VARCHAR2
    ) RETURN BOOLEAN;

    /**
    * Get the patient name (considering VIP alias)
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_pat_name     Patient name
    * @param o_error        error message
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    **********************************************************************************************/

    FUNCTION get_pat_name
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_pat_name OUT patient.name%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Obtém a lista de reports disponíveis para o profissional em determinado ecrã e os reports do episódio seleccionado.
    * @param    I_LANG               Idioma
    * @param    I_PROF               objecto com dados do utilizador
    * @param    I_EPISODE            ID do episódio actual
    * @param    I_AREA_REPORT        área na qual será alocado o relatório
    * @param    I_SCREEN_NAME        Nome do ecrã onde a função é chamada
    * @param    I_SYS_BUTTON_PROP    ID do deepnav selecionado (If this value is null then it will be valid for all screen instances)
    * @param    I_ID_REPORT_EPISODE  ID do episódio seleccionado
    * @param    I_ID_SOFTWARE        ID do software do episódio seleccionado
    *
    * @param    O_REPORTS            Array com a lista de reports
    * @param    O_ERROR              Descrição do erro
    *
    * @return     true (tudo ok), false (erro)
    * @author     Tércio Soares
    * @version    2.6.3.7       2013/07/09
    */

    FUNCTION get_rep_prev_epis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_area_report       IN rep_profile_template_det.flg_area_report%TYPE,
        i_screen_name       IN rep_screen.screen_name%TYPE,
        i_sys_button_prop   IN sys_button_prop.id_sys_button_prop%TYPE,
        i_id_report_episode IN episode.id_episode%TYPE,
        i_id_software       IN software.id_software%TYPE,
        o_reports           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Adds the report to the printing list
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_episode            Episode identifier
    * @param   i_print_list_areas   Print list area id
    * @param   i_report             List of report ids
    * @param   i_print_arguments    List of print arguments necessary to print the jobs
    * @param   o_print_list_jobs    Cursor with the print job ids
    * @param   o_error              An error message, set when return=false
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   07-10-2014
    */

    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_print_list_area IN print_list_area.id_print_list_area%TYPE,
        i_report          IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_jobs OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the identification of the report available on a specific are and for a specific action
    *
    * @param i_lang                       Language id
    * @param i_prof                       Professional id
    * @param i_flg_action                 Action to filter
    * @param i_screen_name                Name of the screen
    *
    * @return id of the report
    * @author ricardo.pires
    * @version 1.0
    * @since 22-10-2011
    ********************************************************************************************/

    FUNCTION get_id_report
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_action  IN reports.flg_action%TYPE,
        i_screen_name IN rep_screen.screen_name%TYPE
    ) RETURN NUMBER;

    /**
    * Set a list of print jobs as completed
    *
    * @param   i_lang                      Preferred language id for this professional
    * @param   i_prof                      Professional id structure
    * @param   i_print_list_job            Array of print list job identifiers
    * @param   i_print_list_area           Array of print list area identifiers
    * @param   i_epis_report               Array of epis report identifiers
    * @param   o_print_list_job            Array of print list job identifiers
    * @param   o_error                     Error information
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   29-10-2014
    */

    FUNCTION set_print_jobs_complete
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_job  IN table_number,
        i_print_list_area IN table_number,
        i_epis_report     IN table_number,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Notify print jobs error
    *
    * @param   i_lang                      Preferred language id for this professional
    * @param   i_prof                      Professional id structure
    * @param   i_print_list_job            Array of print list job identifiers
    * @param   i_print_list_area           Array of print list area identifiers
    * @param   i_epis_report               Array of epis report identifiers
    * @param   o_print_list_job            Array of print list job identifiers
    * @param   o_error                     Error information
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   29-10-2014
    */

    FUNCTION set_print_jobs_error
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_job  IN table_number,
        i_print_list_area IN table_number,
        i_epis_report     IN table_number,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_date_for_reports
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN alert.profissional,
        o_dt_begin OUT VARCHAR2,
        o_dt_end   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_services_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_reports    IN reports.id_reports%TYPE,
        o_info_services OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_patients_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_reports    IN reports.id_reports%TYPE,
        i_id_department IN table_number,
        o_info_patients OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
      * Overload function to allow showing or not the virtual sections.
    * The sections are ordered alphabetically.
      *
      * @param   I_EPISODE            ID do episódio
      * @param   I_PATIENT            ID do paciente
      * @param   I_REPORTS            ID do report que é um grupo
      *
      * @param   O_SECTION            Array com a lista de secções do report
      * @param   O_ERROR              Descrição do erro
      *
      * @param i_lang language id
      * @param i_prof professional type
      * @param i_episode episode's ID
      * @param i_reports report's ID array
      * @param i_show_visible flag indicating whether virtual sections should also be returned ('A' = All, 'Y' = Visible, 'N' = Invisible)
      *
      * @param o_section cursor with section information
      * @param o_error error message
      *
      * @return true (success), false (error)
      *
      * @author Gonçalo Almeida, 2011/Feb/15
      * @version 2.6.1
      * @since 2011/Feb/15
      *
      * @author     João Reis
      * @version    2.6.1.2       2011/07/21
      * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
      */
    FUNCTION get_invisible_section_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_reports            IN table_number,
        i_section_visibility IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_count              IN VARCHAR2 DEFAULT NULL,
        o_section            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);

END pk_print_tool_api_ux;
/