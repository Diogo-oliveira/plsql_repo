/*-- Last Change Revision: $Rev: 2028784 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:55 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_login IS

    SUBTYPE t_prof_info IS pk_prof_utils.t_prof_info;

    /**
       OBJECTIVO:   Actualizar todos os registos necessários ao login do profissional 
       PARAMETROS:  Entrada:  I_LANG - Língua definida por defeito para o utilizador 
                    I_ID_PROF - Id do profissional 
              Saida:   O_ERROR - msg de erro 
          
      CRIAÇÃO: CRS 2005/02/22 
      NOTAS:  
    */
    FUNCTION set_login
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
       OBJECTIVO:   Actualizar todos os registos necessários ao logout do profissional 
       PARAMETROS:  Entrada:  I_LANG - Língua definida por defeito para o utilizador 
                    I_ID_PROF - Id do profissional 
                  I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                           como é retornada em PK_LOGIN.GET_PROF_PREF 
              Saida:   O_FLG_SHOW - Y - existe msg para mostrar; N - ñ existe  
                 O_MSG_TEXT - mensagem  
                 O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso 
                         O_FLG_SHOW = Y 
                 O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
                        Tb pode mostrar combinações destes, qd é p/ mostrar 
                      + do q 1 botão 
                 O_ERROR - msg de erro 
          
      CRIAÇÃO: CRS 2005/02/22 
      NOTAS:  
    */
    FUNCTION set_logout
    (
        i_lang          IN language.id_language%TYPE,
        i_id_prof       IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
       OBJECTIVO:   Obter preferências do profissional 
       PARAMETROS:  Entrada: I_LANG - Língua definida por defeito na BD 
                             I_ID_PROF - Id do profissional 
                   
                      Saida: O_LANG - ID da língua definida por defeito para o utilizador 
                             O_DESC_LANG - Nome da língua 
                             O_TIME - Timeout para o profissional 
                             O_FIRST_SCREEN - Nome do ficheiro a q o prof acede mal faça login 
                             O_PHOTO - URL para foto do médico 
                             O_NICK_NAME - nome abreviado do prof 
                             O_NAME - nome completo do prof 
                             O_CAT_TYPE - tipo de categoria do prof: D - médico, N - enfermeiro, P - farmacêutico, 
                                                                     A - administrativo, T - técnico, O - outro  
                             O_CLIN_CAT - Indicação se é uma categoria médica: Y / N 
                             O_HEADER - Indicação se tem acesso aos atalhos do cabeçalho: Y / N  
                             O_SHORTCUT - atalho para a alocação de instituição / sala, se for o caso 
                             O_NUM_MECAN - Número Mecanográfico do profissional
                             O_ERROR - msg de erro 
      
      CRIAÇÃO: CRS 2005/02/22 
      ALETRAÇÃO: CRS 2006/10/30 Comentado código de pesquisa de última alocação do user 
      NOTAS: O par. de entrada I_LANG é a língua definida por defeito na BD, para ser 
           usado em GET_MESSAGE caso não exista registo em PROF_PREFERENCES 
    */
    FUNCTION get_prof_pref
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof      IN OUT profissional,
        o_lang         OUT language.id_language%TYPE,
        o_desc_lang    OUT language.desc_language%TYPE,
        o_time         OUT prof_preferences.timeout%TYPE,
        o_first_screen OUT prof_preferences.first_screen%TYPE,
        o_photo        OUT VARCHAR2,
        o_nick_name    OUT professional.nick_name%TYPE,
        o_name         OUT professional.name%TYPE,
        o_cat_type     OUT category.flg_type%TYPE,
        o_clin_cat     OUT category.flg_clinical%TYPE,
        o_header       OUT VARCHAR2,
        o_shortcut     OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_num_mecan    OUT prof_institution.num_mecan%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE prof_out_automatic
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_error          OUT t_error_out
    );

    /** @headcom
    * Public Function. Obter a lista de profissionais para mudança de login por foto.   
    *
    * @param      I_LANG              Língua registada como preferência do profissional
    * @param      I_PROF        object (ID do profissional, ID da instituição, ID do software)
    * @param      I_PROF_CAT_TYPE     categoria do profissional (flag)
    * @param      O_INFO              info
    * @param      O_ERROR             erro
    *
    * @return     boolean
    * @author     SS
    * @version    0.1
    * @since      2006/09/19 
    * @notes    Inclui o utilizador actual; os médicos / enfermeiros alocados à mesma sala preferencial do utilizador actual; 
         e todos os outros profissionais alocados ao mesmo departamento / serv. clínico, excepto administrativos e técnicos 
    */
    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Obter a lista de profissionais para mudança de login por foto.   
    *
    * @param      I_LANG              Língua registada como preferência do profissional
    * @param      I_PROF        object (ID do profissional, ID da instituição, ID do software)
    * @param      I_PROF_CAT_TYPE     categoria do profissional (flag)
    * @param      O_INFO              info
    * @param      O_ERROR             erro
    *
    * @return     boolean
    * @author     SS
    * @version    0.1
    * @since      2006/09/19
    */

    FUNCTION get_software_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_software      OUT pk_types.cursor_type,
        o_timestamp_str OUT VARCHAR2,
        o_gmt_offset    OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Obter lista de instituições a q o profissional tem acesso.   
    *
    * @param      I_LANG              Língua registada como preferência do profissional
    * @param      I_PROF        ID do profissional 
    * @param      O_INFO              instituições a q o profissional tem acesso 
    * @param      O_ERROR             erro 
    *
    * @return     boolean 
    * @author     CRS 
    * @version    0.1 
    * @since      2006/09/29 
    */

    FUNCTION get_instit_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN professional.id_professional%TYPE,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Retorna login do user
       PARAMETROS:  Entrada: I_LANG - ID do idioma 
                             I_PROF_ID - ID do profissional 
              Saida: LOGIN
     
      CRIAÇÃO: CMF 2011-09-16
      NOTAS: 
    *********************************************************************************/

    FUNCTION get_prof_login
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_server_time
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_timestamp_str OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_support_info
    (
        i_lang               IN NUMBER,
        i_host_internal_name IN VARCHAR2,
        i_env_internal_name  IN VARCHAR2,
        o_result             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(4000); -- Localização do erro 
    g_found BOOLEAN;

    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    g_epis_active episode.flg_status%TYPE;
    g_flg_log     prof_soft_inst.flg_log%TYPE;
    g_flg_logout  prof_soft_inst.flg_log%TYPE;
    g_doctor      category.flg_type%TYPE;
    g_nurse       category.flg_type%TYPE;
    g_nutri       category.flg_type%TYPE;
    g_terapeuta   category.flg_type%TYPE;
    g_found_true  VARCHAR2(1);
    g_room_pref   prof_room.flg_pref%TYPE;

    g_cat_type_doc   category.flg_type%TYPE;
    g_cat_type_nur   category.flg_type%TYPE;
    g_cat_type_tec   category.flg_type%TYPE;
    g_cat_type_adm   category.flg_type%TYPE;
    g_cat_prof_y     category.flg_prof%TYPE;
    g_prof_room_pref prof_room.flg_pref%TYPE;

    g_flg_mni         software.flg_mni%TYPE;
    g_prof_inst_state prof_institution.flg_state%TYPE;

    g_selected         VARCHAR2(1);
    g_prof_room_prefer sys_config.value%TYPE;
    g_login_tools      VARCHAR2(1);
    g_yes        CONSTANT VARCHAR2(1) := 'Y';
    g_disclaimer CONSTANT VARCHAR2(20) := 'DISCLAIMER_';
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);
END pk_login;
/
