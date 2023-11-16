DECLARE
    g_obj_name     CONSTANT VARCHAR2(30 CHAR) := 'PK_MIG_DIAGNOSIS';
    g_sub_obj_name CONSTANT VARCHAR2(30 CHAR) := 'MIGRATION_SCRIPT';

    l_error t_error_out;
    e_mig_past_history EXCEPTION;
    e_mig_diagnosis_ea EXCEPTION;
BEGIN
    pk_alertlog.log_error(text => '>> START MIGRATION', object_name => g_obj_name, sub_object_name => g_sub_obj_name);

    pk_alertlog.log_error(text            => '>> START PK_MIG_DIAGNOSIS.MIG_PAST_HISTORY',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);
    IF NOT pk_mig_diagnosis.mig_past_history(i_commit => 0, o_error => l_error)
    THEN
        RAISE e_mig_past_history;
    END IF;
    pk_alertlog.log_error(text            => '>> END PK_MIG_DIAGNOSIS.MIG_PAST_HISTORY',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);

    pk_alertlog.log_error(text            => '>> START PK_MIG_DIAGNOSIS.MIG_DIAGNOSIS_EA',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);
    IF NOT pk_mig_diagnosis.mig_diagnosis_ea(i_institution => 0, i_commit => 0, o_error => l_error)
    THEN
        RAISE e_mig_diagnosis_ea;
    END IF;
    pk_alertlog.log_error(text            => '>> END PK_MIG_DIAGNOSIS.MIG_DIAGNOSIS_EA',
                          object_name     => g_obj_name,
                          sub_object_name => g_sub_obj_name);

    pk_alertlog.log_error(text => '>> FINISH MIGRATION', object_name => g_obj_name, sub_object_name => g_sub_obj_name);

    COMMIT;

EXCEPTION
    WHEN e_mig_past_history THEN
        raise_application_error(-20001, '>> ERROR mig_past_history: ' || l_error.log_id);
        ROLLBACK;
    WHEN e_mig_diagnosis_ea THEN
        raise_application_error(-20001, '>> ERROR mig_diagnosis_ea: ' || l_error.log_id);
        ROLLBACK;
END;
/
