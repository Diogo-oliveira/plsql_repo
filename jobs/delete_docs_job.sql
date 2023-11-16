BEGIN
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'DELETE_OLD_DOCS',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'PLSQL_BLOCK',
                                  i_job_action        => 'DECLARE w_res BOOLEAN; BEGIN w_res := pk_doc.delete_docs(i_lifetime => 96); EXCEPTION WHEN OTHERS THEN NULL; END;',
                                  i_repeat_interval   => 'FREQ=DAILY; BYHOUR=00; BYMINUTE=01',
                                  i_start_date        => current_timestamp,
                                  i_id_market         => 0,
                                  i_comment           => 'delete pending docs created before i_lifetime',
                                  i_responsible_team  => 'DOC',
                                  i_flg_available     => 'Y',
                                  i_create_immediatly => 'Y');
END;
/
