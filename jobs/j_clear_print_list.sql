BEGIN
    pk_frmw_jobs.remove_job_configuration(i_owner => 'ALERT', i_obj_name => 'J_CLEAR_PRINT_LIST');
    
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'J_CLEAR_PRINT_LIST',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'STORED_PROCEDURE',
                                  i_job_action        => 'pk_print_list_db.clear_print_list',
                                  i_repeat_interval   => 'FREQ=DAILY; ',
                                  i_start_date        => to_timestamp_tz(to_char(current_timestamp + 1, 'YYYYMMDD') ||
                                                                         '060000',
                                                                         'YYYYMMDDHH24MISS'),
                                  i_id_market         => 0,
                                  i_comment           => 'Clear print list from closed episodes',
                                  i_responsible_team  => 'ORDER TOOLS',
                                  i_flg_available     => 'Y',
                                  i_create_immediatly => 'Y');
END;
/