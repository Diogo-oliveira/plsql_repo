/*-- Last Change Revision: $Rev: 2026781 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:52 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_backoffice_filters IS
    -- Package info
    g_package_owner VARCHAR2(30) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_BACKOFFICE_FILTERS';
    /********************************************************************************************
    * get_prof_match_search            Gets mapping contexts in professional match 
    *
    * @param i_context_ids             predefined contexts array(prof_id, institution, patient, episode, etç)
    * @param i_context_vals            all remaining contexts array(configurable with bind variable definition)
    * @param i_name                    Filter name
    * @param o_vc2                     Output variable type varchar2
    * @param o_num                     Output variable type NUMBER
    * @param o_id                      Output variable type Id
    * @param o_tstz                    Output variable type TIMESTAMP WITH LOCAL TIME ZONE
    *
    * @author                          RMGM
    * @version                         2.6.1.2
    * @since                           15-Sep-2011
    *
    **********************************************************************************************/
    PROCEDURE get_prof_match_search
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    BEGIN
        CASE i_name
        
            WHEN 'i_lang' THEN
                o_id := i_context_ids(1);
            
            WHEN 'i_prof_id' THEN
                o_id := i_context_ids(2);
            
            WHEN 'i_prof_institution' THEN
                o_id := i_context_ids(3);
            
            WHEN 'i_prof_software' THEN
                o_id := i_context_ids(4);
            
            WHEN 'l_dt_birth' THEN
                o_vc2 := i_context_vals(2);
            
            WHEN 'l_institution' THEN
                o_id := to_number(i_context_ids(3));
            
            WHEN 'l_name' THEN
                o_vc2 := i_context_vals(1);
            
            WHEN 'l_num_order' THEN
                o_vc2 := i_context_vals(3);
            
            WHEN 'l_speciality' THEN
                o_id := to_number(i_context_vals(4));
            
        END CASE;
    
    END get_prof_match_search;
    /********************************************************************************************
    * get_prof_match_search            Gets mapping contexts in professional match 
    *
    * @param i_context_ids             predefined contexts array(prof_id, institution, patient, episode, etç)
    * @param i_context_vals            all remaining contexts array(configurable with bind variable definition)
    * @param i_name                    Filter name
    * @param o_vc2                     Output variable type varchar2
    * @param o_num                     Output variable type NUMBER
    * @param o_id                      Output variable type Id
    * @param o_tstz                    Output variable type TIMESTAMP WITH LOCAL TIME ZONE
    *
    * @author                          RMGM
    * @version                         2.6.1.2
    * @since                           15-Sep-2011
    *
    **********************************************************************************************/
    PROCEDURE get_cda_map_search
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    BEGIN
        CASE i_name
        
            WHEN 'i_lang' THEN
                o_id := i_context_ids(1);
            
            WHEN 'i_prof_id' THEN
                o_id := i_context_ids(2);
            
            WHEN 'i_prof_institution' THEN
                o_id := i_context_ids(3);
            
            WHEN 'i_prof_software' THEN
                o_id := i_context_ids(4);
            WHEN 'i_flg_cancel' THEN
                o_vc2 := 'C';
            WHEN 'i_flg_ready' THEN
                o_vc2 := 'R';
            WHEN 'i_flg_processing' THEN
                o_vc2 := 'P';
            WHEN 'i_flg_finished' THEN
                o_vc2 := 'F';
            
        END CASE;
    
    END get_cda_map_search;

    PROCEDURE get_message_map
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        
                                                        i_context_ids(g_prof_software));
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
        --l_flg_sender CONSTANT pending_issue_sender.flg_sender%TYPE := i_context_vals(1);
    BEGIN
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_id_prof', l_prof.id);
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_patient' THEN
                o_id := l_patient;
                /*  WHEN 'i_flg_sender' THEN
                o_vc2 := l_flg_sender;*/
            WHEN 'i_flg_cancel' THEN
                o_vc2 := 'X';
        END CASE;
    END get_message_map;

BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_backoffice_filters;
/
