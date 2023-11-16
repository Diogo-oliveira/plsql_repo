-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 26-NOV-2012
-- CHANGED REASON: ARCHDB-1283
BEGIN
    -- Call the procedure
    pk_frmw_jobs.parameterize_job(i_owner           => 'ALERT',
                                  i_obj_name        => 'J_REF_SESSION_CLEAN',
                                  i_inst_owner      => 0,
                                  i_job_type        => 'PLSQL_BLOCK',
                                  i_job_action      => 'BEGIN ALERT.PK_API_REF_EXT.clean_ref_session(1); END;',
                                  i_repeat_interval => 'FREQ=DAILY;BYHOUR=01',
                                  i_start_date      => current_timestamp,
                                  i_id_market       => 1, -- acss only
								  i_flg_available   => 'N', -- disabled
								  i_responsible_team => 'REFERRAL',
                                  i_comment         => 'ALERT-70412: Cleans inactive application sessions (originated by external systems) that are alive for some time');
END;
/
-- CHANGE END: Ana Monteiro
