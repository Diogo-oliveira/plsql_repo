/*-- Last Change Revision: $Rev: 1911754 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2019-08-08 14:12:57 +0100 (qui, 08 ago 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_dyn_form_constant AS

    -- validated
    FUNCTION get_default_action RETURN NUMBER IS
        k_default_action CONSTANT NUMBER := 235533990;
    BEGIN
        RETURN k_default_action;
    END get_default_action;

    FUNCTION get_submit_action RETURN NUMBER IS
        k_submit_action CONSTANT NUMBER := 235534028;
    BEGIN
        RETURN k_submit_action;
    END get_submit_action;

    FUNCTION get_id_unit_measure_year RETURN NUMBER IS
        k_id_unit_measure_year CONSTANT NUMBER := 27217;
    BEGIN
        RETURN k_id_unit_measure_year;
    END get_id_unit_measure_year;

    FUNCTION get_gender_unknown RETURN VARCHAR2 IS
        k_gender_unknown CONSTANT VARCHAR2(0050 CHAR) := 'UNKNOWN';
    BEGIN
        RETURN k_gender_unknown;
    END get_gender_unknown;

    FUNCTION get_mask_year RETURN VARCHAR2 IS
        k_mask_year CONSTANT VARCHAR2(0050 CHAR) := 'Y';
    BEGIN
        RETURN k_mask_year;
    END get_mask_year;

    FUNCTION get_age_type_limit_min RETURN VARCHAR2 IS
        k_age_type_limit_min CONSTANT VARCHAR2(0050 CHAR) := 'MIN';
    BEGIN
        RETURN k_age_type_limit_min;
    END get_age_type_limit_min;

    FUNCTION get_age_type_limit_max RETURN VARCHAR2 IS
        k_age_type_limit_max CONSTANT VARCHAR2(0050 CHAR) := 'MAX';
    BEGIN
        RETURN k_age_type_limit_max;
    END get_age_type_limit_max;

    -- Returns pl/sql block for desc_criteria processing
    FUNCTION get_crit_block_str(i_text IN VARCHAR2) RETURN VARCHAR2 IS
        l_code VARCHAR2(4000);
        k_lp CONSTANT VARCHAR2(0010 CHAR) := chr(10);
    BEGIN
    
        l_code := 'declare' || k_lp || ' l_text varchar2(4000);' || k_lp || 'begin' || k_lp || ' :l_text := ' || i_text || ';' || k_lp ||
                  'end;';
    
        RETURN l_code;
    
    END get_crit_block_str;

END pk_dyn_form_constant;
/
