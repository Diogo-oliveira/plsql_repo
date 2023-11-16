/*-- Last Change Revision: $Rev: 1919795 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2019-10-09 11:13:58 +0100 (qua, 09 out 2019) $*/
CREATE OR REPLACE PACKAGE pk_pha_search AS

    FUNCTION get_pat_criteria_active_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(0050);
    g_package_name  VARCHAR2(0050);

    --
    g_sysdate_char VARCHAR2(50);

    g_found BOOLEAN;
    g_ret   BOOLEAN;

    g_exception EXCEPTION;

    -- episode status
    g_epis_active   CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_inactive CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_canceled CONSTANT episode.flg_status%TYPE := 'C';
    g_epis_pend     CONSTANT episode.flg_status%TYPE := 'P';

    g_pl             CONSTANT VARCHAR2(50) := '''';
    g_epis_type_code CONSTANT VARCHAR2(200) := 'EPIS_TYPE.CODE_EPIS_TYPE.';

    g_show_in_tooltip CONSTANT VARCHAR2(1) := 'T';

END pk_pha_search;
/
