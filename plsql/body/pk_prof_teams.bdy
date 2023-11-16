/*-- Last Change Revision: $Rev: 2027534 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_prof_teams IS

    g_package_name VARCHAR2(32);
    --    
    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_error.err_desc := g_package_name || '.' || i_func_proc_name || ' / ' || i_error;
    
        pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                        text_in       => i_error,
                                        name1_in      => 'OWNER',
                                        value1_in     => 'ALERT',
                                        name2_in      => 'PACKAGE',
                                        value2_in     => g_package_name,
                                        name3_in      => 'FUNCTION',
                                        value3_in     => i_func_proc_name);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling;

    FUNCTION error_handling_ext
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlcode        IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        i_flg_action     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
    BEGIN
    
        l_error_in.set_all(i_lang,
                           i_sqlcode,
                           i_sqlerror,
                           i_error,
                           'ALERT',
                           g_package_name,
                           i_func_proc_name,
                           NULL,
                           i_flg_action);
        l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling_ext;

    /********************************************************************************************
    * Gets the institution and software associated with a department
    *
    * @param i_lang           language id
    * @param i_prof           professional, software and institution ids
    * @param i_department     department id
    *
    * @param o_institution     institution id
    * @param o_software        software id
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   21-05-2009
    **********************************************************************************************/
    FUNCTION get_soft_by_department
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_department  IN VARCHAR2,
        o_institution OUT institution.id_institution%TYPE,
        o_software    OUT software.id_software%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_soft IS
            SELECT id_institution, id_soft
              FROM (SELECT d.id_institution,
                           pk_episode.get_soft_by_epis_type(pk_sysconfig.get_config('EPIS_TYPE',
                                                                                    profissional(i_prof.id,
                                                                                                 i_prof.institution,
                                                                                                 sd.id_software)),
                                                            d.id_institution) id_soft
                      FROM department d
                      JOIN dept dep
                        ON d.id_dept = dep.id_dept
                      JOIN software_dept sd
                        ON sd.id_dept = dep.id_dept
                     WHERE d.id_department = i_department
                       AND sd.id_software <> pk_alert_constant.g_soft_referral)
             WHERE id_soft IS NOT NULL
             ORDER BY id_soft;
    
    BEGIN
    
        g_error := 'OPEN CURSOR';
        OPEN c_soft;
        FETCH c_soft
            INTO o_institution, o_software;
        CLOSE c_soft;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_SOFT_BY_DEPARTMENT', g_error, SQLERRM, FALSE, o_error);
    END get_soft_by_department;

    /********************************************************************************************
    * Checks if a team can be created
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_type           integrity type: P - professional, T - team
    * @param  i_prof_team      team id (in case of an update)
    * @param  i_department     team department
    * @param  i_prof_team_name team name
    * @param  i_professional   professional to be associated to the team
    * @param  i_dt_begin       date of team/professional shift beginning,
    * @param  i_dt_end         date of team/professional shift ending,
    *
    * @param i_dt_end         effective date of team/professional shift ending,
    * @param o_num_msg         Message ID to show the user in case of not being possible to create the team
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   25-02-2009
    **********************************************************************************************/
    FUNCTION check_team_integrity
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_type           IN VARCHAR2,
        i_prof_team      IN prof_team.id_prof_team%TYPE,
        i_department     IN department.id_department%TYPE,
        i_prof_team_name IN prof_team.prof_team_name%TYPE,
        i_professional   IN prof_team_det.id_professional%TYPE,
        i_dt_begin       IN prof_team.dt_begin_tstz%TYPE,
        i_dt_end         IN prof_team.dt_end_tstz%TYPE,
        o_dt_end         OUT prof_team.dt_end_tstz%TYPE,
        o_num_msg        OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_prof_team     prof_team.id_prof_team%TYPE;
        l_id_prof_team_det prof_team_det.id_prof_team_det%TYPE;
    
    BEGIN
    
        IF i_dt_begin >= i_dt_end
        THEN
            o_dt_end := i_dt_end + numtodsinterval(1, 'DAY');
        ELSE
            o_dt_end := i_dt_end;
        END IF;
    
        IF i_type = g_integrity_type_t
        THEN
            g_error := 'CHECK PROF_TEAM';
            BEGIN
                SELECT pt.id_prof_team
                  INTO l_id_prof_team
                  FROM prof_team pt
                 WHERE pt.id_department = i_department
                   AND pt.prof_team_name = i_prof_team_name
                   AND pt.flg_status = pk_alert_constant.g_team_active
                   AND pt.id_prof_team <> nvl(i_prof_team, 0)
                   AND i_dt_begin < pt.dt_end_tstz
                   AND i_dt_end > pt.dt_begin_tstz;
            EXCEPTION
                WHEN too_many_rows THEN
                    o_num_msg := 2;
                WHEN no_data_found THEN
                    o_num_msg := NULL;
            END;
        
            g_error := 'CHECK PROF_TEAM 2';
            IF l_id_prof_team IS NOT NULL
            THEN
                o_num_msg := 2;
            END IF;
        
        ELSIF i_type = g_integrity_type_p
        THEN
            g_error := 'CHECK PROF_TEAM';
            BEGIN
                SELECT pd.id_prof_team_det
                  INTO l_id_prof_team_det
                  FROM prof_team_det pd
                 WHERE pd.id_professional = i_professional
                   AND pd.flg_status = pk_alert_constant.g_team_det_active
                   AND i_dt_begin < pd.dt_end
                   AND i_dt_end > pd.dt_begin;
            EXCEPTION
                WHEN too_many_rows THEN
                    o_num_msg := 3;
                WHEN no_data_found THEN
                    o_num_msg := NULL;
            END;
        
            g_error := 'CHECK PROF_TEAM 2';
            IF l_id_prof_team_det IS NOT NULL
            THEN
                o_num_msg := 3;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'CHECK_TEAM_INTEGRITY', g_error, SQLERRM, FALSE, o_error);
    END check_team_integrity;

    /********************************************************************************************
    * Returns the domain associated with a team status
    *
    * @param  i_lang           language id
    * @param  i_val            status value
    *                    
    * @return                  domain description
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_prof_team_domain
    (
        i_lang IN language.id_language%TYPE,
        i_val  IN prof_team.flg_status%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF i_val = pk_alert_constant.g_team_cancel
        THEN
            RETURN pk_sysdomain.get_domain('PROF_TEAM.FLG_STATUS', i_val, i_lang);
        ELSE
            RETURN '';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_prof_team_domain;

    /********************************************************************************************
    * Returns the '(With notes)' label
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_notes          team notes
    * @param  i_notes_cancel   team cancellation notes
    *                    
    * @return                  domain description
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_notes_label
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_notes        IN prof_team.notes%TYPE,
        i_notes_cancel IN prof_team.notes_cancel%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF i_notes IS NOT NULL
           OR i_notes_cancel IS NOT NULL
        THEN
            RETURN pk_message.get_message(i_lang, i_prof, 'COMMON_M008');
        ELSE
            RETURN '';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_notes_label;

    /********************************************************************************************
    * Gets the list of active teams for a specific professional
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param o_teams           list of teams
    *                    
    * @return                  current team responsible for the episode
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   06-03-2009
    **********************************************************************************************/
    FUNCTION get_prof_active_teams
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_teams OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_teams IS
            SELECT pt.id_prof_team
              FROM prof_team_ea pt
             WHERE pt.flg_status = pk_alert_constant.g_team_active
               AND EXISTS (SELECT 0
                      FROM prof_team_det_ea pd
                     WHERE pd.id_professional = i_prof.id
                       AND pd.id_prof_team = pt.id_prof_team
                       AND ((current_timestamp BETWEEN pd.dt_begin AND pd.dt_end AND
                           pt.id_team_type IS NULL) OR (pt.id_team_type IS NOT NULL)));
    
    BEGIN
    
        OPEN c_teams;
        FETCH c_teams BULK COLLECT
            INTO o_teams;
        CLOSE c_teams;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_PROF_ACTIVE_TEAMS', g_error, SQLERRM, FALSE, o_error);
    END get_prof_active_teams;

    /********************************************************************************************
    * Inserts a new professional into the team
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_prof_team      team id
    * @param  i_professional   professional id
    * @param  i_prof_dt_begin  date of professional shift start,
    * @param  i_prof_dt_end    date of professional shift end,
    * @param  i_prof_notes     professional notes,
    * @param  i_team_type      id team_type,
    *
    * @param o_num_msg         Message ID to show the user in case of not being possible to create the team
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   25-02-2009
    **********************************************************************************************/
    FUNCTION set_professional_team
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_team     IN prof_team.id_prof_team%TYPE,
        i_professional  IN professional.id_professional%TYPE,
        i_prof_dt_begin IN VARCHAR2,
        i_prof_dt_end   IN VARCHAR2,
        i_prof_notes    IN prof_team_det.notes%TYPE,
        i_team_type     IN team_type.id_team_type%TYPE DEFAULT NULL,
        o_num_msg       OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
        l_dt_begin     prof_team.dt_begin_tstz%TYPE;
        l_dt_end       prof_team.dt_end_tstz%TYPE;
        l_bool         BOOLEAN := TRUE;
        l_num_msg      NUMBER;
        l_effec_dt_end prof_team.dt_end_tstz%TYPE;
        l_rowids       table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate      := SYSDATE;
    
        g_error    := 'CHECK PROF DATE';
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_prof_dt_begin, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_prof_dt_end, NULL);
    
        IF i_team_type IS NULL
        THEN
            IF NOT check_team_integrity(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_type           => g_integrity_type_p,
                                        i_prof_team      => NULL,
                                        i_department     => NULL,
                                        i_prof_team_name => NULL,
                                        i_professional   => i_professional,
                                        i_dt_begin       => l_dt_begin,
                                        i_dt_end         => l_dt_end,
                                        o_dt_end         => l_effec_dt_end,
                                        o_num_msg        => l_num_msg,
                                        o_error          => l_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            l_effec_dt_end := l_dt_end;
        END IF;
    
        IF l_num_msg = 1
        THEN
            l_bool := FALSE;
        ELSIF l_num_msg = 3
        THEN
            l_bool := FALSE;
        END IF;
    
        IF l_bool = TRUE
        THEN
            g_error := 'SET PROF_TEAM_DET';
            ts_prof_team_det.ins(id_prof_team_in    => i_prof_team,
                                 id_professional_in => i_professional,
                                 flg_available_in   => g_available,
                                 flg_status_in      => pk_alert_constant.g_team_det_active,
                                 adw_last_update_in => g_sysdate,
                                 notes_in           => i_prof_notes,
                                 dt_begin_in        => l_dt_begin,
                                 dt_end_in          => l_effec_dt_end,
                                 rows_out           => l_rowids);
        END IF;
    
        o_num_msg := l_num_msg;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling(i_lang,
                                  'SET_PROFESSIONAL_TEAM',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  TRUE,
                                  o_error);
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_PROFESSIONAL_TEAM', g_error, SQLERRM, TRUE, o_error);
    END set_professional_team;

    /********************************************************************************************
    * Creates a team history record
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_prof_team      team id
    *
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION set_prof_team_hist
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_prof_team_hist prof_team_hist.id_prof_team_hist%TYPE;
        l_flg_type_register prof_team_hist.flg_type_register%TYPE;
        l_count             NUMBER;
        l_prof_team_det     table_number;
    
        l_t_prof_team ts_prof_team.prof_team_tc;
        l_rowids      table_varchar := table_varchar();
    
        CURSOR c_profs IS
            SELECT *
              FROM prof_team_det pd
              JOIN TABLE(l_prof_team_det) a
                ON a.column_value = pd.id_professional
             WHERE pd.id_prof_team = i_prof_team;
    
    BEGIN
    
        g_error := 'COUNT HIST RECORDS';
        SELECT COUNT(*)
          INTO l_count
          FROM prof_team_hist p
         WHERE p.id_prof_team = i_prof_team;
    
        g_error := 'GET PROFESSIONAL LIST';
        SELECT id_professional
          BULK COLLECT
          INTO l_prof_team_det
          FROM prof_team_det p
         WHERE p.id_prof_team = i_prof_team;
    
        IF l_count = 0
        THEN
            l_flg_type_register := pk_alert_constant.g_flg_type_reg_c;
        ELSE
            l_flg_type_register := pk_alert_constant.g_flg_type_reg_e;
        END IF;
    
        l_id_prof_team_hist := seq_prof_team_hist.nextval;
    
        g_error := 'GET PROF TEAM';
        SELECT prof_team_name,
               flg_available,
               flg_status,
               dt_begin_tstz,
               dt_end_tstz,
               id_department,
               notes,
               id_prof_register,
               dt_register,
               id_team_type,
               id_prof_team_leader,
               id_episode
          INTO l_t_prof_team(1).prof_team_name,
               l_t_prof_team(1).flg_available,
               l_t_prof_team(1).flg_status,
               l_t_prof_team(1).dt_begin_tstz,
               l_t_prof_team(1).dt_end_tstz,
               l_t_prof_team(1).id_department,
               l_t_prof_team(1).notes,
               l_t_prof_team(1).id_prof_register,
               l_t_prof_team(1).dt_register,
               l_t_prof_team(1).id_team_type,
               l_t_prof_team(1).id_prof_team_leader,
               l_t_prof_team(1).id_episode
          FROM prof_team p
         WHERE p.id_prof_team = i_prof_team;
    
        g_error := 'SET PROF TEAM HIST';
        ts_prof_team_hist.ins(id_prof_team_hist_in   => l_id_prof_team_hist,
                              id_prof_team_in        => i_prof_team,
                              prof_team_name_in      => l_t_prof_team(1).prof_team_name,
                              flg_available_in       => l_t_prof_team(1).flg_available,
                              flg_status_in          => l_t_prof_team(1).flg_status,
                              dt_begin_tstz_in       => l_t_prof_team(1).dt_begin_tstz,
                              dt_end_tstz_in         => l_t_prof_team(1).dt_end_tstz,
                              id_department_in       => l_t_prof_team(1).id_department,
                              notes_in               => l_t_prof_team(1).notes,
                              id_prof_register_in    => l_t_prof_team(1).id_prof_register,
                              dt_register_in         => l_t_prof_team(1).dt_register,
                              flg_type_register_in   => l_flg_type_register,
                              id_team_type_in        => l_t_prof_team(1).id_team_type,
                              id_prof_team_leader_in => l_t_prof_team(1).id_prof_team_leader,
                              id_episode_in          => l_t_prof_team(1).id_episode,
                              rows_out               => l_rowids);
    
        l_rowids := table_varchar();
    
        FOR r_profs IN c_profs
        LOOP
            g_error := 'SET PROFESSIONAL TEAM ' || r_profs.id_professional;
            ts_prof_team_det_hist.ins(id_prof_team_hist_in => l_id_prof_team_hist,
                                      id_prof_team_in      => i_prof_team,
                                      id_professional_in   => r_profs.id_professional,
                                      flg_available_in     => r_profs.flg_available,
                                      flg_status_in        => r_profs.flg_status,
                                      notes_in             => r_profs.notes,
                                      dt_begin_in          => r_profs.dt_begin,
                                      dt_end_in            => r_profs.dt_end,
                                      flg_leader_in        => r_profs.flg_leader,
                                      rows_out             => l_rowids);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_PROF_TEAM_HIST', g_error, SQLERRM, TRUE, o_error);
    END set_prof_team_hist;

    /********************************************************************************************
    * Creates a team history record
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_prof_team      team id
    *
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION set_prof_team_ea
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_team_det table_number;
        l_prof_team     table_number;
    
        l_t_prof_team_ea ts_prof_team_ea.prof_team_ea_tc;
        l_rowids         table_varchar;
    
        CURSOR c_profs IS
            SELECT *
              FROM prof_team_det pd
              JOIN TABLE(l_prof_team_det) a
                ON a.column_value = pd.id_professional
             WHERE pd.id_prof_team = i_prof_team;
    
    BEGIN
    
        g_error := 'GET PROFESSIONAL LIST';
        SELECT id_professional
          BULK COLLECT
          INTO l_prof_team_det
          FROM prof_team_det p
         WHERE p.id_prof_team = i_prof_team;
    
        g_error := 'DELETE FROM PROF_TEAM_DET_EA';
        ts_prof_team_det_ea.del_by(where_clause_in => 'id_prof_team = ' || i_prof_team);
    
        g_error := 'DELETE FROM PROF_TEAM_EA';
        ts_prof_team_ea.del_by(where_clause_in => 'id_prof_team = ' || i_prof_team);
    
        g_error := 'GET PROF TEAM HIST';
        SELECT id_prof_team,
               prof_team_name,
               flg_available,
               flg_status,
               dt_begin_tstz,
               dt_end_tstz,
               id_department,
               notes,
               id_prof_register,
               dt_register,
               num_members,
               id_software,
               id_institution,
               id_team_type,
               id_prof_team_leader
          INTO l_t_prof_team_ea(1).id_prof_team,
               l_t_prof_team_ea(1).prof_team_name,
               l_t_prof_team_ea(1).flg_available,
               l_t_prof_team_ea(1).flg_status,
               l_t_prof_team_ea(1).dt_begin_tstz,
               l_t_prof_team_ea(1).dt_end_tstz,
               l_t_prof_team_ea(1).id_department,
               l_t_prof_team_ea(1).notes,
               l_t_prof_team_ea(1).id_prof_register,
               l_t_prof_team_ea(1).dt_register,
               l_t_prof_team_ea(1).num_members,
               l_t_prof_team_ea(1).id_software,
               l_t_prof_team_ea(1).id_institution,
               l_t_prof_team_ea(1).id_team_type,
               l_t_prof_team_ea(1).id_prof_team_leader
          FROM prof_team p
         WHERE p.id_prof_team = i_prof_team;
    
        g_error := 'SET PROF TEAM HIST';
        ts_prof_team_ea.ins(rows_in => l_t_prof_team_ea, rows_out => l_rowids);
    
        l_rowids := table_varchar();
    
        FOR r_profs IN c_profs
        LOOP
            g_error := 'SET PROFESSIONAL TEAM ' || r_profs.id_professional;
            ts_prof_team_det_ea.ins(id_prof_team_in    => r_profs.id_prof_team,
                                    id_professional_in => r_profs.id_professional,
                                    flg_available_in   => r_profs.flg_available,
                                    flg_status_in      => r_profs.flg_status,
                                    notes_in           => r_profs.notes,
                                    dt_begin_in        => r_profs.dt_begin,
                                    dt_end_in          => r_profs.dt_end,
                                    flg_leader_in      => r_profs.flg_leader,
                                    rows_out           => l_rowids);
        END LOOP;
    
        g_error := 'GET OLD RECORDS';
        BEGIN
            SELECT p.id_prof_team
              BULK COLLECT
              INTO l_prof_team
              FROM prof_team_ea p
             WHERE p.dt_end_tstz < current_timestamp;
        EXCEPTION
            WHEN no_data_found THEN
                l_prof_team := table_number();
        END;
    
        g_error := 'DELETE OLD RECORDS';
        DELETE FROM prof_team_det_ea p
         WHERE p.id_prof_team IN (SELECT column_value
                                    FROM TABLE(l_prof_team));
    
        g_error := 'DELETE OLD RECORDS';
        DELETE FROM prof_team_ea p
         WHERE p.id_prof_team IN (SELECT column_value
                                    FROM TABLE(l_prof_team));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_PROF_TEAM_EA', g_error, SQLERRM, TRUE, o_error);
    END set_prof_team_ea;

    /********************************************************************************************
    * Creates a team of professionals
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_department     team department
    * @param  i_prof_team_name team name
    * @param  i_team_dt_begin  date of team shift beginning,
    * @param  i_team_dt_end    date of team shift ending,
    * @param  i_notes          team notes,
    * @param  i_professional   list of allocated professionals,
    * @param  i_prof_dt_begin  date of professional shift beginning,
    * @param  i_prof_dt_end    date of professional shift ending,
    * @param  i_prof_notes     professional notes,
    *
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION create_prof_team
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_department       IN department.id_department%TYPE,
        i_prof_team_name   IN prof_team.prof_team_name%TYPE,
        i_team_dt_begin    IN VARCHAR2,
        i_team_dt_end      IN VARCHAR2,
        i_notes            IN prof_team.notes%TYPE,
        i_professional     IN table_number,
        i_prof_dt_begin    IN table_varchar,
        i_prof_dt_end      IN table_varchar,
        i_prof_notes       IN table_varchar,
        i_team_type        IN team_type.id_team_type%TYPE DEFAULT NULL,
        i_prof_team_leader IN prof_team.id_prof_team_leader%TYPE DEFAULT NULL,
        o_id_prof_team     OUT prof_team.id_prof_team%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT create_prof_team_internal(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_department       => i_department,
                                         i_prof_team_name   => i_prof_team_name,
                                         i_team_dt_begin    => i_team_dt_begin,
                                         i_team_dt_end      => i_team_dt_end,
                                         i_notes            => i_notes,
                                         i_professional     => i_professional,
                                         i_prof_dt_begin    => i_prof_dt_begin,
                                         i_prof_dt_end      => i_prof_dt_end,
                                         i_prof_notes       => i_prof_notes,
                                         i_team_type        => i_team_type,
                                         i_prof_team_leader => i_prof_team_leader,
                                         i_id_episode       => NULL,
                                         o_id_prof_team     => o_id_prof_team,
                                         o_error            => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'CREATE_PROF_TEAM', g_error, SQLCODE, SQLERRM, TRUE, 'S', o_error);
    END create_prof_team;

    FUNCTION get_id_episode_prof_team(i_prof_team IN prof_team.id_prof_team%TYPE) RETURN prof_team.id_episode%TYPE IS
        l_id_episode prof_team.id_episode%TYPE;
    BEGIN
        SELECT id_episode
          INTO l_id_episode
          FROM prof_team
         WHERE id_prof_team = i_prof_team;
        RETURN l_id_episode;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_id_episode_prof_team;

    /********************************************************************************************
    * Creates a team of professionals
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_department     team department
    * @param  i_prof_team_name team name
    * @param  i_team_dt_begin  date of team shift beginning,
    * @param  i_team_dt_end    date of team shift ending,
    * @param  i_notes          team notes,
    * @param  i_professional   list of allocated professionals,
    * @param  i_prof_dt_begin  date of professional shift beginning,
    * @param  i_prof_dt_end    date of professional shift ending,
    * @param  i_prof_notes     professional notes,
    *
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   25-02-2009
    **********************************************************************************************/
    FUNCTION create_prof_team_internal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_department       IN department.id_department%TYPE,
        i_prof_team_name   IN prof_team.prof_team_name%TYPE,
        i_team_dt_begin    IN VARCHAR2,
        i_team_dt_end      IN VARCHAR2,
        i_notes            IN prof_team.notes%TYPE,
        i_professional     IN table_number,
        i_prof_dt_begin    IN table_varchar,
        i_prof_dt_end      IN table_varchar,
        i_prof_notes       IN table_varchar,
        i_team_type        IN team_type.id_team_type%TYPE DEFAULT NULL,
        i_prof_team_leader IN prof_team.id_prof_team_leader%TYPE DEFAULT NULL,
        i_id_episode       IN episode.id_episode%TYPE,
        o_id_prof_team     OUT prof_team.id_prof_team%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
        l_err_2 EXCEPTION;
        l_err_3 EXCEPTION;
        l_msg_err2 sys_message.desc_message%TYPE;
        l_msg_err3 sys_message.desc_message%TYPE;
    
        l_id_prof_team prof_team.id_prof_team%TYPE;
        l_dt_begin     prof_team.dt_begin_tstz%TYPE;
        l_dt_end       prof_team.dt_end_tstz%TYPE;
        l_num_msg      NUMBER;
        l_num_members  NUMBER;
        l_effec_dt_end prof_team.dt_end_tstz%TYPE;
    
        l_id_software    software.id_software%TYPE;
        l_id_institution institution.id_institution%TYPE;
        l_rowids         table_varchar;
        l_flg_type       prof_team.flg_type%TYPE;
        l_id_episode     episode.id_episode%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate      := SYSDATE;
    
        g_error    := 'GET ERROR MESSAGES';
        l_msg_err2 := pk_message.get_message(i_lang, 'PROF_TEAMS_M001');
        l_msg_err3 := pk_message.get_message(i_lang, 'PROF_TEAMS_M003');
    
        g_error := 'CONVERT DATES';
        IF i_team_dt_begin IS NULL
        THEN
            l_dt_begin := current_timestamp;
        ELSE
            l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_team_dt_begin, NULL);
        END IF;
    
        l_dt_end := pk_date_utils.get_string_tstz(i_lang, i_prof, i_team_dt_end, NULL);
    
        IF i_team_type IS NULL
        THEN
            g_error := 'CHECK TEAM DATE AND NAME';
            IF NOT check_team_integrity(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_type           => g_integrity_type_t,
                                        i_prof_team      => NULL,
                                        i_department     => i_department,
                                        i_prof_team_name => i_prof_team_name,
                                        i_professional   => NULL,
                                        i_dt_begin       => l_dt_begin,
                                        i_dt_end         => l_dt_end,
                                        o_dt_end         => l_effec_dt_end,
                                        o_num_msg        => l_num_msg,
                                        o_error          => l_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            l_effec_dt_end := l_dt_end;
        END IF;
    
        IF l_num_msg = 2
        THEN
            RAISE l_err_2;
        END IF;
    
        g_error := 'GET ID_SOFTWARE AND ID_INSTITUTION';
        IF NOT get_soft_by_department(i_lang        => i_lang,
                                      i_prof        => i_prof,
                                      i_department  => i_department,
                                      o_institution => l_id_institution,
                                      o_software    => l_id_software,
                                      o_error       => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            l_flg_type       := pk_hhc_constant.k_dept_flg_type_h;
            l_id_software    := pk_alert_constant.g_soft_home_care;
            l_id_institution := nvl(l_id_institution, i_prof.institution);
        END IF;
    
        g_error       := 'SET PROF TEAM';
        l_num_members := i_professional.count;
    
        SELECT seq_prof_team.nextval
          INTO l_id_prof_team
          FROM dual;
    
        ts_prof_team.ins(id_prof_team_in        => l_id_prof_team,
                         prof_team_name_in      => i_prof_team_name,
                         flg_available_in       => g_available,
                         flg_status_in          => pk_alert_constant.g_team_active,
                         dt_begin_tstz_in       => l_dt_begin,
                         dt_end_tstz_in         => l_effec_dt_end,
                         id_department_in       => i_department,
                         notes_in               => i_notes,
                         id_prof_register_in    => i_prof.id,
                         dt_register_in         => g_sysdate_tstz,
                         id_software_in         => l_id_software,
                         id_institution_in      => l_id_institution,
                         flg_type_in            => l_flg_type,
                         num_members_in         => l_num_members,
                         id_team_type_in        => i_team_type,
                         id_prof_team_leader_in => i_prof_team_leader,
                         id_episode_in          => i_id_episode,
                         rows_out               => l_rowids);
    
        g_error := 'LOOP PROFESSIONALS';
        FOR i IN 1 .. i_professional.count
        LOOP
            g_error := 'SET PROFESSIONAL TEAM';
            IF NOT set_professional_team(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_prof_team     => l_id_prof_team,
                                         i_professional  => i_professional(i),
                                         i_prof_dt_begin => i_prof_dt_begin(i),
                                         i_prof_dt_end   => i_prof_dt_end(i),
                                         i_prof_notes    => i_prof_notes(i),
                                         i_team_type     => i_team_type,
                                         o_num_msg       => l_num_msg,
                                         o_error         => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF l_num_msg = 3
            THEN
                RAISE l_err_3;
            END IF;
        END LOOP;
    
        g_error := 'SET PROF TEAM EA';
        IF NOT set_prof_team_ea(i_lang => i_lang, i_prof => i_prof, i_prof_team => l_id_prof_team, o_error => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        o_id_prof_team := l_id_prof_team;
    
        --change the status of do hhc request
        IF i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            g_error := 'GET ID EPISODE OF PROF TEAM';
            --get id episode of prof team
            l_id_episode := get_id_episode_prof_team(l_id_prof_team);
        
            g_error := 'CHANGE THE STATUS - PK_HHC_CORE.SET_REQ_STATUS_IE';
            --change the status
            IF NOT pk_hhc_core.set_req_status_ie(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_episode      => l_id_episode,
                                                 i_id_epis_hhc_req => NULL,
                                                 o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_err_2 THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_PROF_TEAM_INTERNAL',
                                      '',
                                      'PROF_TEAMS_M001',
                                      l_msg_err2,
                                      TRUE,
                                      'D',
                                      o_error);
        WHEN l_err_3 THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_PROF_TEAM_INTERNAL',
                                      '',
                                      'PROF_TEAMS_M003',
                                      l_msg_err3,
                                      TRUE,
                                      'D',
                                      o_error);
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_PROF_TEAM_INTERNAL',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'CREATE_PROF_TEAM_INTERNAL',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
    END create_prof_team_internal;

    /********************************************************************************************
    * Updates the information of a team of professionals
    *
    * @param  i_lang           language id
    * @param  i_prof           professional, software and institution ids
    * @param  i_prof_team      team id
    * @param  i_department     team department
    * @param  i_prof_team_name team name
    * @param  i_team_dt_begin  date of team shift beginning,
    * @param  i_team_dt_end    date of team shift ending,
    * @param  i_notes          team notes,
    * @param  i_professional   list of allocated professionals,
    * @param  i_prof_dt_begin  date of professional shift beginning,
    * @param  i_prof_dt_end    date of professional shift ending,
    * @param  i_prof_notes     professional notes,
    * @param  i_team_type      id team type,
    *
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION set_prof_team
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_team        IN prof_team.id_prof_team%TYPE,
        i_department       IN department.id_department%TYPE,
        i_prof_team_name   IN prof_team.prof_team_name%TYPE,
        i_team_dt_begin    IN VARCHAR2,
        i_team_dt_end      IN VARCHAR2,
        i_notes            IN prof_team.notes%TYPE,
        i_professional     IN table_number,
        i_prof_dt_begin    IN table_varchar,
        i_prof_dt_end      IN table_varchar,
        i_prof_notes       IN table_varchar,
        i_team_type        IN team_type.id_team_type%TYPE DEFAULT NULL,
        i_prof_team_leader IN prof_team.id_prof_team_leader%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_err_2     EXCEPTION;
        l_err_3     EXCEPTION;
        l_msg_err2 sys_message.desc_message%TYPE;
        l_msg_err3 sys_message.desc_message%TYPE;
        l_error    t_error_out;
    
        l_dt_begin     prof_team.dt_begin_tstz%TYPE;
        l_dt_end       prof_team.dt_end_tstz%TYPE;
        l_num_msg      NUMBER;
        l_num_members  NUMBER;
        l_effec_dt_end prof_team.dt_end_tstz%TYPE;
    
        l_id_software    software.id_software%TYPE;
        l_id_institution institution.id_institution%TYPE;
        l_rowids         table_varchar;
        l_id_episode     episode.id_episode%TYPE;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate      := SYSDATE;
    
        g_error    := 'GET ERROR MESSAGES';
        l_msg_err2 := pk_message.get_message(i_lang, 'PROF_TEAMS_M001');
        l_msg_err3 := pk_message.get_message(i_lang, 'PROF_TEAMS_M003');
    
        g_error    := 'CONVERT DATES';
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_team_dt_begin, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_team_dt_end, NULL);
    
        IF i_team_type IS NULL
        THEN
            g_error := 'CHECK TEAM DATE AND NAME';
            IF NOT check_team_integrity(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_type           => g_integrity_type_t,
                                        i_prof_team      => i_prof_team,
                                        i_department     => i_department,
                                        i_prof_team_name => i_prof_team_name,
                                        i_professional   => NULL,
                                        i_dt_begin       => l_dt_begin,
                                        i_dt_end         => l_dt_end,
                                        o_dt_end         => l_effec_dt_end,
                                        o_num_msg        => l_num_msg,
                                        o_error          => l_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            l_effec_dt_end := l_dt_end;
        END IF;
    
        IF l_num_msg = 2
        THEN
            RAISE l_err_2;
        END IF;
    
        g_error := 'SET PROF TEAM HISTORY';
        IF NOT set_prof_team_hist(i_lang => i_lang, i_prof => i_prof, i_prof_team => i_prof_team, o_error => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET ID_SOFTWARE AND ID_INSTITUTION';
        IF NOT get_soft_by_department(i_lang        => i_lang,
                                      i_prof        => i_prof,
                                      i_department  => i_department,
                                      o_institution => l_id_institution,
                                      o_software    => l_id_software,
                                      o_error       => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'DELETE PROF_TEAM RECORDS';
        ts_prof_team_det.del_by(where_clause_in => 'id_prof_team = ' || i_prof_team);
    
        g_error       := 'UPDATE PROF TEAM INFO';
        l_num_members := i_professional.count;
    
        ts_prof_team.upd(id_prof_team_in         => i_prof_team,
                         id_department_in        => i_department,
                         prof_team_name_in       => i_prof_team_name,
                         dt_begin_tstz_in        => l_dt_begin,
                         dt_end_tstz_in          => l_effec_dt_end,
                         notes_in                => i_notes,
                         notes_nin               => FALSE,
                         id_prof_register_in     => i_prof.id,
                         dt_register_in          => g_sysdate_tstz,
                         id_software_in          => l_id_software,
                         id_institution_in       => l_id_institution,
                         num_members_in          => l_num_members,
                         id_prof_team_leader_in  => i_prof_team_leader,
                         id_prof_team_leader_nin => FALSE,
                         rows_out                => l_rowids);
    
        g_error := 'LOOP PROFESSIONALS';
        FOR i IN 1 .. i_professional.count
        LOOP
            g_error := 'SET PROFESSIONAL TEAM';
            IF NOT set_professional_team(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_prof_team     => i_prof_team,
                                         i_professional  => i_professional(i),
                                         i_prof_dt_begin => i_prof_dt_begin(i),
                                         i_prof_dt_end   => i_prof_dt_end(i),
                                         i_prof_notes    => i_prof_notes(i),
                                         i_team_type     => i_team_type,
                                         o_num_msg       => l_num_msg,
                                         o_error         => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF l_num_msg = 3
            THEN
                RAISE l_err_3;
            END IF;
        END LOOP;
    
        g_error := 'SET PROF TEAM EA';
        IF NOT set_prof_team_ea(i_lang => i_lang, i_prof => i_prof, i_prof_team => i_prof_team, o_error => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        --change the status of do hhc request
        IF i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            g_error := 'GET ID EPISODE OF PROF TEAM';
            --get id episode of prof team
            l_id_episode := get_id_episode_prof_team(i_prof_team);
        
            g_error := 'CHANGE THE STATUS - PK_HHC_CORE.SET_REQ_STATUS_IE';
            --change the status
            IF NOT pk_hhc_core.set_req_status_ie(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_episode      => l_id_episode,
                                                 i_id_epis_hhc_req => NULL,
                                                 o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_err_2 THEN
            RETURN error_handling_ext(i_lang, 'SET_PROF_TEAM', '', 'PROF_TEAMS_M001', l_msg_err2, TRUE, 'D', o_error);
        WHEN l_err_3 THEN
            RETURN error_handling_ext(i_lang, 'SET_PROF_TEAM', '', 'PROF_TEAMS_M003', l_msg_err3, TRUE, 'D', o_error);
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_PROF_TEAM',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'SET_PROF_TEAM', g_error, SQLCODE, SQLERRM, TRUE, 'S', o_error);
    END set_prof_team;

    /********************************************************************************************
    * Cancels a team of professionals
    *
    * @param  i_lang             language id
    * @param  i_prof             professional, software and institution ids
    * @param  i_prof_team        team id
    * @param  i_id_cancel_reason Cancellation reason ID
    * @param  i_notes            Cancel Notes
    *
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION cancel_prof_team
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_team        IN prof_team.id_prof_team%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error  t_error_out;
        l_rowids table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate      := SYSDATE;
    
        g_error := 'SET PROF TEAM HISTORY';
        IF NOT set_prof_team_hist(i_lang => i_lang, i_prof => i_prof, i_prof_team => i_prof_team, o_error => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'UPDATE PROF TEAM';
        ts_prof_team.upd(id_prof_team_in      => i_prof_team,
                         flg_status_in        => pk_alert_constant.g_team_cancel,
                         id_cancel_reason_in  => i_id_cancel_reason,
                         id_cancel_reason_nin => FALSE,
                         id_prof_register_in  => i_prof.id,
                         dt_register_in       => g_sysdate_tstz,
                         notes_cancel_in      => i_notes,
                         notes_cancel_nin     => FALSE,
                         rows_out             => l_rowids);
    
        g_error := 'UPDATE PROF_TEAM_DET';
        ts_prof_team_det.upd(flg_status_in      => pk_alert_constant.g_team_det_cancel,
                             id_prof_cancel_in  => i_prof.id,
                             dt_cancel_tstz_in  => g_sysdate_tstz,
                             adw_last_update_in => g_sysdate,
                             where_in           => 'id_prof_team = ' || i_prof_team,
                             rows_out           => l_rowids);
    
        g_error := 'SET PROF TEAM EA';
        IF NOT set_prof_team_ea(i_lang => i_lang, i_prof => i_prof, i_prof_team => i_prof_team, o_error => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'CANCEL_PROF_TEAM',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'CANCEL_PROF_TEAM', g_error, SQLCODE, SQLERRM, TRUE, 'S', o_error);
    END cancel_prof_team;

    /********************************************************************************************
    * Gets the active teams for the next 24 hours
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    *
    * @param o_teams           List of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_active_teams
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_teams OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error         t_error_out;
        l_id_prof_teams table_number;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET PROF TEAMS';
        IF NOT get_prof_active_teams(i_lang, i_prof, l_id_prof_teams, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET_ACTIVE_TEAMS';
        OPEN o_teams FOR
            SELECT p.id_prof_team,
                   p.id_department,
                   d.id_dept,
                   p.prof_team_name,
                   p.flg_status,
                   pk_prof_teams.get_prof_team_domain(i_lang, p.flg_status) desc_status,
                   pk_prof_teams.get_notes_label(i_lang, i_prof, p.notes, NULL) with_notes,
                   pk_translation.get_translation(i_lang, d.code_department) desc_department,
                   (SELECT pk_translation.get_translation(i_lang, dp.code_dept)
                      FROM dept dp
                     WHERE dp.id_dept = d.id_dept) desc_dept,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, p.dt_begin_tstz, i_prof) effec_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_begin_tstz, i_prof.institution, i_prof.software) ||
                   ' - ' ||
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_end_tstz, i_prof.institution, i_prof.software) period,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_end_tstz, i_prof) dt_end,
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_begin_tstz, i_prof.institution, i_prof.software) start_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_end_tstz, i_prof.institution, i_prof.software) end_date,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_end_tstz, i_prof) dt_end,
                   p.num_members,
                   p.notes,
                   nvl((SELECT g_yes
                         FROM TABLE(l_id_prof_teams) a
                        WHERE a.column_value = p.id_prof_team),
                       g_no) flg_select,
                   p.id_team_type,
                   pk_translation.get_translation(i_lang, t.code_team_type) desc_team_type,
                   d.flg_type,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_prof_team_leader) prof_leader,
                   p.id_prof_team_leader
              FROM prof_team_ea p
              JOIN department d
                ON d.id_department = p.id_department
              LEFT JOIN team_type t
                ON p.id_team_type = t.id_team_type
             WHERE ((p.flg_status IN (pk_alert_constant.g_team_active, pk_alert_constant.g_team_inactive) AND
                   p.dt_end_tstz >= g_sysdate_tstz AND p.id_team_type IS NULL) OR
                   (p.flg_status = pk_alert_constant.g_team_active AND p.id_team_type IS NOT NULL))
               AND d.id_institution = i_prof.institution
             ORDER BY p.dt_begin_tstz, desc_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_teams);
            RETURN error_handling_ext(i_lang,
                                      'GET_ACTIVE_TEAMS',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_teams);
            RETURN error_handling_ext(i_lang, 'GET_ACTIVE_TEAMS', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_active_teams;

    /********************************************************************************************
    * Gets the active teams for the next 24 hours (for a specific professional)
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    *
    * @param o_teams           List of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_my_active_teams
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_teams OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_error         t_error_out;
        l_id_prof_teams table_number;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET PROF TEAMS';
        IF NOT get_prof_active_teams(i_lang, i_prof, l_id_prof_teams, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET_ACTIVE_TEAMS';
        OPEN o_teams FOR
            SELECT p.id_prof_team,
                   p.id_department,
                   d.id_dept,
                   p.prof_team_name,
                   p.flg_status,
                   pk_prof_teams.get_prof_team_domain(i_lang, p.flg_status) desc_status,
                   pk_prof_teams.get_notes_label(i_lang, i_prof, p.notes, NULL) with_notes,
                   pk_translation.get_translation(i_lang, d.code_department) desc_department,
                   (SELECT pk_translation.get_translation(i_lang, dp.code_dept)
                      FROM dept dp
                     WHERE dp.id_dept = d.id_dept) desc_dept,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, p.dt_begin_tstz, i_prof) effec_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_begin_tstz, i_prof.institution, i_prof.software) ||
                   ' - ' ||
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_end_tstz, i_prof.institution, i_prof.software) period,
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_begin_tstz, i_prof.institution, i_prof.software) start_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_end_tstz, i_prof.institution, i_prof.software) end_date,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_end_tstz, i_prof) dt_end,
                   p.num_members,
                   p.notes,
                   nvl((SELECT g_yes
                         FROM TABLE(l_id_prof_teams) a
                        WHERE a.column_value = p.id_prof_team),
                       g_no) flg_select,
                   p.id_team_type,
                   pk_translation.get_translation(i_lang, t.code_team_type) desc_team_type,
                   d.flg_type,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_prof_team_leader) prof_leader,
                   p.id_prof_team_leader
              FROM prof_team_ea p
              JOIN department d
                ON d.id_department = p.id_department
              LEFT JOIN team_type t
                ON p.id_team_type = t.id_team_type
             WHERE ((p.flg_status IN (pk_alert_constant.g_team_active, pk_alert_constant.g_team_inactive) AND
                   p.dt_end_tstz >= g_sysdate_tstz AND p.id_team_type IS NULL) OR
                   (p.flg_status = pk_alert_constant.g_team_active AND p.id_team_type IS NOT NULL))
               AND d.id_institution = i_prof.institution
               AND EXISTS (SELECT 0
                      FROM prof_team_det pd
                     WHERE pd.id_prof_team = p.id_prof_team
                       AND pd.id_professional = i_prof.id)
             ORDER BY p.dt_begin_tstz, desc_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_teams);
            RETURN error_handling_ext(i_lang,
                                      'GET_MY_ACTIVE_TEAMS',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_teams);
            RETURN error_handling_ext(i_lang, 'GET_MY_ACTIVE_TEAMS', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_my_active_teams;

    /********************************************************************************************
    * Gets all the teams for for a specific institution
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    *
    * @param o_teams           List of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_archive_teams
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_teams OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET ARCHIVE TEAMS';
        OPEN o_teams FOR
            SELECT p.id_prof_team,
                   p.id_department,
                   d.id_dept,
                   p.prof_team_name,
                   p.flg_status,
                   pk_prof_teams.get_prof_team_domain(i_lang, p.flg_status) desc_status,
                   pk_prof_teams.get_notes_label(i_lang, i_prof, p.notes, p.notes_cancel) with_notes,
                   pk_translation.get_translation(i_lang, d.code_department) desc_department,
                   (SELECT pk_translation.get_translation(i_lang, dp.code_dept)
                      FROM dept dp
                     WHERE dp.id_dept = d.id_dept) desc_dept,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, p.dt_begin_tstz, i_prof) effec_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_begin_tstz, i_prof.institution, i_prof.software) ||
                   ' - ' ||
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_end_tstz, i_prof.institution, i_prof.software) period,
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_begin_tstz, i_prof.institution, i_prof.software) start_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_end_tstz, i_prof.institution, i_prof.software) end_date,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_end_tstz, i_prof) dt_end,
                   p.num_members,
                   p.notes,
                   p.id_team_type,
                   pk_translation.get_translation(i_lang, t.code_team_type) desc_team_type,
                   d.flg_type,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_prof_team_leader) prof_leader,
                   p.id_prof_team_leader
              FROM prof_team p
              JOIN department d
                ON d.id_department = p.id_department
              LEFT JOIN team_type t
                ON t.id_team_type = p.id_team_type
             WHERE d.id_institution = i_prof.institution
               AND (p.dt_end_tstz < g_sysdate_tstz OR p.flg_status = pk_alert_constant.g_team_cancel)
             ORDER BY p.dt_begin_tstz DESC, desc_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_teams);
            RETURN error_handling_ext(i_lang, 'GET_ARCHIVE_TEAMS', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_archive_teams;

    /********************************************************************************************
    * Gets the team responsible for the episode
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID associated with the episode
    * @param i_epis_software   software ID
    * @param i_prof_doc        doctor responsible for the episode
    * @param i_prof_nurse      nurse responsible for the episode
    *                    
    * @return                  current team responsible for the episode
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   27-02-2009
    **********************************************************************************************/
    FUNCTION get_prof_current_team
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_department    IN department.id_department%TYPE,
        i_epis_software IN software.id_software%TYPE,
        i_prof_doc      IN professional.id_professional%TYPE,
        i_prof_nurse    IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
    
        l_teams     VARCHAR2(4000);
        l_team_name table_varchar;
    
        CURSOR c_teams IS
            SELECT DISTINCT prof_team_name
              FROM (SELECT pt.prof_team_name, decode(pd.id_professional, i_prof_doc, 1, 0) rank
                      FROM prof_team_ea pt
                      JOIN prof_team_det_ea pd
                        ON pd.id_prof_team = pt.id_prof_team
                     WHERE (pt.id_department = i_department OR pt.id_software = i_epis_software)
                       AND pt.flg_status = pk_alert_constant.g_team_active
                       AND pd.id_professional IN (i_prof_doc, i_prof_nurse)
                       AND current_timestamp BETWEEN pd.dt_begin AND pd.dt_end
                     ORDER BY rank DESC) a;
    
    BEGIN
    
        OPEN c_teams;
        FETCH c_teams BULK COLLECT
            INTO l_team_name;
        CLOSE c_teams;
    
        l_teams := pk_utils.concat_table(l_team_name, ' / ');
    
        RETURN l_teams;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_prof_current_team;

    /********************************************************************************************
    * Checks if the professional has permission to team creation
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    *
    * @param o_flg_permission  Permission to create teams: Y - yes, N - No
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   02-03-2009
    **********************************************************************************************/
    FUNCTION get_team_create_permission
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_flg_permission OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_func        sys_functionality.id_functionality%TYPE;
        l_id_pf          prof_func.id_prof_func%TYPE;
        l_flg_permission VARCHAR2(1);
    
    BEGIN
    
        g_error   := 'GET CONFIG';
        l_id_func := pk_sysconfig.get_config('FUNCTIONALITY_MEDICAL_TEAMS', i_prof);
    
        BEGIN
            SELECT pf.id_prof_func
              INTO l_id_pf
              FROM prof_func pf
             WHERE pf.id_functionality = l_id_func
               AND pf.id_professional = i_prof.id
               AND pf.id_institution = i_prof.institution;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_permission := g_no;
        END;
    
        IF l_flg_permission IS NULL
        THEN
            l_flg_permission := g_yes;
        END IF;
    
        o_flg_permission := l_flg_permission;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'GET_TEAM_CREATE_PERMISSION',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
    END get_team_create_permission;

    /********************************************************************************************
    * Gets the detail of a specific team
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_prof_team       team id
    * @param o_team_reg        List of team records
    * @param o_team_val        List of team values
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   02-03-2009
    **********************************************************************************************/
    FUNCTION get_prof_team_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE,
        o_team_reg  OUT pk_types.cursor_type,
        o_team_val  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_type_reg   prof_team_hist.flg_type_register%TYPE;
        l_count          NUMBER;
        l_id_software    software.id_software%TYPE;
        l_id_institution institution.id_institution%TYPE;
        l_team_prof_det  t_coll_team_prof_det;
    BEGIN
    
        g_error := 'COUNT RECORDS';
        SELECT COUNT(*)
          INTO l_count
          FROM prof_team_hist pt
         WHERE pt.id_prof_team = i_prof_team;
    
        g_error := 'GET ID_SOFTWARE AND ID_INSTITUTION';
        SELECT p.id_software, p.id_institution
          INTO l_id_software, l_id_institution
          FROM prof_team p
         WHERE p.id_prof_team = i_prof_team;
    
        g_error := 'GET FLG_TYPE_REGISTER';
        IF l_count = 0
        THEN
            l_flg_type_reg := pk_alert_constant.g_flg_type_reg_c;
        ELSE
            l_flg_type_reg := pk_alert_constant.g_flg_type_reg_e;
        END IF;
    
        IF l_id_software = pk_alert_constant.g_soft_home_care
        THEN
        
            l_team_prof_det := tf_get_team_det(i_lang, i_prof, i_prof_team);
            g_error         := 'OPEN o_team_val';
            OPEN o_team_val FOR
                SELECT *
                  FROM TABLE(l_team_prof_det);
        
            pk_types.open_my_cursor(o_team_reg);
        ELSE
        
        g_error := 'OPEN o_team_reg';
        OPEN o_team_reg FOR
            SELECT 0 id_reg,
                   p.id_prof_team,
                   p.prof_team_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_prof_register) prof_name,
                   p.flg_status,
                   decode(p.flg_status,
                          pk_alert_constant.g_team_cancel,
                          get_prof_team_domain(i_lang, p.flg_status),
                          pk_sysdomain.get_domain('PROF_TEAM_HIST.FLG_TYPE_REGISTER', l_flg_type_reg, i_lang)) desc_status,
                   pk_translation.get_translation(i_lang, d.code_department) desc_department,
                   (SELECT pk_translation.get_translation(i_lang, d.code_department)
                      FROM dept dp
                     WHERE dp.id_dept = d.id_dept) desc_dept,
                   get_prof_rooms(i_lang, i_prof, p.id_prof_team) prof_rooms,
                   pk_date_utils.date_char_tsz(i_lang, p.dt_register, i_prof.institution, i_prof.software) dt_reg,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, p.dt_begin_tstz, i_prof) effec_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_begin_tstz, i_prof.institution, i_prof.software) start_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, p.dt_end_tstz, i_prof.institution, i_prof.software) end_date,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_end_tstz, i_prof) dt_end,
                   p.notes,
                   p.notes_cancel,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, p.id_cancel_reason) desc_cancel,
                   p.dt_register,
                   pk_translation.get_translation(i_lang, t.code_team_type) desc_team_type,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_prof_team_leader) prof_leader,
                   d.flg_type
            
              FROM prof_team p
              JOIN department d
                ON d.id_department = p.id_department
              LEFT JOIN team_type t
                ON p.id_team_type = t.id_team_type
             WHERE p.id_prof_team = i_prof_team
            
            UNION ALL
            
            SELECT ph.id_prof_team_hist id_reg,
                   ph.id_prof_team,
                   ph.prof_team_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ph.id_prof_register) prof_name,
                   ph.flg_status,
                   pk_sysdomain.get_domain('PROF_TEAM_HIST.FLG_TYPE_REGISTER', ph.flg_type_register, i_lang) desc_status,
                   pk_translation.get_translation(i_lang, d.code_department) desc_department,
                   (SELECT pk_translation.get_translation(i_lang, d.code_department)
                      FROM dept dp
                     WHERE dp.id_dept = d.id_dept) desc_dept,
                   get_prof_rooms(i_lang, i_prof, ph.id_prof_team) prof_rooms,
                   pk_date_utils.date_char_tsz(i_lang, ph.dt_register, i_prof.institution, i_prof.software) dt_reg,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, ph.dt_begin_tstz, i_prof) effec_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, ph.dt_begin_tstz, i_prof.institution, i_prof.software) start_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, ph.dt_end_tstz, i_prof.institution, i_prof.software) end_date,
                   pk_date_utils.date_send_tsz(i_lang, ph.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, ph.dt_end_tstz, i_prof) dt_end,
                   ph.notes,
                   NULL notes_cancel,
                   NULL desc_cancel,
                   ph.dt_register,
                   pk_translation.get_translation(i_lang, t.code_team_type) desc_team_type,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ph.id_prof_team_leader) prof_leader,
                   d.flg_type
            
              FROM prof_team_hist ph
              JOIN department d
                ON d.id_department = ph.id_department
              LEFT JOIN team_type t
                ON ph.id_team_type = t.id_team_type
             WHERE ph.id_prof_team = i_prof_team
             ORDER BY dt_register DESC;
    
        g_error := 'OPEN o_team_val';
        OPEN o_team_val FOR
            SELECT 0 id_reg,
                   pd.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pd.id_professional) prof_name,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, pd.dt_begin, i_prof) effec_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, pd.dt_begin, i_prof.institution, i_prof.software) start_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, pd.dt_end, i_prof.institution, i_prof.software) end_date,
                   pk_date_utils.date_send_tsz(i_lang, pd.dt_begin, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, pd.dt_end, i_prof) dt_end,
                   pd.notes
              FROM prof_team_det pd
              JOIN professional p
                ON p.id_professional = pd.id_professional
             WHERE pd.id_prof_team = i_prof_team
            
            UNION ALL
            
            SELECT pdh.id_prof_team_hist id_reg,
                   pdh.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pdh.id_professional) prof_name,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, pdh.dt_begin, i_prof) effec_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, pdh.dt_begin, i_prof.institution, i_prof.software) start_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, pdh.dt_end, i_prof.institution, i_prof.software) end_date,
                   pk_date_utils.date_send_tsz(i_lang, pdh.dt_begin, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, pdh.dt_end, i_prof) dt_end,
                   pdh.notes
              FROM prof_team_det_hist pdh
              JOIN professional p
                ON p.id_professional = pdh.id_professional
             WHERE pdh.id_prof_team = i_prof_team
             ORDER BY id_reg DESC, id_professional;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_team_reg);
            pk_types.open_my_cursor(o_team_val);
            RETURN error_handling_ext(i_lang, 'GET_PROF_TEAM_DET', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_prof_team_det;

    /********************************************************************************************
    * Gets the professional list for a specific department
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID
    * @param o_prof            list of professionals
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   03-03-2009
    **********************************************************************************************/
    FUNCTION get_prof_create_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        o_prof       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_desc_dept       VARCHAR2(200);
        l_desc_department VARCHAR2(200);
        l_id_institution  institution.id_institution%TYPE;
        l_id_software     software.id_software%TYPE;
        l_error           t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'GET DESC DEPARTMENT';
        SELECT pk_translation.get_translation(i_lang, dt.code_dept),
               pk_translation.get_translation(i_lang, d.code_department)
          INTO l_desc_dept, l_desc_department
          FROM dept dt, department d
         WHERE d.id_department = i_department
           AND d.id_dept = dt.id_dept;
    
        g_error := 'GET ID_SOFTWARE AND ID_INSTITUTION';
        IF NOT get_soft_by_department(i_lang        => i_lang,
                                      i_prof        => i_prof,
                                      i_department  => i_department,
                                      o_institution => l_id_institution,
                                      o_software    => l_id_software,
                                      o_error       => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET ARCHIVE TEAMS';
        OPEN o_prof FOR
            SELECT prof.id_professional,
                   pk_profphoto.get_prof_photo(profissional(prof.id_professional, i_prof.institution, i_prof.software)) prof_photo,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) prof_name,
                   l_desc_dept desc_dept,
                   l_desc_department desc_department,
                   pk_prof_utils.get_prof_speciality(i_lang,
                                                     profissional(prof.id_professional,
                                                                  i_prof.institution,
                                                                  i_prof.software)) prof_speciality
              FROM professional prof
             WHERE EXISTS
             (SELECT 0
                      FROM dep_clin_serv dcs
                      JOIN prof_dep_clin_serv pd
                        ON dcs.id_dep_clin_serv = pd.id_dep_clin_serv
                     WHERE dcs.id_department = i_department
                       AND dcs.flg_available = g_available
                       AND prof.id_professional = pd.id_professional
                       AND pd.flg_status = pk_alert_constant.g_status_selected)
               AND pk_prof_utils.get_category(i_lang,
                                              profissional(prof.id_professional, i_prof.institution, i_prof.software)) IN
                   (pk_alert_constant.g_cat_type_doc,
                    pk_alert_constant.g_cat_type_nurse,
                    pk_alert_constant.g_cat_type_triage)
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, prof.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
               AND EXISTS (SELECT 0
                      FROM prof_institution pi
                     WHERE pi.flg_state = g_active
                       AND pi.id_professional = prof.id_professional
                       AND pi.id_institution = l_id_institution
                       AND pi.dt_end_tstz IS NULL)
            UNION ALL
            -- show ancillaries
            SELECT prof.id_professional,
                   pk_profphoto.get_prof_photo(profissional(prof.id_professional, i_prof.institution, i_prof.software)) prof_photo,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) prof_name,
                   l_desc_dept desc_dept,
                   l_desc_department desc_department,
                   pk_prof_utils.get_prof_speciality(i_lang,
                                                     profissional(prof.id_professional,
                                                                  i_prof.institution,
                                                                  i_prof.software)) prof_speciality
              FROM professional prof
              JOIN prof_profile_template ppt
                ON ppt.id_professional = prof.id_professional
              JOIN profile_template p
                ON ppt.id_profile_template = p.id_profile_template
             WHERE ppt.id_institution = l_id_institution
               AND ppt.id_software = l_id_software
               AND p.flg_type = 'O'
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, prof.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
               AND EXISTS (SELECT 0
                      FROM prof_institution pi
                     WHERE pi.flg_state = g_active
                       AND pi.id_professional = prof.id_professional
                       AND pi.id_institution = l_id_institution
                       AND pi.dt_end_tstz IS NULL)
             ORDER BY prof_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'GET_PROF_CREATE_LIST',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_prof);
            RETURN error_handling_ext(i_lang, 'GET_PROF_CREATE_LIST', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_prof_create_list;

    /********************************************************************************************
    * Gets the group of professionals of a team
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID
    * @param i_prof_team       team ID
    * @param o_prof            list of professionals
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   04-03-2009
    **********************************************************************************************/
    FUNCTION get_prof_edit_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        i_prof_team  IN prof_team.id_prof_team%TYPE,
        o_prof       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_desc_department VARCHAR2(200);
    
    BEGIN
    
        g_error := 'GET DESC DEPARTMENT';
        SELECT pk_translation.get_translation(i_lang, d.code_department)
          INTO l_desc_department
          FROM department d
         WHERE d.id_department = i_department;
    
        g_error := 'GET ARCHIVE TEAMS';
        OPEN o_prof FOR
            SELECT prof.id_professional,
                   pk_profphoto.get_prof_photo(profissional(prof.id_professional, i_prof.institution, i_prof.software)) prof_photo,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) prof_name,
                   l_desc_department desc_department,
                   prof.notes,
                   pk_date_utils.date_char_hour_tsz(i_lang, prof.dt_begin, i_prof.institution, i_prof.software) start_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, prof.dt_end, i_prof.institution, i_prof.software) end_date,
                   pk_date_utils.date_send_tsz(i_lang, prof.dt_begin, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, prof.dt_end, i_prof) dt_end,
                   pk_prof_utils.get_prof_speciality(i_lang,
                                                     profissional(prof.id_professional,
                                                                  i_prof.institution,
                                                                  i_prof.software)) prof_speciality
              FROM prof_team_det prof
             WHERE prof.id_prof_team = i_prof_team
             ORDER BY prof_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_prof);
            RETURN error_handling_ext(i_lang, 'GET_PROF_EDIT_LIST', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_prof_edit_list;

    /********************************************************************************************
    * Checks if the current dept is the default one
    *
    * @param i_prof            professional, software and institution ids
    * @param i_dept            department list
    *                    
    * @return                  Default dept: Y - yes; N - No
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   02-11-2009
    **********************************************************************************************/
    FUNCTION get_default_dept
    (
        i_prof IN profissional,
        i_dept IN dept.id_dept%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count NUMBER;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM software_dept d
         WHERE d.id_dept = i_dept
           AND d.id_software = i_prof.software;
    
        IF l_count > 0
        THEN
            RETURN g_yes;
        ELSE
            RETURN g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_no;
    END get_default_dept;

    /********************************************************************************************
    * Gets the list of departments
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param o_dept            department list
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   21-05-2009
    **********************************************************************************************/
    FUNCTION get_dept_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_dept  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR O_DEPT';
        OPEN o_dept FOR
            SELECT id_dept,
                   abbreviation,
                   pk_translation.get_translation(i_lang, code_dept) dept,
                   get_default_dept(i_prof, d.id_dept) flg_default
              FROM dept d
             WHERE id_institution = i_prof.institution
               AND d.flg_available = g_available
               AND EXISTS (SELECT 0
                      FROM software_dept sd
                     WHERE sd.id_dept = d.id_dept
                       AND sd.id_software IN (pk_alert_constant.g_soft_edis,
                                              pk_alert_constant.g_soft_triage,
                                              pk_alert_constant.g_soft_outpatient))
             ORDER BY d.rank, dept;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dept);
            RETURN error_handling_ext(i_lang, 'GET_DEPT_LIST', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_dept_list;

    /********************************************************************************************
    * Gets the list of team services
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param o_department      department list
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   19-03-2009
    **********************************************************************************************/
    FUNCTION get_department_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET DEPARTMENTS';
        OPEN o_department FOR
            SELECT id_department, pk_translation.get_translation(i_lang, code_department) department
              FROM department d
             WHERE id_institution = i_prof.institution
               AND EXISTS (SELECT 0
                      FROM room r
                     WHERE r.id_department = d.id_department
                       AND r.flg_transp = g_available
                       AND r.flg_available = g_available)
               AND d.flg_available = g_available
               AND EXISTS
             (SELECT 0
                      FROM prof_team_ea p
                     WHERE p.flg_status IN (pk_alert_constant.g_team_active, pk_alert_constant.g_team_inactive)
                       AND p.id_department = d.id_department
                       AND p.dt_end_tstz >= g_sysdate_tstz)
             ORDER BY rank, department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_department);
            RETURN error_handling_ext(i_lang, 'GET_DEPARTMENT_LIST', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_department_list;

    /********************************************************************************************
    * Gets all teams inside a given department
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID
    *
    * @param o_teams           List of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   19-03-2009
    **********************************************************************************************/
    FUNCTION get_department_teams
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        o_teams      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET_DEPARTMENT_TEAMS';
        OPEN o_teams FOR
            SELECT p.id_prof_team, p.prof_team_name
              FROM prof_team_ea p
             WHERE p.flg_status IN (pk_alert_constant.g_team_active, pk_alert_constant.g_team_inactive)
               AND p.id_department = i_department
               AND p.dt_end_tstz >= g_sysdate_tstz
             ORDER BY prof_team_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_teams);
            RETURN error_handling_ext(i_lang, 'GET_DEPARTMENT_TEAMS', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_department_teams;

    /********************************************************************************************
    * Gets all rooms inside a given department
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID
    * @param i_prof_team       team ID
    *
    * @param o_rooms           List of rooms
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   19-03-2009
    **********************************************************************************************/
    FUNCTION get_room_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        i_prof_team  IN prof_team.id_prof_team%TYPE,
        o_rooms      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_rooms FOR
            SELECT r.id_room,
                   pr.id_prof_team_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name,
                   decode(id_prof_team_room, NULL, g_inactive, g_active) flg_select
              FROM room r
              LEFT JOIN prof_team_room pr
                ON r.id_room = pr.id_room
               AND pr.id_prof_team = i_prof_team
               AND pr.flg_status = g_status_team_room_a
             WHERE r.id_department = i_department
               AND r.flg_transp = g_available
               AND r.flg_available = g_available
             ORDER BY r.rank, room_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rooms);
            RETURN error_handling_ext(i_lang, 'GET_ROOM_LIST', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_room_list;

    /********************************************************************************************
    * Gets all rooms inside a given department
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_department      department ID
    * @param i_prof_team       team ID
    *
    * @param o_rooms           List of rooms
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   19-03-2009
    **********************************************************************************************/
    FUNCTION get_bed_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_room           IN room.id_room%TYPE,
        i_prof_team_room IN prof_team_room.id_prof_team_room%TYPE,
        o_beds           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_beds FOR
            SELECT b.id_bed,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_name,
                   decode(pb.id_prof_team_room, NULL, g_inactive, g_active) flg_select
              FROM bed b
              LEFT JOIN prof_team_bed pb
                ON b.id_bed = pb.id_bed
               AND pb.id_prof_team_room = i_prof_team_room
             WHERE b.id_room = i_room
               AND b.flg_type = g_bed_permanent
               AND b.flg_available = g_available
             ORDER BY bed_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_beds);
            RETURN error_handling_ext(i_lang, 'GET_BED_LIST', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_bed_list;

    /********************************************************************************************
    * Allocates rooms and beds to a team
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_prof_team       list of teams
    * @param i_rooms           list of rooms
    * @param i_room_changes    indicates if a room has bed changes    
    * @param i_beds            list of beds
    * 
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   19-03-2009
    **********************************************************************************************/
    FUNCTION create_prof_rooms
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_prof_team    IN table_number,
        i_rooms        IN table_table_number,
        i_room_changes IN table_table_varchar,
        i_beds         IN table_table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_row_ids table_varchar;
        l_id_beds table_number;
    
        l_id_prof_team_room prof_team_room.id_prof_team_room%TYPE;
    
        l_status_team_room_t CONSTANT VARCHAR2(1) := 'T';
    
        CURSOR c_beds
        (
            i_id_beds table_number,
            i_id_room room.id_room%TYPE
        ) IS
            SELECT b.id_bed
              FROM bed b
              JOIN TABLE(i_id_beds) tb
                ON tb.column_value = b.id_bed
             WHERE b.id_room = i_id_room;
    
        CURSOR c_prof_bed
        (
            i_id_room      room.id_room%TYPE,
            i_id_prof_team prof_team.id_prof_team%TYPE
        ) IS
            SELECT p.id_bed
              FROM prof_team_bed p
              JOIN prof_team_room pr
                ON pr.id_prof_team_room = p.id_prof_team_room
             WHERE pr.id_room = i_id_room
               AND pr.flg_status = g_status_team_room_a
               AND pr.id_prof_team = i_id_prof_team;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'LOOP i_prof_team';
        FOR i IN 1 .. i_prof_team.count
        LOOP
        
            g_error := 'LOOP i_rooms';
            FOR j IN 1 .. i_rooms(i).count
            LOOP
            
                g_error := 'SET TEAM ROOM';
                SELECT seq_prof_team_room.nextval
                  INTO l_id_prof_team_room
                  FROM dual;
            
                ts_prof_team_room.ins(id_prof_team_room_in => l_id_prof_team_room,
                                      id_prof_team_in      => i_prof_team(i),
                                      id_room_in           => i_rooms(i) (j),
                                      flg_status_in        => l_status_team_room_t,
                                      create_time_in       => g_sysdate_tstz,
                                      create_user_in       => i_prof.id,
                                      rows_out             => l_row_ids);
            
                l_row_ids := table_varchar();
            
                IF i_room_changes(i) (j) = g_no
                THEN
                    g_error := 'GET OLD BEDS';
                    FOR r_prof_bed IN c_prof_bed(i_rooms(i) (j), i_prof_team(i))
                    LOOP
                        ts_prof_team_bed.ins(id_prof_team_room_in => l_id_prof_team_room,
                                             id_bed_in            => r_prof_bed.id_bed,
                                             rows_out             => l_row_ids);
                    END LOOP;
                ELSE
                    g_error := 'GET ROOM BEDS';
                    OPEN c_beds(i_beds(i), i_rooms(i) (j));
                    FETCH c_beds BULK COLLECT
                        INTO l_id_beds;
                    CLOSE c_beds;
                
                    g_error := 'SET PROF TEAM BED';
                    FOR k IN 1 .. l_id_beds.count
                    LOOP
                        ts_prof_team_bed.ins(id_prof_team_room_in => l_id_prof_team_room,
                                             id_bed_in            => l_id_beds(k),
                                             rows_out             => l_row_ids);
                    
                    END LOOP;
                END IF;
            
                l_row_ids := table_varchar();
            
            END LOOP;
        
            ts_prof_team_room.upd(flg_status_in => g_status_team_room_i,
                                  where_in      => 'flg_status = ''' || g_status_team_room_a || '''' ||
                                                   ' AND id_prof_team = ' || i_prof_team(i),
                                  rows_out      => l_row_ids);
        
            l_row_ids := table_varchar();
        
            ts_prof_team_room.upd(flg_status_in => g_status_team_room_a,
                                  where_in      => 'flg_status = ''' || l_status_team_room_t || '''' ||
                                                   ' AND id_prof_team = ' || i_prof_team(i),
                                  rows_out      => l_row_ids);
        
            l_row_ids := table_varchar();
        
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'CREATE_PROF_ROOMS', g_error, SQLCODE, SQLERRM, TRUE, 'S', o_error);
    END create_prof_rooms;

    /********************************************************************************************
    * Gets all rooms associated with a team
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_prof_team       team ID
    *                    
    * @return                  rooms description
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   21-05-2009
    **********************************************************************************************/
    FUNCTION get_prof_rooms
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE
    ) RETURN VARCHAR2 IS
    
        l_rooms     VARCHAR2(4000);
        l_team_room table_varchar;
    
        CURSOR c_team_room IS
            SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name
              FROM prof_team_room pr
              JOIN room r
                ON r.id_room = pr.id_room
             WHERE pr.id_prof_team = i_prof_team
               AND pr.flg_status = g_status_team_room_a
             ORDER BY r.rank, room_name;
    
    BEGIN
    
        OPEN c_team_room;
        FETCH c_team_room BULK COLLECT
            INTO l_team_room;
        CLOSE c_team_room;
    
        l_rooms := pk_utils.concat_table(l_team_room, ', ');
    
        RETURN l_rooms;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_prof_rooms;

    /********************************************************************************************
    * Gets the list of teams that were assigned to an episode
    *
    * @param i_lang            language ID
    * @param i_prof            professional, software and institution ids
    * @param i_episode         episode ID
    *
    * @param o_teams           List of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  José Silva
    * @version                 1.0   
    * @since                   21-05-2009
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_team
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_teams   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_department department.id_department%TYPE;
        l_id_software   software.id_software%TYPE;
    
    BEGIN
    
        g_error := 'GET EPIS SOFTWARE';
        SELECT e.id_department, pk_episode.get_soft_by_epis_type(e.id_epis_type, i_prof.institution)
          INTO l_id_department, l_id_software
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        g_error := 'GET_ACTIVE_TEAMS';
        OPEN o_teams FOR
            SELECT id_prof_team,
                   prof_team_name,
                   with_notes,
                   effec_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, MIN(dt_max_begin), i_prof.institution, i_prof.software) ||
                   ' - ' ||
                   pk_date_utils.date_char_hour_tsz(i_lang, MAX(dt_min_end), i_prof.institution, i_prof.software) period,
                   num_members,
                   MIN(dt_begin) dt_begin
              FROM (SELECT p.id_prof_team,
                           p.prof_team_name,
                           pd.dt_begin,
                           get_notes_label(i_lang, i_prof, p.notes, NULL) with_notes,
                           pk_date_utils.date_chr_short_read_tsz(i_lang, pd.dt_begin, i_prof) effec_date,
                           greatest(epr.dt_comp_tstz, pd.dt_begin) dt_max_begin,
                           least(pd.dt_end,
                                 nvl((SELECT MIN(ep.dt_comp_tstz)
                                       FROM epis_prof_resp ep
                                       JOIN prof_cat pc2
                                         ON pc2.id_professional = ep.id_prof_to
                                      WHERE ep.id_episode = i_episode
                                        AND pc2.id_category = pc.id_category
                                        AND ep.flg_status = pk_hand_off.g_hand_off_f
                                        AND ep.flg_transf_type = pk_hand_off.g_flg_transf_i
                                        AND ep.dt_comp_tstz > epr.dt_comp_tstz),
                                     pd.dt_end)) dt_min_end,
                           p.num_members
                      FROM epis_prof_resp epr
                      JOIN prof_team_det pd
                        ON pd.id_professional = epr.id_prof_to
                      JOIN prof_team p
                        ON p.id_prof_team = pd.id_prof_team
                      JOIN prof_cat pc
                        ON pc.id_professional = epr.id_prof_to
                     WHERE epr.id_episode = i_episode
                       AND epr.flg_status = pk_hand_off.g_hand_off_f
                       AND epr.flg_transf_type = pk_hand_off.g_flg_transf_i
                       AND p.flg_status = pk_alert_constant.g_team_active
                       AND (p.id_department = l_id_department OR p.id_software = l_id_software)
                       AND pc.id_institution = i_prof.institution
                       AND pd.dt_begin <= current_timestamp
                       AND epr.dt_comp_tstz <= pd.dt_end
                       AND nvl((SELECT MIN(ep.dt_comp_tstz)
                                 FROM epis_prof_resp ep
                                 JOIN prof_cat pc2
                                   ON pc2.id_professional = ep.id_prof_to
                                WHERE ep.id_episode = i_episode
                                  AND pc2.id_category = pc.id_category
                                  AND ep.flg_status = pk_hand_off.g_hand_off_f
                                  AND ep.flg_transf_type = pk_hand_off.g_flg_transf_i
                                  AND ep.dt_comp_tstz > epr.dt_comp_tstz),
                               p.dt_begin_tstz) >= p.dt_begin_tstz)
             GROUP BY id_prof_team, prof_team_name, with_notes, effec_date, num_members
             ORDER BY dt_begin DESC, prof_team_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_teams);
            RETURN error_handling_ext(i_lang,
                                      'GET_EPIS_PROF_RESP_TEAM',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
    END get_epis_prof_resp_team;

    /*******************************************************************************************
    * list of team professionals. This is already present in function get_prof_team_det but it also
    * does other stuff. Just needed a simple list of a team professionals
    *
    * @param i_lang            language ID
    * @param i_prof            professional, software and institution ids
    * @param i_id_prof_team    team ID
    *
    * @param o_profs           List of profs
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  Telmo
    * @version                 2.5.0.4 
    * @since                   19-06-2009
    **********************************************************************************************/
    FUNCTION get_prof_team_profs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_prof_team IN prof_team.id_prof_team%TYPE,
        o_profs        OUT table_number, --pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PROF_TEAM_PROFS';
    BEGIN
        g_error := 'GET PROF LIST';
        SELECT pd.id_professional
          BULK COLLECT
          INTO o_profs
          FROM prof_team_det pd
          JOIN professional p
            ON p.id_professional = pd.id_professional
         WHERE pd.id_prof_team = i_id_prof_team
           AND pd.flg_available = pk_alert_constant.g_yes
           AND pd.flg_status = pk_alert_constant.g_active;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prof_team_profs;

    /*******************************************************************************************
    * Gets the department type
    *
    * @param i_flg_type        department type
    *                    
    * @return                  Department type: C - Outpatient, U - EDIS
    *
    * @author                  José Silva
    * @version                 1.0
    * @since                   02-11-2009
    **********************************************************************************************/
    FUNCTION get_department_type(i_flg_type IN department.flg_type%TYPE) RETURN VARCHAR2 IS
    
        l_dept_type VARCHAR2(10);
    
    BEGIN
    
        IF instr(i_flg_type, g_dpt_outp) > 0
        THEN
            l_dept_type := g_dpt_outp;
        ELSIF instr(i_flg_type, g_dpt_edis) > 0
        THEN
            l_dept_type := g_dpt_edis;
        END IF;
    
        RETURN l_dept_type;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_department_type;

    FUNCTION get_dept_department
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_dept       IN dept.id_dept%TYPE,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
               OBJECTIVO:   Obter lista dos serviços de um dado departamento
               PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                     I_PROF - informação do profissional
                                     I_DEPT - ID do departamento
                            Saida:   O_DEPT - lista de departamentos de uma instituição
                                     O_ERROR - erro
            
              CRIAÇÃO: jsilva 02/05/2007
              NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_DEPARTMENT';
        OPEN o_department FOR
            SELECT id_department,
                   abbreviation,
                   pk_translation.get_translation(i_lang, code_department) department,
                   get_department_type(flg_type) flg_type
              FROM department d
             WHERE id_institution = i_prof.institution
               AND d.id_dept = i_dept
               AND d.flg_available = g_available
             ORDER BY d.rank, department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_department);
            RETURN error_handling_ext(i_lang, 'GET_DEPT_DEPARTMENT', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
            RETURN FALSE;
    END get_dept_department;

    /*******************************************************************************************
    * list of type of teams. 
    *
    * @param i_lang            language ID
    * @param i_prof            professional, software and institution ids
    *
    * @param o_team_type       List of type of teams
    * @param o_error           Error message
    *                    
    * @return                  true or false on success or error
    *
    * @author                  Rita Lopes
    * @version                 2.5.0.4 
    * @since                   03-07-2009
    **********************************************************************************************/
    FUNCTION get_team_types
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_team_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_TEAM_TYPES';
    BEGIN
    
        g_error := 'GET TEAM TYPE';
        OPEN o_team_type FOR
            SELECT tt.id_team_type, pk_translation.get_translation(i_lang, tt.code_team_type) desc_team
              FROM team_type tt, team_type_inst_soft ttis
             WHERE tt.id_team_type = ttis.id_team_type_inst_soft
               AND tt.flg_available = g_available
               AND ttis.flg_available = g_available
               AND nvl(ttis.id_institution, 0) IN (0, i_prof.institution)
               AND nvl(ttis.id_software, 0) IN (0, i_prof.software)
             ORDER BY tt.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_team_types;

    /*******************************************************************************************
    * Gets the professional leader. 
    *
    * @param i_lang            language ID
    * @param i_prof            professional, software and institution ids
    * @param id_prof_team      id team    
    *
    *                    
    * @return                  true or false on success or error
    *
    * @author                  Rita Lopes
    * @version                 2.5.0.4 
    * @since                   05-07-2009
    **********************************************************************************************/
    FUNCTION get_professional_leader
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        id_prof_team IN prof_team.id_prof_team%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'GET_PROFESSIONAL_LEADER';
    
        CURSOR c_prof_leader IS
            SELECT ptd.id_professional
              FROM prof_team_det_ea ptd
             WHERE ptd.id_prof_team = id_prof_team
               AND ptd.flg_leader = g_flg_leader;
    
        r_prof_leader c_prof_leader%ROWTYPE;
    
        l_id_professional prof_team_det_ea.id_professional%TYPE := NULL;
    BEGIN
    
        OPEN c_prof_leader;
        FETCH c_prof_leader
            INTO r_prof_leader;
        IF c_prof_leader%FOUND
        THEN
            l_id_professional := r_prof_leader.id_professional;
        END IF;
        CLOSE c_prof_leader;
    
        RETURN l_id_professional;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_professional_leader;

    FUNCTION get_team_categories
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_category OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_category FOR
            SELECT pk_message.get_message(i_lang, pt.code_profile_template) cat, pt.id_profile_template
              FROM profile_template pt
             WHERE pt.id_profile_template IN (pk_hhc_constant.k_prof_templ_die,
                                              pk_hhc_constant.k_prof_templ_nurse,
                                              pk_hhc_constant.k_prof_templ_ot,
                                              pk_hhc_constant.k_prof_templ_psy,
                                              pk_hhc_constant.k_prof_templ_pt,
                                              pk_hhc_constant.k_prof_templ_phy,
                                              pk_hhc_constant.k_prof_templ_rt,
                                              pk_hhc_constant.k_prof_templ_sw_h,
                                              pk_hhc_constant.k_prof_templ_st)
             ORDER BY 1;
    
        RETURN TRUE;
    
    END get_team_categories;

    FUNCTION get_team_professionals
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        o_professional        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_profile_template_aux profile_template.id_profile_template%TYPE;
    BEGIN
    
        IF i_id_profile_template = pk_hhc_constant.k_prof_templ_pt
        THEN
            l_id_profile_template_aux := pk_hhc_constant.k_prof_templ_pt_c;
        
        END IF;
    
        OPEN o_professional FOR
            SELECT DISTINCT p.id_professional, pk_prof_utils.get_name(i_lang, p.id_professional) prof_name
              FROM prof_dep_clin_serv pdcs
              JOIN dep_clin_serv dcs
                ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
              JOIN department d
                ON dcs.id_department = d.id_department
              JOIN professional p
                ON pdcs.id_professional = p.id_professional
              JOIN prof_profile_template pt
                ON p.id_professional = pt.id_professional
               AND pt.id_institution = pdcs.id_institution
               AND pdcs.flg_status = pk_alert_constant.g_status_selected
             WHERE d.flg_type = pk_hhc_constant.k_dept_flg_type_h
               AND pdcs.id_institution = i_prof.institution
               AND pt.id_profile_template IN (i_id_profile_template, l_id_profile_template_aux)
               AND d.flg_available = pk_alert_constant.g_yes
               AND EXISTS (SELECT 0
                      FROM prof_institution pi
                     WHERE pi.id_prof_institution IN
                           (SELECT MAX(id_prof_institution)
                              FROM prof_institution pr
                             WHERE pr.id_professional = p.id_professional
                               AND pr.id_institution = i_prof.institution)
                       AND flg_state = 'A'
                       AND pi.id_professional = p.id_professional
                       AND pi.id_institution = i_prof.institution)
                  ---
               AND pt.id_profile_template IN (pk_hhc_constant.k_prof_templ_die,
                                              pk_hhc_constant.k_prof_templ_nurse,
                                              pk_hhc_constant.k_prof_templ_ot,
                                              pk_hhc_constant.k_prof_templ_psy,
                                              pk_hhc_constant.k_prof_templ_pt,
                                              pk_hhc_constant.k_prof_templ_phy,
                                              pk_hhc_constant.k_prof_templ_rt,
                                              pk_hhc_constant.k_prof_templ_sw_h,
                                              pk_hhc_constant.k_prof_templ_st,
                                              pk_hhc_constant.k_prof_templ_pt_c);
    
        RETURN TRUE;
    
    END get_team_professionals;

    FUNCTION tf_get_team_det_base
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_tbl_inst  IN table_number,
        i_prof_team IN prof_team.id_prof_team%TYPE
    ) RETURN t_coll_team_prof_det IS
        l_team_prof_det t_coll_team_prof_det;
    BEGIN
    
        SELECT t_rec_team_prof_det(id_professional, prof_name, id_profile_template, cat)
          BULK COLLECT
          INTO l_team_prof_det
          FROM (SELECT DISTINCT ptd.id_professional,
                       pk_prof_utils.get_name(i_lang, ptd.id_professional) prof_name,
                       pt.id_profile_template,
                       pk_message.get_message(i_lang, pt.code_profile_template) cat
                  FROM prof_team_det ptd
                  JOIN prof_profile_template ppt
                    ON ptd.id_professional = ppt.id_professional
                  JOIN profile_template pt
                    ON ppt.id_profile_template = pt.id_profile_template
                 WHERE ptd.id_prof_team = i_prof_team
                   AND ppt.id_institution IN (SELECT /*+ OPT_ESTIMATE(TABLE ttt ROWS=1) */
                                               column_value id_institution
                                                FROM TABLE(i_tbl_inst) ttt)
                   AND ppt.id_profile_template IN (pk_hhc_constant.k_prof_templ_die,
                                                   pk_hhc_constant.k_prof_templ_nurse,
                                                   pk_hhc_constant.k_prof_templ_ot,
                                                   pk_hhc_constant.k_prof_templ_psy,
                                                   pk_hhc_constant.k_prof_templ_pt,
                                                   pk_hhc_constant.k_prof_templ_phy,
                                                   pk_hhc_constant.k_prof_templ_rt,
                                                   pk_hhc_constant.k_prof_templ_sw_h,
                                                   pk_hhc_constant.k_prof_templ_st,
                                                   pk_hhc_constant.k_prof_templ_pt_c))
         ORDER BY cat;
    
        RETURN l_team_prof_det;
    
    END tf_get_team_det_base;

    FUNCTION tf_get_team_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE
    ) RETURN t_coll_team_prof_det IS
        l_team_prof_det t_coll_team_prof_det := t_coll_team_prof_det();
    BEGIN
    
        l_team_prof_det := tf_get_team_det_base(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_tbl_inst  => table_number(i_prof.institution),
                                                i_prof_team => i_prof_team);
    
        RETURN l_team_prof_det;
    
    END tf_get_team_det;

    FUNCTION tf_get_team_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_tbl_inst  IN table_number,
        i_prof_team IN prof_team.id_prof_team%TYPE
    ) RETURN t_coll_team_prof_det IS
        l_team_prof_det t_coll_team_prof_det := t_coll_team_prof_det();
    BEGIN
    
        l_team_prof_det := tf_get_team_det_base(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_tbl_inst  => i_tbl_inst,
                                                i_prof_team => i_prof_team);
    
        RETURN l_team_prof_det;
    
    END tf_get_team_det;

    FUNCTION get_id_prof_team_base
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_tbl_inst   IN table_number
    ) RETURN NUMBER IS
        l_id_epis_hhc epis_hhc_req.id_epis_hhc%TYPE;
        tbl_id        table_number := table_number();
        l_return      NUMBER;
    BEGIN
    
        l_id_epis_hhc := pk_hhc_core.get_id_epis_hhc_by_hhc_req(i_id_hhc_req => i_id_hhc_req);
    
        SELECT pt.id_prof_team
          BULK COLLECT
          INTO tbl_id
          FROM prof_team pt
         WHERE pt.id_episode = l_id_epis_hhc
              --AND pt.id_institution IN (SELECT /*+ OPT_ESTIMATE(TABLE xinst ROWS=1) */
              --                           column_value
              --                            FROM TABLE(i_tbl_inst) xinst)
           AND pt.flg_status = pk_alert_constant.g_active
         ORDER BY pt.dt_register DESC;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_prof_team_base;

    FUNCTION get_id_prof_team
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_hhc_req   IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_id_prof_team OUT prof_team.id_prof_team%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_id_prof_team := get_id_prof_team_base(i_lang       => i_lang, --IN language.id_language%TYPE,
                                                i_prof       => i_prof, --IN profissional,
                                                i_tbl_inst   => table_number(i_prof.institution), --in table_number,
                                                i_id_hhc_req => i_id_hhc_req --IN epis_hhc_req.id_epis_hhc_req%
                                                );
    
        RETURN TRUE;
    
    END get_id_prof_team;

    FUNCTION get_id_prof_team
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_hhc_req   IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_tbl_inst     IN table_number,
        o_id_prof_team OUT prof_team.id_prof_team%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_id_prof_team := get_id_prof_team_base(i_lang       => i_lang, --IN language.id_language%TYPE,
                                                i_prof       => i_prof, --IN profissional,
                                                i_tbl_inst   => i_tbl_inst, --in table_number,
                                                i_id_hhc_req => i_id_hhc_req --IN epis_hhc_req.id_epis_hhc_req%
                                                );
    
        RETURN TRUE;
    
    END get_id_prof_team;

    --this function is used on reports
    FUNCTION get_prof_team_det_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_id_req      IN table_number,
        i_flg_report      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_report_hist IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_team_val        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_hhc      epis_hhc_req.id_epis_hhc%TYPE;
        l_id_prof_team     prof_team.id_prof_team%TYPE;
        l_team_detail      pk_types.cursor_type;
        l_team_detail_hist pk_types.cursor_type;
    
        l_team_det      t_coll_hhc_req_hist := t_coll_hhc_req_hist();
        l_team_det_hist t_coll_hhc_req_hist := t_coll_hhc_req_hist();
        l_descr         VARCHAR2(4000);
        l_type          VARCHAR2(3);
        l_val           VARCHAR2(100);
        l_id_request    epis_hhc_req.id_epis_hhc_req%TYPE;

        l_flg_status    VARCHAR2(0010 CHAR);
        l_exception EXCEPTION;
    BEGIN
        FOR t IN i_tbl_id_req.first() .. i_tbl_id_req.last()
        LOOP
            l_flg_status := pk_hhc_core.get_flg_status(i_id_epis_hhc_req => i_tbl_id_req(t));
        
            IF l_flg_status != pk_alert_constant.g_cancelled
            THEN
                l_flg_status := pk_alert_constant.g_flg_status_report_a;
            END IF;
        
            IF NOT pk_prof_teams.get_id_prof_team(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_hhc_req   => i_tbl_id_req(t),
                                                  o_id_prof_team => l_id_prof_team,
                                                  o_error        => o_error)
            THEN
                RAISE l_exception;
            END IF;
            IF pk_hhc_core.get_prof_team_det(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_prof_team   => l_id_prof_team,
                                             o_team_detail => l_team_detail,
                                             
                                             o_error => o_error)
            THEN
            
                IF i_flg_report = pk_alert_constant.g_yes
                THEN
                    l_descr := pk_message.get_message(i_lang, 'SOCIAL_T124');
                    l_team_det.extend;
                    l_team_det(l_team_det.last()) := t_rec_hhc_req_hist(l_descr,
                                                                        '',
                                                                        pk_alert_constant.g_flg_screen_l0,
                                                                        l_flg_status,
                                                                        i_tbl_id_req(t));
                
                END IF;
                LOOP
                    FETCH l_team_detail
                        INTO l_descr, l_val, l_type;
                    EXIT WHEN l_team_detail%NOTFOUND;
                    l_team_det.extend;
                    l_team_det(l_team_det.last()) := t_rec_hhc_req_hist(l_descr,
                                                                        l_val,
                                                                        l_type,
                                                                        l_flg_status,
                                                                        i_tbl_id_req(t));
                
                END LOOP;
                CLOSE l_team_detail;
            END IF;
        
            IF i_flg_report_hist = pk_alert_constant.g_yes
            THEN
                IF pk_hhc_core.get_prof_team_det_hist(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_prof_team   => l_id_prof_team,
                                                      o_team_detail => l_team_detail_hist,
                                                      o_error       => o_error)
                THEN
                    LOOP
                        FETCH l_team_detail_hist
                            INTO l_descr, l_val, l_type;
                        EXIT WHEN l_team_detail_hist%NOTFOUND;
                        l_team_det_hist.extend;
                        l_team_det_hist(l_team_det_hist.last()) := t_rec_hhc_req_hist(l_descr,
                                                                                      l_val,
                                                                                      l_type,
                                                                                      l_flg_status,
                                                                                      i_tbl_id_req(t));
                    
                    END LOOP;
                    CLOSE l_team_detail_hist;
                END IF;
            END IF;
        END LOOP;
    
        OPEN o_team_val FOR
            SELECT descr, val, tipo AS TYPE, flg_status, id_request
              FROM TABLE(l_team_det)
            UNION ALL
            SELECT descr, val, tipo AS TYPE, flg_status, id_request
              FROM TABLE(l_team_det_hist);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_team_val);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_team_val);
            RETURN TRUE;
    END get_prof_team_det_hist;

    FUNCTION tf_get_team_det_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_team_hist IN prof_team_det_hist.id_prof_team_hist%TYPE
    ) RETURN t_coll_team_prof_det IS
        l_team_prof_det t_coll_team_prof_det;
    BEGIN
    
        SELECT t_rec_team_prof_det(id_professional, prof_name, id_profile_template, cat)
          BULK COLLECT
          INTO l_team_prof_det
          FROM (SELECT ptd.id_professional,
                       pk_prof_utils.get_name(i_lang, ptd.id_professional) prof_name,
                       pt.id_profile_template,
                       pk_message.get_message(i_lang, pt.code_profile_template) cat
                  FROM prof_team_det_hist ptd
                  JOIN prof_profile_template ppt
                    ON ptd.id_professional = ppt.id_professional
                  JOIN profile_template pt
                    ON ppt.id_profile_template = pt.id_profile_template
                 WHERE ptd.id_prof_team_hist = i_id_prof_team_hist
                   AND ppt.id_profile_template IN (pk_hhc_constant.k_prof_templ_die,
                                                   pk_hhc_constant.k_prof_templ_nurse,
                                                   pk_hhc_constant.k_prof_templ_ot,
                                                   pk_hhc_constant.k_prof_templ_psy,
                                                   pk_hhc_constant.k_prof_templ_pt,
                                                   pk_hhc_constant.k_prof_templ_phy,
                                                   pk_hhc_constant.k_prof_templ_rt,
                                                   pk_hhc_constant.k_prof_templ_sw_h,
                                                   pk_hhc_constant.k_prof_templ_st,
                                                   pk_hhc_constant.k_prof_templ_pt_c)
                   AND ppt.id_institution = i_prof.institution)
         ORDER BY cat;
    
        RETURN l_team_prof_det;
    
    END tf_get_team_det_hist;

    --get category of professional - hhc
    FUNCTION get_hhc_prof_category
    (
        i_lang            IN language.id_language%TYPE,
        i_id_profissional IN prof_profile_template.id_professional%TYPE,
        i_id_institution  IN prof_profile_template.id_institution%TYPE
    ) RETURN sys_message.desc_message%TYPE IS
        l_category sys_message.desc_message%TYPE;
    BEGIN
    
        SELECT pk_message.get_message(i_lang, pt.code_profile_template)
          INTO l_category
          FROM prof_profile_template ppt
          JOIN profile_template pt
            ON pt.id_profile_template = ppt.id_profile_template
         WHERE ppt.id_professional = i_id_profissional
           AND ppt.id_institution = i_id_institution
           AND ppt.id_profile_template IN (pk_hhc_constant.k_prof_templ_die,
                                           pk_hhc_constant.k_prof_templ_nurse,
                                           pk_hhc_constant.k_prof_templ_ot,
                                           pk_hhc_constant.k_prof_templ_psy,
                                           pk_hhc_constant.k_prof_templ_pt,
                                           pk_hhc_constant.k_prof_templ_phy,
                                           pk_hhc_constant.k_prof_templ_rt,
                                           pk_hhc_constant.k_prof_templ_sw_h,
                                           pk_hhc_constant.k_prof_templ_st,
                                           pk_hhc_constant.k_prof_templ_pt_c);
    
        RETURN l_category;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_hhc_prof_category;

    FUNCTION set_team_end_of_activity
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_hhc_req IN NUMBER,
        i_dt_end  IN prof_team.dt_end_tstz%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_prof_team NUMBER;
        l_dt_end       prof_team.dt_end_tstz%TYPE;
        l_rowids       table_varchar := table_varchar();
        l_exception EXCEPTION;
    BEGIN
    
        l_id_prof_team := get_id_prof_team_base(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_hhc_req => i_hhc_req,
                                                i_tbl_inst   => table_number(i_prof.institution));
        l_dt_end       := i_dt_end; -- can be null
    
        IF l_id_prof_team IS NOT NULL
        THEN
        
            g_error := 'SET PROF TEAM HISTORY';
            IF NOT
                set_prof_team_hist(i_lang => i_lang, i_prof => i_prof, i_prof_team => l_id_prof_team, o_error => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            ts_prof_team.upd(id_prof_team_in        => l_id_prof_team,
                             id_department_in       => NULL,
                             prof_team_name_in      => NULL,
                             dt_begin_tstz_in       => NULL,
                             dt_end_tstz_in         => l_dt_end,
                             dt_end_tstz_nin        => FALSE,
                             notes_in               => NULL,
                             notes_nin              => FALSE,
                             id_prof_register_in    => i_prof.id,
                             dt_register_in         => g_sysdate_tstz,
                             id_software_in         => NULL,
                             id_institution_in      => NULL,
                             num_members_in         => NULL,
                             id_prof_team_leader_in => NULL,
                             rows_out               => l_rowids);
        
            g_error := 'SET PROF TEAM EA';
            IF NOT
                set_prof_team_ea(i_lang => i_lang, i_prof => i_prof, i_prof_team => l_id_prof_team, o_error => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'set_team_end_of_activity',
                                      g_error || ' / ' || o_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            RAISE;
    END set_team_end_of_activity;

BEGIN

    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_prof_teams;
/