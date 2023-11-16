-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/04/2015 17:01
-- CHANGE REASON: [ALERT-310275] ALERT-310275 Data Migration Versioning - The system must not allow other user than the prescriber to cancel or discontinue one order without co-sign
DECLARE
    l_date_format    CONSTANT VARCHAR2(200 CHAR) := 'YYYYMMDDHH24MISS';
    l_def_order_type CONSTANT order_type.id_order_type%TYPE := 6;
    --
    l_lang                              language.id_language%TYPE := NULL;
    l_error                             t_error_out;
    l_co_sign                           co_sign.id_co_sign%TYPE;
    l_co_sign_hist_pend                 co_sign_hist.id_co_sign_hist%TYPE;
    l_co_sign_hist_outd                 co_sign_hist.id_co_sign_hist%TYPE;
    l_tbl_co_sign_hist_cs               table_number;

    PROCEDURE handle_error
    (
        i_msg   IN VARCHAR2,
        i_error IN t_error_out
    ) IS
    BEGIN
        dbms_output.put_line('#########################################################');
        dbms_output.put_line('I_MSG: ' || i_msg);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLCODE: ' || i_error.ora_sqlcode);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLERRM: ' || i_error.ora_sqlerrm);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_DESC: ' || i_error.err_desc);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_ACTION: ' || i_error.err_action);
        dbms_output.put_line(' ');
        dbms_output.put_line('LOG_ID: ' || i_error.log_id);
        dbms_output.put_line('*********************************************************');
    END handle_error;
