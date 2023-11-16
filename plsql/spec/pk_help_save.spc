/*-- Last Change Revision: $Rev: 2028715 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_help_save AS

    /*
    * Has the professional marked the given message as 'Dont show this message again'?
    *
    * @param i_lang            ID language
    * @param i_prof            Professional
    * @param i_code_message    Message code
    * @param i_id_register     Generic ID
    * @param i_field_register  Table and column relative to the Id_register
    * @param o_flg_show        Should the message be shown? Y or N?
    * @param o_message         The message to be shown
    * @param o_error           Error information
    *
    * @return                  True on success, false otherwise
    *                        
    * @author                  José Castro
    * @version                 2.6
    * @since                   2010/08/27
    */

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
    ) RETURN BOOLEAN;

    /*
    * Marks the given message as 'Dont show this message again' for this professional.
    *
    * @param i_lang            ID language
    * @param i_prof            Professional
    * @param i_code_message    Message code
    * @param i_id_register     Generic ID
    * @param i_field_register  Table and column relative to the Id_register
    * @param o_error           Error information
    *
    * @return                  True on success, false otherwise
    *                        
    * @author                  José Castro
    * @version                 2.6
    * @since                   2010/08/27
    */

    FUNCTION set_prof_show_msg
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_code_message   IN sys_message.code_message%TYPE,
        i_id_register    IN prof_dont_show_again.id_register%TYPE DEFAULT NULL,
        i_field_register IN prof_dont_show_again.field_register%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_help_save;
/
