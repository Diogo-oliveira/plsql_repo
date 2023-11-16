/*-- Last Change Revision: $Rev: 2028784 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:55 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_login IS

    SUBTYPE t_prof_info IS pk_prof_utils.t_prof_info;

    /**
       OBJECTIVO:   Actualizar todos os registos necess�rios ao login do profissional 
       PARAMETROS:  Entrada:  I_LANG - L�ngua definida por defeito para o utilizador 
                    I_ID_PROF - Id do profissional 
              Saida:   O_ERROR - msg de erro 
          
      CRIA��O: CRS 2005/02/22 
      NOTAS:  
    */
    FUNCTION set_login
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
       OBJECTIVO:   Actualizar todos os registos necess�rios ao logout do profissional 
       PARAMETROS:  Entrada:  I_LANG - L�ngua definida por defeito para o utilizador 
                    I_ID_PROF - Id do profissional 
                  I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                           como � retornada em PK_LOGIN.GET_PROF_PREF 
              Saida:   O_FLG_SHOW - Y - existe msg para mostrar; N - � existe  
                 O_MSG_TEXT - mensagem  
                 O_MSG_TITLE - T�tulo da msg a mostrar ao utilizador, caso 
                         O_FLG_SHOW = Y 
                 O_BUTTON - Bot�es a mostrar: N - n�o, R - lido, C - confirmado 
                        Tb pode mostrar combina��es destes, qd � p/ mostrar 
                      + do q 1 bot�o 
                 O_ERROR - msg de erro 
          
      CRIA��O: CRS 2005/02/22 
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
       OBJECTIVO:   Obter prefer�ncias do profissional 
       PARAMETROS:  Entrada: I_LANG - L�ngua definida por defeito na BD 
                             I_ID_PROF - Id do profissional 
                   
                      Saida: O_LANG - ID da l�ngua definida por defeito para o utilizador 
                             O_DESC_LANG - Nome da l�ngua 
                             O_TIME - Timeout para o profissional 
                             O_FIRST_SCREEN - Nome do ficheiro a q o prof acede mal fa�a login 
                             O_PHOTO - URL para foto do m�dico 
                             O_NICK_NAME - nome abreviado do prof 
                             O_NAME - nome completo do prof 
                             O_CAT_TYPE - tipo de categoria do prof: D - m�dico, N - enfermeiro, P - farmac�utico, 
                                                                     A - administrativo, T - t�cnico, O - outro  
                             O_CLIN_CAT - Indica��o se � uma categoria m�dica: Y / N 
                             O_HEADER - Indica��o se tem acesso aos atalhos do cabe�alho: Y / N  
                             O_SHORTCUT - atalho para a aloca��o de institui��o / sala, se for o caso 
                             O_NUM_MECAN - N�mero Mecanogr�fico do profissional
                             O_ERROR - msg de erro 
      
      CRIA��O: CRS 2005/02/22 
      ALETRA��O: CRS 2006/10/30 Comentado c�digo de pesquisa de �ltima aloca��o do user 
      NOTAS: O par. de entrada I_LANG � a l�ngua definida por defeito na BD, para ser 
           usado em GET_MESSAGE caso n�o exista registo em PROF_PREFERENCES 
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
    * Public Function. Obter a lista de profissionais para mudan�a de login por foto.   
    *
    * @param      I_LANG              L�ngua registada como prefer�ncia do profissional
    * @param      I_PROF        object (ID do profissional, ID da institui��o, ID do software)
    * @param      I_PROF_CAT_TYPE     categoria do profissional (flag)
    * @param      O_INFO              info
    * @param      O_ERROR             erro
    *
    * @return     boolean
    * @author     SS
    * @version    0.1
    * @since      2006/09/19 
    * @notes    Inclui o utilizador actual; os m�dicos / enfermeiros alocados � mesma sala preferencial do utilizador actual; 
         e todos os outros profissionais alocados ao mesmo departamento / serv. cl�nico, excepto administrativos e t�cnicos 
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
    * Public Function. Obter a lista de profissionais para mudan�a de login por foto.   
    *
    * @param      I_LANG              L�ngua registada como prefer�ncia do profissional
    * @param      I_PROF        object (ID do profissional, ID da institui��o, ID do software)
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
    * Public Function. Obter lista de institui��es a q o profissional tem acesso.   
    *
    * @param      I_LANG              L�ngua registada como prefer�ncia do profissional
    * @param      I_PROF        ID do profissional 
    * @param      O_INFO              institui��es a q o profissional tem acesso 
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
     
      CRIA��O: CMF 2011-09-16
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

    g_error VARCHAR2(4000); -- Localiza��o do erro 
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
