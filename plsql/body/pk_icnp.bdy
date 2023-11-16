/*-- Last Change Revision: $Rev: 2027213 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_icnp IS

    --------------------------------------------------------------------------------
    -- TYPES
    -------------------------------------------------------------------------------
    -- Types used to control which recurrences are already marked as definitive
    SUBTYPE t_order_recurr_key IS VARCHAR2(24 CHAR);
    TYPE t_order_recurr_rec IS RECORD(
        id_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE,
        id_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE);
    TYPE t_order_recurr_coll IS TABLE OF t_order_recurr_rec INDEX BY t_order_recurr_key;

    TYPE t_processed_plan_rec IS RECORD(
        id_order_recurr_plan   NUMBER(24),
        id_order_recurr_option NUMBER(24));

    TYPE t_processed_plan IS TABLE OF t_processed_plan_rec INDEX BY VARCHAR2(24);

    TYPE t_icnp_instrunction IS RECORD(
        id_order_recurr_option icnp_default_instructions_msi.id_order_recurr_option%TYPE,
        flg_prn                icnp_default_instructions_msi.flg_prn%TYPE,
        prn_notes              icnp_default_instructions_msi.prn_notes%TYPE,
        flg_time               icnp_default_instructions_msi.flg_time%TYPE);
    -------------------------------------------------------------------------------
    -- CONSTANTS
    --------------------------------------------------------------------------------
    g_day    sys_domain.val%TYPE := 'D';
    g_hour   sys_domain.val%TYPE := 'H';
    g_minute sys_domain.val%TYPE := 'M';

    g_retval BOOLEAN;

    --------------------------------------------------------------------------------
    -- METHODS [DEBUG]
    --------------------------------------------------------------------------------

    /*
     * Wrapper of the method from the alertlog mechanism that creates a debug log 
     * message.
     *
     * @param i_text Text to log.
     * @param i_func_name Function / procedure name.
     *
     * @author Cristina Oliveira
     * @version 1.0
     * @since 19/06/2013
    */
    PROCEDURE log_debug
    (
        i_text      VARCHAR2,
        i_func_name VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_debug(text => i_text, object_name => g_package_name, sub_object_name => i_func_name);
    END log_debug;

    --------------------------------------------------------------------------------
    -- METHODS [RECURRENCE]
    --------------------------------------------------------------------------------

    /**
     * Set a temporary order recurrence plan as definitive (final status). Because
     * we can have the same recurrence for some interventions and because we can only 
     * mark the recurrence as definitive once, we must control which recurrences have
     * already been marked as definitive. The objective is achieved using an 
     * associative array with all the recurrences already processed.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_recurr_plan_id The recurrence identifier.
     * @param io_recurr_processed_coll Collection with all the recurrences that were 
     *                                 already processed (marked as definitive). 
     * @param io_recurr_definit_ids_coll Collection with all the definitive recurrence
     *                                   identifiers. It will be used in the
     *                                   prepare_order_recurr_plan method.
     * 
     * @return A record with information about the recurrence: the identifier and the
     *         option (once, no schedule, etc).
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 26/Jul/2011
    */
    FUNCTION set_order_recurr_plan
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_recurr_plan_id           IN icnp_epis_intervention.id_order_recurr_plan%TYPE,
        io_recurr_processed_coll   IN OUT NOCOPY t_order_recurr_coll,
        io_recurr_definit_ids_coll IN OUT NOCOPY table_number,
        io_precessed_plans         IN OUT t_processed_plan
    ) RETURN t_order_recurr_rec IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_order_recurr_plan';
        l_order_recurr_key       t_order_recurr_key;
        l_order_recurr_rec       t_order_recurr_rec;
        l_order_recurr_option_id order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_final_id  order_recurr_plan.id_order_recurr_plan%TYPE;
        l_error                  t_error_out;
    
    BEGIN
        log_debug(c_func_name || '()', c_func_name);
    
        -- Converts the recurrence identifier to a varchar, to be used in the 
        -- associative collection
        l_order_recurr_key := to_char(i_recurr_plan_id);
    
        -- Check this order recurrence identifier was already processed
        IF io_recurr_processed_coll.count > 0
           AND io_recurr_processed_coll.exists(l_order_recurr_key)
        THEN
            -- This recurrence was already processed, retrieve it from the associative array
            l_order_recurr_rec := io_recurr_processed_coll(l_order_recurr_key);
        ELSE
            -- Set a temporary order recurrence plan as definitive (final status)
            log_debug('set_order_recurr_plan / i_recurr_plan_id: ' || i_recurr_plan_id, c_func_name);
            IF NOT io_precessed_plans.exists(i_recurr_plan_id)
            THEN
                IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                        i_prof                    => i_prof,
                                                                        i_order_recurr_plan       => i_recurr_plan_id,
                                                                        o_order_recurr_option     => l_order_recurr_option_id,
                                                                        o_final_order_recurr_plan => l_order_recurr_final_id,
                                                                        o_error                   => l_error)
                THEN
                    pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.set_order_recurr_plan', l_error);
                END IF;
                -- add plan values to processed array
                io_precessed_plans(i_recurr_plan_id).id_order_recurr_option := l_order_recurr_option_id;
                io_precessed_plans(i_recurr_plan_id).id_order_recurr_plan := l_order_recurr_final_id;
            ELSE
                l_order_recurr_option_id := io_precessed_plans(i_recurr_plan_id).id_order_recurr_option;
                l_order_recurr_final_id  := io_precessed_plans(i_recurr_plan_id).id_order_recurr_plan;
            END IF;
        
            -- Mark this recurrence identifier as processed (store it in the associative array)
            l_order_recurr_rec.id_order_recurr_plan := l_order_recurr_final_id;
            l_order_recurr_rec.id_order_recurr_option := l_order_recurr_option_id;
            io_recurr_processed_coll(l_order_recurr_key) := l_order_recurr_rec;
        
            -- Add the final order recurrence identifier for further processing
            -- When the id is null it means that there is no recurrence (once execution)
            log_debug('add l_order_recurr_final_id to io_recurr_definit_ids_coll / l_order_recurr_final_id: ' ||
                      l_order_recurr_final_id,
                      c_func_name);
            IF (l_order_recurr_final_id IS NOT NULL)
            THEN
                io_recurr_definit_ids_coll.extend;
                io_recurr_definit_ids_coll(io_recurr_definit_ids_coll.count) := l_order_recurr_final_id;
            END IF;
        END IF;
    
        RETURN l_order_recurr_rec;
    
    END set_order_recurr_plan;
    --------------------------------------------------------------------------------
    -- METHODS
    --------------------------------------------------------------------------------

    --CIPE Builder Development
    --Start

    /********************************************************************************************
    * Auxiliar function to concatenate return values from queries.
    *
    * @param      i_cursor  Cursor with data
    *
    * @return               List concatenated
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/13
    * @dependents            N/A
    *********************************************************************************************/
    FUNCTION concatenate_list(i_cursor IN SYS_REFCURSOR) RETURN VARCHAR2 IS
        l_return VARCHAR2(2000);
        l_temp   VARCHAR2(2000);
    BEGIN
        LOOP
            FETCH i_cursor
                INTO l_temp;
            EXIT WHEN i_cursor%NOTFOUND;
            IF l_return IS NULL
            THEN
                l_return := l_temp;
            ELSE
                l_return := l_return || ' ' || l_temp;
            END IF;
        
        END LOOP;
        RETURN ltrim(l_return, ',');
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END concatenate_list;

    /********************************************************************************************
    * Auxiliar function to return composition text.
    *
    * @param      i_compo   Cursor with data
    *
    * @return               varchar with description
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/20
    * @dependents            PK_TRANSLATION.GET_TRANSLATION    <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_compo_desc
    (
        i_lang language.id_language%TYPE,
        i_comp IN icnp_composition.id_composition%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(2000);
    BEGIN
    
        l_return := '';
    
        SELECT concatenate_list(CURSOR (SELECT pk_translation.get_translation(ict.id_language, code_term) ||
                                        decode(nvl(ict.desc_term, '0'), '0', '', ' ' || ict.desc_term)
                                   FROM icnp_term it, icnp_composition_term ict
                                  WHERE it.id_term = ict.id_term
                                    AND ict.id_composition = i_comp
                                  ORDER BY ict.rank))
          INTO l_return
          FROM dual;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_compo_desc;

    /********************************************************************************************
    * Auxiliar function to return composition text without rank of the terms.
    *
    * @param      i_compo   Cursor with data
    *
    * @return               varchar with description
    *
    * @raises
    *
    * @author                Cristina Oliveira
    * @version               1
    * @since                 2013/06/26
    * @dependents            PK_TRANSLATION.GET_TRANSLATION    <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_compo_desc_aux
    (
        i_lang language.id_language%TYPE,
        i_comp IN icnp_composition.id_composition%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(2000);
    BEGIN
    
        l_return := '';
    
        SELECT concatenate_list(CURSOR (SELECT pk_translation.get_translation(ict.id_language, code_term) ||
                                        decode(nvl(ict.desc_term, '0'), '0', '', ' ' || ict.desc_term)
                                   FROM icnp_term it, icnp_composition_term ict
                                  WHERE it.id_term = ict.id_term
                                    AND ict.id_composition = i_comp
                                    AND it.rank IS NULL
                                  ORDER BY ict.rank))
          INTO l_return
          FROM dual;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_compo_desc_aux;

    /********************************************************************************************
    * Auxiliar function to return composition text.
    *
    * @param      i_lang   language
    * @param      i_comp   composition hist
    * @param      i_date   date
    *
    * @return               varchar with description
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/20
    * @dependents            PK_TRANSLATION.GET_TRANSLATION    <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_compo_desc_by_date
    (
        i_lang language.id_language%TYPE,
        i_comp IN icnp_composition_hist.id_composition_hist%TYPE,
        i_date IN DATE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(2000);
        l_comp   icnp_composition_hist.id_composition_hist%TYPE;
    BEGIN
    
        l_return := '';
    
        IF i_date IS NOT NULL
        THEN
            SELECT MAX(id_composition)
              INTO l_comp
              FROM icnp_composition_hist ich
             WHERE ich.id_composition_hist = i_comp
               AND ich.dt_composition_hist <= i_date;
        
            SELECT pk_translation.get_translation(i_lang, ic.code_icnp_composition)
              INTO l_return
              FROM icnp_composition ic
             WHERE ic.id_composition = l_comp;
        ELSE
            SELECT pk_translation.get_translation(i_lang, ic.code_icnp_composition)
              INTO l_return
              FROM icnp_composition ic
             WHERE ic.id_composition = (SELECT MAX(ich.id_composition)
                                          FROM icnp_composition_hist ich
                                         WHERE ich.id_composition_hist = i_comp);
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_compo_desc_by_date;

    /********************************************************************************************
    * Returns all the ICNP's axis.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_type    Type (diagnosis, intervention)
    * @param      o_axis    Icnp's axis list
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/13
    * @dependents            PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_axis
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN icnp_axis.flg_type%TYPE,
        o_axis  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(50) := 'GET_ICNP_AXIS';
    
    BEGIN
    
        g_error := 'OPEN O_AXIS';
        OPEN o_axis FOR
            SELECT *
              FROM (SELECT ia.id_axis,
                           pk_translation.get_translation(i_lang, ia.code_axis) desc_axis,
                           ia.flg_axis,
                           pk_translation.get_translation(i_lang, ia.code_help_axis) AS help_term
                      FROM icnp_axis ia
                     WHERE ia.id_icnp_version = get_icnp_version(i_lang, i_prof)
                       AND nvl(ia.flg_type, '@') IN ('@', i_type))
             WHERE desc_axis IS NOT NULL
             ORDER BY 2;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                --pk_util.undo_changes;
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_axis);
                RETURN FALSE;
            END;
        
    END get_icnp_axis;

    /********************************************************************************************
    * Returns all the ICNP's terms within a given axis or term.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_axis    ICNP Axis ID
    * @param      i_term    ICNP Term ID
    * @param      o_term    Icnp's term list
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/13
    * @dependents            PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_term
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_axis  IN icnp_axis.id_axis%TYPE,
        i_term  IN icnp_term.id_term%TYPE,
        o_term  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name    VARCHAR2(50) := 'GET_ICNP_TERM';
        l_icnp_version icnp_axis.id_icnp_version%TYPE;
    
    BEGIN
        g_error := 'OPEN O_TERM';
    
        --get current version icnp
        l_icnp_version := get_icnp_version(i_lang, i_prof);
    
        IF i_term IS NULL
        THEN
            OPEN o_term FOR
                SELECT id_term,
                       pk_translation.get_translation(i_lang, code_term) AS desc_term,
                       flg_axis,
                       decode(SUM(xcounter), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_childs,
                       pk_translation.get_translation(i_lang, code_help_term) AS help_term,
                       rank
                  FROM (SELECT it.id_term,
                               it.code_term,
                               ia.flg_axis,
                               nvl((SELECT it.id_term
                                     FROM icnp_term it3
                                     JOIN icnp_axis ia3
                                       ON it3.id_axis = ia3.id_axis
                                    WHERE ia3.id_icnp_version = l_icnp_version
                                      AND it3.id_term = it2.id_term),
                                   0) xcounter,
                               it.code_help_term,
                               it.rank
                          FROM icnp_term it, icnp_axis ia, icnp_term it2
                         WHERE it.id_axis = i_axis
                           AND it.flg_available = pk_alert_constant.g_available
                           AND it.id_axis = ia.id_axis
                           AND ia.flg_axis = it.parent_code
                           AND it.concept_code = it2.parent_code(+)
                           AND ia.id_icnp_version = l_icnp_version
                           AND pk_translation.get_translation(i_lang, it.code_term) IS NOT NULL)
                 GROUP BY id_term, pk_translation.get_translation(i_lang, code_term), flg_axis, code_help_term, rank
                 ORDER BY rank, 2;
        ELSE
            OPEN o_term FOR
                SELECT it.id_term id_term,
                       pk_translation.get_translation(i_lang, it.code_term) desc_term,
                       it.flg_axis,
                       it.concept_code,
                       decode(connect_by_isleaf, 0, pk_alert_constant.g_yes, 1, pk_alert_constant.g_no) AS flg_childs,
                       pk_translation.get_translation(i_lang, it.code_help_term) AS help_term,
                       rank
                  FROM (SELECT *
                          FROM icnp_term it, icnp_axis ia
                         WHERE it.flg_available = pk_alert_constant.g_available
                           AND it.id_axis = ia.id_axis
                           AND ia.id_axis = i_axis
                           AND ia.id_icnp_version = l_icnp_version
                           AND pk_translation.get_translation(i_lang, it.code_term) IS NOT NULL) it
                 WHERE LEVEL = 2
                CONNECT BY nocycle PRIOR concept_code = parent_code
                 START WITH it.id_term = i_term
                 ORDER BY rank, 2;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_term);
                RETURN FALSE;
            END;
        
    END get_icnp_term;

    /********************************************************************************************
    * Returns all the ICNP's terms for a given search text.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_search  Search text
    * @param      o_info    Term list information
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/16
    * @dependents            PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_UTILS.UNDO_CHANGES                <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_search_term
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_search    IN VARCHAR2,
        i_type      IN icnp_axis.flg_type%TYPE,
        o_info      OUT pk_types.cursor_type,
        o_error     OUT t_error_out,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_count     NUMBER := 0;
        l_func_name VARCHAR2(50) := 'GET_ICNP_SEARCH_TERM';
        l_my_exp EXCEPTION;
    BEGIN
        g_error := 'DELETE FROM tbl_temp';
        DELETE FROM tbl_temp;
    
        FOR tmp_cur IN (SELECT it.id_term id_term,
                               desc_translation desc_term,
                               ia.id_axis,
                               ia.flg_axis,
                               it.concept_code,
                               decode((SELECT COUNT(id_term) id_term
                                        FROM icnp_term
                                       WHERE parent_code = it.concept_code),
                                      0,
                                      pk_alert_constant.g_no,
                                      pk_alert_constant.g_yes) flg_childs,
                               pk_translation.get_translation(i_lang, code_help_term) AS help_term
                          FROM icnp_term it,
                               icnp_axis ia,
                               TABLE(pk_translation.get_search_translation(i_lang, i_search, 'ICNP_TERM.CODE_TERM')) st
                         WHERE st.code_translation = it.code_term
                           AND it.flg_available = pk_alert_constant.g_available
                           AND it.id_axis = ia.id_axis
                           AND ia.id_icnp_version = get_icnp_version(i_lang, i_prof)
                           AND nvl(ia.flg_type, '@') IN ('@', i_type)
                        UNION
                        SELECT it.id_term id_term,
                               pk_translation.get_translation(i_lang, it.code_term) desc_term,
                               ia.id_axis,
                               ia.flg_axis,
                               it.concept_code,
                               decode((SELECT COUNT(id_term) id_term
                                        FROM icnp_term
                                       WHERE parent_code = it.concept_code),
                                      0,
                                      pk_alert_constant.g_no,
                                      pk_alert_constant.g_yes) flg_childs,
                               pk_translation.get_translation(i_lang, code_help_term) AS help_term
                          FROM icnp_term it, icnp_axis ia
                         WHERE it.concept_code = upper(TRIM(i_search))
                           AND it.flg_available = pk_alert_constant.g_available
                           AND it.id_axis = ia.id_axis
                           AND pk_translation.get_translation(i_lang, it.code_term) IS NOT NULL
                           AND ia.id_icnp_version = get_icnp_version(i_lang, i_prof)
                           AND nvl(ia.flg_type, '@') IN ('@', i_type)
                         ORDER BY 2)
        
        LOOP
            INSERT INTO tbl_temp
                (num_1, num_2, vc_1, vc_2, vc_3, vc_4, vc_5)
            VALUES
                (tmp_cur.id_term,
                 tmp_cur.id_axis,
                 tmp_cur.desc_term,
                 tmp_cur.flg_axis,
                 tmp_cur.concept_code,
                 tmp_cur.flg_childs,
                 tmp_cur.help_term);
        
            l_count := l_count + 1;
        END LOOP;
    
        g_error := 'NO RESULT';
        IF l_count = 0
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'ICNP_T027');
            o_msg       := pk_message.get_message(i_lang, 'CIPE_M006');
            o_button    := 'R';
            pk_types.open_my_cursor(o_info);
            RETURN TRUE;
            --RAISE l_my_exp;
        ELSE
            o_flg_show := 'N';
        
        END IF;
    
        g_error := 'CURSOR O_INFO';
        OPEN o_info FOR
            SELECT tt.num_1 id_term,
                   tt.vc_1  desc_term,
                   tt.num_2 id_axis,
                   tt.vc_2  flg_axis,
                   tt.vc_3  concept_code,
                   tt.vc_4  flg_childs,
                   tt.vc_5  help_term
              FROM tbl_temp tt
             ORDER BY 2;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_my_exp THEN
            DECLARE
                l_error t_error_in := t_error_in();
            BEGIN
                l_error.set_all(i_lang,
                                'ICNP_M003',
                                pk_message.get_message(i_lang, 'ICNP_M003'),
                                NULL,
                                'ALERT',
                                g_package_name,
                                l_func_name,
                                pk_message.get_message(i_lang, 'ICNP_M003'),
                                'D');
                g_retval := pk_alert_exceptions.process_error(l_error, o_error);
                pk_types.open_my_cursor(o_info);
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_info);
                RETURN FALSE;
            END;
        
    END get_icnp_search_term;

    /********************************************************************************************
    * Returns all terms from focus axis that are already available throught diagnosis.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      o_folder  Icnp's focuses list
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/16
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_existing_term
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_folder OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_icnp_validation_flag VARCHAR2(10 CHAR);
        l_icnp_version         sys_config.value%TYPE;
    
    BEGIN
    
        l_icnp_validation_flag := get_icnp_validation_flag(i_lang, i_prof, pk_icnp_constant.g_icnp_focus);
        l_icnp_version         := get_icnp_version(i_lang, i_prof);
    
        g_error := 'OPEN O_FOLDER';
        OPEN o_folder FOR
            SELECT *
              FROM (SELECT DISTINCT ta.id_term,
                                    pk_translation.get_translation(i_lang, tb.code_term) desc_focus,
                                    pk_translation.get_translation(i_lang, tb.code_help_term) AS help_term
                      FROM (SELECT id_term
                              FROM icnp_composition_term ict
                             WHERE ict.id_language = i_lang
                               AND ict.flg_main_focus = pk_alert_constant.g_yes
                               AND EXISTS (SELECT 1
                                      FROM icnp_composition_hist ich
                                      JOIN icnp_composition ic
                                        ON ich.id_composition = ic.id_composition
                                     WHERE ich.flg_most_recent = pk_alert_constant.g_yes
                                       AND ich.flg_cancel = pk_alert_constant.g_no
                                       AND ic.id_institution = i_prof.institution
                                       AND ic.flg_available = pk_alert_constant.g_yes
                                       AND ich.id_composition = ict.id_composition)) ta
                     INNER JOIN (SELECT id_term, code_term, code_help_term
                                  FROM icnp_term it
                                 WHERE it.id_axis =
                                       (SELECT id_axis
                                          FROM icnp_axis ia
                                         WHERE ia.flg_axis = l_icnp_validation_flag
                                           AND ia.id_icnp_version = l_icnp_version
                                           AND (ia.flg_type IS NULL OR
                                               ia.flg_type = pk_icnp_constant.g_composition_type_diagnosis))) tb
                        ON ta.id_term = tb.id_term
                     INNER JOIN icnp_term it
                        ON it.id_term = ta.id_term)
             WHERE desc_focus IS NOT NULL
             ORDER BY 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ICNP_EXISTING_TERM',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_folder);
            RETURN FALSE;
    END get_icnp_existing_term;

    /********************************************************************************************
    * Returns all composition terms from focus axis that are already available throught diagnosis.
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      i_term      Focus term ID
    * @param      i_flg_child flag (Y/N to calculate has child nodes)
    * @param      o_folder    Icnp's focuses list
    * @param      o_error     Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/16
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_composition_by_term
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_term      IN table_number,
        i_flg_child IN VARCHAR2,
        o_folder    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(50) := 'GET_ICNP_COMPOSITION_TERM';
    
    BEGIN
    
        DELETE tbl_temp;
    
        IF (i_term IS NULL OR i_term.count = 0)
        THEN
            IF i_flg_child = pk_alert_constant.g_no
            THEN
                g_error := 'OPEN O_FOLDER FOR ALL DIAG';
                OPEN o_folder FOR
                    SELECT DISTINCT (ic.id_composition),
                                    ich.id_composition_hist,
                                    pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc,
                                    'X' AS has_child
                      FROM icnp_composition ic
                      JOIN icnp_composition_hist ich
                        ON ic.id_composition = ich.id_composition
                      JOIN icnp_composition_term ict
                        ON ic.id_composition = ict.id_composition
                      JOIN icnp_term it
                        ON it.id_term = ict.id_term
                      JOIN icnp_axis ia
                        ON ia.id_axis = it.id_axis
                      LEFT JOIN (SELECT *
                                   FROM icnp_predefined_action ipa
                                  WHERE ipa.flg_available = pk_alert_constant.g_yes
                                    AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                                    AND ipa.id_software IN (0, i_prof.software)) ipa
                        ON ipa.id_composition_parent = ic.id_composition
                     WHERE ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                       AND ich.flg_most_recent = pk_alert_constant.g_yes
                       AND ich.flg_cancel = pk_alert_constant.g_no
                       AND ict.flg_main_focus = pk_alert_constant.g_yes
                       AND ic.flg_available = pk_alert_constant.g_yes
                       AND ic.id_institution = i_prof.institution
                       AND ic.id_software = i_prof.software
                       AND ia.id_icnp_version = pk_icnp.get_icnp_version(i_lang, i_prof)
                     ORDER BY 3;
            
                RETURN TRUE;
            ELSE
                g_error := 'OPEN O_FOLDER FOR ALL DIAG CHILD';
                --get diagnosis
                INSERT INTO tbl_temp
                    (num_1, num_2, vc_1)
                    (SELECT DISTINCT (ic.id_composition),
                                     ich.id_composition_hist,
                                     pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc
                       FROM icnp_composition ic
                       JOIN icnp_composition_hist ich
                         ON ic.id_composition = ich.id_composition
                       JOIN icnp_composition_term ict
                         ON ic.id_composition = ict.id_composition
                       JOIN icnp_term it
                         ON it.id_term = ict.id_term
                       JOIN icnp_axis ia
                         ON ia.id_axis = it.id_axis
                       LEFT JOIN (SELECT *
                                   FROM icnp_predefined_action ipa
                                  WHERE ipa.flg_available = pk_alert_constant.g_yes
                                    AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                                    AND ipa.id_software IN (0, i_prof.software)) ipa
                         ON ipa.id_composition_parent = ic.id_composition
                      WHERE ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                        AND ich.flg_most_recent = pk_alert_constant.g_yes
                        AND ich.flg_cancel = pk_alert_constant.g_no
                        AND ict.flg_main_focus = pk_alert_constant.g_yes
                        AND ic.flg_available = pk_alert_constant.g_yes
                        AND ic.id_institution = i_prof.institution
                        AND ic.id_software = i_prof.software
                        AND ia.id_icnp_version = pk_icnp.get_icnp_version(i_lang, i_prof));
            END IF;
        ELSE
        
            g_error := 'OPEN O_FOLDER FOR DIAG BY TERM';
            --get diagnosis
            FORALL k IN i_term.first .. i_term.last
                INSERT INTO tbl_temp
                    (num_1, num_2, vc_1, vc_2, vc_3, num_4, vc_4)
                    (SELECT DISTINCT (ic.id_composition),
                                     ich.id_composition_hist,
                                     pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc,
                                     ich.flg_cancel,
                                     pk_sysdomain.get_domain('ICNP_COMPOSITION.FLG_TYPE', ic.flg_type, i_lang) desc_type,
                                     (SELECT MAX(it.rank)
                                        FROM icnp_term it, icnp_composition_term ict
                                       WHERE it.id_term = ict.id_term
                                         AND ict.id_composition = ict2.id_composition
                                         AND it.rank IS NOT NULL) rank,
                                     get_compo_desc_aux(i_lang, ic.id_composition) AS compo_desc
                       FROM icnp_composition ic
                       JOIN icnp_composition_hist ich
                         ON ic.id_composition = ich.id_composition
                       JOIN icnp_composition_term ict2
                         ON ic.id_composition = ict2.id_composition
                       JOIN icnp_term it
                         ON it.id_term = ict2.id_term
                       JOIN icnp_axis ia
                         ON ia.id_axis = it.id_axis
                       LEFT JOIN (SELECT *
                                   FROM icnp_predefined_action ipa
                                  WHERE ipa.flg_available = pk_alert_constant.g_yes
                                    AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                                    AND ipa.id_software IN (0, i_prof.software)) ipa
                         ON ipa.id_composition_parent = ic.id_composition
                      WHERE ict2.id_term = i_term(k)
                        AND ic.id_institution = i_prof.institution
                        AND ic.id_software = i_prof.software
                        AND ict2.flg_main_focus = pk_alert_constant.g_yes
                        AND ich.flg_most_recent = pk_alert_constant.g_yes
                        AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                        AND ic.flg_available = pk_alert_constant.g_yes
                        AND ich.flg_cancel = pk_alert_constant.g_no
                        AND ia.id_icnp_version = pk_icnp.get_icnp_version(i_lang, i_prof));
        
        END IF;
    
        --get interv related if requested
        IF i_flg_child = pk_alert_constant.g_yes
        THEN
            g_error := 'UPDATE INTERVENTION FLG_CHILD';
            UPDATE tbl_temp tt
               SET tt.num_3 =
                   (SELECT COUNT(*)
                      FROM icnp_predefined_action_hist ipah
                      JOIN icnp_predefined_action ipa
                        ON ipa.id_predefined_action = ipah.id_predefined_action
                      JOIN icnp_composition ic
                        ON ipa.id_composition = ic.id_composition
                      JOIN icnp_composition_hist ich
                        ON ich.id_composition = ic.id_composition
                     WHERE ich.flg_most_recent = pk_alert_constant.g_yes
                       AND ic.flg_type = pk_icnp_constant.g_composition_type_action
                       AND ipah.flg_most_recent = pk_alert_constant.g_yes
                       AND ipah.flg_cancel = pk_alert_constant.g_no
                       AND ic.flg_available = pk_alert_constant.g_yes
                       AND ipa.flg_available = pk_alert_constant.g_yes
                       AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                       AND ipa.id_software IN (0, i_prof.software)
                       AND ic.id_institution = i_prof.institution
                       AND ic.id_software = i_prof.software
                       AND ipa.id_composition_parent IN
                           (SELECT id_composition
                              FROM icnp_composition_hist
                             WHERE id_composition_hist = tt.num_2))
             WHERE tt.num_1 IS NOT NULL;
        
        END IF;
    
        --open temporary table for output
        OPEN o_folder FOR
            SELECT tt.num_1 AS id_composition,
                   tt.num_2 AS id_composition_hist,
                   tt.vc_1 AS short_desc,
                   decode(nvl(tt.num_3, 0), 0, 'N', 'Y') AS has_child,
                   tt.vc_2 AS flg_cancel,
                   tt.vc_3 AS desc_type,
                   tt.num_4 rank,
                   tt.vc_4 compo_desc
              FROM tbl_temp tt
             WHERE tt.vc_1 IS NOT NULL
             ORDER BY compo_desc, rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_folder);
                RETURN FALSE;
            END;
        
    END get_icnp_composition_by_term;

    /********************************************************************************************
    * Returns all composition terms from focus axis that are already available throught diagnosis.
    * This function can filter self diagnostic
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      i_term      Focus term ID
    * @param      i_flg_child flag (Y/N to calculate has child nodes)
    * @param      o_folder    Icnp's focuses list
    * @param      o_error     Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/16
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_composition_by_term
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_term       IN table_number,
        i_flg_child  IN VARCHAR2,
        i_comp       IN icnp_composition.id_composition%TYPE,
        i_backoffice IN VARCHAR2 DEFAULT 'N',
        o_folder     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(50) := 'GET_ICNP_COMPOSITION_TERM';
    
    BEGIN
    
        DELETE tbl_temp;
    
        IF (i_term IS NULL OR i_term.count = 0)
        THEN
            IF i_flg_child = pk_alert_constant.g_no
            THEN
                g_error := 'OPEN O_FOLDER FOR ALL DIAG';
                OPEN o_folder FOR
                    SELECT DISTINCT (ic.id_composition),
                                    ich.id_composition_hist,
                                    pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc,
                                    'X' AS has_child
                      FROM icnp_composition ic
                      JOIN icnp_composition_hist ich
                        ON ic.id_composition = ich.id_composition
                      LEFT JOIN (SELECT *
                                   FROM icnp_predefined_action ipa
                                  WHERE ipa.flg_available = pk_alert_constant.g_yes
                                    AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                                    AND ipa.id_software IN (0, i_prof.software)) ipa
                        ON ipa.id_composition_parent = ic.id_composition
                     WHERE ich.id_composition = ic.id_composition
                       AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                       AND ich.flg_most_recent = pk_alert_constant.g_yes
                       AND ich.flg_cancel = pk_alert_constant.g_no
                       AND ic.id_composition <> nvl(i_comp, -1)
                       AND ic.flg_available = pk_alert_constant.g_yes
                       AND ic.id_institution = i_prof.institution
                       AND ic.id_software = i_prof.software
                       AND pk_translation.get_translation(i_lang, ic.code_icnp_composition) IS NOT NULL;
            
                RETURN TRUE;
            ELSE
                g_error := 'OPEN O_FOLDER FOR ALL DIAG CHILD';
                --get diagnosis
                INSERT INTO tbl_temp
                    (num_1, num_2, vc_1)
                    SELECT DISTINCT (ic.id_composition),
                                    ich.id_composition_hist,
                                    pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc
                      FROM icnp_composition_hist ich, icnp_composition ic, icnp_predefined_action ipa
                     WHERE ich.id_composition = ic.id_composition
                       AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                       AND ich.flg_most_recent = pk_alert_constant.g_yes
                       AND ipa.id_composition_parent = ic.id_composition
                       AND ic.flg_available = pk_alert_constant.g_yes
                       AND ipa.flg_available = pk_alert_constant.g_yes
                       AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                       AND ipa.id_software IN (0, i_prof.software)
                       AND ic.id_institution = i_prof.institution
                       AND ic.id_software = i_prof.software
                       AND ich.flg_cancel = pk_alert_constant.g_no;
            
            END IF;
        ELSE
            g_error := 'OPEN O_FOLDER FOR DIAG BY TERM';
            --get diagnosis
        
            IF i_backoffice = pk_alert_constant.g_yes
            THEN
            
                FORALL k IN i_term.first .. i_term.last
                
                    INSERT INTO tbl_temp
                        (num_1, num_2, vc_1, num_4, vc_4)
                        (SELECT DISTINCT (tb.id_composition),
                                         tb.id_composition_hist,
                                         pk_translation.get_translation(i_lang, tb.code_icnp_composition),
                                         (SELECT MAX(it.rank)
                                            FROM icnp_term it, icnp_composition_term ict
                                           WHERE it.id_term = ict.id_term
                                             AND ict.id_composition = ta.id_composition
                                             AND it.rank IS NOT NULL) rank,
                                         get_compo_desc_aux(i_lang, ta.id_composition) AS compo_desc
                           FROM (SELECT id_composition
                                   FROM icnp_composition_term ict
                                  WHERE ict.id_term = i_term(k)) ta
                          INNER JOIN (SELECT ic.id_composition, ich.id_composition_hist, ic.code_icnp_composition
                                       FROM icnp_composition ic
                                      INNER JOIN icnp_composition_hist ich
                                         ON ic.id_composition = ich.id_composition
                                       LEFT JOIN icnp_predefined_action ipa
                                         ON ipa.id_composition_parent = ic.id_composition
                                        AND ipa.flg_available = pk_alert_constant.g_yes
                                        AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                                        AND ipa.id_software IN (0, i_prof.software)
                                      WHERE ich.flg_most_recent = pk_alert_constant.g_yes
                                        AND ich.flg_cancel = pk_alert_constant.g_no
                                        AND ic.id_institution = i_prof.institution
                                        AND ic.id_software = i_prof.software
                                        AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                                        AND ic.flg_available = pk_alert_constant.g_yes) tb
                             ON ta.id_composition = tb.id_composition);
            ELSE
            
                FORALL k IN i_term.first .. i_term.last
                    INSERT INTO tbl_temp
                        (num_1, num_2, vc_1, num_4, vc_4)
                        (SELECT DISTINCT (tb.id_composition),
                                         tb.id_composition_hist,
                                         pk_translation.get_translation(i_lang, tb.code_icnp_composition),
                                         (SELECT MAX(it.rank)
                                            FROM icnp_term it, icnp_composition_term ict
                                           WHERE it.id_term = ict.id_term
                                             AND ict.id_composition = ta.id_composition
                                             AND it.rank IS NOT NULL) rank,
                                         get_compo_desc_aux(i_lang, ta.id_composition) AS compo_desc
                           FROM (SELECT id_composition
                                   FROM icnp_composition_term ict
                                  WHERE ict.id_term = i_term(k)) ta
                          INNER JOIN (SELECT ic.id_composition, ich.id_composition_hist, ic.code_icnp_composition
                                       FROM icnp_composition ic
                                      INNER JOIN icnp_composition_hist ich
                                         ON ic.id_composition = ich.id_composition
                                       JOIN icnp_predefined_action ipa
                                         ON ipa.id_composition_parent = ic.id_composition
                                        AND ipa.flg_available = pk_alert_constant.g_yes
                                        AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                                        AND ipa.id_software IN (0, i_prof.software)
                                      WHERE ich.flg_most_recent = pk_alert_constant.g_yes
                                        AND ich.flg_cancel = pk_alert_constant.g_no
                                        AND ic.id_institution = i_prof.institution
                                        AND ic.id_software = i_prof.software
                                        AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                                        AND ic.flg_available = pk_alert_constant.g_yes) tb
                             ON ta.id_composition = tb.id_composition);
            END IF;
        
        END IF;
    
        --get interv related if requested
        IF i_flg_child = pk_alert_constant.g_yes
        THEN
            g_error := 'UPDATE INTERVENTION FLG_CHILD';
            UPDATE tbl_temp tt
               SET tt.num_3 =
                   (SELECT COUNT(*)
                      FROM icnp_predefined_action_hist ipah
                      JOIN icnp_predefined_action ipa
                        ON ipa.id_predefined_action = ipah.id_predefined_action
                      JOIN icnp_composition ic
                        ON ipa.id_composition = ic.id_composition
                      JOIN icnp_composition_hist ich
                        ON ich.id_composition = ic.id_composition
                     WHERE ich.flg_most_recent = pk_alert_constant.g_yes
                       AND ic.flg_type = pk_icnp_constant.g_composition_type_action
                       AND ipah.flg_most_recent = pk_alert_constant.g_yes
                       AND ipah.flg_cancel = pk_alert_constant.g_no
                       AND ic.flg_available = pk_alert_constant.g_yes
                       AND ipa.flg_available = pk_alert_constant.g_yes
                       AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                       AND ipa.id_software IN (0, i_prof.software)
                       AND ic.id_institution = i_prof.institution
                       AND ic.id_software = i_prof.software
                       AND ipa.id_composition_parent IN
                           (SELECT id_composition
                              FROM icnp_composition_hist
                             WHERE id_composition_hist = tt.num_2))
             WHERE tt.num_1 IS NOT NULL;
        
        END IF;
    
        --open temporary table for output
        OPEN o_folder FOR
            SELECT tt.num_1 AS id_composition,
                   tt.num_2 AS id_composition_hist,
                   tt.vc_1 AS short_desc,
                   decode(nvl(tt.num_3, 0), 0, 'N', 'Y') AS has_child,
                   tt.num_4 rank,
                   tt.vc_4 compo_desc
              FROM tbl_temp tt
             WHERE tt.vc_1 IS NOT NULL
               AND tt.num_1 <> nvl(i_comp, -1)
             ORDER BY compo_desc, rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_folder);
                RETURN FALSE;
            END;
        
    END get_icnp_composition_by_term;

    /********************************************************************************************
    * Returns all composition from search string.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      o_folder  Icnp's focuses list
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/16
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_comp_by_search
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_search    IN VARCHAR2,
        o_folder    OUT pk_types.cursor_type,
        o_error     OUT t_error_out,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(50) := 'GET_ICNP_COMP_BY_SEARCH';
        l_count     PLS_INTEGER := 0;
    
    BEGIN
    
        g_error := 'DELETE FROM tbl_temp';
        DELETE FROM tbl_temp;
    
        g_error := 'OPEN O_FOLDER FOR ALL DIAG';
        FOR tmp_cur IN (SELECT t.id_composition, t.short_desc, t.flg_cancel, t.id_composition_hist
                          FROM (SELECT ic.id_composition,
                                       st.desc_translation AS short_desc,
                                       ich.flg_cancel,
                                       ich.id_composition_hist,
                                       row_number() over(PARTITION BY st.desc_translation ORDER BY ic.id_software DESC) rn
                                  FROM icnp_composition ic,
                                       icnp_composition_hist ich,
                                       TABLE(pk_translation.get_search_translation(i_lang,
                                                                                   i_search,
                                                                                   'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION')) st
                                 WHERE st.code_translation = ic.code_icnp_composition
                                   AND ic.id_composition = ich.id_composition
                                   AND ic.id_institution = i_prof.institution
                                   AND ic.id_software IN (0, i_prof.software)
                                   AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                                   AND ich.flg_most_recent = pk_alert_constant.g_yes
                                   AND ich.flg_cancel = pk_alert_constant.g_no) t
                         WHERE t.rn = 1
                        UNION
                        SELECT t.id_composition, t.short_desc, t.flg_cancel, t.id_composition_hist
                          FROM (SELECT ic.id_composition,
                                       pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc,
                                       ich.flg_cancel,
                                       ich.id_composition_hist,
                                       row_number() over(PARTITION BY ic.code_icnp_composition ORDER BY ic.id_software DESC) rn
                                  FROM icnp_composition ic, icnp_composition_hist ich
                                 WHERE ic.id_composition = ich.id_composition
                                   AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                                   AND ic.id_institution = i_prof.institution
                                   AND ic.id_software IN (0, i_prof.software)
                                   AND ich.flg_most_recent = pk_alert_constant.g_yes
                                   AND ich.flg_cancel = pk_alert_constant.g_no
                                   AND ic.code_icnp_composition = upper(TRIM(i_search))) t
                         WHERE t.rn = 1)
        
        LOOP
            INSERT INTO tbl_temp
                (num_1, vc_1, vc_2, num_3)
            VALUES
                (tmp_cur.id_composition, tmp_cur.short_desc, tmp_cur.flg_cancel, tmp_cur.id_composition_hist);
        
            l_count := l_count + 1;
        END LOOP;
    
        g_error := 'NO RESULT';
        IF l_count = 0
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'CIPE_T070');
            o_msg       := pk_message.get_message(i_lang, 'CIPE_M006');
            o_button    := 'R';
            pk_types.open_my_cursor(o_folder);
            RETURN TRUE;
            --RAISE l_my_exp;
        ELSE
            o_flg_show := 'N';
        
        END IF;
    
        g_error := 'CURSOR O_INFO';
        OPEN o_folder FOR
            SELECT tt.num_1 id_composition, tt.vc_1 short_desc, tt.vc_2 id_cancel_reason, tt.num_3 id_composition_hist
              FROM tbl_temp tt
             ORDER BY 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                --pk_util.undo_changes;
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_folder);
                RETURN FALSE;
            END;
        
    END get_icnp_comp_by_search;

    /********************************************************************************************
    * Returns all interventions or diagnosis based on id_composition.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_comp    Composition ID
    * @param      i_term    Term ID (optional)
    * @param      i_flag    Get all related (A)ctions or (D)iagnosis
    * @param      o_folder  Icnp's focuses list
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/16
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_interv_or_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_comp       IN icnp_composition_hist.id_composition_hist%TYPE,
        i_flag       VARCHAR2,
        i_interv_old IN table_number,
        o_folder     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(50) := 'GET_ICNP_INTERV_OR_DIAG';
    
        l_diag_has_focus VARCHAR2(1 CHAR);
    
    BEGIN
    
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO l_diag_has_focus
              FROM icnp_composition_hist ich
              JOIN icnp_composition_term ict
                ON ich.id_composition = ict.id_composition
             WHERE ich.id_composition_hist = i_comp
               AND ich.flg_most_recent = pk_alert_constant.g_yes
               AND ict.flg_main_focus = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                l_diag_has_focus := pk_alert_constant.g_no;
        END;
    
        g_error := 'OPEN O_FOLDER';
    
        IF i_flag = pk_icnp_constant.g_composition_type_diagnosis
        THEN
            IF l_diag_has_focus = pk_alert_constant.g_no
            THEN
                OPEN o_folder FOR
                    SELECT *
                      FROM (SELECT id_composition,
                                   id_composition id_composition_hist,
                                   pk_translation.get_translation(i_lang, code_icnp_composition) short_desc
                              FROM (SELECT DISTINCT ic.id_composition,
                                                    ic.flg_repeat,
                                                    ic.flg_solved,
                                                    ic.code_icnp_composition
                                      FROM icnp_predefined_action ipa
                                      JOIN icnp_composition ic
                                        ON ic.id_composition = ipa.id_composition
                                     WHERE ipa.id_composition_parent = i_comp
                                       AND ic.flg_type = 'A'
                                       AND ic.flg_available = pk_alert_constant.g_yes
                                       AND ipa.flg_available = pk_alert_constant.g_yes
                                       AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                                       AND ipa.id_software IN (0, i_prof.software)
                                       AND ic.id_institution = i_prof.institution
                                       AND EXISTS (SELECT dcs.id_dep_clin_serv
                                              FROM dep_clin_serv  dcs,
                                                   department     d,
                                                   dept           dp,
                                                   software_dept  sd,
                                                   icnp_compo_dcs icd
                                             WHERE d.id_department = dcs.id_department
                                               AND icd.id_dep_clin_serv = dcs.id_dep_clin_serv
                                               AND icd.id_composition = ic.id_composition
                                               AND d.id_institution = i_prof.institution
                                               AND dp.id_dept = d.id_dept
                                               AND sd.id_dept = dp.id_dept
                                               AND sd.id_software = i_prof.software)
                                       AND ic.id_composition NOT IN
                                           (SELECT ieiii.id_composition
                                              FROM icnp_epis_intervention ieiii
                                             WHERE ieiii.id_icnp_epis_interv IN
                                                   (SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                                                     t.column_value
                                                      FROM TABLE(i_interv_old) t)))
                             ORDER BY short_desc)
                     WHERE short_desc IS NOT NULL;
            
            ELSE
                --interv by diag
                OPEN o_folder FOR
                    SELECT ta.id_composition,
                           decode(ta.flg_cancel,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_yes,
                                  decode(tb.flg_cancel,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no)) flg_cancel,
                           ta.short_desc,
                           tb.id_cancel_connect,
                           ta.id_composition_hist,
                           desc_type,
                           flg_most_freq
                      FROM (SELECT DISTINCT ich2.id_composition,
                                            ich2.flg_cancel,
                                            ich2.id_composition_hist,
                                            ich2.flg_most_recent,
                                            pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc,
                                            pk_sysdomain.get_domain('ICNP_COMPOSITION.FLG_TYPE', ic.flg_type, i_lang) desc_type
                              FROM icnp_composition_hist ich2, icnp_composition ic
                             WHERE ic.id_composition = ich2.id_composition
                               AND ic.id_institution = i_prof.institution
                               AND ic.flg_available = pk_alert_constant.g_yes
                               AND ich2.flg_most_recent = pk_alert_constant.g_yes) ta,
                           (SELECT ich.id_composition_hist,
                                   ipah.flg_cancel AS id_cancel_connect,
                                   decode(ipah.id_cancel_reason, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_cancel,
                                   ipa.flg_most_freq flg_most_freq
                              FROM icnp_composition            ic,
                                   icnp_predefined_action      ipa,
                                   icnp_predefined_action_hist ipah,
                                   icnp_composition_hist       ich
                             WHERE EXISTS (SELECT 1
                                      FROM icnp_composition_hist
                                     WHERE id_composition_hist = i_comp
                                       AND id_composition = ipa.id_composition_parent)
                               AND ich.id_composition = ipa.id_composition
                               AND ipah.id_predefined_action = ipa.id_predefined_action
                               AND ipa.id_composition = ic.id_composition
                               AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                               AND ipa.id_software IN (0, i_prof.software)
                               AND ic.flg_available = pk_alert_constant.g_yes
                               AND ich.flg_most_recent = pk_alert_constant.g_yes
                               AND ich.flg_cancel = pk_alert_constant.g_no
                               AND ipa.flg_available = pk_alert_constant.g_yes
                               AND ic.flg_type = pk_icnp_constant.g_composition_type_action
                               AND ipah.flg_most_recent = pk_alert_constant.g_yes
                               AND ic.id_composition NOT IN
                                   (SELECT ieiii.id_composition
                                      FROM icnp_epis_intervention ieiii
                                     WHERE ieiii.id_icnp_epis_interv IN
                                           (SELECT /*+OPT_ESTIMATE (table t rows=1)*/
                                             t.column_value
                                              FROM TABLE(i_interv_old) t))) tb
                     WHERE ta.id_composition_hist = tb.id_composition_hist
                       AND decode(ta.flg_cancel,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_yes,
                                  decode(tb.flg_cancel,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no)) = pk_alert_constant.g_no
                       AND tb.id_cancel_connect = pk_alert_constant.g_no
                     ORDER BY 3;
            END IF;
        ELSE
            --diag by interv
            OPEN o_folder FOR
                SELECT DISTINCT ipa.id_composition_parent,
                                pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc,
                                ich.flg_cancel,
                                ipah.id_cancel_reason AS id_cancel_connect,
                                ich.id_composition_hist,
                                pk_sysdomain.get_domain('ICNP_COMPOSITION.FLG_TYPE', ic.flg_type, i_lang) desc_type,
                                ipa.flg_most_freq flg_most_freq
                  FROM icnp_composition            ic,
                       icnp_predefined_action      ipa,
                       icnp_predefined_action_hist ipah,
                       icnp_composition_hist       ich
                 WHERE ich.id_composition_hist = i_comp
                   AND ic.id_institution = i_prof.institution
                   AND ipa.id_composition = ich.id_composition
                   AND nvl(ipa.id_institution, 0) IN (0, i_prof.institution)
                   AND ipa.id_software IN (0, i_prof.software)
                   AND ipah.id_predefined_action = ipa.id_predefined_action
                   AND ic.id_composition = ipa.id_composition_parent
                   AND ipah.flg_most_recent = pk_alert_constant.g_yes
                   AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                   AND ich.flg_cancel = pk_alert_constant.g_no
                   AND ic.flg_available = pk_alert_constant.g_yes
                   AND ipa.flg_available = pk_alert_constant.g_yes
                 ORDER BY 2, 1;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_folder);
                RETURN FALSE;
            END;
        
    END get_icnp_interv_or_diag;

    /********************************************************************************************
    * Returns all diagnosis information based on id_composition.
    *
    * @param      i_lang       Preferred language ID for this professional
    * @param      i_prof       Object (professional ID, institution ID, software ID)
    * @param      i_comp       Composition ID
    * @param      o_date       Date history list
    * @param      o_pro        Professional list
    * @param      o_focus      Action focus list
    * @param      o_diag       Diagnosis
    * @param      o_diagre     Related Diagnosis
    * @param      o_interv     Related Interventions
    * @param      o_status     History description status (Edited/Created/Cancelled)
    * @param      o_flg_cancel Flag cancel(Y/N)
    * @param      o_error      Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/17
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_diag_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_comp          IN icnp_composition.id_composition%TYPE,
        i_comp_hst      IN icnp_composition_hist.id_composition_hist%TYPE,
        o_date          OUT table_varchar,
        o_pro           OUT table_varchar,
        o_focus         OUT table_varchar,
        o_diag          OUT table_varchar,
        o_diagre        OUT table_varchar,
        o_interv        OUT table_varchar,
        o_status        OUT table_varchar,
        o_flg_cancel    OUT VARCHAR2,
        o_cancel_reason OUT table_varchar,
        o_cancel_r      OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_counter       PLS_INTEGER;
        l_tmp_str       VARCHAR2(4000);
        l_tmp_comp      NUMERIC;
        l_focus_str     VARCHAR2(100);
        l_diag_r_str    VARCHAR2(4000);
        l_interv_str    VARCHAR2(4000);
        l_comp          icnp_composition.id_composition%TYPE;
        l_comp_prev     icnp_composition.id_composition%TYPE;
        l_comp_hist     icnp_composition_hist.id_composition_hist%TYPE;
        l_ipah_max      icnp_predefined_action_hist.id_predefined_action_hist%TYPE;
        l_compo_hist    icnp_composition_hist.id_composition_hist%TYPE;
        l_prof_id       VARCHAR(200);
        l_id_cancel     cancel_reason.id_cancel_reason%TYPE;
        l_cancel        VARCHAR2(1);
        l_prof_cancel   VARCHAR(200);
        l_cancel_date   VARCHAR(200);
        l_func_name     VARCHAR2(50) := 'GET_ICNP_DIAG_HIST';
        l_diag_prv_str  VARCHAR2(4000);
        l_created_str   VARCHAR2(50);
        l_edited_str    VARCHAR2(50);
        l_canceled_str  VARCHAR2(50);
        l_cancel_reason VARCHAR2(32767); --REASON NOTES
        l_cancel_r      VARCHAR2(200); --REASON
    
        i                  PLS_INTEGER := 0;
        l_cancelled        BOOLEAN := FALSE;
        l_interv_cancelled table_varchar := table_varchar();
        l_interv           table_varchar := table_varchar();
    
        CURSOR c_diag(l_tmp_comp NUMBER) IS
            SELECT pk_translation.get_translation(i_lang, it.code_term) AS main_focus,
                   pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS desc_compo,
                   ich.id_cancel_reason,
                   pk_date_utils.date_time_chr_tsz(i_lang, ich.dt_cancel, i_prof),
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ich.id_prof_cancel),
                   ich.id_composition_hist,
                   ich.reason_notes, --CR
                   pk_translation.get_translation(i_lang, cr.code_cancel_reason)
              FROM icnp_composition      ic,
                   icnp_composition_hist ich,
                   icnp_composition_term ict,
                   icnp_term             it,
                   cancel_reason         cr
             WHERE ic.id_composition = ict.id_composition
               AND ic.id_composition = ich.id_composition
               AND ict.id_term = it.id_term
               AND ict.flg_main_focus = pk_alert_constant.g_yes
               AND ic.id_composition = l_tmp_comp
               AND pk_translation.get_translation(i_lang, ic.code_icnp_composition) IS NOT NULL
               AND ich.id_cancel_reason(+) = cr.id_cancel_reason;
    
        CURSOR c_recent_pred IS
            SELECT MAX(ipah.id_predefined_action_hist)
              FROM icnp_predefined_action_hist ipah, icnp_predefined_action ipa
             WHERE ipa.id_composition_parent = i_comp;
    
    BEGIN
    
        o_date          := table_varchar();
        o_focus         := table_varchar();
        o_diag          := table_varchar();
        o_diagre        := table_varchar();
        o_interv        := table_varchar();
        o_pro           := table_varchar();
        o_status        := table_varchar();
        o_cancel_reason := table_varchar();
        o_cancel_r      := table_varchar();
        l_counter       := 1;
        l_ipah_max      := 0;
        l_prof_id       := '';
        o_flg_cancel    := 'N';
        l_comp_hist     := i_comp_hst;
    
        --get_composition_hist and messages
        SELECT pk_message.get_message(i_lang, 'ICNP_T047'),
               pk_message.get_message(i_lang, 'ICNP_T049'),
               pk_message.get_message(i_lang, 'ICNP_T091')
          INTO l_created_str, l_edited_str, l_canceled_str
          FROM dual;
    
        g_error := 'GET RECENT PREDEFINED HISTORY';
        OPEN c_recent_pred;
        FETCH c_recent_pred
            INTO l_ipah_max;
        CLOSE c_recent_pred;
    
        DELETE tbl_temp;
    
        INSERT INTO tbl_temp tt
            (num_1, num_2, vc_1, vc_2, vc_3, num_3, vc_4, vc_5)
            (SELECT MAX(hst_id1) AS hst_id1,
                    MAX(hst_id2) AS hst_id2,
                    pk_date_utils.date_time_chr_tsz(i_lang, to_date(dt_tmp, 'YYYYMMDDHH24MISS'), i_prof) AS dt_tmp2,
                    decode(MAX(prof_id1), -1, '', pk_prof_utils.get_name_signature(i_lang, i_prof, MAX(prof_id1))) AS prof_id1,
                    decode(MAX(prof_id2), -1, '', pk_prof_utils.get_name_signature(i_lang, i_prof, MAX(prof_id2))) AS prof_id2,
                    dt_tmp,
                    MAX(desc_compo) AS desc_compo,
                    MAX(flg_cancel) AS flg_cancel
               FROM (SELECT ipah.id_predefined_action_hist AS hst_id1,
                            0 AS hst_id2,
                            ipah.id_professional AS prof_id1,
                            -1 AS prof_id2,
                            to_char(ipah.dt_predefined_action_hist, 'YYYYMMDDHH24MISS') AS dt_tmp,
                            '' AS desc_compo,
                            'N' AS flg_cancel
                       FROM icnp_predefined_action_hist ipah, icnp_predefined_action ipa
                      WHERE ipa.id_composition_parent IN
                            (SELECT id_composition
                               FROM icnp_composition_hist ich
                              WHERE ich.id_composition_hist = l_comp_hist)
                        AND ipah.id_predefined_action = ipa.id_predefined_action
                        AND nvl(ipah.hist_notes, 'internal:') != 'internal:interv_updated'
                     UNION ALL
                     SELECT 0 AS hst_id1,
                            ich.id_composition AS hst_id2,
                            -1 AS prof_id1,
                            ich.id_professional AS prof_id2,
                            to_char(ich.dt_composition_hist, 'YYYYMMDDHH24MISS') AS dt_tmp,
                            pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS desc_compo,
                            ich.flg_cancel
                       FROM icnp_composition_hist ich
                      INNER JOIN icnp_composition ic
                         ON ic.id_composition = ich.id_composition
                      WHERE ich.id_composition_hist = l_comp_hist
                     UNION ALL
                     SELECT ipah.id_predefined_action_hist AS hst_id1,
                            0 AS hst_id2,
                            ipah.id_prof_cancel AS prof_id1,
                            -1 AS prof_id2,
                            to_char(ipah.dt_cancel, 'YYYYMMDDHH24MISS') AS dt_tmp,
                            '' AS desc_compo,
                            'Y' AS flg_cancel
                       FROM icnp_predefined_action_hist ipah, icnp_predefined_action ipa
                      WHERE ipah.id_predefined_action = ipa.id_predefined_action
                        AND ipah.id_cancel_reason IS NOT NULL
                        AND ipa.id_composition_parent IN
                            (SELECT id_composition
                               FROM icnp_composition_hist ich
                              WHERE ich.id_composition_hist = l_comp_hist))
             
              GROUP BY dt_tmp);
    
        UPDATE tbl_temp tt
           SET tt.vc_6 =
               (SELECT pk_translation.get_translation(i_lang, it.code_term)
                  FROM icnp_composition_term ict
                 INNER JOIN icnp_term it
                    ON ict.id_term = it.id_term
                 WHERE ict.id_composition = tt.num_2
                   AND ict.flg_main_focus = pk_alert_constant.g_yes);
    
        g_error := 'GET COMPOSITION HISTORY';
        FOR rec IN (SELECT num_1 AS hst_id1,
                           num_2 AS hst_id2,
                           vc_1  AS dt_tmp2,
                           vc_2  AS prof_id1,
                           vc_3  AS prof_id2,
                           num_3 AS dt_tmp,
                           vc_4  AS desc_compo,
                           vc_5  AS id_cancel_reason,
                           vc_6  AS main_focus
                      FROM tbl_temp
                     WHERE num_1 IS NOT NULL
                     ORDER BY num_3 ASC)
        LOOP
        
            IF rec.hst_id2 = 0
            THEN
                l_comp    := nvl(l_comp_prev, i_comp);
                l_prof_id := rec.prof_id1;
            ELSE
                l_comp    := rec.hst_id2;
                l_prof_id := rec.prof_id2;
            END IF;
        
            IF l_comp != nvl(l_comp_prev, -1)
            THEN
                l_focus_str  := rec.main_focus;
                l_tmp_str    := rec.desc_compo;
                l_cancel     := rec.id_cancel_reason;
                l_compo_hist := i_comp_hst;
            END IF;
        
            --get diag and interv linked
            l_diag_r_str := NULL;
            l_interv_str := NULL;
        
            IF rec.hst_id1 <> 0
            THEN
                l_ipah_max := rec.hst_id1;
            END IF;
        
            IF rec.hst_id1 <> 0
            THEN
                FOR rec2 IN (SELECT id_composition, flg_type, short_desc, flg_cancel, dt_cancel
                               FROM (SELECT ic.id_composition,
                                            ic.flg_type,
                                            pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc,
                                            (SELECT DISTINCT flg_cancel
                                               FROM icnp_composition_hist
                                              WHERE id_composition_hist = ich2.id_composition_hist
                                                AND flg_most_recent = pk_alert_constant.g_yes) AS flg_cancel,
                                            to_char(ipah.dt_cancel, 'YYYYMMDDHH24MISS') dt_cancel,
                                            row_number() over(PARTITION BY ipah.id_predefined_action_hist, ich2.id_composition_hist, ic.flg_type ORDER BY ipah.id_predefined_action_hist DESC, ic.id_composition DESC, flg_type DESC) rn
                                       FROM icnp_predefined_action ipa,
                                            icnp_predefined_action_hist ipah,
                                            icnp_composition ic,
                                            (SELECT DISTINCT id_composition_hist, id_composition
                                               FROM icnp_composition_hist) ich2
                                      WHERE ipah.id_predefined_action_hist = l_ipah_max
                                        AND ipa.id_predefined_action = ipah.id_predefined_action
                                        AND ipa.id_composition = ic.id_composition
                                        AND ipa.id_composition_parent IN
                                            (SELECT DISTINCT id_composition
                                               FROM icnp_composition_hist
                                              WHERE id_composition_hist = l_compo_hist)
                                        AND ich2.id_composition = ipa.id_composition
                                      ORDER BY ipah.id_predefined_action_hist DESC, flg_type DESC)
                              WHERE rn = 1)
                LOOP
                    IF rec2.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                    THEN
                        IF l_diag_r_str IS NULL
                        THEN
                            l_diag_r_str := coalesce(rec2.short_desc, '');
                        ELSE
                            l_diag_r_str := l_diag_r_str || '; ' || coalesce(rec2.short_desc, '');
                        END IF;
                    
                        IF rec2.flg_cancel = pk_alert_constant.g_yes
                        THEN
                            l_diag_r_str := l_diag_r_str || ' ' || pk_message.get_message(i_lang, 'ICNP_T096');
                        END IF;
                    ELSE
                        IF rec.id_cancel_reason = pk_alert_constant.g_yes
                        THEN
                            l_cancelled := TRUE;
                        END IF;
                    
                        IF l_interv_str IS NULL
                        THEN
                            l_interv_str := coalesce(rec2.short_desc, '');
                        ELSE
                            l_interv_str := l_interv_str || '; ' || coalesce(rec2.short_desc, '');
                        END IF;
                    
                        IF l_cancelled
                           AND rec2.flg_cancel = pk_alert_constant.g_yes
                           AND rec.dt_tmp = rec2.dt_cancel
                        THEN
                            i := i + 1;
                            l_interv_cancelled.extend();
                            l_interv_cancelled(i) := rec2.short_desc;
                        END IF;
                    
                        IF l_interv_cancelled.count > 0
                        THEN
                            FOR j IN l_interv_cancelled.first .. l_interv_cancelled.last
                            LOOP
                                l_interv_str := REPLACE(l_interv_str, l_interv_cancelled(j), '');
                            END LOOP;
                        END IF;
                    
                        l_interv_str := regexp_replace(l_interv_str, '; $', '');
                    
                    END IF;
                END LOOP;
            
            END IF;
        
            o_focus.extend;
            o_diag.extend;
            o_date.extend;
            o_pro.extend;
            o_diagre.extend;
            o_interv.extend;
            o_status.extend;
            o_cancel_reason.extend; --CR
            o_cancel_r.extend; --R
            o_focus(l_counter) := l_focus_str;
            o_diag(l_counter) := l_tmp_str;
            o_date(l_counter) := rec.dt_tmp2;
            o_pro(l_counter) := l_prof_id;
            o_diagre(l_counter) := l_diag_r_str;
            o_interv(l_counter) := l_interv_str;
            o_cancel_reason(l_counter) := NULL; --CR
            o_cancel_r(l_counter) := NULL; --R
        
            IF l_counter = 1
            THEN
                o_status(l_counter) := l_created_str;
            ELSE
                o_status(l_counter) := l_edited_str;
            END IF;
            l_counter := l_counter + 1;
        
            l_comp_prev    := l_comp;
            l_diag_prv_str := l_diag_r_str;
        
        END LOOP;
    
        IF l_cancel = pk_alert_constant.g_yes
        THEN
            --get focus and diagnoses desc
            OPEN c_diag(l_comp); --l_comp
            FETCH c_diag
                INTO l_focus_str,
                     l_tmp_str,
                     l_id_cancel,
                     l_cancel_date,
                     l_prof_cancel,
                     l_compo_hist,
                     l_cancel_reason,
                     l_cancel_r;
            CLOSE c_diag;
        
            o_focus.extend;
            o_diag.extend;
            o_date.extend;
            o_pro.extend;
            o_diagre.extend;
            o_interv.extend;
            o_status.extend;
            o_cancel_reason.extend; --CR
            o_cancel_r.extend; --R
            o_focus(l_counter) := l_focus_str;
            o_diag(l_counter) := l_tmp_str;
            o_date(l_counter) := l_cancel_date;
            o_pro(l_counter) := l_prof_cancel;
            o_diagre(l_counter) := nvl(l_diag_r_str, '');
            o_interv(l_counter) := nvl(l_interv_str, '');
            o_status(l_counter) := l_canceled_str;
            o_cancel_reason(l_counter) := l_cancel_reason; --CR
            o_cancel_r(l_counter) := l_cancel_r; --R
            o_flg_cancel := 'Y';
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_icnp_diag_hist;

    /********************************************************************************************
    * Returns diagnosis information based on id_composition.
    *
    * @param      i_lang     Preferred language ID for this professional
    * @param      i_prof     Object (professional ID, institution ID, software ID)
    * @param      i_comp     Composition ID
    * @param      i_comp_hst Composition ID (History ID)
    * @param      o_term     List of composition terms
    * @param      o_comp     List of related compositions
    * @param      o_error    Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/03/30
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_diag_for_update
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_comp     IN icnp_composition.id_composition%TYPE,
        i_comp_hst IN icnp_composition_hist.id_composition_hist%TYPE,
        o_term     OUT pk_types.cursor_type,
        o_comp     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(50) := 'GET_ICNP_DIAG_FOR_UPDATE';
        l_compo_hist icnp_composition_hist.id_composition_hist%TYPE;
    
    BEGIN
        --get composition hist
        l_compo_hist := i_comp_hst;
    
        --get diagnosis terms list (main focus and flag axis inclusive)
        g_error := 'GET O_TERM LIST';
        OPEN o_term FOR
            SELECT ict.id_term,
                   pk_translation.get_translation(ict.id_language, it.code_term) AS short_desc,
                   ict.rank,
                   ict.desc_term,
                   nvl(ict.flg_main_focus, pk_alert_constant.g_no) AS main_focus,
                   ia.flg_axis
              FROM icnp_composition_term ict
             INNER JOIN icnp_term it
                ON ict.id_term = it.id_term
             INNER JOIN icnp_axis ia
                ON ia.id_axis = it.id_axis
             WHERE id_composition = (SELECT id_composition
                                       FROM icnp_composition_hist ich
                                      WHERE ich.id_composition_hist = l_compo_hist
                                        AND ich.flg_most_recent = pk_alert_constant.g_yes)
             ORDER BY ict.rank;
    
        --get list of related compositions (canceled inclusive)
        g_error := 'GET O_COMP LIST';
        OPEN o_comp FOR
            SELECT DISTINCT (SELECT id_composition -- distinct because of historic data
                               FROM icnp_composition_hist ich2
                              WHERE ich2.id_composition_hist = ich.id_composition_hist
                                AND ich2.flg_most_recent = pk_alert_constant.g_yes) AS id_composition,
                            --pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc,
                            get_compo_desc_by_date(i_lang, ich.id_composition_hist, NULL) AS short_desc,
                            ich.id_cancel_reason,
                            ipah.id_cancel_reason AS id_cancel_connect
              FROM icnp_predefined_action ipa
             INNER JOIN icnp_predefined_action_hist ipah
                ON ipa.id_predefined_action = ipah.id_predefined_action
             INNER JOIN icnp_composition ic
                ON ipa.id_composition = ic.id_composition
             INNER JOIN icnp_composition_hist ich
                ON ic.id_composition = ich.id_composition
             WHERE ipa.id_composition_parent IN
                   (SELECT id_composition
                      FROM icnp_composition_hist
                     WHERE id_composition_hist = l_compo_hist)
               AND ipah.flg_most_recent = pk_alert_constant.g_yes
               AND ipah.flg_cancel = pk_alert_constant.g_no
               AND nvl(ipa.id_institution, pk_icnp_constant.g_institution_all) IN
                   (pk_icnp_constant.g_institution_all, i_prof.institution)
               AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
               AND pk_translation.get_translation(i_lang, ic.code_icnp_composition) IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_term);
                pk_types.open_my_cursor(o_comp);
                RETURN FALSE;
            END;
        
    END get_icnp_diag_for_update;

    /********************************************************************************************
    * Returns intervention information based on id_composition.
    *
    * @param      i_lang     Preferred language ID for this professional
    * @param      i_prof     Object (professional ID, institution ID, software ID)
    * @param      i_comp     Composition ID
    * @param      i_comp_hst ID of composition hist
    * @param      o_term     List of composition terms
    * @param      o_comp     List of related diagnosis
    * @param      o_area     Related application area
    * @param      o_error    Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/03/30
    * @dependents            PK_TRANSLATION.GET_TRANSLATION    <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_interv_for_update
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_comp     IN icnp_composition.id_composition%TYPE,
        i_comp_hst IN icnp_composition_hist.id_composition_hist%TYPE,
        o_term     OUT pk_types.cursor_type,
        o_comp     OUT pk_types.cursor_type,
        o_area     OUT pk_types.cursor_type,
        o_inst     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(50) := 'GET_ICNP_INTERV_FOR_UPDATE';
        l_compo_hist icnp_composition_hist.id_composition_hist%TYPE;
        l_compo      icnp_composition.id_composition%TYPE;
    
    BEGIN
        --get composition hist
        l_compo_hist := i_comp_hst;
    
        SELECT id_composition
          INTO l_compo
          FROM icnp_composition_hist ich
         WHERE ich.id_composition_hist = i_comp_hst
           AND ich.flg_most_recent = pk_alert_constant.g_yes;
    
        --get intervention terms list (main focus and flag axis inclusive)
        g_error := 'GET O_TERM LIST';
        OPEN o_term FOR
            SELECT ict.id_term,
                   pk_translation.get_translation(ict.id_language, it.code_term) AS short_desc,
                   ict.rank,
                   ict.desc_term,
                   nvl(ict.flg_main_focus, pk_alert_constant.g_no) AS main_focus,
                   ia.flg_axis
              FROM icnp_composition_term ict
             INNER JOIN icnp_term it
                ON ict.id_term = it.id_term
             INNER JOIN icnp_axis ia
                ON ia.id_axis = it.id_axis
             WHERE id_composition = l_compo
             ORDER BY ict.rank;
    
        --get list of related compositions (not canceled)
        g_error := 'GET O_COMP LIST';
        OPEN o_comp FOR
            SELECT DISTINCT ic.id_composition,
                            get_compo_desc_by_date(i_lang, ich.id_composition_hist, NULL) AS short_desc,
                            ich.id_cancel_reason,
                            ipah.id_cancel_reason AS id_cancel_connect,
                            ipa.flg_most_freq,
                            pk_sysdomain.get_domain('ICNP_PREDEFINED_ACTION.FLG_MOST_FREQ', ipa.flg_most_freq, i_lang) desc_flg_most_freq
              FROM icnp_predefined_action ipa
             INNER JOIN icnp_predefined_action_hist ipah
                ON ipa.id_predefined_action = ipah.id_predefined_action
             INNER JOIN icnp_composition ic
                ON ipa.id_composition_parent = ic.id_composition
             INNER JOIN icnp_composition_hist ich
                ON ipa.id_composition_parent = ich.id_composition
             WHERE ipa.id_composition IN (SELECT id_composition
                                            FROM icnp_composition_hist
                                           WHERE id_composition_hist = l_compo_hist)
               AND ipah.flg_most_recent = pk_alert_constant.g_yes
               AND nvl(ipa.id_institution, pk_icnp_constant.g_institution_all) IN
                   (pk_icnp_constant.g_institution_all, i_prof.institution)
               AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
               AND ich.flg_cancel = pk_alert_constant.g_no
               AND ipah.flg_cancel <> pk_alert_constant.g_yes;
    
        --get application area ID
        g_error := 'GET O_AREA';
        OPEN o_area FOR
            SELECT iaa.id_application_area,
                   pk_translation.get_translation(i_lang, iaa.area_code) short_desc,
                   pk_translation.get_translation(i_lang, iaa.parameter_desc) param_desc,
                   iaa.area area
              FROM icnp_composition ic
             INNER JOIN icnp_application_area iaa
                ON iaa.id_application_area = ic.id_application_area
             WHERE ic.id_composition = l_compo
               AND ic.id_doc_template IS NULL
            UNION ALL
            SELECT dt.id_doc_template * -1,
                   pk_message.get_message(i_lang, 'ICNP_T097') short_desc,
                   coalesce(pk_translation.get_translation(i_lang, dt.code_doc_template), dt.internal_name) param_desc,
                   NULL area
              FROM icnp_composition ic
             INNER JOIN doc_template dt
                ON ic.id_doc_template = dt.id_doc_template
             WHERE ic.id_composition = l_compo
               AND ic.id_doc_template IS NOT NULL;
    
        --get instruction list 
        g_error := 'GET O_INSTRUCTION LIST';
        OPEN o_inst FOR
            SELECT idim.id_software, idim.id_order_recurr_option, idim.flg_prn, idim.prn_notes, idim.flg_time, s.name
              FROM icnp_default_instructions_msi idim
             INNER JOIN software s
                ON s.id_software = idim.id_software
             WHERE idim.id_composition = l_compo;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_term);
                pk_types.open_my_cursor(o_comp);
                pk_types.open_my_cursor(o_area);
                pk_types.open_my_cursor(o_inst);
            
                RETURN FALSE;
            END;
        
    END get_icnp_interv_for_update;

    /********************************************************************************************
    * Returns all intervention information based on id_composition.
    *
    * @param      i_lang       Preferred language ID for this professional
    * @param      i_prof       Object (professional ID, institution ID, software ID)
    * @param      i_comp       Composition ID
    * @param      o_date       Date history list
    * @param      o_pro        Professional list
    * @param      o_action     Action focus list
    * @param      o_comp       Build intervention
    * @param      o_diagre     Related Diagnosis
    * @param      o_app        Application areas
    * @param      o_status     History description status (Edited/Created/Cancelled)
    * @param      o_flg_cancel Application areas
    * @param      o_error      Error
    *
    * @return                  boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                  Pedro Lopes
    * @version                 1
    * @since                   2009/05/11
    * @dependents              PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                          PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                          PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_interv_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_comp          IN icnp_composition.id_composition%TYPE,
        i_comp_hst      IN icnp_composition_hist.id_composition_hist%TYPE,
        o_date          OUT table_varchar,
        o_pro           OUT table_varchar,
        o_action        OUT table_varchar,
        o_comp          OUT table_varchar,
        o_diagre        OUT table_varchar,
        o_app           OUT table_varchar,
        o_status        OUT table_varchar,
        o_flg_cancel    OUT VARCHAR2,
        o_cancel_reason OUT table_varchar,
        o_cancel_r      OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_counter       PLS_INTEGER;
        l_tmp_str       VARCHAR2(4000);
        l_tmp_comp      NUMERIC;
        l_focus_str     VARCHAR2(100);
        l_diag_r_str    VARCHAR2(4000);
        l_diag_prv_str  VARCHAR2(4000);
        l_app_str       VARCHAR2(4000);
        l_comp          icnp_composition.id_composition%TYPE;
        l_comp_prev     icnp_composition.id_composition%TYPE;
        l_comp_hist     icnp_composition_hist.id_composition_hist%TYPE;
        l_ipah_max      icnp_predefined_action_hist.id_predefined_action_hist%TYPE;
        l_ipah_prev     icnp_predefined_action_hist.id_predefined_action_hist%TYPE;
        l_prof_id       VARCHAR(200);
        l_id_cancel     cancel_reason.id_cancel_reason%TYPE;
        l_prof_cancel   VARCHAR(200);
        l_cancel_date   VARCHAR(200);
        l_func_name     VARCHAR2(50) := 'GET_ICNP_DIAG_HIST';
        l_created_str   VARCHAR2(50);
        l_edited_str    VARCHAR2(50);
        l_canceled_str  VARCHAR2(50);
        l_doc_template  icnp_composition.id_doc_template%TYPE;
        l_cancel_reason VARCHAR2(32767); --REASON NOTES
        l_cancel_r      VARCHAR2(200); --REASON
    
        CURSOR c_interv(l_tmp_comp NUMBER) IS
            SELECT pk_translation.get_translation(i_lang, it.code_term) AS main_focus,
                   coalesce(pk_translation.get_translation(i_lang, ic.code_icnp_composition),
                            get_compo_desc(i_lang, l_tmp_comp)) AS desc_compo,
                   ich.id_cancel_reason,
                   pk_date_utils.date_time_chr_tsz(i_lang, ich.dt_cancel, i_prof),
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ich.id_prof_cancel),
                   ich.id_composition_hist,
                   decode(iaa.area,
                          NULL,
                          '',
                          pk_message.get_message(i_lang, 'ICNP_T084') || ': ' ||
                          pk_translation.get_translation(i_lang, iaa.area_code) || ', ' ||
                          pk_message.get_message(i_lang, 'ICNP_T085') || ': ' ||
                          pk_translation.get_translation(i_lang, iaa.parameter_desc)),
                   ic.id_doc_template,
                   ich.reason_notes --REASON NOTES
              FROM icnp_composition_hist ich,
                   icnp_composition      ic,
                   icnp_composition_term ict,
                   icnp_term             it,
                   icnp_application_area iaa
             WHERE ic.id_composition = ict.id_composition
               AND ic.id_composition = ich.id_composition
               AND ict.id_term = it.id_term
               AND ict.flg_main_focus = pk_alert_constant.g_yes
               AND ic.id_composition = l_tmp_comp
               AND ic.id_application_area = iaa.id_application_area(+);
    
        CURSOR c_cancel_r(l_tmp_cancel NUMBER) IS
            SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason) AS cancel_r
              FROM cancel_reason cr
             WHERE cr.id_cancel_reason = l_tmp_cancel;
    
    BEGIN
    
        o_date          := table_varchar();
        o_action        := table_varchar();
        o_comp          := table_varchar();
        o_diagre        := table_varchar();
        o_app           := table_varchar();
        o_pro           := table_varchar();
        o_status        := table_varchar();
        o_cancel_reason := table_varchar(); --RN
        o_cancel_r      := table_varchar(); --R
        l_counter       := 1;
        l_prof_id       := '';
        l_diag_prv_str  := '';
        o_flg_cancel    := 'N';
        l_comp_hist     := i_comp_hst;
    
        --get composition hist
        SELECT pk_message.get_message(i_lang, 'ICNP_T048'),
               pk_message.get_message(i_lang, 'ICNP_T050'),
               pk_message.get_message(i_lang, 'ICNP_T091')
          INTO l_created_str, l_edited_str, l_canceled_str
          FROM dual;
    
        g_error := 'GET COMPOSITION HISTORY';
        FOR rec IN (SELECT MAX(hst_id1) AS hst_id1,
                           MAX(hst_id2) AS hst_id2,
                           pk_date_utils.date_time_chr_tsz(i_lang, to_date(dt_tmp, 'YYYYMMDDHH24MISS'), i_prof) AS dt_tmp2,
                           dt_tmp,
                           decode(MAX(prof_id1), -1, '', pk_prof_utils.get_name_signature(i_lang, i_prof, MAX(prof_id1))) AS prof_id1,
                           decode(MAX(prof_id2), -1, '', pk_prof_utils.get_name_signature(i_lang, i_prof, MAX(prof_id2))) AS prof_id2
                      FROM (SELECT ipah.id_predefined_action_hist AS hst_id1,
                                   0 AS hst_id2,
                                   MAX(ipah.id_professional) AS prof_id1,
                                   -1 AS prof_id2,
                                   MAX(to_char(ipah.dt_predefined_action_hist, 'YYYYMMDDHH24MISS')) AS dt_tmp
                              FROM icnp_predefined_action_hist ipah, icnp_predefined_action ipa
                             WHERE ipah.id_predefined_action = ipa.id_predefined_action
                               AND ipa.id_composition IN
                                   (SELECT DISTINCT id_composition
                                      FROM icnp_composition_hist ich
                                     WHERE ich.id_composition_hist = l_comp_hist)
                             GROUP BY ipah.id_predefined_action_hist
                            UNION ALL
                            SELECT 0 AS hst_id1,
                                   id_composition AS hst_id2,
                                   -1 AS prof_id1,
                                   ich.id_professional AS prof_id2,
                                   to_char(dt_composition_hist, 'YYYYMMDDHH24MISS') AS dt_tmp
                              FROM icnp_composition_hist ich
                             WHERE id_composition_hist = l_comp_hist)
                     GROUP BY dt_tmp
                     ORDER BY dt_tmp ASC)
        LOOP
        
            l_comp    := rec.hst_id2;
            l_prof_id := rec.prof_id2;
        
            IF rec.hst_id2 = 0
            THEN
                l_comp    := nvl(l_comp_prev, i_comp);
                l_prof_id := rec.prof_id1;
            ELSE
                l_comp    := rec.hst_id2;
                l_prof_id := rec.prof_id2;
            END IF;
        
            IF NOT (l_comp = nvl(l_comp_prev, -1))
            THEN
                --get atention focus and intervention description
                OPEN c_interv(l_comp);
                FETCH c_interv
                    INTO l_focus_str,
                         l_tmp_str,
                         l_id_cancel,
                         l_cancel_date,
                         l_prof_cancel,
                         l_comp_hist,
                         l_app_str,
                         l_doc_template,
                         l_cancel_reason;
                CLOSE c_interv;
            END IF;
        
            IF l_doc_template IS NOT NULL
            THEN
                SELECT pk_message.get_message(i_lang, 'ICNP_T084') || ': ' ||
                       pk_message.get_message(i_lang, 'ICNP_T097') || ', ' ||
                       pk_message.get_message(i_lang, 'ICNP_T085') || ': ' ||
                       coalesce(pk_translation.get_translation(i_lang, dt.code_doc_template), dt.internal_name)
                  INTO l_app_str
                  FROM doc_template dt
                 WHERE dt.id_doc_template = l_doc_template;
            END IF;
        
            --get diag and application areas linked
            l_diag_r_str := NULL;
        
            FOR rec2 IN (SELECT DISTINCT ich2.id_composition_hist,
                                         ich2.id_composition,
                                         --pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc
                                         get_compo_desc_by_date(i_lang, ich2.id_composition_hist, NULL) AS short_desc,
                                         ich2.flg_cancel,
                                         ipah.flg_cancel AS flg_cancel_ipah,
                                         ipah.dt_predefined_action_hist,
                                         ipah.dt_cancel
                           FROM icnp_predefined_action      ipa,
                                icnp_predefined_action_hist ipah,
                                icnp_composition            ic,
                                icnp_composition_hist       ich2
                          WHERE ipa.id_predefined_action = ipah.id_predefined_action
                            AND ipa.id_composition_parent = ic.id_composition
                            AND ipa.id_composition IN
                                (SELECT DISTINCT id_composition
                                   FROM icnp_composition_hist ich
                                  WHERE ich.id_composition_hist = l_comp_hist)
                            AND to_char(ipah.dt_predefined_action_hist, 'YYYYMMDDHH24MISS') = rec.dt_tmp
                            AND ich2.id_composition = ic.id_composition
                          ORDER BY dt_predefined_action_hist)
            LOOP
            
                IF l_diag_r_str IS NULL
                THEN
                    l_diag_r_str := rec2.short_desc;
                ELSE
                    l_diag_r_str := l_diag_r_str || '; ' || rec2.short_desc;
                END IF;
            
                IF rec2.flg_cancel = pk_alert_constant.g_yes
                THEN
                    l_diag_r_str := l_diag_r_str || pk_message.get_message(i_lang, 'ICNP_T096');
                END IF;
            
            END LOOP;
        
            IF rec.hst_id2 <> 0
               OR (rec.hst_id1 <> 0 AND l_diag_r_str <> nvl(l_diag_prv_str, 'zzzzzzzzzzzzzzzzz'))
            THEN
            
                IF rec.hst_id1 = 0
                THEN
                    l_diag_r_str := l_diag_prv_str;
                END IF;
            
                o_diagre.extend;
                o_app.extend;
                o_action.extend;
                o_comp.extend;
                o_date.extend;
                o_pro.extend;
                o_status.extend;
                o_cancel_reason.extend; --CR
                o_cancel_r.extend; --R
                o_diagre(l_counter) := l_diag_r_str;
                o_app(l_counter) := l_app_str;
                o_action(l_counter) := l_focus_str;
                o_comp(l_counter) := l_tmp_str;
                o_date(l_counter) := rec.dt_tmp2;
                o_pro(l_counter) := l_prof_id;
                o_cancel_reason(l_counter) := NULL; --CR
                o_cancel_r(l_counter) := NULL; --R
            
                IF l_counter = 1
                THEN
                    o_status(l_counter) := l_created_str;
                ELSE
                    o_status(l_counter) := l_edited_str;
                END IF;
            
                l_counter := l_counter + 1;
            
            END IF;
        
            l_comp_prev    := l_comp;
            l_ipah_prev    := l_ipah_max;
            l_diag_prv_str := l_diag_r_str;
            l_app_str      := '';
        
        END LOOP;
    
        IF l_id_cancel IS NOT NULL
        THEN
        
            OPEN c_cancel_r(l_id_cancel);
            FETCH c_cancel_r
                INTO l_cancel_r;
            CLOSE c_cancel_r;
        
            o_diagre.extend;
            o_app.extend;
            o_action.extend;
            o_comp.extend;
            o_date.extend;
            o_pro.extend;
            o_status.extend;
            o_cancel_reason.extend; --CR
            o_cancel_r.extend; --R
            o_diagre(l_counter) := l_diag_r_str;
            o_app(l_counter) := l_app_str;
            o_action(l_counter) := l_focus_str;
            o_comp(l_counter) := l_tmp_str;
            o_date(l_counter) := l_cancel_date;
            o_pro(l_counter) := l_prof_cancel;
            o_status(l_counter) := l_canceled_str;
            o_cancel_reason(l_counter) := l_cancel_reason; --CR
            o_cancel_r(l_counter) := l_cancel_r; --R
        
            o_flg_cancel := 'Y';
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_icnp_interv_hist;

    /********************************************************************************************
    * Create diagnosis in configurations area.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_term    Term's list for composition
    * @param      i_term_tx Term's text list
    * @param      i_term_fs Term's focus
    * @param      i_comp    Reavaluated Diagnoses
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/26
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_UTILS.UNDO_CHANGES                <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION create_icnp_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_term    IN table_number,
        i_term_tx IN table_varchar,
        i_term_fs IN icnp_composition_term.id_term%TYPE,
        i_comp    IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_new_comp          icnp_composition.id_composition%TYPE;
        l_new_comp_hist     icnp_composition_hist.id_composition_hist%TYPE;
        l_new_pred_act_hist icnp_predefined_action.id_predefined_action%TYPE;
        l_comp_desc         VARCHAR2(4000);
        l_term_desc         VARCHAR2(200);
        l_func_name         VARCHAR2(50) := 'CREATE_ICNP_DIAG';
        l_icnp_exception EXCEPTION;
    
    BEGIN
    
        --terms list is mandatory
        IF (i_term IS NULL OR i_term.count = 0)
        THEN
            RAISE l_icnp_exception;
        END IF;
    
        --get current date time
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET NEW ID_COMPOSITION';
        --new id_composition; id_predefined_action, id_composition_hist; id_predefined_action_hist;
        SELECT seq_icnp_composition.nextval, seq_icnp_composition_hist.nextval, seq_icnp_predef_action_hist.nextval
          INTO l_new_comp, l_new_comp_hist, l_new_pred_act_hist
          FROM dual;
    
        g_error := 'INSERT COMPOSITION';
        --insert <icnp_composition> record
        INSERT INTO icnp_composition
            (id_composition,
             code_icnp_composition,
             flg_type,
             flg_nurse_tea,
             flg_repeat,
             flg_gender,
             flg_available,
             adw_last_update,
             id_institution,
             id_software)
        VALUES
            (l_new_comp,
             'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || l_new_comp,
             pk_icnp_constant.g_composition_type_diagnosis,
             pk_alert_constant.g_no,
             pk_alert_constant.g_no,
             pk_icnp_constant.g_composition_gender_both,
             pk_alert_constant.g_available,
             g_sysdate,
             i_prof.institution,
             i_prof.software);
    
        g_error := 'INSERT COMPOSITION TERMS';
        --Get all terms for insert <icnp_composition_term>
        FOR i IN 1 .. i_term.count
        LOOP
            INSERT INTO icnp_composition_term
                (id_composition_term, id_term, id_composition, desc_term, rank, flg_main_focus, id_language)
            VALUES
                (seq_icnp_composition_term.nextval,
                 i_term(i),
                 l_new_comp,
                 i_term_tx(i),
                 i,
                 decode(i_term(i), i_term_fs, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                 i_lang);
        
            IF i_term_tx(i) IS NULL
            THEN
                l_term_desc := ' ';
            ELSE
                l_term_desc := ' ' || i_term_tx(i) || ' ';
            END IF;
            l_comp_desc := l_comp_desc ||
                           pk_translation.get_translation(i_lang      => i_lang,
                                                          i_code_mess => 'ICNP_TERM.CODE_TERM.' || i_term(i)) ||
                           l_term_desc;
        
        END LOOP;
    
        l_comp_desc := TRIM(l_comp_desc);
    
        g_error := 'INSERT PREDEFINED ACTION';
        --insert <icnp_predefined_action> records of revaluated diagnoses
        FORALL i IN 1 .. i_comp.count
            INSERT INTO icnp_predefined_action
                (id_predefined_action,
                 id_composition_parent,
                 id_composition,
                 id_institution,
                 flg_available,
                 id_software)
            VALUES
                (seq_icnp_predefined_action.nextval,
                 l_new_comp,
                 i_comp(i),
                 i_prof.institution,
                 pk_alert_constant.g_yes,
                 i_prof.software);
    
        g_error := 'INSERT TRANSLATION';
        --insert <translation> record
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => 'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || l_new_comp,
                                               i_desc_trans => l_comp_desc);
    
        g_error := 'INSERT COMPOSITION HIST';
        --insert <icnp_composition_hist> record
        INSERT INTO icnp_composition_hist
            (id_composition_hist, id_composition, flg_most_recent, dt_composition_hist, id_professional, flg_cancel)
        VALUES
            (l_new_comp_hist, l_new_comp, pk_alert_constant.g_yes, g_sysdate_tstz, i_prof.id, pk_alert_constant.g_no);
    
        g_error := 'INSERT PREDEFINED ACTION HIST';
        --insert <icnp_predefined_action_hist> record
        INSERT INTO icnp_predefined_action_hist
            (id_predefined_action_hist,
             id_predefined_action,
             flg_most_recent,
             dt_predefined_action_hist,
             id_professional)
            (SELECT l_new_pred_act_hist, id_predefined_action, pk_alert_constant.g_yes, g_sysdate_tstz, i_prof.id
               FROM icnp_predefined_action
              WHERE id_composition_parent = l_new_comp);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_icnp_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END create_icnp_diag;

    /********************************************************************************************
    * Auxiliar function to insert diagnosis in configurations area.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_new_cmp New composition ID
    * @param      i_prv_cmp Previous composition ID
    * @param      i_desc    Previous composition ID
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/03/02
    * @dependents            <PACKAGE_NAME>.<FUNCTION_NAME>    <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION prv_update_icnp_compo
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_new_comp      IN icnp_composition.id_composition%TYPE,
        i_old_comp_hist IN icnp_composition.id_composition%TYPE,
        i_prv_cmp       IN icnp_composition.id_composition%TYPE,
        i_timezone      IN timezone_region.timezone_region%TYPE,
        i_comp_desc     IN VARCHAR2,
        i_apli          IN icnp_application_area.id_application_area%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        err_id          PLS_INTEGER;
        l_apli          icnp_application_area.id_application_area%TYPE;
        l_doc_template  icnp_composition.id_doc_template%TYPE;
        l_old_comp_hist icnp_composition.id_composition%TYPE;
    
    BEGIN
    
        --get hist id for update
        IF i_old_comp_hist IS NULL
        THEN
            SELECT DISTINCT id_composition_hist
              INTO l_old_comp_hist
              FROM icnp_composition_hist ich
             WHERE ich.id_composition = i_prv_cmp;
        ELSE
            l_old_comp_hist := i_old_comp_hist;
        END IF;
    
        --assign null when apllication area value is -1
        IF i_apli IS NOT NULL
           AND i_apli < 0
        THEN
            l_apli         := NULL;
            l_doc_template := i_apli * -1;
        ELSE
            l_apli := i_apli;
        END IF;
    
        g_error := 'INSERT COMPOSITION';
        --insert <icnp_composition> record
        INSERT INTO icnp_composition
            (id_composition,
             code_icnp_composition,
             flg_type,
             flg_nurse_tea,
             flg_repeat,
             flg_gender,
             flg_available,
             adw_last_update,
             id_vs,
             id_doc_template,
             flg_task,
             flg_solved,
             id_application_area,
             id_institution,
             id_software)
            (SELECT i_new_comp,
                    'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || i_new_comp,
                    flg_type,
                    flg_nurse_tea,
                    flg_repeat,
                    flg_gender,
                    flg_available,
                    SYSDATE,
                    id_vs,
                    l_doc_template,
                    flg_task,
                    flg_solved,
                    l_apli,
                    i_prof.institution,
                    i_prof.software
               FROM icnp_composition
              WHERE id_composition = i_prv_cmp);
    
        g_error := 'INSERT_UPDATE COMPOSITION HIST';
        --update <icnp_composition_hist> old record
        UPDATE icnp_composition_hist
           SET flg_most_recent = pk_alert_constant.g_no
         WHERE id_composition_hist = l_old_comp_hist;
        --insert <icnp_composition_hist> record
        INSERT INTO icnp_composition_hist
            (id_composition_hist, id_composition, flg_most_recent, dt_composition_hist, id_professional, flg_cancel)
        VALUES
            (l_old_comp_hist, i_new_comp, pk_alert_constant.g_yes, i_timezone, i_prof.id, pk_alert_constant.g_no);
    
        --BEGIN THERAPEUTIC ATTITUDES   
        INSERT INTO icnp_task_composition
            (id_task, id_task_type, id_composition, flg_available, id_content)
            (SELECT itc.id_task, itc.id_task_type, i_new_comp, itc.flg_available, itc.id_content
               FROM icnp_task_composition itc
              WHERE itc.id_composition = i_prv_cmp);
    
        INSERT INTO icnp_task_comp_soft_inst
            (id_task, id_task_type, id_composition, id_software, id_institution, flg_available)
            (SELECT itcsi.id_task,
                    itcsi.id_task_type,
                    i_new_comp,
                    itcsi.id_software,
                    itcsi.id_institution,
                    itcsi.flg_available
               FROM icnp_task_comp_soft_inst itcsi
              WHERE itcsi.id_composition = i_prv_cmp);
    
        UPDATE icnp_task_comp_soft_inst itcsi
           SET itcsi.flg_available = pk_alert_constant.g_no
         WHERE itcsi.id_composition = i_prv_cmp;
        --END THERAPEUTIC ATTITUDES  
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.register_error(error_code_in       => SQLCODE,
                                               err_instance_id_out => err_id,
                                               name1_in            => 'OWNER',
                                               value1_in           => 'ALERT',
                                               name2_in            => 'PACKAGE',
                                               value2_in           => 'PK_ICNP',
                                               name3_in            => 'PROCEDURE',
                                               value3_in           => 'PRV_UPDATE_ICNP_COMPO');
            RETURN FALSE;
    END prv_update_icnp_compo;

    /********************************************************************************************
    * Update diagnosis in configurations area.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_term    Term's list for composition
    * @param      i_term_tx Term's text list
    * @param      i_term_fs Term's focus
    * @param      i_prv_cmp Previous composition ID
    * @param      i_comp    Reavaluated Diagnoses
    * @param      i_flg_cmp Y-Terms composition changed; N- No changes for compositions
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/26
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_UTILS.UNDO_CHANGES                <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION update_icnp_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_term    IN table_number,
        i_term_tx IN table_varchar,
        i_term_fs IN icnp_composition_term.id_term%TYPE,
        i_prv_cmp IN icnp_composition.id_composition%TYPE,
        i_prv_cht IN icnp_composition_hist.id_composition_hist%TYPE,
        i_comp    IN table_number,
        i_flg_cmp IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_new_comp          icnp_composition.id_composition%TYPE;
        l_prv_comp          icnp_composition.id_composition%TYPE;
        l_old_comp_hist     icnp_composition_hist.id_composition_hist%TYPE;
        l_old_pre_act_hist  icnp_predefined_action_hist.id_predefined_action_hist%TYPE;
        l_new_pred_act_hist icnp_predefined_action.id_predefined_action%TYPE;
        l_timezone          timezone_region.timezone_region%TYPE;
        l_comp_desc         VARCHAR2(4000);
        l_term_desc         VARCHAR2(200);
        c_temp              pk_types.cursor_type;
        --c_diag              pk_types.cursor_type;
        l_func_name VARCHAR2(50) := 'UPDATE_ICNP_DIAG';
        l_icnp_exception EXCEPTION;
    
        l_tab  t_tbl_upd_icnp := t_tbl_upd_icnp();
        l_rec  t_rec_upd_icnp := t_rec_upd_icnp(NULL, NULL, NULL, NULL);
        l_seq  icnp_predefined_action.id_predefined_action%TYPE;
        l_rec2 t_rec_upd_icnp := t_rec_upd_icnp(NULL, NULL, NULL, NULL);
        l_max  icnp_composition_hist.id_composition_hist%TYPE;
    
    BEGIN
    
        --get current date time
        IF NOT
            pk_date_utils.get_timezone(i_lang => i_lang, i_prof => i_prof, o_timezone => l_timezone, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --get current date time
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET NEW ID_COMPOSITION';
        --new id_composition; id_predefined_action, id_composition_hist; id_predefined_action_hist;
        SELECT seq_icnp_composition.nextval, seq_icnp_predef_action_hist.nextval
          INTO l_new_comp, l_new_pred_act_hist
          FROM dual;
    
        l_old_comp_hist := i_prv_cht;
    
        --update id_software and id_institution
        UPDATE icnp_composition ic
           SET ic.id_software = i_prof.software, ic.id_institution = i_prof.institution
         WHERE ic.id_composition = i_prv_cmp;
    
        --insert data if composition has changed
        IF i_flg_cmp = pk_alert_constant.g_yes
        THEN
            g_error := 'INSERT COMPOSITION';
            --INSERT COMPOSITION
            IF NOT prv_update_icnp_compo(i_lang,
                                         i_prof,
                                         l_new_comp,
                                         l_old_comp_hist,
                                         i_prv_cmp,
                                         g_sysdate_tstz,
                                         l_comp_desc,
                                         NULL,
                                         o_error)
            THEN
                RAISE l_icnp_exception;
            END IF;
        
            g_error := 'INSERT COMPOSITION TERMS';
            --Get all terms for insert <icnp_composition_term>
            FOR i IN 1 .. i_term.count
            LOOP
                INSERT INTO icnp_composition_term
                    (id_composition_term, id_term, id_composition, desc_term, rank, flg_main_focus, id_language)
                VALUES
                    (seq_icnp_composition_term.nextval,
                     i_term(i),
                     l_new_comp,
                     i_term_tx(i),
                     i,
                     decode(i_term(i), i_term_fs, 'Y', 'N'),
                     i_lang);
                IF i_term_tx(i) IS NULL
                THEN
                    l_term_desc := ' ';
                ELSE
                    l_term_desc := ' ' || i_term_tx(i) || ' ';
                END IF;
            
                l_comp_desc := l_comp_desc ||
                               pk_translation.get_translation(i_lang      => i_lang,
                                                              i_code_mess => 'ICNP_TERM.CODE_TERM.' || i_term(i)) ||
                               l_term_desc;
            END LOOP;
        
            l_comp_desc := TRIM(l_comp_desc);
        
            g_error := 'INSERT TRANSLATION';
            --insert <translation> record
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => 'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' ||
                                                                   l_new_comp,
                                                   i_desc_trans => l_comp_desc);
        
            l_prv_comp := l_new_comp;
        ELSE
            l_new_comp := i_prv_cmp;
            l_prv_comp := -1;
        END IF;
    
        FOR i IN 1 .. i_comp.count
        LOOP
            l_rec.num1 := i_comp(i);
            l_rec.num3 := 0;
        
            IF i_comp(i) IS NOT NULL
            THEN
                SELECT MAX(id_composition_hist)
                  INTO l_max
                  FROM icnp_composition_hist
                 WHERE id_composition = i_comp(i);
                IF l_max IS NOT NULL
                THEN
                    l_rec.num6 := l_max;
                END IF;
            END IF;
        
            l_tab.extend();
            l_tab(l_tab.count) := l_rec;
        END LOOP;
    
        --get all most_recent related compositions
        FOR c_temp IN (SELECT ipah.id_predefined_action_hist,
                              ipa.id_predefined_action,
                              ic.id_composition,
                              ic.flg_type,
                              ipah.flg_most_recent,
                              ipah.dt_predefined_action_hist,
                              ipah.id_professional,
                              ipah.id_cancel_reason,
                              ich.id_composition_hist
                         FROM icnp_predefined_action      ipa,
                              icnp_predefined_action_hist ipah,
                              icnp_composition            ic,
                              icnp_composition_hist       ich
                        WHERE ipa.id_composition_parent IN
                              (SELECT id_composition
                                 FROM icnp_composition_hist
                                WHERE id_composition_hist = l_old_comp_hist
                                  AND id_composition != l_prv_comp)
                          AND ipa.id_predefined_action = ipah.id_predefined_action
                          AND ipa.id_composition = ic.id_composition
                          AND ipa.id_institution IN (pk_icnp_constant.g_institution_all, i_prof.institution)
                          AND ic.flg_type = pk_icnp_constant.g_composition_type_diagnosis
                          AND ich.id_composition = ic.id_composition
                          AND ipah.flg_most_recent = pk_alert_constant.g_yes
                          AND ich.id_composition != l_prv_comp
                        ORDER BY 1 DESC)
        LOOP
        
            l_old_pre_act_hist := c_temp.id_predefined_action_hist;
        
            --if it is intervention even if relation is canceled
            IF c_temp.flg_type = pk_icnp_constant.g_composition_type_action
            THEN
                --if it is intervention insert TBL_TEMP with relation ID
                g_error     := 'INSERT TBL_TEMP FOR INTERV';
                l_rec2.num1 := c_temp.id_composition;
                l_rec2.num2 := c_temp.id_predefined_action;
                l_rec2.num3 := 1;
            
                l_tab.extend();
                l_tab(l_tab.count) := l_rec2;
            
            ELSE
                --if it is diagsnosis update TBL_TEMP with relation ID
                g_error := 'UPDATE TBL_TEMP FOR DIAG';
            
                FOR i IN 1 .. l_tab.count
                LOOP
                    l_rec := l_tab(i);
                    IF l_rec.num6 = c_temp.id_composition_hist
                    THEN
                        l_rec2.num2 := c_temp.id_predefined_action;
                        l_rec2.num3 := 0;
                    END IF;
                END LOOP;
            
            END IF;
        
        END LOOP;
    
        g_error := 'OPEN TBL_TEMP';
        --Loop related diagnosis list at TBL_TEMP
    
        FOR i IN 1 .. l_tab.count
        LOOP
            l_rec := l_tab(i);
            IF l_rec.num2 IS NULL
            THEN
                SELECT seq_icnp_predefined_action.nextval
                  INTO l_seq
                  FROM dual;
            ELSE
                l_seq := l_rec.num2;
            END IF;
        
            --NEW RELATED DIAG
            IF l_rec.num2 IS NULL
            THEN
                g_error := 'INSERT PREDEFINED ACTION';
                --insert <icnp_predefined_action> records of previous links
                INSERT INTO icnp_predefined_action
                    (id_predefined_action,
                     id_composition_parent,
                     id_composition,
                     id_institution,
                     flg_available,
                     id_software,
                     adw_last_update)
                VALUES
                    (l_seq,
                     l_new_comp,
                     l_rec.num1,
                     i_prof.institution,
                     pk_alert_constant.g_yes,
                     i_prof.software,
                     SYSDATE);
            
                g_error := 'INSERT PREDEFINED ACTION HIST';
                --insert <icnp_predefined_action> records of previous links
                INSERT INTO icnp_predefined_action_hist
                    (id_predefined_action_hist,
                     id_predefined_action,
                     flg_most_recent,
                     dt_predefined_action_hist,
                     id_professional)
                VALUES
                    (l_new_pred_act_hist, l_seq, pk_alert_constant.g_yes, g_sysdate_tstz, i_prof.id);
            
            END IF;
        
        END LOOP;
    
        g_error := 'UPDATE PREDEFINED ACTION HIST / id_predefined_action_hist=' || l_old_pre_act_hist;
        --insert <icnp_predefined_action> records of previous links
        UPDATE icnp_predefined_action_hist ipah
           SET ipah.flg_most_recent = pk_alert_constant.g_no
         WHERE ipah.id_predefined_action_hist = l_old_pre_act_hist
           AND ipah.flg_most_recent = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_icnp_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END update_icnp_diag;

    /********************************************************************************************
    * Cancel diagnosis in configurations area.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_comp    Diagnose ID
    * @param      i_reason  Cancel Reason ID
    * @param      i_rsn_nts Reason Notes
    * @param      i_flg_warn N-Cancel related interventions; Y- No changes related interventions
    * @param      o_list    List of interventions related with other diagnosis
    * @param      o_id_list List of interventions IDs related with other diagnosis
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/04/06
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_UTILS.UNDO_CHANGES                <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION cancel_icnp_diag
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_comp     IN icnp_composition.id_composition%TYPE,
        i_reason   IN icnp_composition_hist.id_cancel_reason%TYPE,
        i_rsn_nts  IN icnp_composition_hist.reason_notes%TYPE,
        i_flg_warn IN VARCHAR2,
        o_list     OUT table_varchar,
        o_id_list  OUT table_number,
        o_flag     OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count        PLS_INTEGER;
        l_flag         PLS_INTEGER;
        l_i            PLS_INTEGER;
        l_x            PLS_INTEGER;
        l_func_name    VARCHAR2(50) := 'CANCEL_ICNP_DIAG';
        l_id_compo_prt icnp_composition_hist.id_composition_hist%TYPE;
        l_id_list_hist table_number;
        l_id_ipah      table_number;
        l_id_ipa       table_number;
    
        CURSOR c_interv(id_compo_prt IN icnp_composition_hist.id_composition_hist%TYPE) IS
            SELECT ipa.id_composition AS id_composition,
                   pk_translation.get_translation(i_lang, ic.code_icnp_composition) AS short_desc,
                   ich.id_composition_hist AS id_composition_hist
              FROM icnp_predefined_action      ipa,
                   icnp_predefined_action_hist ipah,
                   icnp_composition            ic,
                   icnp_composition_hist       ich
             WHERE ipa.id_predefined_action = ipah.id_predefined_action
               AND ipa.id_composition = ic.id_composition
               AND ic.id_composition = ich.id_composition
                  --AND ich.flg_most_recent = pk_alert_constant.g_yes
               AND ipah.flg_cancel != pk_alert_constant.g_yes
               AND ich.flg_most_recent = pk_alert_constant.g_yes
               AND ich.flg_cancel = pk_alert_constant.g_no
               AND ipah.flg_most_recent = pk_alert_constant.g_yes
               AND ic.flg_type = pk_icnp_constant.g_composition_type_action
               AND ipa.id_composition_parent IN
                   (SELECT id_composition
                      FROM icnp_composition_hist
                     WHERE id_composition_hist = id_compo_prt);
    
        CURSOR c_occurence
        (
            id_interv  IN icnp_composition_hist.id_composition_hist%TYPE,
            l_id_compo IN icnp_composition_hist.id_composition_hist%TYPE
        ) IS
            SELECT COUNT(*) AS xcounter
              FROM icnp_predefined_action ipa, icnp_predefined_action_hist ipah, icnp_composition_hist ich
             WHERE ipa.id_predefined_action = ipah.id_predefined_action
               AND ipa.id_composition = ich.id_composition
               AND ipah.flg_most_recent = pk_alert_constant.g_yes
               AND ipa.id_composition IN (SELECT id_composition
                                            FROM icnp_composition_hist
                                           WHERE id_composition_hist = id_interv)
               AND ipa.id_institution = pk_icnp_constant.g_institution_all
                  --AND ipa.id_software = 0
               AND ipa.id_composition_parent NOT IN
                   (SELECT id_composition
                      FROM icnp_composition_hist
                     WHERE id_composition_hist = l_id_compo)
               AND ich.flg_most_recent = pk_alert_constant.g_yes
               AND ich.flg_cancel = pk_alert_constant.g_no;
    
        CURSOR c_no_exclusive
        (
            id_interv  IN icnp_composition_hist.id_composition_hist%TYPE,
            l_id_compo IN icnp_composition_hist.id_composition_hist%TYPE
        ) IS
            SELECT ipah.id_predefined_action_hist, ipah.id_predefined_action
              FROM icnp_predefined_action ipa, icnp_predefined_action_hist ipah, icnp_composition_hist ich
             WHERE ipa.id_predefined_action = ipah.id_predefined_action
               AND ipa.id_composition = ich.id_composition
               AND ipah.flg_most_recent = pk_alert_constant.g_yes
               AND ipa.id_composition IN (SELECT id_composition
                                            FROM icnp_composition_hist
                                           WHERE id_composition_hist = id_interv)
               AND ipa.id_institution = pk_icnp_constant.g_institution_all
                  --AND ipa.id_software = 0
               AND ipa.id_composition_parent IN (SELECT id_composition
                                                   FROM icnp_composition_hist
                                                  WHERE id_composition_hist = l_id_compo)
               AND ich.flg_most_recent = pk_alert_constant.g_yes
               AND ich.flg_cancel = pk_alert_constant.g_no;
    
    BEGIN
    
        l_flag         := 0;
        l_i            := 1;
        l_x            := 1;
        o_list         := table_varchar();
        o_id_list      := table_number();
        l_id_list_hist := table_number();
        l_id_ipah      := table_number();
        l_id_ipa       := table_number();
    
        --get current date time
        g_sysdate_tstz := current_timestamp;
    
        SELECT MAX(id_composition_hist)
          INTO l_id_compo_prt
          FROM icnp_composition_hist
         WHERE id_composition = i_comp;
    
        --get all related interventions with this diagnosis
        FOR rec IN c_interv(l_id_compo_prt)
        LOOP
            OPEN c_occurence(rec.id_composition_hist, l_id_compo_prt);
            FETCH c_occurence
                INTO l_count;
            IF l_count = 0
            THEN
                l_flag := 1;
                o_id_list.extend;
                o_list.extend;
                l_id_list_hist.extend;
                o_id_list(l_i) := rec.id_composition;
                o_list(l_i) := coalesce(rec.short_desc, get_compo_desc(i_lang, rec.id_composition));
                l_id_list_hist(l_i) := rec.id_composition_hist;
                l_i := l_i + 1;
            END IF;
            CLOSE c_occurence;
        
            --no_exclusive
            FOR x IN c_no_exclusive(rec.id_composition_hist, l_id_compo_prt)
            LOOP
                l_id_ipah.extend;
                l_id_ipa.extend;
                l_id_ipah(l_x) := x.id_predefined_action_hist;
                l_id_ipa(l_x) := x.id_predefined_action;
                l_x := l_x + 1;
            END LOOP;
        
        END LOOP;
    
        IF i_flg_warn = pk_alert_constant.g_no
        THEN
            g_error := 'UPDATE COMPOSITION HIST';
            --update <icnp_composition_hist> record
            FORALL x IN 1 .. o_id_list.count
                UPDATE icnp_composition_hist ich
                   SET ich.id_cancel_reason = i_reason,
                       --ich.reason_notes=i_rsn_nts,
                       ich.id_prof_cancel = i_prof.id,
                       ich.dt_cancel      = g_sysdate_tstz,
                       ich.flg_cancel     = pk_alert_constant.g_yes
                 WHERE ich.id_composition_hist = l_id_list_hist(x)
                   AND ich.flg_most_recent = pk_alert_constant.g_yes;
            --WHERE ich.id_composition = o_id_list(x);
        
            g_error := 'UPDATE PREDEFINED ACTION HIST';
            --update <icnp_predefined_action_hist> record
            FORALL x IN 1 .. l_id_ipah.count
                UPDATE icnp_predefined_action_hist ipah
                   SET ipah.id_cancel_reason = i_reason,
                       ipah.id_prof_cancel   = i_prof.id,
                       ipah.dt_cancel        = g_sysdate_tstz,
                       ipah.flg_cancel       = pk_alert_constant.g_yes
                 WHERE ipah.id_predefined_action_hist = l_id_ipah(x)
                   AND ipah.id_predefined_action = l_id_ipa(x);
        
            g_error := 'UPDATE COMPOSITION HIST';
            --update <icnp_composition_hist> record
            UPDATE icnp_composition_hist ich
               SET ich.id_cancel_reason = i_reason,
                   ich.reason_notes     = i_rsn_nts,
                   ich.id_prof_cancel   = i_prof.id,
                   ich.dt_cancel        = g_sysdate_tstz,
                   ich.flg_cancel       = pk_alert_constant.g_yes
             WHERE ich.id_composition = i_comp;
        END IF;
    
        UPDATE icnp_composition_hist ich
           SET ich.id_cancel_reason = i_reason,
               ich.reason_notes     = i_rsn_nts,
               ich.id_prof_cancel   = i_prof.id,
               ich.dt_cancel        = g_sysdate_tstz,
               ich.flg_cancel       = pk_alert_constant.g_yes
         WHERE ich.id_composition = i_comp
           AND ich.flg_most_recent = pk_alert_constant.g_yes;
    
        g_error := 'UPDATE PREDEFINED ACTION HIST';
        --update <icnp_predefined_action_hist> record
        UPDATE icnp_predefined_action_hist ipah
           SET ipah.id_cancel_reason = i_reason,
               ipah.id_prof_cancel   = i_prof.id,
               ipah.dt_cancel        = g_sysdate_tstz,
               ipah.flg_cancel       = pk_alert_constant.g_yes
         WHERE ipah.id_predefined_action IN (SELECT id_predefined_action
                                               FROM icnp_predefined_action
                                              WHERE id_composition = i_comp)
           AND ipah.flg_most_recent = pk_alert_constant.g_yes;
    
        o_flag := to_char(l_flag);
    
        g_error := 'RETURN';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END cancel_icnp_diag;

    /********************************************************************************************
    * Cancel intervention in configurations area.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_diag    Diagnose ID
    * @param      i_interv  Intervention ID
    * @param      i_reason  Cancel Reason ID
    * @param      i_rsn_nts Reason Notes
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/26
    * @dependents            PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_UTILS.UNDO_CHANGES                <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION cancel_icnp_interv
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_diag    IN icnp_composition.id_composition%TYPE,
        i_interv  IN icnp_composition.id_composition%TYPE,
        i_reason  IN icnp_composition_hist.id_cancel_reason%TYPE,
        i_rsn_nts IN icnp_composition_hist.reason_notes%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name                 VARCHAR2(50) := 'CANCEL_ICNP_INTERV';
        l_diag_hist                 icnp_composition_hist.id_composition_hist%TYPE;
        l_interv_hist               icnp_composition_hist.id_composition_hist%TYPE;
        l_count                     NUMBER;
        l_id_predefined_action_hist table_number;
        l_id_predefined_action      table_number;
        l_dt_cancel                 icnp_composition_hist.dt_cancel%TYPE := g_sysdate_tstz;
    
        CURSOR c_occurence
        (
            l_diag   icnp_composition_hist.id_composition_hist%TYPE,
            l_interv icnp_composition_hist.id_composition_hist%TYPE
        ) IS
            SELECT DISTINCT ipah.id_predefined_action_hist, ipah.id_predefined_action
              FROM icnp_predefined_action ipa, icnp_predefined_action_hist ipah, icnp_composition_hist ich
             WHERE ipa.id_predefined_action = ipah.id_predefined_action
               AND ipa.id_composition = ich.id_composition
               AND ipah.flg_most_recent = pk_alert_constant.g_yes
               AND ipa.id_composition IN (SELECT id_composition
                                            FROM icnp_composition_hist
                                           WHERE id_composition_hist = l_interv)
               AND ipa.id_institution = nvl(i_prof.institution, pk_icnp_constant.g_institution_all)
                  --AND ipa.id_software = 0
               AND ipa.id_composition_parent IN (SELECT id_composition
                                                   FROM icnp_composition_hist
                                                  WHERE id_composition_hist = l_diag)
               AND ich.flg_most_recent = pk_alert_constant.g_yes
               AND ich.flg_cancel = pk_alert_constant.g_no
               AND ipah.flg_cancel = pk_alert_constant.g_no;
    
    BEGIN
    
        g_error := 'GET HIST IDS';
        --get_diag_hist and interv_hist
        SELECT MAX(ich1), MAX(ich2)
          INTO l_diag_hist, l_interv_hist
          FROM (SELECT id_composition_hist ich1, 0 ich2
                  FROM icnp_composition_hist
                 WHERE id_composition = i_diag
                UNION ALL
                SELECT 0 ich1, id_composition_hist ich2
                  FROM icnp_composition_hist
                 WHERE id_composition = i_interv);
    
        --get current date time
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_occurence(l_diag_hist, l_interv_hist);
        FETCH c_occurence BULK COLLECT
            INTO l_id_predefined_action_hist, l_id_predefined_action;
    
        g_error := 'UPDATE PREDEFINED_ACTION_HIST';
        --update links to connected diagosis
        FORALL i IN 1 .. l_id_predefined_action_hist.count
            UPDATE icnp_predefined_action_hist ipah
               SET ipah.id_cancel_reason = i_reason,
                   ipah.reason_notes     = i_rsn_nts,
                   ipah.id_prof_cancel   = i_prof.id,
                   ipah.dt_cancel        = l_dt_cancel,
                   ipah.flg_cancel       = pk_alert_constant.g_yes
             WHERE ipah.id_predefined_action_hist = l_id_predefined_action_hist(i)
               AND ipah.id_predefined_action = l_id_predefined_action(i);
    
        SELECT COUNT(*)
          INTO l_count
          FROM icnp_predefined_action ipa
          JOIN icnp_predefined_action_hist ipah
            ON ipah.id_predefined_action = ipa.id_predefined_action
         WHERE ipa.id_composition = i_interv
           AND ipah.flg_most_recent = pk_alert_constant.g_yes
           AND ipah.id_cancel_reason IS NULL;
    
        IF l_count = 0
        THEN
            g_error := 'UPDATE COMPOSITION HIST';
            --update intervention at <icnp_composition_hist> record
            UPDATE icnp_composition_hist ich
               SET ich.id_cancel_reason = i_reason,
                   ich.reason_notes     = i_rsn_nts,
                   ich.id_prof_cancel   = i_prof.id,
                   ich.dt_cancel        = g_sysdate_tstz,
                   ich.flg_cancel       = pk_alert_constant.g_yes
             WHERE ich.id_composition = i_interv;
        END IF;
    
        g_error := 'RETURN';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END cancel_icnp_interv;

    /********************************************************************************************
    * Create new intervention.
    *
    * @param      i_lang     Preferred language ID for this professional
    * @param      i_prof     Object (professional ID, institution ID, software ID)
    * @param      i_term     Term's list for composition
    * @param      i_term_tx  Term's text list
    * @param      i_term_fs  Term's action focus
    * @param      i_comp     Related Diagnoses (ID_COMPOSITION)
    * @param      i_comp_hst Related Diagnoses (ID_COMPOSITION_HIST)
    * @param      i_apli     Application area ID (area->parameter)
    * @param      o_error    Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/04/06
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_UTILS.UNDO_CHANGES                <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION create_icnp_interv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_term          IN table_number,
        i_term_tx       IN table_varchar,
        i_term_fs       IN icnp_composition_term.id_term%TYPE,
        i_comp          IN table_number,
        i_comp_hst      IN table_number,
        i_apli          IN icnp_application_area.id_application_area%TYPE,
        i_flg_most_freq IN table_varchar,
        i_soft          IN table_number,
        i_inst          IN table_table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_new_comp          icnp_composition.id_composition%TYPE;
        l_new_comp_hist     icnp_composition_hist.id_composition_hist%TYPE;
        l_new_pred_act_hist icnp_predefined_action.id_predefined_action%TYPE;
        l_comp_desc         VARCHAR2(4000);
        l_term_desc         VARCHAR2(200);
        l_func_name         VARCHAR2(50) := 'CREATE_ICNP_INTERV';
        l_term_aux          VARCHAR2(200);
        l_apli              icnp_application_area.id_application_area%TYPE;
        l_doc_template      icnp_composition.id_doc_template%TYPE;
    
    BEGIN
    
        --assign null when apllication area value is -1
        IF i_apli IS NOT NULL
           AND i_apli < 0
        THEN
            l_apli         := NULL;
            l_doc_template := i_apli * -1;
        ELSE
            l_apli := i_apli;
        END IF;
    
        --get current date time
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET NEW ID_COMPOSITION';
        --Get new sequences for id_composition, id_predefined_action, id_composition_hist; id_predefined_action_hist;
        SELECT seq_icnp_composition.nextval, seq_icnp_composition_hist.nextval, seq_icnp_predef_action_hist.nextval
          INTO l_new_comp, l_new_comp_hist, l_new_pred_act_hist
          FROM dual;
    
        g_error := 'INSERT COMPOSITION';
        --insert <icnp_composition> record
        INSERT INTO icnp_composition
            (id_composition,
             code_icnp_composition,
             flg_type,
             flg_nurse_tea,
             flg_repeat,
             flg_gender,
             flg_available,
             id_application_area,
             id_doc_template,
             adw_last_update,
             id_institution,
             id_software)
        VALUES
            (l_new_comp,
             'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || l_new_comp,
             pk_icnp_constant.g_composition_type_action,
             pk_alert_constant.g_no,
             pk_alert_constant.g_no,
             pk_icnp_constant.g_composition_gender_both,
             pk_alert_constant.g_available,
             l_apli,
             l_doc_template,
             g_sysdate,
             i_prof.institution,
             i_prof.software);
    
        g_error := 'INSERT COMPOSITION TERMS';
        --Get all terms for insert <icnp_composition_term>
        FOR i IN i_term.first .. i_term.last
        LOOP
            IF i_term_tx.count < i
               OR i_term_tx(i) IS NULL
            THEN
                l_term_desc := ' ';
                l_term_aux  := NULL;
            ELSE
                l_term_desc := ' ' || i_term_tx(i) || ' ';
                l_term_aux  := i_term_tx(i);
            END IF;
        
            INSERT INTO icnp_composition_term
                (id_composition_term, id_term, id_composition, desc_term, rank, flg_main_focus, id_language)
            VALUES
                (seq_icnp_composition_term.nextval,
                 i_term(i),
                 l_new_comp,
                 l_term_aux,
                 i,
                 decode(i_term(i), i_term_fs, 'Y', 'N'),
                 i_lang);
        
            l_comp_desc := l_comp_desc ||
                           pk_translation.get_translation(i_lang      => i_lang,
                                                          i_code_mess => 'ICNP_TERM.CODE_TERM.' || i_term(i)) ||
                           l_term_desc;
        
        END LOOP;
    
        l_comp_desc := TRIM(l_comp_desc);
    
        g_error := 'INSERT TRANSLATION';
        --insert <translation> record
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => 'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || l_new_comp,
                                               i_desc_trans => l_comp_desc);
    
        g_error := 'INSERT COMPOSITION HIST';
        --insert <icnp_composition_hist> record
        INSERT INTO icnp_composition_hist
            (id_composition_hist, id_composition, flg_most_recent, dt_composition_hist, flg_cancel, id_professional)
        VALUES
            (l_new_comp_hist, l_new_comp, pk_alert_constant.g_yes, g_sysdate_tstz, pk_alert_constant.g_no, i_prof.id);
    
        g_error := 'INSERT PREDEFINED ACTION';
        --insert <icnp_predefined_action> records of associated diagnoses
        FORALL i IN 1 .. i_comp.count
            INSERT INTO icnp_predefined_action
                (id_predefined_action,
                 id_composition_parent,
                 id_composition,
                 id_institution,
                 flg_available,
                 id_software,
                 flg_most_freq)
            VALUES
                (seq_icnp_predefined_action.nextval,
                 i_comp(i),
                 l_new_comp,
                 i_prof.institution,
                 pk_alert_constant.g_yes,
                 i_prof.software,
                 i_flg_most_freq(i));
    
        g_error := 'INSERT PREDEFINED ACTION HIST';
        --insert <icnp_predefined_action_hist> existing records and new one
        FORALL i IN 1 .. i_comp.count
            INSERT INTO icnp_predefined_action_hist
                (id_predefined_action_hist,
                 id_predefined_action,
                 flg_most_recent,
                 dt_predefined_action_hist,
                 id_professional,
                 flg_cancel,
                 flg_most_freq)
                (SELECT DISTINCT l_new_pred_act_hist,
                                 ipa.id_predefined_action,
                                 pk_alert_constant.g_yes,
                                 g_sysdate_tstz,
                                 i_prof.id,
                                 ipah.flg_cancel,
                                 ipa.flg_most_freq
                   FROM icnp_predefined_action ipa, icnp_predefined_action_hist ipah, icnp_composition_hist ich
                  WHERE ipa.id_composition_parent = ich.id_composition
                    AND ipa.id_predefined_action = ipah.id_predefined_action
                    AND ich.id_composition_hist = i_comp_hst(i)
                    AND ich.flg_cancel = pk_alert_constant.g_no
                    AND ipah.flg_most_recent = pk_alert_constant.g_yes
                 UNION ALL
                 SELECT l_new_pred_act_hist,
                        ipa.id_predefined_action,
                        pk_alert_constant.g_yes,
                        g_sysdate_tstz,
                        i_prof.id,
                        pk_alert_constant.g_no,
                        pk_alert_constant.g_yes
                   FROM icnp_predefined_action ipa
                  WHERE ipa.id_composition_parent = i_comp(i)
                    AND ipa.id_composition = l_new_comp);
    
        g_error := 'UPDATE PREDEFINED ACTION HIST';
        --update <icnp_predefined_action_hist> old record
        FORALL i IN 1 .. i_comp.count
            UPDATE icnp_predefined_action_hist ipah
               SET flg_most_recent = pk_alert_constant.g_no
             WHERE ipah.id_predefined_action IN
                   (SELECT ipa.id_predefined_action
                      FROM icnp_predefined_action ipa, icnp_composition_hist ich
                     WHERE ipa.id_composition_parent = ich.id_composition
                       AND ich.id_composition_hist = i_comp_hst(i)
                       AND id_institution IN (i_prof.institution, pk_icnp_constant.g_institution_all))
               AND flg_most_recent = pk_alert_constant.g_yes
               AND ipah.id_predefined_action_hist <> l_new_pred_act_hist;
    
        g_error  := 'INSERT icnp_default_instructions_msi';
        g_retval := set_icnp_instructions_msi(i_lang  => i_lang,
                                              i_prof  => i_prof,
                                              i_soft  => i_soft,
                                              i_inst  => i_inst,
                                              i_comp  => l_new_comp,
                                              o_error => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END create_icnp_interv;

    /********************************************************************************************
    * Update intervention.
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      i_term      Term's list for composition
    * @param      i_term_tx   Term's text list
    * @param      i_term_fs   Term's action focus
    * @param      i_comp      Related Diagnoses
    * @param      i_prv_cmp   Previous Composition ID
    * @param      i_flg_cmp   Flag that checks if composition was updated (links not included)
    * @param      i_apli      Application area ID (area->parameter)
    * @param      o_error     Error
    *
    * @return                 boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                 Pedro Lopes
    * @version                1
    * @since                  2009/02/19
    * @dependents             PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                         PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                         PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                         PK_UTILS.UNDO_CHANGES                <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION update_icnp_interv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_term          IN table_number,
        i_term_tx       IN table_varchar,
        i_term_fs       IN icnp_composition_term.id_term%TYPE,
        i_comp          IN table_number,
        i_prv_cmp       IN icnp_composition.id_composition%TYPE,
        i_prv_cht       IN icnp_composition_hist.id_composition_hist%TYPE,
        i_flg_cmp       IN VARCHAR2,
        i_apli          IN icnp_application_area.id_application_area%TYPE,
        i_flg_most_freq IN table_varchar,
        i_soft          IN table_number,
        i_inst          IN table_table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_new_comp      icnp_composition.id_composition%TYPE;
        l_old_comp_hist icnp_composition_hist.id_composition_hist%TYPE;
        l_comp_desc     VARCHAR2(4000);
        l_term_desc     VARCHAR2(200);
        l_func_name     VARCHAR2(50) := 'UPDATE_ICNP_INTERV';
        l_flg_chg       BOOLEAN := FALSE;
        --l_num_1         table_number;
        --l_num_4         table_number;
        --l_num_6         table_number;
        l_icnp_exception EXCEPTION;
    
        --CURSOR c_links IS
        --    SELECT num_1, num_4, num_6
        --      FROM tbl_temp
        --     WHERE num_2 = 1
        --       AND num_3 = 1;
    
    BEGIN
    
        --get current date time
        g_sysdate_tstz := current_timestamp;
    
        --get hist id for update
        IF i_prv_cht IS NULL
        
        THEN
            SELECT DISTINCT id_composition_hist
              INTO l_old_comp_hist
              FROM icnp_composition_hist ich
             WHERE ich.id_composition = i_prv_cmp;
        ELSE
            l_old_comp_hist := i_prv_cht;
        END IF;
    
        --insert data if composition has changed (NEW COMPOSITION)
        IF i_flg_cmp = pk_alert_constant.g_yes
        THEN
            g_error := 'GET NEW ID_COMPOSITION';
            --new id_composition;
            SELECT seq_icnp_composition.nextval
              INTO l_new_comp
              FROM dual;
        
            --INSERT COMPOSITION
            IF NOT prv_update_icnp_compo(i_lang,
                                         i_prof,
                                         l_new_comp,
                                         l_old_comp_hist,
                                         i_prv_cmp,
                                         g_sysdate_tstz,
                                         l_comp_desc,
                                         i_apli,
                                         o_error)
            THEN
                RAISE l_icnp_exception;
            END IF;
        
            g_error := 'UPDATE COMPOSITION ID ON ICNP DEFAULT INSTRUCTIONS TABLE';
        
            UPDATE icnp_default_instructions_msi def_instr
               SET def_instr.id_composition = l_new_comp
             WHERE def_instr.id_composition = i_prv_cmp;
        
            g_error := 'INSERT COMPOSITION TERMS';
            --Get all terms for insert <icnp_composition_term>
            FOR i IN 1 .. i_term.count
            LOOP
                INSERT INTO icnp_composition_term
                    (id_composition_term, id_term, id_composition, desc_term, rank, flg_main_focus, id_language)
                VALUES
                    (seq_icnp_composition_term.nextval,
                     i_term(i),
                     l_new_comp,
                     i_term_tx(i),
                     i,
                     decode(i_term(i), i_term_fs, 'Y', 'N'),
                     i_lang);
            
                IF i_term_tx(i) IS NULL
                THEN
                    l_term_desc := ' ';
                ELSE
                    l_term_desc := ' ' || i_term_tx(i) || ' ';
                END IF;
            
                l_comp_desc := l_comp_desc ||
                               pk_translation.get_translation(i_lang      => i_lang,
                                                              i_code_mess => 'ICNP_TERM.CODE_TERM.' || i_term(i)) ||
                               l_term_desc;
            END LOOP;
        
            l_comp_desc := TRIM(l_comp_desc);
        
            g_error := 'INSERT TRANSLATION';
            --insert <translation> record
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => 'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' ||
                                                                   l_new_comp,
                                                   i_desc_trans => l_comp_desc);
        
        ELSE
            l_new_comp := i_prv_cmp;
        END IF;
    
        --delete and insert tbl_temp for parent diagnosis (composition parent/old/new)
        DELETE tbl_temp;
    
        FORALL i IN 1 .. i_comp.count
            INSERT INTO tbl_temp
                (num_1, num_2, num_3, vc_1)
            VALUES
                (i_comp(i), 1, 0, i_flg_most_freq(i));
    
        MERGE INTO tbl_temp tgt
        USING (SELECT ipa.id_composition_parent, 0 AS NEW, 1 AS OLD, ipa.flg_most_freq
                 FROM icnp_predefined_action ipa, icnp_predefined_action_hist ipah
                WHERE ipa.id_predefined_action = ipah.id_predefined_action
                  AND ipa.id_institution IN (pk_icnp_constant.g_institution_all, i_prof.institution)
                  AND ipah.flg_most_recent = pk_alert_constant.g_yes
                  AND ipa.id_composition IN (SELECT id_composition
                                               FROM icnp_composition_hist
                                              WHERE id_composition_hist = l_old_comp_hist
                                                AND flg_most_recent = pk_alert_constant.g_yes)) src
        ON (src.id_composition_parent = tgt.num_1)
        WHEN MATCHED THEN
            UPDATE
               SET tgt.num_3 = 1
        WHEN NOT MATCHED THEN
            INSERT
                (tgt.num_1, tgt.num_2, tgt.num_3, tgt.vc_1)
            VALUES
                (src.id_composition_parent, 0, 1, src.flg_most_freq);
    
        --update tbl_temp with new sequences
        UPDATE tbl_temp
           SET num_5 = seq_icnp_predefined_action.nextval
         WHERE num_2 != num_3
           AND num_1 IS NOT NULL;
    
        --update tbl_temp with new sequences (when equal)
        UPDATE tbl_temp tt
           SET tt.num_4 = seq_icnp_predef_action_hist.nextval,
               tt.num_6 =
               (SELECT MAX(id_composition_hist)
                  FROM icnp_composition_hist
                 WHERE id_composition = tt.num_1)
         WHERE num_1 IS NOT NULL;
    
        g_error := 'INSERT NEW LINKS';
        FOR i IN (SELECT num_1, num_4, num_5, num_6, vc_1
                    FROM tbl_temp
                   WHERE num_2 = 1
                     AND num_3 = 0
                     AND num_1 IS NOT NULL)
        LOOP
            --new links flag
            l_flg_chg := TRUE;
        
            g_error := 'INSERT PREDEFINED ACTION: NEW LINK';
            INSERT INTO icnp_predefined_action
                (id_predefined_action,
                 id_composition_parent,
                 id_composition,
                 id_institution,
                 flg_available,
                 id_software,
                 flg_most_freq)
            VALUES
                (i.num_5, i.num_1, l_new_comp, i_prof.institution, pk_alert_constant.g_yes, i_prof.software, i.vc_1);
        
            g_error := 'INSERT PREDEFINED ACTION HIST: OLD LINKS';
            INSERT INTO icnp_predefined_action_hist
                (id_predefined_action_hist,
                 id_predefined_action,
                 flg_most_recent,
                 dt_predefined_action_hist,
                 id_professional,
                 flg_most_freq)
                (SELECT DISTINCT i.num_4,
                                 ipa.id_predefined_action,
                                 pk_alert_constant.g_no,
                                 g_sysdate_tstz,
                                 i_prof.id,
                                 ipa.flg_most_freq
                   FROM icnp_predefined_action ipa, icnp_predefined_action_hist ipah, icnp_composition_hist ich
                  WHERE ipa.id_composition_parent = ich.id_composition
                    AND ipa.id_predefined_action = ipah.id_predefined_action
                    AND ich.id_composition_hist = i.num_6
                    AND ipa.id_predefined_action <> i.num_5
                    AND ich.flg_cancel = pk_alert_constant.g_no
                    AND ipah.flg_most_recent = pk_alert_constant.g_yes);
        
            g_error := 'INSERT PREDEFINED ACTION HIST: NEW LINK';
            INSERT INTO icnp_predefined_action_hist
                (id_predefined_action_hist,
                 id_predefined_action,
                 flg_most_recent,
                 dt_predefined_action_hist,
                 id_professional,
                 flg_most_freq)
            VALUES
                (i.num_4, i.num_5, pk_alert_constant.g_yes, g_sysdate_tstz, i_prof.id, i.vc_1);
        
            UPDATE icnp_predefined_action_hist ipah
               SET ipah.flg_most_recent = pk_alert_constant.g_no
             WHERE ipah.id_predefined_action IN (SELECT ipa.id_predefined_action
                                                   FROM icnp_predefined_action ipa
                                                  WHERE ipa.id_composition = i_prv_cmp);
        
        END LOOP;
    
        g_error  := 'UPDATE icnp_default_instructions_msi';
        g_retval := set_icnp_instructions_msi(i_lang  => i_lang,
                                              i_prof  => i_prof,
                                              i_soft  => i_soft,
                                              i_inst  => i_inst,
                                              i_comp  => l_new_comp,
                                              o_error => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN l_icnp_exception THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END update_icnp_interv;

    /********************************************************************************************
    * Get diagnosis or interventions with related terms list.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_flag    (D)iagnosis or (A)ction
    * @param      i_term    Term's id list for composition
    * @param      o_desc    Related compositions description list
    * @param      o_comp    Related compositions ID list
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/02/25
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_equal_terms
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_flag  IN VARCHAR2,
        i_term  IN table_number,
        i_comp  IN icnp_composition_hist.id_composition_hist%TYPE DEFAULT NULL,
        o_desc  OUT table_varchar,
        o_comp  OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_str       VARCHAR2(400);
        l_flg       VARCHAR2(4);
        l_sql_str   VARCHAR2(1000);
        l_desc      VARCHAR2(4000);
        l_comp      icnp_composition.id_composition%TYPE;
        l_counter   PLS_INTEGER;
        c_search    pk_types.cursor_type;
        l_func_name VARCHAR2(50) := 'GET_ICNP_EQUAL_TERMS';
        l_compo     table_number := table_number();
        l_descr     table_varchar := table_varchar();
        l_i_count   PLS_INTEGER;
    
    BEGIN
        l_str     := '';
        l_counter := 1;
        l_i_count := 1;
    
        l_compo.extend;
        l_descr.extend;
        l_compo(l_counter) := -1;
        l_descr(l_counter) := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ICNP_M013');
    
        --build terms list
        g_error := 'LOOP i_term list';
        FOR i IN (SELECT column_value AS id_term
                    FROM TABLE(CAST(i_term AS table_number))
                   ORDER BY column_value)
        LOOP
            IF l_i_count = 1
            THEN
                l_str     := i.id_term;
                l_i_count := l_i_count + 1;
            ELSE
                l_str := l_str || ',' || i.id_term;
            END IF;
        END LOOP;
    
        l_sql_str := 'SELECT id_composition, ' || 'LTRIM(MAX(SYS_CONNECT_BY_PATH(id_term,'','')) ' ||
                     'KEEP (DENSE_RANK LAST ORDER BY curr),'','') AS list_terms, max(flg_type) ' ||
                     'FROM   (SELECT ict.id_composition, ' || '        ict.id_term, ' || '        ic.flg_type, ' ||
                     '        ROW_NUMBER() OVER (PARTITION BY ict.id_composition ORDER BY id_term) AS curr, ' ||
                     '        ROW_NUMBER() OVER (PARTITION BY ict.id_composition ORDER BY id_term) -1 AS prev ' ||
                     'FROM   icnp_composition_term ict, icnp_composition_hist ich, icnp_composition ic ' ||
                     'WHERE ict.id_term IN (' || l_str || ') ' || 'AND ict.id_composition= ich.id_composition ' ||
                     'AND ict.id_composition= ic.id_composition ' || 'AND ic.flg_type=''' || i_flag || ''' ' ||
                     'AND ic.id_institution= ' || i_prof.institution || ' ' || 'AND ich.id_composition_hist <> ' ||
                     nvl(i_comp, -1) || ' ' || 'AND ich.flg_most_recent=''' || pk_alert_constant.g_yes ||
                     ''' AND ich.flg_cancel = ''' || pk_alert_constant.g_no || ''') ' || 'GROUP BY id_composition ' ||
                     'CONNECT BY prev = PRIOR curr AND id_composition = PRIOR id_composition ' || 'START WITH curr = 1';
    
        g_error := 'OPEN c_search';
        OPEN c_search FOR l_sql_str;
        LOOP
            FETCH c_search
                INTO l_comp, l_desc, l_flg;
            EXIT WHEN c_search%NOTFOUND;
        
            IF l_str = l_desc
            THEN
                l_counter := l_counter + 1;
                l_compo.extend;
                l_descr.extend;
                l_compo(l_counter) := l_comp;
                l_descr(l_counter) := get_compo_desc(i_lang, l_comp);
            END IF;
        
        END LOOP;
    
        o_comp := l_compo;
        o_desc := l_descr;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_icnp_equal_terms;

    /********************************************************************************************
    * Get software departments available for professional responsible of icnp builder
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_term    ICNP term ID (focus term)
    * @param      o_active_servs Active Services    
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/03/23
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_soft_dept
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_term        IN icnp_term.id_term%TYPE,
        o_activ_servs OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(50) := 'GET_ICNP_SOFT_DEPT';
    BEGIN
    
        g_error := 'OPEN o_activ_servs';
        --Cursor to get all active dept's/departments/services by professional institution                     
        OPEN o_activ_servs FOR
            SELECT t.name,
                   t.id_software,
                   t.id_dept,
                   short_dept_desc,
                   t.id_department,
                   short_department_desc,
                   t.id_dep_clin_serv,
                   short_dcs_desc,
                   pk_alert_constant.g_inactive flg_status
              FROM (SELECT s.name,
                           sd.id_software,
                           de.id_dept,
                           pk_translation.get_translation(i_lang, de.code_dept) AS short_dept_desc,
                           d.id_department,
                           d.code_department,
                           pk_translation.get_translation(i_lang, d.code_department) AS short_department_desc,
                           dcs.id_dep_clin_serv,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) short_dcs_desc
                      FROM prof_soft_inst psi
                      JOIN software s
                        ON (psi.id_software = s.id_software)
                      JOIN software_dept sd
                        ON (sd.id_software = s.id_software)
                      JOIN department d
                        ON (sd.id_dept = d.id_dept)
                      JOIN dept de
                        ON (d.id_dept = de.id_dept)
                      JOIN dep_clin_serv dcs
                        ON (d.id_department = dcs.id_department)
                      JOIN clinical_service cs
                        ON (dcs.id_clinical_service = cs.id_clinical_service)
                     WHERE psi.id_institution IN (0, i_prof.institution)
                       AND psi.id_professional = i_prof.id
                       AND d.id_institution IN (0, i_prof.institution)
                       AND d.flg_available = pk_alert_constant.g_yes
                       AND de.flg_available = pk_alert_constant.g_yes
                       AND dcs.flg_available = pk_alert_constant.g_yes
                       AND cs.flg_available = pk_alert_constant.g_yes
                       AND NOT EXISTS (SELECT 1
                              FROM icnp_axis_dcs iad
                             WHERE iad.id_dep_clin_serv = dcs.id_dep_clin_serv
                               AND iad.id_term = i_term
                               AND iad.id_institution IN (0, i_prof.institution))) t
             WHERE short_department_desc IS NOT NULL
               AND short_dcs_desc IS NOT NULL
             GROUP BY t.id_software,
                      t.id_dept,
                      t.name,
                      short_dept_desc,
                      t.id_department,
                      short_department_desc,
                      t.id_dep_clin_serv,
                      short_dcs_desc
            UNION ALL
            SELECT t2.name,
                   t2.id_software,
                   t2.id_dept,
                   short_dept_desc,
                   t2.id_department,
                   short_department_desc,
                   t2.id_dep_clin_serv,
                   short_dcs_desc,
                   pk_alert_constant.g_active flg_status
              FROM (SELECT s.name,
                           sd.id_software,
                           de.id_dept,
                           pk_translation.get_translation(i_lang, de.code_dept) AS short_dept_desc,
                           d.id_department,
                           pk_translation.get_translation(i_lang, d.code_department) AS short_department_desc,
                           dcs.id_dep_clin_serv,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) short_dcs_desc
                      FROM prof_soft_inst psi
                      JOIN software s
                        ON (psi.id_software = s.id_software)
                      JOIN software_dept sd
                        ON (sd.id_software = s.id_software)
                      JOIN department d
                        ON (sd.id_dept = d.id_dept)
                      JOIN dept de
                        ON (d.id_dept = de.id_dept)
                      JOIN dep_clin_serv dcs
                        ON (d.id_department = dcs.id_department)
                      JOIN clinical_service cs
                        ON (dcs.id_clinical_service = cs.id_clinical_service)
                     WHERE psi.id_institution IN (0, i_prof.institution)
                       AND psi.id_professional = i_prof.id
                       AND d.id_institution IN (0, i_prof.institution)
                       AND d.flg_available = pk_alert_constant.g_yes
                       AND de.flg_available = pk_alert_constant.g_yes
                       AND dcs.flg_available = pk_alert_constant.g_yes
                       AND cs.flg_available = pk_alert_constant.g_yes
                       AND EXISTS (SELECT 1
                              FROM icnp_axis_dcs iad
                             WHERE iad.id_dep_clin_serv = dcs.id_dep_clin_serv
                               AND iad.id_term = i_term
                               AND iad.id_institution IN (0, i_prof.institution))) t2
             WHERE short_dcs_desc IS NOT NULL
               AND short_department_desc IS NOT NULL
             GROUP BY t2.id_software,
                      t2.id_dept,
                      t2.name,
                      short_dept_desc,
                      t2.id_department,
                      short_department_desc,
                      t2.id_dep_clin_serv,
                      short_dcs_desc
             ORDER BY 1, 4, 6, 8;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_activ_servs);
                RETURN FALSE;
            END;
        
    END get_icnp_soft_dept;
    /********************************************************************************************
    * Get software departments available for professional responsible of icnp builder
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_soft    Software ID (if available)
    * @param      i_dept    Dept ID (if available)
    * @param      i_term    ICNP term ID
    * @param      o_serv    List of services (from dep_clin_serv)
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/04/14
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_departments
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_soft  IN software.id_software%TYPE,
        i_dept  IN dept.id_dept%TYPE,
        i_term  IN icnp_term.id_term%TYPE,
        o_deps  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(50) := 'GET_ICNP_DEPARTMENTS';
    BEGIN
    
        g_error := 'OPEN o_deps';
        --cursor to get departments based on dept and terms selected
        OPEN o_deps FOR
            SELECT d.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) AS short_desc,
                   SUM(dcs.x) AS total,
                   SUM(nvl(iad.y, 0)) AS parcial
              FROM dept dep
             INNER JOIN department d
                ON d.id_dept = dep.id_dept
             INNER JOIN (SELECT COUNT(*) AS x, id_department
                           FROM dep_clin_serv
                          GROUP BY id_department) dcs
                ON d.id_department = dcs.id_department
              LEFT JOIN (SELECT COUNT(*) AS y, dcs.id_department
                           FROM icnp_axis_dcs iad, dep_clin_serv dcs
                          WHERE iad.id_institution IN (0, i_prof.institution)
                            AND iad.id_term = i_term
                            AND iad.id_dep_clin_serv = dcs.id_dep_clin_serv
                          GROUP BY dcs.id_department) iad
                ON iad.id_department = dcs.id_department
             WHERE dep.id_dept = i_dept
               AND dep.id_institution IN (0, i_prof.institution)
               AND d.id_institution IN (0, i_prof.institution)
               AND d.flg_available = pk_alert_constant.g_yes
             GROUP BY d.id_department, pk_translation.get_translation(i_lang, d.code_department)
             ORDER BY 2, 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_deps);
                RETURN FALSE;
            END;
        
    END get_icnp_departments;

    /********************************************************************************************
    * Get software departments available for professional responsible of icnp builder
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_soft    Software ID (if available)
    * @param      i_depa    Department ID (if available)
    * @param      i_term    ICNP term ID
    * @param      o_serv    List of services (from dep_clin_serv)
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/04/01
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_icnp_services
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_soft  IN software.id_software%TYPE,
        i_depa  IN department.id_department%TYPE,
        i_term  IN icnp_term.id_term%TYPE,
        o_serv  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(50) := 'GET_ICNP_SERVICES';
    BEGIN
    
        g_error := 'OPEN o_serv';
        -- for Non Private Practice
        IF i_depa IS NOT NULL
        THEN
            OPEN o_serv FOR
                SELECT DISTINCT dcs.id_dep_clin_serv,
                                pk_translation.get_translation(i_lang, cs.code_clinical_service) short_desc,
                                decode(nvl(iad.term, 0), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes) AS has_child
                  FROM dep_clin_serv dcs
                 INNER JOIN clinical_service cs
                    ON dcs.id_clinical_service = cs.id_clinical_service
                 INNER JOIN department d
                    ON d.id_department = dcs.id_department
                  LEFT JOIN (SELECT COUNT(*) AS term, id_dep_clin_serv
                               FROM icnp_axis_dcs iad
                              WHERE iad.id_term = i_term
                              GROUP BY id_dep_clin_serv) iad
                    ON dcs.id_dep_clin_serv = iad.id_dep_clin_serv
                 WHERE d.id_department = i_depa
                   AND d.id_institution IN (0, i_prof.institution)
                   AND pk_translation.get_translation(i_lang, cs.code_clinical_service) IS NOT NULL
                   AND d.flg_available = pk_alert_constant.g_yes
                   AND dcs.flg_available = pk_alert_constant.g_yes
                 ORDER BY 2, 1;
        ELSE
            -- for Private Practice
            OPEN o_serv FOR
                SELECT DISTINCT dcs.id_dep_clin_serv,
                                pk_translation.get_translation(i_lang, cs.code_clinical_service) short_desc,
                                decode(nvl(iad.term, 0), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes) AS has_child
                  FROM dep_clin_serv dcs
                 INNER JOIN clinical_service cs
                    ON dcs.id_clinical_service = cs.id_clinical_service
                 INNER JOIN department d
                    ON d.id_department = dcs.id_department
                 INNER JOIN software_dept sd
                    ON sd.id_dept = d.id_dept
                  LEFT JOIN (SELECT COUNT(*) AS term, id_dep_clin_serv
                               FROM icnp_axis_dcs iad
                              WHERE iad.id_term = i_term
                              GROUP BY id_dep_clin_serv) iad
                    ON dcs.id_dep_clin_serv = iad.id_dep_clin_serv
                 WHERE /*sd.id_software = i_prof.softwareAND*/
                 d.id_institution IN (0, i_prof.institution)
                 AND pk_translation.get_translation(i_lang, cs.code_clinical_service) IS NOT NULL
                 AND d.flg_available = pk_alert_constant.g_yes
                 AND dcs.flg_available = pk_alert_constant.g_yes
                 ORDER BY 2, 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_serv);
                RETURN FALSE;
            END;
        
    END get_icnp_services;

    /********************************************************************************************
    * Set software departments and services for available icnp focus
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_serv    Services list
    * @param      i_soft    Software list
    * @param      i_dept    Departments list
    * @param      i_focus   Focus term list
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/04/01
    * @dependents            PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION set_icnp_focus_services
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_serv  IN table_table_number,
        i_soft  IN table_number,
        i_dept  IN table_number,
        i_focus IN table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(50) := 'SET_ICNP_FOCUS_SERVICES';
        l_id_axis   NUMERIC;
        l_focus     NUMERIC;
    
    BEGIN
    
        IF i_focus IS NOT NULL
           AND i_focus.count > 0
        THEN
            --loop by focus
            FOR k IN i_focus.first .. i_focus.last
            LOOP
                l_focus := i_focus(k);
            END LOOP;
        
            --get focus axis
            SELECT id_axis
              INTO l_id_axis
              FROM icnp_term it
             WHERE it.id_term = l_focus;
        
            --General (non private practice)
            IF i_soft IS NOT NULL
               AND i_soft.count > 0
            THEN
                g_error := 'LOOP by software';
            
                --reset old values
                DELETE icnp_axis_dcs dcs
                 WHERE dcs.id_term = l_focus
                   AND dcs.id_institution = i_prof.institution;
                --loop by soft
                FOR i IN i_soft.first .. i_soft.last
                LOOP
                    IF i_soft(i) IS NOT NULL
                    THEN
                        g_error := 'LOOP by services ' || i_serv.count || '->' || i;
                        --loop by services list                
                        IF i_serv.count >= i
                        THEN
                            IF i_serv(i) IS NOT NULL
                            THEN
                                IF i_serv(i).count > 0
                                THEN
                                    g_error := 'Services iteration' || i;
                                    FOR j IN i_serv(i).first .. i_serv(i).last
                                    LOOP
                                        g_error := 'Services iteration';
                                        IF i_serv(i) (j) IS NOT NULL
                                        THEN
                                            INSERT INTO icnp_axis_dcs
                                                (id_icnp_axis_dcs,
                                                 id_axis,
                                                 id_term,
                                                 id_composition,
                                                 id_dep_clin_serv,
                                                 id_software,
                                                 id_institution)
                                            VALUES
                                                (seq_icnp_axis_dcs.nextval,
                                                 l_id_axis,
                                                 l_focus,
                                                 NULL,
                                                 i_serv(i) (j),
                                                 nvl(i_soft(i), i_prof.software),
                                                 i_prof.institution);
                                        END IF;
                                    END LOOP;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            
            ELSE
                --reset old values
                DELETE icnp_axis_dcs dcs
                 WHERE dcs.id_term = l_focus
                   AND dcs.id_institution = i_prof.institution;
            
                IF i_serv IS NOT NULL
                   AND i_serv.count > 0
                THEN
                    g_error := 'LOOP by services (PP + CARE)';
                    --for Private Practice
                    IF i_serv(1).first IS NOT NULL
                    THEN
                        FOR j IN i_serv(1).first .. i_serv(1).last
                        LOOP
                            INSERT INTO icnp_axis_dcs
                                (id_icnp_axis_dcs,
                                 id_axis,
                                 id_term,
                                 id_composition,
                                 id_dep_clin_serv,
                                 id_software,
                                 id_institution)
                            VALUES
                                (seq_icnp_axis_dcs.nextval,
                                 l_id_axis,
                                 l_focus,
                                 NULL,
                                 i_serv(1) (j),
                                 i_prof.software,
                                 i_prof.institution);
                        END LOOP;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_icnp_focus_services;

    /******************************************************************************/
    FUNCTION prv_get_id_patient(i_episode IN episode.id_episode%TYPE) RETURN episode.id_episode%TYPE IS
        l_id_patient patient.id_patient%TYPE;
    BEGIN
        -- <DENORM_EPISODE_JOSE_BRITO>
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e --, visit v
         WHERE e.id_episode = i_episode;
        --AND v.id_visit = e.id_visit;
    
        RETURN l_id_patient;
    END prv_get_id_patient;

    /******************************************************************************/
    FUNCTION prv_pat_get_gender(i_id_patient IN patient.id_patient%TYPE) RETURN patient.gender%TYPE IS
        l_gender patient.gender%TYPE;
    BEGIN
        SELECT gender
          INTO l_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        RETURN l_gender;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'B';
    END prv_pat_get_gender;

    /******************************************************************************/
    FUNCTION desc_composition
    (
        i_lang        IN language.id_language%TYPE,
        i_composition IN icnp_composition.id_composition%TYPE
    ) RETURN VARCHAR2 IS
        /** @headcom
        * Private Function. Textualize the composition description based on the composition id
        * associated terms.
        *
        * @param     i_lang          default language
        * @param     i_composition   composition id, must be unique
        *
        * @return    varchar, the composition description, null on error or if it doesn´t exists
        * @author    Ricardo Pinho
        * @version   alpha
        * @since     2005/10/04
        */
        compo_desc       VARCHAR2(2000) := NULL;
        easy_translation VARCHAR2(4000) := NULL;
        i                NUMBER;
    BEGIN
        /*
        * Input parameters consistency!
        *
        * If composition ID is null return an empty string
        */
        IF (i_composition IS NULL)
        THEN
            RETURN '';
        END IF;
    
        BEGIN
            SELECT pk_translation.get_translation(i_lang, i.code_icnp_composition)
              INTO easy_translation
              FROM icnp_composition i
             WHERE id_composition = i_composition;
        
            IF (easy_translation <> 'NULL')
            THEN
                RETURN easy_translation;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                /*
                * MAJOR ERROR, is not suposed to exist an ID with no correspondence...
                */
                RETURN pk_message.get_message(i_lang, 'COMMON_M001');
        END;
        RETURN compo_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLERRM;
    END desc_composition;

    /******************************************************************************/
    FUNCTION get_compo
    (
        i_lang        IN language.id_language%TYPE,
        i_type        IN icnp_composition.flg_type%TYPE,
        i_nurse_tea   IN icnp_composition.flg_nurse_tea%TYPE DEFAULT NULL,
        i_folder      IN icnp_folder.id_folder%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        o_composition OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /** @headcom
        * Gets all compositions based on some criterias.
        *
        * @param      i_lang           default language
        * @param      i_type           (D)iagnoses or (A)ctions
        * @param      i_nurse_tea      nursering teaching, (Y)es or (N)o
        * @param      i_folder         folder identifier
        * @param      i_prof           alert user
        * @param      i_id_patient      patien identifier... used to know the gender
        * @param      o_composition    the compositions that match criteria
        * @param      o_error          error coming right at you!!!!
        *
        * @return     boolean type, "False" on error or "True" if success
        * @author     Ricardo Pinho
        * @version    beta
        * @since      2005/10/04
        */
        l_gender patient.gender%TYPE;
    BEGIN
        g_error := 'prv_pat_get_gender (' || i_id_patient || ');';
        /* get the patient gender based no patient */
        l_gender := prv_pat_get_gender(i_id_patient);
        g_error  := 'OPEN o_composition FOR';
    
        /* w h e n   i _ f o l d e r   i s   n o t   s p e c i f i e d */
        IF (i_folder < 0)
        THEN
            OPEN o_composition FOR
                SELECT *
                  FROM (SELECT id_composition,
                               desc_composition(i_lang, id_composition) desc_composition,
                               flg_repeat,
                               decode(flg_solved, NULL, 'N', 'Y') flg_solved
                          FROM (SELECT DISTINCT ic.id_composition, ic.flg_repeat, ic.flg_solved
                                  FROM icnp_composition ic, icnp_compo_dcs icd
                                 WHERE rownum > 0
                                   AND ic.flg_available = pk_alert_constant.g_yes
                                   AND ((i_id_patient IS NOT NULL AND
                                       ic.flg_gender IN (l_gender, pk_icnp_constant.g_composition_gender_both)) OR
                                       i_id_patient IS NULL)
                                   AND ic.flg_nurse_tea = nvl(i_nurse_tea, ic.flg_nurse_tea)
                                   AND ic.flg_type = nvl(i_type, ic.flg_type)
                                   AND icd.id_composition = ic.id_composition
                                   AND icd.id_dep_clin_serv IN
                                       (SELECT dcs.id_dep_clin_serv
                                          FROM dep_clin_serv dcs, department d, dept dp, software_dept sd
                                         WHERE d.id_department = dcs.id_department
                                           AND d.id_institution = i_prof.institution
                                           AND dp.id_dept = d.id_dept
                                           AND sd.id_dept = dp.id_dept
                                           AND sd.id_software = i_prof.software))
                         ORDER BY 2)
                 WHERE desc_composition IS NOT NULL;
        
            /* w h e n   a   f o l d e r   i s   s p e c i f i e d */
        ELSE
            OPEN o_composition FOR
                SELECT *
                  FROM (SELECT id_composition,
                               desc_composition(i_lang, id_composition) desc_composition,
                               flg_repeat,
                               decode(flg_solved, NULL, 'N', 'Y') flg_solved
                          FROM (SELECT DISTINCT ic.id_composition, ic.flg_repeat, ic.flg_solved
                                  FROM icnp_composition ic,
                                       icnp_compo_dcs   icd,
                                       dep_clin_serv    dcs,
                                       department       d,
                                       software_dept    sd
                                 WHERE rownum > 0
                                   AND icd.id_composition = ic.id_composition
                                   AND dcs.id_dep_clin_serv = icd.id_dep_clin_serv
                                   AND dcs.id_clinical_service = i_folder
                                   AND d.id_department = dcs.id_department
                                   AND d.id_institution = i_prof.institution
                                   AND sd.id_dept = d.id_dept
                                   AND sd.id_software = i_prof.software
                                   AND ic.flg_available = pk_alert_constant.g_yes
                                   AND ((i_id_patient IS NOT NULL AND
                                       ic.flg_gender IN (l_gender, pk_icnp_constant.g_composition_gender_both)) OR
                                       i_id_patient IS NULL)
                                   AND ic.flg_nurse_tea = nvl(i_nurse_tea, ic.flg_nurse_tea)
                                   AND ic.flg_type = nvl(i_type, ic.flg_type))
                         ORDER BY 2)
                 WHERE desc_composition IS NOT NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_COMPO');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                --pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_composition);
                RETURN FALSE;
            END;
        
    END get_compo;

    /******************************************************************************/
    FUNCTION get_diag_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN icnp_epis_diagnosis.id_episode%TYPE,
        i_diag      IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_interv    IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_status    IN icnp_epis_diagnosis.flg_status%TYPE,
        i_prof      IN profissional,
        o_diagnoses OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /** @headcom
        * Returns summary information about diagnosis. Can be filtered by status and a
        * diagnosis id itself.
        *
        * @param   i_lang            default language
        * @param   i_episode         clinical episode
        * @param   i_diag            optional, refers to a specific diagnosis
        * @param   i_interv          optional, order diagnosis by associated interventions. First to be
                   be returned is the one with i_interv associated
        * @param   i_status          optional, (F)inished, (C)anceled, (A)ctive. NULL means all
        * @param   o_diagnosis       diagnoses coming right at you!!!
        * @param   o_error           error coming right at you!!!
        *
        * @see     get_diagnosis_hist get_diagnosis_hist
        * @return  boolean type, "False" on error or "True" if success
        * @author  Ricardo Pinho
        * @version beta
        * @since   2005/10/27
        */
        l_id_patient       icnp_epis_diagnosis.id_patient%TYPE;
        l_flg_status       table_varchar := table_varchar();
        l_short_diag_nurse sys_shortcut.id_sys_shortcut%TYPE;
        --
        -- ET 2007/04/21
        -- atalho para os diagnósticos de enfermagem
        CURSOR c_short_diag_nurse IS
            SELECT id_sys_shortcut
              FROM sys_shortcut
             WHERE intern_name = 'GRID_ICNP_DIAG'
               AND id_software = i_prof.software
               AND id_institution IN (0, i_prof.institution)
             ORDER BY id_institution DESC;
    
        l_ncp_class sys_config.value%TYPE;
    BEGIN
    
        l_ncp_class := pk_sysconfig.get_config(pk_nnn_constant.g_config_classification, i_prof);
    
        IF l_ncp_class = pk_nnn_constant.g_classification_nanda_nic_noc
        THEN
            g_error  := 'Call GET_EPIS_NNN_DIAG_SUMMARY';
            g_retval := pk_nnn_core.get_epis_nnn_diag_summary(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_episode   => i_episode,
                                                              o_diagnosis => o_diagnoses);
        ELSE
            -- pk_nnn_constant.g_classification_icnp
        
            -- ET 2007/04/21
            g_error := 'OPEN c_short_diag_nurse';
            OPEN c_short_diag_nurse;
            FETCH c_short_diag_nurse
                INTO l_short_diag_nurse;
            CLOSE c_short_diag_nurse;
        
            IF (i_status = pk_icnp_constant.g_epis_diag_status_active OR i_status IS NULL)
            THEN
                l_flg_status := table_varchar(pk_icnp_constant.g_epis_diag_status_active,
                                              pk_icnp_constant.g_epis_diag_status_resolved,
                                              pk_icnp_constant.g_epis_diag_status_revaluated);
            END IF;
        
            --
            g_error := 'prv_get_id_patient (i_episode => ' || i_episode || ');';
            /* get patient based on episode */
            l_id_patient := prv_get_id_patient(i_episode => i_episode);
            --
            g_error := 'OPEN o_diagnoses FOR';
            OPEN o_diagnoses FOR
                SELECT id_icnp_epis_diag,
                       flg_type,
                       description,
                       status,
                       date_target,
                       hour_target,
                       prof,
                       flg_status,
                       dt_ord1,
                       id_composition,
                       dt_icnp_epis_diag,
                       dt_close,
                       flg_check
                  FROM (
                        -- everything active on past episodes --
                        SELECT ied.id_icnp_epis_diag,
                                pk_icnp_constant.g_composition_type_diagnosis flg_type,
                                desc_composition(i_lang, ied.id_composition) description,
                                nvl(l_short_diag_nurse, '0') || '|' || 'xxxxxxxxxxxxxx' || '|' || 'I' || '|' || 'X' || '|' ||
                                pk_sysdomain.get_img(i_lang, 'ICNP_EPIS_DIAGNOSIS.FLG_STATUS', ied.flg_status) status,
                                decode(ied.dt_close_tstz,
                                       NULL,
                                       pk_date_utils.dt_chr_tsz(i_lang, ied.dt_icnp_epis_diag_tstz, i_prof),
                                       pk_date_utils.dt_chr_tsz(i_lang, ied.dt_close_tstz, i_prof)) date_target,
                                decode(ied.dt_close_tstz,
                                       NULL,
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        ied.dt_icnp_epis_diag_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software),
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        ied.dt_close_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software)) hour_target,
                                p.nick_name prof,
                                ied.flg_status,
                                pk_sysdomain.get_rank(i_lang, 'ICNP_EPIS_INTERVENTION.FLG_STATUS', ied.flg_status) rank_type,
                                pk_date_utils.date_send_tsz(i_lang,
                                                            nvl(ied.dt_close_tstz, ied.dt_icnp_epis_diag_tstz),
                                                            i_prof) dt_ord1,
                                ied.id_composition,
                                pk_date_utils.date_send_tsz(i_lang, ied.dt_icnp_epis_diag_tstz, i_prof) dt_icnp_epis_diag,
                                pk_date_utils.date_send_tsz(i_lang, ied.dt_close_tstz, i_prof) dt_close,
                                decode((SELECT COUNT(1)
                                         FROM icnp_epis_intervention iei, icnp_epis_diag_interv iedi, icnp_interv_plan iip
                                        WHERE iei.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                                          AND iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                                          AND iei.id_icnp_epis_interv = iip.id_icnp_epis_interv
                                          AND iip.flg_status = pk_icnp_constant.g_interv_plan_status_executed),
                                       0,
                                       pk_alert_constant.g_yes,
                                       pk_alert_constant.g_no) flg_check
                          FROM icnp_epis_diagnosis ied, professional p
                         WHERE ied.id_patient = l_id_patient
                           AND ied.flg_status IN (SELECT /*+ opt_estimate(table t rows=3)*/
                                                   t.column_value
                                                    FROM TABLE(l_flg_status) t)
                           AND p.id_professional = ied.id_professional
                        UNION
                        -- everything on current episode --
                        SELECT ied.id_icnp_epis_diag,
                                pk_icnp_constant.g_composition_type_diagnosis flg_type,
                                desc_composition(i_lang, ied.id_composition) description,
                                nvl(l_short_diag_nurse, '0') || '|' || 'xxxxxxxxxxxxxx' || '|' || 'I' || '|' || 'X' || '|' ||
                                pk_sysdomain.get_img(i_lang, 'ICNP_EPIS_DIAGNOSIS.FLG_STATUS', ied.flg_status) status,
                                decode(ied.dt_close_tstz,
                                       NULL,
                                       pk_date_utils.dt_chr_tsz(i_lang, ied.dt_icnp_epis_diag_tstz, i_prof),
                                       pk_date_utils.dt_chr_tsz(i_lang, ied.dt_close_tstz, i_prof)) date_target,
                                decode(ied.dt_close_tstz,
                                       NULL,
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        ied.dt_icnp_epis_diag_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software),
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        ied.dt_close_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software)) hour_target,
                                nvl(pc.nick_name, p.nick_name) prof,
                                flg_status,
                                pk_sysdomain.get_rank(i_lang, 'ICNP_EPIS_INTERVENTION.FLG_STATUS', ied.flg_status) rank_type,
                                pk_date_utils.date_send_tsz(i_lang,
                                                            nvl(ied.dt_close_tstz, ied.dt_icnp_epis_diag_tstz),
                                                            i_prof) dt_ord1,
                                ied.id_composition,
                                pk_date_utils.date_send_tsz(i_lang, ied.dt_icnp_epis_diag_tstz, i_prof) dt_icnp_epis_diag,
                                pk_date_utils.date_send_tsz(i_lang, ied.dt_close_tstz, i_prof) dt_close,
                                decode((SELECT COUNT(1)
                                         FROM icnp_epis_intervention iei, icnp_epis_diag_interv iedi, icnp_interv_plan iip
                                        WHERE iei.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                                          AND iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                                          AND iei.id_icnp_epis_interv = iip.id_icnp_epis_interv
                                          AND iip.flg_status = pk_icnp_constant.g_interv_plan_status_executed),
                                       0,
                                       pk_alert_constant.g_yes,
                                       pk_alert_constant.g_no) flg_check
                          FROM icnp_epis_diagnosis ied, professional p, professional pc
                         WHERE ied.id_episode = i_episode
                           AND ied.flg_status = nvl(i_status, ied.flg_status)
                           AND ied.flg_status <> pk_icnp_constant.g_epis_diag_status_revaluated
                           AND p.id_professional = ied.id_professional
                           AND pc.id_professional(+) = ied.id_prof_close)
                -- order com base primeiro no status e depois na data --
                 ORDER BY rank_type, dt_ord1 DESC, 3 ASC;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_DIAG_SUMMARY');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                pk_types.open_my_cursor(o_diagnoses);
                RETURN FALSE;
            END;
        
    END get_diag_summary;

    /******************************************************************************/
    /** @headcom
    * Gets diagnosis history and its associated interventions for the given patient.
    *
    * @param      i_lang         default language
    * @param      i_prof         professional
    * @param      o_diag         diagnosis history
    * @param      o_error        error
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Nelson Lima
    * @version    alpha
    * @since      2007/11/05
    */
    FUNCTION get_diag_viewer
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'RETRIEVING FROM DB';
    
        OPEN o_diag FOR
            SELECT ied.id_icnp_epis_diag id_icnp_epis_diag,
                   pk_date_utils.date_hour_chr_extend_tsz(i_lang, ied.dt_icnp_epis_diag_tstz, i_prof) dt,
                   --p.nick_name professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS professional,
                   pk_translation.get_translation(i_lang, ic.code_icnp_composition) diagnosis,
                   pk_utils.query_to_string('select distinct
                            pk_translation.get_translation(' || i_lang ||
                                            ',ic.code_icnp_composition)
                            from
                            icnp_epis_diagnosis ied,
                            icnp_epis_diag_interv iedi,
                            icnp_epis_intervention iei,
                            icnp_composition ic
                            where
                            ied.id_icnp_epis_diag=iedi.id_icnp_epis_diag
                            AND iedi.id_icnp_epis_interv = iei.id_icnp_epis_interv
                            AND iei.id_composition = ic.id_composition
                            AND ied.id_icnp_epis_diag =' ||
                                            ied.id_icnp_epis_diag,
                                            ', ') interventions,
                   
                   --et.code_epis_type viewer_category,
                   --pk_translation.get_translation(i_lang, et.code_epis_type) viewer_category_desc,
                   'EPIS_TYPE.CODE_EPIS_TYPE.' || ied.id_epis_type viewer_category,
                   pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.' || ied.id_epis_type) viewer_category_desc,
                   ied.id_professional viewer_id_prof,
                   ied.id_episode viewer_id_epis,
                   pk_date_utils.date_send_tsz(i_lang, ied.dt_icnp_epis_diag_tstz, i_prof) viewer_date
              FROM --episode             e,
                   --visit               v,
                   --epis_type           et
                    icnp_epis_diagnosis ied,
                   epis_type_soft_inst etsi,
                   professional        p,
                   icnp_composition    ic
            
             WHERE
            --ied.id_episode = e.id_episode
            --AND e.id_visit = v.id_visit
            --AND v.id_patient = i_patient
            --AND e.flg_status = 'A'  -- faz sentido mostrar episódios activos e inactivos [rui.baeta]
             ied.id_patient = i_patient
             AND ied.flg_status != 'C'
             AND ied.id_professional = p.id_professional
             AND ied.id_epis_type = etsi.id_epis_type --e.id_epis_type = etsi.id_epis_type
             AND ied.id_composition = ic.id_composition
             AND etsi.id_software = i_prof.software
             AND etsi.id_institution IN (0, i_prof.institution)
             AND etsi.id_epis_type = ied.id_epis_type; --et.id_epis_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_DIAG_VIEWER');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                pk_types.open_my_cursor(o_diag);
                RETURN FALSE;
            END;
        
    END get_diag_viewer;

    /******************************************************************************
    * @headcom
    * Returns clinical service set within this institution.
    *
    * @param      i_lang        default language
    * @param      i_inst        institution id
    * @param      i_dep         department id
    * @param      o_clin_serv   clinical services
    * @param      o_error       error coming right at you!!!!
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Ricardo Pinho
    * @version    alpha
    * @since      2005/10/07
    */
    FUNCTION get_folder
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count NUMBER := 0;
    BEGIN
        g_error := 'before delete of tbl_temp';
        DELETE tbl_temp;
    
        -- insert into temporary table to count before return
        g_error := 'insert into tbl_temp';
        INSERT INTO tbl_temp
            (num_1, vc_1, num_2, num_3)
            SELECT id_clinical_service, desc_clinical_service, id_dep_clin_serv, rank
              FROM (SELECT id_clinical_service,
                           --Add the department because some clincal services are repeated in different departments
                           pk_translation.get_translation(i_lang, code_clinical_service) || ' (' ||
                           pk_translation.get_translation(i_lang, code_department) || ')' desc_clinical_service,
                           id_dep_clin_serv,
                           rank
                      FROM (SELECT DISTINCT dcs.id_clinical_service  id_clinical_service,
                                            cs.code_clinical_service,
                                            d.code_department,
                                            dcs.id_dep_clin_serv     id_dep_clin_serv,
                                            0                        rank
                              FROM icnp_compo_dcs   icd,
                                   dep_clin_serv    dcs,
                                   department       d,
                                   software_dept    sd,
                                   clinical_service cs
                             WHERE rownum > 0
                               AND dcs.id_dep_clin_serv = icd.id_dep_clin_serv
                               AND d.id_department = dcs.id_department
                               AND sd.id_dept = d.id_dept
                               AND dcs.flg_available = pk_alert_constant.g_yes
                               AND d.flg_available = pk_alert_constant.g_yes
                               AND cs.flg_available = pk_alert_constant.g_yes
                               AND sd.id_software = i_prof.software
                               AND cs.id_clinical_service = dcs.id_clinical_service
                               AND dcs.id_department IN
                                   (SELECT d.id_department
                                      FROM department d
                                     WHERE d.id_institution = i_prof.institution
                                       AND d.flg_available = pk_alert_constant.g_yes)))
             WHERE desc_clinical_service IS NOT NULL
            UNION
            SELECT -1 id_clinical_service,
                   pk_message.get_message(i_lang, i_prof, 'TodasEspecialidadesCIPE') desc_clinical_service,
                   NULL id_dep_clin_serv,
                   -1 rank
              FROM dual;
    
        g_error := 'count records';
        SELECT COUNT(*)
          INTO l_count
          FROM tbl_temp;
    
        -- l_count > 1 because if there is only the entry TodasEspecialidadesCIPE don't return
        IF l_count > 1
        THEN
            g_error := 'OPEN o_clin_serv FOR';
            OPEN o_clin_serv FOR
                SELECT num_1 AS id_clinical_service,
                       vc_1  AS desc_clinical_service,
                       num_2 AS id_dep_clin_serv,
                       num_3 AS rank
                  FROM tbl_temp
                 ORDER BY num_3, vc_1;
        ELSE
            g_error := 'OPEN o_clin_serv EMPTY';
            pk_types.open_my_cursor(o_clin_serv);
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_FOLDER');
                -- undo changes quando aplicável-> só faz ROLLBACK
                pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                pk_types.open_my_cursor(o_clin_serv);
                RETURN FALSE;
            END;
        
    END get_folder;

    /******************************************************************************/
    FUNCTION get_interv_det
    (
        i_lang          IN language.id_language%TYPE,
        i_interv        IN table_number,
        i_prof          IN profissional,
        o_interventions OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /** @headcom
        * Return the intervention details.
        *
        * @param      i_lang            default language
        * @param      i_interv          a specific intervention
        * @param      o_interventions   nursing intervention details
        * @param      o_error           error coming right at you!!!
        *
        * @return     boolean type, "False" on error or "True" if success
        * @author     Ricardo Pinho
        * @version    alpha
        * @since      2005/10/14
        */
    
        l_suggest_exec_date   VARCHAR2(40) := 'NURSING_SUGGEST_EXEC_DATE';
        l_nursing_exec_keypad VARCHAR2(40) := 'NURSING_EXEC_KEYPAD';
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        /*
        * Get all nursing interventions from all diagnoses
        */
        g_error := 'OPEN O_EPIS_INTERV FOR';
        OPEN o_interventions FOR
            SELECT id_icnp_epis_interv, dt_req, dt_plan, next_dt_plan, keypad_by_def
              FROM (SELECT row_number() over(PARTITION BY iip.id_icnp_epis_interv ORDER BY iip.exec_number) rn,
                           iea.id_icnp_epis_interv,
                           pk_date_utils.get_timestamp_str(i_lang, i_prof, iea.dt_begin, NULL) dt_req,
                           pk_date_utils.date_send_tsz(i_lang,
                                                        CASE
                                                            WHEN pk_sysconfig.get_config(l_suggest_exec_date, i_prof.institution, i_prof.software) =
                                                                 pk_alert_constant.g_yes THEN
                                                             decode(iip.dt_plan_tstz, NULL, g_sysdate_tstz, iip.dt_plan_tstz)
                                                            ELSE
                                                             g_sysdate_tstz
                                                        END,
                                                        i_prof) dt_plan,
                           pk_date_utils.date_send_tsz(i_lang, iip_next.dt_plan_tstz, i_prof) next_dt_plan,
                           pk_sysconfig.get_config(l_nursing_exec_keypad, i_prof.institution, i_prof.software) keypad_by_def
                    
                      FROM interv_icnp_ea iea
                      JOIN icnp_interv_plan iip
                        ON iip.id_icnp_epis_interv = iea.id_icnp_epis_interv
                      LEFT JOIN icnp_interv_plan iip_next
                        ON iip_next.id_icnp_epis_interv = iip.id_icnp_epis_interv
                       AND iip_next.exec_number = iip.exec_number + 1
                       AND iip_next.flg_status = pk_icnp_constant.g_interv_plan_status_requested
                     WHERE iip.id_icnp_interv_plan IN
                           (SELECT iip2.id_icnp_interv_plan
                              FROM icnp_interv_plan iip2
                             WHERE iip2.id_icnp_epis_interv IN (SELECT /*+opt_estimate(table t rows=1) */
                                                                 column_value
                                                                  FROM TABLE(i_interv) t)
                               AND iip2.flg_status = pk_icnp_constant.g_interv_plan_status_requested)
                    
                    )
             WHERE rn = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_INTERV_DET');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                pk_types.open_my_cursor(o_interventions);
                RETURN FALSE;
            END;
        
    END get_interv_det;

    /*
    * Returns episodes interventions. If i_diag is available returns only actions associated
    * with it.
    *
    * @param      i_lang            default language
    * @param      i_episode         clinical episode
    * @param      i_diag            optional, when we want to order interventions by a diagnosis.
                  If parameter IS NOT NULL, interventions from that diagnosis will be returned in first place
    * @param      i_status          DEPRECATED, optional, status
    * @param      o_interventions   nursing intervention
    * @param      o_error           error coming right at you!!!
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Ricardo Pinho
    * @version    beta
    * @since      2005/10/14
    */
    FUNCTION get_interv_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN icnp_epis_intervention.id_episode%TYPE,
        i_diag          IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_status        IN icnp_epis_intervention.flg_status%TYPE,
        i_prof          IN profissional,
        dt_server       OUT VARCHAR2,
        o_interventions OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_id_patient      patient.id_patient%TYPE;
        l_id_sys_shortcut sys_shortcut.id_sys_shortcut%TYPE DEFAULT 0;
        --l_id_epis_type    episode.id_epis_type%TYPE;
    
        CURSOR c_interv_shortcut(i_intern_name IN VARCHAR2) IS
            SELECT ss.id_sys_shortcut
              FROM sys_shortcut ss
             WHERE ss.intern_name = i_intern_name
               AND id_software = i_prof.software
               AND id_institution = i_prof.institution
               AND id_parent IS NULL
            UNION
            SELECT ss.id_sys_shortcut
              FROM sys_shortcut ss
             WHERE ss.intern_name = i_intern_name
               AND id_software = i_prof.software
               AND id_institution = 0
               AND id_parent IS NULL;
    
    BEGIN
        g_error := 'prv_get_id_patient (i_episode => ' || i_episode || ');';
        /* get patient based on episode */
        --l_id_patient := prv_get_id_patient(i_episode => i_episode);
    
        OPEN c_interv_shortcut('GRID_ICNP_INTERV');
        FETCH c_interv_shortcut
            INTO l_id_sys_shortcut;
        CLOSE c_interv_shortcut;
    
        --l_id_epis_type := pk_episode.get_epis_type(i_lang, i_episode);
    
        g_error := 'OPEN O_INTERVENTIONS';
        OPEN o_interventions FOR
            SELECT id_icnp_epis_interv,
                   flg_type,
                   id_diag,
                   desc_diag,
                   flg_status_diag,
                   desc_status_diag,
                   id_interv,
                   t_ti_log.get_desc_with_origin(i_lang,
                                                 i_prof,
                                                 desc_interv,
                                                 pk_episode.get_epis_type(i_lang, id_episode),
                                                 flg_status,
                                                 id_icnp_epis_interv,
                                                 pk_icnp_constant.g_ti_log_type_interv) desc_interv,
                   flg_time,
                   flg_status,
                   status,
                   flg_type_vs,
                   id_vs,
                   date_target,
                   hour_target,
                   prof,
                   dt_ord dt_ord1
              FROM (
                    /*\* ACTIVE NURSING ACTIONS ASSOCIATED WITH PATIENT (IN ALL EPISODES)*\
                    SELECT iea.id_icnp_epis_interv, --iei.id_icnp_epis_interv,
                            pk_icnp_constant.g_composition_type_action flg_type,
                            iea.id_icnp_epis_diag id_diag,
                            desc_composition(i_lang, iea.id_composition_diag) desc_diag,
                            (SELECT flg_status
                               FROM icnp_epis_diagnosis
                              WHERE id_icnp_epis_diag = iea.id_icnp_epis_diag) flg_status_diag,
                            pk_sysdomain.get_domain('ICNP_EPIS_DIAGNOSIS.FLG_STATUS',
                                                    (SELECT flg_status
                                                       FROM icnp_epis_diagnosis
                                                      WHERE id_icnp_epis_diag = iea.id_icnp_epis_diag),
                                                    i_lang) desc_status_diag,
                            iea.id_icnp_epis_interv id_interv,
                            desc_composition(i_lang, iea.id_composition_interv) desc_interv,
                            iea.flg_time,
                            iea.flg_status,
                            l_id_sys_shortcut || pk_utils.get_status_string(i_lang,
                                                                            i_prof,
                                                                            iea.status_str,
                                                                            iea.status_msg,
                                                                            iea.status_icon,
                                                                            iea.status_flg) status,
                            substr(iea.id_vs, 1, 1) flg_type_vs,
                            to_number(substr(iea.id_vs, 2, 7)) id_vs,
                            decode(iea.dt_close,
                                   NULL,
                                   pk_date_utils.dt_chr_tsz(i_lang, iea.dt_next, i_prof),
                                   pk_date_utils.dt_chr_tsz(i_lang, iea.dt_close, i_prof)) date_target,
                            decode(iea.dt_close,
                                   NULL,
                                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                                    iea.dt_next,
                                                                    i_prof.institution,
                                                                    i_prof.software),
                                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                                    iea.dt_close,
                                                                    i_prof.institution,
                                                                    i_prof.software)) hour_target,
                            nvl(pc.nick_name, p.nick_name) prof,
                            pk_sysdomain.get_rank(i_lang, 'ICNP_EPIS_INTERVENTION.FLG_STATUS', iea.flg_status) rank_type,
                            decode(iea.flg_status,
                                   pk_icnp_constant.g_epis_diag_status_active,
                                   pk_date_utils.date_send_tsz(i_lang, iea.dt_next, i_prof.institution, i_prof.software),
                                   NULL) to_order_date,
                            decode(iea.flg_status,
                                   pk_icnp_constant.g_epis_diag_status_active,
                                   NULL,
                                   pk_date_utils.date_send_tsz(i_lang, iea.dt_close, i_prof.institution, i_prof.software)) to_order_date_aux,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        nvl(iea.dt_close, iea.dt_next),
                                                        i_prof.institution,
                                                        i_prof.software) dt_ord,
                            iea.id_episode
                    -- <DENORM_SELECT_JOSE_BRITO>
                      FROM interv_icnp_ea iea, professional p, professional pc
                     WHERE iea.id_patient = l_id_patient
                       AND iea.id_episode != i_episode
                       AND iea.flg_status IN (pk_icnp_constant.g_epis_interv_status_requested,
                                              pk_icnp_constant.g_epis_interv_status_ongoing)
                       AND (iea.flg_status_plan IS NULL OR
                           iea.flg_status_plan =
                           decode(iea.flg_status,
                                   pk_icnp_constant.g_epis_interv_status_requested,
                                   pk_icnp_constant.g_interv_plan_status_requested,
                                   pk_icnp_constant.g_epis_interv_status_ongoing,
                                   pk_icnp_constant.g_interv_plan_status_pending))
                          --AND iea.id_episode_origin IS NOT NULL
                       AND p.id_professional = iea.id_prof
                       AND pc.id_professional(+) = iea.id_prof_close
                    -- </DENORM_SELECT_JOSE_BRITO>
                    UNION*/
                    /* ALL NURSING ACTIONS ASSOCIATED WITH CURRENT EPISODE */
                    SELECT iea.id_icnp_epis_interv,
                            pk_icnp_constant.g_composition_type_action flg_type,
                            iea.id_icnp_epis_diag id_diag,
                            desc_composition(i_lang, iea.id_composition_diag) desc_diag,
                            (SELECT flg_status
                               FROM icnp_epis_diagnosis
                              WHERE id_icnp_epis_diag = iea.id_icnp_epis_diag) flg_status_diag,
                            pk_sysdomain.get_domain('ICNP_EPIS_DIAGNOSIS.FLG_STATUS',
                                                    (SELECT flg_status
                                                       FROM icnp_epis_diagnosis
                                                      WHERE id_icnp_epis_diag = iea.id_icnp_epis_diag),
                                                    i_lang) desc_status_diag,
                            iea.id_icnp_epis_interv id_interv,
                            desc_composition(i_lang, iea.id_composition_interv) desc_interv,
                            iea.flg_time,
                            iea.flg_status,
                            l_id_sys_shortcut || pk_utils.get_status_string(i_lang,
                                                                            i_prof,
                                                                            iea.status_str,
                                                                            iea.status_msg,
                                                                            iea.status_icon,
                                                                            iea.status_flg) status,
                            substr(iea.id_vs, 1, 1) flg_type_vs,
                            to_number(substr(iea.id_vs, 3, 7)) id_vs,
                            decode(iea.dt_close,
                                   NULL,
                                   pk_date_utils.dt_chr_tsz(i_lang, iea.dt_next, i_prof),
                                   pk_date_utils.dt_chr_tsz(i_lang, iea.dt_close, i_prof)) date_target,
                            decode(iea.dt_close,
                                   NULL,
                                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                                    iea.dt_next,
                                                                    i_prof.institution,
                                                                    i_prof.software),
                                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                                    iea.dt_close,
                                                                    i_prof.institution,
                                                                    i_prof.software)) hour_target,
                            nvl(pc.nick_name, p.nick_name) prof,
                            --pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(pc.id_professional, p.id_professional)) AS prof,
                            pk_sysdomain.get_rank(i_lang, 'ICNP_EPIS_INTERVENTION.FLG_STATUS', iea.flg_status) rank_type,
                            decode(iea.flg_status,
                                   pk_icnp_constant.g_epis_diag_status_active,
                                   pk_date_utils.date_send_tsz(i_lang, iea.dt_next, i_prof.institution, i_prof.software),
                                   NULL) to_order_date,
                            decode(iea.flg_status,
                                   pk_icnp_constant.g_epis_diag_status_active,
                                   NULL,
                                   pk_date_utils.date_send_tsz(i_lang, iea.dt_close, i_prof.institution, i_prof.software)) to_order_date_aux,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        nvl(iea.dt_close, iea.dt_next),
                                                        i_prof.institution,
                                                        i_prof.software) dt_ord,
                            iea.id_episode
                    -- <DENORM_SELECT_JOSE_BRITO>
                      FROM interv_icnp_ea iea, icnp_epis_intervention iei, professional p, professional pc
                     WHERE iea.id_episode = i_episode
                       AND iea.id_icnp_epis_interv = iei.id_icnp_epis_interv
                       AND iei.id_episode_destination IS NULL
                       AND p.id_professional = iea.id_prof
                       AND pc.id_professional(+) = iea.id_prof_close)
            -- </DENORM_SELECT_JOSE_BRITO>
             ORDER BY rank_type, to_order_date ASC, to_order_date_aux DESC, 6 ASC;
    
        /* return server time as close as possible to the end of function */
        dt_server := pk_date_utils.to_char_insttimezone(i_prof, current_timestamp, 'yyyymmddHH24miss');
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_INTERV_SUMMARY');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                pk_types.open_my_cursor(o_interventions);
                RETURN FALSE;
            END;
        
    END get_interv_summary;

    FUNCTION get_most_recent_interv
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN icnp_epis_intervention.id_patient%TYPE,
        i_episode  IN icnp_epis_intervention.id_episode%TYPE,
        i_interv   IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_r_interv OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_type episode.id_epis_type%TYPE;
    BEGIN
        l_id_epis_type := pk_episode.get_epis_type(i_lang, i_episode);
    
        OPEN o_r_interv FOR
            SELECT iea.id_icnp_epis_interv, --iei.id_icnp_epis_interv,
                   decode((SELECT h.flg_status
                            FROM icnp_epis_intervention_hist h
                           WHERE h.id_icnp_epis_interv = iea.id_icnp_epis_interv --iei.id_icnp_epis_interv
                             AND h.id_icnp_epis_interv_hist =
                                 (SELECT MAX(id_icnp_epis_interv_hist)
                                    FROM icnp_epis_intervention_hist
                                   WHERE id_icnp_epis_interv = h.id_icnp_epis_interv)),
                          iea.flg_status, --iei.flg_status,
                          pk_message.get_message(i_lang, 'CIPE_T116'),
                          pk_icnp_constant.g_epis_interv_status_requested,
                          decode(iea.flg_status, --decode(iei.flg_status,
                                 pk_icnp_constant.g_epis_interv_status_suspended,
                                 pk_message.get_message(i_lang, 'CIPE_T125'),
                                 pk_message.get_message(i_lang, 'CIPE_T116')),
                          pk_icnp_constant.g_epis_interv_status_suspended,
                          decode(iea.flg_status, --decode(iei.flg_status,
                                 pk_icnp_constant.g_epis_interv_status_requested,
                                 pk_message.get_message(i_lang, 'CIPE_T126'),
                                 pk_message.get_message(i_lang, 'CIPE_T116')),
                          pk_message.get_message(i_lang, 'CIPE_T116')) || ' ' msg_presc,
                   pk_date_utils.dt_chr_tsz(i_lang, iea.dt_icnp_epis_interv, i_prof.institution, i_prof.software) ||
                   ' / ' || pk_date_utils.date_char_hour_tsz(i_lang,
                                                             iea.dt_icnp_epis_interv, --iei.dt_icnp_epis_interv_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) dt_interv,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS prof,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    p.id_professional,
                                                    iea.dt_icnp_epis_interv,
                                                    iea.id_episode) spec_prof,
                   pk_icnp.desc_composition(i_lang, iea.id_composition_interv) ||
                   decode(l_id_epis_type,
                          nvl(t_ti_log.get_epis_type(i_lang,
                                                     i_prof,
                                                     pk_episode.get_epis_type(i_lang, iea.id_episode),
                                                     iea.flg_status,
                                                     iea.id_icnp_epis_interv,
                                                     pk_icnp_constant.g_ti_log_type_interv),
                              pk_episode.get_epis_type(i_lang, iea.id_episode)),
                          '',
                          ' - (' || pk_message.get_message(i_lang,
                                                           profissional(i_prof.id,
                                                                        i_prof.institution,
                                                                        t_ti_log.get_epis_type_soft(i_lang,
                                                                                                    i_prof,
                                                                                                    pk_episode.get_epis_type(i_lang,
                                                                                                                             iea.id_episode),
                                                                                                    iea.flg_status,
                                                                                                    iea.id_icnp_epis_interv,
                                                                                                    pk_icnp_constant.g_ti_log_type_interv)),
                                                           'IMAGE_T009') || ')') desc_interv,
                   decode(iea.flg_status, --decode(iei.flg_status,
                          pk_icnp_constant.g_epis_interv_status_cancelled,
                          NULL,
                          pk_icnp_constant.g_epis_interv_status_discont,
                          NULL,
                          pk_message.get_message(i_lang, 'CIPE_T111') || ' ') msg_status,
                   decode(iea.flg_status, --decode(iei.flg_status,
                          pk_icnp_constant.g_epis_interv_status_cancelled,
                          NULL,
                          pk_icnp_constant.g_epis_interv_status_discont,
                          NULL,
                          pk_sysdomain.get_domain('ICNP_EPIS_INTERVENTION.FLG_STATUS', iea.flg_status, i_lang)) status,
                   pk_message.get_message(i_lang, 'ICNP_T177') || ' ' msg_freq,
                   pk_sysdomain.get_domain('ICNP_EPIS_INTERVENTION.FLG_TIME', iea.flg_time, i_lang) flg_time,
                   pk_sysdomain.get_domain('ICNP_EPIS_INTERVENTION.FLG_TYPE', iea.flg_type, i_lang) flg_type,
                   decode(iea.num_take, --decode(iei.num_take,
                          NULL,
                          NULL,
                          1,
                          iea.num_take || ' ' || pk_message.get_message(i_lang, 'CIPE_T102'),
                          iea.num_take || ' ' || pk_message.get_message(i_lang, 'CIPE_T103')) num_take,
                   decode(iea.interval, --decode(iei.INTERVAL,
                          NULL,
                          NULL,
                          decode(iea.flg_interval_unit,
                                 g_day,
                                 to_char(trunc(iea.interval / 86400)),
                                 g_hour,
                                 to_char(trunc(iea.interval / 3600)),
                                 g_minute,
                                 to_char(trunc(iea.interval / 60)))) || ' ' ||
                   decode(iea.interval,
                          NULL,
                          NULL,
                          decode(iea.flg_interval_unit,
                                 g_day,
                                 decode(iea.interval,
                                        86400,
                                        pk_message.get_message(i_lang, 'CIPE_M004'),
                                        pk_message.get_message(i_lang, 'CIPE_M005')),
                                 g_hour,
                                 decode(iea.interval,
                                        3600,
                                        pk_message.get_message(i_lang, 'CIPE_M008'),
                                        pk_message.get_message(i_lang, 'CIPE_M009')),
                                 g_minute,
                                 decode(iea.interval,
                                        60,
                                        pk_message.get_message(i_lang, 'CIPE_M010'),
                                        pk_message.get_message(i_lang, 'CIPE_M011')))) INTERVAL,
                   decode(iea.duration, NULL, NULL, pk_message.get_message(i_lang, 'CIPE_T124') || ' ') msg_duration,
                   decode(iea.duration,
                          NULL,
                          NULL,
                          decode(iea.flg_duration_unit,
                                 g_day,
                                 to_char(trunc(iea.duration / 86400)),
                                 g_hour,
                                 to_char(trunc(iea.duration / 3600)),
                                 g_minute,
                                 to_char(trunc(iea.duration / 60))) || ' ') ||
                   decode(iea.duration, --decode(iei.duration,
                          NULL,
                          NULL,
                          decode(iea.flg_duration_unit, --decode(iei.flg_duration_unit,
                                 g_day,
                                 decode(iea.duration, --decode(iei.duration,
                                        86400,
                                        pk_message.get_message(i_lang, 'CIPE_M004'),
                                        pk_message.get_message(i_lang, 'CIPE_M005')),
                                 g_hour,
                                 decode(iea.duration, --decode(iei.duration,
                                        3600,
                                        pk_message.get_message(i_lang, 'CIPE_M008'),
                                        pk_message.get_message(i_lang, 'CIPE_M009')),
                                 g_minute,
                                 decode(iea.duration, --decode(iei.duration,
                                        60,
                                        pk_message.get_message(i_lang, 'CIPE_M010'),
                                        pk_message.get_message(i_lang, 'CIPE_M011')))) duration,
                   decode(iea.dt_begin, NULL, NULL, pk_message.get_message(i_lang, 'CIPE_T097') || ' ') msg_begin,
                   decode(iea.dt_begin, --decode(iei.dt_begin_tstz,
                          NULL,
                          NULL,
                          pk_date_utils.dt_chr_tsz(i_lang, iea.dt_begin, i_prof.institution, i_prof.software)) dt_begin,
                   pk_message.get_message(i_lang, 'CIPE_T110') || ' ' msg_diag,
                   pk_icnp.desc_composition(i_lang, iea.id_composition_diag) desc_diag,
                   pk_message.get_message(i_lang, 'CIPE_T078') || ' ' msg_notes,
                   iea.notes, --iei.notes,
                   pk_date_utils.date_send_tsz(i_lang,
                                               iea.dt_icnp_epis_interv, --iei.dt_icnp_epis_interv_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_ord,
                   pk_message.get_message(i_lang, 'ICNP_T176') || ' ' msg_title
              FROM interv_icnp_ea iea, professional p
             WHERE iea.id_composition_interv IN
                   (SELECT iei.id_composition
                      FROM icnp_epis_intervention iei
                     WHERE iei.id_icnp_epis_interv = i_interv)
               AND iea.id_patient = i_patient
               AND iea.id_icnp_epis_interv = i_interv
               AND iea.id_prof = p.id_professional;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_MOST_RECENT_INTERV');
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                pk_types.open_my_cursor(o_r_interv);
                RETURN FALSE;
            END;
        
    END get_most_recent_interv;

    FUNCTION get_compo_dep_clin_serv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE, --ALERT-20717
        i_diag         IN icnp_epis_diagnosis.id_composition%TYPE,
        i_dcs          IN icnp_compo_dcs.id_dep_clin_serv%TYPE,
        o_action_compo OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /** @headcom
        * Obter intervenções sugeridas para um determinado diagnóstico
        *
        * @param      i_lang            number, default language
        * @param      i_prof          object type, health professional
        * @param      i_diag          diagnosis which has predefined actions
        * @param      i_dcs          id dep_clin_serv
        * @param      o_action_compo    list of predefined action compositions
        * @param      o_error           error
        *
        * @return     boolean type, "False" on error or "True" if success
        * @author     ASM
        * @version    0.1
        * @since      2007/05/29
        */
    
        l_gender patient.gender%TYPE;
    
    BEGIN
    
        --CHANGE BY PLLopes 03/04/2009 ALERT-20717
        --Use gender to filter interventions
        g_error := 'prv_pat_get_gender (' || i_id_patient || ');';
        /* get the patient gender based no patient */
        l_gender := prv_pat_get_gender(i_id_patient);
    
        IF i_dcs IS NOT NULL
        THEN
            OPEN o_action_compo FOR
                SELECT DISTINCT ic.id_composition,
                                desc_composition(i_lang, ic.id_composition) desc_composition,
                                ic.flg_repeat,
                                decode(ic.flg_solved, NULL, 'N', 'Y') flg_solved
                  FROM icnp_predefined_action ipa,
                       icnp_composition ic,
                       (SELECT id_composition, id_dep_clin_serv
                          FROM icnp_compo_dcs icdcs
                         WHERE icdcs.id_dep_clin_serv = i_dcs) icdcs
                 WHERE ipa.id_composition_parent = i_diag
                   AND ipa.id_institution = i_prof.institution
                   AND ipa.id_software = i_prof.software
                   AND ipa.flg_available = pk_alert_constant.g_yes
                   AND ipa.id_composition = icdcs.id_composition
                   AND ipa.id_composition = ic.id_composition
                   AND ((i_id_patient IS NOT NULL AND
                       ic.flg_gender IN (l_gender, pk_icnp_constant.g_composition_gender_both)) OR
                       i_id_patient IS NULL) --PLLopes 03/04/2009 ALERT-20717
                 ORDER BY 2;
        ELSE
            OPEN o_action_compo FOR
                SELECT DISTINCT ic.id_composition,
                                desc_composition(i_lang, ic.id_composition) desc_composition,
                                ic.flg_repeat,
                                decode(ic.flg_solved, NULL, 'N', 'Y') flg_solved
                  FROM icnp_predefined_action ipa, icnp_composition ic
                 WHERE ipa.id_composition_parent = i_diag
                   AND ipa.id_institution = i_prof.institution
                   AND ipa.id_software = i_prof.software
                   AND ipa.flg_available = pk_alert_constant.g_yes
                   AND ipa.id_composition = ic.id_composition
                   AND ((i_id_patient IS NOT NULL AND
                       ic.flg_gender IN (l_gender, pk_icnp_constant.g_composition_gender_both)) OR
                       i_id_patient IS NULL) --PLLopes 03/04/2009 ALERT-20717
                 ORDER BY 2;
        END IF;
    
        --CHANGE END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_COMPO_DEP_CLIN_SERV');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                pk_types.open_my_cursor(o_action_compo);
                RETURN FALSE;
            END;
        
    END get_compo_dep_clin_serv;

    /*********************************************************************************
    NAME: GET_ALL_INTERV_LIST
    CREATION INFO: CARLOS FERREIRA 2007/01/19
    GOAL: GET NURSE SUMMARY
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    *********************************************************************************/
    FUNCTION get_all_interv_list
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_interv  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_comm      VARCHAR2(4000);
        l_dt_server VARCHAR2(0050);
    
        TYPE interv1_struct IS RECORD(
            id_icnp_epis_interv NUMBER(24),
            flg_type            VARCHAR2(0050),
            id_diag             NUMBER(24),
            desc_diag           VARCHAR2(4000),
            flg_status_diag     VARCHAR2(0001),
            desc_status_diag    VARCHAR2(0800),
            id_interv           NUMBER(24),
            desc_interv         VARCHAR2(4000),
            flg_time            VARCHAR2(0050),
            flg_status          VARCHAR2(0500),
            status              VARCHAR2(0200),
            flg_type_vs         VARCHAR2(0050),
            id_vs               NUMBER(24),
            date_target         VARCHAR2(0500),
            hour_target         VARCHAR2(0050),
            prof                VARCHAR2(0500),
            dt_ord1             VARCHAR2(0500));
    
        TYPE interv2_struct IS RECORD(
            rank                   NUMBER(6),
            dt_interv_prescription VARCHAR2(0500),
            description            VARCHAR2(4000),
            flg_status             VARCHAR2(0500),
            dt_server              VARCHAR2(0500),
            icon_name1             VARCHAR2(0500));
    
        l_cur1             interv1_struct; --TABLE;
        l_cur2             interv2_struct; --TABLE;
        l_sysdate_char     VARCHAR2(4000);
        l_anl              pk_types.cursor_type;
        l_drug             pk_types.cursor_type;
        l_exam             pk_types.cursor_type;
        l_interv1          pk_types.cursor_type;
        l_interv2          pk_types.cursor_type;
        l_days_warning     sys_message.desc_message%TYPE;
        o_flg_show_warning VARCHAR2(2);
    
        -- tabela temporaria tmp_nurse_summary
        l_ncp_class sys_config.value%TYPE;
    
        error_interv1_summary EXCEPTION;
        error_interv2_summary EXCEPTION;
    
        l_error t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        DELETE tmp_nurse_summary;
    
        l_ncp_class := pk_sysconfig.get_config(pk_nnn_constant.g_config_classification, i_prof);
    
        IF l_ncp_class = pk_nnn_constant.g_classification_icnp
        THEN
            l_comm   := 'GET_INTERV_SUMMARY';
            g_retval := get_interv_summary(i_lang, i_episode, NULL, NULL, i_prof, l_dt_server, l_interv1, l_error);
        ELSE
            -- pk_nnn_constant.g_classification_nnn
            l_comm   := 'GET_EPIS_NNN_SUMMARY';
            g_retval := pk_nnn_core.get_epis_nnn_summary(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_episode => i_episode,
                                                         -- TODO: Nursing summary grid/dashboard just will display Nursing Activities 
                                                         -- until this screen be refactored to support the visualization of other tasks
                                                         i_fltr_type => pk_nnn_constant.g_type_activity,
                                                         o_epis_nnn  => l_interv1);
        END IF;
    
        IF g_retval = FALSE
        THEN
            RAISE error_interv1_summary;
        END IF;
    
        l_comm   := 'GET PROCEDIMENTOS';
        g_retval := pk_edis_summary.get_summary_grid(i_lang,
                                                     i_episode,
                                                     i_prof,
                                                     l_drug,
                                                     l_anl,
                                                     l_interv2,
                                                     l_exam,
                                                     l_days_warning,
                                                     o_flg_show_warning,
                                                     l_error);
    
        IF g_retval = FALSE
        THEN
            RAISE error_interv2_summary;
        END IF;
    
        l_comm := 'GET LOOP 1';
        LOOP
            IF l_ncp_class = pk_nnn_constant.g_classification_icnp
            THEN
                FETCH l_interv1
                    INTO l_cur1.id_icnp_epis_interv,
                         l_cur1.flg_type,
                         l_cur1.id_diag,
                         l_cur1.desc_diag,
                         l_cur1.flg_status_diag,
                         l_cur1.desc_status_diag,
                         l_cur1.id_interv,
                         l_cur1.desc_interv,
                         l_cur1.flg_time,
                         l_cur1.flg_status,
                         l_cur1.status,
                         l_cur1.flg_type_vs,
                         l_cur1.id_vs,
                         l_cur1.date_target,
                         l_cur1.hour_target,
                         l_cur1.prof,
                         l_cur1.dt_ord1;
            ELSE
                -- pk_nnn_constant.g_classification_nnn
                FETCH l_interv1
                    INTO l_cur1.id_icnp_epis_interv,
                         l_cur1.flg_type,
                         l_cur1.desc_interv,
                         l_cur1.flg_time,
                         l_cur1.flg_status,
                         l_cur1.status;
            END IF;
        
            l_comm := 'after fetch 1';
            EXIT WHEN l_interv1%NOTFOUND;
        
            IF l_cur1.flg_status NOT IN
               (pk_icnp_constant.g_epis_diag_status_cancelled, pk_icnp_constant.g_epis_interv_status_discont)
            THEN
                INSERT INTO tmp_nurse_summary
                    (id_interv, tipo, desc_interv, status, dt_server)
                VALUES
                    (l_cur1.id_icnp_epis_interv, 'I', l_cur1.desc_interv, l_cur1.status, l_sysdate_char);
            END IF;
        END LOOP;
    
        l_comm := 'GET LOOP 2';
        LOOP
        
            FETCH l_interv2
                INTO l_cur2.rank,
                     l_cur2.dt_interv_prescription,
                     l_cur2.description,
                     l_cur2.flg_status,
                     l_cur2.dt_server,
                     l_cur2.icon_name1;
        
            l_comm := 'AFTER FETCH 2';
            EXIT WHEN l_interv2%NOTFOUND;
        
            l_comm := 'INSERTING TMP_NURSE_SUMMARY';
            INSERT INTO tmp_nurse_summary
                (id_interv, tipo, desc_interv, status, dt_server)
            VALUES
                (0, 'P', l_cur2.description, l_cur2.icon_name1, l_sysdate_char);
        END LOOP;
    
        OPEN o_interv FOR
            SELECT *
              FROM tmp_nurse_summary;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN error_interv1_summary THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'INTERV1' ||
                                              l_comm || ' / ' || l_error.err_desc;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_ALL_INTERV_LIST');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                --pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_interv);
                RETURN FALSE;
            END;
        
        WHEN error_interv2_summary THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'INTERV2' ||
                                              l_comm || ' / ' || l_error.err_desc;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_ALL_INTERV_LIST');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                --pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_interv);
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || l_comm;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_ALL_INTERV_LIST');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_interv);
                RETURN FALSE;
            END;
        
    END get_all_interv_list;

    -- ##############################################################################

    /*********************************************************************************
    NAME: GET_INTERV_SUMMARY_ACTIVE
    CREATION INFO: CARLOS FERREIRA 2007/01/19
    GOAL: return ALL INTERVENTIONS exception CANCELLED ONES.
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    *********************************************************************************/
    FUNCTION get_interv_summary_active
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_interv  OUT pk_types.cursor_type,
        o_proc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_comm VARCHAR2(4000);
        --l_error     VARCHAR2(4000);
        l_error     t_error_out;
        l_dt_server VARCHAR2(0050);
    
        TYPE interv1_struct IS RECORD(
            id_icnp_epis_interv NUMBER(24),
            flg_type            VARCHAR2(0050),
            id_diag             NUMBER(24),
            desc_diag           VARCHAR2(4000),
            flg_status_diag     VARCHAR2(0001),
            desc_status_diag    VARCHAR2(0800),
            id_interv           NUMBER(24),
            desc_interv         VARCHAR2(4000),
            flg_time            VARCHAR2(0050),
            flg_status          VARCHAR2(0050),
            status              VARCHAR2(0800),
            flg_type_vs         VARCHAR2(0050),
            id_vs               NUMBER(24),
            date_target         VARCHAR2(0500),
            hour_target         VARCHAR2(0050),
            prof                VARCHAR2(0500),
            dt_ord1             VARCHAR2(0500));
    
        l_cur1         interv1_struct; --TABLE;
        l_sysdate_char VARCHAR2(0500);
        l_interv1      pk_types.cursor_type;
    
        error_interv1_summary EXCEPTION;
        -- TABELA TEMPORARIA TMP_NURSE_SUMMARY
    
        l_closed_task_filter_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_cfg_closed_task_filter  NUMBER(24);
        l_epis_flg_status         episode.flg_status%TYPE;
        l_ncp_class               sys_config.value%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        DELETE tmp_nurse_summary;
    
        l_ncp_class := pk_sysconfig.get_config(pk_nnn_constant.g_config_classification, i_prof);
    
        IF l_ncp_class = pk_nnn_constant.g_classification_icnp
        THEN
            l_comm   := 'GET_INTERV_SUMMARY';
            g_retval := get_interv_summary(i_lang, i_episode, NULL, NULL, i_prof, l_dt_server, l_interv1, l_error);
        ELSE
            -- pk_nnn_constant.g_classification_nnn
            l_comm   := 'GET_EPIS_NNN_SUMMARY';
            g_retval := pk_nnn_core.get_epis_nnn_summary(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_episode => i_episode,
                                                         -- TODO: Nursing summary grid/dashboard just will display Nursing Activities 
                                                         -- until this screen be refactored to support the visualization of other tasks
                                                         i_fltr_type => pk_nnn_constant.g_type_activity,
                                                         o_epis_nnn  => l_interv1);
        END IF;
    
        IF g_retval = FALSE
        THEN
            RAISE error_interv1_summary;
        END IF;
    
        l_comm := 'L_INTERV1';
    
        LOOP
            IF l_ncp_class = pk_nnn_constant.g_classification_icnp
            THEN
                FETCH l_interv1
                    INTO l_cur1.id_icnp_epis_interv,
                         l_cur1.flg_type,
                         l_cur1.id_diag,
                         l_cur1.desc_diag,
                         l_cur1.flg_status_diag,
                         l_cur1.desc_status_diag,
                         l_cur1.id_interv,
                         l_cur1.desc_interv,
                         l_cur1.flg_time,
                         l_cur1.flg_status,
                         l_cur1.status,
                         l_cur1.flg_type_vs,
                         l_cur1.id_vs,
                         l_cur1.date_target,
                         l_cur1.hour_target,
                         l_cur1.prof,
                         l_cur1.dt_ord1;
            ELSE
                -- pk_nnn_constant.g_classification_nnn
                FETCH l_interv1
                    INTO l_cur1.id_icnp_epis_interv,
                         l_cur1.flg_type,
                         l_cur1.desc_interv,
                         l_cur1.flg_time,
                         l_cur1.flg_status,
                         l_cur1.status;
            END IF;
        
            EXIT WHEN l_interv1%NOTFOUND;
        
            IF l_cur1.flg_status != pk_icnp_constant.g_epis_diag_status_cancelled
            THEN
                INSERT INTO tmp_nurse_summary
                    (id_interv, tipo, desc_interv, status, dt_server)
                VALUES
                    (l_cur1.id_icnp_epis_interv, 'I', l_cur1.desc_interv, l_cur1.status, l_sysdate_char);
            END IF;
        END LOOP;
    
        l_comm := 'OPEN O_INTERV';
        OPEN o_interv FOR
            SELECT *
              FROM tmp_nurse_summary;
    
        COMMIT;
    
        IF NOT pk_sysconfig.get_config(pk_edis_summary.g_cfg_closed_task_filter, i_prof, l_cfg_closed_task_filter)
        THEN
            RAISE g_exception;
        END IF;
    
        l_closed_task_filter_tstz := g_sysdate_tstz - numtodsinterval(to_number(l_cfg_closed_task_filter), 'DAY');
    
        SELECT flg_status
          INTO l_epis_flg_status
          FROM episode
         WHERE id_episode = i_episode;
    
        IF NOT pk_edis_summary.get_summary_grid_proc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => i_episode,
                                                     i_flg_stat_epis      => l_epis_flg_status,
                                                     i_filter_tstz        => l_closed_task_filter_tstz,
                                                     i_filter_status_proc => pk_edis_summary.g_procedures_status,
                                                     i_filter_status_nur  => pk_edis_summary.g_nursing_status,
                                                     i_filter_status_oris => pk_sr_clinical_info.g_filter_status_sr_posit,
                                                     o_proc               => o_proc,
                                                     o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN error_interv1_summary THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || l_comm ||
                                              ' / ' || l_error.err_desc;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_INTERV_SUMMARY_ACTIVE');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                --pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || l_comm;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_INTERV_SUMMARY_ACTIVE');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                --pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_interv);
                RETURN FALSE;
            END;
        
    END get_interv_summary_active;
    --
    FUNCTION get_cipe_search
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_type      IN icnp_composition.flg_type%TYPE,
        i_nurse_tea IN icnp_composition.flg_nurse_tea%TYPE DEFAULT NULL,
        i_folder    IN icnp_folder.id_folder%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        i_search    IN VARCHAR2,
        o_info      OUT pk_types.cursor_type,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /** @headcom
        * Public Function. Pesquisa
        *
        * @param      I_LANG              Língua registada como preferência do profissional
        * @param      I_PROF              ID do profissional, software e instituição
        * @param      I_TYPE              Flag: D - Diagnósticos; A - Intervenções
        * @param      I_NURSE_TEA         Ensinos de enfermagem: (Y)es ou (N)o
        * @param      I_FOLDER            ID da especialidade
        * @param      I_PATIENT           ID do paciente
        * @param      I_SEARCH            String a pesquisar; se for NULL, devolve todos
        * @param      O_INFO              Resultados da pesquisa
        * @param      O_ERROR             erro
        * @return     boolean
        * @author     ASM
        * @version    0.1
        * @since      2007/04/24
        */
    
        -- CHANGED BY Tiago Silva IN 2007/07/30
    
        aux_sql  VARCHAR2(2000);
        l_count  NUMBER := 1;
        l_gender patient.gender%TYPE;
        --l_icnp_exception EXCEPTION;
    
    BEGIN
        g_error  := 'PRV_PAT_GET_GENDER (' || i_patient || ');';
        l_gender := prv_pat_get_gender(i_patient);
    
        IF i_folder IS NULL
        THEN
            IF i_search IS NOT NULL
            THEN
                -- retornar todos
            
                g_error := 'COUNT I_SEARCH';
                aux_sql := 'SELECT COUNT (*) ' || 'FROM (SELECT DISTINCT DCS.ID_CLINICAL_SERVICE ID_CLINICAL_SERVICE ' ||
                           '      FROM ICNP_COMPOSITION   IC, ICNP_COMPO_DCS   ICD, ' ||
                           '           DEP_CLIN_SERV    DCS, ' || '           DEPARTMENT       D, ' ||
                           '           SOFTWARE_DEPT    SD, ' || '           CLINICAL_SERVICE CS, ' ||
                           '           TABLE(PK_TRANSLATION.GET_SEARCH_TRANSLATION(:i_lang, :i_search, :i_field)) ST ' ||
                           '      WHERE DCS.ID_DEP_CLIN_SERV = ICD.ID_DEP_CLIN_SERV ' ||
                           '      AND D.ID_DEPARTMENT = DCS.ID_DEPARTMENT ' || '      AND SD.ID_DEPT = D.ID_DEPT ' ||
                           '      AND SD.ID_SOFTWARE = :id_software ' ||
                           '      AND CS.ID_CLINICAL_SERVICE = DCS.ID_CLINICAL_SERVICE ' ||
                           '      AND DCS.ID_DEPARTMENT IN (SELECT D.ID_DEPARTMENT ' ||
                           '                                FROM DEPARTMENT D ' ||
                           '                                WHERE D.ID_INSTITUTION = :id_institution) ' ||
                           '      AND ST.CODE_TRANSLATION = CS.CODE_CLINICAL_SERVICE)';
            
                g_error := 'GET EXECUTE IMMEDIATE 1 ' || aux_sql;
                EXECUTE IMMEDIATE aux_sql
                    INTO l_count
                    USING i_lang, i_search, 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE', i_prof.software, i_prof.institution;
            
            END IF;
        ELSE
            IF i_search IS NOT NULL
            THEN
                -- retornar todos
                IF i_folder < 0
                THEN
                    g_error := 'COUNT I_SEARCH';
                    aux_sql := 'SELECT  COUNT (*) ' || 'FROM ICNP_COMPOSITION IC, ' || '     ICNP_COMPO_DCS   ICD, ' ||
                               '     TABLE(pk_translation.get_search_translation(:i_lang, :i_search, :i_field)) ST ' ||
                               'WHERE IC.FLG_AVAILABLE = :4 ' ||
                               'AND ((:ID_PATIENT is not null and IC.FLG_GENDER IN (:5, :6)) OR :ID_PATIENT IS NULL) ' ||
                               'AND IC.FLG_TYPE = NVL(:8, IC.FLG_TYPE) ' ||
                               'AND ICD.ID_COMPOSITION = IC.ID_COMPOSITION ' ||
                               'AND ICD.ID_DEP_CLIN_SERV IN (SELECT DCS.ID_DEP_CLIN_SERV ' ||
                               '                             FROM DEP_CLIN_SERV DCS, ' ||
                               '                                  DEPARTMENT    D, ' ||
                               '                                  DEPT          DP, ' ||
                               '                                  SOFTWARE_DEPT SD ' ||
                               '                             WHERE D.ID_DEPARTMENT = DCS.ID_DEPARTMENT ' ||
                               '                             AND D.ID_INSTITUTION = :2 ' ||
                               '                             AND DP.ID_DEPT = D.ID_DEPT ' ||
                               '                             AND SD.ID_DEPT = DP.ID_DEPT ' ||
                               '                             AND SD.ID_SOFTWARE = :1) ' ||
                               'AND IC.CODE_ICNP_COMPOSITION = ST.CODE_TRANSLATION ';
                
                    g_error := 'GET EXECUTE IMMEDIATE 2' || aux_sql;
                    EXECUTE IMMEDIATE aux_sql
                        INTO l_count
                        USING i_lang, i_search, 'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION', pk_alert_constant.g_yes, i_patient, l_gender, pk_icnp_constant.g_composition_gender_both, i_patient, i_type, i_prof.institution, i_prof.software;
                ELSE
                    g_error := 'COUNT I_SEARCH';
                    aux_sql := 'SELECT COUNT(*) ' || '  FROM (SELECT DISTINCT ic.id_composition ' ||
                               '          FROM icnp_composition ic, icnp_compo_dcs icd, dep_clin_serv dcs, department d, software_dept sd, table(pk_translation.get_search_translation(:i_lang, :i_search, :i_field)) st ' ||
                               '         WHERE icd.id_composition = ic.id_composition ' ||
                               '           AND dcs.id_dep_clin_serv = icd.id_dep_clin_serv ' ||
                               '           AND dcs.id_dep_clin_serv = :folder ' ||
                               '           AND d.id_department = dcs.id_department ' ||
                               '           AND d.id_institution = :institution ' ||
                               '           AND sd.id_dept = d.id_dept ' || '           AND sd.id_software = :software ' ||
                               '           AND ic.flg_available = :yes ' ||
                               '           AND ((:patient IS NOT NULL AND ic.flg_gender IN (:gender, :both)) OR :patient IS NULL) ' ||
                               '           AND ic.flg_type = nvl(:type, ic.flg_type) ' ||
                               '           AND ic.code_icnp_composition = st.code_translation)';
                
                    g_error := 'GET EXECUTE IMMEDIATE 3';
                    EXECUTE IMMEDIATE aux_sql
                        INTO l_count
                        USING i_lang, i_search, 'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION', i_folder, i_prof.institution, i_prof.software, pk_alert_constant.g_yes, i_patient, l_gender, pk_icnp_constant.g_composition_gender_both, i_patient, i_type, i_lang, i_search;
                END IF;
            END IF;
        END IF;
    
        g_error := 'NO RESULT';
        IF l_count = 0
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'ERROR_LABEL_05');
            o_msg       := pk_message.get_message(i_lang, 'CIPE_M006');
            o_button    := 'R';
            pk_types.open_my_cursor(o_info);
            RETURN TRUE;
        ELSE
            o_flg_show := 'N';
        END IF;
    
        IF i_folder IS NULL
        THEN
            IF i_search IS NULL
            THEN
                -- retornar todos
                g_error := 'GET O_INFO';
                OPEN o_info FOR
                    SELECT DISTINCT dcs.id_clinical_service id_clinical_service,
                                    pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clinical_service,
                                    0 rank
                      FROM icnp_compo_dcs icd, dep_clin_serv dcs, department d, software_dept sd, clinical_service cs
                     WHERE dcs.id_dep_clin_serv = icd.id_dep_clin_serv
                       AND d.id_department = dcs.id_department
                       AND sd.id_dept = d.id_dept
                       AND sd.id_software = i_prof.software
                       AND cs.id_clinical_service = dcs.id_clinical_service
                       AND dcs.id_department IN (SELECT d.id_department
                                                   FROM department d
                                                  WHERE d.id_institution = i_prof.institution)
                    UNION
                    SELECT -1 id_clinical_service,
                           pk_message.get_message(i_lang, i_prof, 'TodasEspecialidadesCIPE') desc_clinical_service,
                           -1
                      FROM dual
                     ORDER BY rank ASC, desc_clinical_service;
            ELSE
                -- pesquisa por palavra
                g_error := 'GET O_INFO';
                OPEN o_info FOR
                    SELECT DISTINCT dcs.id_clinical_service id_clinical_service,
                                    st.desc_translation     desc_clinical_service,
                                    0                       rank
                      FROM icnp_compo_dcs icd,
                           dep_clin_serv dcs,
                           department d,
                           software_dept sd,
                           clinical_service cs,
                           TABLE(pk_translation.get_search_translation(i_lang,
                                                                       i_search,
                                                                       'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE')) st
                     WHERE dcs.id_dep_clin_serv = icd.id_dep_clin_serv
                       AND d.id_department = dcs.id_department
                       AND sd.id_dept = d.id_dept
                       AND sd.id_software = i_prof.software
                       AND cs.id_clinical_service = dcs.id_clinical_service
                       AND dcs.id_department IN (SELECT d.id_department
                                                   FROM department d
                                                  WHERE d.id_institution = i_prof.institution)
                       AND cs.code_clinical_service = st.code_translation
                     ORDER BY rank ASC, desc_clinical_service;
            END IF;
        ELSE
            IF i_search IS NULL
            THEN
                -- retornar todos
                IF i_folder < 0
                THEN
                    g_error := 'GET O_INFO';
                    OPEN o_info FOR
                        SELECT DISTINCT ic.id_composition,
                                        desc_composition(i_lang, ic.id_composition) desc_composition,
                                        ic.flg_repeat,
                                        decode(ic.flg_solved, NULL, 'N', 'Y') flg_solved
                          FROM icnp_composition ic, icnp_compo_dcs icd
                         WHERE ic.flg_available = pk_alert_constant.g_yes
                           AND ((i_patient IS NOT NULL AND
                               ic.flg_gender IN (l_gender, pk_icnp_constant.g_composition_gender_both)) OR
                               i_patient IS NULL)
                           AND ic.flg_type = nvl(i_type, ic.flg_type)
                           AND icd.id_composition = ic.id_composition
                           AND icd.id_dep_clin_serv IN
                               (SELECT dcs.id_dep_clin_serv
                                  FROM dep_clin_serv dcs, department d, dept dp, software_dept sd
                                 WHERE d.id_department = dcs.id_department
                                   AND d.id_institution = i_prof.institution
                                   AND dp.id_dept = d.id_dept
                                   AND sd.id_dept = dp.id_dept
                                   AND sd.id_software = i_prof.software)
                         ORDER BY desc_composition;
                ELSE
                    g_error := 'GET O_INFO';
                    OPEN o_info FOR
                        SELECT DISTINCT ic.id_composition,
                                        desc_composition(i_lang, ic.id_composition) desc_composition,
                                        ic.flg_repeat,
                                        decode(ic.flg_solved, NULL, 'N', 'Y') flg_solved
                          FROM icnp_composition ic,
                               icnp_compo_dcs   icd,
                               dep_clin_serv    dcs,
                               department       d,
                               software_dept    sd
                         WHERE icd.id_composition = ic.id_composition
                           AND dcs.id_dep_clin_serv = i_folder
                           AND d.id_department = dcs.id_department
                           AND d.id_institution = i_prof.institution
                           AND sd.id_dept = d.id_dept
                           AND sd.id_software = i_prof.software
                           AND ic.flg_available = pk_alert_constant.g_yes
                           AND ((i_patient IS NOT NULL AND
                               ic.flg_gender IN (l_gender, pk_icnp_constant.g_composition_gender_both)) OR
                               i_patient IS NULL)
                           AND ic.flg_type = nvl(i_type, ic.flg_type)
                         ORDER BY desc_composition;
                
                END IF;
            ELSE
                -- pesquisa por palavra
                IF i_folder < 0
                THEN
                    g_error := 'GET O_INFO';
                    OPEN o_info FOR
                        SELECT DISTINCT ic.id_composition,
                                        st.desc_translation desc_composition,
                                        ic.flg_repeat,
                                        decode(ic.flg_solved, NULL, 'N', 'Y') flg_solved
                          FROM icnp_composition ic,
                               icnp_compo_dcs icd,
                               TABLE(pk_translation.get_search_translation(i_lang,
                                                                           i_search,
                                                                           'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION')) st
                         WHERE ic.flg_available = pk_alert_constant.g_yes
                           AND ((i_patient IS NOT NULL AND
                               ic.flg_gender IN (l_gender, pk_icnp_constant.g_composition_gender_both)) OR
                               i_patient IS NULL)
                           AND ic.flg_type = nvl(i_type, ic.flg_type)
                           AND icd.id_composition = ic.id_composition
                           AND icd.id_dep_clin_serv IN
                               (SELECT dcs.id_dep_clin_serv
                                  FROM dep_clin_serv dcs, department d, dept dp, software_dept sd
                                 WHERE d.id_department = dcs.id_department
                                   AND d.id_institution = i_prof.institution
                                   AND dp.id_dept = d.id_dept
                                   AND sd.id_dept = dp.id_dept
                                   AND sd.id_software = i_prof.software)
                           AND ic.code_icnp_composition = st.code_translation
                         ORDER BY desc_composition;
                
                ELSE
                    g_error := 'GET O_INFO';
                    OPEN o_info FOR
                        SELECT DISTINCT ic.id_composition,
                                        st.desc_translation desc_composition,
                                        ic.flg_repeat,
                                        decode(ic.flg_solved, NULL, 'N', 'Y') flg_solved
                          FROM icnp_composition ic,
                               icnp_compo_dcs icd,
                               dep_clin_serv dcs,
                               department d,
                               software_dept sd,
                               TABLE(pk_translation.get_search_translation(i_lang,
                                                                           i_search,
                                                                           'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION')) st
                         WHERE icd.id_composition = ic.id_composition
                           AND dcs.id_dep_clin_serv = icd.id_dep_clin_serv
                           AND dcs.id_dep_clin_serv = i_folder
                           AND d.id_department = dcs.id_department
                           AND d.id_institution = i_prof.institution
                           AND sd.id_dept = d.id_dept
                           AND sd.id_software = i_prof.software
                           AND ic.flg_available = pk_alert_constant.g_yes
                           AND ((i_patient IS NOT NULL AND
                               ic.flg_gender IN (l_gender, pk_icnp_constant.g_composition_gender_both)) OR
                               i_patient IS NULL)
                           AND ic.flg_type = nvl(i_type, ic.flg_type)
                           AND ic.code_icnp_composition = st.code_translation
                         ORDER BY desc_composition;
                
                END IF;
            END IF;
        END IF;
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_CIPE_SEARCH');
                -- undo changes quando aplicável-> só faz ROLLBACK
                pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                --pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_info);
                RETURN FALSE;
            END;
        
    END get_cipe_search;

    FUNCTION get_interv_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /** @headcom
        * Obter lista de "tipos" para requisição
        *
        * @param      i_lang            Preferred language ID for this professional
        * @param      i_prof            Object (professional ID, institution ID, software ID)
        * @param      o_type           cursor
        * @param      o_error           erro
        *
        * @return     boolean type, "False" on error or "True" if success
        * @author     ASM
        * @version    0.1
        * @since      2007/05/17
        */
    
    BEGIN
        g_error := 'GET CURSOR';
    
        OPEN o_type FOR
            SELECT val AS data,
                   rank,
                   desc_val AS label,
                   decode(pk_sysconfig.get_config('FLG_TAKE_TYPE', i_prof.institution, i_prof.software), val, 'Y', 'N') flg_default
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = pk_icnp_constant.g_domain_epis_interv_type
               AND flg_available = pk_alert_constant.g_yes
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_INTERV_TYPE');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                --pk_alert_exceptions.reset_error_state();
                pk_types.open_my_cursor(o_type);
                RETURN FALSE;
            END;
        
    END get_interv_type;

    FUNCTION get_interv_interval
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_interval OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*
        * Obter lista de "tipos" para requisição
        *
        * @param      i_lang      Preferred language ID for this professional
        * @param      i_prof      Object (professional ID, institution ID, software ID)
        * @param      o_interval  Cursor
        * @param      o_error     Error
        *
        * @return     boolean type, "False" on error or "True" if success
        * @author     Ana Matos
        * @version    0.1
        * @since      2007/09/06
        */
    
        l_edis NUMBER;
        l_ubu  NUMBER;
    
    BEGIN
        l_edis := pk_sysconfig.get_config('SOFTWARE_ID_EDIS', i_prof);
        -- José Brito 16/07/2008 Acrescentar UBU
        l_ubu := pk_sysconfig.get_config('SOFTWARE_ID_UBU', i_prof);
    
        IF i_prof.software IN (l_edis, l_ubu)
        THEN
            g_error := 'GET CURSOR';
            OPEN o_interval FOR
                SELECT val AS data, rank, desc_val AS label, NULL flg_default
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = pk_icnp_constant.g_domain_deprecated_interval
                   AND flg_available = pk_alert_constant.g_yes
                   AND val != 'D'
                 ORDER BY rank;
        ELSE
            g_error := 'GET CURSOR';
            OPEN o_interval FOR
                SELECT val AS data, rank, desc_val AS label, NULL flg_default
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = pk_icnp_constant.g_domain_deprecated_interval
                   AND flg_available = pk_alert_constant.g_yes
                 ORDER BY rank;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_INTERV_INTERVAL');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                --pk_alert_exceptions.reset_error_state();
                pk_types.open_my_cursor(o_interval);
                RETURN FALSE;
            END;
        
    END get_interv_interval;

    FUNCTION get_icnp_interv_duration_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_duration OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*
        * Obter lista de "tipos" para requisição
        *
        * @param      i_lang      Preferred language ID for this professional
        * @param      i_prof      Object (professional ID, institution ID, software ID)
        * @param      o_duration  Cursor
        * @param      o_error     Error
        *
        * @return     boolean type, "False" on error or "True" if success
        * @author     Ana Matos
        * @version    0.1
        * @since      2007/09/06
        */
    
        l_edis NUMBER;
        l_ubu  NUMBER;
    
    BEGIN
        l_edis := pk_sysconfig.get_config('SOFTWARE_ID_EDIS', i_prof);
        -- José Brito 16/07/2008 Acrescentar UBU
        l_ubu := pk_sysconfig.get_config('SOFTWARE_ID_UBU', i_prof);
    
        IF i_prof.software IN (l_edis, l_ubu)
        THEN
            g_error := 'GET CURSOR';
            OPEN o_duration FOR
                SELECT val AS data, rank, desc_val AS label, NULL flg_default
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = pk_icnp_constant.g_domain_deprecated_duration
                   AND flg_available = pk_alert_constant.g_yes
                   AND val != 'D'
                 ORDER BY rank;
        ELSE
            g_error := 'GET CURSOR';
            OPEN o_duration FOR
                SELECT val AS data, rank, desc_val AS label, NULL flg_default
                  FROM sys_domain
                 WHERE id_language = i_lang
                   AND code_domain = pk_icnp_constant.g_domain_deprecated_duration
                   AND flg_available = pk_alert_constant.g_yes
                 ORDER BY rank;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_ICNP_INTERV_DURATION_LIST');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                --pk_alert_exceptions.reset_error_state();
                pk_types.open_my_cursor(o_duration);
                RETURN FALSE;
            END;
        
    END get_icnp_interv_duration_list;

    FUNCTION get_count_and_first
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_viewer_area IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        o_num_occur   OUT NUMBER,
        o_desc_first  OUT VARCHAR2,
        o_code_first  OUT VARCHAR2,
        o_dt_first    OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list  pk_types.cursor_type;
        l_count NUMBER := 0;
        l_str   VARCHAR2(4000);
        l_icnp_exception EXCEPTION;
    
        l_task_type sys_message.desc_message%TYPE;
    
    BEGIN
    
        g_error := 'GET ORDERED LIST';
        IF get_ordered_list(i_lang, i_prof, i_patient, 'N', i_viewer_area, i_episode, l_list, o_error)
        THEN
            LOOP
                FETCH l_list
                    INTO l_str, o_code_first, o_desc_first, o_dt_first, l_str, l_str, l_str, l_str, l_str, l_task_type;
                EXIT WHEN l_list%NOTFOUND;
                l_count := l_count + 1;
            END LOOP;
        
            LOOP
                FETCH l_list
                    INTO l_str, l_str, l_str, l_str, l_str, l_str, l_str, l_str, l_str, l_task_type;
                EXIT WHEN l_list%NOTFOUND;
                l_count := l_count + 1;
            END LOOP;
        
            o_num_occur := l_count;
        
            RETURN TRUE;
        ELSE
            RAISE l_icnp_exception;
        END IF;
    
    EXCEPTION
        WHEN l_icnp_exception THEN
            DECLARE
                l_error_out t_error_out := t_error_out(ora_sqlcode         => SQLCODE,
                                                       ora_sqlerrm         => SQLERRM,
                                                       err_desc            => '',
                                                       err_action          => NULL,
                                                       log_id              => NULL,
                                                       err_instance_id_out => NULL,
                                                       msg_title           => NULL,
                                                       flg_msg_type        => NULL);
            BEGIN
                l_error_out.err_desc := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                        'GET_COUNT_AND_FIRST / ' || g_error || ' / ' || SQLERRM;
                o_error              := l_error_out;
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_COUNT_AND_FIRST');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                --pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
    END get_count_and_first;

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_viewer_lim_tasktime_icnp sys_config.value%TYPE := pk_sysconfig.get_config('VIEWER_LIM_TASKTIME_ICNP', i_prof);
        l_viewer_area              VARCHAR2(200);
        l_episode                  table_number;
    
        l_task_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EHR_VIEWER_T065');
    
        -- ALERT-164737
        CURSOR c_episode IS
            SELECT e.id_episode
              FROM episode e
             WHERE e.id_visit = pk_episode.get_id_visit(i_episode);
        -- end ALERT-164737         
    
    BEGIN
    
        -- ALERT-164737  
        l_viewer_area := i_viewer_area;
        OPEN c_episode;
        FETCH c_episode BULK COLLECT
            INTO l_episode;
        -- end ALERT-164737     
    
        g_error := 'OPEN CURSOR';
        OPEN o_ordered_list FOR
            SELECT ied.id_icnp_epis_diag id,
                   'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || ied.id_composition code_description,
                   decode(i_translate,
                          'N',
                          NULL,
                          pk_translation.get_translation(i_lang,
                                                         'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || ied.id_composition)) description,
                   ied.dt_icnp_epis_diag_tstz dt_req_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ied.dt_icnp_epis_diag_tstz, i_prof) dt_req,
                   ied.flg_status,
                   '|I|||' || pk_sysdomain.get_img(i_lang, 'ICNP_EPIS_DIAGNOSIS.FLG_STATUS', ied.flg_status) || '|||||' desc_status,
                   NULL rank,
                   NULL rank_order,
                   l_task_title task_title
              FROM icnp_epis_diagnosis ied
             WHERE ied.id_patient = i_patient
               AND ied.flg_status NOT IN
                   (pk_icnp_constant.g_epis_diag_status_cancelled, pk_icnp_constant.g_epis_diag_status_revaluated)
                  -- ALERT-164737
               AND ((l_viewer_area = pk_hibernate_intf.g_ordered_list_ehr AND
                   ied.flg_status = pk_icnp_constant.g_epis_diag_status_resolved) OR
                   (l_viewer_area = pk_hibernate_intf.g_ordered_list_wfl AND
                   ied.flg_status NOT IN
                   (pk_icnp_constant.g_epis_diag_status_resolved, pk_icnp_constant.g_epis_diag_status_cancelled) AND
                   ied.id_episode IN (SELECT *
                                          FROM TABLE(l_episode))))
               AND trunc(months_between(SYSDATE, ied.dt_icnp_epis_diag_tstz) / 12) <= l_viewer_lim_tasktime_icnp
            -- end ALERT-164737
             ORDER BY dt_req_tstz ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --PLLopes 10/03/2009 - Inicialization of object for input
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_error     VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                -- setting error content into input object
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_ICNP', 'GET_ORDERED_LIST');
                -- undo changes quando aplicável-> só faz ROLLBACK
                --pk_utils.undo_changes;
                -- execute error processing
                g_retval := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error  := l_error_out;
                --reset error state
                --pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
        
    END get_ordered_list;

    /********************************************************************************************
    * Returns a list of diagnoses according to the professional's category (physician/nurse)
    *
    * @param      i_lang    Language
    * @param      i_prof    Professional
    * @param      i_episode Episode
    * @param      o_diag    Cursor with the diagnoses
    * @param      o_error   Error message
    *
    * @return     List of diagnoses according to professional category
    *
    * @author     Joao Martins
    * @version    2.6.0.1
    * @since      2010/03/17
    *********************************************************************************************/
    FUNCTION get_diagnoses
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        PROCEDURE physician(o_diag OUT pk_types.cursor_type) IS
            l_differ             pk_types.cursor_type;
            l_id_diagnosis       diagnosis.id_diagnosis%TYPE;
            l_desc_diagnosis     pk_translation.t_desc_translation;
            l_code_icd           diagnosis.code_icd%TYPE;
            l_id_alert_diagnosis alert_diagnosis.id_alert_diagnosis%TYPE;
        BEGIN
        
            IF NOT pk_diagnosis.get_associated_diagnosis(i_lang   => i_lang,
                                                         i_prof   => i_prof,
                                                         i_epis   => i_episode,
                                                         o_differ => l_differ,
                                                         o_error  => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            DELETE tbl_temp;
        
            INSERT INTO tbl_temp
                (num_1, num_2, vc_1)
            VALUES
                (-1, 10, pk_message.get_message(i_lang, i_prof, 'PROCEDURES_T073'));
        
            LOOP
                FETCH l_differ
                    INTO l_id_diagnosis, l_desc_diagnosis, l_code_icd, l_id_alert_diagnosis;
                EXIT WHEN l_differ%NOTFOUND;
            
                INSERT INTO tbl_temp
                    (num_1, num_2, vc_1, num_3)
                VALUES
                    (l_id_diagnosis, 20, l_desc_diagnosis, l_id_alert_diagnosis);
            END LOOP;
        
            OPEN o_diag FOR
                SELECT num_1 data, vc_1 label, 'I' flg_selected, num_3 id_alert_diagnosis
                  FROM tbl_temp
                 ORDER BY num_2 ASC, vc_1 ASC;
        END physician;
    
        PROCEDURE nurse(o_diag OUT pk_types.cursor_type) IS
            l_diag             pk_types.cursor_type;
            l_id_composition   diagnosis.id_diagnosis%TYPE;
            l_desc_composition pk_translation.t_desc_translation;
            l_flg_status       icnp_epis_diagnosis.flg_status%TYPE;
            l_dump             VARCHAR2(4000);
        
        BEGIN
            IF NOT get_diag_summary(i_lang      => i_lang,
                                    i_episode   => i_episode,
                                    i_diag      => NULL,
                                    i_interv    => NULL,
                                    i_status    => NULL,
                                    i_prof      => i_prof,
                                    o_diagnoses => l_diag,
                                    o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            DELETE tbl_temp;
        
            INSERT INTO tbl_temp
                (num_1, num_2, vc_1)
            VALUES
                (-1, 10, pk_message.get_message(i_lang, i_prof, 'PROCEDURES_T073'));
        
            LOOP
                FETCH l_diag
                    INTO l_dump,
                         l_dump,
                         l_desc_composition,
                         l_dump,
                         l_dump,
                         l_dump,
                         l_dump,
                         l_flg_status,
                         l_dump,
                         l_id_composition,
                         l_dump,
                         l_dump,
                         l_dump;
                EXIT WHEN l_diag%NOTFOUND;
            
                INSERT INTO tbl_temp
                    (num_1, num_2, vc_1, vc_2)
                VALUES
                    (l_id_composition, 20, l_desc_composition, l_flg_status);
            END LOOP;
        
            OPEN o_diag FOR
                SELECT num_1 data, vc_1 label
                  FROM tbl_temp
                 WHERE num_2 = 10
                    OR vc_2 IN
                       (pk_icnp_constant.g_epis_diag_status_active, pk_icnp_constant.g_epis_diag_status_revaluated)
                 ORDER BY num_2 ASC, vc_1 ASC;
        END nurse;
    BEGIN
        g_error := 'WHICH CATEGORY';
        CASE pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof)
            WHEN pk_alert_constant.g_cat_type_doc THEN
                physician(o_diag => o_diag);
            WHEN pk_alert_constant.g_cat_type_nurse THEN
                nurse(o_diag => o_diag);
            ELSE
                pk_types.open_my_cursor(o_diag);
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROVIDER_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_diag);
            RETURN FALSE;
    END get_diagnoses;

    /********************************************************************************************
     *   
     *  Returns the id of the profile of the logged professional.  
     *
     * @param i_lang                 Language ID
     * @param i_prof                 The ALERT professional calling this function
     * @param o_id_profile_template  ID of the corresponding PROFILE_TEMPLATE
     * @param o_error   
     *
     * @return                         true or false 
     *
     * @author                          RicardoNunoAlmeida
     * @version                         2.5.0.7.6.1
     * @since                           2010/02/10
    **********************************************************************************************/
    FUNCTION get_prof_profile_template
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_id_profile_template OUT prof_profile_template.id_profile_template%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_id_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PROF_PROFILE_TEMPLATE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_prof_profile_template;

    /********************************************************************************************
     * Returns the ICNP version that is configured for the institution/software
     *
     * @param i_lang                 Language ID
     * @param i_prof                 The ALERT professional calling this function
     *
     * @return                       ID_ICNP_VERSION
     *
     * @author                       Joao Martins
     * @version                      2.5.1.1
     * @since                        2010/09/23
    **********************************************************************************************/
    FUNCTION get_icnp_version
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER IS
    BEGIN
        RETURN pk_sysconfig.get_config('ICNP_VERSION', i_prof);
    END get_icnp_version;

    /*********************************************************************************************
     * Returns the validation flags for the version that is configured
     *
     * @param i_lang                 Language ID
     * @param i_prof                 The ALERT professional calling this function
     *
     * @return                       ID_ICNP_VERSION
     *
     * @author                       Joao Martins
     * @version                      2.5.1.1
     * @since                        2010/09/28
    **********************************************************************************************/
    FUNCTION get_icnp_validation_flags
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_info FOR
            SELECT flg_action, flg_focus, flg_judgement
              FROM icnp_version
             WHERE id_icnp_version = get_icnp_version(i_lang, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_ICNP_VALIDATION_FLAGS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_icnp_validation_flags;

    FUNCTION get_icnp_validation_flag
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_flg  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_action    icnp_version.flg_action%TYPE;
        l_focus     icnp_version.flg_focus%TYPE;
        l_judgement icnp_version.flg_judgement%TYPE;
    BEGIN
        SELECT flg_action, flg_focus, flg_judgement
          INTO l_action, l_focus, l_judgement
          FROM icnp_version
         WHERE id_icnp_version = get_icnp_version(i_lang, i_prof);
    
        CASE i_flg
            WHEN pk_icnp_constant.g_icnp_action THEN
                RETURN l_action;
            WHEN pk_icnp_constant.g_icnp_focus THEN
                RETURN l_focus;
            WHEN pk_icnp_constant.g_icnp_judgement THEN
                RETURN l_judgement;
            ELSE
                RETURN NULL;
        END CASE;
    END get_icnp_validation_flag;

    /*********************************************************************************************
     * Insert EA
     *
     * @param i_lang                 Language ID
     * @param i_prof                 The ALERT professional calling this function
     *
     * @return                       ID_ICNP_VERSION
     *
     * @author                       Joao Martins
     * @version                      2.5.1.1
     * @since                        2010/09/28
    **********************************************************************************************/
    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
        o_error                    t_error_out;
        l_viewer_lim_tasktime_icnp sys_config.value%TYPE := pk_sysconfig.get_config('VIEWER_LIM_TASKTIME_ICNP', i_prof);
    BEGIN
        UPDATE viewer_ehr_ea vee
           SET (num_diag_icnp, code_diag_icnp, dt_diag_icnp) =
               (SELECT tab.num_diag_icnp, tab.code_diag_icnp, tab.dt_diag_icnp
                  FROM (SELECT id_patient, code_description code_diag_icnp, COUNT num_diag_icnp, dt_req_tstz dt_diag_icnp
                          FROM (SELECT row_number() over(PARTITION BY id_patient ORDER BY dt_icnp_epis_diag_tstz DESC, ied.id_composition DESC) rn,
                                        id_patient,
                                        'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || ied.id_composition code_description,
                                        '' description,
                                        ied.dt_icnp_epis_diag_tstz dt_req_tstz,
                                        COUNT(0) over(PARTITION BY id_patient) COUNT
                                   FROM icnp_epis_diagnosis ied
                                  WHERE --ied.flg_status NOT IN (g_canceled, g_revaluated))
                                  ied.flg_status = pk_icnp_constant.g_epis_diag_status_resolved
                               AND trunc(months_between(SYSDATE, ied.dt_icnp_epis_diag_tstz) / 12) <=
                                  l_viewer_lim_tasktime_icnp)
                         WHERE rn = 1) tab
                 WHERE tab.id_patient = vee.id_patient) log errors INTO err$_viewer_ehr_ea(to_char(SYSDATE)) reject LIMIT unlimited;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_ICNP_VALIDATION_FLAGS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
    END upd_viewer_ehr_ea;

    /**********************************************************************************************
    *  This fuction will update the table viewer_ehr_ea for the specified patients.
    *
    * @param I_LANG                   The id language
    * @param I_TABLE_ID_PATIENTS      Table of id patients to be clean.
    * @param O_ERROR                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         ANA COELHO
    * @version                        1.0
    * @since                          27-APR-2011
    **********************************************************************************************/
    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_patients IN table_number,
        i_prof              IN profissional,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_viewer_lim_tasktime_icnp sys_config.value%TYPE := pk_sysconfig.get_config('VIEWER_LIM_TASKTIME_ICNP', i_prof);
    BEGIN
    
        UPDATE viewer_ehr_ea vee
           SET (num_diag_icnp, code_diag_icnp, dt_diag_icnp) =
               (SELECT tab.num_diag_icnp, tab.code_diag_icnp, tab.dt_diag_icnp
                  FROM (SELECT id_patient, code_description code_diag_icnp, COUNT num_diag_icnp, dt_req_tstz dt_diag_icnp
                          FROM (SELECT row_number() over(PARTITION BY id_patient ORDER BY dt_icnp_epis_diag_tstz DESC, ied.id_composition DESC) rn,
                                        id_patient,
                                        'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || ied.id_composition code_description,
                                        '' description,
                                        ied.dt_icnp_epis_diag_tstz dt_req_tstz,
                                        COUNT(0) over(PARTITION BY id_patient) COUNT
                                   FROM icnp_epis_diagnosis ied
                                  WHERE --ied.flg_status NOT IN (g_canceled, g_revaluated)
                                  ied.flg_status = pk_icnp_constant.g_epis_diag_status_resolved
                               AND trunc(months_between(SYSDATE, ied.dt_icnp_epis_diag_tstz) / 12) <=
                                  l_viewer_lim_tasktime_icnp
                               AND id_patient IN (SELECT column_value
                                                   FROM TABLE(i_table_id_patients)))
                         WHERE rn = 1) tab
                 WHERE tab.id_patient = vee.id_patient
                   AND id_patient IN (SELECT
                                      /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                       column_value
                                        FROM TABLE(i_table_id_patients) pat))
         WHERE vee.id_patient IN (SELECT
                                  /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                   column_value
                                    FROM TABLE(i_table_id_patients) pat);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'UPDATE VIEWER_EHR_EA',
                                              'ALERT',
                                              g_package_name,
                                              'UPD_VIEWER_EHR_EA_PAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_viewer_ehr_ea_pat;

    /**********************************************************************************************
    *  This function removes all information about ICNP registers (RESET).
    
    *
    * @param i_lang                   Language ID
    * @param i_prof                   The ALERT professional calling this function
    * @param i_patient                Table of id_patient to be clean.
    * @param i_episode                Table of id_episode to be clean.
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1
    * @since                          28-APR-2011
    **********************************************************************************************/
    FUNCTION clear_icnp_reset
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient_count NUMBER;
        l_episode_count NUMBER;
    
        l_id_icnp_interv_plan table_number;
        l_id_icnp_epis_diag   table_number;
        l_id_icnp_epis_interv table_number;
    
        --l_error t_error_out;
    BEGIN
    
        l_patient_count := i_patient.count;
        l_episode_count := i_episode.count;
    
        -- checks if the delete process can be executed
        IF l_patient_count = 0
           AND l_episode_count = 0
        THEN
            g_error := 'EMPTY ARRAYS FOR I_PATIENT AND I_EPISODE';
            RETURN FALSE;
        END IF;
    
        ------------------------------------------------------------------------    
        --ICNP_INTERV_PLAN
        ------------------------------------------------------------------------
        -- selects the lists of all icnp_interv_plan ids to be removed
        g_error := 'icnp_interv_plan BULK COLLECT ERROR';
        SELECT iip.id_icnp_interv_plan
          BULK COLLECT
          INTO l_id_icnp_interv_plan
          FROM icnp_interv_plan iip
         WHERE iip.id_episode_write IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                         *
                                          FROM TABLE(i_episode) epis);
    
        -- remove data from NCH_EFFECTIVE_INTERVENTION
        g_error := 'NCH_EFFECTIVE_INTERVENTION DELETE ERROR';
        DELETE FROM nch_effective_intervention nei
         WHERE nei.id_incp_interv_plan IN (SELECT /*+ OPT_ESTIMATE(table ipp rows = 1)*/
                                            *
                                             FROM TABLE(l_id_icnp_interv_plan) iip);
    
        -- remove data from icnp_interv_plan
        g_error := 'icnp_interv_plan DELETE ERROR';
        DELETE FROM icnp_interv_plan iip
         WHERE iip.id_icnp_interv_plan IN (SELECT /*+ OPT_ESTIMATE(table iip rows = 1)*/
                                            *
                                             FROM TABLE(l_id_icnp_interv_plan) iip);
    
        ------------------------------------------------------------------------                                        
        --ICNP_EPIS_INTERVENTION_HIST
        ------------------------------------------------------------------------
        -- remove data from ICNP_EPIS_INTERVENTION_HIST
        g_error := 'ICNP_EPIS_INTERVENTION_HIST DELETE ERROR';
        DELETE icnp_epis_intervention_hist ieih
         WHERE ieih.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                    *
                                     FROM TABLE(i_episode) epis)
            OR (ieih.id_episode IS NULL AND
               ieih.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                     *
                                      FROM TABLE(i_patient) pat));
    
        ------------------------------------------------------------------------                                        
        --ICNP_EPIS_DIAGNOSIS
        ------------------------------------------------------------------------
    
        -- selects the lists of all icnp_interv_plan ids to be removed
        g_error := 'ICNP_EPIS_DIAGNOSIS BULK COLLECT ERROR';
        SELECT ied.id_icnp_epis_diag
          BULK COLLECT
          INTO l_id_icnp_epis_diag
          FROM icnp_epis_diagnosis ied
         WHERE ied.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                   *
                                    FROM TABLE(i_episode) epis)
            OR (ied.id_episode IS NULL AND
               ied.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                    *
                                     FROM TABLE(i_patient) pat));
    
        -- remove data from ICNP_EPIS_DIAGNOSIS_HIST
        g_error := 'ICNP_EPIS_DIAGNOSIS_HIST DELETE ERROR';
        DELETE FROM icnp_epis_diagnosis_hist iedh
         WHERE iedh.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                    *
                                     FROM TABLE(i_episode) epis)
            OR (iedh.id_episode IS NULL AND
               iedh.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                     *
                                      FROM TABLE(i_patient) pat));
    
        -- remove data from INTERV_ICNP_EA
        g_error := 'INTERV_ICNP_EA DELETE ERROR';
        DELETE FROM interv_icnp_ea iiea
         WHERE iiea.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                    *
                                     FROM TABLE(i_episode) epis)
            OR (iiea.id_episode IS NULL AND
               iiea.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                     *
                                      FROM TABLE(i_patient) pat));
    
        -- remove data from ICNP_SUGGEST_INTERV_HIST
        g_error := 'ICNP_SUGGEST_INTERV_HIST DELETE ERROR';
        DELETE FROM icnp_suggest_interv_hist isih
         WHERE isih.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                    *
                                     FROM TABLE(i_episode) epis)
            OR (isih.id_episode IS NULL AND
               isih.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                     *
                                      FROM TABLE(i_patient) pat));
    
        -- remove data from ICNP_SUGGEST_INTERV
        g_error := 'ICNP_SUGGEST_INTERV DELETE ERROR';
        DELETE FROM icnp_suggest_interv isi
         WHERE isi.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                   *
                                    FROM TABLE(i_episode) epis)
            OR (isi.id_episode IS NULL AND
               isi.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                    *
                                     FROM TABLE(i_patient) pat));
    
        -- remove data from icnp_epis_dg_int_hist
        g_error := 'icnp_epis_dg_int_hist DELETE ERROR';
        DELETE FROM icnp_epis_dg_int_hist iedih
         WHERE iedih.id_icnp_epis_diag IN (SELECT /*+ OPT_ESTIMATE(table ied rows = 1)*/
                                            *
                                             FROM TABLE(l_id_icnp_epis_diag) ied);
    
        -- remove data from ICNP_EPIS_DIAG_INTERV
        g_error := 'ICNP_EPIS_DIAG_INTERV DELETE ERROR';
        DELETE FROM icnp_epis_diag_interv iedi
         WHERE iedi.id_icnp_epis_diag IN (SELECT /*+ OPT_ESTIMATE(table ied rows = 1)*/
                                           *
                                            FROM TABLE(l_id_icnp_epis_diag) ied);
    
        -- remove data from icnp_epis_dg_int_hist
        g_error := 'icnp_epis_dg_int_hist DELETE ERROR';
        DELETE FROM icnp_epis_dg_int_hist iedih
         WHERE iedih.id_icnp_epis_diag IN
               (SELECT ied.id_icnp_epis_diag
                  FROM icnp_epis_diagnosis ied
                 WHERE ied.id_parent IN (SELECT /*+ OPT_ESTIMATE(table ied rows = 1)*/
                                          *
                                           FROM TABLE(l_id_icnp_epis_diag) ied));
    
        -- remove data from ICNP_EPIS_DIAG_INTERV parent
        g_error := 'ICNP_EPIS_DIAG_INTERV DELETE ERROR (parent)';
        DELETE FROM icnp_epis_diag_interv iedi
         WHERE iedi.id_icnp_epis_diag IN
               (SELECT ied.id_icnp_epis_diag
                  FROM icnp_epis_diagnosis ied
                 WHERE ied.id_parent IN (SELECT /*+ OPT_ESTIMATE(table ied rows = 1)*/
                                          *
                                           FROM TABLE(l_id_icnp_epis_diag) ied));
    
        -- remove data from INTERV_ICNP_EA
        g_error := 'INTERV_ICNP_EA DELETE ERROR';
        DELETE FROM interv_icnp_ea iiea
         WHERE iiea.id_icnp_epis_diag IN (SELECT /*+ OPT_ESTIMATE(table ied rows = 1)*/
                                           *
                                            FROM TABLE(l_id_icnp_epis_diag) ied);
    
        -- remove data from INTERV_ICNP_EA (parent)
        g_error := 'INTERV_ICNP_EA DELETE ERROR (parent)';
        DELETE FROM interv_icnp_ea iiea
         WHERE iiea.id_icnp_epis_diag IN
               (SELECT ied.id_icnp_epis_diag
                  FROM icnp_epis_diagnosis ied
                 WHERE ied.id_parent IN (SELECT /*+ OPT_ESTIMATE(table ied rows = 1)*/
                                          *
                                           FROM TABLE(l_id_icnp_epis_diag) ied));
    
        -- remove data from ICNP_EPIS_DIAGNOSIS id_parent
        g_error := 'ICNP_EPIS_DIAGNOSIS id_parent DELETE ERROR';
        DELETE FROM icnp_epis_diagnosis ied
         WHERE ied.id_parent IN (SELECT /*+ OPT_ESTIMATE(table ied rows = 1)*/
                                  *
                                   FROM TABLE(l_id_icnp_epis_diag) ied);
    
        -- remove data from ICNP_EPIS_DIAGNOSIS
        g_error := 'ICNP_EPIS_DIAGNOSIS DELETE ERROR';
        DELETE FROM icnp_epis_diagnosis ied
         WHERE ied.id_icnp_epis_diag IN (SELECT /*+ OPT_ESTIMATE(table ied rows = 1)*/
                                          *
                                           FROM TABLE(l_id_icnp_epis_diag) ied);
    
        ------------------------------------------------------------------------                                        
        --ICNP_EPIS_INTERVENTION
        ------------------------------------------------------------------------
        -- selects the lists of all ICNP_EPIS_INTERVENTION ids to be removed
        g_error := 'ICNP_EPIS_INTERVENTION BULK COLLECT ERROR';
        SELECT iei.id_icnp_epis_interv
          BULK COLLECT
          INTO l_id_icnp_epis_interv
          FROM icnp_epis_intervention iei
         WHERE iei.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                   *
                                    FROM TABLE(i_episode) epis)
            OR (iei.id_episode IS NULL AND
               iei.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                    *
                                     FROM TABLE(i_patient) pat));
    
        -- remove data from NCH_EFFECTIVE_INTERVENTION
        g_error := 'NCH_EFFECTIVE_INTERVENTION DELETE ERROR';
        DELETE FROM nch_effective_intervention nei
         WHERE nei.id_incp_interv_plan IN
               (SELECT iei.id_icnp_interv_plan
                  FROM icnp_interv_plan iei
                 WHERE iei.id_icnp_epis_interv IN (SELECT /*+ OPT_ESTIMATE(table ipp rows = 1)*/
                                                    *
                                                     FROM TABLE(l_id_icnp_epis_interv) iip));
    
        -- remove data from icnp_epis_dg_int_hist
        g_error := 'icnp_epis_dg_int_hist DELETE ERROR';
        DELETE FROM icnp_epis_dg_int_hist iedih
         WHERE iedih.id_icnp_epis_interv IN (SELECT /*+ OPT_ESTIMATE(table iei rows = 1)*/
                                              *
                                               FROM TABLE(l_id_icnp_epis_interv) iei);
    
        -- remove data from ICNP_EPIS_DIAG_INTERV 
        g_error := 'ICNP_EPIS_DIAG_INTERV DELETE ERROR ';
        DELETE FROM icnp_epis_diag_interv iedi
         WHERE iedi.id_icnp_epis_interv IN (SELECT /*+ OPT_ESTIMATE(table iei rows = 1)*/
                                             *
                                              FROM TABLE(l_id_icnp_epis_interv) iei);
    
        -- remove data from ICNP_EPIS_TASK
        g_error := 'ICNP_EPIS_TASK DELETE ERROR';
        DELETE icnp_epis_task iet
         WHERE iet.id_icnp_epis_interv IN (SELECT /*+ OPT_ESTIMATE(table iei rows = 1)*/
                                            *
                                             FROM TABLE(l_id_icnp_epis_interv) iei);
    
        -- remove data from ICNP_INTERV_PLAN
        g_error := 'ICNP_INTERV_PLAN DELETE ERROR';
        DELETE icnp_interv_plan iei
         WHERE iei.id_icnp_epis_interv IN (SELECT /*+ OPT_ESTIMATE(table iei rows = 1)*/
                                            *
                                             FROM TABLE(l_id_icnp_epis_interv) iei);
    
        -- remove data from ICNP_EPIS_INTERVENTION
        g_error := 'ICNP_EPIS_INTERVENTION DELETE ERROR';
        DELETE icnp_epis_intervention iei
         WHERE iei.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                   *
                                    FROM TABLE(i_episode) epis)
            OR (iei.id_episode IS NULL AND
               iei.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                    *
                                     FROM TABLE(i_patient) pat));
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CLEAR_ICNP_RESET',
                                              o_error);
            RETURN FALSE;
    END clear_icnp_reset;

    /********************************************************************************************
    * Get advanced input application areas
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      o_areas   List of application_areas
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/04/16
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_adv_input_areas
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_areas OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name          VARCHAR2(50) := 'GET_ADV_INPUT_AREAS';
        l_templates          pk_types.cursor_type;
        l_template_list      table_number;
        l_template_name_list table_varchar;
        l_template_count     NUMBER(24);
    
    BEGIN
    
        g_retval := pk_touch_option.get_doc_template(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_patient   => NULL,
                                                     i_episode   => NULL,
                                                     i_doc_area  => pk_icnp_constant.g_doc_area_icnp,
                                                     i_context   => -1,
                                                     o_templates => l_templates,
                                                     o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        FETCH l_templates BULK COLLECT
            INTO l_template_list, l_template_name_list;
        CLOSE l_templates;
        l_template_count := l_template_list.count;
    
        OPEN o_areas FOR
            SELECT data, label, editable
              FROM (SELECT DISTINCT iaa.area AS data,
                                    pk_translation.get_translation(i_lang, iaa.area_code) AS label,
                                    'Y' AS editable,
                                    CASE iaa.area
                                        WHEN 'TEMPLATE' THEN
                                         l_template_count
                                        ELSE
                                         1
                                    END AS datas
                      FROM icnp_application_area iaa
                     WHERE iaa.id_institution IN (0, i_prof.institution)
                       AND iaa.id_software IN (0, i_prof.software))
             WHERE datas >= 1
             ORDER BY 2, 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_areas);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_areas);
                RETURN FALSE;
            END;
    END get_adv_input_areas;

    /********************************************************************************************
    * Get advanced input application area parameters
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_area    Area code
    * @param      o_params  List of application_area parameters
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/04/16
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_adv_input_parameters
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_area   IN icnp_application_area.area%TYPE,
        o_params OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name          VARCHAR2(50) := 'GET_ADV_INPUT_PARAMETERS';
        l_templates          pk_types.cursor_type;
        l_template_list      table_number;
        l_template_name_list table_varchar;
    
    BEGIN
        IF i_area != 'TEMPLATE'
        THEN
            OPEN o_params FOR
                SELECT iaa.id_application_area AS data,
                       pk_translation.get_translation(i_lang, iaa.parameter_desc) AS label,
                       'Y' AS editable
                  FROM icnp_application_area iaa
                 WHERE iaa.id_institution IN (0, i_prof.institution)
                   AND iaa.id_software IN (0, i_prof.software)
                   AND upper(iaa.area) = upper(i_area)
                 ORDER BY 2, 1;
        ELSE
            g_retval := pk_touch_option.get_doc_template(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_patient   => NULL,
                                                         i_episode   => NULL,
                                                         i_doc_area  => pk_icnp_constant.g_doc_area_icnp,
                                                         i_context   => -1,
                                                         o_templates => l_templates,
                                                         o_error     => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception;
            END IF;
        
            FETCH l_templates BULK COLLECT
                INTO l_template_list, l_template_name_list;
            CLOSE l_templates;
        
            OPEN o_params FOR
                SELECT -1 * id.column_value AS data, des.column_value AS label, 'Y' AS editable
                  FROM (SELECT /*+ opt_estimate(table t rows=10)*/
                         rownum rown, t.column_value
                          FROM TABLE(l_template_list) t) id
                  JOIN (SELECT /*+ opt_estimate(table t rows=10)*/
                         rownum rown, t.column_value
                          FROM TABLE(l_template_name_list) t) des
                    ON id.rown = des.rown;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_params);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_params);
                RETURN FALSE;
            END;
    END get_adv_input_parameters;

    /**
     * Converts a raw data record sent by ux, with the data of one icnp instruction
     * 
     * @param i_values Array with the values for one record. Each position corresponds
     *                 to a predfined type of information.
     * 
     * @return Typed record with the data of one 
     *
     * @author Cristina Oliveira
     * @version 1.0
     * @since 19/06/2013
    */
    FUNCTION populate_icnp_instrunction(i_values table_varchar) RETURN t_icnp_instrunction IS
    
        -- Function name
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'populate_icnp_instrunction';
        -- Indexes of the fields stored in table_varchar
        c_idx_order_recurr_option_id CONSTANT PLS_INTEGER := 1;
        c_idx_flg_prn                CONSTANT PLS_INTEGER := 2;
        c_idx_prn_notes              CONSTANT PLS_INTEGER := 3;
        c_idx_flg_time               CONSTANT PLS_INTEGER := 4;
    
        -----
        -- Variables
        l_data_ux_inst t_icnp_instrunction;
    
    BEGIN
    
        log_debug(c_func_name || '()', c_func_name);
    
        -- Load the raw data sent by ux into a typed record
        l_data_ux_inst.id_order_recurr_option := to_number(i_values(c_idx_order_recurr_option_id));
        l_data_ux_inst.flg_prn                := i_values(c_idx_flg_prn);
        l_data_ux_inst.prn_notes              := i_values(c_idx_prn_notes);
        l_data_ux_inst.flg_time               := i_values(c_idx_flg_time);
    
        RETURN l_data_ux_inst;
    END;

    /********************************************************************************************
    * Set ICNP instructions
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_soft    Software list
    * @param      i_inst    instructions list
    * @param      i_comp    Composition ID
    * @param      o_error   Error
    *
    * @return               boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author               Cristina Oliveira
    * @version              1
    * @since                2013/03/19
    * @dependents           PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                       PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION set_icnp_instructions_msi
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_soft  IN table_number,
        i_inst  IN table_table_varchar,
        i_comp  IN icnp_composition.id_composition%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(50) := 'SET_ICNP_INSTRUCTIONS_MSI';
        -- Typed i_inst record
        l_data_icnp_instr t_icnp_instrunction;
        -- Associative array to control the recurrences that were already made definitive
        l_recurr_processed_coll   t_order_recurr_coll;
        l_order_recurr_rec        t_order_recurr_rec;
        l_recurr_definit_ids_coll table_number := table_number();
    
        l_processed_plan t_processed_plan;
        -- Aux variables
        l_found VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
    BEGIN
    
        IF (i_soft IS NOT NULL AND i_soft.count > 0)
           AND (i_inst IS NOT NULL AND i_inst.count > 0)
        THEN
            g_error := 'LOOP by software ' || i_soft.count;
        
            --loop by software list
            FOR i IN i_soft.first .. i_soft.last
            LOOP
                IF i_soft(i) IS NOT NULL
                THEN
                
                    IF i_inst(i) IS NOT NULL
                    THEN
                        g_error := 'Instruction iteration ' || i;
                    
                        -- Converts the raw data record into a typed record
                        l_data_icnp_instr := populate_icnp_instrunction(i_values => i_inst(i));
                    
                        BEGIN
                            SELECT pk_alert_constant.g_yes
                              INTO l_found
                              FROM icnp_default_instructions_msi dim
                             WHERE dim.id_composition = i_comp
                               AND dim.id_institution = i_prof.institution
                               AND dim.id_software = i_soft(i);
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_found := pk_alert_constant.g_no;
                        END;
                    
                        -- Set a temporary order recurrence plan as definitive (final status)
                        log_debug('set_order_recurr_plan / l_data_ux_rec.id_order_recurr_plan: ' ||
                                  l_data_icnp_instr.id_order_recurr_option,
                                  l_func_name);
                    
                        l_order_recurr_rec := set_order_recurr_plan(i_lang                     => i_lang,
                                                                    i_prof                     => i_prof,
                                                                    i_recurr_plan_id           => l_data_icnp_instr.id_order_recurr_option,
                                                                    io_recurr_processed_coll   => l_recurr_processed_coll,
                                                                    io_recurr_definit_ids_coll => l_recurr_definit_ids_coll,
                                                                    io_precessed_plans         => l_processed_plan);
                    
                        IF l_found = pk_alert_constant.g_yes
                        THEN
                            UPDATE icnp_default_instructions_msi
                               SET id_order_recurr_option = l_order_recurr_rec.id_order_recurr_option,
                                   flg_prn                = l_data_icnp_instr.flg_prn,
                                   prn_notes              = l_data_icnp_instr.prn_notes,
                                   flg_time               = l_data_icnp_instr.flg_time
                             WHERE id_composition = i_comp
                               AND id_institution = i_prof.institution
                               AND id_software = i_soft(i);
                        ELSE
                            INSERT INTO icnp_default_instructions_msi
                                (id_composition,
                                 id_order_recurr_option,
                                 flg_prn,
                                 prn_notes,
                                 flg_time,
                                 id_institution,
                                 id_software,
                                 id_market,
                                 flg_available)
                            VALUES
                                (i_comp,
                                 l_order_recurr_rec.id_order_recurr_option,
                                 l_data_icnp_instr.flg_prn,
                                 l_data_icnp_instr.prn_notes,
                                 l_data_icnp_instr.flg_time,
                                 i_prof.institution,
                                 i_soft(i),
                                 0, --id_market
                                 pk_alert_constant.g_yes);
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_icnp_instructions_msi;
    /********************************************************************************************
    * Returns the name of the sections only if exists any information registred
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_summary_page        Summary page ID
    * @param i_episode                Episode ID
    * @param o_doc_area_nurse_desc    Cursor containing the sections with info                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2013/10/16
    **********************************************************************************************/

    FUNCTION get_nurse_sections
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_summary_page     IN summary_page.id_summary_page%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        o_label_nurse_eval    OUT VARCHAR2,
        o_doc_area_nurse_desc OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        c_sections    pk_summary_page.t_cur_section;
        l_sections    pk_summary_page.t_coll_section;
        l_aux_section pk_icnp.t_rec_aux_section;
        l_exists      VARCHAR2(1 CHAR);
        l_patient     patient.id_patient%TYPE;
        l_visit       visit.id_visit%TYPE;
        l_episode     episode.id_episode%TYPE;
        l_scope       VARCHAR2(1 CHAR);
        g_other_exception EXCEPTION;
        l_doc_area_desc table_varchar := table_varchar();
    BEGIN
        l_patient := pk_episode.get_id_patient(i_episode);
        IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_summary_page => i_id_summary_page,
                                                         i_pat             => l_patient,
                                                         o_sections        => c_sections,
                                                         o_error           => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_episode,
                                              i_scope_type => pk_alert_constant.g_scope_type_episode,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
        FETCH c_sections BULK COLLECT
            INTO l_sections;
        CLOSE c_sections;
    
        l_doc_area_desc := table_varchar();
        FOR i IN 1 .. l_sections.count
        LOOP
            l_aux_section.translated_code := l_sections(i).translated_code;
            l_aux_section.id_doc_area     := l_sections(i).id_doc_area;
            l_aux_section.flg_scope_type  := l_sections(i).flg_scope_type;
        
            IF NOT pk_touch_option.get_doc_area_exists(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_doc_area_list => table_number(l_aux_section.id_doc_area),
                                                       i_scope         => CASE l_aux_section.flg_scope_type
                                                                              WHEN pk_alert_constant.g_scope_type_episode THEN
                                                                               l_episode
                                                                              WHEN pk_alert_constant.g_scope_type_visit THEN
                                                                               l_visit
                                                                              WHEN pk_alert_constant.g_scope_type_patient THEN
                                                                               l_patient
                                                                              ELSE
                                                                               NULL
                                                                          END,
                                                       i_scope_type    => l_aux_section.flg_scope_type,
                                                       o_flg_data      => l_exists,
                                                       o_error         => o_error)
            
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_exists = pk_alert_constant.g_yes
            THEN
                l_doc_area_desc.extend;
                l_doc_area_desc(l_doc_area_desc.count) := l_aux_section.translated_code;
            END IF;
        
        END LOOP;
    
        o_doc_area_nurse_desc := l_doc_area_desc;
        o_label_nurse_eval    := pk_message.get_message(i_lang, 'NURSE_SUMMARY_T006');
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_nurse_sections',
                                              o_error);
            RETURN FALSE;
        
    END get_nurse_sections;

    FUNCTION get_icnp_tooltip
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_task  IN NUMBER,
        i_flg_type IN VARCHAR2,
        i_screen   IN NUMBER
        
    ) RETURN VARCHAR2 IS
    
        CURSOR c_icnp_task IS
            SELECT b.flg_type icnp_type,
                   pk_translation.get_translation(i_lang, b.code_icnp_composition) name,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => a.dt_begin_tstz,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) dt_begin,
                   (SELECT pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_interv_status, a.flg_status, i_lang)
                      FROM dual) status,
                   pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => a.id_prof) prof,
                   a.notes notes,
                   pk_icnp_fo.get_interv_instructions(i_lang, i_prof, i_id_task) instr,
                   NULL dt_modification,
                   a.flg_status flg_status,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => a.dt_close_tstz,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) dt_end
              FROM icnp_epis_intervention a
             INNER JOIN icnp_composition b
                ON a.id_composition = b.id_composition
             WHERE a.id_icnp_epis_interv = i_id_task
               AND i_flg_type = 2
            UNION ALL
            SELECT b.flg_type icnp_type,
                   pk_translation.get_translation(i_lang, b.code_icnp_composition) name,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => diag.dt_icnp_epis_diag_tstz,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) dt_begin,
                   (SELECT pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_diag_status, diag.flg_status, i_lang) status
                      FROM dual) status,
                   pk_prof_utils.get_name(i_lang    => i_lang,
                                          i_prof_id => (nvl(diag.id_prof_last_update, diag.id_professional))) prof,
                   diag.notes notes,
                   NULL instr,
                   decode((SELECT COUNT(1)
                            FROM icnp_epis_diagnosis_hist h
                           WHERE h.id_icnp_epis_diag = diag.id_icnp_epis_diag
                             AND h.id_composition != diag.id_composition),
                          0,
                          NULL,
                          pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                      i_date => diag.dt_last_update,
                                                      i_inst => i_prof.institution,
                                                      i_soft => i_prof.software)) dt_modification,
                   NULL flg_status,
                   NULL dt_end
              FROM icnp_epis_diagnosis diag
             INNER JOIN icnp_composition b
                ON diag.id_composition = b.id_composition
             WHERE diag.id_icnp_epis_diag = i_id_task
               AND i_flg_type = 1;
    
        l_icnp_task c_icnp_task%ROWTYPE;
    
        l_type_tlp     VARCHAR2(30 CHAR);
        l_name_tlp     VARCHAR2(300 CHAR);
        l_state_tlp    VARCHAR2(100 CHAR);
        l_dt_begin_tlp VARCHAR2(100 CHAR);
        l_prof_tlp     VARCHAR2(500 CHAR);
        l_notes_tlp    VARCHAR2(2000 CHAR);
        l_instr_tlp    VARCHAR2(500 CHAR);
        l_enter        VARCHAR2(15 CHAR) := '<br> <br>';
        l_result_tlp   VARCHAR2(2000 CHAR);
        l_dt_modif_tlp VARCHAR2(100 CHAR);
        l_dt_end_tlp   VARCHAR2(100 CHAR);
    
    BEGIN
    
        OPEN c_icnp_task;
        FETCH c_icnp_task
            INTO l_icnp_task;
        CLOSE c_icnp_task;
    
        CASE l_icnp_task.icnp_type
            WHEN pk_icnp_constant.g_composition_type_diagnosis THEN
                l_type_tlp := pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T001');
            ELSE
                l_type_tlp := pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T057');
        END CASE;
    
        l_name_tlp     := '<b>' || l_type_tlp || ': </b>' || l_icnp_task.name;
        l_state_tlp    := '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T004') || ': ' ||
                          '</b>' || l_icnp_task.status;
        l_dt_begin_tlp := '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T134') || '</b> ' ||
                          l_icnp_task.dt_begin;
        l_prof_tlp     := '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROF_TEAMS_M019') ||
                          ': </b>' || l_icnp_task.prof;
        l_notes_tlp := CASE
                           WHEN l_icnp_task.notes IS NOT NULL THEN
                            l_enter || '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T062') ||
                            ': </b>' || l_icnp_task.notes
                       END;
        l_instr_tlp    := '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'ICNP_T221') || ': </b>' ||
                          l_icnp_task.instr;
    
        l_dt_modif_tlp := CASE
                              WHEN l_icnp_task.dt_modification IS NOT NULL THEN
                               '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'LAST_MODIFICATION_DATE') ||
                               ': </b>' || l_icnp_task.dt_modification
                          END;
    
        l_dt_end_tlp := CASE
                            WHEN l_icnp_task.flg_status = pk_icnp_constant.g_epis_interv_status_executed THEN
                             l_enter || '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T087') ||
                             ': </b>' || l_icnp_task.dt_end
                        END;
    
        CASE l_icnp_task.icnp_type
            WHEN pk_icnp_constant.g_composition_type_diagnosis THEN
                l_result_tlp := l_name_tlp || l_enter || l_state_tlp || l_enter || l_dt_begin_tlp || l_enter ||
                                l_prof_tlp || l_enter || l_dt_modif_tlp || l_notes_tlp;
            ELSE
                IF i_screen = 1
                THEN
                    l_result_tlp := l_name_tlp || l_enter || l_state_tlp || l_enter || l_dt_begin_tlp || l_dt_end_tlp ||
                                    l_enter || l_prof_tlp || l_notes_tlp;
                ELSE
                    l_result_tlp := l_name_tlp || l_enter || l_state_tlp || l_enter || l_dt_begin_tlp || l_dt_end_tlp ||
                                    l_enter || l_prof_tlp || l_enter || l_instr_tlp || l_notes_tlp;
                END IF;
        END CASE;
    
        RETURN l_result_tlp;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, i_id_task || ' - ' || i_flg_type);
            RETURN '';
        
    END get_icnp_tooltip;

    FUNCTION get_icnp_exec_tooltip
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task      IN NUMBER,
        i_id_diag      IN NUMBER,
        i_id_interv    IN NUMBER,
        i_id_plan      IN NUMBER,
        i_id_diag_hist IN NUMBER,
        i_flg_type     IN VARCHAR2
        
    ) RETURN VARCHAR2 IS
    
        CURSOR c_icnp_task IS
            SELECT b.flg_type icnp_type,
                   pk_translation.get_translation(i_lang, b.code_icnp_composition) name,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => decode(p.flg_status,
                                                                pk_icnp_constant.g_interv_plan_status_cancelled,
                                                                p.dt_cancel_tstz,
                                                                decode(p.dt_take_tstz,
                                                                       NULL,
                                                                       decode(p.dt_plan_tstz,
                                                                              NULL,
                                                                              a.dt_begin_tstz,
                                                                              p.dt_plan_tstz),
                                                                       p.dt_take_tstz)),
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) dt_begin,
                   (SELECT pk_sysdomain.get_domain(pk_icnp_constant.g_domain_interv_plan_status, p.flg_status, i_lang)
                      FROM dual) status,
                   pk_prof_utils.get_name(i_lang    => i_lang,
                                          i_prof_id => decode(p.id_prof_take, NULL, a.id_prof, p.id_prof_take)) prof,
                   p.notes notes,
                   pk_icnp_fo.get_interv_instructions(i_lang, i_prof, i_id_task) instr,
                   p.flg_status status_plan
              FROM icnp_epis_intervention a
             INNER JOIN icnp_composition b
                ON a.id_composition = b.id_composition
             INNER JOIN icnp_interv_plan p
                ON a.id_icnp_epis_interv = p.id_icnp_epis_interv
             WHERE a.id_icnp_epis_interv = i_id_task
               AND p.id_icnp_interv_plan = i_id_plan
               AND i_flg_type = 2
            UNION ALL
            SELECT b.flg_type icnp_type,
                   pk_translation.get_translation(i_lang, b.code_icnp_composition) name,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => diag.dt_last_update,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) dt_begin,
                   (SELECT pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_diag_status, diag.flg_status, i_lang) status
                      FROM dual) status,
                   pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => diag.id_prof_last_update) prof,
                   diag.notes notes,
                   NULL instr,
                   NULL status_plan
              FROM icnp_epis_diagnosis diag
             INNER JOIN icnp_composition b
                ON diag.id_composition = b.id_composition
             WHERE diag.id_icnp_epis_diag = i_id_task
               AND i_flg_type = 1
               AND b.id_composition = i_id_diag
               AND i_id_diag_hist IS NULL
            UNION ALL
            SELECT b.flg_type icnp_type,
                   pk_translation.get_translation(i_lang, b.code_icnp_composition) name,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => h.dt_last_update,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) dt_begin,
                   (SELECT pk_sysdomain.get_domain(pk_icnp_constant.g_domain_epis_diag_status, h.flg_status, i_lang) status
                      FROM dual) status,
                   pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => h.id_prof_last_update) prof,
                   h.notes notes,
                   NULL instr,
                   NULL status_plan
              FROM icnp_epis_diagnosis_hist h
             INNER JOIN icnp_composition b
                ON h.id_composition = b.id_composition
             WHERE h.id_icnp_epis_diag_hist = i_id_diag_hist
               AND i_flg_type = 1
               AND b.id_composition = i_id_diag
               AND i_id_diag_hist IS NOT NULL;
    
        l_icnp_task c_icnp_task%ROWTYPE;
    
        l_type_tlp     VARCHAR2(30 CHAR);
        l_name_tlp     VARCHAR2(300 CHAR);
        l_state_tlp    VARCHAR2(100 CHAR);
        l_dt_begin_tlp VARCHAR2(100 CHAR);
        l_prof_tlp     VARCHAR2(500 CHAR);
        l_notes_tlp    VARCHAR2(2000 CHAR);
        l_enter        VARCHAR2(15 CHAR) := '<br> <br>';
        l_result_tlp   VARCHAR2(2000 CHAR);
        l_instr_tlp    VARCHAR2(500 CHAR);
    
    BEGIN
    
        OPEN c_icnp_task;
        FETCH c_icnp_task
            INTO l_icnp_task;
        CLOSE c_icnp_task;
    
        CASE l_icnp_task.icnp_type
            WHEN pk_icnp_constant.g_composition_type_diagnosis THEN
                l_type_tlp := pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T001');
            ELSE
                l_type_tlp := pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T057');
        END CASE;
    
        l_name_tlp     := '<b>' || l_type_tlp || ': </b>' || l_icnp_task.name;
        l_state_tlp    := '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T004') || ': </b>' ||
                          l_icnp_task.status;
        l_dt_begin_tlp := '<b>' || CASE l_icnp_task.icnp_type
                              WHEN pk_icnp_constant.g_composition_type_diagnosis THEN
                               pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T086') || ': </b> '
                              ELSE
                               CASE
                                   WHEN l_icnp_task.status_plan = pk_icnp_constant.g_interv_plan_status_executed THEN
                                    pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T090') || ': </b> '
                                   WHEN l_icnp_task.status_plan = pk_icnp_constant.g_interv_plan_status_cancelled THEN
                                    pk_message.get_message(i_lang => i_lang, i_code_mess => 'PRESCRIPTION_REC_M032') || '</b> '
                                   ELSE
                                    pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T086') || ': </b> '
                               END
                          END || l_icnp_task.dt_begin;
        l_prof_tlp     := '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PROF_TEAMS_M019') ||
                          ': </b>' || l_icnp_task.prof;
        l_notes_tlp := CASE
                           WHEN l_icnp_task.notes IS NOT NULL THEN
                            '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CIPE_T062') || ': </b>' ||
                            l_icnp_task.notes
                       END;
    
        l_instr_tlp := '<b>' || pk_message.get_message(i_lang => i_lang, i_code_mess => 'ICNP_T221') || ': </b>' ||
                       l_icnp_task.instr;
    
        CASE l_icnp_task.icnp_type
            WHEN pk_icnp_constant.g_composition_type_diagnosis THEN
                l_result_tlp := l_name_tlp || l_enter || l_state_tlp || l_enter || l_dt_begin_tlp || l_enter ||
                                l_prof_tlp || l_enter || l_notes_tlp;
            ELSE
                l_result_tlp := l_name_tlp || l_enter || l_state_tlp || l_enter || l_dt_begin_tlp || l_enter ||
                                l_prof_tlp || l_enter || /*l_instr_tlp || l_enter ||*/
                                l_notes_tlp;
        END CASE;
    
        RETURN l_result_tlp;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
        
    END get_icnp_exec_tooltip;

    PROCEDURE hand_off__________________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    FUNCTION get_icnp_by_status
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_icnp_diag OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit           visit.id_visit%TYPE;
        l_code_sys_config sys_config.id_sys_config%TYPE := 'ICNP_CARE_PLAN_SCOPE';
        l_care_plan_scope VARCHAR2(1);
        l_episodes        table_number;
    
    BEGIN
    
        l_care_plan_scope := pk_sysconfig.get_config(i_code_cf => l_code_sys_config, i_prof => i_prof);
    
        CASE l_care_plan_scope
            WHEN pk_icnp_fo.g_icnp_care_plan_e THEN
                l_episodes := NULL;
            WHEN pk_icnp_fo.g_icnp_care_plan_p THEN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episodes
                  FROM episode e
                 WHERE e.id_patient =
                       pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
            WHEN pk_icnp_fo.g_icnp_care_plan_v THEN
                SELECT e.id_episode
                  BULK COLLECT
                  INTO l_episodes
                  FROM episode e
                 WHERE e.id_visit = pk_episode.get_id_visit(i_episode);
        END CASE;
    
        l_visit := pk_visit.get_visit(i_episode, o_error);
    
        g_error := 'OPEN O_ICNP_DIAG';
        OPEN o_icnp_diag FOR
            SELECT pk_utils.concat_table_l(CAST(COLLECT(t.desc_diagnosis) AS table_varchar), '; ') desc_diagnosis,
                   t.flg_status
              FROM (SELECT pk_icnp.desc_composition(i_lang, ied.id_composition) || ' (' ||
                            decode((SELECT COUNT(1)
                                     FROM icnp_epis_diagnosis_hist h
                                    WHERE h.id_icnp_epis_diag = ied.id_icnp_epis_diag
                                      AND h.id_composition != ied.id_composition),
                                   0,
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               ied.dt_icnp_epis_diag_tstz,
                                                               i_prof.institution,
                                                               i_prof.software),
                                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                               i_date => ied.dt_last_update,
                                                               i_inst => i_prof.institution,
                                                               i_soft => i_prof.software))
                            
                            || ')' desc_diagnosis,
                            ied.flg_status flg_status,
                            pk_sysdomain.get_rank(i_lang, 'ICNP_EPIS_DIAGNOSIS.FLG_STATUS', ied.flg_status) rank
                       FROM icnp_epis_diagnosis ied
                      WHERE /*ied.id_visit = l_visit*/
                      ied.id_episode IN (SELECT *
                                           FROM TABLE(l_episodes))
                   AND ied.flg_status = pk_icnp_constant.g_epis_diag_status_active) t
             GROUP BY flg_status;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ICNP_BY_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_icnp_diag);
            RETURN FALSE;
    END get_icnp_by_status;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_icnp;
/
