BEGIN
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'SEND_GP_DISCHARGE_LETTER',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'STORED_PROCEDURE',
                                  i_job_action        => 'PK_DISCHARGE.SEND_CRM_MESSAGES',
                                  i_repeat_interval   => 'FREQ = MINUTELY; INTERVAL = 30',
                                  i_start_date        => current_timestamp,
                                  i_id_market         => 8,
                                  i_flg_available     => 'Y',
                                  i_responsible_team  => 'EDIS',
                                  i_create_immediatly => 'Y',
                                  i_comment           => 'Sends the discharge letter to the GP');
END;
/
BEGIN
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'SEND_GP_DISCHARGE_LETTER',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'STORED_PROCEDURE',
                                  i_job_action        => 'PK_DISCHARGE.SEND_GP_DISCHARGE_LETTER',
                                  i_repeat_interval   => 'FREQ = MINUTELY; INTERVAL = 30',
                                  i_start_date        => current_timestamp,
                                  i_id_market         => 8,
                                  i_flg_available     => 'Y',
                                  i_responsible_team  => 'EDIS',
                                  i_create_immediatly => 'Y',
                                  i_comment           => 'Sends the discharge letter to the GP');
END;
/
