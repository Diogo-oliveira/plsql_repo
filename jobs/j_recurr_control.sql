
-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 20-SEP-2012 10:00
-- CHANGE REASON: [ARCHDB-1212] Order recurrence control job
BEGIN
    -- Call the procedure
    pk_frmw_jobs.parameterize_job(i_owner            => 'ALERT',
                                  i_obj_name         => 'J_RECURR_CONTROL',
                                  i_inst_owner       => 0,
                                  i_job_type         => 'PLSQL_BLOCK',
                                  i_job_action       => 'BEGIN ALERT.PK_ORDER_RECURRENCE_CORE.set_order_recurr_control; END;',
                                  i_repeat_interval  => 'FREQ=HOURLY',
                                  i_start_date      => current_timestamp,
                                  i_id_market        => 0,
                                  i_responsible_team => 'ORDER TOOLS',
                                  i_comment          => 'Creates recurrence executions: Hourly');
END;
/
-- CHANGE END: Carlos Loureiro


-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 05/02/2020
-- CHANGE REASON: [EMR-26397] 
begin
dbms_scheduler.enable(name => 'J_RECURR_CONTROL');
end; 
-- CHANGE END: Pedro Henriques
