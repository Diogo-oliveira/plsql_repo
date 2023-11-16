/*-- Last Change Revision: $Rev: 2027119 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:05 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_epis_er_law_api IS

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    FUNCTION get_fast_track_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN epis_er_law.id_episode%TYPE,
        o_fast_track OUT fast_track.id_fast_track%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.GET_FAST_TRACK_ID';
        RETURN pk_epis_er_law_core.get_fast_track_id(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_episode    => i_episode,
                                                     o_fast_track => o_fast_track,
                                                     o_error      => o_error);
    END get_fast_track_id;

    FUNCTION get_fast_track_id
    (
        i_episode    IN epis_er_law.id_episode%TYPE,
        i_fast_track IN fast_track.id_fast_track%TYPE
    ) RETURN fast_track.id_fast_track%TYPE IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.GET_FAST_TRACK_ID';
        RETURN pk_epis_er_law_core.get_fast_track_id(i_episode => i_episode, i_fast_track => i_fast_track);
    
    END get_fast_track_id;

    FUNCTION set_epis_ges_response
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_ges_msg IN epis_ges_msg.id_epis_ges_msg%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.SET_EPIS_GES_RESPONSE';
        RETURN pk_epis_er_law_core.set_epis_ges_response(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_epis_ges_msg => i_epis_ges_msg,
                                                         i_flg_commit   => FALSE,
                                                         o_error        => o_error);
    END set_epis_ges_response;

    FUNCTION set_epis_ges_alert
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_total_unnot_pathologies IN NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.SET_EPIS_GES_ALERT';
        RETURN pk_epis_er_law_core.set_epis_ges_alert(i_lang                    => i_lang,
                                                      i_prof                    => i_prof,
                                                      i_patient                 => i_patient,
                                                      i_total_unnot_pathologies => i_total_unnot_pathologies,
                                                      i_flg_commit              => FALSE,
                                                      o_error                   => o_error);
    END set_epis_ges_alert;

    FUNCTION get_ges_url
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.GET_GES_URL';
        RETURN pk_epis_er_law_core.get_ges_url(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
    
    END get_ges_url;

    FUNCTION create_epis_ges_msg
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN epis_ges_msg.id_episode%TYPE,
        i_pat_history_diagnosis IN epis_ges_msg.id_pat_history_diagnosis%TYPE,
        i_epis_diagnosis        IN epis_ges_msg.id_epis_diagnosis%TYPE,
        i_flg_origin            IN epis_ges_msg.flg_origin%TYPE,
        o_epis_ges_msg          OUT epis_ges_msg.id_epis_ges_msg%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.CREATE_EPIS_GES_MSG';
        RETURN pk_epis_er_law_core.create_epis_ges_msg(i_lang                  => i_lang,
                                                       i_prof                  => i_prof,
                                                       i_episode               => i_episode,
                                                       i_pat_history_diagnosis => i_pat_history_diagnosis,
                                                       i_epis_diagnosis        => i_epis_diagnosis,
                                                       i_flg_origin            => i_flg_origin,
                                                       i_flg_commit            => FALSE,
                                                       o_epis_ges_msg          => o_epis_ges_msg,
                                                       o_error                 => o_error);
    END create_epis_ges_msg;

    FUNCTION match_er_ges
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.MATCH_ER_GES';
        RETURN pk_epis_er_law_core.match_er_ges(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_episode      => i_episode,
                                                i_episode_temp => i_episode_temp,
                                                o_error        => o_error);
    END match_er_ges;

    FUNCTION get_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_er_law IN epis_er_law.id_epis_er_law%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL PK_EPIS_ER_LAW_CORE.GET_ACTIONS';
        IF NOT pk_epis_er_law_core.get_actions(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_id_epis_er_law => i_id_epis_er_law,
                                               o_actions        => o_actions,
                                               o_error          => o_error)
        THEN
            RAISE l_exception;
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
                                              'GET_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    FUNCTION get_description
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_er_law IN epis_er_law.id_epis_er_law%TYPE,
        o_description    OUT CLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL pk_epis_er_law_core.get_description';
        IF NOT pk_epis_er_law_core.get_description(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_id_epis_er_law => i_id_epis_er_law,
                                                   o_description    => o_description,
                                                   o_error          => o_error)
        THEN
            RAISE l_exception;
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
                                              'GET_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
        
    END get_description;

BEGIN

    g_sysdate_tstz := current_timestamp;

    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(g_package);

END pk_epis_er_law_api;
/
