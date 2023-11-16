/*-- Last Change Revision: $Rev: 2044267 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-08-09 14:44:58 +0100 (ter, 09 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_touch_option_ux AS

    FUNCTION set_prof_touch_options_mode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_institutions IN table_number,
        i_softwares    IN table_number,
        i_doc_areas    IN table_number,
        i_flg_modes    IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_TOUCH_OPTION.SET_PROF_TOUCH_OPTIONS_MODE';
        IF NOT pk_touch_option.set_prof_touch_options_mode(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_institutions => i_institutions,
                                                           i_softwares    => i_softwares,
                                                           i_doc_areas    => i_doc_areas,
                                                           i_flg_modes    => i_flg_modes,
                                                           o_error        => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'SET_PROF_TOUCH_OPTIONS_MODE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_prof_touch_options_mode;

    FUNCTION get_prof_touch_options_mode
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        o_options     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_PROF_TOUCH_OPTIONS_MODE';
        IF NOT pk_touch_option.get_prof_touch_options_mode(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_institution => i_institution,
                                                           i_software    => i_software,
                                                           o_options     => o_options,
                                                           o_error       => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'GET_PROF_TOUCH_OPTIONS_MODE',
                                              o_error);
            pk_types.open_my_cursor(o_options);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_touch_options_mode;

    FUNCTION get_touch_option_software
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_TOUCH_OPTION_SOFTWARE';
        IF NOT pk_touch_option.get_touch_option_software(i_lang  => i_lang,
                                                         i_prof  => i_prof,
                                                         i_inst  => i_inst,
                                                         o_list  => o_list,
                                                         o_error => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'GET_TOUCH_OPTION_SOFTWARE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_touch_option_software;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_touch_option_ux;
/
