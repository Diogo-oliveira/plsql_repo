/*-- Last Change Revision: $Rev: 2028525 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_print_tool IS

    -- Author  : SERGIO.CUNHA
    -- Created : 05-01-2009 14:15:24
    -- Purpose : Print Tool reports configuration

    /********************************************************************************************
    * Get a list of report profiles by software and institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_rep_profile         Reports Profile List cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Sérgio Cunha
    * @version                     0.1
    * @since                       2009/01/06
    ********************************************************************************************/
    FUNCTION get_rep_profile_instit_soft
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_rep_profile    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get a list of reports available and selected by profile
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID
    * @param i_id_software                     Software ID
    * @param i_id_rep_profile_template         Reports Profile ID
    * @param o_rep_list                        Reports Profile List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/07
    ********************************************************************************************/
    FUNCTION get_rep_soft
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_rep_profile_template IN rep_profile_template.id_rep_profile_template%TYPE,
        o_rep_list                OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get a list of sections available by report
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports Profile ID
    * @param o_rep_section_list                Report Sections List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/07
    ********************************************************************************************/
    FUNCTION get_print_tool_rep_details
    (
        i_lang             IN language.id_language%TYPE,
        i_id_software      IN software.id_software%TYPE,
        i_id_reports       IN reports.id_reports%TYPE,
        o_rep_section_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get a list of reports available by software
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_software                     Software ID
    * @param i_id_institution                  Institution ID
    * @param o_rep_list                        Reports by software List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/08
    ********************************************************************************************/
    FUNCTION get_reports_soft
    (
        i_lang           IN language.id_language%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_rep_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get a list of sections available by profile
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports Profile ID
    * @param i_section_visibility              Flag indicating whether virtual sections should also be returned ('A' = All, 'Y' = Visible, 'N' = Invisible)
    * @param o_rep_section_list                Report Sections List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/08
    *
    * @author     João Reis
    * @version    2.6.1.2       2011/07/26
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    ********************************************************************************************/
    FUNCTION get_rep_section_det
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_reports              IN reports.id_reports%TYPE,
        i_id_rep_profile_template IN rep_profile_template.id_rep_profile_template%TYPE DEFAULT 0,
        i_section_visibility      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_rep_section_list        OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates the selected reports for a given profile.
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID
    * @param i_id_software                     Software ID
    * @param i_id_rep_profile_template         Reports Profile Template ID
    * @param i_id_reports                      Table with selected Reports ID's
    * @param i_flg_available                   Table with selected value for each report
    * @param i_rep_institution                 Table with institution ID for each report
    * @param i_flg_area_report                 Table with flg_area for each report
    * @param o_rep_profile_template_det        Array with inserted/updated ids    
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Rui Gomes
    * @version                                 0.2
    * @since                                   2011/04/19
    ********************************************************************************************/
    FUNCTION set_rep_profile_template_det
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_institution           IN institution.id_institution%TYPE,
        i_id_software              IN software.id_software%TYPE,
        i_id_rep_profile_template  IN table_number,
        i_id_reports               IN table_table_number,
        i_flg_available            IN table_table_varchar,
        i_rep_institution          IN table_table_number,
        i_flg_disclosure           IN table_table_varchar,
        i_flg_area_report          IN table_table_varchar,
        o_rep_profile_template_det OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates the selected sections for a given report.
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Array with selected Reports ID's
    * @param i_id_rep_section                  Table with selected Report Sections ID's    
    * @param i_flg_active                      Table with selected value for each report section
    * @param i_rep_institution                 Table with institution ID for each report section
    * @param i_rep_software                    Table with software ID for each report section
    * @param i_software                        Array with software ID
    * @param o_rep_section_det                 Array with inserted/updated ids
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/09
    *
    * @author     João Reis
    * @version    2.6.1.2       2011/07/26
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    ********************************************************************************************/
    FUNCTION set_rep_section_det
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_rep_profile_template IN rep_profile_template.id_rep_profile_template%TYPE DEFAULT 0,
        i_id_reports              IN table_number,
        i_id_rep_section          IN table_table_number,
        i_flg_active              IN table_table_varchar,
        i_rep_institution         IN table_table_number,
        i_rep_software            IN table_table_number,
        i_software                IN table_number,
        o_rep_section_det         OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the software available for the institution, including the "All" softwares clause
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID    
    * @param o_software                        Software ID
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/27
    ********************************************************************************************/
    FUNCTION get_instit_soft_rep_section
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_software       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the software available for the institution that have reports associated to profiles
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID    
    * @param o_software                        Software ID
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/02/16
    ********************************************************************************************/
    FUNCTION get_instit_soft_rep_profile
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_software       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
      * Get MARKET ID by giving the software ID and institution ID
      *
      * @param i_lang                            Prefered language ID
      * @param i_id_software                     Software ID
      * @param i_id_institution                  Institution ID
      *
      *
      * @return                                  true or false on success or error
      *
    * @author                                  Susana Silva
      * @version                                 2.6
      * @since                                   2010/02/11
      ********************************************************************************************/
    FUNCTION get_id_market_soft_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN NUMBER;

    FUNCTION get_rep_ux_section
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_reports          IN reports.id_reports%TYPE,
        i_id_rep_section      IN rep_section.id_rep_section%TYPE,
        o_rep_ux_section_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rep_rules_section
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_institution         IN institution.id_institution%TYPE,
        i_id_software            IN software.id_software%TYPE,
        i_id_reports             IN reports.id_reports%TYPE,
        i_id_rep_section         IN rep_section.id_rep_section%TYPE,
        o_rep_rules_section_list OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rep_layout_section
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_reports              IN reports.id_reports%TYPE,
        i_id_rep_section          IN rep_section.id_rep_section%TYPE,
        o_rep_layout_section_list OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rep_ux_section
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_software           IN software.id_software%TYPE,
        i_id_reports            IN reports.id_reports%TYPE,
        i_id_institution        IN institution.id_institution%TYPE,
        i_rep_unique_identifier IN table_varchar,
        i_flg_active            IN table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rep_layout_section
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_software    IN software.id_software%TYPE,
        i_id_reports     IN reports.id_reports%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_rep_section IN rep_section.id_rep_section%TYPE,
        i_id_rep_layout  IN rep_layout.id_rep_layout%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rep_rule_section
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_software    IN software.id_software%TYPE,
        i_id_reports     IN reports.id_reports%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_rep_section IN rep_section.id_rep_section%TYPE,
        i_id_rep_rule    IN table_varchar,
        i_flg_active     IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rep_section_config
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_software           IN software.id_software%TYPE,
        i_id_reports            IN reports.id_reports%TYPE,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_rep_section        IN rep_section.id_rep_section%TYPE,
        i_id_rep_layout         IN rep_layout.id_rep_layout%TYPE,
        i_rep_unique_identifier IN table_varchar,
        i_ux_flg_active         IN table_varchar,
        i_id_rep_rule           IN table_varchar,
        i_rule_flg_active       IN table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get the list of specific parameterized messages of confidentiality for this institution
    *
    * @param i_lang                    Preferred language ID for this professional 
    * @param i_id_institution          Institution ID
    * @param o_rep_disclosure          Predifined messages of confidentiality
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          Mauro Sousa
    * @version                         2.6.1
    * @since                           2011/02/04
    **********************************************************************************************/
    FUNCTION get_rep_inst_disclosure
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institutiton IN institution.id_institution%TYPE,
        o_rep_disclosure  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Edit existing messages of confidentiality for this institution
    *
    * @param i_lang                    Preferred language ID for this professional 
    * @param i_id_institution          Institution ID
    * @param o_rep_disclosure          Predifined messages of confidentiality
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          Mauro Sousa
    * @version                         2.6.1
    * @since                           2011/02/04
    **********************************************************************************************/
    FUNCTION set_rep_inst_disclosure
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        --
        i_desc_discl IN rep_inst_disclosure.desc_disclosure%TYPE,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create REP_UNIQUE_IDENTIFIER
    *
    * @param i_lang                            Prefered language ID
    * @param i_prof                            Professional
    * @param i_id_section                      Section ID
    * @param i_rep_unique_identifier           REP_UNIQUE_IDENTIFIER list to create
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Tiago Lourenço
    * @version                                 2.6.1.8.4
    * @since                                   15-June-2012
    ********************************************************************************************/
    FUNCTION set_rep_unique_identifier
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_section            IN rep_section.id_rep_section%TYPE,
        i_rep_unique_identifier IN table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get a list of reports available and selected by profile / adapted to report config
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID
    * @param i_id_software                     Software ID
    * @param i_id_rep_profile_template         Reports Profile ID
    * @param o_rep_list                        Reports Profile List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Rui Gomes
    * @version                                 0.1
    * @since                                   2011/04/15
    ********************************************************************************************/
    FUNCTION get_reps_soft
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_rep_profile_template IN rep_profile_template.id_rep_profile_template%TYPE,
        o_rep_list                OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rep_epis_type_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_id_reports  IN reports.id_reports%TYPE
    ) RETURN VARCHAR2;

    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_exception EXCEPTION;

    g_error           VARCHAR2(2000);
    g_flg_unavailable VARCHAR2(1);

    g_flg_area_rep_r CONSTANT rep_profile_template_det.flg_area_report%TYPE := 'R';
    g_flg_action_or  CONSTANT rep_profile_template_det.flg_action%TYPE := 'OR';
    g_flg_all        CONSTANT VARCHAR2(1) := 'A';

    g_open_parenthesis  CONSTANT VARCHAR2(2) := ' (';
    g_close_parenthesis CONSTANT VARCHAR2(2) := ')';
    g_space             CONSTANT VARCHAR2(1 CHAR) := ' ';
    g_flg_sep           CONSTANT VARCHAR2(3 CHAR) := ' - ';
    g_dash              CONSTANT VARCHAR2(3 CHAR) := ' / ';

END pk_backoffice_print_tool;
/
