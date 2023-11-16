create or replace view V_EXAMS_HAND_OFF_IE_LAST_24H as
SELECT * from v_exams_hand_off
WHERE flg_type = 'I'
AND flg_status in ('P', 'F', 'L') 
AND pk_date_utils.compare_dates_tsz(alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                       sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                       sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                    end_time,
                                    pk_date_utils.add_days_to_tstz(current_timestamp, -1)) = 'G';
