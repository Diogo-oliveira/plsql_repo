/*-- Last Change Revision: $Rev: 1562793 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2014-02-28 10:50:58 +0000 (sex, 28 fev 2014) $*/

CREATE OR REPLACE PACKAGE pk_cdr_interface IS

    SUBTYPE t_hug_byte IS VARCHAR2(32000);
    SUBTYPE t_big_byte IS VARCHAR2(4000);

    SUBTYPE t_lob_char IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0500 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_prd_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    SUBTYPE t_timestamp IS TIMESTAMP(6)
        WITH LOCAL TIME ZONE;

    SUBTYPE t_low_num IS NUMBER(06);
    SUBTYPE t_med_num IS NUMBER(12);
    SUBTYPE t_big_num IS NUMBER(24);
    SUBTYPE t_flg_num IS NUMBER(01);

    /** @set_flg_debug
    * Public Function. set value of flag g_show_debug for validation in log_debug.
    * Purpose is to set on/off screen debugging.
    *
    * @param    i_bool  boolean     true -> show debugging, False-> hide debugging
    *
    * @returns  List of available pick_list
    *
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2014/02/25
    */
    PROCEDURE set_flg_debug(i_bool IN BOOLEAN);

    /** @clone_contraindications
    * Public procedure. clones data from given medication Id to other medication ID
    *   Tables cloned:  CDR_INSTANCE, CDR_INST_PARAM, CDR_INST_PAR_VAL,
    *                   CDR_INST_PAR_ACTION, CDR_INST_PAR_ACT_VAL
    *
    * @param    i_prof                  info of professional used
    * @param    i_old_cds_product       id of old product ( already formatted )
    * @param    i_new_cds_product       id of new product ( already formatted )
    *
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2014/02/25
    */
    PROCEDURE clone_contraindications
    (
        i_prof            IN profissional,
        i_old_cds_product IN VARCHAR2,
        i_new_cds_product IN VARCHAR2
    );

END pk_cdr_interface;
/
