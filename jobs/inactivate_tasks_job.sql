BEGIN
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'ORDERS_INACTIVATE_TASKS',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'PLSQL_BLOCK',
                                  i_job_action        => 'BEGIN pk_episode.inactivate_epis_tasks; END;',
                                  i_repeat_interval   => 'freq=minutely',
                                  i_start_date        => current_timestamp,
                                  i_id_market         => 0,
                                  i_comment           => '',
                                  i_responsible_team  => 'ORDERS',
                                  i_create_immediatly => 'Y');
								  
END;
/
