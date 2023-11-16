/*-- Last Change Revision: $Rev: 2026707 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:39 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_pfh_diagnosis_conf IS

    /* CAN'T TOUCH THIS */
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

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
    ) IS
    
    BEGIN
    
        pk_api_diagnosis_func.ins_msi_termin_version(i_institution         => i_institution,
                                                     i_software            => i_software,
                                                     i_terminology_version => i_terminology_version,
                                                     i_task_type           => i_task_type);
    
    END ins_msi_termin_version;

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
    ) IS
    
    BEGIN
    
        pk_api_diagnosis_func.del_msi_termin_version(i_institution         => i_institution,
                                                     i_software            => i_software,
                                                     i_terminology_version => i_terminology_version,
                                                     i_task_type           => i_task_type);
    END del_msi_termin_version;

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
    ) RETURN BOOLEAN IS
    
        l_operation VARCHAR2(10 CHAR);
        l_rows      table_varchar;
        l_error     t_error_out;
    
        l_prof profissional := profissional(0, i_institution, i_software);
    
    BEGIN
    
        IF NOT pk_api_diagnosis_func.ins_msi_cncpt_vers_attrib(i_institution         => i_institution,
                                                               i_software            => i_software,
                                                               i_terminology_version => i_terminology_version,
                                                               i_concept             => i_concept,
                                                               i_gender              => i_gender,
                                                               i_age_min             => i_age_min,
                                                               i_age_max             => i_age_max,
                                                               i_flg_select          => i_flg_select,
                                                               o_operation           => l_operation,
                                                               o_rows                => l_rows)
        THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN FALSE;
        END IF;
    
        IF i_flg_update_ea = pk_alert_constant.g_yes
        THEN
            IF l_operation = g_operation_insert
            THEN
                t_data_gov_mnt.process_insert(i_lang       => g_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'MSI_CNCPT_VERS_ATTRIB',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            ELSIF l_operation = g_operation_update
            THEN
                t_data_gov_mnt.process_update(i_lang       => g_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'MSI_CNCPT_VERS_ATTRIB',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    END ins_msi_cncpt_vers_attrib;

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
    ) RETURN BOOLEAN IS
        l_rows  table_varchar;
        l_error t_error_out;
    
        l_prof            profissional := profissional(0, i_institution, i_software);
        l_concept_version diagnosis_ea.id_concept_version%TYPE;
        l_where           VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF NOT pk_api_diagnosis_func.del_msi_cncpt_vers_attrib(i_institution         => i_institution,
                                                               i_software            => i_software,
                                                               i_terminology_version => i_terminology_version,
                                                               i_concept             => i_concept,
                                                               i_flg_delete          => i_flg_delete,
                                                               o_concept_version     => l_concept_version,
                                                               o_rows                => l_rows)
        THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN FALSE;
        END IF;
    
        IF i_flg_update_ea = pk_alert_constant.g_yes
        THEN
            IF i_flg_delete = pk_alert_constant.g_yes
            THEN
                t_data_gov_mnt.process_delete(i_lang       => g_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'MSI_CNCPT_VERS_ATTRIB',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            
                l_where := 'id_concept_version = ' || l_concept_version;
                l_where := l_where || ' AND id_institution = ' || i_institution;
                l_where := l_where || ' AND id_software = ' || i_software;
            
                ts_diagnosis_ea.del_by(where_clause_in => l_where);
            
            ELSE
                t_data_gov_mnt.process_update(i_lang       => g_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'MSI_CNCPT_VERS_ATTRIB',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    END del_msi_cncpt_vers_attrib;

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
    ) RETURN BOOLEAN IS
        l_operation VARCHAR2(10 CHAR);
        l_rows      table_varchar;
        l_error     t_error_out;
    
        l_prof profissional := profissional(0, i_institution, i_software);
    
    BEGIN
    
        IF NOT pk_api_diagnosis_func.ins_msi_concept_relation(i_institution          => i_institution,
                                                              i_software             => i_software,
                                                              i_terminology_version1 => i_terminology_version1,
                                                              i_concept1             => i_concept1,
                                                              i_terminology_version2 => i_terminology_version2,
                                                              i_concept2             => i_concept2,
                                                              i_concept_rel_type     => i_concept_rel_type,
                                                              i_rank                 => i_rank,
                                                              i_flg_default          => i_flg_default,
                                                              o_operation            => l_operation,
                                                              o_rows                 => l_rows)
        THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN FALSE;
        END IF;
    
        IF i_flg_update_ea = pk_alert_constant.g_yes
        THEN
            IF l_operation = g_operation_insert
            THEN
                t_data_gov_mnt.process_insert(i_lang       => g_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'MSI_CONCEPT_RELATION',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            ELSIF l_operation = g_operation_update
            THEN
                t_data_gov_mnt.process_update(i_lang       => g_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'MSI_CONCEPT_RELATION',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    END ins_msi_concept_relation;

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
    ) RETURN BOOLEAN IS
        l_rows  table_varchar;
        l_error t_error_out;
    
        l_prof              profissional := profissional(0, i_institution, i_software);
        l_concept_version1  diagnosis_relations_ea.id_concept_version_1%TYPE;
        l_concept_version2  diagnosis_relations_ea.id_concept_version_2%TYPE;
        l_rel_internal_name diagnosis_relations_ea.cncpt_rel_type_int_name%TYPE;
        l_where             VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF NOT pk_api_diagnosis_func.del_msi_concept_relation(i_institution          => i_institution,
                                                              i_software             => i_software,
                                                              i_terminology_version1 => i_terminology_version1,
                                                              i_concept1             => i_concept1,
                                                              i_terminology_version2 => i_terminology_version2,
                                                              i_concept2             => i_concept2,
                                                              i_concept_rel_type     => i_concept_rel_type,
                                                              i_flg_delete           => i_flg_delete,
                                                              o_concept_version1     => l_concept_version1,
                                                              o_concept_version2     => l_concept_version2,
                                                              o_rel_internal_name    => l_rel_internal_name,
                                                              o_rows                 => l_rows)
        THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN FALSE;
        END IF;
    
        IF i_flg_update_ea = pk_alert_constant.g_yes
        THEN
            IF i_flg_delete = pk_alert_constant.g_yes
            THEN
                t_data_gov_mnt.process_delete(i_lang       => g_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'MSI_CONCEPT_RELATION',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            
                l_where := 'id_concept_version_1 = ' || l_concept_version1;
                l_where := l_where || ' AND id_concept_version_2 = ' || l_concept_version2;
                l_where := l_where || ' AND cncpt_rel_type_int_name = ''' || l_rel_internal_name || '''';
                l_where := l_where || ' AND id_institution = ' || i_institution;
                l_where := l_where || ' AND id_software = ' || i_software;
            
                ts_diagnosis_relations_ea.del_by(l_where);
            
            ELSE
                t_data_gov_mnt.process_update(i_lang       => g_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'MSI_CONCEPT_RELATION',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    END del_msi_concept_relation;

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
    ) RETURN BOOLEAN IS
        l_operations table_varchar;
        l_rows       table_varchar;
        l_error      t_error_out;
    
        l_prof profissional := profissional(0, i_institution, i_software);
    
    BEGIN
    
        IF NOT pk_api_diagnosis_func.ins_msi_concept_term(i_institution     => i_institution,
                                                          i_software        => i_software,
                                                          i_concept_version => i_concept_version,
                                                          i_concept_term    => i_concept_term,
                                                          i_dep_clin_serv   => i_dep_clin_serv,
                                                          i_professional    => i_professional,
                                                          i_gender          => i_gender,
                                                          i_age_min         => i_age_min,
                                                          i_age_max         => i_age_max,
                                                          i_rank            => i_rank,
                                                          i_flg_type        => i_flg_type,
                                                          o_operations      => l_operations,
                                                          o_rows            => l_rows)
        THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN FALSE;
        END IF;
    
        IF i_flg_update_ea = pk_alert_constant.g_yes
        THEN
            FOR i IN 1 .. l_operations.count
            LOOP
                IF l_operations(i) = g_operation_insert
                THEN
                    t_data_gov_mnt.process_insert(i_lang       => g_lang,
                                                  i_prof       => l_prof,
                                                  i_table_name => 'MSI_CONCEPT_TERM',
                                                  i_rowids     => table_varchar(l_rows(i)),
                                                  o_error      => l_error);
                ELSIF l_operations(i) = g_operation_update
                THEN
                    t_data_gov_mnt.process_update(i_lang       => g_lang,
                                                  i_prof       => l_prof,
                                                  i_table_name => 'MSI_CONCEPT_TERM',
                                                  i_rowids     => table_varchar(l_rows(i)),
                                                  o_error      => l_error);
                
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    END ins_msi_concept_term;

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
    ) RETURN BOOLEAN IS
        l_rows  table_varchar;
        l_error t_error_out;
    
        l_prof            profissional := profissional(0, i_institution, i_software);
        l_where           VARCHAR2(1000 CHAR);
        l_concept_version diagnosis_ea.id_concept_version%TYPE;
    
    BEGIN
    
        IF NOT pk_api_diagnosis_func.del_msi_concept_term(i_institution     => i_institution,
                                                          i_software        => i_software,
                                                          i_concept_version => i_concept_version,
                                                          i_concept_term    => i_concept_term,
                                                          i_dep_clin_serv   => i_dep_clin_serv,
                                                          i_professional    => i_professional,
                                                          i_flg_type        => i_flg_type,
                                                          i_flg_delete      => i_flg_delete,
                                                          o_concept_version => l_concept_version,
                                                          o_rows            => l_rows)
        THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN FALSE;
        END IF;
    
        IF i_flg_update_ea = pk_alert_constant.g_yes
        THEN
            IF i_flg_delete = pk_alert_constant.g_yes
            THEN
                t_data_gov_mnt.process_delete(i_lang       => g_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'MSI_CONCEPT_TERM',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            
                l_where := 'id_concept_version = ' || l_concept_version;
            
                IF i_concept_term IS NOT NULL
                THEN
                    l_where := l_where || ' AND id_concept_term = ' || i_concept_term;
                END IF;
                l_where := l_where || ' AND id_institution = ' || i_institution;
                l_where := l_where || ' AND id_software = ' || i_software;
                l_where := l_where || ' AND id_dep_clin_serv = ' || nvl(i_dep_clin_serv, -1);
                l_where := l_where || ' AND id_professional = ' || nvl(i_professional, -1);
                l_where := l_where || ' AND flg_msi_concept_term = ''' || i_flg_type || '''';
            
                ts_diagnosis_ea.del_by(l_where);
            ELSE
                t_data_gov_mnt.process_update(i_lang       => g_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'MSI_CONCEPT_TERM',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            
            END IF;
        END IF;
    
        RETURN TRUE;
    END del_msi_concept_term;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_api_pfh_diagnosis_conf;
/
