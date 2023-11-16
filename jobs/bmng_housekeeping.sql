BEGIN
    pk_frmw_jobs.parameterize_job(i_owner           => 'ALERT',
                                  i_obj_name        => 'BMNG_HOUSEKEEPING',
                                  i_inst_owner      => 0,
                                  i_job_type        => 'PLSQL_BLOCK',
                                  i_job_action      => 'BEGIN PK_BMNG_PBL.BMNG_HOUSEKEEPING; END;',
                                  i_repeat_interval => 'FREQ=DAILY; BYHOUR=02',
                                  i_start_date      => current_timestamp,
                                  i_id_market       => 0,
                                    i_flg_available   => 'N',
                                    i_responsible_team => 'INP',
                                  i_comment         => 'Scheduled job to update BMNG Easy Access tables');
END;
/
