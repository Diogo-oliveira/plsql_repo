/*-- Last Change Revision: $Rev: 2026699 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_pending_issues IS

    /********************************************************************************************
    * Get a list of issues with the associated department
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_institution                 Institution ID
    * @param o_issue_dept                  Cursor of issues and depts
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION get_issue_dept_info
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN PROFISSIONAL,
        i_id_institution IN institution.id_institution%TYPE,
        o_issue_dept     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ISSUE_DEPT CURSOR';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_issue_dept FOR
            SELECT DISTINCT pitd.id_pending_issue_title,
                            pit.desc_title,
                            pk_utils.concat_table(CAST(MULTISET
                                                       (SELECT ptd.id_dept
                                                          FROM pending_issue_title_dept ptd
                                                          JOIN dept d ON ptd.id_dept = d.id_dept
                                                         WHERE ptd.id_pending_issue_title = pitd.id_pending_issue_title
                                                         ORDER BY pk_translation.get_translation(i_lang, d.code_dept)) AS
                                                       TABLE_VARCHAR),
                                                  ',') id_dept,
                            pk_utils.concat_table(CAST(MULTISET
                                                       (SELECT pk_translation.get_translation(i_lang, d.code_dept)
                                                          FROM pending_issue_title_dept ptd
                                                          JOIN dept d ON ptd.id_dept = d.id_dept
                                                         WHERE ptd.id_pending_issue_title = pitd.id_pending_issue_title
                                                         ORDER BY pk_translation.get_translation(i_lang, d.code_dept)) AS
                                                       TABLE_VARCHAR),
                                                  ', ') desc_dept
              FROM pending_issue_title_dept pitd
              JOIN pending_issue_title pit ON pitd.id_pending_issue_title = pit.id_pending_issue_title
              JOIN dept d ON pitd.id_dept = d.id_dept
             WHERE d.id_institution = i_id_institution
             ORDER BY pit.desc_title;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_issue_dept);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_API_PENDING_ISSUES',
                                   'GET_ISSUE_DEPT_INFO');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_issue_dept_info;

    /********************************************************************************************
    * Get an issue title detail and modifications history
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_issue                       Issue title ID
    * @param o_issue_dept_detail           Cursor of issue title informations detail
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION get_issue_dept_detail_info
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN PROFISSIONAL,
        i_issue             IN pending_issue_title.id_pending_issue_title%TYPE,
        o_issue_dept_detail OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ISSUE_DEPT CURSOR';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_issue_dept_detail FOR
            SELECT DISTINCT pith.desc_title,
                            pk_utils.concat_table(CAST(MULTISET
                                                       (SELECT pk_translation.get_translation(i_lang, d.code_dept)
                                                          FROM pending_issue_title_dept_hist ptdh
                                                          JOIN dept d ON ptdh.id_dept = d.id_dept
                                                         WHERE ptdh.id_pending_issue_title_hist =
                                                               pith.id_pending_issue_title_hist
                                                         ORDER BY pk_translation.get_translation(i_lang, d.code_dept)) AS
                                                       TABLE_VARCHAR),
                                                  ', ') desc_dept,
                            pk_date_utils.date_char_tsz(i_lang, pith.begin_date, i_prof.institution, i_prof.software) bg_date,
                            (SELECT p.name
                               FROM professional p
                              WHERE p.id_professional = pith.id_professional) name_prof,
                            pk_alert_constant.g_active flg_status,
                            pith.begin_date
              FROM pending_issue_title_hist pith
             WHERE pith.id_pending_issue_title = i_issue
               AND pith.end_date IS NULL
            UNION ALL
            SELECT DISTINCT pith.desc_title,
                            pk_utils.concat_table(CAST(MULTISET
                                                       (SELECT pk_translation.get_translation(i_lang, d.code_dept)
                                                          FROM pending_issue_title_dept_hist ptdh
                                                          JOIN dept d ON ptdh.id_dept = d.id_dept
                                                         WHERE ptdh.id_pending_issue_title_hist =
                                                               pith.id_pending_issue_title_hist
                                                         ORDER BY pk_translation.get_translation(i_lang, d.code_dept)) AS
                                                       TABLE_VARCHAR),
                                                  ', ') desc_dept,
                            pk_date_utils.date_char_tsz(i_lang, pith.begin_date, i_prof.institution, i_prof.software) bg_date,
                            (SELECT p.name
                               FROM professional p
                              WHERE p.id_professional = pith.id_professional) name_prof,
                            pk_alert_constant.g_inactive flg_status,
                            pith.begin_date
              FROM pending_issue_title_hist pith
             WHERE pith.id_pending_issue_title = i_issue
               AND pith.end_date IS NOT NULL
             ORDER BY flg_status ASC, begin_date DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_issue_dept_detail);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_API_PENDING_ISSUES',
                                   'GET_ISSUE_DEPT_DETAIL_INFO');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_issue_dept_detail_info;

    /********************************************************************************************
    * Set issue title modifications
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_dept                        Array of departments ID
    * @param i_issue                       Array of pending issue title ID
    * @param i_dec_issue                   Array of pending issue title description ID
    * @param o_issue                       Array of pending issue title IDs updated/inserted
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION set_issue_dept
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN PROFISSIONAL,
        i_dept       IN TABLE_NUMBER,
        i_issue      IN TABLE_NUMBER,
        i_desc_issue IN TABLE_VARCHAR,
        o_issue      OUT TABLE_NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_issue                       pending_issue_title.id_pending_issue_title%TYPE;
        l_id_pending_issue_title_hist pending_issue_title_hist.id_pending_issue_title_hist%TYPE;
    
        e_field_too_long EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_field_too_long, -12899);
        l_error VARCHAR2(4000);
    
    BEGIN
        o_issue := TABLE_NUMBER();
    
        FOR i IN 1 .. i_issue.COUNT
        LOOP
            o_issue.EXTEND();
            IF i_issue(i) IS NOT NULL
            THEN
                l_issue := i_issue(i);
            
                g_error := 'UPDATE PENDING_ISSUE_TITLE';
                pk_alertlog.log_debug(g_error);
                UPDATE pending_issue_title pit
                   SET pit.desc_title = i_desc_issue(i)
                 WHERE pit.id_pending_issue_title = l_issue;
            
                g_error := 'UPDATE PENDING_ISSUE_TITLE_HIST';
                pk_alertlog.log_debug(g_error);
                UPDATE pending_issue_title_hist pith
                   SET pith.end_date = current_timestamp
                 WHERE pith.id_pending_issue_title = l_issue
                   AND pith.end_date IS NULL;
            
                g_error := 'SELECT PENDING_ISSUE_TITLE_HIST NEXTVAL';
                pk_alertlog.log_debug(g_error);
                SELECT seq_pending_issue_title_hist.NEXTVAL
                  INTO l_id_pending_issue_title_hist
                  FROM dual;
            
                g_error := 'INSERT PENDING_ISSUE_TITLE_HIST';
                pk_alertlog.log_debug(g_error);
                INSERT INTO pending_issue_title_hist
                    (id_pending_issue_title_hist,
                     id_pending_issue_title,
                     desc_title,
                     begin_date,
                     end_date,
                     id_professional)
                VALUES
                    (l_id_pending_issue_title_hist, l_issue, i_desc_issue(i), current_timestamp, NULL, i_prof.id);
            
                g_error := 'DELETE PENDING_ISSUE_TITLE_DEPT';
                pk_alertlog.log_debug(g_error);
                DELETE FROM pending_issue_title_dept pitd
                 WHERE pitd.id_pending_issue_title = l_issue;
            
            ELSE
                g_error := 'SELECT PENDING_ISSUE_TITLE NEXTVAL';
                pk_alertlog.log_debug(g_error);
                SELECT seq_pending_issue_title.NEXTVAL
                  INTO l_issue
                  FROM dual;
            
                g_error := 'INSERT PENDING_ISSUE_TITLE';
                pk_alertlog.log_debug(g_error);
                INSERT INTO pending_issue_title
                    (id_pending_issue_title, desc_title)
                VALUES
                    (l_issue, i_desc_issue(i));
            
                g_error := 'SELECT PENDING_ISSUE_TITLE_HIST NEXTVAL';
                pk_alertlog.log_debug(g_error);
                SELECT seq_pending_issue_title_hist.NEXTVAL
                  INTO l_id_pending_issue_title_hist
                  FROM dual;
            
                g_error := 'INSERT PENDING_ISSUE_TITLE_HIST';
                pk_alertlog.log_debug(g_error);
                INSERT INTO pending_issue_title_hist
                    (id_pending_issue_title_hist,
                     id_pending_issue_title,
                     desc_title,
                     begin_date,
                     end_date,
                     id_professional)
                VALUES
                    (l_id_pending_issue_title_hist, l_issue, i_desc_issue(i), current_timestamp, NULL, i_prof.id);
            
            END IF;
        
            o_issue(i) := l_issue;
        
            FOR j IN 1 .. i_dept.COUNT
            LOOP
                g_error := 'INSERT PENDING_ISSUE_TITLE_DEPT';
                pk_alertlog.log_debug(g_error);
                INSERT INTO pending_issue_title_dept
                    (id_pending_issue_title, id_dept)
                VALUES
                    (l_issue, i_dept(j));
            
                g_error := 'INSERT PENDING_ISSUE_TITLE_DEPT_HIST';
                pk_alertlog.log_debug(g_error);
                INSERT INTO pending_issue_title_dept_hist
                    (id_pending_issue_title_hist, id_dept)
                VALUES
                    (l_id_pending_issue_title_hist, i_dept(j));
            
            END LOOP;
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_field_too_long THEN
        
            l_error := pk_message.get_message(i_lang, 'ADMINISTRATOR_T605');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              l_error,
                                              g_error,
                                              'ALERT',
                                              'PK_API_PENDING_ISSUES',
                                              'SET_ISSUE_DEPT',
                                              'U',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_API_PENDING_ISSUES',
                                   'SET_ISSUE_DEPT');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_utils.undo_changes;
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_issue_dept;

    /********************************************************************************************
    * Delete selected issue titles
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_issue                       Array of pending issue title ID
    * @param o_issue                       Array of deleted issue title ID
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION cancel_issues
    (
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN PROFISSIONAL,
        i_issue IN TABLE_NUMBER,
        o_issue OUT TABLE_NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        o_issue := TABLE_NUMBER();
    
        FOR i IN 1 .. i_issue.COUNT
        LOOP
            o_issue.EXTEND();
        
            g_error := 'DELETE PENDING_ISSUE_TITLE_DEPT';
            pk_alertlog.log_debug(g_error);
            DELETE FROM pending_issue_title_dept pitd
             WHERE pitd.id_pending_issue_title = i_issue(i);
        
            g_error := 'DELETE PENDING_ISSUE_TITLE';
            pk_alertlog.log_debug(g_error);
            DELETE FROM pending_issue_title pit
             WHERE pit.id_pending_issue_title = i_issue(i);
        
            g_error := 'UPDATE PENDING_ISSUE_TITLE_HIST';
            pk_alertlog.log_debug(g_error);
            UPDATE pending_issue_title_hist pith
               SET pith.end_date = current_timestamp
             WHERE pith.id_pending_issue_title = i_issue(i)
               AND pith.end_date IS NULL;
        
            o_issue(i) := i_issue(i);
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_API_PENDING_ISSUES',
                                   'CANCEL_ISSUES');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_utils.undo_changes;
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END cancel_issues;

END pk_api_pending_issues;
/
