/*-- Last Change Revision: $Rev: 2027246 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inp_detail IS

    -- -- -- -- --
    -- FUNCTIONS
    -- -- -- -- --

    /**
    * get_signature_text                    Get the signature text given the professional and date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_episode                Episode id
    * @param   i_id_prof                   Professional 
    * @param   i_date                      Date
    * @param   i_code_desc                 Signature code message    
    * @param   i_flg_show_sw               Y-the software should be shown in the signature. N - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version v2.6.0.5
    * @since   18-Jan-2011
    */
    FUNCTION get_signature
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_date                IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_change IN professional.id_professional%TYPE,
        i_code_desc           IN sys_message.code_message%TYPE DEFAULT pk_prog_notes_constants.g_sm_registered,
        i_flg_show_sw         IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_id_software         IN software.id_software%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_desc_signature sys_message.desc_message%TYPE;
        l_spec           VARCHAR2(200 CHAR);
        l_user_zero      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_prof      => i_prof,
                                                                                 i_code_mess => 'COMMON_M141');
        l_date           TIMESTAMP WITH LOCAL TIME ZONE;
        l_soft_desc      sys_message.desc_message%TYPE;
        l_return         sys_message.desc_message%TYPE;
        l_error          t_error_out;
    BEGIN
        g_error := 'CALL pk_message.get_message. i_code_mess: ' || i_code_desc;
        pk_alertlog.log_debug(g_error);
        l_desc_signature := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => i_code_desc);
    
        g_error := 'CALL pk_prof_utils.get_spec_signature. i_prof_id: ' || i_id_prof_last_change || '; i_dt_reg: ' ||
                   CAST(l_date AS VARCHAR2);
        pk_alertlog.log_debug(g_error);
        IF i_id_prof_last_change = 0
        THEN
        
            l_return := l_desc_signature || pk_prog_notes_constants.g_space || l_user_zero ||
                        pk_prog_notes_constants.g_semicolon || -- 
                        pk_date_utils.date_char_tsz(i_lang, i_date, i_prof.institution, i_prof.software);
        ELSE
            l_spec := pk_prof_utils.get_spec_signature(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_prof_id => i_id_prof_last_change,
                                                       i_dt_reg  => i_date,
                                                       i_episode => i_id_episode);
        
            g_error := 'GET SIGNATURE';
            pk_alertlog.log_debug(g_error);
        
            IF NOT pk_utils.get_software_name(i_lang        => i_lang,
                                              i_id_software => i_id_software,
                                              o_soft_name   => l_soft_desc,
                                              o_error       => l_error)
            THEN
                l_soft_desc := NULL;
            END IF;
        
            l_return := l_desc_signature || pk_prog_notes_constants.g_colon ||
                        pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => i_id_prof_last_change) || --
                        CASE
                            WHEN l_spec IS NOT NULL THEN
                             pk_prog_notes_constants.g_space || --
                             pk_string_utils.surround(i_string => l_spec, i_pattern => pk_string_utils.g_pattern_parenthesis)
                        END --
                        || pk_prog_notes_constants.g_semicolon || --        
                        CASE
                            WHEN i_flg_show_sw = pk_alert_constant.g_yes
                                 AND l_soft_desc IS NOT NULL THEN
                             l_soft_desc || --
                             pk_prog_notes_constants.g_semicolon
                            WHEN i_flg_show_sw = pk_alert_constant.g_yes
                                 AND i_id_episode IS NOT NULL THEN
                             pk_prog_notes_utils.get_epis_sw_desc(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_episode => i_id_episode) || --
                             pk_prog_notes_constants.g_semicolon
                            ELSE
                             ''
                        END || pk_date_utils.date_char_tsz(i_lang, i_date, i_prof.institution, i_prof.software);
        END IF;
    
        RETURN l_return;
    
    END get_signature;

    /**
    * Adds a new value to a table_number object
    *
    * @param   io_table_1                    Table that will have the new value
    * @param   i_value_1                     New value
    * @param   io_table_2                    Table that will have the new value
    * @param   i_value_2                     New value
    * @param   io_table_3                    Table that will have the new value
    * @param   i_value_3                     New value
    *
    * @author  Sofia Mendes
    * @version v2.6.0.5
    * @since   13-Jan-2011
    */
    PROCEDURE add_3_values
    (
        io_table_1 IN OUT table_varchar,
        i_value_1  IN VARCHAR2,
        io_table_2 IN OUT table_varchar,
        i_value_2  IN VARCHAR2,
        io_table_3 IN OUT table_varchar,
        i_value_3  IN VARCHAR2
    ) IS
    BEGIN
        io_table_1.extend();
        io_table_1(io_table_1.count) := i_value_1;
    
        io_table_2.extend();
        io_table_2(io_table_2.count) := i_value_2;
    
        io_table_3.extend();
        io_table_3(io_table_3.count) := i_value_3;
    END add_3_values;

    /**
    * Adds a new value to a table_varchar object
    *
    * @param   io_table                    Table that will have the new value
    * @param   i_value                     New value
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   11-06-2010
    */
    PROCEDURE add_value
    (
        io_table IN OUT table_varchar,
        i_value  IN VARCHAR2
    ) IS
    BEGIN
    
        io_table.extend();
        io_table(io_table.count) := i_value;
    
    END add_value;

    /**
    * Calcule record state
    *
    * @param   io_table                    Table that will have the new value
    * @param   i_value                     New value
    *
    * @author  Filipe Silva
    * @version v2.6.1
    * @since   11-04-2011
    */
    FUNCTION get_info_values(i_row_flg_status IN VARCHAR2) RETURN table_varchar IS
        l_table table_varchar := table_varchar();
    BEGIN
        --RECORD_STATE
        add_value(io_table => l_table,
                  i_value  => CASE
                                  WHEN i_row_flg_status = pk_alert_constant.g_cancelled THEN
                                   pk_alert_constant.g_cancelled
                                  ELSE
                                   pk_alert_constant.g_active
                              END);
    
        RETURN l_table;
    END get_info_values;

    /**
    * Send identifier for flash to format the text.
    *
    * @param   io_table                    Table that will have the new value
    * @param   i_value                     New value
    *
    * @author  Filipe Silva
    * @version v2.6.1
    * @since   11-04-2011
    */

    FUNCTION get_info_labels RETURN table_varchar IS
        l_table table_varchar := table_varchar();
    BEGIN
        --RECORD_STATE
        add_value(io_table => l_table, i_value => 'RECORD_STATE_TO_FORMAT');
    
        RETURN l_table;
    END get_info_labels;

    /**********************************************************************************************
    * Adds a new item to the table of INPATIENT Detail
    *
    * @param   i_id_detail                   Identifier of the new item
    * @param   i_label_descr                 Label value to show
    * @param   i_value_descr                 Description of the value to show
    * @param   i_flg_type                    Type of item to insert
    * @param   i_flg_status                  Status of the item
    * @param   io_tab_det                    Structure type where the items will be added
    *
    * @author                                António Neto
    * @version                               v2.6.1
    * @since                                 17-May-2011
    **********************************************************************************************/
    PROCEDURE add_new_item
    (
        i_id_detail   IN NUMBER,
        i_label_descr IN VARCHAR2,
        i_value_descr IN CLOB,
        i_flg_type    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        io_tab_det    IN OUT t_table_inp_detail
    ) IS
    BEGIN
        io_tab_det.extend;
        io_tab_det(io_tab_det.count) := t_rec_inp_detail(id_detail   => i_id_detail,
                                                         label_descr => i_label_descr,
                                                         value_descr => i_value_descr,
                                                         flg_type    => i_flg_type,
                                                         flg_status  => i_flg_status);
    END add_new_item;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_inp_detail;
/
