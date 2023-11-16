/*-- Last Change Revision $Rev 1978898 $*/
/*-- Last Change by $Author nuno.amorim $*/
/*-- Date of last change $Date 2021-02-04 171428 +0000 (qui, 04 fev 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_print_tool_api_ux AS

    FUNCTION get_invisible_section_list_rep
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_reports            IN reports.id_reports%TYPE,
        i_section_visibility IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_section            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_INVISIBLE_SECTION_LIST_REP';
        IF NOT pk_print_tool.get_invisible_section_list_rep(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_reports            => i_reports,
                                                            i_section_visibility => i_section_visibility,
                                                            o_section            => o_section,
                                                            o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INVISIBLE_SECTION_LIST_REP',
                                              o_error);
            pk_types.open_my_cursor(o_section);
            RETURN FALSE;
    END get_invisible_section_list_rep;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_EPIS_REP_SECTION_METADATA';
        IF NOT pk_print_tool.set_epis_rep_sections_metadata(i_lang                    => i_lang,
                                                            i_prof                    => i_prof,
                                                            i_epis_report             => i_epis_report,
                                                            i_id_rep_section          => i_id_rep_section,
                                                            i_cardinality             => i_cardinality,
                                                            i_flg_scope               => i_flg_scope,
                                                            i_id_rep_layout           => i_id_rep_layout,
                                                            i_elapsed_time            => i_elapsed_time,
                                                            i_java_time               => i_java_time,
                                                            i_database_time           => i_database_time,
                                                            i_remote_service_time     => i_remote_service_time,
                                                            i_database_requests       => i_database_requests,
                                                            i_remote_service_requests => i_remote_service_requests,
                                                            i_jasper_time             => i_jasper_time,
                                                            o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REP_SECTIONS_METADATA',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_epis_rep_sections_metadata;

    FUNCTION get_prof_presc_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        o_inst_info       OUT pk_types.cursor_type,
        o_prof_info       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_PROF_PRESC_INFO';
        IF NOT pk_print_tool.get_prof_presc_info(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_professional => i_id_professional,
                                                 o_inst_info       => o_inst_info,
                                                 o_prof_info       => o_prof_info,
                                                 o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_PRESC_INFO',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_prof_presc_info;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_EPIS_REPORT_CTX_GRID';
        IF NOT pk_print_tool.set_epis_report_ctx_grid(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_context             => i_context,
                                                      i_reports             => i_reports,
                                                      i_sections            => i_sections,
                                                      i_flg_status          => i_flg_status,
                                                      i_flg_edit            => i_flg_edit,
                                                      i_rep_binary_file     => i_rep_binary_file,
                                                      i_flg_confidential    => i_flg_confidential,
                                                      i_dt_begin_report     => i_dt_begin_report,
                                                      i_dt_end_report       => i_dt_end_report,
                                                      i_flg_date_filters    => i_flg_date_filters,
                                                      i_flg_disclosure      => i_flg_disclosure,
                                                      i_dt_request          => i_dt_request,
                                                      i_dt_disclosure       => i_dt_disclosure,
                                                      i_disclosure_to       => i_disclosure_to,
                                                      i_recipient_address   => i_recipient_address,
                                                      i_sample_text         => i_sample_text,
                                                      i_free_text_purp_disc => i_free_text_purp_disc,
                                                      i_notes               => i_notes,
                                                      i_flg_disc_recipient  => i_flg_disc_recipient,
                                                      i_id_professional_req => i_id_professional_req,
                                                      i_flg_share_grid      => i_flg_share_grid,
                                                      i_flg_report_origin   => i_flg_report_origin,
                                                      i_flg_saved_outside   => i_flg_saved_outside,
                                                      o_id_doc_external     => o_id_doc_external,
                                                      o_id_epis_report      => o_id_epis_report,
                                                      o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_CTX',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_report_ctx_grid;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_EPIS_REPORT_CTX';
        IF NOT pk_print_tool.set_epis_report_ctx(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_context             => i_context,
                                                 i_reports             => i_reports,
                                                 i_sections            => i_sections,
                                                 i_flg_status          => i_flg_status,
                                                 i_flg_edit            => i_flg_edit,
                                                 i_rep_binary_file     => i_rep_binary_file,
                                                 i_flg_confidential    => i_flg_confidential,
                                                 i_dt_begin_report     => i_dt_begin_report,
                                                 i_dt_end_report       => i_dt_end_report,
                                                 i_flg_date_filters    => i_flg_date_filters,
                                                 i_flg_disclosure      => i_flg_disclosure,
                                                 i_dt_request          => i_dt_request,
                                                 i_dt_disclosure       => i_dt_disclosure,
                                                 i_disclosure_to       => i_disclosure_to,
                                                 i_recipient_address   => i_recipient_address,
                                                 i_sample_text         => i_sample_text,
                                                 i_free_text_purp_disc => i_free_text_purp_disc,
                                                 i_notes               => i_notes,
                                                 i_flg_disc_recipient  => i_flg_disc_recipient,
                                                 i_id_professional_req => i_id_professional_req,
                                                 i_flg_saved_outside   => i_flg_saved_outside,
                                                 o_id_epis_report      => o_id_epis_report,
                                                 o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_CTX',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_report_ctx;

    FUNCTION set_epis_report_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_report IN epis_report.id_epis_report%TYPE,
        i_flg_status  IN epis_report.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_EPIS_REPORT_STATUS';
        IF NOT pk_print_tool.set_epis_report_status(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_epis_report => i_epis_report,
                                                    i_flg_status  => i_flg_status,
                                                    o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_report_status;

    FUNCTION set_epis_report_origin
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_report       IN epis_report.id_epis_report%TYPE,
        i_flg_report_origin IN epis_report.flg_report_origin%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_EPIS_REPORT_ORIGIN';
        IF NOT pk_print_tool.set_epis_report_origin(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_epis_report       => i_epis_report,
                                                    i_flg_report_origin => i_flg_report_origin,
                                                    o_error             => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_ORIGIN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_report_origin;

    FUNCTION get_rep_auth_print
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_reports IN reports.id_reports%TYPE,
        o_reports    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_REP_AUTH_PRINT';
        IF NOT pk_print_tool.get_rep_auth_print(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_reports => i_id_reports,
                                                o_reports    => o_reports,
                                                o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REP_AUTH_PRINT',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_reports);
            RETURN FALSE;
    END get_rep_auth_print;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_DIG_SIG_FLG';
        IF NOT pk_print_tool.get_dig_sig_flg(i_lang                  => i_lang,
                                             i_prof                  => i_prof,
                                             i_id_epis_report        => i_id_epis_report,
                                             o_dig_sig_type          => o_dig_sig_type,
                                             o_dig_sig               => o_dig_sig,
                                             o_show_dig_sig          => o_show_dig_sig,
                                             o_dig_sig_param         => o_dig_sig_param,
                                             o_flg_dig_sig_save_file => o_flg_dig_sig_save_file,
                                             o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DIG_SIG_FLG',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_dig_sig_flg;

    FUNCTION set_epis_report_metadata
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_report  IN epis_report.id_epis_report%TYPE,
        i_json_params  IN epis_report.json_params%TYPE,
        i_elapsed_time IN epis_report.elapsed_time%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_EPIS_REPORT_METADATA';
        IF NOT pk_print_tool.set_epis_report_metadata(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_epis_report  => i_epis_report,
                                                      i_json_params  => i_json_params,
                                                      i_elapsed_time => i_elapsed_time,
                                                      o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_METADATA',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_report_metadata;

    FUNCTION get_timeframe_sections
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_report            IN reports.id_reports%TYPE,
        i_sections             IN table_number,
        o_sections_date_filter OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_TIMEFRAME_SECTIONS';
        IF NOT pk_print_tool.get_timeframe_sections(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_id_report            => i_id_report,
                                                    i_sections             => i_sections,
                                                    o_sections_date_filter => o_sections_date_filter,
                                                    o_error                => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMEFRAME_SECTIONS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sections_date_filter);
            RETURN FALSE;
    END get_timeframe_sections;

    FUNCTION get_hie_parameters
    (
        i_lang       IN language.id_language%TYPE,
        i_id_report  IN NUMBER,
        o_parameters OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_HIE_PARAMETERS';
        IF NOT pk_print_tool.get_hie_parameters(i_lang       => i_lang,
                                                i_id_report  => i_id_report,
                                                o_parameters => o_parameters,
                                                o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HIE_PARAMETERS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_parameters);
            RETURN FALSE;
    END get_hie_parameters;

    FUNCTION get_report_header
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_desc_type OUT VARCHAR2,
        o_desc      OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_REPORT_HEADER';
        IF NOT pk_print_tool.get_report_header(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_episode   => i_episode,
                                               o_desc_type => o_desc_type,
                                               o_desc      => o_desc,
                                               o_error     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORT_HEADER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_report_header;

    FUNCTION get_institution_logos
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN profissional,
        i_id_reports   IN reports.id_reports%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_logos        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_INSTITUTION_LOGOS';
        IF NOT pk_print_tool.get_institution_logos(i_lang         => i_lang,
                                                   i_professional => i_professional,
                                                   i_id_reports   => i_id_reports,
                                                   i_episode      => i_episode,
                                                   o_logos        => o_logos,
                                                   o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INSTITUTION_LOGOS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_logos);
            RETURN FALSE;
    END get_institution_logos;

    FUNCTION get_institution_logos_det
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution_logo IN institution_logo.id_institution_logo%TYPE,
        o_inst_logo           OUT institution_logo.img_logo%TYPE,
        o_inst_banner         OUT institution_logo.img_banner%TYPE,
        o_inst_banner_small   OUT institution_logo.img_banner_small%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_INSTITUTION_LOGOS_DET';
        IF NOT pk_print_tool.get_institution_logos_det(i_lang                => i_lang,
                                                       i_id_institution_logo => i_id_institution_logo,
                                                       o_inst_logo           => o_inst_logo,
                                                       o_inst_banner         => o_inst_banner,
                                                       o_inst_banner_small   => o_inst_banner_small,
                                                       o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INSTITUTION_LOGOS_DET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_institution_logos_det;

    FUNCTION get_inst_logos_by_config_table
    (
        i_lang        IN language.id_language%TYPE,
        i_id_rep_logo IN rep_logos.id_rep_logos%TYPE,
        o_logo        OUT rep_logos.image_logo%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_INST_LOGOS_BY_CONFIG_TABLE';
        IF NOT pk_print_tool.get_inst_logos_by_config_table(i_lang        => i_lang,
                                                            i_id_rep_logo => i_id_rep_logo,
                                                            o_logo        => o_logo,
                                                            o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INST_LOGOS_BY_CONFIG_TABLE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_inst_logos_by_config_table;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_INSTITUTION_IMG_BANNERS';
        IF NOT pk_print_tool.get_institution_img_banners(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_episode             => i_episode,
                                                         o_inst_logo           => o_inst_logo,
                                                         o_inst_banner         => o_inst_banner,
                                                         o_inst_banner_small   => o_inst_banner_small,
                                                         o_inst_name           => o_inst_name,
                                                         o_id_institution_logo => o_id_institution_logo,
                                                         o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INSTITUTION_IMG_BANNERS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_institution_img_banners;

    FUNCTION get_institution_img_logo
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_inst_logo OUT institution_logo.img_logo%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_INSTITUTION_IMG_LOGO';
        IF NOT pk_print_tool.get_institution_img_logo(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_episode   => i_episode,
                                                      o_inst_logo => o_inst_logo,
                                                      o_error     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INSTITUTION_IMG_LOGO',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_institution_img_logo;

    FUNCTION get_prof_presc_rep_info
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        id_prof     IN professional.id_professional%TYPE,
        o_inst_info OUT pk_types.cursor_type,
        o_prof_info OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_PROF_PRESC_REP_INFO';
        IF NOT pk_print_tool.get_prof_presc_rep_info(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     id_prof     => id_prof,
                                                     o_inst_info => o_inst_info,
                                                     o_prof_info => o_prof_info,
                                                     o_error     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_PRESC_REP_INFO',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_inst_info);
            pk_types.open_my_cursor(o_prof_info);
            RETURN FALSE;
    END get_prof_presc_rep_info;

    FUNCTION set_epis_report_thumbnail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_report        IN epis_report.id_epis_report%TYPE,
        i_epis_report_thumbnail IN epis_report.epis_report_thumbnail%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_EPIS_REPORT_THUMBNAIL';
        IF NOT pk_print_tool.set_epis_report_thumbnail(i_lang                  => i_lang,
                                                       i_prof                  => i_prof,
                                                       i_id_epis_report        => i_id_epis_report,
                                                       i_epis_report_thumbnail => i_epis_report_thumbnail,
                                                       o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_THUMBNAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_report_thumbnail;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_EPIS_REPORT';
        IF NOT pk_print_tool.get_epis_report(i_lang                         => i_lang,
                                             i_prof                         => i_prof,
                                             i_id_epis_report               => i_id_epis_report,
                                             o_epis_report                  => o_epis_report,
                                             o_rep_binary_file              => o_rep_binary_file,
                                             o_signed_binary_file           => o_signed_binary_file,
                                             o_temporary_signed_binary_file => o_temporary_signed_binary_file,
                                             o_epis_report_thumbnail        => o_epis_report_thumbnail,
                                             o_error                        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_REPORT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_report;

    FUNCTION set_report_bin_encrypted_file
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_report        IN epis_report.id_epis_report%TYPE,
        i_encrypted_binary_file IN epis_report.rep_binary_encrypted_file%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_REPORT_BIN_ENCRYPTED_FILE';
        IF NOT pk_print_tool.set_report_bin_encrypted_file(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_id_epis_report        => i_id_epis_report,
                                                           i_encrypted_binary_file => i_encrypted_binary_file,
                                                           o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REPORT_BIN_ENCRYPTED_FILE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_report_bin_encrypted_file;

    FUNCTION set_report_bin_signed_file
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_report     IN epis_report.id_epis_report%TYPE,
        i_signed_binary_file IN epis_report.signed_binary_file%TYPE,
        i_dig_sig_type       IN epis_report.dig_sig_type%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_REPORT_BIN_SIGNED_FILE';
        IF NOT pk_print_tool.set_report_bin_signed_file(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_id_epis_report     => i_id_epis_report,
                                                        i_signed_binary_file => i_signed_binary_file,
                                                        i_dig_sig_type       => i_dig_sig_type,
                                                        o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REPORT_BIN_SIGNED_FILE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_report_bin_signed_file;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_PRINT_ARGS_TO_REGEN_REPORT';
        IF NOT pk_print_tool.get_print_args_to_regen_report(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_print_list_job        => i_print_list_job,
                                                            i_print_list_area       => i_print_list_area,
                                                            i_epis_report           => i_epis_report,
                                                            i_print_arguments       => i_print_arguments,
                                                            o_print_list_job        => o_print_list_job,
                                                            o_print_list_area       => o_print_list_area,
                                                            o_epis_report           => o_epis_report,
                                                            o_print_arguments       => o_print_arguments,
                                                            o_flg_regenerate_report => o_flg_regenerate_report,
                                                            o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PRINT_ARGS_TO_REGEN_REPORT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_print_args_to_regen_report;

    FUNCTION is_local_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_reports IN reports.id_reports%TYPE
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.IS_LOCAL_REPORT';
        IF NOT pk_print_tool.is_local_report(i_lang => i_lang, i_prof => i_prof, i_id_reports => i_id_reports)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END is_local_report;

    FUNCTION set_epis_report_binary_file
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_report IN epis_report.id_epis_report%TYPE,
        i_binary_file IN epis_report.rep_binary_file%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_EPIS_REPORT_BINARY_FILE';
        IF NOT pk_print_tool.set_epis_report_binary_file(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_epis_report => i_epis_report,
                                                         i_binary_file => i_binary_file,
                                                         o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_BINARY_FILE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_report_binary_file;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_REPORTS_LIST';
        IF NOT pk_print_tool.get_reports_list(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_episode         => i_episode,
                                              i_area_report     => i_area_report,
                                              i_screen_name     => i_screen_name,
                                              i_sys_button_prop => i_sys_button_prop,
                                              o_reports         => o_reports,
                                              o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_reports);
            RETURN FALSE;
    END get_reports_list;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_REPORTS_LIST';
        IF NOT pk_print_tool.get_reports_list(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_episode         => i_episode,
                                              i_area_report     => i_area_report,
                                              i_screen_name     => i_screen_name,
                                              i_sys_button_prop => i_sys_button_prop,
                                              i_task_type       => i_task_type,
                                              i_context         => i_context,
                                              o_reports         => o_reports,
                                              o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_reports);
            RETURN FALSE;
    END get_reports_list;

    FUNCTION get_reports_group
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_reports IN reports_group.id_reports_master%TYPE,
        o_reports OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_REPORTS_GROUP';
        IF NOT pk_print_tool.get_reports_group(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_reports => i_reports,
                                               o_reports => o_reports,
                                               o_error   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_GROUP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_reports);
            RETURN FALSE;
    END get_reports_group;

    FUNCTION get_filter_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_reports IN reports.id_reports%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_FILTER_LIST';
        IF NOT pk_print_tool.get_filter_list(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_episode => i_episode,
                                             i_reports => i_reports,
                                             o_list    => o_list,
                                             o_error   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FILTER_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_filter_list;

    FUNCTION get_section_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_reports IN table_number,
        o_section OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_SECTION_LIST';
        IF NOT pk_print_tool.get_section_list(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_episode => i_episode,
                                              i_patient => i_patient,
                                              i_reports => i_reports,
                                              o_section => o_section,
                                              o_error   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SECTION_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_section);
            RETURN FALSE;
    END get_section_list;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_SECTION_LIST';
        IF NOT pk_print_tool.get_section_list(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_episode         => i_episode,
                                              i_patient         => i_patient,
                                              i_reports         => i_reports,
                                              i_wl_machine_name => i_wl_machine_name,
                                              o_section         => o_section,
                                              o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SECTION_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_section);
            RETURN FALSE;
    END get_section_list;

    FUNCTION get_archive_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_archive OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_ARCHIVE_DET';
        IF NOT pk_print_tool.get_archive_det(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_episode => i_episode,
                                             o_archive => o_archive,
                                             o_error   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ARCHIVE_DET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_archive);
            RETURN FALSE;
    END get_archive_det;

    FUNCTION set_edit_reports_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_reports         IN reports.id_reports%TYPE,
        i_text            IN CLOB,
        o_rep_edit_report OUT rep_edit_report.id_rep_edit_report%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_EDIT_REPORTS_DET';
        IF NOT pk_print_tool.set_edit_reports_det(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_episode         => i_episode,
                                                  i_reports         => i_reports,
                                                  i_text            => i_text,
                                                  o_rep_edit_report => o_rep_edit_report,
                                                  o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EDIT_REPORTS_DET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_edit_reports_det;

    FUNCTION get_time_fraction_mchoice
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_mchoice OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_TIME_FRACTION_MCHOICE';
        IF NOT pk_print_tool.get_time_fraction_mchoice(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       o_mchoice => o_mchoice,
                                                       o_error   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_FRACTION_MCHOICE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_mchoice);
            RETURN FALSE;
    END get_time_fraction_mchoice;

    FUNCTION get_reports_prof_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_reports  IN reports.id_reports%TYPE,
        i_dt_begin IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        o_profs    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_REPORTS_PROF_LIST';
        IF NOT pk_print_tool.get_reports_prof_list(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_reports  => i_reports,
                                                   i_dt_begin => i_dt_begin,
                                                   i_dt_end   => i_dt_end,
                                                   o_profs    => o_profs,
                                                   o_error    => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_PROF_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_reports_prof_list;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_REPORTS_GEN_PARAMETERS';
        IF NOT pk_print_tool.set_reports_gen_parameters(i_lang                 => i_lang,
                                                        i_prof                 => i_prof,
                                                        i_dt_begin             => i_dt_begin,
                                                        i_dt_end               => i_dt_end,
                                                        i_ids_profs            => i_ids_profs,
                                                        i_flg_time_fraction    => i_flg_time_fraction,
                                                        o_id_reports_gen_param => o_id_reports_gen_param,
                                                        o_error                => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REPORTS_GEN_PARAMETERS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_reports_gen_parameters;

    FUNCTION get_exam_type_list
    (
        i_lang           IN language.id_language%TYPE,
        o_exam_type_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_EXAM_TYPE_LIST';
        IF NOT
            pk_print_tool.get_exam_type_list(i_lang => i_lang, o_exam_type_list => o_exam_type_list, o_error => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_TYPE_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_exam_type_list);
            RETURN FALSE;
    END get_exam_type_list;

    FUNCTION get_lab_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_exam_type IN rep_order_type.id_rep_order_type%TYPE,
        o_lab_list     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_LAB_LIST';
        IF NOT pk_print_tool.get_lab_list(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_id_episode   => i_id_episode,
                                          i_id_exam_type => i_id_exam_type,
                                          o_lab_list     => o_lab_list,
                                          o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_lab_list);
            RETURN FALSE;
    END get_lab_list;

    FUNCTION get_exam_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_exam_type IN rep_order_type.id_rep_order_type%TYPE,
        i_id_room      IN room.id_room%TYPE,
        o_exam_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_EXAM_LIST';
        IF NOT pk_print_tool.get_exam_list(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_id_episode   => i_id_episode,
                                           i_id_exam_type => i_id_exam_type,
                                           i_id_room      => i_id_room,
                                           o_exam_list    => o_exam_list,
                                           o_error        => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_exam_list);
            RETURN FALSE;
    END get_exam_list;

    FUNCTION get_timeframe_screen_rep
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_report   IN timeframe_rep.id_report%TYPE,
        o_title       OUT VARCHAR2,
        o_rep_options OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_TIMEFRAME_SCREEN_REP';
        IF NOT pk_print_tool.get_timeframe_screen_rep(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_id_episode  => i_id_episode,
                                                      i_id_report   => i_id_report,
                                                      o_title       => o_title,
                                                      o_rep_options => o_rep_options,
                                                      o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMEFRAME_SCREEN_REP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_rep_options);
            RETURN FALSE;
    END get_timeframe_screen_rep;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_TIMEFRAME_SCREEN_REP';
        IF NOT pk_print_tool.get_timeframe_screen_rep_option(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_id_episode  => i_id_episode,
                                                             i_id_report   => i_id_report,
                                                             i_id_option   => i_id_option,
                                                             i_param       => i_param,
                                                             o_option_list => o_option_list,
                                                             o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMEFRAME_SCREEN_REP_OPTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_option_list);
            RETURN FALSE;
    END get_timeframe_screen_rep_option;

    FUNCTION check_disclosure_report
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_screen_name     IN rep_screen.screen_name%TYPE,
        i_flg_area_report IN rep_profile_template_det.flg_area_report%TYPE,
        o_has_disc_report OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.CHECK_DISCLOSURE_REPORT';
        IF NOT pk_print_tool.check_disclosure_report(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_screen_name     => i_screen_name,
                                                     i_flg_area_report => i_flg_area_report,
                                                     o_has_disc_report => o_has_disc_report,
                                                     o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_DISCLOSURE_REPORT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_disclosure_report;

    FUNCTION get_prof_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_name OUT professional.name%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_PROF_NAME';
        IF NOT pk_print_tool.get_prof_name(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           o_prof_name => o_prof_name,
                                           o_error     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_NAME',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_name;

    FUNCTION get_epis_rep_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_report   IN epis_report.id_epis_report%TYPE,
        o_report_detail OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_EPIS_REP_DET';
        IF NOT pk_print_tool.get_epis_rep_det(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_epis_report   => i_epis_report,
                                              o_report_detail => o_report_detail,
                                              o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_REP_DET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_report_detail);
            RETURN FALSE;
    END get_epis_rep_det;

    FUNCTION get_epis_rep_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_report   IN epis_report.id_epis_report%TYPE,
        o_report_detail OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_EPIS_REP_HIST';
        IF NOT pk_print_tool.get_epis_rep_hist(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_epis_report   => i_epis_report,
                                               o_report_detail => o_report_detail,
                                               o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_REP_HIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_report_detail);
            RETURN FALSE;
    END get_epis_rep_hist;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.REQUEST_GEN_REPORT';
        IF NOT pk_print_tool.request_gen_report(i_id_episode         => i_id_episode,
                                                i_id_patient         => i_id_patient,
                                                i_id_institution     => i_id_institution,
                                                i_id_language        => i_id_language,
                                                i_id_report_type     => i_id_report_type,
                                                i_id_sections        => i_id_sections,
                                                i_id_professional    => i_id_professional,
                                                i_id_software        => i_id_software,
                                                i_flag_report_origin => i_flag_report_origin)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END request_gen_report;

    FUNCTION get_pat_name
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_pat_name OUT patient.name%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_PAT_NAME';
        IF NOT pk_print_tool.get_pat_name(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_patient  => i_patient,
                                          i_episode  => i_episode,
                                          o_pat_name => o_pat_name,
                                          o_error    => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_NAME',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_name;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_REP_PREV_EPIS';
        IF NOT pk_print_tool.get_rep_prev_epis(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_episode           => i_episode,
                                               i_area_report       => i_area_report,
                                               i_screen_name       => i_screen_name,
                                               i_sys_button_prop   => i_sys_button_prop,
                                               i_id_report_episode => i_id_report_episode,
                                               i_id_software       => i_id_software,
                                               o_reports           => o_reports,
                                               o_error             => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REP_PREV_EPIS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_reports);
            RETURN FALSE;
    END get_rep_prev_epis;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.ADD_PRINT_LIST_JOBS';
        IF NOT pk_print_tool.add_print_list_jobs(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_patient         => i_patient,
                                                 i_episode         => i_episode,
                                                 i_print_list_area => i_print_list_area,
                                                 i_report          => i_report,
                                                 i_print_arguments => i_print_arguments,
                                                 o_print_list_jobs => o_print_list_jobs,
                                                 o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ADD_PRINT_LIST_JOBS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END add_print_list_jobs;

    FUNCTION get_id_report
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_action  IN reports.flg_action%TYPE,
        i_screen_name IN rep_screen.screen_name%TYPE
    ) RETURN NUMBER IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_ID_REPORT';
        RETURN pk_print_tool.get_id_report(i_lang => i_lang,
                                           
                                           i_prof        => i_prof,
                                           i_flg_action  => i_flg_action,
                                           i_screen_name => i_screen_name);
    
    END get_id_report;

    FUNCTION set_print_jobs_complete
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_job  IN table_number,
        i_print_list_area IN table_number,
        i_epis_report     IN table_number,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_PRINT_JOBS_COMPLETE';
        IF NOT pk_print_tool.set_print_jobs_complete(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_print_list_job  => i_print_list_job,
                                                     i_print_list_area => i_print_list_area,
                                                     i_epis_report     => i_epis_report,
                                                     o_print_list_job  => o_print_list_job,
                                                     o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PRINT_JOBS_COMPLETE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_print_jobs_complete;

    FUNCTION set_print_jobs_error
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_job  IN table_number,
        i_print_list_area IN table_number,
        i_epis_report     IN table_number,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.SET_PRINT_JOBS_ERROR';
        IF NOT pk_print_tool.set_print_jobs_error(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_print_list_job  => i_print_list_job,
                                                  i_print_list_area => i_print_list_area,
                                                  i_epis_report     => i_epis_report,
                                                  o_print_list_job  => o_print_list_job,
                                                  o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PRINT_JOBS_ERROR',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_print_jobs_error;

    FUNCTION get_date_for_reports
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN alert.profissional,
        o_dt_begin OUT VARCHAR2,
        o_dt_end   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_DATE_FOR_REPORTS';
        IF NOT pk_print_tool.get_date_for_reports(i_lang     => i_lang,
                                                  i_prof     => i_prof,
                                                  o_dt_begin => o_dt_begin,
                                                  o_dt_end   => o_dt_end,
                                                  o_error    => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DATE_FOR_REPORTS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_date_for_reports;

    FUNCTION get_services_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_reports    IN reports.id_reports%TYPE,
        o_info_services OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_SERVICES_LIST';
        IF NOT pk_print_tool.get_services_list(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_id_reports    => i_id_reports,
                                               o_info_services => o_info_services,
                                               o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SERVICES_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_info_services);
            RETURN FALSE;
    END get_services_list;

    FUNCTION get_patients_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_reports    IN reports.id_reports%TYPE,
        i_id_department IN table_number,
        o_info_patients OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_PATIENTS_LIST';
        IF NOT pk_print_tool.get_patients_list(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_id_reports    => i_id_reports,
                                               i_id_department => i_id_department,
                                               o_info_patients => o_info_patients,
                                               o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENTS_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_info_patients);
            RETURN FALSE;
    END get_patients_list;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_TOOL.GET_INVISIBLE_SECTION_LIST';
        IF NOT pk_print_tool.get_invisible_section_list(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_episode            => i_episode,
                                                        i_patient            => i_patient,
                                                        i_reports            => i_reports,
                                                        i_section_visibility => i_section_visibility,
                                                        i_count              => i_count,
                                                        o_section            => o_section,
                                                        o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INVISIBLE_SECTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_section);
            RETURN FALSE;
    END get_invisible_section_list;
BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_print_tool_api_ux;
/
