/*-- Last Change Revision: $Rev: 2028929 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_reports AS

    /********************************************************************************************
    * Get scope for report sections (episode, patient, visit)
    
    * @author                                  Rui Duarte
    * @version                                 0.1
    * @since                                   2010/11/05
    ********************************************************************************************/
    FUNCTION get_report_scope
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_report         IN reports.id_reports%TYPE,
        i_id_rep_section IN table_number,
        i_report_type    IN rep_scope_inst_soft_market.flg_report_type%TYPE,
        o_report_scope   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Crearte configuration for report scope (episode, patient, visit)
    *
    * @author                                  Rui Duarte
    * @version                                 0.1
    * @since                                   2010/11/05
    ********************************************************************************************/
    FUNCTION insert_into_report_scope
    (
        i_lang           IN language.id_language%TYPE,
        i_report         IN reports.id_reports%TYPE,
        i_section        IN rep_section.id_rep_section%TYPE,
        i_report_type    IN rep_scope_inst_soft_market.flg_report_type%TYPE,
        i_report_scope   IN rep_scope_inst_soft_market.flg_scope%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_market      IN market.id_market%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rep_ux_section
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_reports          IN reports.id_reports%TYPE,
        i_id_rep_section      IN table_number,
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
        i_id_rep_section         IN table_number,
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
        i_id_rep_section          IN table_number,
        o_rep_layout_section_list OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rep_section_config
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_software             IN software.id_software%TYPE,
        i_id_reports              IN reports.id_reports%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_rep_section          IN table_number,
        o_rep_layout_section_list OUT pk_types.cursor_type,
        o_rep_ux_section_list     OUT pk_types.cursor_type,
        o_rep_rules_section_list  OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get metadata for an array of rep_section. Called by Java.
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/02/15
    ********************************************************************************************/
    FUNCTION get_rep_section_metadata
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_report         IN reports.id_reports%TYPE,
        i_id_rep_section IN table_number,
        o_rep_metadata   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set report as assynchronous and generate alert accordingly.
    *
    * @param i_lang                Language Id
    * @param i_prof                ID professional that generates the report
    * @param i_id_episode          ID episode of Record to insert
    * @param i_id_epis_report      ID of the record related do the espisode and report (table EPIS_REPORT)
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Pedro Maia
    * @version                     2.5.1
    * @since                       2010/12/16
    ********************************************************************************************/
    FUNCTION set_alert_report_asynchronous
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_id_episode     IN epis_report.id_episode%TYPE,
        i_id_epis_report IN epis_report.id_epis_report%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the id_context to be printed on each report. Called by Java.
    * @author                                  Ricardo Pires
    * @version                                 0.1
    * @since                                   2014/06/06
    ********************************************************************************************/
    FUNCTION get_order_by_report
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_context         IN table_number,
        i_task_type       IN table_number,
        o_order_by_report OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert a id_context of a order to be printed on a specific report. Called by Java.
    * @author                                  Ricardo Pires
    * @version                                 0.1
    * @since                                   2014/08/20
    ********************************************************************************************/
    FUNCTION insert_order_by_report
    (
        i_lang              IN language.id_language%TYPE,
        i_reports           IN reports.id_reports%TYPE,
        i_market            IN market.id_market%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_software          IN software.id_software%TYPE,
        i_context           IN NUMBER,
        i_task_type_context IN task_type.id_task_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    g_crit_type_a CONSTANT VARCHAR2(1) := 'A'; --All (executions and requests)
    g_crit_type_e CONSTANT VARCHAR2(1) := 'E'; -- Executions      

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    g_owner   VARCHAR2(100);
    g_package VARCHAR2(100);

END pk_reports;
/
