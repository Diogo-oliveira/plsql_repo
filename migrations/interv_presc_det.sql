-- CHANGED BY: cristina.oliveira
-- CHANGE DATE: 22/04/2015 09:06
-- CHANGE REASON: [ALERT-310275 ] 
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
    FOR r_proc IN (SELECT ipd.id_interv_presc_det,
                          epis.id_episode,
                          epis.id_institution,
                          nvl(ei.id_software,
                              (SELECT etsi.id_software
                                 FROM epis_type et
                                 JOIN epis_type_soft_inst etsi
                                   ON etsi.id_epis_type = et.id_epis_type
                                WHERE et.flg_available = 'Y'
                                  AND et.id_epis_type = epis.id_epis_type
                                  AND etsi.id_institution = 0
                                  AND rownum = 1)) id_software,
                          ip.id_professional,
                          ip.dt_interv_prescription_tstz,
                          ip.id_prof_cancel,
                          ip.dt_cancel_tstz,
                          ip.flg_status,
                          ipd.id_prof_order,
                          ipd.dt_order,
                          nvl(ipd.id_order_type, l_def_order_type) id_order_type,
                          ipd.flg_co_sign,
                          ipd.id_prof_co_sign,
                          ipd.dt_co_sign,
                          ipd.notes_co_sign
                     FROM interv_presc_det ipd
                     JOIN interv_prescription ip
                       ON ip.id_interv_prescription = ipd.id_interv_prescription
                     JOIN episode epis
                       ON (epis.id_episode = nvl(ip.id_episode, ip.id_episode_origin))
                     JOIN epis_info ei
                       ON ei.id_episode = epis.id_episode
                    WHERE (ipd.id_prof_order IS NOT NULL AND ipd.dt_order IS NOT NULL AND
                          (ipd.id_order_type IS NOT NULL OR
                          (ipd.id_prof_order != ip.id_professional AND ipd.id_order_type IS NULL)))
                      AND ipd.id_co_sign_order IS NULL)
    LOOP
        l_co_sign := NULL;
    
        --CREATE NEW CO_SIGN
        IF NOT pk_co_sign_api.set_pending_co_sign_task(i_lang                   => l_lang,
                                                       i_prof                   => profissional(r_proc.id_professional,
                                                                                                r_proc.id_institution,
                                                                                                r_proc.id_software),
                                                       i_episode                => r_proc.id_episode,
                                                       i_id_task_type           => 10,
                                                       i_cosign_def_action_type => 'NEEDS_COSIGN_ORDER',
                                                       i_id_task                => r_proc.id_interv_presc_det,
                                                       i_id_task_group          => r_proc.id_interv_presc_det,
                                                       i_id_order_type          => r_proc.id_order_type,
                                                       i_id_prof_created        => r_proc.id_professional,
                                                       i_id_prof_ordered_by     => r_proc.id_prof_order,
                                                       i_dt_created             => r_proc.dt_interv_prescription_tstz,
                                                       i_dt_ordered_by          => r_proc.dt_order,
                                                       o_id_co_sign             => l_co_sign,
                                                       o_id_co_sign_hist        => l_co_sign_hist,
                                                       o_error                  => l_error)
        THEN
            handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_COSIGN_TASK(' || l_lang || --
                                    ', profissional(' || r_proc.id_professional || ', ' || r_proc.id_institution || ', ' ||
                                    r_proc.id_software || '), ' || --
                                    r_proc.id_episode || ', ' || --
                                    10 || ', ' || --
                                    'NEEDS_COSIGN_ORDER' || ', ' || --
                                    r_proc.id_interv_presc_det || ', ' || --
                                    r_proc.id_interv_presc_det || ', ' || --
                                    r_proc.id_order_type || ', ' || --
                                    r_proc.id_professional || ', ' || --
                                    r_proc.id_prof_order || ', ' || --
                                    to_char(r_proc.dt_interv_prescription_tstz, l_date_format) || ', ' || --
                                    to_char(r_proc.dt_order, l_date_format) || ')',
                         i_error => l_error);
        END IF;
    
        --Update Transactional table with id_co_sign_hist
        UPDATE interv_presc_det ipd
           SET ipd.id_co_sign_order = l_co_sign_hist
         WHERE ipd.id_interv_presc_det = r_proc.id_interv_presc_det;
    
        IF r_proc.flg_co_sign = 'Y'
        THEN
            --Co-sign the task
            IF NOT pk_co_sign.set_task_co_signed(i_lang                => l_lang,
                                                 i_prof                => profissional(r_proc.id_professional,
                                                                                       r_proc.id_institution,
                                                                                       r_proc.id_software),
                                                 i_episode             => r_proc.id_episode,
                                                 i_tbl_id_co_sign      => table_number(l_co_sign),
                                                 i_id_prof_cosigned    => r_proc.id_prof_co_sign,
                                                 i_dt_cosigned         => r_proc.dt_co_sign,
                                                 i_cosign_notes        => r_proc.notes_co_sign,
                                                 i_flg_made_auth       => 'N',
                                                 o_tbl_id_co_sign_hist => l_tbl_id_co_sign_hist,
                                                 o_error               => l_error)
            THEN
                handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_TASK_CO_SIGNED(' || l_lang || --
                                        ', profissional(' || r_proc.id_professional || ', ' || r_proc.id_institution || ', ' ||
                                        r_proc.id_software || '), ' || --
                                        r_proc.id_episode || ', ' || --
                                        l_co_sign || ', ' || --
                                        r_proc.id_prof_co_sign || ', ' || --
                                        to_char(r_proc.dt_co_sign, l_date_format) || ', ' || --
                                        r_proc.notes_co_sign || ', ' || --
                                        'N' || ')',
                             i_error => l_error);
            END IF;
        END IF;
    END LOOP;