BEGIN
    FOR r_monit IN (SELECT m.id_monitorization,
                           epis.id_episode,
                           epis.id_institution,
                           nvl(ei.id_software,
                               (SELECT etsi.id_software
                                  FROM epis_type et
                                  JOIN epis_type_soft_inst etsi
                                    ON etsi.id_epis_type = et.id_epis_type
                                 WHERE et.flg_available = 'Y'
                                   AND et.id_epis_type = epis.id_epis_type
                                   AND etsi.id_institution = 0)) id_software,
                           m.id_professional,
                           m.dt_monitorization_tstz,
                           m.id_prof_cancel,
                           m.dt_cancel_tstz,
                           m.flg_status
                      FROM monitorization m
                      JOIN episode epis
                        ON epis.id_episode = m.id_episode
                      JOIN epis_info ei
                        ON ei.id_episode = epis.id_episode
                     WHERE EXISTS (SELECT 1
                              FROM monitorization_vs mvs
                             WHERE mvs.id_monitorization = m.id_monitorization
                               AND mvs.id_prof_order IS NOT NULL)
                       AND m.id_co_sign_order IS NULL
                       AND m.id_co_sign_cancel IS NULL
                     ORDER BY dt_monitorization_tstz, id_monitorization)
    LOOP
        FOR r_mvs IN (SELECT DISTINCT mvs.id_prof_order,
                                      mvs.dt_order,
                                      nvl(mvs.id_order_type, l_def_order_type) id_order_type,
                                      mvs.flg_co_sign,
                                      mvs.id_prof_co_sign,
                                      mvs.dt_co_sign,
                                      mvs.notes_co_sign
                        FROM monitorization_vs mvs
                       WHERE mvs.id_monitorization = r_monit.id_monitorization
                         AND mvs.id_prof_order IS NOT NULL
                       ORDER BY mvs.dt_order, mvs.dt_co_sign)
        LOOP
          -- reset vars
          l_co_sign := NULL;
          l_co_sign_hist_pend := NULL;
          l_co_sign_hist_outd := NULL;
          l_tbl_co_sign_hist_cs := table_number();
            
            --CREATE NEW CO_SIGN
            IF NOT pk_co_sign_api.set_pending_co_sign_task(i_lang                   => l_lang,
                                                       i_prof                   => profissional(r_monit.id_professional,
                                                                                                r_monit.id_institution,
                                                                                                r_monit.id_software),
                                                       i_episode                => r_monit.id_episode,
                                                       i_id_task_type           => pk_alert_constant.g_task_monitoring,
                                                       i_cosign_def_action_type => pk_co_sign.g_cosign_action_def_add,
                                                       i_id_task                => r_monit.id_monitorization,
                                                       i_id_task_group          => r_monit.id_monitorization,
                                                       i_id_order_type          => r_mvs.id_order_type,
                                                       i_id_prof_created        => r_monit.id_professional,
                                                       i_id_prof_ordered_by     => r_mvs.id_prof_order,
                                                       i_dt_created             => r_monit.dt_monitorization_tstz,
                                                       i_dt_ordered_by          => r_mvs.dt_order,
                                                       o_id_co_sign             => l_co_sign,
                                                       o_id_co_sign_hist        => l_co_sign_hist_pend,
                                                       o_error                  => l_error)
            THEN
                handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_COSIGN_TASK(' || l_lang || --
                                        ', profissional(' || r_monit.id_professional || ', ' || r_monit.id_institution || ', ' ||
                                        r_monit.id_software || '), ' || --
                                        r_monit.id_episode || ', ' || --
                                        pk_alert_constant.g_task_monitoring || ', ' || --
                                        pk_co_sign.g_cosign_action_def_add || ', ' || --
                                        r_monit.id_monitorization || ', ' || --
                                        r_monit.id_monitorization || ', ' || --
                                        r_mvs.id_order_type || ', ' || --
                                        r_monit.id_professional || ', ' || --
                                        r_mvs.id_prof_order || ', ' || --
                                        to_char(r_monit.dt_monitorization_tstz, l_date_format) || ', ' || --
                                        to_char(r_mvs.dt_order, l_date_format) || ')',
                             i_error => l_error);
            END IF;
        
            IF l_co_sign IS NOT NULL
            THEN
                --Update Transactional table with id_co_sign
                UPDATE monitorization m
                   SET m.id_co_sign_order = l_co_sign
                 WHERE m.id_monitorization = r_monit.id_monitorization;
            
                IF r_mvs.flg_co_sign = pk_alert_constant.g_yes
                THEN
                    --Co-sign the task
                    IF NOT pk_co_sign.set_task_co_signed(i_lang             => l_lang,
                                                         i_prof             => profissional(r_monit.id_professional,
                                                                                            r_monit.id_institution,
                                                                                            r_monit.id_software),
                                                         i_episode             => r_monit.id_episode,
                                                         i_tbl_id_co_sign      => table_number(l_co_sign),
                                                         i_id_prof_cosigned    => r_mvs.id_prof_co_sign,
                                                         i_dt_cosigned         => r_mvs.dt_co_sign,
                                                         i_cosign_notes        => r_mvs.notes_co_sign,
                                                         i_flg_made_auth       => pk_alert_constant.g_no,
                                                         o_tbl_id_co_sign_hist => l_tbl_co_sign_hist_cs,
                                                         o_error               => l_error)
                    THEN
                        handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_TASK_CO_SIGNED(' || l_lang || --
                                                ', profissional(' || r_monit.id_professional || ', ' ||
                                                r_monit.id_institution || ', ' || r_monit.id_software || '), ' || --
                                                r_monit.id_episode || ', ' || --
                                                l_co_sign || ', ' || --
                                                r_mvs.id_prof_co_sign || ', ' || --
                                                to_char(r_mvs.dt_co_sign, l_date_format) || ', ' || --
                                                r_mvs.notes_co_sign || ', ' || --
                                                pk_alert_constant.g_no || ')',
                                     i_error => l_error);
                    END IF;
                END IF;
            
                IF r_monit.id_prof_cancel IS NOT NULL
                THEN
                    IF nvl(r_mvs.flg_co_sign, pk_alert_constant.g_no) = pk_alert_constant.g_no
                    THEN
                        --Set the co-sign task as outdated
                        IF NOT pk_co_sign.set_task_outdated(i_lang            => l_lang,
                                                            i_prof            => profissional(r_monit.id_professional,
                                                                                         r_monit.id_institution,
                                                                                         r_monit.id_software),
                                                            i_episode         => r_monit.id_episode,
                                                            i_id_co_sign      => l_co_sign,
                                                            o_id_co_sign_hist => l_co_sign_hist_outd,
                                                            o_error           => l_error)
                        THEN
                            handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_TASK_OUTDATED(' || l_lang || --
                                                    ', profissional(' || r_monit.id_professional || ', ' ||
                                                    r_monit.id_institution || ', ' || r_monit.id_software || '), ' || --
                                                    r_monit.id_episode || ', ' || --
                                                    l_co_sign || ')',
                                         i_error => l_error);
                        END IF;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Nuno Alves

