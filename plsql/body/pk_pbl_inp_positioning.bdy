/*-- Last Change Revision: $Rev: 2052495 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-12-07 14:57:50 +0000 (qua, 07 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_pbl_inp_positioning IS

    internal_error_exception EXCEPTION;

    -- Author  : GUSTAVO.SERRANO
    -- Created : 13-11-2009 12:23:20
    -- Purpose : API functions for external modules

    /********************************************************************************************
    * get all tasks information to show in CPOE grid
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    * @param       i_episode                 episode id
    * @param       i_task_request            array of task requests (if null, return all tasks as usual)
    * @param       i_filter_tstz             Date to filter only the records with "end dates" > i_filter_tstz
    * @param       i_filter_status           Array with task status to consider along with i_filter_tstz
    * @param       i_flg_report              Required in all get_task_list APIs
    * @param       o_grid                    cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    ********************************************************************************************/
    FUNCTION get_task_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        i_flg_report    IN VARCHAR2 DEFAULT 'N',
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_plan_list     OUT pk_types.cursor_type,
        o_grid          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancelled_task_filter_interval sys_config.value%TYPE := pk_sysconfig.get_config('CPOE_CANCELLED_TASK_FILTER_INTERVAL',
                                                                                          i_prof);
        l_cancelled_task_filter_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_cancelled_task_filter_tstz := current_timestamp -
                                        numtodsinterval(to_number(l_cancelled_task_filter_interval), 'DAY');
        g_sysdate_tstz               := current_timestamp;
    
        g_error := 'OPEN o_grid';
        OPEN o_grid FOR
            SELECT pk_alert_constant.g_task_type_positioning task_type,
                   decode(i_flg_report,
                          pk_alert_constant.g_yes,
                          pk_inp_positioning.get_positioning_concat(i_lang,
                                                                    i_prof,
                                                                    ep.id_epis_positioning,
                                                                    NULL,
                                                                    i_flg_report),
                          pk_translation.get_translation(i_lang, 'POSITIONING.CODE_POSITIONING.' || epd.id_positioning)) task_description,
                   ep.id_professional id_professional,
                   NULL icon_warning,
                   pk_utils.get_status_string_immediate(i_lang, --i_lang
                                                         i_prof, --i_prof
                                                         CASE
                                                             WHEN ep.flg_status IN
                                                                  (g_epis_posit_d, g_epis_posit_c, g_epis_posit_i, g_epis_posit_f, g_epis_posit_o) THEN
                                                              pk_alert_constant.g_display_type_icon
                                                             ELSE
                                                              pk_alert_constant.g_display_type_date
                                                         END, --i_display_type 
                                                         CASE
                                                             WHEN ep.flg_status IN (g_epis_posit_i) THEN
                                                              epp.flg_status
                                                             ELSE
                                                              ep.flg_status
                                                         END, --i_flg_state
                                                         NULL, --i_value_text
                                                         CASE
                                                             WHEN ep.flg_status IN
                                                                  (g_epis_posit_d, g_epis_posit_c, g_epis_posit_i, g_epis_posit_f, g_epis_posit_o) THEN
                                                              NULL
                                                             ELSE
                                                              pk_date_utils.to_char_insttimezone(i_prof,
                                                                                                 epp.dt_prev_plan_tstz,
                                                                                                 pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)
                                                         
                                                         END, --i_value_date
                                                         CASE
                                                             WHEN ep.flg_status IN (g_epis_posit_i, g_epis_posit_f) THEN
                                                              'EPIS_POSITIONING_PLAN.FLG_STATUS'
                                                             ELSE
                                                              'EPIS_POSITIONING.FLG_STATUS'
                                                         END, --i_value_icon
                                                         NULL, --i_shortcut
                                                         --
                                                         NULL, --i_back_color 
                                                         NULL, --i_icon_color
                                                         NULL, --i_message_style
                                                         NULL, --i_message_color
                                                         NULL, --i_flg_text_domain
                                                         g_sysdate_tstz --i_dt_server
                                                         ) status_str,
                   ep.id_epis_positioning id_request,
                   epp.dt_prev_plan_tstz start_date_tstz,
                   decode(ep.flg_status,
                          g_epis_posit_i,
                          ep.dt_inter_tstz,
                          g_epis_posit_c,
                          ep.dt_cancel_tstz,
                          g_epis_posit_o,
                          ep.dt_cancel_tstz,
                          NULL) end_date_tstz,
                   nvl(ep.update_time, ep.create_time) creation_date_tstz,
                   ep.flg_status,
                   decode(ep.flg_status,
                          g_epis_posit_r,
                          pk_alert_constant.g_yes,
                          g_epis_posit_i,
                          pk_alert_constant.g_no,
                          g_epis_posit_c,
                          pk_alert_constant.g_no,
                          g_epis_posit_e,
                          pk_alert_constant.g_yes,
                          g_epis_posit_d,
                          pk_alert_constant.g_yes,
                          g_epis_posit_o,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_no) flg_cancel,
                   pk_alert_constant.g_no flg_conflit,
                   NULL id_task,
                   --New Fields for CPOE API in Reports
                   --ALERT-202996 (AN)
                   decode(i_flg_report,
                          pk_alert_constant.g_yes,
                          pk_inp_positioning.get_positioning_concat(i_lang,
                                                                    i_prof,
                                                                    ep.id_epis_positioning,
                                                                    NULL,
                                                                    i_flg_report)) task_title,
                   decode(i_flg_report,
                          pk_alert_constant.g_yes,
                          decode(ep.rot_interval,
                                 NULL,
                                 NULL,
                                 pk_inp_positioning.get_rot_interv_format(ep.rot_interval) ||
                                 pk_message.get_message(i_lang, pk_inp_positioning.g_hour_sign))) task_instructions,
                   decode(i_flg_report,
                          pk_alert_constant.g_yes,
                          decode(ep.flg_massage,
                                 NULL,
                                 '',
                                 pk_message.get_message(i_lang, 'POSITIONING_T004') || ': ' ||
                                 pk_sysdomain.get_domain(pk_inp_positioning.g_yes_no, ep.flg_massage, i_lang) || chr(13)) ||
                          decode(coalesce(ep.notes_cancel, ep.notes_inter, ep.notes),
                                 NULL,
                                 NULL,
                                 decode(ep.flg_status,
                                        pk_inp_positioning.g_epis_posit_c,
                                        ep.notes_cancel,
                                        pk_inp_positioning.g_epis_posit_o,
                                        ep.notes_cancel,
                                        pk_inp_positioning.g_epis_posit_i,
                                        ep.notes_inter,
                                        ep.notes))) task_notes,
                   NULL drug_dose,
                   NULL drug_route,
                   NULL drug_take_in_case,
                   decode(i_flg_report,
                          pk_alert_constant.g_yes,
                          pk_sysdomain.get_domain(pk_inp_positioning.g_epis_pos_status, ep.flg_status, i_lang)) task_status,
                   NULL AS instr_bg_color,
                   NULL AS instr_bg_alpha,
                   NULL AS task_icon,
                   pk_alert_constant.g_no AS flg_need_ack,
                   NULL AS edit_icon,
                   NULL AS action_desc,
                   NULL AS previous_status,
                   pk_alert_constant.g_task_inp_positioning AS id_task_type_source,
                   NULL AS id_task_dependency,
                   decode(ep.flg_status,
                          pk_inp_positioning.g_epis_posit_c,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_rep_cancel,
                   NULL flg_prn_conditional
              FROM epis_positioning ep
             INNER JOIN epis_positioning_det epd
                ON epd.id_epis_positioning = ep.id_epis_positioning
             INNER JOIN epis_positioning_plan epp
                ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
             WHERE ep.id_episode = i_episode
               AND ep.flg_origin = pk_inp_positioning.g_flg_origin_n
               AND ep.flg_status != g_epis_posit_l
               AND epp.flg_status NOT IN (g_epis_posit_l)
               AND epp.id_epis_positioning_plan IN
                   (SELECT MAX(epp1.id_epis_positioning_plan)
                      FROM epis_positioning_plan epp1
                     WHERE epp1.id_epis_positioning_det IN
                           (SELECT epd1.id_epis_positioning_det
                              FROM epis_positioning_det epd1
                             WHERE epd1.id_epis_positioning = ep.id_epis_positioning))
               AND (i_task_request IS NULL OR
                   ep.id_epis_positioning IN (SELECT /*+ OPT_ESTIMATE (TABLE d ROWS=1)*/
                                                d.column_value
                                                 FROM TABLE(i_task_request) d))
               AND (ep.flg_status NOT IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                           t.column_value
                                            FROM TABLE(i_filter_status) t) OR
                   ((i_filter_tstz < CASE
                       WHEN ep.flg_status = g_epis_posit_o THEN
                        nvl(ep.dt_cancel_tstz, ep.dt_inter_tstz) --
                       WHEN ep.flg_status = g_epis_posit_i THEN
                        nvl(ep.dt_inter_tstz, ep.dt_cancel_tstz) --   
                       ELSE
                        ep.dt_creation_tstz
                   END) AND ep.flg_status != g_epis_posit_c) OR
                   (l_cancelled_task_filter_tstz < ep.dt_cancel_tstz AND ep.flg_status = g_epis_posit_c))
             ORDER BY pk_sysdomain.get_rank(i_lang, 'EPIS_POSITIONING_PLAN.FLG_STATUS', epp.flg_status),
                      epp.id_epis_positioning_plan DESC;
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
        
            IF NOT get_order_plan_report(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_episode       => i_episode,
                                         i_task_request  => i_task_request,
                                         i_cpoe_dt_begin => i_dt_begin,
                                         i_cpoe_dt_end   => i_dt_end,
                                         o_plan_rep      => o_plan_list,
                                         o_error         => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
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
                                              'GET_TASK_LIST',
                                              o_error);
            pk_types.open_cursor_if_closed(o_grid);
            RETURN FALSE;
    END get_task_list;

    /********************************************************************************************
    * get tasks status based in their requests
    *
    * @param       i_lang                 language id    
    * @param       i_prof                 professional structure
    * @param       i_episode              episode id
    * @param       i_task_request         array of requests that identifies the tasks
    * @param       o_task_status          cursor with all requested task status
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false   
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.1.x
    * @since                          02-Sep-2010 
    ********************************************************************************************/
    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN o_grid';
        OPEN o_task_status FOR
            SELECT pk_alert_constant.g_task_type_positioning id_task_type,
                   ep.id_epis_positioning                    id_task_request,
                   ep.flg_status
              FROM epis_positioning ep
              JOIN epis_positioning_det epd
                ON epd.id_epis_positioning = ep.id_epis_positioning
              JOIN epis_positioning_plan epp
                ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
             WHERE ep.id_episode = i_episode
               AND ep.flg_status != g_epis_posit_l
               AND epp.flg_status NOT IN (g_epis_posit_l, pk_inp_positioning.g_epis_posit_o)
               AND epp.id_epis_positioning_plan IN
                   (SELECT MAX(epp1.id_epis_positioning_plan)
                      FROM epis_positioning_plan epp1
                     WHERE epp1.id_epis_positioning_det IN
                           (SELECT epd1.id_epis_positioning_det
                              FROM epis_positioning_det epd1
                             WHERE epd1.id_epis_positioning = ep.id_epis_positioning))
               AND (i_task_request IS NULL OR
                   ep.id_epis_positioning IN (SELECT /*+ OPT_ESTIMATE (TABLE d ROWS=1)*/
                                                d.column_value
                                                 FROM TABLE(i_task_request) d));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_STATUS',
                                              o_error);
            pk_types.open_cursor_if_closed(o_task_status);
            RETURN FALSE;
    END get_task_status;

    /********************************************************************************************
    * create draft task 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * 
    * @param       param1                    param1
    * @param       param2                    param2
    * @param       param3                    param3
    * ...          ...                       ...
    * @param       paramN                    paramN
    * 
    * @param       o_draft                   list of created drafts
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION create_draft
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_posit         IN table_number,
        i_rot_interv    IN rotation_interval.interval%TYPE,
        i_id_rot_interv IN rotation_interval.id_rotation_interval%TYPE,
        i_flg_massage   IN epis_positioning.flg_massage%TYPE,
        i_notes         IN epis_positioning.notes%TYPE,
        i_pos_type      IN positioning_type.id_positioning_type%TYPE,
        o_draft         OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Call to PK_INP_POSITIONING.CREATE_EPIS_POSITIONING for id_episode: ' || i_episode ||
                   ' with rot_interval: ' || i_rot_interv;
        pk_alertlog.log_debug(text            => 'Call to PK_INP_POSITIONING.CREATE_EPIS_POSITIONING for id_episode: ' ||
                                                 i_episode || ' with rot_interval: ' || i_rot_interv,
                              object_name     => 'PK_PBL_INP_POSITIONING',
                              sub_object_name => 'CREATE_EPIS_POSITIONING');
        IF NOT pk_inp_positioning.create_epis_positioning(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_episode       => i_episode,
                                                          i_posit         => i_posit,
                                                          i_rot_interv    => i_rot_interv,
                                                          i_id_rot_interv => i_id_rot_interv,
                                                          i_flg_massage   => i_flg_massage,
                                                          i_notes         => i_notes,
                                                          i_pos_type      => i_pos_type,
                                                          i_flg_type      => pk_inp_positioning.g_epis_posit_d,
                                                          o_rows          => o_draft,
                                                          o_error         => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DRAFT',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DRAFT',
                                              o_error);
            RETURN FALSE;
    END create_draft;

    /********************************************************************************************
    * cancel draft task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_draft                   list of draft ids
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION cancel_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_error VARCHAR2(4000) := NULL;
    BEGIN
        FOR i IN 1 .. i_draft.count
        LOOP
            g_error := 'Call to PK_INP_POSITIONING.CANCEL_EPIS_POSITIONING for id_epis_pos: ' || i_draft(i) ||
                       ' on iteration: ' || i;
            pk_alertlog.log_debug(text            => 'Call to PK_INP_POSITIONING.CANCEL_EPIS_POSITIONING for id_epis_pos: ' ||
                                                     i_draft(i) || ' on iteration: ' || i,
                                  object_name     => 'PK_PBL_INP_POSITIONING',
                                  sub_object_name => 'CANCEL_DRAFT');
        
            IF NOT pk_inp_positioning.set_epis_pos_status(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_epis_pos         => i_draft(i),
                                                          i_flg_status       => g_epis_posit_l,
                                                          i_notes            => NULL,
                                                          i_id_cancel_reason => NULL,
                                                          o_msg_error        => l_msg_error,
                                                          o_error            => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DRAFT',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DRAFT',
                                              o_error);
            RETURN FALSE;
    END cancel_draft;

    /********************************************************************************************
    * cancel all draft tasks
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false    
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.1.x
    * @since                          02-Sep-2010 
    ********************************************************************************************/
    FUNCTION cancel_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_drafts table_number;
    BEGIN
        --GET EPISODE drafts
        g_error := 'GET drafts';
        SELECT ep.id_epis_positioning
          BULK COLLECT
          INTO l_drafts
          FROM epis_positioning ep
         WHERE ep.id_episode = i_episode
           AND ep.flg_status = pk_inp_positioning.g_epis_posit_d;
    
        IF NOT cancel_draft(i_lang    => i_lang,
                            i_prof    => i_prof,
                            i_episode => i_episode,
                            i_draft   => l_drafts,
                            o_error   => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ALL_DRAFTS',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ALL_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END cancel_all_drafts;

    /******************************************************************************************** 
    * Check conflicts upon created drafts (verify if drafts can be requested or not) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_draft                   draft id 
    * @param       o_flg_conflict            array of draft conflicts indicators
    * @param       o_msg_template            array of message/pop-up templates
    * @param       o_msg_title               array of message titles 
    * @param       o_msg_body                array of message bodies
    * @param       o_error                   error message 
    * 
    * @value       o_flg_conflict            {*} 'Y' the draft has conflicts  
    *                                        {*} 'N' no conflicts found 
    *    
    * @value       o_msg_template            {*} ' WARNING_READ' Warning Read
    *                                        {*} 'WARNING_CONFIRMATION' Warning Confirmation
    *                                        {*} 'WARNING_CANCEL' Warning Cancel
    *                                        {*} 'WARNING_HELP_SAVE' Warning Help Save
    *                                        {*} 'WARNING_SECURITY' Warning Security
    *                                        {*} 'CONFIRMATION' Confirmation
    *                                        {*} 'DETAIL' Detail
    *                                        {*} 'HELP' Help
    *                                        {*} 'WIZARD' Wizard
    *                                        {*} 'ADVANCED_INPUT' Advanced Input
    *         
    * @return                                True on success, false otherwise
    ********************************************************************************************/
    FUNCTION check_drafts_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT NOCOPY table_varchar,
        o_msg_template OUT NOCOPY table_varchar,
        o_msg_title    OUT NOCOPY table_varchar,
        o_msg_body     OUT NOCOPY table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_epis_pos(l_id_epis_pos epis_positioning.id_epis_positioning%TYPE) IS
            SELECT ep.*
              FROM epis_positioning ep
             WHERE ep.id_epis_positioning = l_id_epis_pos;
        --
        l_flg_conflict table_varchar := table_varchar();
        l_msg_template table_varchar := table_varchar();
        l_msg_title    table_varchar := table_varchar();
        l_msg_body     table_varchar := table_varchar();
    
    BEGIN
        g_error := 'PK_PBL_INP_POSITIONING.CHECK_DRAFTS_CONFLICTS';
        pk_alertlog.log_debug(g_error);
        --
        FOR i IN 1 .. i_draft.count
        LOOP
            --
            FOR hid IN c_epis_pos(i_draft(i))
            LOOP
                l_flg_conflict.extend;
                l_msg_template.extend;
                l_msg_title.extend;
                l_msg_body.extend;
                --
                l_flg_conflict(l_flg_conflict.count) := pk_alert_constant.g_no;
                l_msg_template(l_msg_template.count) := '';
                l_msg_title(l_msg_title.count) := '';
                l_msg_body(l_msg_body.count) := '';
            END LOOP;
        END LOOP;
    
        --
        o_flg_conflict := l_flg_conflict;
        o_msg_template := l_msg_template;
        o_msg_title    := l_msg_title;
        o_msg_body     := l_msg_body;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_DRAFTS_CONFLICTS',
                                              o_error);
            RETURN FALSE;
    END check_drafts_conflicts;

    /********************************************************************************************
    * get task parameters needed to fill task edit screens (critical for draft editing)
    *
    * NOTE: this function can be replaced by several functions that returns the required values, 
    *       according to current task workflow edit screens
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       ...                       specific to each target area
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION get_task_parameters
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_pos IN epis_positioning.id_epis_positioning%TYPE,
        o_epis_pos OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Call to PK_INP_POSITIONING.get_epis_positioning_det for id_epis_position: ' || i_epis_pos;
        pk_alertlog.log_debug(text            => 'Call to PK_INP_POSITIONING.get_epis_positioning_det for id_epis_position: ' ||
                                                 i_epis_pos,
                              object_name     => 'PK_PBL_INP_POSITIONING',
                              sub_object_name => 'GET_TASK_PARAMETERS');
        IF NOT pk_inp_positioning.get_epis_positioning_det(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_epis_pos   => i_epis_pos,
                                                           o_epis_pos_d => o_epis_pos,
                                                           o_error      => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_PARAMETERS',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_PARAMETERS',
                                              o_error);
            RETURN FALSE;
    END get_task_parameters;

    /********************************************************************************************
    * set task parameters changed in task edit screens (critical for draft editing)
    *
    * NOTE: this function can be replaced by several functions that update the required values, 
    *       according to current task workflow edit screens
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       ...                       specific to each target area
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION set_task_parameters
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_posit            IN table_number,
        i_rot_interv       IN rotation_interval.interval%TYPE,
        i_id_rot_interv    IN rotation_interval.id_rotation_interval%TYPE,
        i_flg_massage      IN epis_positioning.flg_massage%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_pos_type         IN positioning_type.id_positioning_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Call to PK_INP_POSITIONING.edit_epis_positioning for id_epis_pos: ' || i_epis_positioning;
        pk_alertlog.log_debug(text            => 'Call to PK_INP_POSITIONING.edit_epis_positioning for id_epis_pos: ' ||
                                                 i_epis_positioning,
                              object_name     => 'PK_PBL_INP_POSITIONING',
                              sub_object_name => 'SET_TASK_PARAMETERS');
    
        IF NOT pk_inp_positioning.edit_epis_positioning(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_episode          => i_episode,
                                                        i_epis_positioning => i_epis_positioning,
                                                        i_posit            => i_posit,
                                                        i_rot_interv       => i_rot_interv,
                                                        i_id_rot_interv    => i_id_rot_interv,
                                                        i_flg_massage      => i_flg_massage,
                                                        i_notes            => i_notes,
                                                        i_pos_type         => i_pos_type,
                                                        i_flg_type         => pk_inp_positioning.g_epis_posit_d,
                                                        o_error            => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_PARAMETERS',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_PARAMETERS',
                                              o_error);
            RETURN FALSE;
    END set_task_parameters;

    /********************************************************************************************
    * activates a set of draft tasks (task goes from draft to active workflow)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_draft                   array of selected drafts 
    * @param       i_flg_commit              transaction control
    * @param       o_created_tasks        array of created taksk requests    
    * @param       o_error                   error message
    *
    * @value       i_flg_commit              {*} 'Y' commit/rollback the transaction
    *                                        {*} 'N' transaction control is done outside
    *
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Call to PK_INP_POSITIONING.activate_drafts for id_episode: ' || i_episode;
        pk_alertlog.log_debug(text            => 'Call to PK_INP_POSITIONING.activate_drafts for id_episode: ' ||
                                                 i_episode,
                              object_name     => 'PK_PBL_INP_POSITIONING',
                              sub_object_name => 'ACTIVATE_DRAFTS');
    
        IF NOT pk_inp_positioning.activate_drafts(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_episode       => i_episode,
                                                  i_draft         => i_draft,
                                                  o_created_tasks => o_created_tasks,
                                                  o_error         => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        IF (i_flg_commit = pk_alert_constant.g_yes)
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ACTIVATE_DRAFTS',
                                              o_error);
        
            IF (i_flg_commit = pk_alert_constant.g_yes)
            THEN
                pk_utils.undo_changes;
            END IF;
        
            RETURN FALSE;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ACTIVATE_DRAFTS',
                                              o_error);
        
            IF (i_flg_commit = pk_alert_constant.g_yes)
            THEN
                pk_utils.undo_changes;
            END IF;
        
            RETURN FALSE;
    END activate_drafts;

    /********************************************************************************************
    * get available actions for a requested task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_request            task request id (also used for drafts)
    * @param       o_actions_list            list of available actions for the task request
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_actions_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status           epis_positioning.flg_status%TYPE;
        l_flg_status_to_filter VARCHAR2(2 CHAR) := 'OX';
    BEGIN
        g_error := 'FETCH flg_status from epis_positioning for id_episode: ' || i_episode ||
                   ' and id_epis_positioning: ' || i_task_request;
        SELECT ep.flg_status
          INTO l_flg_status
          FROM epis_positioning ep
         WHERE ep.id_episode = i_episode
           AND ep.id_epis_positioning = i_task_request;
    
        g_error := 'check if status expired the professional is able to execute a last time';
        IF l_flg_status = pk_inp_positioning.g_epis_posit_o
           AND pk_inp_positioning.check_extra_take(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_episode      => i_episode,
                                                   i_task_request => i_task_request) = pk_alert_constant.g_yes
        THEN
            l_flg_status_to_filter := l_flg_status;
        ELSIF l_flg_status <> pk_inp_positioning.g_epis_posit_o
        THEN
            l_flg_status_to_filter := l_flg_status;
        END IF;
    
        g_error := 'Call to pk_action.get_actions for id_episode: ' || i_episode || ' and id_epis_positioning: ' ||
                   i_task_request;
        pk_alertlog.log_debug(text            => 'Call to pk_action.get_actions for id_episode: ' || i_episode ||
                                                 ' and id_epis_positioning: ' || i_task_request,
                              object_name     => 'PK_PBL_INP_POSITIONING',
                              sub_object_name => 'GET_TASK_ACTIONS');
    
        IF NOT pk_action.get_actions(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_subject    => 'INP_POSITIONING',
                                     i_from_state => l_flg_status_to_filter,
                                     o_actions    => o_actions_list,
                                     o_error      => o_error)
        THEN
            RAISE internal_error_exception;
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
                                              'GET_TASK_ACTIONS',
                                              o_error);
            pk_types.open_cursor_if_closed(o_actions_list);
            RETURN FALSE;
    END get_task_actions;

    /************************************************************************************************************ 
    * Return positioning description including all positioning sequence
    *
    * @param      i_lang           language ID
    * @param      i_prof           professional information
    * @param      i_episode        episode ID
    *    
    * @author     Luís Maia
    * @version    2.6.0.3
    * @since      2010/JUN/08
    *
    * @dependencies    This function was developed to Content team
    ***********************************************************************************************************/
    FUNCTION get_all_posit_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_inp_positioning.get_all_posit_desc(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_epis_positioning => i_id_epis_positioning);
        --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_all_posit_desc;

    /********************************************************************************************
    * copy task to draft (from an existing active/inactive task)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id (current episode)
    * @param       i_task_request            task request id (used for active/inactive tasks)
    * @param       o_draft                   draft id
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_posit_tbl         table_number;
        l_rot_interval         epis_positioning.rot_interval%TYPE;
        l_id_rotation_interval epis_positioning.id_rotation_interval%TYPE;
        l_flg_massage          epis_positioning.flg_massage%TYPE;
        l_notes                epis_positioning.notes%TYPE;
        l_draft                table_number;
        l_num_reg              PLS_INTEGER;
        l_pos_type             PLS_INTEGER;
    BEGIN
        g_error := 'FETCH information for create_draft call';
        SELECT SET(CAST(COLLECT(to_number(epd.id_positioning) ORDER BY epd.rank) AS table_number)) id_positioning,
               regexp_substr(ep.rot_interval, '([[:digit:]]*[:]?[[:digit:]]+)?|(h?)') rot_interval,
               ep.id_rotation_interval,
               ep.flg_massage,
               ep.notes
          INTO l_id_posit_tbl, l_rot_interval, l_id_rotation_interval, l_flg_massage, l_notes
          FROM epis_positioning ep
          JOIN epis_positioning_det epd
            ON epd.id_epis_positioning = ep.id_epis_positioning
         WHERE ep.id_epis_positioning = i_task_request
           AND ep.id_episode = i_episode
           AND epd.flg_outdated = pk_alert_constant.g_no
         GROUP BY ep.rot_interval, ep.id_rotation_interval, ep.flg_massage, ep.notes;
    
        g_error := 'Call to PK_INP_POSITIONING.CREATE_EPIS_POSITIONING';
        pk_alertlog.log_debug(text            => 'Call to PK_INP_POSITIONING.CREATE_EPIS_POSITIONING for id_episode: ' ||
                                                 i_episode || chr(10) || '- i_posit: ' || l_rot_interval || chr(10) ||
                                                 '- rot_interval: ' || pk_utils.to_string(l_id_posit_tbl) || chr(10) ||
                                                 '- id_rotation_interval: ' || l_id_rotation_interval || chr(10) ||
                                                 '- flg_massage: ' || l_flg_massage || chr(10) || '- notes: ' ||
                                                 l_notes,
                              object_name     => 'PK_PBL_INP_POSITIONING',
                              sub_object_name => 'CREATE_EPIS_POSITIONING');
    
        --
        g_error := 'GET NUM OF POSITIONS';
        SELECT COUNT(1)
          INTO l_num_reg
          FROM epis_positioning_det epd
         WHERE epd.id_epis_positioning = i_task_request;
    
        --
        IF l_num_reg = 1
        THEN
            l_pos_type := 2;
        ELSE
            l_pos_type := NULL;
        END IF;
    
        IF NOT pk_inp_positioning.create_epis_positioning(i_lang                 => i_lang,
                                                          i_prof                 => i_prof,
                                                          i_episode              => i_episode,
                                                          i_posit                => l_id_posit_tbl,
                                                          i_rot_interv           => l_rot_interval,
                                                          i_id_rot_interv        => l_id_rotation_interval,
                                                          i_flg_massage          => l_flg_massage,
                                                          i_notes                => l_notes,
                                                          i_pos_type             => l_pos_type,
                                                          i_flg_type             => pk_inp_positioning.g_epis_posit_d,
                                                          i_task_start_timestamp => i_task_start_timestamp,
                                                          i_task_end_timestamp   => i_task_end_timestamp,
                                                          o_rows                 => l_draft,
                                                          o_error                => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        -- get first positioning request id
        o_draft := l_draft(1);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COPY_TO_DRAFT',
                                              o_error);
            RETURN FALSE;
    END copy_to_draft;

    -- pk_cpoe functions

    /********************************************************************************************
    * synchronize requested task with cpoe processes 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_task_type               cpoe task type id
    * @param       i_task_request            task request id (also used for drafts)
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION sync_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_type    IN cpoe_task_type.id_task_type%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := '';
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SYNC_TASK',
                                              o_error);
            RETURN FALSE;
    END sync_task;

    /**************************************************************************
    * set new episode when executing match functionality                      *
    *                                                                         *
    * @param       i_lang             preferred language id for this          *
    *                                 professional                            *
    * @param       i_prof             professional id structure               *
    * @param       i_current_episode  episode id                              *
    * @param       i_new_episode      array of selected drafts                *
    * @param       o_error            error message                           *
    *                                                                         *
    * @return      boolean            true on success, otherwise false        *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/11/17                              *
    **************************************************************************/
    FUNCTION set_new_match_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- POSITIONING
        g_error := 'CALL pk_inp_positioning.set_new_match_epis';
        IF NOT pk_inp_positioning.set_new_match_epis(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_episode_temp => i_episode_temp,
                                                     i_episode      => i_episode,
                                                     o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_NEW_MATCH_EPIS',
                                              o_error);
            RETURN FALSE;
    END set_new_match_epis;

    /********************************************************************************************
    * GET_ONGOING_TASKS_POSIT                Get all tasks available to cancel when a patient dies
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/May/22       
    ********************************************************************************************/
    FUNCTION get_ongoing_tasks_posit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list IS
    BEGIN
        g_error := 'CALL PK_INP_POSITIONING.GET_ONGOING_TASKS_POSIT';
        RETURN pk_inp_positioning.get_ongoing_tasks_posit(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ongoing_tasks_posit;

    /********************************************************************************************
    * SUSPEND_TASK_POSIT                     Function that should suspend (cancel or interrupt) ongoing task
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_task                 epis_positioning id
    * @param       i_flg_reason              Reason for the WF suspension: 'D' (Death)
    * @param       o_msg_error               cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/May/22       
    ********************************************************************************************/
    FUNCTION suspend_task_posit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_task    IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note             epis_positioning.notes_cancel%TYPE;
        l_id_cancel_reason cancel_reason.id_cancel_reason%TYPE;
    BEGIN
        IF i_flg_reason = pk_death_registry.c_flg_reason_death
        THEN
            l_note             := pk_message.get_message(i_lang      => i_lang,
                                                         i_code_mess => pk_death_registry.c_code_msg_death);
            l_id_cancel_reason := pk_cancel_reason.c_reason_patient_death;
        ELSE
            l_note             := NULL;
            l_id_cancel_reason := NULL;
        END IF;
    
        g_error := 'CALL PK_INP_POSITIONING.SET_EPIS_POS_STATUS';
        IF NOT pk_inp_positioning.set_epis_pos_status(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_epis_pos         => i_id_task,
                                                      i_flg_status       => g_epis_posit_c,
                                                      i_notes            => l_note,
                                                      i_id_cancel_reason => l_id_cancel_reason,
                                                      o_msg_error        => o_msg_error,
                                                      o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        -- There is none situation that makes this cancel impossible
        o_msg_error := NULL;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SUSPEND_TASK_POSIT',
                                              o_error);
            RETURN FALSE;
    END suspend_task_posit;

    /********************************************************************************************
    * REACTIVATE_TASK_POSIT                  Function that should reactivate cancelled or interrupted task
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_task                 epis_positioning id
    * @param       o_msg_error               cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/May/23     
    ********************************************************************************************/
    FUNCTION reactivate_task_posit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_task   IN epis_positioning.id_epis_positioning%TYPE,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_INP_POSITIONING.SET_EPIS_POS_STATUS';
        IF NOT pk_inp_positioning.set_epis_pos_status(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_epis_pos         => i_id_task,
                                                      i_flg_status       => pk_inp_positioning.g_epis_posit_a,
                                                      i_notes            => NULL,
                                                      i_id_cancel_reason => NULL,
                                                      o_msg_error        => o_msg_error,
                                                      o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        -- There is none situation that makes this reactivation impossible
        o_msg_error := NULL;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'REACTIVATE_TASK_POSIT',
                                              o_error);
            RETURN FALSE;
    END reactivate_task_posit;

    /**********************************************************************************************
    * Returns information about a given request
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_request            Request ID
    * @param o_description           Description
    * @param o_instructions          Instructions
    * @param o_flg_status            Flg_status
    *                        
    * @author                        António Neto
    * @version                       v2.5.1.3
    * @since                         03-Feb-2011
    **********************************************************************************************/
    PROCEDURE get_therapeutic_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_request   IN NUMBER,
        o_description  OUT VARCHAR2,
        o_instructions OUT VARCHAR2,
        o_flg_status   OUT VARCHAR2
    ) IS
    BEGIN
        g_error := 'CALL TO PK_INP_POSITIONING.GET_THERAPEUTIC_STATUS';
        pk_alertlog.log_debug(g_error);
        pk_inp_positioning.get_therapeutic_status(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_request   => i_id_request,
                                                  o_description  => o_description,
                                                  o_instructions => o_instructions,
                                                  o_flg_status   => o_flg_status);
    END;

    /**
    * Expire tasks action (task will change its state to expired)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_requests           array of task request ids to expire
    * @param       o_error                   error message structure
    *
    * @return                                true on success, false otherwise
    * 
    * @author                                António Neto
    * @version                               2.5.1.8
    * @since                                 13-Sep-2011
    */
    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL TO PK_INP_POSITIONING.EXPIRE_TASK';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_positioning.expire_task(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_episode       => i_episode,
                                              i_task_requests => i_task_requests,
                                              o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END expire_task;

    /********************************************************************************************
    * Gets the positionings list for reports with timeframe and scope
    *
    * @param   I_LANG                      Language associated to the professional executing the request
    * @param   I_PROF                      Professional Identification
    * @param   I_SCOPE                     Scope ID
    * @param   I_FLG_SCOPE                 Scope type
    * @param   I_START_DATE                Start date for temporal filtering
    * @param   I_END_DATE                  End date for temporal filtering
    * @param   I_CANCELLED                 Indicates whether the records should be returned canceled ('Y' - Yes, 'N' - No)
    * @param   I_CRIT_TYPE                 Flag that indicates if the filter time to consider all records or only during the executions ('A' - All, 'E' - Executions, ...)
    * @param   I_FLG_REPORT                Flag used to remove formatting ('Y' - Yes, 'N' - No)
    * @param   O_POS                       Positioning list
    * @param   O_POS_EXEC                  Executions for Positioning list
    * @param   O_ERROR                     Error message
    *
    * @value   I_SCOPE                     {*} 'E' Episode ID {*} 'V' Visit ID {*} 'P' Patient ID
    * @value   I_FLG_SCOPE                 {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value   I_CANCELLED                 {*} 'Y' Yes {*} 'N' No
    * @value   I_CRIT_TYPE                 {*} 'A' All {*} 'E' Executions {*} 'R' requests
    * @value   I_FLG_REPORT                {*} 'Y' Yes {*} 'N' No
    *                        
    * @return                              true or false on success or error
    * 
    * @author                              António Neto
    * @version                             2.5.1.8.1
    * @since                               29-Sep-2011
    **********************************************************************************************/
    FUNCTION get_positioning_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_report IN VARCHAR2,
        o_pos        OUT NOCOPY pk_types.cursor_type,
        o_pos_exec   OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        e_get_positioning_rep EXCEPTION;
    
    BEGIN
        g_error := 'CALL PK_INP_POSITIONING.GET_POSITIONING_REP';
        IF NOT pk_inp_positioning.get_positioning_rep(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_scope      => i_scope,
                                                      i_flg_scope  => i_flg_scope,
                                                      i_start_date => i_start_date,
                                                      i_end_date   => i_end_date,
                                                      i_cancelled  => i_cancelled,
                                                      i_crit_type  => i_crit_type,
                                                      i_flg_report => i_flg_report,
                                                      o_pos        => o_pos,
                                                      o_pos_exec   => o_pos_exec,
                                                      o_error      => o_error)
        THEN
            RAISE e_get_positioning_rep;
        END IF;
    
        --                       
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_POSITIONING_REP',
                                              o_error);
        
            RETURN FALSE;
    END get_positioning_rep;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cp_begin        TIMESTAMP WITH LOCAL TIME ZONE;
        l_cp_end          TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_status_ep   epis_positioning.flg_status%TYPE;
        t_tbl_positioning table_number;
    
        l_tbl_rec_exec_static t_tbl_cpoe_execution;
        l_tbl_rec_exec_final  t_tbl_cpoe_execution := t_tbl_cpoe_execution();
        l_last_date           monitorization_vs_plan.dt_plan_tstz%TYPE;
        l_interval            monitorization.interval%TYPE;
        l_calc_last_date      monitorization_vs_plan.dt_plan_tstz%TYPE;
    
        l_rot_interv epis_positioning.rot_interval%TYPE;
    
        t_tbl_epis_pos_det table_number;
        l_count_tbl        NUMBER;
        l_index            NUMBER;
        l_mod              NUMBER;
    
        l_no_executions VARCHAR2(1 CHAR) := 'N';
    
        l_error t_error_out;
    BEGIN
    
        IF i_cpoe_dt_begin IS NULL
        THEN
            IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_episode,
                                                     o_dt_begin_tstz => l_cp_begin,
                                                     o_error         => o_error)
            THEN
                l_cp_begin := current_timestamp;
            END IF;
        ELSE
            l_cp_begin := i_cpoe_dt_begin;
        END IF;
    
        IF i_cpoe_dt_end IS NULL
        THEN
            l_cp_end := pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_end, i_days => 1);
        ELSE
            --l_cp_end :=  pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_end, i_days => 1);
            l_cp_end := nvl(i_cpoe_dt_end, current_timestamp);
        END IF;
    
        SELECT a.id_epis_positioning
          BULK COLLECT
          INTO t_tbl_positioning
          FROM epis_positioning a
         WHERE a.id_episode = i_episode
           AND a.flg_status NOT IN (pk_inp_positioning.g_epis_posit_c, pk_inp_positioning.g_epis_posit_d);
    
        FOR i IN 1 .. t_tbl_positioning.count
        LOOP
        
            SELECT t_rec_cpoe_execution(id_task_type    => NULL,
                                        id_prescription => t.id_epis_positioning,
                                        planned_date    => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                       i_date => t.dt_plan,
                                                                                       i_prof => i_prof),
                                        exec_date       => CASE
                                                               WHEN t.dt_exec IS NULL THEN
                                                                NULL
                                                               ELSE
                                                                pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => t.dt_exec, i_prof => i_prof)
                                                           END,
                                        exec_notes      => notes,
                                        out_of_period   => t.out_of_period)
              BULK COLLECT
              INTO l_tbl_rec_exec_static
              FROM (SELECT t_tbl_positioning(i) id_epis_positioning,
                           epp.dt_prev_plan_tstz dt_plan,
                           epp.dt_execution_tstz dt_exec,
                           (pk_inp_positioning.get_positioning_description(i_lang, i_prof, epd.id_epis_positioning_det) ||
                           ' - ' || epp.notes) notes,
                           'N' out_of_period
                      FROM epis_positioning_det epd
                     INNER JOIN epis_positioning_plan epp
                        ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                     WHERE epd.id_epis_positioning = t_tbl_positioning(i)
                       AND epp.dt_prev_plan_tstz BETWEEN l_cp_begin AND l_cp_end
                       AND epp.flg_status = 'F'
                    UNION ALL
                    SELECT z.id_epis_positioning, z.dt_plan, z.dt_exec, z.notes, z.out_of_period
                      FROM (SELECT t_tbl_positioning(i) id_epis_positioning,
                                   epp.dt_prev_plan_tstz dt_plan,
                                   epp.dt_execution_tstz dt_exec,
                                   pk_inp_positioning.get_positioning_description(i_lang,
                                                                                  i_prof,
                                                                                  epd.id_epis_positioning_det) notes,
                                   'Y' out_of_period
                              FROM epis_positioning_det epd
                             INNER JOIN epis_positioning_plan epp
                                ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                             WHERE epd.id_epis_positioning = t_tbl_positioning(i)
                               AND epp.dt_prev_plan_tstz < l_cp_begin
                               AND epp.flg_status = 'F'
                             ORDER BY epp.dt_execution_tstz DESC) z
                     WHERE rownum = 1) t;
        
            BEGIN
                SELECT DISTINCT MAX(epp.dt_prev_plan_tstz)
                  INTO l_last_date
                  FROM epis_positioning_det epd
                 INNER JOIN epis_positioning_plan epp
                    ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                 WHERE epd.id_epis_positioning = t_tbl_positioning(i)
                      --AND epp.dt_execution_tstz IS NOT NULL
                      --AND epd.flg_outdated = 'Y'
                   AND epp.flg_status = pk_inp_positioning.g_epis_posit_e
                 ORDER BY epp.dt_prev_plan_tstz DESC;
            
                l_no_executions := pk_alert_constant.g_yes;
            EXCEPTION
                WHEN OTHERS THEN
                
                    l_no_executions := pk_alert_constant.g_yes;
                    SELECT DISTINCT epp.dt_prev_plan_tstz
                      INTO l_last_date
                      FROM epis_positioning_det epd
                     INNER JOIN epis_positioning_plan epp
                        ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                     WHERE epd.id_epis_positioning = t_tbl_positioning(i);
            END;
        
            SELECT ep.flg_status
              INTO l_flg_status_ep
              FROM epis_positioning ep
             WHERE ep.id_epis_positioning = t_tbl_positioning(i);
        
            IF l_flg_status_ep != pk_inp_positioning.g_epis_posit_i
            THEN
            
                IF l_last_date IS NULL
                THEN
                    l_no_executions := pk_alert_constant.g_yes;
                    SELECT DISTINCT MAX(epp.dt_prev_plan_tstz)
                      INTO l_last_date
                      FROM epis_positioning_det epd
                     INNER JOIN epis_positioning_plan epp
                        ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                     WHERE epd.id_epis_positioning = t_tbl_positioning(i)
                     ORDER BY epp.dt_prev_plan_tstz DESC;
                
                END IF;
            
                IF l_last_date IS NOT NULL
                   AND l_last_date <= l_cp_end
                THEN
                
                    SELECT ep.rot_interval
                      INTO l_rot_interv
                      FROM epis_positioning ep
                     WHERE ep.id_epis_positioning = t_tbl_positioning(i);
                
                    IF l_rot_interv IS NOT NULL
                    THEN
                        IF instr(l_rot_interv, ':') != 0
                        THEN
                            l_interval := to_number(to_char(to_date(pk_inp_positioning.get_rot_interv_format(l_rot_interv),
                                                                    'HH24:MI'),
                                                            'SSSSS'));
                        ELSIF l_rot_interv IS NULL
                        THEN
                            l_interval := l_rot_interv;
                        END IF;
                    ELSE
                        l_interval := NULL;
                    END IF;
                
                    IF l_interval IS NOT NULL
                    THEN
                    
                        IF l_no_executions = pk_alert_constant.g_yes
                        THEN
                            l_calc_last_date := l_last_date;
                        ELSE
                            l_calc_last_date := l_last_date + numtodsinterval(nvl(l_interval, 0), 'SECOND');
                        END IF;
                    
                        SELECT a.id_epis_positioning_det
                          BULK COLLECT
                          INTO t_tbl_epis_pos_det
                          FROM epis_positioning_det a
                         WHERE a.id_epis_positioning = t_tbl_positioning(i)
                           AND a.flg_outdated = 'N'
                         ORDER BY a.rank;
                    
                        l_count_tbl := t_tbl_epis_pos_det.count;
                    
                        WHILE l_calc_last_date < l_cp_end
                        LOOP
                            IF l_calc_last_date >= l_cp_begin
                            THEN
                                l_tbl_rec_exec_static.extend;
                            
                                IF l_tbl_rec_exec_static.count <= l_count_tbl
                                THEN
                                    l_index := l_tbl_rec_exec_static.count;
                                ELSE
                                    l_mod   := MOD(l_tbl_rec_exec_static.count, l_count_tbl);
                                    l_index := CASE
                                                   WHEN l_mod = 0 THEN
                                                    l_count_tbl
                                                   ELSE
                                                    l_mod
                                               END;
                                END IF;
                            
                                l_tbl_rec_exec_static(l_tbl_rec_exec_static.count) := t_rec_cpoe_execution(id_task_type    => NULL,
                                                                                                           id_prescription => t_tbl_positioning(i),
                                                                                                           planned_date    => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                                                          i_date => l_calc_last_date,
                                                                                                                                                          i_prof => i_prof),
                                                                                                           exec_date       => NULL,
                                                                                                           exec_notes      => pk_inp_positioning.get_positioning_description(i_lang,
                                                                                                                                                                             i_prof,
                                                                                                                                                                             t_tbl_epis_pos_det(l_index)),
                                                                                                           out_of_period   => pk_alert_constant.g_no);
                            END IF;
                            l_calc_last_date := l_calc_last_date + numtodsinterval(nvl(l_interval, 0), 'SECOND');
                        
                        END LOOP;
                    END IF;
                
                END IF;
            END IF;
            l_tbl_rec_exec_final := l_tbl_rec_exec_final MULTISET UNION l_tbl_rec_exec_static;
        END LOOP;
    
        OPEN o_plan_rep FOR
            SELECT t.id_prescription, t.planned_date, t.exec_date, t.exec_notes, t.out_of_period
              FROM TABLE(l_tbl_rec_exec_final) t
             ORDER BY t.planned_date;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'INACTIVATE_MONITORZTN_TASKS',
                                              l_error);
            pk_types.open_my_cursor(o_plan_rep);
            RETURN FALSE;
        
    END get_order_plan_report;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_pbl_inp_positioning;
/
