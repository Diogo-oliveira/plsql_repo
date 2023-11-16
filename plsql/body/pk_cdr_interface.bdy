/*-- Last Change Revision: $Rev: 1563704 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2014-03-05 09:01:59 +0000 (qua, 05 mar 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_cdr_interface IS

    --    k_package_owner CONSTANT t_low_char := 'ALERT_INTER';
    k_package_name CONSTANT t_low_char := 'PK_CDR_INTERFACE';
    --k_package_owner CONSTANT t_low_char := 'ALERT';

    k_yes CONSTANT t_flg_char := 'Y';
    --k_no  CONSTANT t_flg_char := 'N';

    k_cds_seq_name_ci   CONSTANT t_low_char := 'CDR_INSTANCE';
    k_cds_seq_name_cip  CONSTANT t_low_char := 'CDR_INST_PARAM';
    k_cds_seq_name_cipa CONSTANT t_low_char := 'CDR_INST_PAR_ACTION';

    k_sys_config_interfac_prof t_low_char := 'P1_INTERFACE_PROF_ID';

    g_show_debug BOOLEAN := FALSE;

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
    PROCEDURE set_flg_debug(i_bool IN BOOLEAN) IS
    BEGIN
        g_show_debug := i_bool;
    END set_flg_debug;

    /** @log_debug
    * Private procedure. logging function with output for screen, if flg set up to TRUE.
    *
    * @param    i_func_name  varchar2     name of function
    * @param    i_text       varchar2     text to log
    *
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2014/02/25
    */
    PROCEDURE log_debug
    (
        i_func_name IN VARCHAR2,
        i_text      IN VARCHAR2
    ) IS
        k_sp CONSTANT t_flg_char := '-';
    BEGIN
    
        pk_alertlog.log_debug(i_text);
    
        IF g_show_debug
        THEN
            dbms_output.put_line(i_func_name || k_sp || i_text);
        END IF;
    
    END log_debug;

    PROCEDURE log_error
    (
        i_func_name IN VARCHAR2,
        i_text      IN VARCHAR2
    ) IS
        k_sp CONSTANT t_flg_char := '-';
    BEGIN
    
        pk_alertlog.log_error(i_text);
    
        IF g_show_debug
        THEN
            dbms_output.put_line(i_func_name || k_sp || i_text);
        END IF;
    
    END log_error;

    /** @iif
    * Private Function. utility function, just for simplifying statements.
    *
    * @param    i_bool  boolean     true -> show debugging, False-> hide debugging
    * @param    i_true  varchar2    value to return if i_bool true
    * @param    i_false varchar2    value to return if i_bool false
    *
    * @returns  i_true or i_false , depending of i_bool
    *
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2014/02/25
    */
    FUNCTION iif
    (
        i_bool  IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_bool
        THEN
            RETURN i_true;
        ELSE
            RETURN i_false;
        END IF;
    
    END iif;

    --*********************************************************************************************************************************************************************

    FUNCTION get_cds_next_seq(i_seq_name IN t_low_char) RETURN t_big_num IS
        l_id t_big_num;
        k_func_name CONSTANT t_low_char := 'GET_CDS_NEXT_SEQ';
    BEGIN
    
        log_debug(k_func_name, 'SEQUENCE_NAME:' || i_seq_name);
        CASE i_seq_name
            WHEN k_cds_seq_name_ci THEN
                l_id := seq_inst_cdr_instance.nextval;
            WHEN k_cds_seq_name_cip THEN
                l_id := seq_inst_cdr_inst_param.nextval;
            WHEN k_cds_seq_name_cipa THEN
                l_id := seq_inst_cdr_inst_par_action.nextval;
        END CASE;
    
        log_debug(k_func_name, 'NEXT SEQ_NUMBER:' || to_char(l_id));
    
        RETURN l_id;
    
    END get_cds_next_seq;

    ---***********************************************************************************
    ---***********************************************************************************
    ---***********************************************************************************
    ---***********************************************************************************
    FUNCTION get_cdr_instance(i_old_cds_product IN t_prd_char) RETURN table_number IS
        l_tbl_return table_number;
        k_id_cdr_type CONSTANT t_big_num := 3;
        k_func_name   CONSTANT t_low_char := 'GET_CDR_INSTANCE';
    BEGIN
    
        SELECT id_cdr_instance BULK COLLECT
          INTO l_tbl_return
          FROM cdr_inst_param cip
         WHERE cip.id_element = i_old_cds_product
           AND id_cdr_instance IN
               (SELECT id_cdr_instance ci
                  FROM cdr_instance ci
                 WHERE ci.flg_available = k_yes
                   AND ci.id_cdr_definition IN (SELECT id_cdr_definition
                                                  FROM cdr_definition cf
                                                 WHERE cf.id_cdr_type = k_id_cdr_type));
    
        log_debug(k_func_name, 'SELECT COUNT: ' || l_tbl_return.count);
    
        RETURN l_tbl_return;
    
    END get_cdr_instance;

    ---************************************************************************************************************************************************
    ---************************************************************************************************************************************************
    ---************************************************************************************************************************************************
    ---************************************************************************************************************************************************
    -- *************************************************************************************
    -- *************************************************************************************

    -- ***************************************************************
    -- ***************************************************************
    FUNCTION ins_cdr_instance
    (
        i_prof             IN profissional,
        i_old_cdr_instance IN t_big_num
    ) RETURN NUMBER IS
        l_id             t_big_num;
        l_id_content     t_big_char;
        l_id_prof_create t_big_num := i_prof.id;
        l_id_institution t_big_num := i_prof.institution;
        k_func_name CONSTANT t_low_char := 'INS_CDR_INSTANCE';
    BEGIN
    
        l_id := get_cds_next_seq(k_cds_seq_name_ci);
        log_debug(k_func_name, 'Generated ID:' || l_id);
    
        INSERT INTO cdr_instance
            (id_cdr_instance,
             id_cdr_definition,
             code_description,
             flg_status,
             flg_origin,
             id_cdr_severity,
             id_institution,
             id_prof_create,
             id_cancel_info_det,
             id_content,
             flg_available)
            SELECT l_id,
                   id_cdr_definition,
                   code_description,
                   flg_status,
                   flg_origin,
                   id_cdr_severity,
                   l_id_institution,
                   l_id_prof_create,
                   id_cancel_info_det,
                   l_id_content,
                   flg_available
              FROM cdr_instance
             WHERE id_cdr_instance = i_old_cdr_instance;
        log_debug(k_func_name, 'TOTAL CDR_INSTANCE:' || SQL%ROWCOUNT);
    
        RETURN l_id;
    
    END ins_cdr_instance;
    -- *************************************************************************************
    -- *************************************************************************************
    FUNCTION ins_cdr_inst_param
    (
        i_new_id_cdr_instance IN t_big_num,
        i_old_cdr_inst_param  IN t_big_num,
        i_new_cdr_product     IN t_low_char
    ) RETURN t_big_num IS
        l_id_cdr_inst_param t_big_num;
        k_func_name CONSTANT t_low_char := 'INS_CDR_INST_PARAM';
    BEGIN
    
        log_debug(k_func_name, 'Beginning.....:');
    
        l_id_cdr_inst_param := get_cds_next_seq(k_cds_seq_name_cip);
        log_debug(k_func_name, 'CDR_INST_PARAM NEXT SEQ:' || l_id_cdr_inst_param);
    
        INSERT INTO cdr_inst_param
            (id_cdr_inst_param,
             id_cdr_instance,
             id_cdr_parameter,
             id_element,
             validity,
             id_validity_umea,
             val_min,
             val_max,
             id_domain_umea,
             route_id,
             update_institution,
             triggered_by_color)
            SELECT l_id_cdr_inst_param,
                   i_new_id_cdr_instance,
                   id_cdr_parameter,
                   i_new_cdr_product,
                   validity,
                   id_validity_umea,
                   val_min,
                   val_max,
                   id_domain_umea,
                   route_id,
                   update_institution,
                   triggered_by_color
              FROM cdr_inst_param
             WHERE id_cdr_inst_param = i_old_cdr_inst_param;
    
        log_debug(k_func_name, 'TOTAL CDR_INST_PARAM:' || SQL%ROWCOUNT);
    
        RETURN l_id_cdr_inst_param;
    
    END ins_cdr_inst_param;

    -- *****************************************************************************
    -- *****************************************************************************
    PROCEDURE ins_cdr_inst_par_val
    (
        i_old_cdr_inst_param IN NUMBER,
        i_new_cdr_inst_param IN NUMBER
    ) IS
        k_func_name CONSTANT t_low_char := 'CLONE_CDR_INST_PAR_VAL';
    BEGIN
    
        INSERT INTO cdr_inst_par_val
            (id_cdr_inst_param, VALUE)
            SELECT i_new_cdr_inst_param, VALUE
              FROM cdr_inst_par_val
             WHERE id_cdr_inst_param = i_old_cdr_inst_param;
        log_debug(k_func_name, 'TOTAL CDR_INST_PAR_VAL:' || SQL%ROWCOUNT);
    
    END ins_cdr_inst_par_val;

    -- *****************************************************************************
    -- *****************************************************************************
    FUNCTION ins_cdr_inst_par_action
    (
        i_old_id_cdr_inst_par_action IN t_big_num,
        i_id_cdr_inst_param          IN t_big_num
    ) RETURN NUMBER IS
        l_id_cdr_inst_par_action t_big_num;
    BEGIN
    
        l_id_cdr_inst_par_action := get_cds_next_seq(k_cds_seq_name_cipa);
        INSERT INTO cdr_inst_par_action
            (id_cdr_inst_par_action,
             id_cdr_inst_param,
             id_cdr_action,
             message,
             event_span,
             id_event_span_umea,
             flg_first_time,
             id_cdr_message)
            SELECT l_id_cdr_inst_par_action,
                   i_id_cdr_inst_param,
                   id_cdr_action,
                   message,
                   event_span,
                   id_event_span_umea,
                   flg_first_time,
                   id_cdr_message
              FROM cdr_inst_par_action
             WHERE id_cdr_inst_par_action = i_old_id_cdr_inst_par_action;
    
        RETURN l_id_cdr_inst_par_action;
    
    END ins_cdr_inst_par_action;

    -- *****************************************************************************
    -- *****************************************************************************
    PROCEDURE ins_cdr_inst_par_act_val
    (
        i_old_cipav IN t_big_num,
        i_new_cipav IN t_big_num
    ) IS
        k_func_name CONSTANT t_low_char := 'CLONE_CDR_INST_PAR_VAL';
    BEGIN
    
        INSERT INTO cdr_inst_par_act_val
            (id_cdr_inst_par_action, VALUE)
            SELECT i_new_cipav, VALUE
              FROM cdr_inst_par_act_val
             WHERE id_cdr_inst_par_action = i_old_cipav;
    
        log_debug(k_func_name, 'TOTAL CDR_INST_PAT_ACT_VAL:' || SQL%ROWCOUNT);
    
    END ins_cdr_inst_par_act_val;

    -- *****************************************************************************
    -- *****************************************************************************
    PROCEDURE clone_cdr_inst_par_action
    (
        i_old_cdr_inst_param IN t_big_num,
        i_new_cdr_inst_param IN t_big_num
    ) IS
    
        CURSOR c_cipa IS
            SELECT cipa.id_cdr_inst_par_action,
                   cipa.id_cdr_inst_param,
                   cipa.id_cdr_action,
                   cipa.message,
                   cipa.event_span,
                   cipa.id_event_span_umea,
                   cipa.flg_first_time,
                   cipa.id_cdr_message
              FROM cdr_inst_par_action cipa
             WHERE cipa.id_cdr_inst_param = i_old_cdr_inst_param;
    
        l_id_new_par_action t_big_num;
        k_func_name CONSTANT t_low_char := 'CLONE_CDR_INST_PAR_ACTION';
    BEGIN
    
        <<lup_thru_records_found>>
        FOR cipa IN c_cipa
        LOOP
        
            log_debug(k_func_name, 'CIPA_LOOP_ID:' || to_char(cipa.id_cdr_inst_par_action));
            l_id_new_par_action := ins_cdr_inst_par_action(i_old_id_cdr_inst_par_action => cipa.id_cdr_inst_par_action,
                                                           i_id_cdr_inst_param          => i_new_cdr_inst_param);
        
            ins_cdr_inst_par_act_val(i_old_cipav => cipa.id_cdr_inst_par_action, i_new_cipav => l_id_new_par_action);
        
        END LOOP lup_thru_records_found;
    
    END clone_cdr_inst_par_action;

    -- *************************************************************************************
    -- *************************************************************************************
    PROCEDURE clone_cdr_inst_param
    (
        i_prof                IN profissional,
        i_old_id_cdr_instance IN t_big_num,
        i_new_id_cdr_instance IN t_big_num,
        i_old_cdr_product     IN t_low_char,
        i_new_cdr_product     IN t_low_char
    ) IS
    
        CURSOR c_cdr_inst_param IS
            SELECT id_cdr_inst_param,
                   id_cdr_instance,
                   id_cdr_parameter,
                   decode(id_element, i_old_cdr_product, i_new_cdr_product, id_element) id_element,
                   validity,
                   id_validity_umea,
                   val_min,
                   val_max,
                   id_domain_umea,
                   route_id,
                   i_prof.institution update_institution,
                   triggered_by_color
              FROM cdr_inst_param
             WHERE id_cdr_instance = i_old_id_cdr_instance
            --AND id_element = i_old_cdr_product
            ;
        i_new_cdr_inst_param t_big_num;
        k_func_name CONSTANT t_low_char := 'CLONE_CDR_INST_PARAM';
    BEGIN
    
        <<lup_thru_old_cdr_inst_param>>
        FOR cip IN c_cdr_inst_param
        LOOP
        
            log_debug(k_func_name, 'LOOP:' || to_char(cip.id_cdr_inst_param));
        
            i_new_cdr_inst_param := ins_cdr_inst_param(i_new_id_cdr_instance => i_new_id_cdr_instance,
                                                       i_old_cdr_inst_param  => cip.id_cdr_inst_param,
                                                       i_new_cdr_product     => cip.id_element);
            log_debug(k_func_name, 'INSERT CDR_INST_PARAM COUNT:' || to_char(i_new_cdr_inst_param));
        
            ins_cdr_inst_par_val(i_old_cdr_inst_param => cip.id_cdr_inst_param,
                                 i_new_cdr_inst_param => i_new_cdr_inst_param);
        
            clone_cdr_inst_par_action(i_old_cdr_inst_param => cip.id_cdr_inst_param,
                                      i_new_cdr_inst_param => i_new_cdr_inst_param);
        
        END LOOP lup_thru_old_cdr_inst_param;
    
    END clone_cdr_inst_param;

    -- *************************************************************************************
    -- *************************************************************************************
    PROCEDURE clone_cdr_instance
    (
        i_prof             IN profissional,
        i_old_cdr_instance IN table_number,
        i_old_cds_product  IN t_low_char,
        i_new_cds_product  IN t_low_char
    ) IS
    
        CURSOR c_cdr_instance IS
            SELECT id_cdr_instance,
                   id_cdr_definition,
                   code_description,
                   flg_status,
                   flg_origin,
                   id_cdr_severity,
                   id_institution,
                   id_prof_create,
                   id_cancel_info_det,
                   NULL               id_content,
                   flg_available
              FROM cdr_instance
             WHERE id_cdr_instance IN (SELECT /*+OPT_ESTIMATE (TABLE tbl1 ROWS=1)*/
                                        column_value
                                         FROM TABLE(i_old_cdr_instance) tbl1);
    
        l_id_cdr_instance t_big_num;
        l_cfg_config      t_big_num;
        l_prof            profissional;
        k_func_name CONSTANT t_low_char := 'CLONE_CDR_INSTANCE';
    
    BEGIN
    
        -- Obter profissional de interface
        l_cfg_config := to_number(pk_sysconfig.get_config(i_code_cf => k_sys_config_interfac_prof, i_prof => i_prof));
        log_debug(k_func_name, 'PROF OF SYS_CONFIG:' || to_char(l_cfg_config));
    
        l_prof := profissional(l_cfg_config, i_prof.institution, i_prof.software);
    
        <<lup_thru_old_cdr_instances>>
        FOR cci IN c_cdr_instance
        LOOP
        
            l_id_cdr_instance := ins_cdr_instance(i_prof => l_prof, i_old_cdr_instance => cci.id_cdr_instance);
            log_debug(k_func_name, 'NEW ID_CDR_INSTANCE:' || l_id_cdr_instance);
        
            clone_cdr_inst_param(i_prof                => i_prof,
                                 i_old_id_cdr_instance => cci.id_cdr_instance,
                                 i_new_id_cdr_instance => l_id_cdr_instance,
                                 i_old_cdr_product     => i_old_cds_product,
                                 i_new_cdr_product     => i_new_cds_product);
        
        END LOOP lup_thru_old_cdr_instances;
    
    END clone_cdr_instance;

    --*********************************************
    PROCEDURE inicialize IS
    BEGIN
    
        pk_alertlog.log_init(k_package_name);
    
    END inicialize;

    -- *************************************************************************************
    -- *************************************************************************************
    PROCEDURE clone_contraindications
    (
        i_prof            IN profissional,
        i_old_cds_product IN VARCHAR2,
        i_new_cds_product IN VARCHAR2
    ) IS
        k_func_name CONSTANT t_low_char := 'CLONE_CONTRAINDICATIONS';
        l_tbl_old_cdr_instance table_number;
    BEGIN
    
        l_tbl_old_cdr_instance := get_cdr_instance(i_old_cds_product => i_old_cds_product);
        log_debug(k_func_name, 'OLD IDS CDR_INSTANCE: ' || to_char(l_tbl_old_cdr_instance.count));
    
        clone_cdr_instance(i_prof             => i_prof,
                           i_old_cdr_instance => l_tbl_old_cdr_instance,
                           i_old_cds_product  => i_old_cds_product,
                           i_new_cds_product  => i_new_cds_product);
        log_debug(k_func_name, 'CDR_INSTANCE COUNT:' || l_tbl_old_cdr_instance.count);
    
    END clone_contraindications;

BEGIN

    inicialize();

END pk_cdr_interface;
/
