/*-- Last Change Revision: $Rev: 2028722 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:32 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ia_util_url IS

    -- Author  : ELISABETE.BUGALHO
    -- Created : 03-03-2009 
    -- Purpose : 
    /**********************************************************************************************
    * Returns URL of an aplication 
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_app_name            Name of the application for the URL 
    * @param i_id_episode          id of episode
    
    * @param o_url                 URL of application   
    * @param o_error               Error message
    * @param O_FLG_SHOW - Y - existe msg para mostrar; N - ñ existe
    * @param O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                            Tb pode mostrar combinações destes, qd é p/ mostrar
                          + do q 1 botão
    * @param O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso não exista URL
    * @param O_MSG - mensagem a enviar    
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.3
    * @since                       2009/03/03
    **********************************************************************************************/

    FUNCTION get_app_url
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_app_name   IN sys_config.id_sys_config%TYPE,
        i_id_episode IN NUMBER,
        o_url        OUT VARCHAR2,
        o_flg_show   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns URL of an aplication 
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_app_name            Name of the application for the URL 
    * @param i_id_episode          id of episode
    
    * @param o_url                 URL of application   
    * @param o_error               Error message
    * @param O_FLG_SHOW - Y - existe msg para mostrar; N - ñ existe
    * @param O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                            Tb pode mostrar combinações destes, qd é p/ mostrar
                          + do q 1 botão
    * @param O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso não exista URL
    * @param O_MSG - mensagem a enviar    
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.3
    * @since                       2009/03/03
    **********************************************************************************************/

    FUNCTION get_context_url
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_app_name   IN sys_config.id_sys_config%TYPE,
        i_id_episode IN NUMBER,
        o_url        OUT VARCHAR2,
        o_flg_show   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Returns URL of adw 
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_app_name            Name of the application for the URL 
    
    * @param o_url                 URL of application   
    * @param o_error               Error message
    * @param O_FLG_SHOW - Y - existe msg para mostrar; N - ñ existe
    * @param O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                            Tb pode mostrar combinações destes, qd é p/ mostrar
                          + do q 1 botão
    * @param O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso não exista URL
    * @param O_MSG - mensagem a enviar    
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.3
    * @since                       2009/03/03
    **********************************************************************************************/

    FUNCTION get_adw_url
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_url_name  IN sys_config.id_sys_config%TYPE,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns URL of adw 
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_app_name            Name of the application for the URL 
    *
    * @param o_url                 URL of application   
    * @param o_error               Error message
    * @param O_FLG_SHOW - Y - existe msg para mostrar; N - ñ existe
    * @param O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                            Tb pode mostrar combinações destes, qd é p/ mostrar
                          + do q 1 botão
    * @param O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso não exista URL
    * @param O_MSG - mensagem a enviar    
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Jorge Silva 
    * @version                     2.6.2
    * @since                       2014/09/25
    **********************************************************************************************/

    FUNCTION get_adw_open_browser
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_url_name  IN sys_config.id_sys_config%TYPE,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns URL of adw 
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_app_name            Name of the application for the URL 
    * @param i_url_prof            Y/N add a profissional ID
    * @param o_url                 URL of application   
    * @param o_error               Error message
    * @param O_FLG_SHOW - Y - existe msg para mostrar; N - ñ existe
    * @param O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                            Tb pode mostrar combinações destes, qd é p/ mostrar
                          + do q 1 botão
    * @param O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso não exista URL
    * @param O_MSG - mensagem a enviar    
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Jorge Silva 
    * @version                     2.6.2
    * @since                       2014/09/25
    **********************************************************************************************/
    FUNCTION get_adw_open_browser
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_url_name  IN sys_config.id_sys_config%TYPE,
        i_url_prof  IN VARCHAR2,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get URL from external systems using InterAlert v3 methods
    *
    * @param i_lang         Language ID
    * @param i_prof         Current profissional
    * @param i_app_cfg      Configuration key (id_sys_config) used to retrieve the name of the application
    * @param i_episode      Episode ID
    * @param i_patient      Patient ID
    * @param o_url          URL of application
    * @param o_flg_show     Show message? (Y - Yes; N - No)
    * @param o_button       Buttons to show (N - No; R - Read; C - Confirm)
    * @param o_msg_title    Message's title
    * @param o_msg          Message
    * @param o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.1
    * @since   29-Apr-10
    */
    FUNCTION get_app_url_iav3
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_app_cfg   IN sys_config.id_sys_config%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Get URL from external systems using InterAlert v3 methods
    *
    * @param i_lang         Language ID
    * @param i_prof         Current profissional
    * @param i_app_cfg      Configuration key (id_sys_config) used to retrieve the name of the application
    * @param i_episode      Episode ID
    * @param i_patient      Patient ID
    * @param o_url          URL of application
    * @param o_flg_show     Show message? (Y - Yes; N - No)
    * @param o_button       Buttons to show (N - No; R - Read; C - Confirm)
    * @param o_msg_title    Message's title
    * @param o_msg          Message
    * @param o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.1
    * @since   29-Apr-10
    */
    FUNCTION get_context_url_iav3
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_app_cfg   IN links.context_link%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get URL from external systems using InterAlert v3 methods
    *
    * @param i_lang         Language ID
    * @param i_prof         Current profissional
    * @param i_app_cfg      Configuration key (id_sys_config) used to retrieve the name of the application
    * @param i_episode      Episode ID
    * @param i_patient      Patient ID
    * @param i_code         table_varchar,
    * @param i_standard     table_varchar,
    * @param o_url          URL of application
    * @param o_flg_show     Show message? (Y - Yes; N - No)
    * @param o_button       Buttons to show (N - No; R - Read; C - Confirm)
    * @param o_msg_title    Message's title
    * @param o_msg          Message
    * @param o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  Paulo Teixeira
    * @version 2.6.3
    * @since   2014 02 14
    */
    FUNCTION get_app_url_info_button
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_app_cfg               IN sys_config.id_sys_config%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_patient               IN patient.id_patient%TYPE,
        i_code                  table_varchar,
        i_standard              table_varchar,
        i_description           table_varchar,
        i_age                   IN patient.age%TYPE,
        i_gender                IN patient.gender%TYPE,
        i_information_recipient IN VARCHAR2,
        i_url                   IN links.normal_link%TYPE,
        o_url                   OUT VARCHAR2,
        o_flg_show              OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_app_url_replace
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_app_cfg   IN sys_config.id_sys_config%TYPE,
        i_replace   IN table_varchar,
        i_url       IN VARCHAR2,
        i_id_content  IN VARCHAR2,
        i_begin_tag IN VARCHAR2 DEFAULT '{_',
        i_end_tag   IN VARCHAR2 DEFAULT '_}',
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns URL of adw for PP prescriptions
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_app_name            Name of the application for the URL 
    
    * @param o_url                 URL of application   
    * @param i_area                Type of buy (INST/PROF)
    * @param o_error               Error message
    * @param O_FLG_SHOW - Y - existe msg para mostrar; N - ñ existe
    * @param O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                            Tb pode mostrar combinações destes, qd é p/ mostrar
                          + do q 1 botão
    * @param O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso não exista URL
    * @param O_MSG - mensagem a enviar    
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Sérgio Santos
    * @version                     2.5.1
    * @since                       2011/03/11
    **********************************************************************************************/
    FUNCTION get_buy_portal_url
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_url_name  IN sys_config.id_sys_config%TYPE,
        i_url_hash  IN VARCHAR2,
        i_area      IN VARCHAR2,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns URL of adw for PP prescriptions
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_app_name            Name of the application for the URL 
    * @param i_area                Type of buy (INST/PROF)
    * @param o_url                 URL of application   
    * @param o_error               Error message
    * @param O_FLG_SHOW - Y - existe msg para mostrar; N - ñ existe
    * @param O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                            Tb pode mostrar combinações destes, qd é p/ mostrar
                          + do q 1 botão
    * @param O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso não exista URL
    * @param O_MSG - mensagem a enviar    
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Sérgio Santos
    * @version                     2.5.1
    * @since                       2011/03/11
    **********************************************************************************************/
    FUNCTION get_adw_presc_url
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_url_name  IN sys_config.id_sys_config%TYPE,
        i_area      IN VARCHAR2,
        o_url       OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);

    g_buy_type_prof CONSTANT VARCHAR2(4 CHAR) := 'PROF';
    g_buy_type_inst CONSTANT VARCHAR2(4 CHAR) := 'INST';

END pk_ia_util_url;
/
