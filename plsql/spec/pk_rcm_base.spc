/*-- Last Change Revision: $Rev: 1287788 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2012-04-27 18:15:21 +0100 (sex, 27 abr 2012) $*/

CREATE OR REPLACE PACKAGE pk_rcm_base AS

    PROCEDURE do_commit;

    PROCEDURE ins_debug
    (
        i_func_name IN pk_rcm_constant.t_low_char,
        i_text      IN pk_rcm_constant.t_big_char
    );

    -- *********************************************************************
    PROCEDURE ins_rcm_parameter
    (
        i_parameter_name IN rcm_parameter.parameter_name%TYPE,
        i_label          IN rcm_parameter.label%TYPE
    );

    PROCEDURE ins_rcm_rule
    (
        i_id_rcm_rule IN rcm_rule.id_rcm_rule%TYPE,
        i_code_sep    IN rcm_rule.code_sep%TYPE,
        i_rule_query  IN rcm_rule.rule_query%TYPE
    );

    PROCEDURE ins_rcm_rule_inst
    (
        i_id_rcm_rule   IN rcm_rule_inst.id_rcm_rule%TYPE,
        i_id_rule_inst  IN rcm_rule_inst.id_rule_inst%TYPE,
        i_flg_available IN rcm_rule_inst.flg_available%TYPE DEFAULT pk_alert_constant.g_yes
    );

    PROCEDURE ins_rcm_rule_inst_rcm
    (
        i_id_rcm       IN rcm_rule_inst_rcm.id_rcm%TYPE,
        i_id_rcm_rule  IN rcm_rule_inst_rcm.id_rcm_rule%TYPE,
        i_id_rule_inst IN rcm_rule_inst_rcm.id_rule_inst%TYPE
    );

    PROCEDURE ins_rcm_rule_param
    (
        i_id_rcm_rule    IN rcm_rule_param.id_rcm_rule %TYPE,
        i_parameter_name IN rcm_rule_param.parameter_name%TYPE,
        i_rank           IN rcm_rule_param.rank%TYPE,
        i_mask           IN rcm_rule_param.mask%TYPE
    );

    PROCEDURE ins_rcm_rule_param_rel
    (
        i_id_rcm_rule        IN rcm_rule_param_rel.id_rcm_rule %TYPE,
        i_parameter_name     IN rcm_rule_param_rel.parameter_name%TYPE,
        i_parameter_name_rel IN rcm_rule_param_rel.parameter_name_rel%TYPE
    );

    PROCEDURE ins_rcm_rule_inst_param
    (
        i_id_rcm_rule    IN rcm_rule_inst_param.id_rcm_rule%TYPE,
        i_id_rule_inst   IN rcm_rule_inst_param.id_rule_inst%TYPE,
        i_parameter_name IN rcm_rule_inst_param.parameter_name%TYPE
    );

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
    );

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
    );

    PROCEDURE ins_rcm_type_workflow
    (
        i_id_type       IN rcm_type_workflow.id_rcm_type%TYPE,
        i_id_wrk        IN rcm_type_workflow.id_workflow%TYPE,
        i_flg_available IN rcm_type_workflow.id_workflow%TYPE
    );

    PROCEDURE ins_rcm_type_wf_alert
    (
        i_id_type       IN rcm_type_wf_alert.id_rcm_type%TYPE,
        i_id_status     IN rcm_type_wf_alert.id_status%TYPE,
        i_id_wrk        IN rcm_type_wf_alert.id_workflow%TYPE,
        i_id_sys_alert  IN rcm_type_wf_alert.id_sys_alert%TYPE,
        i_sys_alert_msg IN rcm_type_wf_alert.sys_alert_message%TYPE
    );

    PROCEDURE ins_rcm
    (
        i_id          IN rcm.id_rcm%TYPE,
        i_id_cnt      IN rcm.id_content%TYPE,
        i_id_rcm_type IN rcm.id_rcm_type%TYPE
    );

    PROCEDURE ins_rcm_orig
    (
        i_id_rcm_orig   IN rcm_orig.id_rcm_orig%TYPE,
        i_internal_name IN rcm_orig.internal_name%TYPE
    );

    PROCEDURE ins_pat_rcm_det
    (
        i_lang       IN pk_rcm_constant.t_big_num,
        i_prof       IN profissional,
        i_row        IN pat_rcm_det%ROWTYPE,
        o_id_rcm_det OUT pat_rcm_det.id_rcm_det%TYPE
    );

    PROCEDURE ins_pat_rcm_h
    (
        i_lang IN pk_rcm_constant.t_big_num,
        i_prof IN profissional,
        i_row  IN pat_rcm_h%ROWTYPE
    );

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
        i_id_rcm_det IN pat_rcm_det.id_rcm_det%TYPE DEFAULT NULL
    ) RETURN t_rec_rcm;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

END pk_rcm_base;
/
