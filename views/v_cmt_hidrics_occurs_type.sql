create or replace force view alert.v_cmt_hidrics_occurs_type as
select "DESC_HIDRICS_OCCURS_TYPE","ID_CNT_HIDRICS_OCCURS_TYPE"
  from (select (select pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), a.code_hidrics_occurs_type)
                  from dual) desc_hidrics_occurs_type,
              a.id_content id_cnt_hidrics_occurs_type
          from alert.hidrics_occurs_type a
         where a.flg_available = 'Y'
         and a.id_hidrics_occurs_type >0)
 where desc_hidrics_occurs_type is not null
 order by 1;