-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 29/04/2015 11:56
-- CHANGE REASON: [ALERT-310543] ALERT-310543 Monitorization migration script corrections (co-sign)
DECLARE
    l_date_format    CONSTANT VARCHAR2(200 CHAR) := 'YYYYMMDDHH24MISS';
    l_def_order_type CONSTANT order_type.id_order_type%TYPE := 6;
    --
    l_lang                language.id_language%TYPE := NULL;
    l_error               t_error_out;
    l_co_sign             co_sign.id_co_sign%TYPE;
    l_co_sign_hist_pend   co_sign_hist.id_co_sign_hist%TYPE;
    l_co_sign_hist_outd   co_sign_hist.id_co_sign_hist%TYPE;
    l_tbl_co_sign_hist_cs table_number;

    PROCEDURE handle_error
    (
        i_msg   IN VARCHAR2,
        i_error IN t_error_out
    ) IS
    BEGIN
        dbms_output.put_line('#########################################################');
        dbms_output.put_line('I_MSG: ' || i_msg);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLCODE: ' || i_error.ora_sqlcode);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLERRM: ' || i_error.ora_sqlerrm);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_DESC: ' || i_error.err_desc);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_ACTION: ' || i_error.err_action);
        dbms_output.put_line(' ');
        dbms_output.put_line('LOG_ID: ' || i_error.log_id);
        dbms_output.put_line('*********************************************************');
    END handle_error;
