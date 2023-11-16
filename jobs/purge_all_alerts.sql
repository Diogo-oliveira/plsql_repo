BEGIN
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'PURGE_ALL_ALERTS',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'PLSQL_BLOCK',
                                  i_job_action        => 'BEGIN PK_ALERTS.PURGE_ALL_ALERTS; END;',
                                  i_repeat_interval   => 'FREQ=DAILY; BYHOUR=00; BYMINUTE=30',
                                  i_start_date        => current_timestamp,
                                  i_id_market         => 0,
                                  i_flg_available     => 'Y',
                                  i_responsible_team  => 'EDIS',
                                  i_comment           => 'Deletes records from the event table',
                                  i_create_immediatly => 'Y');
END;
/
