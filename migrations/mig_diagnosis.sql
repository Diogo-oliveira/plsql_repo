DECLARE
    g_obj_name     CONSTANT VARCHAR2(30 CHAR) := 'PK_MIG_DIAGNOSIS';
    g_sub_obj_name CONSTANT VARCHAR2(30 CHAR) := 'MIGRATION_SCRIPT';

    l_error t_error_out;
    e_mig_alert_diagnosis EXCEPTION;
    e_mig_diagnosis_ea EXCEPTION;
    e_mig_diagnosis_relations_ea EXCEPTION;

    PROCEDURE update_statistics IS
    BEGIN
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA', --
                                      tabname       => 'TERMINOLOGY',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'TERMINOLOGY_VERSION',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA', --
                                      tabname       => 'CONCEPT',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA', --
                                      tabname       => 'CONCEPT_TYPE',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'TERMIN_CONCEPT_TYPE',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'CONCEPT_TYPE_REL',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'CONCEPT_VERSION',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'CONCEPT_TERM_TYPE',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA', --
                                      tabname       => 'CONCEPT_TERM',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'CONCEPT_TERM_TASK_TYPE',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'CONCEPT_REL_TYPE',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'CONCEPT_RELATION',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA', --
                                      tabname       => 'CONCEPT_MAP',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'CONCEPT_MAP_RELATION',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'MSI_TERMIN_VERSION',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'MSI_CNCPT_VERS_ATTRIB',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'DEF_CNCPT_VERS_ATTRIB',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'MSI_CONCEPT_RELATION',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'DEF_CONCEPT_RELATION',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'MSI_CONCEPT_MAP_REL',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'DEF_CONCEPT_MAP_REL',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'MSI_CONCEPT_TERM',
                                      no_invalidate => FALSE);
        dbms_stats.gather_table_stats(ownname       => 'ALERT_CORE_DATA',
                                      tabname       => 'DEF_CONCEPT_TERM',
                                      no_invalidate => FALSE);
    END update_statistics;
BEGIN
    pk_alertlog.log_error(text => '>> START MIGRATION', object_name => g_obj_name, sub_object_name => g_sub_obj_name);

    pk_alertlog.log_error(text            => '>> START UPDATING STATISTICS (1)',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);
    --update_statistics;
    pk_alertlog.log_error(text            => '>> FINISH UPDATING STATISTICS (1)',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);

    pk_alertlog.log_error(text            => '>> START MIG_ALERT_DIAGNOSIS',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);
    -- Migrate records from: DIAGNOSIS / ALERT_DIAGNOSIS / DIAGNOSIS_DEP_CLIN_SERV
    IF NOT pk_mig_diagnosis.mig_alert_diagnosis(i_output => 0, i_commit => 0, o_error => l_error)
    THEN
        RAISE e_mig_alert_diagnosis;
    END IF;
    pk_alertlog.log_error(text            => '>> FINISH MIG_ALERT_DIAGNOSIS',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);

    pk_alertlog.log_error(text            => '>> START UPDATING STATISTICS (2)',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);
    update_statistics;
    pk_alertlog.log_error(text            => '>> FINISH UPDATING STATISTICS (2)',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);

    pk_alertlog.log_error(text            => '>> START MIG_DIAGNOSIS_EA',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);
    -- Migrate DIAGNOSIS_EA
    IF NOT pk_mig_diagnosis.mig_diagnosis_ea(i_commit => 0, o_error => l_error)
    THEN
        RAISE e_mig_diagnosis_ea;
    END IF;
    pk_alertlog.log_error(text            => '>> FINISH MIG_DIAGNOSIS_EA',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);

    pk_alertlog.log_error(text            => '>> START MIG_DIAGNOSIS_RELATIONS_EA',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);
    -- Migrate DIAGNOSIS_RELATIONS_EA
    IF NOT pk_mig_diagnosis.mig_diagnosis_relations_ea(i_commit => 0, o_error => l_error)
    THEN
        RAISE e_mig_diagnosis_relations_ea;
    END IF;
    pk_alertlog.log_error(text            => '>> FINISH MIG_DIAGNOSIS_RELATIONS_EA',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);

    pk_alertlog.log_error(text => '>> FINISH MIGRATION', object_name => g_obj_name, sub_object_name => g_sub_obj_name);
    
    COMMIT;
    
EXCEPTION
    WHEN e_mig_alert_diagnosis THEN
        raise_application_error(-20001, '>> ERROR mig_alert_diagnosis: ' || l_error.log_id);
        ROLLBACK;
    WHEN e_mig_diagnosis_ea THEN
        raise_application_error(-20001, '>> ERROR mig_diagnosis_ea: ' || l_error.log_id);
        ROLLBACK;
    WHEN e_mig_diagnosis_relations_ea THEN
        raise_application_error(-20001, '>> ERROR mig_diagnosis_relations_ea: ' || l_error.log_id);
        ROLLBACK;
    WHEN OTHERS THEN
        raise_application_error(-20001, '>> ERROR (OTHERS): ' || l_error.log_id || ' (SQL ERROR: ' || SQLCODE || ' - ' || SQLERRM || ' )');
        ROLLBACK;
END;
/
