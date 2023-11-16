/*-- Last Change Revision: $Rev: 1856881 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2018-07-26 09:44:15 +0100 (qui, 26 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_adt_filter IS

    /* DO NOT EDIT THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Gets mapping contexts in referral grids
    * Used by filters
    *
    * @param i_context_ids      Predefined contexts array(prof_id, institution, patient, episode, etç)
    * @param i_context_vals     All remaining contexts array(configurable with bind variable definition)
    * @param i_name             Variable name
    * @param o_vc2              Output variable type varchar2
    * @param o_num              Output variable type NUMBER
    * @param o_id               Output variable type Id
    * @param o_tstz             Output variable type TIMESTAMP WITH LOCAL TIME ZONE
    *
    * @author  Bruno Martins
    * @version 1.0
    * @since   2014-02-21
    */
    PROCEDURE init_params_amendments
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
        g_search_pat_name  CONSTANT NUMBER(24) := 7;
    
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        i_context_ids(g_prof_software));
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
    BEGIN
    
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
            ELSE NULL;
        END CASE;
    
    END init_params_amendments;

BEGIN
    /* DO NOT EDIT THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_adt_filter;
/