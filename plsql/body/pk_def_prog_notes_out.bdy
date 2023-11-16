/*-- Last Change Revision: $Rev: 1509949 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2013-10-02 17:30:51 +0100 (qua, 02 out 2013) $*/
CREATE OR REPLACE PACKAGE BODY pk_def_prog_notes_out IS

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations
    /**
    * Update the hidrics reference in the conf_button_block table
    * 
    * @author Sofia Mendes
    * @version 2.6.2
    * @since   11-Jun-2012
    */
    PROCEDURE update_button_hidrics_ref IS
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'UPDATE_BUTTON_HIDRICS_REF';
    BEGIN
        g_error := 'Update hidrics reference.';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        -- entrada
        UPDATE conf_button_block cbb
           SET cbb.id_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = pk_alert_constant.g_yes
                   AND ht.acronym = pk_inp_hidrics_constant.g_hid_type_i /*'I'*/
                )
         WHERE cbb.id_task_type = pk_prog_notes_constants.g_task_intake_output
           AND cbb.internal_task_type = pk_inp_hidrics_constant.g_hid_type_i;
    
        -- balanço hidrico
        UPDATE conf_button_block cbb
           SET cbb.id_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = pk_alert_constant.g_yes
                   AND ht.acronym = pk_inp_hidrics_constant.g_hid_type_h /*'H'*/
                )
         WHERE cbb.id_task_type = pk_prog_notes_constants.g_task_intake_output
           AND cbb.internal_task_type = pk_inp_hidrics_constant.g_hid_type_h;
           
        -- Irrigation
        UPDATE conf_button_block cbb
           SET cbb.id_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = pk_alert_constant.g_yes
                   AND ht.acronym = pk_inp_hidrics_constant.g_hid_type_g /*'G'*/
                )
         WHERE cbb.id_task_type = pk_prog_notes_constants.g_task_intake_output
           AND cbb.internal_task_type = pk_inp_hidrics_constant.g_hid_type_g;
    
        -- saída (agrupador)
        UPDATE conf_button_block cbb
           SET cbb.id_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = pk_alert_constant.g_yes
                   AND ht.acronym = pk_inp_hidrics_constant.g_hid_type_o /*'O'*/
                )
         WHERE cbb.id_task_type = pk_prog_notes_constants.g_task_intake_output
           AND cbb.internal_task_type = pk_inp_hidrics_constant.g_hid_type_o;
    
        -- registos de drenagem
        UPDATE conf_button_block cbb
           SET cbb.id_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = pk_alert_constant.g_yes
                   AND ht.acronym = pk_inp_hidrics_constant.g_hid_type_r /*'R'*/
                )
         WHERE cbb.id_task_type = pk_prog_notes_constants.g_task_intake_output
           AND cbb.internal_task_type = pk_inp_hidrics_constant.g_hid_type_r;
    
        -- registos de diurese
        UPDATE conf_button_block cbb
           SET cbb.id_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = pk_alert_constant.g_yes
                   AND ht.acronym = pk_inp_hidrics_constant.g_hid_type_d /*'D'*/
                )
         WHERE cbb.id_task_type = pk_prog_notes_constants.g_task_intake_output
           AND cbb.internal_task_type = pk_inp_hidrics_constant.g_hid_type_d;
    
        -- todas as saídas
        UPDATE conf_button_block cbb
           SET cbb.id_type =
               (SELECT ht.id_hidrics_type
                  FROM hidrics_type ht
                 WHERE ht.flg_available = pk_alert_constant.g_yes
                   AND ht.acronym = pk_inp_hidrics_constant.g_hid_type_all /*'A'*/
                )
         WHERE cbb.id_task_type = pk_prog_notes_constants.g_task_intake_output
           AND cbb.internal_task_type = pk_inp_hidrics_constant.g_hid_type_all;
     
    END update_button_hidrics_ref;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_def_prog_notes_out;
/
