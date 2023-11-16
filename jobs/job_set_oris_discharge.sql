-->JOB_SET_ORIS_DISCHARGE|jobs
BEGIN
    pk_frmw_jobs.parameterize_job(i_owner           => 'ALERT',
                                  i_obj_name        => 'JOB_SET_ORIS_DISCHARGE',
                                  i_inst_owner      => 0,
                                  i_job_type        => 'STORED_PROCEDURE',
                                  i_job_action      => 'PK_DISCHARGE.SET_ORIS_DISCHARGE',
                                  i_repeat_interval => 'FREQ=DAILY',
                                  i_start_date      => to_timestamp_tz(to_char(current_timestamp + 1, 'YYYYMMDD') ||
                                                                       '060000',
                                                                       'YYYYMMDDHH24MISS'),
                                  i_id_market       => 0,
                                  i_flg_available   => 'N',
                                  i_responsible_team => 'INP',
                                  i_comment         => 'Close all oris episodes pending longer than 3 days (sys_configurable)');
END;
/


-- CHANGED BY: Ana Matos
-- CHANGE DATE: 03/06/2022 08:23
-- CHANGE REASON: [EMR-53481]
BEGIN
pk_frmw_jobs.parameterize_job(i_owner           => 'ALERT',
i_obj_name        => 'JOB_SET_ORIS_DISCHARGE',
i_inst_owner      => 0,
i_job_type        => 'PLSQL_BLOCK',
i_job_action      => 'BEGIN pk_discharge.set_oris_discharge; END;',
i_repeat_interval => 'FREQ=DAILY',
i_start_date      => to_timestamp_tz(to_char(current_timestamp + 1, 'YYYYMMDD') ||
'060000',
'YYYYMMDDHH24MISS'),
i_id_market       => 0,
i_flg_available   => 'Y',
i_responsible_team => 'CDOC',
i_comment         => 'Close all OR episodes pending longer than 3 days (configurable)',
i_create_immediatly => 'Y');
END;
/
-- CHANGE END: Ana Matos