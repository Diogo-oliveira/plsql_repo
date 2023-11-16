/*-- Last Change Revision: $Rev: 2027256 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:39 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inp_global_search AS

    --Package Info
    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);

    /************************************************************************************************************
    * Get epis positioning info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/22
    ***********************************************************************************************************/
    FUNCTION get_epis_pos_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_positioning%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT i_rowtype.id_episode, e.id_patient, i_rowtype.id_professional, i_rowtype.dt_epis_positioning, NULL
              FROM episode e
             WHERE e.id_episode = i_rowtype.id_episode;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_POS_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_epis_pos_info;

    /************************************************************************************************************
    * Get epis positioning description 
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/22
    ***********************************************************************************************************/
    PROCEDURE get_epis_pos_code
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_positioning%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_pos pk_translation.t_code;
        l_desc_pos pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_POS_CODE';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            l_code_pos := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' || i_rowtype.id_epis_positioning;
            l_desc_pos := pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, i_rowtype.id_cancel_reason);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_pos;
            l_desc_list(l_idx) := l_desc_pos;
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_epis_pos_code;

    /************************************************************************************************************
    * Get epis positioning plan info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/27
    ***********************************************************************************************************/
    FUNCTION get_epis_pos_plan_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_positioning_plan%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT ep.id_episode, e.id_patient, i_rowtype.id_prof_exec, i_rowtype.dt_epis_positioning_plan, NULL
              FROM epis_positioning_det epd
              JOIN epis_positioning ep
                ON ep.id_epis_positioning = epd.id_epis_positioning
              JOIN episode e
                ON e.id_episode = ep.id_episode
             WHERE epd.id_epis_positioning_det = i_rowtype.id_epis_positioning_det;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_POS_PLAN_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            RETURN NULL;
    END get_epis_pos_plan_info;

    /************************************************************************************************************
    * Get epis positioning det info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/22
    ***********************************************************************************************************/
    FUNCTION get_epis_pos_det_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_positioning_det%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT ep.id_episode, e.id_patient, ep.id_professional, ep.dt_epis_positioning, NULL
              FROM epis_positioning ep
              JOIN episode e
                ON e.id_episode = ep.id_episode
             WHERE ep.id_epis_positioning = i_rowtype.id_epis_positioning;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_POS_DET_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_epis_pos_det_info;

    /************************************************************************************************************
    * Get epis positioning det description 
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/22
    ***********************************************************************************************************/
    PROCEDURE get_epis_pos_det_code
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_positioning_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_pos VARCHAR2(200 CHAR);
        l_desc_pos pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_POS_DET_CODE';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    BEGIN
    
        IF i_rowtype.id_positioning IS NOT NULL
        THEN
            l_code_pos := '' || i_owner || '.' || i_table || '.ID_POSITIONING.' || i_rowtype.id_epis_positioning_det;
            l_desc_pos := pk_translation.get_translation(i_lang,
                                                         'POSITIONING.CODE_POSITIONING.' || i_rowtype.id_positioning);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_pos;
            l_desc_list(l_idx) := l_desc_pos;
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_epis_pos_det_code;

    /************************************************************************************************************
    * Get vital sign read info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/26
    ***********************************************************************************************************/
    FUNCTION get_vs_read_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN vital_sign_read%ROWTYPE
    ) RETURN t_trl_trs_result IS
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_VS_READ_INFO';
    
    BEGIN
    
        l_trl_trs_result.id_episode := i_rowtype.id_episode;
        l_trl_trs_result.id_patient := i_rowtype.id_patient;
    
        CASE i_rowtype.flg_state
            WHEN g_vital_sign_active THEN
                l_trl_trs_result.id_professional := i_rowtype.id_prof_read;
                l_trl_trs_result.dt_record       := i_rowtype.dt_vital_sign_read_tstz;
            WHEN g_vital_sign_cancelled THEN
                l_trl_trs_result.id_professional := i_rowtype.id_prof_cancel;
                l_trl_trs_result.dt_record       := i_rowtype.dt_cancel_tstz;
        END CASE;
    
        l_trl_trs_result.id_task_type := NULL;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_vs_read_info;

    /************************************************************************************************************
    * Get vital sign read description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/26
    ***********************************************************************************************************/
    PROCEDURE get_vs_read_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN vital_sign_read%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_vital_sign VARCHAR2(100 CHAR);
        l_desc_vital_sign pk_translation.t_desc_translation;
    
        l_code_cancel_reason VARCHAR2(100 CHAR);
        l_desc_cancel_reason pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_VS_READ_CODES';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        IF i_rowtype.id_vital_sign IS NOT NULL
        THEN
            l_code_vital_sign := '' || i_owner || '.' || i_table || '.ID_VITAL_SIGN.' || i_rowtype.id_vital_sign_read;
            l_desc_vital_sign := pk_translation.get_translation(i_lang,
                                                                'VITAL_SIGN.CODE_VITAL_SIGN.' || i_rowtype.id_vital_sign);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_vital_sign;
            l_desc_list(l_idx) := l_desc_vital_sign;
        END IF;
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            l_code_cancel_reason := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' ||
                                    i_rowtype.id_vital_sign_read;
            l_desc_cancel_reason := pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, i_rowtype.id_cancel_reason);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_cancel_reason;
            l_desc_list(l_idx) := l_desc_cancel_reason;
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_vs_read_codes;

    /************************************************************************************************************
    * Get vital sign notes info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/26
    ***********************************************************************************************************/
    FUNCTION get_vs_notes_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN vital_sign_notes%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT i_rowtype.id_episode, e.id_patient, i_rowtype.id_professional, i_rowtype.dt_notes_tstz, NULL
              FROM episode e
             WHERE e.id_episode = i_rowtype.id_episode;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_VS_NOTES_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_vs_notes_info;

    /************************************************************************************************************
    * Get monitorization info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/27
    ***********************************************************************************************************/
    FUNCTION get_monitorization_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN monitorization%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT i_rowtype.id_episode,
                   nvl(i_rowtype.id_patient, e.id_patient),
                   CASE
                       WHEN i_rowtype.flg_status = g_monitor_cancelled THEN
                        i_rowtype.id_prof_cancel
                       ELSE
                        i_rowtype.id_professional
                   END,
                   CASE
                       WHEN i_rowtype.flg_status = g_monitor_cancelled THEN
                        i_rowtype.dt_cancel_tstz
                       ELSE
                        i_rowtype.dt_monitorization_tstz
                   END,
                   NULL
              FROM episode e
             WHERE e.id_episode = i_rowtype.id_episode;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_MONITORIZATION_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_monitorization_info;

    /************************************************************************************************************
    * Get monitorization vital signs info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/27
    ***********************************************************************************************************/
    FUNCTION get_monitorization_vs_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN monitorization_vs%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT m.id_episode,
                   nvl(m.id_patient, e.id_patient),
                   CASE
                       WHEN i_rowtype.flg_co_sign = g_monitor_co_sign_yes THEN
                        i_rowtype.id_prof_co_sign
                       ELSE
                        i_rowtype.id_prof_order
                   END,
                   CASE
                       WHEN i_rowtype.flg_co_sign = g_monitor_co_sign_yes THEN
                        i_rowtype.dt_co_sign
                       ELSE
                        i_rowtype.dt_order
                   END,
                   NULL
              FROM monitorization m
              JOIN episode e
                ON e.id_episode = m.id_episode
             WHERE m.id_monitorization = i_rowtype.id_monitorization;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_MONITORIZATION_VS_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_monitorization_vs_info;

    /************************************************************************************************************
    * Get monitorization vital sign read description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/27
    ***********************************************************************************************************/
    PROCEDURE get_monitorization_vs_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN monitorization_vs%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_vs VARCHAR2(200 CHAR);
        l_desc_vs pk_translation.t_desc_translation;
    
        l_code_order_type VARCHAR2(100 CHAR);
        l_desc_order_type pk_translation.t_desc_translation;
    
        l_code_cancel_reason VARCHAR2(100 CHAR);
        l_desc_cancel_reason pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_MONITORIZATION_VS_CODES';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        IF i_rowtype.id_vital_sign IS NOT NULL
        THEN
            l_code_vs := '' || i_owner || '.' || i_table || '.ID_VITAL_SIGN.' || i_rowtype.id_monitorization_vs;
            l_desc_vs := pk_translation.get_translation(i_lang,
                                                        'VITAL_SIGN.CODE_VITAL_SIGN.' || i_rowtype.id_vital_sign);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_vs;
            l_desc_list(l_idx) := l_desc_vs;
        END IF;
    
        IF i_rowtype.id_order_type IS NOT NULL
        THEN
            l_code_order_type := '' || i_owner || '.' || i_table || '.ID_ORDER_TYPE.' || i_rowtype.id_monitorization_vs;
            l_desc_order_type := pk_translation.get_translation(i_lang,
                                                                'ORDER_TYPE.CODE_ORDER_TYPE.' || i_rowtype.id_order_type);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_order_type;
            l_desc_list(l_idx) := l_desc_order_type;
        END IF;
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            l_code_cancel_reason := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' ||
                                    i_rowtype.id_monitorization_vs;
            l_desc_cancel_reason := pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, i_rowtype.id_cancel_reason);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_cancel_reason;
            l_desc_list(l_idx) := l_desc_cancel_reason;
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_monitorization_vs_codes;

    /************************************************************************************************************
    * Get epis hidrics info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/29
    ***********************************************************************************************************/
    FUNCTION get_epis_hidrics_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_hidrics%ROWTYPE
    ) RETURN t_trl_trs_result IS
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_HIDRICS_INFO';
    BEGIN
        l_trl_trs_result.id_episode := i_rowtype.id_episode;
        l_trl_trs_result.id_patient := i_rowtype.id_patient;
    
        CASE i_rowtype.flg_status
            WHEN g_hidrics_cancelled THEN
                l_trl_trs_result.id_professional := i_rowtype.id_prof_cancel;
            WHEN g_hidrics_interrupted THEN
                l_trl_trs_result.id_professional := i_rowtype.id_prof_inter;
            ELSE
                l_trl_trs_result.id_professional := i_rowtype.id_prof_last_change;
        END CASE;
    
        CASE i_rowtype.flg_status
            WHEN g_hidrics_cancelled THEN
                l_trl_trs_result.dt_record := i_rowtype.dt_cancel_tstz;
            WHEN g_hidrics_interrupted THEN
                l_trl_trs_result.dt_record := i_rowtype.dt_inter_tstz;
            ELSE
                l_trl_trs_result.dt_record := i_rowtype.dt_epis_hidrics;
        END CASE;
    
        l_trl_trs_result.id_task_type := NULL;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_epis_hidrics_info;

    /************************************************************************************************************
    * Get epis hidrics description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/29
    ***********************************************************************************************************/
    PROCEDURE get_epis_hidrics_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_hidrics%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_hidrics VARCHAR2(100 CHAR);
        l_desc_hidrics pk_translation.t_desc_translation;
    
        l_code_cancel_reason VARCHAR2(100 CHAR);
        l_desc_cancel_reason pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_HIDRICS_CODES';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        IF i_rowtype.id_hidrics_type IS NOT NULL
        THEN
            l_code_hidrics := '' || i_owner || '.' || i_table || '.ID_HIDRICS_TYPE.' || i_rowtype.id_epis_hidrics;
            l_desc_hidrics := pk_translation.get_translation(i_lang,
                                                             'HIDRICS_TYPE.CODE_HIDRICS_TYPE.' ||
                                                             i_rowtype.id_hidrics_type);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_hidrics;
            l_desc_list(l_idx) := l_desc_hidrics;
        
            pk_alertlog.log_error(text            => l_code_hidrics || ' - ' || l_desc_hidrics,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        
        END IF;
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            l_code_cancel_reason := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' ||
                                    i_rowtype.id_epis_hidrics;
            l_desc_cancel_reason := pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, i_rowtype.id_cancel_reason);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_cancel_reason;
            l_desc_list(l_idx) := l_desc_cancel_reason;
        
            pk_alertlog.log_error(text            => l_code_cancel_reason || ' - ' || l_desc_cancel_reason,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_epis_hidrics_codes;

    /************************************************************************************************************
    * Get epis hidrics details info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/29
    ***********************************************************************************************************/
    FUNCTION get_epis_hidrics_det_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_hidrics_det%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT eh.id_episode,
                   eh.id_patient,
                   CASE
                       WHEN i_rowtype.flg_status = g_hidrics_cancelled THEN
                        i_rowtype.id_prof_cancel
                       ELSE
                        i_rowtype.id_professional
                   END,
                   CASE
                       WHEN i_rowtype.flg_status = g_hidrics_cancelled THEN
                        i_rowtype.dt_cancel_tstz
                       ELSE
                        i_rowtype.dt_epis_hidrics_det
                   END,
                   NULL
              FROM epis_hidrics eh
             WHERE eh.id_epis_hidrics = i_rowtype.id_epis_hidrics;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_HIDRICS_DET_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
        
            RETURN NULL;
    END get_epis_hidrics_det_info;

    /************************************************************************************************************
    * Get epis hidrics detail description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/11/29
    ***********************************************************************************************************/
    PROCEDURE get_epis_hidrics_det_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_hidrics_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_device VARCHAR2(100 CHAR);
        l_desc_device pk_translation.t_desc_translation;
    
        l_code_cancel_reason VARCHAR2(100 CHAR);
        l_desc_cancel_reason pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_HIDRICS_DET_CODES';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        IF i_rowtype.id_hidrics_device IS NOT NULL
        THEN
            l_code_device := '' || i_owner || '.' || i_table || '.ID_HIDRICS_DEVICE.' || i_rowtype.id_epis_hidrics_det;
            l_desc_device := pk_inp_hidrics.get_device_desc(i_lang                 => i_lang,
                                                            i_prof                 => i_prof,
                                                            i_id_epis_hidrics_det  => i_rowtype.id_epis_hidrics_det,
                                                            i_dt_epis_hid_det_hist => NULL);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_device;
            l_desc_list(l_idx) := l_desc_device;
        
            pk_alertlog.log_error(text            => l_code_device || ' - ' || l_desc_device,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        
        END IF;
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            l_code_cancel_reason := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' ||
                                    i_rowtype.id_epis_hidrics_det;
            l_desc_cancel_reason := pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, i_rowtype.id_cancel_reason);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_cancel_reason;
            l_desc_list(l_idx) := l_desc_cancel_reason;
        
            pk_alertlog.log_error(text            => l_code_cancel_reason || ' - ' || l_desc_cancel_reason,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_epis_hidrics_det_codes;

    /************************************************************************************************************
    * Get epis hidrics line info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/02
    ***********************************************************************************************************/
    FUNCTION get_epis_hidrics_line_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_hidrics_line%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT eh.id_episode,
                   eh.id_patient,
                   CASE
                       WHEN i_rowtype.flg_status = g_hidrics_cancelled THEN
                        i_rowtype.id_prof_cancel
                       ELSE
                        i_rowtype.id_prof_last_change
                   END,
                   CASE
                       WHEN i_rowtype.flg_status = g_hidrics_cancelled THEN
                        i_rowtype.dt_cancel
                       ELSE
                        i_rowtype.dt_epis_hidrics_line
                   END,
                   NULL
              FROM epis_hidrics eh
             WHERE eh.id_epis_hidrics = i_rowtype.id_epis_hidrics;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_HIDRICS_LINE_INFO';
    BEGIN
    
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            RETURN NULL;
    END get_epis_hidrics_line_info;

    /************************************************************************************************************
    * Get epis hidrics line description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/02
    ***********************************************************************************************************/
    PROCEDURE get_epis_hidrics_line_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_hidrics_line%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_hidrics VARCHAR2(100 CHAR);
        l_desc_hidrics pk_translation.t_desc_translation;
    
        l_code_way VARCHAR2(100 CHAR);
        l_desc_way pk_translation.t_desc_translation;
    
        l_code_location VARCHAR2(100 CHAR);
        l_desc_location pk_translation.t_desc_translation;
    
        l_code_cancel_reason VARCHAR2(100 CHAR);
        l_desc_cancel_reason pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_HIDRICS_LINE_CODES';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        IF i_rowtype.id_hidrics IS NOT NULL
        THEN
            l_code_hidrics := '' || i_owner || '.' || i_table || '.ID_HIDRICS.' || i_rowtype.id_epis_hidrics_line;
        
            BEGIN
                SELECT nvl(ef.free_text, pk_translation.get_translation(i_lang, h.code_hidrics))
                  INTO l_desc_hidrics
                  FROM hidrics h
                  LEFT JOIN epis_hidrics_det_ftxt ef
                    ON ef.id_hidrics = h.id_hidrics
                   AND ef.id_epis_hidrics_det_ftxt = i_rowtype.id_epis_hid_ftxt_fluid
                 WHERE h.id_hidrics = i_rowtype.id_hidrics;
            EXCEPTION
                WHEN no_data_found THEN
                    l_desc_hidrics := '';
            END;
        
            extend_arrays();
            l_code_list(l_idx) := l_code_hidrics;
            l_desc_list(l_idx) := l_desc_hidrics;
        
            pk_alertlog.log_error(text            => l_code_hidrics || ' - ' || l_desc_hidrics,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        END IF;
    
        IF i_rowtype.id_way IS NOT NULL
        THEN
            l_code_way := '' || i_owner || '.' || i_table || '.ID_WAY.' || i_rowtype.id_epis_hidrics_line;
        
            BEGIN
                SELECT nvl(ef.free_text, pk_translation.get_translation(i_lang, w.code_way))
                  INTO l_desc_way
                  FROM way w
                  LEFT JOIN epis_hidrics_det_ftxt ef
                    ON ef.id_way = w.id_way
                   AND ef.id_epis_hidrics_det_ftxt = i_rowtype.id_epis_hid_ftxt_way
                 WHERE w.id_way = i_rowtype.id_way;
            EXCEPTION
                WHEN no_data_found THEN
                    l_desc_way := '';
            END;
        
            extend_arrays();
            l_code_list(l_idx) := l_code_way;
            l_desc_list(l_idx) := l_desc_way;
        
            pk_alertlog.log_error(text            => l_code_way || ' - ' || l_desc_way,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        
        END IF;
    
        IF i_rowtype.id_hidrics_location IS NOT NULL
        THEN
            l_code_location := '' || i_owner || '.' || i_table || '.ID_HIDRICS_LOCATION.' ||
                               i_rowtype.id_epis_hidrics_line;
        
            BEGIN
                SELECT nvl(t.free_text, pk_translation.get_translation(1, t.code_body_part)) ||
                       nvl2(t.id_body_side, ' (' || pk_translation.get_translation(1, t.code_body_side) || ')', '')
                  INTO l_desc_location
                  FROM (SELECT ef.free_text, bp.code_body_part, bs.id_body_side, bs.code_body_side
                          FROM hidrics_location hl
                          LEFT JOIN epis_hidrics_det_ftxt ef
                            ON hl.id_hidrics_location = ef.id_hidrics_location
                           AND ef.id_epis_hidrics_det_ftxt = i_rowtype.id_epis_hid_ftxt_loc
                          LEFT JOIN body_part bp
                            ON hl.id_body_part = bp.id_body_part
                          LEFT JOIN body_side bs
                            ON hl.id_body_side = bs.id_body_side
                         WHERE hl.id_hidrics_location = i_rowtype.id_hidrics_location) t;
            EXCEPTION
                WHEN no_data_found THEN
                    l_desc_location := '';
            END;
        
            extend_arrays();
            l_code_list(l_idx) := l_code_location;
            l_desc_list(l_idx) := l_desc_location;
        
            pk_alertlog.log_error(text            => l_code_location || ' - ' || l_desc_location,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        
        END IF;
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            l_code_cancel_reason := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' ||
                                    i_rowtype.id_epis_hidrics_line;
            l_desc_cancel_reason := pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, i_rowtype.id_cancel_reason);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_cancel_reason;
            l_desc_list(l_idx) := l_desc_cancel_reason;
        
            pk_alertlog.log_error(text            => l_code_cancel_reason || ' - ' || l_desc_cancel_reason,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_epis_hidrics_line_codes;

    /************************************************************************************************************
    * Get the corresponding progress note task type by a given progress note area
    * Used for global search.
    *
    * @param i_pn_area       Progress note area ID
    *
    * @return                Task type ID
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2014/01/06
    ***********************************************************************************************************/
    FUNCTION get_pn_task_type(i_pn_area IN pn_area.id_pn_area%TYPE) RETURN NUMBER IS
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_PN_TASK_TYPE';
        l_task_type task_type.id_task_type%TYPE;
    BEGIN
        /*
        PN_AREA:
        1 - Antecedentes e Exame físico
        2 - Notas do médico
        3 - Visita atual
        4 - Nota de alta
        5 - Avaliações de enfermagem
        6 - Avaliação inicial de enfermagem
        7 - Notas de evolução de enfermagem
        */
        CASE i_pn_area
            WHEN 1 THEN
                /*Nota de entrada*/
                l_task_type := 78;
            WHEN 2 THEN
                /*Notas de evolução do médico*/
                l_task_type := 79;
            WHEN 3 THEN
                /*Visita atual*/
                l_task_type := 76;
            WHEN 4 THEN
                /*Resumo da alta*/
                l_task_type := 73;
            WHEN 5 THEN
                /*Avaliações de enfermagem*/
                l_task_type := 77;
            WHEN 6 THEN
                /*Avaliação inicial de enfermagem*/
                l_task_type := 74;
            WHEN 7 THEN
                /*Notas de evolução de enfermagem*/
                l_task_type := 75;
        END CASE;
    
        RETURN l_task_type;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            RETURN NULL;
    END get_pn_task_type;

    /************************************************************************************************************
    * Get epis progress notes info: episode, patient, professional, date record and task type
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/03
    ***********************************************************************************************************/
    FUNCTION get_epis_pn_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_pn%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT i_rowtype.id_episode,
                   e.id_patient,
                   CASE
                       WHEN i_rowtype.flg_status = g_pn_cancelled THEN
                        i_rowtype.id_prof_cancel
                       WHEN i_rowtype.flg_status IN (g_pn_signed_off, g_pn_migrated, g_pn_temporary) THEN
                        i_rowtype.id_prof_signoff
                       ELSE
                        nvl(i_rowtype.id_prof_last_update, i_rowtype.id_prof_create)
                   END,
                   CASE
                       WHEN i_rowtype.flg_status = g_pn_cancelled THEN
                        i_rowtype.dt_cancel
                       WHEN i_rowtype.flg_status IN (g_pn_signed_off, g_pn_migrated, g_pn_temporary) THEN
                        i_rowtype.dt_signoff
                       ELSE
                        i_rowtype.dt_pn_date
                   END,
                   get_pn_task_type(i_rowtype.id_pn_area)
              FROM episode e
             WHERE e.id_episode = i_rowtype.id_episode;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_PN_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            RETURN NULL;
    END get_epis_pn_info;

    /************************************************************************************************************
    * Get epis progress notes description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/03
    ***********************************************************************************************************/
    PROCEDURE get_epis_pn_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_pn%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_note_type VARCHAR2(100 CHAR);
        l_desc_note_type pk_translation.t_desc_translation;
    
        l_code_cancel_reason VARCHAR2(100 CHAR);
        l_desc_cancel_reason pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_PN_CODES';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        IF i_rowtype.id_pn_note_type IS NOT NULL
        THEN
            l_code_note_type := '' || i_owner || '.' || i_table || '.ID_PN_NOTE_TYPE.' || i_rowtype.id_epis_pn;
            l_desc_note_type := pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_id_pn_note_type    => i_rowtype.id_pn_note_type,
                                                                       i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_desc_d);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_note_type;
            l_desc_list(l_idx) := l_desc_note_type;
        
            pk_alertlog.log_error(text            => l_code_note_type || ' - ' || l_desc_note_type,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        
        END IF;
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            l_code_cancel_reason := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' || i_rowtype.id_epis_pn;
            l_desc_cancel_reason := pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                            i_prof             => i_prof,
                                                                            i_id_cancel_reason => i_rowtype.id_cancel_reason);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_cancel_reason;
            l_desc_list(l_idx) := l_desc_cancel_reason;
        
            pk_alertlog.log_error(text            => l_code_cancel_reason || ' - ' || l_desc_cancel_reason,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_epis_pn_codes;

    /************************************************************************************************************
    * Get epis progress notes det info: episode, patient, professional, date record and task type
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/03
    ***********************************************************************************************************/
    FUNCTION get_epis_pn_det_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_pn_det%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT epn.id_episode,
                   e.id_patient,
                   i_rowtype.id_professional,
                   i_rowtype.dt_pn,
                   get_pn_task_type(epn.id_pn_area)
              FROM epis_pn epn
              JOIN episode e
                ON e.id_episode = epn.id_episode
             WHERE epn.id_epis_pn = i_rowtype.id_epis_pn;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_PN_DET_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            RETURN NULL;
    END get_epis_pn_det_info;

    /************************************************************************************************************
    * Get epis progress notes det description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/03
    ***********************************************************************************************************/
    PROCEDURE get_epis_pn_det_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_pn_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_pn_note VARCHAR2(100 CHAR);
        l_desc_pn_note pk_translation.t_desc_translation;
    
        l_desc_data_block pk_translation.t_desc_translation;
        l_desc_soap_block pk_translation.t_desc_translation;
    
        l_final_desc pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_PN_DET_CODES';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        IF i_rowtype.pn_note IS NOT NULL
        THEN
            l_desc_soap_block := pk_progress_notes_upd.get_soap_block_desc(i_lang             => i_lang,
                                                                           i_prof             => i_prof,
                                                                           i_id_pn_soap_block => i_rowtype.id_pn_soap_block);
        
            l_desc_data_block := pk_progress_notes_upd.get_block_area_desc(i_lang             => i_lang,
                                                                           i_prof             => i_prof,
                                                                           i_id_pn_data_block => i_rowtype.id_pn_data_block);
        
            IF l_desc_soap_block IS NOT NULL
            THEN
                l_final_desc := '[' || l_desc_soap_block || '] ';
            END IF;
        
            IF l_desc_data_block IS NOT NULL
            THEN
                l_final_desc := l_final_desc || '[' || l_desc_data_block || ']' || chr(10);
            END IF;
        
            l_code_pn_note := '' || i_owner || '.' || i_table || '.PN_NOTE.' || i_rowtype.id_epis_pn_det;
            l_desc_pn_note := l_final_desc || i_rowtype.pn_note;
        
            extend_arrays();
            l_code_list(l_idx) := l_code_pn_note;
            l_desc_list(l_idx) := l_desc_pn_note;
        
            pk_alertlog.log_error(text            => l_code_pn_note || ' - ' || l_desc_pn_note,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_epis_pn_det_codes;

    /************************************************************************************************************
    * Get epis progress notes det task info: episode, patient, professional, date record and task type
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/05
    ***********************************************************************************************************/
    FUNCTION get_epis_pn_det_task_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_pn_det_task%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT epn.id_episode,
                   e.id_patient,
                   nvl(i_rowtype.id_prof_last_update, i_rowtype.id_prof_task),
                   nvl(i_rowtype.dt_last_update, i_rowtype.dt_task),
                   get_pn_task_type(epn.id_pn_area)
              FROM epis_pn_det epnd
              JOIN epis_pn epn
                ON epn.id_epis_pn = epnd.id_epis_pn
              JOIN episode e
                ON e.id_episode = epn.id_episode
             WHERE epnd.id_epis_pn_det = i_rowtype.id_epis_pn_det;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_PN_DET_TASK_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            RETURN NULL;
    END get_epis_pn_det_task_info;

    /************************************************************************************************************
    * Get epis progress notes det task description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/05
    ***********************************************************************************************************/
    PROCEDURE get_epis_pn_det_task_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_pn_det_task%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_pn_note VARCHAR2(100 CHAR);
        l_desc_pn_note pk_translation.t_desc_translation;
    
        l_desc_data_block pk_translation.t_desc_translation;
        l_desc_soap_block pk_translation.t_desc_translation;
    
        l_final_desc pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_PN_DET_TASK_CODES';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        IF i_rowtype.pn_note IS NOT NULL
        THEN
            BEGIN
                SELECT pk_progress_notes_upd.get_soap_block_desc(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_id_pn_soap_block => epnd.id_pn_soap_block),
                       pk_progress_notes_upd.get_block_area_desc(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_id_pn_data_block => epnd.id_pn_data_block)
                  INTO l_desc_soap_block, l_desc_data_block
                  FROM epis_pn_det epnd
                 WHERE epnd.id_epis_pn_det = i_rowtype.id_epis_pn_det;
            EXCEPTION
                WHEN no_data_found THEN
                    l_desc_soap_block := NULL;
                    l_desc_data_block := NULL;
            END;
        
            IF l_desc_soap_block IS NOT NULL
            THEN
                l_final_desc := '[' || l_desc_soap_block || '] ';
            END IF;
        
            IF l_desc_data_block IS NOT NULL
            THEN
                l_final_desc := l_final_desc || '[' || l_desc_data_block || ']' || chr(10);
            END IF;
        
            l_code_pn_note := '' || i_owner || '.' || i_table || '.PN_NOTE.' || i_rowtype.id_epis_pn_det_task;
            l_desc_pn_note := l_final_desc || i_rowtype.pn_note;
        
            extend_arrays();
            l_code_list(l_idx) := l_code_pn_note;
            l_desc_list(l_idx) := l_desc_pn_note;
        
            pk_alertlog.log_error(text            => l_code_pn_note || ' - ' || l_desc_pn_note,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_epis_pn_det_task_codes;

    /************************************************************************************************************
    * Get epis progress notes addendum info: episode, patient, professional, date record and task type
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/04
    ***********************************************************************************************************/
    FUNCTION get_epis_pn_addendum_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_pn_addendum%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT epn.id_episode,
                   e.id_patient,
                   CASE
                       WHEN i_rowtype.flg_status = g_addendum_cancelled THEN
                        i_rowtype.id_prof_cancel
                       WHEN i_rowtype.flg_status IN (g_addendum_signed_off, g_addendum_finalized) THEN
                        i_rowtype.id_prof_signoff
                       WHEN i_rowtype.flg_status = g_addendum_draft THEN
                        nvl(i_rowtype.id_prof_last_update, i_rowtype.id_professional)
                   END,
                   CASE
                       WHEN i_rowtype.flg_status = g_addendum_cancelled THEN
                        i_rowtype.dt_cancel
                       WHEN i_rowtype.flg_status IN (g_addendum_signed_off, g_addendum_finalized) THEN
                        i_rowtype.dt_signoff
                       WHEN i_rowtype.flg_status = g_addendum_draft THEN
                        nvl(i_rowtype.dt_last_update, i_rowtype.dt_addendum)
                   END,
                   get_pn_task_type(epn.id_pn_area)
              FROM epis_pn epn
              JOIN episode e
                ON e.id_episode = epn.id_episode
             WHERE epn.id_epis_pn = i_rowtype.id_epis_pn;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_PN_ADDENDUM_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            RETURN NULL;
    END get_epis_pn_addendum_info;

    /************************************************************************************************************
    * Get epis progress notes addendum description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/04
    ***********************************************************************************************************/
    PROCEDURE get_epis_pn_addendum_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_pn_addendum%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_cancel_reason VARCHAR2(100 CHAR);
        l_desc_cancel_reason pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_PN_ADDENDUM_CODES';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        IF i_rowtype.id_cancel_reason IS NOT NULL
        THEN
            l_code_cancel_reason := '' || i_owner || '.' || i_table || '.ID_CANCEL_REASON.' ||
                                    i_rowtype.id_epis_pn_addendum;
            l_desc_cancel_reason := pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, i_rowtype.id_cancel_reason);
        
            extend_arrays();
            l_code_list(l_idx) := l_code_cancel_reason;
            l_desc_list(l_idx) := l_desc_cancel_reason;
        
            pk_alertlog.log_error(text            => l_code_cancel_reason || ' - ' || l_desc_cancel_reason,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_epis_pn_addendum_codes;

    /************************************************************************************************************
    * Get epis progress notes signoff info: episode, patient, professional, date record and task type
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/05
    ***********************************************************************************************************/
    FUNCTION get_epis_pn_signoff_info
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_pn_signoff%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT epn.id_episode,
                   e.id_patient,
                   coalesce(i_rowtype.id_prof_last_update, epn.id_prof_signoff, epn.id_prof_last_update),
                   coalesce(i_rowtype.dt_last_update, epn.dt_signoff, epn.dt_last_update, current_timestamp),
                   get_pn_task_type(epn.id_pn_area)
              FROM epis_pn epn
              JOIN episode e
                ON e.id_episode = epn.id_episode
             WHERE epn.id_epis_pn = i_rowtype.id_epis_pn;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_PN_SIGNOFF_INFO';
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text            => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient ||
                                                 ' - ' || l_trl_trs_result.id_professional || ' - ' ||
                                                 l_trl_trs_result.dt_record,
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
        RETURN l_trl_trs_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            RETURN NULL;
    END get_epis_pn_signoff_info;

    /************************************************************************************************************
    * Get epis progress notes signoff description
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_prof          professional identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Vanessa Barsottelli
    * @version               2.6.3
    * @since                 2013/12/05
    ***********************************************************************************************************/
    PROCEDURE get_epis_pn_signoff_codes
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_pn_signoff%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_signoff_note VARCHAR2(100 CHAR);
        l_desc_signoff_note pk_translation.t_desc_translation;
    
        l_desc_soap_block pk_translation.t_desc_translation;
    
        l_final_desc pk_translation.t_desc_translation;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        l_idx NUMBER(24) := 0;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'GET_EPIS_PN_SIGNOFF_CODES';
    
        PROCEDURE extend_arrays IS
        BEGIN
            l_idx := l_idx + 1;
            l_code_list.extend;
            l_desc_list.extend;
        END extend_arrays;
    
    BEGIN
    
        IF i_rowtype.pn_signoff_note IS NOT NULL
        THEN
            l_desc_soap_block := pk_progress_notes_upd.get_soap_block_desc(i_lang             => i_lang,
                                                                           i_prof             => i_prof,
                                                                           i_id_pn_soap_block => i_rowtype.id_pn_soap_block);
        
            IF l_desc_soap_block IS NOT NULL
            THEN
                l_final_desc := '[' || l_desc_soap_block || '] ' || chr(10);
            END IF;
        
            l_code_signoff_note := '' || i_owner || '.' || i_table || '.PN_SIGNOFF_NOTE.' ||
                                   i_rowtype.id_epis_pn_signoff;
            l_desc_signoff_note := l_final_desc || i_rowtype.pn_signoff_note;
        
            extend_arrays();
            l_code_list(l_idx) := l_code_signoff_note;
            l_desc_list(l_idx) := l_desc_signoff_note;
        
            pk_alertlog.log_error(text            => l_code_signoff_note || ' - ' || l_desc_signoff_note,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name);
        
        END IF;
    
        o_code_list := l_code_list;
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => k_function_name);
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
    END get_epis_pn_signoff_codes;

BEGIN

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);

END pk_inp_global_search;
/
