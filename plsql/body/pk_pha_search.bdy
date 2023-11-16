/*-- Last Change Revision: $Rev: 1919795 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2019-10-09 11:13:58 +0100 (qua, 09 out 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_pha_search IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    FUNCTION get_pat_criteria_active_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where      VARCHAR2(32000);
        l_where_cond VARCHAR2(32000);
    
        l_prof_cat_type category.flg_type%TYPE;
    BEGIN
        l_where := NULL;
    
        --retrieves prof category
        l_prof_cat_type := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lista criterios de pesquisa e preenche clausula WHERE
            g_error      := 'SET WHERE';
            l_where_cond := NULL;
            --
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
            
                g_error  := 'GET CRITERIA CONDITION:';
                g_retval := pk_search.get_criteria_condition(i_lang,
                                                             i_prof,
                                                             CASE
                                                                 WHEN l_prof_cat_type = pk_alert_constant.g_cat_type_pharmacist
                                                                      AND i_id_sys_btn_crit(i) = 1 THEN
                                                                  240
                                                                 ELSE
                                                                  i_id_sys_btn_crit(i)
                                                             END,
                                                             REPLACE(i_crit_val(i), '''', '%'),
                                                             l_where_cond,
                                                             o_error);
            
                IF NOT g_retval
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'SET L_WHERE';
                l_where := l_where || l_where_cond;
            END IF;
        END LOOP;
    
        g_error := 'GET CURSOR O_PAT';
        OPEN o_pat FOR 'SELECT ' || chr(32) || 'wnd.ID_EPISODE ' || chr(32) || --
         'FROM (SELECT EPIS.ID_EPISODE ' || --
        chr(32) || --
         ' FROM EPISODE EPIS, ' || --
         ' PATIENT PAT,' || --
         ' CLIN_RECORD CR ' || --
         ' WHERE ' || --
         ' EPIS.FLG_EHR IN (''N'') ' || --
         ' AND EPIS.ID_INSTITUTION=' || i_prof.institution || --
         ' AND EPIS.ID_PATIENT= PAT.ID_PATIENT ' || --         
         ' AND EPIS.FLG_STATUS          IN (' || g_pl || g_epis_active || g_pl || ', ' || g_pl || g_epis_pend || g_pl || ')' || --
         ' AND CR.ID_PATIENT(+) = PAT.ID_PATIENT' || --
         ' AND CR.ID_INSTITUTION(+) =' || i_prof.institution || --
         ' ' || --
        l_where || --
         ' ) wnd';
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_CRITERIA_ACTIVE_CLIN',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_criteria_active_clin;
BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_pha_search;
/
