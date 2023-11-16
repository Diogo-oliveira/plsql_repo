BEGIN
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'SYSTRACKING_CLEAN_OLD',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'PLSQL_BLOCK',
                                  i_job_action        => 'DECLARE RetVal BOOLEAN; I_DAYS_TO_KEEP NUMBER; BEGIN I_DAYS_TO_KEEP := 30; RetVal := ALERT.PK_SYSTRACKING.CLEAN_OLD ( I_DAYS_TO_KEEP ); END;',
                                  i_repeat_interval   => 'FREQ=DAILY; BYHOUR=00; BYMINUTE=01',
                                  i_start_date        => current_timestamp,
                                  i_id_market         => 0,
                                  i_comment           => 'PK_SYSTRACKING.CLEAN_OLD',
                                  i_responsible_team  => 'N/A',
                                  i_flg_available     => 'Y',
                                  i_create_immediatly => 'Y');
END;
/
