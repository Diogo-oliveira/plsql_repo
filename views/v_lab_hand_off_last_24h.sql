create or replace view V_LAB_HAND_OFF_LAST_24h as
SELECT * FROM v_lab_hand_off
WHERE flg_status in ('F', 'L') 
AND pk_date_utils.compare_dates_tsz(alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                       sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                       sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                    dt_analysis_result_tstz,
                                    pk_date_utils.add_days_to_tstz(current_timestamp, -1)) = 'G';
