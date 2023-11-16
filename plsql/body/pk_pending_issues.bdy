/*-- Last Change Revision: $Rev: 2027475 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:20 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE BODY pk_pending_issues IS

    /**
     * Set the alert message
     *
     * @param i_lang         IN Language ID
     * @param i_thread_level IN Number of message replies
     *
     * @return VARCHAR2
     *
     * @version 2.5.1
     * @author  Filipe Machado
     * @since   08-Jul-2010
     * @scope   Private
     * @reason  ALERT-109743
     * Updated by Gisela Couto - 17-04-2014
    */

    FUNCTION set_alert_msg
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_issue         IN pending_issue.id_pending_issue%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_visit         IN visit.id_visit%TYPE,
        i_receptor_prof IN professional.id_professional%TYPE,
        i_issue_message IN pending_issue_message.id_pending_issue_message%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_next_message_id NUMBER(24, 0);
        l_alert_event_row sys_alert_event%ROWTYPE;
        l_title           pending_issue.title%TYPE;
        l_pi_subject      VARCHAR2(4000);
    
    BEGIN
    
        SELECT pi.title
          INTO l_title
          FROM pending_issue pi
         WHERE pi.id_pending_issue = i_issue;
    
        IF (i_receptor_prof = i_prof.id)
        THEN
            l_pi_subject := pk_message.get_message(i_lang, 'PENDING_ISSUE_M005');
        ELSE
            l_pi_subject := pk_message.get_message(i_lang, 'PENDING_ISSUE_M006');
        END IF;
    
        l_alert_event_row.id_sys_alert        := g_pending_issue_alert;
        l_alert_event_row.id_software         := i_prof.software;
        l_alert_event_row.id_institution      := i_prof.institution;
        l_alert_event_row.id_episode          := nvl(i_episode, -1);
        l_alert_event_row.id_patient          := i_patient;
        l_alert_event_row.id_visit            := nvl(i_visit, -1);
        l_alert_event_row.id_record           := i_issue_message;
        l_alert_event_row.dt_record           := current_timestamp;
        l_alert_event_row.id_professional     := i_receptor_prof;
        l_alert_event_row.id_room             := NULL;
        l_alert_event_row.id_clinical_service := NULL;
        l_alert_event_row.replace1            := l_pi_subject;
        l_alert_event_row.replace2            := l_title;
    
        IF (NOT pk_alerts.insert_sys_alert_event(i_lang,
                                                 profissional(i_receptor_prof, i_prof.institution, i_prof.software),
                                                 l_alert_event_row,
                                                 o_error))
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END set_alert_msg;

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
        i_lang         IN language.id_language%TYPE,
        i_thread_level IN pending_issue_message.thread_level%TYPE
    ) RETURN VARCHAR2 IS
    
        l_replay_string VARCHAR2(4000) := '';
        l_sys_domain_rs VARCHAR2(2000) := pk_message.get_message(i_lang, 'PENDING_ISSUE_T042');
    
    BEGIN
    
        IF (i_thread_level = -1)
        THEN
        
            RETURN l_sys_domain_rs;
        
        ELSE
        
            FOR i IN 1 .. i_thread_level
            LOOP
                l_replay_string := l_replay_string || ' ' || l_sys_domain_rs;
            END LOOP;
        
            RETURN l_replay_string;
        
        END IF;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            RETURN NULL;
        
    END build_reply_string;

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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_issue   IN pending_issue.id_pending_issue%TYPE,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE
    ) RETURN VARCHAR2 IS
    
        l_msg VARCHAR2(200) := '';
    
    BEGIN
        SELECT decode(pip.dt_read, NULL, pk_message.get_message(i_lang, 'PENDING_ISSUE_T045'), '')
          INTO l_msg
          FROM pending_issue_prof pip
         WHERE pip.id_pending_issue_message = i_message
           AND pip.id_pending_issue = i_issue
           AND pip.id_professional = i_prof.id;
    
        RETURN l_msg;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
        
    END is_unread_message;

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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_issue   IN pending_issue.id_pending_issue%TYPE,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE
    ) RETURN VARCHAR2 IS
    
        l_msg VARCHAR2(200) := '';
    
    BEGIN
        SELECT decode(pip.dt_read, NULL, 'Y', 'N')
          INTO l_msg
          FROM pending_issue_prof pip
         WHERE pip.id_pending_issue_message = i_message
           AND pip.id_pending_issue = i_issue
           AND pip.id_professional = i_prof.id;
    
        RETURN l_msg;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
        
    END is_unread_message_flg;

    /**
     * This function returns the name of all professionals
     * passed through the array i_assigned
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
    FUNCTION get_prof_assigned(i_assigned IN table_number) RETURN VARCHAR2 IS
    
        v_name  VARCHAR2(4000) := '';
        va_name table_varchar2;
    
    BEGIN
    
        SELECT nvl(p.nick_name, p.name)
          BULK COLLECT
          INTO va_name
          FROM professional p
         WHERE p.id_professional IN (SELECT column_value
                                       FROM TABLE(i_assigned))
         ORDER BY p.nick_name;
    
        FOR i IN 1 .. va_name.last
        LOOP
            IF (i = 1)
            THEN
                v_name := va_name(i);
            ELSE
                v_name := v_name || g_list_separator || va_name(i);
            END IF;
        END LOOP;
    
        RETURN v_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_prof_assigned;

    /**
     * This function returns the ids of all professionals
     * involved in the issue
     *
     * @param  i_issue NUMBER Issue ID
     *
     * @return TABLE_NUMBER
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Private
    */
    FUNCTION get_prof_assigned(i_issue NUMBER) RETURN table_number IS
    
        l_ids_issues table_number;
    
    BEGIN
    
        SELECT DISTINCT pii.id_involved
          BULK COLLECT
          INTO l_ids_issues
          FROM pending_issue_involved pii
         WHERE pii.id_pending_issue = i_issue
           AND pii.flg_involved = g_professionals;
    
        IF (SQL%ROWCOUNT > 0)
        THEN
            RETURN l_ids_issues;
        ELSE
            RETURN table_number(0);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number(0);
        
    END get_prof_assigned;

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
     * @scope   Private
    */
    FUNCTION get_group_assigned(i_issue NUMBER) RETURN table_number IS
    
        l_ids_groups table_number;
    
    BEGIN
    
        SELECT DISTINCT id_involved
          BULK COLLECT
          INTO l_ids_groups
          FROM pending_issue_involved pig
         WHERE pig.id_pending_issue = i_issue
           AND pig.flg_involved = g_groups;
    
        IF (l_ids_groups.count > 0)
        THEN
            RETURN l_ids_groups;
        ELSE
            RETURN table_number(0);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number(0);
        
    END get_group_assigned;

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
     * @scope   Private
    */
    FUNCTION get_group_assigned(i_assigned IN table_number) RETURN VARCHAR2 IS
    
        v_name  VARCHAR2(4000) := '';
        va_name table_varchar2;
    
    BEGIN
    
        SELECT g.name
          BULK COLLECT
          INTO va_name
          FROM groups g
         WHERE g.id_group IN (SELECT column_value
                                FROM TABLE(i_assigned))
         ORDER BY g.name;
    
        FOR i IN 1 .. va_name.last
        LOOP
            IF (i = 1)
            THEN
                v_name := va_name(i);
            ELSE
                v_name := v_name || g_list_separator || va_name(i);
            END IF;
        END LOOP;
    
        RETURN v_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_group_assigned;

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
    FUNCTION get_assignee_by_issue(i_issue NUMBER) RETURN VARCHAR2 IS
    
        i_profs_ids      table_number;
        l_prof_names     VARCHAR2(4000);
        i_group_ids      table_number;
        l_group_names    VARCHAR2(4000);
        l_assignee_names VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'GET_ASSIGNEE_BY_ISSUE - Getting the Professional IDs';
        SELECT pii.id_involved
          BULK COLLECT
          INTO i_profs_ids
          FROM pending_issue_involved pii
         WHERE pii.flg_involved = g_professionals
           AND pii.id_pending_issue = i_issue;
    
        g_error      := 'GET_ASSIGNEE_BY_ISSUE - Getting the Professional Names';
        l_prof_names := get_prof_assigned(i_profs_ids);
    
        g_error := 'GET_ASSIGNEE_BY_ISSUE - Getting the Group IDs';
        SELECT pii.id_involved
          BULK COLLECT
          INTO i_group_ids
          FROM pending_issue_involved pii
         WHERE pii.flg_involved = g_groups
           AND pii.id_pending_issue = i_issue;
    
        g_error       := 'GET_ASSIGNEE_BY_ISSUE - Getting the Group Names';
        l_group_names := get_group_assigned(i_group_ids);
    
        l_assignee_names := '';
        IF ((l_prof_names IS NOT NULL) AND (l_group_names IS NOT NULL))
        THEN
            -- groups and professionals
            l_assignee_names := l_group_names || g_list_separator || l_prof_names;
        ELSIF ((l_prof_names IS NULL) AND (l_group_names IS NOT NULL))
        THEN
            -- only groups
            l_assignee_names := l_group_names;
        ELSIF ((l_prof_names IS NOT NULL) AND (l_group_names IS NULL))
        THEN
            -- only professionals
            l_assignee_names := l_prof_names;
        END IF;
    
        RETURN l_assignee_names;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_assignee_by_issue;

    FUNCTION get_assigned(i_issue IN NUMBER) RETURN table_number IS
    
        l_prof_prof  table_number;
        l_prof_group table_number;
        l_profs      table_number := table_number();
    
    BEGIN
    
        SELECT DISTINCT pii.id_involved
          BULK COLLECT
          INTO l_prof_prof
          FROM pending_issue_involved pii
         WHERE pii.id_pending_issue = i_issue
           AND pii.flg_involved = g_professionals;
    
        SELECT pg.id_professional
          BULK COLLECT
          INTO l_prof_group
          FROM prof_groups pg
         WHERE pg.id_group IN (SELECT DISTINCT pii.id_involved
                                 FROM pending_issue_involved pii
                                WHERE pii.id_pending_issue = i_issue
                                  AND pii.flg_involved = g_groups)
           AND pg.flg_state = 'A';
    
        SELECT column_value
          BULK COLLECT
          INTO l_profs
          FROM (SELECT column_value
                  FROM TABLE(l_prof_prof)
                UNION
                SELECT column_value
                  FROM TABLE(l_prof_group));
    
        RETURN l_profs;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number(0);
        
    END get_assigned;

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
    FUNCTION get_prof_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN professional.id_professional%TYPE,
        o_prof_name OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUE.GET_ISSUE_LIST';
    
        BEGIN
            SELECT nvl(p.nick_name, p.name)
              INTO o_prof_name
              FROM professional p
             WHERE p.id_professional = i_prof;
        EXCEPTION
            WHEN too_many_rows THEN
                o_prof_name := '';
            WHEN no_data_found THEN
                o_prof_name := '';
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_PROF_NAME',
                                                     o_error);
        
    END get_prof_name;

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
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_name OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUE.GET_ISSUE_LIST';
    
        IF (NOT get_prof_name(i_lang, i_prof.id, o_prof_name, o_error))
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_prof_name;

    /**
     * This function returns all professionals associated with a group.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_group        Group IDs
     * @param  OUT o_error        Error message
     * 
     * @return TABLE_NUMBER
     * 
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Apr-22
    */
    FUNCTION get_profs_by_group
    (
        i_lang  IN language.id_language%TYPE,
        i_group table_number,
        o_error OUT t_error_out
    ) RETURN table_number IS
    
        l_id_professionals table_number;
    
    BEGIN
    
        SELECT pg.id_professional
          BULK COLLECT
          INTO l_id_professionals
          FROM prof_groups pg
         WHERE pg.id_group IN (SELECT column_value
                                 FROM TABLE(i_group))
           AND pg.flg_state = 'A';
    
        RETURN l_id_professionals;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'GET_PROFS_BY_GROUP',
                                              o_error);
        
            RETURN table_number();
        
    END get_profs_by_group;

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
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_issue  IN pending_issue.id_pending_issue%TYPE,
        o_status OUT VARCHAR2,
        o_prof   OUT VARCHAR2,
        o_date   OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        SELECT decode(pi.flg_status_hist,
                      NULL,
                      '',
                      REPLACE(REPLACE(pk_message.get_message(i_lang, 'PENDING_ISSUE_T060'),
                                      '@1',
                                      pk_sysdomain.get_domain('PENDING_ISSUE.FLG_STATUS', pi.flg_status, i_lang)),
                              '@2',
                              pk_sysdomain.get_domain('PENDING_ISSUE.FLG_STATUS', pi.flg_status_hist, i_lang))) AS issue_status,
               pk_prof_utils.get_name_signature(i_lang, i_prof, pi.id_prof_update) prof_name,
               pk_date_utils.date_send_tsz(i_lang, pi.dt_update, i_prof) issue_update
          INTO o_status, o_prof, o_date
          FROM pending_issue pi
         WHERE pi.id_pending_issue = i_issue;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'GET_STATUS_UPDATE',
                                              o_error);
        
            RETURN FALSE;
        
    END get_status_update;

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
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_titles OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_titles FOR
            SELECT DISTINCT pitd.id_pending_issue_title, pit.desc_title, 1 rank
              FROM pending_issue_title_dept pitd
              JOIN pending_issue_title pit
                ON pitd.id_pending_issue_title = pit.id_pending_issue_title
              JOIN dept d
                ON pitd.id_dept = d.id_dept
             WHERE d.id_institution = i_prof.institution
            UNION
            SELECT -1 id_pending_issue_title, pk_message.get_message(i_lang, 'COMMON_M041') desc_title, 999 rank
              FROM dual
             ORDER BY rank, desc_title;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'GET_PI_TITLE_LIST',
                                              o_error);
        
            RETURN FALSE;
        
    END get_pi_title_list;

    /**
     * This function returns the issue or message list of status
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_sd_type      Status type (I: Issue - M: Message)
     * @param  OUT o_status       Issue or Message list of status
     * @param  OUT o_error        Error message
     * 
     * @return boolean
     * 
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Mar-03
     * @scope   Public
    */
    FUNCTION get_status
    (
        i_lang    IN language.id_language%TYPE,
        i_sd_type IN VARCHAR2,
        o_status  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code VARCHAR2(200);
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUES.GET_STATUS / CASE ';
    
        CASE
            WHEN upper(i_sd_type) = 'I' THEN
                l_code := g_pending_issue;
            WHEN upper(i_sd_type) = 'M' THEN
                l_code := g_pending_issue_message;
            ELSE
                l_code := g_pending_issue;
        END CASE;
    
        g_error := 'PK_PENDING_ISSUES.GET_STATUS / OPEN CURSOR ';
    
        OPEN o_status FOR
            SELECT sd.code_domain, sd.val, sd.desc_val, sd.img_name
              FROM sys_domain sd
             WHERE sd.code_domain = l_code
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_STATUS',
                                                     o_error);
        
    END get_status;

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
    ) RETURN VARCHAR2 IS
    
        l_shortcut      PLS_INTEGER := NULL;
        l_display_type  VARCHAR2(2) := 'T';
        l_date          VARCHAR2(200) := NULL; -- [<year> <month> <day> <hour> <minute> <second>]
        l_text          VARCHAR2(200);
        l_icon_name     VARCHAR2(200) := '';
        l_back_color    VARCHAR2(200); -- [“0x” <red>  <green>  <blue>]
        l_message_style VARCHAR2(200) := NULL;
        l_message_color VARCHAR2(200) := NULL;
        l_icon_color    VARCHAR2(200) := NULL;
        l_date_server   TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        l_text := i_desc_status;
    
        CASE i_flg_status
            WHEN g_issue_flg_status_open THEN
                -- ACTIVO
                l_back_color    := g_color_red; -- VERMELHO
                l_icon_color    := g_color_red;
                l_message_style := g_font_p;
            WHEN g_issue_flg_status_ongoing THEN
                -- EM CURSO
                l_back_color    := g_color_orange; -- LARANJA
                l_icon_color    := g_color_orange;
                l_message_style := g_font_p;
            WHEN g_issue_flg_status_closed THEN
                -- FECHADA
                l_back_color    := g_color_beige;
                l_icon_color    := g_color_beige;
                l_message_style := g_font_o;
            WHEN 'X' THEN
                -- CANCELADA
                l_back_color    := g_color_beige;
                l_icon_color    := g_color_beige;
                l_message_style := g_font_o;
            ELSE
                l_back_color    := g_color_beige;
                l_icon_color    := g_color_beige;
                l_message_style := g_font_o;
        END CASE;
    
        RETURN l_shortcut || '|' || l_display_type || '|' || l_date || '|' || l_text || '|' || l_icon_name || '|' || l_back_color || '|' || l_message_style || '|' || l_message_color || '|' || l_icon_color || '|' || l_date_server;
    
    END get_status_string;

    /**
     * This function returns the pending issue by scope
     * and episode.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_prof         Professional type (Id, Institution and Software)
     * @param  IN  i_patient      Patient ID
     * @param  IN  i_episode      Episode ID
     * @param  IN  i_prof_id      Professional ID who is logged on the system
     * @param  OUT o_issues       Patient's issues for this episode
     * @param  OUT o_error        Error message
     *
     * @return boolean
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Private
    */
    FUNCTION prv_get_issue_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_show_all IN VARCHAR2,
        i_flg_filter   IN VARCHAR2,
        o_issues       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis                table_number := table_number();
        l_pending_issues_list table_number := table_number();
    BEGIN
    
        g_error := 'Call PK_UTILS.GET_SCOPE ';
        -- get scope of episodes
        l_epis := pk_episode.get_scope(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_patient    => i_patient,
                                       i_episode    => i_episode,
                                       i_flg_filter => i_flg_filter);
    
        g_error := 'Get penfing issue lisy PK_PENDING_ISSUES.GET_ISSUE_LIST_UNIQUE ';
        -- List of pending issues by prof or all
        IF (i_flg_show_all = g_all_issues)
        THEN
            SELECT pi.id_pending_issue
              BULK COLLECT
              INTO l_pending_issues_list
              FROM pending_issue pi
             WHERE pi.id_patient = i_patient
               AND pi.id_episode IN (SELECT *
                                       FROM TABLE(l_epis));
        ELSE
            SELECT pi.id_pending_issue
              BULK COLLECT
              INTO l_pending_issues_list
              FROM pending_issue pi
              JOIN pending_issue_prof pip
                ON pip.id_pending_issue = pi.id_pending_issue
             WHERE pi.id_patient = i_patient
               AND pip.id_professional = i_prof.id
               AND pi.id_episode IN (SELECT *
                                       FROM TABLE(l_epis));
        END IF;
    
        g_error := 'PK_PENDING_ISSUES.GET_ISSUE_LIST_UNIQUE / OPEN CURSOR ';
        OPEN o_issues FOR
            SELECT pi.id_pending_issue,
                   get_number_of_unread_messages(pi.id_pending_issue, i_prof.id) AS total_unread_messages,
                   get_assignee_by_issue(pi.id_pending_issue) AS nick_name,
                   pi.title AS title,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name
                      FROM professional p
                     WHERE p.id_professional IN
                           (SELECT DISTINCT pim.id_professional
                              FROM pending_issue_message pim
                             WHERE pim.id_pending_issue = pi.id_pending_issue
                               AND pim.dt_creation IN (SELECT DISTINCT pim2.dt_creation
                                                         FROM pending_issue_message pim2
                                                        WHERE pim2.id_pending_issue = pi.id_pending_issue
                                                          AND rownum = 1))) AS lu_nick_name,
                   (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            pi.id_professional,
                                                            pi.dt_creation,
                                                            pi.id_episode) speciality
                      FROM professional p
                     WHERE p.id_professional IN
                           (SELECT DISTINCT pim.id_professional
                              FROM pending_issue_message pim
                             WHERE pim.id_pending_issue = pi.id_pending_issue
                               AND pim.dt_creation IN (SELECT DISTINCT pim2.dt_creation
                                                         FROM pending_issue_message pim2
                                                        WHERE pim2.id_pending_issue = pi.id_pending_issue
                                                          AND rownum = 1))) AS lu_speciality,
                   pk_date_utils.date_send_tsz(i_lang, pi.dt_update, i_prof) last_update,
                   pi.flg_status AS flg_status,
                   (SELECT sd.img_name
                      FROM sys_domain sd
                     WHERE sd.code_domain = g_pending_issue
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                       AND sd.val = pi.flg_status) AS icon,
                   decode(pi.flg_status,
                          g_issue_flg_status_open,
                          g_color_red,
                          g_issue_flg_status_ongoing,
                          g_color_orange,
                          g_issue_flg_status_closed,
                          g_color_beige,
                          g_issue_flg_status_cancelled,
                          g_color_beige,
                          g_color_beige) status_color,
                   get_status_string(pi.flg_status, pk_sysdomain.get_domain(g_pending_issue, pi.flg_status, i_lang)) status_str,
                   decode(pi.id_professional, i_prof.id, g_is_owner_y, g_is_owner_n) is_owner,
                   decode(pi.flg_status,
                          g_issue_flg_status_open,
                          1,
                          g_issue_flg_status_ongoing,
                          2,
                          g_issue_flg_status_closed,
                          3,
                          g_issue_flg_status_cancelled,
                          4) AS rank
              FROM pending_issue pi
             WHERE pi.id_pending_issue IN (SELECT *
                                             FROM TABLE(l_pending_issues_list))
             ORDER BY rank, pi.dt_update DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'PRV_GET_ISSUE_LIST',
                                                     o_error);
        
    END prv_get_issue_list;

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
     * @return boolean
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION get_my_pending_issues_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_issues  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUE.GET_MY_PENDING_ISSUES_LIST';
    
        RETURN(prv_get_issue_list(i_lang,
                                  i_prof,
                                  i_patient,
                                  i_episode,
                                  g_my_issues,
                                  pk_alert_constant.g_scope_type_patient,
                                  o_issues,
                                  o_error));
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_MY_PENDING_ISSUES_LIST',
                                                     o_error);
        
    END get_my_pending_issues_list;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUE.GET_REP_PENDING_ISSUES_LIST';
    
        RETURN(prv_get_issue_list(i_lang,
                                  i_prof,
                                  i_patient,
                                  i_episode,
                                  i_flg_show_all,
                                  i_flg_filter,
                                  o_issues,
                                  o_error));
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_REP_PENDING_ISSUES_LIST',
                                                     o_error);
        
    END get_rep_pending_issues_list;
    --
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
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_name IN professional.name%TYPE,
        o_assigns   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_ASSIGN_LIST - OPEN o_assigns CURSOR';
    
        OPEN o_assigns FOR
            SELECT p.id_professional AS id,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) description,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, NULL, NULL, NULL) prof_speciality
              FROM professional p
             WHERE p.flg_state = pk_alert_constant.g_active
               AND EXISTS
             (SELECT 1
                      FROM prof_institution pi
                     INNER JOIN prof_profile_template ppt
                        ON pi.id_professional = ppt.id_professional
                       AND pi.id_institution = ppt.id_institution
                     INNER JOIN profile_template pt
                        ON ppt.id_profile_template = pt.id_profile_template
                       AND ppt.id_software = pt.id_software
                     WHERE p.id_professional = pi.id_professional
                       AND pi.flg_state = pk_alert_constant.g_active
                       AND pi.id_institution = i_prof.institution
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pi.id_professional, pi.id_institution) =
                           pk_alert_constant.g_yes
                       AND pt.flg_available = pk_alert_constant.g_yes)
               AND upper(p.name) LIKE '%' || upper(i_prof_name) || '%'
             ORDER BY p.name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ASSIGN_LIST',
                                                     o_error);
    END get_assign_search;

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
     * @param  OUT o_assigns      Cursor
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
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        o_assigns  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_ASSIGN_LIST';
    
        IF (i_flg_type IS NULL)
        THEN
            -- first level
            g_error := 'GET_ASSIGN_LIST - OPEN FIRST LEVEL';
            OPEN o_assigns FOR
                SELECT rank AS id, flg_type, description
                  FROM (SELECT 1 rank, 'P' flg_type, pk_message.get_message(i_lang, 'PENDING_ISSUE_T037') description
                          FROM dual
                        UNION
                        SELECT 2 rank, 'G' flg_type, pk_message.get_message(i_lang, 'PENDING_ISSUE_T052') description
                          FROM dual)
                 ORDER BY rank;
        
        ELSE
            IF (upper(i_flg_type) = 'G')
            THEN
                -- group
                g_error := 'GET_ASSIGN_LIST - OPEN GROUP';
                OPEN o_assigns FOR
                    SELECT DISTINCT g.id_group AS id, i_flg_type AS flg_type, g.name AS description
                      FROM groups g
                      JOIN groups_dept gd
                        ON g.id_group = gd.id_group
                      JOIN dept d
                        ON gd.id_dept = d.id_dept
                     WHERE g.flg_available = pk_alert_constant.g_yes
                       AND d.id_institution = i_prof.institution
                     ORDER BY g.name;
            
            ELSIF (upper(i_flg_type) = 'P')
            THEN
                -- professionals
                g_error := 'GET_ASSIGN_LIST - OPEN PROFESSIONALS';
                OPEN o_assigns FOR
                    SELECT p.id_professional AS id,
                           i_flg_type AS flg_type,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS description,
                           pk_prof_utils.get_spec_signature(i_lang, i_prof, NULL, NULL, NULL) prof_speciality
                      FROM professional p
                     WHERE p.flg_state = pk_alert_constant.g_active
                       AND EXISTS
                     (SELECT 1
                              FROM prof_institution pi
                             INNER JOIN prof_profile_template ppt
                                ON pi.id_professional = ppt.id_professional
                               AND pi.id_institution = ppt.id_institution
                             INNER JOIN profile_template pt
                                ON ppt.id_profile_template = pt.id_profile_template
                               AND ppt.id_software = pt.id_software
                             WHERE p.id_professional = pi.id_professional
                               AND pi.flg_state = pk_alert_constant.g_active
                               AND pi.id_institution = i_prof.institution
                               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pi.id_professional, pi.id_institution) =
                                   pk_alert_constant.g_yes
                               AND pt.flg_available = pk_alert_constant.g_yes)
                     ORDER BY description;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ASSIGN_LIST',
                                                     o_error);
    END get_assign_list;

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
        i_lang   IN language.id_language%TYPE,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_groups FOR
            SELECT *
              FROM group_pending_issues gpi
             WHERE gpi.flg_available = g_flg_available_y;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_GROUPS_LIST',
                                                     o_error);
    END get_groups_list;

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
        i_lang   IN language.id_language%TYPE,
        o_labels OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_labels FOR
            SELECT 'P' AS group_key, pk_message.get_message(i_lang, 'PENDING_ISSUE_T037') group_name
              FROM dual -- PROFESSIONALS
            UNION
            SELECT 'G' AS group_key, pk_message.get_message(i_lang, 'PENDING_ISSUE_T051') group_name
              FROM dual; -- GROUPS
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_GROUPS_TO_ASSIGN_MESSAGE',
                                                     o_error);
    END get_groups_to_assign_message;

    /**
     * This function is used by the following functions:
     * 
     * GET_ISSUE_DETAIL_ACTIONS
     * GET_MESSAGE_DETAIL_ACTIONS
     * GET_MESSAGE_LIST_ACTIONS
     * GET_MESSAGE_VIEW_ACTIONS
     *
     * In order to get the actions of a functionality
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
    FUNCTION get_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_subject IN action.subject%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   IN OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_actions FOR
            SELECT id_action,
                   id_parent,
                   LEVEL,
                   to_state,
                   pk_message.get_message(i_lang, code_action) desc_action,
                   icon,
                   flg_default action_type,
                   flg_status AS action_statement,
                   internal_name
              FROM action a
             WHERE subject = i_subject
            CONNECT BY PRIOR id_action = id_parent
             START WITH id_parent IS NULL
             ORDER BY LEVEL, rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ACTIONS',
                                                     o_error);
    END get_actions;

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
        i_lang    IN language.id_language%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_subject VARCHAR2(200) := 'PENDING_ISSUE.ASSIGN_ISSUE';
    
    BEGIN
    
        RETURN get_actions(i_lang, l_subject, o_actions, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ASSIGN_MESSAGE_ACTION',
                                                     o_error);
    END get_assign_message_action;

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
        i_lang    IN language.id_language%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_subject VARCHAR2(200) := 'PENDING_ISSUE.ISSUE_DETAIL';
    
    BEGIN
    
        RETURN get_actions(i_lang, l_subject, o_actions, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ISSUE_DETAIL_ACTIONS',
                                                     o_error);
    END get_issue_detail_actions;

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
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pending_issue IN pending_issue.id_pending_issue%TYPE,
        o_show          OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ids_involved table_number;
    
    BEGIN
    
        o_show := 'Y';
    
        SELECT pii.id_involved
          BULK COLLECT
          INTO l_ids_involved
          FROM pending_issue_involved pii
         WHERE pii.flg_involved = g_professionals
           AND pii.id_pending_issue = i_pending_issue;
    
        IF (l_ids_involved.exists(1))
        THEN
        
            IF ((l_ids_involved.count = 1) AND (l_ids_involved(1) = i_prof.id))
            THEN
                o_show := 'N';
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ASSIGN_TO_ME_FLG',
                                                     o_error);
    END get_assign_to_me_flg;

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
        i_lang    IN language.id_language%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_subject VARCHAR2(200) := 'PENDING_ISSUE.MESSAGE_DETAIL';
    
    BEGIN
    
        RETURN get_actions(i_lang, l_subject, o_actions, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_MESSAGE_DETAIL_ACTIONS',
                                                     o_error);
    END get_message_detail_actions;

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
        i_lang    IN language.id_language%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_subject VARCHAR2(200) := 'PENDING_ISSUE.MESSAGE_LIST';
    
    BEGIN
    
        RETURN get_actions(i_lang, l_subject, o_actions, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_MESSAGE_LIST_ACTIONS',
                                                     o_error);
    END get_message_list_actions;

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
        i_lang    IN language.id_language%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_subject VARCHAR2(200) := 'PENDING_ISSUE.MESSAGE_VIEW';
    
    BEGIN
    
        RETURN get_actions(i_lang, l_subject, o_actions, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_MESSAGE_VIEW_ACTIONS',
                                                     o_error);
    END get_message_view_actions;

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
     * @return boolean
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION get_all_pending_issues_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_issues  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUE.GET_ALL_PENDING_ISSUES_LIST';
    
        RETURN(prv_get_issue_list(i_lang,
                                  i_prof,
                                  i_patient,
                                  i_episode,
                                  g_all_issues,
                                  pk_alert_constant.g_scope_type_patient,
                                  o_issues,
                                  o_error));
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ALL_PENDING_ISSUES_LIST',
                                                     o_error);
        
    END get_all_pending_issues_list;

    /**
     * This function returns a cursor of messages ordered by date.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_prof         Professional type (Id, Institution and Software)
     * @param  IN  i_issue        Issue ID
     * @param  OUT o_messages     Messages for the issue
     * @param  OUT o_error        Error message
     *
     * @return boolean
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Private
    */
    FUNCTION get_issue_messages_by_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_issue    IN pending_issue.id_pending_issue%TYPE,
        o_messages OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUE.GET_ISSUE_MESSAGES_BY_DATE';
    
        OPEN o_messages FOR
            SELECT pim.id_pending_issue,
                   pim.id_pending_issue_message,
                   pim.id_pending_issue_msg_parent,
                   pim.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pim.id_professional) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pim.id_professional,
                                                    pim.dt_creation,
                                                    (SELECT pi.id_episode
                                                       FROM pending_issue pi
                                                      WHERE pi.id_pending_issue = pim.id_pending_issue)) prof_speciality,
                   pim.thread_level,
                   0 pixels,
                   pim.flg_status,
                   pim.title AS title,
                   pim.text AS message,
                   nvl(pk_date_utils.date_send_tsz(i_lang, pim.dt_update, i_prof), pim.dt_creation) AS dt_last_update,
                   (is_unread_message(i_lang, i_prof, i_issue, pim.id_pending_issue_message)) AS new_message,
                   (is_unread_message_flg(i_lang, i_prof, i_issue, pim.id_pending_issue_message)) AS new_message_flg,
                   decode(pim.id_professional, i_prof.id, 'Y', 'N') is_owner
              FROM pending_issue_message pim
             WHERE pim.id_pending_issue = i_issue
             ORDER BY pim.dt_creation ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ISSUE_MESSAGES_BY_DATE',
                                                     o_error);
        
    END get_issue_messages_by_date;

    /**
     * This function returns a cursor of messages ordered by thread.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_prof         Professional type (Id, Institution and Software)
     * @param  IN  i_issue        Issue ID
     * @param  OUT o_messages     Messages for the issue
     * @param  OUT o_error        Error message
     *
     * @return boolean
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Private
    */
    FUNCTION get_issue_messages_by_thread
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_issue    IN pending_issue.id_pending_issue%TYPE,
        o_messages OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUE.GET_ISSUE_MESSAGES_BY_THREAD';
    
        OPEN o_messages FOR
            SELECT pim.id_pending_issue,
                   pim.id_pending_issue_message,
                   pim.id_pending_issue_msg_parent,
                   pim.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pim.id_professional) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pim.id_professional,
                                                    pim.dt_creation,
                                                    (SELECT pi.id_episode
                                                       FROM pending_issue pi
                                                      WHERE pi.id_pending_issue = pim.id_pending_issue)) prof_speciality,
                   pim.thread_level,
                   get_pixels(pim.thread_level) pixels,
                   pim.flg_status,
                   pim.title AS title,
                   pim.text AS message,
                   nvl(pk_date_utils.date_send_tsz(i_lang, pim.dt_update, i_prof), pim.dt_creation) AS dt_last_update,
                   (is_unread_message(i_lang, i_prof, i_issue, pim.id_pending_issue_message)) AS new_message,
                   (is_unread_message_flg(i_lang, i_prof, i_issue, pim.id_pending_issue_message)) AS new_message_flg,
                   decode(pim.id_professional, i_prof.id, 'Y', 'N') is_owner
              FROM pending_issue_message pim
             WHERE pim.id_pending_issue = i_issue
             ORDER BY pim.dt_creation ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ISSUE_MESSAGES_BY_THREAD',
                                                     o_error);
        
    END get_issue_messages_by_thread;

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
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_issue  IN pending_issue.id_pending_issue%TYPE,
        o_groups OUT pk_types.cursor_type,
        o_profs  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN o_groups CURSOR';
        OPEN o_groups FOR
            SELECT pii.id_involved AS id,
                   (SELECT g.name
                      FROM groups g
                     WHERE g.id_group = pii.id_involved) AS name
              FROM pending_issue_involved pii
             WHERE pii.id_pending_issue = i_issue
               AND pii.flg_involved = g_groups;
    
        g_error := 'OPEN o_profs CURSOR';
        OPEN o_profs FOR
            SELECT pii.id_involved AS id,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pii.id_involved) AS name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, NULL, NULL, NULL) AS speciality
              FROM pending_issue_involved pii
             WHERE pii.id_pending_issue = i_issue
               AND pii.flg_involved = g_professionals;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ISSUE_INVOLVED',
                                                     o_error);
        
    END get_issue_involved;

    /**
     * This function returns the issue's detail and all messages
     * for that issue. If i_flg_show_all = 'Y' then all messages
     * will be returned otherwise only the messages assign to the
     * professional id.
     *
     * @param  IN  i_lang         Language ID
     * @param  IN  i_prof         Professional type (Id, Institution and Software)
     * @param  IN  i_issue        Issue ID
     * @param  IN  i_flg_view     View by thread (T) or view by date (D)
     * @param  OUT o_issue        Issue's data
     * @param  OUT o_messages     Messages for the issue
     * @param  OUT o_error        Error message
     *
     * @return boolean
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Dec-10
     * @scope   Public
    */
    FUNCTION get_issue_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_issue    IN pending_issue.id_pending_issue%TYPE,
        i_flg_view IN VARCHAR2,
        o_issue    OUT pk_types.cursor_type,
        o_messages OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_issue_stakeholders VARCHAR2(4000) := '';
        l_previous_status    VARCHAR2(200) := '';
        l_previous_prof      VARCHAR2(200) := '';
        l_previous_date      VARCHAR2(200) := '';
        l_error              VARCHAR2(4000) := '';
    
    BEGIN
    
        l_error := 'PK_PENDING_ISSUE.GET_ISSUE_DETAIL';
    
        -- we're going to get the issue's detail
        l_issue_stakeholders := get_assignee_by_issue(i_issue);
    
        IF (NOT get_status_update(i_lang, i_prof, i_issue, l_previous_status, l_previous_prof, l_previous_date, o_error))
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := l_error || ' / ' || ' SELECT INTO STATEMENT ';
        OPEN o_issue FOR
            SELECT pi.title,
                   pi.id_professional id_prof_create,
                   pi.id_prof_cancel,
                   pi.id_prof_update,
                   pk_date_utils.date_send_tsz(i_lang, pi.dt_update, i_prof) last_update,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(pi.id_prof_update, pi.id_professional)) AS prof_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    decode(pi.id_prof_update,
                                                           NULL,
                                                           pi.id_professional,
                                                           pi.id_prof_update),
                                                    pi.dt_creation,
                                                    pi.id_episode) AS prof_speciality,
                   l_issue_stakeholders AS assigned_to,
                   get_number_of_unread_messages(pi.id_pending_issue, i_prof.id) AS total_unread_messages,
                   pi.flg_status,
                   pk_sysdomain.get_domain(g_pending_issue, pi.flg_status, i_lang) AS msg_status,
                   l_previous_status msg_previous_status,
                   l_previous_prof msg_previous_prof,
                   l_previous_date msg_previous_date
              FROM pending_issue pi
             WHERE pi.id_pending_issue = i_issue;
    
        -- we're going to get the issue's messages
        IF (i_flg_view = g_view_by_date)
        THEN
            g_error := l_error || ' / ' || ' VIEW BY DATE ';
            RETURN get_issue_messages_by_date(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_issue    => i_issue,
                                              o_messages => o_messages,
                                              o_error    => o_error);
        ELSE
            g_error := l_error || ' / ' || ' VIEW BY THREAD';
            RETURN get_issue_messages_by_thread(i_lang     => i_lang,
                                                i_prof     => i_prof,
                                                i_issue    => i_issue,
                                                o_messages => o_messages,
                                                o_error    => o_error);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ISSUE_DETAIL',
                                                     o_error);
        
    END get_issue_detail;

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
     * @return  BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Feb-26
     * @scope   Public
    */
    FUNCTION get_message_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_issue   IN pending_issue.id_pending_issue%TYPE,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE,
        o_message OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error VARCHAR2(4000) := '';
    
    BEGIN
    
        l_error := 'PK_PENDING_ISSUE.GET_MESSAGE_DETAIL';
    
        g_error := l_error || ' / OPEN o_message FOR ';
        OPEN o_message FOR
            SELECT pim.id_pending_issue,
                   pim.id_pending_issue_message,
                   pim.id_pending_issue_msg_parent,
                   pim.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pim.id_professional) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pim.id_professional,
                                                    pim.dt_creation,
                                                    (SELECT pi.id_episode
                                                       FROM pending_issue pi
                                                      WHERE pi.id_pending_issue = pim.id_pending_issue)) prof_speciality,
                   pim.thread_level,
                   pim.flg_status,
                   pim.title AS title,
                   pim.text AS message,
                   pk_date_utils.date_send_tsz(i_lang, nvl(pim.dt_update, pim.dt_creation), i_prof) dt_last_update,
                   g_msg_flg_new_n AS new_message,
                   pk_date_utils.date_send_tsz(i_lang, pim.dt_creation, i_prof) dt_creation
              FROM pending_issue_message pim
             WHERE pim.id_pending_issue = i_issue
               AND pim.id_pending_issue_message = nvl(i_message, pim.id_pending_issue_message)
             ORDER BY pim.dt_creation ASC;
    
        g_error := l_error || ' / Calling SET_AS_READ function ';
        IF (NOT set_as_read(i_lang, i_prof, i_issue, i_message, o_error))
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_MESSAGE_DETAIL',
                                                     o_error);
        
    END get_message_detail;

    /**
     * This function returns the status for an issue. If the second
     * parameter is NULL then this function will return the default
     * status of "Open"
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
        i_lang   IN language.id_language%TYPE,
        i_issue  IN pending_issue.id_pending_issue%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_issue_status_val pending_issue.flg_status%TYPE;
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUES.GET_ISSUE_STATUS - GETTING VAL';
        IF (i_issue IS NOT NULL)
        THEN
            SELECT flg_status
              INTO l_issue_status_val
              FROM pending_issue pi
             WHERE pi.id_pending_issue = i_issue;
        ELSE
            l_issue_status_val := g_issue_flg_status_open;
        END IF;
    
        g_error := 'PK_PENDING_ISSUES.GET_ISSUE_STATUS - OPEN CURSOR';
        OPEN o_status FOR
            SELECT sd.val, sd.desc_val
              FROM sys_domain sd
             WHERE sd.code_domain = g_pending_issue
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.val = l_issue_status_val
               AND sd.id_language = i_lang;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'GET_ISSUE_STATUS',
                                                     o_error);
        
    END get_issue_status;

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
    ) RETURN PLS_INTEGER IS
    
        l_number PLS_INTEGER := 0;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_number
          FROM pending_issue_prof pip
         WHERE pip.id_pending_issue = i_issue
           AND pip.dt_read IS NULL
           AND pip.id_professional = i_id_prof;
    
        RETURN l_number;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END;

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
    */
    FUNCTION get_pixels(i_thread_level pending_issue_message.thread_level%TYPE) RETURN NUMBER IS
    
        pixels PLS_INTEGER := 0;
    
    BEGIN
    
        pixels := g_pixels_factor * i_thread_level;
    
        IF (pixels > g_pixels_max)
        THEN
            RETURN g_pixels_max;
        ELSE
            RETURN pixels;
        END IF;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            RETURN 0;
        
    END get_pixels;

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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_issue   IN pending_issue.id_pending_issue%TYPE,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
        l_error           VARCHAR2(4000) := '';
    
    BEGIN
    
        l_error := 'PK_PENDING_ISSUE.SET_AS_READ';
    
        UPDATE pending_issue_prof pip
           SET pip.dt_read = current_timestamp
         WHERE pip.id_pending_issue_message = i_message
           AND pip.id_pending_issue = i_issue
           AND pip.id_professional = i_prof.id;
    
        g_error := l_error || ' SELECT INTO - OPERATION';
        BEGIN
            SELECT *
              INTO l_sys_alert_event
              FROM sys_alert_event sae
             WHERE sae.id_record = i_message
               AND sae.id_professional = i_prof.id;
        
            g_error := l_error || ' DELETE_SYS_ALERT_EVENT CALL';
            IF (NOT pk_alerts.delete_sys_alert_event(i_lang, i_prof, l_sys_alert_event, o_error))
            THEN
                RAISE g_exception;
            END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_AS_READ',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_AS_READ',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_as_read;

    /**
     * This function deletes one or more sys alert events, related to peding issue.
     *
     * @param  i_lang      Language ID
     * @param  i_prof      table_number(professional_id)
     * @param  i_issue     table_number(pending_issue_id)
     * @param  o_error     Error message
     *
     * @return BOOLEAN
     *
     * @version 2.6.3
     * @author  Gisela Couto
     * @since   2014-Apr-28
     * @scope   Private
    */
    FUNCTION delete_pend_issue_alert_event
    (
        i_lang      IN language.id_language%TYPE,
        i_tbl_prof  IN table_number,
        i_tbl_issue IN table_number,
        o_error     IN OUT t_error_out
    ) RETURN BOOLEAN IS
        TYPE t_sys_alert_event IS TABLE OF sys_alert_event%ROWTYPE;
        l_sys_alert_event t_sys_alert_event;
        l_error           VARCHAR2(4000) := '';
    BEGIN
    
        l_error := 'BULK COLLECT';
    
        IF i_tbl_prof IS NOT NULL
        THEN
            SELECT *
              BULK COLLECT
              INTO l_sys_alert_event
              FROM sys_alert_event sae
             WHERE sae.id_record IN (SELECT pim.id_pending_issue_message
                                       FROM pending_issue_message pim
                                      WHERE pim.id_pending_issue IN (SELECT *
                                                                       FROM TABLE(i_tbl_issue)))
               AND sae.id_professional IN (SELECT *
                                             FROM TABLE(i_tbl_prof));
        
        ELSE
            SELECT *
              BULK COLLECT
              INTO l_sys_alert_event
              FROM sys_alert_event sae
             WHERE sae.id_record IN (SELECT pim.id_pending_issue_message
                                       FROM pending_issue_message pim
                                      WHERE pim.id_pending_issue IN (SELECT *
                                                                       FROM TABLE(i_tbl_issue)));
        END IF;
    
        IF (l_sys_alert_event.count > 0)
        THEN
        
            FOR i IN 1 .. l_sys_alert_event.last
            LOOP
            
                l_error := ' CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT';
                IF (NOT pk_alerts.delete_sys_alert_event(i_lang,
                                                         profissional(l_sys_alert_event(i).id_professional,
                                                                      l_sys_alert_event(i).id_institution,
                                                                      l_sys_alert_event(i).id_software),
                                                         l_sys_alert_event(i),
                                                         o_error))
                THEN
                    RAISE g_exception;
                END IF;
            
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'DELETE_PEND_ISSUE_ALERT_EVENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END delete_pend_issue_alert_event;

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
     * @Updated By Gisela Couto - 2014-04-29
    */
    FUNCTION set_all_as_read
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_issue IN pending_issue.id_pending_issue%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'UPDATE ISSUE READ DATE';
    
        UPDATE pending_issue_prof pip
           SET pip.dt_read = current_timestamp
         WHERE pip.id_pending_issue = i_issue
           AND pip.id_professional = i_prof.id;
    
        g_error := 'CALL DELETE SYS_ALERT_EVENT';
        IF NOT delete_pend_issue_alert_event(i_lang      => i_lang,
                                             i_tbl_prof  => table_number(i_prof.id),
                                             i_tbl_issue => table_number(i_issue),
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_ALL_AS_READ',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_all_as_read;

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
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_issue IN pending_issue.id_pending_issue%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUE.SET_ALL_AS_UNREAD';
    
        UPDATE pending_issue_prof pip
           SET pip.dt_read = NULL
         WHERE pip.id_professional = i_prof.id
           AND pip.id_pending_issue = i_issue;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_ALL_AS_UNREAD',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_all_as_unread;

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
     * @Updated By Gisela Couto - 2014-04-28
    */
    FUNCTION set_as_unread
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_issue   IN pending_issue.id_pending_issue%TYPE,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_episode pending_issue.id_episode%TYPE;
        l_visit   episode.id_visit%TYPE;
        l_patient pending_issue.id_patient%TYPE;
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUE.SET_AS_UNREAD';
    
        UPDATE pending_issue_prof pip
           SET pip.dt_read = NULL
         WHERE pip.id_pending_issue_message = i_message
           AND pip.id_pending_issue = i_issue
           AND pip.id_professional = i_prof.id;
    
        g_error := 'GET PENDING ISSUE EPISODE, PATIENT AND VISIT.';
        SELECT pi.id_episode, pi.id_patient, epis.id_visit
          INTO l_episode, l_patient, l_visit
          FROM pending_issue pi
          JOIN episode epis
            ON pi.id_episode = epis.id_episode
         WHERE pi.id_pending_issue = nvl(i_issue, 0);
    
        g_error := 'CREATE SYS_ALERT';
        IF NOT set_alert_msg(i_lang          => i_lang,
                             i_prof          => i_prof,
                             i_issue         => i_issue,
                             i_episode       => l_episode,
                             i_patient       => l_patient,
                             i_visit         => l_visit,
                             i_receptor_prof => i_prof.id,
                             i_issue_message => i_message,
                             o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_AS_UNREAD',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_as_unread;

    PROCEDURE get_arrays_difference
    (
        i_old IN table_number,
        i_new IN table_number,
        o_ins OUT table_number,
        o_del OUT table_number
    ) IS
    
    BEGIN
    
        -- To be inserted
        BEGIN
            SELECT column_value
              BULK COLLECT
              INTO o_ins
              FROM (SELECT column_value -- new
                      FROM TABLE(i_new)
                    MINUS
                    SELECT column_value -- old
                      FROM TABLE(i_old));
        EXCEPTION
            WHEN OTHERS THEN
                o_ins := table_number();
        END;
    
        -- To be removed
        BEGIN
            SELECT column_value
              BULK COLLECT
              INTO o_del
              FROM (SELECT column_value -- old
                      FROM TABLE(i_old)
                    MINUS
                    SELECT column_value -- new
                      FROM TABLE(i_new));
        EXCEPTION
            WHEN OTHERS THEN
                o_del := table_number();
        END;
    
    END get_arrays_difference;

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
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_issue        IN OUT pending_issue.id_pending_issue%TYPE,
        i_issue_status IN pending_issue.flg_status%TYPE,
        i_groups       IN table_number,
        i_profs        IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'SET_ISSUE_STATUS CALL';
        IF (NOT set_issue_status(i_lang, i_prof, i_issue, i_issue_status, o_error))
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'UPDATE_INVOLVED CALL';
        IF (NOT update_involved(i_lang, i_prof, i_issue, i_groups, i_profs, o_error))
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PENDING_ISSUES',
                                                     'UPDATE_ISSUE_STATUS_INVOLVED',
                                                     o_error);
        
    END set_issue_status_involved;

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
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_issue  IN OUT pending_issue.id_pending_issue%TYPE,
        i_groups IN table_number,
        i_profs  IN table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_issue_info(l_issue pending_issue.id_pending_issue%TYPE) IS
            SELECT pei.id_episode, pei.id_patient, v.id_visit
              FROM pending_issue_involved pii
             INNER JOIN pending_issue pei
                ON pei.id_pending_issue = pii.id_pending_issue
             INNER JOIN episode e
                ON e.id_episode = pei.id_episode
             INNER JOIN visit v
                ON v.id_visit = e.id_visit
               AND pei.id_pending_issue = l_issue
             GROUP BY pei.id_pending_issue, pei.id_episode, pei.id_patient, v.id_visit;
    
        l_count_table_profs table_number; -- OLD ones
        l_count_colle_profs table_number := i_profs; -- OLD + NEW ones
        l_new_profs         table_number; -- NEW ones: to be inserted
        l_old_profs         table_number; -- OLD ones: to be removed
    
        l_count_table_groups table_number; -- OLD ones
        l_count_colle_groups table_number := i_groups; -- OLD + NEW ones
        l_new_groups         table_number; -- NEW ones: to be inserted
        l_old_groups         table_number; -- NEW ones: to be removed
    
        l_profs_by_group    table_number;
        l_messages_by_issue table_number;
    
        l_pi_subject VARCHAR2(2000);
    
        l_alert_event_row  sys_alert_event%ROWTYPE;
        l_next_message_id  NUMBER(24, 0);
        l_c_issue_info_row c_issue_info%ROWTYPE;
    
        l_error VARCHAR2(4000) := '';
    
    BEGIN
    
        l_error := 'PK_PENDING_ISSUE.UPDATE_INVOLVED';
        g_error := 'UPDATE_INVOLVED';
    
        -- ------------------------------------------------------------------ --
        -- PROFESSIONALS
    
        BEGIN
        
            g_error := 'UPDATE_INVOLVED - PROFESSIONALS';
            SELECT id_involved
              BULK COLLECT
              INTO l_count_table_profs
              FROM pending_issue_involved pii
             WHERE pii.id_pending_issue = i_issue
               AND pii.flg_involved = g_professionals;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_count_table_profs := table_number();
            
        END;
    
        g_error := 'UPDATE_INVOLVED - PROFESSIONALS - GET_ARRAYS_DIFFERENCE';
        get_arrays_difference(i_old => l_count_table_profs,
                              i_new => l_count_colle_profs,
                              o_ins => l_new_profs,
                              o_del => l_old_profs);
    
        IF (l_old_profs IS NOT NULL)
        THEN
        
            IF (l_old_profs.count > 0)
            THEN
                -- remove old profs
                g_error := 'UPDATE_INVOLVED - PROFESSIONALS - DELETE OLD';
                DELETE FROM pending_issue_involved pii
                 WHERE pii.id_pending_issue = i_issue
                   AND pii.flg_involved = g_professionals
                   AND pii.id_involved IN (SELECT column_value
                                             FROM TABLE(l_old_profs));
            
                -- remover alertas activos
                FOR i IN 1 .. l_old_profs.count
                LOOP
                    DELETE FROM sys_alert_event sae
                     WHERE sae.id_record IN (SELECT pip.id_pending_issue_message + l_old_profs(i)
                                               FROM pending_issue_prof pip
                                              WHERE pip.id_pending_issue = i_issue
                                                AND pip.id_professional = l_old_profs(i));
                END LOOP;
            
                -- remover os profissionais da pending_issue_prof
                DELETE FROM pending_issue_prof pip
                 WHERE pip.id_pending_issue = i_issue
                   AND pip.id_professional IN (SELECT column_value
                                                 FROM TABLE(l_old_profs));
            
            END IF;
        
        END IF;
    
        IF (l_new_profs IS NOT NULL)
        THEN
        
            OPEN c_issue_info(i_issue);
        
            FETCH c_issue_info
                INTO l_c_issue_info_row;
            CLOSE c_issue_info;
        
            IF (l_new_profs.count > 0)
            THEN
                -- insert new profs
                g_error := 'UPDATE_INVOLVED - PROFESSIONALS - INSERT NEW';
                FORALL i IN l_new_profs.first .. l_new_profs.last
                    INSERT INTO pending_issue_involved
                        (id_pending_issue, id_involved, flg_involved)
                    VALUES
                        (i_issue, l_new_profs(i), g_professionals);
            
                -- inserir na tabela pending_issue_prof
            
                SELECT pim.id_pending_issue_message
                  BULK COLLECT
                  INTO l_messages_by_issue
                  FROM pending_issue_message pim
                 WHERE pim.id_pending_issue = i_issue;
            
                IF ((l_messages_by_issue IS NOT NULL) AND (l_messages_by_issue.count > 0))
                THEN
                
                    FOR i IN l_messages_by_issue.first .. l_messages_by_issue.last
                    LOOP
                    
                        FOR j IN l_new_profs.first .. l_new_profs.last
                        LOOP
                        
                            BEGIN
                            
                                INSERT INTO pending_issue_prof
                                    (id_pending_issue, id_pending_issue_message, id_professional, flg_status)
                                VALUES
                                    (i_issue, l_messages_by_issue(i), l_new_profs(j), g_msg_prof_flg_status_active);
                            
                                g_error := l_error || ' / ' || 'INSERT_SYS_ALERT_EVENT';
                            
                                IF NOT set_alert_msg(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_issue         => i_issue,
                                                     i_episode       => l_c_issue_info_row.id_episode,
                                                     i_patient       => l_c_issue_info_row.id_patient,
                                                     i_visit         => l_c_issue_info_row.id_visit,
                                                     i_receptor_prof => l_new_profs(j),
                                                     i_issue_message => l_messages_by_issue(i),
                                                     o_error         => o_error)
                                THEN
                                    RAISE g_exception;
                                END IF;
                            
                            EXCEPTION
                                WHEN OTHERS THEN
                                    NULL;
                                
                            END;
                        
                        END LOOP;
                    
                    END LOOP;
                
                END IF;
            
            END IF;
        
        END IF;
    
        -- ------------------------------------------------------------------ --
        -- GROUPS
    
        BEGIN
        
            g_error := 'UPDATE_INVOLVED - GROUPS';
            SELECT id_involved
              BULK COLLECT
              INTO l_count_table_groups
              FROM pending_issue_involved pii
             WHERE pii.id_pending_issue = i_issue
               AND pii.flg_involved = g_groups;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_count_table_groups := table_number();
            
        END;
    
        g_error := 'UPDATE_INVOLVED - GROUPS - GET_ARRAYS_DIFFERENCE';
        get_arrays_difference(i_old => l_count_table_groups,
                              i_new => l_count_colle_groups,
                              o_ins => l_new_groups,
                              o_del => l_old_groups);
    
        IF (l_old_groups IS NOT NULL)
        THEN
        
            IF (l_old_groups.count > 0)
            THEN
                -- remove old groups
                g_error := 'UPDATE_INVOLVED - GROUPS - DELETE OLD';
                DELETE FROM pending_issue_involved pii
                 WHERE pii.id_pending_issue = i_issue
                   AND pii.flg_involved = g_groups
                   AND pii.id_involved IN (SELECT column_value
                                             FROM TABLE(l_old_groups));
            
                -- remover alertas activos
                FOR i IN 1 .. l_old_profs.count
                LOOP
                    DELETE FROM sys_alert_event sae
                     WHERE sae.id_record IN (SELECT pip.id_pending_issue_message + l_old_profs(i)
                                               FROM pending_issue_prof pip
                                              WHERE pip.id_pending_issue = i_issue
                                                AND pip.id_professional = l_old_groups(i));
                END LOOP;
            
                -- remover os profissionais da pending_issue_prof
                l_profs_by_group := get_profs_by_group(i_lang, l_old_groups, o_error);
            
                IF (l_profs_by_group.count > 0)
                THEN
                    DELETE FROM pending_issue_prof pip
                     WHERE pip.id_pending_issue = i_issue
                       AND pip.id_professional IN (SELECT column_value
                                                     FROM TABLE(l_profs_by_group));
                END IF;
            
                l_profs_by_group := table_number();
            
            END IF;
        
        END IF;
    
        IF (l_new_groups IS NOT NULL)
        THEN
        
            IF (l_new_groups.count > 0)
            THEN
                -- insert new groups
                g_error := 'UPDATE_INVOLVED - GROUPS - INSERT NEW';
                FORALL i IN l_new_groups.first .. l_new_groups.last
                    INSERT INTO pending_issue_involved
                        (id_pending_issue, id_involved, flg_involved)
                    VALUES
                        (i_issue, l_new_groups(i), g_groups);
            
                -- pegar os profissionais associados ao grupo e
                -- inseri-los na tabela pending_issue_prof
            
                SELECT pim.id_pending_issue_message
                  BULK COLLECT
                  INTO l_messages_by_issue
                  FROM pending_issue_message pim
                 WHERE pim.id_pending_issue = i_issue;
            
                IF ((l_messages_by_issue IS NOT NULL) AND (l_messages_by_issue.count > 0))
                THEN
                
                    l_profs_by_group := get_profs_by_group(i_lang, l_old_groups, o_error);
                
                    IF ((l_profs_by_group IS NOT NULL) AND (l_profs_by_group.count > 0))
                    THEN
                    
                        FOR i IN l_messages_by_issue.first .. l_messages_by_issue.last
                        LOOP
                        
                            FOR j IN l_profs_by_group.first .. l_profs_by_group.last
                            LOOP
                            
                                BEGIN
                                
                                    INSERT INTO pending_issue_prof
                                        (id_pending_issue, id_pending_issue_message, id_professional, flg_status)
                                    VALUES
                                        (i_issue,
                                         l_messages_by_issue(i),
                                         l_profs_by_group(j),
                                         g_msg_prof_flg_status_active);
                                
                                    -- send alert message
                                    IF NOT set_alert_msg(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_issue         => i_issue,
                                                         i_episode       => l_c_issue_info_row.id_episode,
                                                         i_patient       => l_c_issue_info_row.id_patient,
                                                         i_visit         => l_c_issue_info_row.id_visit,
                                                         i_receptor_prof => l_profs_by_group(i),
                                                         i_issue_message => l_messages_by_issue(i),
                                                         o_error         => o_error)
                                    THEN
                                        RETURN FALSE;
                                    END IF;
                                
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        NULL;
                                    
                                END;
                            
                            END LOOP;
                        
                        END LOOP;
                    
                        l_profs_by_group := table_number();
                    
                    END IF;
                
                END IF;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'UPDATE_INVOLVED',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END update_involved;
    /**
     * This function is responsable to manage the professionals and groups
     * involved in an issue's discussion.
     *
     * @param i_lang              Language ID
     * @param i_prof              Professional type (Id, Institution and Software)
     * @param i_issue             Issue ID (NULL for insert; NOT NULL for update)
     * @param i_involved          Table of professional IDs or group IDs
     * @param i_flg_involved      G: Group; P: Professional
     * @param o_error             Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2008-Apr-09
    */
    FUNCTION set_involved
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_issue        IN OUT pending_issue.id_pending_issue%TYPE,
        i_involved     IN table_number,
        i_flg_involved IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --IF (i_involved.COUNT > 0) -- José Brito 13/04/2009
        IF i_involved IS NOT NULL
        THEN
            IF i_involved.count > 0
            THEN
                g_error := 'SET_INVOLVED - Deleting existing involved.';
                DELETE FROM pending_issue_involved pii
                 WHERE pii.id_pending_issue = i_issue
                   AND pii.flg_involved = i_flg_involved;
            
                g_error := 'SET_INVOLVED - Inserting involved.';
                FOR i IN 1 .. i_involved.last
                LOOP
                    INSERT INTO pending_issue_involved
                        (id_pending_issue, id_involved, flg_involved)
                    VALUES
                        (i_issue, i_involved(i), i_flg_involved);
                END LOOP;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ALLERGY',
                                              'SET_INVOLVED',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_involved;

    /**
     * This function is responsible for the core of the saving process
     * of an issue.
     *
     * @param i_lang        Language ID
     * @param i_prof        Professional type (Id, Institution and Software)
     * @param i_issue       Issue ID (NULL for insert; NOT NULL for update)
     * @param i_title       Issue's Title
     * @param i_patient     Patient ID
     * @param i_episode     Episode ID
     * @param i_assigns     Table of professional's IDs
     * @param i_status      Status of the issue
     * @param i_subject     First message subject
     * @param i_message     First message text
     * @param o_error       Error message
     *
     * @return BOOLEAN
     *
     * @version 2.4.4
     * @author  Thiago Brito
     * @since   2009-Apr-22
     * @scope   Public
    */
    FUNCTION set_issue_generic
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_issue   IN OUT pending_issue.id_pending_issue%TYPE,
        i_title   IN VARCHAR2,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_assigns IN table_number,
        i_status  IN VARCHAR2,
        i_subject IN VARCHAR2,
        i_message IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_date            TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_next_message_id NUMBER(24, 0) := 0;
        l_error           VARCHAR2(4000) := '';
        l_pi_subject      VARCHAR2(2000);
        l_alert_event_row sys_alert_event%ROWTYPE;
        l_visit           visit.id_visit%TYPE;
        l_excep_episode EXCEPTION;
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
    BEGIN
    
        g_error := l_error || ' / ' || 'ID EPISODE IS NULL';
        IF i_episode IS NULL
        THEN
            RAISE l_excep_episode;
        END IF;
    
        g_error := l_error || ' / ' || 'INSERT INTO PENDING_ISSUE';
        INSERT INTO pending_issue
            (id_pending_issue,
             id_patient,
             id_episode,
             title,
             dt_creation,
             dt_cancel,
             dt_update,
             flg_status,
             id_professional,
             id_prof_cancel)
        VALUES
            (i_issue, i_patient, i_episode, i_title, l_date, NULL, l_date, i_status, i_prof.id, NULL);
    
        -- We're going to create the first message
        g_error := l_error || ' / ' || 'MESSAGE NEXTVAL';
        SELECT seq_issue_message.nextval
          INTO l_next_message_id
          FROM dual;
    
        g_error := l_error || ' / ' || 'INSERT INTO PENDING_ISSUE_MESSAGE';
        INSERT INTO pending_issue_message
            (id_pending_issue_message,
             id_pending_issue_msg_parent,
             id_pending_issue,
             title,
             text,
             thread_level,
             dt_creation,
             dt_cancel,
             dt_update,
             flg_status,
             id_professional,
             id_prof_cancel)
        VALUES
            (l_next_message_id,
             0,
             i_issue,
             i_subject,
             i_message,
             0,
             l_date,
             NULL,
             l_date,
             g_msg_flg_status_active,
             i_prof.id,
             NULL);
    
        -- We're going to create the relation with the assigned professionals
    
        IF (i_assigns IS NOT NULL AND i_assigns.count > 0)
        THEN
        
            FOR i IN i_assigns.first .. i_assigns.last
            LOOP
            
                g_error := l_error || ' / ' || 'INSERT INTO PENDING_ISSUE_PROF';
                INSERT INTO pending_issue_prof
                    (id_pending_issue, id_pending_issue_message, id_professional, dt_read, flg_status, dt_cancel)
                VALUES
                    (i_issue, l_next_message_id, i_assigns(i), NULL, g_msg_prof_flg_status_active, NULL);
            
                BEGIN
                    SELECT nvl(id_visit, -1)
                      INTO l_visit
                      FROM episode e
                     WHERE e.id_episode = nvl(i_episode, -1);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_visit := -1;
                END;
                IF i_status != g_issue_flg_status_closed
                THEN
                    IF NOT set_alert_msg(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_issue         => i_issue,
                                         i_episode       => i_episode,
                                         i_patient       => i_patient,
                                         i_visit         => l_visit,
                                         i_receptor_prof => i_assigns(i),
                                         i_issue_message => l_next_message_id,
                                         o_error         => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_excep_episode THEN
            l_error_in.set_all(i_lang,
                               'PENDING_ISSUE_M007',
                               pk_message.get_message(i_lang, 'PENDING_ISSUE_M007'),
                               g_error,
                               'ALERT',
                               'PK_ALLERGY',
                               'SET_ISSUE_GENERIC',
                               pk_message.get_message(i_lang, 'PENDING_ISSUE_M007'),
                               'U');
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_ret;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ALLERGY',
                                              'SET_ISSUE_GENERIC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_issue_generic;

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
     * @param i_assigns     Table of professional's IDs
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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_issue   IN OUT pending_issue.id_pending_issue%TYPE,
        i_title   IN VARCHAR2,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_assigns IN table_number,
        i_status  IN VARCHAR2,
        i_subject IN VARCHAR2,
        i_message IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error           VARCHAR2(4000) := '';
        l_previous_status VARCHAR2(1);
        l_date            TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        l_error := 'PK_PENDING_ISSUE.SET_ISSUE';
    
        IF (i_assigns IS NULL)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (i_issue IS NULL)
        THEN
        
            -- We're going to create a new issue
        
            g_error := l_error || ' / ' || 'ISSUE NEXTVAL';
            SELECT seq_issue.nextval
              INTO i_issue
              FROM dual;
        
            -- We're going to call the set_issue_generic
            IF (NOT set_issue_generic(i_lang,
                                      i_prof,
                                      i_issue,
                                      i_title,
                                      i_patient,
                                      i_episode,
                                      i_assigns,
                                      i_status,
                                      i_subject,
                                      i_message,
                                      o_error))
            THEN
                RAISE g_exception;
            END IF;
        
            -- We're going to set the professional involved in this new issue
            IF (NOT set_involved(i_lang, i_prof, i_issue, i_assigns, g_professionals, o_error))
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE
        
            -- We're going to set the professional involved in this existing issue
            IF (NOT set_involved(i_lang, i_prof, i_issue, i_assigns, g_professionals, o_error))
            THEN
                RAISE g_exception;
            END IF;
        
            -- We're going to change the flg_status_hist
            BEGIN
            
                g_error := l_error || ' / ' || 'GET PENDING_ISSUE PREVIOUS STATUS';
            
                SELECT pi.flg_status
                  INTO l_previous_status
                  FROM pending_issue pi
                 WHERE pi.id_pending_issue = i_issue;
            
                IF (l_previous_status = i_status)
                THEN
                    l_previous_status := NULL;
                END IF;
            
            EXCEPTION
                WHEN OTHERS THEN
                    l_previous_status := NULL;
                
            END;
        
            -- We're going to update the issue
            g_error := l_error || ' / ' || 'UPDATE PENDING_ISSUE';
            UPDATE pending_issue pi
               SET pi.title           = nvl(i_title, pi.title),
                   pi.dt_update       = l_date,
                   pi.flg_status      = nvl(i_status, pi.flg_status),
                   pi.flg_status_hist = l_previous_status
             WHERE pi.id_pending_issue = i_issue;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_ISSUE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_ISSUE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_issue;

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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_issue   IN OUT pending_issue.id_pending_issue%TYPE,
        i_title   IN VARCHAR2,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_group   IN table_number,
        i_profs   IN table_number,
        i_status  IN VARCHAR2,
        i_subject IN VARCHAR2,
        i_message IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error VARCHAR2(4000) := '';
        l_date  TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_prof_array       table_number := i_profs;
        l_group_prof_array table_number;
        l_involved         table_number;
    
    BEGIN
    
        l_error := 'PK_PENDING_ISSUE.SET_ISSUE_PROF_GROUP';
    
        SELECT pg.id_professional
          BULK COLLECT
          INTO l_group_prof_array
          FROM prof_groups pg
         WHERE pg.id_group IN (SELECT column_value
                                 FROM TABLE(i_group))
           AND pg.flg_state = 'A';
    
        IF (i_issue IS NULL)
        THEN
        
            -- We're going to create a new issue
            g_error := l_error || ' / ' || 'ISSUE NEXTVAL';
            SELECT seq_issue.nextval
              INTO i_issue
              FROM dual;
        
            -- We could not allow repeated IDs
            SELECT DISTINCT column_value
              BULK COLLECT
              INTO l_involved
              FROM (SELECT column_value
                      FROM TABLE(l_prof_array)
                    UNION
                    SELECT column_value
                      FROM TABLE(l_group_prof_array));
        
            -- We're going to call the set_issue_generic
            IF (NOT set_issue_generic(i_lang,
                                      i_prof,
                                      i_issue,
                                      i_title,
                                      i_patient,
                                      i_episode,
                                      l_involved, -- Professional IDs
                                      i_status,
                                      i_subject,
                                      i_message,
                                      o_error))
            THEN
                RAISE g_exception;
            END IF;
        
            -- We're going to set the professional involved in this new issue
            IF (NOT set_involved(i_lang, i_prof, i_issue, i_profs, g_professionals, o_error))
            THEN
                RAISE g_exception;
            END IF;
        
            -- We're going to set the groups involved in this new issue
            IF (NOT set_involved(i_lang, i_prof, i_issue, i_group, g_groups, o_error))
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE
        
            -- We're going to set the professional involved in this new issue
            IF (NOT set_involved(i_lang, i_prof, i_issue, i_profs, g_professionals, o_error))
            THEN
                RAISE g_exception;
            END IF;
        
            -- We're going to set the groups involved in this new issue
            IF (NOT set_involved(i_lang, i_prof, i_issue, i_group, g_groups, o_error))
            THEN
                RAISE g_exception;
            END IF;
        
            -- We're going to update the issue
            g_error := l_error || ' / ' || 'UPDATE PENDING_ISSUE';
            UPDATE pending_issue pi
               SET pi.title      = nvl(i_title, pi.title),
                   pi.dt_update  = l_date,
                   pi.flg_status = nvl(i_status, pi.flg_status)
             WHERE pi.id_pending_issue = i_issue;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        -- José Brito 13/04/2009 Declare OTHERS and specify error in G_EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_ISSUE',
                                              o_error);
        
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_ISSUE',
                                              o_error);
        
            ROLLBACK;
            RETURN FALSE;
    END set_issue_prof_group;

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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_issue   IN OUT pending_issue.id_pending_issue%TYPE,
        i_title   IN VARCHAR2,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_group   IN table_number,
        i_status  IN VARCHAR2,
        i_subject IN VARCHAR2,
        i_message IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_profs table_number;
        l_date  TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        g_error := 'PK_PENDING_ISSUE.SET_ISSUE_GROUP - Getting the professionals associated with a group';
    
        SELECT pgpi.id_professional
          BULK COLLECT
          INTO l_profs
          FROM group_pending_issues gpi, prof_group_pending_issues pgpi
         WHERE gpi.id_group = gpi.id_group
           AND gpi.id_group IN (SELECT column_value
                                  FROM TABLE(i_group));
    
        g_error := 'PK_PENDING_ISSUE.SET_ISSUE_GROUP - Creating an ISSUE';
    
        IF (i_issue IS NULL)
        THEN
        
            -- We're going to create a new issue
        
            g_error := 'ISSUE NEXTVAL';
            SELECT seq_issue.nextval
              INTO i_issue
              FROM dual;
        
            -- We're going to call the set_issue_generic
            IF (NOT set_issue_generic(i_lang,
                                      i_prof,
                                      i_issue,
                                      i_title,
                                      i_patient,
                                      i_episode,
                                      l_profs,
                                      i_status,
                                      i_subject,
                                      i_message,
                                      o_error))
            THEN
                RAISE g_exception;
            END IF;
        
            -- We're going to set the groups involved in this new issue
            IF (NOT set_involved(i_lang, i_prof, i_issue, i_group, g_groups, o_error))
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE
        
            -- We're going to set the groups involved in this existing issue
            IF (NOT set_involved(i_lang, i_prof, i_issue, i_group, g_groups, o_error))
            THEN
                RAISE g_exception;
            END IF;
        
            -- We're going to update the issue
            g_error := 'UPDATE PENDING_ISSUE';
            UPDATE pending_issue pi
               SET pi.title      = nvl(i_title, pi.title),
                   pi.dt_update  = l_date,
                   pi.flg_status = nvl(i_status, pi.flg_status)
             WHERE pi.id_pending_issue = i_issue;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_ISSUE_GROUP',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_issue_group;

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
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_issue      IN pending_issue.id_pending_issue%TYPE,
        i_id_message    IN pending_issue_message.id_pending_issue_message%TYPE,
        i_message_title IN VARCHAR2,
        i_message_body  IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_replay_string VARCHAR2(4000) := pk_message.get_message(i_lang, 'PENDING_ISSUE_T042');
    
    BEGIN
    
        g_error := 'SET_MESSAGE - BEGIN';
    
        UPDATE pending_issue_message pim
           SET pim.title     = REPLACE(i_message_title, l_replay_string, ''),
               pim.text      = i_message_body,
               pim.dt_update = current_timestamp
         WHERE pim.id_pending_issue = i_id_issue
           AND pim.id_pending_issue_message = i_id_message
           AND pim.id_professional = i_prof.id;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_MESSAGE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_message;

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
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_issue      IN pending_issue.id_pending_issue%TYPE,
        i_flg_reply  IN VARCHAR2,
        i_parent_msg IN pending_issue_message.id_pending_issue_msg_parent%TYPE,
        i_subject    IN VARCHAR2,
        i_message    IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_thread_level PLS_INTEGER := 0;
        l_parent_msg   PLS_INTEGER := 0;
    
        l_date TIMESTAMP WITH LOCAL TIME ZONE := SYSDATE;
    
        l_next_message_id NUMBER(24, 0);
    
        l_ids_profs table_number;
    
        l_episode pending_issue.id_episode%TYPE;
    
        l_error VARCHAR2(4000) := '';
    
        l_replay_string VARCHAR2(4000) := pk_message.get_message(i_lang, 'PENDING_ISSUE_T042');
    
        l_pi_subject VARCHAR2(2000);
    
        l_alert_event_row sys_alert_event%ROWTYPE;
        l_visit           visit.id_visit%TYPE;
        l_patient         patient.id_patient%TYPE;
    
        l_excep_episode EXCEPTION;
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
    BEGIN
    
        l_error := 'PK_PENDING_ISSUE.SET_MESSAGE';
    
        IF ((i_flg_reply = 'Y') AND (nvl(i_parent_msg, 0) > 0))
        THEN
            SELECT thread_level + 1
              INTO l_thread_level
              FROM pending_issue_message pim
             WHERE pim.id_pending_issue_message = i_parent_msg;
        
            l_parent_msg := i_parent_msg;
        END IF;
    
        BEGIN
            SELECT pi.id_episode, pi.id_patient
              INTO l_episode, l_patient
              FROM pending_issue pi
             WHERE pi.id_pending_issue = nvl(i_issue, 0);
        EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END;
    
        g_error := l_error || ' / ' || 'ID EPISODE IS NULL';
        IF l_episode IS NULL
        THEN
            RAISE l_excep_episode;
        END IF;
    
        -- CREATING THE MESSAGE ROOT
        g_error := l_error || ' / ' || 'MESSAGE NEXT VAL';
        SELECT seq_issue_message.nextval
          INTO l_next_message_id
          FROM dual;
    
        g_error := l_error || ' / ' || 'INSERT INTO PENDING_ISSUE_MESSAGE';
        INSERT INTO pending_issue_message
            (id_pending_issue_message,
             id_pending_issue_msg_parent,
             id_pending_issue,
             title,
             text,
             thread_level,
             dt_creation,
             dt_cancel,
             dt_update,
             flg_status,
             id_professional,
             id_prof_cancel)
        VALUES
            (l_next_message_id,
             l_parent_msg,
             i_issue,
             i_subject,
             REPLACE(i_message, l_replay_string, ''),
             l_thread_level,
             l_date,
             NULL,
             l_date,
             g_msg_flg_status_active,
             i_prof.id,
             NULL);
    
        -- CREATING THE PROFESSIONAL'S MESSAGES
        l_ids_profs := get_assigned(i_issue);
    
        FOR i IN 1 .. l_ids_profs.count
        LOOP
            IF (l_ids_profs(i) > 0)
            THEN
            
                g_error := l_error || ' / ' || 'INSERT INTO PENDING_ISSUE_PROF';
                INSERT INTO pending_issue_prof
                    (id_pending_issue, id_pending_issue_message, id_professional, dt_read, flg_status, dt_cancel)
                VALUES
                    (i_issue, l_next_message_id, l_ids_profs(i), NULL, g_msg_prof_flg_status_active, NULL);
            
                -- We're going to create the alert
                g_error := l_error || ' / ' || 'INSERT_SYS_ALERT_EVENT';
            
                BEGIN
                    SELECT nvl(id_visit, -1)
                      INTO l_visit
                      FROM episode e
                     WHERE e.id_episode = nvl(l_episode, -1);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_visit := -1;
                END;
            
                IF NOT set_alert_msg(i_lang          => i_lang,
                                     i_prof          => i_prof,
                                     i_issue         => i_issue,
                                     i_episode       => l_episode,
                                     i_patient       => l_patient,
                                     i_visit         => l_visit,
                                     i_receptor_prof => l_ids_profs(i),
                                     i_issue_message => l_next_message_id,
                                     o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_excep_episode THEN
            l_error_in.set_all(i_lang,
                               'PENDING_ISSUE_M007',
                               pk_message.get_message(i_lang, 'PENDING_ISSUE_M007'),
                               g_error,
                               'ALERT',
                               'PK_ALLERGY',
                               'SET_MESSAGE',
                               pk_message.get_message(i_lang, 'PENDING_ISSUE_M007'),
                               'U');
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_ret;
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_MESSAGE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_MESSAGE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_message;

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
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_issue IN pending_issue.id_pending_issue%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_created professional.id_professional%TYPE;
    
        TYPE t_sys_alert_event IS TABLE OF sys_alert_event%ROWTYPE;
        l_sys_alert_event t_sys_alert_event;
    
        l_error VARCHAR2(4000) := '';
    
    BEGIN
    
        l_error := 'PK_PENDING_ISSUE.CANCEL_ISSUE';
    
        -- GETTING THE PROFESSIONAL WHO CREATED THE MESSAGE
        BEGIN
            SELECT pi.id_professional
              INTO l_prof_created
              FROM pending_issue pi
             WHERE pi.id_pending_issue = i_issue;
        EXCEPTION
            WHEN OTHERS THEN
                l_prof_created := 0;
        END;
    
        IF (l_prof_created = i_prof.id)
        THEN
        
            g_error := l_error || ' / ' || 'UPDATE PENDING_ISSUE';
            UPDATE pending_issue pi
               SET pi.flg_status     = g_issue_flg_status_cancelled,
                   pi.dt_cancel      = current_timestamp,
                   pi.dt_update      = current_timestamp,
                   pi.id_prof_cancel = i_prof.id
             WHERE pi.id_pending_issue = i_issue;
        
            IF (SQL%ROWCOUNT > 0)
            THEN
                IF (pk_pending_issues.cancel_all_issue_messages(i_lang, i_prof, i_issue, o_error))
                THEN
                    g_error := l_error || ' BULK COLLECT STATEMENT';
                    SELECT *
                      BULK COLLECT
                      INTO l_sys_alert_event
                      FROM sys_alert_event sae
                     WHERE sae.id_record IN (SELECT pim.id_pending_issue_message
                                               FROM pending_issue_message pim
                                              WHERE pim.id_pending_issue = i_issue)
                       AND sae.id_professional = i_prof.id;
                
                    IF (l_sys_alert_event.count > 0)
                    THEN
                    
                        FOR i IN 1 .. l_sys_alert_event.last
                        LOOP
                        
                            g_error := l_error || ' / ' || 'DELETE_SYS_ALERT_EVENT';
                            IF (NOT pk_alerts.delete_sys_alert_event(i_lang, i_prof, l_sys_alert_event(i), o_error))
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                        END LOOP;
                    
                    END IF;
                
                    RETURN TRUE;
                ELSE
                    RAISE g_exception;
                END IF;
            ELSE
                -- mensagem a dizer que o profissional nao tem permissoes
                -- para remover o issue
                RAISE g_exception;
            END IF;
        
        ELSE
            RAISE g_exception;
        END IF;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'CANCEL_ISSUE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'CANCEL_ISSUE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END cancel_issue;

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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_message IN pending_issue_message.id_pending_issue_message%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_created professional.id_professional%TYPE;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_error VARCHAR2(4000) := '';
    
    BEGIN
    
        l_error := 'PK_PENDING_ISSUE.CANCEL_MESSAGE';
    
        -- GETTING THE PROFESSIONAL WHO CREATED THE MESSAGE
        BEGIN
            SELECT pim.id_professional
              INTO l_prof_created
              FROM pending_issue_message pim
             WHERE pim.id_pending_issue_message = i_message;
        EXCEPTION
            WHEN OTHERS THEN
                l_prof_created := 0;
        END;
    
        IF (l_prof_created = i_prof.id)
        THEN
            -- THE MESSAGE IS GOING TO BE CANCELLED
            g_error := l_error || ' UPDATE PENDING_ISSUE_MESSAGE';
            UPDATE pending_issue_message pim
               SET pim.flg_status     = g_msg_flg_status_cancelled,
                   pim.id_prof_cancel = i_prof.id,
                   pim.dt_cancel      = current_timestamp,
                   pim.dt_update      = current_timestamp
             WHERE pim.id_pending_issue_message = i_message;
        
            IF (SQL%ROWCOUNT > 0)
            THEN
                -- ALL MESSAGES FOR I_PROF.ID IS GOING TO BE CANCELLED
                g_error := l_error || ' UPDATE PENDING_ISSUE_PROF';
                UPDATE pending_issue_prof pip
                   SET pip.flg_status = g_msg_prof_flg_status_cancel, pip.dt_cancel = current_timestamp
                 WHERE pip.id_pending_issue_message = i_message
                   AND pip.id_professional = i_prof.id;
            
                BEGIN
                
                    g_error := l_error || ' SELECT INTO STATEMENT';
                    SELECT *
                      INTO l_sys_alert_event
                      FROM sys_alert_event sae
                     WHERE sae.id_record = i_message
                       AND sae.id_professional = i_prof.id;
                
                    g_error := l_error || ' DELETE_SYS_ALERT_EVENT CALL';
                    IF (NOT pk_alerts.delete_sys_alert_event(i_lang, i_prof, l_sys_alert_event, o_error))
                    THEN
                        RAISE g_exception;
                    END IF;
                
                EXCEPTION
                
                    WHEN OTHERS THEN
                        NULL;
                    
                END;
            
                RETURN TRUE;
            ELSE
                -- mensagem a indicar que a mensagem não foi cancelada
                RAISE g_exception;
            END IF;
        
        ELSE
            -- mensagem a indicar que o profissional nao tem permissões para
            -- cancelar o registo em questao
            RAISE g_exception;
        END IF;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'CANCEL_MESSAGE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'CANCEL_MESSAGE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END cancel_message;

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
     * @scope   Private
    */
    FUNCTION cancel_all_issue_messages
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_issue IN pending_issue.id_pending_issue%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_sys_alert_event IS TABLE OF sys_alert_event%ROWTYPE;
        l_sys_alert_event t_sys_alert_event;
    
        l_error VARCHAR2(4000) := '';
    
    BEGIN
    
        l_error := 'PK_PENDING_ISSUE.CANCEL_ALL_ISSUE_MESSAGES';
    
        -- THE MESSAGES IS GOING TO BE CANCELLED
        UPDATE pending_issue_message pim
           SET pim.flg_status     = g_msg_flg_status_cancelled,
               pim.dt_cancel      = current_timestamp,
               pim.id_prof_cancel = i_prof.id
         WHERE pim.id_pending_issue = i_issue;
    
        IF (SQL%ROWCOUNT > 0)
        THEN
            -- ALL THE PROF MESSAGES IS GOING TO BE CANCELLED
            g_error := l_error || ' / ' || 'UPDATE PENDING_ISSUE_PROF';
            UPDATE pending_issue_prof pip
               SET pip.flg_status = g_msg_prof_flg_status_cancel, pip.dt_cancel = current_timestamp
             WHERE pip.id_pending_issue = i_issue;
        
            g_error := l_error || ' / ' || 'BULK COLLECT STATEMENT - SYS_ALERT_EVENT';
            SELECT *
              BULK COLLECT
              INTO l_sys_alert_event
              FROM sys_alert_event sae
             WHERE sae.id_record IN (SELECT pim.id_pending_issue_message
                                       FROM pending_issue_message pim
                                      WHERE pim.id_pending_issue = i_issue)
               AND sae.id_professional = i_prof.id;
        
            IF (l_sys_alert_event.count > 0)
            THEN
            
                FOR i IN 1 .. l_sys_alert_event.last
                LOOP
                
                    IF (NOT pk_alerts.delete_sys_alert_event(i_lang, i_prof, l_sys_alert_event(i), o_error))
                    THEN
                        RAISE g_exception;
                    END IF;
                
                END LOOP;
            
            END IF;
        
            RETURN TRUE;
        ELSE
            RAISE g_exception;
        END IF;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'CANCEL_ALL_ISSUE_MESSAGES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'CANCEL_ALL_ISSUE_MESSAGES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_all_issue_messages;

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
     * @Updated By Gisela Couto - 2014-04-28
    */
    FUNCTION set_issue_status
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_issue  IN pending_issue.id_pending_issue%TYPE,
        i_status IN pending_issue.flg_status%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_previous_status VARCHAR2(1);
    
    BEGIN
    
        g_error := 'GET PREVIOUS STATUS';
    
        BEGIN
        
            SELECT pi.flg_status
              INTO l_previous_status
              FROM pending_issue pi
             WHERE pi.id_pending_issue = i_issue;
        
            IF (l_previous_status = i_status)
            THEN
                l_previous_status := NULL;
            END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_previous_status := NULL;
            
        END;
    
        g_error := 'UPDATE ISSUE STATUS';
        UPDATE pending_issue pi
           SET pi.flg_status      = i_status,
               pi.dt_update       = current_timestamp,
               pi.id_prof_update  = i_prof.id,
               pi.flg_status_hist = l_previous_status
         WHERE pi.id_pending_issue = i_issue;
    
        IF i_status = g_issue_flg_status_closed
           AND l_previous_status IS NOT NULL
        THEN
            g_error := 'CALL DELETE SYS_ALERT_EVENT';
            IF NOT delete_pend_issue_alert_event(i_lang      => i_lang,
                                                 i_tbl_prof  => NULL,
                                                 i_tbl_issue => table_number(i_issue),
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PENDING_ISSUES',
                                              'SET_ISSUE_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_issue_status;
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
    ) RETURN NUMBER IS
        l_recent_epis episode.id_episode%TYPE;
    BEGIN
        SELECT id_episode
          INTO l_recent_epis
          FROM (SELECT e.id_episode,
                       pk_episode.get_soft_by_epis_type(e.id_epis_type, 2) id_software,
                       e.dt_begin_tstz dt_begin
                  FROM episode e
                 WHERE e.id_patient = i_patient
                 ORDER BY dt_begin) epis
         WHERE epis.id_software = i_prof.software
           AND rownum = 1;
    
        RETURN l_recent_epis;
    
    END get_most_recent_epis;

END pk_pending_issues;
/