BEGIN
    -- CLEAN LAST MIGRATION
    BEGIN
        -- co_sign_hist
        DELETE FROM co_sign_hist c
         WHERE c.id_task_type = 9;
    
        -- monitorization
        UPDATE monitorization m
           SET m.id_co_sign_order = NULL, m.id_co_sign_cancel = NULL
         WHERE m.id_co_sign_order IS NOT NULL
            OR m.id_co_sign_cancel IS NOT NULL;
    
        -- co_sign
        DELETE FROM co_sign cs
         WHERE cs.id_task_type = 9;
    END;
    -- END CLEANING  

    FOR r_monit IN (SELECT m.id_monitorization,
                           epis.id_episode,
                           epis.id_institution,
                           nvl(ei.id_software,
                               (SELECT etsi.id_software
                                  FROM epis_type et
                                  JOIN epis_type_soft_inst etsi
                                    ON etsi.id_epis_type = et.id_epis_type
                                 WHERE et.flg_available = 'Y'
                                   AND et.id_epis_type = epis.id_epis_type
                                   AND etsi.id_institution = 0)) id_software,
                           m.id_professional,
                           m.dt_monitorization_tstz,
                           m.id_prof_cancel,
                           m.dt_cancel_tstz,
                           m.flg_status
                      FROM monitorization m
                      JOIN episode epis
                        ON epis.id_episode = m.id_episode
                      JOIN epis_info ei
                        ON ei.id_episode = epis.id_episode
                     WHERE EXISTS (SELECT 1
                              FROM monitorization_vs mvs
                             WHERE mvs.id_monitorization = m.id_monitorization
                               AND (mvs.id_order_type IS NOT NULL OR
                                   (m.id_professional <> mvs.id_prof_order AND mvs.id_prof_order IS NOT NULL))
                               AND mvs.flg_status <> pk_alert_constant.g_monitor_vs_draft)
                       AND m.id_co_sign_order IS NULL
                       AND m.id_co_sign_cancel IS NULL
                     ORDER BY dt_monitorization_tstz, id_monitorization)
    LOOP
        FOR r_mvs IN (SELECT DISTINCT mvs.id_prof_order,
                                      mvs.dt_order,
                                      nvl(mvs.id_order_type, l_def_order_type) id_order_type,
                                      mvs.flg_co_sign,
                                      mvs.id_prof_co_sign,
                                      mvs.dt_co_sign,
                                      mvs.notes_co_sign
                        FROM monitorization_vs mvs
                       WHERE mvs.id_monitorization = r_monit.id_monitorization
                         AND (mvs.id_order_type IS NOT NULL OR
                             (r_monit.id_professional <> mvs.id_prof_order AND mvs.id_prof_order IS NOT NULL))
                         AND mvs.flg_status <> pk_alert_constant.g_monitor_vs_draft
                       ORDER BY mvs.dt_order, mvs.dt_co_sign)
        LOOP
            -- reset vars
            l_co_sign             := NULL;
            l_co_sign_hist_pend   := NULL;
            l_co_sign_hist_outd   := NULL;
            l_tbl_co_sign_hist_cs := table_number();
        
            --CREATE NEW CO_SIGN
            IF NOT pk_co_sign_api.set_pending_co_sign_task(i_lang                   => l_lang,
                                                           i_prof                   => profissional(r_monit.id_professional,
                                                                                                    r_monit.id_institution,
                                                                                                    r_monit.id_software),
                                                           i_episode                => r_monit.id_episode,
                                                           i_id_task_type           => pk_alert_constant.g_task_monitoring,
                                                           i_cosign_def_action_type => pk_co_sign.g_cosign_action_def_add,
                                                           i_id_task                => r_monit.id_monitorization,
                                                           i_id_task_group          => r_monit.id_monitorization,
                                                           i_id_order_type          => r_mvs.id_order_type,
                                                           i_id_prof_created        => r_monit.id_professional,
                                                           i_id_prof_ordered_by     => r_mvs.id_prof_order,
                                                           i_dt_created             => r_monit.dt_monitorization_tstz,
                                                           i_dt_ordered_by          => r_mvs.dt_order,
                                                           o_id_co_sign             => l_co_sign,
                                                           o_id_co_sign_hist        => l_co_sign_hist_pend,
                                                           o_error                  => l_error)
            THEN
                handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_COSIGN_TASK(' || l_lang || --
                                        ', profissional(' || r_monit.id_professional || ', ' || r_monit.id_institution || ', ' ||
                                        r_monit.id_software || '), ' || --
                                        r_monit.id_episode || ', ' || --
                                        pk_alert_constant.g_task_monitoring || ', ' || --
                                        pk_co_sign.g_cosign_action_def_add || ', ' || --
                                        r_monit.id_monitorization || ', ' || --
                                        r_monit.id_monitorization || ', ' || --
                                        r_mvs.id_order_type || ', ' || --
                                        r_monit.id_professional || ', ' || --
                                        r_mvs.id_prof_order || ', ' || --
                                        to_char(r_monit.dt_monitorization_tstz, l_date_format) || ', ' || --
                                        to_char(r_mvs.dt_order, l_date_format) || ')',
                             i_error => l_error);
            END IF;
        
            IF l_co_sign IS NOT NULL
            THEN
                --Update Transactional table with id_co_sign
                UPDATE monitorization m
                   SET m.id_co_sign_order = l_co_sign
                 WHERE m.id_monitorization = r_monit.id_monitorization;
            
                IF r_mvs.flg_co_sign = pk_alert_constant.g_yes
                THEN
                    --Co-sign the task
                    IF NOT pk_co_sign.set_task_co_signed(i_lang                => l_lang,
                                                         i_prof                => profissional(r_monit.id_professional,
                                                                                               r_monit.id_institution,
                                                                                               r_monit.id_software),
                                                         i_episode             => r_monit.id_episode,
                                                         i_tbl_id_co_sign      => table_number(l_co_sign),
                                                         i_id_prof_cosigned    => r_mvs.id_prof_co_sign,
                                                         i_dt_cosigned         => r_mvs.dt_co_sign,
                                                         i_cosign_notes        => r_mvs.notes_co_sign,
                                                         i_flg_made_auth       => pk_alert_constant.g_no,
                                                         o_tbl_id_co_sign_hist => l_tbl_co_sign_hist_cs,
                                                         o_error               => l_error)
                    THEN
                        handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_TASK_CO_SIGNED(' || l_lang || --
                                                ', profissional(' || r_monit.id_professional || ', ' ||
                                                r_monit.id_institution || ', ' || r_monit.id_software || '), ' || --
                                                r_monit.id_episode || ', ' || --
                                                l_co_sign || ', ' || --
                                                r_mvs.id_prof_co_sign || ', ' || --
                                                to_char(r_mvs.dt_co_sign, l_date_format) || ', ' || --
                                                r_mvs.notes_co_sign || ', ' || --
                                                pk_alert_constant.g_no || ')',
                                     i_error => l_error);
                    END IF;
                END IF;
            
                IF r_monit.id_prof_cancel IS NOT NULL
                THEN
                    IF nvl(r_mvs.flg_co_sign, pk_alert_constant.g_no) = pk_alert_constant.g_no
                    THEN
                        --Set the co-sign task as outdated
                        IF NOT pk_co_sign.set_task_outdated(i_lang            => l_lang,
                                                            i_prof            => profissional(r_monit.id_professional,
                                                                                              r_monit.id_institution,
                                                                                              r_monit.id_software),
                                                            i_episode         => r_monit.id_episode,
                                                            i_id_co_sign      => l_co_sign,
                                                            o_id_co_sign_hist => l_co_sign_hist_outd,
                                                            o_error           => l_error)
                        THEN
                            handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_TASK_OUTDATED(' || l_lang || --
                                                    ', profissional(' || r_monit.id_professional || ', ' ||
                                                    r_monit.id_institution || ', ' || r_monit.id_software || '), ' || --
                                                    r_monit.id_episode || ', ' || --
                                                    l_co_sign || ')',
                                         i_error => l_error);
                        END IF;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Nuno Alves