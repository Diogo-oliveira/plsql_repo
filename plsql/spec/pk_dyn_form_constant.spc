/*-- Last Change Revision: $Rev: 1909552 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2019-07-24 17:22:39 +0100 (qua, 24 jul 2019) $*/

CREATE OR REPLACE PACKAGE pk_dyn_form_constant AS

    FUNCTION get_default_action RETURN NUMBER;

    FUNCTION get_id_unit_measure_year RETURN NUMBER;
    FUNCTION get_gender_unknown RETURN VARCHAR2;

    FUNCTION get_mask_year RETURN VARCHAR2;
    FUNCTION get_age_type_limit_min RETURN VARCHAR2;
    FUNCTION get_age_type_limit_max RETURN VARCHAR2;

    FUNCTION get_crit_block_str(i_text IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION get_submit_action RETURN NUMBER;

END pk_dyn_form_constant;
/
