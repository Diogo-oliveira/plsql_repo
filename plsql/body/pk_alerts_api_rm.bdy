/*-- Last Change Revision: $Rev: 2026634 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_alerts_api_rm IS

    /********************************************************************************************
    * Esta função obtém os alertas disponíveis para o profissional.
    *
    * @param i_lang          Id do idioma
    * @param i_prof          ID do profissional, instituição e software
    * @param o_alert         Array com todos os alertas disponíveis para o profissional
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
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL TO PK_ALERTS.GET_PROF_ALERTS';
        IF NOT pk_alerts.get_prof_alerts(i_lang => i_lang, i_prof => i_prof, o_alert => o_alert, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PROF_ALERTS',
                                              o_error);
            pk_types.open_my_cursor(o_alert);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_prof_alerts;

    /********************************************************************************************
    * Esta função determina o número de alertas disponíveis para o profissional.
    *
    * @param i_lang          Id do idioma
    * @param i_prof          ID do profissional, instituição e software
    * @param o_num_alerts    Número de alertas disponível para o profissional
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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_ALERTS.GET_PROF_ALERTS_COUNT';
        IF NOT pk_alerts.get_prof_alerts_count(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               o_num_alerts => o_num_alerts,
                                               o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PROF_ALERTS_COUNT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_prof_alerts_count;

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_alerts_api_rm;
/
