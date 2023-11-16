/*-- Last Change Revision: $Rev: 2027468 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_patient_tracking IS

    e_call_exception EXCEPTION;
    -- Private global constant declarations
    g_flg_stage_code_domain    CONSTANT sys_domain.code_domain%TYPE := 'CARE_STAGE.FLG_STAGE';
    g_syscfg_auto_wait_consult CONSTANT sys_config.id_sys_config%TYPE := 'AUTO_WAITING_FOR_CONSULTANT_STAGE';
    g_syscfg_care_state_after  CONSTANT sys_config.id_sys_config%TYPE := 'CARE_STATE_AFTER_PAT_CONSULT';
    g_syscfg_death_status      CONSTANT sys_config.id_sys_config%TYPE := 'PATIENT_DEATH_STATUS';
    g_syscfg_auto_cancel_disch CONSTANT sys_config.id_sys_config%TYPE := 'AUTO_CANCEL_DISCHARGE_STAGE';

    g_syscfg_reopen_status    CONSTANT sys_config.id_sys_config%TYPE := 'AUTO_REOPEN_EPISODE_CARE_STATUS';
    g_syscfg_auto_reopen_epis CONSTANT sys_config.id_sys_config%TYPE := 'AUTO_REOPEN_EPISODE_STAGE';

    -- type of department statuses request (Total, Registered, Not Registered)
    g_summary_type_all CONSTANT VARCHAR2(1) := 'A';
    g_summary_type_reg CONSTANT VARCHAR2(1) := 'R';
    g_summary_type_nrg CONSTANT VARCHAR2(1) := 'N';

    g_flg_active_yes  CONSTANT VARCHAR2(1) := 'Y';
    g_flg_active_no   CONSTANT VARCHAR2(1) := 'N';
    g_flg_active_hist CONSTANT VARCHAR2(1) := 'H';

    g_flg_ins_type_auto CONSTANT care_stage.flg_ins_type%TYPE := 'A'; --Automatically
    g_flg_ins_type_man  CONSTANT care_stage.flg_ins_type%TYPE := 'M'; --Manual
    g_flg_ins_type_int  CONSTANT care_stage.flg_ins_type%TYPE := 'I'; --Interface

    g_flg_stage_wait_paym CONSTANT care_stage.flg_stage%TYPE := 'WPY'; -- Waiting for payment
    g_flg_stage_paym_made CONSTANT care_stage.flg_stage%TYPE := 'PYM'; -- Payment made
    g_flg_stage_in_treat  CONSTANT care_stage.flg_stage%TYPE := 'ITM'; -- In treatment

    g_opinion_reply_stage CONSTANT sys_domain.val%TYPE := 'CSA';

    g_discharge_stages CONSTANT table_varchar := table_varchar('RDS',
                                                               'RTF',
                                                               'ADM',
                                                               'HBD',
                                                               'WCR',
                                                               'WFH',
                                                               'WOD',
                                                               'HOR',
                                                               'AMA',
                                                               'WBS');

    -- Private global variables declarations

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    FUNCTION get_statuses_summary
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- type of item on department statuses
        g_flg_type_item     CONSTANT VARCHAR2(1) := 'I';
        g_flg_type_subt     CONSTANT VARCHAR2(1) := 'S';
        g_flg_type_tots     CONSTANT VARCHAR2(1) := 'T';
        g_flg_type_nonumber CONSTANT VARCHAR2(1) := 'N';
    
        -- rank for 'Holding for:' line. Must be equal to 'Holding for Coroner' rank minus 0.5
        g_holdingfor_rank CONSTANT NUMBER := 15.5;
    
        -- space used for identation
        g_identationspace CONSTANT VARCHAR2(3) := '   ';
    
        -- message codes
        g_msg_all CONSTANT sys_message.code_message%TYPE := 'PAT_TRACK_T001';
        g_msg_reg CONSTANT sys_message.code_message%TYPE := 'PAT_TRACK_T002';
        g_msg_nrg CONSTANT sys_message.code_message%TYPE := 'PAT_TRACK_T003';
        g_msg_wcr CONSTANT sys_message.code_message%TYPE := 'PAT_TRACK_T004';
        g_msg_wfh CONSTANT sys_message.code_message%TYPE := 'PAT_TRACK_T005';
        g_msg_wod CONSTANT sys_message.code_message%TYPE := 'PAT_TRACK_T006';
        g_msg_wfl CONSTANT sys_message.code_message%TYPE := 'PAT_TRACK_T007';
    
        -- stages to show for reach department statuses request type
        g_summary_list_a CONSTANT table_varchar := table_varchar('IRT', -- In Route
                                                                 'WTR', -- Waiting for Triage
                                                                 'ITR', -- In Triage
                                                                 'WRG', -- Waiting for Registration
                                                                 'WRM', -- Waiting for Room
                                                                 'WNR', -- Waiting for Nurse
                                                                 'WPH', -- Waiting for Physician
                                                                 'WCS', -- Waiting for Consultant
                                                                 'WRS', -- Waiting for Results
                                                                 'WDP', -- Waiting for Disposition
                                                                 'RDS', -- Ready for Discharge
                                                                 'RTF', -- Ready for Transfer
                                                                 'ADM', -- Admit
                                                                 'HBD', -- Holding for bed
                                                                 'WCR', -- Waiting for Coroner
                                                                 'WFH', -- Waiting Funeral Home
                                                                 'WOD', -- Waiting Organ Donation
                                                                 'HOR', -- Holding for OR
                                                                 'AMA', -- AMA
                                                                 'WBS', -- LWBS
                                                                 'WPR',
                                                                 'DSG');
        g_summary_list_r CONSTANT table_varchar := table_varchar('IRT', -- In Route
                                                                 'WTR', -- Waiting for Triage
                                                                 'ITR', -- In Triage
                                                                 'WRM', -- Waiting for Room
                                                                 'WNR', -- Waiting for Nurse
                                                                 'WPH', -- Waiting for Physician
                                                                 'WCS', -- Waiting for Consultant
                                                                 'WRS', -- Waiting for Results
                                                                 'WDP', -- Waiting for Disposition
                                                                 'RDS', -- Ready for Discharge
                                                                 'RTF', -- Ready for Transfer
                                                                 'ADM', -- Admit
                                                                 'HBD', -- Holding for bed
                                                                 'WCR', -- Waiting for Coroner
                                                                 'WFH', -- Waiting Funeral Home
                                                                 'WOD', -- Waiting Organ Donation
                                                                 'HOR', -- Holding for OR
                                                                 'AMA', -- AMA
                                                                 'WBS', -- LWBS
                                                                 'WPR',
                                                                 'DSG');
        g_summary_list_n CONSTANT table_varchar := table_varchar('IRT', -- In Route
                                                                 'WTR', -- Waiting for Triage
                                                                 'ITR', -- In Triage
                                                                 'WRG', -- Waiting for Registration
                                                                 'WRM', -- Waiting for Room
                                                                 'WNR', -- Waiting for Nurse
                                                                 'WPH', -- Waiting for Physician
                                                                 'WCS', -- Waiting for Consultant
                                                                 'WRS', -- Waiting for Results
                                                                 'WDP', -- Waiting for Disposition
                                                                 'RDS', -- Ready for Discharge
                                                                 'RTF', -- Ready for Transfer
                                                                 'ADM', -- Admit
                                                                 'HBD', -- Holding for bed
                                                                 'WCR', -- Waiting for Coroner
                                                                 'WFH', -- Waiting Funeral Home
                                                                 'WOD', -- Waiting Organ Donation
                                                                 'HOR', -- Holding for OR
                                                                 'AMA', -- AMA
                                                                 'WBS', -- LWBS
                                                                 'WPR',
                                                                 'DSG');
    
        -- local variables
        l_set     table_varchar;
        l_msg_all sys_message.desc_message%TYPE;
        l_msg_reg sys_message.desc_message%TYPE;
        l_msg_rng sys_message.desc_message%TYPE;
        l_msg_wcr sys_message.desc_message%TYPE;
        l_msg_wfh sys_message.desc_message%TYPE;
        l_msg_wod sys_message.desc_message%TYPE;
        l_msg_wfl sys_message.desc_message%TYPE;
    
        e_wrongparameters EXCEPTION;
    BEGIN
        -- choose the set of stages for the selected summary
        g_error := 'STAGES SET';
        l_set   := CASE i_flg_type --
                       WHEN g_summary_type_all THEN
                        g_summary_list_a --
                       WHEN g_summary_type_reg THEN
                        g_summary_list_r --
                       WHEN g_summary_type_nrg THEN
                        g_summary_list_n --
                       ELSE
                        table_varchar() --
                   END;
    
        IF l_set.count = 0
        THEN
            RAISE e_wrongparameters;
        END IF;
    
        g_error   := 'MESSAGES SET';
        l_msg_all := pk_message.get_message(i_lang, g_msg_all);
        l_msg_reg := pk_message.get_message(i_lang, g_msg_reg);
        l_msg_rng := pk_message.get_message(i_lang, g_msg_nrg);
        l_msg_wcr := pk_message.get_message(i_lang, g_msg_wcr);
        l_msg_wfh := pk_message.get_message(i_lang, g_msg_wfh);
        l_msg_wod := pk_message.get_message(i_lang, g_msg_wod);
        l_msg_wfl := pk_message.get_message(i_lang, g_msg_wfl);
    
        -- cursor for data
        g_error := 'GET DATA';
        OPEN o_data FOR
            SELECT decode(flg_unknown,
                          NULL,
                          decode(stage_desc,
                                 NULL,
                                 l_msg_all || ':',
                                 decode(val,
                                        'HBD',
                                        g_identationspace || stage_desc || ':',
                                        'WCR',
                                        g_identationspace || l_msg_wcr || ':',
                                        'WFH',
                                        g_identationspace || l_msg_wfh || ':',
                                        'WOD',
                                        g_identationspace || l_msg_wod || ':',
                                        stage_desc || ':')),
                          pk_alert_constant.g_yes,
                          l_msg_rng || ':',
                          pk_alert_constant.g_no,
                          l_msg_reg || ':') stage_desc,
                   episode_count,
                   -- totals and subtotals have negative ranks
                   decode(flg_unknown, NULL, rank, pk_alert_constant.g_yes, -1, pk_alert_constant.g_no, -2) rank,
                   -- flg_type is 'T' for current total, 'S' for sub-total and 'I' for an individual item
                   decode(flg_unknown,
                          NULL,
                          decode(stage_desc, NULL, g_flg_type_tots, g_flg_type_item),
                          decode(i_flg_type, g_summary_type_all, g_flg_type_subt, g_flg_type_tots)) flg_type
              FROM (SELECT COUNT(cs.flg_unknown) episode_count, sd.val, sd.desc_val stage_desc, flg_unknown, sd.rank
                    -- don't know why I had to cast
                       FROM TABLE(CAST(pk_sysdomain.get_values_domain_pipelined(i_lang          => i_lang,
                                                                                i_prof          => i_prof,
                                                                                i_code_dom      => g_flg_stage_code_domain,
                                                                                i_dep_clin_serv => NULL) AS
                                       t_coll_values_domain_mkt)) sd
                     -- hint for avoid table full access to epis_info table
                       LEFT JOIN (SELECT /*+ index(EI EI(ID_EPISODE)) */
                                  cs.flg_stage, ei.flg_unknown
                                   FROM care_stage cs
                                   JOIN episode epis
                                     ON (cs.id_episode = epis.id_episode)
                                   JOIN epis_info ei
                                     ON (ei.id_episode = epis.id_episode)
                                  WHERE cs.flg_active = g_flg_active_yes
                                    AND ei.flg_unknown IS NOT NULL
                                       -- when we want to filter by registered or temporary patients
                                    AND ei.flg_unknown = decode(i_flg_type,
                                                                g_summary_type_reg,
                                                                pk_alert_constant.g_no,
                                                                g_summary_type_nrg,
                                                                pk_alert_constant.g_yes,
                                                                ei.flg_unknown)
                                    AND epis.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_pending)
                                    AND epis.id_institution = i_prof.institution) cs
                         ON (cs.flg_stage = sd.val)
                      WHERE 1 = 1
                           -- don't know why I had to cast
                       AND sd.val IN (SELECT column_value
                                        FROM TABLE(CAST(l_set AS table_varchar)))
                    -- grouping sets for sub-totals (NULL is added for grand total)
                     GROUP BY GROUPING SETS((sd.desc_val, sd.rank, sd.val), cs.flg_unknown, NULL))
             WHERE -- this is used to avoid having a null row
            -- for 'Registered' or 'Not Registered' patients we don't need the grand total
             episode_count != decode(i_flg_type, g_summary_type_all, 0, episode_count)
             OR stage_desc IS NOT NULL
             OR flg_unknown IS NOT NULL
            UNION ALL
            SELECT l_msg_wfl || ':' stage_desc,
                   NULL episode_count,
                   -- rank has to be suficient to hold this line between 'Holding for Bed' and 'Waiting for Coroner'
                   g_holdingfor_rank   rank,
                   g_flg_type_nonumber flg_type
              FROM dual
             ORDER BY rank NULLS FIRST;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_wrongparameters THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'WRONG PARAMETERS',
                                              'Wrong input parameters. i_flg_type=' || i_flg_type,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_STATUSES_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_STATUSES_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_statuses_summary;

    FUNCTION set_care_stage_no_commit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_stage    IN care_stage.flg_stage%TYPE,
        i_flg_ins_type IN care_stage.flg_ins_type%TYPE DEFAULT 'A',
        i_flg_active   IN care_stage.flg_active%TYPE DEFAULT 'Y',
        o_date         OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        g_time_warn_unit     CONSTANT VARCHAR2(30) := 'MINUTE';
        g_ti_log_flg_type_cs CONSTANT VARCHAR2(2) := 'CS';
    
        -- local variables
        l_rows table_varchar;
    
        l_date      care_stage.dt_set%TYPE := current_timestamp;
        l_date_warn care_stage.dt_warn%TYPE;
    
        l_time_to_warn care_stage_warn.time_to_warn%TYPE;
    
        CURSOR c_warn IS
            SELECT csw.time_to_warn
              FROM care_stage_warn csw
             WHERE csw.flg_stage = i_flg_stage
               AND csw.id_institution IN (0, i_prof.institution)
               AND csw.id_software IN (0, i_prof.software)
             ORDER BY csw.id_institution DESC, csw.id_software DESC;
    
        l_id_care_stage care_stage.id_care_stage%TYPE;
        l_flg_active    care_stage.flg_active%TYPE := nvl(i_flg_active, g_flg_active_yes);
    
    BEGIN
    
        g_error := 'GET PARAMETERIZED STATUS TIME TO WARN';
        OPEN c_warn;
        FETCH c_warn
            INTO l_time_to_warn;
        CLOSE c_warn;
    
        g_error := 'SETS TIME TO WARN';
        IF l_time_to_warn != -1
        THEN
            l_date_warn := l_date + numtodsinterval(l_time_to_warn, g_time_warn_unit);
        ELSE
            l_date_warn := NULL;
        END IF;
    
        IF l_flg_active = g_flg_active_yes
        THEN
            -- update any existing care stage records for the current episode
            g_error := 'UPDATE EPISODE FORMER STAGE';
            ts_care_stage.upd(flg_active_in => g_flg_active_no,
                              where_in      => 'id_episode = ' || i_episode || ' AND flg_active = ''' ||
                                               g_flg_active_yes || '''',
                              rows_out      => l_rows);
            t_data_gov_mnt.process_update(i_lang, i_prof, 'CARE_STAGE', l_rows, o_error, table_varchar('FLG_ACTIVE'));
        END IF;
    
        IF i_flg_stage IS NOT NULL
        THEN
            -- insert an active record for the selected stage
            g_error := 'INSERT CURRENT STAGE';
            ts_care_stage.ins(id_episode_in     => i_episode,
                              dt_set_in         => l_date,
                              flg_stage_in      => i_flg_stage,
                              flg_active_in     => l_flg_active,
                              dt_warn_in        => l_date_warn,
                              flg_ins_type_in   => i_flg_ins_type,
                              create_user_in    => i_prof.id,
                              rows_out          => l_rows,
                              id_care_stage_out => l_id_care_stage);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'CARE_STAGE', l_rows, o_error);
        
            ts_ti_log.ins(id_episode_in       => i_episode,
                          id_professional_in  => i_prof.id,
                          flg_status_in       => i_flg_stage,
                          id_record_in        => l_id_care_stage,
                          flg_type_in         => g_ti_log_flg_type_cs,
                          dt_creation_tstz_in => l_date,
                          rows_out            => l_rows);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'TI_LOG', l_rows, o_error);
        
            IF i_flg_stage = g_opinion_reply_stage
            THEN
                g_error := 'CALL TO PK_OPINION.SET_OPINION_AUTO_REPLY';
                IF NOT pk_opinion.set_opinion_auto_reply(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_episode => i_episode,
                                                         o_error   => o_error)
                THEN
                    RAISE e_call_exception;
                END IF;
            END IF;
        
        END IF;
    
        o_date := pk_date_utils.date_send_tsz(i_lang, l_date, i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_CARE_STAGE_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_care_stage_no_commit;

    FUNCTION get_change_state_mode(i_episode IN episode.id_episode%TYPE) RETURN VARCHAR2 IS
    
        l_flg_clear VARCHAR2(1);
    
    BEGIN
        SELECT decode(cs.flg_ins_type,
                      g_flg_ins_type_auto,
                      pk_alert_constant.g_no,
                      g_flg_ins_type_int,
                      pk_alert_constant.g_no,
                      pk_alert_constant.g_yes)
          INTO l_flg_clear
          FROM care_stage cs
         WHERE cs.id_episode = i_episode
           AND cs.flg_active = pk_alert_constant.g_yes;
    
        RETURN l_flg_clear;
    
    EXCEPTION
        WHEN no_data_found THEN
            -- no active status clear button must not be active
            RETURN pk_alert_constant.g_no;
    END get_change_state_mode;

    FUNCTION get_profile_care_stages
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_data      OUT pk_types.cursor_type,
        o_flg_clear OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DATA';
        -- doesn't show disposition statuses as available when no disposition is set and just shows disposition statuses as available when a disposition is set
        OPEN o_data FOR
            SELECT sd.desc_val label,
                   sd.val data,
                   substr(sd.img_name, instr(sd.img_name, '|') + 1) icon,
                   CASE
                        WHEN (SELECT id_discharge
                                FROM (SELECT d.id_discharge,
                                             d.flg_status,
                                             row_number() over(ORDER BY nvl(d.dt_pend_tstz, d.dt_med_tstz) DESC) rn
                                        FROM discharge d
                                       WHERE id_episode = i_episode)
                               WHERE rn = 1
                                 AND flg_status NOT IN ('R', 'C')) IS NOT NULL THEN
                         CASE
                             WHEN sd.val IN (SELECT *
                                               FROM TABLE(g_discharge_stages)) THEN
                              cssp.flg_set
                             ELSE
                              pk_alert_constant.g_no
                         END
                        ELSE
                         CASE
                             WHEN sd.val IN (SELECT *
                                               FROM TABLE(g_discharge_stages)) THEN
                              pk_alert_constant.g_no
                             ELSE
                              cssp.flg_set
                         END
                    END flg_set,
                   nvl(cssp.rank, sd.rank) order_rank
              FROM -- don't know why I had to cast
                   TABLE(CAST(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_flg_stage_code_domain, NULL) AS
                              t_coll_values_domain_mkt)) sd
              JOIN care_stage_set_permissions cssp
                ON (sd.val = cssp.domain_val)
              LEFT JOIN care_stage cs
                ON (cs.id_episode = i_episode AND cs.flg_active = g_flg_active_yes)
             WHERE cssp.id_institution IN (0, i_prof.institution)
               AND cssp.id_profile_template IN
                   (SELECT ppt.id_profile_template
                      FROM prof_profile_template ppt
                     WHERE ppt.id_professional = i_prof.id
                       AND ppt.id_software = i_prof.software
                       AND ppt.id_institution = i_prof.institution)
             ORDER BY order_rank;
    
        o_flg_clear := get_change_state_mode(i_episode);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PROFILE_CARE_STAGES',
                                              o_error);
            pk_types.open_my_cursor(o_data);
            o_flg_clear := pk_alert_constant.g_no;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_profile_care_stages;

    FUNCTION set_care_stage
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_stage   IN care_stage.flg_stage%TYPE,
        o_stage       OUT VARCHAR2,
        o_destination OUT VARCHAR2,
        o_rank        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_date     TIMESTAMP WITH LOCAL TIME ZONE;
        l_date_str VARCHAR2(50);
    
        l_pat                patient.id_patient%TYPE;
        l_flg_dsch_status    epis_info.flg_dsch_status%TYPE;
        l_id_disch_reas_dest epis_info.id_disch_reas_dest%TYPE;
    
    BEGIN
    
        g_error := 'SET CARE STATUS AS ' || i_flg_stage;
        IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_episode      => i_episode,
                                        i_flg_stage    => i_flg_stage,
                                        i_flg_ins_type => g_flg_ins_type_man,
                                        o_date         => l_date_str,
                                        o_error        => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        g_error := 'GET STAGE STATUS STR';
        o_stage := pk_patient_tracking.get_care_stage_grid_status(i_lang, i_prof, i_episode, l_date_str);
    
        g_error := 'GET EPISODE INFO';
        SELECT epis.id_patient, ei.flg_dsch_status, ei.id_disch_reas_dest
          INTO l_pat, l_flg_dsch_status, l_id_disch_reas_dest
          FROM episode epis
          JOIN epis_info ei
            ON ei.id_episode = epis.id_episode
         WHERE epis.id_episode = i_episode;
    
        g_error       := 'GET NEW DESTINATION';
        o_destination := pk_tracking_view.get_epis_destination(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_episode         => i_episode,
                                                               i_disch_reas_dest => l_id_disch_reas_dest,
                                                               i_flg_status      => l_flg_dsch_status);
    
        l_date := pk_date_utils.get_string_tstz(i_lang, i_prof, l_date_str, NULL);
    
        g_error := 'GET NEW rank';
        o_rank  := pk_patient_tracking.get_current_state_rank(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_episode);
    
        g_error := 'CALL TO SET FIRST OBS';
        IF NOT pk_visit.set_first_obs(i_lang, i_episode, l_pat, i_prof, NULL, l_date, l_date, o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_CARE_STAGE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_care_stage;

    FUNCTION get_statuses_summary_all
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'FUNCTION CALL';
        IF NOT get_statuses_summary(i_lang, i_prof, g_summary_type_all, o_data, o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_STATUSES_SUMMARY_ALL',
                                              o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_statuses_summary_all;

    FUNCTION get_statuses_summary_reg
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'FUNCTION CALL';
        IF NOT get_statuses_summary(i_lang, i_prof, g_summary_type_reg, o_data, o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_STATUSES_SUMMARY_REG',
                                              o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_statuses_summary_reg;

    FUNCTION get_statuses_summary_nrg
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'FUNCTION CALL';
        IF NOT get_statuses_summary(i_lang, i_prof, g_summary_type_nrg, o_data, o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_STATUSES_SUMMARY_NRG',
                                              o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_statuses_summary_nrg;

    FUNCTION get_care_stage_grid_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_dt_set     care_stage.dt_set%TYPE;
        l_flg_stage  care_stage.flg_stage%TYPE;
        l_icon_type  VARCHAR2(3);
        l_dt_warn    care_stage.dt_warn%TYPE;
        l_color      VARCHAR2(30);
        l_icon_color VARCHAR2(30);
    
        l_img      sys_domain.img_name%TYPE;
        l_img_temp sys_domain.img_name%TYPE;
    
        -- outer join is used to avoid having to treat a %notfound case (performance issues)
        CURSOR c_care_stage IS
            SELECT cs.dt_set, cs.flg_stage, cs.dt_warn
              FROM episode epis
              LEFT JOIN care_stage cs
                ON (cs.id_episode = epis.id_episode AND cs.flg_active = g_flg_active_yes)
             WHERE epis.id_episode = i_episode;
    
    BEGIN
    
        g_error := 'GET STAGE STATUS';
        OPEN c_care_stage;
        FETCH c_care_stage
            INTO l_dt_set, l_flg_stage, l_dt_warn;
    
        CLOSE c_care_stage;
    
        IF l_dt_set IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_img_temp := pk_sysdomain.get_img(i_lang, g_flg_stage_code_domain, l_flg_stage);
    
        g_error := 'SET COLOR BASED ON WARN';
        IF l_dt_warn <= current_timestamp
        THEN
            l_icon_type  := pk_alert_constant.g_display_type_date_icon;
            l_color      := pk_alert_constant.g_color_red;
            l_icon_color := pk_alert_constant.g_color_icon_light_grey;
            l_dt_set     := l_dt_warn;
            l_img := CASE
                         WHEN instr(l_img_temp, '|') != 0 THEN
                          substr(l_img_temp, 0, instr(l_img_temp, '|') - 1)
                         ELSE
                          l_img_temp
                     END;
        ELSE
            l_icon_type  := pk_alert_constant.g_display_type_icon;
            l_color      := NULL;
            l_icon_color := pk_alert_constant.g_color_icon_medium_grey;
            l_dt_set     := NULL;
            l_img        := substr(l_img_temp, instr(l_img_temp, '|') + 1);
        END IF;
    
        g_error := 'RETURN STATUS STRING';
        RETURN '|' || l_icon_type || '|' || CASE WHEN l_dt_set IS NULL THEN NULL ELSE pk_date_utils.date_send_tsz(i_lang,
                                                                                                                  l_dt_set,
                                                                                                                  i_prof) END || '|' || l_flg_stage || '|' || l_img || '|' || l_color || '|||' || l_icon_color || '|' || i_date;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_care_stage_grid_status;

    FUNCTION restore_care_stage_disposition
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        g_flg_stage_after_disposition CONSTANT care_stage.flg_stage%TYPE := 'WDP';
        g_pat_tracking_config         CONSTANT sys_config.id_sys_config%TYPE := 'CCHIT_PAT_TRACKING';
    
        l_date VARCHAR2(50);
    
    BEGIN
    
        g_error := 'GET PAT TRACKING CONFIG';
        IF pk_sysconfig.get_config(g_pat_tracking_config, i_prof) = pk_alert_constant.g_yes
        THEN
            IF pk_sysconfig.get_config(g_syscfg_auto_cancel_disch, i_prof) = pk_alert_constant.g_yes
            THEN
                g_error := 'SET CARE STATUS AS ' || g_flg_stage_after_disposition;
                IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_episode      => i_episode,
                                                i_flg_stage    => g_flg_stage_after_disposition,
                                                i_flg_ins_type => g_flg_ins_type_auto,
                                                o_date         => l_date,
                                                o_error        => o_error)
                THEN
                    RAISE e_call_exception;
                END IF;
            ELSE
                -- Reset state
                g_error := 'reset_care_stage_disposition ';
                IF NOT reset_care_stage_disposition(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_episode   => i_episode,
                                                    i_discharge => i_discharge,
                                                    o_error     => o_error)
                THEN
                    RAISE e_call_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_call_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'RESTORE_CARE_STAGE_DISPOSITION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END restore_care_stage_disposition;

    FUNCTION set_care_stage_disposition
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        g_flg_stage_discharge CONSTANT care_stage.flg_stage%TYPE := 'DSG';
    
        l_date VARCHAR2(50);
    
    BEGIN
        g_error := 'SET CARE STAGE AS ' || g_flg_stage_discharge;
        IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_episode      => i_episode,
                                        i_flg_stage    => g_flg_stage_discharge,
                                        i_flg_ins_type => g_flg_ins_type_auto,
                                        o_date         => l_date,
                                        o_error        => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_CARE_STAGE_DISPOSITION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_care_stage_disposition;

    FUNCTION match_care_stage
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        g_choose_definitive CONSTANT INTEGER := 1;
        g_choose_temporary  CONSTANT INTEGER := 2;
        g_no_cs_definitive  CONSTANT INTEGER := 3;
        g_no_cs_temporary   CONSTANT INTEGER := 4;
        g_none              CONSTANT INTEGER := 5;
    
        l_rows table_varchar;
        l_epis INTEGER;
    
    BEGIN
    
        g_error := 'Choose records';
        BEGIN
            SELECT CASE
                       WHEN cs1_dt_set = cs2_dt_set THEN
                        g_choose_definitive
                       WHEN cs1_dt_set > cs2_dt_set THEN
                        g_choose_definitive
                       WHEN cs1_dt_set < cs2_dt_set THEN
                        g_choose_temporary
                       WHEN cs1_dt_set IS NULL THEN
                        CASE
                            WHEN cs2_dt_set IS NULL THEN
                             g_none
                            ELSE
                             g_no_cs_definitive
                        END
                       WHEN cs2_dt_set IS NULL THEN
                        g_no_cs_temporary
                   END
              INTO l_epis
              FROM (SELECT (SELECT dt_set
                              FROM care_stage
                             WHERE id_episode = i_episode
                               AND flg_active = g_flg_active_yes) cs1_dt_set,
                           (SELECT dt_set
                              FROM care_stage
                             WHERE id_episode = i_episode_temp
                               AND flg_active = g_flg_active_yes) cs2_dt_set
                      FROM dual);
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
    
        g_error := 'Update records and set history';
        IF l_epis = g_choose_definitive
        THEN
            g_error := 'Choose definitive';
            -- definir o fluxo antigo como histórico para o episódio definitivo
            ts_care_stage.upd(id_episode_in => i_episode,
                              flg_active_in => g_flg_active_hist,
                              where_in      => 'id_episode = ' || i_episode_temp,
                              rows_out      => l_rows);
        ELSIF l_epis = g_choose_temporary
        THEN
            g_error := 'Choose temporary';
            -- definir o fluxo antigo como histórico para o episódio definitivo
            ts_care_stage.upd(id_episode_in => i_episode,
                              flg_active_in => g_flg_active_hist,
                              where_in      => 'id_episode = ' || i_episode,
                              rows_out      => l_rows);
        
            -- definir o fluxo correcto para o episódio definitivo
            ts_care_stage.upd(id_episode_in => i_episode,
                              where_in      => 'id_episode = ' || i_episode_temp,
                              rows_out      => l_rows);
        ELSIF l_epis = g_no_cs_definitive
        THEN
            g_error := 'No care stage for definitive';
            -- definir o fluxo correcto para o episódio definitivo
            ts_care_stage.upd(id_episode_in => i_episode,
                              where_in      => 'id_episode = ' || i_episode_temp,
                              rows_out      => l_rows);
        END IF;
    
        g_error := 'Process update';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'CARE_STAGE', l_rows, o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'MATCH_CARE_STAGE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END match_care_stage;

    FUNCTION set_auto_disposition_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error EXCEPTION;
        l_flg_care_stage disch_reas_dest.flg_care_stage%TYPE;
        l_date           VARCHAR2(50);
    
    BEGIN
    
        BEGIN
            g_error := 'CHECK PERMISSIONS / GET CARE STAGE STATUS';
            pk_alertlog.log_debug(g_error);
            SELECT drd.flg_care_stage
              INTO l_flg_care_stage
              FROM disch_reas_dest drd, care_stage_set_permissions cssp, prof_profile_template ppt
             WHERE drd.id_disch_reas_dest = i_id_disch_reas_dest
               AND drd.flg_care_stage = cssp.domain_val
               AND ppt.id_profile_template = cssp.id_profile_template
               AND ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
               AND cssp.flg_set = pk_alert_constant.g_yes -- Check if has permissions
               AND (cssp.id_institution = i_prof.institution
                   -- ALL other permissions should be ignored if
                   -- exists permissions for the current institution,
                   -- that's way this query doesn't join DOMAIN_VAL with "CSSP"
                   OR cssp.id_institution = 0 AND NOT EXISTS
                    (SELECT 0
                       FROM care_stage_set_permissions c1
                      WHERE c1.id_profile_template = ppt.id_profile_template
                        AND c1.id_institution = i_prof.institution));
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_care_stage := NULL;
        END;
    
        IF l_flg_care_stage IS NOT NULL
        THEN
            -- Found permissions! Insert in CARE_STAGE.
            g_error := 'INSERT CARE STAGE';
            pk_alertlog.log_debug(g_error);
            IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_episode      => i_episode,
                                            i_flg_stage    => l_flg_care_stage,
                                            i_flg_ins_type => g_flg_ins_type_auto,
                                            o_date         => l_date,
                                            o_error        => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_AUTO_DISPOSITION_STATUS',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_AUTO_DISPOSITION_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_auto_disposition_status;

    FUNCTION set_auto_opinion_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error    EXCEPTION;
        l_auto_wait_consult sys_config.value%TYPE;
        l_flg_care_stage    care_stage.flg_stage%TYPE := 'WCS';
        l_date              VARCHAR2(50);
    
    BEGIN
    
        g_error             := 'GET SYS_CONFIG ' || g_syscfg_auto_wait_consult;
        l_auto_wait_consult := pk_sysconfig.get_config(i_code_cf => g_syscfg_auto_wait_consult, i_prof => i_prof);
    
        IF l_auto_wait_consult = pk_alert_constant.g_yes
        THEN
            g_error := 'INSERT CARE STAGE';
            IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_episode      => i_episode,
                                            i_flg_stage    => l_flg_care_stage,
                                            i_flg_ins_type => g_flg_ins_type_auto,
                                            o_date         => l_date,
                                            o_error        => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_AUTO_OPINION_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_auto_opinion_status;

    FUNCTION set_after_opinion_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_status IN opinion.flg_state%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error           EXCEPTION;
        l_auto_wait_consult        sys_config.value%TYPE;
        l_care_state_after_consult sys_config.value%TYPE;
        l_total_unansw_opinions    NUMBER(24);
        l_date                     VARCHAR2(50);
    
    BEGIN
    
        g_error             := 'GET SYS_CONFIG ' || g_syscfg_auto_wait_consult;
        l_auto_wait_consult := pk_sysconfig.get_config(i_code_cf => g_syscfg_auto_wait_consult, i_prof => i_prof);
    
        IF l_auto_wait_consult = pk_alert_constant.g_yes
        THEN
            l_total_unansw_opinions := pk_opinion.get_total_unanswered_opinions(i_lang    => i_lang,
                                                                                i_prof    => i_prof,
                                                                                i_episode => i_episode);
            IF l_total_unansw_opinions = 0
            THEN
                g_error := 'GET SYS_CONFIG ' || g_syscfg_care_state_after;
                IF i_flg_status = pk_opinion.g_opinion_cancel
                THEN
                    l_care_state_after_consult := NULL;
                ELSE
                    l_care_state_after_consult := pk_sysconfig.get_config(i_code_cf => g_syscfg_care_state_after,
                                                                          i_prof    => i_prof);
                END IF;
            
                g_error := 'INSERT CARE STAGE';
                IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_episode      => i_episode,
                                                i_flg_stage    => l_care_state_after_consult,
                                                i_flg_ins_type => g_flg_ins_type_auto,
                                                o_date         => l_date,
                                                o_error        => o_error)
                THEN
                    RAISE l_internal_error;
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
                                              g_owner,
                                              g_package,
                                              'SET_AFTER_OPINION_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_after_opinion_status;

    FUNCTION set_patient_death_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_dt_deceased IN patient.dt_deceased%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error EXCEPTION;
    
        l_profile_template profile_template.id_profile_template%TYPE;
        l_epis_dt_begin    episode.dt_begin_tstz%TYPE;
        l_epis_dt_end      episode.dt_end_tstz%TYPE;
        l_pat_death_status sys_config.value%TYPE;
    
        l_count_status NUMBER;
        l_date         VARCHAR2(50);
    
    BEGIN
    
        g_error            := 'GET SYS_CONFIG';
        l_pat_death_status := pk_sysconfig.get_config(i_code_cf => g_syscfg_death_status, i_prof => i_prof);
    
        g_error            := 'GET PROFILE TEMPLATE';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        IF l_pat_death_status IS NOT NULL
           AND i_episode IS NOT NULL
        THEN
            g_error := 'CHECK STATUS PARAM';
            SELECT COUNT(*)
              INTO l_count_status
              FROM care_stage_set_permissions cs
             WHERE cs.id_profile_template = l_profile_template
               AND cs.domain_val = l_pat_death_status
               AND cs.id_institution IN (0, i_prof.institution);
        
            g_error := 'GET EPIS DT_BEGIN';
            SELECT epis.dt_begin_tstz, epis.dt_end_tstz
              INTO l_epis_dt_begin, l_epis_dt_end
              FROM episode epis
             WHERE epis.id_episode = i_episode;
        
            IF i_dt_deceased BETWEEN l_epis_dt_begin AND nvl(l_epis_dt_end, i_dt_deceased)
               AND l_count_status > 0
            THEN
                g_error := 'INSERT CARE STAGE';
                IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_episode      => i_episode,
                                                i_flg_stage    => l_pat_death_status,
                                                i_flg_ins_type => g_flg_ins_type_auto,
                                                o_date         => l_date,
                                                o_error        => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            ELSIF i_dt_deceased IS NULL -- reset patient death status
                  AND i_episode IS NOT NULL
            THEN
                IF NOT pk_patient_tracking.reset_care_stage_death(i_lang    => i_lang,
                                                                  i_prof    => i_prof,
                                                                  i_episode => i_episode,
                                                                  o_error   => o_error)
                THEN
                    pk_utils.undo_changes;
                    RETURN FALSE;
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
                                              g_owner,
                                              g_package,
                                              'SET_PATIENT_DEATH_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_patient_death_status;

    FUNCTION was_pat_already_obs(i_episode IN episode.id_episode%TYPE) RETURN VARCHAR2 IS
    
        l_was_pat_already_obs VARCHAR2(1);
    
    BEGIN
    
        SELECT nvl2(ei.dt_first_obs_tstz, pk_alert_constant.g_yes, pk_alert_constant.g_no)
          INTO l_was_pat_already_obs
          FROM epis_info ei
         WHERE ei.id_episode = i_episode;
    
        RETURN l_was_pat_already_obs;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END was_pat_already_obs;

    FUNCTION get_current_state_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_curr_flg_stage    OUT care_stage.flg_stage%TYPE,
        o_curr_flg_ins_type OUT care_stage.flg_ins_type%TYPE,
        o_curr_rank         OUT sys_domain.rank%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURRENT STATE INFO';
        BEGIN
            SELECT /*+ opt_estimate(table sd rows=1) */
             t.flg_stage, t.flg_ins_type, sd.rank
              INTO o_curr_flg_stage, o_curr_flg_ins_type, o_curr_rank
              FROM (SELECT cs.flg_stage, cs.flg_ins_type
                      FROM care_stage cs
                     WHERE cs.id_episode = i_episode
                       AND cs.flg_active = pk_alert_constant.g_yes) t
              JOIN TABLE(CAST(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_flg_stage_code_domain, NULL) AS t_coll_values_domain_mkt)) sd
                ON sd.val = t.flg_stage;
        EXCEPTION
            WHEN no_data_found THEN
                o_curr_flg_stage    := NULL;
                o_curr_flg_ins_type := NULL;
                o_curr_rank         := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_CURRENT_STATE_INFO',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_current_state_info;

    FUNCTION get_current_state_rank
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN sys_domain.rank%TYPE IS
    
        l_rank                    sys_domain.rank%TYPE;
        l_dummy_flg_stage         care_stage.flg_stage%TYPE;
        l_dummy_curr_flg_ins_type care_stage.flg_ins_type%TYPE;
    
        l_exception EXCEPTION;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET CURRENT STATE INFO';
        IF NOT get_current_state_info(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_episode           => i_episode,
                                      o_curr_flg_stage    => l_dummy_flg_stage,
                                      o_curr_flg_ins_type => l_dummy_curr_flg_ins_type,
                                      o_curr_rank         => l_rank,
                                      o_error             => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_CURRENT_STATE_RANK',
                                              l_error);
            pk_utils.undo_changes;
            RETURN NULL;
    END get_current_state_rank;

    FUNCTION get_wait_for_paym_rank
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        o_stage_wait_paym_rank OUT sys_domain.rank%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_stage sys_config.value%TYPE;
    
    BEGIN
    
        g_error     := 'GET WAINTING COMPLETION STATUS TYPE - WPY or WAP';
        l_flg_stage := pk_sysconfig.get_config(g_config_wait_compl_stat_type, i_prof);
    
        g_error := 'GET RANK OF WAITING FOR PAYMENT';
        BEGIN
            SELECT sd.rank
              INTO o_stage_wait_paym_rank
              FROM care_stage_set_permissions csp
              JOIN TABLE(CAST(pk_sysdomain.get_values_domain_pipelined(i_lang => i_lang, i_prof => i_prof, i_code_dom => g_flg_stage_code_domain, i_dep_clin_serv => NULL) AS t_coll_values_domain_mkt)) sd
                ON csp.domain_val = sd.val
             WHERE csp.domain_val = l_flg_stage
               AND csp.id_profile_template = pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
        EXCEPTION
            WHEN no_data_found THEN
                o_stage_wait_paym_rank := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_WAIT_FOR_PAYM_RANK',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_wait_for_paym_rank;

    FUNCTION get_in_treatment_rank
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_stage_in_treat_rank OUT sys_domain.rank%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET RANK OF IN TREATMENT';
        BEGIN
            SELECT t.rank
              INTO o_stage_in_treat_rank
              FROM (SELECT sd.rank,
                           row_number() over(PARTITION BY csp.id_profile_template ORDER BY csp.id_institution DESC) rn
                      FROM care_stage_set_permissions csp
                      JOIN TABLE(CAST(pk_sysdomain.get_values_domain_pipelined(i_lang => i_lang, i_prof => i_prof, i_code_dom => g_flg_stage_code_domain, i_dep_clin_serv => NULL) AS t_coll_values_domain_mkt)) sd
                        ON csp.domain_val = sd.val
                     WHERE csp.domain_val = g_flg_stage_in_treat
                       AND csp.id_profile_template = pk_prof_utils.get_prof_profile_template(i_prof => i_prof)) t
             WHERE t.rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                o_stage_in_treat_rank := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_IN_TREATMENT_RANK',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_in_treatment_rank;

    FUNCTION check_if_paym_already_made
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_is_pay_made OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_stage sys_config.value%TYPE;
    
        l_one CONSTANT PLS_INTEGER := 1;
    
    BEGIN
    
        g_error     := 'GET COMPLETION DONE STATUS TYPE - PYM or APD';
        l_flg_stage := pk_sysconfig.get_config(g_config_compl_done_stat_type, i_prof);
    
        g_error := 'VERIFY IF PAYMENT WAS ALREADY MADE';
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO o_is_pay_made
              FROM (SELECT cs.flg_stage, row_number() over(ORDER BY cs.dt_set DESC) line_number
                      FROM care_stage cs
                     WHERE cs.id_episode = i_episode
                       AND cs.flg_stage = l_flg_stage) t
             WHERE t.line_number = l_one;
        EXCEPTION
            WHEN no_data_found THEN
                o_is_pay_made := pk_alert_constant.g_no;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_IF_PAYM_ALREADY_MADE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_if_paym_already_made;

    FUNCTION set_care_stage_triage
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_curr_flg_stage         care_stage.flg_stage%TYPE;
        l_curr_flg_ins_type      care_stage.flg_ins_type%TYPE;
        l_curr_rank              sys_domain.rank%TYPE;
        l_is_made                VARCHAR2(1);
        l_was_pat_already_obs    VARCHAR2(1);
        l_stage_wait_rank        sys_domain.rank%TYPE;
        l_date                   VARCHAR2(50);
        l_new_flg_stage          care_stage.flg_stage%TYPE;
        l_wait_compl_status_type sys_config.value%TYPE;
        l_compl_status_type      sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'CALL GET_CURRENT_STATE_INFO';
        IF NOT get_current_state_info(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_episode           => i_episode,
                                      o_curr_flg_stage    => l_curr_flg_stage,
                                      o_curr_flg_ins_type => l_curr_flg_ins_type,
                                      o_curr_rank         => l_curr_rank,
                                      o_error             => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        g_error := 'CALL GET_WAIT_FOR_CONCLUSION_RANK';
        IF NOT get_wait_for_paym_rank(i_lang                 => i_lang,
                                      i_prof                 => i_prof,
                                      o_stage_wait_paym_rank => l_stage_wait_rank,
                                      o_error                => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        g_error := 'CALL CHECK_IF_CONCLUSION_IS_ALREADY_MADE';
        IF NOT check_if_paym_already_made(i_lang        => i_lang,
                                          i_prof        => i_prof,
                                          i_episode     => i_episode,
                                          o_is_pay_made => l_is_made,
                                          o_error       => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        g_error               := 'CALL WAS_PAT_ALREADY_OBS';
        l_was_pat_already_obs := was_pat_already_obs(i_episode => i_episode);
    
        g_error                  := 'GET WAITING COMPLETION STATUS TYPE - WPY,WAP';
        l_wait_compl_status_type := pk_sysconfig.get_config(g_config_wait_compl_stat_type, i_prof);
    
        g_error             := 'GET WAITING COMPLETION STATUS TYPE - PYM,APD';
        l_compl_status_type := pk_sysconfig.get_config(g_config_compl_done_stat_type, i_prof);
    
        --The following conditions must be verified before updating the care state to 'WAITING FOR PAYMENT' (WPY)
        -- 1 - When l_stage_wait_rank is null means that this state isn't available for the current market, and we must ignore this action
        -- 2 - Only update to WPY if current state is previous to WPY or current state is null 
        -- 3 - Only update to WPY if current state record was not manually set
        -- 4 - Payment wasn't made
        IF (l_stage_wait_rank IS NOT NULL AND
           ((l_curr_rank IS NULL) OR (l_curr_rank IS NOT NULL AND l_curr_rank < l_stage_wait_rank)) AND
           (l_curr_flg_ins_type IS NULL OR l_curr_flg_ins_type != g_flg_ins_type_man) AND
           l_is_made = pk_alert_constant.g_no)
        THEN
            l_new_flg_stage := l_wait_compl_status_type;
            --When all the above conditions are verified, payment has been made and patient wasn't observed 
            --set de care stage to 'Payment made' (PYM)
        ELSIF (l_stage_wait_rank IS NOT NULL AND
              ((l_curr_rank IS NULL) OR (l_curr_rank IS NOT NULL AND l_curr_rank < l_stage_wait_rank)) AND
              (l_curr_flg_ins_type IS NULL OR l_curr_flg_ins_type != g_flg_ins_type_man) AND
              l_is_made = pk_alert_constant.g_yes AND l_was_pat_already_obs = pk_alert_constant.g_yes)
        THEN
            l_new_flg_stage := l_compl_status_type;
            --When all the above conditions are verified, payment has been made and patient was already observed 
            --set de care stage to 'In Treatment' (ITM)
        ELSIF (l_stage_wait_rank IS NOT NULL AND
              ((l_curr_rank IS NULL) OR (l_curr_rank IS NOT NULL AND l_curr_rank < l_stage_wait_rank)) AND
              (l_curr_flg_ins_type IS NULL OR l_curr_flg_ins_type != g_flg_ins_type_man) AND
              l_is_made = pk_alert_constant.g_yes AND l_was_pat_already_obs = pk_alert_constant.g_yes)
        THEN
            l_new_flg_stage := g_flg_stage_in_treat;
        END IF;
    
        IF l_new_flg_stage IS NOT NULL
        THEN
            g_error := 'SET CARE STAGE AS ' || l_new_flg_stage;
            IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_episode      => i_episode,
                                            i_flg_stage    => l_new_flg_stage,
                                            i_flg_ins_type => g_flg_ins_type_auto,
                                            o_date         => l_date,
                                            o_error        => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_call_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_CARE_STAGE_TRIAGE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_care_stage_triage;

    FUNCTION set_cs_payment_made
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_date                VARCHAR2(50);
        l_was_pat_already_obs VARCHAR2(1);
        l_status_type         sys_config.value%TYPE;
    
    BEGIN
        g_error               := 'CALL WAS_PAT_ALREADY_OBS';
        l_was_pat_already_obs := was_pat_already_obs(i_episode => i_episode);
    
        g_error       := 'GET COMPLETION DONE STATUS TYPE';
        l_status_type := pk_sysconfig.get_config(g_config_compl_done_stat_type, i_prof);
    
        IF l_was_pat_already_obs = pk_alert_constant.g_no
        THEN
            g_error := 'SET CARE STAGE AS ' || l_status_type;
            IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_episode      => i_episode,
                                            i_flg_stage    => l_status_type,
                                            i_flg_ins_type => g_flg_ins_type_int,
                                            i_flg_active   => g_flg_active_yes,
                                            o_date         => l_date,
                                            o_error        => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        ELSE
            g_error := 'ADD CARE STAGE ' || l_status_type;
            IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_episode      => i_episode,
                                            i_flg_stage    => l_status_type,
                                            i_flg_ins_type => g_flg_ins_type_int,
                                            i_flg_active   => g_flg_active_no,
                                            o_date         => l_date,
                                            o_error        => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
            g_error := 'SET CARE STAGE AS ' || g_flg_stage_in_treat;
            IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_episode      => i_episode,
                                            i_flg_stage    => g_flg_stage_in_treat,
                                            i_flg_ins_type => g_flg_ins_type_auto,
                                            o_date         => l_date,
                                            o_error        => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_call_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_CS_PAYMENT_MADE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_cs_payment_made;

    FUNCTION set_cs_wait_fr_payment
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_date        VARCHAR2(50);
        l_status_type sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'I_EPISODE ' || i_episode;
        IF (i_episode IS NULL)
        THEN
            RAISE e_call_exception;
        END IF;
    
        g_error       := 'GET WAITING COMPLETION STATUS TYPE';
        l_status_type := pk_sysconfig.get_config(g_config_wait_compl_stat_type, i_prof);
    
        g_error := 'SET CARE STAGE AS ' || l_status_type;
        IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_episode      => i_episode,
                                        i_flg_stage    => l_status_type,
                                        i_flg_ins_type => g_flg_ins_type_int,
                                        i_flg_active   => g_flg_active_yes,
                                        o_date         => l_date,
                                        o_error        => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_call_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_CS_WAIT_FR_PAYMENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_cs_wait_fr_payment;

    FUNCTION set_care_stage_in_treat
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_triage_call IN VARCHAR2,
        i_flg_er_law      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_curr_flg_stage      care_stage.flg_stage%TYPE;
        l_curr_flg_ins_type   care_stage.flg_ins_type%TYPE;
        l_curr_rank           sys_domain.rank%TYPE;
        l_stage_in_treat_rank sys_domain.rank%TYPE;
        l_is_pay_made         VARCHAR2(1);
        l_date                VARCHAR2(50);
    
        l_new_flg_stage care_stage.flg_stage%TYPE;
    
    BEGIN
    
        IF i_flg_triage_call = pk_alert_constant.g_no
        THEN
            g_error := 'CALL GET_CURRENT_STATE_INFO';
            IF NOT get_current_state_info(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_episode           => i_episode,
                                          o_curr_flg_stage    => l_curr_flg_stage,
                                          o_curr_flg_ins_type => l_curr_flg_ins_type,
                                          o_curr_rank         => l_curr_rank,
                                          o_error             => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
            g_error := 'CALL GET_IN_TREATMENT_RANK';
            IF NOT get_in_treatment_rank(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         o_stage_in_treat_rank => l_stage_in_treat_rank,
                                         o_error               => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
            g_error := 'CALL CHECK_IF_PAYM_ALREADY_MADE';
            IF NOT check_if_paym_already_made(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_episode     => i_episode,
                                              o_is_pay_made => l_is_pay_made,
                                              o_error       => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
            IF nvl(l_curr_flg_ins_type, g_flg_ins_type_auto) != g_flg_ins_type_man
               AND (l_is_pay_made = pk_alert_constant.g_yes OR
                    nvl(i_flg_er_law, pk_alert_constant.g_no) = pk_alert_constant.g_yes)
               AND (l_curr_rank IS NULL OR l_curr_rank < l_stage_in_treat_rank)
            THEN
                l_new_flg_stage := g_flg_stage_in_treat;
            END IF;
        
            IF l_new_flg_stage IS NOT NULL
            THEN
                g_error := 'SET CARE STAGE AS ' || l_new_flg_stage;
                IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_episode      => i_episode,
                                                i_flg_stage    => l_new_flg_stage,
                                                i_flg_ins_type => g_flg_ins_type_auto,
                                                o_date         => l_date,
                                                o_error        => o_error)
                THEN
                    RAISE e_call_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_call_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_CARE_STAGE_IN_TREAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_care_stage_in_treat;

    FUNCTION reset_care_stage_er_law
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_two CONSTANT PLS_INTEGER := 2;
    
        l_curr_flg_stage      care_stage.flg_stage%TYPE;
        l_curr_flg_ins_type   care_stage.flg_ins_type%TYPE;
        l_curr_rank           sys_domain.rank%TYPE;
        l_stage_in_treat_rank sys_domain.rank%TYPE;
        l_is_made             VARCHAR2(1);
        l_was_pat_already_obs VARCHAR2(1);
        l_date                VARCHAR2(50);
    
        l_new_flg_stage          care_stage.flg_stage%TYPE;
        l_wait_compl_status_type sys_config.value%TYPE;
        l_compl_status_type      sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'CALL GET_CURRENT_STATE_INFO';
        IF NOT get_current_state_info(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_episode           => i_episode,
                                      o_curr_flg_stage    => l_curr_flg_stage,
                                      o_curr_flg_ins_type => l_curr_flg_ins_type,
                                      o_curr_rank         => l_curr_rank,
                                      o_error             => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        g_error := 'CALL GET_IN_TREATMENT_RANK';
        IF NOT get_in_treatment_rank(i_lang                => i_lang,
                                     i_prof                => i_prof,
                                     o_stage_in_treat_rank => l_stage_in_treat_rank,
                                     o_error               => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        g_error := 'CALL CHECK_IF_CONCLUSION_IS_ALREADY_MADE';
        IF NOT check_if_paym_already_made(i_lang        => i_lang,
                                          i_prof        => i_prof,
                                          i_episode     => i_episode,
                                          o_is_pay_made => l_is_made,
                                          o_error       => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        g_error               := 'CALL WAS_PAT_ALREADY_OBS';
        l_was_pat_already_obs := was_pat_already_obs(i_episode => i_episode);
    
        g_error                  := 'GET WAITING COMPLETION STATUS TYPE - WPY,WAP';
        l_wait_compl_status_type := pk_sysconfig.get_config(g_config_wait_compl_stat_type, i_prof);
    
        g_error             := 'GET WAITING COMPLETION STATUS TYPE - PYM,APD';
        l_compl_status_type := pk_sysconfig.get_config(g_config_compl_done_stat_type, i_prof);
    
        IF l_curr_flg_ins_type != g_flg_ins_type_man
           AND l_is_made = pk_alert_constant.g_yes
           AND l_was_pat_already_obs = pk_alert_constant.g_yes
           AND (l_curr_rank IS NULL OR l_curr_rank <= l_stage_in_treat_rank)
        THEN
            l_new_flg_stage := g_flg_stage_in_treat;
        ELSIF l_curr_flg_ins_type != g_flg_ins_type_man
              AND l_is_made = pk_alert_constant.g_yes
              AND l_was_pat_already_obs = pk_alert_constant.g_no
              AND (l_curr_rank IS NULL OR l_curr_rank <= l_stage_in_treat_rank)
        THEN
            l_new_flg_stage := l_compl_status_type;
        ELSIF l_curr_flg_ins_type != g_flg_ins_type_man
              AND l_is_made = pk_alert_constant.g_no
              AND (l_curr_rank IS NULL OR l_curr_rank <= l_stage_in_treat_rank)
        THEN
            BEGIN
                SELECT t.flg_stage
                  INTO l_new_flg_stage
                  FROM (SELECT cs.flg_stage, row_number() over(ORDER BY cs.dt_set DESC) line_number
                          FROM care_stage cs
                         WHERE cs.id_episode = i_episode) t
                 WHERE t.line_number = l_two;
            EXCEPTION
                WHEN no_data_found THEN
                    l_new_flg_stage := l_wait_compl_status_type;
            END;
        END IF;
    
        IF l_new_flg_stage IS NOT NULL
           AND l_curr_flg_stage != l_new_flg_stage
        THEN
            g_error := 'SET CARE STAGE AS ' || l_new_flg_stage;
            IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_episode      => i_episode,
                                            i_flg_stage    => l_new_flg_stage,
                                            i_flg_ins_type => g_flg_ins_type_auto,
                                            o_date         => l_date,
                                            o_error        => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_call_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'RESET_CARE_STAGE_ER_LAW',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END reset_care_stage_er_law;

    FUNCTION reset_care_stage_disposition
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_care_stage     disch_reas_dest.flg_care_stage%TYPE;
        l_curr_flg_stage     care_stage.flg_stage%TYPE;
        l_curr_flg_ins_type  care_stage.flg_ins_type%TYPE;
        l_previous_flg_stage care_stage.flg_stage%TYPE;
        l_curr_rank          sys_domain.rank%TYPE;
        l_two                PLS_INTEGER := 2;
        l_date               VARCHAR2(50);
    
    BEGIN
    
        BEGIN
            g_error := 'CHECK PERMISSIONS / GET CARE STAGE STATUS';
            SELECT drd.flg_care_stage
              INTO l_flg_care_stage
              FROM discharge d, disch_reas_dest drd, care_stage_set_permissions cssp, prof_profile_template ppt
             WHERE d.id_discharge = i_discharge
               AND d.id_disch_reas_dest = drd.id_disch_reas_dest
               AND drd.flg_care_stage = cssp.domain_val
               AND ppt.id_profile_template = cssp.id_profile_template
               AND ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
               AND cssp.flg_set = pk_alert_constant.g_yes -- Check if has permissions
               AND (cssp.id_institution = i_prof.institution
                   -- ALL other permissions should be ignored if
                   -- exists permissions for the current institution,
                   -- that's way this query doesn't join DOMAIN_VAL with "CSSP"
                   OR cssp.id_institution = 0 AND NOT EXISTS
                    (SELECT 0
                       FROM care_stage_set_permissions c1
                      WHERE c1.id_profile_template = ppt.id_profile_template
                        AND c1.id_institution = i_prof.institution));
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_care_stage := NULL;
        END;
    
        IF l_flg_care_stage IS NOT NULL
        THEN
            IF NOT get_current_state_info(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_episode           => i_episode,
                                          o_curr_flg_stage    => l_curr_flg_stage,
                                          o_curr_flg_ins_type => l_curr_flg_ins_type,
                                          o_curr_rank         => l_curr_rank,
                                          o_error             => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
            IF l_flg_care_stage = l_curr_flg_stage
            THEN
                BEGIN
                    SELECT t.flg_stage
                      INTO l_previous_flg_stage
                      FROM (SELECT cs.flg_stage, row_number() over(ORDER BY cs.dt_set DESC) line_number
                              FROM care_stage cs
                             WHERE cs.id_episode = i_episode) t
                     WHERE t.line_number = l_two;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_previous_flg_stage := NULL;
                END;
                g_error := 'SET CARE STAGE AS ' || l_previous_flg_stage;
                IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_episode      => i_episode,
                                                i_flg_stage    => l_previous_flg_stage,
                                                i_flg_ins_type => g_flg_ins_type_auto,
                                                o_date         => l_date,
                                                o_error        => o_error)
                THEN
                    RAISE e_call_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_call_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'RESET_CARE_STAGE_DISPOSITION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END reset_care_stage_disposition;

    FUNCTION set_auto_reopen_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error   EXCEPTION;
        l_auto_reopen_epis sys_config.value%TYPE;
        l_flg_care_stage   care_stage.flg_stage%TYPE;
        l_date             VARCHAR2(50);
    
    BEGIN
    
        g_error            := 'GET SYS_CONFIG ' || g_syscfg_auto_wait_consult;
        l_auto_reopen_epis := pk_sysconfig.get_config(g_syscfg_auto_reopen_epis, i_prof);
        l_flg_care_stage   := pk_sysconfig.get_config(g_syscfg_reopen_status, i_prof);
    
        IF l_auto_reopen_epis = pk_alert_constant.g_yes
        THEN
            g_error := 'INSERT CARE STAGE';
            IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_episode      => i_episode,
                                            i_flg_stage    => l_flg_care_stage,
                                            i_flg_ins_type => g_flg_ins_type_auto,
                                            o_date         => l_date,
                                            o_error        => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_AUTO_REOPEN_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_auto_reopen_status;

    FUNCTION reset_care_stage_death
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pat_death_status   disch_reas_dest.flg_care_stage%TYPE;
        l_curr_flg_stage     care_stage.flg_stage%TYPE;
        l_curr_flg_ins_type  care_stage.flg_ins_type%TYPE;
        l_previous_flg_stage care_stage.flg_stage%TYPE;
        l_curr_rank          sys_domain.rank%TYPE;
        l_two                PLS_INTEGER := 2;
        l_date               VARCHAR2(50);
    
    BEGIN
    
        g_error            := 'GET CARE STAGE _DEATH';
        l_pat_death_status := pk_sysconfig.get_config(g_syscfg_death_status, i_prof);
    
        IF l_pat_death_status IS NOT NULL
        THEN
            IF NOT get_current_state_info(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_episode           => i_episode,
                                          o_curr_flg_stage    => l_curr_flg_stage,
                                          o_curr_flg_ins_type => l_curr_flg_ins_type,
                                          o_curr_rank         => l_curr_rank,
                                          o_error             => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        
            IF l_pat_death_status = l_curr_flg_stage
            THEN
                BEGIN
                    SELECT t.flg_stage
                      INTO l_previous_flg_stage
                      FROM (SELECT cs.flg_stage, row_number() over(ORDER BY cs.dt_set DESC) line_number
                              FROM care_stage cs
                             WHERE cs.id_episode = i_episode) t
                     WHERE t.line_number = l_two;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_previous_flg_stage := NULL;
                END;
                g_error := 'SET CARE STAGE AS ' || l_previous_flg_stage;
                IF NOT set_care_stage_no_commit(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_episode      => i_episode,
                                                i_flg_stage    => l_previous_flg_stage,
                                                i_flg_ins_type => g_flg_ins_type_auto,
                                                o_date         => l_date,
                                                o_error        => o_error)
                THEN
                    RAISE e_call_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_call_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'RESET_CARE_STAGE_DEATH',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END reset_care_stage_death;

BEGIN
    -- Initialization
    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(g_package);
END pk_patient_tracking;
/
