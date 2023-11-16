-->JOB_CLOSE_PREGNANCY|jobs
BEGIN
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'JOB_CLOSE_PREGNANCY',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'STORED_PROCEDURE',
                                  i_job_action        => 'PK_PREGNANCY.JOB_CLOSE_PREGNANCY',
                                  i_repeat_interval   => 'FREQ=DAILY',
                                  i_start_date        => to_timestamp_tz(to_char(current_timestamp + 1, 'YYYYMMDD') ||
                                                                         '060000',
                                                                         'YYYYMMDDHH24MISS'),
                                  i_id_market         => 0,
                                  i_flg_available     => 'Y',
                                  i_responsible_team  => 'EDIS',
                                  i_comment           => 'Close all pregnancys longer than 44 weeks (sys_configurable)',
                                  i_create_immediatly => 'Y');
END;
/
