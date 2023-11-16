-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/03/2015 11:21
-- CHANGE REASON: [ALERT-308718] 
update analysis_req_det 
set notes_scheduler = notes;

update analysis_req_det 
set notes = null;
-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 12/03/2015 11:20
-- CHANGE REASON: [ALERT-308720] 
DECLARE
    l_date_format    CONSTANT VARCHAR2(200 CHAR) := 'YYYYMMDDHH24MISS';
    l_def_order_type CONSTANT order_type.id_order_type%TYPE := 6;

    l_lang                language.id_language%TYPE := NULL;
    l_error               t_error_out;
    l_co_sign             co_sign.id_co_sign%TYPE;
    l_co_sign_hist        co_sign_hist.id_co_sign_hist%TYPE;
    l_tbl_id_co_sign_hist table_number;

    PROCEDURE handle_error
    (
        i_msg   IN VARCHAR2,
        i_error IN t_error_out
    ) IS
    BEGIN
        dbms_output.put_line('#########################################################');
        dbms_output.put_line('I_MSG: ' || i_msg);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLCODE: ' || i_error.ora_sqlcode);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLERRM: ' || i_error.ora_sqlerrm);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_DESC: ' || i_error.err_desc);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_ACTION: ' || i_error.err_action);
        dbms_output.put_line(' ');
        dbms_output.put_line('LOG_ID: ' || i_error.log_id);
        dbms_output.put_line('*********************************************************');
    END handle_error;

BEGIN
    FOR rec IN (SELECT ard.id_analysis_req_det,
                       e.id_episode,
                       e.id_institution,
                       nvl(ei.id_software,
                           (SELECT etsi.id_software
                              FROM epis_type et
                              JOIN epis_type_soft_inst etsi
                                ON etsi.id_epis_type = et.id_epis_type
                             WHERE et.flg_available = 'Y'
                               AND et.id_epis_type = e.id_epis_type
                               AND etsi.id_institution = 0
                               AND rownum = 1)) id_software,
                       ar.id_prof_writes,
                       ar.dt_req_tstz,
                       ard.id_prof_cancel,
                       ard.dt_cancel_tstz,
                       ard.flg_status,
                       ard.id_prof_order,
                       ard.dt_order,
                       nvl(ard.id_order_type, l_def_order_type) id_order_type,
                       ard.flg_co_sign,
                       ard.id_prof_co_sign,
                       ard.dt_co_sign,
                       ard.notes_co_sign
                  FROM analysis_req_det ard
                  JOIN analysis_req ar
                    ON ar.id_analysis_req = ard.id_analysis_req
                  JOIN episode e
                    ON (e.id_episode = nvl(ar.id_episode, ar.id_episode_origin))
                  JOIN epis_info ei
                    ON ei.id_episode = e.id_episode
                 WHERE ard.id_prof_order IS NOT NULL
                   AND ard.dt_order IS NOT NULL
                   AND ard.id_co_sign_order IS NULL
                   AND ard.id_co_sign_cancel IS NULL)
    LOOP
        l_co_sign := NULL;
    
        --CREATE NEW CO_SIGN
        IF NOT pk_co_sign_api.set_pending_co_sign_task(i_lang                   => l_lang,
                                                       i_prof                   => profissional(rec.id_prof_writes,
                                                                                                rec.id_institution,
                                                                                                rec.id_software),
                                                       i_episode                => rec.id_episode,
                                                       i_id_task_type           => 11,
                                                       i_cosign_def_action_type => 'NEEDS_COSIGN_ORDER',
                                                       i_id_task                => rec.id_analysis_req_det,
                                                       i_id_task_group          => rec.id_analysis_req_det,
                                                       i_id_order_type          => rec.id_order_type,
                                                       i_id_prof_created        => rec.id_prof_writes,
                                                       i_id_prof_ordered_by     => rec.id_prof_order,
                                                       i_dt_created             => rec.dt_req_tstz,
                                                       i_dt_ordered_by          => rec.dt_order,
                                                       o_id_co_sign             => l_co_sign,
                                                       o_id_co_sign_hist        => l_co_sign_hist,
                                                       o_error                  => l_error)
        THEN
            handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_COSIGN_TASK(' || l_lang || --
                                    ', profissional(' || rec.id_prof_writes || ', ' || rec.id_institution || ', ' ||
                                    rec.id_software || '), ' || --
                                    rec.id_episode || ', ' || --
                                    'NEEDS_COSIGN_ORDER' || ', ' || --
                                    rec.id_analysis_req_det || ', ' || --
                                    rec.id_analysis_req_det || ', ' || --
                                    rec.id_order_type || ', ' || --
                                    rec.id_prof_writes || ', ' || --
                                    rec.id_prof_order || ', ' || --
                                    to_char(rec.dt_req_tstz, l_date_format) || ', ' || --
                                    to_char(rec.dt_order, l_date_format) || ')',
                         i_error => l_error);
        END IF;
    
        --Update Transactional table with id_co_sign
        UPDATE analysis_req_det ard
           SET ard.id_co_sign_order = l_co_sign
         WHERE ard.id_analysis_req_det = rec.id_analysis_req_det;
    
        IF rec.flg_co_sign = 'Y'
        THEN
            --Co-sign the task
            IF NOT pk_co_sign.set_task_co_signed(i_lang                => l_lang,
                                                 i_prof                => profissional(rec.id_prof_writes,
                                                                                       rec.id_institution,
                                                                                       rec.id_software),
                                                 i_episode             => rec.id_episode,
                                                 i_tbl_id_co_sign      => table_number(l_co_sign),
                                                 i_id_prof_cosigned    => rec.id_prof_co_sign,
                                                 i_dt_cosigned         => rec.dt_co_sign,
                                                 i_cosign_notes        => rec.notes_co_sign,
                                                 i_flg_made_auth       => 'N',
                                                 o_tbl_id_co_sign_hist => l_tbl_id_co_sign_hist,
                                                 o_error               => l_error)
            THEN
                handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_TASK_CO_SIGNED(' || l_lang || --
                                        ', profissional(' || rec.id_prof_writes || ', ' || rec.id_institution || ', ' ||
                                        rec.id_software || '), ' || --
                                        rec.id_episode || ', ' || --
                                        l_co_sign || ', ' || --
                                        rec.id_prof_co_sign || ', ' || --
                                        to_char(rec.dt_co_sign, l_date_format) || ', ' || --
                                        rec.notes_co_sign || ', ' || --
                                        'N' || ')',
                             i_error => l_error);
            END IF;
        END IF;
    END LOOP;
