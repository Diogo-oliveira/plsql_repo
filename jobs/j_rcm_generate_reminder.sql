-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 26-NOV-2012
-- CHANGED REASON: ARCHDB-1283
BEGIN
    -- Call the procedure
    pk_frmw_jobs.parameterize_job(i_owner            => 'ALERT',
                                  i_obj_name         => 'J_RCM_GENERATE_REMINDER',
                                  i_inst_owner       => 0,
                                  i_job_type         => 'PLSQL_BLOCK',
                                  i_job_action       => 'BEGIN ALERT.PK_API_RCM_OUT.generate_reminders; END;',
                                  i_repeat_interval  => 'FREQ=WEEKLY; BYDAY=SUN;',
                                  i_start_date      => current_timestamp,
                                  i_id_market        => 2, -- US market 
                                  i_flg_available    => 'N', -- disabled
                                  i_responsible_team => 'ORDER TOOLS',
                                  i_comment          => 'Job that generates patient reminders');
END;
/
-- CHANGE END: Ana Monteiro

