CREATE OR REPLACE PACKAGE pk_reports_referral_api IS

    -- Author  : PEDRO.MORAIS
    -- Created : 27-05-2010 16:10:00
    -- Purpose : Package with functions called by Reports

    -- Public variable declarations
    g_error VARCHAR2(4000);

    FUNCTION get_exr_group
    (
        i_lang              IN language.id_language%TYPE,
        id_prof             IN professional.id_professional%TYPE,
        id_inst             IN institution.id_institution%TYPE,
        id_soft             IN software.id_software%TYPE,
        i_exr               IN p1_external_request.id_external_request%TYPE,
        i_type              IN VARCHAR2,
        i_id_report         IN reports.id_reports%TYPE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        i_flg_isencao       IN VARCHAR2,
        o_ref               OUT pk_types.cursor_type,
        o_institution       OUT pk_types.cursor_type,
        o_patient           OUT pk_types.cursor_type,
        o_ref_health_plan   OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_referral_xml
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_referral_xml_req IN NUMBER,
        o_req                 OUT pk_types.cursor_type,
        o_det                 OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_referral_xml
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_p1_external_request IN NUMBER,
        i_flg_type               IN VARCHAR2,
        i_id_report              IN NUMBER,
        i_id_group               IN table_number,
        i_xml_request            IN CLOB,
        i_xml_response           IN CLOB,
        i_auth_response          IN CLOB,
        i_flg_status             IN VARCHAR2,
        i_dt_ws_send             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_ws_received         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_xml_det_request        IN table_clob,
        i_xml_det_response       IN table_clob,
        i_flg_status_det         IN table_varchar,
        i_pdf_request            IN CLOB,
        i_pdf_response           IN CLOB,
        i_epis_report            IN NUMBER,
        o_id_referral_xml_req    OUT NUMBER,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_referral_xml
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_referral_xml_req IN NUMBER,
        i_xml_request         IN CLOB,
        i_xml_response        IN CLOB,
        i_auth_response       IN CLOB,
        i_flg_status          IN VARCHAR2,
        i_dt_ws_send          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_ws_received      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_group            IN table_number,
        i_xml_det_request     IN table_clob,
        i_xml_det_response    IN table_clob,
        i_flg_status_det      IN table_varchar,
        i_pdf_request         IN CLOB,
        i_pdf_response        IN CLOB,
        i_epis_report         IN NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION split_mcdt_request_by_group
    (
        i_lang                IN language.id_language%TYPE,
        id_prof               IN professional.id_professional%TYPE,
        id_inst               IN institution.id_institution%TYPE,
        id_soft               IN software.id_software%TYPE,
        i_exr                 IN p1_external_request.id_external_request%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_type                IN VARCHAR2,
        i_num_req             IN table_varchar,
        i_id_report           IN reports.id_reports%TYPE,
        i_id_ref_completion   IN ref_completion.id_ref_completion%TYPE,
        i_flg_isencao         IN VARCHAR2,
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

END pk_reports_referral_api;
/
