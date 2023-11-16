/*-- Last Change Revision: $Rev: 2028742 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:39 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_diet AS

    FUNCTION get_diet_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_diet  IN diet.id_diet%TYPE,
        o_diet  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diet_sched_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_diet_sched OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_diet_status_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_epis_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_diet        IN diet.id_diet%TYPE,
        i_epis_diet      IN epis_diet.id_epis_diet%TYPE,
        i_desc_diet      IN epis_diet.desc_diet%TYPE,
        i_notes          IN epis_diet.notes%TYPE,
        i_diet_schedule  IN diet_schedule.id_diet_schedule%TYPE,
        i_dt_initial_str IN VARCHAR2,
        i_dt_end_str     IN VARCHAR2,
        i_flg_help       IN epis_diet.flg_help%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_epis_diet  IN diet.id_diet%TYPE,
        i_notes      IN epis_diet.notes%TYPE,
        i_flg_status IN epis_diet.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_diet
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_epis_diet OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_diet_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_diet IN epis_diet.id_epis_diet%TYPE,
        o_epis_diet OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_diet_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diet      IN diet.id_diet%TYPE,
        o_epis_diet OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    --
    --
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    --
    g_error         VARCHAR2(2000);
    g_ret           BOOLEAN;
    g_sysdate       DATE;
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_flg_available speciality.flg_available%TYPE;
    g_found         BOOLEAN;
    --
    g_separador VARCHAR2(500);
    --
    g_epis_active episode.flg_status%TYPE;
    --
    g_diet_status_r    epis_diet.flg_status%TYPE;
    g_diet_status_i    epis_diet.flg_status%TYPE;
    g_diet_status_c    epis_diet.flg_status%TYPE;
    g_yes_no           sys_domain.code_domain%TYPE;
    g_epis_diet_status sys_domain.code_domain%TYPE;

END pk_inp_diet;
/
