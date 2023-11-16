/*-- Last Change Revision: $Rev: 2028519 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_inst_mx IS

    FUNCTION cret_or_updt_inst_by_clues_cat
    (
        i_tbl_id_clues  IN table_number,
        i_override_name IN BOOLEAN DEFAULT FALSE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

END pk_backoffice_inst_mx;
/
