/*-- Last Change Revision: $Rev: 372225 $*/
/*-- Last Change by: $Author: claudio.ferreira $*/
/*-- Date of last change: $Date: 2010-01-08 10:42:48 +0000 (sex, 08 jan 2010) $*/

CREATE OR REPLACE PACKAGE pk_epis_health_plan IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 07-11-2009 10:01:23
    -- Purpose : Package for epis_health_plan table related functions and procedures

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations
    g_error         VARCHAR2(4000);
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);

    -- Public function and procedure declarations

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
    * @reason [ALERT-54779]
    */
    FUNCTION check_sns_active_epis
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_pat_health_plan IN pat_health_plan.id_pat_health_plan%TYPE,
        i_epis               IN episode.id_episode%TYPE,
        i_flg_default        IN pat_health_plan.flg_default%TYPE
    ) RETURN VARCHAR2;

END pk_epis_health_plan;
/
