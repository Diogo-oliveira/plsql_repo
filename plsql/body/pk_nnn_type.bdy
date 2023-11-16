/*-- Last Change Revision: $Rev: 1965628 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2020-10-09 09:22:44 +0100 (sex, 09 out 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_nnn_type IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error    VARCHAR2(1000 CHAR);
    g_owner    VARCHAR2(30 CHAR);
    g_package  VARCHAR2(30 CHAR);
    g_lob_text CLOB;

    -- Function and procedure implementations

    FUNCTION get_nnn_ux_instructions
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_instructions_rec IS
        l_type t_nnn_ux_instructions_rec;
    BEGIN
        /*l_type.flg_priority         := i_json.get_string('FLG_PRIORITY');
        l_type.priority             := json_ext.get_string(i_json, 'PRIORITY');
        l_type.flg_prn              := json_ext.get_string(i_json, 'FLG_PRN');
        l_type.prn                  := json_ext.get_string(i_json, 'PRN');
        l_type.notes_prn            := pk_json_utils.get_clob(i_json, 'NOTES_PRN');
        l_type.flg_time             := json_ext.get_string(i_json, 'FLG_TIME');
        l_type.to_be_performed      := json_ext.get_string(i_json, 'TO_BE_PERFORMED');
        l_type.start_date           := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                     i_prof      => i_prof,
                                                                     i_timestamp => json_ext.get_string(i_json,
                                                                                                        'START_DATE'),
                                                                     i_timezone  => NULL);
        l_type.desc_instructions    := json_ext.get_string(i_json, 'DESC_INSTRUCTIONS');
        l_type.id_order_recurr_plan := json_ext.get_number(i_json, 'ID_ORDER_RECURR_PLAN');*/
    
        RETURN l_type;
    END get_nnn_ux_instructions;

    FUNCTION get_nnn_ux_instructions
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_instructions_rec
    ) RETURN json_object_t IS
        l_jsn json_object_t;
    BEGIN
    
        /*l_jsn.put('FLG_PRIORITY', i_type.flg_priority);
        l_jsn.put('PRIORITY', i_type.priority);
        l_jsn.put('FLG_PRN', i_type.flg_prn);
        l_jsn.put('PRN', i_type.prn);
        l_jsn.put('FLG_TIME', i_type.flg_time);
        l_jsn.put('NOTES_PRN', json_object_t.parse(i_type.notes_prn));
        l_jsn.put('TO_BE_PERFORMED', i_type.to_be_performed);
        l_jsn.put('START_DATE', pk_date_utils.date_send_tsz(i_lang, i_type.start_date, i_prof));
        l_jsn.put('DESC_INSTRUCTIONS', i_type.desc_instructions);
        l_jsn.put('ID_ORDER_RECURR_PLAN', i_type.id_order_recurr_plan);*/
    
        RETURN l_jsn;
    END get_nnn_ux_instructions;

    FUNCTION get_nnn_ux_epis_diag_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_diag_eval_rec IS
        l_type t_nnn_ux_epis_diag_eval_rec;
    BEGIN
        /*l_type.id_nnn_epis_diag_eval       := json_ext.get_number(i_json, 'ID_NNN_EPIS_DIAG_EVAL');
        l_type.flg_status                  := json_ext.get_string(i_json, 'FLG_STATUS');
        l_type.dt_evaluation               := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                            i_prof      => i_prof,
                                                                            i_timestamp => json_ext.get_string(i_json,
                                                                                                               'DT_EVALUATION'),
                                                                            i_timezone  => NULL);
        l_type.lst_related_factor          := pk_json_utils.get_table_number(i_json, 'LST_RELATED_FACTOR');
        l_type.lst_risk_factor             := pk_json_utils.get_table_number(i_json, 'LST_RISK_FACTOR');
        l_type.lst_defining_characteristic := pk_json_utils.get_table_number(i_json, 'LST_DEFINING_CHARACTERISTIC');
        l_type.notes                       := pk_json_utils.get_clob(i_json, 'NOTES');*/
    
        RETURN l_type;
    END get_nnn_ux_epis_diag_eval;

    FUNCTION get_nnn_ux_epis_diag_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_diag_eval_rec
    ) RETURN json_object_t IS
        l_jsn json_object_t;
    BEGIN
    
        /* l_jsn.put('DT_EVALUATION',
                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => i_type.dt_evaluation, i_prof => i_prof));
        l_jsn.put('FLG_STATUS', i_type.flg_status);
        l_jsn.put('ID_NNN_EPIS_DIAG_EVAL', i_type.id_nnn_epis_diag_eval);
        l_jsn.put('LST_DEFINING_CHARACTERISTIC', pk_json_utils.to_json_list(i_type.lst_defining_characteristic));
        l_jsn.put('LST_RELATED_FACTOR', pk_json_utils.to_json_list(i_type.lst_related_factor));
        l_jsn.put('LST_RISK_FACTOR', pk_json_utils.to_json_list(i_type.lst_risk_factor));
        
        l_jsn.put('NOTES', json_object_t.parse(i_type.notes));*/
    
        RETURN l_jsn;
    END get_nnn_ux_epis_diag_eval;

    FUNCTION get_nnn_ux_epis_diagnosis
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_diagnosis_rec IS
        l_type t_nnn_ux_epis_diagnosis_rec;
    BEGIN
        /*l_type.id                    := json_ext.get_string(i_json, 'ID');
        l_type.id_nnn_epis_diagnosis := json_ext.get_number(i_json, 'ID_NNN_EPIS_DIAGNOSIS');
        l_type.id_nan_diagnosis      := json_ext.get_number(i_json, 'ID_NAN_DIAGNOSIS');
        l_type.nanda_code            := json_ext.get_number(i_json, 'NANDA_CODE');
        l_type.diagnosis_name        := json_ext.get_string(i_json, 'DIAGNOSIS_NAME');
        l_type.notes                 := json_ext.get_string(i_json, 'NOTES');
        l_type.dt_diagnosis          := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                      i_prof      => i_prof,
                                                                      i_timestamp => json_ext.get_string(i_json,
                                                                                                         'DT_DIAGNOSIS'),
                                                                      i_timezone  => NULL);
        l_type.flg_req_status        := json_ext.get_string(i_json, 'FLG_REQ_STATUS');
        l_type.linked_outcomes       := pk_json_utils.get_table_varchar(i_json, 'LINKED_OUTCOMES');
        l_type.linked_interventions  := pk_json_utils.get_table_varchar(i_json, 'LINKED_INTERVENTIONS');
        l_type.diagnosis_evaluation  := get_nnn_ux_epis_diag_eval(i_lang => i_lang,
                                                                  i_prof => i_prof,
                                                                  i_json => json_ext.get_json(i_json,
                                                                                              'DIAGNOSIS_EVALUATION'));*/
        RETURN l_type;
    END get_nnn_ux_epis_diagnosis;

    FUNCTION get_nnn_ux_epis_diagnosis
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_diagnosis_rec
    ) RETURN json_object_t IS
        l_jsn json_object_t;
    BEGIN
        /* l_jsn.put('ID', i_type.id);
        l_jsn.put('ID_NNN_EPIS_DIAGNOSIS', i_type.id_nnn_epis_diagnosis);
        l_jsn.put('ID_NAN_DIAGNOSIS', i_type.id_nan_diagnosis);
        l_jsn.put('NANDA_CODE', i_type.nanda_code);
        l_jsn.put('DIAGNOSIS_NAME', i_type.diagnosis_name);
        l_jsn.put('NOTES', i_type.notes);
        l_jsn.put('DT_DIAGNOSIS',
                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => i_type.dt_diagnosis, i_prof => i_prof));
        l_jsn.put('FLG_REQ_STATUS', i_type.flg_req_status);
        l_jsn.put('LINKED_OUTCOMES', pk_json_utils.to_json_list(i_type.linked_outcomes));
        l_jsn.put('LINKED_INTERVENTIONS', pk_json_utils.to_json_list(i_type.linked_interventions));
        l_jsn.put('DIAGNOSIS_EVALUATION',
                  get_nnn_ux_epis_diag_eval(i_lang => i_lang, i_prof => i_prof, i_type => i_type.diagnosis_evaluation));*/
    
        RETURN l_jsn;
    END get_nnn_ux_epis_diagnosis;

    FUNCTION get_nnn_ux_epis_outcome_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_outcome_eval_rec IS
        l_type t_nnn_ux_epis_outcome_eval_rec;
    BEGIN
        /*l_type.id_nnn_epis_outcome_eval := json_ext.get_number(i_json, 'ID_NNN_EPIS_OUTCOME_EVAL');
        l_type.dt_evaluation            := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_timestamp => json_ext.get_string(i_json,
                                                                                                            'DT_EVALUATION'),
                                                                         i_timezone  => NULL);
        l_type.target_value             := json_ext.get_number(i_json, 'TARGET_VALUE');
        l_type.outcome_value            := json_ext.get_number(i_json, 'CURRENT_VALUE'); -- Notice that key name differs between json and type due to a implementing decision the UX layer.
        l_type.notes                    := pk_json_utils.get_clob(i_json, 'NOTES');*/
        RETURN l_type;
    END get_nnn_ux_epis_outcome_eval;

    FUNCTION get_nnn_ux_epis_outcome_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_outcome_eval_rec
    ) RETURN json_object_t IS
        l_jsn json_object_t;
    BEGIN
    
        /*l_jsn.put('ID_NNN_EPIS_OUTCOME_EVAL', i_type.id_nnn_epis_outcome_eval);
        l_jsn.put('DT_EVALUATION',
                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => i_type.dt_evaluation, i_prof => i_prof));
        l_jsn.put('TARGET_VALUE', i_type.target_value);
        l_jsn.put('CURRENT_VALUE', i_type.outcome_value); -- Notice that key name differs between json and type due to a implementing decision the UX layer.
        l_jsn.put('NOTES', json_object_t.parse(i_type.notes));*/
    
        RETURN l_jsn;
    END get_nnn_ux_epis_outcome_eval;

    FUNCTION get_nnn_ux_epis_outcome
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_outcome_rec IS
        l_type t_nnn_ux_epis_outcome_rec;
    BEGIN
        /*l_type.id                  := json_ext.get_string(i_json, 'ID');
        l_type.id_nnn_epis_outcome := json_ext.get_number(i_json, 'ID_NNN_EPIS_OUTCOME');
        l_type.id_noc_outcome      := json_ext.get_number(i_json, 'ID_NOC_OUTCOME');
        l_type.noc_code            := json_ext.get_number(i_json, 'NOC_CODE');
        l_type.outcome_name        := json_ext.get_string(i_json, 'OUTCOME_NAME');
        l_type.flg_req_status      := json_ext.get_string(i_json, 'FLG_REQ_STATUS');
        l_type.linked_diagnoses    := pk_json_utils.get_table_varchar(i_json, 'LINKED_DIAGNOSES');
        l_type.linked_indicators   := pk_json_utils.get_table_varchar(i_json, 'LINKED_INDICATORS');
        l_type.instructions        := get_nnn_ux_instructions(i_lang => i_lang,
                                                              i_prof => i_prof,
                                                              i_json => json_ext.get_json(i_json, 'INSTRUCTIONS'));
        l_type.outcome_evaluation  := get_nnn_ux_epis_outcome_eval(i_lang => i_lang,
                                                                   i_prof => i_prof,
                                                                   i_json => json_ext.get_json(i_json,
                                                                                               'OUTCOME_EVALUATION'));*/
        RETURN l_type;
    END get_nnn_ux_epis_outcome;

    FUNCTION get_nnn_ux_epis_outcome
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_outcome_rec
    ) RETURN json_object_t IS
        l_jsn json_object_t;
    BEGIN
    
        /*l_jsn.put('ID', i_type.id);
        l_jsn.put('ID_NNN_EPIS_OUTCOME', i_type.id_nnn_epis_outcome);
        l_jsn.put('ID_NOC_OUTCOME', i_type.id_noc_outcome);
        l_jsn.put('NOC_CODE', i_type.noc_code);
        l_jsn.put('OUTCOME_NAME', i_type.outcome_name);
        l_jsn.put('FLG_REQ_STATUS', i_type.flg_req_status);
        l_jsn.put('LINKED_DIAGNOSES', pk_json_utils.to_json_list(i_type.linked_diagnoses));
        l_jsn.put('LINKED_INDICATORS', pk_json_utils.to_json_list(i_type.linked_indicators));
        l_jsn.put('INSTRUCTIONS',
                  get_nnn_ux_instructions(i_lang => i_lang, i_prof => i_prof, i_type => i_type.instructions));
        l_jsn.put('OUTCOME_EVALUATION',
                  get_nnn_ux_epis_outcome_eval(i_lang => i_lang, i_prof => i_prof, i_type => i_type.outcome_evaluation));*/
    
        RETURN l_jsn;
    END get_nnn_ux_epis_outcome;

    FUNCTION get_nnn_ux_epis_indicator
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_indicator_rec IS
        l_type t_nnn_ux_epis_indicator_rec;
    BEGIN
        /* l_type.id                    := json_ext.get_string(i_json, 'ID');
        l_type.id_nnn_epis_indicator := json_ext.get_number(i_json, 'ID_NNN_EPIS_INDICATOR');
        l_type.id_noc_indicator      := json_ext.get_number(i_json, 'ID_NOC_INDICATOR');
        l_type.indicator_name        := json_ext.get_string(i_json, 'INDICATOR_NAME');
        l_type.flg_req_status        := json_ext.get_string(i_json, 'FLG_REQ_STATUS');
        l_type.linked_outcomes       := pk_json_utils.get_table_varchar(i_json, 'LINKED_OUTCOMES');
        l_type.instructions          := get_nnn_ux_instructions(i_lang => i_lang,
                                                                i_prof => i_prof,
                                                                i_json => json_ext.get_json(i_json, 'INSTRUCTIONS'));
        l_type.indicator_evaluation  := get_nnn_ux_epis_ind_eval(i_lang => i_lang,
                                                                 i_prof => i_prof,
                                                                 i_json => json_ext.get_json(i_json,
                                                                                             'INDICATOR_EVALUATION'));*/
        RETURN l_type;
    END get_nnn_ux_epis_indicator;

    FUNCTION get_nnn_ux_epis_indicator
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_indicator_rec
    ) RETURN json_object_t IS
        l_jsn json_object_t;
    BEGIN
        /*l_jsn.put('ID', i_type.id);
        l_jsn.put('ID_NNN_EPIS_INDICATOR', i_type.id_nnn_epis_indicator);
        l_jsn.put('ID_NOC_INDICATOR', i_type.id_noc_indicator);
        l_jsn.put('INDICATOR_NAME', i_type.indicator_name);
        l_jsn.put('FLG_REQ_STATUS', i_type.flg_req_status);
        l_jsn.put('LINKED_OUTCOMES', pk_json_utils.to_json_list(i_type.linked_outcomes));
        l_jsn.put('INSTRUCTIONS',
                  get_nnn_ux_instructions(i_lang => i_lang, i_prof => i_prof, i_type => i_type.instructions));
        l_jsn.put('INDICATOR_EVALUATION',
                  get_nnn_ux_epis_ind_eval(i_lang => i_lang, i_prof => i_prof, i_type => i_type.indicator_evaluation));*/
    
        RETURN l_jsn;
    END get_nnn_ux_epis_indicator;

    FUNCTION get_nnn_ux_epis_ind_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_ind_eval_rec IS
        l_type t_nnn_ux_epis_ind_eval_rec;
    BEGIN
    
        /*l_type.id_nnn_epis_ind_eval := json_ext.get_number(i_json, 'ID_NNN_EPIS_IND_EVAL');
        l_type.dt_evaluation        := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                     i_prof      => i_prof,
                                                                     i_timestamp => json_ext.get_string(i_json,
                                                                                                        'DT_EVALUATION'),
                                                                     i_timezone  => NULL);
        l_type.target_value         := json_ext.get_number(i_json, 'TARGET_VALUE');
        l_type.indicator_value      := json_ext.get_number(i_json, 'CURRENT_VALUE'); -- Notice that key name differs between json and type due to a implementing decision the UX layer.
        l_type.notes                := pk_json_utils.get_clob(i_json, 'NOTES');*/
        RETURN l_type;
    END get_nnn_ux_epis_ind_eval;

    FUNCTION get_nnn_ux_epis_ind_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_ind_eval_rec
    ) RETURN json_object_t IS
        l_jsn json_object_t;
    BEGIN
    
        /*l_jsn.put('ID_NNN_EPIS_IND_EVAL', i_type.id_nnn_epis_ind_eval);
        l_jsn.put('DT_EVALUATION',
                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => i_type.dt_evaluation, i_prof => i_prof));
        l_jsn.put('TARGET_VALUE', i_type.target_value);
        l_jsn.put('CURRENT_VALUE', i_type.indicator_value); -- Notice that key name differs between json and type due to a implementing decision the UX layer.
        l_jsn.put('NOTES', json_object_t.parse(i_type.notes));*/
        RETURN l_jsn;
    END get_nnn_ux_epis_ind_eval;

    FUNCTION get_nnn_ux_epis_intervention
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_intervention_rec IS
        l_type t_nnn_ux_epis_intervention_rec;
    BEGIN
        /*l_type.id                       := json_ext.get_string(i_json, 'ID');
        l_type.id_nnn_epis_intervention := json_ext.get_number(i_json, 'ID_NNN_EPIS_INTERVENTION');
        l_type.id_nic_intervention      := json_ext.get_number(i_json, 'ID_NIC_INTERVENTION');
        l_type.nic_code                 := json_ext.get_number(i_json, 'NIC_CODE');
        l_type.intervention_name        := json_ext.get_string(i_json, 'INTERVENTION_NAME');
        l_type.flg_req_status           := json_ext.get_string(i_json, 'FLG_REQ_STATUS');
        l_type.linked_diagnoses         := pk_json_utils.get_table_varchar(i_json, 'LINKED_DIAGNOSES');
        l_type.linked_activities        := pk_json_utils.get_table_varchar(i_json, 'LINKED_ACTIVITIES');*/
    
        RETURN l_type;
    END get_nnn_ux_epis_intervention;

    FUNCTION get_nnn_ux_epis_intervention
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_intervention_rec
    ) RETURN json_object_t IS
        l_jsn json_object_t;
    BEGIN
    
        /*l_jsn.put('ID_NNN_EPIS_INTERVENTION', i_type.id_nnn_epis_intervention);
        l_jsn.put('ID_NIC_INTERVENTION', i_type.id_nic_intervention);
        l_jsn.put('NIC_CODE', i_type.nic_code);
        l_jsn.put('INTERVENTION_NAME', i_type.intervention_name);
        l_jsn.put('FLG_REQ_STATUS', i_type.flg_req_status);
        l_jsn.put('LINKED_DIAGNOSES', pk_json_utils.to_json_list(i_type.linked_diagnoses));
        l_jsn.put('LINKED_ACTIVITIES', pk_json_utils.to_json_list(i_type.linked_activities));*/
    
        RETURN l_jsn;
    END get_nnn_ux_epis_intervention;

    FUNCTION get_nnn_ux_epis_activity
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_activity_rec IS
        l_type t_nnn_ux_epis_activity_rec;
    BEGIN
        /*l_type.id                   := json_ext.get_string(i_json, 'ID');
        l_type.id_nnn_epis_activity := json_ext.get_number(i_json, 'ID_NNN_EPIS_ACTIVITY');
        l_type.id_nic_activity      := json_ext.get_number(i_json, 'ID_NIC_ACTIVITY');
        l_type.activity_name        := json_ext.get_string(i_json, 'ACTIVITY_NAME');
        l_type.flg_req_status       := json_ext.get_string(i_json, 'FLG_REQ_STATUS');
        l_type.instructions         := get_nnn_ux_instructions(i_lang => i_lang,
                                                               i_prof => i_prof,
                                                               i_json => json_ext.get_json(i_json, 'INSTRUCTIONS'));
        l_type.linked_interventions := pk_json_utils.get_table_varchar(i_json, 'LINKED_INTERVENTIONS');*/
        RETURN l_type;
    END get_nnn_ux_epis_activity;

    FUNCTION get_nnn_ux_epis_activity
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_activity_rec
    ) RETURN json_object_t IS
        l_jsn json_object_t;
    BEGIN
        /*l_jsn.put('ID', i_type.id);
        l_jsn.put('ID_NNN_EPIS_ACTIVITY', i_type.id_nnn_epis_activity);
        l_jsn.put('ID_NIC_ACTIVITY', i_type.id_nic_activity);
        l_jsn.put('ACTIVITY_NAME', i_type.activity_name);
        l_jsn.put('FLG_REQ_STATUS', i_type.flg_req_status);
        l_jsn.put('INSTRUCTIONS',
                  get_nnn_ux_instructions(i_lang => i_lang, i_prof => i_prof, i_type => i_type.instructions));
        l_jsn.put('LINKED_INTERVENTIONS', pk_json_utils.to_json_list(i_type.linked_interventions));*/
        RETURN l_jsn;
    END get_nnn_ux_epis_activity;

    FUNCTION get_map_ux_epis_diagnosis
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_map_epis_diagnosis IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_map_ux_epis_diagnosis';
        l_jsn               json_object_t;
        l_jsn_val           json_element_t;
        l_jsn_lst_diagnoses json_array_t;
        l_diagnosis         pk_nnn_type.t_nnn_ux_epis_diagnosis_rec;
        l_map_diagnoses     pk_nnn_type.t_map_epis_diagnosis;
    BEGIN
        /*l_jsn_lst_diagnoses := json_ext.get_json_list(obj => i_json, path => 'DIAGNOSES');
        IF l_jsn_lst_diagnoses IS NULL
        THEN
            pk_alertlog.log_warn(text            => 'No pair-name "DIAGNOSES" found in JSON object ',
                                 object_name     => g_package,
                                 sub_object_name => k_function_name);
        ELSE
            -- Conditional compilation to remove log debug in prod code and avoid to_char overhead
            $if pk_nnn_type.is_debug $then
            pk_alertlog.log_debug(text            => 'DIAGNOSES:' || chr(10) || l_jsn_lst_diagnoses.to_char(FALSE),
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
            $end
            FOR indx IN 1 .. l_jsn_lst_diagnoses.count()
            LOOP
                l_jsn_val := l_jsn_lst_diagnoses.get(indx);
                l_jsn     := json(l_jsn_val);
            
                l_diagnosis := pk_nnn_type.get_nnn_ux_epis_diagnosis(i_lang => i_lang,
                                                                     i_prof => i_prof,
                                                                     i_json => l_jsn);
                l_map_diagnoses(to_char(l_diagnosis.id)) := l_diagnosis;
            END LOOP;
        
        END IF;*/
        RETURN l_map_diagnoses;
    
    END get_map_ux_epis_diagnosis;

    FUNCTION get_map_ux_epis_outcome
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_map_epis_outcome IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_map_ux_epis_outcome';
        l_jsn              json_object_t;
        l_jsn_val          json_element_t;
        l_jsn_lst_outcomes json_array_t;
        l_outcome          pk_nnn_type.t_nnn_ux_epis_outcome_rec;
        l_map_outcomes     pk_nnn_type.t_map_epis_outcome;
    BEGIN
        /*l_jsn_lst_outcomes := json_ext.get_json_list(obj => i_json, path => 'OUTCOMES');
        IF l_jsn_lst_outcomes IS NULL
        THEN
            pk_alertlog.log_warn(text            => 'No pair-name "OUTCOMES" found in JSON object ',
                                 object_name     => g_package,
                                 sub_object_name => k_function_name);
        ELSE
            -- Conditional compilation to remove log debug in prod code and avoid to_char overhead
            $if pk_nnn_type.is_debug $then
            pk_alertlog.log_debug(text            => 'OUTCOMES:' || chr(10) || l_jsn_lst_outcomes.to_char(FALSE),
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
            $end
        
            FOR indx IN 1 .. l_jsn_lst_outcomes.count()
            LOOP
                l_jsn_val := l_jsn_lst_outcomes.get(indx);
                l_jsn     := json(l_jsn_val);
            
                l_outcome := pk_nnn_type.get_nnn_ux_epis_outcome(i_lang => i_lang, i_prof => i_prof, i_json => l_jsn);
                l_map_outcomes(to_char(l_outcome.id)) := l_outcome;
            END LOOP;
        END IF;*/
        RETURN l_map_outcomes;
    END get_map_ux_epis_outcome;

    FUNCTION get_map_ux_epis_indicator
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_map_epis_indicator IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_map_ux_epis_indicator';
        l_jsn                json_object_t;
        l_jsn_val            json_element_t;
        l_jsn_lst_indicators json_array_t;
        l_map_indicators     pk_nnn_type.t_map_epis_indicator;
        l_indicator          pk_nnn_type.t_nnn_ux_epis_indicator_rec;
    BEGIN
        /*l_jsn_lst_indicators := json_ext.get_json_list(obj => i_json, path => 'INDICATORS');
        IF l_jsn_lst_indicators IS NULL
        THEN
            pk_alertlog.log_warn(text            => 'No pair-name "INDICATORS" found in JSON object ',
                                 object_name     => g_package,
                                 sub_object_name => k_function_name);
        ELSE
            -- Conditional compilation to remove log debug in prod code and avoid to_char overhead
            $if pk_nnn_type.is_debug $then
            pk_alertlog.log_debug(text            => 'INDICATORS:' || chr(10) || l_jsn_lst_indicators.to_char(FALSE),
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
            $end
            FOR indx IN 1 .. l_jsn_lst_indicators.count()
            LOOP
                l_jsn_val := l_jsn_lst_indicators.get(indx);
                l_jsn     := json(l_jsn_val);
            
                l_indicator := pk_nnn_type.get_nnn_ux_epis_indicator(i_lang => i_lang,
                                                                     i_prof => i_prof,
                                                                     i_json => l_jsn);
                l_map_indicators(to_char(l_indicator.id)) := l_indicator;
            END LOOP;
        END IF;*/
        RETURN l_map_indicators;
    END get_map_ux_epis_indicator;

    FUNCTION get_map_ux_epis_intervention
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_map_epis_intervention IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_map_ux_epis_intervention';
        l_jsn                   json_object_t;
        l_jsn_val               json_element_t;
        l_jsn_lst_interventions json_array_t;
        l_map_interventions     pk_nnn_type.t_map_epis_intervention;
        l_intervention          pk_nnn_type.t_nnn_ux_epis_intervention_rec;
    BEGIN
        /* l_jsn_lst_interventions := json_ext.get_json_list(obj => i_json, path => 'INTERVENTIONS');
        IF l_jsn_lst_interventions IS NULL
        THEN
            pk_alertlog.log_warn(text            => 'No pair-name "INTERVENTIONS" found in JSON object ',
                                 object_name     => g_package,
                                 sub_object_name => k_function_name);
        ELSE
            -- Conditional compilation to remove log debug in prod code and avoid to_char overhead
            $if pk_nnn_type.is_debug $then
            pk_alertlog.log_debug(text            => 'INTERVENTIONS:' || chr(10) ||
                                                     l_jsn_lst_interventions.to_char(FALSE),
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
            $end
            FOR indx IN 1 .. l_jsn_lst_interventions.count()
            LOOP
                l_jsn_val := l_jsn_lst_interventions.get(indx);
                l_jsn     := json(l_jsn_val);
            
                l_intervention := pk_nnn_type.get_nnn_ux_epis_intervention(i_lang => i_lang,
                                                                           i_prof => i_prof,
                                                                           i_json => l_jsn);
                l_map_interventions(to_char(l_intervention.id)) := l_intervention;
            END LOOP;
        END IF;*/
        RETURN l_map_interventions;
    END get_map_ux_epis_intervention;

    FUNCTION get_map_ux_epis_activity
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_map_epis_activity IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_map_ux_epis_activity';
        l_jsn                json_object_t;
        l_jsn_val            json_element_t;
        l_jsn_lst_activities json_array_t;
        l_activity           pk_nnn_type.t_nnn_ux_epis_activity_rec;
        l_map_activities     pk_nnn_type.t_map_epis_activity;
    BEGIN
        /*l_jsn_lst_activities := json_ext.get_json_list(obj => i_json, path => 'ACTIVITIES');
        IF l_jsn_lst_activities IS NULL
        THEN
            pk_alertlog.log_warn(text            => 'No pair-name "ACTIVITIES" found in JSON object ',
                                 object_name     => g_package,
                                 sub_object_name => k_function_name);
        ELSE
            -- Conditional compilation to remove log debug in prod code and avoid to_char overhead
            $if pk_nnn_type.is_debug $then
            pk_alertlog.log_debug(text            => 'ACTIVITIES:' || chr(10) || l_jsn_lst_activities.to_char(FALSE),
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
            $end
            FOR indx IN 1 .. l_jsn_lst_activities.count()
            LOOP
                l_jsn_val := l_jsn_lst_activities.get(indx);
                l_jsn     := json(l_jsn_val);
            
                l_activity := pk_nnn_type.get_nnn_ux_epis_activity(i_lang => i_lang, i_prof => i_prof, i_json => l_jsn);
                l_map_activities(to_char(l_activity.id)) := l_activity;
            END LOOP;
        END IF;*/
        RETURN l_map_activities;
    END get_map_ux_epis_activity;

    FUNCTION get_nnn_ux_set_activity_exec
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_set_activity_exec_rec IS
        l_type t_nnn_ux_set_activity_exec_rec;
    BEGIN
    
        /*l_type.i_nnn_epis_activity          := json_ext.get_number(i_json, 'I_NNN_EPIS_ACTIVITY');
        l_type.i_nnn_epis_activity_det      := json_ext.get_number(i_json, 'I_NNN_EPIS_ACTIVITY_DET');
        l_type.i_time_start                 := json_ext.get_string(i_json, 'I_TIME_START');
        l_type.i_time_end                   := json_ext.get_string(i_json, 'I_TIME_END');
        l_type.i_doc_template               := json_ext.get_number(i_json, 'I_DOC_TEMPLATE');
        l_type.i_lst_documentation          := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_DOCUMENTATION');
        l_type.i_lst_doc_element            := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_DOC_ELEMENT');
        l_type.i_lst_doc_element_crit       := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_DOC_ELEMENT_CRIT');
        l_type.i_lst_value                  := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_VALUE');
        l_type.i_lst_lst_doc_element_qualif := pk_json_utils.get_table_table_number(i_obj       => i_json,
                                                                                    i_pair_name => 'I_LST_LST_DOC_ELEMENT_QUALIF');
        l_type.i_lst_vs_element             := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_VS_ELEMENT');
        l_type.i_lst_vs_save_mode           := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_VS_SAVE_MODE');
        l_type.i_lst_vs                     := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_VS');
        l_type.i_lst_vs_value               := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_VS_VALUE');
        l_type.i_lst_vs_uom                 := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_VS_UOM');
        l_type.i_lst_vs_scales              := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_VS_SCALES');
        l_type.i_lst_vs_date                := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_VS_DATE');
        l_type.i_lst_vs_read                := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_VS_READ');
        l_type.i_notes                      := pk_json_utils.get_clob(i_obj => i_json, i_pair_name => 'I_NOTES');
        l_type.i_lst_task_activity          := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_TASK_ACTIVITY');
        l_type.i_lst_task_executed          := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_TASK_EXECUTED');
        l_type.i_lst_task_notes             := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_TASK_NOTES');
        l_type.i_lst_supply_workflow        := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_SUPPLY_WORKFLOW');
        l_type.i_lst_supply                 := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_SUPPLY');
        l_type.i_lst_supply_set             := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_SUPPLY_SET');
        l_type.i_lst_supply_qty             := pk_json_utils.get_table_number(i_obj       => i_json,
                                                                              i_pair_name => 'I_LST_SUPPLY_QTY');
        l_type.i_lst_supply_type            := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_SUPPLY_TYPE');
        l_type.i_lst_supply_barcode_scanned := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_SUPPLY_BARCODE_SCANNED');
        l_type.i_lst_supply_deliver_needed  := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_SUPPLY_DELIVER_NEEDED');
        l_type.i_lst_supply_cons_type       := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_SUPPLY_CONS_TYPE');
        l_type.i_lst_supply_dt_expiration   := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_SUPPLY_DT_EXPIRATION');
        l_type.i_lst_supply_validation      := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_SUPPLY_VALIDATION');
        l_type.i_lst_supply_lot             := pk_json_utils.get_table_varchar(i_obj       => i_json,
                                                                               i_pair_name => 'I_LST_SUPPLY_LOT');*/
        RETURN l_type;
    END get_nnn_ux_set_activity_exec;

    FUNCTION get_nnn_ux_set_activity_exec
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_set_activity_exec_rec
    ) RETURN json_object_t IS
        l_jsn json_object_t;
    BEGIN
    
        /* l_jsn.put('I_NNN_EPIS_ACTIVITY', i_type.i_nnn_epis_activity);
        l_jsn.put('I_NNN_EPIS_ACTIVITY_DET', i_type.i_nnn_epis_activity_det);
        l_jsn.put('I_TIME_START', i_type.i_time_start);
        l_jsn.put('I_TIME_END', i_type.i_time_end);
        l_jsn.put('I_DOC_TEMPLATE', i_type.i_doc_template);
        l_jsn.put('I_LST_DOCUMENTATION', pk_json_utils.to_json_list(i_type.i_lst_documentation));
        l_jsn.put('I_LST_DOC_ELEMENT', pk_json_utils.to_json_list(i_type.i_lst_doc_element));
        l_jsn.put('I_LST_DOC_ELEMENT_CRIT', pk_json_utils.to_json_list(i_type.i_lst_doc_element_crit));
        l_jsn.put('I_LST_VALUE', pk_json_utils.to_json_list(i_type.i_lst_value));
        l_jsn.put('I_LST_LST_DOC_ELEMENT_QUALIF', pk_json_utils.to_json_list(i_type.i_lst_lst_doc_element_qualif));
        l_jsn.put('I_LST_VS_ELEMENT', pk_json_utils.to_json_list(i_type.i_lst_vs_element));
        l_jsn.put('I_LST_VS_SAVE_MODE', pk_json_utils.to_json_list(i_type.i_lst_vs_save_mode));
        l_jsn.put('I_LST_VS', pk_json_utils.to_json_list(i_type.i_lst_vs));
        l_jsn.put('I_LST_VS_VALUE', pk_json_utils.to_json_list(i_type.i_lst_vs_value));
        l_jsn.put('I_LST_VS_UOM', pk_json_utils.to_json_list(i_type.i_lst_vs_uom));
        l_jsn.put('I_LST_VS_SCALES', pk_json_utils.to_json_list(i_type.i_lst_vs_scales));
        l_jsn.put('I_LST_VS_DATE', pk_json_utils.to_json_list(i_type.i_lst_vs_date));
        l_jsn.put('I_LST_VS_READ', pk_json_utils.to_json_list(i_type.i_lst_vs_read));
        l_jsn.put('I_NOTES', json_object_t.parse(i_type.i_notes));
        l_jsn.put('I_LST_TASK_ACTIVITY', pk_json_utils.to_json_list(i_type.i_lst_task_activity));
        l_jsn.put('I_LST_TASK_EXECUTED', pk_json_utils.to_json_list(i_type.i_lst_task_executed));
        l_jsn.put('I_LST_TASK_NOTES', pk_json_utils.to_json_list(i_type.i_lst_task_notes));
        l_jsn.put('I_LST_SUPPLY_WORKFLOW', pk_json_utils.to_json_list(i_type.i_lst_supply_workflow));
        l_jsn.put('I_LST_SUPPLY', pk_json_utils.to_json_list(i_type.i_lst_supply));
        l_jsn.put('I_LST_SUPPLY_SET', pk_json_utils.to_json_list(i_type.i_lst_supply_set));
        l_jsn.put('I_LST_SUPPLY_QTY', pk_json_utils.to_json_list(i_type.i_lst_supply_qty));
        l_jsn.put('I_LST_SUPPLY_TYPE', pk_json_utils.to_json_list(i_type.i_lst_supply_type));
        l_jsn.put('I_LST_SUPPLY_BARCODE_SCANNED', pk_json_utils.to_json_list(i_type.i_lst_supply_barcode_scanned));
        l_jsn.put('I_LST_SUPPLY_DELIVER_NEEDED', pk_json_utils.to_json_list(i_type.i_lst_supply_deliver_needed));
        l_jsn.put('I_LST_SUPPLY_CONS_TYPE', pk_json_utils.to_json_list(i_type.i_lst_supply_cons_type));
        l_jsn.put('I_LST_SUPPLY_DT_EXPIRATION', pk_json_utils.to_json_list(i_type.i_lst_supply_dt_expiration));
        l_jsn.put('I_LST_SUPPLY_VALIDATION', pk_json_utils.to_json_list(i_type.i_lst_supply_validation));
        l_jsn.put('I_LST_SUPPLY_LOT', pk_json_utils.to_json_list(i_type.i_lst_supply_lot));*/
    
        RETURN l_jsn;
    END get_nnn_ux_set_activity_exec;

    FUNCTION get_lst_ux_set_activity_exec
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_lst_nnn_ux_set_activity_exec IS
        k_function_name  CONSTANT VARCHAR2(30 CHAR) := 'get_lst_ux_set_activity_exec';
        k_root_pair_name CONSTANT pk_types.t_internal_name_byte := 'LST_SET_ACTIVITY_EXECUTE';
        l_jsn                          json_object_t;
        l_jsn_val                      json_element_t;
        l_jsn_lst_set_activity_execute json_array_t;
        l_set_activity_execute         pk_nnn_type.t_nnn_ux_set_activity_exec_rec;
        l_lst_set_activity_execute     pk_nnn_type.t_lst_nnn_ux_set_activity_exec;
    
    BEGIN
        /*l_jsn_lst_set_activity_execute := json_ext.get_json_list(obj => i_json, path => k_root_pair_name);
        
        IF l_jsn_lst_set_activity_execute IS NULL
        THEN
            pk_alertlog.log_warn(text            => 'No pair-name "' || k_root_pair_name || '" found in JSON object ',
                                 object_name     => g_package,
                                 sub_object_name => k_function_name);
        ELSE
            -- Conditional compilation to remove log debug in prod code and avoid to_char overhead
            $if pk_nnn_type.is_debug $then
            g_lob_text := k_root_pair_name || chr(10);
            l_jsn_lst_set_activity_execute.to_clob(buf => g_lob_text, spaces => TRUE, erase_clob => FALSE);
            pk_alertlog.log_debug(lob_text => g_lob_text, object_name => g_package, sub_object_name => k_function_name);
            $end
        
            l_lst_set_activity_execute := pk_nnn_type.t_lst_nnn_ux_set_activity_exec();
        
            FOR indx IN 1 .. l_jsn_lst_set_activity_execute.count()
            LOOP
                l_jsn_val := l_jsn_lst_set_activity_execute.get(indx);
                l_jsn     := json(l_jsn_val);
            
                l_set_activity_execute := pk_nnn_type.get_nnn_ux_set_activity_exec(i_lang => i_lang,
                                                                                   i_prof => i_prof,
                                                                                   i_json => l_jsn);
            
                l_lst_set_activity_execute.extend(1);
                l_lst_set_activity_execute(l_lst_set_activity_execute.last) := l_set_activity_execute;
            END LOOP;
        END IF;*/
        RETURN l_lst_set_activity_execute;
    
    END get_lst_ux_set_activity_exec;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_nnn_type;
/
