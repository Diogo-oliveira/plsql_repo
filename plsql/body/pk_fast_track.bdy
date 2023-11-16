/*-- Last Change Revision: $Rev: 2054030 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2023-01-03 13:49:27 +0000 (ter, 03 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_fast_track IS

    g_package_owner VARCHAR2(32);
    g_package_name  VARCHAR2(32);

    /**********************************************************************************************
    * Checks the permission to disable the fast track
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution IDs
    * @param i_fast_track             fast track ID
    *
    * @return                         Permission to enable/disable the fast track: Y - yes, N - no
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/15
    **********************************************************************************************/
    FUNCTION get_fast_track_permission
    (
        i_prof_cat       IN category.flg_type%TYPE,
        i_flg_permission IN fast_track.flg_permission%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF i_flg_permission IS NULL
        THEN
            RETURN g_yes;
        ELSE
            IF instr(i_flg_permission, i_prof_cat) > 0
            THEN
                RETURN g_yes;
            ELSE
                RETURN g_no;
            END IF;
        END IF;
    
    END get_fast_track_permission;

    FUNCTION get_fast_track_permission
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_fast_track IN fast_track.id_fast_track%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_permission fast_track.flg_permission%TYPE;
        l_prof_cat       category.flg_type%TYPE;
    
    BEGIN
    
        SELECT flg_permission
          INTO l_flg_permission
          FROM fast_track
         WHERE id_fast_track = i_fast_track;
    
        IF l_flg_permission IS NULL
        THEN
            RETURN g_yes;
        ELSE
            l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        
            IF instr(l_flg_permission, l_prof_cat) > 0
            THEN
                RETURN g_yes;
            ELSE
                RETURN g_no;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_no;
    END get_fast_track_permission;

    /**********************************************************************************************
    * Checks the permission to disable the fast track
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution IDs
    * @param i_fast_track             fast track ID
    * @param i_flg_activate_disable     'A' - Activate action, 'D' - Disable action
    *
    * @return                         Permission to enable/disable the fast track: Y - yes, N - no
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/15
    **********************************************************************************************/
    FUNCTION get_fast_track_permission
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_triage            IN triage.id_triage%TYPE,
        i_flg_activation_type  IN fast_track_institution.flg_activation_type%TYPE,
        i_eft_id_fast_track    IN epis_fast_track.id_fast_track%TYPE,
        i_eft_flg_status       IN epis_fast_track.flg_status%TYPE,
        i_flg_activate_disable IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(1);
    
    BEGIN
    
        IF i_flg_activate_disable = g_fast_track_active
           AND (i_eft_id_fast_track IS NULL OR i_eft_flg_status = g_fast_track_disabled)
        THEN
            -- Check if profissional has permission to manually activate at least one of the fast tracks
            BEGIN
                SELECT g_yes
                  INTO l_ret
                  FROM (SELECT /*+opt_estimate (table t rows=1)*/
                         t.flg_action_active
                          FROM TABLE(tf_fast_track_cfg(i_lang, i_prof)) t
                         WHERE t.flg_action_active = pk_alert_constant.g_active
                           AND rownum = 1);
            EXCEPTION
                WHEN no_data_found THEN
                    l_ret := g_no;
            END;
        ELSIF i_flg_activate_disable = g_fast_track_disabled
              AND i_eft_id_fast_track IS NOT NULL
              AND i_eft_flg_status = g_fast_track_active
        THEN
            -- Check permission to disable
            BEGIN
                SELECT /*+opt_estimate (table t rows=1)*/
                 g_yes
                  INTO l_ret
                  FROM TABLE(tf_fast_track_cfg(i_lang, i_prof, i_id_triage, i_flg_activation_type, i_eft_id_fast_track)) t
                 WHERE t.flg_action_active = pk_alert_constant.g_active;
            EXCEPTION
                WHEN no_data_found THEN
                    l_ret := g_no;
            END;
        ELSE
            l_ret := g_no;
        END IF;
    
        RETURN l_ret;
    
    END get_fast_track_permission;

    FUNCTION set_epis_fast_track_int
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_triage            IN triage.id_triage%TYPE,
        i_id_epis_triage       IN epis_triage.id_epis_triage%TYPE,
        i_flg_epis_ft          IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_activation_type  IN epis_fast_track.flg_activation_type%TYPE,
        i_flg_type             IN epis_fast_track.flg_type%TYPE,
        i_id_fast_track        IN fast_track.id_fast_track%TYPE,
        i_tb_fast_track_reason IN table_number,
        i_notes                IN epis_fast_track.notes_enable%TYPE,
        i_ft_status            IN epis_fast_track.flg_status%TYPE,
        i_ft_dt_activation     IN epis_fast_track.dt_activation%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_current_fast_track      fast_track.id_fast_track%TYPE;
        l_id_fast_track           fast_track.id_fast_track%TYPE;
        l_rec_eft                 epis_fast_track%ROWTYPE;
        l_tab_eft                 ts_epis_fast_track.epis_fast_track_tc;
        l_rows                    table_varchar;
        l_count                   NUMBER;
        l_exception               EXCEPTION;
        l_id_epis_fast_track_hist epis_fast_track_hist.id_epis_fast_track_hist%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_error        := 'GET CURRENT FAST TRACK';
        BEGIN
            SELECT eft.id_fast_track
              INTO l_current_fast_track
              FROM epis_fast_track eft
             WHERE eft.id_epis_triage = i_id_epis_triage
               AND eft.flg_status != g_fast_track_disabled;
        EXCEPTION
            WHEN no_data_found THEN
                l_current_fast_track := NULL;
        END;
    
        IF l_current_fast_track IS NULL
           AND i_flg_epis_ft = g_yes
        THEN
            IF i_flg_activation_type = g_ft_manual_activation
               AND i_id_fast_track IS NOT NULL
            THEN
                -- Manual activation
                l_id_fast_track := i_id_fast_track;
            
            ELSIF i_flg_activation_type = g_ft_triggered_activation
                  AND i_id_triage IS NOT NULL
            THEN
                -- Triggered activation
                g_error := 'GET_TRIAGE_FAST_TRACK';
                IF NOT get_triage_fast_track(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_id_triage     => i_id_triage,
                                             o_id_fast_track => l_id_fast_track,
                                             o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            ELSE
                g_error := 'INVALID PARAMETERS PK_FAST_TRACK.SET_EPIS_FAST_TRACK_INT: i_id_epis_triage: ' ||
                           i_id_epis_triage || ', i_id_triage: ' || i_id_triage || ', i_flg_activation_type: ' ||
                           i_flg_activation_type || ', i_id_fast_track: ' || i_id_fast_track;
                RAISE l_exception;
            END IF;
        
            IF l_id_fast_track IS NOT NULL
            THEN
                SELECT COUNT(1)
                  INTO l_count
                  FROM epis_fast_track eft
                 WHERE eft.id_epis_triage = i_id_epis_triage;
            
                l_rec_eft.id_epis_triage := i_id_epis_triage;
                l_rec_eft.id_fast_track := l_id_fast_track;
                l_rec_eft.flg_status := g_fast_track_active;
                l_rec_eft.id_prof_disable := NULL;
                l_rec_eft.dt_disable := NULL;
                l_rec_eft.id_fast_track_disable := NULL;
                l_rec_eft.notes_disable := NULL;
                l_rec_eft.flg_type := i_flg_type;
                l_rec_eft.flg_activation_type := i_flg_activation_type;
                l_rec_eft.dt_enable := g_sysdate_tstz;
                l_rec_eft.id_prof_enable := i_prof.id;
                l_rec_eft.notes_enable := i_notes;
                l_rec_eft.dt_activation := i_ft_dt_activation; -- EMR-4797
                l_tab_eft(l_rec_eft.id_epis_triage) := l_rec_eft;
            
                IF l_count = 0
                THEN
                    g_error := 'INSERT EPIS_FAST_TRACK';
                    ts_epis_fast_track.ins(rec_in => l_rec_eft, rows_out => l_rows);
                ELSE
                    ts_epis_fast_track.upd(col_in => l_tab_eft, ignore_if_null_in => FALSE, rows_out => l_rows);
                END IF;
            
                IF i_tb_fast_track_reason.exists(1)
                THEN
                    g_error := 'call set_fast_track_reason';
                    IF NOT set_fast_track_reason(i_lang                 => i_lang,
                                                 i_prof                 => i_prof,
                                                 i_id_epis_triage       => i_id_epis_triage,
                                                 i_tb_fast_track_reason => i_tb_fast_track_reason,
                                                 i_flg_add_cancel       => pk_alert_constant.g_active,
                                                 o_error                => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
                l_id_epis_fast_track_hist := ts_epis_fast_track_hist.next_key;
                ts_epis_fast_track_hist.ins(id_epis_fast_track_hist_in => l_id_epis_fast_track_hist,
                                            id_epis_triage_in          => l_rec_eft.id_epis_triage,
                                            id_fast_track_in           => l_rec_eft.id_fast_track,
                                            flg_status_in              => l_rec_eft.flg_status,
                                            id_prof_disable_in         => l_rec_eft.id_prof_disable,
                                            dt_disable_in              => l_rec_eft.dt_disable,
                                            id_fast_track_disable_in   => l_rec_eft.id_fast_track_disable,
                                            notes_disable_in           => l_rec_eft.notes_disable,
                                            flg_type_in                => l_rec_eft.flg_type,
                                            flg_activation_type_in     => l_rec_eft.flg_activation_type,
                                            dt_enable_in               => l_rec_eft.dt_enable,
                                            id_prof_enable_in          => l_rec_eft.id_prof_enable,
                                            notes_enable_in            => l_rec_eft.notes_enable,
                                            dt_activation_in           => l_rec_eft.dt_activation, --EMR-4797
                                            rows_out                   => l_rows);
            
                IF i_tb_fast_track_reason.exists(1)
                THEN
                    g_error := 'call set_fast_track_reason_hist';
                    IF NOT set_fast_track_reason_hist(i_lang                    => i_lang,
                                                      i_prof                    => i_prof,
                                                      i_id_epis_triage          => l_rec_eft.id_epis_triage,
                                                      i_id_epis_fast_track_hist => l_id_epis_fast_track_hist,
                                                      i_flg_add_cancel          => pk_alert_constant.g_active,
                                                      o_error                   => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
                l_current_fast_track := l_id_fast_track;
            END IF;
        END IF;
    
        l_rows  := table_varchar();
        g_error := 'UPDATE EPISODE';
        /* <DENORM Fábio> */
        ts_episode.upd(id_episode_in     => i_id_episode,
                       id_fast_track_in  => l_current_fast_track,
                       id_fast_track_nin => FALSE,
                       rows_out          => l_rows);
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPISODE', l_rows, o_error, table_varchar('ID_FAST_TRACK'));
    
        g_error := 'UPDATE EPIS_INFO';
        IF NOT set_epis_info_fast_track(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => i_id_episode,
                                        o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_EPIS_FAST_TRACK_INT',
                                                     o_error);
    END set_epis_fast_track_int;

    /**********************************************************************************************
    * Sets the triggered fast track to given episode
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_id_triage              triage ID
    * @param i_id_epis_triage         episode triage id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Nuno Alves
    * @version                        1.0 
    * @since                          2015/11/12
    **********************************************************************************************/
    FUNCTION set_epis_fast_track_auto
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_triage      IN triage.id_triage%TYPE,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL SET_EPIS_FAST_TRACK_INT';
        IF NOT set_epis_fast_track_int(i_lang                 => i_lang,
                                       i_prof                 => i_prof,
                                       i_id_episode           => i_id_episode,
                                       i_id_triage            => i_id_triage,
                                       i_id_epis_triage       => i_id_epis_triage,
                                       i_flg_epis_ft          => pk_alert_constant.g_yes,
                                       i_flg_activation_type  => g_ft_triggered_activation,
                                       i_flg_type             => g_eft_flg_type_primary,
                                       i_id_fast_track        => NULL,
                                       i_tb_fast_track_reason => NULL,
                                       i_notes                => NULL,
                                       i_ft_status            => g_fast_track_reason_active,
                                       i_ft_dt_activation     => NULL,
                                       o_error                => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_EPIS_FAST_TRACK_AUTO',
                                                     o_error);
    END set_epis_fast_track_auto;

    /**********************************************************************************************
    * Sets a fast track manually to a given episode
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_id_triage              triage ID
    * @param i_id_epis_triage         episode triage id
    * @param i_id_fast_track          Fast track to be activated
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Nuno Alves
    * @version                        1.0 
    * @since                          2015/11/12
    **********************************************************************************************/
    FUNCTION set_epis_fast_track_manual
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_triage       IN epis_triage.id_epis_triage%TYPE,
        i_id_fast_track        IN fast_track.id_fast_track%TYPE,
        i_flg_type             IN epis_fast_track.flg_type%TYPE,
        i_tb_fast_track_reason IN table_number,
        i_notes                IN epis_fast_track.notes_enable%TYPE,
        i_ft_status            IN epis_fast_track.flg_status%TYPE DEFAULT 'A',
        i_ft_dt_activation     IN VARCHAR2 DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ft_status        epis_fast_track.flg_status%TYPE := g_fast_track_reason_active;
        l_ft_dt_activation epis_fast_track.dt_activation%TYPE;
        l_exception        EXCEPTION;
    
    BEGIN
    
        l_ft_dt_activation := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_timezone  => NULL,
                                                            i_mask      => 'YYYYMMDDHH24MI',
                                                            i_timestamp => i_ft_dt_activation);
    
        g_error := 'CALL SET_EPIS_FAST_TRACK_INT';
        IF NOT set_epis_fast_track_int(i_lang                 => i_lang,
                                       i_prof                 => i_prof,
                                       i_id_episode           => i_id_episode,
                                       i_id_triage            => NULL,
                                       i_id_epis_triage       => i_id_epis_triage,
                                       i_flg_epis_ft          => pk_alert_constant.g_yes,
                                       i_flg_activation_type  => g_ft_manual_activation,
                                       i_flg_type             => i_flg_type,
                                       i_id_fast_track        => i_id_fast_track,
                                       i_tb_fast_track_reason => i_tb_fast_track_reason,
                                       i_notes                => i_notes,
                                       i_ft_status            => l_ft_status,
                                       i_ft_dt_activation     => l_ft_dt_activation,
                                       o_error                => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_EPIS_FAST_TRACK_MANUAL',
                                                     o_error);
    END set_epis_fast_track_manual;

    /**********************************************************************************************
    * Sets the triggered fast track to given episode
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_id_triage              triage ID
    * @param i_id_epis_triage         episode triage id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2008/05/07
    **********************************************************************************************/
    FUNCTION set_epis_fast_track
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_triage      IN triage.id_triage%TYPE,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        IF NOT set_epis_fast_track_int(i_lang                 => i_lang,
                                       i_prof                 => i_prof,
                                       i_id_episode           => i_id_episode,
                                       i_id_triage            => i_id_triage,
                                       i_id_epis_triage       => i_id_epis_triage,
                                       i_flg_epis_ft          => pk_alert_constant.g_no,
                                       i_flg_activation_type  => NULL,
                                       i_flg_type             => NULL,
                                       i_id_fast_track        => NULL,
                                       i_tb_fast_track_reason => NULL,
                                       i_notes                => NULL,
                                       i_ft_status            => g_fast_track_reason_active,
                                       i_ft_dt_activation     => NULL,
                                       o_error                => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_EPIS_FAST_TRACK',
                                                     o_error);
    END set_epis_fast_track;

    /**********************************************************************************************
    * Sets the triggered fast track to given episode
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_id_triage              triage ID
    * @param i_id_epis_triage         episode triage id
    * @param i_flg_epis_ft            Insert in epis_fast_track should be made: Y - yes; N - No
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2008/05/07
    **********************************************************************************************/
    FUNCTION set_epis_fast_track
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_triage      IN triage.id_triage%TYPE,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        i_flg_epis_ft    IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_fast_track IS
            SELECT ft.id_fast_track
              FROM fast_track ft, fast_track_institution fti
             WHERE ft.id_fast_track = fti.id_fast_track
               AND fti.id_institution IN (i_prof.institution, 0)
               AND fti.id_triage = i_id_triage
               AND ft.flg_available = g_yes
               AND NOT EXISTS (SELECT 0
                      FROM epis_fast_track ef
                     WHERE ef.id_epis_triage = i_id_epis_triage
                       AND ef.flg_status = g_fast_track_disabled)
             ORDER BY fti.id_institution, ft.rank;
    
        l_id_fast_track fast_track.id_fast_track%TYPE;
        l_rows          table_varchar;
        l_exception     EXCEPTION;
    
    BEGIN
    
        g_error := 'GET FAST TRACK';
        OPEN c_fast_track;
        FETCH c_fast_track
            INTO l_id_fast_track;
        CLOSE c_fast_track;
    
        IF l_id_fast_track IS NOT NULL
           AND i_flg_epis_ft = g_yes
        THEN
            g_error := 'INSERT EPIS_FAST_TRACK';
            ts_epis_fast_track.ins(id_epis_triage_in => i_id_epis_triage,
                                   id_fast_track_in  => l_id_fast_track,
                                   flg_status_in     => g_fast_track_active,
                                   rows_out          => l_rows);
        END IF;
    
        l_rows  := table_varchar();
        g_error := 'UPDATE EPISODE';
        /* <DENORM Fábio> */
        ts_episode.upd(id_episode_in     => i_id_episode,
                       id_fast_track_in  => l_id_fast_track,
                       id_fast_track_nin => FALSE,
                       rows_out          => l_rows);
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPISODE', l_rows, o_error, table_varchar('ID_FAST_TRACK'));
    
        g_error := 'UPDATE EPIS_INFO';
        IF NOT set_epis_info_fast_track(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => i_id_episode,
                                        o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_EPIS_FAST_TRACK',
                                                     o_error);
    END set_epis_fast_track;

    /**********************************************************************************************
    * Sets the epis info fast track to columns
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/09/15
    **********************************************************************************************/
    FUNCTION set_epis_info_fast_track
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_epis_transfer VARCHAR2(1);
        l_triage_color      triage_color.color%TYPE;
        l_rows_ei           table_varchar;
        l_id_fast_track     fast_track.id_fast_track%TYPE;
    
    BEGIN
    
        g_error             := 'CHECK EPIS_TRANSFER';
        l_flg_epis_transfer := pk_transfer_institution.check_epis_transfer(i_id_episode);
    
        g_error := 'SELECT FROM TRIAGE_COLOR';
        BEGIN
            SELECT tc.color
              INTO l_triage_color
              FROM (SELECT etr2.*
                      FROM epis_triage etr2
                     ORDER BY etr2.dt_end_tstz DESC) et
              JOIN triage_color tc
                ON et.id_triage_color = tc.id_triage_color
             WHERE et.id_episode = i_id_episode
               AND rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                l_triage_color := NULL;
        END;
    
        g_error := 'SELECT ID_FAST_TRACK';
        BEGIN
            SELECT epi.id_fast_track
              INTO l_id_fast_track
              FROM episode epi
             WHERE epi.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_fast_track := NULL;
        END;
    
        g_error := 'UPDATE EPIS_INFO';
        ts_epis_info.upd(id_episode_in        => i_id_episode,
                         fast_track_icon_in   => get_fast_track_icon(i_lang       => i_lang,
                                                                     i_prof       => i_prof,
                                                                     i_fast_track => l_id_fast_track,
                                                                     i_type       => CASE l_flg_epis_transfer
                                                                                         WHEN 1 THEN
                                                                                          g_icon_ft_transfer
                                                                                         ELSE
                                                                                          g_icon_ft
                                                                                     END),
                         fast_track_icon_nin  => FALSE,
                         fast_track_desc_in   => get_fast_track_desc(i_lang       => i_lang,
                                                                     i_prof       => i_prof,
                                                                     i_fast_track => l_id_fast_track,
                                                                     i_type       => CASE l_flg_epis_transfer
                                                                                         WHEN 1 THEN
                                                                                          g_icon_ft_transfer
                                                                                         ELSE
                                                                                          g_icon_ft
                                                                                     END),
                         fast_track_desc_nin  => FALSE,
                         fast_track_color_in  => CASE l_triage_color
                                                     WHEN '0xFFFFFF' THEN
                                                      '0x787864'
                                                     ELSE
                                                      '0xFFFFFF'
                                                 END,
                         fast_track_color_nin => FALSE,
                         rows_out             => l_rows_ei);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FAST_TRACK_ICON',
                                                                      'FAST_TRACK_DESC',
                                                                      'FAST_TRACK_COLOR'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_EPIS_INFO_FAST_TRACK',
                                                     o_error);
    END set_epis_info_fast_track;

    /**********************************************************************************************
    * Disables the triggered fast track to given episode
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param i_id_epis_triage         Triage made to the episode (it assumes the last one if it is NULL)
    * @param i_fast_track_disable     Disable reason
    * @param i_notes                  Disable notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION set_fast_track_disable
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_triage       IN epis_triage.id_epis_triage%TYPE,
        i_tb_fast_track_reason IN table_number,
        i_notes                IN epis_fast_track.notes_disable%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_triage epis_triage.id_epis_triage%TYPE;
        l_exception      EXCEPTION;
        l_error          t_error_out;
        l_rec_eft        epis_fast_track%ROWTYPE;
        l_rows           table_varchar;
    
        CURSOR c_epis_triage IS
            SELECT et.id_epis_triage
              FROM epis_triage et
             WHERE et.id_episode = i_id_episode
             ORDER BY et.dt_end_tstz DESC;
    
        l_id_epis_fast_track_hist epis_fast_track_hist.id_epis_fast_track_hist%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET EPIS_TRIAGE';
        OPEN c_epis_triage;
        FETCH c_epis_triage
            INTO l_id_epis_triage;
        CLOSE c_epis_triage;
    
        -- Set the needed fields according to the disabled state
        l_rec_eft.id_epis_triage  := nvl(i_id_epis_triage, l_id_epis_triage);
        l_rec_eft.flg_status      := g_fast_track_disabled;
        l_rec_eft.id_prof_disable := i_prof.id;
        l_rec_eft.dt_disable      := g_sysdate_tstz;
        --l_rec_eft.id_fast_track_disable := i_fast_track_disable;
        l_rec_eft.notes_disable := i_notes;
    
        g_error := 'UPDATE EPIS_FAST_TRACK';
    
        ts_epis_fast_track.upd(id_epis_triage_in  => l_rec_eft.id_epis_triage,
                               flg_status_in      => l_rec_eft.flg_status,
                               id_prof_disable_in => l_rec_eft.id_prof_disable,
                               dt_disable_in      => l_rec_eft.dt_disable,
                               --id_fast_track_disable_in => l_rec_eft.id_fast_track_disable,
                               notes_disable_in  => l_rec_eft.notes_disable,
                               notes_disable_nin => FALSE,
                               notes_enable_in   => NULL,
                               notes_enable_nin  => FALSE,
                               rows_out          => l_rows);
    
        g_error := 'call set_fast_track_reason';
        IF NOT set_fast_track_reason(i_lang                 => i_lang,
                                     i_prof                 => i_prof,
                                     i_id_epis_triage       => nvl(i_id_epis_triage, l_id_epis_triage),
                                     i_tb_fast_track_reason => i_tb_fast_track_reason,
                                     i_flg_add_cancel       => pk_alert_constant.g_cancelled,
                                     o_error                => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET EPIS_FAST_TRACK';
        SELECT *
          INTO l_rec_eft
          FROM epis_fast_track eft
         WHERE eft.id_epis_triage = nvl(i_id_epis_triage, l_id_epis_triage);
    
        l_id_epis_fast_track_hist := ts_epis_fast_track_hist.next_key;
    
        g_error := 'INSERT INTO EPIS_FAST_TRACK_HIST';
        ts_epis_fast_track_hist.ins(id_epis_fast_track_hist_in => l_id_epis_fast_track_hist,
                                    id_epis_triage_in          => l_rec_eft.id_epis_triage,
                                    id_fast_track_in           => l_rec_eft.id_fast_track,
                                    flg_status_in              => l_rec_eft.flg_status,
                                    id_prof_disable_in         => l_rec_eft.id_prof_disable,
                                    dt_disable_in              => l_rec_eft.dt_disable,
                                    --id_fast_track_disable_in => l_rec_eft.id_fast_track_disable,
                                    notes_disable_in       => l_rec_eft.notes_disable,
                                    flg_type_in            => l_rec_eft.flg_type,
                                    flg_activation_type_in => l_rec_eft.flg_activation_type,
                                    dt_enable_in           => l_rec_eft.dt_enable,
                                    id_prof_enable_in      => l_rec_eft.id_prof_enable,
                                    rows_out               => l_rows);
    
        g_error := 'call set_fast_track_reason_hist';
        IF NOT set_fast_track_reason_hist(i_lang                    => i_lang,
                                          i_prof                    => i_prof,
                                          i_id_epis_triage          => l_rec_eft.id_epis_triage,
                                          i_id_epis_fast_track_hist => l_id_epis_fast_track_hist,
                                          i_flg_add_cancel          => pk_alert_constant.g_cancelled,
                                          o_error                   => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_rec_eft.id_epis_triage = l_id_epis_triage
        THEN
            g_error := 'UPDATE EPISODE';
            l_rows  := table_varchar();
            ts_episode.upd(id_episode_in     => i_id_episode,
                           id_fast_track_in  => NULL,
                           id_fast_track_nin => FALSE,
                           rows_out          => l_rows);
        
            t_data_gov_mnt.process_update(i_lang, i_prof, 'EPISODE', l_rows, o_error, table_varchar('ID_FAST_TRACK'));
            l_rows := table_varchar();
        
            g_error := 'UPDATE EPIS_INFO';
            IF NOT set_epis_info_fast_track(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_id_episode,
                                            o_error      => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error || ' / ' || l_error.err_desc,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_FAST_TRACK_DISABLE',
                                                     o_error);
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_FAST_TRACK_DISABLE',
                                                     o_error);
    END set_fast_track_disable;

    /**********************************************************************************************
    * Gets the fast track icon to place in the patients grid.
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_fast_track             fast track ID   
    * @param i_type                   icon type: F - fast track; T - fast track + transfer institution  
    *
    * @return                         fast track icon
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2008/05/08
    **********************************************************************************************/
    FUNCTION get_fast_track_icon
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_fast_track IN fast_track.id_fast_track%TYPE,
        i_type       IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_ft_icon fast_track.icon%TYPE;
    
    BEGIN
        BEGIN
            SELECT (SELECT ft.icon
                      FROM fast_track ft
                     WHERE ft.id_fast_track = i_fast_track)
              INTO l_ft_icon
              FROM dual;
        EXCEPTION
            WHEN no_data_found THEN
                l_ft_icon := NULL;
        END;
    
        IF i_type = g_icon_ft
        THEN
            RETURN pk_utils.str_token(l_ft_icon, 1, '|');
        ELSIF i_type = g_icon_ft_transfer
        THEN
            IF i_fast_track IS NOT NULL
            THEN
                RETURN pk_utils.str_token(l_ft_icon, 2, '|');
            ELSE
                RETURN g_icon_transfer;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_fast_track_icon;

    /**********************************************************************************************
    * Gets the fast track icon to place in the patients grid; or, the ESI triage protocol icon.
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_fast_track             fast track ID   
    * @param i_triage_color           triage color ID
    * @param i_type                   icon type: F - fast track; T - fast track + transfer institution  
    *
    * @return                         Fast track icon or ESI protocol icon
    *                        
    * @author                         José Brito
    * @version                        2.6 
    * @since                          2010/01/12
    **********************************************************************************************/
    FUNCTION get_fast_track_icon
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis      IN episode.id_episode%TYPE,
        i_fast_track   IN fast_track.id_fast_track%TYPE,
        i_triage_color IN triage_color.id_triage_color%TYPE,
        i_type         IN VARCHAR2,
        i_has_transfer IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_ft_icon       fast_track.icon%TYPE;
        l_id_fast_track fast_track.id_fast_track%TYPE;
        l_has_transfer  NUMBER(6);
        l_ft_type       VARCHAR2(1 CHAR);
    
    BEGIN
    
        IF i_has_transfer IS NULL
        THEN
            g_error        := 'CHECK FOR TRANSFER';
            l_has_transfer := pk_transfer_institution.check_epis_transfer(i_id_epis);
        ELSE
            l_has_transfer := i_has_transfer;
        END IF;
    
        IF l_has_transfer > 0
        THEN
            BEGIN
                g_error := 'GET ESI ICON';
                pk_alertlog.log_debug(g_error);
                SELECT telvl.icon_transfer
                  INTO l_ft_icon
                  FROM triage_esi_level telvl
                 WHERE telvl.id_triage_color = i_triage_color
                      -- This icon represents an ESI triage in patients with transfer between institutions,
                      -- so return the icon, only if exists fast track data.
                   AND nvl(l_has_transfer, 0) > 0;
            EXCEPTION
                WHEN no_data_found THEN
                    l_ft_icon := NULL;
            END;
        ELSE
            l_ft_icon := NULL;
        END IF;
    
        IF l_ft_icon IS NULL
        THEN
            IF i_fast_track IS NULL
            THEN
                g_error         := 'GET FAST TRACK ID';
                l_id_fast_track := pk_fast_track.get_epis_fast_track_int(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_id_episode     => i_id_epis,
                                                                         i_id_epis_triage => NULL);
            
            ELSIF i_fast_track = -1
            THEN
                l_id_fast_track := NULL; -- ID_FAST_TRACK sent as -1 in PK_EDIS_TRIAGE.GET_EPIS_TRIAGE.
            ELSE
                l_id_fast_track := i_fast_track;
            END IF;
        
            IF i_type IS NULL
               OR i_has_transfer IS NULL
            THEN
                CASE l_has_transfer
                    WHEN 0 THEN
                        l_ft_type := pk_alert_constant.g_icon_ft;
                    ELSE
                        l_ft_type := pk_alert_constant.g_icon_ft_transfer;
                END CASE; --
            ELSE
                l_ft_type := i_type;
            END IF;
        
            g_error := 'GET FT ICON';
            pk_alertlog.log_debug(g_error);
            l_ft_icon := pk_fast_track.get_fast_track_icon(i_lang, i_prof, l_id_fast_track, l_ft_type);
        END IF;
    
        RETURN l_ft_icon;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_fast_track_icon;

    /**********************************************************************************************
    * Gets the fast track title to place in the patients grid.
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                Episode ID   
    * @param i_fast_track             fast track ID   
    * @param i_type                   desc type: H - header; G - grid  
    *
    * @return                         fast track desc
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2008/05/15
    **********************************************************************************************/
    FUNCTION get_fast_track_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_fast_track IN fast_track.id_fast_track%TYPE,
        i_type       IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_ft_desc    VARCHAR2(50);
        l_fast_track fast_track.id_fast_track%TYPE;
    
        l_error     t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
    
        IF i_fast_track IS NOT NULL
        THEN
            l_fast_track := i_fast_track;
        ELSIF i_episode IS NOT NULL
        THEN
            IF NOT pk_epis_er_law_api.get_fast_track_id(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_episode    => i_episode,
                                                        o_fast_track => l_fast_track,
                                                        o_error      => l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_fast_track IS NOT NULL
        THEN
            IF i_type = g_desc_header
            THEN
                SELECT pk_translation.get_translation(i_lang, ft.code_fast_track_header)
                  INTO l_ft_desc
                  FROM fast_track ft
                 WHERE ft.id_fast_track = l_fast_track;
            ELSIF i_type = g_desc_grid
            THEN
                SELECT pk_translation.get_translation(i_lang, ft.code_fast_track)
                  INTO l_ft_desc
                  FROM fast_track ft
                 WHERE ft.id_fast_track = l_fast_track;
            END IF;
        END IF;
    
        RETURN l_ft_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_fast_track_desc;

    /**********************************************************************************************
    * Gets the fast track title to place in the patients grid.
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_fast_track             fast track ID   
    * @param i_type                   desc type: H - header; G - grid  
    *
    * @return                         fast track desc
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2008/05/15
    **********************************************************************************************/
    FUNCTION get_fast_track_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_fast_track IN fast_track.id_fast_track%TYPE,
        i_type       IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_fast_track.get_fast_track_desc(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_episode    => NULL,
                                                 i_fast_track => i_fast_track,
                                                 i_type       => i_type);
    END get_fast_track_desc;

    /**********************************************************************************************
    * Gets the fast track title to place in the patients grid.
    *   
    * @param i_lang                   language ID
    * @param i_epis_triage            episode triage id   
    * @param i_type                   desc type: H - header; G - grid  
    *
    * @return                         fast track desc
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/12
    **********************************************************************************************/
    FUNCTION get_fast_track_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_epis_triage IN epis_triage.id_epis_triage%TYPE,
        i_type        IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_id_fast_track fast_track.id_fast_track%TYPE;
    
        CURSOR c_fast_track IS
            SELECT ef.id_fast_track
              FROM epis_fast_track ef
             WHERE ef.id_epis_triage = i_epis_triage;
    
    BEGIN
    
        OPEN c_fast_track;
        FETCH c_fast_track
            INTO l_id_fast_track;
        CLOSE c_fast_track;
    
        RETURN pk_fast_track.get_fast_track_desc(i_lang       => i_lang,
                                                 i_prof       => profissional(0, 0, 0),
                                                 i_fast_track => l_id_fast_track,
                                                 i_type       => i_type);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_fast_track_desc;

    /**********************************************************************************************
    * Gets the fast track title to place in the patients grid.
    *   
    * @param i_lang                   language ID
    * @param i_episfast_track_hist    ep+is_fast_track hist   
    *
    * @return                         fast track desc
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0 
    * @since                          2016/05/30
    **********************************************************************************************/
    FUNCTION get_fast_track_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_fast_track_hist IN epis_fast_track_hist.id_epis_fast_track_hist%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_fast_track fast_track.id_fast_track%TYPE;
    
        CURSOR c_fast_track IS
            SELECT ef.id_fast_track
              FROM epis_fast_track_hist ef
             WHERE ef.id_epis_fast_track_hist = i_fast_track_hist;
    
    BEGIN
    
        OPEN c_fast_track;
        FETCH c_fast_track
            INTO l_id_fast_track;
        CLOSE c_fast_track;
    
        RETURN pk_fast_track.get_fast_track_desc(i_lang       => i_lang,
                                                 i_prof       => profissional(0, 0, 0),
                                                 i_fast_track => l_id_fast_track,
                                                 i_type       => pk_fast_track.g_desc_grid);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_fast_track_desc;

    /**********************************************************************************************
    * Gets the description of a disable reason
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_fast_track_disable     Fast track disable reason ID
    *
    * @return                         Disable reason
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/14
    **********************************************************************************************/
    FUNCTION get_disable_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_fast_track_disable IN fast_track_disable.id_fast_track_disable%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc_disable VARCHAR2(4000);
    
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, fd.code_fast_track_disable)
          INTO l_desc_disable
          FROM fast_track_disable fd
         WHERE fd.id_fast_track_disable = i_fast_track_disable;
    
        RETURN l_desc_disable;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_disable_desc;

    /**********************************************************************************************
    * Gets the current episode fast track
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param o_id_fast_track          Fast track ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION get_epis_fast_track
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        o_id_fast_track OUT fast_track.id_fast_track%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error     t_error_out;
        l_exception EXCEPTION;
    
        CURSOR c_epis_triage IS
            SELECT ef.id_fast_track
              FROM epis_triage et
              JOIN epis_fast_track ef
                ON ef.id_epis_triage = et.id_epis_triage
             WHERE et.id_episode = i_id_episode
             ORDER BY et.dt_end_tstz DESC;
    
    BEGIN
    
        OPEN c_epis_triage;
        FETCH c_epis_triage
            INTO o_id_fast_track;
        CLOSE c_epis_triage;
    
        IF o_id_fast_track IS NULL
        THEN
            g_error := 'CALL PK_EPIS_ER_LAW_API.GET_FAST_TRACK_ID';
            IF NOT pk_epis_er_law_api.get_fast_track_id(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_episode    => i_id_episode,
                                                        o_fast_track => o_id_fast_track,
                                                        o_error      => l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_EPIS_FAST_TRACK',
                                                     o_error);
    END get_epis_fast_track;

    FUNCTION get_epis_fast_track_int
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE
    ) RETURN NUMBER IS
    
        l_error     t_error_out;
        l_exception EXCEPTION;
    
        l_id_fast_track fast_track.id_fast_track%TYPE;
    
    BEGIN
    
        IF i_id_epis_triage IS NULL
        THEN
            BEGIN
                g_error := 'GET FAST TRACK ID (1)';
                SELECT t.id_fast_track
                  INTO l_id_fast_track
                  FROM (SELECT ef.id_fast_track
                          FROM epis_triage et
                          LEFT JOIN epis_fast_track ef
                            ON et.id_epis_triage = ef.id_epis_triage
                           AND flg_status = g_fast_track_active
                         WHERE et.id_episode = i_id_episode
                         ORDER BY et.dt_end_tstz DESC) t
                 WHERE rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_fast_track := NULL;
            END;
        
            IF l_id_fast_track IS NULL
            THEN
                g_error := 'GET FAST TRACK ID (1.5) - CALL PK_EPIS_ER_LAW_API.GET_FAST_TRACK_ID';
                IF NOT pk_epis_er_law_api.get_fast_track_id(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_episode    => i_id_episode,
                                                            o_fast_track => l_id_fast_track,
                                                            o_error      => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        ELSE
            BEGIN
                g_error := 'GET FAST TRACK ID (2)';
                SELECT ef.id_fast_track
                  INTO l_id_fast_track
                  FROM epis_triage et
                  JOIN epis_fast_track ef
                    ON ef.id_epis_triage = et.id_epis_triage
                 WHERE et.id_epis_triage = i_id_epis_triage;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_fast_track := NULL;
            END;
        END IF;
    
        RETURN l_id_fast_track;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_FAST_TRACK_INT',
                                              l_error);
            RETURN NULL;
    END get_epis_fast_track_int;

    /**********************************************************************************************
    * Gets the automatically triggered fast track for a given triage (if configured)
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_triage              Triage ID
    * @param o_id_fast_track          Fast track ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Nuno Alves
    * @version                        2.5
    * @since                          2015/10/22
    **********************************************************************************************/
    FUNCTION get_triage_fast_track
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_triage     IN triage.id_triage%TYPE,
        o_id_fast_track OUT fast_track.id_fast_track%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rec_fast_track_cfg t_rec_fast_track_cfg;
        l_tbl_fast_track_cfg t_tbl_fast_track_cfg := t_tbl_fast_track_cfg();
    
    BEGIN
    
        g_error              := 'GET ID_FAST_TRACK with TF_FAST_TRACK_CFG FOR i_id_triage: ' || i_id_triage;
        l_tbl_fast_track_cfg := tf_fast_track_cfg(i_lang, i_prof, i_id_triage, g_ft_triggered_activation);
    
        IF l_tbl_fast_track_cfg.exists(1)
        THEN
            l_rec_fast_track_cfg := l_tbl_fast_track_cfg(1);
            o_id_fast_track      := l_rec_fast_track_cfg.id_fast_track;
        ELSE
            o_id_fast_track := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_TRIAGE_FAST_TRACK',
                                                     o_error);
    END get_triage_fast_track;

    /**********************************************************************************************
    * Gets the automatically triggered fast track for a given triage (if configured)
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_triage              Triage ID
    *
    * @return                         id_fast_track          Fast track ID (NULL if none)
    *                        
    * @author                         Nuno Alves
    * @version                        2.5
    * @since                          2015/10/22
    **********************************************************************************************/
    FUNCTION get_triage_fast_track
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_triage IN triage.id_triage%TYPE
    ) RETURN fast_track.id_fast_track%TYPE IS
    
        l_id_fast_track fast_track.id_fast_track%TYPE;
        l_error         t_error_out;
    
    BEGIN
    
        IF NOT get_triage_fast_track(i_lang          => i_lang,
                                     i_prof          => i_prof,
                                     i_id_triage     => i_id_triage,
                                     o_id_fast_track => l_id_fast_track,
                                     o_error         => l_error)
        THEN
            l_id_fast_track := NULL;
        END IF;
    
        RETURN l_id_fast_track;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_triage_fast_track;

    /**********************************************************************************************
    * Gets fast track configurations
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_triage              Triage ID
    * @param i_flg_activation_type    'M' - Manual activation, 'T' - automatically Triggered
    *
    * @return                         t_coll_fast_track_cfg
    *                        
    * @author                         Nuno Alves
    * @version                        2.5
    * @since                          2015/10/27
    **********************************************************************************************/
    FUNCTION tf_fast_track_cfg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_triage           IN triage.id_triage%TYPE DEFAULT NULL,
        i_flg_activation_type IN fast_track_institution.flg_activation_type%TYPE DEFAULT 'M',
        i_id_fast_track       IN fast_track.id_fast_track%TYPE DEFAULT NULL
    ) RETURN t_tbl_fast_track_cfg IS
    
        l_tbl_fast_track_cfg t_tbl_fast_track_cfg := t_tbl_fast_track_cfg();
        l_id_triage          fast_track_institution.id_triage%TYPE;
        l_prof_cat           category.flg_type%TYPE;
    
    BEGIN
        g_error    := 'CALL PK_PROF_UTILS.GET_CATEGORY';
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        IF i_flg_activation_type = g_ft_manual_activation
        THEN
            l_id_triage := -1;
        ELSIF i_flg_activation_type = g_ft_triggered_activation
              AND nvl(i_id_triage, -1) != -1
        THEN
            l_id_triage := i_id_triage;
        ELSE
            g_error := 'PK_FAST_TRACK.TF_FAST_TRACK_CFG INVALID PARAMETERS: i_flg_activation_type: ' ||
                       i_flg_activation_type || ', i_id_triage: ' || i_id_triage;
            RETURN NULL;
        END IF;
    
        BEGIN
            SELECT t_rec_fast_track_cfg(t.id_fast_track,
                                        t.id_triage,
                                        t.id_institution,
                                        t.rank,
                                        t.flg_activation_type,
                                        t.id_action,
                                        t.flg_action_active)
              BULK COLLECT
              INTO l_tbl_fast_track_cfg
              FROM (SELECT ft.id_fast_track id_fast_track,
                           ft.id_action id_action,
                           nvl(fti.rank, ft.rank) rank,
                           fti.id_triage id_triage,
                           fti.id_institution id_institution,
                           fti.flg_activation_type flg_activation_type,
                           decode(get_fast_track_permission(l_prof_cat, nvl(fti.flg_permission, ft.flg_permission)),
                                  g_yes,
                                  pk_alert_constant.g_active,
                                  pk_alert_constant.g_inactive) flg_action_active,
                           decode(fti.flg_activation_type,
                                  g_ft_manual_activation,
                                  dense_rank() over(ORDER BY fti.id_institution DESC),
                                  row_number() over(ORDER BY fti.id_institution DESC, nvl(fti.rank, ft.rank) ASC)) rn
                      FROM fast_track ft
                      JOIN fast_track_institution fti
                        ON ft.id_fast_track = fti.id_fast_track
                     WHERE fti.id_institution IN (i_prof.institution, 0)
                       AND fti.id_triage = l_id_triage
                       AND fti.flg_activation_type = i_flg_activation_type
                       AND nvl(fti.flg_available, ft.flg_available) = g_yes
                       AND (i_id_fast_track IS NULL OR ft.id_fast_track = i_id_fast_track)) t
             WHERE t.rn = 1
             ORDER BY t.rank ASC;
        EXCEPTION
            WHEN no_data_found THEN
                l_tbl_fast_track_cfg := NULL;
        END;
    
        RETURN l_tbl_fast_track_cfg;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_fast_track_cfg;

    /********************************************************************************************
     * Get the manual fast track activation actions.
     * Based on get_actions function.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)  
     *
     * @return                         True or False on Success or Error
     *
     * @author                          Sofia Mendes
     * @version                         2.6.0.5
     * @since                           27-Jan-2011
    **********************************************************************************************/
    FUNCTION get_fast_track_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_epis_triage IN epis_fast_track.id_epis_triage%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_subject                   VARCHAR2(30) := 'TRIAGE_ACTION';
        l_ft_manual_activations_cfg sys_config.value%TYPE;
        l_id_epis_triage            epis_triage.id_epis_triage%TYPE;
        l_most_recent_triage        sys_config.value%TYPE;
        l_ft_disable_active         VARCHAR2(1 CHAR);
        l_ft_enable_active          VARCHAR2(1 CHAR);
        l_id_action_parent          action.id_action%TYPE := 2355540;
        l_internal_name             action.internal_name%TYPE := 'FAST_TRACK_ACTIVATE';
        l_eft_status                epis_fast_track.flg_status%TYPE;
    
    BEGIN
    
        g_error                     := 'GET SYS_CONFIG ''FAST_TRACKS_MANUAL_ACTIVATION''';
        l_ft_manual_activations_cfg := nvl(pk_sysconfig.get_config(i_code_cf => 'FAST_TRACKS_MANUAL_ACTIVATION',
                                                                   i_prof    => i_prof),
                                           g_no);
    
        BEGIN
            SELECT aux.id_epis_triage
              INTO l_id_epis_triage
              FROM (SELECT et.id_epis_triage, row_number() over(ORDER BY et.dt_end_tstz DESC) rn
                      FROM epis_triage et
                     WHERE et.id_episode = i_id_episode) aux
             WHERE aux.rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_triage := i_id_epis_triage;
        END;
    
        IF l_id_epis_triage = i_id_epis_triage
        THEN
            l_most_recent_triage := pk_alert_constant.g_yes;
        ELSE
            l_most_recent_triage := pk_alert_constant.g_no;
        END IF;
    
        --EMR-4797
        BEGIN
            SELECT flg_status
              INTO l_eft_status
              FROM epis_fast_track e
             WHERE e.id_epis_triage = i_id_epis_triage;
        EXCEPTION
            WHEN no_data_found THEN
                l_eft_status := 'A';
            WHEN OTHERS THEN
                NULL;
        END;
        --EMR-4797 END
    
        BEGIN
            SELECT pk_fast_track.get_fast_track_permission(i_lang,
                                                           i_prof,
                                                           et.id_triage,
                                                           ef.flg_activation_type,
                                                           ef.id_fast_track,
                                                           decode(ef.flg_status, 'C', 'A', ef.flg_status), -- EMR-4797 ef.flg_status,
                                                           pk_fast_track.g_fast_track_disabled),
                   decode(l_ft_manual_activations_cfg,
                          g_no,
                          g_no,
                          pk_fast_track.get_fast_track_permission(i_lang,
                                                                  i_prof,
                                                                  et.id_triage,
                                                                  ef.flg_activation_type,
                                                                  ef.id_fast_track,
                                                                  ef.flg_status,
                                                                  pk_fast_track.g_fast_track_active))
              INTO l_ft_disable_active, l_ft_enable_active
              FROM epis_triage et
              LEFT JOIN epis_fast_track ef
                ON et.id_epis_triage = ef.id_epis_triage
             WHERE et.id_epis_triage = i_id_epis_triage;
        EXCEPTION
            WHEN no_data_found THEN
                l_ft_disable_active := pk_alert_constant.g_no;
                l_ft_enable_active  := pk_alert_constant.g_yes;
        END;
    
        IF l_ft_disable_active = pk_alert_constant.g_no
        THEN
            l_ft_disable_active := pk_alert_constant.g_inactive;
        ELSE
            l_ft_disable_active := pk_alert_constant.g_active;
        END IF;
    
        IF l_ft_enable_active = pk_alert_constant.g_no
        THEN
            l_ft_enable_active := pk_alert_constant.g_inactive;
        ELSE
            l_ft_enable_active := pk_alert_constant.g_active;
        END IF;
    
        g_error := 'GET CURSOR O_ACTIONS';
        OPEN o_actions FOR
            SELECT *
              FROM (SELECT /*+opt_estimate (table a rows=1)*/
                     a.id_action,
                     a.desc_action desc_action,
                     l_subject subject,
                     a.to_state,
                     a.icon,
                     CASE
                          WHEN a.to_state = g_fast_track_action_disabled THEN
                           l_ft_disable_active
                          WHEN a.to_state = g_fast_track_action_confirm THEN -- EMR-4797
                           decode(l_eft_status,
                                  pk_fast_track.g_fast_track_confirm,
                                  l_ft_enable_active,
                                  l_ft_disable_active)
                          ELSE
                           l_ft_enable_active
                      END flg_active,
                     a.flg_default,
                     a.id_parent,
                     a.action internal_name,
                     a.level_nr action_level,
                     NULL id_fast_track
                      FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, l_subject, NULL)) a
                     WHERE (l_ft_manual_activations_cfg = g_yes OR a.to_state <> g_fast_track_active)
                       AND (l_most_recent_triage = g_yes OR a.to_state <> g_fast_track_active)
                    UNION
                    SELECT ft.id_fast_track id_action,
                           pk_translation.get_translation(i_lang, 'FAST_TRACK.CODE_FAST_TRACK.' || ft.id_fast_track),
                           l_subject subject,
                           flg_action_active,
                           NULL icon,
                           CASE
                               WHEN l_ft_enable_active = pk_alert_constant.g_active THEN
                                nvl(ft.flg_action_active, l_ft_enable_active)
                               ELSE
                                l_ft_enable_active
                           END flg_active,
                           pk_alert_constant.g_no flg_default,
                           l_id_action_parent id_parent,
                           l_internal_name internal_name,
                           2 action_level,
                           ft.id_fast_track
                      FROM TABLE(tf_fast_track_cfg(i_lang, i_prof)) ft
                     WHERE l_ft_manual_activations_cfg = g_yes
                       AND l_most_recent_triage = g_yes) t
             ORDER BY t.action_level, t.desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_FAST_TRACK_ACTIONS',
                                                     o_error);
    END get_fast_track_actions;

    /************************************************************************************************************
    * This function returns the fast track reason list
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_fast_track           vital_sign identifier
    * @param      i_flg_add_cancel      add or cancel reasons
    * @param       o_cursor             out cursor
    * @param       o_error             error message 
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.5
    * @since      2016/04/07
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_fast_track_reason
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_fast_track  IN fast_track.id_fast_track%TYPE,
        i_flg_add_cancel IN fast_track_reason_si.flg_add_cancel%TYPE,
        o_cursor         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_age       fast_track_reason_si.age_min%TYPE;
    
    BEGIN
    
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'YEARS', i_id_patient);
    
        g_error := 'get_vs_read_attributes: open o_cursor';
        OPEN o_cursor FOR
            SELECT aux.id_fast_track_reason id,
                   pk_translation.get_translation(i_lang, ftr.code_fast_track_reason) label
              FROM (SELECT ftrsi.id_fast_track_reason,
                           ftrsi.rank,
                           ftrsi.flg_available,
                           row_number() over(PARTITION BY ftrsi.id_fast_track_reason ORDER BY ftrsi.id_software DESC, ftrsi.id_institution DESC, ftrsi.id_market DESC) rn
                      FROM fast_track_reason_si ftrsi
                     WHERE ftrsi.id_fast_track = i_id_fast_track
                       AND ftrsi.flg_add_cancel = decode(i_flg_add_cancel, 'D', 'V', i_flg_add_cancel) --EMR-4797
                       AND ftrsi.id_market IN (pk_alert_constant.g_id_market_all, l_id_market)
                       AND ftrsi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND ftrsi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND (l_age IS NULL OR l_age BETWEEN nvl(ftrsi.age_min, 0) AND nvl(ftrsi.age_max, 999))) aux
              JOIN fast_track_reason ftr
                ON ftr.id_fast_track_reason = aux.id_fast_track_reason
               AND ftr.flg_available = pk_alert_constant.g_yes
               AND aux.flg_available = pk_alert_constant.g_yes
             WHERE aux.rn = 1
             ORDER BY label, aux.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FAST_TRACK_REASON',
                                              o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END get_fast_track_reason;

    /************************************************************************************************************
    * This function creates a record in the history table for fast track reasons
    *
    * @param        i_lang                       Language id
    * @param        i_prof                       Professional, software and institution ids
    * @param        i_id_epis_triage             triage ID
    * @param        i_id_epis_fast_track_hist    epis_fast_track_hist ID
    * @param        i_flg_add_cancel             flg_add_cancel
    *
    * @author     Paulo Teixeira
    * @version    2.5
    * @since      2016/04/07
    ************************************************************************************************************/
    FUNCTION set_fast_track_reason_hist
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_triage          IN epis_fast_track.id_epis_triage%TYPE,
        i_id_epis_fast_track_hist IN epis_ft_reason_hist.id_epis_fast_track_hist%TYPE,
        i_flg_add_cancel          IN fast_track_reason_si.flg_add_cancel%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis_fast_track_reason(l_id epis_fast_track_reason.id_epis_triage%TYPE) IS
            SELECT eftr.id_fast_track_reason
              FROM epis_fast_track_reason eftr
             WHERE eftr.id_epis_triage = l_id
               AND eftr.flg_active = pk_alert_constant.g_active
               AND eftr.flg_add_cancel = i_flg_add_cancel;
    
        v_fast_track_reason fast_track_reason%ROWTYPE;
    
        rows_out table_varchar;
    
    BEGIN
    
        g_error := 'open c_epis_fast_track_reason(i_id_epis_triage);';
        OPEN c_epis_fast_track_reason(i_id_epis_triage);
    
        LOOP
            FETCH c_epis_fast_track_reason
                INTO v_fast_track_reason.id_fast_track_reason;
            EXIT WHEN c_epis_fast_track_reason%NOTFOUND;
        
            g_error := 'call ts_epis_ft_reason_hist.ins';
            ts_epis_ft_reason_hist.ins(id_epis_fast_track_hist_in => i_id_epis_fast_track_hist,
                                       id_fast_track_reason_in    => v_fast_track_reason.id_fast_track_reason,
                                       flg_add_cancel_in          => i_flg_add_cancel,
                                       rows_out                   => rows_out);
        
            g_error := 'call t_data_gov_mnt.process_insert for epis_ft_reason_hist';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_FT_REASON_HIST',
                                          i_rowids     => rows_out,
                                          o_error      => o_error);
        
        END LOOP;
    
        CLOSE c_epis_fast_track_reason;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_FAST_TRACK_REASON_HIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_fast_track_reason_hist;

    /************************************************************************************************************
    * This function creates a record in the table fast track reasons
    *
    * @param        i_lang                       Language id
    * @param        i_prof                       Professional, software and institution ids
    * @param        i_id_epis_triage             triage ID
    * @param        i_id_epis_fast_track_hist    epis_fast_track_hist ID
    * @param        i_flg_add_cancel             flg_add_cancel
    *
    * @param       o_error             error message 
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/11/15
    *
    * @dependencies     BD
    ***********************************************************************************************************/

    FUNCTION set_fast_track_reason
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_epis_triage       IN epis_fast_track.id_epis_triage%TYPE,
        i_tb_fast_track_reason IN table_number,
        i_flg_add_cancel       IN fast_track_reason_si.flg_add_cancel%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        rows_vsr_out table_varchar;
        l_where      VARCHAR2(200 CHAR);
    
    BEGIN
    
        l_where := 'id_epis_triage = ' || i_id_epis_triage || ' and flg_add_cancel = ''' || i_flg_add_cancel || '''';
        g_error := 'call ts_epis_fast_track_reason.upd flg_active_in => pk_alert_constant.g_inactive l_where:' ||
                   l_where;
        ts_epis_fast_track_reason.upd(flg_active_in => pk_alert_constant.g_inactive,
                                      where_in      => l_where,
                                      rows_out      => rows_vsr_out);
    
        g_error := 'call t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_FAST_TRACK_REASON',
                                      i_rowids     => rows_vsr_out,
                                      o_error      => o_error);
    
        IF i_tb_fast_track_reason.exists(1)
        THEN
            FOR i IN 1 .. i_tb_fast_track_reason.count
            LOOP
                g_error := 'call ts_epis_fast_track_reason.upd_ins';
                ts_epis_fast_track_reason.upd_ins(id_epis_triage_in       => i_id_epis_triage,
                                                  id_fast_track_reason_in => i_tb_fast_track_reason(i),
                                                  flg_add_cancel_in       => i_flg_add_cancel,
                                                  flg_active_in           => pk_alert_constant.g_active,
                                                  rows_out                => rows_vsr_out);
            
                g_error := 'call t_data_gov_mnt.process_insert EPIS_FAST_TRACK_REASON';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_FAST_TRACK_REASON',
                                              i_rowids     => rows_vsr_out,
                                              o_error      => o_error);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_FAST_TRACK_REASON',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_fast_track_reason;

    FUNCTION get_fast_track_reason_rank
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_fast_track        IN fast_track.id_fast_track%TYPE,
        i_id_fast_track_reason IN fast_track_reason.id_fast_track_reason%TYPE,
        i_flg_add_cancel       IN fast_track_reason_si.flg_add_cancel%TYPE
    ) RETURN fast_track_reason_si.rank%TYPE IS
    
        l_id_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_rank      fast_track_reason_si.rank%TYPE;
    
    BEGIN
    
        g_error := 'get_vs_read_attributes: open o_cursor';
        SELECT aux.rank
          INTO l_rank
          FROM (SELECT ftrsi.id_fast_track_reason,
                       ftrsi.rank,
                       row_number() over(PARTITION BY ftrsi.id_fast_track_reason ORDER BY ftrsi.id_software DESC, ftrsi.id_institution DESC, ftrsi.id_market DESC) rn
                  FROM fast_track_reason_si ftrsi
                 WHERE ftrsi.id_fast_track = i_id_fast_track
                   AND ftrsi.id_fast_track_reason = i_id_fast_track_reason
                   AND ftrsi.flg_add_cancel = i_flg_add_cancel
                   AND ftrsi.id_market IN (pk_alert_constant.g_id_market_all, l_id_market)
                   AND ftrsi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                   AND ftrsi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)) aux
         WHERE aux.rn = 1;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_fast_track_reason_rank;

    /**********************************************************************************************
    * Gets the description of a fast_track enable/disable reason
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis_fast_track_hist     fast_track hist record
    * @param i_flg_add_cancel         enable/disable reason A/C
    *
    * @return                         Disable reason
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/14
    **********************************************************************************************/
    FUNCTION get_fast_track_reasons
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_fast_track_hist IN epis_fast_track_hist.id_epis_fast_track_hist%TYPE,
        i_flg_add_cancel          IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_desc table_varchar;
    
    BEGIN
    
        SELECT aux.descr
          BULK COLLECT
          INTO l_desc
          FROM (SELECT pk_translation.get_translation(i_lang, ftr.code_fast_track_reason) descr,
                       get_fast_track_reason_rank(i_lang,
                                                  i_prof,
                                                  efth.id_fast_track,
                                                  eftrh.id_fast_track_reason,
                                                  i_flg_add_cancel) rank
                  FROM epis_fast_track_hist efth
                  JOIN epis_ft_reason_hist eftrh
                    ON eftrh.id_epis_fast_track_hist = efth.id_epis_fast_track_hist
                   AND eftrh.flg_add_cancel = i_flg_add_cancel
                  JOIN fast_track_reason ftr
                    ON ftr.id_fast_track_reason = eftrh.id_fast_track_reason
                 WHERE efth.id_epis_fast_track_hist = i_id_epis_fast_track_hist) aux
         ORDER BY aux.descr ASC, aux.rank ASC;
    
        RETURN pk_utils.concat_table(l_desc, '; ', 1, -1);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_fast_track_reasons;

    /**********************************************************************************************
    * Change status for fast track to given episode - EMR-4797
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param i_id_epis_triage         Triage made to the episode (it assumes the last one if it is NULL)
    * @param i_fast_track             Reasons
    * @param i_notes                  Notes
    * @param i_flg_status             Target status (D - Disable, C - Confirm)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexander Camilo
    * @version                        1.0 
    * @since                          2018/06/15
    **********************************************************************************************/
    FUNCTION set_fast_track_status_int
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_triage       IN epis_triage.id_epis_triage%TYPE,
        i_tb_fast_track_reason IN table_number,
        i_notes                IN epis_fast_track.notes_disable%TYPE,
        i_flg_status           IN epis_fast_track.flg_status%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_triage    epis_triage.id_epis_triage%TYPE;
        l_exception         EXCEPTION;
        l_error             t_error_out;
        l_rec_eft           epis_fast_track%ROWTYPE;
        l_rows              table_varchar;
        l_flg_status_reason VARCHAR2(1 CHAR);
    
        CURSOR c_epis_triage IS
            SELECT et.id_epis_triage
              FROM epis_triage et
             WHERE et.id_episode = i_id_episode
             ORDER BY et.dt_end_tstz DESC;
    
        l_id_epis_fast_track_hist epis_fast_track_hist.id_epis_fast_track_hist%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET EPIS_TRIAGE';
        OPEN c_epis_triage;
        FETCH c_epis_triage
            INTO l_id_epis_triage;
        CLOSE c_epis_triage;
    
        -- Set the needed fields according to the disabled state
        l_rec_eft.id_epis_triage := nvl(i_id_epis_triage, l_id_epis_triage);
        l_rec_eft.flg_status     := i_flg_status;
        IF i_flg_status = g_fast_track_disabled
        THEN
            l_rec_eft.id_prof_disable := i_prof.id;
            l_rec_eft.dt_disable      := g_sysdate_tstz;
            l_rec_eft.notes_disable   := i_notes;
            l_flg_status_reason       := pk_alert_constant.g_cancelled;
        ELSE
            l_rec_eft.id_prof_enable := i_prof.id;
            l_rec_eft.dt_activation  := g_sysdate_tstz;
            l_rec_eft.notes_enable   := i_notes;
            l_flg_status_reason      := pk_alert_constant.g_active;
        END IF;
    
        g_error := 'UPDATE EPIS_FAST_TRACK';
    
        ts_epis_fast_track.upd(id_epis_triage_in  => l_rec_eft.id_epis_triage,
                               flg_status_in      => l_rec_eft.flg_status,
                               id_prof_disable_in => l_rec_eft.id_prof_disable,
                               dt_disable_in      => l_rec_eft.dt_disable,
                               notes_disable_in   => l_rec_eft.notes_disable,
                               notes_enable_in    => l_rec_eft.notes_enable,
                               dt_enable_in       => l_rec_eft.dt_enable,
                               id_prof_enable_in  => l_rec_eft.id_prof_enable,
                               dt_activation_in   => l_rec_eft.dt_activation,
                               rows_out           => l_rows);
    
        g_error := 'call set_fast_track_reason';
        IF NOT set_fast_track_reason(i_lang                 => i_lang,
                                     i_prof                 => i_prof,
                                     i_id_epis_triage       => nvl(i_id_epis_triage, l_id_epis_triage),
                                     i_tb_fast_track_reason => i_tb_fast_track_reason,
                                     i_flg_add_cancel       => l_flg_status_reason,
                                     o_error                => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET EPIS_FAST_TRACK';
        SELECT *
          INTO l_rec_eft
          FROM epis_fast_track eft
         WHERE eft.id_epis_triage = nvl(i_id_epis_triage, l_id_epis_triage);
    
        l_id_epis_fast_track_hist := ts_epis_fast_track_hist.next_key;
    
        g_error := 'INSERT INTO EPIS_FAST_TRACK_HIST';
        ts_epis_fast_track_hist.ins(id_epis_fast_track_hist_in => l_id_epis_fast_track_hist,
                                    id_epis_triage_in          => l_rec_eft.id_epis_triage,
                                    id_fast_track_in           => l_rec_eft.id_fast_track,
                                    flg_status_in              => l_rec_eft.flg_status,
                                    id_prof_disable_in         => l_rec_eft.id_prof_disable,
                                    dt_disable_in              => l_rec_eft.dt_disable,
                                    notes_disable_in           => l_rec_eft.notes_disable,
                                    flg_type_in                => l_rec_eft.flg_type,
                                    flg_activation_type_in     => l_rec_eft.flg_activation_type,
                                    dt_enable_in               => l_rec_eft.dt_enable,
                                    id_prof_enable_in          => l_rec_eft.id_prof_enable,
                                    dt_activation_in           => g_sysdate_tstz,
                                    notes_enable_in            => i_notes,
                                    rows_out                   => l_rows);
    
        g_error := 'call set_fast_track_reason_hist';
        IF NOT set_fast_track_reason_hist(i_lang                    => i_lang,
                                          i_prof                    => i_prof,
                                          i_id_epis_triage          => l_rec_eft.id_epis_triage,
                                          i_id_epis_fast_track_hist => l_id_epis_fast_track_hist,
                                          i_flg_add_cancel          => l_flg_status_reason,
                                          o_error                   => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_rec_eft.id_epis_triage = l_id_epis_triage
           AND i_flg_status = g_fast_track_disabled
        THEN
            g_error := 'UPDATE EPISODE';
            l_rows  := table_varchar();
            ts_episode.upd(id_episode_in     => i_id_episode,
                           id_fast_track_in  => NULL,
                           id_fast_track_nin => FALSE,
                           rows_out          => l_rows);
        
            t_data_gov_mnt.process_update(i_lang, i_prof, 'EPISODE', l_rows, o_error, table_varchar('ID_FAST_TRACK'));
        
            g_error := 'UPDATE EPIS_INFO';
            IF NOT set_epis_info_fast_track(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_id_episode,
                                            o_error      => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'CALL TO SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_id_episode,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error || ' / ' || l_error.err_desc,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_FAST_TRACK_STATUS_INT',
                                                     o_error);
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_FAST_TRACK_STATUS_INT',
                                                     o_error);
    END set_fast_track_status_int;

    /**********************************************************************************************
    * Change status for fast track to given episode --  EMR-4797
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param i_id_epis_triage         Triage made to the episode (it assumes the last one if it is NULL)
    * @param i_fast_track             Reasons
    * @param i_notes                  Notes
    * @param i_flg_status             Target status (D - Disable, C - Confirm)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexander Camilo
    * @version                        1.0 
    * @since                          2018/06/15
    **********************************************************************************************/

    FUNCTION set_fast_track_status
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_triage       IN epis_triage.id_epis_triage%TYPE,
        i_tb_fast_track_reason IN table_number,
        i_notes                IN epis_fast_track.notes_disable%TYPE,
        i_flg_status           IN epis_fast_track.flg_status%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        IF NOT set_fast_track_status_int(i_lang                 => i_lang,
                                         i_prof                 => i_prof,
                                         i_id_episode           => i_id_episode,
                                         i_id_epis_triage       => i_id_epis_triage,
                                         i_tb_fast_track_reason => i_tb_fast_track_reason,
                                         i_notes                => i_notes,
                                         i_flg_status           => i_flg_status,
                                         o_error                => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'SET_FAST_TRACK_STATUS',
                                                     o_error);
    END set_fast_track_status;

    /**********************************************************************************************
    * Check if there is an active fast track and return the respective number  --  EMR-4797
    * EMR-3449
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param o_epis_triag             return Triage Episode
    * @param o_fast_track             return ID Fast Track
    * @param o_ft_descr               reutnr Fast Track Description
    *
    * @return                         True if Ok, False if Error
    *                        
    * @author                         Alexander Camilo
    * @version                        1.0 
    * @since                          2017/06/01
    **********************************************************************************************/
    FUNCTION get_fast_track_to_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN alert.profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_epis_triag OUT epis_triage.id_epis_triage%TYPE,
        o_fast_track OUT fast_track.id_fast_track%TYPE,
        o_ft_descr   OUT translation.desc_lang_1%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cfg_fasttrack_disch sys_config.value%TYPE;
        l_ret_epis_triage     epis_triage.id_epis_triage%TYPE;
        l_ret_id_fast_track   fast_track.id_fast_track%TYPE;
        l_bool                BOOLEAN;
        l_epis_triag          table_number;
        l_fast_track          table_number;
    
    BEGIN
    
        l_cfg_fasttrack_disch := pk_sysconfig.get_config(g_cfg_fasttrack_disch, i_prof);
    
        IF nvl(l_cfg_fasttrack_disch, 'N') = 'N'
        THEN
            RETURN TRUE;
        ELSE
            g_error := 'Looking for epis_triage related to the episode: ' || i_id_episode;
            -- Get and return the active fast track of the episode
            SELECT et.id_epis_triage, ef.id_fast_track
              BULK COLLECT
              INTO l_epis_triag, l_fast_track
              FROM epis_triage et, epis_fast_track ef
             WHERE et.id_epis_triage = ef.id_epis_triage(+)
               AND et.id_episode = i_id_episode
               AND ef.flg_status = g_fast_track_active
             ORDER BY ef.dt_enable DESC;
        
            IF l_fast_track.exists(1)
            THEN
                o_fast_track := l_fast_track(1);
                o_epis_triag := l_epis_triag(1);
            END IF;
        
            o_ft_descr := get_fast_track_desc(i_lang, i_prof, o_fast_track, 'H');
        
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN too_many_rows THEN
            g_error := 'More than one active fast track when looking for epis_triage related to the episode: ' ||
                       i_id_episode;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'get_fast_track_to_discharge',
                                                     o_error);
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'get_fast_track_to_discharge',
                                                     o_error);
    END get_fast_track_to_discharge;

    /**************************************************************************
    * Get the limit dates for each fast track admission --  EMR-4797
    *   
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_episode                 Episode ID
    * @param o_limits                  Cursor with fast_track option and limit dates
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *                        
    * @author                          Alexander Camilo
    * @version                         2.7
    * @since                           30/05/2018
    **************************************************************************/
    FUNCTION get_epis_action_limit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_limits  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_admission episode.dt_begin_tstz%TYPE;
    
        l_dt_current    TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_dt_initial    patient.dt_birth%TYPE;
        l_ext_fast_t    sys_domain.val%TYPE := 'E';
        l_cfg_show      sys_config.value%TYPE;
        l_cfg_ext_limit sys_config.value%TYPE;
    
    BEGIN
    
        l_cfg_show      := pk_sysconfig.get_config(i_code_cf => g_cfg_fasttrack_confirm, i_prof => i_prof);
        l_cfg_ext_limit := pk_sysconfig.get_config(i_code_cf => g_syscfg_ft_ext_limit, i_prof => i_prof);
    
        IF nvl(l_cfg_show, pk_alert_constant.g_no) = pk_alert_constant.g_no
        THEN
            pk_types.open_my_cursor(o_limits);
            RETURN TRUE;
        END IF;
    
        SELECT e.dt_begin_tstz
          INTO l_dt_admission
          FROM patient p
          JOIN episode e
            ON e.id_patient = p.id_patient
         WHERE e.id_episode = i_episode;
    
        l_dt_initial := pk_date_utils.add_to_ltstz(i_timestamp => l_dt_admission,
                                                   i_amount    => -l_cfg_ext_limit,
                                                   i_unit      => 'YEAR');
    
        OPEN o_limits FOR
            SELECT s.val,
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(s.val, l_ext_fast_t, l_dt_initial, l_dt_admission),
                                               i_prof) min_limit,
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(s.val, l_ext_fast_t, l_dt_admission, l_dt_current),
                                               i_prof) max_limit
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, 'EPIS_FAST_TRACK.FLG_TYPE', NULL)) s
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_limits);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_ACTION_LIMIT',
                                              o_error);
            RETURN FALSE;
    END get_epis_action_limit;

BEGIN

    --globals are in the spec
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_fast_track;
/
