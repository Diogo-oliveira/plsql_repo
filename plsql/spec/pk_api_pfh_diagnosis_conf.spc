/*-- Last Change Revision: $Rev: 2028482 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_pfh_diagnosis_conf IS

    -- Author  : José Silva
    -- Purpose : Diagnosis configuration APIs

    g_operation_insert VARCHAR2(10 CHAR) := 'INSERT';
    g_operation_update VARCHAR2(10 CHAR) := 'UPDATE';

    g_lang           CONSTANT language.id_language%TYPE := 2;
    g_inst_owner_all CONSTANT diagnosis_ea.id_cncpt_vrs_inst_owner%TYPE := 0;

    /********************************************************************************************
    * Insert into MSI_TERMIN_VERSION.
    *
    * @param i_institution                       Institution ID to be affected by the configuration
    * @param i_software                          Software ID to be affected by the configuration
    * @param i_terminology_version               TERMINOLOGY VERSION ID
    * @param i_task_type                         Task type ID
    *
    * @author                                    José Silva
    * @version                                   2.6.2
    * @since                                     14-May-2012
    *
    **********************************************************************************************/
    PROCEDURE ins_msi_termin_version
    (
        i_institution         institution.id_institution%TYPE,
        i_software            software.id_software%TYPE,
        i_terminology_version terminology_version.id_terminology_version%TYPE,
        i_task_type           NUMBER
    );

    /********************************************************************************************
    * DELETE FROM MSI_TERMIN_VERSION.
    *
    * @param i_institution                       Institution ID to be affected by the configuration
    * @param i_software                          Software ID to be affected by the configuration
    * @param i_terminology_version               Terminology version record to be deleted
    * @param i_task_type                         Task type ID
    *
    * @author                                    José Silva
    * @version                                   2.6.2
    * @since                                     14-May-2012
    **********************************************************************************************/
    PROCEDURE del_msi_termin_version
    (
        i_institution         institution.id_institution%TYPE,
        i_software            software.id_software%TYPE,
        i_terminology_version terminology_version.id_terminology_version%TYPE,
        i_task_type           NUMBER
    );

    /********************************************************************************************
    * Insert into msi_cncpt_vers_attrib.
    *
    * @param i_institution                       Institution ID to be affected by the configuration
    * @param i_software                          Software ID to be affected by the configuration
    * @param i_terminology_version               Terminology version record to be configured
    * @param i_concept                           Concept ID
    * @param i_gender                            Gender to be configured
    * @param i_age_min                           Minimum age
    * @param i_age_max                           Maximum age
    * @param i_flg_select                        Is this a selectable concept? (Y)es or (N)o
    * @param i_flg_update_ea                     Updates the EA tables? (Y)es or (N)o
    *
    * @return                                    TRUE / FALSE
    *
    * @author                                    José Silva
    * @version                                   2.6.2
    * @since                                     14-May-2012
    **********************************************************************************************/
    FUNCTION ins_msi_cncpt_vers_attrib
    (
        i_institution         IN institution.id_institution%TYPE,
        i_software            IN software.id_software%TYPE,
        i_terminology_version IN terminology_version.id_terminology_version%TYPE,
        i_concept             IN concept.id_concept%TYPE,
        i_gender              IN msi_cncpt_vers_attrib.gender%TYPE,
        i_age_min             IN msi_cncpt_vers_attrib.age_min%TYPE,
        i_age_max             IN msi_cncpt_vers_attrib.age_max%TYPE,
        i_flg_select          IN msi_cncpt_vers_attrib.txt_attribute_04%TYPE,
        i_flg_update_ea       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Delete from msi_cncpt_vers_attrib.
    *
    * @param i_institution                       Institution ID to be affected by the configuration
    * @param i_software                          Software ID to be affected by the configuration
    * @param i_terminology_version               Terminology version record to be configured
    * @param i_concept                           Concept ID
    * @param i_flg_delete                        Deletes the record: Y - yes, N - only inactivates
    * @param i_flg_update_ea                     Updates the EA tables? (Y)es or (N)o
    *
    * @return                                    TRUE / FALSE
    *
    * @author                                    José Silva
    * @version                                   2.6.2
    * @since                                     15-May-2012
    **********************************************************************************************/
    FUNCTION del_msi_cncpt_vers_attrib
    (
        i_institution         IN institution.id_institution%TYPE,
        i_software            IN software.id_software%TYPE,
        i_terminology_version IN terminology_version.id_terminology_version%TYPE,
        i_concept             IN concept.id_concept%TYPE,
        i_flg_delete          IN VARCHAR2,
        i_flg_update_ea       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert into msi_concept_relation.
    *
    * @param i_institution                       Institution ID to be affected by the configuration
    * @param i_software                          Software ID to be affected by the configuration
    * @param i_terminology_version1              Terminology version of the 1st concept of the relation
    * @param i_concept1                          1st concept ID
    * @param i_terminology_version2              Terminology version of the 1st concept of the relation
    * @param i_concept2                          2nd concept ID 
    * @param i_concept_rel_type                  Concept relation type
    * @param i_rank                              Rank associated with the relation
    * @param i_flg_default                       Concept associated by default in the relation
    * @param i_flg_update_ea                     Updates the EA tables? (Y)es or (N)o
    *
    * @return                                    TRUE / FALSE
    *
    * @author                                    José Silva
    * @version                                   2.6.2
    * @since                                     15-May-2012
    **********************************************************************************************/
    FUNCTION ins_msi_concept_relation
    (
        i_institution          IN institution.id_institution%TYPE,
        i_software             IN software.id_software%TYPE,
        i_terminology_version1 IN terminology_version.id_terminology_version%TYPE,
        i_concept1             IN concept.id_concept%TYPE,
        i_terminology_version2 IN terminology_version.id_terminology_version%TYPE,
        i_concept2             IN concept.id_concept%TYPE,
        i_concept_rel_type     IN concept_rel_type.id_concept_rel_type%TYPE,
        i_rank                 IN msi_concept_relation.rank%TYPE,
        i_flg_default          IN msi_concept_relation.flg_default%TYPE,
        i_flg_update_ea        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Delete from msi_concept_relation.
    *
    * @param i_institution                       Institution ID to be affected by the configuration
    * @param i_software                          Software ID to be affected by the configuration
    * @param i_terminology_version1              Terminology version of the 1st concept of the relation
    * @param i_concept1                          1st concept ID
    * @param i_terminology_version2              Terminology version of the 1st concept of the relation
    * @param i_concept2                          2nd concept ID 
    * @param i_concept_rel_type                  Concept relation type
    * @param i_flg_delete                        Deletes the record: Y - yes, N - only inactivates
    * @param i_flg_update_ea                     Updates the EA tables? (Y)es or (N)o
    *
    * @return                                    TRUE / FALSE
    *
    * @author                                    José Silva
    * @version                                   2.6.2
    * @since                                     15-May-2012
    **********************************************************************************************/
    FUNCTION del_msi_concept_relation
    (
        i_institution          IN institution.id_institution%TYPE,
        i_software             IN software.id_software%TYPE,
        i_terminology_version1 IN terminology_version.id_terminology_version%TYPE,
        i_concept1             IN concept.id_concept%TYPE,
        i_terminology_version2 IN terminology_version.id_terminology_version%TYPE,
        i_concept2             IN concept.id_concept%TYPE,
        i_concept_rel_type     IN concept_rel_type.id_concept_rel_type%TYPE,
        i_flg_delete           IN VARCHAR2,
        i_flg_update_ea        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert into msi_concept_term.
    *
    * @param i_institution                       Institution ID to be affected by the configuration
    * @param i_software                          Software ID to be affected by the configuration
    * @param i_concept_version                   Concept version ID
    * @param i_concept_term                      Concept term ID
    * @param i_dep_clin_serv                     Dep clin serv ID
    * @param i_professional                      Professional ID
    * @param i_gender                            Gender to be configured
    * @param i_age_min                           Minimum age
    * @param i_age_max                           Maximum age
    * @param i_rank                              Rank associated with the term
    * @param i_flg_type                          Configuration type: P - universe, M - most frequent
    * @param i_flg_update_ea                     Updates the EA tables? (Y)es or (N)o
    *
    * @return                                    TRUE / FALSE
    *
    * @author                                    José Silva
    * @version                                   2.6.2
    * @since                                     15-May-2012
    **********************************************************************************************/
    FUNCTION ins_msi_concept_term
    (
        i_institution     IN institution.id_institution%TYPE,
        i_software        IN software.id_software%TYPE,
        i_concept_version IN concept_version.id_concept_version%TYPE,
        i_concept_term    IN concept_term.id_concept_term%TYPE,
        i_dep_clin_serv   IN msi_concept_term.id_dep_clin_serv%TYPE,
        i_professional    IN msi_concept_term.id_professional%TYPE,
        i_gender          IN msi_concept_term.gender%TYPE,
        i_age_min         IN msi_concept_term.age_min%TYPE,
        i_age_max         IN msi_concept_term.age_max%TYPE,
        i_rank            IN msi_concept_term.rank%TYPE,
        i_flg_type        IN msi_concept_term.flg_type%TYPE,
        i_flg_update_ea   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Delete from msi_concept_term.
    *
    * @param i_institution                       Institution ID to be affected by the configuration
    * @param i_software                          Software ID to be affected by the configuration
    * @param i_concept_version                   Concept version ID
    * @param i_concept_term                      Concept term ID
    * @param i_dep_clin_serv                     Dep clin serv ID
    * @param i_professional                      Professional ID
    * @param i_flg_type                          Configuration type: M - most frequent, P - Universe
    * @param i_flg_delete                        Deletes the record: Y - yes, N - only inactivates
    * @param i_flg_update_ea                     Updates the EA tables? (Y)es or (N)o
    *
    * @return                                    TRUE / FALSE
    *
    * @author                                    José Silva
    * @version                                   2.6.2
    * @since                                     15-May-2012
    **********************************************************************************************/
    FUNCTION del_msi_concept_term
    (
        i_institution     IN institution.id_institution%TYPE,
        i_software        IN software.id_software%TYPE,
        i_concept_version IN concept_version.id_concept_version%TYPE,
        i_concept_term    IN concept_term.id_concept_term%TYPE,
        i_dep_clin_serv   IN msi_concept_term.id_dep_clin_serv%TYPE,
        i_professional    IN msi_concept_term.id_professional%TYPE,
        i_flg_type        IN msi_concept_term.flg_type%TYPE,
        i_flg_delete      IN VARCHAR2,
        i_flg_update_ea   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN BOOLEAN;

END pk_api_pfh_diagnosis_conf;
/
