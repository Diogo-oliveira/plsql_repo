/*-- Last Change Revision: $Rev: 2027445 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_paramedical_prof_core IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    --generic exception
    g_sw_generic_exception EXCEPTION;

    g_opinion_status_domain CONSTANT sys_domain.code_domain%TYPE := 'OPINION.FLG_STATE.REQUEST';

    g_plan_active    CONSTANT epis_interv_plan.flg_status%TYPE := 'A';
    g_plan_edited    CONSTANT epis_interv_plan.flg_status%TYPE := 'E';
    g_plan_cancelled CONSTANT epis_interv_plan.flg_status%TYPE := 'C';
    g_plan_suspended CONSTANT epis_interv_plan.flg_status%TYPE := 'S';
    g_plan_concluded CONSTANT epis_interv_plan.flg_status%TYPE := 'F';
    g_action_edit    CONSTANT NUMBER := 235534144;

    g_ds_follow_up_notes_start CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_NOTES_START';
    g_ds_follow_up_notes_spent CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_NOTES_SPENT';
    g_ds_follow_up_notes_end   CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_NOTES_END';
    g_ds_follow_up_notes_next  CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_NOTES_NEXT';
    g_ds_follow_up_notes_text  CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_NOTES_TEXT';

    -- line break
    g_break CONSTANT VARCHAR2(5 CHAR) := '<br/>';

    -- Function and procedure implementations

    /********************************************************************************************
    * Format a string in bold and add a colon at the end
    *
    * @param i_srt                String to format
    * @param i_is_report          The string is to be used in a report: Y - yes, N- no, O - old
    * @param i_is_mandatory       String to format
    *
    * @return                     The formated
    *
    * @author                     Orlando Antunes
    * @version                    0.1
    * @since                      2009/01/21
    ********************************************************************************************/
    FUNCTION format_str_header_w_colon
    (
        i_srt          IN VARCHAR2,
        i_is_report    IN VARCHAR2 DEFAULT 'N',
        i_is_mandatory IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        --
        l_return VARCHAR2(1000 CHAR) := '';
    
    BEGIN
        IF i_srt IS NULL
        THEN
            l_return := i_srt;
        ELSE
            IF i_is_report = pk_alert_constant.g_outdated
            THEN
                --the old reports does not have the fields labels given by this function
                l_return := '';
            ELSIF i_is_report = pk_alert_constant.get_yes
            THEN
                IF i_is_mandatory = pk_alert_constant.get_yes
                THEN
                    l_return := i_srt || c_colon || c_mandatory_field;
                ELSE
                    l_return := i_srt || c_colon;
                END IF;
            ELSE
                IF i_is_mandatory = pk_alert_constant.get_yes
                THEN
                    l_return := c_open_bold_html || i_srt || c_colon || c_mandatory_field || c_close_bold_html ||
                                c_whitespace;
                ELSE
                    l_return := c_open_bold_html || i_srt || c_colon || c_close_bold_html || c_whitespace;
                END IF;
            END IF;
        END IF;
    
        RETURN l_return;
    END format_str_header_w_colon;
    --

    /********************************************************************************************
    * Format a string in bold
    *
    * @param i_srt                String to format
    *
    * @return                     The formated
    *
    * @author                     Orlando Antunes
    * @version                    0.1
    * @since                      2009/01/21
    ********************************************************************************************/
    FUNCTION format_str_header_bold(i_srt IN VARCHAR2) RETURN VARCHAR2 IS
        --
        l_return VARCHAR2(1000 CHAR) := '';
    
    BEGIN
        IF i_srt IS NULL
        THEN
            l_return := i_srt;
        ELSE
            l_return := c_open_bold_html || i_srt || c_close_bold_html || c_whitespace;
        END IF;
    
        RETURN l_return;
    END format_str_header_bold;
    --

    /*
    * Retrieve an array of messages.
    *
    * @param i_lang           language identifier
    * @param i_code_msg_arr   message codes list
    * @param i_prof           logged professional structure
    * @param o_desc_msg_arr   messages list
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Orlando Antunes
    * @version                 2.6.0.1
    * @since                  2010/??/??
    */
    FUNCTION get_message_array
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg_arr IN table_varchar,
        i_prof         IN profissional,
        o_desc_msg_arr OUT table_message_array
    ) RETURN BOOLEAN IS
    
        t_temp_table_table_varchar table_table_varchar := table_table_varchar();
        t_table_message_array      table_message_array;
    
    BEGIN
        g_error := 'GET LIST OF MESSAGES';
        SELECT table_varchar(code_message, desc_message) msg
          BULK COLLECT
          INTO t_temp_table_table_varchar
          FROM (SELECT DISTINCT code_message, desc_message
                  FROM (SELECT code_message,
                               first_value(desc_message) over(PARTITION BY code_message ORDER BY id_software DESC, id_institution DESC) desc_message
                          FROM sys_message
                         WHERE id_language = i_lang
                           AND code_message IN (SELECT column_value
                                                  FROM TABLE(i_code_msg_arr))
                           AND flg_available = pk_alert_constant.g_yes
                           AND id_software IN (i_prof.software, 0)
                           AND id_institution IN (i_prof.institution, 0)));
    
        FOR j IN 1 .. t_temp_table_table_varchar.count
        LOOP
            t_table_message_array(t_temp_table_table_varchar(j)(1)) := t_temp_table_table_varchar(j) (2);
        END LOOP;
        --
    
        --validate translations:
        IF t_table_message_array.count <> i_code_msg_arr.count
        THEN
            FOR z IN 1 .. i_code_msg_arr.count
            LOOP
                IF NOT t_table_message_array.exists(i_code_msg_arr(z))
                THEN
                    t_table_message_array(i_code_msg_arr(z)) := NULL;
                END IF;
            END LOOP;
        END IF;
        --
    
        o_desc_msg_arr := t_table_message_array;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            --pk_types.open_my_cursor(o_desc_msg_arr);
            pk_alert_exceptions.error_handling('GET_MESSAGE_ARRAY', g_package, g_error, SQLERRM);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_message_array;
    --

    /********************************************************************************************
    * Get the cancel information: Professional, date, reason and notes
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_cancel_det          Cancel detail ID
    *
    * @param o_cancel_info            Cursor with all information regarding the cancel action
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/11
    **********************************************************************************************/
    FUNCTION get_cancel_info_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_cancel_det IN cancel_info_det.id_cancel_info_det%TYPE,
        o_cancel_info   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_CANCEL_INFO_DET: i_id_cancel_det = ' || i_id_cancel_det;
        pk_alertlog.log_debug(g_error);
        --
        OPEN o_cancel_info FOR
            SELECT cid.id_cancel_info_det id,
                   cid.id_prof_cancel id_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cid.id_prof_cancel) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, NULL, NULL) || ',' ||
                   (SELECT i.abbreviation
                      FROM institution i
                     WHERE i.id_institution = i_prof.institution) prof_sign,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, cid.dt_cancel, i_prof) dt,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, cid.id_cancel_reason) desc_reason,
                   decode(cid.flg_notes_cancel_type, 'S', cid.notes_cancel_short, cid.notes_cancel_long) notes
              FROM cancel_info_det cid
             WHERE cid.id_cancel_info_det = i_id_cancel_det;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_CANCEL_INFO_DET',
                                                     o_error);
    END get_cancel_info_det;
    --

    /********************************************************************************************
    * Get the signature of the professional that cancel a given record
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_cancel_det          Cancel detail ID
    *
    * @param o_error                  Error
    *
    * @return                         The professional signature on success NULL on error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/11
    **********************************************************************************************/
    FUNCTION get_cancel_professional_sign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_cancel_det IN cancel_info_det.id_cancel_info_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_prof_str VARCHAR2(1000 CHAR);
        l_error    t_error_out;
    BEGIN
        g_error := 'GET_CANCEL_PROFESSIONAL: i_id_cancel_det = ' || i_id_cancel_det;
        pk_alertlog.log_debug(g_error);
        SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, cid.id_prof_cancel) ||
               pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, NULL, NULL) || ',' ||
               (SELECT i.abbreviation
                  FROM institution i
                 WHERE i.id_institution = i_prof.institution) prof_sign
          INTO l_prof_str
          FROM cancel_info_det cid
         WHERE cid.id_cancel_info_det = i_id_cancel_det;
    
        RETURN l_prof_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_CANCEL_PROFESSIONAL_SIGN',
                                              l_error);
            RETURN NULL;
    END get_cancel_professional_sign;
    --

    /********************************************************************************************
    * Get the date for a given cancel detail ID
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_cancel_det          Cancel detail ID
    *
    * @param o_error                  Error
    *
    * @return                         The string format of the cancel date on success NULL on error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/11
    **********************************************************************************************/
    FUNCTION get_cancel_date
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_cancel_det IN cancel_info_det.id_cancel_info_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_dt_str VARCHAR2(1000 CHAR);
        l_error  t_error_out;
    BEGIN
        g_error := 'GET_CANCEL_DATE: i_id_cancel_det = ' || i_id_cancel_det;
        pk_alertlog.log_debug(g_error);
        --
        SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang, cid.dt_cancel, i_prof) dt
          INTO l_dt_str
          FROM cancel_info_det cid
         WHERE cid.id_cancel_info_det = i_id_cancel_det;
    
        RETURN l_dt_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_CANCEL_DATE',
                                              l_error);
            RETURN NULL;
    END get_cancel_date;
    --

    /********************************************************************************************
    * Get the cancel reason for a given cancel detail ID
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_cancel_det          Cancel detail ID
    *
    * @param o_error                  Error
    *
    * @return                         The string format of the cancel date on success NULL on error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/11
    **********************************************************************************************/
    FUNCTION get_cancel_reason_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_cancel_det IN cancel_info_det.id_cancel_info_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_reason_str VARCHAR2(1000 CHAR);
        l_error      t_error_out;
    BEGIN
        g_error := 'GET_CANCEL_REASON_DESC: i_id_cancel_det = ' || i_id_cancel_det;
        pk_alertlog.log_debug(g_error);
        --
        SELECT pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, cid.id_cancel_reason) desc_reason
          INTO l_reason_str
          FROM cancel_info_det cid
         WHERE cid.id_cancel_info_det = i_id_cancel_det;
    
        RETURN l_reason_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_CANCEL_REASON_DESC',
                                              l_error);
            RETURN NULL;
    END get_cancel_reason_desc;
    --

    /********************************************************************************************
    * Get the cancel notes for a given cancel detail ID
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_cancel_det          Cancel detail ID
    *
    * @param o_error                  Error
    *
    * @return                         The notes on success NULL on error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/11
    **********************************************************************************************/
    FUNCTION get_notes_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_cancel_det IN cancel_info_det.id_cancel_info_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_notes_str VARCHAR2(1000 CHAR);
        l_error     t_error_out;
    BEGIN
        g_error := 'GET_NOTES_DESC: i_id_cancel_det = ' || i_id_cancel_det;
        pk_alertlog.log_debug(g_error);
        --
        SELECT decode(cid.flg_notes_cancel_type, 'L', cid.notes_cancel_long, cid.notes_cancel_short) notes
          INTO l_notes_str
          FROM cancel_info_det cid
         WHERE cid.id_cancel_info_det = i_id_cancel_det;
    
        RETURN l_notes_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NOTES_DESC',
                                              l_error);
            RETURN NULL;
    END get_notes_desc;
    --

    /*
    * Get followup notes time spent unit subtype and default unit.
    *
    * @param i_prof           logged professional structure
    * @param o_time_units     time units
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    PROCEDURE get_followup_time_units
    (
        i_prof       IN profissional,
        o_time_units OUT pk_types.cursor_type
    ) IS
        l_um_subtype unit_measure_group.id_unit_measure_subtype%TYPE;
        l_default_um unit_measure_group.id_unit_measure%TYPE;
    BEGIN
        g_error      := 'GET configs';
        l_um_subtype := pk_sysconfig.get_config(i_code_cf => 'PARAMEDICAL_PROF_FOLLOWUP_NOTES_TIME_UNIT_MEASURE_SUBTYPE',
                                                i_prof    => i_prof);
        l_default_um := pk_sysconfig.get_config(i_code_cf => 'PARAMEDICAL_PROF_FOLLOWUP_NOTES_DEFAULT_TIME_UNIT_MEASURE',
                                                i_prof    => i_prof);
    
        g_error := 'OPEN o_time_units';
        OPEN o_time_units FOR
            SELECT l_um_subtype id_unit_measure_subtype, l_default_um id_unit_measure
              FROM dual;
    END get_followup_time_units;

    /*
    * Get a follow up notes record history.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up      follow up notes
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    PROCEDURE get_followup_notes_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type
    ) IS
        l_notes_title    sys_message.desc_message%TYPE;
        l_start_dt_title sys_message.desc_message%TYPE;
        l_time_title     sys_message.desc_message%TYPE;
        l_next_dt_title  sys_message.desc_message%TYPE;
        l_msg_oper_add   sys_message.desc_message%TYPE;
        l_msg_oper_edit  sys_message.desc_message%TYPE;
        l_msg_oper_canc  sys_message.desc_message%TYPE;
        l_canc_rea_title sys_message.desc_message%TYPE;
        l_canc_not_title sys_message.desc_message%TYPE;
        l_end_followup   sys_message.desc_message%TYPE;
        l_next_dt_enable VARCHAR2(1 CHAR);
    BEGIN
        l_notes_title    := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T103'));
        l_start_dt_title := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T104'));
        l_time_title     := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T105'));
        l_next_dt_title  := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T154'));
        l_msg_oper_add   := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T107');
        l_msg_oper_edit  := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T108');
        l_msg_oper_canc  := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T109');
        l_canc_rea_title := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'COMMON_M072'));
        l_canc_not_title := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'COMMON_M073'));
        l_next_dt_enable := check_hospital_profile(i_prof => i_prof);
        l_end_followup   := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'PARAMEDICAL_T023'));
        g_error          := 'OPEN o_follow_up_prof_hist';
    
        OPEN o_follow_up_prof FOR
            SELECT mfu.id_management_follow_up id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_register, i_prof) dt,
                   pk_tools.get_prof_description(i_lang, i_prof, mfu.id_professional, mfu.dt_register, mfu.id_episode) prof_sign,
                   mfu.flg_status,
                   decode(mfu.id_parent,
                          NULL,
                          l_msg_oper_add,
                          decode(mfu.flg_status, pk_case_management.g_mfu_status_canc, l_msg_oper_canc, l_msg_oper_edit)) desc_status,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_cancel,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_action
              FROM management_follow_up mfu
            CONNECT BY PRIOR mfu.id_parent = mfu.id_management_follow_up
             START WITH mfu.id_management_follow_up = i_mng_followup;
    
        g_error := 'OPEN o_follow_up_hist';
        IF i_prof.software = pk_alert_constant.g_soft_nutritionist
        THEN
            OPEN o_follow_up FOR
                SELECT mfu.id_management_follow_up id,
                       mfu.id_episode,
                       pk_activity_therapist.get_epis_parent(i_lang, i_prof, mfu.id_episode) id_episode_origin,
                       l_start_dt_title || nvl2(mfu.dt_start,
                                                pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof),
                                                pk_paramedical_prof_core.c_dashes) desc_start_dt,
                       l_time_title ||
                       nvl(get_format_time_spent(i_lang,
                                                 time_spent_convert(i_prof, mfu.id_episode, mfu.id_management_follow_up)),
                           pk_paramedical_prof_core.c_dashes) desc_time_spent,
                       l_end_followup ||
                       nvl2(mfu.flg_end_followup,
                            pk_sysdomain.get_domain(pk_list.g_yes_no, mfu.flg_end_followup, i_lang),
                            pk_sysdomain.get_domain(pk_list.g_yes_no, pk_alert_constant.g_no, i_lang)) desc_end_followup,
                       decode(l_next_dt_enable,
                              pk_alert_constant.g_yes,
                              l_next_dt_title || nvl2(mfu.dt_next_encounter,
                                                      get_partial_date_format(i_lang      => i_lang,
                                                                              i_prof      => i_prof,
                                                                              i_date      => mfu.dt_next_encounter,
                                                                              i_precision => mfu.dt_next_enc_precision),
                                                      pk_paramedical_prof_core.c_dashes)) desc_next_dt,
                       
                       decode(mfu.flg_status,
                              pk_case_management.g_mfu_status_canc,
                              l_canc_rea_title || pk_translation.get_translation(i_lang, cr.code_cancel_reason)) desc_cancel_reason,
                       decode(mfu.flg_status,
                              pk_case_management.g_mfu_status_canc,
                              l_canc_not_title || htf.escape_sc(mfu.notes)) desc_cancel_notes,
                       decode(mfu.flg_status, pk_case_management.g_mfu_status_canc, mfu.notes_cancel, '') desc_cancel
                  FROM management_follow_up mfu
                  LEFT JOIN unit_measure um
                    ON mfu.id_unit_time = um.id_unit_measure
                  LEFT JOIN cancel_reason cr
                    ON mfu.id_cancel_reason = cr.id_cancel_reason
                CONNECT BY PRIOR mfu.id_parent = mfu.id_management_follow_up
                 START WITH mfu.id_management_follow_up = i_mng_followup
                 ORDER BY mfu.dt_register DESC;
        ELSE
            OPEN o_follow_up FOR
                SELECT mfu.id_management_follow_up id,
                       mfu.id_episode,
                       pk_activity_therapist.get_epis_parent(i_lang, i_prof, mfu.id_episode) id_episode_origin,
                       nvl2(mfu.notes, l_notes_title || htf.escape_sc(mfu.notes), NULL) desc_followup_notes,
                       l_start_dt_title || nvl2(mfu.dt_start,
                                                pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof),
                                                pk_paramedical_prof_core.c_dashes) desc_start_dt,
                       l_time_title ||
                       nvl(get_format_time_spent(i_lang,
                                                 time_spent_convert(i_prof, mfu.id_episode, mfu.id_management_follow_up)),
                           pk_paramedical_prof_core.c_dashes) desc_time_spent,
                       l_end_followup ||
                       nvl2(mfu.flg_end_followup,
                            pk_sysdomain.get_domain(pk_list.g_yes_no, mfu.flg_end_followup, i_lang),
                            pk_sysdomain.get_domain(pk_list.g_yes_no, pk_alert_constant.g_no, i_lang)) desc_end_followup,
                       decode(l_next_dt_enable,
                              pk_alert_constant.g_yes,
                              nvl2(mfu.dt_next_encounter,
                                   l_next_dt_title ||
                                   get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => mfu.dt_next_encounter,
                                                           i_precision => mfu.dt_next_enc_precision),
                                   NULL)) desc_next_dt,
                       decode(mfu.flg_status,
                              pk_case_management.g_mfu_status_canc,
                              l_canc_rea_title || pk_translation.get_translation(i_lang, cr.code_cancel_reason)) desc_cancel_reason,
                       decode(mfu.flg_status,
                              pk_case_management.g_mfu_status_canc,
                              l_canc_not_title || htf.escape_sc(mfu.notes)) desc_cancel_notes,
                       decode(mfu.flg_status, pk_case_management.g_mfu_status_canc, mfu.notes_cancel, '') desc_cancel
                  FROM management_follow_up mfu
                  LEFT JOIN unit_measure um
                    ON mfu.id_unit_time = um.id_unit_measure
                  LEFT JOIN cancel_reason cr
                    ON mfu.id_cancel_reason = cr.id_cancel_reason
                CONNECT BY PRIOR mfu.id_parent = mfu.id_management_follow_up
                 START WITH mfu.id_management_follow_up = i_mng_followup
                 ORDER BY mfu.dt_register DESC;
        END IF;
    END get_followup_notes_hist;
    --

    /*
    * Get the follow up notes list for the given array of episodes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up      follow up notes
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/15
    */
    PROCEDURE get_followup_notes_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_show_cancelled IN VARCHAR2,
        i_report         IN VARCHAR2 DEFAULT 'N',
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_opinion_type   IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type
    ) IS
        l_notes_title    sys_message.desc_message%TYPE;
        l_start_dt_title sys_message.desc_message%TYPE;
        l_time_title     sys_message.desc_message%TYPE;
        l_next_dt_title  sys_message.desc_message%TYPE;
        l_end_followup   sys_message.desc_message%TYPE;
        l_canc_rea_title sys_message.desc_message%TYPE;
        l_canc_not_title sys_message.desc_message%TYPE;
        l_next_dt_enable VARCHAR2(1 CHAR);
        l_opinion_type   opinion_type.id_opinion_type%TYPE;
    
    BEGIN
        l_notes_title    := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T103'),
                                                      i_is_report => i_report);
        l_start_dt_title := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T104'),
                                                      i_is_report => i_report);
        l_time_title     := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T105'),
                                                      i_is_report => i_report);
        l_next_dt_title  := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T154'),
                                                      i_is_report => i_report);
    
        l_end_followup   := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'PARAMEDICAL_T023'),
                                                      i_is_report => i_report);
        l_canc_rea_title := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'COMMON_M072'));
        l_canc_not_title := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'COMMON_M073'));
    
        l_next_dt_enable := check_hospital_profile(i_prof => i_prof);
    
        IF i_opinion_type IS NULL
        THEN
            l_opinion_type := get_id_opinion_type(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode(1));
        ELSE
            l_opinion_type := i_opinion_type;
        END IF;
    
        g_error := 'OPEN o_follow_up_prof_list';
        OPEN o_follow_up_prof FOR
            SELECT mfu.id_management_follow_up id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_register, i_prof) dt,
                   pk_tools.get_prof_description(i_lang, i_prof, mfu.id_professional, mfu.dt_register, mfu.id_episode) prof_sign,
                   mfu.flg_status,
                   NULL desc_status,
                   get_actions_active(i_lang                    => i_lang,
                                      i_prof                    => i_prof,
                                      i_episode                 => mfu.id_episode,
                                      i_flg_status              => mfu.flg_status,
                                      i_id_management_follow_up => mfu.id_management_follow_up) flg_cancel,
                   get_actions_active(i_lang                    => i_lang,
                                      i_prof                    => i_prof,
                                      i_episode                 => mfu.id_episode,
                                      i_flg_status              => mfu.flg_status,
                                      i_id_management_follow_up => mfu.id_management_follow_up) flg_action
              FROM management_follow_up mfu
             WHERE mfu.id_episode IN (SELECT /*+dynamic_sampling(t 2)*/
                                       t.column_value id_episode
                                        FROM TABLE(i_episode) t)
               AND (mfu.flg_status = pk_case_management.g_mfu_status_active OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND
                   mfu.flg_status = pk_case_management.g_mfu_status_canc))
               AND (i_start_date IS NULL OR mfu.dt_register >= i_start_date)
               AND (i_end_date IS NULL OR mfu.dt_register <= i_end_date)
               AND (mfu.id_opinion_type = l_opinion_type OR mfu.id_opinion_type IS NULL)
             ORDER BY decode(mfu.flg_status, pk_case_management.g_mnp_flg_status_c, 2, 1) ASC, mfu.dt_register DESC;
    
        g_error := 'OPEN o_follow_up_list';
    
        OPEN o_follow_up FOR
            SELECT mfu.id_management_follow_up id,
                   mfu.id_episode,
                   pk_activity_therapist.get_epis_parent(i_lang, i_prof, mfu.id_episode) id_episode_origin,
                   decode(dbms_lob.getlength(mfu.notes), 0, NULL, to_clob(l_notes_title || htf.escape_sc(mfu.notes))) desc_followup_notes,
                   l_start_dt_title || nvl2(mfu.dt_start,
                                            pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof),
                                            pk_paramedical_prof_core.c_dashes) desc_start_dt,
                   
                   nvl2(mfu.time_spent,
                        l_time_title ||
                        get_format_time_spent(i_lang,
                                              time_spent_convert(i_prof, mfu.id_episode, mfu.id_management_follow_up)),
                        NULL) desc_time_spent,
                   l_end_followup ||
                   nvl2(mfu.flg_end_followup,
                        pk_sysdomain.get_domain(pk_list.g_yes_no, mfu.flg_end_followup, i_lang),
                        pk_sysdomain.get_domain(pk_list.g_yes_no, pk_alert_constant.g_no, i_lang)) desc_end_followup,
                   decode(l_next_dt_enable,
                          pk_alert_constant.g_yes,
                          nvl2(mfu.dt_next_encounter,
                               l_next_dt_title ||
                               get_partial_date_format(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_date      => mfu.dt_next_encounter,
                                                       i_precision => mfu.dt_next_enc_precision),
                               NULL)) desc_next_dt,
                   -- get_ehr_last_update_info(i_lang, i_prof, mfu.dt_register, mfu.id_professional, mfu.dt_register) last_update_info,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          l_canc_rea_title || pk_translation.get_translation(i_lang, cr.code_cancel_reason)) desc_cancel_reason,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          l_canc_not_title || htf.escape_sc(mfu.notes)) desc_cancel_notes,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_message.get_message(i_lang, pk_act_therap_constant.g_msg_cancelled),
                          '') desc_cancel
              FROM management_follow_up mfu
              LEFT JOIN unit_measure um
                ON mfu.id_unit_time = um.id_unit_measure
              LEFT JOIN cancel_reason cr
                ON mfu.id_cancel_reason = cr.id_cancel_reason
             WHERE mfu.id_episode IN (SELECT /*+dynamic_sampling(t 2)*/
                                       t.column_value id_episode
                                        FROM TABLE(i_episode) t)
               AND (mfu.flg_status = pk_case_management.g_mfu_status_active OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND
                   mfu.flg_status = pk_case_management.g_mfu_status_canc))
               AND (i_start_date IS NULL OR mfu.dt_register >= i_start_date)
               AND (i_end_date IS NULL OR mfu.dt_register <= i_end_date)
               AND (mfu.id_opinion_type = l_opinion_type OR mfu.id_opinion_type IS NULL)
             ORDER BY decode(mfu.flg_status, pk_case_management.g_mfu_status_canc, 2, 1) ASC, mfu.dt_register DESC;
    
    END get_followup_notes_list;
    --

    /*
    * Get an episode's follow up notes list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up      follow up notes
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    PROCEDURE get_followup_notes_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN management_follow_up.id_episode%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type
    ) IS
    
    BEGIN
    
        g_error := 'CALL get_followup_notes_list';
        get_followup_notes_list(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_episode        => table_number(i_episode),
                                i_show_cancelled => i_show_cancelled,
                                o_follow_up_prof => o_follow_up_prof,
                                o_follow_up      => o_follow_up);
        --
    END get_followup_notes_list;
    --

    /*
    * Get an episode's follow up notes list. Specify the follow up notes
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN management_follow_up.id_episode%TYPE,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_mng_followup IS NULL
        THEN
            g_error := 'CALL get_followup_notes_list';
            get_followup_notes_list(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_episode        => i_episode,
                                    i_show_cancelled => i_show_cancelled,
                                    o_follow_up_prof => o_follow_up_prof,
                                    o_follow_up      => o_follow_up);
        ELSE
            g_error := 'CALL get_followup_notes_hist';
            get_followup_notes_hist(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_mng_followup   => i_mng_followup,
                                    o_follow_up_prof => o_follow_up_prof,
                                    o_follow_up      => o_follow_up);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_FOLLOWUP_NOTES',
                                                     o_error    => o_error);
    END get_followup_notes;
    --

    /*
    * Get an episode's follow up notes list. Specify the follow up notes
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param i_mng_followup   follow up notes identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        i_show_cancelled IN VARCHAR2,
        i_opinion_type   IN opinion_type.id_opinion_type%TYPE,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_mng_followup IS NULL
        THEN
            g_error := 'CALL get_followup_notes_list';
            get_followup_notes_list(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_episode        => i_episode,
                                    i_show_cancelled => i_show_cancelled,
                                    i_opinion_type   => i_opinion_type,
                                    o_follow_up_prof => o_follow_up_prof,
                                    o_follow_up      => o_follow_up);
        ELSE
            g_error := 'CALL get_followup_notes_hist';
            get_followup_notes_hist(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_mng_followup   => i_mng_followup,
                                    o_follow_up_prof => o_follow_up_prof,
                                    o_follow_up      => o_follow_up);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_FOLLOWUP_NOTES',
                                                     o_error    => o_error);
    END get_followup_notes;

    FUNCTION get_followup_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_mng_followup IS NULL
        THEN
            g_error := 'CALL get_followup_notes_list';
            get_followup_notes_list(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_episode        => i_episode,
                                    i_show_cancelled => i_show_cancelled,
                                    o_follow_up_prof => o_follow_up_prof,
                                    o_follow_up      => o_follow_up);
        ELSE
            g_error := 'CALL get_followup_notes_hist';
            get_followup_notes_hist(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_mng_followup   => i_mng_followup,
                                    o_follow_up_prof => o_follow_up_prof,
                                    o_follow_up      => o_follow_up);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_FOLLOWUP_NOTES',
                                                     o_error    => o_error);
    END get_followup_notes;
    --

    /*
    * Get an episode's follow up notes list. Specify the follow up notes
    * identifier to retrieve the history of its changes.
    * Only returns the registies done in the specified time period.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param i_mng_followup   follow up notes identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param i_start_date     Registry time period start date
    * @param i_end_date       Registry time period end date
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  22-Jun-2010
    */
    FUNCTION get_followup_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_show_cancelled IN VARCHAR2,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_opinion_type   IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_followup_notes_list';
        get_followup_notes_list(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_episode        => i_episode,
                                i_show_cancelled => i_show_cancelled,
                                i_start_date     => i_start_date,
                                i_end_date       => i_end_date,
                                i_opinion_type   => i_opinion_type,
                                o_follow_up_prof => o_follow_up_prof,
                                o_follow_up      => o_follow_up);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_FOLLOWUP_NOTES',
                                                     o_error    => o_error);
    END get_followup_notes;

    /**
    * Get an episode's follow up notes list, for reports layer usage.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      actual episode identifier
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up    follow up notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/03/02
    */
    FUNCTION get_followup_notes_rep
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_show_cancelled IN VARCHAR2 DEFAULT NULL,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_FOLLOWUP_NOTES_REP';
        l_notes_title    sys_message.desc_message%TYPE;
        l_start_dt_title sys_message.desc_message%TYPE;
        l_time_title     sys_message.desc_message%TYPE;
        l_next_dt_title  sys_message.desc_message%TYPE;
        l_last_upd_title sys_message.desc_message%TYPE;
        l_end_followup   sys_message.desc_message%TYPE;
        l_next_dt_enable VARCHAR2(1 CHAR);
    BEGIN
        l_notes_title    := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T103'),
                                                      i_is_report => pk_alert_constant.g_yes);
        l_start_dt_title := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T104'),
                                                      i_is_report => pk_alert_constant.g_yes);
        l_time_title     := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T105'),
                                                      i_is_report => pk_alert_constant.g_yes);
        l_next_dt_title  := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T154'),
                                                      i_is_report => pk_alert_constant.g_yes);
        l_last_upd_title := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'PAST_HISTORY_M006'),
                                                      i_is_report => pk_alert_constant.g_yes);
        l_next_dt_enable := check_hospital_profile(i_prof => i_prof);
    
        l_end_followup := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'PARAMEDICAL_T023'),
                                                    i_is_report => pk_alert_constant.g_yes);
    
        g_error := 'OPEN o_follow_up_prof_rep';
        OPEN o_follow_up_prof FOR
            SELECT mfu.id_management_follow_up id,
                   decode(mfu.id_parent,
                          NULL,
                          pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_register, i_prof),
                          (SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang, m.dt_register, i_prof)
                             FROM management_follow_up m
                            WHERE m.id_parent IS NULL
                           CONNECT BY PRIOR m.id_parent = m.id_management_follow_up
                            START WITH m.id_management_follow_up = mfu.id_management_follow_up)) dt,
                   decode(mfu.id_parent,
                          NULL,
                          pk_date_utils.date_send_tsz(i_lang, mfu.dt_register, i_prof),
                          (SELECT pk_date_utils.date_send_tsz(i_lang, m.dt_register, i_prof)
                             FROM management_follow_up m
                            WHERE m.id_parent IS NULL
                           CONNECT BY PRIOR m.id_parent = m.id_management_follow_up
                            START WITH m.id_management_follow_up = mfu.id_management_follow_up)) dt_serial,
                   decode(mfu.id_parent,
                          NULL,
                          pk_tools.get_prof_description(i_lang,
                                                        i_prof,
                                                        mfu.id_professional,
                                                        mfu.dt_register,
                                                        mfu.id_episode),
                          (SELECT pk_tools.get_prof_description(i_lang,
                                                                i_prof,
                                                                m.id_professional,
                                                                m.dt_register,
                                                                m.id_episode)
                             FROM management_follow_up m
                            WHERE m.id_parent IS NULL
                           CONNECT BY PRIOR m.id_parent = m.id_management_follow_up
                            START WITH m.id_management_follow_up = mfu.id_management_follow_up)) prof_sign,
                   mfu.flg_status,
                   NULL desc_status
              FROM management_follow_up mfu
             WHERE mfu.id_episode = i_episode
               AND (mfu.flg_status = pk_case_management.g_mfu_status_active OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND
                   mfu.flg_status IN (pk_case_management.g_mfu_status_canc, pk_case_management.g_mfu_status_outd)))
             ORDER BY mfu.flg_status, mfu.dt_register DESC;
    
        g_error := 'OPEN o_follow_up_rep';
        OPEN o_follow_up FOR
            SELECT mfu.id_management_follow_up id,
                   mfu.id_episode,
                   pk_activity_therapist.get_epis_parent(i_lang, i_prof, mfu.id_episode) id_episode_origin,
                   l_notes_title lbl_follow_notes,
                   --ALERT-258085 htf.escape_sc(mfu.notes) desc_followup_notes,
                   pk_string_utils.escape_sc(mfu.notes) desc_followup_notes,
                   l_start_dt_title lbl_start_dt,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof) desc_start_dt,
                   pk_date_utils.dt_chr_tsz(i_lang, mfu.dt_start, i_prof) desc_start_dt_day,
                   pk_date_utils.date_char_hour_tsz(i_lang, mfu.dt_start, i_prof.institution, i_prof.software) desc_start_dt_hour,
                   pk_date_utils.date_send_tsz(i_lang, mfu.dt_start, i_prof) start_dt_serial,
                   l_time_title lbl_time_spent,
                   get_format_time_spent(i_lang,
                                         time_spent_convert(i_prof, mfu.id_episode, mfu.id_management_follow_up)) desc_time_spent,
                   l_next_dt_enable next_dt_enable,
                   l_next_dt_title lbl_next_dt,
                   get_partial_date_format(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_date      => mfu.dt_next_encounter,
                                           i_precision => mfu.dt_next_enc_precision) desc_next_dt,
                   l_last_upd_title lbl_last_update,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_register, i_prof) dt_last_update,
                   pk_tools.get_prof_description_cat(i_lang, i_prof, mfu.id_professional, NULL, NULL) prof_last_update,
                   l_end_followup lbl_end_followup,
                   nvl2(mfu.flg_end_followup,
                        pk_sysdomain.get_domain(pk_list.g_yes_no, mfu.flg_end_followup, i_lang),
                        pk_sysdomain.get_domain(pk_list.g_yes_no, pk_alert_constant.g_no, i_lang)) desc_end_followup
              FROM management_follow_up mfu
             WHERE mfu.id_episode = i_episode
               AND (mfu.flg_status = pk_case_management.g_mfu_status_active OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND
                   mfu.flg_status IN (pk_case_management.g_mfu_status_canc, pk_case_management.g_mfu_status_outd)))
             ORDER BY mfu.flg_status, mfu.dt_register DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_followup_notes_rep;

    /*
    * Get follow up notes data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up      follow up notes
    * @param o_time_units     time units
    * @param o_domain         option of end of follow up
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */

    FUNCTION get_followup_notes_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_FOLLOWUP_NOTES_VALUES';
        l_ds_internal_name        ds_component.internal_name%TYPE;
        l_id_ds_component         ds_component.id_ds_component%TYPE;
        l_id_management_follow_up management_follow_up.id_management_follow_up%TYPE;
        l_next_dt_enable          VARCHAR2(1 CHAR);
        l_has_end_encounter       VARCHAR2(1);
        l_has_time_mandatory      VARCHAR2(1);
        l_dt                      VARCHAR2(200 CHAR);
        CURSOR c_follow_up IS
            SELECT mfu.notes desc_notes,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof) desc_start_dt,
                   pk_date_utils.date_send_tsz(i_lang, mfu.dt_start, i_prof) flg_start_dt,
                   nvl2(mfu.time_spent,
                        get_format_time_spent(i_lang,
                                              time_spent_convert(i_prof, mfu.id_episode, mfu.id_management_follow_up)),
                        NULL) desc_time_spent,
                   get_time_spent_send(i_lang, i_prof, mfu.time_spent, mfu.id_unit_time) flg_time_spent,
                   mfu.id_unit_time measure_time_spent,
                   get_partial_date_format(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_date      => mfu.dt_next_encounter,
                                           i_precision => mfu.dt_next_enc_precision) desc_next_dt,
                   pk_date_utils.date_send_tsz(i_lang, mfu.dt_next_encounter, i_prof) flg_next_dt,
                   l_next_dt_enable next_dt_enable,
                   decode(mfu.flg_end_followup,
                          NULL,
                          pk_sysdomain.get_domain(pk_list.g_yes_no, pk_alert_constant.g_no, i_lang),
                          pk_sysdomain.get_domain(pk_list.g_yes_no, mfu.flg_end_followup, i_lang)) desc_end_followup,
                   nvl(mfu.flg_end_followup, pk_alert_constant.g_no) flg_end_followup,
                   l_has_end_encounter followup_end_enable,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, mfu.id_unit_time) unit_measure_desc
              FROM management_follow_up mfu
              LEFT JOIN unit_measure um
                ON mfu.id_unit_time = um.id_unit_measure
             WHERE mfu.id_management_follow_up = l_id_management_follow_up;
    
        r_follow_up              c_follow_up%ROWTYPE;
        l_paramedical_time_spent VARCHAR2(2 CHAR) := pk_sysconfig.get_config('PARAMEDICAL_PROF_FOLLOWUP_TIME_SPENT_MANDATORY',
                                                                             i_prof);
    
        l_paramedical_note_mandatory VARCHAR2(2 CHAR) := pk_sysconfig.get_config('PARAMEDICAL_PROF_FOLLOWUP_NOTE_MANDATORY',
                                                                                 i_prof);
    
        l_desc_unit_measure VARCHAR2(200 CHAR);
    BEGIN
    
        g_sysdate_tstz      := current_timestamp;
        l_desc_unit_measure := pk_unit_measure.get_unit_measure_description(i_lang,
                                                                            i_prof,
                                                                            pk_paramedical_prof_core.g_id_unit_minutes);
        IF i_tbl_id_pk.exists(1)
        THEN
            l_id_management_follow_up := i_tbl_id_pk(1);
        ELSE
            l_id_management_follow_up := NULL;
        END IF;
    
        IF l_id_management_follow_up IS NOT NULL -- if l_id_hhc_discharge is not null, it means it is an edition
        --    AND i_action = g_action_edit
        
        THEN
        
            OPEN c_follow_up;
            FETCH c_follow_up
                INTO r_follow_up;
            CLOSE c_follow_up;
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_start THEN
                                                                  r_follow_up.flg_start_dt
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_spent THEN
                                                                  to_char(r_follow_up.flg_time_spent)
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_end THEN
                                                                  r_follow_up.flg_end_followup
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_next THEN
                                                                  r_follow_up.flg_next_dt
                                                             
                                                             END,
                                       value_clob         => CASE
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_text THEN
                                                                  r_follow_up.desc_notes
                                                             END,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_start THEN
                                                                  r_follow_up.desc_start_dt
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_spent THEN
                                                                  r_follow_up.desc_time_spent
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_end THEN
                                                                  r_follow_up.desc_end_followup
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_next THEN
                                                                  r_follow_up.desc_next_dt
                                                             
                                                             END,
                                       desc_clob          => CASE
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_text THEN
                                                                  r_follow_up.desc_notes
                                                             END,
                                       id_unit_measure    => NULL,
                                       desc_unit_measure  => NULL,
                                       flg_validation     => pk_alert_constant.g_yes,
                                       err_msg            => NULL,
                                       flg_event_type     => CASE
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_next THEN
                                                                  decode(r_follow_up.flg_end_followup, pk_alert_constant.g_yes, 'I', 'A')
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_text THEN
                                                                  decode(l_paramedical_note_mandatory, pk_alert_constant.g_yes, 'M', 'A')
                                                             
                                                                 ELSE
                                                                  'A'
                                                             END,
                                       flg_multi_status   => NULL,
                                       idx                => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             ORDER BY t.rn;
        ELSE
            l_dt := pk_date_utils.date_send_tsz(i_lang,
                                                pk_date_utils.trunc_insttimezone(i_prof, current_timestamp),
                                                i_prof);
            --  l_dt := substr(l_dt, 1, 8) || l_c_round || l_c_mod || '00';
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_start THEN
                                                                  pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof)
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_spent THEN
                                                                  l_dt
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_end THEN
                                                                  pk_alert_constant.g_no
                                                             
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_start THEN
                                                                  pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof)
                                                             
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_end THEN
                                                                  pk_sysdomain.get_domain(pk_list.g_yes_no, pk_alert_constant.g_no, i_lang)
                                                             
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => NULL,
                                       desc_unit_measure  => NULL,
                                       flg_validation     => pk_alert_constant.g_yes,
                                       err_msg            => NULL,
                                       flg_event_type     => CASE
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_spent THEN
                                                                  decode(l_paramedical_time_spent, pk_alert_constant.g_yes, 'M', 'A')
                                                                 WHEN t.internal_name_child = g_ds_follow_up_notes_text THEN
                                                                  decode(l_paramedical_note_mandatory, pk_alert_constant.g_yes, 'M', 'A')
                                                             END,
                                       flg_multi_status   => NULL,
                                       idx                => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             ORDER BY t.rn;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_followup_notes_values;

    FUNCTION set_followup_notes
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_mng_followup         IN management_follow_up.id_management_follow_up%TYPE,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_str          IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_tbl_val_umea         IN table_table_varchar DEFAULT NULL,
        o_mng_followup         OUT management_follow_up.id_management_follow_up%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        i_notes                 management_follow_up.notes%TYPE;
        i_start_dt              VARCHAR2(200 CHAR);
        i_time_spent            management_follow_up.time_spent%TYPE;
        l_hour                  management_follow_up.time_spent%TYPE;
        l_minute                management_follow_up.time_spent%TYPE;
        l_time_date             VARCHAR2(200 CHAR);
        i_unit_time             management_follow_up.id_unit_time%TYPE;
        i_next_dt               VARCHAR2(200 CHAR);
        i_flg_end_followup      sys_domain.val%TYPE;
        i_dt_next_enc_precision management_follow_up.dt_next_enc_precision%TYPE;
        i_dt_register           TIMESTAMP;
        l_time_unit_measure     management_follow_up.id_unit_time%TYPE;
    
    BEGIN
        /*TODO - unidades de medida e precisão da data*/
        i_dt_register := current_timestamp;
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) = g_ds_follow_up_notes_start
            THEN
                i_start_dt := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = g_ds_follow_up_notes_spent
            THEN
                l_time_date := to_number(i_tbl_real_val(i) (1));
                --    l_time_unit_measure := to_number(i_tbl_val_umea(i) (1));
            ELSIF i_tbl_ds_internal_name(i) = g_ds_follow_up_notes_end
            THEN
                i_flg_end_followup := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = g_ds_follow_up_notes_text
            THEN
                i_notes := i_tbl_val_clob(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = g_ds_follow_up_notes_next
            THEN
                i_next_dt := i_tbl_real_val(i) (1);
            END IF;
        END LOOP;
        IF l_time_date IS NOT NULL
        THEN
            --    i_time_spent := l_time_date;
            l_time_date := substr(l_time_date, 9, 4);
            --         i_time_spent := 
            l_hour       := to_number(substr(l_time_date, 1, 2));
            l_minute     := to_number(substr(l_time_date, 3));
            i_time_spent := (l_hour * g_hour) + l_minute;
            IF l_time_unit_measure IS NOT NULL
            THEN
                i_unit_time := l_time_unit_measure;
            ELSE
                i_unit_time := pk_paramedical_prof_core.g_id_unit_minutes;
            END IF;
        END IF;
    
        IF NOT pk_paramedical_prof_core.set_followup_notes(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_mng_followup          => i_mng_followup,
                                                           i_episode               => i_id_episode,
                                                           i_notes                 => i_notes,
                                                           i_start_dt              => i_start_dt,
                                                           i_time_spent            => i_time_spent,
                                                           i_unit_time             => i_unit_time,
                                                           i_next_dt               => i_next_dt,
                                                           i_flg_end_followup      => i_flg_end_followup,
                                                           i_dt_next_enc_precision => i_dt_next_enc_precision,
                                                           i_dt_register           => i_dt_register,
                                                           o_mng_followup          => o_mng_followup,
                                                           o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => ' set_followup_notes',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_followup_notes;

    FUNCTION get_followup_notes_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE DEFAULT NULL,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up    OUT pk_types.cursor_type,
        o_time_units   OUT pk_types.cursor_type,
        o_domain       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_notes_title            sys_message.desc_message%TYPE;
        l_start_dt_title         sys_message.desc_message%TYPE;
        l_time_title             sys_message.desc_message%TYPE;
        l_next_dt_title          sys_message.desc_message%TYPE;
        l_next_dt_enable         VARCHAR2(1 CHAR);
        l_epis_type              epis_type.id_epis_type%TYPE := NULL;
        l_has_end_encounter      VARCHAR2(1);
        l_has_time_mandatory     VARCHAR2(1);
        l_end_followup           sys_message.desc_message%TYPE;
        l_domain_ux              t_coll_values_domain_ux := t_coll_values_domain_ux();
        l_domain_func            pk_types.cursor_type;
        l_desc_val               VARCHAR2(300 CHAR);
        l_val                    VARCHAR2(300 CHAR);
        l_img_name               VARCHAR2(300 CHAR);
        l_rank                   NUMBER(6);
        l_count                  NUMBER := 0;
        l_opinion                t_rec_opinion;
        l_paramedical_time_spent sys_config.value%TYPE;
        l_id_schedule            schedule.id_schedule%TYPE;
        l_cat_prof               category.flg_type%TYPE := pk_prof_utils.get_category(i_lang => i_lang,
                                                                                      i_prof => i_prof);
        l_exist_schedule         NUMBER := 0;
        l_id_software            table_number;
    BEGIN
    
        l_opinion := get_opinion_active_value(i_lang, i_prof, i_episode);
    
        l_paramedical_time_spent := pk_sysconfig.get_config(' paramedical_prof_followup_time_spent_mandatory', i_prof);
    
        IF i_episode IS NOT NULL
        THEN
            SELECT e.id_epis_type, ei.id_schedule
              INTO l_epis_type, l_id_schedule
              FROM episode e
              JOIN epis_info ei
                ON ei.id_episode = e.id_episode
             WHERE e.id_episode = i_episode;
        END IF;
    
        IF (l_epis_type IN (pk_alert_constant.g_epis_type_social,
                            pk_alert_constant.g_epis_type_dietitian,
                            pk_alert_constant.g_epis_type_psychologist) OR
           i_prof.software IN (pk_alert_constant.g_soft_act_therapist))
        THEN
            SELECT etsi.id_software
              BULK COLLECT
              INTO l_id_software
              FROM epis_type_soft_inst etsi
             WHERE etsi.id_epis_type = l_epis_type
               AND etsi.id_institution IN (0)
             ORDER BY etsi.id_software DESC;
            IF l_id_software.exists(1)
            THEN
                IF l_id_software(1) = i_prof.software
                THEN
                    l_has_end_encounter := pk_alert_constant.g_no;
                ELSE
                    l_has_end_encounter := pk_alert_constant.g_yes;
                END IF;
            ELSE
                l_has_end_encounter := pk_alert_constant.g_yes;
            END IF;
        
            IF l_paramedical_time_spent = pk_alert_constant.g_yes
            THEN
                l_has_time_mandatory := pk_alert_constant.g_yes;
            ELSE
                l_has_time_mandatory := pk_alert_constant.g_no;
            END IF;
        ELSIF l_epis_type = pk_alert_constant.g_epis_type_home_health_care
        THEN
            SELECT COUNT(1)
              INTO l_exist_schedule
              FROM sch_resource sr
             WHERE sr.id_schedule = l_id_schedule
               AND pk_prof_utils.get_category(i_lang => i_lang,
                                              i_prof => profissional(sr.id_professional,
                                                                     sr.id_institution,
                                                                     i_prof.software)) = l_cat_prof;
            IF l_exist_schedule > 0
            THEN
                l_has_end_encounter := pk_alert_constant.g_no;
            ELSE
                --if you haven' t scheduled it FOR THE professional, THEN you can do THE END OF THE followup 
                l_has_end_encounter := pk_alert_constant.g_yes;
            END IF;
        ELSE
            l_has_end_encounter  := pk_alert_constant.g_yes;
            l_has_time_mandatory := pk_alert_constant.g_no;
        END IF;
    
        g_sysdate_tstz   := current_timestamp;
        l_notes_title    := format_str_header_w_colon(i_srt          => pk_message.get_message(i_lang,
                                                                                               i_prof,
                                                                                               'SOCIAL_T103'),
                                                      i_is_report    => 'Y',
                                                      i_is_mandatory => 'Y');
        l_start_dt_title := format_str_header_w_colon(i_srt          => pk_message.get_message(i_lang,
                                                                                               i_prof,
                                                                                               'SOCIAL_T104'),
                                                      i_is_report    => 'Y',
                                                      i_is_mandatory => 'Y');
        l_time_title     := format_str_header_w_colon(i_srt          => pk_message.get_message(i_lang,
                                                                                               i_prof,
                                                                                               'SOCIAL_T105'),
                                                      i_is_report    => 'Y',
                                                      i_is_mandatory => l_has_time_mandatory);
        l_next_dt_title  := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T154'),
                                                      i_is_report => 'Y');
    
        l_end_followup := format_str_header_w_colon(i_srt          => pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'PARAMEDICAL_T023'),
                                                    i_is_report    => 'Y',
                                                    i_is_mandatory => 'Y');
    
        l_next_dt_enable := check_hospital_profile(i_prof => i_prof);
    
        IF i_mng_followup IS NULL
        THEN
            -- if no management_follow_up id is provided,
            -- we are creating a new record...
            g_error := 'OPEN o_follow_up I';
            OPEN o_follow_up FOR
                SELECT l_notes_title title_notes,
                       NULL desc_notes,
                       l_opinion.id_opinion op,
                       l_start_dt_title title_start_dt,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) desc_start_dt,
                       pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof) flg_start_dt,
                       l_time_title title_time_spent,
                       NULL desc_time_spent,
                       NULL flg_time_spent,
                       NULL measure_time_spent,
                       l_next_dt_title title_next_dt,
                       NULL desc_next_dt,
                       NULL flg_next_dt,
                       l_next_dt_enable next_dt_enable,
                       l_end_followup title_end_followup,
                       pk_sysdomain.get_domain(pk_list.g_yes_no, pk_alert_constant.g_no, i_lang) desc_end_followup,
                       pk_alert_constant.g_no flg_end_followup,
                       l_has_end_encounter followup_end_enable,
                       l_opinion.dt_problem_str desc_start_min_dt
                  FROM dual;
        ELSE
            -- ... otherwise, we are editing a previous record
            g_error := 'OPEN o_follow_up II';
            OPEN o_follow_up FOR
                SELECT l_notes_title title_notes,
                       mfu.notes desc_notes,
                       l_start_dt_title title_start_dt,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof) desc_start_dt,
                       pk_date_utils.date_send_tsz(i_lang, mfu.dt_start, i_prof) flg_start_dt,
                       l_time_title title_time_spent,
                       nvl2(mfu.time_spent,
                            get_format_time_spent(i_lang,
                                                  time_spent_convert(i_prof, mfu.id_episode, mfu.id_management_follow_up)),
                            pk_paramedical_prof_core.c_dashes) desc_time_spent,
                       mfu.time_spent flg_time_spent,
                       mfu.id_unit_time measure_time_spent,
                       l_next_dt_title title_next_dt,
                       get_partial_date_format(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_date      => mfu.dt_next_encounter,
                                               i_precision => mfu.dt_next_enc_precision) desc_next_dt,
                       pk_date_utils.date_send_tsz(i_lang, mfu.dt_next_encounter, i_prof) flg_next_dt,
                       l_next_dt_enable next_dt_enable,
                       l_end_followup title_end_followup,
                       decode(mfu.flg_end_followup,
                              NULL,
                              pk_sysdomain.get_domain(pk_list.g_yes_no, pk_alert_constant.g_no, i_lang),
                              pk_sysdomain.get_domain(pk_list.g_yes_no, mfu.flg_end_followup, i_lang)) desc_end_followup,
                       nvl(mfu.flg_end_followup, pk_alert_constant.g_no) flg_end_followup,
                       l_has_end_encounter followup_end_enable,
                       l_opinion.dt_problem_str desc_start_min_dt
                  FROM management_follow_up mfu
                  LEFT JOIN unit_measure um
                    ON mfu.id_unit_time = um.id_unit_measure
                 WHERE mfu.id_management_follow_up = i_mng_followup;
        
        END IF;
    
        g_error := 'CALL get_followup_time_units';
        get_followup_time_units(i_prof => i_prof, o_time_units => o_time_units);
    
        IF NOT pk_list.get_yes_no_list(i_lang => i_lang, o_list => l_domain_func, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        LOOP
            FETCH l_domain_func
                INTO l_desc_val, l_val, l_img_name, l_rank;
            EXIT WHEN l_domain_func%NOTFOUND;
        
            l_domain_ux.extend();
        
            l_count := l_count + 1;
        
            l_domain_ux(l_count) := t_rec_values_domain_ux(label => l_desc_val,
                                                           data  => l_val,
                                                           icon  => l_img_name,
                                                           rank  => l_rank);
        END LOOP;
    
        OPEN o_domain FOR
            SELECT *
              FROM TABLE(l_domain_ux) d;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_FOLLOWUP_NOTES_EDIT',
                                                     o_error    => o_error);
    END get_followup_notes_edit;

    /*
    * Set follow up notes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param i_episode        episode identifier
    * @param i_notes          follow up notes
    * @param i_start_dt       start date
    * @param i_time_spent     time spent
    * @param i_unit_time      time spent unit measure
    * @param i_next_dt        next date
    * @param i_flg_end_followup flagend of followup  Y/N  
    * @param o_mng_followup   created follow up notes identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION set_followup_notes
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_mng_followup          IN management_follow_up.id_management_follow_up%TYPE,
        i_episode               IN management_follow_up.id_episode%TYPE,
        i_notes                 IN management_follow_up.notes%TYPE,
        i_start_dt              IN VARCHAR2,
        i_time_spent            IN management_follow_up.time_spent%TYPE,
        i_unit_time             IN management_follow_up.id_unit_time%TYPE,
        i_next_dt               IN VARCHAR2,
        i_flg_end_followup      IN sys_domain.val%TYPE DEFAULT NULL,
        i_dt_next_enc_precision IN management_follow_up.dt_next_enc_precision%TYPE DEFAULT NULL,
        i_dt_register           IN TIMESTAMP DEFAULT NULL,
        o_mng_followup          OUT management_follow_up.id_management_follow_up%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out     table_varchar := table_varchar();
        l_mng_followup management_follow_up.id_management_follow_up%TYPE;
        l_start_dt     management_follow_up.dt_start%TYPE;
        l_next_dt      management_follow_up.dt_next_encounter%TYPE;
    
        l_opinion_hist opinion_hist.id_opinion_hist%TYPE;
        l_opinion      t_rec_opinion;
        l_opinion_type opinion_type.id_opinion_type%TYPE;
    
        l_dt_temp_diag_precision management_follow_up.dt_next_enc_precision%TYPE;
        l_dt_next_encounter      management_follow_up.dt_next_encounter%TYPE;
        l_dt_next_enc_precision  management_follow_up.dt_next_enc_precision%TYPE;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
        l_visit           visit.id_visit%TYPE;
        l_patient         patient.id_patient%TYPE;
        l_prof_id         professional.id_professional%TYPE;
        l_id_room         room.id_room%TYPE;
    
    BEGIN
        l_opinion      := get_opinion_active_value(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        l_opinion_type := get_id_opinion_type(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        g_sysdate_tstz := current_timestamp;
        l_start_dt     := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_start_dt,
                                                        i_timezone  => NULL);
        l_next_dt      := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_next_dt,
                                                        i_timezone  => NULL);
    
        IF i_mng_followup IS NOT NULL
        THEN
            g_error := 'CALL ts_management_follow_up.upd';
            ts_management_follow_up.upd(id_management_follow_up_in => i_mng_followup,
                                        flg_status_in              => pk_case_management.g_mfu_status_outd,
                                        flg_status_nin             => FALSE,
                                        rows_out                   => l_rows_out);
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'MANAGEMENT_FOLLOW_UP',
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
            l_rows_out := table_varchar();
        END IF;
    
        IF i_dt_next_enc_precision IS NOT NULL
        THEN
            l_dt_temp_diag_precision := i_dt_next_enc_precision;
        END IF;
    
        IF i_next_dt IS NOT NULL
        THEN
            IF NOT parse_date(i_lang      => i_lang,
                              i_prof      => i_prof,
                              i_date      => i_next_dt,
                              i_precision => l_dt_temp_diag_precision,
                              o_date      => l_dt_next_encounter,
                              o_precision => l_dt_next_enc_precision,
                              o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'CALL ts_management_follow_up.ins';
        ts_management_follow_up.ins(id_management_follow_up_out => l_mng_followup,
                                    id_episode_in               => i_episode,
                                    time_spent_in               => i_time_spent,
                                    flg_status_in               => pk_case_management.g_mfu_status_active,
                                    id_unit_time_in             => i_unit_time,
                                    dt_register_in              => nvl(i_dt_register, g_sysdate_tstz),
                                    id_professional_in          => i_prof.id,
                                    notes_in                    => i_notes,
                                    id_parent_in                => i_mng_followup,
                                    dt_start_in                 => l_start_dt,
                                    dt_next_encounter_in        => nvl(l_dt_next_encounter, l_next_dt),
                                    flg_end_followup_in         => i_flg_end_followup,
                                    id_opinion_type_in          => l_opinion_type,
                                    dt_next_enc_precision_in    => i_dt_next_enc_precision,
                                    id_opinion_in               => l_opinion.id_opinion,
                                    rows_out                    => l_rows_out);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MANAGEMENT_FOLLOW_UP',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        o_mng_followup := l_mng_followup;
    
        IF (i_flg_end_followup = pk_alert_constant.g_yes)
        THEN
        
            IF l_opinion.id_opinion IS NOT NULL
            THEN
                g_error := 'CALL pk_opinion_pc.set_consult_request_state';
                IF NOT pk_opinion.set_consult_request_state(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_opinion      => l_opinion.id_opinion,
                                                            i_state        => pk_opinion.g_opinion_over,
                                                            o_opinion_hist => l_opinion_hist,
                                                            o_error        => o_error)
                THEN
                    RAISE g_sw_generic_exception;
                END IF;
            
                SELECT e.id_visit, e.id_patient
                  INTO l_visit, l_patient
                  FROM episode e
                 WHERE e.id_episode = i_episode;
            
                SELECT o.id_prof_questions, ei.id_room
                  INTO l_prof_id, l_id_room
                  FROM opinion o
                  JOIN episode e
                    ON e.id_episode = o.id_episode
                  JOIN epis_info ei
                    ON ei.id_episode = e.id_episode
                 WHERE o.id_opinion = l_opinion.id_opinion;
            
                l_sys_alert_event.id_sys_alert    := pk_opinion.g_alert_end_followup;
                l_sys_alert_event.id_software     := i_prof.software;
                l_sys_alert_event.id_institution  := i_prof.institution;
                l_sys_alert_event.id_patient      := l_patient;
                l_sys_alert_event.id_visit        := l_visit;
                l_sys_alert_event.id_episode      := i_episode;
                l_sys_alert_event.id_record       := l_opinion.id_opinion;
                l_sys_alert_event.dt_record       := l_opinion.dt_problem_tstz;
                l_sys_alert_event.id_professional := l_prof_id;
                l_sys_alert_event.id_room         := l_id_room;
            
                IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_FOLLOWUP_NOTES',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_followup_notes;
    --

    /********************************************************************************************
    * Retrieves the list of Categories/Intervention plans parametrized as 'searchable'.
    * This function is prepared to return categories or plans hierarchy, where either
    * categories or plans can have an undetermined number of levels.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat       ID intervention plan category. Can be null, if no
    *                                 category is selected.
    * @ param i_interv_plan           ID intervention plan. Can be null, if no
    *                                 intervention plan is selected.
    * @ param i_inter_type            Intervention plna type
    * @ param o_interv_plan_info      List of categories/intervention plans
    * @ param o_header_label          Label for the screen header
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_plan_cat  IN interv_plan_category.id_interv_plan_category%TYPE,
        i_interv_plan      IN interv_plan.id_interv_plan%TYPE,
        i_inter_type       IN interv_plan_type.flg_type%TYPE,
        o_interv_plan_info OUT pk_types.cursor_type,
        o_header_label     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_plan_cat_tab table_number := table_number();
    BEGIN
    
        IF i_interv_plan_cat IS NULL
        THEN
            IF i_interv_plan IS NOT NULL
            THEN
                IF NOT get_interv_plan_list_int(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_interv_plan_cat => i_interv_plan_cat,
                                                i_interv_plan     => i_interv_plan,
                                                i_ipdcs_flg_type  => pk_alert_constant.g_interv_plan_type_p,
                                                o_interv_plan     => o_interv_plan_info,
                                                o_error           => o_error)
                THEN
                    RAISE g_sw_generic_exception;
                END IF;
                o_header_label := pk_message.get_message(i_lang, 'SOCIAL_T121');
            ELSE
                --OPEN o_interv_plan_cat FOR
                SELECT id
                  BULK COLLECT
                  INTO l_interv_plan_cat_tab
                  FROM (SELECT ipc.id_interv_plan_category id
                          FROM interv_plan_category ipc
                          JOIN interv_plan ip
                            ON ip.id_interv_plan_category = ipc.id_interv_plan_category
                          JOIN interv_plan_dep_clin_serv ipdcs
                            ON ipdcs.id_interv_plan = ip.id_interv_plan
                         WHERE ipc.flg_available = pk_alert_constant.get_yes
                           AND ipc.id_parent IS NULL
                           AND ip.flg_available = pk_alert_constant.get_yes
                           AND ip.id_parent IS NULL
                           AND ipdcs.id_interv_plan = ip.id_interv_plan
                           AND ipdcs.id_software IN (i_prof.software, 0)
                           AND ipdcs.id_institution IN (i_prof.institution, 0)
                           AND ipdcs.flg_available = pk_alert_constant.g_yes
                         GROUP BY ipc.id_interv_plan_category, ipc.code_interv_plan_category);
            
                IF l_interv_plan_cat_tab.count <> 0
                THEN
                
                    --
                    OPEN o_interv_plan_info FOR
                        SELECT NULL id_plan,
                               ipc.id_interv_plan_category id_cat,
                               pk_translation.get_translation(i_lang, ipc.code_interv_plan_category) info_desc,
                               has_child_interv_plan_cat(i_lang,
                                                         i_prof,
                                                         ipc.id_interv_plan_category,
                                                         pk_alert_constant.g_interv_plan_type_p) has_child
                          FROM interv_plan_category ipc
                          JOIN TABLE(l_interv_plan_cat_tab) tab_cat
                            ON (ipc.id_interv_plan_category = tab_cat.column_value)
                         WHERE has_child_interv_plan_cat(i_lang,
                                                         i_prof,
                                                         ipc.id_interv_plan_category,
                                                         pk_alert_constant.g_interv_plan_type_p) =
                               pk_alert_constant.g_yes
                         ORDER BY info_desc;
                
                    o_header_label := pk_message.get_message(i_lang, 'SOCIAL_T120');
                
                ELSE
                    IF NOT get_interv_plan_list_int(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_interv_plan_cat => i_interv_plan_cat,
                                                    i_interv_plan     => i_interv_plan,
                                                    i_ipdcs_flg_type  => pk_alert_constant.g_interv_plan_type_p,
                                                    o_interv_plan     => o_interv_plan_info,
                                                    o_error           => o_error)
                    THEN
                        RAISE g_sw_generic_exception;
                    END IF;
                    o_header_label := pk_message.get_message(i_lang, 'SOCIAL_T121');
                END IF;
            END IF;
        
        ELSE
            SELECT id
              BULK COLLECT
              INTO l_interv_plan_cat_tab
              FROM (SELECT ipc.id_interv_plan_category id
                      FROM interv_plan_category ipc
                     WHERE ipc.flg_available = pk_alert_constant.get_yes
                          --
                       AND ipc.id_parent = i_interv_plan_cat
                    --
                     GROUP BY ipc.id_interv_plan_category, ipc.code_interv_plan_category);
        
            IF l_interv_plan_cat_tab.count <> 0
            THEN
                OPEN o_interv_plan_info FOR
                    SELECT NULL id_plan,
                           ipc.id_interv_plan_category id_cat,
                           pk_translation.get_translation(i_lang, ipc.code_interv_plan_category) info_desc,
                           has_child_interv_plan_cat(i_lang,
                                                     i_prof,
                                                     ipc.id_interv_plan_category,
                                                     pk_alert_constant.g_interv_plan_type_p) has_child
                      FROM interv_plan_category ipc
                     WHERE ipc.flg_available = pk_alert_constant.get_yes
                          --
                       AND ipc.id_parent = i_interv_plan_cat
                          --
                       AND has_child_interv_plan_cat(i_lang,
                                                     i_prof,
                                                     ipc.id_interv_plan_category,
                                                     pk_alert_constant.g_interv_plan_type_p) = pk_alert_constant.g_yes
                     GROUP BY ipc.id_interv_plan_category, ipc.code_interv_plan_category
                     ORDER BY info_desc;
                o_header_label := pk_message.get_message(i_lang, 'SOCIAL_T120');
            ELSE
                IF NOT get_interv_plan_list_int(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_interv_plan_cat => i_interv_plan_cat,
                                                i_interv_plan     => i_interv_plan,
                                                i_ipdcs_flg_type  => pk_alert_constant.g_interv_plan_type_p,
                                                o_interv_plan     => o_interv_plan_info,
                                                o_error           => o_error)
                THEN
                    RAISE g_sw_generic_exception;
                END IF;
                o_header_label := pk_message.get_message(i_lang, 'SOCIAL_T121');
            END IF;
        
        END IF;
        --
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan_info);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_LIST',
                                                     o_error);
        
    END get_interv_plan_list;
    --

    /********************************************************************************************
    * Retrieves the list of Categories/Intervention plans parametrized as 'more frequents'.
    * This function is prepared to return categories or plans hierarchy, where either
    * categories or plans can have an undetermined number of levels.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat       ID intervention plan category. Can be null, if no
    *                                 category is selected.
    * @ param i_interv_plan           ID intervention plan. Can be null, if no
    *                                 intervention plan is selected.
    * @ param i_inter_type            Intervention plna type
    * @ param o_interv_plan_info      List of categories/intervention plans
    * @ param o_header_label          Label for the screen header
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_freq_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_plan_cat  IN interv_plan_category.id_interv_plan_category%TYPE,
        i_interv_plan      IN interv_plan.id_interv_plan%TYPE,
        i_inter_type       IN interv_plan_type.flg_type%TYPE,
        o_interv_plan_info OUT pk_types.cursor_type,
        o_header_label     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_plan_cat_tab table_number := table_number();
    BEGIN
    
        IF i_interv_plan_cat IS NULL
        THEN
            IF i_interv_plan IS NOT NULL
            THEN
                IF NOT get_interv_plan_list_int(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_interv_plan_cat => i_interv_plan_cat,
                                                i_interv_plan     => i_interv_plan,
                                                i_ipdcs_flg_type  => pk_alert_constant.g_interv_plan_type_m,
                                                o_interv_plan     => o_interv_plan_info,
                                                o_error           => o_error)
                THEN
                    RAISE g_sw_generic_exception;
                END IF;
                o_header_label := pk_message.get_message(i_lang, 'SOCIAL_T121');
            ELSE
                --OPEN o_interv_plan_cat FOR
                SELECT id
                  BULK COLLECT
                  INTO l_interv_plan_cat_tab
                  FROM (SELECT ipc.id_interv_plan_category id
                          FROM interv_plan_category ipc
                          JOIN interv_plan ip
                            ON (ipc.id_interv_plan_category = ip.id_interv_plan_category)
                         WHERE ipc.flg_available = pk_alert_constant.get_yes
                           AND ip.flg_available = pk_alert_constant.get_yes
                           AND ipc.id_parent IS NULL
                         GROUP BY ipc.id_interv_plan_category, ipc.code_interv_plan_category);
            
                IF l_interv_plan_cat_tab.count <> 0
                THEN
                    --
                    OPEN o_interv_plan_info FOR
                        SELECT NULL id_plan,
                               ipc.id_interv_plan_category id_cat,
                               pk_translation.get_translation(i_lang, ipc.code_interv_plan_category) info_desc,
                               has_child_interv_plan_cat(i_lang,
                                                         i_prof,
                                                         ipc.id_interv_plan_category,
                                                         pk_alert_constant.g_interv_plan_type_m) has_child
                          FROM interv_plan_category ipc
                          JOIN TABLE(l_interv_plan_cat_tab) tab_cat
                            ON (ipc.id_interv_plan_category = tab_cat.column_value)
                         WHERE has_child_interv_plan_cat(i_lang,
                                                         i_prof,
                                                         ipc.id_interv_plan_category,
                                                         pk_alert_constant.g_interv_plan_type_m) =
                               pk_alert_constant.g_yes
                         ORDER BY info_desc;
                
                    o_header_label := pk_message.get_message(i_lang, 'SOCIAL_T120');
                
                ELSE
                    IF NOT get_interv_plan_list_int(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_interv_plan_cat => i_interv_plan_cat,
                                                    i_interv_plan     => i_interv_plan,
                                                    i_ipdcs_flg_type  => pk_alert_constant.g_interv_plan_type_m,
                                                    o_interv_plan     => o_interv_plan_info,
                                                    o_error           => o_error)
                    THEN
                        RAISE g_sw_generic_exception;
                    END IF;
                    o_header_label := pk_message.get_message(i_lang, 'SOCIAL_T121');
                END IF;
            END IF;
        
        ELSE
            SELECT id
              BULK COLLECT
              INTO l_interv_plan_cat_tab
              FROM (SELECT ipc.id_interv_plan_category id
                      FROM interv_plan_category ipc
                      JOIN interv_plan ip
                        ON (ipc.id_interv_plan_category = ip.id_interv_plan_category)
                     WHERE ipc.flg_available = pk_alert_constant.get_yes
                       AND ip.flg_available = pk_alert_constant.get_yes
                          --
                       AND ipc.id_parent = i_interv_plan_cat
                          --
                       AND has_child_interv_plan_cat(i_lang,
                                                     i_prof,
                                                     ipc.id_interv_plan_category,
                                                     pk_alert_constant.g_interv_plan_type_m) = pk_alert_constant.g_yes
                     GROUP BY ipc.id_interv_plan_category, ipc.code_interv_plan_category);
        
            IF l_interv_plan_cat_tab.count <> 0
            THEN
                OPEN o_interv_plan_info FOR
                    SELECT NULL id_plan,
                           ipc.id_interv_plan_category id_cat,
                           pk_translation.get_translation(i_lang, ipc.code_interv_plan_category) info_desc,
                           has_child_interv_plan_cat(i_lang,
                                                     i_prof,
                                                     ipc.id_interv_plan_category,
                                                     pk_alert_constant.g_interv_plan_type_m) has_child
                      FROM interv_plan_category ipc
                      JOIN interv_plan ip
                        ON (ipc.id_interv_plan_category = ip.id_interv_plan_category)
                     WHERE ipc.flg_available = pk_alert_constant.get_yes
                       AND ip.flg_available = pk_alert_constant.get_yes
                          --
                       AND ipc.id_parent = i_interv_plan_cat
                          --
                       AND has_child_interv_plan_cat(i_lang,
                                                     i_prof,
                                                     ipc.id_interv_plan_category,
                                                     pk_alert_constant.g_interv_plan_type_m) = pk_alert_constant.g_yes
                     GROUP BY ipc.id_interv_plan_category, ipc.code_interv_plan_category
                     ORDER BY info_desc;
                o_header_label := pk_message.get_message(i_lang, 'SOCIAL_T120');
            ELSE
                IF NOT get_interv_plan_list_int(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_interv_plan_cat => i_interv_plan_cat,
                                                i_interv_plan     => i_interv_plan,
                                                i_ipdcs_flg_type  => pk_alert_constant.g_interv_plan_type_m,
                                                o_interv_plan     => o_interv_plan_info,
                                                o_error           => o_error)
                THEN
                    RAISE g_sw_generic_exception;
                END IF;
                o_header_label := pk_message.get_message(i_lang, 'SOCIAL_T121');
            END IF;
        
        END IF;
        --
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan_info);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_FREQ_LIST',
                                                     o_error);
        
    END get_interv_plan_freq_list;
    --

    /********************************************************************************************
    * Retrieves the list Intervention plans
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat       ID intervention plan category. Can be null, if no
    *                                 category is selected.
    * @ param i_interv_plan           ID intervention plan. Can be null, if no
    *                                 intervention plan is selected.
    * @ param o_interv_plan           List of categories/intervention plans
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_list_int
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_interv_plan_cat IN interv_plan_category.id_interv_plan_category%TYPE,
        i_interv_plan     IN interv_plan.id_interv_plan%TYPE,
        i_ipdcs_flg_type  IN interv_plan_dep_clin_serv.flg_type%TYPE,
        o_interv_plan     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_interv_plan IS NULL
        THEN
            OPEN o_interv_plan FOR
                SELECT ip.id_interv_plan id_plan,
                       NULL id_cat,
                       pk_translation.get_translation(i_lang, ip.code_interv_plan) info_desc,
                       has_child_interv_plan(i_lang, i_prof, ip.id_interv_plan, pk_alert_constant.g_interv_plan_type_p) has_child
                  FROM interv_plan ip, interv_plan_dep_clin_serv ipdcs
                 WHERE ip.flg_available = pk_alert_constant.get_yes
                   AND ip.id_parent IS NULL
                   AND ((ip.id_interv_plan_category = i_interv_plan_cat AND i_interv_plan_cat IS NOT NULL) OR
                       i_interv_plan_cat IS NULL)
                   AND ipdcs.id_interv_plan = ip.id_interv_plan
                   AND ipdcs.id_software IN (i_prof.software, 0)
                   AND ipdcs.id_institution IN (i_prof.institution, 0)
                   AND ipdcs.flg_available = pk_alert_constant.g_yes
                   AND ipdcs.flg_type = i_ipdcs_flg_type
                 GROUP BY ip.id_interv_plan, ip.id_interv_plan_category, ip.code_interv_plan
                 ORDER BY info_desc;
        ELSE
            OPEN o_interv_plan FOR
                SELECT ip.id_interv_plan id_plan,
                       NULL id_cat,
                       pk_translation.get_translation(i_lang, ip.code_interv_plan) info_desc,
                       has_child_interv_plan(i_lang, i_prof, ip.id_interv_plan, pk_alert_constant.g_interv_plan_type_p) has_child
                  FROM interv_plan ip, interv_plan_dep_clin_serv ipdcs
                 WHERE ip.flg_available = pk_alert_constant.get_yes
                      --
                   AND ip.id_parent = i_interv_plan
                      --
                   AND ((ip.id_interv_plan_category = i_interv_plan_cat AND i_interv_plan_cat IS NOT NULL) OR
                       i_interv_plan_cat IS NULL)
                   AND ipdcs.id_interv_plan = ip.id_interv_plan
                   AND ipdcs.id_software IN (i_prof.software, 0)
                   AND ipdcs.id_institution IN (i_prof.institution, 0)
                   AND ipdcs.flg_available = pk_alert_constant.g_yes
                   AND ipdcs.flg_type = i_ipdcs_flg_type
                 GROUP BY ip.id_interv_plan, ip.id_interv_plan_category, ip.code_interv_plan
                 ORDER BY info_desc;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_LIST_INT',
                                                     o_error);
        
    END get_interv_plan_list_int;
    --

    /********************************************************************************************
    * Validate if a given intervention plan category has childs
    *
    * @ param i_lang                   Preferred language ID for this professional
    * @ param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_cat        ID intervention plan category
    *
    * @return                         Y/N
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION has_child_interv_plan_cat
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_interv_plan_cat IN interv_plan_category.id_interv_plan_category%TYPE,
        i_ipdcs_flg_type  IN interv_plan_dep_clin_serv.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_has_chid VARCHAR2(1 CHAR) := 'N';
        l_error    t_error_out;
    BEGIN
    
        g_error := 'GET_INTER_PLAN_CAT_HAS_CHILDS';
        pk_alertlog.log_debug(g_error || ': i_interv_plan_cat = ' || i_interv_plan_cat);
        SELECT decode(count_n, 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_has_chid
          FROM (SELECT COUNT(*) count_n
                  FROM (SELECT ipc.id_interv_plan_category id
                          FROM interv_plan_category ipc
                         WHERE ipc.id_parent = i_interv_plan_cat
                        --
                        UNION ALL
                        SELECT ip.id_interv_plan id
                          FROM interv_plan ip, interv_plan_dep_clin_serv ipdcs
                         WHERE ip.id_interv_plan_category = i_interv_plan_cat
                           AND ipdcs.id_software IN (i_prof.software, 0)
                           AND ipdcs.id_institution IN (i_prof.institution, 0)
                           AND ipdcs.flg_available = pk_alert_constant.g_yes
                           AND ipdcs.flg_type = i_ipdcs_flg_type));
    
        RETURN l_has_chid;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'HAS_CHILD_INTERV_PLAN_CAT',
                                              l_error);
        
    END has_child_interv_plan_cat;
    --

    /********************************************************************************************
    * Validate if a given intervention plan has childs
    *
    * @ param i_lang                   Preferred language ID for this professional
    * @ param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan            ID intervention plan
    *
    * @return                         Y/N
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION has_child_interv_plan
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_interv_plan    IN interv_plan.id_interv_plan%TYPE,
        i_ipdcs_flg_type IN interv_plan_dep_clin_serv.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_has_chid VARCHAR2(1 CHAR) := 'N';
        l_error    t_error_out;
    BEGIN
    
        g_error := 'GET_INTER_PLAN_HAS_CHILDS';
        pk_alertlog.log_debug(g_error || ': i_interv_plan = ' || i_interv_plan);
        SELECT decode(count_n, 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_has_chid
          FROM (SELECT COUNT(*) count_n
                  FROM (SELECT ip.id_interv_plan id
                          FROM interv_plan ip, interv_plan_dep_clin_serv ipdcs
                         WHERE ip.id_parent = i_interv_plan
                           AND ipdcs.id_interv_plan = ip.id_interv_plan
                           AND ipdcs.id_software IN (i_prof.software, 0)
                           AND ipdcs.id_institution IN (i_prof.institution, 0)
                           AND ipdcs.flg_available = pk_alert_constant.g_yes
                           AND ipdcs.flg_type = i_ipdcs_flg_type));
    
        RETURN l_has_chid;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'HAS_CHILD_INTERV_PLAN',
                                              l_error);
        
    END has_child_interv_plan;
    --
    /********************************************************************************************
    * Get the list of intervention plans for a patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_patient               Patient ID 
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Jorge Silva
    * @version                         0.1
    * @since                           2014/01/20
    **********************************************************************************************/
    FUNCTION get_interv_ehr_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        t_table_epis table_number := table_number();
        --
    BEGIN
        g_error := 'get_interv_ehr_plan - get the current patient';
        pk_alertlog.log_debug(g_error);
    
        t_table_epis := pk_patient.get_episode_list(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_patient        => i_id_patient,
                                                    i_id_episode        => NULL,
                                                    i_flg_visit_or_epis => pk_patient.g_scope_patient);
    
        --
        IF NOT get_interv_plan(i_lang          => i_lang,
                               i_prof          => i_prof,
                               i_id_epis       => t_table_epis,
                               o_interv_plan   => o_interv_plan,
                               o_screen_labels => o_screen_labels,
                               o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_EHR_PLAN',
                                                     o_error);
    END get_interv_ehr_plan;

    /********************************************************************************************
    * Get the list of intervention plans for a patient episode
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN episode.id_episode%TYPE,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        --
    BEGIN
        g_error := 'GET_INTERV_PLAN - get the current episode data:';
        pk_alertlog.log_debug(g_error);
        --
        IF NOT get_interv_plan(i_lang          => i_lang,
                               i_prof          => i_prof,
                               i_id_epis       => table_number(i_id_epis),
                               o_interv_plan   => o_interv_plan,
                               o_screen_labels => o_screen_labels,
                               o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN',
                                                     o_error);
    END get_interv_plan;
    --

    /********************************************************************************************
    * Get the list of intervention plans for a patient episode for a list of episodes(i_id_epis).
    * The goal of this function is to return the data for the patient ehr
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               List of Episode IDs (Epis type = Social Worker)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN table_number,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('COMMON_M008',
                                                                                          'PARAMEDICAL_T003',
                                                                                          'SOCIAL_T124',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'PARAMEDICAL_T002',
                                                                                          'PARAMEDICAL_T022'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'OPEN LABELS CURSOR';
        OPEN o_screen_labels FOR
            SELECT t_table_message_array('PARAMEDICAL_T003') interv_plan_main_header,
                   t_table_message_array('SOCIAL_T124') interv_plan_column,
                   t_table_message_array('PARAMEDICAL_T002') task_goal_column,
                   t_table_message_array('SOCIAL_T104') dt_begin_column,
                   t_table_message_array('SOCIAL_T125') dt_end_column,
                   t_table_message_array('SOCIAL_T004') state_column,
                   t_table_message_array('PARAMEDICAL_T022') social_diagnosis_column
              FROM dual;
    
        --
        g_error := 'GET CURSOR ALL INTERVENTION';
        OPEN o_interv_plan FOR
            SELECT id,
                   id_interv_plan,
                   interv_plan_desc,
                   id_task_goal_det,
                   desc_task_goal,
                   prof_sign,
                   dt_begin,
                   dt_begin_str,
                   dt_end,
                   dt_end_str,
                   has_notes,
                   notes,
                   flg_status,
                   desc_status,
                   get_id_diagnosis(i_lang, i_prof, tb_epis_diag) id_interv_diagnosis,
                   tb_desc_diag desc_interv_diagnosis,
                   pk_utils.concat_table(tb_desc_diag, '; ', 1, -1) desc_diagnosis
              FROM (SELECT id,
                           id_interv_plan,
                           interv_plan_desc,
                           id_task_goal_det,
                           desc_task_goal,
                           prof_sign,
                           dt_begin,
                           dt_begin_str,
                           dt_end,
                           dt_end_str,
                           has_notes,
                           notes,
                           flg_status,
                           desc_status,
                           tb_epis_diag,
                           get_desc_epis_diag(i_lang, i_prof, tb_epis_diag) tb_desc_diag
                      FROM (SELECT eip.id_epis_interv_plan id,
                                   eip.id_interv_plan id_interv_plan,
                                   CASE
                                        WHEN eip.id_interv_plan = 0 THEN
                                         eip.desc_other_interv_plan
                                        WHEN eip.id_interv_plan IS NULL THEN
                                         eip.desc_other_interv_plan
                                        ELSE
                                         pk_translation.get_translation(i_lang, ip.code_interv_plan)
                                    END interv_plan_desc,
                                   eip.id_task_goal_det,
                                   get_task_goal_desc(i_lang, i_prof, eip.id_task_goal_det) desc_task_goal,
                                   pk_tools.get_prof_description(i_lang, i_prof, eip.id_professional, eip.dt_begin, NULL) prof_sign,
                                   pk_date_utils.dt_chr_tsz(i_lang, eip.dt_begin, i_prof) dt_begin,
                                   pk_date_utils.date_send_tsz(i_lang, eip.dt_begin, i_prof) dt_begin_str,
                                   pk_date_utils.dt_chr_tsz(i_lang, eip.dt_end, i_prof) dt_end,
                                   pk_date_utils.date_send_tsz(i_lang, eip.dt_end, i_prof) dt_end_str,
                                   --We are not considering the actual state of the record!
                                   decode(eip.notes,
                                          NULL,
                                          decode(pk_paramedical_prof_core.get_notes_desc(i_lang,
                                                                                         i_prof,
                                                                                         eip.id_cancel_info_det),
                                                 NULL,
                                                 NULL,
                                                 '(' || t_table_message_array('COMMON_M008') || ')'),
                                          
                                          '(' || t_table_message_array('COMMON_M008') || ')') has_notes,
                                   eip.notes notes,
                                   eip.flg_status flg_status,
                                   pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS',
                                                           decode(eip.flg_status,
                                                                  pk_alert_constant.g_flg_status_e,
                                                                  pk_alert_constant.g_flg_status_a,
                                                                  eip.flg_status),
                                                           i_lang) desc_status,
                                   get_epis_interv_plan_diag(i_lang, i_prof, eip.id_epis_interv_plan, NULL) tb_epis_diag
                              FROM epis_interv_plan eip
                              LEFT JOIN interv_plan ip
                                ON (eip.id_interv_plan = ip.id_interv_plan)
                             WHERE eip.id_episode IN (SELECT column_value
                                                        FROM TABLE(i_id_epis))
                             ORDER BY pk_sysdomain.get_rank(i_lang,
                                                            'EPIS_INTERV_PLAN.FLG_STATUS',
                                                            decode(eip.flg_status,
                                                                   pk_alert_constant.g_flg_status_e,
                                                                   pk_alert_constant.g_flg_status_a,
                                                                   eip.flg_status)),
                                      eip.dt_begin,
                                      interv_plan_desc));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN',
                                                     o_error);
    END get_interv_plan;
    --

    /********************************************************************************************
    * Set one or more intervention plans for a given episode. This function can be used either to 
    * create new intervention plans or to edit existing ones. When editing intervention plans
    * the parameter i_id_epis_interv_plan must be not null.
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social worker)
    * @ param i_id_epis_interv_plan   List of IDs for the existing intervention plans to edit
    * @ param i_id_interv_plan        List of IDs for the intervention plans
    * @ param i_desc_other_interv_plan List of description of free text intervention plans
    * @ param i_dt_begin               List of begin dates for the intervention plans
    * @ param i_dt_end                 List of end dates for the intervention plans
    * @ param i_interv_plan_state      List of current states for the intervention plans
    * @ param i_notes                  List of notes for the intervention plans
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION set_interv_plan
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        i_id_epis_interv_plan IN table_number,
        i_id_interv_plan      IN table_number,
        --
        i_desc_other_interv_plan IN table_varchar,
        i_dt_begin               IN table_varchar,
        i_dt_end                 IN table_varchar,
        i_interv_plan_state      IN table_varchar,
        i_notes                  IN table_varchar,
        i_tb_tb_diag             IN table_table_number,
        i_tb_tb_alert_diag       IN table_table_number,
        i_tb_tb_desc_diag        IN table_table_varchar,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /* CURSOR c_soc_e_interv IS
        SELECT 'X'
          FROM social_epis_interv
         WHERE id_social_epis_interv = i_id_epis_interv_plan;*/
        l_epis_interv_plan      epis_interv_plan.id_epis_interv_plan%TYPE;
        l_epis_interv_plan_hist epis_interv_plan_hist.id_epis_interv_plan%TYPE;
        l_rowids                table_varchar;
        l_tb_diag               table_number;
        l_tb_alert_diag         table_number;
        l_tb_desc_diag          table_varchar;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        -- Verificar se a intervenção já existe
        g_error := 'SET_INTERV_PLAN: i_id_epis = ' || i_id_epis;
        --           || ', i_id_interv_plan = ' || i_id_interv_plan || k_soc_soc
        --           ', i_desc_other_interv_plan = ' || i_desc_other_interv_plan || ', i_dt_begin = ' || i_dt_begin ||
        --           ', i_dt_end = ' || i_dt_end || ', i_notes= ' || i_notes;
        pk_alertlog.log_debug(g_error);
    
        --iterate for all intervention plans
        FOR i IN 1 .. i_id_interv_plan.count
        LOOP
            -- assign local collections safely to avoid subscript beyond count
            l_tb_diag       := CASE
                                   WHEN i_tb_tb_diag.exists(i) THEN
                                    i_tb_tb_diag(i)
                                   ELSE
                                    table_number()
                               END;
            l_tb_alert_diag := CASE
                                   WHEN i_tb_tb_alert_diag.exists(i) THEN
                                    i_tb_tb_alert_diag(i)
                                   ELSE
                                    table_number()
                               END;
            l_tb_desc_diag := CASE
                                  WHEN i_tb_tb_desc_diag.exists(i) THEN
                                   i_tb_tb_desc_diag(i)
                                  ELSE
                                   table_varchar()
                              END;
        
            IF i_id_epis_interv_plan(i) IS NULL
            THEN
                g_error := 'SET_NEW_INTERV_PLAN - i_id_epis_interv_plan' || i_id_interv_plan(i);
                --create new intervention plans
                ts_epis_interv_plan.ins(id_interv_plan_in         => nvl(i_id_interv_plan(i), 0),
                                        id_episode_in             => i_id_epis,
                                        id_professional_in        => i_prof.id,
                                        flg_status_in             => i_interv_plan_state(i),
                                        notes_in                  => i_notes(i),
                                        dt_creation_in            => g_sysdate_tstz,
                                        dt_begin_in               => pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   i_dt_begin(i),
                                                                                                   NULL),
                                        dt_end_in                 => pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   i_dt_end(i),
                                                                                                   NULL),
                                        desc_other_interv_plan_in => i_desc_other_interv_plan(i),
                                        id_epis_interv_plan_out   => l_epis_interv_plan,
                                        rows_out                  => l_rowids);
            
                g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON EPIS_INTERV_PLAN';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INTERV_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                --and create the history records for new intervention plans
                ts_epis_interv_plan_hist.ins(id_epis_interv_plan_in       => l_epis_interv_plan,
                                             id_interv_plan_in            => nvl(i_id_interv_plan(i), 0),
                                             id_episode_in                => i_id_epis,
                                             id_professional_in           => i_prof.id,
                                             flg_status_in                => i_interv_plan_state(i),
                                             notes_in                     => i_notes(i),
                                             dt_creation_in               => g_sysdate_tstz,
                                             dt_begin_in                  => pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           i_dt_begin(i),
                                                                                                           NULL),
                                             dt_end_in                    => pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           i_dt_end(i),
                                                                                                           NULL),
                                             desc_other_interv_plan_in    => i_desc_other_interv_plan(i),
                                             id_epis_interv_plan_hist_out => l_epis_interv_plan_hist,
                                             rows_out                     => l_rowids);
            
                g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON EPIS_INTERV_PLAN_HIST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INTERV_PLAN_HIST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'call set_epis_interv_plan_diag_nc';
                IF NOT set_epis_interv_plan_diag_nc(i_lang                     => i_lang,
                                                    i_prof                     => i_prof,
                                                    i_id_episode               => i_id_epis,
                                                    i_id_epis_interv_plan_hist => l_epis_interv_plan_hist,
                                                    i_tb_diag                  => l_tb_diag,
                                                    i_tb_alert_diag            => l_tb_alert_diag,
                                                    i_tb_desc_diag             => l_tb_desc_diag,
                                                    i_tb_epis_diag             => table_number(),
                                                    o_error                    => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSE
                g_error := 'UPDATE_INTERV_PLAN - i_id_epis_interv_plan' || i_id_epis_interv_plan(i);
                --update intervention plans
                ts_epis_interv_plan.upd(id_epis_interv_plan_in     => i_id_epis_interv_plan(i),
                                        flg_status_in              => CASE
                                                                          WHEN i_interv_plan_state(i) =
                                                                               pk_alert_constant.g_flg_status_a THEN
                                                                           pk_alert_constant.g_flg_status_e
                                                                          ELSE
                                                                           i_interv_plan_state(i)
                                                                      END,
                                        notes_in                   => i_notes(i),
                                        notes_nin                  => FALSE,
                                        dt_begin_in                => pk_date_utils.get_string_tstz(i_lang,
                                                                                                    i_prof,
                                                                                                    i_dt_begin(i),
                                                                                                    NULL),
                                        dt_begin_nin               => FALSE,
                                        dt_end_in                  => pk_date_utils.get_string_tstz(i_lang,
                                                                                                    i_prof,
                                                                                                    i_dt_end(i),
                                                                                                    NULL),
                                        dt_end_nin                 => FALSE,
                                        desc_other_interv_plan_in  => i_desc_other_interv_plan(i),
                                        desc_other_interv_plan_nin => FALSE,
                                        rows_out                   => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INTERV_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                --and create the history records for new intervention plans
                ts_epis_interv_plan_hist.ins(id_epis_interv_plan_in       => i_id_epis_interv_plan(i),
                                             id_interv_plan_in            => nvl(i_id_interv_plan(i), 0),
                                             id_episode_in                => i_id_epis,
                                             id_professional_in           => i_prof.id,
                                             flg_status_in                => CASE
                                                                                 WHEN i_interv_plan_state(i) =
                                                                                      pk_alert_constant.g_flg_status_a THEN
                                                                                  pk_alert_constant.g_flg_status_e
                                                                                 ELSE
                                                                                  i_interv_plan_state(i)
                                                                             END,
                                             notes_in                     => i_notes(i),
                                             dt_creation_in               => g_sysdate_tstz,
                                             dt_begin_in                  => pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           i_dt_begin(i),
                                                                                                           NULL),
                                             dt_end_in                    => pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           i_dt_end(i),
                                                                                                           NULL),
                                             desc_other_interv_plan_in    => i_desc_other_interv_plan(i),
                                             id_epis_interv_plan_hist_out => l_epis_interv_plan_hist,
                                             rows_out                     => l_rowids);
            
                g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON EPIS_INTERV_PLAN_HIST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INTERV_PLAN_HIST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'call set_epis_interv_plan_diag_nc';
                IF NOT set_epis_interv_plan_diag_nc(i_lang                     => i_lang,
                                                    i_prof                     => i_prof,
                                                    i_id_episode               => i_id_epis,
                                                    i_id_epis_interv_plan_hist => l_epis_interv_plan_hist,
                                                    i_tb_diag                  => l_tb_diag,
                                                    i_tb_alert_diag            => l_tb_alert_diag,
                                                    i_tb_desc_diag             => l_tb_desc_diag,
                                                    i_tb_epis_diag             => table_number(),
                                                    o_error                    => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        
        END LOOP;
        --
    
        -- Verificar se a primeira observação do parecer realizada pela assistente social
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        --
        COMMIT;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_INTERV_PLAN',
                                                     o_error);
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_INTERV_PLAN',
                                                     o_error);
    END set_interv_plan;
    --
    /********************************************************************************************
    * Set one or more intervention plans for a given episode. This function can be used either to
    * create new intervention plans or to edit existing ones. When editing intervention plans
    * the parameter i_id_epis_interv_plan must be not null.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social worker)
    * @ param i_id_epis_interv_plan   List of IDs for the existing intervention plans to edit
    * @ param i_id_interv_plan        List of IDs for the intervention plans
    * @ param i_desc_other_interv_plan List of description of free text intervention plans
    * @ param i_dt_begin               List of begin dates for the intervention plans
    * @ param i_dt_end                 List of end dates for the intervention plans
    * @ param i_interv_plan_state      List of current states for the intervention plans
    * @ param i_notes                  List of notes for the intervention plans
    * @ param i_id_task_goal_det       List of task/goal detail identifier         
    * @ param i_id_task_goal           List of coded task/goal identifier   
    * @ param i_desc_task_goal         List of description of tasks/goals
    * @ param i_tb_tb_diag             table with id_diagnosis to associate
    * @ param i_tb_tb_desc_diag        table with diagnosis desctiptions to associate   
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION set_interv_plan
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        i_id_epis_interv_plan IN table_number,
        i_id_interv_plan      IN table_number,
        --
        i_desc_other_interv_plan IN table_varchar,
        i_dt_begin               IN table_varchar,
        i_dt_end                 IN table_varchar,
        i_interv_plan_state      IN table_varchar,
        i_notes                  IN table_varchar,
        i_id_task_goal_det       IN table_number,
        i_id_task_goal           IN table_number,
        i_desc_task_goal         IN table_varchar,
        i_tb_tb_diag             IN table_table_number,
        i_tb_tb_desc_diag        IN table_table_varchar,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_interv_plan      epis_interv_plan.id_epis_interv_plan%TYPE;
        l_epis_interv_plan_hist epis_interv_plan_hist.id_epis_interv_plan%TYPE;
        l_id_task_goal_det      epis_interv_plan.id_task_goal_det%TYPE;
    
        l_rowids       table_varchar;
        l_tb_diag      table_number;
        l_tb_desc_diag table_varchar;
        g_ret_val      BOOLEAN;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        -- Verificar se a intervenção já existe
        g_error := 'SET_INTERV_PLAN: i_id_epis = ' || i_id_epis;
    
        pk_alertlog.log_debug(g_error);
    
        --iterate for all intervention plans
        FOR i IN 1 .. i_id_interv_plan.count
        LOOP
            -- assign local collections safely to avoid subscript beyond count
            l_tb_diag      := CASE
                                  WHEN i_tb_tb_diag.exists(i) THEN
                                   i_tb_tb_diag(i)
                                  ELSE
                                   table_number()
                              END;
            l_tb_desc_diag := CASE
                                  WHEN i_tb_tb_desc_diag.exists(i) THEN
                                   i_tb_tb_desc_diag(i)
                                  ELSE
                                   table_varchar()
                              END;
        
            g_ret_val := set_task_goal_det(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_id_task_goal_det => i_id_task_goal_det(i),
                                           i_id_task_goal     => CASE
                                                                     WHEN i_id_task_goal IS NOT NULL THEN
                                                                      i_id_task_goal(i)
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           i_desc_task_goal   => CASE
                                                                     WHEN i_desc_task_goal IS NOT NULL THEN
                                                                      i_desc_task_goal(i)
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           o_id_task_goal_det => l_id_task_goal_det,
                                           o_error            => o_error);
        
            IF NOT g_ret_val
            THEN
            
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
            
            END IF;
        
            IF i_id_epis_interv_plan(i) IS NULL
            THEN
                g_error := 'SET_NEW_INTERV_PLAN - i_id_epis_interv_plan' || i_id_interv_plan(i);
                --create new intervention plans
                ts_epis_interv_plan.ins(id_interv_plan_in         => nvl(i_id_interv_plan(i), 0),
                                        id_episode_in             => i_id_epis,
                                        id_professional_in        => i_prof.id,
                                        flg_status_in             => i_interv_plan_state(i),
                                        notes_in                  => i_notes(i),
                                        dt_creation_in            => g_sysdate_tstz,
                                        dt_begin_in               => pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   i_dt_begin(i),
                                                                                                   NULL),
                                        dt_end_in                 => pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   i_dt_end(i),
                                                                                                   NULL),
                                        desc_other_interv_plan_in => i_desc_other_interv_plan(i),
                                        id_task_goal_det_in       => l_id_task_goal_det,
                                        id_epis_interv_plan_out   => l_epis_interv_plan,
                                        rows_out                  => l_rowids);
            
                g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON EPIS_INTERV_PLAN';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INTERV_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                --and create the history records for new intervention plans
                ts_epis_interv_plan_hist.ins(id_epis_interv_plan_in       => l_epis_interv_plan,
                                             id_interv_plan_in            => nvl(i_id_interv_plan(i), 0),
                                             id_episode_in                => i_id_epis,
                                             id_professional_in           => i_prof.id,
                                             flg_status_in                => i_interv_plan_state(i),
                                             notes_in                     => i_notes(i),
                                             dt_creation_in               => g_sysdate_tstz,
                                             dt_begin_in                  => pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           i_dt_begin(i),
                                                                                                           NULL),
                                             dt_end_in                    => pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           i_dt_end(i),
                                                                                                           NULL),
                                             desc_other_interv_plan_in    => i_desc_other_interv_plan(i),
                                             id_task_goal_det_in          => l_id_task_goal_det,
                                             id_epis_interv_plan_hist_out => l_epis_interv_plan_hist,
                                             rows_out                     => l_rowids);
            
                g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON EPIS_INTERV_PLAN_HIST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INTERV_PLAN_HIST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'call set_epis_interv_plan_diag_nc';
                IF NOT set_epis_interv_plan_diag_nc(i_lang                     => i_lang,
                                                    i_prof                     => i_prof,
                                                    i_id_episode               => i_id_epis,
                                                    i_id_epis_interv_plan_hist => l_epis_interv_plan_hist,
                                                    i_tb_diag                  => l_tb_diag,
                                                    i_tb_alert_diag            => table_number(),
                                                    i_tb_desc_diag             => l_tb_desc_diag,
                                                    i_tb_epis_diag             => table_number(),
                                                    o_error                    => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSE
                g_error := 'UPDATE_INTERV_PLAN - i_id_epis_interv_plan' || i_id_epis_interv_plan(i);
                --update intervention plans
                ts_epis_interv_plan.upd(id_epis_interv_plan_in     => i_id_epis_interv_plan(i),
                                        flg_status_in              => CASE
                                                                          WHEN i_interv_plan_state(i) =
                                                                               pk_alert_constant.g_flg_status_a THEN
                                                                           pk_alert_constant.g_flg_status_e
                                                                          ELSE
                                                                           i_interv_plan_state(i)
                                                                      END,
                                        notes_in                   => CASE
                                                                          WHEN i_notes IS NOT NULL THEN
                                                                           i_notes(i)
                                                                          ELSE
                                                                           NULL
                                                                      END,
                                        dt_begin_in                => pk_date_utils.get_string_tstz(i_lang,
                                                                                                    i_prof,
                                                                                                    i_dt_begin(i),
                                                                                                    NULL),
                                        dt_end_in                  => pk_date_utils.get_string_tstz(i_lang,
                                                                                                    i_prof,
                                                                                                    i_dt_end(i),
                                                                                                    NULL),
                                        desc_other_interv_plan_in  => CASE
                                                                          WHEN i_desc_other_interv_plan IS NOT NULL THEN
                                                                           i_desc_other_interv_plan(i)
                                                                          ELSE
                                                                           NULL
                                                                      END,
                                        id_task_goal_det_in        => l_id_task_goal_det,
                                        notes_nin                  => FALSE,
                                        dt_begin_nin               => FALSE,
                                        dt_end_nin                 => FALSE,
                                        desc_other_interv_plan_nin => FALSE,
                                        rows_out                   => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INTERV_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                --and create the history records for new intervention plans
                ts_epis_interv_plan_hist.ins(id_epis_interv_plan_in       => i_id_epis_interv_plan(i),
                                             id_interv_plan_in            => nvl(i_id_interv_plan(i), 0),
                                             id_episode_in                => i_id_epis,
                                             id_professional_in           => i_prof.id,
                                             flg_status_in                => CASE
                                                                                 WHEN i_interv_plan_state(i) =
                                                                                      pk_alert_constant.g_flg_status_a THEN
                                                                                  pk_alert_constant.g_flg_status_e
                                                                                 ELSE
                                                                                  i_interv_plan_state(i)
                                                                             END,
                                             notes_in                     => CASE
                                                                                 WHEN i_notes IS NOT NULL THEN
                                                                                  i_notes(i)
                                                                                 ELSE
                                                                                  NULL
                                                                             END,
                                             dt_creation_in               => g_sysdate_tstz,
                                             dt_begin_in                  => pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           i_dt_begin(i),
                                                                                                           NULL),
                                             dt_end_in                    => pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           i_dt_end(i),
                                                                                                           NULL),
                                             desc_other_interv_plan_in    => CASE
                                                                                 WHEN i_desc_other_interv_plan IS NOT NULL THEN
                                                                                  i_desc_other_interv_plan(i)
                                                                                 ELSE
                                                                                  NULL
                                                                             END,
                                             id_task_goal_det_in          => l_id_task_goal_det,
                                             id_epis_interv_plan_hist_out => l_epis_interv_plan_hist,
                                             rows_out                     => l_rowids);
            
                g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON EPIS_INTERV_PLAN_HIST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INTERV_PLAN_HIST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'call set_epis_interv_plan_diag_nc';
                IF NOT set_epis_interv_plan_diag_nc(i_lang                     => i_lang,
                                                    i_prof                     => i_prof,
                                                    i_id_episode               => i_id_epis,
                                                    i_id_epis_interv_plan_hist => l_epis_interv_plan_hist,
                                                    i_tb_diag                  => l_tb_diag,
                                                    i_tb_alert_diag            => table_number(),
                                                    i_tb_desc_diag             => l_tb_desc_diag,
                                                    i_tb_epis_diag             => table_number(),
                                                    o_error                    => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        
        END LOOP;
        --
    
        -- Verificar se a primeira observação do parecer realizada pela assistente social
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        --
        COMMIT;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_INTERV_PLAN',
                                                     o_error);
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_INTERV_PLAN',
                                                     o_error);
    END set_interv_plan;

    /********************************************************************************************
    * Get domains values for the intervention plan states.
    * If the parameter i_current_state is null then all available states will be returned,
    * otherwise the function returns only the states that are different form the current one.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_current_state          Current state
    *
    * @ param o_interv_plan_state     List with available states
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_state_domains
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_state     IN epis_interv_plan.flg_status%TYPE,
        o_interv_plan_state OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_current_state sys_domain.val%TYPE;
    
    BEGIN
    
        IF i_current_state IS NULL
        THEN
            --return all available states;
            l_current_state := '-';
        ELSE
            l_current_state := i_current_state;
        END IF;
    
        OPEN o_interv_plan_state FOR
            SELECT sd.val, sd.desc_val, sd.rank
              FROM sys_domain sd
             WHERE sd.code_domain = 'EPIS_INTERV_PLAN.FLG_STATUS'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND sd.flg_available = pk_alert_constant.g_yes
               AND sd.val != g_plan_edited
               AND sd.val <> decode(l_current_state, g_plan_edited, g_plan_active, l_current_state)
            --alphabetic order
             ORDER BY sd.desc_val;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan_state);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_STATE_DOMAINS',
                                                     o_error);
        
    END get_interv_plan_state_domains;
    --

    /********************************************************************************************
    * Set(change) a new intervention plan state
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social worker)
    * @ param i_id_epis_interv_plan   Intervention plan ID
    * @ param i_new_interv_plan_state New state for the existing plan
    *
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION set_new_interv_plan_state
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_id_epis_interv_plan   IN table_number,
        i_new_interv_plan_state IN epis_interv_plan.flg_status%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tb_epis_diag          table_number;
        l_epis_interv_plan_hist epis_interv_plan_hist.id_epis_interv_plan%TYPE;
        l_epis_interv_plan_row  epis_interv_plan%ROWTYPE;
        l_rowids                table_varchar;
    BEGIN
        FOR i IN 1 .. i_id_epis_interv_plan.count
        LOOP
            g_error := 'set_new_interv_plan_state: i_id_epis = ' || i_id_epis || ', i_prof.id = ' || i_prof.id ||
                       ', i_id_epis_interv_plan = ' || i_id_epis_interv_plan(i) || ', i_new_interv_plan_state = ' ||
                       i_new_interv_plan_state;
            pk_alertlog.log_debug(g_error);
            --
            g_sysdate_tstz := current_timestamp;
            --
            --update intervention plans state
            g_error := 'UPDATE CURRENT epis_interv_plan';
            ts_epis_interv_plan.upd(id_epis_interv_plan_in => i_id_epis_interv_plan(i),
                                    flg_status_in          => i_new_interv_plan_state,
                                    rows_out               => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_INTERV_PLAN',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            --
            g_error := 'GET CURRENT epis_interv_plan';
            SELECT *
              INTO l_epis_interv_plan_row
              FROM epis_interv_plan eip
             WHERE eip.id_epis_interv_plan = i_id_epis_interv_plan(i);
        
            g_error        := 'call get_epis_interv_plan_diag';
            l_tb_epis_diag := get_epis_interv_plan_diag(i_lang, i_prof, i_id_epis_interv_plan(i), NULL);
        
            g_error := 'CREATE epis_interv_plan HISTORY';
            --and create the history records for new intervention plans
            ts_epis_interv_plan_hist.ins(id_epis_interv_plan_in       => i_id_epis_interv_plan(i),
                                         id_interv_plan_in            => l_epis_interv_plan_row.id_interv_plan,
                                         id_episode_in                => l_epis_interv_plan_row.id_episode,
                                         id_professional_in           => i_prof.id,
                                         flg_status_in                => i_new_interv_plan_state,
                                         notes_in                     => l_epis_interv_plan_row.notes,
                                         dt_creation_in               => g_sysdate_tstz,
                                         dt_begin_in                  => l_epis_interv_plan_row.dt_begin,
                                         dt_end_in                    => l_epis_interv_plan_row.dt_end,
                                         desc_other_interv_plan_in    => l_epis_interv_plan_row.desc_other_interv_plan,
                                         id_epis_interv_plan_hist_out => l_epis_interv_plan_hist,
                                         rows_out                     => l_rowids);
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON EPIS_INTERV_PLAN_HIST';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_INTERV_PLAN_HIST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'call set_epis_interv_plan_diag_nc';
            IF NOT set_epis_interv_plan_diag_nc(i_lang                     => i_lang,
                                                i_prof                     => i_prof,
                                                i_id_episode               => i_id_epis,
                                                i_id_epis_interv_plan_hist => l_epis_interv_plan_hist,
                                                i_tb_diag                  => table_number(),
                                                i_tb_alert_diag            => table_number(),
                                                i_tb_desc_diag             => table_varchar(),
                                                i_tb_epis_diag             => l_tb_epis_diag,
                                                o_error                    => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Verificar se a primeira observação do parecer realizada pela assistente social
            g_error := 'CALL pk_visit.set_first_obs';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_id_epis,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        END LOOP;
        --
        COMMIT;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_NEW_INTERV_PLAN_STATE',
                                                     o_error);
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_NEW_INTERV_PLAN_STATE',
                                                     o_error);
    END set_new_interv_plan_state;
    --

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a
    * given list of interventions plans that are already set for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_id_epis_interv_plan   List of intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN table_number,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
        l_tab_id           table_number := table_number();
        l_tab_name         table_varchar := table_varchar();
        l_edit_mode        table_varchar := table_varchar();
        l_tab_dt_begin     table_timestamp_tz := table_timestamp_tz();
        l_tab_dt_end       table_timestamp_tz := table_timestamp_tz();
        l_tab_state        table_varchar := table_varchar();
        l_tab_notes        table_varchar := table_varchar();
        l_tab_tsk_goal_det table_number := table_number();
        l_tab_tsk_goal     table_number := table_number();
    
        l_dt_begin_value VARCHAR2(100 CHAR);
        l_dt_end_value   VARCHAR2(100 CHAR);
        l_state_value    VARCHAR2(100 CHAR);
        l_notes_value    VARCHAR2(1000 CHAR);
    
        l_task_goal_value     task_goal.desc_task_goal%TYPE;
        l_task_goal_det_value task_goal_det.id_task_goal_det%TYPE;
        l_tab_tab_epis_diag   table_table_number;
        l_tab_tab_desc_diag   table_table_varchar;
        l_tab_desc_diag       table_varchar;
        l_tab_epis_diag       table_number;
        l_label_epis_diag     sys_message.desc_message%TYPE;
        l_notes_flg           VARCHAR2(1 CHAR);
        l_diag_flg            VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('PARAMEDICAL_T004',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'SOCIAL_T082',
                                                                                          'SOCIAL_T135',
                                                                                          'SOCIAL_T124',
                                                                                          'PARAMEDICAL_T002',
                                                                                          'PARAMEDICAL_T022'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'OPEN LABELS CURSOR';
        OPEN o_screen_labels FOR
            SELECT t_table_message_array('PARAMEDICAL_T004') edit_interv_plan_main_header,
                   t_table_message_array('SOCIAL_T124') interv_plan_column,
                   t_table_message_array('PARAMEDICAL_T002') task_goal_column,
                   t_table_message_array('SOCIAL_T104') dt_begin_column,
                   t_table_message_array('SOCIAL_T125') dt_end_column,
                   t_table_message_array('SOCIAL_T004') state_column,
                   t_table_message_array('SOCIAL_T082') notes_column,
                   t_table_message_array('PARAMEDICAL_T022') social_diagnosis_column
              FROM dual;
    
        --
        g_error := 'GET_ALL_VALUES';
        pk_alertlog.log_debug(g_error);
        SELECT id_interv_plan,
               interv_plan_desc,
               edit_mode,
               dt_begin,
               dt_end,
               flg_status,
               notes,
               id_task_goal_det,
               id_task_goal,
               tab_tab_epis_diag,
               tab_tab_desc_diag,
               pk_utils.concat_table(tab_tab_desc_diag, '; ', 1, -1) tab_desc_diag
          BULK COLLECT
          INTO l_tab_id,
               l_tab_name,
               l_edit_mode,
               l_tab_dt_begin,
               l_tab_dt_end,
               l_tab_state,
               l_tab_notes,
               l_tab_tsk_goal_det,
               l_tab_tsk_goal,
               l_tab_tab_epis_diag,
               l_tab_tab_desc_diag,
               l_tab_desc_diag
          FROM (SELECT id_interv_plan,
                       interv_plan_desc,
                       edit_mode,
                       dt_begin,
                       dt_end,
                       flg_status,
                       notes,
                       id_task_goal_det,
                       id_task_goal,
                       tab_tab_epis_diag,
                       get_desc_epis_diag(i_lang, i_prof, tab_tab_epis_diag) tab_tab_desc_diag
                  FROM (SELECT eip.id_interv_plan,
                               CASE
                                    WHEN eip.id_interv_plan = 0 THEN
                                     eip.desc_other_interv_plan
                                    WHEN eip.id_interv_plan IS NULL THEN
                                     eip.desc_other_interv_plan
                                    ELSE
                                     pk_translation.get_translation(i_lang, ip.code_interv_plan)
                                END interv_plan_desc,
                               
                               CASE
                                    WHEN eip.id_interv_plan = 0 THEN
                                     pk_alert_constant.g_yes
                                    WHEN eip.id_interv_plan IS NULL THEN
                                     pk_alert_constant.g_yes
                                    ELSE
                                     pk_alert_constant.g_no
                                END edit_mode,
                               pk_date_utils.trunc_insttimezone(i_prof, eip.dt_begin) dt_begin,
                               pk_date_utils.trunc_insttimezone(i_prof, eip.dt_end) dt_end,
                               eip.flg_status,
                               eip.notes,
                               eip.id_task_goal_det,
                               tg.id_task_goal,
                               get_epis_interv_plan_diag(i_lang, i_prof, eip.id_epis_interv_plan, NULL) tab_tab_epis_diag
                          FROM epis_interv_plan eip
                          LEFT JOIN interv_plan ip
                            ON eip.id_interv_plan = ip.id_interv_plan
                          LEFT JOIN task_goal_det tgd
                            ON tgd.id_task_goal_det = eip.id_task_goal_det
                          LEFT JOIN task_goal tg
                            ON tg.id_task_goal = tgd.id_task_goal
                         WHERE eip.id_epis_interv_plan IN
                               (SELECT column_value
                                  FROM TABLE(i_id_epis_interv_plan))));
        --    
        IF i_id_epis_interv_plan.count = 1
        THEN
            g_error := 'EDITING ONLY ONE INTERV_PLAN';
            pk_alertlog.log_debug(g_error);
        
            OPEN o_interv_plan FOR
                SELECT i_id_epis_interv_plan(1) id,
                       l_tab_id(1) id_interv_plan,
                       l_tab_name(1) interv_plan_desc,
                       l_edit_mode(1) can_edit_interv_plan,
                       --
                       pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_begin(1), i_prof) dt_begin,
                       pk_date_utils.date_send_tsz(i_lang, l_tab_dt_begin(1), i_prof) dt_begin_str,
                       --
                       pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_end(1), i_prof) dt_end,
                       pk_date_utils.date_send_tsz(i_lang, l_tab_dt_end(1), i_prof) dt_end_str,
                       --
                       CASE
                            WHEN l_tab_state(1) = g_eip_status_e THEN
                             pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', g_eip_status_a, i_lang)
                            ELSE
                             pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', l_tab_state(1), i_lang)
                        END desc_status,
                       CASE
                            WHEN l_tab_state(1) = pk_alert_constant.g_flg_status_e THEN
                             pk_alert_constant.g_flg_status_a
                            ELSE
                             l_tab_state(1)
                        END flg_status,
                       get_id_diagnosis(i_lang, i_prof, l_tab_tab_epis_diag(1)) id_interv_diagnosis,
                       l_tab_tab_desc_diag(1) desc_interv_diagnosis,
                       l_tab_desc_diag(1) desc_diagnosis,
                       NULL diag_flg,
                       l_tab_notes(1) notes,
                       NULL notes_flg,
                       get_task_goal_desc(i_lang, i_prof, l_tab_tsk_goal_det(1)) desc_task_goal,
                       l_tab_tsk_goal(1) id_task_goal,
                       l_tab_tsk_goal_det(1) id_task_goal_det,
                       get_id_alert_diagnosis(i_lang, i_prof, l_tab_tab_epis_diag(1)) id_alert_diagnosis
                  FROM dual;
        ELSE
            --DT_BEGIN
            --1 is the initial value
            g_error := 'EDITING MORE THAN ONE INTERV_PLAN : ' || i_id_epis_interv_plan.count;
            pk_alertlog.log_debug(g_error);
        
            l_dt_begin_value := l_tab_dt_begin(1);
            FOR i IN 2 .. l_tab_dt_begin.count
            LOOP
                IF ((l_dt_begin_value IS NULL AND l_tab_dt_begin(i) IS NOT NULL) OR
                   (l_dt_begin_value IS NOT NULL AND l_tab_dt_begin(i) IS NULL))
                THEN
                    l_dt_begin_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_dt_begin_value <> l_tab_dt_begin(i)
                    THEN
                        l_dt_begin_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            --DT_END
            --1 is the initial value
            l_dt_end_value := l_tab_dt_end(1);
            FOR i IN 2 .. l_tab_dt_end.count
            LOOP
                IF ((l_dt_end_value IS NULL AND l_tab_dt_end(i) IS NOT NULL) OR
                   (l_dt_end_value IS NOT NULL AND l_tab_dt_end(i) IS NULL))
                THEN
                    l_dt_end_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_dt_end_value <> l_tab_dt_end(i)
                    THEN
                        l_dt_end_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            --STATE
            --1 is the initial value
            l_state_value := l_tab_state(1);
            FOR i IN 2 .. l_tab_state.count
            LOOP
                IF ((l_state_value IS NULL AND l_tab_state(i) IS NOT NULL) OR
                   (l_state_value IS NOT NULL AND l_tab_state(i) IS NULL))
                THEN
                    l_state_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_state_value <> l_tab_state(i)
                    THEN
                        l_state_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            --epis_diag
            --1 is the initial value
            l_diag_flg      := NULL;
            l_tab_epis_diag := l_tab_tab_epis_diag(1);
            FOR i IN 2 .. l_tab_tab_epis_diag.count
            LOOP
                IF ((l_tab_epis_diag IS NULL AND l_tab_tab_epis_diag(i) IS NOT NULL) OR
                   (l_tab_epis_diag IS NOT NULL AND l_tab_tab_epis_diag(i) IS NULL))
                THEN
                    l_label_epis_diag := t_table_message_array('SOCIAL_T135');
                    l_diag_flg        := 'M';
                    EXIT;
                ELSE
                    IF l_tab_epis_diag <> l_tab_tab_epis_diag(i)
                    THEN
                        l_label_epis_diag := t_table_message_array('SOCIAL_T135');
                        l_diag_flg        := 'M';
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            --NOTES
            --1 is the initial value
            l_notes_flg   := NULL;
            l_notes_value := l_tab_notes(1);
            FOR i IN 2 .. l_tab_notes.count
            LOOP
                IF ((l_notes_value IS NULL AND l_tab_notes(i) IS NOT NULL) OR
                   (l_notes_value IS NOT NULL AND l_tab_notes(i) IS NULL))
                THEN
                    l_notes_value := t_table_message_array('SOCIAL_T135');
                    l_notes_flg   := 'M';
                    EXIT;
                ELSE
                    IF l_notes_value <> l_tab_notes(i)
                    THEN
                        l_notes_value := t_table_message_array('SOCIAL_T135');
                        l_notes_flg   := 'M';
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            --TASK GOAL
            --1 is the initial value
            l_task_goal_value := l_tab_tsk_goal(1);
            FOR i IN 2 .. l_tab_tsk_goal.count
            LOOP
                l_task_goal_det_value := l_tab_tsk_goal_det(i);
            
                IF ((l_task_goal_value IS NULL AND l_tab_tsk_goal(i) IS NOT NULL) OR
                   (l_task_goal_value IS NOT NULL AND l_tab_tsk_goal(i) IS NULL))
                THEN
                    l_task_goal_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_task_goal_value <> l_tab_tsk_goal(i)
                    THEN
                        l_task_goal_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            OPEN o_interv_plan FOR
                SELECT t_table_message_array('SOCIAL_T135') id,
                       NULL id_interv_plan,
                       t_table_message_array('SOCIAL_T135') interv_plan_desc,
                       pk_alert_constant.g_no can_edit_interv_plan,
                       decode(l_dt_begin_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              pk_date_utils.dt_chr_tsz(i_lang, l_dt_begin_value, i_prof)) dt_begin,
                       decode(l_dt_begin_value,
                              t_table_message_array('SOCIAL_T135'),
                              'M',
                              pk_date_utils.date_send_tsz(i_lang, l_dt_begin_value, i_prof)) dt_begin_str,
                       --
                       decode(l_dt_end_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              pk_date_utils.dt_chr_tsz(i_lang, l_dt_end_value, i_prof)) dt_end,
                       decode(l_dt_end_value,
                              t_table_message_array('SOCIAL_T135'),
                              'M',
                              pk_date_utils.date_send_tsz(i_lang, l_dt_end_value, i_prof)) dt_end_str,
                       -- 
                       CASE
                            WHEN l_state_value = t_table_message_array('SOCIAL_T135') THEN
                             t_table_message_array('SOCIAL_T135')
                            WHEN l_tab_state(1) = g_eip_status_e THEN
                             pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', g_eip_status_a, i_lang)
                            ELSE
                             pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', l_tab_state(1), i_lang)
                        END desc_status,
                       decode(l_state_value, t_table_message_array('SOCIAL_T135'), 'M', l_state_value) flg_status,
                       decode(l_label_epis_diag,
                              t_table_message_array('SOCIAL_T135'),
                              table_number(),
                              get_id_diagnosis(i_lang, i_prof, l_tab_tab_epis_diag(1))) id_interv_diagnosis,
                       decode(l_label_epis_diag,
                              t_table_message_array('SOCIAL_T135'),
                              table_varchar(),
                              l_tab_tab_desc_diag(1)) desc_interv_diagnosis,
                       decode(l_label_epis_diag,
                              t_table_message_array('SOCIAL_T135'),
                              l_label_epis_diag,
                              l_tab_desc_diag(1)) desc_diagnosis,
                       l_diag_flg diag_flg,
                       l_notes_value notes,
                       l_notes_flg notes_flg,
                       decode(l_task_goal_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              get_task_goal_desc(i_lang, i_prof, l_task_goal_det_value)) desc_task_goal,
                       decode(l_label_epis_diag,
                              t_table_message_array('SOCIAL_T135'),
                              table_number(),
                              get_id_alert_diagnosis(i_lang, i_prof, l_tab_tab_epis_diag(1))) id_alert_diagnosis
                  FROM dual;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT_POPUP',
                                                     o_error);
    END get_interv_plan_edit_popup;
    --

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a
    * given list of interventions plans that are not yet set for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_dt_begin              List of begin dates for the select intervention plans to edit
    * @ param i_dt_end                List of end dates for the select intervention plans to edit
    * @ param i_dt_begin              List of states for the select intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_epis  IN episode.id_episode%TYPE,
        i_dt_begin IN table_varchar,
        i_dt_end   IN table_varchar,
        i_state    IN table_varchar,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
        l_tab_dt_begin table_timestamp_tz := table_timestamp_tz();
        l_tab_dt_end   table_timestamp_tz := table_timestamp_tz();
        l_tab_state    table_varchar := table_varchar();
        --
        l_dt_begin_value    VARCHAR2(100 CHAR);
        l_dt_end_value      VARCHAR2(100 CHAR);
        l_tab_dt_begin_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_tab_dt_end_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_state_value       VARCHAR2(100 CHAR);
        l_edit_mode_value   VARCHAR2(1 CHAR);
        l_row_nums          PLS_INTEGER := 0;
    
    BEGIN
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('PARAMEDICAL_T004',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'SOCIAL_T082',
                                                                                          'SOCIAL_T135',
                                                                                          'SOCIAL_T124',
                                                                                          'PARAMEDICAL_T002'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'OPEN LABELS CURSOR';
        OPEN o_screen_labels FOR
            SELECT t_table_message_array('PARAMEDICAL_T004') edit_interv_plan_main_header,
                   t_table_message_array('SOCIAL_T124') interv_plan_column,
                   t_table_message_array('PARAMEDICAL_T002') task_goal_column,
                   t_table_message_array('SOCIAL_T104') dt_begin_column,
                   t_table_message_array('SOCIAL_T125') dt_end_column,
                   t_table_message_array('SOCIAL_T004') state_column,
                   t_table_message_array('SOCIAL_T082') notes_column
              FROM dual;
        --
        FOR i IN 1 .. i_dt_begin.count
        LOOP
            l_tab_dt_begin.extend;
            IF i_dt_begin(i) IS NULL
            THEN
                l_tab_dt_begin(i) := NULL;
            ELSE
                l_tab_dt_begin(i) := pk_date_utils.trunc_insttimezone(i_prof,
                                                                      pk_date_utils.get_string_tstz(i_lang,
                                                                                                    i_prof,
                                                                                                    i_dt_begin(i),
                                                                                                    NULL));
            END IF;
        END LOOP;
        --
        FOR i IN 1 .. i_dt_end.count
        LOOP
            l_tab_dt_end.extend;
            IF i_dt_end(i) IS NULL
            THEN
                l_tab_dt_end(i) := NULL;
            ELSE
                l_tab_dt_end(i) := pk_date_utils.trunc_insttimezone(i_prof,
                                                                    pk_date_utils.get_string_tstz(i_lang,
                                                                                                  i_prof,
                                                                                                  i_dt_end(i),
                                                                                                  NULL));
            END IF;
        
        END LOOP;
        --
        l_tab_state := i_state;
    
        l_row_nums := i_dt_begin.count;
        --
        IF l_row_nums = 1
        THEN
            g_error := 'EDITING ONLY ONE INTERV_PLAN';
            pk_alertlog.log_debug(g_error);
        
            l_edit_mode_value := pk_alert_constant.get_yes;
        
            OPEN o_interv_plan FOR
                SELECT NULL id,
                       --
                       l_edit_mode_value can_edit_interv_plan,
                       pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_begin(1), i_prof) dt_begin,
                       pk_date_utils.date_send_tsz(i_lang, l_tab_dt_begin(1), i_prof) dt_begin_str,
                       --
                       pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_end(1), i_prof) dt_end,
                       pk_date_utils.date_send_tsz(i_lang, l_tab_dt_end(1), i_prof) dt_end_str,
                       --
                       pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', l_tab_state(1), i_lang) desc_status,
                       l_tab_state(1) flg_status,
                       NULL notes
                  FROM dual;
        ELSE
            --DT_BEGIN
            --1 is the initial value
            g_error := 'EDITING MORE THAN ONE INTERV_PLAN ';
            pk_alertlog.log_debug(g_error);
        
            l_edit_mode_value := pk_alert_constant.get_no;
        
            l_tab_dt_begin_tstz := l_tab_dt_begin(1);
            FOR i IN 2 .. l_tab_dt_begin.count
            LOOP
                IF ((l_tab_dt_begin_tstz IS NULL AND l_tab_dt_begin(i) IS NOT NULL) OR
                   (l_tab_dt_begin_tstz IS NOT NULL AND l_tab_dt_begin(i) IS NULL))
                THEN
                    l_dt_begin_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_tab_dt_begin_tstz <> l_tab_dt_begin(i)
                    THEN
                        l_dt_begin_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            --DT_END
            --1 is the initial value
            l_tab_dt_end_tstz := l_tab_dt_end(1);
            FOR i IN 2 .. l_tab_dt_end.count
            LOOP
                IF ((l_dt_end_value IS NULL AND l_tab_dt_end(i) IS NOT NULL) OR
                   (l_dt_end_value IS NOT NULL AND l_tab_dt_end(i) IS NULL))
                THEN
                    l_dt_end_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_tab_dt_end_tstz <> l_tab_dt_end(i)
                    THEN
                        l_dt_end_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            --STATE
            --1 is the initial value
            l_state_value := l_tab_state(1);
            FOR i IN 2 .. l_tab_state.count
            LOOP
                IF ((l_state_value IS NULL AND l_tab_state(i) IS NOT NULL) OR
                   (l_state_value IS NOT NULL AND l_tab_state(i) IS NULL))
                THEN
                    l_state_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_state_value <> l_tab_state(i)
                    THEN
                        l_state_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            OPEN o_interv_plan FOR
                SELECT t_table_message_array('SOCIAL_T135') id,
                       l_edit_mode_value can_edit_interv_plan,
                       decode(l_dt_begin_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_begin_tstz, i_prof)) dt_begin,
                       decode(l_dt_begin_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              pk_date_utils.date_send_tsz(i_lang, l_tab_dt_begin_tstz, i_prof)) dt_begin_str,
                       --
                       decode(l_dt_end_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              pk_date_utils.dt_chr_tsz(i_lang, l_dt_end_value, i_prof)) dt_end,
                       decode(l_dt_end_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              pk_date_utils.date_send_tsz(i_lang, l_dt_end_value, i_prof)) dt_end_str,
                       --
                       decode(l_state_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', l_state_value, i_lang)) desc_status,
                       l_state_value flg_status,
                       NULL notes
                  FROM dual;
        
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT_POPUP',
                                                     o_error);
    END get_interv_plan_edit_popup;
    --

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a
    * given list of interventions plans that are not yet set for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_dt_begin              List of begin dates for the select intervention plans to edit
    * @ param i_dt_end                List of end dates for the select intervention plans to edit
    * @ param i_dt_begin              List of states for the select intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis        IN episode.id_episode%TYPE,
        i_id_interv_plan IN table_number,
        i_dt_begin       IN table_varchar,
        i_dt_end         IN table_varchar,
        i_state          IN table_varchar,
        i_notes          IN table_varchar,
        i_task_goal_det  IN table_number,
        i_task_goal      IN table_number,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
        l_tab_dt_begin      table_timestamp_tz := table_timestamp_tz();
        l_tab_dt_end        table_timestamp_tz := table_timestamp_tz();
        l_tab_state         table_varchar := table_varchar();
        l_tab_notes         table_varchar := table_varchar();
        l_tab_id_tsk_goal   table_number := table_number();
        l_tab_tsk_goal_desc table_varchar := table_varchar();
        --
        l_dt_begin_value      VARCHAR2(100 CHAR);
        l_dt_end_value        VARCHAR2(100 CHAR);
        l_tab_dt_begin_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_tab_dt_end_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
        l_state_value         VARCHAR2(100 CHAR);
        l_notes_value         VARCHAR2(100 CHAR);
        l_edit_mode_value     VARCHAR2(1 CHAR);
        l_row_nums            PLS_INTEGER := 0;
        l_tsk_goal_desc_value task_goal.desc_task_goal%TYPE;
        l_id_tsk_goal_value   VARCHAR2(100 CHAR);
    
        l_interv_plan_desc pk_translation.t_desc_translation;
    
    BEGIN
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('PARAMEDICAL_T004',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'SOCIAL_T082',
                                                                                          'SOCIAL_T135',
                                                                                          'SOCIAL_T124',
                                                                                          'PARAMEDICAL_T002'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'OPEN LABELS CURSOR';
        OPEN o_screen_labels FOR
            SELECT t_table_message_array('PARAMEDICAL_T004') edit_interv_plan_main_header,
                   t_table_message_array('SOCIAL_T124') interv_plan_column,
                   t_table_message_array('PARAMEDICAL_T002') task_goal_column,
                   t_table_message_array('SOCIAL_T104') dt_begin_column,
                   t_table_message_array('SOCIAL_T125') dt_end_column,
                   t_table_message_array('SOCIAL_T004') state_column,
                   t_table_message_array('SOCIAL_T082') notes_column
              FROM dual;
    
        --
        FOR i IN 1 .. i_dt_begin.count
        LOOP
            l_tab_dt_begin.extend;
            IF i_dt_begin(i) IS NULL
            THEN
                l_tab_dt_begin(i) := NULL;
            ELSE
                l_tab_dt_begin(i) := pk_date_utils.trunc_insttimezone(i_prof,
                                                                      pk_date_utils.get_string_tstz(i_lang,
                                                                                                    i_prof,
                                                                                                    i_dt_begin(i),
                                                                                                    NULL));
            
            END IF;
        
        END LOOP;
    
        --
        FOR i IN 1 .. i_dt_end.count
        LOOP
            l_tab_dt_end.extend;
            IF i_dt_end(i) IS NULL
            THEN
                l_tab_dt_end(i) := NULL;
            ELSE
                l_tab_dt_end(i) := pk_date_utils.trunc_insttimezone(i_prof,
                                                                    pk_date_utils.get_string_tstz(i_lang,
                                                                                                  i_prof,
                                                                                                  i_dt_end(i),
                                                                                                  NULL));
            
            END IF;
        
        END LOOP;
    
        FOR i IN 1 .. i_task_goal_det.count
        LOOP
            l_tab_tsk_goal_desc.extend;
            l_tab_id_tsk_goal.extend;
            IF i_task_goal_det(i) IS NULL
            THEN
                IF i_task_goal(i) IS NULL
                THEN
                    l_tab_tsk_goal_desc(i) := NULL;
                    l_tab_id_tsk_goal(i) := NULL;
                ELSE
                    --Edition of a record that is not yet saved
                    l_tab_id_tsk_goal(i) := i_task_goal(i);
                    BEGIN
                        SELECT pk_translation.get_translation(i_lang, tg.code_task_goal)
                          INTO l_tab_tsk_goal_desc(i)
                          FROM task_goal tg
                         WHERE tg.id_task_goal = i_task_goal(i);
                    EXCEPTION
                        WHEN OTHERS THEN
                            --This shouldn't happen
                            l_tab_id_tsk_goal(i) := '';
                    END;
                END IF;
            ELSE
                IF i_task_goal(i) IS NULL
                THEN
                    l_tab_tsk_goal_desc(i) := pk_paramedical_prof_core.get_task_goal_desc(i_lang,
                                                                                          i_prof,
                                                                                          i_task_goal_det(i));
                    l_tab_id_tsk_goal(i) := to_char(pk_paramedical_prof_core.get_id_task_goal(i_lang,
                                                                                              i_prof,
                                                                                              i_task_goal_det(i)));
                ELSE
                    l_tab_id_tsk_goal(i) := i_task_goal(i);
                    BEGIN
                        SELECT pk_translation.get_translation(i_lang, tg.code_task_goal)
                          INTO l_tab_tsk_goal_desc(i)
                          FROM task_goal tg
                         WHERE tg.id_task_goal = i_task_goal(i);
                    EXCEPTION
                        WHEN OTHERS THEN
                            --This shouldn't happen
                            l_tab_id_tsk_goal(i) := '';
                    END;
                END IF;
            END IF;
        END LOOP;
    
        --
        l_tab_state := i_state;
        --
        l_tab_notes := i_notes;
    
        l_row_nums := i_dt_begin.count;
        --
        IF l_row_nums = 1
        THEN
            g_error := 'EDITING ONLY ONE INTERV_PLAN';
            pk_alertlog.log_debug(g_error);
        
            --
            --TODO: create the type others for the interv plans
            --TODO: change 16
            SELECT decode(ip.id_interv_plan, -1, pk_alert_constant.g_yes, pk_alert_constant.g_no) TYPE,
                   pk_translation.get_translation(i_lang, ip.code_interv_plan)
              INTO l_edit_mode_value, l_interv_plan_desc
              FROM interv_plan ip
             WHERE ip.id_interv_plan = i_id_interv_plan(1);
        
            OPEN o_interv_plan FOR
                SELECT NULL id,
                       l_interv_plan_desc interv_plan_desc,
                       l_edit_mode_value can_edit_interv_plan,
                       pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_begin(1), i_prof) dt_begin,
                       pk_date_utils.date_send_tsz(i_lang, l_tab_dt_begin(1), i_prof) dt_begin_str,
                       --
                       pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_end(1), i_prof) dt_end,
                       pk_date_utils.date_send_tsz(i_lang, l_tab_dt_end(1), i_prof) dt_end_str,
                       --
                       CASE
                            WHEN l_tab_state(1) = g_eip_status_e THEN
                             pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', g_eip_status_a, i_lang)
                            ELSE
                             pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', l_tab_state(1), i_lang)
                        END desc_status,
                       --
                       CASE
                            WHEN l_tab_state(1) = pk_alert_constant.g_flg_status_e THEN
                             pk_alert_constant.g_flg_status_a
                            ELSE
                             l_tab_state(1)
                        END flg_status,
                       l_tab_notes(1) notes,
                       l_tab_id_tsk_goal(1) id_task_goal,
                       l_tab_tsk_goal_desc(1) desc_task_goal
                  FROM dual;
        ELSE
            --DT_BEGIN
            --1 is the initial value
            g_error := 'EDITING MORE THAN ONE INTERV_PLAN ';
            pk_alertlog.log_debug(g_error);
        
            l_edit_mode_value := pk_alert_constant.get_no;
        
            l_tab_dt_begin_tstz := l_tab_dt_begin(1);
            FOR i IN 2 .. l_tab_dt_begin.count
            LOOP
                IF ((l_tab_dt_begin_tstz IS NULL AND l_tab_dt_begin(i) IS NOT NULL) OR
                   (l_tab_dt_begin_tstz IS NOT NULL AND l_tab_dt_begin(i) IS NULL))
                THEN
                    l_dt_begin_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_tab_dt_begin_tstz <> l_tab_dt_begin(i)
                    THEN
                        l_dt_begin_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                
                END IF;
            
            END LOOP;
        
            --DT_END
            --1 is the initial value
            l_tab_dt_end_tstz := l_tab_dt_end(1);
            FOR i IN 2 .. l_tab_dt_end.count
            LOOP
                IF ((l_tab_dt_end_tstz IS NULL AND l_tab_dt_end(i) IS NOT NULL) OR
                   (l_tab_dt_end_tstz IS NOT NULL AND l_tab_dt_end(i) IS NULL))
                THEN
                    l_dt_end_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_tab_dt_end_tstz <> l_tab_dt_end(i)
                    THEN
                        l_dt_end_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                
                END IF;
            
            END LOOP;
        
            --STATE
            --1 is the initial value
            l_state_value := l_tab_state(1);
            FOR i IN 2 .. l_tab_state.count
            LOOP
                IF ((l_state_value IS NULL AND l_tab_state(i) IS NOT NULL) OR
                   (l_state_value IS NOT NULL AND l_tab_state(i) IS NULL))
                THEN
                    l_state_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_state_value <> l_tab_state(i)
                    THEN
                        l_state_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                
                END IF;
            
            END LOOP;
        
            --NOTES
            --1 is the initial value
            l_notes_value := l_tab_notes(1);
            FOR i IN 2 .. l_tab_notes.count
            LOOP
                IF ((l_notes_value IS NULL AND l_tab_notes(i) IS NOT NULL) OR
                   (l_notes_value IS NOT NULL AND l_tab_notes(i) IS NULL))
                THEN
                    l_notes_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_notes_value <> l_tab_notes(i)
                    THEN
                        l_notes_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                
                END IF;
            
            END LOOP;
        
            --TASK GOAL
            --1 is the initial value
            l_tsk_goal_desc_value := l_tab_tsk_goal_desc(1);
            FOR i IN 2 .. l_tab_tsk_goal_desc.count
            LOOP
                --l_task_goal_det_value := l_tab_tsk_goal_det(i) ;
            
                IF ((l_tsk_goal_desc_value IS NULL AND l_tab_tsk_goal_desc(i) IS NOT NULL) OR
                   (l_tsk_goal_desc_value IS NOT NULL AND l_tab_tsk_goal_desc(i) IS NULL))
                THEN
                    l_tsk_goal_desc_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_tsk_goal_desc_value <> l_tab_tsk_goal_desc(i)
                    THEN
                        l_tsk_goal_desc_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            --TASK GOAL ID
            ----l_id_tsk_goal_value
            --1 is the initial value
            l_id_tsk_goal_value := l_tab_id_tsk_goal(1);
            FOR i IN 2 .. l_tab_id_tsk_goal.count
            LOOP
                --l_task_goal_det_value := l_tab_tsk_goal_det(i) ;
            
                IF ((l_id_tsk_goal_value IS NULL AND l_tab_id_tsk_goal(i) IS NOT NULL) OR
                   (l_id_tsk_goal_value IS NOT NULL AND l_tab_id_tsk_goal(i) IS NULL))
                THEN
                    l_id_tsk_goal_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_id_tsk_goal_value <> l_tab_id_tsk_goal(i)
                    THEN
                        l_id_tsk_goal_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            OPEN o_interv_plan FOR
                SELECT t_table_message_array('SOCIAL_T135') id,
                       t_table_message_array('SOCIAL_T135') interv_plan_desc,
                       l_edit_mode_value can_edit_interv_plan,
                       decode(l_dt_begin_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_begin_tstz, i_prof)) dt_begin,
                       decode(l_dt_begin_value,
                              t_table_message_array('SOCIAL_T135'),
                              'M',
                              pk_date_utils.date_send_tsz(i_lang, l_tab_dt_begin_tstz, i_prof)) dt_begin_str,
                       --
                       decode(l_dt_end_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_end_tstz, i_prof)) dt_end,
                       decode(l_dt_end_value,
                              t_table_message_array('SOCIAL_T135'),
                              'M',
                              pk_date_utils.date_send_tsz(i_lang, l_tab_dt_end_tstz, i_prof)) dt_end_str,
                       --
                       decode(l_state_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              decode(l_state_value,
                                     t_table_message_array('SOCIAL_T135'),
                                     t_table_message_array('SOCIAL_T135'),
                                     pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS',
                                                             decode(l_state_value,
                                                                    pk_alert_constant.g_flg_status_e,
                                                                    pk_alert_constant.g_flg_status_a,
                                                                    l_state_value),
                                                             i_lang))) desc_status,
                       decode(l_state_value,
                              t_table_message_array('SOCIAL_T135'),
                              'M',
                              decode(l_state_value,
                                     pk_alert_constant.g_flg_status_e,
                                     pk_alert_constant.g_flg_status_a,
                                     l_state_value)) flg_status,
                       decode(l_notes_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              l_notes_value) notes,
                       decode(l_id_tsk_goal_value, t_table_message_array('SOCIAL_T135'), 'M', l_id_tsk_goal_value) id_task_goal,
                       decode(l_tsk_goal_desc_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              l_tsk_goal_desc_value) desc_task_goal
                
                  FROM dual;
        
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT_POPUP',
                                                     o_error);
        
    END get_interv_plan_edit_popup;
    --

    /********************************************************************************************
    * Get data for the popup screen that allows the professionals to edit a
    * given list of interventions plans that are not yet set for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_dt_begin              List of begin dates for the select intervention plans to edit
    * @ param i_dt_end                List of end dates for the select intervention plans to edit
    * @ param i_dt_begin              List of states for the select intervention plans to edit
    * @ param o_interv_plan           Intervention plan list
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit_popup
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis        IN episode.id_episode%TYPE,
        i_id_interv_plan IN table_number,
        i_dt_begin       IN table_varchar,
        i_dt_end         IN table_varchar,
        i_state          IN table_varchar,
        i_notes          IN table_varchar,
        i_epis_diag      IN table_table_number,
        --
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
        l_tab_dt_begin table_timestamp_tz := table_timestamp_tz();
        l_tab_dt_end   table_timestamp_tz := table_timestamp_tz();
        l_tab_state    table_varchar := table_varchar();
        l_tab_notes    table_varchar := table_varchar();
        --
        l_dt_begin_value    VARCHAR2(100 CHAR);
        l_dt_end_value      VARCHAR2(100 CHAR);
        l_tab_dt_begin_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_tab_dt_end_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_state_value       VARCHAR2(100 CHAR);
        l_notes_value       VARCHAR2(100 CHAR);
        l_edit_mode_value   VARCHAR2(1 CHAR);
        l_row_nums          PLS_INTEGER := 0;
    
        l_interv_plan_desc pk_translation.t_desc_translation;
        l_tab_tab_diag     table_table_number;
        l_tab_epis_diag    table_number;
        l_label_epis_diag  sys_message.desc_message%TYPE;
        l_notes_flg        VARCHAR2(1 CHAR);
        l_diag_flg         VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('PARAMEDICAL_T004',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'SOCIAL_T082',
                                                                                          'SOCIAL_T135',
                                                                                          'SOCIAL_T124',
                                                                                          'PARAMEDICAL_T002',
                                                                                          'PARAMEDICAL_T022'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error := 'OPEN LABELS CURSOR';
        OPEN o_screen_labels FOR
            SELECT t_table_message_array('PARAMEDICAL_T004') edit_interv_plan_main_header,
                   t_table_message_array('SOCIAL_T124') interv_plan_column,
                   t_table_message_array('PARAMEDICAL_T002') task_goal_column,
                   t_table_message_array('SOCIAL_T104') dt_begin_column,
                   t_table_message_array('SOCIAL_T125') dt_end_column,
                   t_table_message_array('SOCIAL_T004') state_column,
                   t_table_message_array('SOCIAL_T082') notes_column,
                   t_table_message_array('PARAMEDICAL_T022') social_diagnosis_column
              FROM dual;
    
        FOR i IN 1 .. i_dt_begin.count
        LOOP
            l_tab_dt_begin.extend;
            IF i_dt_begin(i) IS NULL
            THEN
                l_tab_dt_begin(i) := NULL;
            ELSE
                l_tab_dt_begin(i) := pk_date_utils.trunc_insttimezone(i_prof,
                                                                      pk_date_utils.get_string_tstz(i_lang,
                                                                                                    i_prof,
                                                                                                    i_dt_begin(i),
                                                                                                    NULL));
            
            END IF;
        END LOOP;
    
        FOR i IN 1 .. i_dt_end.count
        LOOP
            l_tab_dt_end.extend;
            IF i_dt_end(i) IS NULL
            THEN
                l_tab_dt_end(i) := NULL;
            ELSE
                l_tab_dt_end(i) := pk_date_utils.trunc_insttimezone(i_prof,
                                                                    pk_date_utils.get_string_tstz(i_lang,
                                                                                                  i_prof,
                                                                                                  i_dt_end(i),
                                                                                                  NULL));
            END IF;
        END LOOP;
    
        l_tab_state    := i_state;
        l_tab_tab_diag := i_epis_diag;
        l_tab_notes    := i_notes;
        l_row_nums     := i_dt_begin.count;
        --
        IF l_row_nums = 1
        THEN
            g_error := 'EDITING ONLY ONE INTERV_PLAN';
            pk_alertlog.log_debug(g_error);
        
            --
            --TODO: create the type others for the interv plans
            --TODO: change 16
            SELECT decode(ip.id_interv_plan, -1, pk_alert_constant.g_yes, pk_alert_constant.g_no) TYPE,
                   pk_translation.get_translation(i_lang, ip.code_interv_plan)
              INTO l_edit_mode_value, l_interv_plan_desc
              FROM interv_plan ip
             WHERE ip.id_interv_plan = i_id_interv_plan(1);
        
            OPEN o_interv_plan FOR
                SELECT NULL id,
                       --
                       l_interv_plan_desc interv_plan_desc,
                       l_edit_mode_value can_edit_interv_plan,
                       pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_begin(1), i_prof) dt_begin,
                       pk_date_utils.date_send_tsz(i_lang, l_tab_dt_begin(1), i_prof) dt_begin_str,
                       --
                       pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_end(1), i_prof) dt_end,
                       pk_date_utils.date_send_tsz(i_lang, l_tab_dt_end(1), i_prof) dt_end_str,
                       --
                       CASE
                            WHEN l_tab_state(1) = g_eip_status_e THEN
                             pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', g_eip_status_a, i_lang)
                            ELSE
                             pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', l_tab_state(1), i_lang)
                        END desc_status,
                       CASE
                            WHEN l_tab_state(1) = pk_alert_constant.g_flg_status_e THEN
                             pk_alert_constant.g_flg_status_a
                            ELSE
                             l_tab_state(1)
                        END flg_status,
                       l_tab_tab_diag(1) id_interv_diagnosis,
                       get_desc_diag(i_lang, i_prof, l_tab_tab_diag(1)) desc_interv_diagnosis,
                       pk_utils.concat_table(get_desc_diag(i_lang, i_prof, l_tab_tab_diag(1)), '; ', 1, -1) desc_diagnosis,
                       NULL diag_flg,
                       l_tab_notes(1) notes,
                       NULL notes_flg
                  FROM dual;
        ELSE
            --DT_BEGIN
            --1 is the initial value
            g_error := 'EDITING MORE THAN ONE INTERV_PLAN ';
            pk_alertlog.log_debug(g_error);
        
            l_edit_mode_value := pk_alert_constant.get_no;
        
            l_tab_dt_begin_tstz := l_tab_dt_begin(1);
            FOR i IN 2 .. l_tab_dt_begin.count
            LOOP
                IF ((l_tab_dt_begin_tstz IS NULL AND l_tab_dt_begin(i) IS NOT NULL) OR
                   (l_tab_dt_begin_tstz IS NOT NULL AND l_tab_dt_begin(i) IS NULL))
                THEN
                    l_dt_begin_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_tab_dt_begin_tstz <> l_tab_dt_begin(i)
                    THEN
                        l_dt_begin_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                
                END IF;
            
            END LOOP;
        
            --DT_END
            --1 is the initial value
            l_tab_dt_end_tstz := l_tab_dt_end(1);
            FOR i IN 2 .. l_tab_dt_end.count
            LOOP
                IF ((l_tab_dt_end_tstz IS NULL AND l_tab_dt_end(i) IS NOT NULL) OR
                   (l_tab_dt_end_tstz IS NOT NULL AND l_tab_dt_end(i) IS NULL))
                THEN
                    l_dt_end_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_tab_dt_end_tstz <> l_tab_dt_end(i)
                    THEN
                        l_dt_end_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                
                END IF;
            
            END LOOP;
        
            --STATE
            --1 is the initial value
            l_state_value := l_tab_state(1);
            FOR i IN 2 .. l_tab_state.count
            LOOP
                IF ((l_state_value IS NULL AND l_tab_state(i) IS NOT NULL) OR
                   (l_state_value IS NOT NULL AND l_tab_state(i) IS NULL))
                THEN
                    l_state_value := t_table_message_array('SOCIAL_T135');
                    EXIT;
                ELSE
                    IF l_state_value <> l_tab_state(i)
                    THEN
                        l_state_value := t_table_message_array('SOCIAL_T135');
                        EXIT;
                    END IF;
                
                END IF;
            
            END LOOP;
        
            --diag
            --1 is the initial value
            l_diag_flg      := NULL;
            l_tab_epis_diag := l_tab_tab_diag(1);
            FOR i IN 2 .. l_tab_tab_diag.count
            LOOP
                IF ((l_tab_epis_diag IS NULL AND l_tab_tab_diag(i) IS NOT NULL) OR
                   (l_tab_epis_diag IS NOT NULL AND l_tab_tab_diag(i) IS NULL))
                THEN
                    l_label_epis_diag := t_table_message_array('SOCIAL_T135');
                    l_diag_flg        := 'M';
                    EXIT;
                ELSE
                    IF l_tab_epis_diag <> l_tab_tab_diag(i)
                    THEN
                        l_label_epis_diag := t_table_message_array('SOCIAL_T135');
                        l_diag_flg        := 'M';
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        
            --NOTES
            --1 is the initial value
            l_notes_flg   := NULL;
            l_notes_value := l_tab_notes(1);
            FOR i IN 2 .. l_tab_notes.count
            LOOP
                IF ((l_notes_value IS NULL AND l_tab_notes(i) IS NOT NULL) OR
                   (l_notes_value IS NOT NULL AND l_tab_notes(i) IS NULL))
                THEN
                    l_notes_value := t_table_message_array('SOCIAL_T135');
                    l_notes_flg   := 'M';
                    EXIT;
                ELSE
                    IF l_notes_value <> l_tab_notes(i)
                    THEN
                        l_notes_value := t_table_message_array('SOCIAL_T135');
                        l_notes_flg   := 'M';
                        EXIT;
                    END IF;
                
                END IF;
            
            END LOOP;
        
            OPEN o_interv_plan FOR
                SELECT t_table_message_array('SOCIAL_T135') id,
                       t_table_message_array('SOCIAL_T135') interv_plan_desc,
                       l_edit_mode_value can_edit_interv_plan,
                       decode(l_dt_begin_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_begin_tstz, i_prof)) dt_begin,
                       decode(l_dt_begin_value,
                              t_table_message_array('SOCIAL_T135'),
                              'M',
                              pk_date_utils.date_send_tsz(i_lang, l_tab_dt_begin_tstz, i_prof)) dt_begin_str,
                       --
                       decode(l_dt_end_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              pk_date_utils.dt_chr_tsz(i_lang, l_tab_dt_end_tstz, i_prof)) dt_end,
                       decode(l_dt_end_value,
                              t_table_message_array('SOCIAL_T135'),
                              'M',
                              pk_date_utils.date_send_tsz(i_lang, l_tab_dt_end_tstz, i_prof)) dt_end_str,
                       --
                       CASE
                            WHEN l_state_value = t_table_message_array('SOCIAL_T135') THEN
                             t_table_message_array('SOCIAL_T135')
                            WHEN l_state_value = g_eip_status_e THEN
                             pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', g_eip_status_a, i_lang)
                            ELSE
                             pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', l_state_value, i_lang)
                        END desc_status,
                       decode(l_state_value, t_table_message_array('SOCIAL_T135'), 'M', l_state_value) flg_status,
                       decode(l_label_epis_diag,
                              t_table_message_array('SOCIAL_T135'),
                              table_number(),
                              l_tab_tab_diag(1)) id_interv_diagnosis,
                       decode(l_label_epis_diag,
                              t_table_message_array('SOCIAL_T135'),
                              table_varchar(),
                              get_desc_diag(i_lang, i_prof, l_tab_tab_diag(1))) desc_interv_diagnosis,
                       decode(l_label_epis_diag,
                              t_table_message_array('SOCIAL_T135'),
                              l_label_epis_diag,
                              pk_utils.concat_table(get_desc_diag(i_lang, i_prof, l_tab_tab_diag(1)), '; ', 1, -1)) desc_diagnosis,
                       l_diag_flg diag_flg,
                       decode(l_notes_value,
                              t_table_message_array('SOCIAL_T135'),
                              t_table_message_array('SOCIAL_T135'),
                              l_notes_value) notes,
                       l_notes_flg notes_flg
                  FROM dual;
        
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT_POPUP',
                                                     o_error);
        
    END get_interv_plan_edit_popup;
    --

    /********************************************************************************************
    * Get labels and domains for the edit screen
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    
    * @ param o_interv_plan           State domains
    * @ param o_screen_labels         Screen label
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_edit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_state_domains OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('PARAMEDICAL_T004',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'SOCIAL_T124',
                                                                                          'PARAMEDICAL_T002',
                                                                                          'PARAMEDICAL_T022'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'OPEN LABELS CURSOR';
        OPEN o_screen_labels FOR
            SELECT t_table_message_array('PARAMEDICAL_T004') edit_interv_plan_main_header,
                   t_table_message_array('SOCIAL_T124') plan_column,
                   t_table_message_array('PARAMEDICAL_T002') task_goal_column,
                   t_table_message_array('SOCIAL_T104') dt_begin_column,
                   t_table_message_array('SOCIAL_T125') dt_end_column,
                   t_table_message_array('SOCIAL_T004') state_column,
                   t_table_message_array('PARAMEDICAL_T022') social_diagnosis_column
              FROM dual;
    
        g_error := 'GET_DOMAINS';
        IF NOT get_interv_plan_state_domains(i_lang              => i_lang,
                                             i_prof              => i_prof,
                                             i_current_state     => NULL,
                                             o_interv_plan_state => o_state_domains,
                                             o_error             => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_state_domains);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_EDIT',
                                                     o_error);
    END get_interv_plan_edit;
    --

    /********************************************************************************************
    * Get the history of a given intervention plan (when i_epis_interv_plan is not null) or the
    * history of all intervention plans (the current state) for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_epis_interv_plan      ID Intervention plan
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_HIST: i_id_epis = ' || i_id_epis || ', i_prof.id = ' || i_prof.id ||
                   ', i_id_epis_interv_plan = ' || i_id_epis_interv_plan;
        pk_alertlog.log_debug(g_error);
        --
    
        IF NOT get_interv_plan_hist(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_epis             => table_number(i_id_epis),
                                    i_id_epis_interv_plan => i_id_epis_interv_plan,
                                    o_interv_plan         => o_interv_plan,
                                    o_interv_plan_prof    => o_interv_plan_prof,
                                    o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_interv_plan_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_HIST',
                                                     o_error);
    END get_interv_plan_hist;
    --

    /********************************************************************************************
    * Get the history of a given intervention plan (when i_epis_interv_plan is not null) or the
    * history of all intervention plans (the current state) for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_epis_interv_plan      ID Intervention plan
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN table_number,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
        l_category category.flg_type%TYPE;
    BEGIN
        g_error := 'GET_INTERV_PLAN_HIST: i_id_epis is array ' || ', i_prof.id = ' || i_prof.id ||
                   ', i_id_epis_interv_plan = ' || i_id_epis_interv_plan;
        pk_alertlog.log_debug(g_error);
        --
        l_category := pk_prof_utils.get_category(i_lang, i_prof);
        g_error    := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('PARAMEDICAL_T003',
                                                                                          'SOCIAL_T082',
                                                                                          'SOCIAL_T124',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'SOCIAL_T107',
                                                                                          'SOCIAL_T108',
                                                                                          'SOCIAL_T109',
                                                                                          'PARAMEDICAL_T002',
                                                                                          'PARAMEDICAL_T022'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF i_id_epis_interv_plan IS NOT NULL
        THEN
            --
            g_error := 'GET CURSOR INTER_PLAN HISTORY';
            OPEN o_interv_plan FOR
                SELECT t.id,
                       t.id_episode,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T003')) || CASE
                            WHEN t.id_interv_plan = 0 THEN
                             t.desc_other_interv_plan
                            WHEN t.id_interv_plan IS NULL THEN
                             t.desc_other_interv_plan
                            ELSE
                             pk_translation.get_translation(i_lang, t.code_interv_plan)
                        END interv_plan_desc,
                       decode(l_category,
                              pk_alert_constant.g_cat_type_social,
                              NULL,
                              decode(tt.code_task_goal,
                                     NULL,
                                     decode(get_task_goal_desc(i_lang, i_prof, t.id_task_goal_det),
                                            NULL,
                                            NULL,
                                            pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T002')) ||
                                            get_task_goal_desc(i_lang, i_prof, t.id_task_goal_det)),
                                     pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T002')) ||
                                     pk_translation.get_translation(i_lang, tt.code_task_goal))) desc_task_goal,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T104')) ||
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_begin, i_prof) desc_dt_begin,
                       decode(t.dt_end,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T125')) ||
                              pk_date_utils.dt_chr_tsz(i_lang, t.dt_end, i_prof)) desc_dt_end,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T004')) ||
                       decode(t.flg_status,
                              pk_alert_constant.g_flg_status_e,
                              pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS',
                                                      pk_alert_constant.g_flg_status_a,
                                                      i_lang),
                              pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', t.flg_status, i_lang)) desc_status,
                       decode(t.desc_diagnosis,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T022')) ||
                              t.desc_diagnosis) desc_diagnosis,
                       decode(t.notes,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082')) ||
                              t.notes) desc_notes,
                       decode(t.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                        'COMMON_M072')) ||
                              pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, t.id_cancel_info_det),
                              NULL) cancel_reason,
                       decode(t.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              decode(t.cancel_desc,
                                     NULL,
                                     NULL,
                                     pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                               'COMMON_M073')) ||
                                     t.cancel_desc),
                              NULL) cancel_notes
                  FROM (SELECT eiph.id_epis_interv_plan_hist id,
                               eiph.id_episode id_episode,
                               eiph.id_interv_plan,
                               eiph.desc_other_interv_plan,
                               ip.code_interv_plan,
                               eiph.id_task_goal_det,
                               eiph.dt_begin,
                               eiph.dt_end,
                               eiph.flg_status,
                               pk_utils.concat_table(get_desc_epis_diag(i_lang,
                                                                        i_prof,
                                                                        get_epis_interv_plan_diag(i_lang,
                                                                                                  i_prof,
                                                                                                  NULL,
                                                                                                  eiph.id_epis_interv_plan_hist)),
                                                     '; ',
                                                     1,
                                                     -1) desc_diagnosis,
                               eiph.notes,
                               eiph.id_cancel_info_det,
                               eiph.dt_creation,
                               pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, eiph.id_cancel_info_det) cancel_desc,
                               row_number() over(PARTITION BY eiph.id_epis_interv_plan ORDER BY eiph.id_epis_interv_plan_hist) AS rn
                          FROM epis_interv_plan_hist eiph
                          LEFT JOIN interv_plan ip
                            ON (eiph.id_interv_plan = ip.id_interv_plan)
                         WHERE eiph.id_epis_interv_plan = i_id_epis_interv_plan) t
                  LEFT JOIN (SELECT tgdh.*,
                                    tg.code_task_goal,
                                    row_number() over(PARTITION BY tgdh.id_task_goal_det ORDER BY tgdh.id_task_goal_det_hist) AS rn
                               FROM task_goal_det_hist tgdh
                               JOIN task_goal tg
                                 ON tg.id_task_goal = tgdh.id_task_goal
                              WHERE tgdh.id_task_goal_det IN
                                    (SELECT eiph.id_task_goal_det
                                       FROM epis_interv_plan_hist eiph
                                      WHERE eiph.id_epis_interv_plan = i_id_epis_interv_plan)) tt
                    ON tt.rn = t.rn
                 ORDER BY t.dt_creation DESC;
            --
            g_error := 'GET CURSOR INTER_PLAN_PROF HISTORY';
            OPEN o_interv_plan_prof FOR
                SELECT eiph.id_epis_interv_plan_hist,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, eiph.dt_creation, i_prof) dt,
                       pk_tools.get_prof_description(i_lang, i_prof, eiph.id_professional, eiph.dt_creation, NULL) prof_sign,
                       eiph.flg_status flg_status,
                       CASE
                            WHEN eiph.flg_status = g_plan_active
                                 AND (SELECT COUNT(*)
                                        FROM epis_interv_plan_hist eiph2
                                       WHERE eiph2.id_epis_interv_plan = i_id_epis_interv_plan
                                         AND eiph2.dt_creation < eiph.dt_creation) > 1 THEN
                             pk_message.get_message(i_lang, 'MEDICATION_DETAILS_M055')
                            ELSE
                             get_interv_plan_state_desc(i_lang, i_prof, eiph.flg_status)
                        END desc_status,
                       eiph.id_task_goal_det,
                       get_task_goal_desc(i_lang, i_prof, eiph.id_task_goal_det) desc_task_goal
                  FROM epis_interv_plan_hist eiph
                 WHERE eiph.id_epis_interv_plan = i_id_epis_interv_plan
                 ORDER BY eiph.dt_creation DESC;
        ELSE
            g_error := 'GET CURSOR INTER_PLAN HISTORY';
            OPEN o_interv_plan FOR
                SELECT t.id,
                       t.id_episode,
                       CASE
                            WHEN t.id_interv_plan = 0 THEN
                             t.desc_other_interv_plan
                            WHEN t.id_interv_plan IS NULL THEN
                             t.desc_other_interv_plan
                            ELSE
                             pk_translation.get_translation(i_lang, t.code_interv_plan)
                        END interv_plan_desc,
                       t.id_task_goal_det,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T002')) ||
                       --ALERT-98764 - The goal field must be available also for SW, but we need flash changes to do that!
                       --The changes will be implemented in the Issue - ALERT-99008
                        decode(l_category,
                               pk_alert_constant.g_cat_type_social,
                               NULL,
                               get_task_goal_desc(i_lang, i_prof, t.id_task_goal_det)) desc_task_goal,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T104')) ||
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_begin, i_prof) desc_dt_begin,
                       decode(t.dt_end,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T125')) ||
                              pk_date_utils.dt_chr_tsz(i_lang, t.dt_end, i_prof)) desc_dt_end,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082')) ||
                       t.notes desc_notes,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T004')) ||
                       pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', t.flg_status, i_lang) desc_status,
                       decode(t.desc_diagnosis,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T022')) ||
                              t.desc_diagnosis) desc_diagnosis,
                       decode(t.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                        'COMMON_M072')) ||
                              pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, t.id_cancel_info_det),
                              NULL) cancel_reason,
                       decode(t.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              decode(t.desc_cancel,
                                     NULL,
                                     NULL,
                                     pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                               'COMMON_M073')) ||
                                     t.desc_cancel),
                              NULL) cancel_notes
                  FROM (SELECT eiph.id_epis_interv_plan_hist id,
                               eiph.id_episode id_episode,
                               eiph.id_interv_plan,
                               eiph.desc_other_interv_plan,
                               ip.code_interv_plan,
                               eiph.id_task_goal_det,
                               eiph.dt_begin,
                               eiph.dt_end,
                               eiph.notes,
                               eiph.flg_status,
                               pk_utils.concat_table(get_desc_epis_diag(i_lang,
                                                                        i_prof,
                                                                        get_epis_interv_plan_diag(i_lang,
                                                                                                  i_prof,
                                                                                                  NULL,
                                                                                                  eiph.id_epis_interv_plan_hist)),
                                                     '; ',
                                                     1,
                                                     -1) desc_diagnosis,
                               eiph.id_cancel_info_det,
                               pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, eiph.id_cancel_info_det) desc_cancel,
                               eiph.dt_creation
                          FROM epis_interv_plan_hist eiph
                          LEFT JOIN interv_plan ip
                            ON (eiph.id_interv_plan = ip.id_interv_plan)
                         WHERE eiph.id_episode IN (SELECT column_value
                                                     FROM TABLE(i_id_epis))) t
                 ORDER BY t.dt_creation DESC;
            --
            g_error := 'GET CURSOR INTER_PLAN_PROF HISTORY';
            OPEN o_interv_plan_prof FOR
                SELECT eiph.id_epis_interv_plan_hist id,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, eiph.dt_creation, i_prof) dt,
                       pk_tools.get_prof_description(i_lang, i_prof, eiph.id_professional, eiph.dt_creation, NULL) prof_sign,
                       eiph.flg_status flg_status,
                       CASE
                            WHEN eiph.flg_status = g_plan_active
                                 AND (SELECT COUNT(*)
                                        FROM epis_interv_plan_hist eiph2
                                       WHERE eiph2.id_epis_interv_plan = i_id_epis_interv_plan
                                         AND eiph2.dt_creation < eiph.dt_creation) > 1 THEN
                             pk_message.get_message(i_lang, 'MEDICATION_DETAILS_M055')
                            ELSE
                             get_interv_plan_state_desc(i_lang, i_prof, eiph.flg_status)
                        END desc_status,
                       eiph.id_task_goal_det,
                       get_task_goal_desc(i_lang, i_prof, eiph.id_task_goal_det) desc_task_goal
                  FROM epis_interv_plan_hist eiph
                 WHERE eiph.id_episode IN (SELECT column_value
                                             FROM TABLE(i_id_epis))
                 ORDER BY eiph.dt_creation DESC;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_interv_plan_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_HIST',
                                                     o_error);
    END get_interv_plan_hist;
    --

    /********************************************************************************************
    * Get the intervention plan list for the summary screen.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/22
    **********************************************************************************************/
    FUNCTION get_interv_plan_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN table_number,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET_INTERV_PLAN_SUMMARY: i_id_epis is array ' || ', i_prof.id = ' || i_prof.id || '.';
        pk_alertlog.log_debug(g_error);
        --
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('PARAMEDICAL_T003',
                                                                                          'SOCIAL_T082',
                                                                                          'SOCIAL_T124',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'SOCIAL_T107',
                                                                                          'SOCIAL_T108',
                                                                                          'SOCIAL_T109',
                                                                                          'PARAMEDICAL_T002',
                                                                                          'PARAMEDICAL_T022'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error := 'GET CURSOR INTER_PLAN HISTORY';
        OPEN o_interv_plan FOR
            SELECT eip.id_epis_interv_plan id,
                   eip.id_episode id_episode,
                   CASE
                        WHEN eip.id_interv_plan = 0 THEN
                         eip.desc_other_interv_plan || chr(10)
                        WHEN eip.id_interv_plan IS NULL THEN
                         eip.desc_other_interv_plan || chr(10)
                        ELSE
                         '<b>' || pk_translation.get_translation(i_lang, ip.code_interv_plan) || '</b>' || chr(10)
                    END interv_plan_desc,
                   --pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T002')) ||
                   --nvl2(eip.id_task_goal_det,
                   --     get_task_goal_desc(i_lang, i_prof, eip.id_task_goal_det),
                   --     pk_paramedical_prof_core.c_dashes) interv_plan_goal,
                   --pk_tools.get_prof_description(i_lang, i_prof, eip.id_professional, eip.dt_begin, NULL) prof_sign,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T104')) ||
                   nvl2(eip.dt_begin,
                        pk_date_utils.dt_chr_tsz(i_lang, eip.dt_begin, i_prof),
                        pk_paramedical_prof_core.c_dashes) desc_dt_begin,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T125')) ||
                   nvl2(eip.dt_end,
                        pk_date_utils.dt_chr_tsz(i_lang, eip.dt_end, i_prof),
                        pk_paramedical_prof_core.c_dashes) desc_dt_end,
                   --diagnosis
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T022')) ||
                   nvl(pk_utils.concat_table(get_desc_epis_diag(i_lang,
                                                                i_prof,
                                                                get_epis_interv_plan_diag(i_lang,
                                                                                          i_prof,
                                                                                          eip.id_epis_interv_plan,
                                                                                          NULL)),
                                             '; ',
                                             1,
                                             -1),
                       pk_paramedical_prof_core.c_dashes) desc_diagnosis,
                   --notes
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082')) ||
                   nvl(eip.notes, pk_paramedical_prof_core.c_dashes) desc_notes,
                   get_ehr_last_update_info(i_lang, i_prof, eip.dt_creation, eip.id_professional, eip.dt_creation) last_update_info
              FROM epis_interv_plan eip
              LEFT JOIN interv_plan ip
                ON (eip.id_interv_plan = ip.id_interv_plan)
             WHERE eip.id_episode IN (SELECT column_value
                                        FROM TABLE(i_id_epis))
               AND eip.flg_status <> pk_alert_constant.g_flg_status_c
             ORDER BY eip.dt_creation DESC;
        --
        g_error := 'GET CURSOR INTER_PLAN_PROF HISTORY';
        OPEN o_interv_plan_prof FOR
            SELECT eip.id_epis_interv_plan id,
                   eip.id_task_goal_det,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, eip.dt_creation, i_prof) dt,
                   pk_tools.get_prof_description(i_lang, i_prof, eip.id_professional, eip.dt_creation, NULL) prof_sign,
                   eip.flg_status flg_status --,
            --get_interv_plan_state_desc(i_lang, i_prof, eiph.flg_status) desc_status
              FROM epis_interv_plan eip
             WHERE eip.id_episode IN (SELECT column_value
                                        FROM TABLE(i_id_epis))
               AND eip.flg_status <> pk_alert_constant.g_flg_status_c
             ORDER BY eip.dt_creation DESC;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_interv_plan_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_SUMMARY',
                                                     o_error);
    END get_interv_plan_summary;

    /**
    * Get the intervention plan list for the summary screen
    * (implementation of get_interv_plan_summary for the Reports layer).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_epis      list of episodes
    * @param o_interv_plan  social intervention plans
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/12
    */
    PROCEDURE get_interv_plan_summary_rep
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis     IN table_number,
        o_interv_plan OUT pk_types.cursor_type
    ) IS
        l_lbl_dt_begin  sys_message.desc_message%TYPE;
        l_lbl_dt_end    sys_message.desc_message%TYPE;
        l_lbl_diagnosis sys_message.desc_message%TYPE;
        l_lbl_notes     sys_message.desc_message%TYPE;
        l_lbl_last_upd  sys_message.desc_message%TYPE;
    BEGIN
        l_lbl_dt_begin  := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang      => i_lang,
                                                                                           i_prof      => i_prof,
                                                                                           i_code_mess => 'SOCIAL_T104'),
                                                     i_is_report => pk_alert_constant.g_yes);
        l_lbl_dt_end    := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang      => i_lang,
                                                                                           i_prof      => i_prof,
                                                                                           i_code_mess => 'SOCIAL_T125'),
                                                     i_is_report => pk_alert_constant.g_yes);
        l_lbl_diagnosis := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang      => i_lang,
                                                                                           i_prof      => i_prof,
                                                                                           i_code_mess => 'PARAMEDICAL_T022'),
                                                     i_is_report => pk_alert_constant.g_yes);
        l_lbl_notes     := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang      => i_lang,
                                                                                           i_prof      => i_prof,
                                                                                           i_code_mess => 'SOCIAL_T082'),
                                                     i_is_report => pk_alert_constant.g_yes);
        l_lbl_last_upd  := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang      => i_lang,
                                                                                           i_prof      => i_prof,
                                                                                           i_code_mess => 'PAST_HISTORY_M006'),
                                                     i_is_report => pk_alert_constant.g_yes);
    
        g_error := 'OPEN o_interv_plan';
        OPEN o_interv_plan FOR
            SELECT eip.id_epis_interv_plan id,
                   eip.id_episode,
                   CASE
                        WHEN eip.id_interv_plan IS NULL
                             OR eip.id_interv_plan = 0 THEN
                         eip.desc_other_interv_plan
                        ELSE
                         pk_translation.get_translation(i_lang, ip.code_interv_plan)
                    END interv_plan_desc,
                   l_lbl_dt_begin lbl_dt_begin,
                   pk_date_utils.dt_chr_tsz(i_lang, eip.dt_begin, i_prof) desc_dt_begin,
                   l_lbl_dt_end lbl_dt_end,
                   pk_date_utils.dt_chr_tsz(i_lang, eip.dt_end, i_prof) desc_dt_end,
                   --diagnosis
                   l_lbl_diagnosis lbl_diagnosis,
                   pk_utils.concat_table(get_desc_epis_diag(i_lang,
                                                            i_prof,
                                                            get_epis_interv_plan_diag(i_lang,
                                                                                      i_prof,
                                                                                      eip.id_epis_interv_plan,
                                                                                      NULL)),
                                         '; ',
                                         1,
                                         -1) desc_diagnosis,
                   --notes
                   l_lbl_notes lbl_notes,
                   eip.notes desc_notes,
                   l_lbl_last_upd lbl_last_upd,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eip.id_professional) desc_prof_last_upd,
                   pk_prof_utils.get_desc_category(i_lang, i_prof, eip.id_professional, i_prof.institution) desc_cat_last_upd,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, eip.dt_creation, i_prof) desc_dt_last_upd,
                   pk_date_utils.date_send_tsz(i_lang, eip.dt_creation, i_prof) serial_dt_last_upd
              FROM epis_interv_plan eip
              LEFT JOIN interv_plan ip
                ON (eip.id_interv_plan = ip.id_interv_plan)
             WHERE eip.id_episode IN (SELECT /*+dynamic_sampling(t 2)*/
                                       t.column_value
                                        FROM TABLE(i_id_epis) t)
               AND eip.flg_status <> pk_alert_constant.g_flg_status_c
             ORDER BY eip.dt_creation DESC;
    END get_interv_plan_summary_rep;

    /********************************************************************************************
    * Return a string with the intervention plan state
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_interv_plan_flg       Intervention plane state
    *
    * @return                         intervention plan state
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/03/17
    **********************************************************************************************/
    FUNCTION get_interv_plan_state_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_interv_plan_flg IN epis_interv_plan.flg_status%TYPE
    ) RETURN sys_message.desc_message%TYPE IS
        l_msg_code sys_message.code_message%TYPE;
    BEGIN
        IF i_interv_plan_flg = g_plan_active
        THEN
            l_msg_code := 'SOCIAL_T107';
        ELSIF i_interv_plan_flg = g_plan_edited
        THEN
            l_msg_code := 'SOCIAL_T108';
        ELSIF i_interv_plan_flg = g_plan_cancelled
        THEN
            l_msg_code := 'SOCIAL_T109';
        ELSIF i_interv_plan_flg = g_plan_suspended
        THEN
            l_msg_code := 'SOCIAL_T151';
        ELSIF i_interv_plan_flg = g_plan_concluded
        THEN
            l_msg_code := 'SOCIAL_T152';
        END IF;
    
        RETURN pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => l_msg_code);
    END get_interv_plan_state_desc;
    --

    /********************************************************************************************
    * Cancel Intervention plans.
    *
    * @param i_lang                    Preferred language ID for this professional
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_epis                 Episode ID
    * @ param i_id_epis_interv_plan     Intervention plan ID
    * @ param i_notes                   Cancel notes
    * @ param i_cancel_reason           Cancel reason
    *
    * @ param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                           Orlando Antunes
    * @version                          0.1
    * @since                            2010/02/25
    **********************************************************************************************/
    FUNCTION set_cancel_interv_plan
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN table_number,
        i_notes               IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cancel_info_det_id    cancel_info_det.id_cancel_info_det%TYPE;
        l_rowids                table_varchar;
        l_tb_epis_diag          table_number;
        l_epis_interv_plan_hist epis_interv_plan_hist.id_epis_interv_plan%TYPE;
        l_epis_interv_plan_row  epis_interv_plan%ROWTYPE;
    
    BEGIN
        FOR i IN 1 .. i_id_epis_interv_plan.count
        LOOP
            g_error := 'SET_CANCEL_INTERV_PLAN: i_id_epis_interv_plan = ' || i_id_epis_interv_plan(i) ||
                       ', i_prof.id = ' || i_prof.id || ', i_notes = ' || i_notes || ', i_cancel_reason = ' ||
                       i_cancel_reason;
        
            pk_alertlog.log_debug(g_error);
        
            g_sysdate_tstz := current_timestamp;
            --
            --
            IF i_id_epis_interv_plan IS NULL
            THEN
                g_error := 'SET_CANCEL_INTERV_PLAN: INVALID i_id_epis_interv_plan';
                RAISE g_sw_generic_exception;
            ELSE
                /*IF NOT set_new_interv_plan_state(i_lang                  => i_lang,
                                                 i_prof                  => i_prof,
                                                 i_id_epis               => i_id_epis,
                                                 i_id_epis_interv_plan   => i_id_epis_interv_plan,
                                                 i_new_interv_plan_state => pk_alert_constant.g_flg_status_c,
                                                 o_error                 => o_error)
                THEN
                    RAISE g_sw_generic_exception;
                END IF;*/
            
                g_sysdate_tstz := current_timestamp;
                --
                pk_alertlog.log_debug('SET_CANCEL_SOCIAL_CLASS : SAVE CANCEL DETAILS');
                ts_cancel_info_det.ins(id_prof_cancel_in      => i_prof.id,
                                       id_cancel_reason_in    => i_cancel_reason,
                                       dt_cancel_in           => g_sysdate_tstz,
                                       notes_cancel_short_in  => i_notes,
                                       id_cancel_info_det_out => l_cancel_info_det_id,
                                       rows_out               => l_rowids);
            
                g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON CANCEL_INFO_DET';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CANCEL_INFO_DET',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                --update intervention plans state
                g_error := 'UPDATE CURRENT epis_interv_plan';
                ts_epis_interv_plan.upd(id_epis_interv_plan_in => i_id_epis_interv_plan(i),
                                        flg_status_in          => pk_alert_constant.g_flg_status_c,
                                        id_cancel_info_det_in  => l_cancel_info_det_id,
                                        rows_out               => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INTERV_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
                --
                g_error := 'GET CURRENT epis_interv_plan';
                SELECT *
                  INTO l_epis_interv_plan_row
                  FROM epis_interv_plan eip
                 WHERE eip.id_epis_interv_plan = i_id_epis_interv_plan(i);
            
                g_error        := 'call get_epis_interv_plan_diag';
                l_tb_epis_diag := get_epis_interv_plan_diag(i_lang, i_prof, i_id_epis_interv_plan(i), NULL);
            
                g_error := 'CREATE epis_interv_plan HISTORY';
                --and create the history records for new intervention plans
                ts_epis_interv_plan_hist.ins(id_epis_interv_plan_in       => i_id_epis_interv_plan(i),
                                             id_interv_plan_in            => l_epis_interv_plan_row.id_interv_plan,
                                             id_episode_in                => l_epis_interv_plan_row.id_episode,
                                             id_professional_in           => i_prof.id,
                                             flg_status_in                => pk_alert_constant.g_flg_status_c,
                                             notes_in                     => l_epis_interv_plan_row.notes,
                                             dt_creation_in               => g_sysdate_tstz,
                                             dt_begin_in                  => l_epis_interv_plan_row.dt_begin,
                                             dt_end_in                    => l_epis_interv_plan_row.dt_end,
                                             desc_other_interv_plan_in    => l_epis_interv_plan_row.desc_other_interv_plan,
                                             id_cancel_info_det_in        => l_cancel_info_det_id,
                                             id_epis_interv_plan_hist_out => l_epis_interv_plan_hist,
                                             id_task_goal_det_in          => l_epis_interv_plan_row.id_task_goal_det,
                                             rows_out                     => l_rowids);
            
                g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON EPIS_INTERV_PLAN_HIST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INTERV_PLAN_HIST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'call set_epis_interv_plan_diag_nc';
                IF NOT set_epis_interv_plan_diag_nc(i_lang                     => i_lang,
                                                    i_prof                     => i_prof,
                                                    i_id_episode               => i_id_epis,
                                                    i_id_epis_interv_plan_hist => l_epis_interv_plan_hist,
                                                    i_tb_diag                  => table_number(),
                                                    i_tb_alert_diag            => table_number(),
                                                    i_tb_desc_diag             => table_varchar(),
                                                    i_tb_epis_diag             => l_tb_epis_diag,
                                                    o_error                    => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                -- Verificar se a primeira observação do parecer realizada pela assistente social
                g_error := 'CALL pk_visit.set_first_obs';
                IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                              i_id_episode          => i_id_epis,
                                              i_pat                 => NULL,
                                              i_prof                => i_prof,
                                              i_prof_cat_type       => NULL,
                                              i_dt_last_interaction => g_sysdate_tstz,
                                              i_dt_first_obs        => g_sysdate_tstz,
                                              o_error               => o_error)
                THEN
                    pk_utils.undo_changes;
                    pk_alert_exceptions.reset_error_state;
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
        --
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_CANCEL_INTERV_PLAN',
                                                     o_error);
        
    END set_cancel_interv_plan;
    --

    /********************************************************************************************
    * Get Intervention plans available actiosn
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_current_state          Current state
    * @param o_interv_plan_actions    List of actions
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/25
    **********************************************************************************************/
    FUNCTION get_interv_plan_actions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_current_state       IN table_varchar,
        o_interv_plan_actions OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET SOCIAL STATUS ACTIONS';
        IF NOT pk_action.get_actions_with_exceptions(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_subject    => table_varchar('SOCIAL_WORKER_INTERV_PLANS'),
                                                     i_from_state => i_current_state,
                                                     o_actions    => o_interv_plan_actions,
                                                     o_error      => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan_actions);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_ACTIONS',
                                                     o_error);
        
    END get_interv_plan_actions;
    --

    /*
    * Get an episode's paramedical service reports list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_report_prof    reports records info
    * @param o_report         reports
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    PROCEDURE get_paramed_report_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_show_cancelled IN VARCHAR2,
        o_report_prof    OUT pk_types.cursor_type,
        o_report         OUT pk_types.cursor_type
    ) IS
    BEGIN
        g_error := 'OPEN o_report_prof_list';
        OPEN o_report_prof FOR
            SELECT pr.id_paramed_report id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, pr.dt_last_update, i_prof) dt,
                   pk_tools.get_prof_description(i_lang, i_prof, pr.id_professional, pr.dt_last_update, pr.id_episode) prof_sign,
                   pr.flg_status,
                   NULL desc_status,
                   decode(pr.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_cancel,
                   decode(pr.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_action
              FROM paramed_report pr
             WHERE pr.id_episode IN (SELECT column_value
                                       FROM TABLE(i_episode))
               AND (pr.flg_status IN (g_report_active, g_report_edit) OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND pr.flg_status = g_report_cancel))
             ORDER BY decode(pr.flg_status, g_report_cancel, 2, 1) ASC, pr.dt_last_update DESC;
    
        g_error := 'OPEN o_report_list';
        OPEN o_report FOR
            SELECT pr.id_paramed_report id,
                   pr.id_episode id_episode,
                   pr.text,
                   get_ehr_last_update_info(i_lang,
                                            i_prof,
                                            pr.dt_last_update,
                                            pr.id_professional,
                                            pr.dt_last_update,
                                            pr.id_episode) last_update_info
              FROM paramed_report pr
             WHERE pr.id_episode IN (SELECT column_value
                                       FROM TABLE(i_episode))
               AND (pr.flg_status IN (g_report_active, g_report_edit) OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND pr.flg_status = g_report_cancel))
             ORDER BY decode(pr.flg_status, g_report_cancel, 2, 1) ASC, pr.dt_last_update DESC;
    END get_paramed_report_list;

    /*
    * Get an episode's paramedical service reports list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_report_prof    reports records info
    * @param o_report         reports
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    PROCEDURE get_paramed_report_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN management_follow_up.id_episode%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_report_prof    OUT pk_types.cursor_type,
        o_report         OUT pk_types.cursor_type
    ) IS
    BEGIN
        get_paramed_report_list(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_episode        => table_number(i_episode),
                                i_show_cancelled => i_show_cancelled,
                                o_report_prof    => o_report_prof,
                                o_report         => o_report);
    
    END get_paramed_report_list;
    --

    /*
    * Get an episode's paramedical service reports list. Specify the report
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_report         report identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_report_prof    reports records info
    * @param o_report         reports
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/04
    */
    FUNCTION get_paramed_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_report         IN paramed_report.id_paramed_report%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_report_prof    OUT pk_types.cursor_type,
        o_report         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_report IS NULL
        THEN
            g_error := 'CALL get_paramed_report_list';
            get_paramed_report_list(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_episode        => i_episode,
                                    i_show_cancelled => i_show_cancelled,
                                    o_report_prof    => o_report_prof,
                                    o_report         => o_report);
        ELSE
            -- TODO history function
            NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_PARAMED_REPORT',
                                                     o_error    => o_error);
    END get_paramed_report;

    /*
    * Set paramedical service report history.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_report         report identifier
    * @param o_error          error
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/04
    */
    PROCEDURE set_paramed_report_hist
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_report IN paramed_report.id_paramed_report%TYPE,
        o_error  OUT t_error_out
    ) IS
        l_hist_rec paramed_report_hist%ROWTYPE;
        l_rows_out table_varchar := table_varchar();
    BEGIN
        g_error := 'SELECT paramed_report';
        SELECT pr.id_paramed_report,
               pr.flg_status,
               pr.text,
               pr.id_episode,
               pr.dt_creation,
               pr.dt_last_update,
               pr.id_professional,
               pr.id_cancel_info_det
          INTO l_hist_rec.id_paramed_report,
               l_hist_rec.flg_status,
               l_hist_rec.text,
               l_hist_rec.id_episode,
               l_hist_rec.dt_creation,
               l_hist_rec.dt_last_update,
               l_hist_rec.id_professional,
               l_hist_rec.id_cancel_info_det
          FROM paramed_report pr
         WHERE pr.id_paramed_report = i_report;
    
        g_error := 'CALL ts_paramed_report_hist.ins';
        ts_paramed_report_hist.ins(rec_in => l_hist_rec, gen_pky_in => TRUE, rows_out => l_rows_out);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PARAMED_REPORT_HIST',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    END set_paramed_report_hist;

    /*
    * Set paramedical service report.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_report         report identifier
    * @param i_episode        episode identifier
    * @param i_text           report text
    * @param o_report         created report identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/04
    */
    FUNCTION set_paramed_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_report  IN paramed_report.id_paramed_report%TYPE,
        i_episode IN paramed_report.id_episode%TYPE,
        i_text    IN paramed_report.text%TYPE,
        o_report  OUT paramed_report.id_paramed_report%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out table_varchar := table_varchar();
        l_report   paramed_report.id_paramed_report%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_report IS NULL
        THEN
            g_error := 'CALL ts_paramed_report.ins';
            ts_paramed_report.ins(flg_status_in         => g_report_active,
                                  text_in               => i_text,
                                  id_episode_in         => i_episode,
                                  dt_creation_in        => g_sysdate_tstz,
                                  dt_last_update_in     => g_sysdate_tstz,
                                  id_professional_in    => i_prof.id,
                                  rows_out              => l_rows_out,
                                  id_paramed_report_out => l_report);
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PARAMED_REPORT',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        ELSE
            g_error := 'CALL ts_paramed_report.upd';
            ts_paramed_report.upd(id_paramed_report_in => i_report,
                                  flg_status_in        => g_report_edit,
                                  flg_status_nin       => FALSE,
                                  text_in              => i_text,
                                  text_nin             => FALSE,
                                  dt_last_update_in    => g_sysdate_tstz,
                                  dt_last_update_nin   => FALSE,
                                  id_professional_in   => i_prof.id,
                                  id_professional_nin  => FALSE,
                                  rows_out             => l_rows_out);
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'PARAMED_REPORT',
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS',
                                                                          'TEXT',
                                                                          'DT_LAST_UPDATE',
                                                                          'ID_PROFESSIONAL'));
        END IF;
    
        g_error := 'CALL set_paramed_report_hist';
        set_paramed_report_hist(i_lang   => i_lang,
                                i_prof   => i_prof,
                                i_report => nvl(i_report, l_report),
                                o_error  => o_error);
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        o_report := l_report;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PARAMED_REPORT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_paramed_report;

    /********************************************************************************************
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_task_goal_det       Identifier of the task/goal detail from intervention plans
    * @param i_id_task_goal           Identifier of the coded task/goal
    * @param i_desc_task_goal         Free text description of the task/goal
    * @param o_id_task_goal_det       Identifier of the task/goal detail from intervention plans
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         João Almeida
    * @version                        0.1
    * @since                          2010/04/12
    **********************************************************************************************/
    FUNCTION set_task_goal_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_task_goal_det IN task_goal_det.id_task_goal_det%TYPE,
        i_id_task_goal     IN task_goal.id_task_goal%TYPE,
        i_desc_task_goal   IN task_goal_det.desc_task_goal%TYPE,
        o_id_task_goal_det OUT task_goal_det.id_task_goal_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_task_goal_det task_goal_det.id_task_goal_det%TYPE;
        l_rowids           table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        -- Verificar se a o detalhe já existe
        g_error := 'SET_TASK_GOAL_DET: Verificar se a o detalhe já existe';
    
        pk_alertlog.log_debug(g_error);
        IF i_id_task_goal_det IS NULL
        THEN
            g_error := 'SET_TASK_GOAL_DET - i_id_task_goal_det' || i_id_task_goal_det;
            --create new task_goal_det
            ts_task_goal_det.ins(id_task_goal_in      => i_id_task_goal,
                                 desc_task_goal_in    => i_desc_task_goal,
                                 id_task_goal_det_out => o_id_task_goal_det,
                                 rows_out             => l_rowids);
        
            l_id_task_goal_det := o_id_task_goal_det;
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON TASK_GOAL_DET';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'TASK_GOAL_DET',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            ts_task_goal_det_hist.ins(id_task_goal_det_in => l_id_task_goal_det,
                                      id_task_goal_in     => i_id_task_goal,
                                      desc_task_goal_in   => i_desc_task_goal,
                                      rows_out            => l_rowids);
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON TASK_GOAL_DET_HIST';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'TASK_GOAL_DET_HIST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
            g_error := 'UPDATE_TASK_GOAL_DET - i_id_task_goal_det' || i_id_task_goal_det;
        
            --update task_goal_det
            ts_task_goal_det.upd(id_task_goal_det_in => i_id_task_goal_det,
                                 id_task_goal_in     => i_id_task_goal,
                                 desc_task_goal_in   => i_desc_task_goal,
                                 rows_out            => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'TASK_GOAL_DET',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            ts_task_goal_det_hist.ins(id_task_goal_det_in => i_id_task_goal_det,
                                      id_task_goal_in     => i_id_task_goal,
                                      desc_task_goal_in   => i_desc_task_goal,
                                      rows_out            => l_rowids);
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON TASK_GOAL_DET_HIST';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'TASK_GOAL_DET_HIST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            o_id_task_goal_det := i_id_task_goal_det;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_TASK_GOAL_DET',
                                                     o_error);
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_TASK_GOAL_DET',
                                                     o_error);
    END set_task_goal_det;

    /*
    * Retrieve the number of follow up notes of an episode.
    *
    * @param i_episode        episode identifier
    *
    * @return                 count of follow up notes.
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    FUNCTION get_encounter_count(i_episode IN episode.id_episode%TYPE) RETURN PLS_INTEGER IS
        l_retval PLS_INTEGER;
    BEGIN
        g_error := 'SELECT COUNT(*)';
        SELECT COUNT(*)
          INTO l_retval
          FROM management_follow_up mfu
         WHERE mfu.id_episode = i_episode
           AND mfu.flg_status = pk_case_management.g_mfu_status_active;
    
        RETURN l_retval;
    END get_encounter_count;

    /*
    * Retrieve the number of follow up notes of an episode.
    *
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param o_time_spent     total time spent
    * @param o_time_unit      time spent unit measure
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    PROCEDURE time_spent
    (
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_time_spent OUT management_follow_up.time_spent%TYPE
    ) IS
        l_enc_count PLS_INTEGER;
    BEGIN
    
        -- determine if the episode has follow_up records
    
        l_enc_count := get_encounter_count(i_episode => i_episode);
    
        IF l_enc_count > 0
        THEN
            -- calculate the time spent
        
            SELECT SUM(time_spent)
              INTO o_time_spent
              FROM (SELECT decode(mfu.id_unit_time,
                                  g_id_unit_minutes,
                                  mfu.time_spent,
                                  pk_unit_measure.get_unit_mea_conversion(mfu.time_spent,
                                                                          mfu.id_unit_time,
                                                                          g_id_unit_minutes)) time_spent
                      FROM management_follow_up mfu
                     WHERE mfu.id_episode = i_episode
                       AND mfu.flg_status = pk_case_management.g_mfu_status_active);
        
        END IF;
    END time_spent;

    /*
    * Get total time spent description.
    *
    * @param i_lang           language identifier
    * @param i_time_spent     total time spent
    * @param i_time_unit      unit measure identifier
    *
    * @return                 total time spent description
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    FUNCTION get_time_spent_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_time_spent IN management_follow_up.time_spent%TYPE,
        i_time_unit  IN management_follow_up.id_unit_time%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_retval    pk_translation.t_desc_translation;
        l_desc_unit pk_translation.t_desc_translation;
    BEGIN
        IF i_time_unit IS NOT NULL
        THEN
            g_error := 'SELECT l_desc_unit';
            SELECT nvl(pk_translation.get_translation(i_lang, u.code_unit_measure),
                       pk_translation.get_translation(i_lang, u.code_unit_measure_abrv))
              INTO l_desc_unit
              FROM unit_measure u
             WHERE u.id_unit_measure = i_time_unit;
        
            l_retval := CASE
                            WHEN i_time_spent < 1 THEN
                             '0'
                        END || i_time_spent || ' ' || l_desc_unit;
        END IF;
    
        RETURN l_retval;
    END get_time_spent_desc;

    /*
    * Retrieve the number of follow up notes of an episode.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    *
    * @return                 total time spent description
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    FUNCTION get_time_spent
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_time_spent management_follow_up.time_spent%TYPE;
        l_time_unit  management_follow_up.id_unit_time%TYPE;
    BEGIN
        g_error := 'CALL time_spent';
        time_spent(i_prof => i_prof, i_episode => i_episode, o_time_spent => l_time_spent);
    
        g_error := 'CALL get_time_spent_desc';
        RETURN get_time_spent_desc(i_lang => i_lang, i_time_spent => l_time_spent, i_time_unit => l_time_unit);
    END get_time_spent;

    /********************************************************************************************
    * Create parametrization values for Intervention plans
    *
    * @author                           Orlando Antunes
    * @version                          0.1
    * @since                            2010/03/25
    **********************************************************************************************/
    PROCEDURE set_interv_plan_dep_clin_serv
    (
        i_id_interv_plan   IN interv_plan_dep_clin_serv.id_interv_plan%TYPE,
        i_id_dep_clin_serv IN interv_plan_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_professional  IN interv_plan_dep_clin_serv.id_professional%TYPE,
        i_id_software      IN interv_plan_dep_clin_serv.id_software%TYPE,
        i_id_institution   IN interv_plan_dep_clin_serv.id_institution%TYPE,
        i_flg_available    IN interv_plan_dep_clin_serv.flg_available%TYPE,
        i_flg_type         IN interv_plan_dep_clin_serv.flg_type%TYPE
    ) IS
    BEGIN
        g_error := 'INSERT INTO set_interv_plan_dep_clin_serv';
        INSERT INTO interv_plan_dep_clin_serv
            (id_interv_plan, id_dep_clin_serv, id_professional, id_software, id_institution, flg_available, flg_type)
        VALUES
            (i_id_interv_plan,
             i_id_dep_clin_serv,
             i_id_professional,
             i_id_software,
             i_id_institution,
             i_flg_available,
             i_flg_type);
    END set_interv_plan_dep_clin_serv;
    --
    /*
    * Get the last registered next encounter date. Internal use only.
    * Made public to be used in SQL statements.
    *
    * @param i_episode        episode identifier
    *
    * @return                 last registered next encounter date.
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/25
    */
    FUNCTION get_dt_next_enc(i_episode IN episode.id_episode%TYPE) RETURN management_follow_up.dt_next_encounter%TYPE IS
        CURSOR c_mfu_dt_next_enc IS
            SELECT mfu.dt_next_encounter
              FROM management_follow_up mfu
             WHERE mfu.id_episode = i_episode
               AND mfu.flg_status = pk_case_management.g_mfu_status_active
             ORDER BY mfu.dt_register DESC;
    
        l_retval management_follow_up.dt_next_encounter%TYPE;
    BEGIN
        IF i_episode IS NOT NULL
        THEN
            OPEN c_mfu_dt_next_enc;
            FETCH c_mfu_dt_next_enc
                INTO l_retval;
            CLOSE c_mfu_dt_next_enc;
        END IF;
    
        RETURN l_retval;
    END get_dt_next_enc;

    /*
    * Build status string for social assistance requests. Internal use only.
    * Made public to be used in SQL statements.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_status         request status
    * @param i_dt_req         request date
    *
    * @return                 request status string
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION get_req_status_str
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_status IN opinion.flg_state%TYPE,
        i_dt_req IN opinion.dt_problem_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_retval       VARCHAR2(32767);
        l_display_type VARCHAR2(2 CHAR);
        l_value_date   sys_domain.code_domain%TYPE;
        l_value_icon   sys_domain.code_domain%TYPE;
        l_back_color   VARCHAR2(8 CHAR);
        l_icon_color   VARCHAR2(8 CHAR);
    BEGIN
        -- social assistance requests status string logic
        IF i_status IN (pk_opinion.g_opinion_req, pk_opinion.g_opinion_approved)
        THEN
            -- pending requests
            l_display_type := pk_alert_constant.g_display_type_date;
            l_value_date   := pk_date_utils.to_char_insttimezone(i_prof      => i_prof,
                                                                 i_timestamp => i_dt_req,
                                                                 i_mask      => pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
            l_value_icon   := NULL;
            l_back_color   := pk_alert_constant.g_color_red;
            l_icon_color   := pk_alert_constant.g_color_null;
        ELSE
            -- other request status
            l_display_type := pk_alert_constant.g_display_type_icon;
            l_value_date   := NULL;
            l_value_icon   := g_opinion_status_domain;
            l_back_color   := pk_alert_constant.g_color_null;
            l_icon_color   := pk_alert_constant.g_color_icon_medium_grey;
        END IF;
        -- generate status string
        l_retval := pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_display_type    => l_display_type,
                                                         i_flg_state       => i_status,
                                                         i_value_text      => NULL,
                                                         i_value_date      => l_value_date,
                                                         i_value_icon      => l_value_icon,
                                                         i_shortcut        => NULL,
                                                         i_back_color      => l_back_color,
                                                         i_icon_color      => l_icon_color,
                                                         i_message_style   => NULL,
                                                         i_message_color   => NULL,
                                                         i_flg_text_domain => pk_alert_constant.g_no);
        RETURN l_retval;
    END get_req_status_str;

    /*
    * Get data for the paramedical requests grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_show_all       'Y' to show all requests,
    *                         'N' to show my requests.
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.0.1
    * @since                  06-04-2010
    */
    FUNCTION get_paramedical_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_show_all IN VARCHAR2,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_today        TIMESTAMP WITH LOCAL TIME ZONE;
        l_type_opinion opinion_type.id_opinion_type%TYPE;
        l_category     category.id_category%TYPE;
        l_prof_cat     category.flg_type%TYPE;
        l_handoff_type sys_config.value%TYPE;
    
        CURSOR c_type_request IS
            SELECT ot.id_opinion_type
              FROM opinion_type ot
             WHERE ot.id_category = l_category;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_today        := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
    
        --l_type_opinion := pk_sysconfig.get_config('ID_OPINION_TYPE', i_prof);
    
        g_error    := 'GET PROF CATEGORY';
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'OPEN C_TYPE_REQUEST';
        OPEN c_type_request;
        FETCH c_type_request
            INTO l_type_opinion;
        CLOSE c_type_request;
    
        g_error := 'GET PROF CAT';
        pk_alertlog.log_info(text => g_error);
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET HANDOFF TYPE';
        pk_alertlog.log_info(text => g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        g_error := 'OPEN o_requests';
        OPEN o_requests FOR
            SELECT to_char(rownum, '00000') serv_rank,
                   dt.id_opinion,
                   nvl(dt.id_episode, id_episode_answer) id_episode,
                   dt.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, dt.id_patient, dt.id_episode, NULL) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, dt.id_patient, dt.id_episode) name_pat_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, dt.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, dt.id_patient) pat_nd_icon,
                   pk_patient.get_julian_age(i_lang, dt.dt_birth, dt.age) pat_age_for_order_by, -- campo para ordenação unicamente
                   (SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', dt.gender, i_lang)
                      FROM dual) gender,
                   pk_patient.get_pat_age(i_lang, dt.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, dt.id_patient, dt.id_episode, NULL) photo,
                   decode(dt.flg_auto_follow_up,
                          pk_alert_constant.get_yes,
                          pk_message.get_message(i_lang, 'COMMON_M036'),
                          pk_translation.get_translation(i_lang, dt.code_epis_type) || ' - ' ||
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           dt.id_professional,
                                                           dt.dt_last_update,
                                                           dt.id_episode_origin)) origin,
                   decode(dt.flg_auto_follow_up,
                          pk_alert_constant.get_yes,
                          '',
                          pk_prof_utils.get_name_signature(i_lang, i_prof, dt.id_professional)) origin_prof,
                   decode(dt.id_prof_resp,
                          NULL,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, dt.id_prof_questioned),
                          pk_prof_utils.get_name_signature(i_lang, i_prof, dt.id_prof_resp)) prof_answer,
                   decode(dt.flg_auto_follow_up,
                          pk_alert_constant.get_yes,
                          pk_message.get_message(i_lang, 'COMMON_M036'),
                          dt.desc_problem) reason,
                   pk_date_utils.date_char_hour_tsz(i_lang, dt.next_enc_tstz, i_prof.institution, i_prof.software) dt_next_hour,
                   pk_date_utils.dt_chr_tsz(i_lang, dt.next_enc_tstz, i_prof.institution, i_prof.software) dt_next_date,
                   pk_date_utils.date_send_tsz(i_lang, dt.next_enc_tstz, i_prof) dt_next_enc,
                   dt.next_enc_tstz,
                   dt.flg_state,
                   get_req_status_str(i_lang, i_prof, dt.flg_state, dt.dt_last_update) desc_status,
                   dt.id_department,
                   --pk_translation.get_translation(i_lang, dt.code_department) desc_department,
                   dt.desc_department,
                   dt.rank_department,
                   dt.id_room,
                   --pk_translation.get_translation(i_lang, dt.code_room) desc_room,
                   nvl(dt.desc_room_used, dt.desc_room) desc_room,
                   dt.rank_room,
                   dt.id_bed,
                   nvl(dt.desc_temp_bed, nvl(dt.desc_bed, pk_translation.get_translation(i_lang, dt.code_bed))) desc_bed,
                   dt.rank_bed,
                   pk_diagnosis.get_epis_diagnosis(i_lang, dt.id_episode_origin) diagnostic,
                   dt.show_triage,
                   decode(dt.show_triage, pk_alert_constant.g_yes, dt.acuity) acuity,
                   decode(dt.show_triage, pk_alert_constant.g_yes, dt.color_text) color_text,
                   decode(dt.show_triage, pk_alert_constant.g_yes, dt.rank_acuity) rank_acuity,
                   decode(dt.show_triage,
                          pk_alert_constant.g_yes,
                          pk_fast_track.get_fast_track_icon(i_lang,
                                                            i_prof,
                                                            dt.id_episode_origin,
                                                            dt.id_fast_track,
                                                            dt.id_triage_color,
                                                            decode(dt.has_transfer,
                                                                   0,
                                                                   pk_alert_constant.g_icon_ft,
                                                                   pk_alert_constant.g_icon_ft_transfer),
                                                            dt.has_transfer)) fast_track_icon,
                   decode(dt.show_triage,
                          pk_alert_constant.g_yes,
                          decode(dt.acuity,
                                 pk_alert_constant.g_ft_color,
                                 pk_alert_constant.g_ft_triage_white,
                                 pk_alert_constant.g_ft_color)) fast_track_color,
                   decode(dt.show_triage, pk_alert_constant.g_yes, pk_alert_constant.g_ft_status) fast_track_status,
                   decode(dt.show_triage,
                          pk_alert_constant.g_yes,
                          pk_fast_track.get_fast_track_desc(i_lang,
                                                            i_prof,
                                                            dt.id_fast_track,
                                                            pk_alert_constant.g_desc_grid)) fast_track_desc,
                   decode(dt.show_triage,
                          pk_alert_constant.g_yes,
                          pk_edis_triage.get_epis_esi_level(i_lang, i_prof, dt.id_episode_origin, dt.id_triage_color)) esi_level,
                   decode(dt.show_triage,
                          pk_alert_constant.g_yes,
                          pk_date_utils.date_send_tsz(i_lang, dt.dt_first_obs_tstz, i_prof)) dt_first_obs,
                   CASE
                        WHEN dt.flg_state IN (pk_opinion.g_opinion_req, pk_opinion.g_opinion_approved) THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END flg_action,
                   get_ok_active(i_lang, i_prof, dt.flg_state) flg_ok,
                   --discharge fields: to be used in the activity therapist
                   pk_inp_grid.get_discharge_msg(i_lang, i_prof, dt.id_episode_origin, NULL) discharge_desc,
                   pk_date_utils.dt_chr_tsz(i_lang, dt.dt_discharge, i_prof) discharge_date_desc,
                   --.dt_discharge,
                   pk_date_utils.date_send_tsz(i_lang, dt.dt_discharge, i_prof) dt_discharge,
                   -- supplies to return
                   pk_supplies_external_api_db.get_has_supplies_desc(i_lang, i_prof, dt.id_episode) return_desc,
                   -- responsable prof (requested to)
                   decode(dt.id_prof_answer,
                          NULL,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, dt.id_prof_questioned),
                          pk_prof_utils.get_name_signature(i_lang, i_prof, dt.id_prof_answer)) resp_prof_name,
                   decode(dt.id_prof_answer,
                          NULL,
                          decode(dt.id_prof_questioned,
                                 NULL,
                                 NULL,
                                 pk_message.get_message(i_lang, pk_act_therap_constant.g_msg_requested_to)),
                          NULL) responsable_desc,
                   dt.id_episode_origin,
                   pk_alert_constant.g_no flg_needs_approval,
                   decode(pk_prof_follow.get_follow_opinion_by_me(i_prof, dt.id_opinion),
                          pk_alert_constant.g_no,
                          decode(dt.id_prof_resp, i_prof.id, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                          pk_alert_constant.g_no) prof_follow_add,
                   decode(pk_prof_follow.get_follow_opinion_by_me(i_prof, dt.id_opinion),
                          pk_alert_constant.g_yes,
                          decode(dt.id_prof_resp, i_prof.id, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                          pk_alert_constant.g_no) prof_follow_remove
              FROM (SELECT o.id_opinion,
                           o.flg_auto_follow_up,
                           e.id_episode,
                           eo.id_patient,
                           eo.id_epis_type,
                           et.code_epis_type,
                           p.gender,
                           p.dt_birth,
                           p.age,
                           o.id_prof_questions id_professional,
                           o.dt_last_update,
                           o.id_episode id_episode_origin,
                           eid.id_professional id_prof_answer,
                           o.desc_problem,
                           get_dt_next_enc(e.id_episode) next_enc_tstz,
                           o.flg_state,
                           dep.id_department,
                           dep.code_department,
                           dep.rank rank_department,
                           pk_translation.get_translation(i_lang, dep.code_department) desc_department,
                           r.id_room,
                           r.code_room,
                           r.rank rank_room,
                           pk_translation.get_translation(i_lang, r.code_room) desc_room,
                           b.id_bed,
                           b.code_bed,
                           decode(b.flg_type, pk_bmng_constant.g_bmng_bed_flg_type_t, b.desc_bed) desc_temp_bed,
                           pk_translation.get_translation(i_lang, b.code_bed) bed_desc,
                           b.rank rank_bed,
                           decode(eo.id_epis_type,
                                  pk_alert_constant.g_epis_type_emergency,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) show_triage,
                           ei.triage_acuity acuity,
                           ei.triage_color_text color_text,
                           ei.triage_rank_acuity rank_acuity,
                           ei.id_triage_color,
                           eo.id_fast_track,
                           pk_transfer_institution.check_epis_transfer(eo.id_episode) has_transfer,
                           ei.dt_first_obs_tstz,
                           o.flg_type,
                           o.id_prof_questioned,
                           o.dt_approved,
                           pk_discharge.get_discharge_date(i_lang, i_prof, o.id_episode) dt_discharge,
                           b.desc_bed,
                           r.desc_room desc_room_used,
                           eo.id_episode id_episode_answer,
                           op.id_professional id_prof_resp
                      FROM opinion o
                      JOIN episode eo
                        ON o.id_episode = eo.id_episode
                      JOIN patient p
                        ON eo.id_patient = p.id_patient
                      JOIN epis_type et
                        ON eo.id_epis_type = et.id_epis_type
                      JOIN epis_info ei
                        ON eo.id_episode = ei.id_episode
                      LEFT JOIN opinion_prof op
                        ON o.id_opinion = op.id_opinion
                       AND op.flg_type IN (pk_opinion.g_opinion_prof_accept, pk_opinion.g_opinion_prof_reject)
                      LEFT JOIN episode e
                        ON o.id_episode_answer = e.id_episode
                      LEFT JOIN epis_info eid
                        ON e.id_episode = eid.id_episode
                      LEFT JOIN bed b
                        ON ei.id_bed = b.id_bed
                       AND b.flg_available = pk_alert_constant.g_yes
                      LEFT JOIN room r
                        ON r.id_room = b.id_room
                       AND r.flg_available = pk_alert_constant.g_yes
                      LEFT JOIN department dep
                        ON dep.id_department = r.id_department
                       AND dep.flg_available = pk_alert_constant.g_yes
                      LEFT JOIN discharge d
                        ON e.id_episode = d.id_episode
                       AND d.flg_status = pk_alert_constant.g_active
                     WHERE eo.id_institution = i_prof.institution
                       AND o.id_opinion_type = l_type_opinion
                       AND (i_show_all = pk_alert_constant.g_yes OR
                           (i_prof.id IN (op.id_professional, o.id_prof_questioned) OR
                           pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                              i_prof,
                                                                                              eid.id_episode,
                                                                                              l_prof_cat,
                                                                                              l_handoff_type),
                                                          i_prof.id) != -1 OR
                           (pk_prof_follow.get_follow_opinion_by_me(i_prof, o.id_opinion) = pk_alert_constant.g_yes)))
                       AND (o.flg_state IN (pk_opinion.g_opinion_accepted, pk_opinion.g_opinion_approved) OR
                           (o.flg_state = pk_opinion.g_opinion_req AND
                           pk_opinion.check_approval_need(profissional(o.id_prof_questions,
                                                                         eo.id_institution,
                                                                         decode(l_type_opinion,
                                                                                pk_act_therap_constant.g_at_opinion_type,
                                                                                i_prof.software,
                                                                                ei.id_software)),
                                                            l_type_opinion) = pk_alert_constant.g_no) OR
                           (o.flg_state = pk_opinion.g_opinion_rejected AND op.dt_opinion_prof_tstz > l_today) OR
                           (o.flg_state = pk_opinion.g_opinion_over AND
                           ((d.dt_med_tstz > l_today OR op.dt_opinion_prof_tstz > l_today) OR
                           (l_type_opinion = pk_act_therap_constant.g_at_opinion_type AND d.dt_med_tstz IS NULL AND
                           (SELECT dis.dt_med_tstz
                                  FROM discharge dis
                                 WHERE dis.id_episode = eo.id_episode
                                   AND dis.flg_status = pk_alert_constant.g_active) > l_today))))
                     ORDER BY rank_department, desc_department, rank_room, desc_room, rank_bed, bed_desc) dt
             ORDER BY decode(dt.flg_state,
                             pk_opinion.g_opinion_req,
                             1,
                             pk_opinion.g_opinion_approved,
                             1,
                             pk_opinion.g_opinion_accepted,
                             2,
                             pk_opinion.g_opinion_rejected,
                             3,
                             pk_opinion.g_opinion_over,
                             4),
                      dt.dt_last_update;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PARAMEDICAL_REQUESTS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
    END get_paramedical_requests;

    /********************************************************************************************
    * Get all parametrizations for the paramedical professional
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_parametrizations List with all parametrizations  (name/value)
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/19
    **********************************************************************************************/
    FUNCTION get_paramedical_param
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_paramedical_param OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_configs CONSTANT table_varchar := table_varchar('SUMMARY_VIEW_ALL',
                                                          'GRID_NAVIGATION',
                                                          'PARAMEDICAL_REQUESTS_SHOW_PATIENT_AREA');
    BEGIN
        RETURN pk_sysconfig.get_config(l_configs, i_prof, o_paramedical_param);
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_paramedical_param);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_PARAMEDICAL_PARAM',
                                                     o_error);
    END get_paramedical_param;

    /********************************************************************************************
    * Get the task/goal description based on i_id_task_goal_det
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_task_goal_det       Identifier of the task/goal defined within the scope
    *
    * @return                         description of the task/goal
    *
    * @author                          João Almeida
    * @version                         0.1
    * @since                           2010/04/08
    **********************************************************************************************/
    FUNCTION get_task_goal_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_task_goal_det IN task_goal_det.id_task_goal_det%TYPE
        
    ) RETURN VARCHAR2 IS
        --cursor to hold the information regardless if it's a free text or coded task/goal
        --if there is no id_task_goal (coded task/goal) the cursor will return only the free
        --text description entered by the user
        CURSOR c_task_goal_det IS
            SELECT tgd.id_task_goal, tgd.desc_task_goal, tg.code_task_goal
              FROM task_goal_det tgd
              LEFT JOIN task_goal tg
                ON tgd.id_task_goal = tg.id_task_goal
             WHERE tgd.id_task_goal_det = i_id_task_goal_det;
    
        l_id_task_goal   task_goal_det.id_task_goal%TYPE;
        l_desc_task_goal task_goal_det.desc_task_goal%TYPE;
        l_code_task_goal task_goal.code_task_goal%TYPE;
    
    BEGIN
    
        OPEN c_task_goal_det;
    
        FETCH c_task_goal_det
            INTO l_id_task_goal, l_desc_task_goal, l_code_task_goal;
    
        CLOSE c_task_goal_det;
    
        --check if it's a coded task/goal or not
        IF l_id_task_goal IS NOT NULL
        THEN
            RETURN pk_translation.get_translation(i_lang => i_lang, i_code_mess => l_code_task_goal);
        ELSE
            RETURN l_desc_task_goal;
        END IF;
    
    EXCEPTION
    
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_task_goal_desc;

    /********************************************************************************************
    * Get the task/goal id based on i_id_task_goal_det
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_task_goal_det       Identifier of the task/goal defined within the scope
    *
    * @return                         id of the task/goal
    *
    * @author                          João Almeida
    * @version                         0.1
    * @since                           2010/04/08
    **********************************************************************************************/
    FUNCTION get_id_task_goal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_task_goal_det IN task_goal_det.id_task_goal_det%TYPE
        
    ) RETURN NUMBER IS
        --cursor to hold the information regardless if it's a free text or coded task/goal
        --if there is no id_task_goal (coded task/goal) the cursor will return only the free
        --text description entered by the user
        CURSOR c_task_goal_det IS
            SELECT tgd.id_task_goal
              FROM task_goal_det tgd
              LEFT JOIN task_goal tg
                ON tgd.id_task_goal = tg.id_task_goal
             WHERE tgd.id_task_goal_det = i_id_task_goal_det;
    
        l_id_task_goal task_goal_det.id_task_goal%TYPE;
    
    BEGIN
    
        OPEN c_task_goal_det;
    
        FETCH c_task_goal_det
            INTO l_id_task_goal;
    
        CLOSE c_task_goal_det;
    
        RETURN l_id_task_goal;
    
    EXCEPTION
    
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_id_task_goal;

    /********************************************************************************************
    * Get the task/goal for the specific intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_interv_plan         Intervention Plan array
    *
    * @param o_task_goal              list of task/goal defined for the specific intervention plan
    * @return                         TRUE/FALSE
    *
    * @author                          João Almeida
    * @version                         0.1
    * @since
    **********************************************************************************************/
    FUNCTION get_task_goal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_interv_plan IN table_number,
        o_task_goal      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Open task_goal';
        OPEN o_task_goal FOR
            SELECT tg.id_task_goal data, pk_translation.get_translation(i_lang, tg.code_task_goal) label
              FROM task_goal tg, task_goal_task tgt
              JOIN (SELECT column_value
                      FROM TABLE(i_id_interv_plan)) i
                ON tgt.id_interv_plan = i.column_value
             WHERE tg.id_task_goal = tgt.id_task_goal
                  
               AND tgt.id_institution IN (i_prof.institution, 0)
               AND tgt.id_software IN (i_prof.software, 0)
               AND tgt.flg_available = pk_alert_constant.g_yes
            
             GROUP BY tg.id_task_goal, pk_translation.get_translation(i_lang, tg.code_task_goal)
            HAVING COUNT(tg.id_task_goal) >= (SELECT COUNT(*)
                                                FROM TABLE(i_id_interv_plan));
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TASK_GOAL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_task_goal);
            RETURN FALSE;
        
    END get_task_goal;

    /********************************************************************************************
    * Get all parametrizations for the paramedical professional
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_parametrizations List with all parametrizations  (name/value)
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Elisabete Bugalho
    * @version                         0.1
    * @since                          12-04-2010
    **********************************************************************************************/
    FUNCTION get_parametrizations
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_configs           IN table_varchar,
        o_paramedical_param OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_sysconfig.get_config(i_configs, i_prof, o_paramedical_param);
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_paramedical_param);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_PARAMEDICAL_PARAM',
                                                     o_error);
    END get_parametrizations;

    /*
    * Checks if the current environment is of an hospital, through the
    * logged professional's profile template.
    *
    * @param i_prof           logged professional structure
    *
    * @returns                'Y', if under an hospital environment, or 'N' otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/18
    * @change                 Elisabete Bugalho
    */
    FUNCTION check_hospital_profile(i_prof IN profissional) RETURN VARCHAR2 IS
        l_ret     VARCHAR2(1 CHAR);
        l_this_pt profile_template.id_profile_template%TYPE;
    BEGIN
        l_this_pt := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        IF l_this_pt NOT IN (pk_social.g_non_hospital_sw_pt, pk_diet.g_non_hospital_nutr_pt)
        THEN
            l_ret := pk_alert_constant.g_yes;
        ELSE
            l_ret := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ret;
    END check_hospital_profile;

    /*
    * Set discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_prof_cat       logged professional category
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_dt_end         discharge date
    * @param i_disch_dest     discharge reason destiny identifier
    * @param i_notes          discharge notes_med
    * @param i_print_report   print report?
    * @param o_reports_pat    report to print
    * @param o_flg_show       warm
    * @param o_msg_title      warn
    * @param o_msg_text       warn
    * @param o_button         warn
    * @param o_id_episode     created episode identifier
    * @param o_discharge      created discharge identifier
    * @param o_disch_detail   created discharge_detail identifier
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error message
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION set_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_cat         IN category.flg_type%TYPE,
        i_discharge        IN discharge.id_discharge%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_dt_end           IN VARCHAR2,
        i_disch_dest       IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_notes            IN discharge.notes_med%TYPE,
        i_time_spent       IN discharge_detail.total_time_spent%TYPE,
        i_unit_measure     IN discharge_detail.id_unit_measure%TYPE,
        i_print_report     IN discharge_detail.flg_print_report%TYPE,
        i_flg_type_closure IN discharge_detail.flg_type_closure%TYPE,
        o_reports_pat      OUT reports.id_reports%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_discharge        OUT discharge.id_discharge%TYPE,
        o_disch_detail     OUT discharge_detail.id_discharge_detail%TYPE,
        o_disch_hist       OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist   OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_request_info IS
            SELECT o.id_opinion
              FROM opinion o
             WHERE o.id_episode = i_episode;
    
        CURSOR c_request_info_old IS
            SELECT o.id_opinion
              FROM opinion o
             WHERE o.id_episode_answer = i_episode;
    
        l_transaction  VARCHAR2(4000);
        l_opinion_hist opinion_hist.id_opinion_hist%TYPE;
        l_opinion      opinion.id_opinion%TYPE;
        l_epis_type    episode.id_epis_type%TYPE;
    BEGIN
        g_error       := 'CALL pk_schedule_api_upstream.begin_new_transaction';
        l_transaction := pk_schedule_api_upstream.begin_new_transaction(l_transaction, i_prof);
    
        l_epis_type := pk_episode.get_epis_type(i_lang, i_episode);
    
        IF (l_epis_type IN (pk_alert_constant.g_epis_type_social,
                            pk_alert_constant.g_epis_type_dietitian,
                            pk_alert_constant.g_epis_type_psychologist,
                            pk_alert_constant.g_epis_type_resp_therapist,
                            pk_alert_constant.g_epis_type_cdc_appointment,
                            pk_alert_constant.g_epis_type_home_health_care) OR
           i_prof.software IN (pk_alert_constant.g_soft_act_therapist))
        THEN
            -- set discharge
            g_error := 'CALL pk_discharge_amb.set_discharge';
            IF NOT pk_discharge_amb.set_discharge(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_prof_cat         => i_prof_cat,
                                                  i_discharge        => i_discharge,
                                                  i_episode          => i_episode,
                                                  i_dt_end           => i_dt_end,
                                                  i_disch_dest       => i_disch_dest,
                                                  i_notes            => i_notes,
                                                  i_time_spent       => i_time_spent,
                                                  i_unit_measure     => i_unit_measure,
                                                  i_print_report     => i_print_report,
                                                  i_transaction      => l_transaction,
                                                  i_flg_type_closure => i_flg_type_closure,
                                                  o_reports_pat      => o_reports_pat,
                                                  o_flg_show         => o_flg_show,
                                                  o_msg_title        => o_msg_title,
                                                  o_msg_text         => o_msg_text,
                                                  o_button           => o_button,
                                                  o_id_episode       => o_id_episode,
                                                  o_discharge        => o_discharge,
                                                  o_disch_detail     => o_disch_detail,
                                                  o_disch_hist       => o_disch_hist,
                                                  o_disch_det_hist   => o_disch_det_hist,
                                                  o_error            => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
            -- get request information
            g_error := 'OPEN c_request_info';
            OPEN c_request_info_old;
            FETCH c_request_info_old
                INTO l_opinion;
            g_found := c_request_info_old%FOUND;
            CLOSE c_request_info_old;
        ELSE
            -- get request information
            g_error := 'OPEN c_request_info';
            OPEN c_request_info;
            FETCH c_request_info
                INTO l_opinion;
            g_found := c_request_info%FOUND;
            CLOSE c_request_info;
        END IF;
    
        IF g_found
        THEN
            g_error := 'CALL pk_opinion_pc.set_consult_request_state';
            IF NOT pk_opinion.set_consult_request_state(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_opinion      => l_opinion,
                                                        i_state        => pk_opinion.g_opinion_over,
                                                        o_opinion_hist => l_opinion_hist,
                                                        o_error        => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction, i_prof);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE',
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_discharge;

    /*
    * Cancels a discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_cancel_reason  cancel reason identifier
    * @param i_cancel_notes   cancel notes
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION set_discharge_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes   IN discharge.notes_cancel%TYPE,
        o_disch_hist     OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction VARCHAR2(4000);
        CURSOR c_request_info IS
            SELECT o.id_opinion
              FROM opinion o
             WHERE o.id_episode_answer = i_episode;
        l_opinion      opinion.id_opinion%TYPE;
        l_opinion_hist opinion_hist.id_opinion_hist%TYPE;
    BEGIN
        g_error       := 'CALL pk_schedule_api_upstream.begin_new_transaction';
        l_transaction := pk_schedule_api_upstream.begin_new_transaction(l_transaction, i_prof);
    
        -- cancel discharge
        g_error := 'CALL pk_discharge_amb.set_discharge_cancel';
        IF NOT pk_discharge_amb.set_discharge_cancel(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_discharge      => i_discharge,
                                                     i_cancel_reason  => i_cancel_reason,
                                                     i_cancel_notes   => i_cancel_notes,
                                                     i_transaction    => l_transaction,
                                                     o_disch_hist     => o_disch_hist,
                                                     o_disch_det_hist => o_disch_det_hist,
                                                     o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        -- get request information
        g_error := 'OPEN c_request_info';
        OPEN c_request_info;
        FETCH c_request_info
            INTO l_opinion;
        g_found := c_request_info%FOUND;
        CLOSE c_request_info;
    
        IF g_found
        THEN
            g_error := 'CALL pk_opinion.set_consult_request_state';
            IF NOT pk_opinion.set_consult_request_state(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_opinion      => l_opinion,
                                                        i_state        => pk_opinion.g_opinion_accepted,
                                                        i_set_oprof    => pk_alert_constant.g_no,
                                                        o_opinion_hist => l_opinion_hist,
                                                        o_error        => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction, i_prof);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE_CANCEL',
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_discharge_cancel;
    --

    /*********************************************************************
    * Returns a string with the last update information to be
    * used in the ehr summay.
    *
    * @ param i_lang               language identifier
    * @ param i_prof               professional information
    * @ param i_dt                 last update date
    * @ param i_id_prof_descr      professional ID that
    * @ param i_dt_prof_descr      last update date
    * @ param i_epis_prof_descr    last update episode
    *
    * @param o_error          error
    *
    * @return                 string with the last update information
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    *************************************************************************/
    FUNCTION get_ehr_last_update_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dt              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_descr   IN professional.id_professional%TYPE,
        i_dt_prof_descr   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_epis_prof_descr IN episode.id_episode%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_error                t_error_out;
        l_last_update          sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => 'PAST_HISTORY_M006');
        l_ehr_last_update_info VARCHAR2(1000 CHAR) := NULL;
    BEGIN
        g_error := 'GET_EHR_LAST_UPDATE_INFO - ' || g_package;
        pk_alertlog.log_debug(g_error);
    
        l_ehr_last_update_info := get_ehr_last_update_info(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_dt              => i_dt,
                                                           i_id_prof_descr   => i_id_prof_descr,
                                                           i_dt_prof_descr   => i_dt_prof_descr,
                                                           i_epis_prof_descr => i_epis_prof_descr,
                                                           i_start_message   => l_last_update);
    
        RETURN l_ehr_last_update_info;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package,
                                              g_package,
                                              'GET_EHR_LAST_UPDATE_INFO',
                                              l_error);
            RETURN NULL;
    END get_ehr_last_update_info;
    --

    /*********************************************************************
    * Returns a string with the last update information to be
    * used in the ehr summay.
    *
    * @ param i_lang               language identifier
    * @ param i_prof               professional information
    * @ param i_dt                 last update date
    * @ param i_id_prof_descr      professional ID that
    * @ param i_dt_prof_descr      last update date
    * @ param i_epis_prof_descr    last update episode
    *
    * @param o_error          error
    *
    * @return                 string with the last update information
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    *
    * UPDATED: included the possibility to include different messages
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  23-Jun-2010
    *************************************************************************/
    FUNCTION get_ehr_last_update_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dt              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_descr   IN professional.id_professional%TYPE,
        i_dt_prof_descr   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_epis_prof_descr IN episode.id_episode%TYPE DEFAULT NULL,
        i_start_message   IN sys_message.desc_message%TYPE
    ) RETURN VARCHAR2 IS
    
        l_error t_error_out;
        --l_last_update          sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
        --                                                                               i_code_mess => 'PAST_HISTORY_M006');
        l_ehr_last_update_info VARCHAR2(1000 CHAR) := NULL;
    BEGIN
        g_error := 'GET_EHR_LAST_UPDATE_INFO - ' || g_package;
        pk_alertlog.log_debug(g_error);
    
        l_ehr_last_update_info := '<i>(' || i_start_message || ': ' ||
                                  pk_tools.get_prof_description_cat(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_prof_id => i_id_prof_descr,
                                                                    i_date    => i_dt_prof_descr,
                                                                    i_episode => i_epis_prof_descr) || '; ' ||
                                  pk_date_utils.dt_chr_date_hour_tsz(i_lang, i_dt, i_prof) || ')</i>';
    
        RETURN l_ehr_last_update_info;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package,
                                              g_package,
                                              'GET_EHR_LAST_UPDATE_INFO',
                                              l_error);
            RETURN NULL;
    END get_ehr_last_update_info;
    --

    /**********************************************************************************************
    * Listar todos os diagnósticos do episódio para usar nas summary pages
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis                   episode id
    * @param i_prof_cat_type          categoty of professional
    *
    * @param o_diagnosis              Informação relativa aos diagnósticos
    * @param o_diagnosis_prof         Informação relativa ao profissional que efectuou o registo
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Sérgio Santos
    * @version                        1.0
    * @since                          23-Mar-2010
    **********************************************************************************************/
    FUNCTION get_summ_page_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN table_number,
        o_diagnosis      OUT pk_types.cursor_type,
        o_diagnosis_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message_status     sys_message.code_message%TYPE := pk_message.get_message(i_lang,
                                                                                     i_prof,
                                                                                     'DIAGNOSIS_FINAL_T025') || ':';
        l_message_notes      sys_message.code_message%TYPE := pk_message.get_message(i_lang,
                                                                                     i_prof,
                                                                                     'DIAGNOSIS_DIFF_M006');
        l_message_spec_notes sys_message.code_message%TYPE := pk_message.get_message(i_lang,
                                                                                     i_prof,
                                                                                     'DIAGNOSIS_DIFF_M007');
    BEGIN
        g_error := 'OPEN O_LIST'; -- AM 14/11/2008
        OPEN o_diagnosis FOR
            SELECT id, id_episode, desc_diagnosis, desc_state, desc_gen_notes, desc_spec_notes, last_update_info
              FROM (SELECT ed.id_epis_diagnosis id,
                           ed.id_episode,
                           '<b>' || decode(ed.desc_epis_diagnosis,
                                           NULL,
                                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                      i_prof                => i_prof,
                                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                                      i_id_diagnosis        => d.id_diagnosis,
                                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                      i_code                => d.code_icd,
                                                                      i_flg_other           => d.flg_other,
                                                                      i_flg_std_diag        => ad.flg_icd9),
                                           ed.desc_epis_diagnosis) || '</b><br>' desc_diagnosis,
                           '<b>' || l_message_status || ' </b>' ||
                           nvl(pk_sysdomain.get_domain(g_epis_diag_status, ed.flg_status, i_lang),
                               pk_paramedical_prof_core.c_dashes) desc_state,
                           '<b>' || l_message_notes || ' </b>' ||
                           nvl(pk_diagnosis_core.get_epis_diag_note(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_episode        => ed.id_episode,
                                                                    i_epis_diag      => ed.id_epis_diagnosis,
                                                                    i_epis_diag_hist => NULL),
                               pk_paramedical_prof_core.c_dashes) desc_gen_notes,
                           '<b>' || l_message_spec_notes || ' </b>' || nvl(ed.notes, pk_paramedical_prof_core.c_dashes) desc_spec_notes,
                           pk_date_utils.date_send_tsz(i_lang,
                                                       decode(ed.flg_status,
                                                              g_ed_flg_status_d,
                                                              ed.dt_epis_diagnosis_tstz,
                                                              g_ed_flg_status_co,
                                                              ed.dt_confirmed_tstz,
                                                              g_ed_flg_status_ca,
                                                              ed.dt_cancel_tstz,
                                                              g_ed_flg_status_b,
                                                              ed.dt_base_tstz,
                                                              ed.dt_rulled_out_tstz),
                                                       i_prof) date_order,
                           pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                             i_prof,
                                                                             decode(ed.flg_status,
                                                                                    g_ed_flg_status_d,
                                                                                    ed.dt_epis_diagnosis_tstz,
                                                                                    g_ed_flg_status_co,
                                                                                    ed.dt_confirmed_tstz,
                                                                                    g_ed_flg_status_ca,
                                                                                    ed.dt_cancel_tstz,
                                                                                    g_ed_flg_status_b,
                                                                                    ed.dt_base_tstz,
                                                                                    ed.dt_rulled_out_tstz),
                                                                             nvl(ed.id_prof_rulled_out,
                                                                                 nvl(ed.id_prof_confirmed,
                                                                                     nvl(ed.id_professional_cancel,
                                                                                         ed.id_professional_diag))),
                                                                             NULL,
                                                                             ed.id_episode) last_update_info,
                           pk_sysdomain.get_rank(i_lang, g_epis_diag_status, ed.flg_status) rank
                      FROM epis_diagnosis ed, diagnosis d, alert_diagnosis ad
                     WHERE ed.id_episode IN (SELECT /*+dynamic_sampling(t 2)*/
                                              t.column_value id_episode
                                               FROM TABLE(i_epis) t)
                       AND d.id_diagnosis = ed.id_diagnosis
                       AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                       AND ed.flg_type IN (g_diag_type_p, g_diag_type_b)
                       AND ed.flg_status IN (pk_diagnosis.g_ed_flg_status_d, pk_diagnosis.g_ed_flg_status_co)
                     ORDER BY rank, date_order DESC);
    
        OPEN o_diagnosis_prof FOR
            SELECT ed.id_epis_diagnosis id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      decode(ed.flg_status,
                                                             g_ed_flg_status_d,
                                                             ed.dt_epis_diagnosis_tstz,
                                                             g_ed_flg_status_co,
                                                             ed.dt_confirmed_tstz,
                                                             g_ed_flg_status_ca,
                                                             ed.dt_cancel_tstz,
                                                             g_ed_flg_status_b,
                                                             ed.dt_base_tstz,
                                                             ed.dt_rulled_out_tstz),
                                                      i_prof) dt,
                   pk_tools.get_prof_description(i_lang,
                                                 i_prof,
                                                 nvl(ed.id_prof_rulled_out,
                                                     nvl(ed.id_prof_confirmed,
                                                         nvl(ed.id_professional_cancel, ed.id_professional_diag))),
                                                 NULL,
                                                 ed.id_episode) prof_sign,
                   ed.flg_status,
                   NULL desc_status,
                   decode(ed.flg_status,
                          pk_diagnosis.g_ed_flg_status_ca,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_cancel,
                   decode(ed.flg_status,
                          pk_diagnosis.g_ed_flg_status_ca,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_action,
                   pk_date_utils.date_send_tsz(i_lang,
                                               decode(ed.flg_status,
                                                      g_ed_flg_status_d,
                                                      ed.dt_epis_diagnosis_tstz,
                                                      g_ed_flg_status_co,
                                                      ed.dt_confirmed_tstz,
                                                      g_ed_flg_status_ca,
                                                      ed.dt_cancel_tstz,
                                                      g_ed_flg_status_b,
                                                      ed.dt_base_tstz,
                                                      ed.dt_rulled_out_tstz),
                                               i_prof) date_order
              FROM epis_diagnosis ed, diagnosis d, alert_diagnosis ad
             WHERE ed.id_episode IN (SELECT /*+dynamic_sampling(t 2)*/
                                      t.column_value id_episode
                                       FROM TABLE(i_epis) t)
               AND d.id_diagnosis = ed.id_diagnosis
               AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
               AND ed.flg_type IN (g_diag_type_p, g_diag_type_b)
               AND ed.flg_status IN (pk_diagnosis.g_ed_flg_status_d, pk_diagnosis.g_ed_flg_status_co)
             ORDER BY pk_sysdomain.get_rank(i_lang, g_epis_diag_status, ed.flg_status), date_order DESC;
    
        pk_backoffice_translation.set_read_translation(g_epis_diag_status, 'SYS_DOMAIN');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_SUMM_PAGE_DIAG',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_summ_page_diag;

    /**
    * Get the diagnoses list for the summary screen
    * (implementation of get_summ_page_diag for the Reports layer).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_epis         list of episodes
    * @param o_diagnosis    diagnoses
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/12
    */
    PROCEDURE get_summ_page_diag_rep
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN table_number,
        o_diagnosis OUT pk_types.cursor_type
    ) IS
        l_message_status     sys_message.code_message%TYPE := pk_message.get_message(i_lang,
                                                                                     i_prof,
                                                                                     'DIAGNOSIS_DIFF_M001');
        l_message_notes      sys_message.code_message%TYPE := pk_message.get_message(i_lang,
                                                                                     i_prof,
                                                                                     'DIAGNOSIS_DIFF_M006');
        l_message_spec_notes sys_message.code_message%TYPE := pk_message.get_message(i_lang,
                                                                                     i_prof,
                                                                                     'DIAGNOSIS_DIFF_M007');
        l_message_last_upd   sys_message.code_message%TYPE := pk_message.get_message(i_lang,
                                                                                     i_prof,
                                                                                     'PAST_HISTORY_M006');
    BEGIN
        g_error := 'OPEN o_diagnosis';
        OPEN o_diagnosis FOR
            SELECT d.id_epis_diagnosis id,
                   d.id_episode,
                   nvl(d.desc_epis_diagnosis,
                       pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_alert_diagnosis  => d.id_alert_diagnosis,
                                                  i_id_diagnosis        => d.id_diagnosis,
                                                  i_desc_epis_diagnosis => d.desc_epis_diagnosis,
                                                  i_code                => d.code_icd,
                                                  i_flg_other           => d.flg_other,
                                                  i_flg_std_diag        => d.flg_icd9)) desc_diagnosis,
                   l_message_status lbl_state,
                   d.desc_state,
                   l_message_notes lbl_gen_notes,
                   pk_diagnosis_core.get_epis_diag_note(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => d.id_episode,
                                                        i_epis_diag      => d.id_epis_diagnosis,
                                                        i_epis_diag_hist => NULL) desc_gen_notes,
                   l_message_spec_notes lbl_spec_notes,
                   d.notes desc_spec_notes,
                   l_message_last_upd lbl_last_upd,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, d.id_prof) desc_prof_last_upd,
                   pk_prof_utils.get_desc_category(i_lang, i_prof, d.id_prof, i_prof.institution) desc_cat_last_upd,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, d.dt_last_upd, i_prof) desc_dt_last_upd,
                   pk_date_utils.date_send_tsz(i_lang, d.dt_last_upd, i_prof) serial_dt_last_upd
              FROM (SELECT ed.id_epis_diagnosis,
                           ed.id_episode,
                           ed.desc_epis_diagnosis,
                           ed.notes,
                           coalesce(ed.id_prof_rulled_out,
                                    ed.id_prof_confirmed,
                                    ed.id_professional_cancel,
                                    ed.id_professional_diag) id_prof,
                           decode(ed.flg_status,
                                  g_ed_flg_status_d,
                                  ed.dt_epis_diagnosis_tstz,
                                  g_ed_flg_status_co,
                                  ed.dt_confirmed_tstz,
                                  g_ed_flg_status_ca,
                                  ed.dt_cancel_tstz,
                                  g_ed_flg_status_b,
                                  ed.dt_base_tstz,
                                  ed.dt_rulled_out_tstz) dt_last_upd,
                           d.id_diagnosis,
                           d.code_icd,
                           d.flg_other,
                           ad.id_alert_diagnosis,
                           ad.flg_icd9,
                           sd.desc_val desc_state
                      FROM epis_diagnosis ed, diagnosis d, sys_domain sd, alert_diagnosis ad
                     WHERE ed.id_episode IN (SELECT /*+dynamic_sampling(t 2)*/
                                              t.column_value id_episode
                                               FROM TABLE(i_epis) t)
                       AND d.id_diagnosis = ed.id_diagnosis
                       AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
                       AND ed.flg_type IN (g_diag_type_p, g_diag_type_b)
                       AND sd.id_language = i_lang
                       AND sd.code_domain = g_epis_diag_status
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.val = ed.flg_status
                       AND ed.flg_status IN (pk_diagnosis.g_ed_flg_status_d, pk_diagnosis.g_ed_flg_status_co)
                     ORDER BY sd.rank, dt_last_upd DESC) d;
    END get_summ_page_diag_rep;

    /*
    * Get list of follow up notes as string.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/21
    */
    FUNCTION get_followup_notes_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_follow_up    OUT NOCOPY CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_data_cursor  pk_types.cursor_type;
        l_prof_cursor  pk_types.cursor_type;
        l_rec_id       table_number := table_number();
        l_epis_id      table_number := table_number();
        l_epis_origin  table_number := table_number();
        l_notes        table_clob := table_clob();
        l_start_dt     table_varchar := table_varchar();
        l_time_spent   table_varchar := table_varchar();
        l_end_followup table_varchar := table_varchar();
        l_next_enc     table_varchar := table_varchar();
        l_last_update  table_varchar := table_varchar();
        l_desc_cancel  table_varchar := table_varchar();
        l_report_title VARCHAR2(100 CHAR);
    BEGIN
        l_report_title := format_str_header_bold(pk_message.get_message(i_lang      => i_lang,
                                                                        i_prof      => i_prof,
                                                                        i_code_mess => 'SOCIAL_T103'));
    
        g_error := 'CALL get_followup_notes';
        get_followup_notes_list(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_episode        => table_number(i_episode),
                                i_show_cancelled => pk_alert_constant.g_no,
                                o_follow_up_prof => l_prof_cursor,
                                o_follow_up      => l_data_cursor);
    
        g_error := 'CLOSE l_prof_cursor';
        CLOSE l_prof_cursor;
    
        g_error := 'FETCH l_data_cursor';
        FETCH l_data_cursor BULK COLLECT
            INTO l_rec_id,
                 l_epis_id,
                 l_epis_origin,
                 l_notes,
                 l_start_dt,
                 l_time_spent,
                 l_end_followup,
                 l_next_enc,
                 l_last_update,
                 l_desc_cancel;
        CLOSE l_data_cursor;
    
        IF l_rec_id IS NOT NULL
           AND l_rec_id.first IS NOT NULL
        THEN
            g_error := 'LOOP begin';
            FOR i IN l_rec_id.first .. l_rec_id.last
            LOOP
                o_follow_up := o_follow_up || l_notes(i) || g_break || l_start_dt(i) || g_break || l_time_spent(i) ||
                               g_break || l_next_enc(i) || g_break || l_last_update(i) || g_break || g_break;
            END LOOP;
        
            o_follow_up := l_report_title || g_break || g_break || o_follow_up;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_FOLLOWUP_NOTES_STR',
                                                     o_error    => o_error);
    END get_followup_notes_str;

    /*
    * Get list of paramedical service reports as string.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param o_report         paramedical reports
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/21
    */
    FUNCTION get_paramed_report_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_report       OUT NOCOPY CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_data_cursor pk_types.cursor_type;
        l_prof_cursor pk_types.cursor_type;
        l_rec_id      table_number := table_number();
        l_epis_id     table_number := table_number();
        l_text        table_clob := table_clob();
        l_last_update table_varchar := table_varchar();
    
        l_report_title sys_message.desc_message%TYPE;
    BEGIN
    
        IF i_opinion_type = pk_opinion.g_ot_dietitian
        THEN
            l_report_title := format_str_header_bold(pk_message.get_message(i_lang      => i_lang,
                                                                            i_prof      => i_prof,
                                                                            i_code_mess => 'DIET_T117'));
        ELSIF i_opinion_type = pk_opinion.g_ot_social_worker
        THEN
            l_report_title := format_str_header_bold(pk_message.get_message(i_lang      => i_lang,
                                                                            i_prof      => i_prof,
                                                                            i_code_mess => 'SOCIAL_T113'));
        ELSE
            l_report_title := NULL;
        END IF;
    
        g_error := 'CALL get_paramed_report_list';
        get_paramed_report_list(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_episode        => table_number(i_episode),
                                i_show_cancelled => pk_alert_constant.g_no,
                                o_report_prof    => l_prof_cursor,
                                o_report         => l_data_cursor);
    
        g_error := 'CLOSE l_prof_cursor';
        CLOSE l_prof_cursor;
    
        g_error := 'FETCH l_data_cursor';
        FETCH l_data_cursor BULK COLLECT
            INTO l_rec_id, l_epis_id, l_text, l_last_update;
        CLOSE l_data_cursor;
    
        IF l_rec_id IS NOT NULL
           AND l_rec_id.first IS NOT NULL
        THEN
            g_error := 'LOOP begin';
            FOR i IN l_rec_id.first .. l_rec_id.last
            LOOP
                o_report := o_report || l_text(i) || g_break || l_last_update(i) || g_break;
            END LOOP;
            o_report := l_report_title || g_break || g_break || o_report;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_PARAMED_REPORT_STR',
                                                     o_error    => o_error);
    END get_paramed_report_str;
    --

    /********************************************************************************************
    * Get the Diagnosis list, concatenated as a String (CLOB)
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = Social Worker)
    * @ param o_diagnosis_str         String with all the diagnosis information
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/04/21
    **********************************************************************************************/
    FUNCTION get_summ_page_diag_str
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_opinion_type  IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_diagnosis_str OUT NOCOPY CLOB,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_diagnosis pk_types.cursor_type;
        l_cur_dummy pk_types.cursor_type;
    
        --get_diagnosis
        l_id         table_number := table_number();
        l_id_episode table_number := table_number();
        --
        l_desc_diagnosis   table_varchar := table_varchar();
        l_desc_state       table_varchar := table_varchar();
        l_desc_gen_notes   table_varchar := table_varchar();
        l_desc_spec_notes  table_varchar := table_varchar();
        l_last_update_info table_varchar := table_varchar();
        ------------------------||--------------------------
    
        l_text_summary CLOB;
    
        l_diagnosis_title sys_message.desc_message%TYPE;
    BEGIN
        IF i_opinion_type = pk_opinion.g_ot_dietitian
        THEN
            l_diagnosis_title := format_str_header_bold(pk_message.get_message(i_lang      => i_lang,
                                                                               i_code_mess => 'DIET_T115'));
        ELSIF i_opinion_type = pk_opinion.g_ot_social_worker
        THEN
            l_diagnosis_title := format_str_header_bold(pk_message.get_message(i_lang      => i_lang,
                                                                               i_code_mess => 'PARAMEDICAL_T022'));
        ELSE
            l_diagnosis_title := NULL;
        END IF;
        --
        --get_all_summary_pages
        IF NOT pk_paramedical_prof_core.get_summ_page_diag(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_epis           => table_number(i_episode),
                                                           o_diagnosis      => l_diagnosis,
                                                           o_diagnosis_prof => l_cur_dummy,
                                                           o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        --
        FETCH l_diagnosis BULK COLLECT
            INTO l_id,
                 l_id_episode,
                 l_desc_diagnosis,
                 l_desc_state,
                 l_desc_gen_notes,
                 l_desc_spec_notes,
                 l_last_update_info;
        CLOSE l_diagnosis;
        CLOSE l_cur_dummy;
        --
        l_text_summary := '';
        FOR i IN 1 .. l_id.count
        LOOP
            l_text_summary := l_text_summary || chr(10) || l_desc_diagnosis(i) || chr(10) || l_desc_state(i) || chr(10) ||
                              l_desc_gen_notes(i) || chr(10) || l_desc_spec_notes(i) || chr(10) ||
                              l_last_update_info(i) || chr(10) || chr(10);
        END LOOP;
        --
        IF l_text_summary IS NOT NULL
        THEN
            --Diagnósticos:
            l_text_summary := l_diagnosis_title || chr(10) || l_text_summary || chr(10);
            --
        END IF;
    
        o_diagnosis_str := l_text_summary;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SUMM_PAGE_DIAG_STR',
                                                     o_error);
        
    END get_summ_page_diag_str;
    --

    /********************************************************************************************
    * Get the Intervention plans list, concatenated as a String (CLOB)
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = Social Worker)
    * @ param o_interv_plan_summ_str  String with all the intervention plans information
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/04/21
    **********************************************************************************************/
    FUNCTION get_interv_plan_summary_str
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_opinion_type         IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_interv_plan_summ_str OUT NOCOPY CLOB,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_inter_plan pk_types.cursor_type;
        l_cur_dummy  pk_types.cursor_type;
        --Interv_plans
        l_id         table_number := table_number();
        l_id_episode table_number := table_number();
        --
        l_desc_interv_plan table_varchar := table_varchar();
        l_desc_dt_begin    table_varchar := table_varchar();
        l_desc_dt_end      table_varchar := table_varchar();
        l_desc_diag        table_varchar := table_varchar();
        l_desc_notes       table_varchar := table_varchar();
        l_last_update_info table_varchar := table_varchar();
    
        l_text_summary CLOB;
    
        l_interv_plan_title sys_message.desc_message%TYPE;
    BEGIN
        IF i_opinion_type = pk_opinion.g_ot_social_worker
        THEN
            l_interv_plan_title := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => 'PARAMEDICAL_T005');
        ELSE
            l_interv_plan_title := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => 'PARAMEDICAL_T006');
        END IF;
        --
        IF NOT pk_paramedical_prof_core.get_interv_plan_summary(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_id_epis          => table_number(i_episode),
                                                                o_interv_plan      => l_inter_plan,
                                                                o_interv_plan_prof => l_cur_dummy,
                                                                o_error            => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        FETCH l_inter_plan BULK COLLECT
            INTO l_id,
                 l_id_episode,
                 l_desc_interv_plan,
                 l_desc_dt_begin,
                 l_desc_dt_end,
                 l_desc_diag,
                 l_desc_notes,
                 l_last_update_info;
        CLOSE l_inter_plan;
        CLOSE l_cur_dummy;
        --
        FOR i IN 1 .. l_id.count
        LOOP
            l_text_summary := l_text_summary || chr(10) || l_desc_interv_plan(i) || chr(10) || l_desc_dt_begin(i) ||
                              chr(10) || l_desc_dt_end(i) || chr(10) || l_desc_diag(i) || chr(10) || l_desc_notes(i) ||
                              chr(10) || l_last_update_info(i) || chr(10);
        END LOOP;
        --
    
        IF l_text_summary IS NOT NULL
        THEN
            --Intervention plans:
            l_text_summary := format_str_header_bold(l_interv_plan_title) || chr(10) || l_text_summary || chr(10);
            --
        END IF;
    
        o_interv_plan_summ_str := l_text_summary;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_SUMMARY_STR',
                                                     o_error);
        
    END get_interv_plan_summary_str;
    --

    /*
    * Get a follow up notes record history.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    PROCEDURE get_followup_notes_hist_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type
    ) IS
        l_notes_title           sys_message.desc_message%TYPE;
        l_start_dt_title        sys_message.desc_message%TYPE;
        l_time_title            sys_message.desc_message%TYPE;
        l_next_dt_title         sys_message.desc_message%TYPE;
        l_msg_oper_add          sys_message.desc_message%TYPE;
        l_msg_oper_edit         sys_message.desc_message%TYPE;
        l_msg_oper_canc         sys_message.desc_message%TYPE;
        l_canc_rea_title        sys_message.desc_message%TYPE;
        l_canc_not_title        sys_message.desc_message%TYPE;
        l_next_dt_enable        VARCHAR2(1 CHAR);
        l_notes_title_report    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T103');
        l_start_dt_title_report sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T104');
        l_time_title_report     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T105');
        l_next_dt_title_report  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T154');
        l_canc_rea_title_report sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M072');
        l_canc_not_title_report sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T109');
    
    BEGIN
        l_notes_title    := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T103'));
        l_start_dt_title := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T104'));
        l_time_title     := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T105'));
        l_next_dt_title  := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T154'));
        l_msg_oper_add   := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T107');
        l_msg_oper_edit  := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T108');
        l_msg_oper_canc  := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T109');
        l_canc_rea_title := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'COMMON_M072'));
        l_canc_not_title := format_str_header_w_colon(i_srt => pk_message.get_message(i_lang, i_prof, 'COMMON_M073'));
        l_next_dt_enable := check_hospital_profile(i_prof => i_prof);
    
        g_error := 'OPEN o_follow_up_prof_hist';
        OPEN o_follow_up_prof FOR
            SELECT mfu.id_management_follow_up id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_register, i_prof) dt,
                   pk_tools.get_prof_description(i_lang, i_prof, mfu.id_professional, mfu.dt_register, mfu.id_episode) prof_sign,
                   mfu.flg_status,
                   decode(mfu.id_parent,
                          NULL,
                          l_msg_oper_add,
                          decode(mfu.flg_status, pk_case_management.g_mfu_status_canc, l_msg_oper_canc, l_msg_oper_edit)) desc_status,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_cancel,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_action,
                   pk_date_utils.date_send_tsz(i_lang, mfu.dt_register, i_prof) dt_send,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, mfu.id_professional) prof_name_sign,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    mfu.id_professional,
                                                    mfu.dt_register,
                                                    mfu.id_episode) prof_spec_sign
            
              FROM management_follow_up mfu
            CONNECT BY PRIOR mfu.id_parent = mfu.id_management_follow_up
             START WITH mfu.id_management_follow_up = i_mng_followup;
    
        g_error := 'OPEN o_follow_up_hist';
        OPEN o_follow_up FOR
            SELECT mfu.id_management_follow_up id,
                   l_notes_title || mfu.notes desc_followup_notes,
                   l_start_dt_title || nvl2(mfu.dt_start,
                                            pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof),
                                            pk_paramedical_prof_core.c_dashes) desc_start_dt,
                   l_time_title ||
                   nvl(pk_paramedical_prof_core.get_format_time_spent(i_lang, mfu.time_spent, mfu.id_unit_time),
                       pk_paramedical_prof_core.c_dashes) desc_time_spent,
                   decode(l_next_dt_enable,
                          pk_alert_constant.g_yes,
                          l_next_dt_title || nvl2(mfu.dt_next_encounter,
                                                  get_partial_date_format(i_lang      => i_lang,
                                                                          i_prof      => i_prof,
                                                                          i_date      => mfu.dt_next_encounter,
                                                                          i_precision => mfu.dt_next_enc_precision),
                                                  pk_paramedical_prof_core.c_dashes)) desc_next_dt,
                   
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          l_canc_rea_title || pk_translation.get_translation(i_lang, cr.code_cancel_reason)) desc_cancel_reason,
                   decode(mfu.flg_status, pk_case_management.g_mfu_status_canc, l_canc_not_title || mfu.notes_cancel) desc_cancel_notes,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_message.get_message(i_lang, pk_act_therap_constant.g_msg_cancelled),
                          '') desc_cancel,
                   
                   l_notes_title_report label_followup_notes,
                   mfu.notes            info_followup_notes,
                   /*  l_end_followup_report label_end_followup,
                   nvl2(mfu.flg_end_followup,
                        pk_sysdomain.get_domain(pk_list.g_yes_no, mfu.flg_end_followup, i_lang),
                        pk_sysdomain.get_domain(pk_list.g_yes_no, pk_alert_constant.g_no, i_lang)) info_end_followup,
                   */
                   l_start_dt_title_report label_start_dt,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof) info_start_dt,
                   pk_date_utils.date_send_tsz(i_lang, mfu.dt_start, i_prof) info_start_dt_send,
                   l_time_title_report label_time_spent,
                   mfu.time_spent || ' ' ||
                   nvl(pk_translation.get_translation(i_lang, um.code_unit_measure),
                       pk_translation.get_translation(i_lang, um.code_unit_measure_abrv)) info_time_spent,
                   decode(l_next_dt_enable, pk_alert_constant.g_yes, l_next_dt_title_report) label_next_dt,
                   decode(l_next_dt_enable,
                          pk_alert_constant.g_yes,
                          get_partial_date_format(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_date      => mfu.dt_next_encounter,
                                                  i_precision => mfu.dt_next_enc_precision)) info_next_dt,
                   decode(l_next_dt_enable,
                          pk_alert_constant.g_yes,
                          pk_date_utils.date_send_tsz(i_lang, mfu.dt_next_encounter, i_prof)) info_next_dt_send,
                   decode(mfu.flg_status, pk_case_management.g_mfu_status_canc, l_canc_rea_title_report) label_cancel_reason,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_translation.get_translation(i_lang, cr.code_cancel_reason)) info_cancel_reason,
                   decode(mfu.flg_status, pk_case_management.g_mfu_status_canc, l_canc_not_title_report) label_cancel_notes,
                   decode(mfu.flg_status, pk_case_management.g_mfu_status_canc, mfu.notes_cancel) info_cancel_notes
              FROM management_follow_up mfu
              LEFT JOIN unit_measure um
                ON mfu.id_unit_time = um.id_unit_measure
              LEFT JOIN cancel_reason cr
                ON mfu.id_cancel_reason = cr.id_cancel_reason
            CONNECT BY PRIOR mfu.id_parent = mfu.id_management_follow_up
             START WITH mfu.id_management_follow_up = i_mng_followup
             ORDER BY mfu.dt_register DESC;
    END get_followup_notes_hist_report;
    /*
    * Get the follow up notes list for the given array of episodes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/15
    */
    PROCEDURE get_followup_notes_list_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_show_cancelled IN VARCHAR2,
        i_report         IN VARCHAR2 DEFAULT 'N',
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type
    ) IS
        l_notes_title_report    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T103');
        l_start_dt_title_report sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T104');
        l_time_title_report     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T105');
        l_next_dt_title_report  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T154');
        l_last_update_report    sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'PAST_HISTORY_M006');
        l_notes_title           sys_message.desc_message%TYPE;
        l_start_dt_title        sys_message.desc_message%TYPE;
        l_time_title            sys_message.desc_message%TYPE;
        l_next_dt_title         sys_message.desc_message%TYPE;
        l_next_dt_enable        VARCHAR2(1 CHAR);
    BEGIN
        l_notes_title    := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T103'),
                                                      i_is_report => i_report);
        l_start_dt_title := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T104'),
                                                      i_is_report => i_report);
        l_time_title     := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T105'),
                                                      i_is_report => i_report);
        l_next_dt_title  := format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'SOCIAL_T154'),
                                                      i_is_report => i_report);
        l_next_dt_enable := check_hospital_profile(i_prof => i_prof);
    
        g_error := 'OPEN o_follow_up_prof_list';
        OPEN o_follow_up_prof FOR
            SELECT mfu.id_management_follow_up id,
                   decode(mfu.id_parent,
                          NULL,
                          pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_register, i_prof),
                          (SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang, m.dt_register, i_prof)
                             FROM management_follow_up m
                            WHERE m.id_parent IS NULL
                           CONNECT BY PRIOR m.id_parent = m.id_management_follow_up
                            START WITH m.id_management_follow_up = mfu.id_management_follow_up)) dt,
                   decode(mfu.id_parent,
                          NULL,
                          pk_tools.get_prof_description(i_lang,
                                                        i_prof,
                                                        mfu.id_professional,
                                                        mfu.dt_register,
                                                        mfu.id_episode),
                          (SELECT pk_tools.get_prof_description(i_lang,
                                                                i_prof,
                                                                m.id_professional,
                                                                m.dt_register,
                                                                m.id_episode)
                             FROM management_follow_up m
                            WHERE m.id_parent IS NULL
                           CONNECT BY PRIOR m.id_parent = m.id_management_follow_up
                            START WITH m.id_management_follow_up = mfu.id_management_follow_up)) prof_sign,
                   mfu.flg_status,
                   NULL desc_status,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_cancel,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_action,
                   decode(mfu.id_parent,
                          NULL,
                          pk_date_utils.date_send_tsz(i_lang, mfu.dt_register, i_prof),
                          (SELECT pk_date_utils.date_send_tsz(i_lang, m.dt_register, i_prof)
                             FROM management_follow_up m
                            WHERE m.id_parent IS NULL
                           CONNECT BY PRIOR m.id_parent = m.id_management_follow_up
                            START WITH m.id_management_follow_up = mfu.id_management_follow_up)) dt_send,
                   decode(mfu.id_parent,
                          NULL,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, mfu.id_professional),
                          (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, m.id_professional)
                             FROM management_follow_up m
                            WHERE m.id_parent IS NULL
                           CONNECT BY PRIOR m.id_parent = m.id_management_follow_up
                            START WITH m.id_management_follow_up = mfu.id_management_follow_up)) prof_name_sign,
                   decode(mfu.id_parent,
                          NULL,
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           mfu.id_professional,
                                                           mfu.dt_register,
                                                           mfu.id_episode),
                          (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   m.id_professional,
                                                                   m.dt_register,
                                                                   m.id_episode)
                             FROM management_follow_up m
                            WHERE m.id_parent IS NULL
                           CONNECT BY PRIOR m.id_parent = m.id_management_follow_up
                            START WITH m.id_management_follow_up = mfu.id_management_follow_up)) prof_spec_sign
              FROM management_follow_up mfu
             WHERE mfu.id_episode IN (SELECT /*+dynamic_sampling(t 2)*/
                                       t.column_value id_episode
                                        FROM TABLE(i_episode) t)
               AND (mfu.flg_status = pk_case_management.g_mfu_status_active OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND
                   mfu.flg_status = pk_case_management.g_mfu_status_canc))
               AND (i_start_date IS NULL OR mfu.dt_register >= i_start_date)
               AND (i_end_date IS NULL OR mfu.dt_register <= i_end_date)
             ORDER BY decode(mfu.flg_status, pk_case_management.g_mnp_flg_status_c, 2, 1) ASC, mfu.dt_register DESC;
    
        g_error := 'OPEN o_follow_up_list';
        OPEN o_follow_up FOR
            SELECT mfu.id_management_follow_up id,
                   mfu.id_episode,
                   pk_activity_therapist.get_epis_parent(i_lang, i_prof, mfu.id_episode) id_episode_origin,
                   to_clob(l_notes_title || nvl(mfu.notes, pk_paramedical_prof_core.c_dashes)) desc_followup_notes,
                   l_start_dt_title || nvl2(mfu.dt_start,
                                            pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof),
                                            pk_paramedical_prof_core.c_dashes) desc_start_dt,
                   l_time_title ||
                   nvl(pk_paramedical_prof_core.get_format_time_spent(i_lang, mfu.time_spent, mfu.id_unit_time),
                       pk_paramedical_prof_core.c_dashes) desc_time_spent,
                   decode(l_next_dt_enable,
                          pk_alert_constant.g_yes,
                          l_next_dt_title || nvl2(mfu.dt_next_encounter,
                                                  get_partial_date_format(i_lang      => i_lang,
                                                                          i_prof      => i_prof,
                                                                          i_date      => mfu.dt_next_encounter,
                                                                          i_precision => mfu.dt_next_enc_precision),
                                                  
                                                  pk_paramedical_prof_core.c_dashes)) desc_next_dt,
                   get_ehr_last_update_info(i_lang, i_prof, mfu.dt_register, mfu.id_professional, mfu.dt_register) last_update_info,
                   decode(mfu.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_message.get_message(i_lang, pk_act_therap_constant.g_msg_cancelled),
                          '') desc_cancel,
                   l_notes_title_report label_followup_notes,
                   mfu.notes info_followup_notes,
                   l_start_dt_title_report label_start_dt,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof) info_start_dt,
                   pk_date_utils.date_send_tsz(i_lang, mfu.dt_start, i_prof) info_start_dt_send,
                   l_time_title_report label_time_spent,
                   mfu.time_spent || ' ' ||
                   nvl(pk_translation.get_translation(i_lang, um.code_unit_measure),
                       pk_translation.get_translation(i_lang, um.code_unit_measure_abrv)) info_time_spent,
                   decode(l_next_dt_enable, pk_alert_constant.g_yes, l_next_dt_title_report) label_next_dt,
                   decode(l_next_dt_enable,
                          pk_alert_constant.g_yes,
                          get_partial_date_format(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_date      => mfu.dt_next_encounter,
                                                  i_precision => mfu.dt_next_enc_precision)) info_next_dt,
                   decode(l_next_dt_enable,
                          pk_alert_constant.g_yes,
                          pk_date_utils.date_send_tsz(i_lang, mfu.dt_next_encounter, i_prof)) info_next_dt_send,
                   l_last_update_report label_last_update_info,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_register, i_prof) dt_last_update_info,
                   pk_date_utils.date_send_tsz(i_lang, mfu.dt_register, i_prof) dt_send_last_update_info,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, mfu.id_professional) prof_update_info,
                   pk_prof_utils.get_desc_category(i_lang, i_prof, mfu.id_professional, i_prof.institution) cat_last_update_info
              FROM management_follow_up mfu
              LEFT JOIN unit_measure um
                ON mfu.id_unit_time = um.id_unit_measure
             WHERE mfu.id_episode IN (SELECT /*+dynamic_sampling(t 2)*/
                                       t.column_value id_episode
                                        FROM TABLE(i_episode) t)
               AND (mfu.flg_status = pk_case_management.g_mfu_status_active OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND
                   mfu.flg_status = pk_case_management.g_mfu_status_canc))
               AND (i_start_date IS NULL OR mfu.dt_register >= i_start_date)
               AND (i_end_date IS NULL OR mfu.dt_register <= i_end_date)
             ORDER BY decode(mfu.flg_status, pk_case_management.g_mfu_status_canc, 2, 1) ASC, mfu.dt_register DESC;
    END get_followup_notes_list_report;
    /********************************************************************************************
    * Get the list of intervention plans for a patient episode for a list of episodes(i_id_epis).
    * The goal of this function is to return the data for the patient ehr
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               List of Episode IDs (Epis type = Social Worker)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN table_number,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('COMMON_M008',
                                                                                          'PARAMEDICAL_T003',
                                                                                          'SOCIAL_T124',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'PARAMEDICAL_T002'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        -- 
        g_error := 'OPEN LABELS CURSOR';
        OPEN o_screen_labels FOR
            SELECT t_table_message_array('PARAMEDICAL_T003') interv_plan_main_header,
                   t_table_message_array('SOCIAL_T124') interv_plan_column,
                   t_table_message_array('PARAMEDICAL_T002') task_goal_column,
                   t_table_message_array('SOCIAL_T104') dt_begin_column,
                   t_table_message_array('SOCIAL_T125') dt_end_column,
                   t_table_message_array('SOCIAL_T004') state_column
              FROM dual;
    
        --
        g_error := 'GET CURSOR ALL INTERVENTION';
        OPEN o_interv_plan FOR
            SELECT eip.id_epis_interv_plan id,
                   eip.id_interv_plan id_interv_plan,
                   CASE
                        WHEN eip.id_interv_plan = 0 THEN
                         eip.desc_other_interv_plan
                        WHEN eip.id_interv_plan IS NULL THEN
                         eip.desc_other_interv_plan
                        ELSE
                         pk_translation.get_translation(i_lang, ip.code_interv_plan)
                    END interv_plan_desc,
                   eip.id_task_goal_det,
                   get_task_goal_desc(i_lang, i_prof, eip.id_task_goal_det) desc_task_goal,
                   pk_tools.get_prof_description(i_lang, i_prof, eip.id_professional, eip.dt_begin, NULL) prof_sign,
                   pk_date_utils.dt_chr_tsz(i_lang, eip.dt_begin, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, eip.dt_begin, i_prof) dt_begin_str,
                   pk_date_utils.dt_chr_tsz(i_lang, eip.dt_end, i_prof) dt_end,
                   pk_date_utils.date_send_tsz(i_lang, eip.dt_end, i_prof) dt_end_str,
                   --We are not considering the actual state of the record!
                   decode(eip.notes,
                          NULL,
                          decode(pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, eip.id_cancel_info_det),
                                 NULL,
                                 NULL,
                                 '(' || t_table_message_array('COMMON_M008') || ')'),
                          
                          '(' || t_table_message_array('COMMON_M008') || ')') has_notes,
                   eip.notes notes,
                   eip.flg_status flg_status,
                   pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS',
                                           decode(eip.flg_status,
                                                  pk_alert_constant.g_flg_status_e,
                                                  pk_alert_constant.g_flg_status_a,
                                                  eip.flg_status),
                                           i_lang) desc_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eip.id_professional) prof_name_sign,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, eip.id_professional, eip.dt_begin, eip.id_episode) prof_spec_sign
              FROM epis_interv_plan eip
              LEFT JOIN interv_plan ip
                ON (eip.id_interv_plan = ip.id_interv_plan)
             WHERE eip.id_episode IN (SELECT column_value
                                        FROM TABLE(i_id_epis))
             ORDER BY pk_sysdomain.get_rank(i_lang,
                                            'EPIS_INTERV_PLAN.FLG_STATUS',
                                            decode(eip.flg_status,
                                                   pk_alert_constant.g_flg_status_e,
                                                   pk_alert_constant.g_flg_status_a,
                                                   eip.flg_status)),
                      eip.dt_begin,
                      interv_plan_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'get_interv_plan_report',
                                                     o_error);
    END get_interv_plan_report;
    /********************************************************************************************
    * Get the history of a given intervention plan (when i_epis_interv_plan is not null) or the 
    * history of all intervention plans (the current state) for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = Social Worker)
    * @ param i_epis_interv_plan      ID Intervention plan
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the 
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/24
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist_report
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN table_number,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
        l_category category.flg_type%TYPE;
    BEGIN
        g_error := 'GET_INTERV_PLAN_HIST: i_id_epis is array ' || ', i_prof.id = ' || i_prof.id ||
                   ', i_id_epis_interv_plan = ' || i_id_epis_interv_plan;
        pk_alertlog.log_debug(g_error);
        --
        l_category := pk_prof_utils.get_category(i_lang, i_prof);
        g_error    := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('PARAMEDICAL_T003',
                                                                                          'SOCIAL_T082',
                                                                                          'SOCIAL_T124',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'SOCIAL_T107',
                                                                                          'SOCIAL_T108',
                                                                                          'SOCIAL_T109',
                                                                                          'PARAMEDICAL_T002',
                                                                                          'PARAMEDICAL_T022'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF i_id_epis_interv_plan IS NOT NULL
        THEN
            --
            g_error := 'GET CURSOR INTER_PLAN HISTORY';
            OPEN o_interv_plan FOR
                SELECT eiph.id_epis_interv_plan_hist id,
                       eiph.id_episode id_episode,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T003')) || CASE
                            WHEN eiph.id_interv_plan = 0 THEN
                             eiph.desc_other_interv_plan
                            WHEN eiph.id_interv_plan IS NULL THEN
                             eiph.desc_other_interv_plan
                            ELSE
                             pk_translation.get_translation(i_lang, ip.code_interv_plan)
                        END interv_plan_desc,
                       eiph.id_task_goal_det,
                       --ALERT-98764 - The goal field must be available also for SW, but we need flash changes to do that!
                       --The changes will be implemented in the Issue - ALERT-99008
                       decode(l_category,
                              pk_alert_constant.g_cat_type_social,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T002')) ||
                              get_task_goal_desc(i_lang, i_prof, eiph.id_task_goal_det)) desc_task_goal,
                       --pk_tools.get_prof_description(i_lang, i_prof, eip.id_professional, eip.dt_begin_tstz, NULL) prof_sign,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T104')) ||
                       pk_date_utils.dt_chr_tsz(i_lang, eiph.dt_begin, i_prof) desc_dt_begin,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T125')) ||
                       pk_date_utils.dt_chr_tsz(i_lang, eiph.dt_end, i_prof) desc_dt_end,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T004')) ||
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_e,
                              pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS',
                                                      pk_alert_constant.g_flg_status_a,
                                                      i_lang),
                              pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', eiph.flg_status, i_lang)) desc_status,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T022')) ||
                       pk_utils.concat_table(get_desc_epis_diag(i_lang,
                                                                i_prof,
                                                                get_epis_interv_plan_diag(i_lang,
                                                                                          i_prof,
                                                                                          NULL,
                                                                                          eiph.id_epis_interv_plan_hist)),
                                             '; ',
                                             1,
                                             -1) desc_diagnosis,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082')) ||
                       eiph.notes desc_notes,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                        'COMMON_M072')) ||
                              pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, eiph.id_cancel_info_det),
                              NULL) cancel_reason,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                        'COMMON_M073')) ||
                              pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, eiph.id_cancel_info_det),
                              NULL) cancel_notes,
                       
                       t_table_message_array('PARAMEDICAL_T003') label_interv_plan,
                       CASE
                            WHEN eiph.id_interv_plan = 0 THEN
                             eiph.desc_other_interv_plan
                            WHEN eiph.id_interv_plan IS NULL THEN
                             eiph.desc_other_interv_plan
                            ELSE
                             pk_translation.get_translation(i_lang, ip.code_interv_plan)
                        END info_interv_plan,
                       decode(l_category,
                              pk_alert_constant.g_cat_type_social,
                              NULL,
                              t_table_message_array('PARAMEDICAL_T002')) label_task_goal,
                       decode(l_category,
                              pk_alert_constant.g_cat_type_social,
                              NULL,
                              get_task_goal_desc(i_lang, i_prof, eiph.id_task_goal_det)) info_task_goal,
                       t_table_message_array('SOCIAL_T104') label_dt_begin,
                       pk_date_utils.dt_chr_tsz(i_lang, eiph.dt_begin, i_prof) info_dt_begin,
                       pk_date_utils.date_send_tsz(i_lang, eiph.dt_begin, i_prof) info_dt_begin_send,
                       t_table_message_array('SOCIAL_T125') label_dt_end,
                       pk_date_utils.dt_chr_tsz(i_lang, eiph.dt_end, i_prof) info_dt_end,
                       pk_date_utils.date_send_tsz(i_lang, eiph.dt_end, i_prof) info_dt_end_send,
                       t_table_message_array('SOCIAL_T004') label_status,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_e,
                              pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS',
                                                      pk_alert_constant.g_flg_status_a,
                                                      i_lang),
                              pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', eiph.flg_status, i_lang)) info_status,
                       t_table_message_array('PARAMEDICAL_T022') label_diagnosis,
                       pk_utils.concat_table(get_desc_epis_diag(i_lang,
                                                                i_prof,
                                                                get_epis_interv_plan_diag(i_lang,
                                                                                          i_prof,
                                                                                          NULL,
                                                                                          eiph.id_epis_interv_plan_hist)),
                                             '; ',
                                             1,
                                             -1) info_diagnosis,
                       t_table_message_array('SOCIAL_T082') label_notes,
                       eiph.notes info_notes,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_message.get_message(i_lang, 'COMMON_M072'),
                              NULL) label_cancel_reason,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, eiph.id_cancel_info_det),
                              NULL) info_cancel_reason,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_message.get_message(i_lang, 'COMMON_M073'),
                              NULL) label_cancel_notes,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, eiph.id_cancel_info_det),
                              NULL) info_cancel_notes
                  FROM epis_interv_plan_hist eiph
                  LEFT JOIN interv_plan ip
                    ON (eiph.id_interv_plan = ip.id_interv_plan)
                 WHERE eiph.id_epis_interv_plan = i_id_epis_interv_plan
                 ORDER BY eiph.dt_creation DESC;
            --     
            g_error := 'GET CURSOR INTER_PLAN_PROF HISTORY';
            OPEN o_interv_plan_prof FOR
                SELECT eiph.id_epis_interv_plan_hist,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, eiph.dt_creation, i_prof) dt,
                       pk_tools.get_prof_description(i_lang, i_prof, eiph.id_professional, eiph.dt_creation, NULL) prof_sign,
                       eiph.flg_status flg_status,
                       CASE
                            WHEN eiph.flg_status = g_plan_active
                                 AND (SELECT COUNT(*)
                                        FROM epis_interv_plan_hist eiph2
                                       WHERE eiph2.id_epis_interv_plan = i_id_epis_interv_plan
                                         AND eiph2.dt_creation < eiph.dt_creation) > 1 THEN
                             pk_message.get_message(i_lang, 'MEDICATION_DETAILS_M055')
                            ELSE
                             get_interv_plan_state_desc(i_lang, i_prof, eiph.flg_status)
                        END desc_status,
                       eiph.id_task_goal_det,
                       get_task_goal_desc(i_lang, i_prof, eiph.id_task_goal_det) desc_task_goal,
                       pk_date_utils.date_send_tsz(i_lang, eiph.dt_creation, i_prof) dt_send,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, eiph.id_professional) prof_name_sign,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        eiph.id_professional,
                                                        eiph.dt_creation,
                                                        eiph.id_episode) prof_spec_sign
                  FROM epis_interv_plan_hist eiph
                 WHERE eiph.id_epis_interv_plan = i_id_epis_interv_plan
                 ORDER BY eiph.dt_creation DESC;
        ELSE
            g_error := 'GET CURSOR INTER_PLAN HISTORY';
            OPEN o_interv_plan FOR
                SELECT eiph.id_epis_interv_plan_hist id,
                       eiph.id_episode id_episode,
                       CASE
                            WHEN eiph.id_interv_plan = 0 THEN
                             eiph.desc_other_interv_plan
                            WHEN eiph.id_interv_plan IS NULL THEN
                             eiph.desc_other_interv_plan
                            ELSE
                             pk_translation.get_translation(i_lang, ip.code_interv_plan)
                        END interv_plan_desc,
                       eiph.id_task_goal_det,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T002')) ||
                       --ALERT-98764 - The goal field must be available also for SW, but we need flash changes to do that!
                       --The changes will be implemented in the Issue - ALERT-99008
                        decode(l_category,
                               pk_alert_constant.g_cat_type_social,
                               NULL,
                               get_task_goal_desc(i_lang, i_prof, eiph.id_task_goal_det)) desc_task_goal,
                       --pk_tools.get_prof_description(i_lang, i_prof, eip.id_professional, eip.dt_begin, NULL) prof_sign,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T104')) ||
                       pk_date_utils.dt_chr_tsz(i_lang, eiph.dt_begin, i_prof) desc_dt_begin,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T125')) ||
                       pk_date_utils.dt_chr_tsz(i_lang, eiph.dt_end, i_prof) desc_dt_end,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082')) ||
                       eiph.notes desc_notes,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T004')) ||
                       pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', eiph.flg_status, i_lang) desc_status,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T022')) ||
                       pk_utils.concat_table(get_desc_epis_diag(i_lang,
                                                                i_prof,
                                                                get_epis_interv_plan_diag(i_lang,
                                                                                          i_prof,
                                                                                          NULL,
                                                                                          eiph.id_epis_interv_plan_hist)),
                                             '; ',
                                             1,
                                             -1) desc_diagnosis,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                        'COMMON_M072')) ||
                              pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, eiph.id_cancel_info_det),
                              NULL) cancel_reason,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                        'COMMON_M073')) ||
                              pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, eiph.id_cancel_info_det),
                              NULL) cancel_notes,
                       
                       t_table_message_array('PARAMEDICAL_T002') label_task_goal,
                       decode(l_category,
                              pk_alert_constant.g_cat_type_social,
                              NULL,
                              get_task_goal_desc(i_lang, i_prof, eiph.id_task_goal_det)) info_task_goal,
                       t_table_message_array('SOCIAL_T104') label_dt_begin,
                       pk_date_utils.dt_chr_tsz(i_lang, eiph.dt_begin, i_prof) info_dt_begin,
                       pk_date_utils.date_send_tsz(i_lang, eiph.dt_begin, i_prof) info_dt_begin_send,
                       t_table_message_array('SOCIAL_T125') label_dt_end,
                       pk_date_utils.dt_chr_tsz(i_lang, eiph.dt_end, i_prof) info_dt_end,
                       pk_date_utils.date_send_tsz(i_lang, eiph.dt_end, i_prof) info_dt_end_send,
                       t_table_message_array('SOCIAL_T082') label_notes,
                       eiph.notes info_notes,
                       t_table_message_array('SOCIAL_T004') label_status,
                       pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', eiph.flg_status, i_lang) info_status,
                       t_table_message_array('PARAMEDICAL_T022') label_diagnosis,
                       pk_utils.concat_table(get_desc_epis_diag(i_lang,
                                                                i_prof,
                                                                get_epis_interv_plan_diag(i_lang,
                                                                                          i_prof,
                                                                                          NULL,
                                                                                          eiph.id_epis_interv_plan_hist)),
                                             '; ',
                                             1,
                                             -1) info_diagnosis,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_message.get_message(i_lang, 'COMMON_M072'),
                              NULL) label_cancel_reason,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, eiph.id_cancel_info_det),
                              NULL) info_cancel_reason,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_message.get_message(i_lang, 'COMMON_M073'),
                              NULL) cancel_notes,
                       decode(eiph.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, eiph.id_cancel_info_det),
                              NULL) info_cancel_notes
                
                  FROM epis_interv_plan_hist eiph
                  LEFT JOIN interv_plan ip
                    ON (eiph.id_interv_plan = ip.id_interv_plan)
                 WHERE eiph.id_episode IN (SELECT column_value
                                             FROM TABLE(i_id_epis))
                 ORDER BY eiph.dt_creation DESC;
            --     
            g_error := 'GET CURSOR INTER_PLAN_PROF HISTORY';
            OPEN o_interv_plan_prof FOR
                SELECT eiph.id_epis_interv_plan_hist id,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, eiph.dt_creation, i_prof) dt,
                       pk_tools.get_prof_description(i_lang, i_prof, eiph.id_professional, eiph.dt_creation, NULL) prof_sign,
                       eiph.flg_status flg_status,
                       CASE
                            WHEN eiph.flg_status = g_plan_active
                                 AND (SELECT COUNT(*)
                                        FROM epis_interv_plan_hist eiph2
                                       WHERE eiph2.id_epis_interv_plan = i_id_epis_interv_plan
                                         AND eiph2.dt_creation < eiph.dt_creation) > 1 THEN
                             pk_message.get_message(i_lang, 'MEDICATION_DETAILS_M055')
                            ELSE
                             get_interv_plan_state_desc(i_lang, i_prof, eiph.flg_status)
                        END desc_status,
                       eiph.id_task_goal_det,
                       get_task_goal_desc(i_lang, i_prof, eiph.id_task_goal_det) desc_task_goal,
                       pk_date_utils.date_send_tsz(i_lang, eiph.dt_creation, i_prof) dt_send,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, eiph.id_professional) prof_name_sign,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        eiph.id_professional,
                                                        eiph.dt_creation,
                                                        eiph.id_episode) prof_spec_sign
                  FROM epis_interv_plan_hist eiph
                 WHERE eiph.id_episode IN (SELECT column_value
                                             FROM TABLE(i_id_epis))
                 ORDER BY eiph.dt_creation DESC;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_interv_plan_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'get_interv_plan_hist_report',
                                                     o_error);
    END get_interv_plan_hist_report;
    /*
    * Get an episode's paramedical service reports list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_report_prof    reports records info 
    * @param o_report         reports
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    PROCEDURE get_paramed_report_list_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN table_number,
        i_show_cancelled IN VARCHAR2,
        o_report_prof    OUT pk_types.cursor_type,
        o_report         OUT pk_types.cursor_type
    ) IS
    BEGIN
        g_error := 'OPEN o_report_prof_list';
        OPEN o_report_prof FOR
            SELECT pr.id_paramed_report id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, pr.dt_last_update, i_prof) dt,
                   pk_tools.get_prof_description(i_lang, i_prof, pr.id_professional, pr.dt_last_update, pr.id_episode) prof_sign,
                   pr.flg_status,
                   NULL desc_status,
                   decode(pr.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_cancel,
                   decode(pr.flg_status,
                          pk_case_management.g_mfu_status_canc,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_action,
                   pk_date_utils.date_send_tsz(i_lang, pr.dt_last_update, i_prof) dt_send,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pr.id_professional) prof_name_sign,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pr.id_professional,
                                                    pr.dt_last_update,
                                                    pr.id_episode) prof_spec_sign
            
              FROM paramed_report pr
             WHERE pr.id_episode IN (SELECT /*+dynamic_sampling(t 2)*/
                                      t.column_value id_episode
                                       FROM TABLE(i_episode) t)
               AND (pr.flg_status IN (g_report_active, g_report_edit) OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND pr.flg_status = g_report_cancel))
             ORDER BY decode(pr.flg_status, g_report_cancel, 2, 1) ASC, pr.dt_last_update DESC;
    
        g_error := 'OPEN o_report_list';
        OPEN o_report FOR
            SELECT pr.id_paramed_report id,
                   pr.id_episode id_episode,
                   pr.text,
                   get_ehr_last_update_info(i_lang,
                                            i_prof,
                                            pr.dt_last_update,
                                            pr.id_professional,
                                            pr.dt_last_update,
                                            pr.id_episode) last_update_info,
                   pk_message.get_message(i_lang, 'PAST_HISTORY_M006') label_last_update,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, pr.dt_last_update, i_prof) desc_dt_last_upd,
                   pk_date_utils.date_send_tsz(i_lang, pr.dt_last_update, i_prof) serial_dt_last_upd,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pr.id_professional) prof_name_sign,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pr.id_professional,
                                                    pr.dt_last_update,
                                                    pr.id_episode) prof_spec_sign
              FROM paramed_report pr
             WHERE pr.id_episode IN (SELECT /*+dynamic_sampling(t 2)*/
                                      t.column_value id_episode
                                       FROM TABLE(i_episode) t)
               AND (pr.flg_status IN (g_report_active, g_report_edit) OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND pr.flg_status = g_report_cancel))
             ORDER BY decode(pr.flg_status, g_report_cancel, 2, 1) ASC, pr.dt_last_update DESC;
    END get_paramed_report_list_report;

    /*
    * Get list of follow up notes as string.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/21
    */
    FUNCTION get_followup_notes_str_report
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE DEFAULT NULL,
        o_follow_up    OUT NOCOPY CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_data_cursor              pk_types.cursor_type;
        l_prof_cursor              pk_types.cursor_type;
        l_rec_id                   table_number := table_number();
        l_epis_id                  table_number := table_number();
        l_epis_origin              table_number := table_number();
        l_notes                    table_clob := table_clob();
        l_start_dt                 table_varchar := table_varchar();
        l_time_spent               table_varchar := table_varchar();
        l_next_enc                 table_varchar := table_varchar();
        l_last_update              table_varchar := table_varchar();
        l_desc_cancel              table_varchar := table_varchar();
        l_label_followup_notes     table_varchar := table_varchar();
        l_info_followup_notes      table_clob := table_clob();
        l_label_start_dt           table_varchar := table_varchar();
        l_info_start_dt            table_varchar := table_varchar();
        l_info_start_dt_send       table_varchar := table_varchar();
        l_label_time_spent         table_varchar := table_varchar();
        l_info_time_spent          table_varchar := table_varchar();
        l_label_next_dt            table_varchar := table_varchar();
        l_info_next_dt             table_varchar := table_varchar();
        l_info_next_dt_send        table_varchar := table_varchar();
        l_label_last_update_info   table_varchar := table_varchar();
        l_dt_last_update_info      table_varchar := table_varchar();
        l_dt_send_last_update_info table_varchar := table_varchar();
        l_prof_update_info         table_varchar := table_varchar();
        l_cat_last_update_info     table_varchar := table_varchar();
    
        l_report_title VARCHAR2(100 CHAR);
    BEGIN
        l_report_title := format_str_header_bold(pk_message.get_message(i_lang      => i_lang,
                                                                        i_prof      => i_prof,
                                                                        i_code_mess => 'SOCIAL_T103'));
    
        g_error := 'CALL get_followup_notes';
        get_followup_notes_list(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_episode        => table_number(i_episode),
                                i_show_cancelled => pk_alert_constant.g_no,
                                o_follow_up_prof => l_prof_cursor,
                                o_follow_up      => l_data_cursor);
    
        g_error := 'CLOSE l_prof_cursor';
        CLOSE l_prof_cursor;
    
        g_error := 'FETCH l_data_cursor';
        FETCH l_data_cursor BULK COLLECT
            INTO l_rec_id,
                 l_epis_id,
                 l_epis_origin,
                 l_notes,
                 l_start_dt,
                 l_time_spent,
                 l_next_enc,
                 l_last_update,
                 l_desc_cancel,
                 l_label_followup_notes,
                 l_info_followup_notes,
                 l_label_start_dt,
                 l_info_start_dt,
                 l_info_start_dt_send,
                 l_label_time_spent,
                 l_info_time_spent,
                 l_label_next_dt,
                 l_info_next_dt,
                 l_info_next_dt_send,
                 l_label_last_update_info,
                 l_dt_last_update_info,
                 l_dt_send_last_update_info,
                 l_prof_update_info,
                 l_cat_last_update_info;
        CLOSE l_data_cursor;
    
        IF l_rec_id IS NOT NULL
           AND l_rec_id.first IS NOT NULL
        THEN
            g_error := 'LOOP begin';
            FOR i IN l_rec_id.first .. l_rec_id.last
            LOOP
                o_follow_up := o_follow_up || l_notes(i) || g_break || l_start_dt(i) || g_break || l_time_spent(i) ||
                               g_break || l_next_enc(i) || g_break || l_last_update(i) || g_break || g_break;
            END LOOP;
        
            o_follow_up := l_report_title || g_break || g_break || o_follow_up;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'get_followup_notes_str_report',
                                                     o_error    => o_error);
    END get_followup_notes_str_report;
    /*
    * Get an episode's follow up notes list. Specify the follow up notes
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/15
    */
    FUNCTION get_followup_notes_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN management_follow_up.id_episode%TYPE,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_mng_followup IS NULL
        THEN
            g_error := 'CALL get_followup_notes_list_report';
            get_followup_notes_list_report(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_episode        => table_number(i_episode),
                                           i_show_cancelled => i_show_cancelled,
                                           o_follow_up_prof => o_follow_up_prof,
                                           o_follow_up      => o_follow_up);
        ELSE
            g_error := 'CALL get_followup_notes_hist_report';
            get_followup_notes_hist_report(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_mng_followup   => i_mng_followup,
                                           o_follow_up_prof => o_follow_up_prof,
                                           o_follow_up      => o_follow_up);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'get_followup_notes_report',
                                                     o_error    => o_error);
    END get_followup_notes_report;

    /*************************************************
    * set_epis_interv_plan_diag
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_id_episode
    * @param i_id_epis_interv_plan_hist              epis_interv_plan_hist identifier to associate
    * @param i_tb_diag                     table with diagnosis to insert
    * @param i_tb_desc_diag                     table with desc_diagnosis to insert
    * @param i_tb_epis_diag                     table with epis_diagnosis to insert
    *    
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION set_epis_interv_plan_diag_nc
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_epis_interv_plan_hist IN epis_interv_plan_hist.id_epis_interv_plan_hist%TYPE,
        i_tb_diag                  IN table_number,
        i_tb_alert_diag            IN table_number,
        i_tb_desc_diag             IN table_varchar,
        i_tb_epis_diag             IN table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids          table_varchar;
        l_id_epis_diag    epis_diagnosis.id_epis_diagnosis%TYPE;
        l_flg_add_problem epis_diagnosis.flg_add_problem%TYPE;
    
        l_rec_diag        pk_edis_types.rec_in_diagnosis;
        l_rec_epis_diag   pk_edis_types.rec_in_epis_diagnoses;
        l_diag_out_params pk_edis_types.table_out_epis_diags;
    BEGIN
    
        IF i_tb_epis_diag.count > 0
        THEN
            -- it's only gonna change the state of the inrvention so there's no change in the epis_diagnosis, 
            -- only need to maintain the history coeerence
            FOR i IN 1 .. i_tb_epis_diag.count
            LOOP
                IF i_tb_epis_diag(i) IS NOT NULL
                THEN
                    g_error := ' call ts_epis_interv_plan_diag.ins';
                    ts_epis_interv_plan_diag.ins(id_epis_interv_plan_hist_in => i_id_epis_interv_plan_hist,
                                                 id_epis_diagnosis_in        => i_tb_epis_diag(i),
                                                 rows_out                    => l_rowids);
                
                    g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON EPIS_INTERV_PLAN_DIAG';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_INTERV_PLAN_DIAG',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                END IF;
            END LOOP;
        ELSE
            -- associated diagnosis to the intervention might have changed
            IF i_tb_diag.count > 0
            THEN
                FOR i IN 1 .. i_tb_diag.count
                LOOP
                    IF i_tb_diag(i) IS NOT NULL
                    THEN
                        -- get epis_diagnosis for the diagnosis list
                        g_error := 'call pk_diagnosis.get_epis_diagnosis';
                        IF NOT pk_diagnosis.get_epis_diagnosis(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_epis            => i_id_episode,
                                                               i_diag            => i_tb_diag(i),
                                                               i_desc_diag       => i_tb_desc_diag(i),
                                                               o_epis_diag       => l_id_epis_diag,
                                                               o_flg_add_problem => l_flg_add_problem,
                                                               o_error           => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        IF l_id_epis_diag IS NOT NULL
                        THEN
                            -- id_epis_diagnosis already exists, only maintain the history coeerence
                            ts_epis_interv_plan_diag.ins(id_epis_interv_plan_hist_in => i_id_epis_interv_plan_hist,
                                                         id_epis_diagnosis_in        => l_id_epis_diag,
                                                         rows_out                    => l_rowids);
                        
                            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON EPIS_INTERV_PLAN_DIAG';
                            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'EPIS_INTERV_PLAN_DIAG',
                                                          i_rowids     => l_rowids,
                                                          o_error      => o_error);
                        ELSE
                            l_rec_diag.flg_status     := pk_diagnosis.g_ed_flg_status_d;
                            l_rec_diag.id_diagnosis   := i_tb_diag(i);
                            l_rec_diag.desc_diagnosis := i_tb_desc_diag(i);
                            IF i_tb_alert_diag.exists(i)
                            THEN
                                l_rec_diag.id_alert_diagnosis := i_tb_alert_diag(i);
                            ELSE
                                l_rec_diag.id_alert_diagnosis := NULL;
                            END IF;
                            l_rec_epis_diag.epis_diagnosis.id_episode    := i_id_episode;
                            l_rec_epis_diag.epis_diagnosis.flg_type      := pk_diagnosis.g_diag_type_p;
                            l_rec_epis_diag.epis_diagnosis.tbl_diagnosis := pk_edis_types.table_in_diagnosis(l_rec_diag);
                        
                            -- id_epis_diagnosis donn't exists, then create new epis_diagnosis
                            g_error := 'call pk_diagnosis.set_epis_diagnosis';
                            IF NOT pk_diagnosis.set_epis_diagnosis(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_epis_diagnoses => l_rec_epis_diag,
                                                                   o_params         => l_diag_out_params,
                                                                   o_error          => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            IF l_diag_out_params.count = 1
                            THEN
                                IF l_diag_out_params(1).id_epis_diagnosis IS NOT NULL
                                THEN
                                    --maintain the history coeerence
                                    g_error := 'call  ts_epis_interv_plan_diag.ins';
                                    ts_epis_interv_plan_diag.ins(id_epis_interv_plan_hist_in => i_id_epis_interv_plan_hist,
                                                                 id_epis_diagnosis_in        => l_diag_out_params(1).id_epis_diagnosis,
                                                                 rows_out                    => l_rowids);
                                
                                    g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON EPIS_INTERV_PLAN_DIAG';
                                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_table_name => 'EPIS_INTERV_PLAN_DIAG',
                                                                  i_rowids     => l_rowids,
                                                                  o_error      => o_error);
                                
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'SET_EPIS_INTERV_PLAN_DIAG_NC',
                                                     o_error    => o_error);
    END set_epis_interv_plan_diag_nc;

    /*************************************************
    * get_interv_plan_diag
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_id_episode                                  episode identifier
    *
    * @param o_diag output cursor
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION get_interv_plan_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_diag       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_search_diagnosis sys_config.value%TYPE := pk_sysconfig.get_config('PERMISSION_FOR_SEARCH_DIAGNOSIS', i_prof);
    
        l_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    
        l_search    VARCHAR2(1 CHAR);
        l_tbl_diags t_coll_diagnosis_config;
    
    BEGIN
    
        l_tbl_diags := pk_diagnosis.get_associated_diagnosis_tf(i_lang, i_prof, i_id_episode);
    
        --check permissions for search diagnosis option avalilable
        IF instr(nvl(l_search_diagnosis, '#'), l_profile_template) != 0
        THEN
            l_search := pk_alert_constant.g_yes;
        END IF;
    
        g_error := 'get o_diag - pk_diagnosis.get_associated_diagnosis_tf';
        OPEN o_diag FOR
            SELECT id_diagnosis, id_alert_diagnosis, desc_diagnosis, code_icd
              FROM (SELECT a.id_diagnosis, a.id_alert_diagnosis, a.desc_diagnosis, a.code_icd, a.rank
                      FROM (SELECT NULL id_diagnosis,
                                   NULL id_alert_diagnosis,
                                   pk_message.get_message(i_lang, i_prof, 'PARAMEDICAL_T007') desc_diagnosis,
                                   NULL code_icd,
                                   10 rank
                              FROM dual
                             WHERE l_search = pk_alert_constant.g_yes
                            UNION ALL
                            SELECT /*+opt_estimate (table t rows=0.000001)*/
                             t.id_diagnosis, t.id_alert_diagnosis, t.desc_diagnosis, t.code_icd, 20 rank
                              FROM TABLE(l_tbl_diags) t) a
                     ORDER BY a.rank ASC, a.desc_diagnosis ASC);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_INTERV_PLAN_DIAG',
                                                     o_error    => o_error);
    END get_interv_plan_diag;

    /*************************************************
    * get_interv_plan_diag
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_id_epis_interv_plan                   epis_interv_plan identifier
    * @param i_id_epis_interv_plan_hist              epis_interv_plan_hist identifier
    *
    * @param o_diag output cursor
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION get_epis_interv_plan_diag
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_epis_interv_plan      IN epis_interv_plan.id_epis_interv_plan%TYPE,
        i_id_epis_interv_plan_hist IN epis_interv_plan_hist.id_epis_interv_plan_hist%TYPE
    ) RETURN table_number IS
        l_id_epis_interv_plan_hist epis_interv_plan_hist.id_epis_interv_plan_hist%TYPE;
        l_tb_epis_diagnosis        table_number;
    BEGIN
        -- if i_id_epis_interv_plan_hist means that you want to retrive an history record 
        IF i_id_epis_interv_plan_hist IS NOT NULL
        THEN
            SELECT eipd.id_epis_diagnosis
              BULK COLLECT
              INTO l_tb_epis_diagnosis
              FROM epis_interv_plan_diag eipd
             WHERE eipd.id_epis_interv_plan_hist = i_id_epis_interv_plan_hist;
            -- if i_id_epis_interv_plan means that you want the current, most recent record
        ELSIF i_id_epis_interv_plan IS NOT NULL
        THEN
            SELECT id_epis_interv_plan_hist
              INTO l_id_epis_interv_plan_hist
              FROM (SELECT eiph.id_epis_interv_plan_hist
                      FROM epis_interv_plan_hist eiph
                     WHERE eiph.id_epis_interv_plan = i_id_epis_interv_plan
                     ORDER BY eiph.dt_creation DESC)
             WHERE rownum = 1;
        
            SELECT eipd.id_epis_diagnosis
              BULK COLLECT
              INTO l_tb_epis_diagnosis
              FROM epis_interv_plan_diag eipd
             WHERE eipd.id_epis_interv_plan_hist = l_id_epis_interv_plan_hist;
        ELSE
            l_tb_epis_diagnosis := table_number();
        END IF;
    
        RETURN l_tb_epis_diagnosis;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number();
    END get_epis_interv_plan_diag;
    /*************************************************
    * get_interv_plan_diag
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_tb_diag                               diag table
    *
    * @param o_diag output cursor
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION get_desc_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_tb_diag IN table_number
    ) RETURN table_varchar IS
        l_tb_desc_diag table_varchar := table_varchar();
    BEGIN
        --init collection
        l_tb_desc_diag.extend(i_tb_diag.count);
        --loop trought id_epis_diagnosis array and build a desc_diagnosis array
        FOR i IN 1 .. i_tb_diag.count
        LOOP
            SELECT pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_diagnosis => d.id_diagnosis,
                                              i_code         => d.code_icd,
                                              i_flg_other    => d.flg_other,
                                              i_flg_std_diag => pk_alert_constant.g_yes) desc_diagnosis
              INTO l_tb_desc_diag(i)
              FROM diagnosis d
             WHERE d.id_diagnosis = i_tb_diag(i);
        END LOOP;
    
        RETURN l_tb_desc_diag;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_varchar();
    END get_desc_diag;
    /*************************************************
    * get_interv_plan_diag
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_tb_epis_diag                           epis_diag table
    *
    * @param o_diag output cursor
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION get_desc_epis_diag
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_tb_epis_diag IN table_number
    ) RETURN table_varchar IS
        l_tb_desc_diag table_varchar := table_varchar();
    BEGIN
        --init collection
        l_tb_desc_diag.extend(i_tb_epis_diag.count);
        --loop trought id_epis_diagnosis array and build a desc_diagnosis array
        FOR i IN 1 .. i_tb_epis_diag.count
        LOOP
            SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => pk_alert_constant.g_yes) desc_diagnosis
              INTO l_tb_desc_diag(i)
              FROM epis_diagnosis ed
              JOIN diagnosis d
                ON d.id_diagnosis = ed.id_diagnosis
             WHERE ed.id_epis_diagnosis = i_tb_epis_diag(i);
        END LOOP;
    
        RETURN l_tb_desc_diag;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_varchar();
    END get_desc_epis_diag;
    /*************************************************
    * get_id_diagnosis
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_tb_epis_diag                           epis_diag table
    *
    * @param o_diag output cursor
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Paulo Teixeira  
    * @version                2.6.1.2
    * @since                  2011/09/12
    ***********************************************/
    FUNCTION get_id_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_tb_epis_diag IN table_number
    ) RETURN table_number IS
        l_tb_id_diag table_number := table_number();
    BEGIN
        --init collection
        l_tb_id_diag.extend(i_tb_epis_diag.count);
        --loop trought id_epis_diagnosis array and build id_diagnosis array
        FOR i IN 1 .. i_tb_epis_diag.count
        LOOP
            SELECT ed.id_diagnosis
              INTO l_tb_id_diag(i)
              FROM epis_diagnosis ed
             WHERE ed.id_epis_diagnosis = i_tb_epis_diag(i);
        END LOOP;
    
        RETURN l_tb_id_diag;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number();
    END get_id_diagnosis;

    FUNCTION get_id_alert_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_tb_epis_diag IN table_number
    ) RETURN table_number IS
        l_tb_id_diag table_number := table_number();
    BEGIN
        --init collection
        l_tb_id_diag.extend(i_tb_epis_diag.count);
        --loop trought id_epis_diagnosis array and build id_diagnosis array
        FOR i IN 1 .. i_tb_epis_diag.count
        LOOP
            SELECT ed.id_alert_diagnosis
              INTO l_tb_id_diag(i)
              FROM epis_diagnosis ed
             WHERE ed.id_epis_diagnosis = i_tb_epis_diag(i);
        END LOOP;
    
        RETURN l_tb_id_diag;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number();
    END get_id_alert_diagnosis;

    /*************************************************
    * Get a id opinion type of professional
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    *
    *
    * @return                 opinion type identifier
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/19
    ***********************************************/
    FUNCTION get_id_opinion_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN opinion_type.id_opinion_type%TYPE IS
    
        l_type_opinion opinion_type.id_opinion_type%TYPE;
    
        l_id_opinion table_number;
    BEGIN
    
        l_id_opinion := get_lst_id_opinion_type(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        IF l_id_opinion.count > 0
        THEN
        
            RETURN l_id_opinion(1);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_id_opinion_type;

    /*************************************************
    * Get a id opinion type of professional
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    *
    *
    * @return                 opinion type identifier
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/19
    ***********************************************/
    FUNCTION get_lst_id_opinion_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_number IS
    
        l_category  category.id_category%TYPE;
        l_epis_type epis_type.id_epis_type%TYPE := 0;
    
        l_type_opinion     opinion_type.id_opinion_type%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_id_opinion       table_number;
    
    BEGIN
    
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        IF i_episode IS NOT NULL
        THEN
            l_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_episode);
        
        END IF;
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        SELECT ot.id_opinion_type
          BULK COLLECT
          INTO l_id_opinion
          FROM opinion_type ot
          JOIN opinion_type_category otc
            ON ot.id_opinion_type = otc.id_opinion_type
         WHERE ((otc.id_category = l_category AND otc.id_profile_template IS NULL) OR
               (otc.id_profile_template = l_profile_template))
           AND ((l_epis_type IN
               (pk_alert_constant.g_epis_type_home_health_care, pk_alert_constant.g_epis_type_hhc_process) AND
               ot.id_opinion_type <> pk_opinion.g_ot_social_worker) OR
               (l_epis_type NOT IN
               (pk_alert_constant.g_epis_type_home_health_care, pk_alert_constant.g_epis_type_hhc_process) AND
               ot.id_opinion_type <> pk_opinion.g_ot_social_worker_ds));
    
        RETURN l_id_opinion;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lst_id_opinion_type;
    /*************************************************
    * Check a values of opinion table where followup is active in the opion_type of prof 
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_episode                               episode idendifier
    *
    *
    * @return                 a opinion table_function 
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/18
    ***********************************************/
    FUNCTION get_opinion_active_value
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN t_rec_opinion IS
        l_type_opinion opinion_type.id_opinion_type%TYPE;
        l_lst_opinion  table_number;
        l_ret          t_rec_opinion;
    BEGIN
    
        --   l_type_opinion := get_id_opinion_type(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        l_lst_opinion := get_lst_id_opinion_type(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        SELECT t_rec_opinion(id_opinion      => t.id_opinion,
                             flg_state       => t.flg_state,
                             dt_problem_tstz => t.dt_problem_tstz,
                             dt_problem_str  => pk_date_utils.date_send_tsz(i_lang, t.dt_problem_tstz, i_prof),
                             desc_problem    => t.desc_problem)
          INTO l_ret
          FROM (SELECT o.id_opinion, o.flg_state, o.dt_problem_tstz, o.desc_problem
                  FROM opinion o
                 WHERE (o.id_episode = i_episode OR o.id_episode_answer = i_episode)
                   AND ((o.id_opinion_type IN (SELECT /*+dynamic_sampling(t 2)*/
                                                t.column_value id_episode
                                                 FROM TABLE(l_lst_opinion) t) AND
                       pk_utils.search_table_number(l_lst_opinion, pk_opinion.g_ot_social_worker) = -1) OR
                       (pk_utils.search_table_number(l_lst_opinion, pk_opinion.g_ot_social_worker) <> -1 AND
                       o.id_opinion_type IN (pk_opinion.g_ot_social_worker, pk_opinion.g_ot_social_worker_ds)))
                   AND o.flg_state NOT IN (pk_opinion.g_opinion_rejected,
                                           pk_opinion.g_opinion_over,
                                           pk_opinion.g_opinion_cancel,
                                           pk_opinion.g_opinion_req,
                                           pk_opinion.g_opinion_prof_refuse)) t;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_opinion_active_value;

    /*************************************************
    * Check if create button is active
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_episode                               episode idendifier
    *
    * @param 
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/18
    ***********************************************/
    FUNCTION get_create_active
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_flg_active OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_opinion   t_rec_opinion;
        l_epis_type epis_type.id_epis_type%TYPE := NULL;
    BEGIN
    
        l_opinion := get_opinion_active_value(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        SELECT e.id_epis_type
          INTO l_epis_type
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        IF l_opinion.id_opinion IS NOT NULL
        THEN
            o_flg_active := pk_alert_constant.g_yes;
        ELSE
            o_flg_active := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_create_active;

    /*************************************************
    * Check if cancel and actions button is active
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_episode                               episode idendifier
    * @param i_flg_status                            management_follow_up status 
    * @param i_id_management_follow_up               management_follow_up identifier
    *
    * @param 
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/18
    ***********************************************/
    FUNCTION get_actions_active
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_flg_status              IN VARCHAR2,
        i_id_management_follow_up IN NUMBER
    ) RETURN VARCHAR2 IS
        l_create_active    VARCHAR2(1);
        l_start_management management_follow_up.dt_start%TYPE;
        l_opinion          t_rec_opinion;
    BEGIN
    
        l_opinion := get_opinion_active_value(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        IF (l_opinion.id_opinion IS NOT NULL)
        THEN
            l_create_active := pk_alert_constant.g_yes;
        ELSE
            l_create_active := pk_alert_constant.g_no;
        END IF;
    
        IF (i_flg_status = pk_case_management.g_mfu_status_canc OR l_create_active = pk_alert_constant.g_no)
        THEN
            RETURN pk_alert_constant.g_no;
        
        ELSE
            SELECT mfu.dt_start
              INTO l_start_management
              FROM management_follow_up mfu
             WHERE mfu.id_management_follow_up = i_id_management_follow_up;
        
            IF (l_start_management > l_opinion.dt_problem_tstz)
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        
        END IF;
    
        RETURN pk_alert_constant.g_no;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_actions_active;

    /*************************************************
    * Check if ok actions button is active
    *
    * @param i_lang                                  language identifier
    * @param i_prof                                  logged professional structure
    * @param i_flg_opinion_state                     opinion state
    *
    * @param 
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Jorge Silva  
    * @version                2.6.3.13
    * @since                  2014/03/21
    ***********************************************/
    FUNCTION get_ok_active
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_opinion_state IN opinion.flg_state%TYPE
    ) RETURN VARCHAR2 IS
        l_ok_active VARCHAR2(1);
    BEGIN
        IF (i_flg_opinion_state NOT IN
           (pk_opinion.g_opinion_cancel, pk_opinion.g_opinion_rejected, pk_opinion.g_opinion_over))
        THEN
            l_ok_active := pk_alert_constant.g_yes;
        ELSE
            l_ok_active := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ok_active;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_ok_active;

    FUNCTION get_swf_by_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_flg_type      IN category.code_category%TYPE,
        o_swf_file_name OUT swf_file.swf_file_name%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_info_software epis_info.id_software%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT a.id_software
              INTO l_epis_info_software
              FROM epis_info a
             WHERE a.id_episode = i_id_episode;
        
        EXCEPTION
            WHEN OTHERS THEN
                g_error := 'ERROR GETING EPIS INFO FOR EPISODE: ' || i_id_episode;
        END;
    
        g_error := 'LOGICAL ERROR';
        IF i_flg_type = pk_alert_constant.g_cat_type_nurse
        THEN
            IF l_epis_info_software IN (pk_alert_constant.g_soft_inpatient,
                                        pk_alert_constant.g_soft_outpatient,
                                        pk_alert_constant.g_soft_edis,
                                        pk_alert_constant.g_soft_nutritionist,
                                        pk_alert_constant.g_soft_psychologist,
                                        pk_alert_constant.g_soft_social)
            THEN
                o_swf_file_name := 'NPNSummary.swf';
            ELSIF l_epis_info_software = pk_alert_constant.g_soft_edis
            THEN
                o_swf_file_name := 'NSPCreate.swf';
            ELSE
                o_swf_file_name := 'NurseDiary.swf';
            END IF;
        
        ELSIF i_flg_type = pk_alert_constant.g_cat_type_doc
        THEN
            IF l_epis_info_software IN (pk_alert_constant.g_soft_inpatient,
                                        pk_alert_constant.g_soft_edis,
                                        pk_alert_constant.g_soft_nutritionist,
                                        pk_alert_constant.g_soft_psychologist,
                                        pk_alert_constant.g_soft_social,
                                        pk_alert_constant.g_soft_outpatient,
                                        pk_alert_constant.g_soft_resptherap,
                                        pk_alert_constant.g_soft_home_care,
                                        pk_alert_constant.g_soft_private_practice)
            THEN
                o_swf_file_name := 'INPPNSummary.swf';
            ELSIF l_epis_info_software = pk_alert_constant.g_soft_oris
            THEN
                o_swf_file_name := 'SR_InterventionRegisterSummary.swf';
            ELSE
                o_swf_file_name := 'ProgressNotesSummarySOAP.swf';
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SWF_BY_EPIS',
                                                     o_error);
    END get_swf_by_epis;

    --
    FUNCTION parse_date
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN VARCHAR2,
        i_precision IN VARCHAR2,
        o_date      OUT management_follow_up.dt_next_encounter%TYPE,
        o_precision OUT management_follow_up.dt_next_enc_precision%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_temp   VARCHAR2(14 CHAR);
        l_length NUMBER;
    BEGIN
        g_error := 'PARSE DATE';
        pk_alertlog.log_debug(g_error);
        IF i_date IS NOT NULL
        THEN
            l_length := length(i_date);
        
            g_error := 'TEST DATE LENGTH';
            pk_alertlog.log_debug(g_error);
            IF l_length NOT IN (4, 6, 8, 12, 14)
            THEN
                -- partial date must match formats YYYY, YYYYMM or YYYYMMDD so it can be completed here
                RAISE g_exception;
            END IF;
        
            g_error := 'COMPLETE PARTIAL DATE';
            pk_alertlog.log_debug(g_error);
            l_temp := i_date;
            -- if it receives an incomplete date like 2014, complete the serialized date to format YYYYMMDDHHMMSS
            IF l_length < 6
            THEN
                -- completes months
                l_temp := rpad(l_temp, 6, '01');
            END IF;
        
            IF l_length < 8
            THEN
                -- completes days
                l_temp := rpad(l_temp, 8, '01');
            END IF;
        
            IF l_length < 14
            THEN
                -- completes hours
                l_temp := rpad(l_temp, 14, '0');
            END IF;
            o_date := pk_date_utils.get_string_tstz(i_lang, i_prof, l_temp, NULL);
        ELSE
            o_date := NULL;
        END IF;
    
        g_error := 'PARSE DATE PRECISION';
        pk_alertlog.log_debug(g_error);
        IF i_precision IS NOT NULL
        THEN
            o_precision := i_precision;
        ELSE
            IF i_date IS NOT NULL
            THEN
                SELECT decode(length(i_date), 4, 'Y', 6, 'M', 8, 'D', 14, 'H', 1, 'U', 2, 'U', NULL)
                  INTO o_precision
                  FROM dual;
            ELSE
                o_precision := NULL;
            END IF;
        END IF;
        IF i_precision IS NOT NULL
           AND i_precision <> 'U'
           AND i_date IS NULL
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
                                                     g_owner,
                                                     g_package,
                                                     'PARSE_DATE',
                                                     o_error);
            RETURN FALSE;
    END parse_date;

    FUNCTION get_partial_date_format
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN management_follow_up.dt_next_encounter%TYPE,
        i_precision IN management_follow_up.dt_next_enc_precision%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_precision = g_date_unknown
        THEN
            RETURN pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
        
        ELSIF i_precision = g_date_precision_hour
        THEN
            RETURN pk_date_utils.date_char_tsz(i_lang => NULL,
                                               i_date => i_date,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software);
        ELSIF i_precision = g_date_precision_day
        THEN
            RETURN pk_date_utils.date_chr_short_read_tsz(i_lang, i_date, i_prof.institution, i_prof.software);
        
        ELSIF i_precision = g_date_precision_month
        THEN
            RETURN pk_date_utils.get_month_year(i_lang, i_prof, i_date);
        ELSIF i_precision = g_date_precision_year
        THEN
            RETURN pk_date_utils.get_year(i_lang, i_prof, i_date);
        ELSE
            RETURN pk_date_utils.date_chr_short_read_tsz(i_lang, i_date, i_prof.institution, i_prof.software);
        END IF;
    END;

    FUNCTION time_spent_convert
    (
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_management_follow_up IN management_follow_up.id_management_follow_up%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_time_spent VARCHAR2(2000);
        l_enc_count  PLS_INTEGER;
    
    BEGIN
    
        g_error     := 'CALL get_encounter_count';
        l_enc_count := get_encounter_count(i_episode => i_episode);
    
        IF l_enc_count > 0
        THEN
            -- calculate the time spent
            g_error := 'SELECT o_time_spent';
            SELECT SUM(time_spent)
              INTO l_time_spent
              FROM (SELECT decode(mfu.id_unit_time,
                                  g_id_unit_minutes,
                                  mfu.time_spent,
                                  pk_unit_measure.get_unit_mea_conversion(mfu.time_spent,
                                                                          mfu.id_unit_time,
                                                                          g_id_unit_minutes)) time_spent
                      FROM management_follow_up mfu
                     WHERE mfu.id_episode = i_episode
                       AND mfu.id_management_follow_up = i_management_follow_up
                        OR (i_management_follow_up IS NULL AND mfu.flg_status = pk_case_management.g_mfu_status_active));
        
        END IF;
    
        RETURN l_time_spent;
    END time_spent_convert;

    FUNCTION get_format_time_spent
    (
        i_lang         language.id_language%TYPE,
        i_val          management_follow_up.time_spent%TYPE,
        i_unit_measure unit_measure.id_unit_measure%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_round   management_follow_up.time_spent%TYPE;
        l_mod     management_follow_up.time_spent%TYPE;
        l_c_round VARCHAR2(20 CHAR);
        l_c_mod   VARCHAR2(20 CHAR);
        l_val     NUMBER;
    BEGIN
        IF i_unit_measure IS NOT NULL
        THEN
            l_val := pk_unit_measure.get_unit_mea_conversion(i_val,
                                                             i_unit_measure,
                                                             pk_paramedical_prof_core.g_id_unit_minutes);
        ELSE
            l_val := i_val;
        END IF;
    
        g_error := 'GET VALUES';
        IF i_val IS NULL
        THEN
            RETURN i_val;
        ELSE
            l_round := floor(l_val / g_hour);
            l_mod   := MOD(l_val, g_hour);
        END IF;
    
        g_error := 'SEASON VALUES';
        IF l_round < 10
        THEN
            l_c_round := '0' || l_round;
        ELSE
            l_c_round := l_round;
        END IF;
    
        IF l_mod < 10
        THEN
            l_c_mod := '0' || l_mod;
        ELSE
            l_c_mod := l_mod;
        END IF;
    
        g_error := 'RETURN FORMATTED STRING';
        RETURN l_c_round || ':' || l_c_mod || pk_message.get_message(i_lang, 'HOURS_SIGN');
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_format_time_spent;

    FUNCTION get_time_spent_send
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_val          IN management_follow_up.time_spent%TYPE,
        i_unit_measure IN unit_measure.id_unit_measure%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_round    management_follow_up.time_spent%TYPE;
        l_mod      management_follow_up.time_spent%TYPE;
        l_c_round  VARCHAR2(20 CHAR);
        l_c_mod    VARCHAR2(20 CHAR);
        l_val      NUMBER;
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt       VARCHAR(200 CHAR);
    BEGIN
        IF i_unit_measure IS NOT NULL
        THEN
            l_val := pk_unit_measure.get_unit_mea_conversion(i_val,
                                                             i_unit_measure,
                                                             pk_paramedical_prof_core.g_id_unit_minutes);
        ELSE
            l_val := i_val;
        END IF;
    
        g_error := 'GET VALUES';
        IF i_val IS NULL
        THEN
            RETURN i_val;
        ELSE
            l_round := floor(l_val / g_hour);
            l_mod   := MOD(l_val, g_hour);
        END IF;
    
        g_error := 'SEASON VALUES';
        IF l_round < 10
        THEN
            l_c_round := '0' || l_round;
        ELSE
            l_c_round := l_round;
        END IF;
    
        IF l_mod < 10
        THEN
            l_c_mod := '0' || l_mod;
        ELSE
            l_c_mod := l_mod;
        END IF;
        l_dt := pk_date_utils.date_send_tsz(i_lang, pk_date_utils.trunc_insttimezone(i_prof, current_timestamp), i_prof);
        l_dt := substr(l_dt, 1, 8) || l_c_round || l_c_mod || '00';
    
        g_error := 'RETURN FORMATTED STRING';
        RETURN l_dt;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_time_spent_send;

    FUNCTION get_followup_access
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        o_followup_access OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_category         category.id_category%TYPE;
        l_type_opinion     opinion_type.id_opinion_type%TYPE;
        l_follow_up_status VARCHAR2(2 CHAR);
        l_epis_type        episode.id_epis_type%TYPE := pk_episode.get_epis_type(i_lang, i_episode);
    
        CURSOR c_type_request
        (
            i_epis_type epis_type.id_epis_type%TYPE,
            i_category  category.id_category%TYPE
        ) IS
            SELECT ot.id_opinion_type
              FROM opinion_type ot
             WHERE ot.id_category = i_category
               AND ((i_epis_type IN
                   (pk_alert_constant.g_epis_type_home_health_care, pk_alert_constant.g_epis_type_hhc_process) AND
                   ot.id_opinion_type <> pk_opinion.g_ot_social_worker) OR
                   (i_epis_type NOT IN
                   (pk_alert_constant.g_epis_type_home_health_care, pk_alert_constant.g_epis_type_hhc_process) AND
                   ot.id_opinion_type <> pk_opinion.g_ot_social_worker_ds));
    BEGIN
    
        IF i_prof.software IN (pk_alert_constant.g_soft_nutritionist,
                               pk_alert_constant.g_soft_psychologist,
                               pk_alert_constant.g_soft_social)
        THEN
            l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        
            g_error := 'OPEN C_TYPE_REQUEST';
            OPEN c_type_request(l_epis_type, l_category);
            FETCH c_type_request
                INTO l_type_opinion;
            CLOSE c_type_request;
        
            OPEN o_followup_access FOR
                SELECT CASE
                            WHEN i_prof.software = epis.id_software THEN
                             'NA' -- Not Aplicable
                            WHEN o.id_opinion IS NULL THEN
                             'ND' -- No followup request
                            WHEN o.id_opinion IS NOT NULL
                                 AND o.id_episode_answer IS NULL
                                 AND ((o.flg_state = pk_opinion.g_opinion_req AND
                                 pk_opinion.check_approval_need(profissional(o.id_prof_questions,
                                                                                   e.id_institution,
                                                                                   epis.id_software),
                                                                      l_type_opinion) = pk_alert_constant.g_no) OR
                                 o.flg_state = pk_opinion.g_opinion_approved) THEN
                             pk_opinion.g_opinion_req -- Folloup request waiting for aproval
                            WHEN o.id_opinion IS NOT NULL
                                 AND o.id_episode_answer IS NULL
                                 AND o.flg_state = pk_opinion.g_opinion_req
                                 AND pk_opinion.check_approval_need(profissional(o.id_prof_questions,
                                                                                 e.id_institution,
                                                                                 epis.id_software),
                                                                    l_type_opinion) = pk_alert_constant.g_yes THEN
                             'ND'
                            WHEN o.id_opinion IS NOT NULL
                                 AND o.flg_state IN (pk_opinion.g_opinion_accepted, pk_opinion.g_opinion_approved) THEN
                             'OG' -- Ongoing                                      
                            ELSE
                             'NA' -- Not Aplicable
                        END follow_up_status,
                       epis.id_dep_clin_serv id_department_service,
                       epis.id_professional id_professional,
                       o.id_opinion id_opinion
                  FROM epis_info epis
                  JOIN episode e
                    ON e.id_episode = epis.id_episode
                   AND e.flg_ehr = pk_alert_constant.g_flg_ehr_n
                  LEFT JOIN opinion o
                    ON epis.id_episode = o.id_episode
                   AND o.id_opinion_type = l_type_opinion
                   AND o.flg_state NOT IN
                       (pk_opinion.g_opinion_cancel, pk_opinion.g_opinion_rejected, pk_opinion.g_opinion_over)
                 WHERE epis.id_episode = i_episode;
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'get_followup_access',
                                                     o_error);
    END get_followup_access;

    /********************************************************************************************
    *  Get current state of management follow-up for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_followup_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_FOLLOWUP_VIEWER_CHECK';
        l_episodes      table_number := table_number();
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
        -- current management follow-up records
        SELECT COUNT(*) cnt
          INTO l_cnt_completed
          FROM management_follow_up mfu
         WHERE mfu.id_episode IN (SELECT *
                                    FROM TABLE(l_episodes))
           AND mfu.flg_status = pk_case_management.g_mfu_status_active;
    
        -- fill in viewer checklist flag
        IF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_followup_viewer_check;

    /********************************************************************************************
    * Get patient's Psychologist Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Diets
    *    - Evaluation tools
    *    - Dietitian report
    *    - Dietitian requests
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @param i_episode                ID Episode
    * 
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_diagnosis_prof        Professional that creates/edit the diagnosis
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_interv_plan_prof      Professional that creates/edit the intervention plan
    * @ param o_follow_up             Follow up notes for the current episode
    * @ param o_follow_up_prof        Professional that creates the follow up notes
    * @ param o_psychologist          Patient diets
    * @ param o_psychologist_prof     Professional that prescribes the diets
    * @ param o_evaluation_tools      List of evaluation tools
    * @ param o_evaluation_tools_prof Professional that creates the evaluation
    * @ param o_dietitian_report         dietitian report
    * @ param o_dietitian_report_prof    Professional that creates/edit the dietitian report
    * @ param o_dietitian_request        dietitian request
    * @ param o_dietitian_request_prof   Professional that creates/edit the dietitian request
    * @ param o_request_origin        Y/N  - Indicates if the episode started with a request 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Nuno Coelho
    * @version                         
    * @since                           04-12-2018
    **********************************************************************************************/
    FUNCTION get_psycho_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --request
        o_psychologist_request      OUT pk_types.cursor_type,
        o_psychologist_request_prof OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_temp_cur                 pk_types.cursor_type;
        l_psycho_summary_view_type VARCHAR2(1 CHAR);
        l_category                 category.flg_type%TYPE;
        --
    BEGIN
    
        -- get view type
        l_psycho_summary_view_type := pk_sysconfig.get_config(i_code_cf => 'SUMMARY_VIEW_ALL', i_prof => i_prof);
        l_category                 := pk_prof_utils.get_category(i_lang, i_prof);
    
        g_error := 'CALL get_psychologist_requests_summary';
        IF NOT get_psycho_requests_summary(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_episode       => i_episode,
                                           o_requests      => o_psychologist_request,
                                           o_requests_prof => o_psychologist_request_prof,
                                           o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_psychologist_request);
            pk_types.open_my_cursor(o_psychologist_request_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_PSYCHOLOGIST_SUMMARY',
                                                     o_error);
        
    END get_psycho_summary;

    /********************************************************************************************
    * Get the dietitian summary screen labels
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_dietitian_summary_labels   Social summary screen labels  
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/04/
    **********************************************************************************************/
    FUNCTION get_psycho_summary_labels
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        o_psychologist_summary_labels OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET LABELS';
        pk_alertlog.log_debug('GET_DIETITIAN_SUMMARY_LABELS - get all labels for the psychologist summary screen');
        IF NOT get_message_array(i_lang         => i_lang,
                                 i_code_msg_arr => table_varchar('PARAMEDICAL_T027', 'PARAMEDICAL_T001'),
                                 i_prof         => i_prof,
                                 o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_exception;
        END IF;
    
        --    
        OPEN o_psychologist_summary_labels FOR
            SELECT t_table_message_array('PARAMEDICAL_T027') psycho_summary_main_header,
                   t_table_message_array('PARAMEDICAL_T001') psycho_request_header
              FROM dual;
        --      
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_psychologist_summary_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_PSYCHOLIST_SUMMARY_LABELS',
                                                     o_error);
        
    END get_psycho_summary_labels;

    /*
    * Get Psychologist requests list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param o_requests       requests cursor
    * @param o_requests_prof  requests cursor prof
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Nuno Coelho
    * @version                 
    * @since                  04-12-2018
    */
    FUNCTION get_psycho_requests_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_requests      OUT pk_types.cursor_type,
        o_requests_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        t_table_message_array pk_paramedical_prof_core.table_message_array;
        l_label_any_prof      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'CONSULT_REQUEST_T021');
    BEGIN
        g_error := 'GET_PSYCHOLOGIST_REQUESTS_SUMMARY BEGIN';
        pk_alertlog.log_debug(g_error);
    
        IF get_psycho_epis_origin_type(i_lang, i_prof, i_episode) = 'R'
        THEN
            IF NOT get_message_array(i_lang         => i_lang,
                                     i_code_msg_arr => table_varchar('PARAMEDICAL_T026',
                                                                     'CONSULT_REQUEST_T003',
                                                                     'CONSULT_REQUEST_T024',
                                                                     'CONSULT_REQUEST_T004',
                                                                     'SCH_T004'),
                                     i_prof         => i_prof,
                                     o_desc_msg_arr => t_table_message_array)
            THEN
                RAISE g_exception;
            END IF;
        
            --
            g_error := 'OPEN o_requests';
            OPEN o_requests FOR
                SELECT o.id_opinion        id,
                       o.id_episode_answer id_episode,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T024')) ||
                       nvl((SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                             FROM clinical_service cs
                            WHERE cs.id_clinical_service = o.id_clinical_service),
                           pk_paramedical_prof_core.c_dashes) request_type,
                       --reason
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T003')) ||
                       nvl(decode(o.id_opinion_type,
                                  pk_opinion.g_ot_case_manager,
                                  pk_opinion.get_cm_req_reason(i_lang, i_prof, o.id_opinion),
                                  o.desc_problem),
                           pk_paramedical_prof_core.c_dashes) request_reason,
                       --origin
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T004')) ||
                       pk_translation.get_translation(i_lang, et.code_epis_type) || pk_opinion.g_dash ||
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, o.id_prof_questions, NULL, o.id_episode) || ' (' ||
                       nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions),
                           pk_paramedical_prof_core.c_dashes) || ')' request_origin,
                       --profissional      
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SCH_T004')) ||
                       nvl2(o.id_prof_questioned,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                            l_label_any_prof) name_prof_request_type,
                       --notas
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T026')) ||
                       nvl(o.notes, pk_paramedical_prof_core.c_dashes) prof_answers,
                       pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                         i_prof,
                                                                         o.dt_problem_tstz,
                                                                         op.id_professional,
                                                                         o.dt_last_update,
                                                                         o.id_episode) last_update_info
                  FROM opinion o
                  LEFT OUTER JOIN opinion_prof op
                    ON (o.id_opinion = op.id_opinion AND op.flg_type = 'E')
                  LEFT OUTER JOIN opinion_type ot
                    ON ot.id_opinion_type = o.id_opinion_type
                  LEFT OUTER JOIN episode e
                    ON e.id_episode = o.id_episode
                  LEFT OUTER JOIN epis_type et
                    ON et.id_epis_type = e.id_epis_type
                  LEFT OUTER JOIN clinical_service cs
                    ON cs.id_clinical_service = o.id_clinical_service
                 WHERE o.id_episode_answer = i_episode
                 ORDER BY o.dt_approved DESC;
        
            --
            g_error := 'OPEN o_requests_prof';
            OPEN o_requests_prof FOR
                SELECT o.id_opinion id,
                       o.id_episode_answer id_episode,
                       pk_tools.get_prof_description(i_lang, i_prof, op.id_professional, o.dt_last_update, o.id_episode) prof_sign,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_problem_tstz, i_prof) dt,
                       o.flg_state flg_status,
                       pk_sysdomain.get_domain('OPINION.FLG_STATE', o.flg_state, i_lang) desc_status
                  FROM opinion o
                  LEFT OUTER JOIN opinion_prof op
                    ON (o.id_opinion = op.id_opinion AND op.flg_type = 'E')
                  LEFT OUTER JOIN opinion_type ot
                    ON ot.id_opinion_type = o.id_opinion_type
                  LEFT OUTER JOIN episode e
                    ON e.id_episode = o.id_episode
                  LEFT OUTER JOIN epis_type et
                    ON et.id_epis_type = e.id_epis_type
                  LEFT OUTER JOIN clinical_service cs
                    ON cs.id_clinical_service = o.id_clinical_service
                 WHERE o.id_episode_answer = i_episode
                 ORDER BY o.dt_problem_tstz DESC;
            --
        ELSIF get_psycho_epis_origin_type(i_lang, i_prof, i_episode) = 'C'
        THEN
        
            IF NOT get_message_array(i_lang         => i_lang,
                                     i_code_msg_arr => table_varchar('PARAMEDICAL_T026',
                                                                     'CONSULT_REQ_T015',
                                                                     'CONSULT_REQUEST_T024',
                                                                     'SCH_T004'),
                                     i_prof         => i_prof,
                                     o_desc_msg_arr => t_table_message_array)
            THEN
                RAISE g_exception;
            END IF;
        
            --
            g_error := 'OPEN o_requests';
            OPEN o_requests FOR
                SELECT cr.id_consult_req id,
                       ei.id_episode     id_episode,
                       --reason
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQ_T015')) ||
                       cr.notes request_reason,
                       --profissional      
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SCH_T004')) ||
                       nvl2(crp.id_professional,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, crp.id_professional),
                            l_label_any_prof) name_prof_request_type,
                       --notas
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T026')) ||
                       crp.denial_justif prof_answers
                  FROM epis_info ei
                  JOIN consult_req cr
                    ON (ei.id_schedule = cr.id_schedule)
                  JOIN consult_req_prof crp
                    ON (crp.id_consult_req = cr.id_consult_req AND crp.flg_status = 'A')
                 WHERE ei.id_episode = i_episode
                 ORDER BY cr.dt_scheduled_tstz DESC;
        
            --
            g_error := 'OPEN o_requests_prof';
            OPEN o_requests_prof FOR
                SELECT cr.id_consult_req id,
                       ei.id_episode id_episode,
                       pk_tools.get_prof_description(i_lang,
                                                     i_prof,
                                                     cr.id_prof_req,
                                                     crp.dt_consult_req_prof_tstz,
                                                     ei.id_episode) prof_sign,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) dt,
                       crp.flg_status flg_status,
                       pk_sysdomain.get_domain('CONSULT_REQ.FLG_STATUS', crp.flg_status, i_lang) desc_status
                  FROM epis_info ei
                  JOIN consult_req cr
                    ON (ei.id_schedule = cr.id_schedule)
                  JOIN consult_req_prof crp
                    ON (crp.id_consult_req = cr.id_consult_req AND crp.flg_status = 'A')
                 WHERE ei.id_episode = i_episode
                 ORDER BY cr.dt_scheduled_tstz DESC;
            --
        ELSE
            --this episode is an appointment
            pk_types.open_my_cursor(o_requests);
            pk_types.open_my_cursor(o_requests_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PSYCHOLOGIST_REQUESTS_SUMMARY',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_requests);
            pk_types.open_my_cursor(o_requests_prof);
            RETURN FALSE;
    END get_psycho_requests_summary;

    /********************************************************************************************
    * Get psychologist episode origin type
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID
    *
    * @return                         A for appointments or R for requests
    *
    * @author                          Nuno Coelho
    * @version                         
    * @since                           04-12-2018
    **********************************************************************************************/
    FUNCTION get_psycho_epis_origin_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        --
        l_psycho_epis      VARCHAR2(1 CHAR);
        l_count            PLS_INTEGER;
        l_count_apointment PLS_INTEGER;
    BEGIN
        g_error := 'GET_PSYCHOLOGIST_EPIS_TYPE BEGIN';
        pk_alertlog.log_debug(g_error);
        --
        SELECT COUNT(*)
          INTO l_count
          FROM opinion o
         WHERE o.id_episode_answer = i_id_epis;
        --
        SELECT COUNT(*)
          INTO l_count_apointment
          FROM epis_info ei
          JOIN consult_req cr
            ON (ei.id_schedule = cr.id_schedule)
         WHERE ei.id_episode = i_id_epis;
        --
    
        IF l_count <> 0
        THEN
            --request
            l_psycho_epis := pk_paramedical_prof_core.g_paramedical_epis_origin_r;
        ELSIF l_count_apointment <> 0
        THEN
            --appointment request
            l_psycho_epis := pk_paramedical_prof_core.g_paramedical_epis_origin_c;
        ELSE
            --appointment
            l_psycho_epis := pk_paramedical_prof_core.g_paramedical_epis_origin_a;
        END IF;
        RETURN l_psycho_epis;
    EXCEPTION
        WHEN OTHERS THEN
            --
            RETURN l_psycho_epis;
    END get_psycho_epis_origin_type;

    /********************************************************************************************
    * Get the Follow-up requests summary, concatenated as a String (CLOB).
    * The information includes: Diagnosis, Intervention plans, Follow-up notes and Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = Social Worker)
    * @ param o_follow_up_request_summary  Array with all information, where each 
    *                                      position has a diferent type of data.
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/04/21
    **********************************************************************************************/
    FUNCTION get_follow_up_req_sum_str
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        o_follow_up_request_summary OUT table_clob,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_follow_up_request_summary table_clob := table_clob();
        l_summary_temp              CLOB;
        l_summary_index             PLS_INTEGER := 1;
    BEGIN
        pk_alertlog.log_debug('GET_FOLLOW_UP_REQ_SUM_STR - get follow up requests summary as a string!');
        --title
        g_error := 'Get title';
        l_follow_up_request_summary.extend;
        l_follow_up_request_summary(l_summary_index) := pk_message.get_message(i_lang, 'CONSULT_REQUEST_T031') ||
                                                        '<br>';
        l_summary_index := l_summary_index + 1;
        --
    
        --create complete summary:
        g_error := 'Get Diagnosis summary str';
        --1 - Diagnosis
        IF NOT get_summ_page_diag_str(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => i_patient,
                                      i_episode       => i_episode,
                                      i_opinion_type  => pk_opinion.g_ot_psychology,
                                      o_diagnosis_str => l_summary_temp,
                                      o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
            --
        END IF;
        --
        g_error := 'Get Intervention plan summary str';
        --2 - Intervention plans
        IF NOT get_interv_plan_summary_str(i_lang                 => i_lang,
                                           i_prof                 => i_prof,
                                           i_patient              => i_patient,
                                           i_episode              => i_episode,
                                           i_opinion_type         => pk_opinion.g_ot_psychology,
                                           o_interv_plan_summ_str => l_summary_temp,
                                           o_error                => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
        END IF;
    
        g_error := 'Get Follow up notes summary str';
        --3 - Follow-up notes
        IF NOT get_followup_notes_str(i_lang      => i_lang,
                                      i_prof      => i_prof,
                                      i_episode   => i_episode,
                                      o_follow_up => l_summary_temp,
                                      o_error     => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
        END IF;
        --
    
        g_error := 'Get Follow up notes summary str';
        --4 - Reports
        IF NOT get_paramed_report_str(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_episode      => i_episode,
                                      i_opinion_type => pk_opinion.g_ot_psychology,
                                      o_report       => l_summary_temp,
                                      o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
        END IF;
        --
        o_follow_up_request_summary := l_follow_up_request_summary;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_FOLLOW_UP_REQ_SUM_STR',
                                                     o_error);
        
    END get_follow_up_req_sum_str;

    FUNCTION get_opinion_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_opinion_type OUT opinion_type.id_opinion_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_today            TIMESTAMP WITH LOCAL TIME ZONE;
        l_category         category.id_category%TYPE;
        l_epis_type        epis_type.id_epis_type%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        CURSOR c_type_request IS
            SELECT ot.id_opinion_type
              FROM opinion_type ot
              JOIN opinion_type_category otc
                ON ot.id_opinion_type = otc.id_opinion_type
             WHERE ((otc.id_category = l_category AND otc.id_profile_template IS NULL) OR
                   (otc.id_profile_template = l_profile_template))
               AND ((l_epis_type IN
                   (pk_alert_constant.g_epis_type_home_health_care, pk_alert_constant.g_epis_type_hhc_process) AND
                   ot.id_opinion_type <> pk_opinion.g_ot_social_worker) OR
                   (l_epis_type NOT IN
                   (pk_alert_constant.g_epis_type_home_health_care, pk_alert_constant.g_epis_type_hhc_process) AND
                   ot.id_opinion_type <> pk_opinion.g_ot_social_worker_ds));
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_today        := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
    
        --l_type_opinion := pk_sysconfig.get_config('ID_OPINION_TYPE', i_prof);
    
        g_error            := 'GET PROF CATEGORY';
        l_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
        l_epis_type        := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_episode);
    
        g_error := 'OPEN C_TYPE_REQUEST';
        OPEN c_type_request;
        FETCH c_type_request
            INTO o_opinion_type;
        CLOSE c_type_request;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_OPINION_TYPE',
                                                     o_error);
            RETURN FALSE;
        
    END get_opinion_type;

    /********************************************************************************************
    * create a follow-up request and sets it as accepted. To be used in the All patient button when
    * the user presses OK in a valid episode (those without follow-up). Also used in the same button
    * inside the dietitian software.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             episode that will be followed
    * @param i_id_patient             episode patient
    * @param i_id_dcs                 episode dcs
    * @param i_id_prof                professional that is creating this follow up
    * @param o_id_opinion             resulting follow up request id
    * @param o_id_episode             resulting follow-up episode id
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *
    * @author                         Telmo
    * @version                        2.6.1.2
    * @since                          21-09-2011
    **********************************************************************************************/
    FUNCTION set_accepted_follow_up
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_dcs          IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_prof         IN opinion.id_prof_questioned%TYPE,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        o_id_opinion      OUT opinion.id_opinion%TYPE,
        o_id_episode      OUT opinion.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'SET_ACCEPTED_FOLLOW_UP';
        l_id_cs          dep_clin_serv.id_clinical_service%TYPE;
        l_dummy          opinion_hist.id_opinion_hist%TYPE;
        l_dummy2         opinion_prof.id_opinion_prof%TYPE;
        l_dummy4         epis_encounter.id_epis_encounter%TYPE;
        l_transaction_id VARCHAR2(4000);
        l_ext_exception EXCEPTION;
    BEGIN
    
        g_error := l_func_name || ' - GET CLINICAL SERVICE ID';
        SELECT id_clinical_service
          INTO l_id_cs
          FROM dep_clin_serv
         WHERE id_dep_clin_serv = nvl(i_id_dcs, -1);
    
        g_error := l_func_name || ' - CREATE FOLLOW-UP REQUEST';
        IF NOT pk_opinion.set_consult_request(i_lang                => i_lang,
                                              i_prof                => i_prof, -- este vai ser o id_prof_questions
                                              i_episode             => i_id_episode,
                                              i_patient             => i_id_patient,
                                              i_opinion             => NULL,
                                              i_opinion_type        => i_id_opinion_type,
                                              i_clin_serv           => l_id_cs,
                                              i_reason_ft           => NULL,
                                              i_reason_mc           => NULL,
                                              i_tbl_alert_diagnosis => NULL,
                                              i_prof_id             => i_prof.id, -- este vai ser o id_prof_questioned
                                              i_notes               => NULL,
                                              i_do_commit           => pk_alert_constant.g_no,
                                              i_followup_auto       => pk_alert_constant.g_yes,
                                              o_opinion             => o_id_opinion,
                                              o_opinion_hist        => l_dummy,
                                              o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- get remote transaction
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        -- create 'accepted' answer 
        g_error := l_func_name || ' - CREATE FOLLOW-UP ANSWER';
        IF NOT pk_opinion.set_request_answer(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_opinion          => o_id_opinion,
                                             i_patient          => i_id_patient,
                                             i_flg_state        => pk_opinion.g_opinion_accepted,
                                             i_management_level => NULL,
                                             i_notes            => NULL,
                                             i_cancel_reason    => NULL,
                                             i_transaction_id   => l_transaction_id,
                                             i_do_commit        => pk_alert_constant.g_no,
                                             o_opinion_prof     => l_dummy2,
                                             o_episode          => o_id_episode,
                                             o_epis_encounter   => l_dummy4,
                                             o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- fechar transacoes
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            o_id_opinion := NULL;
            o_id_episode := NULL;
            RETURN FALSE;
        WHEN l_ext_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            o_id_opinion := NULL;
            o_id_episode := NULL;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            o_id_opinion := NULL;
            o_id_episode := NULL;
            RETURN FALSE;
    END set_accepted_follow_up;
    /********************************************************************************************
    * Get the list of intervention plans for a patient episode for a list of episodes(i_id_epis).
    * The goal of this function is to return the data for the patient
    * 
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               List of Episode IDs (Epis type = psychologist)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Nuno Coelhos
    * @version                         0.1
    * @since                           2019/02/11
    **********************************************************************************************/
    FUNCTION get_interv_plan_psycho
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN table_number,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('COMMON_M008',
                                                                                          'PSYCHO_T010',
                                                                                          'SOCIAL_T124',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'PARAMEDICAL_T002',
                                                                                          'PARAMEDICAL_T022'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'OPEN LABELS CURSOR';
        OPEN o_screen_labels FOR
            SELECT t_table_message_array('PSYCHO_T010') interv_plan_main_header,
                   t_table_message_array('SOCIAL_T124') interv_plan_column,
                   t_table_message_array('PARAMEDICAL_T002') task_goal_column,
                   t_table_message_array('SOCIAL_T104') dt_begin_column,
                   t_table_message_array('SOCIAL_T125') dt_end_column,
                   t_table_message_array('SOCIAL_T004') state_column,
                   t_table_message_array('PARAMEDICAL_T022') social_diagnosis_column
              FROM dual;
    
        --
        g_error := 'GET CURSOR ALL INTERVENTION';
        OPEN o_interv_plan FOR
            SELECT id,
                   id_interv_plan,
                   interv_plan_desc,
                   id_task_goal_det,
                   desc_task_goal,
                   id_task_goal,
                   prof_sign,
                   dt_begin,
                   dt_begin_str,
                   dt_end,
                   dt_end_str,
                   has_notes,
                   notes,
                   flg_status,
                   desc_status,
                   get_id_diagnosis(i_lang, i_prof, tb_epis_diag) id_interv_diagnosis,
                   tb_desc_diag desc_interv_diagnosis,
                   pk_utils.concat_table(tb_desc_diag, '; ', 1, -1) desc_diagnosis
              FROM (SELECT id,
                           id_interv_plan,
                           interv_plan_desc,
                           id_task_goal_det,
                           id_task_goal,
                           desc_task_goal,
                           prof_sign,
                           dt_begin,
                           dt_begin_str,
                           dt_end,
                           dt_end_str,
                           has_notes,
                           notes,
                           flg_status,
                           desc_status,
                           tb_epis_diag,
                           get_desc_epis_diag(i_lang, i_prof, tb_epis_diag) tb_desc_diag
                      FROM (SELECT eip.id_epis_interv_plan id,
                                   eip.id_interv_plan id_interv_plan,
                                   CASE
                                        WHEN eip.id_interv_plan = 0 THEN
                                         eip.desc_other_interv_plan
                                        WHEN eip.id_interv_plan IS NULL THEN
                                         eip.desc_other_interv_plan
                                        ELSE
                                         pk_translation.get_translation(i_lang, ip.code_interv_plan)
                                    END interv_plan_desc,
                                   eip.id_task_goal_det,
                                   tgd.id_task_goal,
                                   get_task_goal_desc(i_lang, i_prof, eip.id_task_goal_det) desc_task_goal,
                                   pk_tools.get_prof_description(i_lang, i_prof, eip.id_professional, eip.dt_begin, NULL) prof_sign,
                                   pk_date_utils.dt_chr_tsz(i_lang, eip.dt_begin, i_prof) dt_begin,
                                   pk_date_utils.date_send_tsz(i_lang, eip.dt_begin, i_prof) dt_begin_str,
                                   pk_date_utils.dt_chr_tsz(i_lang, eip.dt_end, i_prof) dt_end,
                                   pk_date_utils.date_send_tsz(i_lang, eip.dt_end, i_prof) dt_end_str,
                                   --We are not considering the actual state of the record!
                                   decode(eip.notes,
                                          NULL,
                                          decode(pk_paramedical_prof_core.get_notes_desc(i_lang,
                                                                                         i_prof,
                                                                                         eip.id_cancel_info_det),
                                                 NULL,
                                                 NULL,
                                                 '(' || t_table_message_array('COMMON_M008') || ')'),
                                          
                                          '(' || t_table_message_array('COMMON_M008') || ')') has_notes,
                                   eip.notes notes,
                                   eip.flg_status flg_status,
                                   pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS',
                                                           decode(eip.flg_status,
                                                                  pk_alert_constant.g_flg_status_e,
                                                                  pk_alert_constant.g_flg_status_a,
                                                                  eip.flg_status),
                                                           i_lang) desc_status,
                                   get_epis_interv_plan_diag(i_lang, i_prof, eip.id_epis_interv_plan, NULL) tb_epis_diag
                              FROM epis_interv_plan eip
                              LEFT JOIN interv_plan ip
                                ON (eip.id_interv_plan = ip.id_interv_plan)
                              LEFT JOIN task_goal_det tgd
                                ON tgd.id_task_goal_det = eip.id_task_goal_det
                             WHERE eip.id_episode IN (SELECT column_value
                                                        FROM TABLE(i_id_epis))
                             ORDER BY pk_sysdomain.get_rank(i_lang,
                                                            'EPIS_INTERV_PLAN.FLG_STATUS',
                                                            decode(eip.flg_status,
                                                                   pk_alert_constant.g_flg_status_e,
                                                                   pk_alert_constant.g_flg_status_a,
                                                                   eip.flg_status)),
                                      eip.dt_begin,
                                      interv_plan_desc));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_PSYCHO',
                                                     o_error);
    END get_interv_plan_psycho;

    FUNCTION get_summary_labels
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_summary_labels OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET LABELS';
        pk_alertlog.log_debug('get_summary_labels - get all labels for the dietitian summary screen');
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('DIET_T118', 'PARAMEDICAL_T001'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_exception;
        END IF;
    
        --    
        OPEN o_summary_labels FOR
            SELECT t_table_message_array('DIET_T118') summary_main_header,
                   t_table_message_array('PARAMEDICAL_T001') request_header
              FROM dual;
        --      
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_summary_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_PARAMEDICAL_PROF_CORE',
                                                     'get_summary_labels',
                                                     o_error);
        
    END get_summary_labels;

    /********************************************************************************************
    * Get the list of intervention plans for a patient episode
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = psychologist)
    * @ param o_interv_plan           Intervention plan list
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2019/02/11
    **********************************************************************************************/
    FUNCTION get_interv_plan_psycho
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN episode.id_episode%TYPE,
        o_interv_plan   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        --
    BEGIN
        g_error := 'GET_INTERV_PLAN_PSYCHO - get the current episode data:';
        pk_alertlog.log_debug(g_error);
        --
        IF NOT get_interv_plan_psycho(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_id_epis       => table_number(i_id_epis),
                                      o_interv_plan   => o_interv_plan,
                                      o_screen_labels => o_screen_labels,
                                      o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_screen_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_PSYCHO',
                                                     o_error);
    END get_interv_plan_psycho;

    /********************************************************************************************
    * Get the history of a given intervention plan (when i_epis_interv_plan is not null) or the
    * history of all intervention plans (the current state) for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = psychologist)
    * @ param i_epis_interv_plan      ID Intervention plan
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2019/02/11
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist_psycho
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN episode.id_episode%TYPE,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_INTERV_PLAN_HIST_PSYCHO: i_id_epis = ' || i_id_epis || ', i_prof.id = ' || i_prof.id ||
                   ', i_id_epis_interv_plan = ' || i_id_epis_interv_plan;
        pk_alertlog.log_debug(g_error);
        --
    
        IF NOT get_interv_plan_hist_psycho(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_id_epis             => table_number(i_id_epis),
                                           i_id_epis_interv_plan => i_id_epis_interv_plan,
                                           o_interv_plan         => o_interv_plan,
                                           o_interv_plan_prof    => o_interv_plan_prof,
                                           o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_interv_plan_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_HIST_PSYCHO',
                                                     o_error);
    END get_interv_plan_hist_psycho;
    --

    /********************************************************************************************
    * Get the history of a given intervention plan (when i_epis_interv_plan is not null) or the
    * history of all intervention plans (the current state) for the patient
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID (Epis type = psychologist)
    * @ param i_epis_interv_plan      ID Intervention plan
    * @ param o_interv_plan           Cursor intervention plan history
    * @ param o_interv_plan_prof      Cursor with prof history information for the
    *                                 given Intervention plan
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Nuno Coelho
    * @version                         0.1
    * @since                           2019/02/11
    **********************************************************************************************/
    FUNCTION get_interv_plan_hist_psycho
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis             IN table_number,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        --
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
        l_category category.flg_type%TYPE;
    
    BEGIN
    
        g_error := 'GET_INTERV_PLAN_HIST_PSYCHO: i_id_epis is array ' || ', i_prof.id = ' || i_prof.id ||
                   ', i_id_epis_interv_plan = ' || i_id_epis_interv_plan;
        pk_alertlog.log_debug(g_error);
    
        l_category := pk_prof_utils.get_category(i_lang, i_prof);
        g_error    := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('PSYCHO_T010',
                                                                                          'SOCIAL_T082',
                                                                                          'SOCIAL_T124',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'SOCIAL_T107',
                                                                                          'SOCIAL_T108',
                                                                                          'SOCIAL_T109',
                                                                                          'PARAMEDICAL_T002'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF i_id_epis_interv_plan IS NOT NULL
        THEN
            g_error := 'GET CURSOR INTER_PLAN HISTORY';
            OPEN o_interv_plan FOR
                SELECT t.id_epis_interv_plan_hist id,
                       t.id_episode,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PSYCHO_T010')) || CASE
                            WHEN t.id_interv_plan = 0 THEN
                             t.desc_other_interv_plan
                            WHEN t.id_interv_plan IS NULL THEN
                             t.desc_other_interv_plan
                            ELSE
                             pk_translation.get_translation(i_lang, t.code_interv_plan)
                        END interv_plan_desc,
                       decode(l_category,
                              pk_alert_constant.g_cat_type_social,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T002')) ||
                              get_task_goal_desc(i_lang, i_prof, t.id_task_goal_det)) desc_task_goal,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T104')) ||
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_begin, i_prof) desc_dt_begin,
                       decode(t.dt_end,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T125')) ||
                              pk_date_utils.dt_chr_tsz(i_lang, t.dt_end, i_prof)) desc_dt_end,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T004')) ||
                       decode(t.flg_status,
                              pk_alert_constant.g_flg_status_e,
                              pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS',
                                                      pk_alert_constant.g_flg_status_a,
                                                      i_lang),
                              pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', t.flg_status, i_lang)) desc_status,
                       decode(t.notes,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082')) ||
                              t.notes) desc_notes,
                       decode(t.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                        'COMMON_M072')) ||
                              t.cancel_reason_desc,
                              NULL) cancel_reason,
                       decode(t.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              decode(t.cancel_notes_desc,
                                     NULL,
                                     NULL,
                                     pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                               'COMMON_M073')) ||
                                     t.cancel_notes_desc,
                                     NULL)) cancel_notes
                  FROM (SELECT eiph.id_epis_interv_plan_hist,
                               eiph.id_episode,
                               eiph.id_interv_plan,
                               eiph.desc_other_interv_plan,
                               ip.code_interv_plan,
                               eiph.id_task_goal_det,
                               eiph.dt_begin,
                               eiph.dt_end,
                               eiph.flg_status,
                               eiph.notes,
                               eiph.id_cancel_info_det,
                               pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, eiph.id_cancel_info_det) cancel_reason_desc,
                               pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, eiph.id_cancel_info_det) cancel_notes_desc,
                               eiph.dt_creation
                          FROM epis_interv_plan_hist eiph
                          LEFT JOIN interv_plan ip
                            ON (eiph.id_interv_plan = ip.id_interv_plan)
                         WHERE eiph.id_epis_interv_plan = i_id_epis_interv_plan) t
                 ORDER BY t.dt_creation DESC;
        
            g_error := 'GET CURSOR INTER_PLAN_PROF HISTORY';
            OPEN o_interv_plan_prof FOR
                SELECT eiph.id_epis_interv_plan_hist,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, eiph.dt_creation, i_prof) dt,
                       pk_tools.get_prof_description(i_lang, i_prof, eiph.id_professional, eiph.dt_creation, NULL) prof_sign,
                       eiph.flg_status flg_status,
                       CASE
                            WHEN eiph.flg_status = g_plan_active
                                 AND (SELECT COUNT(*)
                                        FROM epis_interv_plan_hist eiph2
                                       WHERE eiph2.id_epis_interv_plan = i_id_epis_interv_plan
                                         AND eiph2.dt_creation < eiph.dt_creation) > 1 THEN
                             pk_message.get_message(i_lang, 'MEDICATION_DETAILS_M055')
                            ELSE
                             get_interv_plan_state_desc(i_lang, i_prof, eiph.flg_status)
                        END desc_status,
                       eiph.id_task_goal_det,
                       get_task_goal_desc(i_lang, i_prof, eiph.id_task_goal_det) desc_task_goal
                  FROM epis_interv_plan_hist eiph
                 WHERE eiph.id_epis_interv_plan = i_id_epis_interv_plan
                 ORDER BY eiph.dt_creation DESC;
        ELSE
            g_error := 'GET CURSOR INTER_PLAN HISTORY';
            OPEN o_interv_plan FOR
                SELECT t.id_epis_interv_plan_hist id,
                       t.id_episode,
                       CASE
                            WHEN t.id_interv_plan = 0 THEN
                             t.desc_other_interv_plan
                            WHEN t.id_interv_plan IS NULL THEN
                             t.desc_other_interv_plan
                            ELSE
                             pk_translation.get_translation(i_lang, t.code_interv_plan)
                        END interv_plan_desc,
                       t.id_task_goal_det,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('PARAMEDICAL_T002')) ||
                       --ALERT-98764 - The goal field must be available also for SW, but we need flash changes to do that!
                       --The changes will be implemented in the Issue - ALERT-99008
                        decode(l_category,
                               pk_alert_constant.g_cat_type_social,
                               NULL,
                               get_task_goal_desc(i_lang, i_prof, t.id_task_goal_det)) desc_task_goal,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T104')) ||
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_begin, i_prof) desc_dt_begin,
                       decode(t.dt_end,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T125')) ||
                              pk_date_utils.dt_chr_tsz(i_lang, t.dt_end, i_prof)) desc_dt_end,
                       decode(t.notes,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082')) ||
                              t.notes) desc_notes,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T004')) ||
                       pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', t.flg_status, i_lang) desc_status,
                       decode(t.flg_status,
                              pk_alert_constant.g_flg_status_c,
                              pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                        'COMMON_M072')) ||
                              t.cancel_reason_desc,
                              NULL) cancel_reason,
                       decode(t.cancel_notes_desc,
                              NULL,
                              NULL,
                              decode(t.flg_status,
                                     pk_alert_constant.g_flg_status_c,
                                     pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                               'COMMON_M073')) ||
                                     t.cancel_notes_desc,
                                     NULL)) cancel_notes
                  FROM (SELECT eiph.id_epis_interv_plan_hist,
                               eiph.id_episode,
                               eiph.id_interv_plan,
                               eiph.desc_other_interv_plan,
                               ip.code_interv_plan,
                               eiph.id_task_goal_det,
                               eiph.dt_begin,
                               eiph.dt_end,
                               eiph.notes,
                               eiph.flg_status,
                               eiph.id_cancel_info_det,
                               pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, eiph.id_cancel_info_det) cancel_reason_desc,
                               pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, eiph.id_cancel_info_det) cancel_notes_desc,
                               eiph.dt_creation
                          FROM epis_interv_plan_hist eiph
                          LEFT JOIN interv_plan ip
                            ON (eiph.id_interv_plan = ip.id_interv_plan)
                         WHERE eiph.id_episode IN (SELECT column_value
                                                     FROM TABLE(i_id_epis))) t
                 ORDER BY t.dt_creation DESC;
        
            g_error := 'GET CURSOR INTER_PLAN_PROF HISTORY';
            OPEN o_interv_plan_prof FOR
                SELECT eiph.id_epis_interv_plan_hist id,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, eiph.dt_creation, i_prof) dt,
                       pk_tools.get_prof_description(i_lang, i_prof, eiph.id_professional, eiph.dt_creation, NULL) prof_sign,
                       eiph.flg_status flg_status,
                       CASE
                            WHEN eiph.flg_status = g_plan_active
                                 AND (SELECT COUNT(*)
                                        FROM epis_interv_plan_hist eiph2
                                       WHERE eiph2.id_epis_interv_plan = i_id_epis_interv_plan
                                         AND eiph2.dt_creation < eiph.dt_creation) > 1 THEN
                             pk_message.get_message(i_lang, 'MEDICATION_DETAILS_M055')
                            ELSE
                             get_interv_plan_state_desc(i_lang, i_prof, eiph.flg_status)
                        END desc_status,
                       eiph.id_task_goal_det,
                       get_task_goal_desc(i_lang, i_prof, eiph.id_task_goal_det) desc_task_goal
                  FROM epis_interv_plan_hist eiph
                 WHERE eiph.id_episode IN (SELECT column_value
                                             FROM TABLE(i_id_epis))
                 ORDER BY eiph.dt_creation DESC;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_interv_plan_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_INTERV_PLAN_HIST_PSYCHO',
                                                     o_error);
    END get_interv_plan_hist_psycho;

    /********************************************************************************************
    * Get the task/goal for the specific intervention plan
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_interv_plan         Intervention Plan
    *
    * @return                         task/goal defined for the specific intervention plan
    *
    * @author                          Nuno Coelho
    * @version                         0.1
    * @since
    **********************************************************************************************/
    FUNCTION get_task_goal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc_task_goal VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'Open task_goal';
        SELECT pk_translation.get_translation(i_lang, tg.code_task_goal)
          INTO l_desc_task_goal
          FROM task_goal tg, task_goal_task tgt
         WHERE tg.id_task_goal = tgt.id_task_goal
           AND tgt.id_interv_plan = i_id_interv_plan
           AND tgt.id_institution IN (i_prof.institution, 0)
           AND tgt.id_software IN (i_prof.software, 0)
           AND tgt.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_desc_task_goal;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_task_goal;
    /**
    * Returns the message for start follow-up
    *
    * @param i_lang                 Language identifier.
    * @param i_prof                 The professional record.
    * @param o_message              The message to show
    * @param o_error                Error object
    *
    * @return  True if success, false otherwise
    *
    * @author   Ana Moita
    * @version  2.8
    * @since    2019/07/05
    */
    FUNCTION get_followup_start_message
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_message OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_message_general VARCHAR2(200) := 'PARAMEDICAL_T019';
    
    BEGIN
    
        OPEN o_message FOR
            SELECT *
              FROM (SELECT (pk_message.get_message(i_lang, ot.code_start_follow_up) || chr(10) || chr(10) ||
                           pk_message.get_message(i_lang, l_code_message_general)) followup_start_message
                      FROM opinion_type ot
                     WHERE ot.id_opinion_type = pk_paramedical_prof_core.get_id_opinion_type(i_lang, i_prof, NULL));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_FOLLOWUP_START_MESSAGE',
                                              o_error);
            pk_types.open_my_cursor(o_message);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_followup_start_message;

    FUNCTION tf_followup_notes_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE
    ) RETURN t_tab_dd_block_data IS
    
        l_msg_oper_add  sys_message.desc_message%TYPE;
        l_msg_oper_edit sys_message.desc_message%TYPE;
        l_msg_oper_canc sys_message.desc_message%TYPE;
    
        l_return t_tab_dd_block_data;
    
    BEGIN
    
        l_msg_oper_add  := pk_message.get_message(i_lang, i_prof, 'COMMON_T030');
        l_msg_oper_edit := pk_message.get_message(i_lang, i_prof, 'COMMON_T029');
        l_msg_oper_canc := pk_message.get_message(i_lang, i_prof, 'COMMON_T032');
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   ddb.rank,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_return
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT *
                          FROM (SELECT mfu.id_management_follow_up id,
                                       mfu.flg_status,
                                       decode(mfu.id_parent,
                                              NULL,
                                              l_msg_oper_add,
                                              decode(mfu.flg_status,
                                                     pk_case_management.g_mfu_status_canc,
                                                     l_msg_oper_canc,
                                                     l_msg_oper_edit)) follow_up_notes_title,
                                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof) dt_start,
                                       get_format_time_spent(i_lang,
                                                             time_spent_convert(i_prof,
                                                                                mfu.id_episode,
                                                                                mfu.id_management_follow_up)) time_spent,
                                       nvl2(mfu.flg_end_followup,
                                            pk_sysdomain.get_domain(pk_list.g_yes_no, mfu.flg_end_followup, i_lang),
                                            pk_sysdomain.get_domain(pk_list.g_yes_no, pk_alert_constant.g_no, i_lang)) end_follow_up,
                                       
                                       get_partial_date_format(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_date      => mfu.dt_next_encounter,
                                                               i_precision => mfu.dt_next_enc_precision) next_follow_up,
                                       
                                       decode(mfu.flg_status,
                                              pk_case_management.g_mfu_status_canc,
                                              pk_translation.get_translation(i_lang, cr.code_cancel_reason)) cancel_reason,
                                       nvl2(mfu.notes, to_char(mfu.id_management_follow_up), NULL) follow_up_notes,
                                       
                                       decode(mfu.flg_status, pk_case_management.g_mfu_status_canc, mfu.notes_cancel, '') cancel_notes,
                                       pk_tools.get_prof_description(i_lang,
                                                                     i_prof,
                                                                     mfu.id_professional,
                                                                     mfu.dt_register,
                                                                     mfu.id_episode) || '; ' ||
                                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_register, i_prof) registered
                                  FROM management_follow_up mfu
                                  LEFT JOIN unit_measure um
                                    ON mfu.id_unit_time = um.id_unit_measure
                                  LEFT JOIN cancel_reason cr
                                    ON mfu.id_cancel_reason = cr.id_cancel_reason
                                 WHERE mfu.id_management_follow_up = i_mng_followup) unpivot include NULLS(data_source_val FOR data_source IN(follow_up_notes_title,
                                                                                                                                              dt_start,
                                                                                                                                              time_spent,
                                                                                                                                              end_follow_up,
                                                                                                                                              next_follow_up,
                                                                                                                                              follow_up_notes,
                                                                                                                                              cancel_reason,
                                                                                                                                              cancel_notes,
                                                                                                                                              registered)))) dd
          JOIN dd_block ddb
            ON ddb.area = pk_dynamic_detail.g_follow_up_notes
           AND ddb.internal_name = 'CREATE'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_return;
    
    END tf_followup_notes_detail;

    FUNCTION tf_followup_notes_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE
    ) RETURN t_tab_dd_block_data IS
    
        l_msg_oper_add  sys_message.desc_message%TYPE;
        l_msg_oper_edit sys_message.desc_message%TYPE;
        l_msg_oper_canc sys_message.desc_message%TYPE;
    
        l_return t_tab_dd_block_data;
    BEGIN
    
        l_msg_oper_add  := pk_message.get_message(i_lang, i_prof, 'COMMON_T030');
        l_msg_oper_edit := pk_message.get_message(i_lang, i_prof, 'COMMON_T029');
        l_msg_oper_canc := pk_message.get_message(i_lang, i_prof, 'COMMON_T032');
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank) * rn,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_return
          FROM (SELECT data_source, data_source_val, row_number() over(PARTITION BY data_source ORDER BY rownum) AS rn
                  FROM (SELECT decode(rn,
                                       cnt,
                                       l_msg_oper_add,
                                       decode(flg_status,
                                              pk_case_management.g_mfu_status_canc,
                                              l_msg_oper_canc,
                                              l_msg_oper_edit))
                               /*CASE
                                   WHEN rn = cnt THEN
                                    'Criação'
                                   WHEN rn <> cnt
                                        AND flg_status <> 'C' THEN
                                    'Edicão'
                                   WHEN flg_status = 'C' THEN
                                    'Cancelar'
                                   ELSE
                                    NULL
                               END*/ follow_up_notes_title,
                               decode(cnt,
                                      rn,
                                      decode(dt_start, NULL, NULL, dt_start),
                                      decode(dt_start, dt_start_prev, NULL, decode(dt_start, NULL, NULL, dt_start_prev))) dt_start,
                               decode(dt_start, dt_start_prev, NULL, NULL, 'DEL', dt_start) dt_start_new,
                               decode(cnt,
                                      rn,
                                      decode(time_spent, NULL, NULL, time_spent),
                                      decode(time_spent,
                                             time_spent_prev,
                                             NULL,
                                             decode(time_spent, NULL, NULL, time_spent_prev))) time_spent,
                               decode(time_spent, time_spent_prev, NULL, NULL, 'DEL', time_spent) time_spent_new,
                               
                               decode(cnt,
                                      rn,
                                      decode(end_follow_up, NULL, NULL, end_follow_up),
                                      decode(end_follow_up,
                                             end_follow_up_prev,
                                             NULL,
                                             decode(end_follow_up, NULL, NULL, end_follow_up_prev))) end_follow_up,
                               decode(end_follow_up, end_follow_up_prev, NULL, NULL, 'DEL', end_follow_up) end_follow_up_new,
                               
                               decode(cnt,
                                      rn,
                                      decode(next_follow_up, NULL, NULL, next_follow_up),
                                      decode(next_follow_up,
                                             next_follow_up_prev,
                                             NULL,
                                             decode(next_follow_up, NULL, NULL, next_follow_up_prev))) next_follow_up,
                               decode(next_follow_up, next_follow_up_prev, NULL, NULL, 'DEL', next_follow_up) next_follow_up_new,
                               decode(cnt,
                                      rn,
                                      decode(to_char(dbms_lob.getlength(follow_up_notes_text)), '0', NULL, follow_up_notes),
                                      decode(to_char(dbms_lob.compare(follow_up_notes_text, follow_up_notes_text_prev)),
                                             '0',
                                             NULL,
                                             decode(follow_up_notes, NULL, NULL, follow_up_notes_prev))) follow_up_notes,
                               decode(to_char(dbms_lob.compare(follow_up_notes_text, follow_up_notes_text_prev)),
                                      '0',
                                      NULL,
                                      follow_up_notes) follow_up_notes_new,
                               cancel_reason,
                               cancel_notes,
                               registered,
                               NULL request_white_line
                          FROM (SELECT id,
                                       row_number() over(ORDER BY dt_register DESC) rn,
                                       MAX(rownum) over() cnt,
                                       flg_status,
                                       flg_status_prev,
                                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_start, i_prof) dt_start,
                                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_start_prev, i_prof) dt_start_prev,
                                       time_spent,
                                       time_spent_prev,
                                       pk_sysdomain.get_domain(pk_list.g_yes_no, t.end_follow_up, i_lang) end_follow_up,
                                       pk_sysdomain.get_domain(pk_list.g_yes_no, t.end_follow_up_prev, i_lang) end_follow_up_prev,
                                       pk_paramedical_prof_core.get_partial_date_format(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_date      => t.dt_next_encounter,
                                                                                        i_precision => t.dt_next_enc_precision) next_follow_up,
                                       
                                       pk_paramedical_prof_core.get_partial_date_format(i_lang      => i_lang,
                                                                                        i_prof      => i_prof,
                                                                                        i_date      => t.dt_next_encounter_prev,
                                                                                        i_precision => t.dt_next_enc_precision_prev) next_follow_up_prev,
                                       follow_up_notes,
                                       follow_up_notes_prev,
                                       cancel_reason,
                                       cancel_notes,
                                       (SELECT m.notes
                                          FROM management_follow_up m
                                         WHERE m.id_management_follow_up = t.follow_up_notes) follow_up_notes_text,
                                       (SELECT m.notes
                                          FROM management_follow_up m
                                         WHERE m.id_management_follow_up = t.follow_up_notes_prev) follow_up_notes_text_prev,
                                       registered
                                  FROM (SELECT mfu.id_management_follow_up id,
                                               mfu.dt_register,
                                               mfu.flg_status,
                                               first_value(mfu.flg_status) over(ORDER BY mfu.dt_register rows BETWEEN 1 preceding AND CURRENT ROW) flg_status_prev,
                                               mfu.dt_start dt_start,
                                               first_value(mfu.dt_start) over(ORDER BY mfu.dt_register rows BETWEEN 1 preceding AND CURRENT ROW) dt_start_prev,
                                               pk_paramedical_prof_core.get_format_time_spent(i_lang,
                                                                                              pk_paramedical_prof_core.time_spent_convert(i_prof,
                                                                                                                                          mfu.id_episode,
                                                                                                                                          mfu.id_management_follow_up)) time_spent,
                                               first_value(pk_paramedical_prof_core.get_format_time_spent(i_lang,
                                                                                                          pk_paramedical_prof_core.time_spent_convert(i_prof,
                                                                                                                                                      mfu.id_episode,
                                                                                                                                                      mfu.id_management_follow_up))) over(ORDER BY mfu.dt_register rows BETWEEN 1 preceding AND CURRENT ROW) time_spent_prev,
                                               nvl(mfu.flg_end_followup, pk_alert_constant.g_no) end_follow_up,
                                               first_value(nvl(mfu.flg_end_followup, pk_alert_constant.g_no)) over(ORDER BY mfu.dt_register rows BETWEEN 1 preceding AND CURRENT ROW) end_follow_up_prev,
                                               mfu.dt_next_encounter,
                                               first_value(mfu.dt_next_encounter) over(ORDER BY mfu.dt_register rows BETWEEN 1 preceding AND CURRENT ROW) dt_next_encounter_prev,
                                               mfu.dt_next_enc_precision,
                                               first_value(mfu.dt_next_enc_precision) over(ORDER BY mfu.dt_register rows BETWEEN 1 preceding AND CURRENT ROW) dt_next_enc_precision_prev,
                                               --   nvl2(mfu.notes, to_char(mfu.id_management_follow_up), NULL) follow_up_notes,
                                               mfu.id_management_follow_up follow_up_notes,
                                               --                                                 first_valu(nvl2(mfu.notes, to_char(mfu.id_management_follow_up), NULL)) over(ORDER BY mfu.dt_register rows BETWEEN 1 preceding AND CURRENT ROW) follow_up_notes_prev,
                                               first_value(mfu.id_management_follow_up) over(ORDER BY mfu.dt_register rows BETWEEN 1 preceding AND CURRENT ROW) follow_up_notes_prev,
                                               
                                               decode(mfu.flg_status,
                                                      pk_case_management.g_mfu_status_canc, -- pk_case_management.g_mfu_status_canc,
                                                      pk_translation.get_translation(i_lang, cr.code_cancel_reason)) cancel_reason,
                                               decode(mfu.flg_status,
                                                      pk_case_management.g_mfu_status_canc,
                                                      mfu.notes_cancel,
                                                      '') cancel_notes,
                                               pk_tools.get_prof_description(i_lang,
                                                                             i_prof,
                                                                             mfu.id_professional,
                                                                             mfu.dt_register,
                                                                             mfu.id_episode) || '; ' ||
                                               pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_register, i_prof) registered
                                          FROM management_follow_up mfu
                                          LEFT JOIN unit_measure um
                                            ON mfu.id_unit_time = um.id_unit_measure
                                          LEFT JOIN cancel_reason cr
                                            ON mfu.id_cancel_reason = cr.id_cancel_reason
                                        CONNECT BY PRIOR mfu.id_parent = mfu.id_management_follow_up
                                         START WITH mfu.id_management_follow_up = i_mng_followup
                                         ORDER BY mfu.dt_register DESC) t)) unpivot include NULLS(data_source_val FOR data_source IN(follow_up_notes_title,
                                                                                                                                     dt_start,
                                                                                                                                     dt_start_new,
                                                                                                                                     time_spent,
                                                                                                                                     time_spent_new,
                                                                                                                                     end_follow_up,
                                                                                                                                     end_follow_up_new,
                                                                                                                                     next_follow_up,
                                                                                                                                     next_follow_up_new,
                                                                                                                                     follow_up_notes,
                                                                                                                                     follow_up_notes_new,
                                                                                                                                     cancel_reason,
                                                                                                                                     cancel_notes,
                                                                                                                                     registered,
                                                                                                                                     request_white_line))) dd
          JOIN dd_block ddb
            ON ddb.area = pk_dynamic_detail.g_follow_up_notes
           AND ddb.internal_name = 'CREATE'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_return;
    END tf_followup_notes_hist;

    FUNCTION get_followup_notes_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tab_dd_block_data t_tab_dd_block_data;
        l_tab_dd_data       t_tab_dd_data := t_tab_dd_data();
        l_data_source_list  table_varchar := table_varchar();
    BEGIN
    
        l_tab_dd_block_data := tf_followup_notes_detail(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_mng_followup => i_mng_followup);
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => data_code_message)
                                  WHEN flg_type = 'L1'
                                       AND data_code_message IS NULL THEN
                                   data_source_val
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                              --For L1, it will only show the message available in dd_code_source.
                              --If there is no message configured in dd_code_source, it will instead show
                              --the info from data_source_val
                                  WHEN flg_type = 'L1'
                                       AND data_code_message IS NULL THEN
                                   NULL
                                  ELSE
                                   CASE
                                       WHEN flg_clob = pk_alert_constant.g_yes THEN
                                        NULL
                                       ELSE
                                        data_source_val
                                   END
                              END, --VAL
                              flg_type,
                              flg_html,
                              CASE
                                  WHEN flg_clob = pk_alert_constant.g_yes THEN
                                   (SELECT notes
                                      FROM management_follow_up m
                                     WHERE m.id_management_follow_up = data_source_val)
                                  ELSE
                                   NULL
                              END,
                              flg_clob), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       rank,
                       db.id_dd_block,
                       ddc.flg_html,
                       ddc.internal_name,
                       ddc.flg_clob
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_follow_up_notes
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR ddc.flg_type = 'WL') --white lines from follow-up notes 
                UNION
                --New lines
                SELECT ddc.data_code_message,
                       ddc.flg_type,
                       NULL                  data_source_val,
                       ddc.data_source,
                       ddb.rank              rnk,
                       ddc.rank,
                       ddb.id_dd_block,
                       ddc.flg_html,
                       ddc.internal_name,
                       ddc.flg_clob
                  FROM dd_content ddc
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = pk_dynamic_detail.g_follow_up_notes
                  JOIN (SELECT DISTINCT id_dd_block --Join to show 'new lines' only for blocks that are available
                         FROM TABLE(l_tab_dd_block_data)
                        WHERE data_source_val IS NOT NULL) t
                    ON t.id_dd_block = ddb.id_dd_block
                 WHERE ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_follow_up_notes
                   AND ddc.flg_type = 'WL')
         ORDER BY rnk, rank;
    
        OPEN o_detail FOR
            SELECT dt.descr, dt.val, dt.flg_type, dt.flg_html, dt.val_clob, dt.flg_clob
              FROM (SELECT CASE
                                WHEN d.descr IS NULL THEN
                                 NULL
                                WHEN flg_type <> 'L1' THEN
                                 d.descr || ': '
                                ELSE
                                 d.descr
                            END descr,
                           --d.descr,
                           d.val,
                           d.flg_type,
                           d.flg_html,
                           d.val_clob,
                           d.flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn) dt
             WHERE ((dt.val IS NOT NULL) OR (dt.val_clob IS NOT NULL) OR (dbms_lob.getlength(dt.val_clob) > 0))
                OR (dt.flg_type IN ('L1', 'WL'))
             ORDER BY rn;
        NULL;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_FOLLOWUP_NOTES_DETAIL',
                                                     o_error);
            RETURN FALSE;
    END get_followup_notes_detail;

    FUNCTION get_followup_notes_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tab_dd_block_data t_tab_dd_block_data;
        l_tab_dd_data       t_tab_dd_data := t_tab_dd_data();
        l_data_source_list  table_varchar := table_varchar();
    BEGIN
    
        l_tab_dd_block_data := tf_followup_notes_hist(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_mng_followup => i_mng_followup);
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => data_code_message)
                                  WHEN flg_type = 'L1'
                                       AND data_code_message IS NULL THEN
                                   data_source_val
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                              --For L1, it will only show the message available in dd_code_source.
                              --If there is no message configured in dd_code_source, it will instead show
                              --the info from data_source_val
                                  WHEN flg_type = 'L1'
                                       AND data_code_message IS NULL THEN
                                   NULL
                                  ELSE
                                   CASE
                                       WHEN flg_clob = pk_alert_constant.g_yes THEN
                                        NULL
                                       ELSE
                                        data_source_val
                                   END
                              END, --VAL
                              flg_type,
                              flg_html,
                              CASE
                                  WHEN flg_clob = pk_alert_constant.g_yes THEN
                                   (SELECT notes
                                      FROM management_follow_up m
                                     WHERE m.id_management_follow_up = data_source_val)
                                  ELSE
                                   NULL
                              END,
                              flg_clob), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       rank,
                       db.id_dd_block,
                       ddc.flg_html,
                       ddc.internal_name,
                       ddc.flg_clob
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_follow_up_notes
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR ddc.flg_type = 'WL') --white lines from follow-up notes 
                UNION
                --New lines
                SELECT ddc.data_code_message,
                       ddc.flg_type,
                       NULL                  data_source_val,
                       ddc.data_source,
                       ddb.rank              rnk,
                       ddc.rank,
                       ddb.id_dd_block,
                       ddc.flg_html,
                       ddc.internal_name,
                       ddc.flg_clob
                  FROM dd_content ddc
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = pk_dynamic_detail.g_follow_up_notes
                  JOIN (SELECT id_dd_block --Join to show 'new lines' only for blocks that are available
                         FROM TABLE(l_tab_dd_block_data)
                        WHERE data_source_val IS NOT NULL) t
                    ON t.id_dd_block = ddb.id_dd_block
                 WHERE ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_follow_up_notes
                   AND ddc.flg_type = 'WL')
         ORDER BY rnk, rank;
    
        OPEN o_detail FOR
            SELECT dt.descr, dt.val, dt.flg_type, dt.flg_html, dt.val_clob, dt.flg_clob
              FROM (SELECT CASE
                                WHEN d.descr IS NULL THEN
                                 NULL
                                WHEN flg_type <> 'L1' THEN
                                 d.descr || ': '
                                ELSE
                                 d.descr
                            END descr,
                           --d.descr,
                           d.val,
                           d.flg_type,
                           d.flg_html,
                           d.val_clob,
                           d.flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn) dt
             WHERE ((dt.val IS NOT NULL) OR (dt.val_clob IS NOT NULL) OR (dbms_lob.getlength(dt.val_clob) > 0))
                OR (dt.flg_type IN ('L1', 'WL'))
             ORDER BY rn;
        NULL;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_FOLLOWUP_NOTES_HIST',
                                                     o_error);
            RETURN FALSE;
    END get_followup_notes_hist;

BEGIN
    -- Initialization
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_paramedical_prof_core;
/
