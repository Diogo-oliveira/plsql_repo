/*-- Last Change Revision: $Rev: 2028857 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_pending_issues IS

    /**
     * This function returns a string in the following format:
     * 'Re: Re: Re: '
     *
     * @param i_lang         IN Language ID
     * @param i_thread_level IN Number of message replies
     *
     * @return VARCHAR2
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-11
     * @scope   Private
    */
    FUNCTION build_reply_string
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_thread_level IN pending_issue_message.thread_level%TYPE
    ) RETURN VARCHAR2;

    /**
     * This function verifies if the professional have read the message or not.
     *
     * @param i_prof    IN PROFESSIONAL ARRAY
     * @param i_message IN Message ID
     *
     * @return VARCHAR2
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-11
     * @scope   Private
    */
    FUNCTION is_unread_message
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN PROFISSIONAL,
        i_issue   IN pending_issue.id_pending_issue%TYPE,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE
    ) RETURN VARCHAR2;

    /**
     * This function verifies if the professional have read the message or not.
     *
     * @param i_prof    IN PROFESSIONAL ARRAY
     * @param i_message IN Message ID
     *
     * @return VARCHAR2
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-11
     * @scope   Private
    */
    FUNCTION is_unread_message_flg
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN PROFISSIONAL,
        i_issue   IN pending_issue.id_pending_issue%TYPE,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE
    ) RETURN VARCHAR2;

    /**
     * This function returns the name of all professionals
     * involved in the issue
     *
     * @param  IN Array of professionals IDs
     *
     * @return VARCHAR2
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Private
    */
    FUNCTION get_prof_assigned(i_assigned IN TABLE_NUMBER) RETURN VARCHAR2;

    /**
     * This function returns the name of the professional.
     *
     * @param  IN    i_lang           Language ID
     * @param  IN    i_prof           Professional ID
     * @param  OUT   o_prof_name      Professional's Name
     * @param  OUT   o_error          Error Message
     * 
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */

    /**
     * This function returns all professionals whose name is similar to
     * the parameter i_prof_name.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_prof         Professional type (Id, Institution and Software)
     * @param  IN  i_prof_name    Professional name
     * @param  OUT o_assigns      Cursor
     * @param  OUT o_error        Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @since   2009-Apr-07
     * @author  Thiago Brito
    */
    FUNCTION get_assign_search
    (
        i_lang      IN LANGUAGE.id_language%TYPE,
        i_prof      IN PROFISSIONAL,
        i_prof_name IN professional.name%TYPE,
        o_assigns   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the ids of all professionals and groups
     * involved in the issue
     *
     * @param  i_issue NUMBER Issue ID
     *
     * @return VARCHAR2
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Private
    */
    FUNCTION get_assignee_by_issue(i_issue NUMBER) RETURN VARCHAR2;

    /**
     * This function returns the ids of all groups
     * involved in the issue
     *
     * @param  i_issue NUMBER Issue ID
     *
     * @return TABLE_NUMBER
     *
     * @version 2.5
     * @author  Filipe Machado
     * @since   2009-Apr-06
    */
    FUNCTION get_group_assigned(i_issue NUMBER) RETURN TABLE_NUMBER;

    /**
     * This function returns the name of all group
     * passed through the array i_assigned
     *
     * @param  IN Array of professionals IDs
     *
     * @return VARCHAR2
     *
     * @version 2.5
     * @author  Filipe Machado
     * @since   2009-Apr-06
    */
    FUNCTION get_group_assigned(i_assigned IN TABLE_NUMBER) RETURN VARCHAR2;

    FUNCTION get_prof_name
    (
        i_lang      IN LANGUAGE.id_language%TYPE,
        i_prof      IN professional.id_professional%TYPE,
        o_prof_name OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function represents another possibility to get
     * the name of the professional.
     *
     * @param  IN    i_lang           Language ID
     * @param  IN    i_prof           Professional ID
     * @param  OUT   o_prof_name      Professional's Name
     * @param  OUT   o_error          Error Message
     * 
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION get_prof_name
    (
        i_lang      IN LANGUAGE.id_language%TYPE,
        i_prof      IN PROFISSIONAL,
        o_prof_name OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the previous status of an issue.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_issue        Issue ID
     * @param  OUT o_status       Issue's previous status 
     * @param  OUT o_error        Error message
     * 
     * @return boolean
     * 
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-May-11
    */
    FUNCTION get_status_update
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        i_prof   IN PROFISSIONAL,
        i_issue  IN pending_issue.id_pending_issue%TYPE,
        o_status OUT VARCHAR2,
        o_prof   OUT VARCHAR2,
        o_date   OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all titles saved for this institution
     * throught backoffice's application.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_prof         Professional type (id, software, institution)
     * @param  OUT o_titles       Titles' cursor
     * @param  OUT o_error        Error message
     * 
     * @return boolean
     * 
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-May-11
    */
    FUNCTION get_pi_title_list
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        i_prof   IN PROFISSIONAL,
        o_titles OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the issue or message list of status
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_sd_type      Status type (I: Issue - M: Message)
     * @param  OUT o_status       Issue or Message list of status
     * @param  OUT o_error        Error message
     * 
     * @return BOOLEAN
     * 
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Mar-03
     * @scope   Public
    */
    FUNCTION get_status
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_sd_type IN VARCHAR2,
        o_status  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the status message string for the pending issue.
     * This function cannot be used by outside this package. This function
     * was not developed to access data base data directly. This function 
     * only build the string according to the i_flg_status and i_desc_status
     * parameters.
     *
     * @param  IN i_flg_status         Flag status
     * @param  IN i_desc_status        Status description (already translated)
     *
     * @return VARCHAR2
     *
     * @version   2.4.4
     * @since     2009-Apr-02
     * @author    Thiago Brito
    */
    FUNCTION get_status_string
    (
        i_flg_status  IN VARCHAR2,
        i_desc_status IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
     * This function returns the pending issue about the current patient
     * and episode that have been assigned to me.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_prof         Professional type (Id, Institution and Software)
     * @param  IN  i_patient      Patient ID
     * @param  IN  i_episode      Episode ID
     * @param  OUT o_issues       Patient's issues for this episode
     * @param  OUT o_error        Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION get_my_pending_issues_list
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN PROFISSIONAL,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_issues  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all actions related to the 'PENDING_ISSUE.ASSIGN_ISSUE'
     * subject.
     *
     * @param  IN  i_lang         Language ID
     * @param  OUT o_issues       Actions
     * @param  OUT o_error        Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @since   2009-Mar-23
     * @author  Thiago Brito
    */
    FUNCTION get_assign_message_action
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all actions related to the 'PENDING_ISSUE.ISSUE_DETAIL'
     * subject.
     *
     * @param  IN  i_lang         Language ID
     * @param  OUT o_issues       Actions
     * @param  OUT o_error        Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @since   2009-Mar-19
     * @author  Thiago Brito
    */
    FUNCTION get_issue_detail_actions
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all actions related to the 'PENDING_ISSUE.MESSAGE_DETAIL'
     * subject.
     *
     * @param  IN  i_lang         Language ID
     * @param  OUT o_issues       Actions
     * @param  OUT o_error        Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @since   2009-Mar-19
     * @author  Thiago Brito
    */
    FUNCTION get_message_detail_actions
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all actions related to the 'PENDING_ISSUE.MESSAGE_LIST'
     * subject.
     *
     * @param  IN  i_lang         Language ID
     * @param  OUT o_issues       Actions
     * @param  OUT o_error        Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @since   2009-Mar-19
     * @author  Thiago Brito
    */
    FUNCTION get_message_list_actions
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all actions related to the 'PENDING_ISSUE.MESSAGE_VIEW'
     * subject.
     *
     * @param  IN  i_lang         Language ID
     * @param  OUT o_issues       Actions
     * @param  OUT o_error        Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @since   2009-Mar-19
     * @author  Thiago Brito
    */
    FUNCTION get_message_view_actions
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the ALL pending issue about the current patient
     * and episode.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_prof         Professional type (Id, Institution and Software)
     * @param  IN  i_patient      Patient ID
     * @param  IN  i_episode      Episode ID
     * @param  OUT o_issues       Patient's issues for this episode
     * @param  OUT o_error        Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION get_all_pending_issues_list
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN PROFISSIONAL,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_issues  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is used in order to get the groups or professionals that
     * will be assigned to a pending issue
     *
     * When i_flg_type IS NULL then the function returns:
     * Professionals
     * Groups
     *
     * When i_flg_type IS 'G' then all groups will be returned. Finally, when
     * i_flg_type IS 'P' then all professionals will be returned.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_prof         Professional type (Id, Institution and Software)
     * @param  IN  i_flg_type     NULL: level 0; G: groups; P: professionals
     * @param  OUT o_error        Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @since   2009-Apr-07
     * @author  Thiago Brito
    */
    FUNCTION get_assign_list
    (
        i_lang     IN LANGUAGE.id_language%TYPE,
        i_prof     IN PROFISSIONAL,
        i_flg_type IN VARCHAR2,
        o_assigns  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns a list of groups
     *
     * @param  IN  i_lang         Language ID
     * @param  OUT o_groups       List of groups
     * @param  OUT o_error        Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @since   2009-Mar-25
     * @author  Thiago Brito
    */
    FUNCTION get_groups_list
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the following lables:
     *
     * GROUP
     * PROFESSIONAL
     *
     * It is importante to note that at the beggining this function
     * will return only the PROFESSIONAL label because the
     * GROUP parametrization is not defined yet.
     *
     * @param  IN  i_lang         Language ID
     * @param  OUT o_labels       Messages that will be returned
     * @param  OUT o_error        Error message
     *
     * @return boolean
     *
     * @since   2008-Dec-10
     * @version 2.4.4
     * @author  Thiago Brito
    */
    FUNCTION get_groups_to_assign_message
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        o_labels OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns two CURSORs with the ID and NAME for GROUPS
     * and PROFESSIONALS involved in an ISSUE.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_prof         Professional type (Id, Institution and Software)
     * @param  IN  i_issue        Issue ID
     * @param  OUT i_issue        Issue's data
     * @param  OUT o_messages     Messages for the issue
     * @param  OUT o_error        Error message
     *
     * @return boolean
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Apr-22
    */
    FUNCTION get_issue_involved
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        i_prof   IN PROFISSIONAL,
        i_issue  IN pending_issue.id_pending_issue%TYPE,
        o_groups OUT pk_types.cursor_type,
        o_profs  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the issue's detail and all messages
     * for that issue. If i_flg_show_all = 'Y' then all messages
     * will be returned otherwise only the messages assign to the
     * professional id.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_prof         Professional type (Id, Institution and Software)
     * @param  IN  i_issue        Issue ID
     * @param  OUT i_issue        Issue's data
     * @param  OUT o_messages     Messages for the issue
     * @param  OUT o_error        Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION get_issue_detail
    (
        i_lang     IN LANGUAGE.id_language%TYPE,
        i_prof     IN PROFISSIONAL,
        i_issue    IN pending_issue.id_pending_issue%TYPE,
        i_flg_view IN VARCHAR2,
        o_issue    OUT pk_types.cursor_type,
        o_messages OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all details of an issue message.
     * 
     * @param    i_lang      IN          Language ID
     * @param    i_prof      IN          Professional type (Id, Institution and Software)
     * @param    i_issue     IN          Issue ID
     * @param    i_message   IN          Message ID
     * @param    o_message   OUT         Messages' List
     * @param    o_error     OUT         Error Message
     * 
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Feb-26
     * @scope   Public
    */
    FUNCTION get_message_detail
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN PROFISSIONAL,
        i_issue   IN pending_issue.id_pending_issue%TYPE,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE,
        o_message OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the status for an issue.
     *
     * @param i_lang      IN          Language ID
     * @param i_issue     IN          Issue's ID
     * @param o_status    OUT         Status' List
     * @param o_error     OUT         Error Message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Mar-04
     * @scope   Public
    */
    FUNCTION get_issue_status
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        i_issue  IN pending_issue.id_pending_issue%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function marks a message as read.
     *
     * @param  i_lang      Language ID
     * @param  i_prof      Professional type (Id, Institution and Software)
     * @param  i_message   Issue Message ID
     * @param  o_error     Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION set_as_read
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN PROFISSIONAL,
        i_issue   IN pending_issue.id_pending_issue%TYPE,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the number of unread messages of a professional for
     * a determined pending issue.
     *
     * @param  IN  i_issue      ID Pending Issue
     * @param  IN  i_id_prof    ID Professional
     *
     * @return PLS_INTEGER
     *
     * @version 2.4.4
     * @sinse   2009-Mar-18
     * @author  Thiago Brito
    */
    FUNCTION get_number_of_unread_messages
    (
        i_issue   pending_issue.id_pending_issue%TYPE,
        i_id_prof professional.id_professional%TYPE
    ) RETURN PLS_INTEGER;

    /**
     * This function computes the number of pixels of a thread. The maximum
     * value, as specified by design team, is 240px.
     *
     * @param i_thread_level number
     *
     * @return NUMBER
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-12-22
     * @scope   Public
    */
    FUNCTION get_pixels(i_thread_level pending_issue_message.thread_level%TYPE) RETURN NUMBER;

    /**
     * This function marks all messages of an issue as read. This function
     * affects only the messages assigned to me.
     *
     * @param  i_lang      Language ID
     * @param  i_prof      Professional type (Id, Institution and Software)
     * @param  i_issue     Issue ID
     * @param  o_error     Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION set_all_as_read
    (
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN PROFISSIONAL,
        i_issue IN pending_issue.id_pending_issue%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function marks all messages of an issue as Unread. This function
     * affects only the messages assigned to the professional identified
     * by the parameter i_prof.id
     *
     * @param  i_lang      Language ID
     * @param  i_prof      Professional type (Id, Institution and Software)
     * @param  i_issue     Issue ID
     * @param  o_error     Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-23
     * @scope   Public
    */
    FUNCTION set_all_as_unread
    (
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN PROFISSIONAL,
        i_issue IN pending_issue.id_pending_issue%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function marks a message as unread.
     *
     * @param  i_lang      Language ID
     * @param  i_prof      Professional type (Id, Institution and Software)
     * @param  i_message   Issue Message ID
     * @param  o_error     Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION set_as_unread
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN PROFISSIONAL,
        i_issue   IN pending_issue.id_pending_issue%TYPE,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * Insert or update an issue. If the parameter i_issue is NULL
     * this function will create a new issue. Otherwise, an update
     * will be performed.
     *
     * @param i_lang        Language ID
     * @param i_prof        Professional type (Id, Institution and Software)
     * @param i_issue       Issue ID (NULL for insert; NOT NULL for update)
     * @param i_title       Issue's Title
     * @param i_patient     Patient ID
     * @param i_episode     Episode ID
     * @param i_assigns     Array of professional's IDs
     * @param i_status      Status of the issue
     * @param i_subject     First message subject
     * @param i_message     First message text
     * @param o_error       Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION set_issue
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN PROFISSIONAL,
        i_issue   IN OUT pending_issue.id_pending_issue%TYPE,
        i_title   IN VARCHAR2,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_assigns IN TABLE_NUMBER,
        i_status  IN VARCHAR2,
        i_subject IN VARCHAR2,
        i_message IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function was developed to support the issue's creation
     * associated with a group of professionals.
     * It is important to note that this function will create a pending
     * issue for all professionals related with that group.
     *
     * @param i_lang        Language ID
     * @param i_prof        Professional type (Id, Institution and Software)
     * @param i_issue       Issue ID (NULL for insert; NOT NULL for update)
     * @param i_title       Issue's Title
     * @param i_patient     Patient ID
     * @param i_episode     Episode ID
     * @param i_group       Group ID
     * @param i_status      Status of the issue
     * @param i_subject     First message subject
     * @param i_message     First message text
     * @param o_error       Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Mar-18
    */
    FUNCTION set_issue_group
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN PROFISSIONAL,
        i_issue   IN OUT pending_issue.id_pending_issue%TYPE,
        i_title   IN VARCHAR2,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_group   IN TABLE_NUMBER,
        i_status  IN VARCHAR2,
        i_subject IN VARCHAR2,
        i_message IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * Insert or update an issue. If the parameter i_issue is NULL
     * this function will create a new issue. Otherwise, an update
     * will be performed.
     *
     * @param i_lang        Language ID
     * @param i_prof        Professional type (Id, Institution and Software)
     * @param i_issue       Issue ID (NULL for insert; NOT NULL for update)
     * @param i_title       Issue's Title
     * @param i_patient     Patient ID
     * @param i_episode     Episode ID
     * @param i_group       Table of groups's IDs
     * @param i_profs       Table of professional's IDs
     * @param i_status      Status of the issue
     * @param i_subject     First message subject
     * @param i_message     First message text
     * @param o_error       Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */

    FUNCTION set_issue_prof_group
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN PROFISSIONAL,
        i_issue   IN OUT pending_issue.id_pending_issue%TYPE,
        i_title   IN VARCHAR2,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_group   IN TABLE_NUMBER,
        i_profs   IN TABLE_NUMBER,
        i_status  IN VARCHAR2,
        i_subject IN VARCHAR2,
        i_message IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is supposed to be used for UPDATE a message.
     *
     *
     * @param i_lang               Language ID
     * @param i_prof               Professional type (Id, Institution and Software)
     * @param i_id_issue           Issue ID
     * @param i_id_message         Message ID
     * @param i_message_title      Message title
     * @param i_message_body       Message body
     * @param o_error              Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Apr-08
    */
    FUNCTION set_message
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN PROFISSIONAL,
        i_id_issue      IN pending_issue.id_pending_issue%TYPE,
        i_id_message    IN pending_issue_message.id_pending_issue_message%TYPE,
        i_message_title IN VARCHAR2,
        i_message_body  IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * Create (new or reply) a message. The level field will be incremented if
     * flg_reply = 'Y'. Otherwise, the level field will be the same.
     *
     * @param i_lang        Language ID
     * @param i_prof        Professional type (Id, Institution and Software)
     * @param i_issue       Issue ID
     * @param flg_reply     'Y' for a reply action. 'N' for a new message
     * @param i_parent_msg  Parent message ID
     * @param i_subject     First message subject
     * @param i_message     First message text
     * @param o_error       Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION set_message
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN PROFISSIONAL,
        i_issue      IN pending_issue.id_pending_issue%TYPE,
        i_flg_reply  IN VARCHAR2,
        i_parent_msg IN pending_issue_message.id_pending_issue_msg_parent%TYPE,
        i_subject    IN VARCHAR2,
        i_message    IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is responsible for the update of the issue's status
     * as well as the professionals and/or groups assigned to that issue.
     *
     * @param  i_lang               Language ID
     * @param  i_prof               Professional type (Id, Institution and Software)
     * @param  i_issue              Pending Issue ID
     * @param  i_issue_status       Issue's status
     * @param  i_groups             Groups IDs
     * @param  i_profs              Professionals IDs
     * @param  o_error              Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Apr-22
    */
    FUNCTION set_issue_status_involved
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN PROFISSIONAL,
        i_issue        IN OUT pending_issue.id_pending_issue%TYPE,
        i_issue_status IN pending_issue.flg_status%TYPE,
        i_groups       IN TABLE_NUMBER,
        i_profs        IN TABLE_NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function was developed to support changes in the
     * pending issue's assignment.
     *
     * @param  i_lang      Language ID
     * @param  i_prof      Professional type (Id, Institution and Software)
     * @param  i_issue     Pending Issue ID
     * @param  i_groups    Groups IDs
     * @param  i_profs     Professionals IDs
     * @param  o_error     Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Apr-09
    */
    FUNCTION update_involved
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        i_prof   IN PROFISSIONAL,
        i_issue  IN OUT pending_issue.id_pending_issue%TYPE,
        i_groups IN TABLE_NUMBER,
        i_profs  IN TABLE_NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function cancels a pending issue. The flg_status will be updated to 'C'.
     * The register won't be removed from the data base.
     *
     * @param i_lang        Language ID
     * @param i_prof        Professional type (Id, Institution and Software)
     * @param i_issue       Issue ID
     * @param o_error       Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION cancel_issue
    (
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN PROFISSIONAL,
        i_issue IN pending_issue.id_pending_issue%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function cancels all messages associated with an issue.
     *
     * @param i_lang        Language ID
     * @param i_prof        Professional type (Id, Institution and Software)
     * @param i_issue       Issue ID
     * @param o_error       Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-11
     * @scope   Public
    */
    FUNCTION cancel_all_issue_messages
    (
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN PROFISSIONAL,
        i_issue IN pending_issue.id_pending_issue%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function cancels a pending message. The flg_status will be updated to 'C'.
     * The register won't be removed from the data base.
     *
     * @param i_lang        Language ID
     * @param i_prof        Professional type (Id, Institution and Software)
     * @param i_message     Message ID
     * @param o_error       Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION cancel_message
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN PROFISSIONAL,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function changes the status of an issue.
     *
     * @param i_lang        Language ID
     * @param i_prof        Professional type (Id, Institution and Software)
     * @param i_issue       Message ID
     * @param i_status      Status flag
     * @param o_error       Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION set_issue_status
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        i_prof   IN PROFISSIONAL,
        i_issue  IN pending_issue.id_pending_issue%TYPE,
        i_status IN pending_issue.flg_status%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function must be used to verify if the option "assign to me"
     * should be available or not.
     *
     * @param  IN  i_lang           Language ID
     * @param  IN  i_prof           PROFESSIONAL type (id, institution, software)
     * @param  IN  i_pending_issue  Pending Issu ID
     * @param  OUT o_show           Y: Show; N: Hidden
     * @param  OUT o_error          Error message
     *
     * @return BOOLEAN
     *
     * @version 2.5.0.4
     * @since   2009-Jun-29
     * @author  Thiago Brito
     *
    */
    FUNCTION get_assign_to_me_flg
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN PROFISSIONAL,
        i_pending_issue IN pending_issue.id_pending_issue%TYPE,
        o_show          OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(4000) := '';
    --
    /**
     * Get most recent episode of the same software
     *
     * @param  IN  i_prof           PROFESSIONAL type (id, institution, software)
     * @param  IN  i_patient        Patient ID
     *
     * @return BOOLEAN
     *
     * @version 2.6.1.4
     * @since   2011-Out-26
     * @author  Rui Duarte
     *
    */
    FUNCTION get_most_recent_epis
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;
    --
    /**
     * This function returns the pending issue for reports by scope
     *
     * @param  IN  i_lang                Language ID
     * @param  IN  i_prof                Professional type (Id, Institution and Software)
     * @param  IN  i_patient             Patient ID
     * @param  IN  i_episode             Episode ID
     * @param  IN  i_flg_show_all        Show all pending issue or show only for current user
     * @param  IN  i_flg_filter          Episode ID
     * @param  OUT o_issues              Patient's issues for this episode
     * @param  OUT o_error               Error message
     *
     * @return boolean
     *
     * @version 2.6.1
     * @author  Rui Duarte
     * @since   2011-Out-27
     * @scope   Public
    */
    FUNCTION get_rep_pending_issues_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_show_all IN VARCHAR2,
        i_flg_filter   IN VARCHAR2,
        o_issues       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    
    -- issue
    g_issue_flg_status_open      CONSTANT VARCHAR2(1) := 'O';
    g_issue_flg_status_ongoing   CONSTANT VARCHAR2(1) := 'G';
    g_issue_flg_status_closed    CONSTANT VARCHAR2(1) := 'C';
    g_issue_flg_status_cancelled CONSTANT VARCHAR2(1) := 'X';

    -- messages
    g_msg_flg_new_y            CONSTANT VARCHAR2(1) := 'Y'; -- NEW MESSAGE
    g_msg_flg_new_n            CONSTANT VARCHAR2(1) := 'N'; -- NOT NEW MESSAGE
    g_msg_flg_status_active    CONSTANT VARCHAR2(1) := 'A';
    g_msg_flg_status_cancelled CONSTANT VARCHAR2(1) := 'C';

    -- messages prof
    g_msg_prof_flg_status_active CONSTANT VARCHAR2(1) := 'A';
    g_msg_prof_flg_status_cancel CONSTANT VARCHAR2(1) := 'C';

    -- get issues
    g_all_issues CONSTANT VARCHAR2(1) := 'Y';
    g_my_issues  CONSTANT VARCHAR2(1) := 'N';

    -- issue detail's view
    g_view_by_date   CONSTANT VARCHAR2(1) := 'D';
    g_view_by_thread CONSTANT VARCHAR2(1) := 'T';

    -- sys_domain
    g_pending_issue         CONSTANT VARCHAR2(200) := 'PENDING_ISSUE.FLG_STATUS';
    g_pending_issue_message CONSTANT VARCHAR2(200) := 'PENDING_ISSUE_MESSAGE.FLG_STATUS';
    g_pending_issue_prof    CONSTANT VARCHAR2(200) := 'PENDING_ISSUE_PROF.FLG_STATUS';

    -- flash pixels
    g_pixels_factor CONSTANT PLS_INTEGER := 15;
    g_pixels_max    CONSTANT PLS_INTEGER := 240;

    -- alerts
    g_pending_issue_alert CONSTANT PLS_INTEGER := 52;

    -- exceptions
    g_exception EXCEPTION;
    g_exception_user EXCEPTION;
    g_action_type_user    CONSTANT VARCHAR2(1) := 'U';
    g_action_type_system  CONSTANT VARCHAR2(1) := 'S';
    g_action_type_default CONSTANT VARCHAR2(1) := 'D';

    -- active
    g_active CONSTANT VARCHAR2(1) := 'A';

    -- involved
    g_professionals CONSTANT VARCHAR2(1) := 'P';
    g_groups        CONSTANT VARCHAR2(1) := 'G';

    g_flg_available_y CONSTANT VARCHAR2(1) := 'Y';
    g_flg_available_n CONSTANT VARCHAR2(1) := 'N';

    g_is_owner_n CONSTANT VARCHAR2(1) := 'N';
    g_is_owner_y CONSTANT VARCHAR2(1) := 'Y';

    -- status string
    g_color_red    CONSTANT VARCHAR2(8) := '0xC86464'; -- VERMELHO
    g_color_orange CONSTANT VARCHAR2(8) := '0xD2A05A'; -- LARANJA
    g_color_beige  CONSTANT VARCHAR2(8) := '0xC6C9B3'; -- BEGE
    g_font_p       CONSTANT VARCHAR2(50) := 'ViewerState'; -- PASSIVO
    g_font_o       CONSTANT VARCHAR2(50) := 'ViewerCancelState'; -- OUTROS

    -- prof cats
    g_physician_category     PLS_INTEGER := 1;
    g_nurse_category         PLS_INTEGER := 2;
    g_registrar_category     PLS_INTEGER := 4;
    g_ancillary_category     PLS_INTEGER := 6;
    g_social_worker_category PLS_INTEGER := 25;
	g_nutri_category         PLS_INTEGER := 29;
	
	g_list_separator CONSTANT VARCHAR2(2) := '; ';

END pk_pending_issues;
/
