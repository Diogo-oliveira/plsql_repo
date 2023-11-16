/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_rcm_base AS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_retval  BOOLEAN;

    ---------------------------------- PRIVATE CONSTANTS ------------------------------

    PROCEDURE do_commit IS
    BEGIN
        COMMIT;
    END do_commit;

    PROCEDURE ins_debug
    (
        i_func_name IN pk_rcm_constant.t_low_char,
        i_text      IN pk_rcm_constant.t_big_char
    ) IS
        l_text pk_rcm_constant.t_big_char;
    BEGIN
    
        l_text := substrb(i_text, 1, 255);
        pk_alertlog.log_debug(text => l_text, object_name => g_package, sub_object_name => i_func_name);
    
    END ins_debug;

    -- *********************************************************************
    PROCEDURE ins_rcm_parameter
    (
        i_parameter_name IN rcm_parameter.parameter_name%TYPE,
        i_label          IN rcm_parameter.label%TYPE
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_PARAMETER';
        l_row       rcm_parameter%ROWTYPE;
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.parameter_name := i_parameter_name;
        l_row.label          := i_label;
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_parameter
        VALUES l_row;
    
    END ins_rcm_parameter;

    -- *********************************************************************
    PROCEDURE ins_rcm_rule
    (
        i_id_rcm_rule IN rcm_rule.id_rcm_rule%TYPE,
        i_code_sep    IN rcm_rule.code_sep%TYPE,
        i_rule_query  IN rcm_rule.rule_query%TYPE
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_RULE';
        l_row       rcm_rule%ROWTYPE;
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm_rule := i_id_rcm_rule;
        l_row.code_sep    := i_code_sep;
        l_row.rule_query  := empty_clob();
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_rule
        VALUES l_row;
    
        UPDATE rcm_rule
           SET rule_query = i_rule_query
         WHERE id_rcm_rule = i_id_rcm_rule;
    
    END ins_rcm_rule;

    -- *********************************************************************
    PROCEDURE ins_rcm_rule_inst
    (
        i_id_rcm_rule   IN rcm_rule_inst.id_rcm_rule%TYPE,
        i_id_rule_inst  IN rcm_rule_inst.id_rule_inst%TYPE,
        i_flg_available IN rcm_rule_inst.flg_available%TYPE DEFAULT pk_alert_constant.g_yes
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_RULE_INST';
        l_row       rcm_rule_inst%ROWTYPE;
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm_rule   := i_id_rcm_rule;
        l_row.id_rule_inst  := i_id_rule_inst;
        l_row.flg_available := i_flg_available;
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_rule_inst
        VALUES l_row;
    
    END ins_rcm_rule_inst;

    -- *********************************************************************
    PROCEDURE ins_rcm_rule_inst_rcm
    (
        i_id_rcm       IN rcm_rule_inst_rcm.id_rcm%TYPE,
        i_id_rcm_rule  IN rcm_rule_inst_rcm.id_rcm_rule%TYPE,
        i_id_rule_inst IN rcm_rule_inst_rcm.id_rule_inst%TYPE
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_RULE_INST_RCM';
        l_row       rcm_rule_inst_rcm%ROWTYPE;
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm       := i_id_rcm;
        l_row.id_rcm_rule  := i_id_rcm_rule;
        l_row.id_rule_inst := i_id_rule_inst;
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_rule_inst_rcm
        VALUES l_row;
    
    END ins_rcm_rule_inst_rcm;

    -- *********************************************************************
    PROCEDURE ins_rcm_rule_param
    (
        i_id_rcm_rule    IN rcm_rule_param.id_rcm_rule %TYPE,
        i_parameter_name IN rcm_rule_param.parameter_name%TYPE,
        i_rank           IN rcm_rule_param.rank%TYPE,
        i_mask           IN rcm_rule_param.mask%TYPE
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_RULE_PARAM';
        l_row       rcm_rule_param%ROWTYPE;
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm_rule    := i_id_rcm_rule;
        l_row.parameter_name := i_parameter_name;
        l_row.rank           := i_rank;
        l_row.mask           := i_mask;
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_rule_param
        VALUES l_row;
    
    END ins_rcm_rule_param;

    -- *********************************************************************
    PROCEDURE ins_rcm_rule_param_rel
    (
        i_id_rcm_rule        IN rcm_rule_param_rel.id_rcm_rule %TYPE,
        i_parameter_name     IN rcm_rule_param_rel.parameter_name%TYPE,
        i_parameter_name_rel IN rcm_rule_param_rel.parameter_name_rel%TYPE
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_RULE_PARAM_REL';
        l_row       rcm_rule_param_rel%ROWTYPE;
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm_rule        := i_id_rcm_rule;
        l_row.parameter_name     := i_parameter_name;
        l_row.parameter_name_rel := i_parameter_name_rel;
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_rule_param_rel
        VALUES l_row;
    
    END ins_rcm_rule_param_rel;

    -- *********************************************************************
    PROCEDURE ins_rcm_rule_inst_param
    (
        i_id_rcm_rule    IN rcm_rule_inst_param.id_rcm_rule%TYPE,
        i_id_rule_inst   IN rcm_rule_inst_param.id_rule_inst%TYPE,
        i_parameter_name IN rcm_rule_inst_param.parameter_name%TYPE
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_RULE_PARAM_REL';
        l_row       rcm_rule_inst_param%ROWTYPE;
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm_rule    := i_id_rcm_rule;
        l_row.id_rule_inst   := i_id_rule_inst;
        l_row.parameter_name := i_parameter_name;
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_rule_inst_param
        VALUES l_row;
    
    END ins_rcm_rule_inst_param;

    -- *********************************************************************
    PROCEDURE ins_rcm_inst_param_val
    (
        i_id_rcm_rule    IN rcm_inst_param_val.id_rcm_rule%TYPE,
        i_id_rule_inst   IN rcm_inst_param_val.id_rule_inst%TYPE,
        i_parameter_name IN rcm_inst_param_val.parameter_name%TYPE,
        i_id_param_seq   IN rcm_inst_param_val.id_param_seq%TYPE,
        i_chr_val        IN rcm_inst_param_val.chr_val%TYPE DEFAULT NULL,
        i_num_val        IN rcm_inst_param_val.num_val%TYPE DEFAULT NULL,
        i_dte_val        IN rcm_inst_param_val.dte_val%TYPE DEFAULT NULL,
        i_interval_val   IN rcm_inst_param_val.interval_val%TYPE DEFAULT NULL
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_INST_PARAM_VAL';
        l_row       rcm_inst_param_val%ROWTYPE;
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm_rule    := i_id_rcm_rule;
        l_row.id_rule_inst   := i_id_rule_inst;
        l_row.parameter_name := i_parameter_name;
        l_row.id_param_seq   := i_id_param_seq;
        l_row.chr_val        := i_chr_val;
        l_row.num_val        := i_num_val;
        l_row.dte_val        := i_dte_val;
        l_row.interval_val   := i_interval_val;
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_inst_param_val
        VALUES l_row;
    
    END ins_rcm_inst_param_val;

    -- *********************************************************************
    PROCEDURE ins_rcm_inst_param_val_inst
    (
        i_id_rcm_rule    IN rcm_inst_param_val_inst.id_rcm_rule%TYPE,
        i_id_rule_inst   IN rcm_inst_param_val_inst.id_rule_inst%TYPE,
        i_parameter_name IN rcm_inst_param_val_inst.parameter_name%TYPE,
        i_id_param_seq   IN rcm_inst_param_val_inst.id_param_seq%TYPE,
        i_id_institution IN rcm_inst_param_val_inst.id_institution%TYPE,
        i_chr_val        IN rcm_inst_param_val_inst.chr_val%TYPE DEFAULT NULL,
        i_num_val        IN rcm_inst_param_val_inst.num_val%TYPE DEFAULT NULL,
        i_dte_val        IN rcm_inst_param_val_inst.dte_val%TYPE DEFAULT NULL,
        i_interval_val   IN rcm_inst_param_val_inst.interval_val%TYPE DEFAULT NULL
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_INST_PARAM_VAL_INST';
        l_row       rcm_inst_param_val_inst%ROWTYPE;
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm_rule    := i_id_rcm_rule;
        l_row.id_rule_inst   := i_id_rule_inst;
        l_row.parameter_name := i_parameter_name;
        l_row.id_param_seq   := i_id_param_seq;
        l_row.id_institution := i_id_institution;
        l_row.chr_val        := i_chr_val;
        l_row.num_val        := i_num_val;
        l_row.dte_val        := i_dte_val;
        l_row.interval_val   := i_interval_val;
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_inst_param_val_inst
        VALUES l_row;
    
    END ins_rcm_inst_param_val_inst;

    -- *********************************************************************
    PROCEDURE ins_rcm_orig
    (
        i_id_rcm_orig   IN rcm_orig.id_rcm_orig%TYPE,
        i_internal_name IN rcm_orig.internal_name%TYPE
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_ORIG';
        l_row       rcm_orig%ROWTYPE;
        k_code CONSTANT VARCHAR2(0050 CHAR) := 'RCM_ORIG.CODE_RCM_ORIG.';
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm_orig   := i_id_rcm_orig;
        l_row.code_rcm_orig := k_code || to_char(l_row.id_rcm_orig);
        l_row.internal_name := upper(i_internal_name);
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_orig
            (id_rcm_orig, code_rcm_orig, internal_name)
        VALUES
            (l_row.id_rcm_orig, l_row.code_rcm_orig, l_row.internal_name);
    
    END ins_rcm_orig;
    -- ####################################################################

    -- *********************************************************************
    PROCEDURE ins_rcm_type_workflow
    (
        i_id_type       IN rcm_type_workflow.id_rcm_type%TYPE,
        i_id_wrk        IN rcm_type_workflow.id_workflow%TYPE,
        i_flg_available IN rcm_type_workflow.id_workflow%TYPE
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_TYPE_WORKFLOW';
        l_row       rcm_type_workflow%ROWTYPE;
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm_type   := i_id_type;
        l_row.id_workflow   := i_id_wrk;
        l_row.flg_available := i_flg_available;
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_type_workflow
            (id_rcm_type, id_workflow, flg_available)
        VALUES
            (l_row.id_rcm_type, l_row.id_workflow, l_row.flg_available);
    
    END ins_rcm_type_workflow;
    -- ####################################################################

    -- *********************************************************************
    PROCEDURE ins_rcm_type_wf_alert
    (
        i_id_type       IN rcm_type_wf_alert.id_rcm_type%TYPE,
        i_id_status     IN rcm_type_wf_alert.id_status%TYPE,
        i_id_wrk        IN rcm_type_wf_alert.id_workflow%TYPE,
        i_id_sys_alert  IN rcm_type_wf_alert.id_sys_alert%TYPE,
        i_sys_alert_msg IN rcm_type_wf_alert.sys_alert_message%TYPE
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM_TYPE_WF_ALERT';
        l_row       rcm_type_wf_alert%ROWTYPE;
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm_type       := i_id_type;
        l_row.id_status         := i_id_status;
        l_row.id_workflow       := i_id_wrk;
        l_row.id_sys_alert      := i_id_sys_alert;
        l_row.sys_alert_message := i_sys_alert_msg;
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm_type_wf_alert
            (id_rcm_type, id_status, id_workflow, id_sys_alert, sys_alert_message)
        VALUES
            (l_row.id_rcm_type, l_row.id_status, l_row.id_workflow, l_row.id_sys_alert, l_row.sys_alert_message);
    
    END ins_rcm_type_wf_alert;
    -- ####################################################################

    -- *********************************************************************
    PROCEDURE ins_rcm
    (
        i_id          IN rcm.id_rcm%TYPE,
        i_id_cnt      IN rcm.id_content%TYPE,
        i_id_rcm_type IN rcm.id_rcm_type%TYPE
    ) IS
        l_func_name pk_rcm_constant.t_low_char := 'INS_RCM';
        l_row       rcm%ROWTYPE;
        k_code_summ CONSTANT VARCHAR2(0050 CHAR) := 'RCM.CODE_RCM_SUMM.';
        k_code_desc CONSTANT VARCHAR2(0050 CHAR) := 'RCM.CODE_RCM_DESC.';
    BEGIN
    
        ins_debug(l_func_name, 'validating row');
        l_row.id_rcm        := i_id;
        l_row.code_rcm_summ := k_code_summ || to_char(l_row.id_rcm);
        l_row.code_rcm_desc := k_code_desc || to_char(l_row.id_rcm);
        l_row.id_content    := i_id_cnt;
        l_row.id_rcm_type   := i_id_rcm_type;
    
        ins_debug(l_func_name, 'Inserting row into table');
        INSERT INTO rcm
            (id_rcm, code_rcm_summ, code_rcm_desc, id_content, id_rcm_type)
        VALUES
            (l_row.id_rcm, l_row.code_rcm_summ, l_row.code_rcm_desc, l_row.id_content, l_row.id_rcm_type);
    
    END ins_rcm;
    -- ####################################################################

    -- inserções transacionais
    -- *********************************************************************
    PROCEDURE ins_pat_rcm_det
    (
        i_lang       IN pk_rcm_constant.t_big_num,
        i_prof       IN profissional,
        i_row        IN pat_rcm_det%ROWTYPE,
        o_id_rcm_det OUT pat_rcm_det.id_rcm_det%TYPE
    ) IS
        l_func_name      CONSTANT pk_rcm_constant.t_low_char := 'INS_PAT_RCM_DET';
        k_data_gov_table CONSTANT pk_rcm_constant.t_low_char := 'PAT_RCM_DET';
        l_row_out table_varchar := table_varchar();
        l_error   t_error_out;
        l_row     pat_rcm_det%ROWTYPE;
    BEGIN
    
        l_row := i_row;
    
        g_error := l_func_name || ': validating row';
        SELECT nvl(MAX(prd.id_rcm_det), 0) + 1
          INTO l_row.id_rcm_det
          FROM pat_rcm_det prd
         WHERE prd.id_patient = i_row.id_patient
           AND prd.id_institution = i_row.id_institution
           AND prd.id_rcm = i_row.id_rcm;
    
        g_error := l_func_name || ': Inserting row into table';
        ts_pat_rcm_det.ins(rec_in => l_row, rows_out => l_row_out);
    
        o_id_rcm_det := l_row.id_rcm_det;
    
        g_error := l_func_name || ': Launch DataGovernance';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => k_data_gov_table,
                                      i_rowids     => l_row_out,
                                      o_error      => l_error);
    END ins_pat_rcm_det;
    -- ####################################################################

    PROCEDURE ins_pat_rcm_h
    (
        i_lang IN pk_rcm_constant.t_big_num,
        i_prof IN profissional,
        i_row  IN pat_rcm_h%ROWTYPE
    ) IS
        l_func_name      CONSTANT pk_rcm_constant.t_low_char := 'INS_PAT_RCM_H';
        k_data_gov_table CONSTANT pk_rcm_constant.t_low_char := 'PAT_RCM_H';
        l_row_out table_varchar := table_varchar();
        l_error   t_error_out;
        l_row     pat_rcm_h%ROWTYPE;
    BEGIN
    
        l_row := i_row;
    
        SELECT nvl(MAX(id_rcm_det_h), 0) + 1
          INTO l_row.id_rcm_det_h
          FROM pat_rcm_h prh
         WHERE prh.id_patient = i_row.id_patient
           AND prh.id_institution = i_row.id_institution
           AND prh.id_rcm = i_row.id_rcm
           AND prh.id_rcm_det = i_row.id_rcm_det
           AND prh.dt_status = i_row.dt_status;
    
        g_error := l_func_name || ': Inserting row into table';
        ts_pat_rcm_h.ins(rec_in => l_row, rows_out => l_row_out);
    
        g_error := l_func_name || ': Launch DataGovernance';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => k_data_gov_table,
                                      i_rowids     => l_row_out,
                                      o_error      => l_error);
    
    END ins_pat_rcm_h;

    /**
    * Gets a recommendation workflow
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identifier and its context (institution and software)
    * @param   i_id_rcm       Recommendation identifier
    * @param   o_id_workflow  Recommendation workflow
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-02-2012
    */
    FUNCTION get_rcm_workflow
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_rcm      IN rcm.id_rcm%TYPE,
        o_id_workflow OUT NOCOPY rcm_type_workflow.id_workflow%TYPE,
        o_error       OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RCM_WORKFLOW';
    BEGIN
    
        g_error := 'Init ' || l_func_name || ' / ID_RCM=' || i_id_rcm;
        SELECT rtw.id_workflow
          INTO o_id_workflow
          FROM rcm r
          JOIN rcm_type rt
            ON (rt.id_rcm_type = r.id_rcm_type)
          JOIN rcm_type_workflow rtw
            ON (rtw.id_rcm_type = rt.id_rcm_type AND rtw.flg_available = pk_alert_constant.get_yes)
         WHERE r.id_rcm = i_id_rcm;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rcm_workflow;

    /**
    * Gets a recommendation origin identifier, given the internal name
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identifier and its context (institution and software)
    * @param   i_internal_name Origin internal name
    * @param   o_id_rcm_orig   Origin identifier
    * @param   o_error         Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-02-2012
    */
    FUNCTION get_rcm_orig
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN rcm_orig.internal_name%TYPE,
        o_id_rcm_orig   OUT NOCOPY rcm_orig.id_rcm_orig%TYPE,
        o_error         OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RCM_ORIG';
        l_internal_name rcm_orig.internal_name%TYPE;
    BEGIN
    
        g_error         := 'Init ' || l_func_name || ' / i_internal_name=' || i_internal_name;
        l_internal_name := upper(i_internal_name);
    
        SELECT ro.id_rcm_orig
          INTO o_id_rcm_orig
          FROM rcm_orig ro
         WHERE ro.internal_name = l_internal_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rcm_orig;

    /**
    * Gets a recommendation origin identifier, given the internal name
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identifier and its context (institution and software)
    * @param   i_id_rcm       Recommendation identifier
    * @param   o_id_rcm_type  Recommendation type identifier
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   14-02-2012
    */
    FUNCTION get_rcm_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_rcm      IN rcm.id_rcm%TYPE,
        o_id_rcm_type OUT NOCOPY rcm_orig.id_rcm_orig%TYPE,
        o_error       OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RCM_TYPE';
        l_id_rcm_type_tab table_number;
    BEGIN
    
        g_error  := 'Init ' || l_func_name || ' / i_id_rcm=' || i_id_rcm;
        g_retval := get_rcm_type(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_id_rcm_tab      => table_number(i_id_rcm),
                                 o_id_rcm_type_tab => l_id_rcm_type_tab,
                                 o_error           => o_error);
    
        o_id_rcm_type := l_id_rcm_type_tab(1);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rcm_type;

    /**
    * Gets a recommendation origin identifier, given the internal name
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identifier and its context (institution and software)
    * @param   i_id_rcm_tab        Array of recommendation identifiers
    * @param   o_id_rcm_type_tab   Array of recommendation type identifiers
    * @param   o_error             Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   03-04-2012
    */
    FUNCTION get_rcm_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_rcm_tab      IN table_number,
        o_id_rcm_type_tab OUT NOCOPY table_number,
        o_error           OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RCM_TYPE';
    BEGIN
    
        g_error := 'Init ' || l_func_name;
        SELECT r.id_rcm_type
          BULK COLLECT
          INTO o_id_rcm_type_tab
          FROM rcm r
          JOIN TABLE(CAST(i_id_rcm_tab AS table_number)) t
            ON (t.column_value = r.id_rcm);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rcm_type;

    /**
    * Gets a recommendation summary description
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identifier and its context (institution and software)
    * @param   i_id_rcm        Recommendation identifier
    * @param   o_rcm_summ      Recommendation summary description
    * @param   o_error         Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION get_rcm_summ
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_rcm   IN rcm.id_rcm%TYPE,
        o_rcm_summ OUT NOCOPY pk_translation.t_desc_translation,
        o_error    OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RCM_SUMM';
    BEGIN
    
        g_error := 'Init ' || l_func_name || ' / i_id_rcm=' || i_id_rcm;
    
        SELECT pk_translation.get_translation(i_lang, r.code_rcm_summ)
          INTO o_rcm_summ
          FROM rcm r
         WHERE r.id_rcm = i_id_rcm;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rcm_summ;

    /**
    * Gets the template value to be sent to the CRM
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identifier and its context (institution and software)
    * @param   i_id_rcm             Recommendation identifier
    * @param   i_id_contact_method  Contact method identifier
    * @param   o_templ_value        Template value
    * @param   o_error              Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   13-04-2012
    */
    FUNCTION get_rcm_templ_crm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rcm            IN rcm_templ_crm.id_rcm%TYPE,
        i_id_contact_method IN patient.id_preferred_contact_method%TYPE,
        o_templ_value       OUT rcm_templ_crm.templ_value%TYPE,
        o_error             OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RCM_TEMPL_CRM';
    BEGIN
    
        g_error := 'Init ' || l_func_name || ' / i_id_rcm=' || i_id_rcm;
        SELECT rtc.templ_value
          INTO o_templ_value
          FROM rcm_templ_crm rtc
         WHERE rtc.id_contact_method = i_id_contact_method
           AND rtc.id_rcm = i_id_rcm;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rcm_templ_crm;

    /**
    * Gets recommendation detail latest info
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identifier and its context (institution and software)
    * @param   i_id_patient   Patient identifier
    * @param   i_id_rcm       Recommendation identifier
    * @param   i_id_rcm_det   Recommendation detail identifier. If null, returns the most recent detail identifier.
    * @param   i_id_workflow  Recommendation workflow identifier
    *
    * @return  recommendation latest data
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION get_pat_rcm_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_rcm     IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det IN pat_rcm_det.id_rcm_det%TYPE
    ) RETURN t_rec_rcm IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_PAT_RCM_DATA';
        l_error  t_error_out;
        l_result t_rec_rcm := t_rec_rcm();
    
        CURSOR c_rcm IS
            SELECT tab.id_rcm,
                   tab.id_rcm,
                   tab.id_rcm_det,
                   rt.id_rcm_type,
                   tab.rcm_text,
                   tab.id_rcm_orig,
                   tab.id_rcm_orig_value,
                   tab.id_workflow,
                   tab.id_status,
                   tab.dt_status,
                   tab.id_prof_status,
                   tab.id_epis_created,
                   tab.id_workflow_action,
                   tab.notes
              FROM (SELECT prd.id_patient,
                           prd.id_rcm,
                           prd.id_rcm_det,
                           prd.rcm_text,
                           prd.id_rcm_orig,
                           prd.id_rcm_orig_value,
                           prh.id_workflow,
                           prh.id_status,
                           prh.dt_status,
                           prh.id_prof_status,
                           prh.id_epis_created,
                           prh.id_workflow_action,
                           prh.notes,
                           prh.id_rcm_det_h
                      FROM pat_rcm_det prd
                      JOIN pat_rcm_h prh
                        ON (prd.id_patient = prh.id_patient AND prd.id_rcm = prh.id_rcm AND
                           prd.id_rcm_det = prh.id_rcm_det AND prd.id_institution = prh.id_institution)
                     WHERE prd.id_patient = i_id_patient
                       AND prd.id_rcm = i_id_rcm
                       AND prd.id_rcm_det = i_id_rcm_det
                       AND prd.id_institution = i_prof.institution) tab
              JOIN rcm r
                ON (r.id_rcm = tab.id_rcm)
              JOIN rcm_type rt
                ON (rt.id_rcm_type = r.id_rcm_type)
             ORDER BY tab.dt_status DESC, tab.id_rcm_det_h DESC;
    
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_rcm=' || i_id_rcm ||
                   ' i_id_rcm_det=' || i_id_rcm_det;
        OPEN c_rcm;
        FETCH c_rcm
            INTO l_result.id_patient,
                 l_result.id_rcm,
                 l_result.id_rcm_det,
                 l_result.id_rcm_type,
                 l_result.rcm_text,
                 l_result.id_rcm_orig,
                 l_result.id_rcm_orig_value,
                 l_result.id_workflow,
                 l_result.id_status,
                 l_result.dt_status,
                 l_result.id_prof_status,
                 l_result.id_episode,
                 l_result.id_workflow_action,
                 l_result.notes;
        CLOSE c_rcm;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            IF c_rcm%ISOPEN
            THEN
                CLOSE c_rcm;
            END IF;
            RETURN NULL;
    END get_pat_rcm_data;

    /**
    * Gets recommendation text
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identifier and its context (institution and software)
    * @param   i_id_patient   Patient identifier
    * @param   i_id_rcm       Recommendation identifier
    * @param   i_id_rcm_det   Recommendation detail identifier. If null, returns the most recent detail identifier.
    * @param   o_rcm_text     Recommendation text
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-04-2012
    */
    FUNCTION get_pat_rcm_text
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_rcm     IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det IN pat_rcm_det.id_rcm_det%TYPE,
        o_rcm_text   OUT NOCOPY pat_rcm_det.rcm_text%TYPE,
        o_error      OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_PAT_RCM_TEXT';
        l_pat_rcm_data t_rec_rcm := t_rec_rcm();
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_patient=' || i_id_patient || ' i_id_rcm=' || i_id_rcm ||
                   ' i_id_rcm_det=' || i_id_rcm_det;
    
        l_pat_rcm_data := get_pat_rcm_data(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_patient => i_id_patient,
                                           i_id_rcm     => i_id_rcm,
                                           i_id_rcm_det => i_id_rcm_det);
    
        o_rcm_text := l_pat_rcm_data.rcm_text;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_rcm_text;

    /**
    * Sets category of the system professional in this institution 
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identifier and its context (institution and software)
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   15-02-2012
    */
    FUNCTION set_prof_cat_system
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     pk_rcm_constant.t_low_char := 'SET_PROF_CAT_SYSTEM';
        l_id_prof_alert professional.id_professional%TYPE;
        l_id_category   category.id_category%TYPE;
    BEGIN
    
        g_error := 'Init ' || l_func_name || ' / ID=' || i_prof.id || ' institution=' || i_prof.institution || ' soft=' ||
                   i_prof.software;
    
        l_id_prof_alert := to_number(pk_sysconfig.get_config(i_code_cf => 'ID_PROF_ALERT', i_prof => i_prof));
    
        IF i_prof.id = l_id_prof_alert
        THEN
            -- getting prof category        
            l_id_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        
            IF l_id_category IS NULL
            THEN
                -- professional is not configured for this institution
                INSERT INTO prof_cat
                    (id_prof_cat, id_professional, id_category, id_institution, id_category_sub)
                VALUES
                    (seq_prof_cat.nextval, i_prof.id, pk_rcm_constant.g_cat_system, i_prof.institution, NULL);
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_prof_cat_system;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_rcm_base;
/