END;
/
-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 21/04/2015 16:47
-- CHANGE REASON: [ALERT-310275] 
DECLARE
    l_date_format    CONSTANT VARCHAR2(200 CHAR) := 'YYYYMMDDHH24MISS';
    l_def_order_type CONSTANT order_type.id_order_type%TYPE := 6;

    l_lang                language.id_language%TYPE := NULL;
    l_error               t_error_out;
    l_co_sign             co_sign.id_co_sign%TYPE;
    l_co_sign_hist        co_sign_hist.id_co_sign_hist%TYPE;
    l_tbl_id_co_sign_hist table_number;

    PROCEDURE handle_error
    (
        i_msg   IN VARCHAR2,
        i_error IN t_error_out
    ) IS
    BEGIN
        dbms_output.put_line('#########################################################');
        dbms_output.put_line('I_MSG: ' || i_msg);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLCODE: ' || i_error.ora_sqlcode);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLERRM: ' || i_error.ora_sqlerrm);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_DESC: ' || i_error.err_desc);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_ACTION: ' || i_error.err_action);
        dbms_output.put_line(' ');
        dbms_output.put_line('LOG_ID: ' || i_error.log_id);
        dbms_output.put_line('*********************************************************');
    END handle_error;

BEGIN

    FOR rec IN (SELECT ard.id_analysis_req_det,
                       e.id_episode,
                       e.id_institution,
                       nvl(ei.id_software,
                           (SELECT etsi.id_software
                              FROM epis_type et
                              JOIN epis_type_soft_inst etsi
                                ON etsi.id_epis_type = et.id_epis_type
                             WHERE et.flg_available = 'Y'
                               AND et.id_epis_type = e.id_epis_type
                               AND etsi.id_institution = 0
                               AND rownum = 1)) id_software,
                       ar.id_prof_writes,
                       ar.dt_req_tstz,
                       ard.id_prof_cancel,
                       ard.dt_cancel_tstz,
                       ard.flg_status,
                       ard.id_prof_order,
                       ard.dt_order,
                       nvl(ard.id_order_type, l_def_order_type) id_order_type,
                       ard.flg_co_sign,
                       ard.id_prof_co_sign,
                       ard.dt_co_sign,
                       ard.notes_co_sign
                  FROM analysis_req_det ard
                  JOIN analysis_req ar
                    ON ar.id_analysis_req = ard.id_analysis_req
                  JOIN episode e
                    ON (e.id_episode = nvl(ar.id_episode, ar.id_episode_origin))
                  JOIN epis_info ei
                    ON ei.id_episode = e.id_episode
                 WHERE ard.id_co_sign_order IS NOT NULL
                   AND ard.id_prof_order IS NOT NULL
                   AND ard.dt_order IS NOT NULL
                   AND (ard.id_order_type IS NOT NULL OR
                       (ard.id_prof_order != ar.id_prof_writes AND ard.id_order_type IS NULL)))
    LOOP
    
        l_co_sign_hist := NULL;
    
        --CREATE NEW CO_SIGN
        IF NOT pk_co_sign_api.set_pending_co_sign_task(i_lang                   => l_lang,
                                                       i_prof                   => profissional(rec.id_prof_writes,
                                                                                                rec.id_institution,
                                                                                                rec.id_software),
                                                       i_episode                => rec.id_episode,
                                                       i_id_task_type           => 11,
                                                       i_cosign_def_action_type => 'NEEDS_COSIGN_ORDER',
                                                       i_id_task                => rec.id_analysis_req_det,
                                                       i_id_task_group          => rec.id_analysis_req_det,
                                                       i_id_order_type          => rec.id_order_type,
                                                       i_id_prof_created        => rec.id_prof_writes,
                                                       i_id_prof_ordered_by     => rec.id_prof_order,
                                                       i_dt_created             => rec.dt_req_tstz,
                                                       i_dt_ordered_by          => rec.dt_order,
                                                       o_id_co_sign             => l_co_sign,
                                                       o_id_co_sign_hist        => l_co_sign_hist,
                                                       o_error                  => l_error)
        THEN
            handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_COSIGN_TASK(' || l_lang || --
                                    ', profissional(' || rec.id_prof_writes || ', ' || rec.id_institution || ', ' ||
                                    rec.id_software || '), ' || --
                                    rec.id_episode || ', ' || --
                                    'NEEDS_COSIGN_ORDER' || ', ' || --
                                    rec.id_analysis_req_det || ', ' || --
                                    rec.id_analysis_req_det || ', ' || --
                                    rec.id_order_type || ', ' || --
                                    rec.id_prof_writes || ', ' || --
                                    rec.id_prof_order || ', ' || --
                                    to_char(rec.dt_req_tstz, l_date_format) || ', ' || --
                                    to_char(rec.dt_order, l_date_format) || ')',
                         i_error => l_error);
        END IF;
    
        --Update Transactional table with id_co_sign
        UPDATE analysis_req_det ard
           SET ard.id_co_sign_order = l_co_sign_hist
         WHERE ard.id_analysis_req_det = rec.id_analysis_req_det;
    
        IF rec.flg_co_sign = 'Y'
        THEN
            SELECT cs.id_co_sign
              INTO l_co_sign
              FROM TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(l_lang,
                                                                  profissional(rec.id_prof_writes,
                                                                               rec.id_institution,
                                                                               rec.id_software),
                                                                  rec.id_episode,
                                                                  NULL,
                                                                  l_co_sign_hist)) cs;
        
            --Co-sign the task
            IF NOT pk_co_sign.set_task_co_signed(i_lang                => l_lang,
                                                 i_prof                => profissional(rec.id_prof_writes,
                                                                                       rec.id_institution,
                                                                                       rec.id_software),
                                                 i_episode             => rec.id_episode,
                                                 i_tbl_id_co_sign      => table_number(l_co_sign),
                                                 i_id_prof_cosigned    => rec.id_prof_co_sign,
                                                 i_dt_cosigned         => rec.dt_co_sign,
                                                 i_cosign_notes        => rec.notes_co_sign,
                                                 i_flg_made_auth       => 'N',
                                                 o_tbl_id_co_sign_hist => l_tbl_id_co_sign_hist,
                                                 o_error               => l_error)
            THEN
                handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_TASK_CO_SIGNED(' || l_lang || --
                                        ', profissional(' || rec.id_prof_writes || ', ' || rec.id_institution || ', ' ||
                                        rec.id_software || '), ' || --
                                        rec.id_episode || ', ' || --
                                        l_co_sign || ', ' || --
                                        rec.id_prof_co_sign || ', ' || --
                                        to_char(rec.dt_co_sign, l_date_format) || ', ' || --
                                        rec.notes_co_sign || ', ' || --
                                        'N' || ')',
                             i_error => l_error);
            END IF;
        END IF;
    END LOOP;
