/*-- Last Change Revision: $Rev: 1587097 $*/
/*-- Last Change by: $Author: sergio.dias $*/
/*-- Date of last change: $Date: 2014-05-08 16:28:38 +0100 (qui, 08 mai 2014) $*/
CREATE OR REPLACE PACKAGE pk_mig_diagnosis IS

    ---------------------------------------------------------------------------------------------
    -- Content tables 
    ---------------------------------------------------------------------------------------------

    -- Terminology
    r_terminology         alert_core_func.pk_api_diagnosis_func.r_terminology%TYPE;
    r_terminology_version alert_core_func.pk_api_diagnosis_func.r_terminology_version%TYPE;

    -- Concept type
    r_concept_type        alert_core_func.pk_api_diagnosis_func.r_concept_type%TYPE;
    r_termin_concept_type alert_core_func.pk_api_diagnosis_func.r_termin_concept_type%TYPE;

    -- Concept
    r_concept          alert_core_func.pk_api_diagnosis_func.r_concept%TYPE;
    r_concept_type_rel alert_core_func.pk_api_diagnosis_func.r_concept_type_rel%TYPE;
    r_concept_version  alert_core_func.pk_api_diagnosis_func.r_concept_version%TYPE;

    -- Concept term
    r_concept_term           alert_core_func.pk_api_diagnosis_func.r_concept_term%TYPE;
    r_concept_term_type      alert_core_func.pk_api_diagnosis_func.r_concept_term_type%TYPE;
    r_concept_term_task_type alert_core_func.pk_api_diagnosis_func.r_concept_term_task_type%TYPE;

    -- Concept relation
    r_concept_relation alert_core_func.pk_api_diagnosis_func.r_concept_relation%TYPE;
    r_concept_rel_type alert_core_func.pk_api_diagnosis_func.r_concept_rel_type%TYPE;

    ---------------------------------------------------------------------------------------------
    -- Configuration tables
    ---------------------------------------------------------------------------------------------

    r_msi_termin_version    alert_core_func.pk_api_diagnosis_func.r_msi_termin_version%TYPE;
    r_msi_cncpt_vers_attrib alert_core_func.pk_api_diagnosis_func.r_msi_cncpt_vers_attrib%TYPE;
    r_msi_concept_term      alert_core_func.pk_api_diagnosis_func.r_msi_concept_term%TYPE;
    r_msi_concept_relation  alert_core_func.pk_api_diagnosis_func.r_msi_concept_relation%TYPE;

    ---------------------------------------------------------------------------------------------
    -- Default tables
    ---------------------------------------------------------------------------------------------    

    r_def_concept_relation  alert_core_func.pk_api_diagnosis_func.r_def_concept_relation%TYPE;
    r_def_cncpt_vers_attrib alert_core_func.pk_api_diagnosis_func.r_def_cncpt_vers_attrib%TYPE;
    r_def_concept_term      alert_core_func.pk_api_diagnosis_func.r_def_concept_term%TYPE;

    ---------------------------------------------------------------------------------------------
    -- Other globals
    ---------------------------------------------------------------------------------------------

    g_error VARCHAR2(200 CHAR);
    g_yes   VARCHAR2(1 CHAR) := 'Y';
    g_no    VARCHAR2(1 CHAR) := 'N';

    -- INST_OWNER columns are always 0
    g_inst_owner NUMBER(24) := 0;

    -- INSTITUTION 0
    g_inst_zero institution.id_institution%TYPE := 0;

    -- PROFESSIONAL 0
    g_id_professional_zero professional.id_professional%TYPE := 0;

    -- Default rank
    g_rank_zero NUMBER(6) := 0;

    -- DEP_CLIN_SERV and CLINICAL_SERVICE default ID's
    g_id_dep_clin_serv_default    dep_clin_serv.id_dep_clin_serv%TYPE := -1;
    g_id_clinical_service_default clinical_service.id_clinical_service%TYPE := -1;

    -- ID_TASK_TYPE values -- 
    -- 60 PL - Problems
    -- 62 MH - Medical history
    -- 63 DG - Diagnosis
    g_id_task_type_pl task_type.id_task_type%TYPE := 60;
    g_id_task_type_mh task_type.id_task_type%TYPE := 62;
    g_id_task_type_dg task_type.id_task_type%TYPE := 63;
    -- 61 SH - Surgical History
    g_id_task_type_sh task_type.id_task_type%TYPE := 61;
    -- 64 CA - Congenital Anomalies
    g_id_task_type_ca task_type.id_task_type%TYPE := 64;
    -- Death Event task type
    g_id_task_type_de task_type.id_task_type%TYPE := 87;

    -- ALERT_DIAGNOSIS.FLG_TYPE values:
    g_flg_type_m alert_diagnosis.flg_type%TYPE := 'M'; -- Medical
    g_flg_type_s alert_diagnosis.flg_type%TYPE := 'S'; -- Surgical
    g_flg_type_a alert_diagnosis.flg_type%TYPE := 'A'; -- Congenital anomalies

    ---------------------------------------------------------------------------------------------
    -- Migration functions
    ---------------------------------------------------------------------------------------------

    /********************************************************************************************
    * DIAGNOSIS, ALERT_DIAGNOSIS and DIAGNOSIS_DEP_CLIN_SERV migration script.
    *
    * @param i_output                  Output debug strings: [1] Output ON  [Other value] Output OFF
    * @param i_commit                  [1] Commit data  [Other value] Commit OFF
    * @param o_error                   Error object
    * 
    * @return                          True: sucess / False: failed
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION mig_alert_diagnosis
    (
        i_output IN NUMBER,
        i_commit IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Migration script for DIAGNOSIS_EA
    *
    * @param i_commit                  [1] Commit data  [Other value] Commit OFF
    * @param o_error                   Error object
    *
    * @return                          True: sucess / False: failed
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION mig_diagnosis_ea
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_commit      IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Migration script for DIAGNOSIS_RELATIONS_EA
    *
    * @param i_commit                  [1] Commit data  [Other value] Commit OFF
    * @param o_error                   Error object
    *
    * @return                          True: sucess / False: failed
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           21-Mar-2012
    *
    **********************************************************************************************/
    FUNCTION mig_diagnosis_relations_ea
    (
        i_commit IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Migration script for Past history 
    *
    * @param i_commit                  [1] Commit data  [Other value] Commit OFF
    * @param o_error                   Error object
    *
    * @return                          True: sucess / False: failed
    *
    * @author                          Alexandre Santos
    * @version                         2.6.2
    * @since                           01-Jun-2012
    *
    **********************************************************************************************/
    FUNCTION mig_past_history
    (
        i_commit IN NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

END pk_mig_diagnosis;
/
