/*-- Last Change Revision: $Rev: 2028585 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:40 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_cpt_code IS

    TYPE cpt_code_rec IS RECORD(
        id_cpt_code   cpt_code.id_cpt_code%TYPE,
        cpt_code_desc cpt_code.long_desc%TYPE,
        flg_default   eval_mng.flg_default%TYPE);

    TYPE cpt_code_cur IS REF CURSOR RETURN cpt_code_rec;

    FUNCTION get_cpt_code_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT cpt_code_cur,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_has_cpt_cfg
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    g_error        VARCHAR2(2000);
    g_yes          VARCHAR2(1);
    g_no           VARCHAR2(1);
    g_sch_event_f  VARCHAR2(1);
    g_sch_event_s  VARCHAR2(1);
    g_cptc_n       VARCHAR2(1);
    g_cptc_e       VARCHAR2(1);
    g_cptc_c       VARCHAR2(1);

    --
    g_default_market CONSTANT eval_mng.id_market%TYPE := 0;

END pk_cpt_code;
/
