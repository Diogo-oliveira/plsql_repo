BEGIN
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'PK_DISCH_SET_END_DAY_DISCH',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'STORED_PROCEDURE',
                                  i_job_action        => 'PK_DISCHARGE.SET_END_DAY_DISCHARGES',
                                  i_repeat_interval   => 'FREQ=DAILY; BYHOUR=06',
                                  i_start_date        => current_timestamp,
                                  i_id_market         => 0,
                                  i_flg_available     => 'N',
                                  i_responsible_team  => 'AMB',
                                  i_comment           => 'Close all episodes pending at the end of the day (DISCHARGE)',
                                  i_create_immediatly => 'Y');
END;
/
