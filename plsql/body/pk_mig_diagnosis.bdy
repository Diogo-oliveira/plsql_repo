/*-- Last Change Revision: $Rev: 1684330 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2015-02-11 10:39:32 +0000 (qua, 11 fev 2015) $*/
CREATE OR REPLACE PACKAGE BODY pk_mig_diagnosis IS

    ---------------------------------------------------------------------------------------------
    -- PROCEDURES
    ---------------------------------------------------------------------------------------------

    -- Outputs data (for DEBUG only)
    PROCEDURE int_proc_output_record
    (
        i_level        NUMBER,
        i_id_diagnosis NUMBER,
        i_output       NUMBER
    ) IS
        l_str       VARCHAR2(200 CHAR);
        l_final_str VARCHAR2(200 CHAR);
        l_level     NUMBER(6);
        l_pad_str   VARCHAR2(1 CHAR) := '-';
    BEGIN
        -- Output control string
        IF i_output = 1
        THEN
            IF i_level < 0
            THEN
                l_level := 0;
            ELSE
                l_level := i_level;
            END IF;
        
            l_str := '>' || ' ' || i_id_diagnosis || ' [' || i_level || ']';
        
            l_final_str := lpad(l_str, l_level + length(l_str), l_pad_str);
        
            dbms_output.put_line(l_final_str);
        END IF;
    END int_proc_output_record;

    /********************************************************************************************
    * Insert into CONCEPT.
    *
    * @param i_concept                 CONCEPT row
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_concept(i_concept IN r_concept%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_concept(i_concept => i_concept);
    END ins_concept;

    /********************************************************************************************
    * Insert into CONCEPT_TYPE_REL.
    *
    * @param i_concept_type_rel        CONCEPT_TYPE_REL row
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_concept_type_rel(i_concept_type_rel IN r_concept_type_rel%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_concept_type_rel(i_concept_type_rel => i_concept_type_rel);
    END ins_concept_type_rel;

    /********************************************************************************************
    * Insert into CONCEPT_VERSION.
    *
    * @param i_concept_version         CONCEPT_VERSION row
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_concept_version(i_concept_version IN r_concept_version%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_concept_version(i_concept_version => i_concept_version);
    END ins_concept_version;

    /********************************************************************************************
    * Insert into CONCEPT_TERM.
    *
    * @param i_concept_term            CONCEPT_TERM row
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           09-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_concept_term(i_concept_term IN r_concept_term%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_concept_term(i_concept_term => i_concept_term);
    END ins_concept_term;

    /********************************************************************************************
    * Insert into CONCEPT_TERM_TASK_TYPE.
    *
    * @param i_concept_term_task_type            CONCEPT_TERM_TASK_TYPE row
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           09-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_concept_term_task_type(i_concept_term_task_type IN r_concept_term_task_type%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_concept_term_task_type(i_concept_term_task_type => i_concept_term_task_type);
    END ins_concept_term_task_type;

    /********************************************************************************************
    * Insert into CONCEPT_RELATION.
    *
    * @param i_concept_relation            CONCEPT_RELATION row
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           10-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_concept_relation(i_concept_relation IN r_concept_relation%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_concept_relation(i_concept_relation => i_concept_relation);
    END ins_concept_relation;

    /********************************************************************************************
    * Insert into msi_cncpt_vers_attrib.
    *
    * @param i_msi_cncpt_vers_attrib        msi_cncpt_vers_attrib row
    *
    * @author                                    José Brito
    * @version                                   2.6.2
    * @since                                     13-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_msi_cncpt_vers_attrib(i_msi_cncpt_vers_attrib IN r_msi_cncpt_vers_attrib%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_msi_cncpt_vers_attrib(i_msi_cncpt_vers_attrib => i_msi_cncpt_vers_attrib);
    END ins_msi_cncpt_vers_attrib;

    /********************************************************************************************
    * Insert into MSI_CONCEPT_RELATION.
    *
    * @param i_msi_concept_relation              MSI_CONCEPT_RELATION row
    *
    * @author                                    José Brito
    * @version                                   2.6.2
    * @since                                     13-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_msi_concept_relation(i_msi_concept_relation IN r_msi_concept_relation%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_msi_concept_relation(i_msi_concept_relation => i_msi_concept_relation);
    END ins_msi_concept_relation;

    /********************************************************************************************
    * Insert into MSI_CONCEPT_TERM.
    *
    * @param i_MSI_CONCEPT_TERM                  MSI_CONCEPT_TERM row
    *
    * @author                                    José Brito
    * @version                                   2.6.2
    * @since                                     13-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_msi_concept_term(i_msi_concept_term IN r_msi_concept_term%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_msi_concept_term(i_msi_concept_term => i_msi_concept_term);
    END ins_msi_concept_term;

    /********************************************************************************************
    * Insert into MSI_TERMIN_VERSION.
    *
    * @param i_msi_termin_version                MSI_TERMIN_VERSION row
    *
    * @author                                    José Brito
    * @version                                   2.6.2
    * @since                                     17-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_msi_termin_version(i_msi_termin_version IN r_msi_termin_version%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_msi_termin_version(i_msi_termin_version => i_msi_termin_version);
    END ins_msi_termin_version;

    /********************************************************************************************
    * Insert into def_cncpt_vers_attrib.
    *
    * @param i_def_cncpt_vers_attrib        def_cncpt_vers_attrib row
    *
    * @author                                    José Brito
    * @version                                   2.6.2
    * @since                                     13-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_def_cncpt_vers_attrib(i_def_cncpt_vers_attrib IN r_def_cncpt_vers_attrib%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_def_cncpt_vers_attrib(i_def_cncpt_vers_attrib => i_def_cncpt_vers_attrib);
    END ins_def_cncpt_vers_attrib;

    /********************************************************************************************
    * Insert into def_CONCEPT_RELATION.
    *
    * @param i_def_concept_relation              def_CONCEPT_RELATION row
    *
    * @author                                    José Brito
    * @version                                   2.6.2
    * @since                                     13-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_def_concept_relation(i_def_concept_relation IN r_def_concept_relation%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_def_concept_relation(i_def_concept_relation => i_def_concept_relation);
    END ins_def_concept_relation;

    /********************************************************************************************
    * Insert into def_CONCEPT_TERM.
    *
    * @param i_def_concept_term                  def_CONCEPT_TERM row
    *
    * @author                                    José Brito
    * @version                                   2.6.2
    * @since                                     13-Feb-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_def_concept_term(i_def_concept_term IN r_def_concept_term%TYPE) IS
    BEGIN
        alert_core_func.pk_api_diagnosis_func.ins_def_concept_term(i_def_concept_term => i_def_concept_term);
    END ins_def_concept_term;

    ---------------------------------------------------------------------------------------------
    -- FUNCTIONS
    ---------------------------------------------------------------------------------------------

    /********************************************************************************************
    * Returns a list of ID_TASK_TYPE according to the value of ALERT_DIAGNOSIS.FLG_TYPE
    *
    * @param i_flg_type                Value of ALERT_DIAGNOSIS.FLG_TYPE                    
    * @param i_flg_sys_config          Migrating SYS_CONFIG entries: [Y] Yes [N] No - default
    * 
    * @return                          List with ID_TASK_TYPE
    *
    * @author                          José Brito
    * @version                         2.6
    * @since                           10-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_id_task_type_list
    (
        i_flg_type       IN alert_diagnosis.flg_type%TYPE,
        i_flg_sys_config IN VARCHAR2 DEFAULT 'N'
    ) RETURN table_number IS
        l_empty_table         table_number := table_number();
        l_tab_id_task_type    table_number;
        l_alert_diag_flg_type alert_diagnosis.flg_type%TYPE;
    BEGIN
    
        l_alert_diag_flg_type := upper(i_flg_type); -- "upper" is required to fix some lowercase values found in this column
    
        IF i_flg_sys_config = g_yes
        THEN
            -- When migrating SYS_CONFIG entries, return all supported values of ID_TASK_TYPE
            l_tab_id_task_type := table_number(g_id_task_type_dg,
                                               g_id_task_type_mh,
                                               g_id_task_type_pl,
                                               g_id_task_type_sh,
                                               g_id_task_type_ca);
        
        ELSE
        
            IF l_alert_diag_flg_type = g_flg_type_m
            THEN
                -- ALERT_DIAGNOSIS.FLG_TYPE = 'M' requires THREE records in CONCEPT_TERM_TASK_TYPE, in order to provide
                -- access to diagnosis in the application areas: 1) Diagnosis, 2) Medical history and 3) Problems
                l_tab_id_task_type := table_number(g_id_task_type_dg, g_id_task_type_mh, g_id_task_type_pl);
            
            ELSIF l_alert_diag_flg_type = g_flg_type_s
            THEN
                -- ALERT_DIAGNOSIS.FLG_TYPE = 'S' requires ONE record, to provide access to Surgical History application area.
                l_tab_id_task_type := table_number(g_id_task_type_sh);
            
            ELSIF l_alert_diag_flg_type = g_flg_type_a
            THEN
                -- ALERT_DIAGNOSIS.FLG_TYPE = 'A' requires ONE record, to provide access to Congenital Anomalies application area.
                l_tab_id_task_type := table_number(g_id_task_type_ca);
            
            ELSE
                -- Not predicted  values will have the same behaviour as in FLG_TYPE = 'M', although this shouldn't happen.
                l_tab_id_task_type := table_number(g_id_task_type_dg, g_id_task_type_mh, g_id_task_type_pl);
            END IF;
        END IF;
    
        RETURN l_tab_id_task_type;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_empty_table;
    END get_id_task_type_list;

    /********************************************************************************************
    * Returns ID_CLINICAL_SERVICE
    *
    * @param i_id_dep_clin_serv        ID_DEP_CLIN_SERV                
    * 
    * @return                          Corresponding ID_CLINICAL_SERVICE
    *
    * @author                          José Brito
    * @version                         2.6
    * @since                           10-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_id_clinical_service(i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE) RETURN NUMBER IS
        l_id_clinical_service clinical_service.id_clinical_service%TYPE;
    BEGIN
    
        IF i_id_dep_clin_serv IS NULL
        THEN
            l_id_clinical_service := g_id_clinical_service_default;
        ELSE
            SELECT dcs.id_clinical_service
              INTO l_id_clinical_service
              FROM dep_clin_serv dcs
             WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
        END IF;
    
        RETURN l_id_clinical_service;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN g_id_clinical_service_default;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_id_clinical_service;

    /********************************************************************************************
    * Updates sequence of CONCEPT_TERM in order to allow missing records of ALERT_DIAGNOSIS.
    *
    * @param i_id_alert_diagnosis      Max. value of ID_ALERT_DIAGNOSIS
    *
    * @return                          Current value of SEQ_CONCEPT_TERM after updating sequence
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           16-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION update_seq_concept_term(i_id_alert_diagnosis IN NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.update_seq_concept_term(i_id_alert_diagnosis => i_id_alert_diagnosis);
    END update_seq_concept_term;

    /********************************************************************************************
    * Get ID_TERMINOLOGY
    *
    * @param i_flg_type                DIAGNOSIS.FLG_TYPE
    * 
    * @return                          ID_TERMINOLOGY
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_id_terminology(i_flg_type IN diagnosis.flg_type%TYPE) RETURN NUMBER IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.get_id_terminology(i_flg_type => i_flg_type);
    END get_id_terminology;

    /********************************************************************************************
    * Get list of applicable ID_CONCEPT_TYPE for the current diagnosis
    *
    * @param i_flg_subtype             Diagnosis subtype. DIAGNOSIS.FLG_SUBTYPE IN ('S', 'I', 'N', 'T', 'A', 'O')
    * @param i_flg_other               Free text diagnosis. DIAGNOSIS.FLG_OTHER IN ('Y', 'N')
    * 
    * @return                          List of ID_CONCEPT_TYPE
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_id_concept_type_list
    (
        i_flg_subtype IN diagnosis.flg_subtype%TYPE,
        i_flg_other   IN diagnosis.flg_other%TYPE
    ) RETURN table_number IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.get_id_concept_type_list(i_flg_subtype => i_flg_subtype,
                                                                              i_flg_other   => i_flg_other);
    END get_id_concept_type_list;

    /********************************************************************************************
    * Get value of FLG_MAIN_CONCEPT_TYPE
    *
    * @param i_id_concept_type         Concept type ID
    * 
    * @return                          FLG_MAIN_CONCEPT_TYPE
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           27-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_flg_main_concept_type(i_id_concept_type IN concept_type.id_concept_type%TYPE) RETURN VARCHAR2 IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.get_flg_main_concept_type(i_id_concept_type => i_id_concept_type);
    END get_flg_main_concept_type;

    /********************************************************************************************
    * Get ID_TERMINOLOGY_VERSION
    *
    * @param i_id_terminology          Terminology ID                    
    * 
    * @return                          ID_TERMINOLOGY_VERSION
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_id_terminology_version(i_id_terminology IN r_terminology.id_terminology%TYPE) RETURN NUMBER IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.get_id_terminology_version(i_id_terminology => i_id_terminology);
    END get_id_terminology_version;

    /********************************************************************************************
    * Get terminology version row
    *
    * @param i_id_terminology          Terminology ID                    
    * 
    * @return                          Terminology version row
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           08-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_terminology_version_row(i_id_terminology IN terminology.id_terminology%TYPE)
        RETURN r_terminology_version%TYPE IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.get_terminology_version_row(i_id_terminology => i_id_terminology);
    END get_terminology_version_row;

    /********************************************************************************************
    * Get ID_CONCEPT_TERM_TYPE
    *
    * @param i_flg_icd9                (Y) Coded diagnosis (N) Uncoded/synonyms                    
    * 
    * @return                          ID_CONCEPT_TERM_TYPE
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           09-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_id_concept_term_type(i_flg_icd9 IN alert_diagnosis.flg_icd9%TYPE) RETURN NUMBER IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.get_id_concept_term_type(i_flg_icd9 => i_flg_icd9);
    END get_id_concept_term_type;

    /********************************************************************************************
    * Get ID_CONCEPT_RELATION
    * 
    * @return                          Next value of ID_CONCEPT_RELATION
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           10-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_id_concept_relation RETURN NUMBER IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.get_id_concept_relation;
    END get_id_concept_relation;

    /********************************************************************************************
    * Get ID_CONCEPT_REL_TYPE
    * 
    * @return                          ID_CONCEPT_REL_TYPE
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           10-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_id_concept_rel_type RETURN NUMBER IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.get_id_concept_rel_type;
    END get_id_concept_rel_type;

    /********************************************************************************************
    * Get ID_TERMINOLOGY_MKT
    *
    * @param i_id_terminology_version  ID_TERMINOLOGY_VERSION                    
    * 
    * @return                          ID_TERMINOLOGY_MKT
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           13-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_id_terminology_mkt(i_id_terminology_version IN r_terminology_version.id_terminology_version%TYPE)
        RETURN NUMBER IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.get_id_terminology_mkt(i_id_terminology_version => i_id_terminology_version);
    END get_id_terminology_mkt;

    /********************************************************************************************
    * Get ID_CONCEPT_VERSION
    *
    * @param i_id_concept_version      ID_CONCEPT_VERSION                    
    * 
    * @return                          ID_TERMINOLOGY_MKT
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           13-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_id_termin_mkt_by_concept(i_id_concept_version IN r_concept_version.id_concept_version%TYPE) RETURN NUMBER IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.get_id_termin_mkt_by_concept(i_id_concept_version => i_id_concept_version);
    END get_id_termin_mkt_by_concept;

    /********************************************************************************************
    * Get the next value for the ID_CONCEPT_TERM sequence
    * 
    * @return                          ID_CONCEPT_TERM
    *
    * @author                          José Brito
    * @version                         2.6.2
    * @since                           16-Feb-2012
    *
    **********************************************************************************************/
    FUNCTION get_id_concept_term RETURN r_concept_term.id_concept_term%TYPE IS
    BEGIN
        RETURN alert_core_func.pk_api_diagnosis_func.get_id_concept_term;
    END get_id_concept_term;

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
    ) RETURN BOOLEAN IS
    
        ------------
        -- Variables
        ------------
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'MIG_ALERT_DIAGNOSIS';
    
        -- Exceptions
        err_sequence     EXCEPTION;
        err_concept_term EXCEPTION;
        err_def_record   EXCEPTION;
    
        -- Aux / Debug
        l_output_strings NUMBER(6) := i_output; -- [1] Output ON  [Other value] Output OFF
    
        l_max_id_alert_diagnosis alert_diagnosis.id_alert_diagnosis%TYPE;
        l_new_id_concept_term    r_concept_term.id_concept_term%TYPE;
    
        l_alert_diagnosis_flg_type alert_diagnosis.flg_type%TYPE;
    
        l_curr_id_diagnosis diagnosis.id_diagnosis%TYPE := NULL;
        l_prev_id_diagnosis diagnosis.id_diagnosis%TYPE := NULL;
    
        l_id_concept_type_list  table_number;
        l_id_task_type_list     table_number;
        l_id_task_type_list_cfg table_number;
    
        l_id_terminology         r_terminology.id_terminology%TYPE;
        l_terminology_version    r_terminology_version%TYPE;
        l_id_terminology_version r_terminology_version.id_terminology_version%TYPE;
        l_id_concept_rel_type    r_concept_rel_type.id_concept_rel_type%TYPE;
    
        l_exists_concept_rel BOOLEAN;
    
        l_count NUMBER(6);
    
        l_is_valid_child VARCHAR2(1 CHAR);
    
        ------------
        -- Diagnosis tree cursor
        ------------
        CURSOR c_diag_tree IS -- ALERT_DIAGNOSIS records
            SELECT d.tree_level,
                   -- DIAGNOSIS
                   d.id_diagnosis,
                   d.id_diagnosis_parent,
                   d.code_diagnosis,
                   d.code_icd,
                   d.flg_select,
                   d.flg_job,
                   d.flg_available       diag_flg_available,
                   d.flg_type            diag_flg_type,
                   d.flg_other,
                   d.gender              diag_gender,
                   d.age_min             diag_age_min,
                   d.age_max             diag_age_max,
                   d.mdm_coding,
                   d.flg_family,
                   d.flg_pos_birth,
                   d.flg_subtype,
                   d.id_content          diag_id_content,
                   -- ALERT_DIAGNOSIS
                   ad.id_alert_diagnosis,
                   ad.code_alert_diagnosis,
                   ad.flg_type             alert_diag_flg_type,
                   ad.flg_icd9,
                   ad.flg_available        alert_diag_flg_available,
                   ad.gender               alert_diag_gender,
                   ad.age_min              alert_diag_age_min,
                   ad.age_max              alert_diag_age_max,
                   ad.id_content           alert_diag_id_content
              FROM (SELECT LEVEL tree_level,
                           d1.id_diagnosis,
                           d1.id_diagnosis_parent,
                           d1.code_diagnosis,
                           d1.code_icd,
                           d1.flg_select,
                           d1.flg_job,
                           d1.flg_available,
                           d1.flg_type,
                           d1.flg_other,
                           d1.gender,
                           d1.age_min,
                           d1.age_max,
                           d1.mdm_coding,
                           d1.flg_family,
                           d1.flg_pos_birth,
                           d1.flg_subtype,
                           d1.id_content
                      FROM diagnosis d1
                     START WITH d1.id_diagnosis_parent IS NULL
                    CONNECT BY PRIOR d1.id_diagnosis = d1.id_diagnosis_parent) d
            -- Using LEFT JOIN also returns ID_DIAGNOSIS records without a matching record in ALERT_DIAGNOSIS.
              LEFT JOIN alert_diagnosis ad
                ON ad.id_diagnosis = d.id_diagnosis
            UNION ALL
            -- ALERT_DIAGNOSIS records with ID_DIAGNOSIS = NULL
            SELECT -999 tree_level,
                   -- DIAGNOSIS
                   -2 id_diagnosis,
                   NULL id_diagnosis_parent,
                   NULL code_diagnosis,
                   'DUMMY' code_icd,
                   NULL flg_select,
                   NULL flg_job,
                   'N' diag_flg_available,
                   'DUMMY' diag_flg_type,
                   NULL flg_other,
                   NULL diag_gender,
                   NULL diag_age_min,
                   NULL diag_age_max,
                   NULL mdm_coding,
                   NULL flg_family,
                   NULL flg_pos_birth,
                   NULL flg_subtype,
                   NULL diag_id_content,
                   -- ALERT_DIAGNOSIS
                   ad.id_alert_diagnosis,
                   ad.code_alert_diagnosis,
                   ad.flg_type             alert_diag_flg_type,
                   ad.flg_icd9,
                   ad.flg_available        alert_diag_flg_available,
                   ad.gender               alert_diag_gender,
                   ad.age_min              alert_diag_age_min,
                   ad.age_max              alert_diag_age_max,
                   ad.id_content           alert_diag_id_content
              FROM alert_diagnosis ad
             WHERE ad.id_diagnosis IS NULL
             ORDER BY tree_level, id_diagnosis, id_diagnosis_parent, id_alert_diagnosis;
    
        -- DIAGNOSIS_DEP_CLIN_SERV cursors
        CURSOR c_diag_dep_clin_serv(i_id_diagnosis diagnosis.id_diagnosis%TYPE) IS
            SELECT d.id_diagnosis, d.id_institution, d.id_software
              FROM diagnosis_dep_clin_serv d
             WHERE d.id_diagnosis = i_id_diagnosis
             GROUP BY d.id_diagnosis, d.id_institution, d.id_software
             ORDER BY d.id_diagnosis;
    
        CURSOR c_diag_dep_clin_serv_terms(i_id_diagnosis diagnosis.id_diagnosis%TYPE) IS
            SELECT d.id_diagnosis,
                   d.id_alert_diagnosis,
                   d.id_institution,
                   d.id_software,
                   d.id_dep_clin_serv,
                   d.id_professional,
                   d.flg_type,
                   d.rank
              FROM diagnosis_dep_clin_serv d
             WHERE d.id_diagnosis = i_id_diagnosis
             GROUP BY d.id_diagnosis,
                      d.id_alert_diagnosis,
                      d.id_institution,
                      d.id_software,
                      d.id_dep_clin_serv,
                      d.id_professional,
                      d.flg_type,
                      d.rank
             ORDER BY id_diagnosis, id_alert_diagnosis NULLS LAST;
    
        -- ALERT_DEFAULT data
        CURSOR c_diag_alert_default(i_id_diagnosis diagnosis.id_diagnosis%TYPE) IS
            SELECT dcs.id_diagnosis,
                   dmv.id_market,
                   dmv.version,
                   dcs.id_diagnosis_clin_serv,
                   dcs.id_clinical_service,
                   dcs.flg_type,
                   dcs.id_software,
                   dcs.content_date_tstz,
                   dcs.id_alert_diagnosis
              FROM alert_default.diagnosis_clin_serv dcs
              JOIN alert_default.diagnosis_mrk_vrs dmv
                ON dmv.id_diagnosis = dcs.id_diagnosis
             WHERE dcs.id_diagnosis = i_id_diagnosis
             ORDER BY dcs.id_diagnosis, dcs.id_alert_diagnosis;
    
        -- SYS_CONFIG cursor. Migrate configurations to MSI_TERMIN_VERSION.
        CURSOR c_sys_config IS
            SELECT s.id_sys_config,
                   s.value,
                   s.desc_sys_config,
                   s.id_institution,
                   s.id_software,
                   s.fill_type,
                   s.flg_schema,
                   s.id_market
              FROM sys_config s
             WHERE s.id_sys_config = 'DIAGNOSIS_TYPE';
    
    BEGIN
        -- When an ID_DIAGNOSIS is not found in ALERT_DIAGNOSIS, a new record must be created in CONCEPT_TERM and related tables.
        -- Get the maximum ID in ALERT_DIAGNOSIS, so there isn't conflicts when generating the new ID_CONCEPT_TERM values.
        SELECT MAX(ad.id_alert_diagnosis)
          INTO l_max_id_alert_diagnosis
          FROM alert_diagnosis ad;
    
        -- Update sequence value
        l_new_id_concept_term := update_seq_concept_term(l_max_id_alert_diagnosis);
    
        -- Check for conflicts
        SELECT COUNT(*)
          INTO l_count
          FROM alert_diagnosis ad
         WHERE ad.id_alert_diagnosis > l_new_id_concept_term;
    
        IF l_count > 0
        THEN
            g_error := '>> ERROR UPDATING SEQ_CONCEPT_TERM [l_count = ' || l_count || ' / l_max_id_alert_diagnosis = ' ||
                       l_max_id_alert_diagnosis || ' l_new_id_concept_term = ' || l_new_id_concept_term || ']';
            RAISE err_sequence;
        END IF;
    
        --------------------------------------------------------------------
        -- A) Migration of SYS_CONFIG "DIAGNOSIS_TYPE" to MSI_TERMIN_VERSION
        --------------------------------------------------------------------
        FOR k IN c_sys_config
        LOOP
            l_id_terminology      := get_id_terminology(k.value);
            l_terminology_version := get_terminology_version_row(l_id_terminology);
        
            l_id_task_type_list_cfg := get_id_task_type_list(i_flg_type       => NULL, -- Not needed
                                                             i_flg_sys_config => g_yes);
        
            g_error := '>> [MSI_TERMIN_VERSION] Value=' || k.value || '/Inst=' || k.id_institution || '/Soft=' ||
                       k.id_software;
            IF l_id_task_type_list_cfg.exists(1)
            THEN
                FOR i IN l_id_task_type_list_cfg.first .. l_id_task_type_list_cfg.last
                LOOP
                    -- MSI_TERMIN_VERSION
                    r_msi_termin_version.id_terminology     := l_id_terminology;
                    r_msi_termin_version.version            := l_terminology_version.version;
                    r_msi_termin_version.id_terminology_mkt := l_terminology_version.id_terminology_mkt;
                    r_msi_termin_version.id_language        := l_terminology_version.id_language;
                    r_msi_termin_version.id_inst_owner      := g_inst_owner;
                    r_msi_termin_version.id_market          := k.id_market;
                    r_msi_termin_version.id_institution     := k.id_institution;
                    r_msi_termin_version.id_software        := k.id_software;
                    r_msi_termin_version.id_task_type       := l_id_task_type_list_cfg(i);
                    r_msi_termin_version.flg_active         := g_yes;
                
                    ins_msi_termin_version(r_msi_termin_version);
                END LOOP;
            END IF;
        END LOOP;
    
        --------------------------------------------------------------------
        -- B) Migration of DIAGNOSIS/ALERT_DIAGNOSIS parent & child records
        --------------------------------------------------------------------
        FOR r IN c_diag_tree
        LOOP
            l_curr_id_diagnosis := r.id_diagnosis;
        
            -- Each ID_DIAGNOSIS must have only ONE record in these tables
            IF l_curr_id_diagnosis <> nvl(l_prev_id_diagnosis, -999)
            THEN
                -- CONCEPT
                r_concept.id_concept       := l_curr_id_diagnosis;
                r_concept.id_inst_owner    := g_inst_owner;
                r_concept.id_terminology   := get_id_terminology(r.diag_flg_type);
                r_concept.code             := r.code_icd;
                r_concept.flg_transparency := '';
            
                g_error := '>> [CONCEPT] ID_DIAGNOSIS = ' || l_curr_id_diagnosis;
                ins_concept(r_concept);
            
                -- CONCEPT_TYPE_REL
                l_id_concept_type_list := get_id_concept_type_list(r.flg_subtype, r.flg_other);
            
                IF l_id_concept_type_list.exists(1)
                THEN
                    FOR i IN l_id_concept_type_list.first .. l_id_concept_type_list.last
                    LOOP
                        r_concept_type_rel.id_terminology        := r_concept.id_terminology;
                        r_concept_type_rel.id_concept_type       := nvl(l_id_concept_type_list(i), -999);
                        r_concept_type_rel.id_concept            := l_curr_id_diagnosis;
                        r_concept_type_rel.id_concept_inst_owner := g_inst_owner;
                        r_concept_type_rel.id_inst_owner         := g_inst_owner;
                        r_concept_type_rel.flg_main_concept_type := get_flg_main_concept_type(l_id_concept_type_list(i));
                    
                        g_error := '>> [CONCEPT_TYPE_REL] ID_DIAGNOSIS = ' || l_curr_id_diagnosis;
                        ins_concept_type_rel(r_concept_type_rel);
                    END LOOP;
                END IF;
            
                -- CONCEPT_VERSION
                l_id_terminology_version := get_id_terminology_version(r_concept.id_terminology);
            
                r_concept_version.id_concept_version     := l_curr_id_diagnosis;
                r_concept_version.id_inst_owner          := g_inst_owner;
                r_concept_version.id_terminology_version := l_id_terminology_version;
                r_concept_version.id_concept             := l_curr_id_diagnosis;
                r_concept_version.id_concept_inst_owner  := g_inst_owner;
            
                g_error := '>> [CONCEPT_VERSION] ID_DIAGNOSIS = ' || l_curr_id_diagnosis;
                ins_concept_version(r_concept_version);
            
                -- CONCEPT_RELATION
                IF r.id_diagnosis_parent IS NOT NULL
                THEN
                    -- Validate diagnosis standard of the child record, which must be the same as the parent.
                    SELECT decode(d.flg_type, r.diag_flg_type, g_yes, g_no)
                      INTO l_is_valid_child
                      FROM diagnosis d
                     WHERE d.id_diagnosis = r.id_diagnosis_parent;
                
                    -- Skip insert in CONCEPT_RELATION if child record follows a different standard than the parent record.
                    IF l_is_valid_child = g_yes
                    THEN
                        l_id_concept_rel_type := get_id_concept_rel_type;
                    
                        r_concept_relation.id_concept_relation    := get_id_concept_relation;
                        r_concept_relation.id_inst_owner          := g_inst_owner;
                        r_concept_relation.id_term_vers_start1    := l_id_terminology_version;
                        r_concept_relation.id_term_vers_end1      := NULL;
                        r_concept_relation.id_concept1            := l_curr_id_diagnosis;
                        r_concept_relation.id_concept_inst_owner1 := g_inst_owner;
                        r_concept_relation.id_term_vers_start2    := l_id_terminology_version;
                        r_concept_relation.id_term_vers_end2      := NULL;
                        r_concept_relation.id_concept2            := r.id_diagnosis_parent;
                        r_concept_relation.id_concept_inst_owner2 := g_inst_owner;
                        r_concept_relation.id_concept_rel_type    := l_id_concept_rel_type;
                        r_concept_relation.flg_available          := r.diag_flg_available;
                    
                        g_error := '>> [CONCEPT_RELATION] ID_DIAGNOSIS = ' || l_curr_id_diagnosis;
                        ins_concept_relation(r_concept_relation);
                    
                        l_exists_concept_rel := TRUE;
                    ELSE
                        l_exists_concept_rel := FALSE;
                    END IF;
                ELSE
                    l_exists_concept_rel := FALSE;
                END IF;
            
                FOR c IN c_diag_dep_clin_serv(l_curr_id_diagnosis)
                LOOP
                    IF c.id_institution IS NOT NULL -- Ignore records with NULL ID_INSTITUTION
                    THEN
                        -- msi_cncpt_vers_attrib
                        r_msi_cncpt_vers_attrib.id_terminology_version := l_id_terminology_version;
                        r_msi_cncpt_vers_attrib.id_concept             := l_curr_id_diagnosis;
                        r_msi_cncpt_vers_attrib.id_concept_inst_owner  := g_inst_owner;
                        r_msi_cncpt_vers_attrib.id_inst_owner          := g_inst_owner;
                        r_msi_cncpt_vers_attrib.id_institution         := c.id_institution;
                        r_msi_cncpt_vers_attrib.id_software            := c.id_software;
                        r_msi_cncpt_vers_attrib.gender                 := r.diag_gender;
                        r_msi_cncpt_vers_attrib.age_min                := r.diag_age_min;
                        r_msi_cncpt_vers_attrib.age_max                := r.diag_age_max;
                        r_msi_cncpt_vers_attrib.txt_attribute_01       := r.flg_family;
                        r_msi_cncpt_vers_attrib.txt_attribute_02       := r.flg_job;
                        r_msi_cncpt_vers_attrib.txt_attribute_03       := r.flg_pos_birth;
                        r_msi_cncpt_vers_attrib.txt_attribute_04       := r.flg_select;
                        r_msi_cncpt_vers_attrib.num_attribute_01       := r.mdm_coding;
                        r_msi_cncpt_vers_attrib.flg_active             := r.diag_flg_available;
                    
                        IF r_msi_cncpt_vers_attrib.id_institution = g_inst_zero
                           AND r_msi_cncpt_vers_attrib.flg_active = g_no
                        THEN
                            -- Records originated from ALERT Default -> replace value of FLG_ACTIVE with 'Y'. 
                            r_msi_cncpt_vers_attrib.flg_active := g_yes;
                        END IF;
                    
                        g_error := '>> [msi_cncpt_vers_attrib] ID_DIAGNOSIS = ' || l_curr_id_diagnosis;
                        ins_msi_cncpt_vers_attrib(r_msi_cncpt_vers_attrib);
                    
                        -- MSI_CONCEPT_RELATION
                        IF l_exists_concept_rel
                        THEN
                            r_msi_concept_relation.id_term_vers_start1    := l_id_terminology_version;
                            r_msi_concept_relation.id_concept1            := l_curr_id_diagnosis;
                            r_msi_concept_relation.id_concept_inst_owner1 := g_inst_owner;
                            r_msi_concept_relation.id_term_vers_start2    := l_id_terminology_version;
                            r_msi_concept_relation.id_concept2            := r.id_diagnosis_parent;
                            r_msi_concept_relation.id_concept_inst_owner2 := g_inst_owner;
                            r_msi_concept_relation.id_concept_rel_type    := r_concept_relation.id_concept_rel_type;
                            r_msi_concept_relation.id_inst_owner          := g_inst_owner;
                            r_msi_concept_relation.id_institution         := nvl(c.id_institution, g_inst_zero);
                            r_msi_concept_relation.id_software            := c.id_software;
                            r_msi_concept_relation.rank                   := g_rank_zero;
                            r_msi_concept_relation.flg_default            := g_yes;
                            r_msi_concept_relation.flg_active             := r.diag_flg_available;
                        
                            BEGIN
                                g_error := '>> [MSI_CONCEPT_RELATION] ID_DIAGNOSIS = ' || l_curr_id_diagnosis;
                                ins_msi_concept_relation(r_msi_concept_relation);
                            EXCEPTION
                                WHEN OTHERS THEN
                                    -- Ignore error when parent configurations are not found.
                                    NULL;
                            END;
                        END IF;
                    END IF;
                END LOOP;
            
                -- Collect ALERT_DEFAULT data
                FOR f IN c_diag_alert_default(l_curr_id_diagnosis)
                LOOP
                    -- def_cncpt_vers_attrib
                    r_def_cncpt_vers_attrib.internal_name          := f.version;
                    r_def_cncpt_vers_attrib.id_market              := f.id_market;
                    r_def_cncpt_vers_attrib.id_software            := f.id_software;
                    r_def_cncpt_vers_attrib.id_terminology_version := l_id_terminology_version;
                    r_def_cncpt_vers_attrib.id_concept             := l_curr_id_diagnosis;
                    r_def_cncpt_vers_attrib.id_concept_inst_owner  := g_inst_owner;
                    r_def_cncpt_vers_attrib.gender                 := r.diag_gender;
                    r_def_cncpt_vers_attrib.age_min                := r.diag_age_min;
                    r_def_cncpt_vers_attrib.age_max                := r.diag_age_max;
                    r_def_cncpt_vers_attrib.txt_attribute_01       := r.flg_family;
                    r_def_cncpt_vers_attrib.txt_attribute_02       := r.flg_job;
                    r_def_cncpt_vers_attrib.txt_attribute_03       := r.flg_pos_birth;
                    r_def_cncpt_vers_attrib.txt_attribute_04       := r.flg_select;
                    r_def_cncpt_vers_attrib.num_attribute_01       := r.mdm_coding;
                    r_def_cncpt_vers_attrib.flg_active             := r.diag_flg_available;
                
                    BEGIN
                        g_error := '>> [def_cncpt_vers_attrib] ID_DIAGNOSIS = ' || l_curr_id_diagnosis;
                        ins_def_cncpt_vers_attrib(r_def_cncpt_vers_attrib);
                    EXCEPTION
                        WHEN dup_val_on_index THEN
                            -- Ignore error when duplicated records are found.
                            NULL;
                        WHEN OTHERS THEN
                            g_error := '> ERROR def_cncpt_vers_attrib: ' || r.id_diagnosis || ' / ' ||
                                       f.id_diagnosis_clin_serv;
                            RAISE err_def_record;
                    END;
                
                    IF l_exists_concept_rel
                    THEN
                        -- DEF_CONCEPT_RELATION
                        r_def_concept_relation.internal_name          := f.version;
                        r_def_concept_relation.id_market              := f.id_market;
                        r_def_concept_relation.id_software            := f.id_software;
                        r_def_concept_relation.id_term_vers_start1    := l_id_terminology_version;
                        r_def_concept_relation.id_concept1            := l_curr_id_diagnosis;
                        r_def_concept_relation.id_concept_inst_owner1 := g_inst_owner;
                        r_def_concept_relation.id_term_vers_start2    := l_id_terminology_version;
                        r_def_concept_relation.id_concept2            := r.id_diagnosis_parent;
                        r_def_concept_relation.id_concept_inst_owner2 := g_inst_owner;
                        r_def_concept_relation.id_concept_rel_type    := l_id_concept_rel_type;
                        r_def_concept_relation.rank                   := g_rank_zero;
                        r_def_concept_relation.flg_default            := g_yes;
                        r_def_concept_relation.flg_active             := r.diag_flg_available;
                    
                        BEGIN
                            g_error := '>> [DEF_CONCEPT_RELATION] ID_DIAGNOSIS = ' || l_curr_id_diagnosis;
                            ins_def_concept_relation(r_def_concept_relation);
                        EXCEPTION
                            WHEN OTHERS THEN
                                -- Ignore error when parent configurations are not found.
                                NULL;
                        END;
                    END IF;
                END LOOP;
            END IF;
        
            -- Some ID_DIAGNOSIS do not exist in ALERT_DIAGNOSIS. Missing data must be generated from DIAGNOSIS or child records.
            IF r.id_alert_diagnosis IS NULL
            THEN
                -- Generate a new ID_CONCEPT_TERM 
                g_error              := '>> [GET_ID_CONCEPT_TERM] ID_DIAGNOSIS = ' || l_curr_id_diagnosis;
                r.id_alert_diagnosis := get_id_concept_term;
                -- Assume FLG_ICD9 = 'Y'
                r.flg_icd9 := g_yes;
                -- FLG_AVAILABLE will be the same as in DIAGNOSIS
                r.alert_diag_flg_available := r.diag_flg_available;
                -- Label translation will be the same as in DIAGNOSIS (preferred term)
                r.code_alert_diagnosis := r.code_diagnosis;
            
                -- Get ALERT_DIAGNOSIS.FLG_TYPE value from a child record
                g_error := '>> [GET ALERT_DIAGNOSIS.FLG_TYPE] ID_DIAGNOSIS = ' || l_curr_id_diagnosis;
                BEGIN
                    SELECT ad.flg_type
                      INTO l_alert_diagnosis_flg_type
                      FROM diagnosis d
                      JOIN alert_diagnosis ad
                        ON ad.id_diagnosis = d.id_diagnosis
                     WHERE d.id_diagnosis_parent = l_curr_id_diagnosis
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        -- Assume FLG_TYPE = 'M' when no child records are found
                        l_alert_diagnosis_flg_type := g_flg_type_m;
                END;
            
                r.alert_diag_flg_type := l_alert_diagnosis_flg_type;
            END IF;
        
            -- CONCEPT_TERM
            r_concept_term.id_concept_term         := r.id_alert_diagnosis;
            r_concept_term.id_inst_owner           := g_inst_owner;
            r_concept_term.id_concept_vers_start   := l_curr_id_diagnosis;
            r_concept_term.id_concept_vers_end     := l_curr_id_diagnosis;
            r_concept_term.id_cncpt_vrs_inst_owner := g_inst_owner;
            r_concept_term.id_concept_term_type    := get_id_concept_term_type(r.flg_icd9);
            r_concept_term.flg_available           := r.alert_diag_flg_available;
            r_concept_term.flg_client              := g_no;
        
            g_error := '>> [CONCEPT_TERM] ID_ALERT_DIAGNOSIS = ' || r.id_alert_diagnosis;
            ins_concept_term(r_concept_term);
        
            -- CONCEPT_TERM_TASK_TYPE
            g_error             := '>> [GET_ID_TASK_TYPE_LIST] ID_ALERT_DIAGNOSIS = ' || r.id_alert_diagnosis;
            l_id_task_type_list := get_id_task_type_list(r.alert_diag_flg_type);
        
            IF l_id_task_type_list.exists(1)
            THEN
                FOR i IN l_id_task_type_list.first .. l_id_task_type_list.last
                LOOP
                    r_concept_term_task_type.id_concept_term         := r.id_alert_diagnosis;
                    r_concept_term_task_type.id_cncpt_trm_inst_owner := g_inst_owner;
                    r_concept_term_task_type.id_inst_owner           := g_inst_owner;
                    r_concept_term_task_type.id_task_type            := l_id_task_type_list(i);
                    r_concept_term_task_type.code_concept_term       := r.code_alert_diagnosis;
                
                    g_error := '>> [CONCEPT_TERM_TASK_TYPE] ID_ALERT_DIAGNOSIS = ' || r.id_alert_diagnosis;
                    ins_concept_term_task_type(r_concept_term_task_type);
                END LOOP;
            END IF;
        
            FOR d IN c_diag_dep_clin_serv_terms(l_curr_id_diagnosis)
            LOOP
                IF nvl(d.id_alert_diagnosis, -111) = r.id_alert_diagnosis
                   OR d.id_alert_diagnosis IS NULL
                THEN
                    -- MSI_CONCEPT_TERM 
                    r_msi_concept_term.id_concept_term         := r.id_alert_diagnosis;
                    r_msi_concept_term.id_cncpt_trm_inst_owner := g_inst_owner;
                    r_msi_concept_term.id_concept_version      := l_curr_id_diagnosis;
                    r_msi_concept_term.id_cncpt_vrs_inst_owner := g_inst_owner;
                    r_msi_concept_term.id_inst_owner           := g_inst_owner;
                    r_msi_concept_term.id_institution          := nvl(d.id_institution, -1);
                    r_msi_concept_term.id_software             := nvl(d.id_software, -1);
                    r_msi_concept_term.id_dep_clin_serv        := nvl(d.id_dep_clin_serv, g_id_dep_clin_serv_default);
                    r_msi_concept_term.id_professional         := nvl(d.id_professional, -1);
                    r_msi_concept_term.rank                    := d.rank;
                    r_msi_concept_term.flg_type                := d.flg_type;
                    r_msi_concept_term.flg_active              := r.alert_diag_flg_available;
                    r_msi_concept_term.gender                  := r.alert_diag_gender;
                    r_msi_concept_term.age_min                 := r.alert_diag_age_min;
                    r_msi_concept_term.age_max                 := r.alert_diag_age_max;
                
                    BEGIN
                        g_error := '>> [MSI_CONCEPT_TERM] ID_ALERT_DIAGNOSIS = ' || r.id_alert_diagnosis;
                        ins_msi_concept_term(r_msi_concept_term);
                    EXCEPTION
                        WHEN dup_val_on_index THEN
                            -- Ignore duplicated configurations
                            NULL;
                        WHEN OTHERS THEN
                            g_error := '> ERROR: ' || r.id_diagnosis_parent || ' / ' || r.id_alert_diagnosis || ' / ' ||
                                       r_msi_concept_term.id_dep_clin_serv;
                            RAISE err_concept_term;
                    END;
                END IF;
            END LOOP;
        
            -- Collect ALERT_DEFAULT data
            FOR f IN c_diag_alert_default(l_curr_id_diagnosis)
            LOOP
                IF nvl(f.id_alert_diagnosis, -111) = r.id_alert_diagnosis
                   OR f.id_alert_diagnosis IS NULL
                THEN
                    -- DEF_CONCEPT_TERM 
                    r_def_concept_term.internal_name           := f.version;
                    r_def_concept_term.id_market               := f.id_market;
                    r_def_concept_term.id_software             := f.id_software;
                    r_def_concept_term.id_terminology_version  := l_id_terminology_version;
                    r_def_concept_term.id_clinical_service     := nvl(f.id_clinical_service,
                                                                      g_id_clinical_service_default);
                    r_def_concept_term.id_concept_term         := r.id_alert_diagnosis;
                    r_def_concept_term.id_cncpt_trm_inst_owner := g_inst_owner;
                    r_def_concept_term.id_concept_version      := l_curr_id_diagnosis;
                    r_def_concept_term.id_cncpt_vrs_inst_owner := g_inst_owner;
                    r_def_concept_term.gender                  := r.alert_diag_gender;
                    r_def_concept_term.age_min                 := r.alert_diag_age_min;
                    r_def_concept_term.age_max                 := r.alert_diag_age_max;
                    r_def_concept_term.rank                    := g_rank_zero;
                    r_def_concept_term.flg_type                := f.flg_type;
                    r_def_concept_term.flg_active              := r.alert_diag_flg_available;
                
                    BEGIN
                        g_error := '>> [DEF_CONCEPT_TERM] ID_ALERT_DIAGNOSIS = ' || r.id_alert_diagnosis;
                        ins_def_concept_term(r_def_concept_term);
                    EXCEPTION
                        WHEN dup_val_on_index THEN
                            -- Ignore duplicated configurations
                            NULL;
                        WHEN OTHERS THEN
                            g_error := '> ERROR DEF_CONCEPT_TERM: ' || r.id_diagnosis || ' / ' ||
                                       f.id_diagnosis_clin_serv;
                            RAISE err_def_record;
                    END;
                END IF;
            END LOOP;
        
            -- Set history. Stops the same ID_DIAGNOSIS from being processed again in the next iteration.
            l_prev_id_diagnosis := l_curr_id_diagnosis;
        
            -- Output control string   -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
            int_proc_output_record(r.tree_level, r.id_diagnosis, l_output_strings);
            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
        
        END LOOP;
    
        IF i_commit = 1
        THEN
            COMMIT;
        END IF;
    
        dbms_output.put_line('> END diagnosis migration.');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_def_record THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MIG_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            IF i_commit = 1
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
        WHEN err_concept_term THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MIG_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            IF i_commit = 1
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
        WHEN err_sequence THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MIG_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            IF i_commit = 1
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MIG_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            IF i_commit = 1
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MIG_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            IF i_commit = 1
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
    END mig_alert_diagnosis;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'MIG_ALERT_DIAGNOSIS';
    
		    --THIS CODE IS DEPRECATED AND IS NOT USED.
