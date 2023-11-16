/*-- Last Change Revision: $Rev: 1965628 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2020-10-09 09:22:44 +0100 (sex, 09 out 2020) $*/

CREATE OR REPLACE PACKAGE pk_nnn_type IS

    -- Author  : ARIEL.MACHADO
    -- Created : 11/25/2013 12:36:52 PM
    -- Purpose : NANDA, NIC and NOC (NNN): Types

    -- Public type declarations

    -- Using maps with keys of type "varchar" to ensure be possible to use up to 24 digits and GUIDs as identifiers
    SUBTYPE t_map_key IS VARCHAR2(255 CHAR);

    --Typed record with information sent by the UX layer about task instructions
    TYPE t_nnn_ux_instructions_rec IS RECORD(
        flg_priority         nnn_epis_outcome.flg_priority%TYPE, -- Flag that indicates the priority of the outcome
        priority             pk_translation.t_desc_translation, -- Priority description
        flg_prn              nnn_epis_outcome.flg_prn%TYPE, -- Flag that indicates wether the Outcome is PRN or not
        prn                  pk_translation.t_desc_translation, -- PRN description
        notes_prn            CLOB, -- Notes to indicate when a PRN order should be activated
        flg_time             nnn_epis_outcome.flg_time%TYPE, -- Execution time to evaluate the outcome
        to_be_performed      pk_translation.t_desc_translation, -- Execution time description 
        start_date           nnn_epis_outcome.dt_val_time_start%TYPE, -- Start date
        desc_instructions    pk_translation.t_desc_translation, -- Human readeable description of instructions
        id_order_recurr_plan nnn_epis_outcome.id_order_recurr_plan%TYPE -- Order recurrence plan ID for defined frequency in the instructions
        );

    --Typed record with information sent by the UX layer about the evaluation of a nursing diagnosis 
    TYPE t_nnn_ux_epis_diag_eval_rec IS RECORD(
        id_nnn_epis_diag_eval       nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE, -- Diagnosis Evaluation ID
        flg_status                  nnn_epis_diag_eval.flg_status%TYPE, -- Diagnosis status: (A)ctive, (I)nactive, (R)esolved, (C)ancelled.
        dt_evaluation               nnn_epis_diag_eval.dt_evaluation%TYPE, -- Evaluation date
        lst_related_factor          table_number, -- Collection of related factors ID
        lst_risk_factor             table_number, -- Collection of risk factors ID
        lst_defining_characteristic table_number, -- Collection of defining characteristic ID
        notes                       CLOB -- Notes about diagnosis evaluation
        );

    -- Typed record with the information sent by the UX layer about nursing diagnosis in the creation of a patient's nursing care plan
    TYPE t_nnn_ux_epis_diagnosis_rec IS RECORD(
        id                    t_map_key, -- ID to be used as reference identifier in the collections of linkages
        id_nnn_epis_diagnosis nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE, -- Episode's NANDA Diagnosis ID
        id_nan_diagnosis      nnn_epis_diagnosis.id_nan_diagnosis%TYPE, -- NANDA Diagnosis ID
        nanda_code            nnn_epis_diagnosis.nanda_code%TYPE, -- NANDA Code
        diagnosis_name        pk_translation.t_desc_translation, -- Diagnosis name
        notes                 nnn_epis_diagnosis.edited_diagnosis_name%TYPE, -- Notes used to explain the diagnosis and required to duplicate an already existent (location, etc.)
        dt_diagnosis          nnn_epis_diagnosis.dt_diagnosis%TYPE, -- Diagnosis date
        flg_req_status        nnn_epis_diagnosis.flg_req_status%TYPE, -- Request status: Ordered, Draft, etc.
        linked_outcomes       table_varchar, -- Linked outcomes for this NANDA diagnosis
        linked_interventions  table_varchar, -- Linked interventions for this NANDA diagnosis
        diagnosis_evaluation  t_nnn_ux_epis_diag_eval_rec -- An evaluation that can be registered  at the same time a diagnosis is added to the care plan 
        );

    -- Typed record with the information sent by the UX layer about the evaluation of a nursing outcome
    TYPE t_nnn_ux_epis_outcome_eval_rec IS RECORD(
        id_nnn_epis_outcome_eval nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE, -- Outcome Evaluation ID
        dt_evaluation            nnn_epis_outcome_eval.dt_evaluation%TYPE, -- Evaluation date
        target_value             nnn_epis_outcome_eval.target_value%TYPE, -- Outcome Target rating: Likert scale (1 to 5)
        outcome_value            nnn_epis_outcome_eval.outcome_value%TYPE, -- Outcome overall rating: Likert scale (1 to 5)
        notes                    CLOB -- Notes about outcome evaluation
        );

    -- Typed record with the information sent by the UX layer about nursing outcomes in the creation of a patient's nursing care plan
    TYPE t_nnn_ux_epis_outcome_rec IS RECORD(
        id                  t_map_key, -- ID to be used as reference identifier in the collections of linkages        
        id_nnn_epis_outcome nnn_epis_outcome.id_nnn_epis_outcome%TYPE, -- Episode's NOC Outcome ID
        id_noc_outcome      nnn_epis_outcome.id_noc_outcome%TYPE, -- NOC Outcome ID
        noc_code            nnn_epis_outcome.noc_code%TYPE, -- NOC Code
        outcome_name        pk_translation.t_desc_translation, -- Outcome description
        flg_req_status      nnn_epis_outcome.flg_req_status%TYPE, -- Request status: Order, Draft, etc.
        linked_diagnoses    table_varchar, -- Linked diagnoses for this NOC outcome
        linked_indicators   table_varchar, -- Linked indicators for this NOC outcome
        instructions        t_nnn_ux_instructions_rec, -- Instructions
        outcome_evaluation  t_nnn_ux_epis_outcome_eval_rec --  Outcome evaluation
        );

    -- Typed record with the information sent by the UX layer about the evaluation of a nursing indicator 
    TYPE t_nnn_ux_epis_ind_eval_rec IS RECORD(
        id_nnn_epis_ind_eval nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE, -- Episode's NOC Indicator evaluation ID
        dt_evaluation        nnn_epis_ind_eval.dt_evaluation%TYPE, -- Evaluation date
        target_value         nnn_epis_ind_eval.target_value%TYPE, -- Indicator Target rating: Likert scale (1 to 5)
        indicator_value      nnn_epis_ind_eval.indicator_value%TYPE, -- Indicator overall rating: Likert scale (1 to 5)
        notes                CLOB -- Notes about indicator evaluation
        );

    -- Typed record with the information sent by the UX layer about nursing indicator in the creation of a patient's nursing care plan
    TYPE t_nnn_ux_epis_indicator_rec IS RECORD(
        id                    t_map_key, -- ID to be used as reference identifier in the collections of linkages        
        id_nnn_epis_indicator nnn_epis_indicator.id_nnn_epis_indicator%TYPE, -- Episode's NOC Indicator ID
        id_noc_indicator      nnn_epis_indicator.id_noc_indicator%TYPE, -- NOC Indicator ID
        indicator_name        pk_translation.t_desc_translation, -- Indicator name
        flg_req_status        nnn_epis_indicator.flg_req_status%TYPE, -- Request status: Order, Draft, etc.
        linked_outcomes       table_varchar, -- Linked outcomes for this NOC indicator
        instructions          t_nnn_ux_instructions_rec, -- Instructions
        indicator_evaluation  t_nnn_ux_epis_ind_eval_rec -- Indicator evaluation
        );

    -- Typed record with the information sent by the UX layer about nursing intervention in the creation of a patient's nursing care plan
    TYPE t_nnn_ux_epis_intervention_rec IS RECORD(
        id                       t_map_key, -- ID to be used as reference identifier in the collections of linkages
        id_nnn_epis_intervention nnn_epis_intervention.id_nnn_epis_intervention%TYPE, -- Episode's NIC Intervention ID
        id_nic_intervention      nnn_epis_intervention.id_nic_intervention%TYPE, -- NIC Intervention ID
        nic_code                 nnn_epis_intervention.nic_code%TYPE, -- NIC Code
        intervention_name        pk_translation.t_desc_translation, -- Intervention Name
        flg_req_status           nnn_epis_intervention.flg_req_status%TYPE, -- Request status: Order, Draft, etc.
        linked_diagnoses         table_varchar, -- Linked diagnosis for this NIC intervention
        linked_activities        table_varchar -- Linked activities for this NIC intervention
        );

    TYPE t_nnn_ux_epis_activity_rec IS RECORD(
        id                   t_map_key, -- ID to be used as reference identifier in the collections of linkages
        id_nnn_epis_activity nnn_epis_activity.id_nnn_epis_activity%TYPE, -- Episode's NIC Activity ID
        id_nic_activity      nnn_epis_activity.id_nic_activity%TYPE, -- NIC Activity ID
        activity_name        pk_translation.t_desc_translation, -- Activity name
        flg_req_status       nnn_epis_activity.flg_req_status%TYPE, -- Request status: Order, Draft, etc. 
        instructions         t_nnn_ux_instructions_rec, -- Instructions
        linked_interventions table_varchar -- Linked interventions for this NIC activity         
        );

    -- Typed record with the information sent by the UX layer about execution of a NIC activity
    TYPE t_nnn_ux_set_activity_exec_rec IS RECORD(
        i_nnn_epis_activity          nnn_epis_activity_det.id_nnn_epis_activity%TYPE,
        i_nnn_epis_activity_det      nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_time_start                 pk_types.t_low_char,
        i_time_end                   pk_types.t_low_char,
        i_doc_template               doc_template.id_doc_template%TYPE,
        i_lst_documentation          table_number,
        i_lst_doc_element            table_number,
        i_lst_doc_element_crit       table_number,
        i_lst_value                  table_varchar,
        i_lst_lst_doc_element_qualif table_table_number,
        i_lst_vs_element             table_number,
        i_lst_vs_save_mode           table_varchar,
        i_lst_vs                     table_number,
        i_lst_vs_value               table_number,
        i_lst_vs_uom                 table_number,
        i_lst_vs_scales              table_number,
        i_lst_vs_date                table_varchar,
        i_lst_vs_read                table_number,
        i_notes                      CLOB,
        i_lst_task_activity          table_number,
        i_lst_task_executed          table_varchar,
        i_lst_task_notes             table_varchar,
        i_lst_supply_workflow        table_number,
        i_lst_supply                 table_number,
        i_lst_supply_set             table_number,
        i_lst_supply_qty             table_number,
        i_lst_supply_type            table_varchar,
        i_lst_supply_barcode_scanned table_varchar,
        i_lst_supply_deliver_needed  table_varchar,
        i_lst_supply_cons_type       table_varchar,
        i_lst_supply_dt_expiration   table_varchar,
        i_lst_supply_validation      table_varchar,
        i_lst_supply_lot             table_varchar);

    TYPE t_map_epis_diagnosis IS TABLE OF t_nnn_ux_epis_diagnosis_rec INDEX BY t_map_key;
    TYPE t_map_epis_outcome IS TABLE OF t_nnn_ux_epis_outcome_rec INDEX BY t_map_key;
    TYPE t_map_epis_indicator IS TABLE OF t_nnn_ux_epis_indicator_rec INDEX BY t_map_key;
    TYPE t_map_epis_intervention IS TABLE OF t_nnn_ux_epis_intervention_rec INDEX BY t_map_key;
    TYPE t_map_epis_activity IS TABLE OF t_nnn_ux_epis_activity_rec INDEX BY t_map_key;

    TYPE t_lst_nnn_ux_set_activity_exec IS TABLE OF t_nnn_ux_set_activity_exec_rec;

    -- Public constant declarations
    /* A typical usage of this boolean constants is
        
    $if pk_nnn_type.is_debug $then
    code supported for Debug Mode
    $else
    code supported for Production
    $end
    */
    is_debug CONSTANT BOOLEAN := TRUE;

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Deserialize a JSON object to a t_nnn_ux_instructions_rec record
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A record t_nnn_ux_instructions_rec
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_instructions
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_instructions_rec;

    /**
    * Serialize a t_nnn_ux_instructions_rec record to a JSON object
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A JSON objcet
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_instructions
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_instructions_rec
    ) RETURN json_object_t;

    /**
    * Deserialize a JSON object to a t_nnn_ux_epis_diag_eval_rec record
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A record t_nnn_ux_epis_diag_eval_rec
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_diag_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_diag_eval_rec;

    /**
    * Serialize a t_nnn_ux_epis_diag_eval_rec record to a JSON object
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A JSON objcet
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_diag_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_diag_eval_rec
    ) RETURN json_object_t;

    /**
    * Deserialize a JSON object to a t_nnn_ux_epis_diagnosis_rec record
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A record t_nnn_ux_epis_diagnosis_rec
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_diagnosis
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_diagnosis_rec;

    /**
    * Serialize a t_nnn_ux_epis_diagnosis_rec record to a JSON object
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A JSON objcet
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_diagnosis
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_diagnosis_rec
    ) RETURN json_object_t;

    /**
    * Deserialize a JSON object to a t_nnn_ux_epis_outcome_eval_rec record
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A record t_nnn_ux_epis_outcome_eval_rec
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_outcome_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_outcome_eval_rec;

    /**
    * Serialize a t_nnn_ux_epis_outcome_eval_rec record to a JSON object
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A JSON objcet
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_outcome_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_outcome_eval_rec
    ) RETURN json_object_t;

    /**
    * Deserialize a JSON object to a t_nnn_ux_epis_outcome_rec record
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A record t_nnn_ux_epis_outcome_rec
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_outcome
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_outcome_rec;

    /**
    * Serialize a t_nnn_ux_epis_outcome_rec record to a JSON object
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A JSON objcet
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_outcome
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_outcome_rec
    ) RETURN json_object_t;

    /**
    * Deserialize a JSON object to a t_nnn_ux_epis_indicator_rec record
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A record t_nnn_ux_epis_indicator_rec
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_indicator
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_indicator_rec;

    /**
    * Serialize a t_nnn_ux_epis_indicator_rec record to a JSON object
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A JSON objcet
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_indicator
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_indicator_rec
    ) RETURN json_object_t;

    /**
    * Deserialize a JSON object to a t_nnn_ux_epis_ind_eval_rec record
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A record t_nnn_ux_epis_ind_eval_rec
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_ind_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_ind_eval_rec;

    /**
    * Serialize a t_nnn_ux_epis_ind_eval_rec record to a JSON object
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A JSON objcet
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_ind_eval
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_ind_eval_rec
    ) RETURN json_object_t;

    /**
    * Deserialize a JSON object to a t_nnn_ux_epis_intervention_rec record
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A record t_nnn_ux_epis_intervention_rec
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_intervention
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_intervention_rec;

    /**
    * Serialize a t_nnn_ux_epis_intervention_rec record to a JSON object
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A JSON objcet
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_intervention
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_intervention_rec
    ) RETURN json_object_t;

    /**
    * Deserialize a JSON object to a t_nnn_ux_epis_activity_rec record
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A record t_nnn_ux_epis_activity_rec
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_activity
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_epis_activity_rec;

    /**
    * Serialize a t_nnn_ux_epis_activity_rec record to a JSON object
    *
    * @param    i_lang 
    * @param    i_prof 
    * @param    i_json 
    *
    * @return   A JSON objcet
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/25/2013
    */
    FUNCTION get_nnn_ux_epis_activity
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_epis_activity_rec
    ) RETURN json_object_t;

    /**
    * Extract from a nursing care plan in JSON the nested collection of NANDA diagnoses
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_json              JSON object with a pair-name "DIAGNOSES"
    *
    * @return  A map of t_nnn_ux_epis_diagnosis_rec records using the ID property as key.
    *
    * @author   ARIEL.MACHADO
    * @since    12/9/2013
    */
    FUNCTION get_map_ux_epis_diagnosis
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_map_epis_diagnosis;

    /**
    * Extract from a nursing care plan in JSON the nested collection of NOC outcomes
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_json              JSON object with a pair-name "OUTCOMES"
    *
    * @return  A map of t_nnn_ux_epis_outcome_rec records using the ID property as key.
    *
    * @author   ARIEL.MACHADO
    * @since    12/9/2013
    */
    FUNCTION get_map_ux_epis_outcome
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_map_epis_outcome;

    /**
    * Extract from a nursing care plan in JSON the nested collection of NOC indicators
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_json              JSON object with a pair-name "INDICATORS"
    *
    * @return  A map of t_map_epis_indicator records using the ID property as key.
    *
    * @author   ARIEL.MACHADO
    * @since    12/9/2013
    */
    FUNCTION get_map_ux_epis_indicator
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_map_epis_indicator;

    /**
    * Extract from a nursing care plan in JSON the nested collection of NIC interventions
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_json              JSON object with a pair-name "INTERVENTIONS"
    *
    * @return  A map of t_nnn_ux_epis_intervention_rec records using the ID property as key.
    *
    * @author   ARIEL.MACHADO
    * @since    12/9/2013
    */
    FUNCTION get_map_ux_epis_intervention
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_map_epis_intervention;

    /**
    * Extract from a nursing care plan in JSON the nested collection of NIC activities
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_json              JSON object with a pair-name "ACTIVITIES"
    *
    * @return  A map of t_nnn_ux_epis_activity_rec records using the ID property as key.
    *
    * @author   ARIEL.MACHADO
    * @since    12/9/2013
    */
    FUNCTION get_map_ux_epis_activity
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_map_epis_activity;

    /**
    * Deserialize a JSON object to a t_nnn_ux_set_activity_exec_rec record
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_json              JSON object with input parameters required by set_pk_nnn_api_db.activity_execute().
    *
    * @return   A record t_nnn_ux_epis_activity_rec
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    09/11/2014
    */
    FUNCTION get_nnn_ux_set_activity_exec
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_nnn_ux_set_activity_exec_rec;

    /**
    * Serializea t_nnn_ux_set_activity_exec_rec record to a JSON object
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_type              Record with input parameters required by set_pk_nnn_api_db.activity_execute().
    *
    * @return   A JSON object
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    09/12/2014
    */
    FUNCTION get_nnn_ux_set_activity_exec
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN t_nnn_ux_set_activity_exec_rec
    ) RETURN json_object_t;

    /**
    * Extracts from a JSON sent by UX the input parameters required to save executions of NIC activities.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_json              JSON object with a pair-name "LST_SET_ACTIVITY_EXECUTE"
    *
    * @return  A collection of t_nnn_ux_set_activity_exec_rec. One record for each activity execution to save
    *
    * @author   ARIEL.MACHADO
    * @since    09/11/2014
    */
    FUNCTION get_lst_ux_set_activity_exec
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_json IN json_object_t
    ) RETURN t_lst_nnn_ux_set_activity_exec;

END pk_nnn_type;
/
