/*-- Last Change Revision: $Rev: 2027783 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_task_type IS

    FUNCTION get_task_type_with_all
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out --VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT tt.id_task_type, pk_translation.get_translation(i_lang, tt.code_task_type) desc_type, 1 order_1
              FROM task_type tt
             WHERE tt.id_task_type IN (SELECT DISTINCT tt.id_task_type
                                         FROM translation_trs tt)
            UNION ALL
            SELECT 0 id_task_type,
                   pk_translation.get_translation(i_lang, 'VIEW_OPTION.CODE_VIEW_OPTION.4000') desc_type,
                   0 order_1
              FROM dual
             ORDER BY 3 ASC, 2 ASC NULLS FIRST;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_TASK_TYPE_WITH_ALL',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_task_type_with_all;

    FUNCTION get_task_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out --VARCHAR2
    ) RETURN BOOLEAN IS
    
        /*
        * Returns a list of tasks' types
        *
        * @param     i_lang
        * @param     i_prof
        * @param     o_list
        * @param     o_error     Error message
        
        * @return    true or false on success or error
        *
        * @author    Ana Matos
        * @version   0.1
        * @since     2008/04/29
        */
    
    BEGIN
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT tt.id_task_type, pk_translation.get_translation(i_lang, tt.code_task_type) desc_type
              FROM task_type tt
             ORDER BY 2 ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_TASK_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_task_type;

    FUNCTION get_task_type_icon
    (
        i_lang      IN language.id_language%TYPE,
        i_task_type IN task_type.id_task_type%TYPE
    ) RETURN task_type.icon%TYPE IS
    
        /*
        * Returns the icon for a given task type
        *
        * @param     i_lang
        * @param     i_task_type
        
        * @return    true or false on success or error
        *
        * @author    Ana Matos
        * @version   0.1
        * @since     2008/04/29
        */
    
        l_icon task_type.icon%TYPE;
    
    BEGIN
    
        SELECT icon
          INTO l_icon
          FROM task_type
         WHERE id_task_type = i_task_type;
    
        RETURN l_icon;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_task_type_icon;

    FUNCTION get_task_type_flg
    (
        i_lang      IN language.id_language%TYPE,
        i_task_type IN task_type.id_task_type%TYPE
    ) RETURN task_type.flg_type%TYPE IS
    
        /*
        * Returns the flag type for a given task type
        *
        * @param     i_lang
        * @param     i_task_type
        * @param     o_error       Error message
        
        * @return    true or false on success or error
        *
        * @author    Ana Matos
        * @version   0.1
        * @since     2008/05/09
        */
    
        l_flg task_type.flg_type%TYPE;
    
    BEGIN
    
        SELECT flg_type
          INTO l_flg
          FROM task_type
         WHERE id_task_type = i_task_type;
    
        RETURN l_flg;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_task_type_flg;

    FUNCTION get_task_type_code_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_task_type IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
    
        /*
        * Returns the code for translation for a given task type
        *
        * @param     i_lang
        * @param     i_task_type
        * @param     o_error       Error message
        
        * @return    true or false on success or error
        *
        * @author    Ana Matos
        * @version   0.1
        * @since     2008/04/29
        */
    
        l_code VARCHAR2(200);
    
    BEGIN
    
        SELECT decode(flg_type,
                      'PS',
                      'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.',
                      'PZ',
                      'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.',
                      'O',
                      'SPECIALITY.CODE_SPECIALITY.',
                      'A',
                      'ANALYSIS.CODE_ANALYSIS.',
                      'AG',
                      'ANALYSIS_GROUP.CODE_ANALYSIS_GROUP.',
                      'EI',
                      'EXAM.CODE_EXAM.',
                      'EO',
                      'EXAM.CODE_EXAM.',
                      'N',
                      'VITAL_SIGN.CODE_VITAL_SIGN.',
                      'I',
                      'INTERVENTION.CODE_INTERVENTION.',
                      'OP',
                      'INTERVENTION.CODE_INTERVENTION.',
                      'ED',
                      'NURSE_TEA_TOPIC.CODE_NURSE_TEA_TOPIC.',
                      NULL)
          INTO l_code
          FROM task_type
         WHERE id_task_type = i_task_type;
    
        RETURN l_code;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_task_type_code_translation;

    PROCEDURE insert_into_task_type
    (
        i_id_task_type           task_type.id_task_type%TYPE,
        i_id_task_type_parent    task_type.id_task_type_parent%TYPE DEFAULT NULL,
        i_code_task_type         task_type.code_task_type%TYPE DEFAULT NULL,
        i_icon                   task_type.icon%TYPE DEFAULT NULL,
        i_flg_type               task_type.flg_type%TYPE,
        i_flg_dependency_support task_type.flg_dependency_support%TYPE DEFAULT 'N',
        i_flg_episode_task       task_type.flg_episode_task%TYPE DEFAULT 'T',
        i_flg_modular_workflow   task_type.flg_modular_workflow%TYPE DEFAULT 'N'
        
    ) IS
    
        l_code_task_type task_type.code_task_type%TYPE;
    BEGIN
    
        IF i_code_task_type IS NULL
        THEN
            l_code_task_type := 'TASK_TYPE.CODE_TASK_TYPE.' || i_id_task_type;
        ELSE
            l_code_task_type := i_code_task_type;
        END IF;
    
        UPDATE task_type
           SET id_task_type_parent    = i_id_task_type_parent,
               code_task_type         = l_code_task_type,
               icon                   = i_icon,
               flg_type               = i_flg_type,
               flg_dependency_support = i_flg_dependency_support,
               flg_episode_task       = i_flg_episode_task,
               flg_modular_workflow   = i_flg_modular_workflow
         WHERE id_task_type = i_id_task_type;
    
        IF SQL%ROWCOUNT = 0
        THEN
        
            INSERT INTO task_type
                (id_task_type,
                 id_task_type_parent,
                 code_task_type,
                 icon,
                 flg_type,
                 flg_dependency_support,
                 flg_episode_task,
                 flg_modular_workflow)
            VALUES
                (i_id_task_type,
                 i_id_task_type_parent,
                 l_code_task_type,
                 i_icon,
                 i_flg_type,
                 i_flg_dependency_support,
                 i_flg_episode_task,
                 i_flg_modular_workflow);
        END IF;
    
    END;

    /********************************************************************************************
    * set hidrics references in task_type table (to be executed only by DEFAULT)
    *
    * @author                                Vanessa Barsottelli
    * @since                                 09/02/2017
    ********************************************************************************************/
    PROCEDURE set_tt_hidric_references IS
    BEGIN
    
        -- intake
        UPDATE task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'I')
         WHERE ctt.id_task_type = pk_inp_hidrics_constant.g_task_type_hidric_in;
    
        -- intake and output
        UPDATE task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'H')
         WHERE ctt.id_task_type = pk_inp_hidrics_constant.g_task_type_hidric_in_out;
    
        -- output
        UPDATE task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'O')
         WHERE ctt.id_task_type = pk_inp_hidrics_constant.g_task_type_hidric_out;
    
        -- drainage records
        UPDATE task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'R')
         WHERE ctt.id_task_type = pk_inp_hidrics_constant.g_task_type_hidric_drain;
    
        -- urinary output
        UPDATE task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'D')
         WHERE ctt.id_task_type = pk_inp_hidrics_constant.g_task_type_hidric_urinary;
    
        -- all outputs
        UPDATE task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'A')
         WHERE ctt.id_task_type = pk_inp_hidrics_constant.g_task_type_hidric_all_output;
    
        -- irrigations
        UPDATE task_type ctt
           SET ctt.id_target_task_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = 'Y'
                   AND ht.acronym = 'G')
         WHERE ctt.id_task_type = pk_inp_hidrics_constant.g_task_type_hidric_irrigations; -- hidrics (irrigations)         
    
    END set_tt_hidric_references;

BEGIN

    -- Logging mechanism
    pk_alertlog.who_am_i(g_log_object_owner, g_log_object_name);
    pk_alertlog.log_init(g_log_object_name);

END;
/