/*        PROCEDURE ins_diagnosis_ea IS
            l_tab_diagnosis_ea pk_api_pfh_diagnosis_in.g_tbl_diagnosis_ea%TYPE;
        BEGIN
            pk_alertlog.log_debug('MSI_TERMIN_VERSION: GET_EA_DATA_BY_MTV (Y)', 'PK_MIG_DIAGNOSIS', l_func_name);
            l_tab_diagnosis_ea := pk_api_pfh_diagnosis_in.get_ea_data_for_migration(i_institution => i_institution);
        
            IF l_tab_diagnosis_ea.exists(1)
            THEN
                FOR i IN l_tab_diagnosis_ea.first .. l_tab_diagnosis_ea.last
                LOOP
                    pk_ea_logic_diagnosis.ins_diagnosis_ea(l_tab_diagnosis_ea(i));
                END LOOP;
            END IF;
        END ins_diagnosis_ea;
    
        PROCEDURE ins_past_hist_in_diag_ea(i_inst IN institution.id_institution%TYPE) IS
            l_rec               pk_api_pfh_diagnosis_in.g_rec_diagnosis_ea%TYPE;
            l_tbl_terminologies table_number;
        
            CURSOR c_diag_data IS
                SELECT data.id_concept_version id_concept_version,
                       data.id_cncpt_vrs_inst_owner id_cncpt_vrs_inst_owner,
                       data.id_concept_term id_concept_term,
                       data.id_cncpt_trm_inst_owner id_cncpt_trm_inst_owner,
                       data.id_language,
                       alert_core_func.pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                            data.id_cncpt_trm_inst_owner,
                                                                                            alert_core_func.pk_api_diagnosis_func.g_id_task_type_dg,
                                                                                            data.id_mct_inst_owner) code_diagnosis,
                       alert_core_func.pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                            data.id_cncpt_trm_inst_owner,
                                                                                            alert_core_func.pk_api_diagnosis_func.g_id_task_type_mh,
                                                                                            data.id_mct_inst_owner) code_medical,
                       alert_core_func.pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                            data.id_cncpt_trm_inst_owner,
                                                                                            alert_core_func.pk_api_diagnosis_func.g_id_task_type_sh,
                                                                                            data.id_mct_inst_owner) code_surgical,
                       alert_core_func.pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                            data.id_cncpt_trm_inst_owner,
                                                                                            alert_core_func.pk_api_diagnosis_func.g_id_task_type_pl,
                                                                                            data.id_mct_inst_owner) code_problems,
                       alert_core_func.pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                            data.id_cncpt_trm_inst_owner,
                                                                                            alert_core_func.pk_api_diagnosis_func.g_id_task_type_ca,
                                                                                            data.id_mct_inst_owner) code_cong_anomalies,
                       data.code concept_code,
                       data.num_attribute_01 mdm_coding,
                       alert_core_func.pk_api_diagnosis_func.get_ea_flg_terminology(data.id_terminology) flg_terminology,
                       alert_core_func.pk_api_diagnosis_func.get_ea_flg_subtype(data.id_terminology,
                                                                                data.id_concept,
                                                                                data.id_concept_inst_owner,
                                                                                data.id_mct_inst_owner) flg_subtype,
                       alert_core_func.pk_api_diagnosis_func.get_ea_flg_diag_type(data.id_concept_term,
                                                                                  data.id_cncpt_trm_inst_owner,
                                                                                  data.id_mct_inst_owner) flg_diag_type,
                       data.txt_attribute_01 flg_family,
                       decode(data.internal_name,
                              alert_core_func.pk_api_diagnosis_func.g_ctt_int_name_pref,
                              alert_core_func.pk_api_diagnosis_func.g_flg_preferred,
                              alert_core_func.pk_api_diagnosis_func.g_ctt_int_name_syn,
                              alert_core_func.pk_api_diagnosis_func.g_flg_synonym,
                              alert_core_func.pk_api_diagnosis_func.g_ctt_int_name_rep,
                              alert_core_func.pk_api_diagnosis_func.g_flg_reportable,
                              alert_core_func.pk_api_diagnosis_func.g_empty_string) flg_icd9,
                       data.txt_attribute_02 flg_job,
                       data.flg_type flg_msi_concept_term,
                       alert_core_func.pk_api_diagnosis_func.get_ea_flg_other(data.id_terminology,
                                                                              data.id_concept,
                                                                              data.id_concept_inst_owner,
                                                                              data.id_mct_inst_owner) flg_other,
                       data.txt_attribute_03 flg_pos_birth,
                       data.txt_attribute_04 flg_select,
                       alert_core_func.pk_api_diagnosis_func.get_ea_concept_type_int_name(data.id_terminology,
                                                                                          data.id_concept,
                                                                                          data.id_concept_inst_owner,
                                                                                          data.id_mct_inst_owner) concept_type_int_name,
                       data.age_min age_min,
                       data.age_max age_max,
                       data.gender gender,
                       data.rank rank,
                       data.id_institution id_institution,
                       data.id_software id_software,
                       data.id_dep_clin_serv id_dep_clin_serv,
                       data.id_professional id_professional,
                       data.code_diagnosis_partial,
                       data.diagnosis_path,
                       pk_api_diagnosis_func.is_diagnosis(i_concept_version      => data.id_concept_version,
                                                          i_cncpt_vrs_inst_owner => data.id_cncpt_vrs_inst_owner) flg_is_diagnosis,
                       alert_core_func.pk_api_diagnosis_func.get_ea_code_concept_term_by_tt(data.id_concept_term,
                                                                                            data.id_cncpt_trm_inst_owner,
                                                                                            alert_core_func.pk_api_diagnosis_func.g_id_task_type_de,
                                                                                            data.id_mct_inst_owner) code_death_event
                  FROM (SELECT mct.id_concept_version,
                               mct.id_cncpt_vrs_inst_owner,
                               mct.id_concept_term,
                               mct.id_cncpt_trm_inst_owner,
                               tv.id_language,
                               c.id_concept,
                               c.code,
                               c.id_inst_owner id_concept_inst_owner,
                               t.id_terminology,
                               ctt.internal_name,
                               mcva.txt_attribute_01,
                               mcva.txt_attribute_02,
                               mcva.txt_attribute_03,
                               mcva.txt_attribute_04,
                               mcva.num_attribute_01,
                               nvl(mct.age_min, mcva.age_min) age_min,
                               nvl(mct.age_max, mcva.age_max) age_max,
                               nvl(mct.gender, mcva.gender) gender,
                               mct.id_inst_owner id_mct_inst_owner,
                               mct.flg_type,
                               mct.rank,
                               decode(mct.id_institution, -1, d.id_institution, mct.id_institution) id_institution,
                               mct.id_software,
                               mct.id_dep_clin_serv,
                               mct.id_professional,
                               -- Fields to check configured version
                               tv.id_terminology_version,
                               tv.version,
                               tv.id_terminology_mkt,
                               -- Check if concept is a "staging basis"
                               alert_core_func.pk_api_diagnosis_func.check_concept_type(alert_core_func.pk_api_diagnosis_func.g_id_concept_type_stag_basis,
                                                                                        t.id_terminology,
                                                                                        c.id_concept,
                                                                                        c.id_inst_owner,
                                                                                        mct.id_inst_owner) is_staging_basis,
                               (SELECT alert_core_func.pk_api_diagnosis_func.get_ea_partial_desc_code(ct.id_concept_term,
                                                                                                      mct.id_inst_owner)
                                  FROM dual) code_diagnosis_partial,
                               (SELECT alert_core_func.pk_api_diagnosis_func.get_concept_path(c.id_concept,
                                                                                              pk_api_diagnosis_func.g_id_concept_type_diag)
                                  FROM dual) diagnosis_path
                          FROM msi_concept_term mct -- [MSI_CONCEPT_TERM]
                        -- [CONCEPT_TERM]
                          JOIN concept_term ct
                            ON ct.id_concept_term = mct.id_concept_term
                           AND ct.id_inst_owner = mct.id_cncpt_trm_inst_owner
                           AND ct.id_concept_vers_start = mct.id_concept_version
                           AND ct.id_concept_vers_end = mct.id_concept_version
                           AND ct.id_cncpt_vrs_inst_owner = mct.id_cncpt_vrs_inst_owner
                           AND ct.flg_available = g_yes
                        -- [CONCEPT_TERM_TYPE]
                          JOIN concept_term_type ctt
                            ON ctt.id_concept_term_type = ct.id_concept_term_type
                           AND ctt.internal_name IN
                               (alert_core_func.pk_api_diagnosis_func.g_ctt_int_name_pref,
                                alert_core_func.pk_api_diagnosis_func.g_ctt_int_name_syn,
                                alert_core_func.pk_api_diagnosis_func.g_ctt_int_name_rep)
                        -- [CONCEPT_VERSION]
                          JOIN concept_version cv
                            ON cv.id_concept_version = ct.id_concept_vers_start
                           AND cv.id_concept_version = ct.id_concept_vers_end
                           AND cv.id_inst_owner = ct.id_cncpt_vrs_inst_owner
                        -- [TERMINOLOGY_VERSION]
                          JOIN terminology_version tv
                            ON tv.id_terminology_version = cv.id_terminology_version
                        -- [TERMINOLOGY]
                          JOIN terminology t
                            ON t.id_terminology = tv.id_terminology
                        -- [CONCEPT]
                          JOIN concept c
                            ON c.id_concept = cv.id_concept
                           AND c.id_inst_owner = cv.id_concept_inst_owner
                           AND c.id_terminology = t.id_terminology
                          LEFT JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = mct.id_dep_clin_serv
                          LEFT JOIN department d
                            ON d.id_department = dcs.id_department
                        -- [msi_cncpt_vers_attrib]
                          JOIN msi_cncpt_vers_attrib mcva
                            ON mcva.id_terminology_version = cv.id_terminology_version
                           AND mcva.id_concept = cv.id_concept
                           AND mcva.id_concept_inst_owner = cv.id_concept_inst_owner
                              -- Joins with MSI_CONCEPT_TERM required to match configurations
                           AND mcva.id_institution =
                               decode(mct.id_institution, -1, d.id_institution, mct.id_institution)
                           AND mcva.id_software = mct.id_software
                           AND mcva.flg_active = g_yes
                         WHERE mct.flg_type = pk_ea_logic_diagnosis.g_past_hist_diag_type
                           AND mct.flg_active = g_yes
                           AND mct.id_institution = pk_alert_constant.g_inst_all
                              -- The concept term must have a preferred term
                           AND EXISTS
                         (SELECT 1
                                  FROM concept_term ct1
                                  JOIN concept_term_type ctt1
                                    ON ctt1.id_concept_term_type = ct1.id_concept_term_type
                                 WHERE ct1.id_concept_vers_start = cv.id_concept_version
                                   AND ct1.id_concept_vers_end = cv.id_concept_version
                                   AND ct1.flg_available = g_yes
                                   AND ctt1.internal_name = alert_core_func.pk_api_diagnosis_func.g_ctt_int_name_pref)
                              -- Only insert diagnosis of terminologies in use
                           AND t.id_terminology IN (SELECT \*+opt_estimate (table a rows=10)*\
                                                     column_value id_terminology
                                                      FROM TABLE(l_tbl_terminologies) a)) data
                 WHERE
                -- Avoid rank = 0 for "staging basis" concept types
                 ((data.rank <> 0 AND data.is_staging_basis = 1) OR data.is_staging_basis = 0);
        BEGIN
            SELECT id_terminology BULK COLLECT
              INTO l_tbl_terminologies
              FROM TABLE(pk_ea_logic_diagnosis.tf_diag_ea_terminologies(i_institution => i_inst));
        
            FOR l_rec IN c_diag_data
            LOOP
                pk_ea_logic_diagnosis.ins_diagnosis_ea(l_rec);
            END LOOP;
        END ins_past_hist_in_diag_ea;*/
    BEGIN
		    --THIS CODE IS DEPRECATED AND IS NOT USED.
        /*IF i_institution IS NULL
           OR i_institution != pk_alert_constant.g_inst_all
        THEN
            ins_diagnosis_ea;
        
            ins_past_hist_in_diag_ea(i_inst => i_institution);
        ELSE
            --i_institution = 0
            ins_past_hist_in_diag_ea(i_inst => NULL);
        END IF;*/
    
        IF i_commit = 1
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MIG_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            IF i_commit = 1
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MIG_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            IF i_commit = 1
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
    END mig_diagnosis_ea;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'MIG_DIAGNOSIS_RELATIONS_EA';
        l_tab_diagnosis_rel_ea alert_core_func.pk_api_diagnosis_func.g_tbl_diagnosis_rel_ea;
    BEGIN
        pk_alertlog.log_debug('MSI_CONCEPT_RELATION: GET_RELATIONS_EA_DATA_FOR_MIGR (Y)',
                              'PK_MIG_DIAGNOSIS',
                              l_func_name);
        l_tab_diagnosis_rel_ea := pk_api_pfh_diagnosis_in.get_relations_ea_data_for_migr;
    
        IF l_tab_diagnosis_rel_ea.exists(1)
        THEN
            FOR i IN l_tab_diagnosis_rel_ea.first .. l_tab_diagnosis_rel_ea.last
            LOOP
                pk_ea_logic_diagnosis.ins_diagnosis_relations_ea(l_tab_diagnosis_rel_ea(i));
            END LOOP;
        END IF;
    
        IF i_commit = 1
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MIG_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            IF i_commit = 1
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MIG_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            IF i_commit = 1
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
    END mig_diagnosis_relations_ea;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'MIG_PAST_HISTORY';
    BEGIN
        pk_api_pfh_diagnosis_in.ins_missing_past_hist_diags;
    
        IF i_commit = 1
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MIG_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            IF i_commit = 1
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MIG_DIAGNOSIS',
                                              l_func_name,
                                              o_error);
            IF i_commit = 1
            THEN
                ROLLBACK;
            END IF;
            RETURN FALSE;
    END mig_past_history;
END pk_mig_diagnosis;
/
