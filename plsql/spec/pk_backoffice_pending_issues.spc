/*-- Last Change Revision: $Rev: 2028522 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:17 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_pending_issues IS

    -- Author  : SUSANA.SILVA
    -- Created : 19-03-2009 15:01:58
    -- Purpose : ALERT-10826

    /********************************************************************************************
    * Get institution group info
    *
    * @param i_lang                                         Prefered language ID
    * @param i_institution                                  Institution identification
    * @param o_group_institution                            List of institution group
    * @param o_error                                        Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  Sérgio Cunha
    * @version                 0.2
    * @since                   2009/04/14
    ********************************************************************************************/
    FUNCTION get_group_institution
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        o_group_institution OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get institution departments
    *
    * @param i_lang                                         Prefered language ID
    * @param i_institution                                  Institution identification
    * @param o_department                                   List of institution deptartments
    * @param o_error                                        Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  Susana Silva
    * @version                 0.1
    * @since                   2009/04/14
    ********************************************************************************************/
    FUNCTION get_department_instit
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_department  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get institution professionals
    *
    * @param i_lang                                         Prefered language ID
    * @param i_institution                                  Institution identification
    * @param i_category                                     Category identification
    * @param o_prof_institution                             List of institution professional
    * @param o_error                                        Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  Susana Silva
    * @version                 0.1
    * @since                   2009/04/14
    ********************************************************************************************/
    FUNCTION get_prof_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_institution      IN institution.id_institution%TYPE,
        i_category         IN prof_cat.id_category%TYPE,
        o_prof_institution OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get institution professional categories
    *
    * @param i_lang                                         Prefered language ID
    * @param i_institution                                  Institution identification
    * @param o_prof_cat_institution                         List of institution categories
    * @param o_error                                        Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  Susana Silva
    * @version                 0.1
    * @since                   2009/04/14
    ********************************************************************************************/
    FUNCTION get_prof_category_institution
    (
        i_lang                 IN language.id_language%TYPE,
        i_institution          IN institution.id_institution%TYPE,
        o_prof_cat_institution OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel groups
    *
    * @param i_lang                                         Prefered language ID
    * @param i_institution                                  Institution identification
    * @param i_id_group                                     Array of groups ids
    * @param i_prof                                         Professional information
    * @param o_id_group                                     Array of groups ids
    * @param o_error                                        Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  Sérgio Cunha
    * @version                 0.2
    * @since                   2009/04/14
    ********************************************************************************************/
    FUNCTION update_group_institution
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_id_group    IN table_number,
        i_prof        IN profissional,
        o_id_group    OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel groups
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_group                                     Group identification
    * @param i_department                                   List of institution deptartments
    * @param i_group_name                                   Group name
    * @param i_professional                                 List of group professionals
    * @param i_prof_status                                  List of professional status
    * @param i_notes                                        List of professional notes
    * @param i_prof_change                                  Professional identification
    * @param o_id_group                                     Group id updated/inserted
    * @param o_id_hist_group                                History group id inserted
    * @param o_error                                        Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  Sérgio Cunha
    * @version                 0.2
    * @since                   2009/04/15
    ********************************************************************************************/
    FUNCTION set_prof_group_institution
    (
        i_lang          IN language.id_language%TYPE,
        i_id_group      IN groups.id_group%TYPE,
        i_department    IN table_number,
        i_group_name    IN VARCHAR2,
        i_professional  IN table_number,
        i_prof_status   IN table_varchar,
        i_notes         IN table_varchar,
        i_prof_change   IN profissional,
        o_id_group      OUT NUMBER,
        o_id_hist_group OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get group info to edit
    *
    * @param i_lang                                         Prefered language ID
    * @param i_institution                                  Institution identification
    * @param i_group                                        Groups id
    * @param o_name                                         Group Name
    * @param o_departments                                  Group departments
    * @param o_professional                                 Group professionals
    * @param o_error                                        Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  Sérgio Cunha
    * @version                 0.2
    * @since                   2009/04/14
    ********************************************************************************************/
    FUNCTION get_prof_group_institution
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_group        IN groups.id_group%TYPE,
        o_name         OUT pk_types.cursor_type,
        o_departments  OUT pk_types.cursor_type,
        o_professional OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get group detail info
    *
    * @param i_lang                                         Prefered language ID
    * @param i_prof                                         Professional identification
    * @param i_group                                        Groups id
    * @param i_id_institution                               Institution identification
    * @param o_detail_group                                 Group detail and history
    * @param o_prof_detail_group                            Prof group detail and history
    * @param o_error                                        Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  Sérgio Cunha
    * @version                 0.2
    * @since                   2009/04/14
    ********************************************************************************************/
    FUNCTION get_detail_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_group             IN groups.id_group%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        o_detail_group      OUT pk_types.cursor_type,
        o_prof_detail_group OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /*TEST MSG CORE*/
    /********************************************************************************************
    * Get PAtient Sent messages
    *
    * @param i_lang                                         Prefered language ID
    * @param i_patient                                         Entity identification
    * @param i_flg_filter                                     Filter (canceled or active)
    * @param i_search                               search terms for subject and entity name
    *
    *
    * @return                  table of messages
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION get_patient_outbox
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_msg;
    /********************************************************************************************
    * Get PAtient Inbox messages
    *
    * @param i_lang                                         Prefered language ID
    * @param i_patient                                         Entity identification
    * @param i_flg_filter                                     Filter (canceled or active)
    * @param i_search                               search terms for subject and entity name
    *
    *
    * @return                  table of messages
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION get_patient_inbox
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_msg;
    /********************************************************************************************
    * Get Professional sent messages
    *
    * @param i_lang                                         Prefered language ID
    * @param i_patient                                         Entity identification
    * @param i_flg_filter                                     Filter (canceled or active)
    * @param i_search                               search terms for subject and entity name
    *
    *
    * @return                  table of messages
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION get_professional_outbox
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE
    ) RETURN t_tbl_msg;
    /********************************************************************************************
    * Get Professional Inbox messages
    *
    * @param i_lang                                         Prefered language ID
    * @param i_patient                                         Entity identification
    * @param i_flg_filter                                     Filter (canceled or active)
    * @param i_search                               search terms for subject and entity name
    *
    *
    * @return                  table of messages
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION get_professional_inbox
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE
    ) RETURN t_tbl_msg;
    /********************************************************************************************
    * Get Inbox number of unread messages
    *
    * @param i_lang                                         Prefered language ID
    * @param i_flg_inbox                                   P (patient) or F (facility professionals)
    * @param i_id_receiver                                Patient or professional context id
    *
    * @return                  Number of unread messages
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION get_inbox_count
    (
        i_lang        IN language.id_language%TYPE,
        i_flg_inbox   IN VARCHAR2,
        i_id_receiver IN NUMBER
    ) RETURN NUMBER;
    /********************************************************************************************
    * Set message as read
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION set_status_read
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN pending_issue_message.id_pending_issue_message%TYPE,
        i_flg_from   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set message as replied
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION set_status_reply
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN pending_issue_message.id_pending_issue_message%TYPE,
        i_flg_from   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set message as cancelled
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION set_status_cancel
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN pending_issue_message.id_pending_issue_message%TYPE,
        i_flg_from   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set message as unread
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION set_status_unread
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN pending_issue_message.id_pending_issue_message%TYPE,
        i_flg_from   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set message as sent
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION set_status_sent
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN pending_issue_message.id_pending_issue_message%TYPE,
        i_flg_from   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get message thread
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_thread                                 Thread message identifier
    * @param i_thread_level                               maximum thread level (message being seen)
    *
    * @return                 table of messages
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/16
    ********************************************************************************************/
    FUNCTION get_message_thread
    (
        i_lang         IN language.id_language%TYPE,
        i_id_thread    IN pending_issue_message.id_pending_issue%TYPE,
        i_thread_level IN pending_issue_message.thread_level%TYPE
    ) RETURN t_tbl_msg;
    FUNCTION set_pi_sender
    (
        i_lang           IN language.id_language%TYPE,
        i_id_thread      IN pending_issue.id_pending_issue%TYPE,
        i_id_msg         IN pending_issue_message.id_pending_issue_message%TYPE,
        i_from           IN VARCHAR2,
        i_sender_state   IN VARCHAR2,
        i_receiver_state IN VARCHAR2,
        i_rep_str        IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /* Get Patient age attribute */
    FUNCTION get_pat_age
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE
    ) RETURN NUMBER;
    /* Get Patient gender attribute */
    FUNCTION get_pat_gender
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    /* Get Patient photo path attribute */
    FUNCTION get_pat_photo
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        i_id_prof IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;
    /* Filter search method defined as lucene in configuration 
    *  Returns a list of message ids that contains terms both in patient (sender) name 
    *  or in message subject 
    *  or in representative tag
    */
    FUNCTION search_messages
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_search_term IN VARCHAR2
    ) RETURN table_number;
    /* Get Last Message inserted */
    FUNCTION get_latest_message
    (
        i_id_thread pending_issue_message.id_pending_issue%TYPE,
        i_id_parent pending_issue_message.id_pending_issue_message%TYPE
    ) RETURN NUMBER;
    /********************************************************************************************
    * Set New Messages messages
    *
    * @param i_lang                                         Prefered language ID
    * @param i_flg_from                                     DEfinition for message sender (F - facility professional or P - patient)
    * @param i_rep_str                                     Legal representative text
    * @param i_id_prof                                     profissional type
    * @param i_id_patient                                  Patient ID
    * @param i_msg_subject                                 Mesage title or subject
    * @param i_msg_body                                    MEssage body or text max 1000 char
    * @param i_id_msg_rep                                  If reply need message parent id
    * @param i_id_thread                                   If reply need message thread id
    * @param o_new_msg_id                                  New message identification
    * @param o_error                                     Error type identifier
    *
    *
    * @return                  Boolean (true or false)
    *
    * @author                  RMGM
    * @version                 2.6.4.2.1
    * @since                   2014/10/17
    ********************************************************************************************/
    FUNCTION set_message
    (
        i_lang        IN language.id_language%TYPE,
        i_flg_from    IN VARCHAR2,
        i_rep_str     IN VARCHAR2,
        i_id_prof     IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_msg_subject IN VARCHAR2,
        i_msg_body    IN CLOB,
        i_id_msg_rep  IN pending_issue_message.id_pending_issue_message%TYPE,
        i_id_thread   IN OUT pending_issue_message.id_pending_issue%TYPE,
        i_commit      IN VARCHAR2,
        o_new_msg_id  OUT pending_issue_message.id_pending_issue_message%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /* Get Message sender flag */
    FUNCTION get_message_sender
    (
        i_id_msg     IN pending_issue_message.id_pending_issue_message%TYPE,
        o_flg_sender OUT pending_issue_sender.flg_sender%TYPE
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set message in previous status
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param i_flg_from                             O - outbox, I - Inbox
    * @param o_error                                error details return
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.2
    * @since                   2014/10/27
    ********************************************************************************************/
    FUNCTION set_msg_prev_status
    (
        i_lang       IN language.id_language%TYPE,
        i_id_message IN pending_issue_message.id_pending_issue_message%TYPE,
        i_flg_from   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);
    exception1 EXCEPTION;
    exception2 EXCEPTION;
    g_found BOOLEAN;
    -- messaging globals
    g_patient_sender      VARCHAR2(1 CHAR);
    g_professional_sender VARCHAR2(1 CHAR);
    g_unread_status       VARCHAR2(1 CHAR);
    g_read_status         VARCHAR2(1 CHAR);
    g_reply_status        VARCHAR2(1 CHAR);
    g_cancel_status       VARCHAR2(1 CHAR);
    g_sent_status         VARCHAR2(1 CHAR);

    g_flg_outbox VARCHAR2(1 CHAR);
    g_flg_inbox  VARCHAR2(1 CHAR);
END pk_backoffice_pending_issues;
/
