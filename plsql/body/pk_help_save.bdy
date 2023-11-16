/*-- Last Change Revision: $Rev: 2027196 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_help_save AS

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
    
        l_count PLS_INTEGER;
    
    BEGIN
    
        g_error := 'COUNT ROWS';
        SELECT COUNT(*)
          INTO l_count
          FROM prof_dont_show_again p
         WHERE ((i_id_register IS NULL AND i_field_register IS NULL AND p.id_register IS NULL AND
               p.field_register IS NULL) OR (i_id_register IS NOT NULL AND i_field_register IS NOT NULL AND
               p.id_register = i_id_register AND p.field_register = i_field_register))
           AND p.id_professional = i_prof.id
           AND p.code_message = i_code_message;
    
        g_error := 'GET INFORMATION';
        IF l_count = 0
        THEN
            o_flg_show := pk_alert_constant.g_yes;
            o_message  := pk_message.get_message(i_lang, i_prof, i_code_message);
        ELSE
            o_flg_show := pk_alert_constant.g_no;
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
            RETURN FALSE;
    END get_prof_show_msg;

    FUNCTION set_prof_show_msg
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_code_message   IN sys_message.code_message%TYPE,
        i_id_register    IN prof_dont_show_again.id_register%TYPE DEFAULT NULL,
        i_field_register IN prof_dont_show_again.field_register%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count PLS_INTEGER;
    
    BEGIN
    
        g_error := 'COUNT ROWS';
        SELECT COUNT(*)
          INTO l_count
          FROM prof_dont_show_again p
         WHERE ((i_id_register IS NULL AND i_field_register IS NULL AND p.id_register IS NULL AND
               p.field_register IS NULL) OR (i_id_register IS NOT NULL AND i_field_register IS NOT NULL AND
               p.id_register = i_id_register AND p.field_register = i_field_register))
           AND p.id_professional = i_prof.id
           AND p.code_message = i_code_message;
    
        g_error := 'MARK AS DONT SHOW AGAIN';
        IF l_count = 0
        THEN
            INSERT INTO prof_dont_show_again
                (id_register, field_register, id_professional, code_message)
            VALUES
                (i_id_register, i_field_register, i_prof.id, i_code_message);
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
            RETURN FALSE;
    END set_prof_show_msg;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_help_save;
/
