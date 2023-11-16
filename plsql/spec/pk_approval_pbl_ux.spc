/*-- Last Change Revision: $Rev: 2028503 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_approval_pbl_ux IS

    /********************************************************************************************
    * Returns all approval resquests that are associated with the logged professional specialities. 
    * (Except expired requests)
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    *
    * @param o_approvals          The approval requests list
    * @param o_appr_types         Approval types list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/31
    *********************************************************************************************/
    FUNCTION get_all_approval_requests
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        o_approvals  OUT pk_types.cursor_type,
        o_appr_types OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all approval resquests in witch the logged professional is responsible.
    * (Except expired requests)
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    *
    * @param o_approvals          The approval requests list
    * @param o_appr_types         Approval types list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/31
    *********************************************************************************************/
    FUNCTION get_my_approval_requests
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        o_approvals  OUT pk_types.cursor_type,
        o_appr_types OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all approval resquests associated to the given patient.
    * (Except expired requests)
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_patient            Patient identifier
    *
    * @param o_approvals          The approval requests list
    * @param o_appr_types         Approval types list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/31
    *********************************************************************************************/
    FUNCTION get_patient_approval_requests
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_approvals  OUT pk_types.cursor_type,
        o_appr_types OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all approval resquests that are expired associated to the given patient.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_patient            Patient identifier
    *
    * @param o_approvals          The approval requests list
    * @param o_appr_types         Approval types list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/31
    *********************************************************************************************/
    FUNCTION get_hist_pat_approval_requests
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_approvals  OUT pk_types.cursor_type,
        o_appr_types OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all approval resquests based on the search conditions.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_criteria           Search criterias list
    * @param i_values             Search values list
    *
    * @param o_approvals          The approval requests list
    * @param o_appr_types         Approval types list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/31
    *********************************************************************************************/
    FUNCTION get_search_approval_requests
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_criteria   IN table_number,
        i_values     IN table_varchar,
        o_approvals  OUT pk_types.cursor_type,
        o_appr_types OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @since                 2009/07/24
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

    /********************************************************************************************
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
    * @since                 2009/07/24
    *********************************************************************************************/
    FUNCTION set_prof_responsibility
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

    /********************************************************************************************
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
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    *********************************************************************************************/
    FUNCTION approve_approval_request
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
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
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    *********************************************************************************************/
    FUNCTION reject_approval_request
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
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
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    *********************************************************************************************/
    FUNCTION canc_appr_req_decis
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

    ---------------------------------------------------------------------------
    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';

    g_error        VARCHAR2(4000);
    g_package_name VARCHAR2(32);
    g_exception EXCEPTION;
END pk_approval_pbl_ux;
/
