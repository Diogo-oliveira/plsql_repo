/*-- Last Change Revision: $Rev: 2027123 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:05 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_epis_er_law_ux IS

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    FUNCTION set_epis_er_law
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN epis_er_law.id_episode%TYPE,
        i_dt_activation     IN VARCHAR2,
        i_dt_inactivation   IN VARCHAR2,
        i_flg_er_law_status IN epis_er_law.flg_er_law_status%TYPE,
        i_flg_create        IN VARCHAR2,
        o_epis_er_law       OUT epis_er_law.id_epis_er_law%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.SET_EPIS_ER_LAW';
        RETURN pk_epis_er_law_core.set_epis_er_law(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_episode           => i_episode,
                                                   i_dt_activation     => i_dt_activation,
                                                   i_dt_inactivation   => i_dt_inactivation,
                                                   i_flg_er_law_status => i_flg_er_law_status,
                                                   i_flg_commit        => TRUE,
                                                   o_epis_er_law       => o_epis_er_law,
                                                   o_error             => o_error);
    END set_epis_er_law;

    FUNCTION cancel_epis_er_law
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN epis_er_law.id_episode%TYPE,
        i_cancel_reason IN epis_er_law.id_cancel_reason%TYPE,
        i_cancel_notes  IN epis_er_law.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.CANCEL_EPIS_ER_LAW';
        RETURN pk_epis_er_law_core.cancel_epis_er_law(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_episode       => i_episode,
                                                      i_cancel_reason => i_cancel_reason,
                                                      i_cancel_notes  => i_cancel_notes,
                                                      o_error         => o_error);
    END cancel_epis_er_law;

    FUNCTION get_lst_epis_er_law
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN epis_er_law.id_episode%TYPE,
        o_lst_epis_er_law OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.GET_LST_EPIS_ER_LAW';
        RETURN pk_epis_er_law_core.get_lst_epis_er_law(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_episode         => i_episode,
                                                       o_lst_epis_er_law => o_lst_epis_er_law,
                                                       o_error           => o_error);
    END get_lst_epis_er_law;

    FUNCTION get_epis_er_law
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_er_law IN epis_er_law.id_epis_er_law%TYPE,
        o_epis_er_law OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.GET_EPIS_ER_LAW';
        RETURN pk_epis_er_law_core.get_epis_er_law(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_epis_er_law => i_epis_er_law,
                                                   o_epis_er_law => o_epis_er_law,
                                                   o_error       => o_error);
    END get_epis_er_law;

    FUNCTION get_date_limits
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN epis_er_law.id_episode%TYPE,
        o_limits  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.GET_DATE_LIMITS';
        RETURN pk_epis_er_law_core.get_date_limits(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_episode => i_episode,
                                                   o_limits  => o_limits,
                                                   o_error   => o_error);
    END get_date_limits;

    FUNCTION get_ges_discharge_msg
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN epis_ges_msg.id_episode%TYPE,
        o_flg_type                OUT VARCHAR2,
        o_url                     OUT VARCHAR2,
        o_total_unnot_pathologies OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.GET_GES_DISCHARGE_MSG';
        RETURN pk_epis_er_law_core.get_ges_discharge_msg(i_lang                    => i_lang,
                                                         i_prof                    => i_prof,
                                                         i_episode                 => i_episode,
                                                         o_flg_type                => o_flg_type,
                                                         o_url                     => o_url,
                                                         o_total_unnot_pathologies => o_total_unnot_pathologies,
                                                         o_error                   => o_error);
    END get_ges_discharge_msg;

BEGIN

    g_sysdate_tstz := current_timestamp;

    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(g_package);

END pk_epis_er_law_ux;
/
