/*-- Last Change Revision: $Rev: 2028697 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:23 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_filter_lov IS

    SUBTYPE t_big_byte IS pk_types.t_big_byte;
    SUBTYPE t_huge_byte IS pk_types.t_huge_byte;
    SUBTYPE t_hug_byte IS pk_types.t_huge_byte;

    SUBTYPE t_big_char IS pk_types.t_big_char;
    SUBTYPE t_med_char IS pk_types.t_med_char;
    SUBTYPE t_low_char IS pk_types.t_low_char;
    SUBTYPE t_flg_char IS pk_types.t_flg_char;

    SUBTYPE t_timestamp IS pk_types.t_timestamp;

    SUBTYPE t_category IS pk_types.t_category;

    SUBTYPE t_msg_char IS pk_types.t_msg_char;

    SUBTYPE t_low_num IS pk_types.t_low_num;
    SUBTYPE t_med_num IS pk_types.t_med_num;
    SUBTYPE t_big_num IS pk_types.t_big_num;
    SUBTYPE t_pls_num IS PLS_INTEGER;

    -- ***************************************************************
    FUNCTION execute_list
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
		i_id_episode  in number,
        i_id_patient  in number,
        i_list       IN VARCHAR2,
        i_tbl_par_name    IN table_varchar,
        i_tbl_par_value   IN table_varchar,
        i_flg_default_use in varchar2 default 'N'
    ) RETURN t_tbl_filter_list;

    -- sample function for desc menu function
    FUNCTION get_desc_menu
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_menu_function IN VARCHAR2
    ) RETURN VARCHAR2;

    --*****************************
    FUNCTION get_lov_value
    (
        i_tbl_lov  IN table_varchar,
        i_tbl_keys IN table_varchar,
        i_tbl_vals IN table_varchar
    ) RETURN VARCHAR2;

END pk_filter_lov;
/
