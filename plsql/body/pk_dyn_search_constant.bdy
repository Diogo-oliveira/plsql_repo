/*-- Last Change Revision: $Rev: 1909557 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2019-07-24 17:43:23 +0100 (qua, 24 jul 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_dyn_search_constant IS

    g_package_name VARCHAR2(1000 CHAR);
    --k_sp CONSTANT VARCHAR2(0010 CHAR) := chr(32);
    k_lp CONSTANT VARCHAR2(0010 CHAR) := chr(10);

    k_mark_func  CONSTANT VARCHAR2(0050 CHAR) := '#SEARCH_FUNC#';
    k_mark_addon CONSTANT VARCHAR2(0050 CHAR) := '#SEARCH_ADDON#';

    k_bind_i_return   CONSTANT VARCHAR2(0050 CHAR) := ':L_RETURN';
    k_bind_i_lang     CONSTANT VARCHAR2(0050 CHAR) := ':I_LANG';
    k_bind_i_prof     CONSTANT VARCHAR2(0050 CHAR) := ':I_PROF';
    k_bind_i_tbl_crit CONSTANT VARCHAR2(0050 CHAR) := ':I_TBL_CRIT';
    k_bind_i_tbl_val  CONSTANT VARCHAR2(0050 CHAR) := ':I_TBL_CRIT_VAL';
    k_bind_o_flg_show CONSTANT VARCHAR2(0050 CHAR) := ':O_FLG_SHOW';
    k_bind_o_result   CONSTANT VARCHAR2(0050 CHAR) := ':O_RESULT';
    k_bind_o_error    CONSTANT VARCHAR2(0050 CHAR) := ':O_ERROR';

    FUNCTION get_template RETURN VARCHAR2 IS
        k_code VARCHAR2(4000);
    BEGIN
    
        k_code := 'declare' || k_lp || 'l_dummy_02  varchar2(4000);' || k_lp || 'l_dummy_03  varchar2(4000);' || k_lp ||
                  'l_dummy_04  varchar2(4000);' || k_lp || 'l_dummy_05  varchar2(4000);' || k_lp ||
                  'l_dummy_06  varchar2(4000);' || k_lp || 'l_return    number;' || k_lp || 'l_bool   boolean;' || k_lp ||
                  'begin' || k_lp || 'l_bool := ' || k_mark_func || k_lp || '(' || k_lp || ' i_lang            => ' ||
                  k_bind_i_lang || k_lp || ',i_prof            => ' || k_bind_i_prof || k_lp ||
                  ',i_id_sys_btn_crit => ' || k_bind_i_tbl_crit || k_lp || ',i_crit_val        => ' || k_bind_i_tbl_val || k_lp ||
                  ',i_instit          => NULL' || k_lp || ',i_epis_type       => NULL' || k_lp ||
                  ',i_dt              => NULL' || k_lp || ',i_prof_cat_type   => NULL' || k_lp ||
                  ',o_flg_show       => ' || k_bind_o_flg_show || k_lp || ',o_msg             => l_dummy_02' || k_lp ||
                  ',o_msg_title       => l_dummy_03' || k_lp || ',o_button          => l_dummy_04' || k_lp ||
                  ',o_mess_no_result  => l_dummy_05' || k_lp || k_mark_addon || k_lp || ',o_error           => ' ||
                  k_bind_o_error || k_lp || ');' || k_lp || k_bind_i_return || ' := diutil.bool_to_int(l_bool);' || k_lp ||
                  'end;';
    
        RETURN k_code;
    
    END get_template;

    --*********************************************
    FUNCTION get_inp_pat_code RETURN VARCHAR2 IS
        k_inp_code_search CONSTANT VARCHAR2(4000) := 'declare' || k_lp || 'l_dummy_02  varchar2(4000);' || k_lp ||
                                                     'l_dummy_03  varchar2(4000);' || k_lp ||
                                                     'l_dummy_04  varchar2(4000);' || k_lp ||
                                                     'l_dummy_05  varchar2(4000);' || k_lp || 'l_return    number;' || k_lp ||
                                                     'l_bool   boolean;' || k_lp || 'begin' || k_lp || 'l_bool := ' ||
                                                     k_mark_func || k_lp || '(' || k_lp || ' i_lang            => ' ||
                                                     k_bind_i_lang || k_lp || ',i_prof         => ' || k_bind_i_prof || k_lp ||
                                                     ',i_id_sys_btn_crit => ' || k_bind_i_tbl_crit || k_lp ||
                                                     ',i_crit_val        => ' || k_bind_i_tbl_val || k_lp ||
                                                     ',i_instit          => NULL' || k_lp ||
                                                     ',i_epis_type       => NULL' || k_lp ||
                                                     ',i_dt              => NULL' || k_lp ||
                                                     ',i_prof_cat_type   => NULL' || k_lp || ',o_flg_show       => ' ||
                                                     k_bind_o_flg_show || k_lp || ',o_msg             => l_dummy_02' || k_lp ||
                                                     ',o_msg_title       => l_dummy_03' || k_lp ||
                                                     ',o_button          => l_dummy_04' || k_lp ||
                                                     ',o_mess_no_result  => l_dummy_05' || k_lp ||
                                                     ',o_pat             => ' || k_bind_o_result || k_lp ||
                                                     ',o_error           => ' || k_bind_o_error || k_lp || ');' || k_lp ||
                                                     k_bind_i_return || ' := diutil.bool_to_int(l_bool);' || k_lp ||
                                                     'end;';
    BEGIN
    
        RETURN k_inp_code_search;
    
    END get_inp_pat_code;

    --*********************************************
    FUNCTION get_inp_epis_code RETURN VARCHAR2 IS
        k_inp_code_search CONSTANT VARCHAR2(4000) := 'declare' || k_lp || 'l_dummy_02  varchar2(4000);' || k_lp ||
                                                     'l_dummy_03  varchar2(4000);' || k_lp ||
                                                     'l_dummy_04  varchar2(4000);' || k_lp ||
                                                     'l_dummy_05  varchar2(4000);' || k_lp || 'l_return    number;' || k_lp ||
                                                     'l_bool   boolean;' || k_lp || 'begin' || k_lp || 'l_bool := ' ||
                                                     k_mark_func || k_lp || '(' || k_lp || ' i_lang            => ' ||
                                                     k_bind_i_lang || k_lp || ',i_prof         => ' || k_bind_i_prof || k_lp ||
                                                     ',i_id_sys_btn_crit => ' || k_bind_i_tbl_crit || k_lp ||
                                                     ',i_crit_val        => ' || k_bind_i_tbl_val || k_lp ||
                                                     ',i_instit          => NULL' || k_lp ||
                                                     ',i_epis_type       => NULL' || k_lp ||
                                                     ',i_dt              => NULL' || k_lp ||
                                                     ',i_prof_cat_type   => NULL' || k_lp || ',o_flg_show       => ' ||
                                                     k_bind_o_flg_show || k_lp || ',o_msg             => l_dummy_02' || k_lp ||
                                                     ',o_msg_title       => l_dummy_03' || k_lp ||
                                                     ',o_button          => l_dummy_04' || k_lp ||
                                                     ',o_mess_no_result  => l_dummy_05' || k_lp ||
                                                     ',o_epis_cancel     => ' || k_bind_o_result || k_lp ||
                                                     ',o_error           => ' || k_bind_o_error || k_lp || ');' || k_lp ||
                                                     k_bind_i_return || ' := diutil.bool_to_int(l_bool);' || k_lp ||
                                                     'end;';
    BEGIN
    
        RETURN k_inp_code_search;
    
    END get_inp_epis_code;

    FUNCTION get_edis_proc_e_inactive RETURN VARCHAR2 IS
        l_code_search VARCHAR2(4000);
    BEGIN
    
        l_code_search := 'declare' || k_lp || 'l_dummy_02  varchar2(4000);' || k_lp || 'l_dummy_03  varchar2(4000);' || k_lp ||
                         'l_dummy_04  varchar2(4000);' || k_lp || 'l_dummy_05  varchar2(4000);' || k_lp ||
                         'l_return    number;' || k_lp || 'l_bool   boolean;' || k_lp || 'begin' || k_lp ||
                         'l_bool := ' || k_mark_func || k_lp || '(' || k_lp || ' i_lang            => ' ||
                         k_bind_i_lang || k_lp || ',i_prof            => ' || k_bind_i_prof || k_lp ||
                         ',i_id_sys_btn_crit => ' || k_bind_i_tbl_crit || k_lp || ',i_crit_val        => ' ||
                         k_bind_i_tbl_val || k_lp || ',i_dt              => NULL' || k_lp ||
                         ',o_msg             => l_dummy_02' || k_lp || ',o_msg_title       => l_dummy_03' || k_lp ||
                         ',o_button          => l_dummy_04' || k_lp || ',o_epis_cancel     => ' || k_bind_o_result || k_lp ||
                         ',o_mess_no_result  => l_dummy_05' || k_lp || ',o_flg_show       => ' || k_bind_o_flg_show || k_lp ||
                         ',o_error           => ' || k_bind_o_error || k_lp || ');' || k_lp || k_bind_i_return ||
                         ' := diutil.bool_to_int(l_bool);' || k_lp || 'end;';
    
        RETURN l_code_search;
    
    END get_edis_proc_e_inactive;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_dyn_search_constant;
