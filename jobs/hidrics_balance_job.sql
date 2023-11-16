BEGIN
    pk_frmw_jobs.parameterize_job(i_owner           => 'ALERT',
                                  i_obj_name        => 'HIDRICS_BALANCE_JOB',
                                  i_inst_owner      => 0,
                                  i_job_type        => 'STORED_PROCEDURE',
                                  i_job_action      => 'PK_INP_HIDRICS.SET_BALANCE',
                                  i_repeat_interval => 'FREQ = MINUTELY; INTERVAL = 30',
                                  i_start_date      => current_timestamp,
                                  i_id_market       => 0,
                                i_flg_available   => 'N',
                                i_responsible_team => 'INP',
                                  i_comment         => 'Closes or recalculates the inputed balance and opens a new one (when applicable)');
END;
/
