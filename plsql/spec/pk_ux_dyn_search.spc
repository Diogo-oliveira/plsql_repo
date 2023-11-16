/*-- Last Change Revision: $Rev: 1911177 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2019-08-05 14:43:33 +0100 (seg, 05 ago 2019) $*/

CREATE OR REPLACE PACKAGE pk_ux_dyn_search IS

    /**
    * This function maps id_ds_cmpt_mkt_rel to ID_CRITERIA for search execution purposes.
    *
    * @return     True
    * @author     Carlos Ferreira
    * @version    2.8.0
    * @since      06/06/2019
    */
    FUNCTION map_ds_cmp_to_criteria
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_ds_cmp      IN table_number,
        o_tbl_id_criteria OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_search_next_screen
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_id_sys_button_prop IN NUMBER,
        o_screen_name        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ux_dyn_search;
/

