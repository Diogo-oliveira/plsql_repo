/*-- Last Change Revision: $Rev: 2026792 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_pending_issues IS
    /********************************************************************************************
    * Set message body in clob field
    *
    * @param i_lang                                Prefered language ID
    * @param i_id_message                          Message identifier
    * @param i_id_thread                           Thread identifier
    * @param i_msg_body                            Large text with message bocy
    *
    * @return                  true or false
    *
    * @author                  RMGM
    * @version                 2.6.4.2.2
    * @since                   2014/10/27
    ********************************************************************************************/
    PROCEDURE set_message_body
    (
        i_lang      IN language.id_language%TYPE,
        i_id_msg    IN pending_issue_message.id_pending_issue_message%TYPE,
        i_id_thread IN pending_issue_message.id_pending_issue%TYPE,
        i_msg_body  IN CLOB
    ) IS
    BEGIN
        g_error := 'SET NEW MESSAGE body ' || i_id_thread || '/ ' || i_id_msg;
        UPDATE pending_issue_message pim
           SET pim.msg_body = i_msg_body
         WHERE pim.id_pending_issue = i_id_thread
           AND pim.id_pending_issue_message = i_id_msg;
    END set_message_body;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET GROUP INSTITUTION';
        OPEN o_group_institution FOR
            SELECT DISTINCT g.id_group,
                            g.name,
                            pk_utils.concat_table(CAST(MULTISET
                                                       (SELECT pk_translation.get_translation(i_lang, d.code_dept)
                                                          FROM groups_dept gdi, dept d
                                                         WHERE gdi.id_dept = d.id_dept
                                                           AND gdi.id_group = g.id_group
                                                           AND d.id_institution = i_institution
                                                         ORDER BY 1) AS table_varchar),
                                                  ', ') departments_names,
                            pk_utils.concat_table(CAST(MULTISET
                                                       (SELECT d.id_dept
                                                          FROM groups_dept gdi, dept d
                                                         WHERE gdi.id_dept = d.id_dept
                                                           AND gdi.id_group = g.id_group
                                                           AND d.id_institution = i_institution
                                                         ORDER BY pk_translation.get_translation(i_lang, d.code_dept)) AS
                                                       table_number),
                                                  ',') id_departments,
                            (SELECT COUNT(DISTINCT pg.id_professional)
                               FROM prof_groups pg
                              WHERE pg.id_group = g.id_group
                                AND pg.flg_state = pk_alert_constant.g_active) count_active_prof,
                            pk_alert_constant.g_inactive help_group
              FROM groups g
              JOIN groups_dept gd
                ON g.id_group = gd.id_group
              JOIN dept d
                ON gd.id_dept = d.id_dept
             WHERE g.flg_available = pk_alert_constant.g_yes
               AND d.id_institution = i_institution
             ORDER BY g.name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_group_institution);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'GET_GROUP_INSTITUTION',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_group_institution;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET DEPARTMENT INSTITUTION';
        IF i_institution IS NOT NULL
           AND i_lang IS NOT NULL
        THEN
            OPEN o_department FOR
                SELECT pk_translation.get_translation(i_lang, d.code_dept) department_name, d.id_dept department_id
                  FROM dept d
                 WHERE d.id_institution = i_institution
                   AND d.flg_available = pk_alert_constant.g_yes
                   AND pk_translation.get_translation(i_lang, d.code_dept) IS NOT NULL
                 ORDER BY 1;
        ELSE
            RAISE exception1;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN exception1 THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'GET_DEPARTMENT_INSTIT',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_department);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'GET_DEPARTMENT_INSTIT',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_department_instit;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET PROFESSIONAL INSTITUTION';
        IF i_institution IS NOT NULL
           AND i_lang IS NOT NULL
        THEN
            OPEN o_prof_institution FOR
                SELECT DISTINCT p.id_professional id_professional,
                                p.name name,
                                decode(pk_profphoto.check_blob(p.id_professional),
                                       'N',
                                       '',
                                       pk_profphoto.get_prof_photo(profissional(p.id_professional, 0, 0))) photo
                  FROM prof_institution pi, professional p, prof_cat pc
                 WHERE pi.id_professional = p.id_professional
                   AND pc.id_professional = p.id_professional
                   AND pc.id_category = i_category
                   AND pi.id_institution = i_institution
                   AND p.flg_state = pk_alert_constant.g_active
                   AND pi.flg_state = pk_alert_constant.g_active
                   AND pi.dt_end_tstz IS NULL
                   AND pk_prof_utils.is_internal_prof(i_lang, profissional(0, 0, 0), p.id_professional, i_institution) =
                       pk_alert_constant.get_yes
                   AND p.name IS NOT NULL
                 ORDER BY 2;
        ELSE
            RAISE exception1;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN exception1 THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'GET_PROF_INSTITUTION',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_prof_institution);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'GET_PROF_INSTITUTION',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_prof_institution;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET PROF CATEGORY INSTITUTION';
        IF i_institution IS NOT NULL
           AND i_lang IS NOT NULL
        THEN
            OPEN o_prof_cat_institution FOR
                SELECT res.id_category id_category,
                       pk_translation.get_translation(i_lang, c.code_category) code_category
                  FROM (SELECT pc.id_category
                          FROM prof_institution pi
                         INNER JOIN prof_cat pc
                            ON (pc.id_professional = pi.id_professional)
                         WHERE pi.flg_state = pk_alert_constant.g_active
                           AND pc.id_institution = pi.id_institution
                           AND pi.id_institution = i_institution
                           AND pi.dt_end_tstz IS NULL
                         GROUP BY pc.id_category) res
                 INNER JOIN category c
                    ON (c.id_category = res.id_category)
                 WHERE pk_translation.get_translation(i_lang, c.code_category) IS NOT NULL
                   AND c.flg_available = pk_alert_constant.g_yes
                 ORDER BY code_category;
        ELSE
            RAISE exception1;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN exception1 THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'GET_PROF_CATEGORY_INSTITUTION',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_prof_cat_institution);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'GET_PROF_CATEGORY_INSTITUTION',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_prof_category_institution;

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
    ) RETURN BOOLEAN IS
    
        l_id_group groups.id_group%TYPE;
    
    BEGIN
        o_id_group := table_number();
    
        FOR i IN 1 .. i_id_group.count
        LOOP
            o_id_group.extend();
            l_id_group := i_id_group(i);
        
            g_error := 'CANCEL GROUPS';
            pk_alertlog.log_debug(g_error);
            UPDATE groups g
               SET g.flg_available = pk_alert_constant.g_no
             WHERE g.id_group = l_id_group;
        
            g_error := 'UPDATE GROUPS_HIST';
            pk_alertlog.log_debug(g_error);
            UPDATE groups_hist gh
               SET gh.end_date = current_timestamp
             WHERE gh.id_group = l_id_group
               AND gh.end_date IS NULL;
        
            o_id_group(i) := i_id_group(i);
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'UPDATE_GROUP_INSTITUTION',
                                              o_error);
            pk_utils.undo_changes;
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END update_group_institution;

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
    ) RETURN BOOLEAN IS
    
        l_id_group      NUMBER;
        l_id_group_hist NUMBER;
    
    BEGIN
    
        IF i_id_group IS NOT NULL
        THEN
            l_id_group := i_id_group;
        
            g_error := 'UPDATE GROUPS_HIST';
            pk_alertlog.log_debug(g_error);
            UPDATE groups_hist gh
               SET gh.end_date = current_timestamp
             WHERE gh.id_group = l_id_group
               AND gh.end_date IS NULL;
        
            g_error := 'UPDATE GROUPS NAME';
            pk_alertlog.log_debug(g_error);
            UPDATE groups g
               SET g.name = i_group_name
             WHERE g.id_group = l_id_group;
        
            g_error := 'SELECT GROUP_HIST NEXTVAL';
            pk_alertlog.log_debug(g_error);
            SELECT seq_groups_hist.nextval
              INTO l_id_group_hist
              FROM dual;
        
            g_error := 'INSERT GROUP_HIST';
            pk_alertlog.log_debug(g_error);
            INSERT INTO groups_hist
                (id_group_hist, id_group, name, begin_date, end_date, id_prof_change)
            VALUES
                (l_id_group_hist, l_id_group, i_group_name, current_timestamp, NULL, i_prof_change.id);
        
            g_error := 'DELETE GROUP_DEPT';
            pk_alertlog.log_debug(g_error);
            DELETE FROM groups_dept gd
             WHERE gd.id_group = l_id_group;
        
            g_error := 'DELETE PROF_GROUP';
            pk_alertlog.log_debug(g_error);
            DELETE FROM prof_groups pg
             WHERE pg.id_group = l_id_group;
        ELSE
            g_error := 'SELECT GROUPS NEXTVAL';
            pk_alertlog.log_debug(g_error);
            SELECT seq_groups.nextval
              INTO l_id_group
              FROM dual;
        
            g_error := 'INSERT GROUPS';
            pk_alertlog.log_debug(g_error);
            INSERT INTO groups
                (id_group, name, flg_available)
            VALUES
                (l_id_group, i_group_name, pk_alert_constant.g_yes);
        
            g_error := 'SELECT GROUP_HIST NEXTVAL';
            pk_alertlog.log_debug(g_error);
            SELECT seq_groups_hist.nextval
              INTO l_id_group_hist
              FROM dual;
        
            g_error := 'INSERT GROUP_HIST';
            pk_alertlog.log_debug(g_error);
            INSERT INTO groups_hist
                (id_group_hist, id_group, name, begin_date, end_date, id_prof_change)
            VALUES
                (l_id_group_hist, l_id_group, i_group_name, current_timestamp, NULL, i_prof_change.id);
        END IF;
    
        FOR i IN 1 .. i_department.count
        LOOP
            g_error := 'INSERT GROUPS DEPT';
            pk_alertlog.log_debug(g_error);
            INSERT INTO groups_dept
                (id_group, id_dept)
            VALUES
                (l_id_group, i_department(i));
        
            g_error := 'INSERT GROUPS DEPT HIST';
            pk_alertlog.log_debug(g_error);
            INSERT INTO groups_dept_hist
                (id_group_hist, id_group, id_dept)
            VALUES
                (l_id_group_hist, l_id_group, i_department(i));
        END LOOP;
    
        FOR j IN 1 .. i_professional.count
        LOOP
            g_error := 'INSERT PROF GROUPS';
            pk_alertlog.log_debug(g_error);
            INSERT INTO prof_groups
                (id_group, id_professional, flg_state, notes)
            VALUES
                (l_id_group, i_professional(j), i_prof_status(j), i_notes(j));
        
            g_error := 'INSERT PROF GROUPS HIST';
            pk_alertlog.log_debug(g_error);
            INSERT INTO prof_groups_hist
                (id_group_hist, id_group, id_professional, flg_state, notes)
            VALUES
                (l_id_group_hist, l_id_group, i_professional(j), i_prof_status(j), i_notes(j));
        END LOOP;
    
        o_id_group      := l_id_group;
        o_id_hist_group := l_id_group_hist;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'SET_PROF_GROUP_INSTITUTION',
                                              o_error);
        
            pk_utils.undo_changes;
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_prof_group_institution;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET GROUP NAME';
        pk_alertlog.log_debug(g_error);
        OPEN o_name FOR
            SELECT g.name
              FROM groups g
             WHERE g.id_group = i_group;
    
        g_error := 'GET DEPARTMENTS';
        pk_alertlog.log_debug(g_error);
        OPEN o_departments FOR
            SELECT d.id_dept,
                   pk_translation.get_translation(i_lang, d.code_dept) code_dept,
                   pk_alert_constant.g_yes flg_active
              FROM groups_dept gd
              JOIN dept d
                ON gd.id_dept = d.id_dept
             WHERE gd.id_group = i_group
               AND pk_translation.get_translation(i_lang, d.code_dept) IS NOT NULL
             ORDER BY 2;
    
        g_error := 'GET PROFESSIONAL INFO';
        pk_alertlog.log_debug(g_error);
        OPEN o_professional FOR
            SELECT p.id_professional id_professional,
                   p.name name,
                   c.id_category id_category,
                   pk_translation.get_translation(i_lang, c.code_category) code_category,
                   pg.flg_state flg_status,
                   pk_sysdomain.get_domain('ACTIVE_INACTIVE', nvl(pg.flg_state, 'I'), i_lang) status,
                   decode(pk_profphoto.check_blob(p.id_professional),
                          'N',
                          '',
                          pk_profphoto.get_prof_photo(profissional(p.id_professional, 0, 0))) photo,
                   pg.notes notes,
                   'I' flg_help
              FROM prof_groups pg
              JOIN professional p
                ON pg.id_professional = p.id_professional
              JOIN prof_cat pc
                ON p.id_professional = pc.id_professional
              JOIN category c
                ON pc.id_category = c.id_category
             WHERE pg.id_group = i_group
               AND pc.id_institution = i_institution
               AND pk_prof_utils.is_internal_prof(i_lang, profissional(0, 0, 0), p.id_professional, i_institution) =
                   pk_alert_constant.get_yes
             ORDER BY p.name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_name);
            pk_types.open_my_cursor(o_departments);
            pk_types.open_my_cursor(o_professional);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'GET_PROF_GROUP_INSTITUTION',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_prof_group_institution;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET DETAIL GROUP';
        pk_alertlog.log_debug(g_error);
        OPEN o_detail_group FOR
            SELECT gh.id_group_hist,
                   gh.name,
                   pk_utils.concat_table(CAST(MULTISET (SELECT pk_translation.get_translation(i_lang, d.code_dept)
                                                 FROM groups_dept_hist gdhi, dept d
                                                WHERE gdhi.id_dept = d.id_dept
                                                  AND gdhi.id_group_hist = gh.id_group_hist
                                                ORDER BY 1) AS table_varchar),
                                         ', ') departments_names,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, gh.begin_date, i_prof) bg_date,
                   (SELECT p.name
                      FROM professional p
                     WHERE p.id_professional = gh.id_prof_change) name_prof,
                   pk_alert_constant.g_active flg_status,
                   gh.begin_date
              FROM groups_hist gh
              JOIN groups_dept_hist gdh
                ON gh.id_group_hist = gdh.id_group_hist
             WHERE gh.id_group = i_group
               AND gh.end_date IS NULL
            UNION
            SELECT gh.id_group_hist,
                   gh.name,
                   pk_utils.concat_table(CAST(MULTISET (SELECT pk_translation.get_translation(i_lang, d.code_dept)
                                                 FROM groups_dept_hist gdhi, dept d
                                                WHERE gdhi.id_dept = d.id_dept
                                                  AND gdhi.id_group_hist = gh.id_group_hist
                                                ORDER BY 1) AS table_varchar),
                                         ', ') departments_names,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, gh.begin_date, i_prof) bg_date,
                   (SELECT p.name
                      FROM professional p
                     WHERE p.id_professional = gh.id_prof_change) name_prof,
                   pk_alert_constant.g_inactive flg_status,
                   gh.begin_date
              FROM groups_hist gh
              JOIN groups_dept_hist gdh
                ON gh.id_group_hist = gdh.id_group_hist
             WHERE gh.id_group = i_group
               AND gh.end_date IS NOT NULL
             ORDER BY flg_status ASC, begin_date DESC;
    
        g_error := 'GET PROF DETAIL GROUP';
        pk_alertlog.log_debug(g_error);
        OPEN o_prof_detail_group FOR
            SELECT pgh.id_group_hist,
                   p.name,
                   pk_translation.get_translation(i_lang, c.code_category) code_category,
                   pgh.flg_state,
                   pk_sysdomain.get_domain('ACTIVE_INACTIVE', nvl(pgh.flg_state, 'I'), i_lang) desc_state,
                   pgh.notes
              FROM prof_groups_hist pgh
              JOIN professional p
                ON pgh.id_professional = p.id_professional
              JOIN prof_cat pc
                ON p.id_professional = pc.id_professional
              JOIN category c
                ON pc.id_category = c.id_category
             WHERE pgh.id_group = i_group
               AND pc.id_institution = i_id_institution
               AND pk_prof_utils.is_internal_prof(i_lang, profissional(0, 0, 0), p.id_professional, i_id_institution) =
                   pk_alert_constant.get_yes
            
             ORDER BY pgh.id_group_hist DESC, p.name ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail_group);
            pk_types.open_my_cursor(o_prof_detail_group);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'GET_DETAIL_GROUP',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_detail_group;

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
    ) RETURN t_tbl_msg IS
        l_tbl_msg t_tbl_msg;
    BEGIN
        SELECT t_rec_msg(msg.thread_id,
                         msg.msg_id,
                         msg.subject,
                         msg.body,
                         msg.id_sender,
                         msg.name_sender,
                         msg.id_receiver,
                         msg.name_to,
                         msg.thread_status,
                         msg.msg_status_sender,
                         msg.msg_status_receiver,
                         msg.thread_level,
                         msg.dt_creation,
                         msg.flg_sender,
                         msg.representative_tag)
          BULK COLLECT
          INTO l_tbl_msg
          FROM (SELECT sms.thread_id,
                       sms.msg_id,
                       sms.subject,
                       sms.body,
                       sms.id_sender,
                       decode(sms.flg_sender,
                              g_patient_sender,
                              pk_patient.get_pat_name(i_lang, profissional(sms.id_receiver, 0, 0), sms.id_sender, -1),
                              pk_prof_utils.get_name(i_lang, sms.id_sender)) name_sender,
                       sms.id_receiver,
                       decode(sms.flg_sender,
                              g_patient_sender,
                              pk_prof_utils.get_name(i_lang, sms.id_receiver),
                              pk_patient.get_pat_name(i_lang, profissional(sms.id_sender, 0, 0), sms.id_receiver, -1)) name_to,
                       sms.thread_status,
                       sms.msg_status_sender,
                       sms.msg_status_receiver,
                       sms.thread_level,
                       sms.dt_creation,
                       sms.flg_sender,
                       sms.representative_tag
                  FROM v_all_messages sms
                 WHERE sms.id_sender = i_patient
                   AND sms.flg_sender = g_patient_sender) msg;
    
        RETURN l_tbl_msg;
    END get_patient_outbox;
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
    ) RETURN t_tbl_msg IS
        l_tbl_msg t_tbl_msg;
    BEGIN
    
        SELECT t_rec_msg(msg.thread_id,
                         msg.msg_id,
                         msg.subject,
                         msg.body,
                         msg.id_sender,
                         msg.name_sender,
                         msg.id_receiver,
                         msg.name_to,
                         msg.thread_status,
                         msg.msg_status_sender,
                         msg.msg_status_receiver,
                         msg.thread_level,
                         msg.dt_creation,
                         msg.flg_sender,
                         msg.representative_tag)
          BULK COLLECT
          INTO l_tbl_msg
          FROM (SELECT sms.thread_id,
                       sms.msg_id,
                       sms.subject,
                       sms.body,
                       sms.id_sender,
                       decode(sms.flg_sender,
                              g_patient_sender,
                              pk_patient.get_pat_name(i_lang, profissional(sms.id_receiver, 0, 0), sms.id_sender, -1),
                              pk_prof_utils.get_name(i_lang, sms.id_sender)) name_sender,
                       sms.id_receiver,
                       decode(sms.flg_sender,
                              g_patient_sender,
                              pk_prof_utils.get_name(i_lang, sms.id_receiver),
                              pk_patient.get_pat_name(i_lang, profissional(sms.id_sender, 0, 0), sms.id_receiver, -1)) name_to,
                       sms.thread_status,
                       sms.msg_status_sender,
                       sms.msg_status_receiver,
                       sms.thread_level,
                       sms.dt_creation,
                       sms.flg_sender,
                       sms.representative_tag
                  FROM v_all_messages sms
                 WHERE sms.id_receiver = i_patient
                   AND sms.flg_sender = g_professional_sender) msg;
    
        RETURN l_tbl_msg;
    END get_patient_inbox;

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
    ) RETURN t_tbl_msg IS
        l_tbl_msg t_tbl_msg;
    BEGIN
    
        SELECT t_rec_msg(msg.thread_id,
                         msg.msg_id,
                         msg.subject,
                         msg.body,
                         msg.id_sender,
                         msg.name_sender,
                         msg.id_receiver,
                         msg.name_to,
                         msg.thread_status,
                         msg.msg_status_sender,
                         msg.msg_status_receiver,
                         msg.thread_level,
                         msg.dt_creation,
                         msg.flg_sender,
                         msg.representative_tag)
          BULK COLLECT
          INTO l_tbl_msg
          FROM (SELECT sms.thread_id,
                       sms.msg_id,
                       sms.subject,
                       sms.body,
                       sms.id_sender,
                       decode(sms.flg_sender,
                              g_patient_sender,
                              pk_patient.get_pat_name(i_lang, profissional(sms.id_receiver, 0, 0), sms.id_sender, -1),
                              pk_prof_utils.get_name(i_lang, sms.id_sender)) name_sender,
                       sms.id_receiver,
                       decode(sms.flg_sender,
                              g_patient_sender,
                              pk_prof_utils.get_name(i_lang, sms.id_receiver),
                              pk_patient.get_pat_name(i_lang, profissional(sms.id_sender, 0, 0), sms.id_receiver, -1)) name_to,
                       sms.thread_status,
                       sms.msg_status_sender,
                       sms.msg_status_receiver,
                       sms.thread_level,
                       sms.dt_creation,
                       sms.flg_sender,
                       sms.representative_tag
                  FROM v_all_messages sms
                 WHERE sms.id_sender = i_professional
                   AND sms.flg_sender = g_professional_sender) msg;
    
        RETURN l_tbl_msg;
    END get_professional_outbox;
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
    ) RETURN t_tbl_msg IS
        l_tbl_msg t_tbl_msg;
    BEGIN
        SELECT t_rec_msg(msg.thread_id,
                         msg.msg_id,
                         msg.subject,
                         msg.body,
                         msg.id_sender,
                         msg.name_sender,
                         msg.id_receiver,
                         msg.name_to,
                         msg.thread_status,
                         msg.msg_status_sender,
                         msg.msg_status_receiver,
                         msg.thread_level,
                         msg.dt_creation,
                         msg.flg_sender,
                         msg.representative_tag)
          BULK COLLECT
          INTO l_tbl_msg
          FROM (SELECT sms.thread_id,
                       sms.msg_id,
                       sms.subject,
                       sms.body,
                       sms.id_sender,
                       decode(sms.flg_sender,
                              g_patient_sender,
                              pk_patient.get_pat_name(i_lang, profissional(sms.id_receiver, 0, 0), sms.id_sender, -1),
                              pk_prof_utils.get_name(i_lang, sms.id_sender)) name_sender,
                       sms.id_receiver,
                       decode(sms.flg_sender,
                              g_patient_sender,
                              pk_prof_utils.get_name(i_lang, sms.id_receiver),
                              pk_patient.get_pat_name(i_lang, profissional(sms.id_sender, 0, 0), sms.id_receiver, -1)) name_to,
                       sms.thread_status,
                       sms.msg_status_sender,
                       sms.msg_status_receiver,
                       sms.thread_level,
                       sms.dt_creation,
                       sms.flg_sender,
                       sms.representative_tag
                  FROM v_all_messages sms
                 WHERE sms.id_receiver = i_professional
                   AND sms.flg_sender = g_patient_sender) msg;
    
        RETURN l_tbl_msg;
    END get_professional_inbox;

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
    ) RETURN NUMBER IS
        l_result NUMBER(24) := 0;
    BEGIN
        IF i_flg_inbox = g_patient_sender
        THEN
            SELECT COUNT(*)
              INTO l_result
              FROM TABLE(pk_backoffice_pending_issues.get_patient_inbox(i_lang, i_id_receiver)) msg
             WHERE msg.msg_status_receiver = g_unread_status;
        ELSE
            SELECT COUNT(*)
              INTO l_result
              FROM TABLE(pk_backoffice_pending_issues.get_professional_inbox(i_lang, i_id_receiver)) msg
             WHERE msg.msg_status_receiver = g_unread_status;
        END IF;
        RETURN l_result;
    END get_inbox_count;
    /********************************************************************************************
    * Set message as read
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param i_flg_from                             O - outbox, I - Inbox
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
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_flg_from = g_flg_inbox
        THEN
            UPDATE pending_issue_sender pis
               SET pis.flg_status_receiver = g_read_status, pis.flg_last_status_r = pis.flg_status_receiver
             WHERE pis.id_pending_issue_message = i_id_message;
        ELSE
            UPDATE pending_issue_sender pis
               SET pis.flg_status_sender = g_read_status, pis.flg_last_status_s = pis.flg_status_sender
             WHERE pis.id_pending_issue_message = i_id_message;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'SET_STATUS_READ',
                                              o_error);
            RETURN FALSE;
    END set_status_read;
    /********************************************************************************************
    * Set message as replied
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param i_flg_from                             O - outbox, I - Inbox
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
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_flg_from = g_flg_inbox
        THEN
            UPDATE pending_issue_sender pis
               SET pis.flg_status_receiver = g_reply_status, pis.flg_last_status_r = pis.flg_status_receiver
             WHERE pis.id_pending_issue_message = i_id_message;
        ELSE
            UPDATE pending_issue_sender pis
               SET pis.flg_status_sender = g_reply_status, pis.flg_last_status_s = pis.flg_status_sender
             WHERE pis.id_pending_issue_message = i_id_message;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'SET_STATUS_REPLY',
                                              o_error);
            RETURN FALSE;
    END set_status_reply;
    /********************************************************************************************
    * Set message as cancelled
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param i_flg_from                             O - outbox, I - Inbox
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
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_flg_from = g_flg_inbox
        THEN
            UPDATE pending_issue_sender pis
               SET pis.flg_status_receiver = g_cancel_status, pis.flg_last_status_r = pis.flg_status_receiver
             WHERE pis.id_pending_issue_message = i_id_message;
        ELSE
            UPDATE pending_issue_sender pis
               SET pis.flg_status_sender = g_cancel_status, pis.flg_last_status_s = pis.flg_status_sender
             WHERE pis.id_pending_issue_message = i_id_message;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'SET_STATUS_CANCEL',
                                              o_error);
            RETURN FALSE;
    END set_status_cancel;
    /********************************************************************************************
    * Set message as unread
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param i_flg_from                             O - outbox, I - Inbox
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
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_flg_from = g_flg_inbox
        THEN
            UPDATE pending_issue_sender pis
               SET pis.flg_status_receiver = g_unread_status, pis.flg_last_status_r = pis.flg_status_receiver
             WHERE pis.id_pending_issue_message = i_id_message;
        ELSE
            UPDATE pending_issue_sender pis
               SET pis.flg_status_sender = g_unread_status, pis.flg_last_status_s = pis.flg_status_sender
             WHERE pis.id_pending_issue_message = i_id_message;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'SET_STATUS_UNREAD',
                                              o_error);
            RETURN FALSE;
    END set_status_unread;
    /********************************************************************************************
    * Set message as sent
    *
    * @param i_lang                                         Prefered language ID
    * @param i_id_message                                  Message identifier
    * @param i_flg_from                             O - outbox, I - Inbox
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
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_flg_from = g_flg_inbox
        THEN
            UPDATE pending_issue_sender pis
               SET pis.flg_status_receiver = g_sent_status, pis.flg_last_status_r = pis.flg_status_receiver
             WHERE pis.id_pending_issue_message = i_id_message;
        ELSE
            UPDATE pending_issue_sender pis
               SET pis.flg_status_sender = g_sent_status, pis.flg_last_status_s = pis.flg_status_sender
             WHERE pis.id_pending_issue_message = i_id_message;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'SET_STATUS_SENT',
                                              o_error);
            RETURN FALSE;
    END set_status_sent;
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
    ) RETURN t_tbl_msg IS
        l_tbl_msg t_tbl_msg;
    BEGIN
        SELECT t_rec_msg(thread_msg.thread_id,
                         thread_msg.msg_id,
                         thread_msg.subject,
                         thread_msg.body,
                         thread_msg.id_sender,
                         thread_msg.name_sender,
                         thread_msg.id_receiver,
                         thread_msg.name_to,
                         thread_msg.thread_status,
                         thread_msg.msg_status_sender,
                         thread_msg.msg_status_receiver,
                         thread_msg.thread_level,
                         thread_msg.dt_creation,
                         thread_msg.flg_sender,
                         thread_msg.representative_tag)
          BULK COLLECT
          INTO l_tbl_msg
          FROM (SELECT sms.thread_id,
                       sms.msg_id,
                       sms.subject,
                       sms.body,
                       sms.id_sender,
                       decode(sms.flg_sender,
                              g_patient_sender,
                              pk_patient.get_pat_name(i_lang, profissional(sms.id_receiver, 0, 0), sms.id_sender, -1),
                              pk_prof_utils.get_name(i_lang, sms.id_sender)) name_sender,
                       sms.id_receiver,
                       decode(sms.flg_sender,
                              g_patient_sender,
                              pk_prof_utils.get_name(i_lang, sms.id_receiver),
                              pk_patient.get_pat_name(i_lang, profissional(sms.id_sender, 0, 0), sms.id_receiver, -1)) name_to,
                       sms.thread_status,
                       sms.msg_status_sender,
                       sms.msg_status_receiver,
                       sms.thread_level,
                       sms.dt_creation,
                       sms.flg_sender,
                       sms.representative_tag
                  FROM v_all_messages sms
                 WHERE sms.thread_id = i_id_thread
                   AND (sms.thread_level < = i_thread_level OR i_thread_level IS NULL)) thread_msg
         ORDER BY thread_msg.thread_level DESC;
        RETURN l_tbl_msg;
    END get_message_thread;

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
    ) RETURN BOOLEAN IS
        l_rep_str VARCHAR2(200); /*pk_message.get_message*/
    BEGIN
        IF i_rep_str IS NOT NULL
        THEN
            l_rep_str := '(' || i_rep_str || ' On Behalf of)';
        END IF;
        INSERT INTO pending_issue_sender
            (id_pending_issue_message,
             id_pending_issue,
             flg_sender,
             representative_tag,
             flg_status_sender,
             flg_status_receiver)
        VALUES
            (i_id_msg, i_id_thread, i_from, l_rep_str, i_sender_state, i_receiver_state);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'SET_PI_SENDER',
                                              o_error);
            RETURN FALSE;
    END set_pi_sender;

    /* Get Patient age attribute */
    FUNCTION get_pat_age
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_pat_age NUMBER(24) := NULL;
    BEGIN
    
        SELECT pk_patient.get_pat_age(i_lang, p.dt_birth, p.age, 0, 0)
          INTO l_pat_age
          FROM patient p
         WHERE p.id_patient = i_id_pat;
        RETURN l_pat_age;
    END get_pat_age;
    /* Get Patient gender attribute */
    FUNCTION get_pat_gender
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_pat_gender VARCHAR2(10 CHAR) := NULL;
    BEGIN
        SELECT pk_patient.get_gender(i_lang, p.gender)
          INTO l_pat_gender
          FROM patient p
         WHERE p.id_patient = i_id_pat;
        RETURN l_pat_gender;
    END get_pat_gender;
    /* Get Patient photo path attribute */
    FUNCTION get_pat_photo
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        i_id_prof IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        l_pat_photo VARCHAR2(200 CHAR) := NULL;
    BEGIN
        SELECT pk_patphoto.get_pat_photo(i_lang, profissional(i_id_prof, 0, 0), p.id_patient, -1, NULL)
          INTO l_pat_photo
          FROM patient p
         WHERE p.id_patient = i_id_pat;
        RETURN l_pat_photo;
    END get_pat_photo;

    /* Search terms in mesage and representative fields */
    FUNCTION get_msg_by_desc
    (
        i_lang   IN language.id_language%TYPE,
        i_search IN VARCHAR2
    ) RETURN table_number IS
        l_search_val translation.desc_lang_1%TYPE := '%' || translate(upper(i_search),
                                                                      'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ',
                                                                      'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%';
        l_msg_ids    table_number := table_number();
    BEGIN
        SELECT pim.id_pending_issue_message
          BULK COLLECT
          INTO l_msg_ids
          FROM pending_issue_message pim
         INNER JOIN pending_issue_sender pis
            ON (pim.id_pending_issue = pis.id_pending_issue AND
               pim.id_pending_issue_message = pis.id_pending_issue_message)
         WHERE (translate(upper(pim.title), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE l_search_val OR
               translate(upper(pis.representative_tag), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
               l_search_val);
        RETURN l_msg_ids;
    END get_msg_by_desc;
    /* Search terms in patient name */
    FUNCTION get_msg_by_pat
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_search IN VARCHAR2
    ) RETURN table_number IS
        l_msg_ids table_number := table_number();
    BEGIN
        SELECT pim.id_pending_issue_message
          BULK COLLECT
          INTO l_msg_ids
          FROM pending_issue_message pim
          JOIN pending_issue pi
            ON (pi.id_pending_issue = pim.id_pending_issue)
          JOIN TABLE(pk_adt.get_patients(i_lang, i_prof, i_search)) pat_tbl
            ON (pat_tbl.id_patient = pi.id_patient);
        RETURN l_msg_ids;
    END get_msg_by_pat;
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
    ) RETURN table_number IS
        l_msg_search table_number := table_number();
        l_pat_search table_number := table_number();
        l_ret_search table_number := table_number();
    BEGIN
        dbms_output.put_line('--> Start search!');
        l_msg_search := get_msg_by_desc(i_lang, i_search_term);
        dbms_output.put_line('FOUND messages --> ' || l_msg_search.count);
        l_pat_search := get_msg_by_pat(i_lang, i_prof, i_search_term);
        dbms_output.put_line('FOUND patient messages --> ' || l_pat_search.count);
        l_ret_search := l_msg_search MULTISET UNION l_pat_search;
        dbms_output.put_line('FOUND total messages --> ' || l_ret_search.count);
        RETURN l_ret_search;
    END search_messages;
    /* Get Last Message inserted */
    FUNCTION get_latest_message
    (
        i_id_thread pending_issue_message.id_pending_issue%TYPE,
        i_id_parent pending_issue_message.id_pending_issue_message%TYPE
    ) RETURN NUMBER IS
        l_latest_msg pending_issue_message.id_pending_issue_message%TYPE := NULL;
    BEGIN
        SELECT nvl((SELECT my_ordered.id_pending_issue_message
                     FROM (SELECT pim.id_pending_issue_message
                             FROM pending_issue_message pim
                             LEFT JOIN pending_issue_sender pis
                               ON (pis.id_pending_issue = pim.id_pending_issue AND
                                  pis.id_pending_issue_message = pim.id_pending_issue_message)
                            WHERE pim.id_pending_issue = i_id_thread
                              AND (pim.id_pending_issue_msg_parent = i_id_parent OR i_id_parent IS NULL)
                            ORDER BY pim.dt_creation DESC) my_ordered
                    WHERE rownum = 1),
                   0)
          INTO l_latest_msg
          FROM dual;
        RETURN l_latest_msg;
    END get_latest_message;

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
    ) RETURN BOOLEAN IS
        l_new_msg_id   pending_issue_message.id_pending_issue_message%TYPE;
        l_msg_sender   pending_issue_sender.flg_sender%TYPE := NULL;
        l_msg_location VARCHAR2(1 CHAR) := NULL;
    
        l_error t_error_out;
        l_fatal_exception EXCEPTION;
    BEGIN
    
        IF i_id_msg_rep IS NULL
        THEN
            g_error := 'NEW THREAD BEING BUILT ';
            IF NOT pk_pending_issues.set_issue(i_lang    => i_lang,
                                               i_prof    => i_id_prof,
                                               i_issue   => i_id_thread,
                                               i_title   => i_msg_subject,
                                               i_patient => i_id_patient,
                                               i_episode => -1,
                                               i_assigns => table_number(),
                                               i_status  => 'G',
                                               i_subject => i_msg_subject,
                                               i_message => NULL,
                                               o_error   => l_error)
            THEN
                RAISE l_fatal_exception;
            ELSE
            
                g_error      := 'GET NEW MESSAGE IDENTIFIER FOR THREAD ' || i_id_thread;
                l_new_msg_id := pk_backoffice_pending_issues.get_latest_message(i_id_thread, NULL);
            
                g_error := 'SET NEW MESSAGE body ' || i_id_thread || '/ ' || l_new_msg_id;
                set_message_body(i_lang, l_new_msg_id, i_id_thread, i_msg_body);
            
                g_error := 'SET MESSAGE ORIGIN AND ORIGINAL STATUS ' || l_new_msg_id;
                IF NOT pk_backoffice_pending_issues.set_pi_sender(i_lang,
                                                                  i_id_thread,
                                                                  l_new_msg_id,
                                                                  i_flg_from,
                                                                  'S',
                                                                  'U',
                                                                  i_rep_str,
                                                                  o_error)
                THEN
                    RAISE l_fatal_exception;
                END IF;
            END IF;
        ELSE
            g_error := 'NEW MESSAGE REPLY TO ' || i_id_msg_rep;
            IF NOT pk_pending_issues.set_message(i_lang       => i_lang,
                                                 i_prof       => i_id_prof,
                                                 i_issue      => i_id_thread,
                                                 i_flg_reply  => 'Y',
                                                 i_parent_msg => i_id_msg_rep,
                                                 i_subject    => i_msg_subject,
                                                 i_message    => NULL,
                                                 o_error      => l_error)
            THEN
                RAISE l_fatal_exception;
            ELSE
                g_error      := 'GET NEW MESSAGE IDENTIFIER ' || i_id_thread;
                l_new_msg_id := pk_backoffice_pending_issues.get_latest_message(i_id_thread, i_id_msg_rep);
            
                g_error := 'SET NEW MESSAGE body ' || i_id_thread || '/ ' || l_new_msg_id;
                set_message_body(i_lang, l_new_msg_id, i_id_thread, i_msg_body);
            
                g_error := 'SET MESSAGE ORIGIN AND STATUS ' || l_new_msg_id;
                IF NOT pk_backoffice_pending_issues.set_pi_sender(i_lang,
                                                                  i_id_thread,
                                                                  l_new_msg_id,
                                                                  i_flg_from,
                                                                  'R',
                                                                  'U',
                                                                  i_rep_str,
                                                                  o_error)
                THEN
                    RAISE l_fatal_exception;
                ELSE
                    IF NOT pk_backoffice_pending_issues.get_message_sender(i_id_msg_rep, l_msg_sender)
                    THEN
                        RAISE l_fatal_exception;
                    ELSE
                        SELECT decode(l_msg_sender, i_flg_from, g_flg_outbox, g_flg_inbox)
                          INTO l_msg_location
                          FROM dual;
                    
                        g_error := 'SET REPLIED MESSAGE TO REPLIED ' || i_id_msg_rep;
                        IF NOT set_status_reply(i_lang, i_id_msg_rep, l_msg_location, o_error)
                        THEN
                            RAISE l_fatal_exception;
                        END IF;
                    END IF;
                END IF;
            END IF;
        
        END IF;
        o_new_msg_id := l_new_msg_id;
        IF i_commit = 'Y'
        THEN
            COMMIT;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_fatal_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'SET_MESSAGE',
                                              o_error);
            IF i_commit = 'Y'
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'SET_MESSAGE',
                                              o_error);
            IF i_commit = 'Y'
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
        
    END set_message;
    /* Get Message sender flag */
    FUNCTION get_message_sender
    (
        i_id_msg     IN pending_issue_message.id_pending_issue_message%TYPE,
        o_flg_sender OUT pending_issue_sender.flg_sender%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
    
        SELECT pis.flg_sender
          INTO o_flg_sender
          FROM pending_issue_sender pis
         WHERE pis.id_pending_issue_message = i_id_msg;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_flg_sender := NULL;
            RETURN FALSE;
    END get_message_sender;
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
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_flg_from = g_flg_inbox
        THEN
            UPDATE pending_issue_sender pis
               SET pis.flg_status_receiver = nvl(pis.flg_last_status_r, pis.flg_status_receiver),
                   pis.flg_last_status_r   = pis.flg_status_receiver
             WHERE pis.id_pending_issue_message = i_id_message;
        ELSE
            UPDATE pending_issue_sender pis
               SET pis.flg_status_sender = nvl(pis.flg_last_status_s, pis.flg_status_sender),
                   pis.flg_last_status_s = pis.flg_status_sender
             WHERE pis.id_pending_issue_message = i_id_message;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PENDING_ISSUES',
                                              'SET_MSG_PREV_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_msg_prev_status;

BEGIN
    g_patient_sender      := 'P';
    g_professional_sender := 'F';
    g_unread_status       := 'U';
    g_read_status         := 'C';
    g_reply_status        := 'R';
    g_cancel_status       := 'X';
    g_sent_status         := 'S';
    g_flg_outbox          := 'O';
    g_flg_inbox           := 'I';
END pk_backoffice_pending_issues;
/
