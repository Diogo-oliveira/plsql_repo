/*-- Last Change Revision: $Rev: 2028502 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_approval IS
    TYPE et_rec_t IS RECORD(
        data  VARCHAR2(200),
        label VARCHAR2(200),
        rank  NUMBER,
        icon  VARCHAR(200));

    TYPE et_rec_list_t IS TABLE OF et_rec_t;

    TYPE app_pk_rec IS RECORD(
        id_approval_type approval_request_hist.id_approval_type%TYPE,
        id_external      approval_request_hist.id_external%TYPE);

    TYPE app_pk_rec_list IS TABLE OF app_pk_rec;

    /**
    * This function returns a an list of the epis_type that available for the given professional
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional identifier
    *
    * @return                List of id_epis_type
    *
    * @version               2.5.0.5
    */
    FUNCTION get_inst_epis_type
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_prof IN profissional
    ) RETURN et_rec_list_t
        PIPELINED;

    -- property values    
    TYPE val_representation_type IS RECORD(
        val            VARCHAR2(200),
        representation VARCHAR2(1));
    TYPE val_representation_table IS TABLE OF val_representation_type;
    TYPE property_type IS RECORD(
        name                   VARCHAR2(200),
        values_representations val_representation_table,
        default_value          VARCHAR2(1));
    TYPE property_table IS TABLE OF property_type; -- INDEX BY property_type.name%TYPE;

    FUNCTION make_apprv_properties_field
    (
        i_property_names  IN table_varchar,
        i_property_values IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * This function checks if a given episode is a nursing related episode
    *
    * @param i_et            ID_EPIS_TYPE
    *
    * @return                Y - if nurse related, N - otherwise
    *
    * @version               2.5.0.5
    */
    FUNCTION is_nurse_et(i_et NUMBER) RETURN VARCHAR2;

    FUNCTION get_property_value
    (
        i_property_name       VARCHAR,
        i_approval_properties approval_request.approval_properties%TYPE
    ) RETURN VARCHAR;

    /**
    * Get all the approval types configured for the given professional
    *
    * @param i_prof          Professional identifier
    *
    * @return                List of id_approval_type
    */
    FUNCTION appr_req_has_config_prof(i_prof IN profissional) RETURN table_number;

    /**
    * Runs an approval function
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional identifier
    * @param i_id_approval_type       Approval type identifier
    * @param i_id_external            External identifier
    *
    * @return                         The function return value in VARCHAR2
    */
    FUNCTION run_approval_function
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_external          IN approval_request.id_external%TYPE,
        i_id_approval_function IN approval_function.id_approval_function%TYPE,
        i_is_dml               IN VARCHAR
    ) RETURN VARCHAR2;

    /**
    * Checks if an approval belongs to the history (outdated).
    * An approval request is assumed outdated if is in the pending state and have overlimited the time of expiricy.
    *
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @return                Y - if belong to history, N - otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/21
    */
    FUNCTION approval_belongs_to_history
    (
        i_prof             IN profissional,
        i_id_approval_type IN approval_type.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2;

    /**
    * Checks if an approval has notes (in any transaction).
    *
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @return                Y - if has notes, N - otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/21
    */
    FUNCTION approval_has_notes
    (
        i_id_approval_type IN approval_type.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_approval_requests
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE DEFAULT NULL,
        i_filter_by_prof      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_filter_by_patient   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_filter_by_history   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_filter_by_dcs       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_filter_by_search    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_filter_by_prof_req  IN table_number DEFAULT NULL,
        i_filter_by_dir_resp  IN table_number DEFAULT NULL,
        i_filter_by_origin    IN table_number DEFAULT NULL,
        i_filter_by_req_date  IN VARCHAR2 DEFAULT NULL,
        i_filter_by_app_type  IN table_number DEFAULT NULL,
        i_filter_by_app_state IN table_varchar DEFAULT NULL,
        i_filter_by_app_desc  IN VARCHAR2 DEFAULT NULL,
        o_approvals           OUT pk_types.cursor_type,
        o_appr_types          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the date to use when counting time elapsed.
    *
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @return                The base time for the elapsed time
    *
    * @author                Sérgio Santos
    * @version               2.5.0.7
    * @since                 2009/12/09
    */
    FUNCTION get_base_elapsed_time
    (
        i_id_approval_type IN approval_type.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE
    ) RETURN approval_request.dt_action%TYPE;

    /**
    * Checks if the provided approval requests have no responsible or are already assigned to another
    * professional.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_flg_show           Show modal window (Y - yes, N - no)
    * @param o_msg_title          Modal window title
    * @param o_msg_text_highlight Modal window highlighted text
    * @param o_msg_text_detail    Modal window detail text
    * @param o_button             Modal window buttons
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/21
    */
    FUNCTION check_prof_responsibility
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_approval_type   IN table_number,
        i_id_external        IN table_number,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_text_highlight OUT VARCHAR2,
        o_msg_text_detail    OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks and sets the professional responsible for the given approval request.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION set_prof_responsible_no_commit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN table_number,
        i_id_external      IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Adds a new approval request for the director
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    * @param i_id_patient         Patient identifier
    * @param i_id_episode         Episode identifier
    * @param i_property_names     Properties identifiers
    * @param i_property_values    Properties values
    * @param i_notes              notes
    *
    * @param o_error              Error object
    *
    * @return                True if succed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/21
    */
    PROCEDURE add_approval_request_nocommit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_id_patient       IN approval_request.id_patient%TYPE,
        i_id_episode       IN approval_request.id_episode%TYPE,
        i_property_names   IN table_varchar,
        i_property_values  IN table_varchar,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    );
    /**
    * Update a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    * @param i_property_names     Properties identifiers
    * @param i_property_values    Properties values
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    PROCEDURE update_appr_req_nocommit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_property_names   IN table_varchar,
        i_property_values  IN table_varchar,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    );

    /**
    * Send a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    * @param i_property_names     Properties identifiers
    * @param i_property_values    Properties values
    * @param i_notes              Notes
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    PROCEDURE send_appr_req_nocommit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_property_names   IN table_varchar,
        i_property_values  IN table_varchar,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    );
    /**
    * Approve a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION approve_appr_request_no_commit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Reject a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION reject_appr_request_no_commit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if the decision made by an approval request can be cancelled
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                Y - Can cancel the decision, N - otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION chk_cancel_director_decision
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2;

    /**
    * Cancel a decision of a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION canc_appr_req_decis_no_commit
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_approval_type   IN approval_request.id_approval_type%TYPE,
        i_id_external        IN approval_request.id_external%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_text_highlight OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    PROCEDURE cancel_appr_req_nocommit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    );

    /**
    * Function used in the match functionality
    *
    * @param i_lang         Language id
    * @param i_prof         Professional id
    * @param i_episode_temp Temporary episode id
    * @param i_episode      Episode id
    * @param i_patient      Patient id
    * @param i_patient_temp Temporary patient id
    *
    * @param o_error        Error object    
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/08/18
    */
    FUNCTION approval_match
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Function used in the reset functionality
    * (approval_request_hist table)
    *
    * @param i_episode      Episode id
    *
    * @param o_error        Error object    
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/08/18   
    */
    FUNCTION approval_request_hist_reset(i_id_episode IN episode.id_episode%TYPE) RETURN table_varchar;

    /**
    * Function used in the reset functionality
    * (approval_request table)
    *
    * @param i_episode      Episode id
    *
    * @param o_error        Error object    
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/08/18   
    */
    FUNCTION approval_request_reset(i_id_episode IN episode.id_episode%TYPE) RETURN table_varchar;

    /**
    * SIMULATION FUNCTION - TO BE DELETED
    */
    FUNCTION simulate_appr_func_info
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_external IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2;

    /**
    * SIMULATION FUNCTION - TO BE DELETED
    */
    FUNCTION simulate_appr_func_chk_cancel
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_external IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2;

    /**
    * SIMULATION FUNCTION - TO BE DELETED
    */
    FUNCTION simulate_appr_func_cancel
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_external IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2;

    /**
    * SIMULATION FUNCTION - TO BE DELETED
    */
    FUNCTION simulate_appr_func_approve
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_external IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2;

    /**
    * SIMULATION FUNCTION - TO BE DELETED
    */
    FUNCTION simulate_appr_func_reject
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_external IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2;

    ---------------------------------------------------------------------------
    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';

    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    g_error        VARCHAR2(4000);
    g_package_name VARCHAR2(32);
    g_found        BOOLEAN;
    g_exception EXCEPTION;

    -- flags
    g_flg_selected CONSTANT VARCHAR2(1) := 'S';

    -- approval request status
    g_approval_request_pending   CONSTANT VARCHAR2(1) := 'P';
    g_approval_request_approved  CONSTANT VARCHAR2(1) := 'A';
    g_approval_request_rejected  CONSTANT VARCHAR2(1) := 'R';
    g_approval_request_cancelled CONSTANT VARCHAR2(1) := 'C';

    -- approval request actions
    g_action_create_approval  CONSTANT VARCHAR2(1) := 'N';
    g_action_approve_approval CONSTANT VARCHAR2(1) := 'A';
    g_action_reject_approval  CONSTANT VARCHAR2(1) := 'R';
    g_action_cancel_request   CONSTANT VARCHAR2(1) := 'G';
    g_action_send_request     CONSTANT VARCHAR2(1) := 'S';
    g_action_update_request   CONSTANT VARCHAR2(1) := 'U';
    g_action_cancel_decision  CONSTANT VARCHAR2(1) := 'C';
    g_action_change_prof_resp CONSTANT VARCHAR2(1) := 'P';

    -- colors
    g_color_red  CONSTANT VARCHAR(8) := '0xC86464';
    g_color_icon CONSTANT VARCHAR(8) := '0xEBEBC8';

    -- Search screens criteria identifiers
    g_id_criteria_prof_req     CONSTANT NUMBER := 153;
    g_id_criteria_dir_resp     CONSTANT NUMBER := 154;
    g_id_criteria_origin       CONSTANT NUMBER := 155;
    g_id_criteria_app_req_date CONSTANT NUMBER := 156;
    g_id_criteria_app_type     CONSTANT NUMBER := 157;
    g_id_criteria_status       CONSTANT NUMBER := 158;
    g_id_criteria_app_desc     CONSTANT NUMBER := 159;

    -- text constants
    g_no_record_notation CONSTANT VARCHAR2(3) := '---';

    -- shortcuts
    g_shortcut_patient_app  CONSTANT NUMBER := 28;
    g_shortcut_patient_hist CONSTANT NUMBER := 101;

    g_properties property_table;

END pk_approval;
/
