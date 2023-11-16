CREATE OR REPLACE PACKAGE BODY pk_alerts_api_crm IS

    PROCEDURE set_notification
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_sys_alert        IN sys_alert.id_sys_alert%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) IS
    
        CURSOR c_profs IS
            SELECT t.id_professional, t.id_institution, t.id_software
              FROM (SELECT sap.id_professional, sap.id_institution, sap.id_software
                      FROM sys_alert_prof sap
                     WHERE sap.flg_sms = pk_alert_constant.g_yes
                       AND sap.id_sys_alert = i_sys_alert
                       AND sap.id_institution = i_prof.institution
                       AND sap.id_software = i_prof.software
                       AND sap.id_profile_template = nvl(i_profile_template, sap.id_profile_template)
                       AND (i_prof.id IS NOT NULL OR
                           (sap.flg_notification_all = pk_alert_constant.g_yes AND i_prof.id IS NULL))
                    UNION
                    SELECT sap.id_professional, sap.id_institution, sap.id_software
                      FROM sys_alert_prof sap
                     WHERE sap.flg_email = pk_alert_constant.g_yes
                       AND sap.id_sys_alert = i_sys_alert
                       AND sap.id_institution = i_prof.institution
                       AND sap.id_software = i_prof.software
                       AND sap.id_profile_template = nvl(i_profile_template, sap.id_profile_template)
                       AND (i_prof.id IS NOT NULL OR
                           (sap.flg_notification_all = pk_alert_constant.g_yes AND i_prof.id IS NULL))
                    UNION
                    SELECT sap.id_professional, sap.id_institution, sap.id_software
                      FROM sys_alert_prof sap
                     WHERE sap.flg_im = pk_alert_constant.g_yes
                       AND sap.id_sys_alert = i_sys_alert
                       AND sap.id_institution = i_prof.institution
                       AND sap.id_software = i_prof.software
                       AND sap.id_profile_template = nvl(i_profile_template, sap.id_profile_template)
                       AND (i_prof.id IS NOT NULL OR
                           (sap.flg_notification_all = pk_alert_constant.g_yes AND i_prof.id IS NULL))) t
              JOIN professional p
                ON t.id_professional = p.id_professional
             WHERE p.flg_state = pk_alert_constant.g_active;
    
        l_sql_alert pk_types.cursor_type;
    
        l_sys_alert      sys_alert%ROWTYPE;
        l_sys_alert_temp sys_alert_temp%ROWTYPE;
    
        l_id_sys_alert sys_alert.id_sys_alert%TYPE;
        l_replace1     sys_alert_event.replace1%TYPE;
        l_replace2     sys_alert_event.replace2%TYPE;
    
        l_flg_profile      profile_template.flg_profile%TYPE;
        l_resp_icons_table table_varchar;
    
        l_prof_lang language.id_language%TYPE;
    
        l_sql   VARCHAR2(32767);
        l_where VARCHAR2(32767);
    
        l_max_dt_record VARCHAR2(50 CHAR);
    
        -- convert clob to varchar2
        FUNCTION clob2varchar(i_str_clob CLOB) RETURN VARCHAR2 IS
            l_str_varchar VARCHAR2(32767);
            l_amount      PLS_INTEGER := 32767;
        
            e_clob2varchar EXCEPTION;
            PRAGMA EXCEPTION_INIT(e_clob2varchar, -06502);
        
        BEGIN
            -- copy characters of the buffer
            l_str_varchar := to_char(i_str_clob);
            RETURN l_str_varchar;
        
        EXCEPTION
            WHEN e_clob2varchar THEN
                -- copy bytes of the buffer
                dbms_lob.read(i_str_clob, l_amount, 1, l_str_varchar);
                RETURN l_str_varchar;
        END clob2varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        SELECT sa.id_sys_alert, sa.sql_alert alert_sql, sa.intern_name
          INTO l_sys_alert.id_sys_alert, l_sys_alert.sql_alert, l_sys_alert.intern_name
          FROM sys_alert sa
         WHERE sa.id_sys_alert = i_sys_alert
           AND EXISTS (SELECT 1
                  FROM sys_alert_config sac
                 WHERE sac.id_sys_alert = sa.id_sys_alert
                   AND sac.flg_sms = pk_alert_constant.g_yes
                   AND sac.id_institution = i_prof.institution
                UNION ALL
                SELECT 1
                  FROM sys_alert_config sac
                 WHERE sac.id_sys_alert = sa.id_sys_alert
                   AND sac.flg_email = pk_alert_constant.g_yes
                   AND sac.id_institution = i_prof.institution
                UNION ALL
                SELECT 1
                  FROM sys_alert_config sac
                 WHERE sac.id_sys_alert = sa.id_sys_alert
                   AND sac.flg_im = pk_alert_constant.g_yes
                   AND sac.id_institution = i_prof.institution);
    
        FOR l_prof IN c_profs
        LOOP
        
            BEGIN
                SELECT nvl(t.dt_record, '0')
                  INTO l_max_dt_record
                  FROM (SELECT pk_date_utils.to_char_insttimezone(i_prof, san.dt_record, 'YYYYMMDDHH24MISS') dt_record,
                               row_number() over(ORDER BY san.dt_record DESC) rn
                          FROM sys_alert_notification san
                         WHERE to_char(san.dt_record, 'DD-MM-YYYY') = to_char(g_sysdate_tstz, 'DD-MM-YYYY')
                           AND san.id_sys_alert = i_sys_alert
                           AND san.id_sys_alert_event != l_sys_alert_temp.id_sys_alert_det) t
                 WHERE rn = 1;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_max_dt_record := '0';
            END;
        
            -- get the language of the professional
            BEGIN
                SELECT pp.id_language
                  INTO l_prof_lang
                  FROM prof_preferences pp
                 WHERE pp.id_professional = l_prof.id_professional
                   AND pp.id_institution = l_prof.id_institution
                   AND pp.id_software = l_prof.id_software;
            EXCEPTION
                WHEN no_data_found THEN
                    l_prof_lang := pk_utils.get_institution_language(i_institution => l_prof.id_institution,
                                                                     i_software    => l_prof.id_software);
            END;
        
            -- get category of the professional
            l_flg_profile := pk_hand_off_core.get_flg_profile(i_lang,
                                                              profissional(l_prof.id_professional,
                                                                           l_prof.id_institution,
                                                                           l_prof.id_software),
                                                              NULL);
        
            pk_context_api.set_parameter('i_institution', l_prof.id_institution);
            pk_context_api.set_parameter('i_prof', l_prof.id_professional);
            pk_context_api.set_parameter('i_software', l_prof.id_software);
            pk_context_api.set_parameter('i_lang', i_lang);
            pk_context_api.set_parameter('l_flg_profile', l_flg_profile);
            pk_context_api.set_parameter('l_hand_off_type', pk_alert_constant.g_no);
        
            l_where := CASE l_max_dt_record
                           WHEN '0' THEN
                            ' WHERE pk_date_utils.trunc_insttimezone(
                               profissional(' || l_prof.id_professional || ',' ||
                            l_prof.id_institution || ',' || l_prof.id_software || '), 
                               pk_date_utils.get_string_tstz(' || i_lang || ', profissional(' ||
                            l_prof.id_professional || ',' || l_prof.id_institution || ',' || l_prof.id_software ||
                            '), dt_req, NULL),
                               ''DD'')
                            = pk_date_utils.trunc_insttimezone(
                               profissional(' || l_prof.id_professional || ',' ||
                            l_prof.id_institution || ',' || l_prof.id_software || '),
                               current_timestamp, 
                               ''DD'') '
                           ELSE
                            ' WHERE dt_req >  ' || l_max_dt_record
                       END;
        
            l_sql := 'SELECT * FROM (' || clob2varchar(l_sys_alert.sql_alert) || ')' || l_where;
        
            BEGIN
            
                OPEN l_sql_alert FOR l_sql;
            
                LOOP
                    l_id_sys_alert := l_sys_alert_temp.id_sys_alert;
                
                    FETCH l_sql_alert
                        INTO l_sys_alert_temp.id_sys_alert_det,
                             l_sys_alert_temp.id_reg,
                             l_sys_alert_temp.id_episode,
                             l_sys_alert_temp.id_institution,
                             l_sys_alert_temp.id_prof, --
                             l_sys_alert_temp.dt_req,
                             l_sys_alert_temp.time,
                             l_sys_alert_temp.message,
                             l_sys_alert_temp.id_room,
                             l_sys_alert_temp.id_patient,
                             l_sys_alert_temp.name_pat,
                             l_sys_alert_temp.pat_ndo,
                             l_sys_alert_temp.pat_nd_icon,
                             l_sys_alert_temp.photo, --
                             l_sys_alert_temp.gender,
                             l_sys_alert_temp.pat_age,
                             l_sys_alert_temp.desc_room,
                             l_sys_alert_temp.date_send,
                             l_sys_alert_temp.desc_epis_anamnesis,
                             l_sys_alert_temp.acuity, --
                             l_sys_alert_temp.rank_acuity,
                             l_sys_alert_temp.id_schedule,
                             l_sys_alert_temp.id_sys_shortcut,
                             l_sys_alert_temp.id_reg_det,
                             l_sys_alert_temp.id_sys_alert, --
                             l_sys_alert_temp.dt_first_obs_tstz,
                             l_sys_alert_temp.fast_track_icon,
                             l_sys_alert_temp.fast_track_color,
                             l_sys_alert_temp.fast_track_status,
                             l_sys_alert_temp.esi_level,
                             l_sys_alert_temp.name_pat_sort,
                             l_resp_icons_table,
                             l_sys_alert_temp.id_prof_order;
                
                    IF l_sql_alert%FOUND
                    THEN
                    
                        BEGIN
                            SELECT sae.replace1, sae.replace2
                              INTO l_replace1, l_replace2
                              FROM sys_alert_event sae
                             WHERE sae.id_sys_alert_event = l_sys_alert_temp.id_sys_alert_det;
                        
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_replace1 := NULL;
                                l_replace2 := NULL;
                        END;
                    
                        BEGIN
                            INSERT INTO sys_alert_notification
                                (id_sys_alert_event,
                                 dt_record,
                                 dt_processed,
                                 id_prof,
                                 id_sys_alert,
                                 id_language,
                                 id_patient,
                                 id_episode,
                                 id_software,
                                 replace1,
                                 replace2,
                                 replace3,
                                 replace4,
                                 replace5,
                                 replace6,
                                 replace7,
                                 replace8,
                                 replace9,
                                 replace10)
                            VALUES
                                (l_sys_alert_temp.id_sys_alert_det,
                                 pk_date_utils.get_string_tstz(i_lang, i_prof, l_sys_alert_temp.dt_req, NULL),
                                 g_sysdate_tstz,
                                 l_prof.id_professional,
                                 l_sys_alert_temp.id_sys_alert,
                                 l_prof_lang,
                                 l_sys_alert_temp.id_patient,
                                 l_sys_alert_temp.id_episode,
                                 l_prof.id_software,
                                 l_replace1,
                                 l_replace2,
                                 l_replace1,
                                 (SELECT u.login
                                    FROM ab_user_info u
                                   WHERE u.id_ab_user_info = l_prof.id_professional),
                                 l_replace1,
                                 l_replace1,
                                 '',
                                 '',
                                 '',
                                 '');
                        
                            -- notify the INTER_ALERT
                            pk_ia_event_common.alert_notification_new(id_sys_alert_event => l_sys_alert_temp.id_sys_alert_det,
                                                                      i_id_professional  => l_prof.id_professional,
                                                                      i_id_institution   => l_prof.id_institution);
                        EXCEPTION
                            WHEN dup_val_on_index THEN
                                NULL;
                        END;
                    END IF;
                
                    EXIT WHEN l_sql_alert%NOTFOUND;
                END LOOP;
            
            EXCEPTION
                WHEN OTHERS THEN
                    dbms_output.put_line('ID_SYS_ALERT: ' || l_sys_alert.id_sys_alert || ', ' || 'INTERN_NAME: ' ||
                                         l_sys_alert.intern_name);
                    dbms_output.put_line('ERROR MESSAGE: ' || SQLERRM);
                    dbms_output.put_line('   ---   ');
            END;
        END LOOP;
    
    EXCEPTION
        WHEN no_data_found THEN
            NULL;
    END set_notification;

    PROCEDURE delete_notification(i_sys_alert_event IN table_number) IS
    
    BEGIN
    
        DELETE sys_alert_notification san
         WHERE san.id_sys_alert_event IN (SELECT /*+ opt_estimate(table t rows=1*/
                                           t.*
                                            FROM TABLE(i_sys_alert_event) t);
    
    EXCEPTION
        WHEN no_data_found THEN
            NULL;
    END delete_notification;

    PROCEDURE process_notification IS
    
        CURSOR c_lang
        (
            l_prof        NUMBER,
            l_institution NUMBER
        ) IS
            SELECT p.id_language
              FROM prof_preferences p
             WHERE p.id_professional = l_prof
               AND p.id_institution = l_institution;
    
        CURSOR c_sys_alert_event(l_dt sys_alert_event.dt_record%TYPE) IS
            SELECT DISTINCT sae.id_sys_alert, sae.id_professional, sae.id_institution, sae.id_software
              FROM sys_alert_event sae
             WHERE NOT EXISTS
             (SELECT 1
                      FROM sys_alert_notification san
                     WHERE san.id_sys_alert_event = sae.id_sys_alert_event)
               AND pk_date_utils.trunc_insttimezone(profissional(0, sae.id_institution, sae.id_software),
                                                    sae.dt_record,
                                                    'DD') >=
                   pk_date_utils.trunc_insttimezone(profissional(0, sae.id_institution, sae.id_software), l_dt, 'DD')
               AND pk_sysconfig.get_config('CRM_ALERTS', profissional(0, sae.id_institution, sae.id_software)) =
                   pk_alert_constant.g_yes;
    
        l_lang    NUMBER;
        l_id_prof NUMBER;
    
        l_dt_processed sys_alert_notification.dt_processed%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        SELECT MAX(san.dt_processed)
          INTO l_dt_processed
          FROM sys_alert_notification san;
    
        FOR sea IN c_sys_alert_event(l_dt_processed)
        LOOP
            IF sea.id_professional IS NOT NULL
            THEN
                OPEN c_lang(l_id_prof, sea.id_institution);
                FETCH c_lang
                    INTO l_lang;
                CLOSE c_lang;
            
                pk_alerts_api_crm.set_notification(l_lang,
                                                   profissional(sea.id_professional,
                                                                sea.id_institution,
                                                                sea.id_software),
                                                   sea.id_sys_alert,
                                                   NULL);
            
            ELSE
                l_id_prof := pk_sysconfig.get_config('ID_PROF_ALERT',
                                                     profissional(0, sea.id_institution, sea.id_software));
            
                OPEN c_lang(l_id_prof, sea.id_institution);
                FETCH c_lang
                    INTO l_lang;
                CLOSE c_lang;
            
                FOR sac IN (SELECT id_profile_template, flg_notification_all
                              FROM (SELECT sac.*,
                                           row_number() over(PARTITION BY sac.id_profile_template ORDER BY sac.id_institution DESC, sac.id_software DESC) rn
                                      FROM sys_alert_config sac
                                     WHERE sac.id_sys_alert = sea.id_sys_alert
                                       AND sac.id_software IN (sea.id_software, 0)
                                       AND sac.id_institution IN (sea.id_institution, 0))
                             WHERE rn = 1)
                LOOP
                    IF sac.flg_notification_all = pk_alert_constant.g_yes
                    THEN
                        pk_alerts_api_crm.set_notification(l_lang,
                                                           profissional(sea.id_professional,
                                                                        sea.id_institution,
                                                                        sea.id_software),
                                                           sea.id_sys_alert,
                                                           sac.id_profile_template);
                    END IF;
                END LOOP;
            END IF;
        
            COMMIT;
        END LOOP;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PROCESS_NOTIFICATION',
                                              l_error);
    END process_notification;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_alerts_api_crm;
/
