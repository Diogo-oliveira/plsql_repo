BEGIN
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'JOB_SET_OUTP_NO_SHOW',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'STORED_PROCEDURE',
                                  i_job_action        => 'PK_EPISODE.SET_OUTP_NO_SHOW',
                                  i_repeat_interval   => 'FREQ=DAILY',
                                  i_start_date        => to_timestamp_tz(to_char(current_timestamp + 1, 'YYYYMMDD') ||
                                                                         '060000',
                                                                         'YYYYMMDDHH24MISS'),
                                  i_id_market         => 19,
                                  i_comment           => 'Mark daily scheduled episodes as No Show with a specific reason (sys_configurable)',
                                  i_responsible_team  => 'AMB',
                                  i_flg_available     => 'N',
                                  i_create_immediatly => 'Y');
END;
/

BEGIN
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'JOB_SET_OUTP_NO_SHOW',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'STORED_PROCEDURE',
                                  i_job_action        => 'PK_EPISODE.SET_OUTP_NO_SHOW',
                                  i_repeat_interval   => 'FREQ=DAILY',
                                  i_start_date        => to_timestamp_tz(to_char(current_timestamp + 1, 'YYYYMMDD') ||
                                                                         '060000',
                                                                         'YYYYMMDDHH24MISS'),
                                  i_id_market         => 19,
                                  i_comment           => 'Mark daily scheduled episodes as No Show with a specific reason (sys_configurable)',
                                  i_responsible_team  => 'AMB',
                                  i_flg_available     => 'N',
                                  i_create_immediatly => 'Y');
END;
/
