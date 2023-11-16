create or replace force view alert.v_cmt_hidrics_interval as
select "DESC_HIDRICS_INTERVAL","ID_HIDRICS_INTERVAL","RANK","FLG_TYPE","INTERVAL_MINUTES"
  from (select (select pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), a.code_hidrics_interval)
                  from dual) desc_hidrics_interval,
              a.id_hidrics_interval,  a.rank,a.flg_type,a.interval_minutes
          from alert.hidrics_interval a
         where a.flg_available = 'Y'
         and a.id_hidrics_interval >0)
 where desc_hidrics_interval is not null
 order by 1;

