/*-- Last Change Revision: $Rev: 2028449 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:50 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_alerts_api_rm IS

    /********************************************************************************************
    * Esta fun��o obt�m os alertas dispon�veis para o profissional.
    *
    * @param i_lang          Id do idioma
    * @param i_prof          ID do profissional, institui��o e software
    * @param o_alert         Array com todos os alertas dispon�veis para o profissional
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2010/07/02
    ********************************************************************************************/
    FUNCTION get_prof_alerts
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_alert OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Esta fun��o determina o n�mero de alertas dispon�veis para o profissional.
    *
    * @param i_lang          Id do idioma
    * @param i_prof          ID do profissional, institui��o e software
    * @param o_num_alerts    N�mero de alertas dispon�vel para o profissional
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2010/07/02
    ********************************************************************************************/
    FUNCTION get_prof_alerts_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_num_alerts OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**######################################################
      GLOBAIS
    ######################################################**/
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_owner        VARCHAR2(100);
    g_package      VARCHAR2(100);
END pk_alerts_api_rm;
/
