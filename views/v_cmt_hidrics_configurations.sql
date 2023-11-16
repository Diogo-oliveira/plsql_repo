create or replace force view alert.v_cmt_hidrics_configurations as
select "DESC_HIDRICS_INTERVAL","ID_HIDRICS_INTERVAL","NEXT_BALANCE","MAX_INTAKE_WARN_PERCENTAGE"
  from (select (select pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), a.code_hidrics_interval)
                  from dual) desc_hidrics_interval,
              a.id_hidrics_interval,  b.dt_def_next_balance next_balance ,b.almost_max_int max_intake_warn_percentage
          from alert.hidrics_interval a
          inner join hidrics_configurations b
          on b.id_hidrics_interval=a.id_hidrics_interval
         where a.flg_available = 'Y'
         and b.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           and a.flg_available = 'Y'
         and a.id_hidrics_interval >0)
 where desc_hidrics_interval is not null
 order by 1;

