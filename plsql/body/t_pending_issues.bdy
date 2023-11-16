/*-- Last Change Revision: $Rev: 2028428 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY t_pending_issues IS

    /** @headcom
    * DML operation - insert into issue table
    *
    * @param      I_LANG                     Language id
    * @param      I_ID_ISSUE                 The issue ID
    * @param      I_ID_PROF                  Profissional ID
    * @param      I_ID_PATIENT               Identificação do paciente
    * @param      I_ID_EPISODE               Identificação do episódio
    * @param      I_TITLE                    Título
    * @param      I_FLG_STATUS               The new issue status
    * @param      I_DATE_TSTZ                Issue creation date
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Sérgio Santos
    * @version    0.1
    * @since      2008/04/28
    */
    FUNCTION insert_issue
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_id_issue   IN issue.id_issue%TYPE,
        i_id_prof    IN issue.id_prof_owner%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_title      IN issue.title%TYPE,
        i_flg_status IN issue.flg_status%TYPE,
        i_date_tstz  IN issue.dt_creation%TYPE,
        o_error      OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'INSERT INTO issue';
        INSERT INTO issue
            (id_issue,
             title,
             id_prof_owner,
             id_patient,
             id_episode,
             flg_status,
             dt_creation,
             id_prof_deletion,
             dt_deletion)
        VALUES
            (i_id_issue, i_title, i_id_prof, i_id_patient, i_id_episode, i_flg_status, i_date_tstz, NULL, NULL);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'T_PENDING_ISSUES.INSERT_ISSUE / ' ||
                       g_error || ' / ' || SQLERRM;
            ROLLBACK;
            RETURN FALSE;
    END insert_issue;

    /** @headcom
    * DML operation - insert into issue message table
    *
    * @param      I_LANG                     Language id
    * @param      I_ID_ISSUE                 The issue ID
    * @param      I_ID_PROF                  Profissional ID
    * @param      I_FIRST_MESSAGE            The issue first message text
    * @param      I_FLG_STATUS               The new issue message status
    * @param      I_DATE_TSTZ                Issue message  creation date
    * @param      I_ID_PROF_DELETION         Professional id that cancelled the message
    * @param      ID_DT_DELETION_TSTZ        Date that the message was cancelled
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Sérgio Santos
    * @version    0.1
    * @since      2008/04/28
    */
    FUNCTION insert_issue_message
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_id_issue         IN issue_message.id_issue%TYPE,
        i_id_prof          IN issue_message.id_prof_owner%TYPE,
        i_first_msg        IN issue_message.text%TYPE,
        i_flg_status       IN issue_message.flg_status%TYPE,
        i_date_tstz        IN issue_message.dt_creation%TYPE,
        i_id_prof_deletion IN issue_message.id_prof_deletion%TYPE,
        i_dt_deletion_tstz IN issue_message.dt_deletion%TYPE,
        o_error            OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'INSERT INTO issue_message';
        INSERT INTO issue_message
            (id_issue_message, id_issue, id_prof_owner, dt_creation, text, flg_status, id_prof_deletion, dt_deletion)
        VALUES
            (seq_issue_message.NEXTVAL,
             i_id_issue,
             i_id_prof,
             i_date_tstz,
             i_first_msg,
             i_flg_status,
             i_id_prof_deletion,
             i_dt_deletion_tstz);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                       'T_PENDING_ISSUES.INSERT_ISSUE_MESSAGE / ' || g_error || ' / ' || SQLERRM;
            ROLLBACK;
            RETURN FALSE;
    END insert_issue_message;
    --
    /** @headcom
    * DML operation - insert into issue_prof_assigned table
    *
    * @param      I_LANG                     Language id
    * @param      I_ID_ISSUE                 The issue ID
    * @param      I_ID_PROF                     Profissional ID
    * @param      I_FLG_STATUS               The new issue message status
    * @param      I_DATE_TSTZ                Issue message  creation date
    * @param      I_ID_PROF_DELETION         Professional id that cancelled the message
    * @param      ID_DT_DELETION_TSTZ        Date that the message was cancelled
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Sérgio Santos
    * @version    0.1
    * @since      2008/04/28
    */
    FUNCTION insert_issue_prof_assigned
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_id_issue         IN issue_prof_assigned.id_issue%TYPE,
        i_id_prof          IN issue_prof_assigned.id_prof%TYPE,
        i_flg_status       IN issue_prof_assigned.flg_status%TYPE,
        i_date_tstz        IN issue_prof_assigned.dt_assign%TYPE,
        i_id_prof_deletion IN issue_prof_assigned.id_prof_deletion%TYPE,
        i_dt_deletion_tstz IN issue_prof_assigned.dt_deletion%TYPE,
        o_error            OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'INSERT INTO issue_prof_assigned';
        INSERT INTO issue_prof_assigned
            (id_issue, id_prof, flg_status, dt_assign, id_prof_deletion, dt_deletion)
        VALUES
            (i_id_issue, i_id_prof, i_flg_status, i_date_tstz, i_id_prof_deletion, i_dt_deletion_tstz);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                       'T_PENDING_ISSUES.INSERT_ISSUE_PROF_ASSIGNED / ' || g_error || ' / ' || SQLERRM;
            ROLLBACK;
            RETURN FALSE;
    END insert_issue_prof_assigned;
    --
BEGIN
    g_yes := 'Y';
    g_no  := 'N';
END t_pending_issues;
/
