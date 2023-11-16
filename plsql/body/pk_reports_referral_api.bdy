CREATE OR REPLACE PACKAGE BODY pk_reports_referral_api IS
    ------------------------------ PRIVATE PACKAGE VARIABLES ---------------------------
    g_package_name  VARCHAR2(30);
    g_package_owner VARCHAR2(30);
    my_exception EXCEPTION;

    g_debug_enable BOOLEAN;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_p1_ext_sys.get_exr_group(i_lang              => i_lang,
                                           id_prof             => id_prof,
                                           id_inst             => id_inst,
                                           id_soft             => id_soft,
                                           i_exr               => i_exr,
                                           i_type              => i_type,
                                           i_id_report         => i_id_report,
                                           i_id_ref_completion => i_id_ref_completion,
                                           i_flg_isencao       => i_flg_isencao,
                                           o_ref               => o_ref,
                                           o_institution       => o_institution,
                                           o_patient           => o_patient,
                                           o_ref_health_plan   => o_ref_health_plan,
                                           o_error             => o_error)
        THEN
            RAISE my_exception;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_ref);
            pk_types.open_cursor_if_closed(o_institution);
            pk_types.open_cursor_if_closed(o_patient);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EXR_GROUP',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_exr_group;

    FUNCTION get_referral_xml
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_referral_xml_req IN NUMBER,
        o_req                 OUT pk_types.cursor_type,
        o_det                 OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN AS
    BEGIN
    
        OPEN o_req FOR
            SELECT *
              FROM referral_xml_req rxr
             WHERE rxr.id_referral_xml_req = i_id_referral_xml_req;
    
        OPEN o_det FOR
            SELECT *
              FROM referral_xml_req_det a
             WHERE a.id_referral_xml_req = i_id_referral_xml_req;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_req);
            pk_types.open_cursor_if_closed(o_det);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_XML',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_referral_xml;

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
    ) RETURN BOOLEAN AS
        l_id_referral_xml_req     referral_xml_req.id_referral_xml_req%TYPE;
        l_id_referral_xml_req_det referral_xml_req_det.id_referral_xml_req_det%TYPE;
    
        l_id_group         NUMBER(24);
        l_xml_det_request  CLOB;
        l_xml_det_response CLOB;
        l_flg_status_det   VARCHAR2(2 CHAR);
    
    BEGIN
        l_id_referral_xml_req := seq_referral_xml_req.nextval;
    
        INSERT INTO referral_xml_req
            (id_referral_xml_req,
             flg_type,
             id_report,
             xml_request,
             xml_response,
             auth_response,
             flg_status,
             dt_ws_send,
             dt_ws_received,
             pdf_request,
             pdf_response,
             id_epis_report,
             id_p1_external_request)
        VALUES
            (l_id_referral_xml_req,
             i_flg_type,
             i_id_report,
             i_xml_request,
             i_xml_response,
             i_auth_response,
             i_flg_status,
             nvl(i_dt_ws_send, current_timestamp),
             i_dt_ws_received,
             i_pdf_request,
             i_pdf_response,
             i_epis_report,
             i_id_p1_external_request);
    
        FOR i IN 1 .. i_id_group.count
        LOOP
        
            l_id_group := i_id_group(i);
        
            IF i_xml_det_request IS NOT NULL
            THEN
                IF i_xml_det_request.count >= i
                THEN
                    l_xml_det_request := i_xml_det_request(i);
                END IF;
            END IF;
        
            IF i_xml_det_response IS NOT NULL
            THEN
                IF i_xml_det_response.count >= i
                THEN
                    l_xml_det_response := i_xml_det_response(i);
                END IF;
            END IF;
        
            IF i_flg_status_det IS NOT NULL
            THEN
                IF i_flg_status_det.count >= i
                THEN
                    l_flg_status_det := i_flg_status_det(i);
                END IF;
            END IF;
        
            l_id_referral_xml_req_det := seq_referral_xml_req_det.nextval;
            INSERT INTO referral_xml_req_det
                (id_referral_xml_req_det, id_referral_xml_req, id_group, xml_det_request, xml_det_response, flg_status)
            VALUES
                (l_id_referral_xml_req_det,
                 l_id_referral_xml_req,
                 l_id_group,
                 l_xml_det_request,
                 l_xml_det_response,
                 l_flg_status_det);
        END LOOP;
    
        o_id_referral_xml_req := l_id_referral_xml_req;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REFERRAL_XML',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_referral_xml;

    FUNCTION set_referral_xml_req_hist
    (
        i_id_referral_xml_req IN referral_xml_req.id_referral_xml_req%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN AS
        l_seq NUMBER(24) := seq_referral_xml_req_hist.nextval;
    BEGIN
    
        INSERT INTO referral_xml_req_hist
            SELECT l_seq,
                   a.id_referral_xml_req,
                   a.flg_type,
                   a.id_report,
                   a.xml_request,
                   a.xml_response,
                   a.auth_response,
                   a.flg_status,
                   a.dt_ws_send,
                   a.dt_ws_received,
                   a.pdf_request,
                   a.pdf_response,
                   a.id_epis_report,
                   a.id_p1_external_request
              FROM referral_xml_req a
             WHERE a.id_referral_xml_req = i_id_referral_xml_req;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END set_referral_xml_req_hist;

    FUNCTION set_referral_xml_req_det_hist
    (
        i_id_referral_xml_req IN referral_xml_req.id_referral_xml_req%TYPE,
        i_id_group            IN referral_xml_req_det.id_group%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN AS
        l_seq NUMBER(24) := seq_referral_xml_req_det_hist.nextval;
    BEGIN
    
        INSERT INTO referral_xml_req_det_hist
            SELECT l_seq,
                   a.id_referral_xml_req_det,
                   a.id_referral_xml_req,
                   a.id_group,
                   a.xml_det_request,
                   a.xml_det_response,
                   a.flg_status
              FROM referral_xml_req_det a
             WHERE a.id_referral_xml_req = i_id_referral_xml_req
               AND a.id_group = i_id_group;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END set_referral_xml_req_det_hist;

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
    ) RETURN BOOLEAN AS
    
        l_id_group NUMBER(24);
    
        l_xml_det_request  CLOB;
        l_xml_det_response CLOB;
        l_flg_status_det   VARCHAR2(2 CHAR);
    
    BEGIN
    
        IF NOT set_referral_xml_req_hist(i_id_referral_xml_req => i_id_referral_xml_req, o_error => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        UPDATE referral_xml_req a
           SET a.xml_request    = nvl(i_xml_request, a.xml_request),
               a.xml_response   = nvl(i_xml_response, a.xml_response),
               a.auth_response  = nvl(i_auth_response, a.auth_response),
               a.flg_status     = nvl(i_flg_status, a.flg_status),
               a.dt_ws_send     = nvl(i_dt_ws_send, a.dt_ws_send),
               a.dt_ws_received = nvl(i_dt_ws_received, a.dt_ws_received),
               a.pdf_request    = nvl(i_pdf_request, a.pdf_request),
               a.pdf_response   = nvl(i_pdf_response, a.pdf_request),
               a.id_epis_report = nvl(i_epis_report, a.id_epis_report)
         WHERE a.id_referral_xml_req = i_id_referral_xml_req;
    
        FOR i IN 1 .. i_id_group.count
        LOOP
        
            l_id_group := i_id_group(i);
        
            IF i_xml_det_request IS NOT NULL
            THEN
                IF i_xml_det_request.count >= i
                THEN
                    l_xml_det_request := i_xml_det_request(i);
                END IF;
            END IF;
        
            IF i_xml_det_response IS NOT NULL
            THEN
                IF i_xml_det_response.count >= i
                THEN
                    l_xml_det_response := i_xml_det_response(i);
                END IF;
            END IF;
        
            IF i_flg_status_det IS NOT NULL
            THEN
                IF i_flg_status_det.count >= i
                THEN
                    l_flg_status_det := i_flg_status_det(i);
                END IF;
            END IF;
        
            IF NOT set_referral_xml_req_det_hist(i_id_referral_xml_req => i_id_referral_xml_req,
                                                 i_id_group            => l_id_group,
                                                 o_error               => o_error)
            THEN
                RAISE my_exception;
            END IF;
            UPDATE referral_xml_req_det a
               SET a.xml_det_request  = nvl(l_xml_det_request, a.xml_det_request),
                   a.xml_det_response = nvl(l_xml_det_response, a.xml_det_response),
                   a.flg_status       = nvl(l_flg_status_det, a.flg_status)
             WHERE a.id_referral_xml_req = i_id_referral_xml_req
               AND a.id_group = l_id_group;
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REFERRAL_XML',
                                              o_error    => o_error);
            RETURN FALSE;
    END update_referral_xml;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_p1_med_cs.split_mcdt_request_by_group(i_lang                => i_lang,
                                                        i_prof                => profissional(id_prof, id_inst, id_soft),
                                                        i_exr                 => i_exr,
                                                        i_id_patient          => i_id_patient,
                                                        i_id_episode          => i_id_episode,
                                                        i_type                => i_type,
                                                        i_num_req             => i_num_req,
                                                        i_id_report           => i_id_report,
                                                        i_id_ref_completion   => i_id_ref_completion,
                                                        i_flg_isencao         => i_flg_isencao,
                                                        o_id_external_request => o_id_external_request,
                                                        o_error               => o_error)
        
        THEN
            RAISE my_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SPLIT_MCDT_REQUEST_BY_GROUP',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END split_mcdt_request_by_group;

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
    g_debug_enable := pk_alertlog.is_debug_enabled(i_object_name => g_package_name);

END pk_reports_referral_api;
/
