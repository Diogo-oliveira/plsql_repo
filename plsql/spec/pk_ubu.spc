/*-- Last Change Revision: $Rev: 2029026 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:22 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ubu AS

    FUNCTION get_id_ext_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN VARCHAR2;
    FUNCTION get_episode_transportation
    (
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional DEFAULT NULL,
        i_limit      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_flg_unknown
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN VARCHAR2;
    FUNCTION get_admin_discharge_ubu(i_episode IN discharge.id_episode%TYPE) RETURN discharge.dt_admin_tstz%TYPE;

    FUNCTION get_date_transportation(i_id_episode IN episode.id_episode%TYPE) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    PROCEDURE cancel_epis_ubu;
    ----
    --
    g_error   VARCHAR2(4000);
    g_sysdate DATE;

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;
    g_exception EXCEPTION;

    g_epis_type_urg CONSTANT epis_type.id_epis_type%TYPE := 2;
    g_epis_type_ubu CONSTANT epis_type.id_epis_type%TYPE := 9;
    g_epis_inactive CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_active   CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_cancel   CONSTANT episode.flg_status%TYPE := 'C';
    g_software_ubu  CONSTANT software.id_software%TYPE := 29;
    g_default_inst  CONSTANT institution.id_institution%TYPE := 0;

    g_time_max_adm_urg_ubu sys_config.value%TYPE;

END pk_ubu;
/
