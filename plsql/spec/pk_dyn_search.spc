/*-- Last Change Revision: $Rev: 1911180 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2019-08-05 14:44:29 +0100 (seg, 05 ago 2019) $*/


CREATE OR REPLACE PACKAGE pk_dyn_search IS

    FUNCTION map_ds_cmp_to_criteria
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_ds_cmp      IN table_number,
        o_tbl_id_criteria OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    -- ***************************
    PROCEDURE ins_search_next_screen_cfg
    (
        i_id_sys_button_prop IN NUMBER,
        i_next_screen        IN VARCHAR2,
        i_id_config          IN NUMBER,
        i_id_inst_owner      IN NUMBER
    );

    PROCEDURE ins_search_next_screen_cfg
    (
        i_prof                IN profissional,
        i_id_market           IN NUMBER,
        i_id_category         IN NUMBER,
        i_id_profile_template IN NUMBER,
        i_id_sys_button_prop  IN NUMBER,
        i_next_screen         IN VARCHAR2
    );

    FUNCTION get_search_next_screen
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_id_sys_button_prop IN NUMBER,
        o_screen_name        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_dyn_search;

/
