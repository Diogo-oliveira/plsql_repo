begin
pk_frmw_jobs.parameterize_job(i_owner           => 'ALERT',
							i_obj_name        => 'ORDERS_PROCESS_PENDING',
							i_inst_owner      => 0,
							i_job_type        => 'PLSQL_BLOCK',
							i_job_action      => 'BEGIN pk_exams_external_api_db.process_exam_pending; pk_lab_tests_external_api_db.process_lab_test_pending; END;',
							i_repeat_interval => 'freq=minutely',
							i_start_date      => current_timestamp,
							i_id_market       => 0, 
							i_comment         => '',
							i_responsible_team => 'ORDERS',
							i_create_immediatly => 'N');
end;
/
