/*-- Last Change Revision: $Rev: 1974697 $*/
/*-- Last Change by: $Author: anna.kurowska $*/
/*-- Date of last change: $Date: 2020-12-21 12:45:25 +0000 (seg, 21 dez 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_epis_health_plan IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    -- Function and procedure implementations

    /**
    * Check if a given health plan is default
    *
    * @param   i_lang                    language associated to the professional executing the request
    * @param   i_prof                    professional identifier
    * @param   i_id_pat_health_plan      Patient health plan
    * @param   i_flg_default             Y if default, N otherwise
    * @param   i_epis                    Episode Id
    *
    * @RETURN  Referral id_external_request if success, return -1 otherwise
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   24-10-2009
    */
    FUNCTION check_sns_active_epis
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_pat_health_plan IN pat_health_plan.id_pat_health_plan%TYPE,
        i_epis               IN episode.id_episode%TYPE,
        i_flg_default        IN pat_health_plan.flg_default%TYPE
    ) RETURN VARCHAR2 IS
        l_result         VARCHAR2(1);
        l_id_cnt_hp      health_plan.id_content%TYPE;
        l_id_health_plan health_plan.id_health_plan%TYPE;
    BEGIN
    
        -- Get the National Health Plan identifier
        g_error          := 'Get the National Health Plan identifier';
        l_id_cnt_hp := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
    
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_health_plan
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = pk_alert_constant.get_available;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_health_plan := NULL;
                g_error          := 'If there is no default configuration for the national healt plan then l_result gets value ' ||
                                    to_char(i_flg_default);
        END;
        -- inicialize the l_result variable with the value of parameter i_flg_default
        g_error  := 'inicialize the l_result variable with value ' || to_char(i_flg_default);
        l_result := i_flg_default;
    
        IF l_id_health_plan IS NOT NULL
        THEN
        -- gets the active health plan for this episode
        g_error := 'gets the active health plan for episode ' || to_char(i_epis);
        FOR c1 IN (SELECT php.id_health_plan
                     FROM epis_health_plan e, pat_health_plan php
                    WHERE e.id_episode = i_epis
                      AND e.id_pat_health_plan = php.id_pat_health_plan)
        LOOP
            -- verifies if the plan is SNS or other. 
            g_error := 'verifies if the plan is SNS or other.' || chr(10) || ' Is ' || to_char(c1.id_health_plan) ||
                       ' to ' || to_char(l_id_health_plan) || '?';
            IF c1.id_health_plan = l_id_health_plan
            THEN
                -- If the active plan is SNS then return 'Y'
                g_error  := 'If the Active plan for the current episode is the national healt plan then l_result gets value ' ||
                            pk_ref_constant.g_yes;
                l_result := pk_ref_constant.g_yes;
            ELSE
                -- Returns 'N' otherwise
                g_error  := 'If the Active plan for the current episode is not the national healt plan then l_result gets value ' ||
                            pk_ref_constant.g_no;
                l_result := pk_ref_constant.g_no;
            END IF;
        END LOOP;
        END IF;
        -- returns the result
        g_error := 'Return the value of variable l_result ' || l_result;
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out := t_error_out(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
            BEGIN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => 'check_sns_active_epis',
                                                  o_error    => l_error);
                pk_alert_exceptions.reset_error_state();
            END;
        
            -- If unsuccess return -1
            RETURN '- 1';
    END check_sns_active_epis;

BEGIN
    -- Initialization
    NULL;
END pk_epis_health_plan;
/
