create or replace view V_PROC_HAND_OFF_LAST_24H as
select * from v_proc_hand_off
where flg_status in ('F', 'I') 
AND  pk_date_utils.compare_dates_tsz(alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                        sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                        sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                     nvl(dt_plan_tstz, dt_begin_tstz),
                                     pk_date_utils.add_days_to_tstz(current_timestamp, -1)) = 'G';


create or replace view V_PROC_HAND_OFF_LAST_24H as
select * from v_proc_hand_off
where flg_status in ('F') 
AND  pk_date_utils.compare_dates_tsz(alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                        sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                        sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                     nvl(dt_plan_tstz, dt_begin_tstz),
                                     pk_date_utils.add_days_to_tstz(current_timestamp, -1)) = 'G';
