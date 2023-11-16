/*-- Last Change Revision: $Rev: 2026921 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_cpt_code IS

    -- EMR-1557
    PROCEDURE get_ism_cfg
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_market OUT institution.id_market%TYPE,
        o_inst   OUT institution.id_institution%TYPE,
        o_soft   OUT software.id_software%TYPE
    ) IS
        l_inst_market institution.id_market%TYPE;
    BEGIN
        g_error := 'Getting the default market';
        pk_alertlog.log_debug(g_error);
        l_inst_market := nvl(n1 => pk_utils.get_institution_market(i_lang, i_prof.institution), n2 => g_default_market);
    
        BEGIN
            g_error := 'GET CPT_CODE ISM_CFG';
            pk_alertlog.log_debug(g_error);
            SELECT id_market, id_institution, id_software
              INTO o_market, o_inst, o_soft
              FROM (SELECT em.id_market,
                           em.id_institution,
                           em.id_software,
                           row_number() over(ORDER BY decode(em.id_market, l_inst_market, 1, 2), --
                           decode(em.id_institution, i_prof.institution, 1, 2), --
                           decode(em.id_software, i_prof.software, 1, 2)) line_number
                      FROM eval_mng em
                     WHERE em.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND em.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND em.id_market IN (pk_alert_constant.g_id_market_all, l_inst_market))
             WHERE line_number = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_market := l_inst_market;
                o_inst   := i_prof.institution;
                o_soft   := i_prof.software;
        END;
    END get_ism_cfg;

    /** @headcom
    * Public Function. Returns the list of CPT Codes available for assign to the discharge.
    *
    * @param      I_LANG                     Language Identification
    * @param      I_PROF                     Professional variables
    * @param      I_ID_EPISODE               Episode identifier
    * @param      O_CUR                      The list of CPT Codes available
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      12/19/2007
    */
    FUNCTION get_cpt_code_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT cpt_code_cur,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_show_id_cpt_code sys_config.value%TYPE := nvl(pk_sysconfig.get_config('SHOW_ID_CPT_CODE', i_prof),
                                                        pk_alert_constant.g_yes);
        l_id_market        market.id_market%TYPE;
        l_inst             institution.id_institution%TYPE;
        l_soft             software.id_software%TYPE;
    
    BEGIN
    
        g_error     := 'GET ID_MARKET';
        l_id_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        get_ism_cfg(i_lang => i_lang, i_prof => i_prof, o_market => l_id_market, o_inst => l_inst, o_soft => l_soft);
    
        g_error := 'GET_CPT_CODE_LIST';
        OPEN o_cur FOR
        -- José Brito 29/05/2008 Modificar a query para ser compatível com outros softwares para além do Private Practice
            SELECT em.id_cpt_code,
                   CASE
                        WHEN l_show_id_cpt_code = pk_alert_constant.g_yes THEN
                         cc.medium_desc || ' (' || em.id_cpt_code || ')'
                        ELSE
                         cc.medium_desc
                    END cpt_code_desc,
                   nvl(em.flg_default, pk_alert_constant.get_no) AS flg_default -- EMR-1557
              FROM cpt_code cc, eval_mng em
             WHERE cc.id_cpt_code = em.id_cpt_code
               AND em.id_institution = l_inst
               AND em.id_software = l_soft
               AND em.id_market = l_id_market
               AND em.flg_available = pk_alert_constant.g_yes
               AND (em.flg_type IS NULL OR em.flg_type = decode((SELECT se.flg_occurrence
                                                                  FROM schedule s
                                                                  JOIN epis_info ei
                                                                    ON s.id_schedule = ei.id_schedule
                                                                  JOIN sch_event se
                                                                    ON se.id_sch_event = s.id_sch_event
                                                                 WHERE ei.id_episode = i_id_episode),
                                                                g_sch_event_f /*'F'*/,
                                                                g_cptc_n /*'N'*/,
                                                                g_sch_event_s /*'S'*/,
                                                                g_cptc_e /*'E'*/,
                                                                g_cptc_c /*'C'*/))
             ORDER BY em.rank;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', g_package_name, 'GET_CPT_CODE_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_types.open_my_cursor(o_cur);
                RETURN FALSE;
            END;
    END get_cpt_code_list;

    FUNCTION check_has_cpt_cfg
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_id_market market.id_market%TYPE;
        l_inst      institution.id_institution%TYPE;
        l_soft      software.id_software%TYPE;
        l_count     NUMBER;
        l_has_cpt   VARCHAR2(1 CHAR) := pk_alert_constant.get_no;
    BEGIN
        g_error     := 'GET ID_MARKET';
        l_id_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        get_ism_cfg(i_lang => i_lang, i_prof => i_prof, o_market => l_id_market, o_inst => l_inst, o_soft => l_soft);
    
        SELECT COUNT(1)
          INTO l_count
          FROM cpt_code cc, eval_mng em
         WHERE cc.id_cpt_code = em.id_cpt_code
           AND em.id_institution = l_inst
           AND em.id_software = l_soft
           AND em.id_market = l_id_market
           AND em.flg_available = pk_alert_constant.g_yes
           AND (em.flg_type IS NULL OR em.flg_type = decode((SELECT se.flg_occurrence
                                                              FROM schedule s
                                                              JOIN epis_info ei
                                                                ON s.id_schedule = ei.id_schedule
                                                              JOIN sch_event se
                                                                ON se.id_sch_event = s.id_sch_event
                                                             WHERE ei.id_episode = i_id_episode),
                                                            g_sch_event_f /*'F'*/,
                                                            g_cptc_n /*'N'*/,
                                                            g_sch_event_s /*'S'*/,
                                                            g_cptc_e /*'E'*/,
                                                            g_cptc_c /*'C'*/))
         ORDER BY em.rank;
        IF l_count > 0
        THEN
            l_has_cpt := pk_alert_constant.g_yes;
        END IF;
        RETURN l_has_cpt;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_has_cpt;
    END check_has_cpt_cfg;
BEGIN

    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

    g_yes         := 'Y';
    g_no          := 'N';
    g_sch_event_f := 'F';
    g_sch_event_s := 'S';
    g_cptc_n      := 'N';
    g_cptc_e      := 'E';
    g_cptc_c      := 'C';

END pk_cpt_code;
/
