declare
	l_sql varchar2(4000);
BEGIN

	l_sql := l_sql || 'begin'||chr(10);
	l_sql := l_sql || 'pk_wlcore.clean_queues(x_id_queue  => null, x_num_queue => null );'|| chr(10);
	l_sql := l_sql || 'end;';

    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'RESET_WL_QUEUES',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'PLSQL_BLOCK',
                                  i_job_action        => l_sql,
                                  i_repeat_interval   => 'FREQ=DAILY',
                                  i_start_date        => current_timestamp,
                                  i_id_market         => 0,
                                  i_comment           => 'Resets waiting Line queues',
                                  i_responsible_team  => 'DOC',
                                  i_flg_available     => 'Y',
                                  i_create_immediatly => 'Y');
END;
/