/*-- Last Change Revision: $Rev: 2028927 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_reminder_constant IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 31-05-2011 12:11:48
    -- Purpose : Reminder constants

    -- Public type declarations

    -- Public constant declarations
    g_recurr_adv_dir_dnar_area CONSTANT order_recurr_area.internal_name%TYPE := 'ADV_DIR_DNAR';
    g_rem_param_int_nm_active  CONSTANT reminder_param.internal_name%TYPE := 'ACTIVE';
    g_rem_param_int_nm_recurr  CONSTANT reminder_param.internal_name%TYPE := 'RECURRENCE';

-- Public variable declarations

END pk_reminder_constant;
/
