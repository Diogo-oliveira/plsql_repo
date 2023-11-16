/*-- Last Change Revision: $Rev: 2027818 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_trauma_core IS
    --
    --
    /**********************************************************************************************
    * Calculates Revised Trauma Score (RTS). 
    * IMPORTANT!! This function is for specific use by Announced Arrival (Dashboard)!!
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_vital_sign         Array with the vital signs ID
    * @param i_value              Array with the registered values
    * @param o_score              Revised Trauma Score
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_rts_score
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_vital_sign IN table_number,
        i_value      IN table_number,
        o_score      OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'GET_RTS_SCORE';
        l_common_error EXCEPTION;
        l_error_msg VARCHAR2(200);
        --
        l_total_aux NUMBER(6, 4) := 0;
    BEGIN
    
        IF i_vital_sign.exists(1)
        THEN
            g_error := 'CHECK PARAMETERS';
            pk_alertlog.log_debug(g_error);
            IF i_vital_sign.count <> i_value.count
            THEN
                l_error_msg := 'INVALID ARRAY SIZE';
                RAISE l_common_error;
            END IF;
        
            g_error := 'START LOOP';
            pk_alertlog.log_debug(g_error);
            FOR i IN i_vital_sign.first .. i_vital_sign.last
            LOOP
                IF i_value(i) IS NOT NULL
                THEN
                    g_error := 'CALCULATE SCORE - ' || i_vital_sign(i);
                    pk_alertlog.log_debug(g_error);
                    SELECT (mpe.value * mtm.multiplier_value) + l_total_aux
                      INTO l_total_aux
                      FROM mtos_param_value      mpe,
                           mtos_multiplier       mtm,
                           mtos_param            mpm,
                           mtos_score            mse,
                           mtos_param_value_task mpvt,
                           mtos_param_task       mpt
                     WHERE mpvt.id_mtos_param_value(+) = mpe.id_mtos_param_value                     
                       AND mpm.id_mtos_param = mpe.id_mtos_param
                       AND mpm.id_mtos_score = mse.id_mtos_score
                       AND mpt.id_mtos_param(+) = mpm.id_mtos_param             
                       AND decode(mpvt.flg_param_task_type,
                                  pk_sev_scores_constant.g_flg_param_task_vital_sign,
                                  mpt.id_param_task,
                                  NULL) = decode(mtm.flg_param_task_type,
                                                 pk_sev_scores_constant.g_flg_param_task_vital_sign,
                                                 mtm.id_param_task,
                                                 NULL)                                 
                       AND mse.flg_score_type = pk_sev_scores_constant.g_flg_score_rts -- Revised Trauma Score                       
                       AND decode(mpvt.flg_param_task_type,
                                  pk_sev_scores_constant.g_flg_param_task_vital_sign,
                                  mpt.id_param_task,
                                  NULL) = i_vital_sign(i)
                       AND decode(mpvt.flg_param_task_type,
                                  pk_sev_scores_constant.g_flg_param_task_vital_sign,
                                  mpvt.min_val,
                                  NULL) <= i_value(i)
                       AND decode(mpvt.flg_param_task_type,
                                  pk_sev_scores_constant.g_flg_param_task_vital_sign,
                                  mpvt.max_val,
                                  NULL) >= i_value(i)
                       AND mtm.flg_parameter = pk_sev_scores_constant.g_parameter_vs
                       AND mtm.flg_multiplier_type = pk_sev_scores_constant.g_multiplier_normal
                       AND mpe.flg_available = pk_alert_constant.g_yes
                       AND mtm.flg_available = pk_alert_constant.g_yes
                       AND mpm.flg_available = pk_alert_constant.g_yes
                       AND mse.flg_available = pk_alert_constant.g_yes;
                
                ELSE
                    -- All values need to be provided in order to calculate the RTS total.
                    -- If one NULL value is found, terminate the execution and return NULL.
                    l_total_aux := NULL;
                    EXIT;
                END IF;
            END LOOP;
        END IF;
    
        o_score := round(l_total_aux, 3);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_common_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_COMMON_ERROR',
                                              l_error_msg,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rts_score;
    --
    /**
    * Gets the TRISS score ID
    *
    * @param   i_lang                  Professional preferred language
    *
    * @return  TRISS ID
    *
    * @author  José Silva
    * @version v2.6.0.3
    * @since   08-09-2010
    */
    FUNCTION get_triss_id_score(i_lang IN language.id_language%TYPE) RETURN NUMBER IS
        l_func_name VARCHAR2(30) := 'GET_TRISS_ID_SCORE';
        l_error     t_error_out;
        --
        l_score_triss mtos_score.id_mtos_score%TYPE;
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'GET ID TRISS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT m.id_mtos_score
          INTO l_score_triss
          FROM mtos_score m
         WHERE m.flg_score_type = pk_sev_scores_constant.g_flg_score_triss;
    
        RETURN l_score_triss;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_triss_id_score;
    --
    /**********************************************************************************************
    * Database internal function. Used to return the total value of a given score.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_patient         Patient ID
    * @param i_id_mtos_param      ID's of the score parameters
    * @param i_value              Registered values for each parameter
    * @param i_flg_score_type     Type of score
    * @param i_calculate_age      (Y) Calculate patient age in years (N) Do not calculate
    * @param i_pat_age_years      Patient age (in years)
    * @param o_score_a            Total score value
    * @param o_score_b            Total score second value, if applicable (only for TRISS)
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_total_score_internal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_mtos_param  IN table_number,
        i_value          IN table_number,
        i_flg_score_type IN mtos_score.flg_score_type%TYPE,
        i_calculate_age  IN VARCHAR2,
        i_pat_age_years  IN NUMBER,
        o_score_a        OUT NUMBER,
        o_score_b        OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_total pk_types.cursor_type;
    
    BEGIN
    
        RETURN pk_sev_scores_core.get_total_score_internal(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_id_patient     => i_id_patient,
                                                           i_id_mtos_param  => i_id_mtos_param,
                                                           i_value          => i_value,
                                                           i_flg_score_type => i_flg_score_type,
                                                           i_calculate_age  => i_calculate_age,
                                                           i_pat_age_years  => i_pat_age_years,
                                                           o_score_a        => o_score_a,
                                                           o_score_b        => o_score_b,
                                                           o_total          => l_total,
                                                           o_error          => o_error);
    
    END get_total_score_internal;
    --
    /**********************************************************************************************
    * Database internal function. Used to return the total value of a given score.
    * This function is used during the screen loading, so the scores are correctly shown.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_id_patient         Patient ID
    * @param i_flg_score_type     Type of score   
    * @param i_total_glasgow      Glasgow total score (needed for RTS)
    * @param i_total_rts          RTS total score (needed for TRISS)
    * @param i_total_iss          ISS total score (needed for TRISS)
    * @param i_pat_age_years      Patient age (in years)
    * @param o_score_a            Total score value
    * @param o_score_b            Total score second value, if applicable (only for TRISS)
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_total_score_aux
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_flg_score_type IN mtos_score.flg_score_type%TYPE,
        i_total_glasgow  IN NUMBER, -- Needed for RTS
        i_total_rts      IN NUMBER, -- Needed for TRISS
        i_total_iss      IN NUMBER, -- Needed for TRISS
        i_pat_age_years  IN NUMBER,
        o_score_a        OUT NUMBER,
        o_score_b        OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_sev_scores_core.get_total_score_aux(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_episode     => i_id_episode,
                                                      i_id_patient     => i_id_patient,
                                                      i_flg_score_type => i_flg_score_type,
                                                      i_total_glasgow  => i_total_glasgow,
                                                      i_total_rts      => i_total_rts,
                                                      i_total_iss      => i_total_iss,
                                                      i_pat_age_years  => i_pat_age_years,
                                                      o_score_a        => o_score_a,
                                                      o_score_b        => o_score_b,
                                                      o_error          => o_error);
    
    END get_total_score_aux;
    --
    /**********************************************************************************************
    * Returns the total value for a given score.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_patient         Patient ID
    * @param i_id_mtos_param      ID's of the score parameters
    * @param i_value              Registered values for each parameter
    * @param i_flg_score_type     Type of score
    * @param o_total              Cursor with the results
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_total_score
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_mtos_param  IN table_number,
        i_value          IN table_number,
        i_flg_score_type IN mtos_score.flg_score_type%TYPE,
        o_total          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_viewer pk_types.cursor_type;
    BEGIN
    
        RETURN pk_sev_scores_core.get_total_score(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_id_patient         => i_id_patient,
                                                  i_id_mtos_param      => i_id_mtos_param,
                                                  i_value              => i_value,
                                                  i_flg_score_type     => i_flg_score_type,
                                                  i_vs_scales_elements => table_number(),
                                                  o_total              => o_total,
                                                  o_viewer             => l_viewer,
                                                  o_error              => o_error);
    
    END get_total_score;
    --
    /**********************************************************************************************
    * Database internal function. Used to return the total value of TRISS score.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_episode            Episode ID
    * @param i_id_patient         Patient ID
    * @param i_pat_age_years      Patient age (in years)
    * @param o_total_glasgow      Glasgow total score (needed for RTS)
    * @param o_total_rts          RTS total score (needed for TRISS)
    * @param o_total_iss          ISS total score (needed for TRISS)
    * @param o_total_pts          PTS total score (needed for TRISS)
    * @param o_total_triss_b      TRISS total score (blunt)
    * @param o_total_triss_p      TRISS total score (penetrating)
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_total_triss
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_pat_age_years IN NUMBER,
        o_total_glasgow OUT NUMBER, -- Needed for RTS
        o_total_rts     OUT NUMBER, -- Needed for TRISS
        o_total_iss     OUT NUMBER, -- Needed for TRISS
        o_total_pts     OUT NUMBER,
        o_total_triss_b OUT NUMBER,
        o_total_triss_p OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'GET_TOTAL_TRISS';
        l_internal_error EXCEPTION;
    
        l_total_gcs     NUMBER(6, 4);
        l_total_pts     NUMBER(6, 4);
        l_total_rts     NUMBER(6, 4);
        l_total_iss     NUMBER(6, 4);
        l_total_triss_b NUMBER(6, 4);
        l_total_triss_p NUMBER(6, 4);
        l_dummy         NUMBER(6, 4);
    
    BEGIN
    
        -- Get TOTAL SCORES
        -- Please do not change the order of the functions.
        -- There are dependencies between the score results.
        g_error := 'GET TOTAL - GCS';
        pk_alertlog.log_debug(g_error);
        IF NOT get_total_score_aux(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_id_episode     => i_episode,
                                   i_id_patient     => i_id_patient,
                                   i_flg_score_type => pk_sev_scores_constant.g_flg_score_gcs,
                                   i_total_glasgow  => NULL,
                                   i_total_rts      => NULL,
                                   i_total_iss      => NULL,
                                   i_pat_age_years  => i_pat_age_years,
                                   o_score_a        => l_total_gcs,
                                   o_score_b        => l_dummy,
                                   o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'GET TOTAL - PTS';
        pk_alertlog.log_debug(g_error);
        IF NOT get_total_score_aux(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_id_episode     => i_episode,
                                   i_id_patient     => i_id_patient,
                                   i_flg_score_type => pk_sev_scores_constant.g_flg_score_pts,
                                   i_total_glasgow  => NULL,
                                   i_total_rts      => NULL,
                                   i_total_iss      => NULL,
                                   i_pat_age_years  => i_pat_age_years,
                                   o_score_a        => l_total_pts,
                                   o_score_b        => l_dummy,
                                   o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'GET TOTAL - RTS';
        pk_alertlog.log_debug(g_error);
        IF NOT get_total_score_aux(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_id_episode     => i_episode,
                                   i_id_patient     => i_id_patient,
                                   i_flg_score_type => pk_sev_scores_constant.g_flg_score_rts,
                                   i_total_glasgow  => l_total_gcs,
                                   i_total_rts      => NULL,
                                   i_total_iss      => NULL,
                                   i_pat_age_years  => i_pat_age_years,
                                   o_score_a        => l_total_rts,
                                   o_score_b        => l_dummy,
                                   o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'GET TOTAL - ISS';
        pk_alertlog.log_debug(g_error);
        IF NOT get_total_score_aux(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_id_episode     => i_episode,
                                   i_id_patient     => i_id_patient,
                                   i_flg_score_type => pk_sev_scores_constant.g_flg_score_iss,
                                   i_total_glasgow  => NULL,
                                   i_total_rts      => NULL,
                                   i_total_iss      => NULL,
                                   i_pat_age_years  => i_pat_age_years,
                                   o_score_a        => l_total_iss,
                                   o_score_b        => l_dummy,
                                   o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'GET TOTAL - TRISS';
        pk_alertlog.log_debug(g_error);
        IF NOT get_total_score_aux(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_id_episode     => i_episode,
                                   i_id_patient     => i_id_patient,
                                   i_flg_score_type => pk_sev_scores_constant.g_flg_score_triss,
                                   i_total_glasgow  => NULL,
                                   i_total_rts      => l_total_rts,
                                   i_total_iss      => l_total_iss,
                                   i_pat_age_years  => i_pat_age_years,
                                   o_score_a        => l_total_triss_b,
                                   o_score_b        => l_total_triss_p,
                                   o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        o_total_glasgow := l_total_gcs;
        o_total_rts     := l_total_rts;
        o_total_iss     := l_total_iss;
        o_total_pts     := l_total_pts;
        o_total_triss_b := l_total_triss_b;
        o_total_triss_p := l_total_triss_p;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_total_triss;
    --
    /**********************************************************************************************
    * Returns the available scores. Used by Flash to know how many blocks must be shown, 
    * one block for each score.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID for each parameter
    * @param o_score              Cursor with the available scores
    * @param o_flg_detail         Activate the DETAIL button: (Y)es (N)o
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_mtos_score
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_score      OUT pk_types.cursor_type,
        o_flg_detail OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'GET_MTOS_SCORE';
        l_internal_error EXCEPTION;
        --
        l_score_triss mtos_score.id_mtos_score%TYPE;
    BEGIN
    
        g_error := 'CALL TO PK_SEV_SCORES_CORE.GET_MTOS_SCORE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sev_scores_core.get_mtos_score(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_id_episode => i_id_episode,
                                                 i_mtos_score => get_triss_id_score(i_lang),
                                                 o_score      => o_score,
                                                 o_flg_detail => o_flg_detail,
                                                 o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_score);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_score);
            RETURN FALSE;
    END get_mtos_score;
    --
    /**********************************************************************************************
    * Shows all parameters for all scores.
    * Returns the parameters properties and current value.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_episode            Episode ID
    * @param i_id_epis_mtos_score Score ID (currently not needed)
    * @param o_list               Cursor with the parameters
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_mtos_param_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_mtos_score epis_mtos_score.id_epis_mtos_score%TYPE;
    
    BEGIN
    
        -- Get most recent saved SCORE
        BEGIN
            g_error := 'GET LATEST SCORE';
            pk_alertlog.log_debug(g_error);
            SELECT t.id_epis_mtos_score
              INTO l_id_epis_mtos_score
              FROM (SELECT ems.id_epis_mtos_score,
                           ems.id_episode,
                           row_number() over(PARTITION BY id_episode ORDER BY ems.dt_create DESC) row_number
                      FROM epis_mtos_score ems
                      JOIN epis_mtos_param ep
                        ON ep.id_epis_mtos_score = ems.id_epis_mtos_score
                      JOIN mtos_param mp
                        ON mp.id_mtos_param = ep.id_mtos_param
                     WHERE ems.flg_status = pk_sev_scores_constant.g_flg_status_a
                       AND mp.id_mtos_score = get_triss_id_score(i_lang)) t
             WHERE t.id_episode = i_episode
               AND row_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_mtos_score := NULL;
        END;
    
        --SUBSTITUIR por GET_TRISS_PARAM_LIST
        RETURN pk_sev_scores_core.get_sev_score_param_list(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_episode         => i_episode,
                                                           i_mtos_score      => get_triss_id_score(i_lang),
                                                           i_epis_mtos_score => l_id_epis_mtos_score,
                                                           o_list            => o_list,
                                                           o_error           => o_error);
    
    END get_mtos_param_list;
    --
    /**********************************************************************************************
    * Returns the history of scores for the current episode. Results shown in the detail screen.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param o_reg                Cursor with the scores
    * @param o_value              Cursor with the parameters and registered values
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_mtos_param_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_reg        OUT pk_types.cursor_type,
        o_value      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_groups pk_types.cursor_type;
        l_cancel pk_types.cursor_type;
    
    BEGIN
    
        RETURN pk_sev_scores_core.get_sev_scores_values(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_patient      => pk_episode.get_id_patient(i_id_episode),
                                                        i_id_episode      => i_id_episode,
                                                        i_mtos_score      => get_triss_id_score(i_lang),
                                                        i_epis_mtos_score => NULL,
                                                        o_reg             => o_reg,
                                                        o_groups          => l_groups,
                                                        o_values          => o_value,
                                                        o_cancel          => l_cancel,
                                                        o_error           => o_error);
    
    END get_mtos_param_detail;
    --
    /**********************************************************************************************
    * Returns the options for the parameters filled by multichoice.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_mtos_param      Parameter ID
    * @param i_flg_score_type     Type of score
    * @param i_id_patient         Patient ID
    * @param o_list               Cursor with the results
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_param_options
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_mtos_param  IN mtos_param.id_mtos_param%TYPE,
        i_flg_score_type IN mtos_score.flg_score_type%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'GET_PARAM_OPTIONS';
        --
        l_flg_fill_type mtos_param.flg_fill_type%TYPE;
        l_id_vital_sign vital_sign.id_vital_sign%TYPE;
    BEGIN
    
        g_error := 'GET PARAM INFO';
        pk_alertlog.log_debug(g_error);
        SELECT mpm.flg_fill_type,
               decode(mpm.flg_param_task_type,
                      pk_sev_scores_constant.g_flg_param_task_vital_sign,
                      mpm.id_param_task,
                      NULL)
          INTO l_flg_fill_type, l_id_vital_sign
          FROM mtos_param mpm
         WHERE mpm.id_mtos_param = i_id_mtos_param;
    
        IF l_flg_fill_type = pk_sev_scores_constant.g_flg_fill_type_m
           AND l_id_vital_sign IS NULL -- Parameters selected by multichoice that ARE NOT vital signs
        THEN
            g_error := 'GET OPTION LIST (1)';
            pk_alertlog.log_debug(g_error);
            OPEN o_list FOR
                SELECT t.data, t.label, t.value
                  FROM (SELECT mpe.id_mtos_param_value data,
                               decode(i_flg_score_type,
                                      pk_sev_scores_constant.g_flg_score_iss, -- ISS score options show the score value
                                      mpe.value || ' - ' ||
                                      pk_translation.get_translation(i_lang, mpe.code_mtos_param_value),
                                      pk_translation.get_translation(i_lang, mpe.code_mtos_param_value)) label,
                               mpe.value, -- Needed for the ISS evaluation (to know if the value is 6)
                               mpe.rank
                          FROM mtos_param_value mpe
                         WHERE mpe.id_mtos_param = i_id_mtos_param
                           AND mpe.flg_available = pk_alert_constant.g_yes
                        UNION ALL
                        SELECT -1 data, pk_message.get_message(i_lang, 'COMMON_M002') label, NULL VALUE, -1 rank
                          FROM dual) t
                 ORDER BY rank;
        
        ELSIF l_flg_fill_type = pk_sev_scores_constant.g_flg_fill_type_m
              AND l_id_vital_sign IS NOT NULL -- Parameters selected by multichoice that ARE vital signs
        THEN
            g_error := 'GET OPTION LIST (2)';
            pk_alertlog.log_debug(g_error);
            OPEN o_list FOR
                SELECT data, label
                  FROM (SELECT vsd.id_vital_sign_desc data,
                               pk_vital_sign.get_vs_alias(i_lang, i_id_patient, vsd.code_vital_sign_desc) label,
                               vsd.rank
                          FROM vital_sign_desc vsd
                         WHERE vsd.id_vital_sign = l_id_vital_sign
                           AND vsd.flg_available = pk_alert_constant.g_yes
                        UNION ALL
                        SELECT -1 data, pk_message.get_message(i_lang, 'COMMON_M002') label, -1 rank
                          FROM dual)
                 ORDER BY rank;
        
        ELSE
            pk_types.open_my_cursor(o_list);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Saves a score and all the registered values.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_prof_cat           Professional category
    * @param i_id_episode         Episode ID
    * @param i_id_patient         Patient ID
    * @param i_id_mtos_param      Array of parameter ID's
    * @param i_value              Array with the registered values
    * @param i_unit_measure       Array with unit measures
    * @param o_flg_detail         Activate the DETAIL button: (Y)es (N)o
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION set_mtos_score
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat      IN category.flg_type%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_mtos_param IN table_number,
        i_value         IN table_number,
        i_unit_measure  IN table_number,
        o_flg_detail    OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200) := 'SET_MTOS_SCORE';
        l_internal_error EXCEPTION;
        l_common_error   EXCEPTION;
        l_save_vs_error  EXCEPTION;
        l_error_msg VARCHAR2(200);
        --
        l_rowids  table_varchar;
        l_sysdate TIMESTAMP WITH LOCAL TIME ZONE;
        --
        l_new_vital_sign_read table_number;
        --
        l_epis_mtos_score      epis_mtos_score.id_epis_mtos_score%TYPE := NULL;
        l_next_epis_mtos_score epis_mtos_score.id_epis_mtos_score%TYPE := NULL;
        l_id_vital_sign        vital_sign.id_vital_sign%TYPE;
        l_id_vital_sign_read   vital_sign_read.id_vital_sign_read%TYPE;
        l_internal_name        mtos_param.internal_name%TYPE;
        l_sys_alert_event      sys_alert_event%ROWTYPE;
        l_alert_processed      BOOLEAN := FALSE;
        l_age_processed        BOOLEAN := FALSE;
        --
        l_curr_pat_age  VARCHAR2(30);
        l_pat_age_years NUMBER(6);
        --
        -- arrays used to call the function that saves vital signs
        l_tab_param    table_number := table_number(); -- Parameter ID's
        l_tab_vs_id    table_number := table_number(); -- Vital signs ID's
        l_tab_vs_value table_number := table_number(); -- Registered values in vital signs
        l_tab_vs_um    table_number := table_number(); -- Vital signs unit measures
        l_counter      NUMBER(6) := 0;
        l_exists_vs    NUMBER(6) := 0;
        l_dt_registry  VARCHAR2(20 CHAR);
    BEGIN
        l_sysdate := current_timestamp;
    
        g_error := 'CHECK ARRAYS';
        IF NOT i_id_mtos_param.exists(1)
        THEN
            RETURN TRUE;
        ELSIF i_id_mtos_param.count <> i_value.count
              OR i_id_mtos_param.count <> i_unit_measure.count
        THEN
            l_error_msg := 'INVALID ARRAY SIZES';
            RAISE l_common_error;
        END IF;
    
        g_error := 'GET OLD SCORE EVALUATION ID - OUTDATED';
        pk_alertlog.log_debug(g_error);
        SELECT nvl((SELECT ems.id_epis_mtos_score
                     FROM epis_mtos_score ems
                    WHERE ems.id_episode = i_id_episode
                      AND ems.id_mtos_score = get_triss_id_score(i_lang)
                      AND ems.flg_status = pk_sev_scores_constant.g_flg_status_a),
                   NULL)
          INTO l_epis_mtos_score
          FROM dual;
    
        IF l_epis_mtos_score IS NOT NULL
        THEN
            -- Set active score evaluation as outdated
            g_error := 'UPDATE SCORE - OUTDATED';
            pk_alertlog.log_debug(g_error);
            ts_epis_mtos_score.upd(flg_status_in => pk_sev_scores_constant.g_flg_status_o,
                                   where_in      => 'id_epis_mtos_score = ' || l_epis_mtos_score,
                                   rows_out      => l_rowids);
        
            g_error := 'PROCESS UPDATE - EPIS_MTOS_SCORE';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_MTOS_SCORE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            l_rowids := table_varchar();
        
        END IF;
    
        -- Save parameters
        g_error := 'START PARAMETERS LOOP';
        pk_alertlog.log_debug(g_error);
        FOR i IN i_id_mtos_param.first .. i_id_mtos_param.last
        LOOP
        
            g_error := 'GET PARAM INFO';
            pk_alertlog.log_debug(g_error);
            SELECT decode(mpm.flg_param_task_type,
                          pk_sev_scores_constant.g_flg_param_task_vital_sign,
                          mpm.id_param_task,
                          NULL),
                   mpm.internal_name
              INTO l_id_vital_sign, l_internal_name
              FROM mtos_param mpm
             WHERE mpm.id_mtos_param = i_id_mtos_param(i);
        
            IF i_value(i) IS NOT NULL -- Save parameter only if has value
            THEN
            
                IF l_next_epis_mtos_score IS NULL
                THEN
                    -- New MTOS score ID
                    l_next_epis_mtos_score := ts_epis_mtos_score.next_key;
                
                    -- Create new score
                    g_error := 'CREATE NEW SCORE';
                    pk_alertlog.log_debug(g_error);
                    ts_epis_mtos_score.ins(id_epis_mtos_score_in        => l_next_epis_mtos_score,
                                           id_episode_in                => i_id_episode,
                                           flg_status_in                => pk_sev_scores_constant.g_flg_status_a,
                                           id_prof_create_in            => i_prof.id,
                                           dt_create_in                 => l_sysdate,
                                           id_epis_mtos_score_parent_in => l_epis_mtos_score,
                                           id_mtos_score_in             => get_triss_id_score(i_lang),
                                           rows_out                     => l_rowids);
                
                    g_error := 'PROCESS INSERT - EPIS_MTOS_SCORE';
                    pk_alertlog.log_debug(g_error);
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_MTOS_SCORE',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    l_rowids := table_varchar();
                END IF;
            
                l_id_vital_sign_read := NULL; -- Reset variable for vital_sign_read
            
                IF l_id_vital_sign IS NOT NULL
                   AND l_internal_name <> 'G_TOTAL' -- Total Glasgow must not be saved in VITAL_SIGN_READ
                THEN
                
                    -- Check if the vital is already processed. This avoids duplication of records in VITAL_SIGN_READ.
                    g_error := 'CHECK VS EXISTS';
                    pk_alertlog.log_debug(g_error);
                    SELECT COUNT(*)
                      INTO l_exists_vs
                      FROM TABLE(l_tab_vs_id)
                     WHERE column_value = l_id_vital_sign;
                
                    IF l_exists_vs = 0
                    THEN
                        -- Increment counter
                        l_counter := l_counter + 1;
                    
                        -- Fill arrays to save vital signs
                        g_error := 'PROCESS VITAL SIGN ARRAYS';
                        pk_alertlog.log_debug(g_error);
                        l_tab_param.extend;
                        l_tab_vs_id.extend;
                        l_tab_vs_value.extend;
                        l_tab_vs_um.extend;
                    
                        l_tab_param(l_counter) := i_id_mtos_param(i);
                        l_tab_vs_id(l_counter) := l_id_vital_sign;
                        l_tab_vs_value(l_counter) := i_value(i);
                        l_tab_vs_um(l_counter) := i_unit_measure(i);
                    END IF;
                
                ELSIF l_internal_name = 'PAT_AGE'
                      AND NOT l_age_processed
                THEN
                    -- Process patient age (check if it was changed)
                    g_error := 'GET PATIENT CURRENT AGE';
                    pk_alertlog.log_debug(g_error);
                    l_curr_pat_age := pk_patient.get_pat_age(i_lang, i_id_patient, i_prof);
                
                    g_error := 'GET PATIENT AGE (YEARS)';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_sev_scores_core.get_pat_age_years(i_lang  => i_lang,
                                                                i_prof  => i_prof,
                                                                i_age   => l_curr_pat_age,
                                                                o_age   => l_pat_age_years,
                                                                o_error => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                
                    IF nvl(l_pat_age_years, -1) <> i_value(i)
                    THEN
                        -- CHANGE PATIENT AGE
                        -- SET DT_BIRTH AS NULL
                        g_error := 'SET NEW PATIENT ATTRIBUTES';
                        pk_alertlog.log_debug(g_error);
                        ts_patient.upd(id_patient_in => i_id_patient,
                                       dt_birth_in   => NULL,
                                       dt_birth_nin  => FALSE,
                                       age_in        => i_value(i),
                                       rows_out      => l_rowids);
                    
                        g_error := 'PROCESS UPDATE - PATIENT';
                        pk_alertlog.log_debug(g_error);
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PATIENT',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        l_rowids := table_varchar();
                    END IF;
                
                    l_age_processed := TRUE;
                
                ELSIF l_internal_name IN ('TRISS_TOTAL_P', 'TRISS_TOTAL_B')
                      AND NOT l_alert_processed
                THEN
                    -- TRISS total will be saved. This means the score is complete. 
                    -- It's time to delete the 
                    l_sys_alert_event.id_sys_alert := pk_sev_scores_constant.g_trauma_alert;
                    l_sys_alert_event.id_episode   := i_id_episode;
                    l_sys_alert_event.id_record    := i_id_episode;
                
                    g_error := 'DELETE FROM SYS_ALERT_EVENT';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            o_error           => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                
                    l_alert_processed := TRUE; -- Alert was processed.
                
                END IF;
            
                -- SAVE PARAMETER!
                g_error := 'CREATE NEW PARAM';
                pk_alertlog.log_debug(g_error);
                ts_epis_mtos_param.ins(id_epis_mtos_param_in => seq_epis_mtos_param.nextval,
                                       id_epis_mtos_score_in => l_next_epis_mtos_score,
                                       id_mtos_param_in      => i_id_mtos_param(i),
                                       registered_value_in   => i_value(i),
                                       id_prof_create_in     => i_prof.id,
                                       dt_create_in          => l_sysdate,
                                       rows_out              => l_rowids);
            
                g_error := 'PROCESS INSERT - EPIS_MTOS_PARAM';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_MTOS_PARAM',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            ELSIF i_value(i) IS NULL
                  AND l_internal_name IN ('PAT_AGE')
                  AND NOT l_age_processed
            THEN
                -- If AGE is NULL, then the patient data must be updated.
                -- However, the parameter is not saved in EPIS_MTOS_PARAM.
                g_error := 'SET NEW PATIENT ATTRIBUTES';
                pk_alertlog.log_debug(g_error);
                ts_patient.upd(id_patient_in => i_id_patient,
                               dt_birth_in   => NULL,
                               dt_birth_nin  => FALSE,
                               age_in        => i_value(i),
                               age_nin       => FALSE,
                               rows_out      => l_rowids);
            
                g_error := 'PROCESS UPDATE - PATIENT';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PATIENT',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                l_rowids := table_varchar();
            
                l_age_processed := TRUE;
            
            ELSIF i_value(i) IS NULL
                  AND l_internal_name IN ('TRISS_TOTAL_P', 'TRISS_TOTAL_B')
                  AND NOT l_alert_processed
            THEN
                -- NULL value found. Check it if's TRISS total to process the 
                g_error := 'INSERT INTO SYS_ALERT_EVENT';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_sys_alert           => pk_sev_scores_constant.g_trauma_alert,
                                                        i_id_episode          => i_id_episode,
                                                        i_id_record           => i_id_episode,
                                                        i_dt_record           => l_sysdate,
                                                        i_id_professional     => NULL,
                                                        i_id_room             => NULL,
                                                        i_id_clinical_service => NULL,
                                                        i_flg_type_dest       => NULL,
                                                        i_replace1            => NULL,
                                                        o_error               => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                l_alert_processed := TRUE; -- Alert was processed.
            
            END IF;
        END LOOP;
    
        IF l_tab_vs_value IS NOT NULL
           AND l_tab_vs_value.count > 0
        THEN
            -- Save vital signs
            g_error := 'CALL TO PK_VITAL_SIGN.SET_EPIS_VITAL_SIGN';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_vital_sign.set_epis_vital_sign(i_lang               => i_lang,
                                                     i_episode            => i_id_episode,
                                                     i_prof               => i_prof,
                                                     i_pat                => i_id_patient,
                                                     i_vs_id              => l_tab_vs_id,
                                                     i_vs_val             => l_tab_vs_value,
                                                     i_id_monit           => NULL,
                                                     i_unit_meas          => l_tab_vs_um,
                                                     i_vs_scales_elements => table_number(),
                                                     i_notes              => NULL,
                                                     i_prof_cat_type      => i_prof_cat,
                                                     i_dt_vs_read         => table_varchar(),
                                                     i_epis_triage        => NULL,
                                                     i_unit_meas_convert  => l_tab_vs_um,
                                                     o_vital_sign_read    => l_new_vital_sign_read, -- array with new ID's
                                                     o_dt_registry        => l_dt_registry,
                                                     o_error              => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        BEGIN
            -- Update EPIS_MTOS_PARAM with the vital_sign_read id's
            g_error := 'START IF CLAUSE';
            IF l_new_vital_sign_read.exists(1)
            THEN
                g_error := 'LOOP OVER SAVED VITAL SIGNS';
                pk_alertlog.log_debug(g_error);
                FOR i IN l_new_vital_sign_read.first .. l_new_vital_sign_read.last
                LOOP
                    IF l_new_vital_sign_read(i) IS NOT NULL
                    THEN
                        g_error := 'SAVE VALUE - ' || l_new_vital_sign_read(i);
                        pk_alertlog.log_debug(g_error);
                        SELECT vsr.id_vital_sign
                          INTO l_id_vital_sign
                          FROM vital_sign_read vsr
                         WHERE vsr.id_vital_sign_read = l_new_vital_sign_read(i)
                           AND vsr.id_episode = i_id_episode;
                    
                        g_error := 'UPDATE EPIS_MTOS_PARAM.ID_VITAL_SIGN_READ';
                        pk_alertlog.log_debug(g_error);
                        ts_epis_mtos_param.upd(id_task_refid_in => l_new_vital_sign_read(i),
                                               where_in         => 'id_epis_mtos_score = ' || l_next_epis_mtos_score ||
                                                                   ' AND id_mtos_param IN (SELECT mpm.id_mtos_param
                                            FROM mtos_param mpm
                                            WHERE decode(mpm.flg_param_task_type,
                                                             pk_sev_scores_constant.g_flg_param_task_vital_sign,
                                                             mpm.id_param_task,
                                                             NULL) = ' ||
                                                                   l_id_vital_sign || ')',
                                               rows_out         => l_rowids);
                    
                        g_error := 'PROCESS UPDATE - EPIS_MTOS_PARAM';
                        pk_alertlog.log_debug(g_error);
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'EPIS_MTOS_PARAM',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                    END IF;
                END LOOP;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE l_save_vs_error;
        END;
    
        -- Check if any score was saved to activate the detail button
        g_error := 'CALL TO CHECK_FLG_DETAIL';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sev_scores_core.check_flg_detail(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_episode => i_id_episode,
                                                   o_flg_detail => o_flg_detail,
                                                   o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => l_sysdate,
                                      i_dt_first_obs        => l_sysdate,
                                      o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_save_vs_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN l_common_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_COMMON_ERROR',
                                              l_error_msg,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_mtos_score;

BEGIN
    -- Log initialization
    g_owner        := 'ALERT';
    g_package_name := pk_alertlog.who_am_i;

    pk_alertlog.who_am_i(g_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_trauma_core;
/