END;
/

-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 28/04/2015 11:48
-- CHANGE REASON: [ALERT-310480] 
DECLARE
    l_date_format    CONSTANT VARCHAR2(200 CHAR) := 'YYYYMMDDHH24MISS';
    l_def_order_type CONSTANT order_type.id_order_type%TYPE := 6;

    l_lang                language.id_language%TYPE := NULL;
    l_error               t_error_out;
    l_co_sign             co_sign.id_co_sign%TYPE;
    l_co_sign_hist        co_sign_hist.id_co_sign_hist%TYPE;
    l_tbl_id_co_sign_hist table_number;

    PROCEDURE handle_error
    (
        i_msg   IN VARCHAR2,
        i_error IN t_error_out
    ) IS
    BEGIN
        dbms_output.put_line('#########################################################');
        dbms_output.put_line('I_MSG: ' || i_msg);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLCODE: ' || i_error.ora_sqlcode);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLERRM: ' || i_error.ora_sqlerrm);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_DESC: ' || i_error.err_desc);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_ACTION: ' || i_error.err_action);
        dbms_output.put_line(' ');
        dbms_output.put_line('LOG_ID: ' || i_error.log_id);
        dbms_output.put_line('*********************************************************');
    END handle_error;

BEGIN

    FOR rec IN (SELECT ard.id_analysis_req_det,
                       e.id_episode,
                       e.id_institution,
                       nvl(ei.id_software,
                           (SELECT etsi.id_software
                              FROM epis_type et
                              JOIN epis_type_soft_inst etsi
                                ON etsi.id_epis_type = et.id_epis_type
                             WHERE et.flg_available = 'Y'
                               AND et.id_epis_type = e.id_epis_type
                               AND etsi.id_institution = 0
                               AND rownum = 1)) id_software,
                       ar.id_prof_writes,
                       ar.dt_req_tstz,
                       ard.id_prof_cancel,
                       ard.dt_cancel_tstz,
                       ard.flg_status,
                       ard.id_prof_order,
                       ard.dt_order,
                       nvl(ard.id_order_type, l_def_order_type) id_order_type,
                       ard.flg_co_sign,
                       ard.id_prof_co_sign,
                       ard.dt_co_sign,
                       ard.notes_co_sign
                  FROM analysis_req_det ard
                  JOIN analysis_req ar
                    ON ar.id_analysis_req = ard.id_analysis_req
                  JOIN episode e
                    ON (e.id_episode = nvl(ar.id_episode, ar.id_episode_origin))
                  JOIN epis_info ei
                    ON ei.id_episode = e.id_episode
                 WHERE ard.id_co_sign_order IS NULL
                   AND ard.id_prof_order IS NOT NULL
                   AND ard.dt_order IS NOT NULL
                   AND (ard.id_order_type IS NOT NULL OR
                       (ard.id_prof_order != ar.id_prof_writes AND ard.id_order_type IS NULL)))
    LOOP
    
        l_co_sign_hist := NULL;
    
        --CREATE NEW CO_SIGN
        IF NOT pk_co_sign_api.set_pending_co_sign_task(i_lang                   => l_lang,
                                                       i_prof                   => profissional(rec.id_prof_writes,
                                                                                                rec.id_institution,
                                                                                                rec.id_software),
                                                       i_episode                => rec.id_episode,
                                                       i_id_task_type           => 11,
                                                       i_cosign_def_action_type => 'NEEDS_COSIGN_ORDER',
                                                       i_id_task                => rec.id_analysis_req_det,
                                                       i_id_task_group          => rec.id_analysis_req_det,
                                                       i_id_order_type          => rec.id_order_type,
                                                       i_id_prof_created        => rec.id_prof_writes,
                                                       i_id_prof_ordered_by     => rec.id_prof_order,
                                                       i_dt_created             => rec.dt_req_tstz,
                                                       i_dt_ordered_by          => rec.dt_order,
                                                       o_id_co_sign             => l_co_sign,
                                                       o_id_co_sign_hist        => l_co_sign_hist,
                                                       o_error                  => l_error)
        THEN
            handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_COSIGN_TASK(' || l_lang || --
                                    ', profissional(' || rec.id_prof_writes || ', ' || rec.id_institution || ', ' ||
                                    rec.id_software || '), ' || --
                                    rec.id_episode || ', ' || --
                                    'NEEDS_COSIGN_ORDER' || ', ' || --
                                    rec.id_analysis_req_det || ', ' || --
                                    rec.id_analysis_req_det || ', ' || --
                                    rec.id_order_type || ', ' || --
                                    rec.id_prof_writes || ', ' || --
                                    rec.id_prof_order || ', ' || --
                                    to_char(rec.dt_req_tstz, l_date_format) || ', ' || --
                                    to_char(rec.dt_order, l_date_format) || ')',
                         i_error => l_error);
        END IF;
    
        --Update Transactional table with id_co_sign
        UPDATE analysis_req_det ard
           SET ard.id_co_sign_order = l_co_sign_hist
         WHERE ard.id_analysis_req_det = rec.id_analysis_req_det;
    
        IF rec.flg_co_sign = 'Y'
        THEN
            SELECT cs.id_co_sign
              INTO l_co_sign
              FROM TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(l_lang,
                                                                  profissional(rec.id_prof_writes,
                                                                               rec.id_institution,
                                                                               rec.id_software),
                                                                  rec.id_episode,
                                                                  NULL,
                                                                  l_co_sign_hist)) cs;
        
            --Co-sign the task
            IF NOT pk_co_sign.set_task_co_signed(i_lang                => l_lang,
                                                 i_prof                => profissional(rec.id_prof_writes,
                                                                                       rec.id_institution,
                                                                                       rec.id_software),
                                                 i_episode             => rec.id_episode,
                                                 i_tbl_id_co_sign      => table_number(l_co_sign),
                                                 i_id_prof_cosigned    => rec.id_prof_co_sign,
                                                 i_dt_cosigned         => rec.dt_co_sign,
                                                 i_cosign_notes        => rec.notes_co_sign,
                                                 i_flg_made_auth       => 'N',
                                                 o_tbl_id_co_sign_hist => l_tbl_id_co_sign_hist,
                                                 o_error               => l_error)
            THEN
                handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_TASK_CO_SIGNED(' || l_lang || --
                                        ', profissional(' || rec.id_prof_writes || ', ' || rec.id_institution || ', ' ||
                                        rec.id_software || '), ' || --
                                        rec.id_episode || ', ' || --
                                        l_co_sign || ', ' || --
                                        rec.id_prof_co_sign || ', ' || --
                                        to_char(rec.dt_co_sign, l_date_format) || ', ' || --
                                        rec.notes_co_sign || ', ' || --
                                        'N' || ')',
                             i_error => l_error);
            END IF;
        END IF;
    END LOOP;
END;
/

-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 04/05/2017 10:22
-- CHANGE REASON: [ALERT-330278] 
update analysis_req_det
set id_clinical_purpose = 501
where flg_clinical_purpose = 'N';

update analysis_req_det
set id_clinical_purpose = 502
where flg_clinical_purpose = 'S';

update analysis_req_det
set id_clinical_purpose = 508
where flg_clinical_purpose = 'P';

update analysis_req_det
set id_clinical_purpose = 504
where flg_clinical_purpose = 'R';

update analysis_req_det
set id_clinical_purpose = 503
where flg_clinical_purpose = 'T';

update analysis_req_det
set id_clinical_purpose = 505
where flg_clinical_purpose = 'C';

update analysis_req_det
set id_clinical_purpose = 506
where flg_clinical_purpose = 'PO';

update analysis_req_det
set id_clinical_purpose = 507
where flg_clinical_purpose = 'F';

update analysis_req_det
set id_clinical_purpose = 0
where flg_clinical_purpose = 'O';
-- CHANGE END: Ana Matos