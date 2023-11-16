/*-- Last Change Revision: $Rev: 2027081 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_edis_hist AS

    -- Private type declarations
    TYPE t_tab_section_titles IS TABLE OF NUMBER INDEX BY VARCHAR2(200);

    -- Private constant declarations

    -- Private variable declarations
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_tbl_hist       t_table_edis_hist := NULL;
    g_curr_hist_line t_rec_edis_hist := NULL;

    g_section_titles t_tab_section_titles;
    g_curr_title     VARCHAR2(200);

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    PROCEDURE init_vars IS
    BEGIN
        g_sysdate_tstz   := current_timestamp;
        g_tbl_hist       := t_table_edis_hist();
        g_curr_hist_line := NULL;
    END init_vars;

    PROCEDURE reset_vars IS
    BEGIN
        g_section_titles.delete();
        g_curr_title := NULL;
    END reset_vars;

    PROCEDURE add_line_to_tbl IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'ADD_LINE_TO_TBL';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'ADD NEW LINE TO TBL';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF g_curr_hist_line IS NOT NULL
        THEN
            g_tbl_hist.extend;
            g_tbl_hist(g_tbl_hist.count) := g_curr_hist_line;
        END IF;
    END add_line_to_tbl;

    PROCEDURE add_section_title
    (
        i_lang          IN language.id_language%TYPE,
        i_code_title    IN VARCHAR2,
        i_title_desc    IN VARCHAR2,
        i_title_value   IN VARCHAR2,
        i_title_type    IN VARCHAR2 DEFAULT g_type_subtitle,
        i_add_empy_line IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) IS
    
        l_exception EXCEPTION;
    BEGIN
    
        -- if a previous section exists, a new line must separate the 2 sections (except content type titles)
        IF g_curr_title IS NOT NULL
           AND i_title_type <> g_type_content
           AND i_add_empy_line = pk_alert_constant.g_yes
        THEN
            pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => g_type_empty_line);
        END IF;
    
        pk_edis_hist.add_value(i_label => nvl(i_title_desc, pk_translation.get_translation(i_lang, i_code_title)),
                               i_value => i_title_value,
                               i_type  => i_title_type,
                               i_code  => i_code_title);
    
        g_curr_title := i_code_title;
    
        g_section_titles(i_code_title) := 1;
    END add_section_title;

    PROCEDURE add_line
    (
        i_history         IN NUMBER,
        i_dt_hist         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_record_state    IN VARCHAR2,
        i_desc_rec_state  IN VARCHAR2,
        i_desc_cat_viewer IN VARCHAR2 DEFAULT '',
        i_professional    IN professional.id_professional%TYPE DEFAULT NULL,
        i_episode         IN episode.id_episode%TYPE DEFAULT NULL
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'ADD_LINE';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL ADD_LINE_TO_TBL';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        add_line_to_tbl;
    
        g_error := 'CREATE NEW LINE';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        g_curr_hist_line := t_rec_edis_hist(id_history      => i_history,
                                            id_episode      => i_episode,
                                            desc_cat_viewer => i_desc_cat_viewer,
                                            id_professional => i_professional,
                                            dt_history      => i_dt_hist,
                                            tbl_labels      => table_varchar(),
                                            tbl_values      => table_clob(),
                                            tbl_types       => table_varchar(),
                                            tbl_codes       => table_varchar(),
                                            tbl_info_labels => table_varchar(pk_edis_hist.g_info_lbl_rec_state_format,
                                                                             pk_edis_hist.g_info_lbl_rec_action,
                                                                             pk_edis_hist.g_info_lbl_desc_rec_action),
                                            tbl_info_values => table_varchar(CASE
                                                                                 WHEN i_record_state = pk_alert_constant.g_cancelled THEN
                                                                                  pk_alert_constant.g_cancelled
                                                                                 ELSE
                                                                                  pk_alert_constant.g_active
                                                                             END,
                                                                             i_record_state,
                                                                             i_desc_rec_state));
    END add_line;

    PROCEDURE add_info_value
    (
        i_label IN VARCHAR2,
        i_value IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'ADD_INFO_VALUE';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'ADD INFO_LABEL';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        g_curr_hist_line.tbl_info_labels.extend;
        g_curr_hist_line.tbl_info_labels(g_curr_hist_line.tbl_info_labels.count) := i_label;
    
        g_error := 'ADD INFO_VALUE';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        g_curr_hist_line.tbl_info_values.extend;
        g_curr_hist_line.tbl_info_values(g_curr_hist_line.tbl_info_values.count) := i_value;
    END add_info_value;

    PROCEDURE add_value
    (
        i_lang        IN language.id_language%TYPE DEFAULT NULL,
        i_flg_call    IN VARCHAR2 DEFAULT g_call_detail,
        i_label       IN VARCHAR2,
        i_value       IN CLOB,
        i_type        IN VARCHAR2,
        i_code        IN VARCHAR2 DEFAULT '',
        i_title_code  IN table_varchar,
        i_title_desc  IN table_varchar,
        i_title_value IN table_varchar,
        i_title_type  IN table_varchar,
        i_old_value   IN CLOB DEFAULT ''
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'ADD_VALUE';
    
        l_msg_new_label sys_message.desc_message%TYPE;
        l_msg_del_label sys_message.desc_message%TYPE;
    
        PROCEDURE fill_title IS
        BEGIN
            FOR i IN 1 .. i_title_code.count
            LOOP
                IF i_title_code(i) IS NOT NULL
                   AND NOT g_section_titles.exists(i_title_code(i))
                THEN
                    add_section_title(i_lang        => i_lang,
                                      i_code_title  => i_title_code(i),
                                      i_title_desc  => i_title_desc(i),
                                      i_title_value => i_title_value(i),
                                      i_title_type  => i_title_type(i),
                                      -- multiple lines must have a separator only at the first title
                                      i_add_empy_line => CASE i
                                                             WHEN 1 THEN
                                                              pk_alert_constant.g_yes
                                                             ELSE
                                                              pk_alert_constant.g_no
                                                         END);
                END IF;
            END LOOP;
        END fill_title;
    
        PROCEDURE fill_value(i_val CLOB) IS
        BEGIN
        
            g_error := 'ADD LABEL';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_curr_hist_line.tbl_labels.extend;
            g_curr_hist_line.tbl_labels(g_curr_hist_line.tbl_labels.count) := i_label;
        
            g_error := 'ADD VALUE';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_curr_hist_line.tbl_values.extend;
            g_curr_hist_line.tbl_values(g_curr_hist_line.tbl_values.count) := i_val;
        
            g_error := 'ADD CODE';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_curr_hist_line.tbl_codes.extend;
            g_curr_hist_line.tbl_codes(g_curr_hist_line.tbl_codes.count) := i_code;
        
            g_error := 'ADD TYPE';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_curr_hist_line.tbl_types.extend;
            g_curr_hist_line.tbl_types(g_curr_hist_line.tbl_types.count) := i_type;
        END fill_value;
    
        PROCEDURE fill_new_value(i_val CLOB) IS
        BEGIN
            g_error := 'ADD LABEL';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_curr_hist_line.tbl_labels.extend;
            g_curr_hist_line.tbl_labels(g_curr_hist_line.tbl_labels.count) := pk_utils.append_str_if_not_null(i_label,
                                                                                                              ' ') ||
                                                                              l_msg_new_label;
        
            g_error := 'ADD VALUE';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_curr_hist_line.tbl_values.extend;
            g_curr_hist_line.tbl_values(g_curr_hist_line.tbl_values.count) := nvl(i_val, to_clob(l_msg_del_label));
        
            g_error := 'ADD CODE';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_curr_hist_line.tbl_codes.extend;
            g_curr_hist_line.tbl_codes(g_curr_hist_line.tbl_codes.count) := i_code;
        
            g_error := 'ADD TYPE';
            alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            g_curr_hist_line.tbl_types.extend;
            g_curr_hist_line.tbl_types(g_curr_hist_line.tbl_types.count) := g_type_new_content;
        END fill_new_value;
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        l_msg_new_label := pk_message.get_message(i_lang, 'EDIS_HIST_M001');
        l_msg_del_label := pk_message.get_message(i_lang, 'COMMON_M106');
    
        IF i_flg_call = g_call_detail
        THEN
            fill_title;
            fill_value(i_value);
        ELSIF i_flg_call = g_call_hist
        THEN
            IF (i_old_value IS NOT NULL AND i_value IS NULL)
               OR i_old_value <> i_value
            THEN
                fill_title;
                fill_new_value(i_value);
                fill_value(i_old_value);
            ELSIF i_old_value IS NULL
                  AND i_value IS NOT NULL
            THEN
                fill_title;
                fill_new_value(i_value);
            END IF;
        END IF;
    
    END add_value;

    PROCEDURE add_value
    (
        i_lang        IN language.id_language%TYPE DEFAULT NULL,
        i_flg_call    IN VARCHAR2 DEFAULT g_call_detail,
        i_label       IN VARCHAR2,
        i_value       IN CLOB,
        i_type        IN VARCHAR2,
        i_code        IN VARCHAR2 DEFAULT '',
        i_title_code  IN VARCHAR2 DEFAULT '',
        i_title_desc  IN VARCHAR2 DEFAULT '',
        i_title_value IN VARCHAR2 DEFAULT '',
        i_title_type  IN VARCHAR2 DEFAULT g_type_subtitle,
        i_old_value   IN CLOB DEFAULT ''
    ) IS
    BEGIN
        add_value(i_lang        => i_lang,
                  i_flg_call    => i_flg_call,
                  i_label       => i_label,
                  i_value       => i_value,
                  i_type        => i_type,
                  i_code        => i_code,
                  i_title_code  => table_varchar(i_title_code),
                  i_title_desc  => table_varchar(i_title_desc),
                  i_title_value => table_varchar(i_title_value),
                  i_title_type  => table_varchar(i_title_type),
                  i_old_value   => i_old_value);
    END add_value;

    PROCEDURE add_value_if_not_null
    (
        i_lang        IN language.id_language%TYPE DEFAULT NULL,
        i_flg_call    IN VARCHAR2 DEFAULT g_call_detail,
        i_label       IN VARCHAR2,
        i_value       IN CLOB,
        i_type        IN VARCHAR2,
        i_code        IN VARCHAR2 DEFAULT '',
        i_title_code  IN table_varchar,
        i_title_desc  IN table_varchar,
        i_title_value IN table_varchar,
        i_title_type  IN table_varchar,
        i_old_value   IN CLOB DEFAULT ''
    ) IS
    BEGIN
        IF (i_value IS NOT NULL AND dbms_lob.getlength(i_value) > 0)
           OR (i_old_value IS NOT NULL AND dbms_lob.getlength(i_old_value) > 0)
        THEN
            add_value(i_lang        => i_lang,
                      i_flg_call    => i_flg_call,
                      i_label       => i_label,
                      i_value       => i_value,
                      i_type        => i_type,
                      i_code        => i_code,
                      i_title_code  => i_title_code,
                      i_title_desc  => i_title_desc,
                      i_title_value => i_title_value,
                      i_title_type  => i_title_type,
                      i_old_value   => i_old_value);
        END IF;
    END add_value_if_not_null;

    PROCEDURE add_value_if_not_null
    (
        i_lang        IN language.id_language%TYPE DEFAULT NULL,
        i_flg_call    IN VARCHAR2 DEFAULT g_call_detail,
        i_label       IN VARCHAR2,
        i_value       IN CLOB,
        i_type        IN VARCHAR2,
        i_code        IN VARCHAR2 DEFAULT '',
        i_title_code  IN VARCHAR2 DEFAULT '',
        i_title_desc  IN VARCHAR2 DEFAULT '',
        i_title_value IN VARCHAR2 DEFAULT '',
        i_title_type  IN VARCHAR2 DEFAULT g_type_subtitle,
        i_old_value   IN CLOB DEFAULT ''
    ) IS
    BEGIN
        add_value_if_not_null(i_lang        => i_lang,
                              i_flg_call    => i_flg_call,
                              i_label       => i_label,
                              i_value       => i_value,
                              i_type        => i_type,
                              i_code        => i_code,
                              i_title_code  => table_varchar(i_title_code),
                              i_title_desc  => table_varchar(i_title_desc),
                              i_title_value => table_varchar(i_title_value),
                              i_title_type  => table_varchar(i_title_type),
                              i_old_value   => i_old_value);
    END add_value_if_not_null;

    FUNCTION tf_hist RETURN t_table_edis_hist IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_HIST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL ADD LAST LINE TO TBL BEFORE RETURN';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        add_line_to_tbl;
    
        RETURN g_tbl_hist;
    END tf_hist;

    /**
    * Get detail/history signature line
    * Based on PK_INP_HIDRICS.GET_SIGNATURE function
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_episode                Episode id
    * @param   i_date                      Date of the insertion/last change
    * @param   i_id_prof_last_change       Professional id that performed the insertion/ last change
    * @param   i_has_historical_changes    The record has historical of changes or not. Used to select the corresponding label ("Updated:" or "Documented:")
    *
    * @value  i_has_historical_changes      {*} 'Y'  Has historical data, use "Updated:" {*} 'N'  Has no historical data, use "Documented:"(Default)
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version 2.6.2
    * @since   01-08-2011
    */
    FUNCTION get_signature
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_date                   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_change    IN professional.id_professional%TYPE,
        i_has_historical_changes IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_desc_signature         IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SIGNATURE';
        --
        l_code_msg_documented CONSTANT sys_message.code_message%TYPE := 'COMMON_M107';
        l_code_msg_updated    CONSTANT sys_message.code_message%TYPE := 'COMMON_M127';
        --
        l_desc_signature sys_message.desc_message%TYPE;
        l_date           sys_message.desc_message%TYPE;
        l_prof_signature professional.name%TYPE;
        l_spec           VARCHAR2(200 CHAR);
        l_id_visit       episode.id_visit%TYPE;
    BEGIN
        IF i_desc_signature IS NOT NULL
        THEN
            l_desc_signature := i_desc_signature;
        ELSE
            IF i_has_historical_changes = pk_alert_constant.g_yes
            THEN
                l_desc_signature := pk_message.get_message(i_lang, i_prof, l_code_msg_updated);
            ELSE
                l_desc_signature := pk_message.get_message(i_lang, i_prof, l_code_msg_documented);
            END IF;
        END IF;
    
        g_error := 'CALL PK_EPISODE.GET_ID_VISIT. I_ID_EPISODE: ' || i_id_episode;
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_id_episode IS NOT NULL
        THEN
            l_id_visit := pk_episode.get_id_visit(i_episode => i_id_episode);
        END IF;
    
        g_error := 'CALL PK_PROF_UTILS.GET_SPEC_SIGN_BY_VISIT. I_ID_PROF_LAST_CHANGE: ' || i_id_prof_last_change ||
                   '; i_date: ' || CAST(i_date AS VARCHAR2) || '; id_visit: ' || l_id_visit;
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_spec := pk_prof_utils.get_spec_sign_by_visit(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_prof_id  => i_id_prof_last_change,
                                                       i_dt_reg   => i_date,
                                                       i_id_visit => l_id_visit);
    
        g_error := 'CALL PK_DATE_UTILS.DATE_CHAR_TSZ. I_DATE: ' || to_char(i_date);
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_date := pk_date_utils.date_char_tsz(i_lang, i_date, i_prof.institution, i_prof.software);
    
        g_error := 'CALL PK_PROF_UTILS.GET_NAME_SIGNATURE. I_PROF: ' || to_char(i_id_prof_last_change);
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_prof_signature := pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                             i_prof    => i_prof,
                                                             i_prof_id => i_id_prof_last_change);
    
        g_error := 'ADD INFO VALUE - CHANGE_DATE';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        add_info_value(i_label => pk_edis_hist.g_info_lbl_change_date, i_value => l_date);
    
        g_error := 'ADD INFO VALUE - CHANGE_PROF';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        add_info_value(i_label => pk_edis_hist.g_info_lbl_change_prof, i_value => l_prof_signature);
    
        g_error := 'ADD INFO VALUE - CHANGE_PROF_SPEC';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        add_info_value(i_label => pk_edis_hist.g_info_lbl_change_prof_spec, i_value => l_spec);
    
        g_error := 'RETURN SIGNATURE';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN l_desc_signature || ' ' || l_date || '; ' || l_prof_signature || --
        CASE WHEN l_spec IS NOT NULL THEN ' (' || l_spec || ')' END;
    END get_signature;
BEGIN
    init_vars;

    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(g_package);
END;
/
