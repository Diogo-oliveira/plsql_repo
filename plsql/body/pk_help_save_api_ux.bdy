/*-- Last Change Revision: $Rev: 2027198 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_help_save_api_ux AS

    FUNCTION set_prof_show_msg
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_code_message   IN sys_message.code_message%TYPE,
        i_id_register    IN prof_dont_show_again.id_register%TYPE DEFAULT NULL,
        i_field_register IN prof_dont_show_again.field_register%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_HELP_SAVE.SET_PROF_SHOW_MSG';
        IF NOT pk_help_save.set_prof_show_msg(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_code_message   => i_code_message,
                                              i_id_register    => i_id_register,
                                              i_field_register => i_field_register,
                                              o_error          => o_error)
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
                                              'SET_PROF_SHOW_MSG',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_prof_show_msg;

    FUNCTION get_prof_show_msg
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_code_message   IN sys_message.code_message%TYPE,
        i_id_register    IN prof_dont_show_again.id_register%TYPE DEFAULT NULL,
        i_field_register IN prof_dont_show_again.field_register%TYPE DEFAULT NULL,
        o_flg_show       OUT VARCHAR2,
        o_message        OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_HELP_SAVE.GET_PROF_SHOW_MSG';
        IF NOT pk_help_save.get_prof_show_msg(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_code_message   => i_code_message,
                                              i_id_register    => i_id_register,
                                              i_field_register => i_field_register,
                                              o_flg_show       => o_flg_show,
                                              o_message        => o_message,
                                              o_error          => o_error)
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
                                              'GET_PROF_SHOW_MSG',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_show_msg;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_help_save_api_ux;
/
