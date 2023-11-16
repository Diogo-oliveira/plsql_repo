/*-- Last Change Revision: $Rev: 2028483 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_pfh_diagnosis_in IS

    -- Author  : José Silva
    -- Purpose : Handle calls to the new diagnosis data model

    ---------------------------------------------------------------------------------------------
    -- Easy access tables
    ---------------------------------------------------------------------------------------------

    -- DIAGNOSIS_EA
    g_rec_diagnosis_ea alert_core_func.pk_api_diagnosis_func.g_rec_diagnosis_ea;
    g_tbl_diagnosis_ea alert_core_func.pk_api_diagnosis_func.g_tbl_diagnosis_ea;

    -- DIAGNOSIS_RELATIONS_EA
    g_rec_diagnosis_rel_ea alert_core_func.pk_api_diagnosis_func.g_rec_diagnosis_rel_ea;
    g_tbl_diagnosis_rel_ea alert_core_func.pk_api_diagnosis_func.g_tbl_diagnosis_rel_ea;

    /**********************************************************************************************
    * Get the parent diagnosis (to be used in the views that simultate the old column DIAGNOSIS.ID_DIAGNOSIS_PARENT)
    *
    * @param i_concept                concept ID
    * @param i_terminology_ver        terminology version ID
    *
    * @return                         diagnosis parent ID (concept version ID)
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/08
    **********************************************************************************************/
    FUNCTION get_diagnosis_parent
    (
        i_concept         IN concept.id_concept%TYPE,
        i_terminology_ver IN concept_version.id_terminology_version%TYPE
    ) RETURN concept_version.id_concept_version%TYPE;

    /**********************************************************************************************
    * Get the parent diagnosis (to be used in the views that simultate the old column DIAGNOSIS.ID_DIAGNOSIS_PARENT)
    *
    * @param i_concept_version        diagnosis/concept version ID
    *
    * @return                         diagnosis parent ID (concept version ID)
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/27
    **********************************************************************************************/
    FUNCTION get_diagnosis_parent(i_concept_version IN concept_version.id_concept_version%TYPE)
        RETURN concept_version.id_concept_version%TYPE;

    /**********************************************************************************************
    * Get the histology of a given morphology
    *
    * @param i_concept                concept ID
    * @param i_terminology_ver        terminology version ID
    *
    * @return                         diagnosis parent ID (concept version ID)
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/27
    **********************************************************************************************/
    FUNCTION get_hist_by_morphology
    (
        i_concept         IN concept.id_concept%TYPE,
        i_terminology_ver IN concept_version.id_terminology_version%TYPE
    ) RETURN concept_version.id_concept_version%TYPE;

    /********************************************************************************************
    * Get the diagnosis type
    *
    * @param i_id_terminology          Terminology ID
    * 
    * @return                          Diagnosis type
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           28-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_diag_flg_type(i_id_terminology IN terminology.id_terminology%TYPE) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the value of FLG_OTHER
    *
    * @param i_id_terminology          Terminology ID
    * @param i_id_concept              Concept ID
    * 
    * @return                          FLG_OTHER
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           24-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_diag_flg_other
    (
        i_id_terminology IN concept.id_terminology%TYPE,
        i_id_concept     IN concept.id_concept%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the value of concept type INTERNAL_NAME
    *
    * @param i_id_terminology          Terminology ID
    * @param i_id_concept              Concept ID
    * 
    * @return                          INTERNAL_NAME
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           24-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_diag_int_name
    (
        i_id_terminology IN concept.id_terminology%TYPE,
        i_id_concept     IN concept.id_concept%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the definition of a concept included in a specific version
    *
    * @param i_lang                   user language ID   
    * @param i_concept_version        concept ID
    * @param i_task_type              task type ID
    * @param i_lang_termin            terminology language ID
    *
    * @return                         concept description
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/18
    **********************************************************************************************/
    FUNCTION get_concept_definition_term
    (
        i_lang            IN language.id_language%TYPE,
        i_concept_version IN concept_version.id_concept_version%TYPE,
        i_lang_termin     IN terminology_version.id_language%TYPE,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the fully specified name of a concept included in a specific version
    *
    * @param i_lang                   user language ID   
    * @param i_concept_version        concept ID
    * @param i_task_type              task type ID
    * @param i_lang_termin            terminology language ID
    *
    * @return                         concept description
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/18
    **********************************************************************************************/
    FUNCTION get_concept_fsn_term
    (
        i_lang            IN language.id_language%TYPE,
        i_concept_version IN concept_version.id_concept_version%TYPE,
        i_lang_termin     IN terminology_version.id_language%TYPE,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the preferred term of a concept included in a specific version
    *
    * @param i_concept_version        concept ID
    * @param i_task_type              task type ID
    *
    * @return                         concept description
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/09
    **********************************************************************************************/
    FUNCTION get_diag_preferred_term
    (
        i_concept_version IN concept.id_concept%TYPE,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the preferred term ID of a concept included in a specific version
    *
    * @param i_concept_version        concept ID
    * @param i_task_type              task type ID
    *
    * @return                         concept term id
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/09
    **********************************************************************************************/
    FUNCTION get_diag_preferred_term_id
    (
        i_concept_version IN concept_version.id_concept_version%TYPE,
        i_task_type       IN NUMBER DEFAULT 63
    ) RETURN concept_term.id_concept_term%TYPE;

    /**********************************************************************************************
    * Get the term of a concept based on the task type
    *
    * @param i_concept_term           concept term ID
    * @param i_task_type              task type ID
    *
    * @return                         concept description
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/09
    **********************************************************************************************/
    FUNCTION get_diag_term
    (
        i_concept_term IN concept_term.id_concept_term%TYPE,
        i_task_type    IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis
    ) RETURN concept_term_task_type.code_concept_term%TYPE;

    /********************************************************************************************
    * Get the value for ALERT_DIAGNOSIS.FLG_TYPE / DIAGNOSIS_EA.FLG_DIAG_TYPE
    *
    * @param i_id_concept_term         Concept term ID
    * 
    * @return                          Value for ALERT_DIAGNOSIS.FLG_TYPE / DIAGNOSIS_EA.FLG_DIAG_TYPE
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           02-Mar-2012
    *
    **********************************************************************************************/
    FUNCTION get_alert_diag_flg_type
    (
        i_id_concept_term IN concept_term.id_concept_term%TYPE,
        i_id_task_type    IN task_type.id_task_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the value for ALERT_DIAGNOSIS.FLG_ICD9
    *
    * @param i_concept_term           concept term ID
    *
    * @return                         value for ALERT_DIAGNOSIS.FLG_ICD9
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/09
    **********************************************************************************************/
    FUNCTION get_alert_diag_flg_icd9(i_concept_term IN concept_term.id_concept_term%TYPE) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the language applicable for a concept available in a specific terminology
    *
    * @param i_concept_version        concept version ID
    *
    * @return                         language ID
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/09
    **********************************************************************************************/
    FUNCTION get_concept_id_language(i_concept_version IN concept_version.id_concept_version%TYPE) RETURN NUMBER;

    /**********************************************************************************************
    * Get the concept version ID of a concept type that refers to the 'Any' validation
    *
    * @param i_concept_type_int_name  concept type internal name
    *
    * @return                         concept version ID
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/19
    **********************************************************************************************/
    FUNCTION get_concept_validation_any(i_concept_type_int_name IN concept_type.internal_name%TYPE)
        RETURN concept_version.id_concept_version%TYPE;

    /**
    * Get the concept version ids associated with a concept
    *
    * @param   i_concept          Concept ID
    *
    * @return  Concept version IDs
    *
    * @author  José Silva
    * @version v2.6.2
    * @since   04/Jun/2012
    */
    FUNCTION get_id_concept_version(i_concept IN concept.id_concept%TYPE) RETURN table_number;

    /**
    * Get the concept id associated with a concept version
    *
    * @param   i_concept_version          Concept version ID
    *
    * @return  Concept ID
    *
    * @author  José Silva
    * @version v2.6.2
    * @since   04/Jun/2012
    */
    FUNCTION get_id_concept(i_concept_version IN concept_version.id_concept_version%TYPE) RETURN concept.id_concept%TYPE;

    /********************************************************************************************
    * Get data to DIAGNOSIS_EA, through MSI_CONCEPT_TERM rowids
    *
    * @param i_rowids                  List of row ID's
    * @param i_flg_active              Filter by record status: Active? 
    *                                  (Y) Yes (N) No (NULL) Doesn't filter results - default.
    *
    * @return                          Collection of DIAGNOSIS_EA data
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           02-Mar-2012
    *
    **********************************************************************************************/
    FUNCTION get_ea_data_by_mct
    (
        i_rowids     IN table_varchar,
        i_flg_active IN VARCHAR2 DEFAULT NULL
    ) RETURN g_tbl_diagnosis_ea%TYPE;

    /********************************************************************************************
    * Get data to DIAGNOSIS_EA, through MSI_TERMIN_VERSION rowids
    *
    * @param i_rowids                  List of row ID's
    * @param i_flg_active              Filter by record status: Active? 
    *                                  (Y) Yes (N) No (NULL) Doesn't filter results - default.
    *
    * @return                          Collection of DIAGNOSIS_EA data
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           02-Mar-2012
    *
    **********************************************************************************************/
    FUNCTION get_ea_data_by_mtv
    (
        i_rowids     IN table_varchar,
        i_flg_active IN VARCHAR2 DEFAULT NULL
    ) RETURN g_tbl_diagnosis_ea%TYPE;

    /********************************************************************************************
    * Get data to DIAGNOSIS_EA, through msi_cncpt_vers_attrib rowids
    *
    * @param i_rowids                  List of row ID's
    * @param i_flg_active              Filter by record status: Active? 
    *                                  (Y) Yes (N) No (NULL) Doesn't filter results - default.
    *
    * @return                          Collection of DIAGNOSIS_EA data
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           02-Mar-2012
    *
    **********************************************************************************************/
    FUNCTION get_ea_data_by_mcva
    (
        i_rowids     IN table_varchar,
        i_flg_active IN VARCHAR2 DEFAULT NULL
    ) RETURN g_tbl_diagnosis_ea%TYPE;

    /********************************************************************************************
    * Get data to DIAGNOSIS_EA (migration script)
    *
    * @return                          Collection of DIAGNOSIS_EA data
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           16-Mar-2012
    *
    **********************************************************************************************/
    FUNCTION get_ea_data_for_migration(i_institution IN institution.id_institution%TYPE DEFAULT NULL)
        RETURN g_tbl_diagnosis_ea%TYPE;

    /********************************************************************************************
    * Get data to DIAGNOSIS_RELATIONS_EA, through MSI_CONCEPT_RELATION rowids
    *
    * @param i_rowids                  List of row ID's
    * @param i_flg_active              Filter by record status: Active? 
    *                                  (Y) Yes (N) No (NULL) Doesn't filter results - default.
    *
    * @return                          Collection of DIAGNOSIS_RELATIONS_EA data
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           19-Mar-2012
    *
    **********************************************************************************************/
    FUNCTION get_relations_ea_data_by_mcr
    (
        i_rowids     IN table_varchar,
        i_flg_active IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_api_diagnosis_func.g_tbl_diagnosis_rel_ea;

    /********************************************************************************************
    * Get data to DIAGNOSIS_RELATIONS_EA (migration script)
    *
    * @return                          Collection of DIAGNOSIS_RELATIONS_EA data
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           21-Mar-2012
    *
    **********************************************************************************************/
    FUNCTION get_relations_ea_data_for_migr RETURN alert_core_func.pk_api_diagnosis_func.g_tbl_diagnosis_rel_ea;

    /********************************************************************************************
    * Insert into msi_cncpt_vers_attrib.
    *
    * @param i_lang                              Language ID
    * @param i_prof                              Professional info
    * @param i_msi_cncpt_vers_attrib        msi_cncpt_vers_attrib row
    * @param o_rows                              Inserted row ID's
    * @param o_error                             Error message
    *
    * @return                                    TRUE / FALSE
    *
    * @author                                    José Brito
    * @version                                   2.6.2
    * @since                                     13-Mar-2012
    *
    **********************************************************************************************/
    FUNCTION ins_msi_cncpt_vers_attrib
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_msi_cncpt_vers_attrib IN msi_cncpt_vers_attrib%ROWTYPE,
        o_rows                  OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert into MSI_CONCEPT_RELATION.
    *
    * @param i_lang                              Language ID
    * @param i_prof                              Professional info
    * @param i_msi_concept_relation              MSI_CONCEPT_RELATION row
    * @param o_rows                              Inserted row ID's
    * @param o_error                             Error message
    *
    * @return                                    TRUE / FALSE
    *
    * @author                                    José Brito
    * @version                                   2.6.2
    * @since                                     13-Mar-2012
    *
    **********************************************************************************************/
    FUNCTION ins_msi_concept_relation
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_msi_concept_relation IN msi_concept_relation%ROWTYPE,
        o_rows                 OUT table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert into MSI_CONCEPT_TERM.
    *
    * @param i_lang                              Language ID
    * @param i_prof                              Professional info
    * @param i_msi_concept_term                  MSI_CONCEPT_TERM row
    * @param o_rows                              Inserted row ID's
    * @param o_error                             Error message
    *
    * @return                                    TRUE / FALSE
    *
    * @author                                    José Brito
    * @version                                   2.6.2
    * @since                                     13-Mar-2012
    *
    **********************************************************************************************/
    FUNCTION ins_msi_concept_term
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_msi_concept_term IN msi_concept_term%ROWTYPE,
        o_rows             OUT table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert into CONCEPT.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_concept                 CONCEPT row
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION ins_concept
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_concept IN concept%ROWTYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert into CONCEPT_TYPE_REL.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_concept_type_rel        CONCEPT_TYPE_REL row
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION ins_concept_type_rel
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_concept_type_rel IN concept_type_rel%ROWTYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert into CONCEPT_VERSION.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_concept_version         CONCEPT_VERSION row
    * @param o_error                   Error message
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION ins_concept_version
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_concept_version IN concept_version%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert into CONCEPT_TERM.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_concept_term            CONCEPT_TERM row
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           09-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION ins_concept_term
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_concept_term IN concept_term%ROWTYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert into CONCEPT_TERM_TASK_TYPE.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_concept_term_task_type  CONCEPT_TERM_TASK_TYPE row
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           09-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION ins_concept_term_task_type
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_concept_term_task_type IN concept_term_task_type%ROWTYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert into CONCEPT_RELATION.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_concept_relation        CONCEPT_RELATION row
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           10-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION ins_concept_relation
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_concept_relation IN concept_relation%ROWTYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert into MSI_TERMIN_VERSION.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_msi_termin_version      MSI_TERMIN_VERSION row
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *
    * @author                                    José Brito
    * @version                                   2.6.2
    * @since                                     17-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION ins_msi_termin_version
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_msi_termin_version IN msi_termin_version%ROWTYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert missing past history diagnoses MSI
    *
    * @param   i_concept_version          Concept version ID
    *
    * @return  The concept path
    *
    * @author  Alexandre Santos
    * @version v2.6.2
    * @since   01/Jun/2012
    */
    PROCEDURE ins_missing_past_hist_diags;

    /********************************************************************************************
    * Returns terminology information given an id_concept_version
    *
    * @param i_concept_version        Concept version ID
    *
    * @return                          pk_api_termin_server_func.g_rec_terminology_info
    *
    * @author                          Sergio Dias
    * @version                         2.6.3.8.4
    * @since                           Nov/11/2013
    *
    **********************************************************************************************/
    FUNCTION get_terminology_information(i_concept_version IN concept_version.id_concept_version%TYPE)
        RETURN pk_api_termin_server_func.g_rec_terminology_info;

    /********************************************************************************************
    * Returns terminology information given an id_terminology
    *
    * @param i_terminology            Terminology ID
    *
    * @return                          pk_api_termin_server_func.g_rec_terminology_info
    *
    * @author                          Sergio Dias
    * @version                         2.6.3.8.4
    * @since                           Nov/11/2013
    *
    **********************************************************************************************/
    FUNCTION get_terminology_information(i_terminology IN terminology.id_terminology%TYPE)
        RETURN pk_api_termin_server_func.g_rec_terminology_info;
END pk_api_pfh_diagnosis_in;
/