END;
/
-- CHANGE END: cristina.oliveira

-- CHANGED BY: cristina.oliveira
-- CHANGE DATE: 23/04/2015 11:18
-- CHANGE REASON: [ALERT-310275 ] 
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
    FOR r_proc IN (SELECT ipd.id_interv_presc_det,
                          epis.id_episode,
                          epis.id_institution,
                          nvl(ei.id_software,
                              (SELECT etsi.id_software
                                 FROM epis_type et
                                 JOIN epis_type_soft_inst etsi
                                   ON etsi.id_epis_type = et.id_epis_type
                                WHERE et.flg_available = 'Y'
                                  AND et.id_epis_type = epis.id_epis_type
                                  AND etsi.id_institution = 0
                                  AND rownum = 1)) id_software,
                          ip.id_professional,
                          ip.dt_interv_prescription_tstz,
                          ip.id_prof_cancel,
                          ip.dt_cancel_tstz,
                          ip.flg_status,
                          ipd.id_prof_order,
                          ipd.dt_order,
                          nvl(ipd.id_order_type, l_def_order_type) id_order_type,
                          ipd.flg_co_sign,
                          ipd.id_prof_co_sign,
                          ipd.dt_co_sign,
                          ipd.notes_co_sign
                     FROM interv_presc_det ipd
                     JOIN interv_prescription ip
                       ON ip.id_interv_prescription = ipd.id_interv_prescription
                     JOIN episode epis
                       ON (epis.id_episode = nvl(ip.id_episode, ip.id_episode_origin))
                     JOIN epis_info ei
                       ON ei.id_episode = epis.id_episode
                    WHERE (ipd.id_prof_order IS NOT NULL AND ipd.dt_order IS NOT NULL AND
                          (ipd.id_order_type IS NOT NULL OR
                          (ipd.id_prof_order != ip.id_professional AND ipd.id_order_type IS NULL)))
                      AND ipd.id_co_sign_order IS NULL)
    LOOP
        l_co_sign := NULL;
    
        --CREATE NEW CO_SIGN
        IF NOT pk_co_sign_api.set_pending_co_sign_task(i_lang                   => l_lang,
                                                       i_prof                   => profissional(r_proc.id_professional,
                                                                                                r_proc.id_institution,
                                                                                                r_proc.id_software),
                                                       i_episode                => r_proc.id_episode,
                                                       i_id_task_type           => 43,
                                                       i_cosign_def_action_type => 'NEEDS_COSIGN_ORDER',
                                                       i_id_task                => r_proc.id_interv_presc_det,
                                                       i_id_task_group          => r_proc.id_interv_presc_det,
                                                       i_id_order_type          => r_proc.id_order_type,
                                                       i_id_prof_created        => r_proc.id_professional,
                                                       i_id_prof_ordered_by     => r_proc.id_prof_order,
                                                       i_dt_created             => r_proc.dt_interv_prescription_tstz,
                                                       i_dt_ordered_by          => r_proc.dt_order,
                                                       o_id_co_sign             => l_co_sign,
                                                       o_id_co_sign_hist        => l_co_sign_hist,
                                                       o_error                  => l_error)
        THEN
            handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_COSIGN_TASK(' || l_lang || --
                                    ', profissional(' || r_proc.id_professional || ', ' || r_proc.id_institution || ', ' ||
                                    r_proc.id_software || '), ' || --
                                    r_proc.id_episode || ', ' || --
                                    10 || ', ' || --
                                    'NEEDS_COSIGN_ORDER' || ', ' || --
                                    r_proc.id_interv_presc_det || ', ' || --
                                    r_proc.id_interv_presc_det || ', ' || --
                                    r_proc.id_order_type || ', ' || --
                                    r_proc.id_professional || ', ' || --
                                    r_proc.id_prof_order || ', ' || --
                                    to_char(r_proc.dt_interv_prescription_tstz, l_date_format) || ', ' || --
                                    to_char(r_proc.dt_order, l_date_format) || ')',
                         i_error => l_error);
        END IF;
    
        --Update Transactional table with id_co_sign_hist
        UPDATE interv_presc_det ipd
           SET ipd.id_co_sign_order = l_co_sign_hist
         WHERE ipd.id_interv_presc_det = r_proc.id_interv_presc_det;
    
        IF r_proc.flg_co_sign = 'Y'
        THEN
            --Co-sign the task
            IF NOT pk_co_sign.set_task_co_signed(i_lang                => l_lang,
                                                 i_prof                => profissional(r_proc.id_professional,
                                                                                       r_proc.id_institution,
                                                                                       r_proc.id_software),
                                                 i_episode             => r_proc.id_episode,
                                                 i_tbl_id_co_sign      => table_number(l_co_sign),
                                                 i_id_prof_cosigned    => r_proc.id_prof_co_sign,
                                                 i_dt_cosigned         => r_proc.dt_co_sign,
                                                 i_cosign_notes        => r_proc.notes_co_sign,
                                                 i_flg_made_auth       => 'N',
                                                 o_tbl_id_co_sign_hist => l_tbl_id_co_sign_hist,
                                                 o_error               => l_error)
            THEN
                handle_error(i_msg   => 'ERROR CALLING PK_CO_SIGN.SET_TASK_CO_SIGNED(' || l_lang || --
                                        ', profissional(' || r_proc.id_professional || ', ' || r_proc.id_institution || ', ' ||
                                        r_proc.id_software || '), ' || --
                                        r_proc.id_episode || ', ' || --
                                        l_co_sign || ', ' || --
                                        r_proc.id_prof_co_sign || ', ' || --
                                        to_char(r_proc.dt_co_sign, l_date_format) || ', ' || --
                                        r_proc.notes_co_sign || ', ' || --
                                        'N' || ')',
                             i_error => l_error);
            END IF;
        END IF;
    END LOOP;
END;
/
-- CHANGE END: cristina.oliveira

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 04/05/2017 10:22
-- CHANGE REASON: [ALERT-330278] 
update interv_presc_det
set id_clinical_purpose = 501
where flg_clinical_purpose = 'N';

update interv_presc_det
set id_clinical_purpose = 502
where flg_clinical_purpose = 'S';

update interv_presc_det
set id_clinical_purpose = 508
where flg_clinical_purpose = 'P';

update interv_presc_det
set id_clinical_purpose = 504
where flg_clinical_purpose = 'R';

update interv_presc_det
set id_clinical_purpose = 503
where flg_clinical_purpose = 'T';

update interv_presc_det
set id_clinical_purpose = 0
where flg_clinical_purpose = 'O';
-- CHANGE END: Ana Matos