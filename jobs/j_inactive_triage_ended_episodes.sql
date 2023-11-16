BEGIN
    pk_frmw_jobs.parameterize_job(i_owner           => 'ALERT',
                                  i_obj_name        => 'J_INACT_TRIAGE_ENDED_EPIS',
                                  i_inst_owner      => 0,
                                  i_job_type        => 'PLSQL_BLOCK',
                                  i_job_action      => 'begin inactive_triage_ended_episodes; end;',
                                  i_repeat_interval => 'FREQ=DAILY',
                                  i_start_date      => current_timestamp,
                                  i_id_market       => 0,
                                  i_flg_available   => 'N',
                                  i_responsible_team => 'EDIS',
                                  i_comment         => 'sys_config INACTIVE_TRIAGE_ENDED_EPISODES must be set to Y by institution',
                                  i_create_immediatly => 'Y');
END;
/
