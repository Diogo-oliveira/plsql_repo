/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_glb_search_orders IS

    --BEGIN: private constant declarations
    g_package_owner CONSTANT VARCHAR2(30 CHAR) := 'ALERT';
    g_package_name  CONSTANT VARCHAR2(30 CHAR) := 'PK_GLB_SEARCH_ORDERS';

    --END: private constant declarations

    -- Function and procedure implementations

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_analysis_harvest
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_analysis_harvest
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_harvest%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT ar.id_episode, ar.id_patient, ar.id_prof_writes, ar.dt_req_tstz
              FROM analysis_req_det ard
             INNER JOIN analysis_req ar
                ON ard.id_analysis_req = ar.id_analysis_req
             WHERE ard.id_analysis_req_det = i_rowtype.id_analysis_req_det;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_analysis_harvest';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_analysis_harvest');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_analysis_harvest;

    /********************************************************************************************
    * pk_glb_search_orders.get_tbl_an_harvest_desc_codes
    *
    * @param    I_OWNER                         IN          VARCHAR2
    * @param    I_TABLE                         IN          VARCHAR2
    * @param    I_LANG                          IN          NUMBER(2)
    * @param    i_rowtype                       IN          I_TABLE.ROWTYPE
    * @param    o_code_list                     IN          TABLE_VARCHAR
    * @param    o_desc_list                     IN          TABLE_VARCHAR
    *
    *
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    PROCEDURE get_tbl_an_harvest_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN analysis_harvest%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_record VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_SAMPLE_RECIPIENT.' ||
                                            i_rowtype.id_analysis_req_det;
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_an_harvest_desc_codes';
    
    BEGIN
        o_code_list := table_varchar(l_code_record);
        o_desc_list := table_varchar(pk_translation.get_translation(i_lang,
                                                                    'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                    i_rowtype.id_sample_recipient));
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
    END get_tbl_an_harvest_desc_codes;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_analysis_quest_resp
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_analysis_quest_resp
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_question_response%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT ar.id_episode, ar.id_patient, ar.id_prof_writes, ar.dt_req_tstz
              FROM analysis_req_det ard
             INNER JOIN analysis_req ar
                ON ard.id_analysis_req = ar.id_analysis_req
             WHERE ard.id_analysis_req_det = i_rowtype.id_analysis_req_det;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_analysis_quest_resp';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_analysis_quest_resp');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_analysis_quest_resp;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_analysis_req
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_analysis_req
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_req%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT i_rowtype.id_episode, i_rowtype.id_patient, i_rowtype.id_prof_writes, i_rowtype.dt_req_tstz
              FROM dual;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_analysis_req';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_analysis_req');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_analysis_req;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_analysis_result
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_analysis_result
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_result%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT i_rowtype.id_episode,
                   i_rowtype.id_patient,
                   i_rowtype.id_professional,
                   i_rowtype.dt_analysis_result_tstz
              FROM dual;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_analysis_result';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_analysis_result');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_analysis_result;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_analysis_result_par
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_analysis_result_par
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_result_par%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT ar.id_episode, ar.id_patient, ar.id_professional, ar.dt_analysis_result_tstz
              FROM analysis_result ar
             WHERE ar.id_analysis_result = i_rowtype.id_analysis_result;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_analysis_result_par';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_analysis_result_par');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_analysis_result_par;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_care_plan
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_care_plan
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN care_plan%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT i_rowtype.id_episode, i_rowtype.id_patient, i_rowtype.id_prof, i_rowtype.dt_care_plan
              FROM dual;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_care_plan';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_care_plan');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_care_plan;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_care_plan_task
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_care_plan_task
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN care_plan_task%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT cp.id_episode, cp.id_patient, cp.id_prof, cp.dt_care_plan
              FROM care_plan cp
             INNER JOIN care_plan_task_link cptl
                ON cptl.id_care_plan = cp.id_care_plan
             WHERE cptl.id_care_plan_task = i_rowtype.id_care_plan_task;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_care_plan_task';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_care_plan_task');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_care_plan_task;

    /********************************************************************************************
    * pk_glb_search_orders.get_tbl_cp_task_desc_codes
    *
    * @param    I_OWNER                         IN          VARCHAR2
    * @param    I_TABLE                         IN          VARCHAR2
    * @param    I_LANG                          IN          NUMBER(2)
    * @param    i_rowtype                       IN          I_TABLE.ROWTYPE
    * @param    o_code_list                     IN          TABLE_VARCHAR
    * @param    o_desc_list                     IN          TABLE_VARCHAR
    *
    *
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    PROCEDURE get_tbl_cp_task_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN care_plan_task%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_cp_task_desc_codes';
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
    BEGIN
    
        l_code_list.extend;
        l_code_list(1) := '' || i_owner || '.' || i_table || '.ID_ITEM.' || i_rowtype.id_care_plan_task;
        l_desc_list.extend;
        l_desc_list(1) := pk_care_plans.get_desc_translation(i_lang,
                                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                                          sys_context('ALERT_CONTEXT', 'i_software')),
                                                             i_rowtype.id_item,
                                                             i_rowtype.id_task_type);
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_tbl_cp_task_desc_codes;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_care_plan_task_lk
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_care_plan_task_lk
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN care_plan_task_link%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT cp.id_episode, cp.id_patient, cp.id_prof, cp.dt_care_plan
              FROM care_plan cp
             WHERE cp.id_care_plan = i_rowtype.id_care_plan;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_care_plan_task_lk';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_care_plan_task_lk');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_care_plan_task_lk;

    /********************************************************************************************
    * pk_glb_search_orders.get_tbl_cp_task_lk_desc_codes
    *
    * @param    I_OWNER                         IN          VARCHAR2
    * @param    I_TABLE                         IN          VARCHAR2
    * @param    I_LANG                          IN          NUMBER(2)
    * @param    i_rowtype                       IN          I_TABLE.ROWTYPE
    * @param    o_code_list                     IN          TABLE_VARCHAR
    * @param    o_desc_list                     IN          TABLE_VARCHAR
    *
    *
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    PROCEDURE get_tbl_cp_task_lk_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN care_plan_task_link%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_cp_task_desc_codes';
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER := 0;
    
        l_id_item      care_plan_task.id_item%TYPE;
        l_id_task_type care_plan_task.id_task_type%TYPE;
        l_notes        care_plan_task.notes%TYPE;
        l_notes_cancel care_plan_task.notes_cancel%TYPE;
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        SELECT cpt.id_item, cpt.id_task_type, cpt.notes, cpt.notes_cancel
          INTO l_id_item, l_id_task_type, l_notes, l_notes_cancel
          FROM care_plan_task cpt
         WHERE cpt.id_care_plan_task = i_rowtype.id_care_plan_task;
    
        IF l_notes_cancel IS NOT NULL
        THEN
            extend_arrays;
            l_code_list(l_idx) := 'CARE_PLAN_TASK.NOTES_CANCEL' || '.' || i_rowtype.id_care_plan_task || '';
            l_desc_list(l_idx) := l_notes_cancel;
        END IF;
    
        IF l_notes IS NOT NULL
        THEN
            extend_arrays;
            l_code_list(l_idx) := 'CARE_PLAN_TASK.NOTES' || '.' || i_rowtype.id_care_plan_task || '';
            l_desc_list(l_idx) := l_notes;
        END IF;
    
        l_code_list.extend;
        l_code_list(l_idx) := '' || i_owner || '.' || i_table || '.ID_ITEM.' || i_rowtype.id_care_plan_task;
        l_desc_list.extend;
        l_desc_list(l_idx) := pk_care_plans.get_desc_translation(i_lang,
                                                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                                              sys_context('ALERT_CONTEXT',
                                                                                          'i_institution'),
                                                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                                                 l_id_item,
                                                                 l_id_task_type);
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_tbl_cp_task_lk_desc_codes;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_exam_req
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_exam_req
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN exam_req%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT nvl(i_rowtype.id_episode, nvl(i_rowtype.id_episode_origin, i_rowtype.id_episode_destination)),
                   i_rowtype.id_patient,
                   i_rowtype.id_prof_req,
                   i_rowtype.dt_req_tstz
              FROM dual;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_exam_req';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_exam_req');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_exam_req;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_exam_req_det
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_exam_req_det
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN exam_req_det%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT nvl(er.id_episode, nvl(er.id_episode_origin, er.id_episode_destination)),
                   er.id_patient,
                   er.id_prof_req,
                   er.dt_req_tstz
              FROM exam_req er
             WHERE er.id_exam_req = i_rowtype.id_exam_req;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_exam_req_det';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_exam_req_det');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_exam_req_det;

    /********************************************************************************************
    * pk_glb_search_orders.get_tbl_exam_req_dt_desc_codes
    *
    * @param    I_OWNER                         IN          VARCHAR2
    * @param    I_TABLE                         IN          VARCHAR2
    * @param    I_LANG                          IN          NUMBER(2)
    * @param    i_rowtype                       IN          I_TABLE.ROWTYPE
    * @param    o_code_list                     IN          TABLE_VARCHAR
    * @param    o_desc_list                     IN          TABLE_VARCHAR
    *
    *
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    PROCEDURE get_tbl_exam_req_dt_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN exam_req_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_exam_req_dt_desc_codes';
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
    BEGIN
        l_code_list.extend;
        l_code_list(1) := '' || i_owner || '.' || i_table || '.ID_ROOM.' || i_rowtype.id_exam_req;
        l_desc_list.extend;
        l_desc_list(1) := pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || i_rowtype.id_room);
    
        l_code_list.extend;
        l_code_list(2) := '' || i_owner || '.' || i_table || '.ID_EXAM.' || i_rowtype.id_exam_req;
        l_desc_list.extend;
        l_desc_list(2) := pk_exams_api_db.get_alias_translation(i_lang,
                                                                profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                                                             sys_context('ALERT_CONTEXT', 'i_software')),
                                                                'EXAM.CODE_EXAM.' || i_rowtype.id_exam);
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_tbl_exam_req_dt_desc_codes;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_exam_result
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_exam_result
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN exam_result%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT i_rowtype.id_episode, i_rowtype.id_patient, i_rowtype.id_professional, i_rowtype.dt_exam_result_tstz
              FROM dual;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_exam_result';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_exam_result');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_exam_result;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_harvest
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_harvest
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN harvest%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT i_rowtype.id_episode, i_rowtype.id_patient, i_rowtype.id_prof_harvest, i_rowtype.dt_harvest_reg_tstz
              FROM dual;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_harvest';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_harvest');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_harvest;

    /********************************************************************************************
    * pk_glb_search_orders.get_tbl_harvest_desc_codes
    *
    * @param    I_OWNER                         IN          VARCHAR2
    * @param    I_TABLE                         IN          VARCHAR2
    * @param    I_LANG                          IN          NUMBER(2)
    * @param    i_rowtype                       IN          I_TABLE.ROWTYPE
    * @param    o_code_list                     IN          TABLE_VARCHAR
    * @param    o_desc_list                     IN          TABLE_VARCHAR
    *
    *
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    PROCEDURE get_tbl_harvest_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN harvest%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_harvest_desc_codes';
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
    BEGIN
        l_code_list.extend;
        l_code_list(1) := '' || i_owner || '.' || i_table || '.ID_ROOM_HARVEST.' || i_rowtype.id_harvest;
        l_desc_list.extend;
        l_desc_list(1) := pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || i_rowtype.id_room_harvest);
    
        l_code_list.extend;
        l_code_list(2) := '' || i_owner || '.' || i_table || '.ID_ROOM_RECEIVE_TUBE.' || i_rowtype.id_harvest;
        l_desc_list.extend;
        l_desc_list(2) := pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || i_rowtype.id_room_receive_tube);
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_tbl_harvest_desc_codes;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_order_set_process
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_order_set_process
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN order_set_process%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT i_rowtype.id_episode,
                   i_rowtype.id_patient,
                   i_rowtype.id_professional,
                   i_rowtype.dt_order_set_process_tstz
              FROM dual;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_order_set_process';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_order_set_process');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_order_set_process;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_order_set_proc_task
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_order_set_proc_task
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN order_set_process_task_det%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT osp.id_episode, osp.id_patient, osp.id_professional, osp.dt_order_set_process_tstz
              FROM order_set_process_task ospt
             INNER JOIN order_set_process osp
                ON ospt.id_order_set_process = osp.id_order_set_process
             WHERE ospt.id_order_set_process_task = i_rowtype.id_order_set_process_task;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_order_set_proc_task';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_order_set_proc_task');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_order_set_proc_task;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_protocol_process
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_protocol_process
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN protocol_process%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT i_rowtype.id_episode, i_rowtype.id_patient, i_rowtype.id_professional, i_rowtype.dt_status
              FROM dual;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_protocol_process';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_protocol_process');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_protocol_process;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_protocol_proc_element
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_protocol_proc_element
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN protocol_process_element%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT pp.id_episode, pp.id_patient, pp.id_professional, pp.dt_status
              FROM protocol_process pp
             WHERE pp.id_protocol_process = i_rowtype.id_protocol_process;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_protocol_proc_element';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_protocol_proc_element');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_protocol_proc_element;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_therapeutic_decision
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_therapeutic_decision
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN therapeutic_decision%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT i_rowtype.id_episode, i_rowtype.id_patient, i_rowtype.id_professional, i_rowtype.dt_creation
              FROM dual;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_therapeutic_decision';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_therapeutic_decision');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_therapeutic_decision;

    /********************************************************************************************
    * pk_glb_search_orders.get_tbl_analysis_desc_codes
    *
    * @param    I_OWNER                         IN          VARCHAR2
    * @param    I_TABLE                         IN          VARCHAR2
    * @param    I_LANG                          IN          NUMBER(2)
    * @param    i_rowtype                       IN          I_TABLE.ROWTYPE
    * @param    o_code_list                     IN          TABLE_VARCHAR
    * @param    o_desc_list                     IN          TABLE_VARCHAR
    *
    *
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    PROCEDURE get_tbl_analysis_desc_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN analysis_req_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_analysis_desc_codes';
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
    BEGIN
        l_code_list.extend;
        l_code_list(1) := '' || i_owner || '.' || i_table || '.ID_ANALYSIS.' || i_rowtype.id_analysis_req_det;
        l_desc_list.extend;
        l_desc_list(1) := pk_translation.get_translation(i_lang, 'ANALYSIS.CODE_ANALYSIS.' || i_rowtype.id_analysis);
    
        l_code_list.extend;
        l_code_list(2) := '' || i_owner || '.' || i_table || '.ID_SAMPLE_TYPE.' || i_rowtype.id_analysis_req_det;
        l_desc_list.extend;
        l_desc_list(2) := pk_translation.get_translation(i_lang,
                                                         'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || i_rowtype.id_sample_type);
    
        l_code_list.extend;
        l_code_list(3) := '' || i_owner || '.' || i_table || '.DESC_ANALYSIS_ALIAS.' || i_rowtype.id_analysis_req_det;
        l_desc_list.extend;
        l_desc_list(3) := pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                                                 sys_context('ALERT_CONTEXT',
                                                                                             'i_institution'),
                                                                                 sys_context('ALERT_CONTEXT',
                                                                                             'i_software')),
                                                                    'A',
                                                                    'ANALYSIS.CODE_ANALYSIS.' || i_rowtype.id_analysis,
                                                                    'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                    i_rowtype.id_sample_type,
                                                                    NULL);
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
        
    END get_tbl_analysis_desc_codes;

    /********************************************************************************************   
    * pk_glb_search_orders.get_tbl_therapeutic_decision
    *
    * @param    I_OWNER                        IN          VARCHAR2
    * @param    I_TABLE                        IN          VARCHAR2
    * @param    I_ROWTYPE                      IN          I_TABLE.ROWTYPE
    *
    * @return    T_TRL_TRS_RESULT
    *
    * @author    Pedro Miranda
    * @version   2.6.3
    * @since     2013-12-10
    *
    * @notes    
    *
    ********************************************************************************************/
    FUNCTION get_tbl_col_info_rec
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN analysis_req_det%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT ar.id_episode, ar.id_patient, ar.id_prof_writes, ar.dt_req_tstz
              FROM analysis_req ar
             WHERE ar.id_analysis_req = i_rowtype.id_analysis_req;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_info_rec';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_col_info_rec');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_col_info_rec;
BEGIN
    --INIT LOG SYSTEM!
    pk_alertlog.log_init(g_package_name);

END pk_glb_search_orders;
/
