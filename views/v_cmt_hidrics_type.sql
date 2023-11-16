create or replace force view alert.v_cmt_hidrics_type as
select "DESC_HIDRICS_TYPE","ID_CNT_HIDRICS_TYPE","FLG_TI_TYPE","ID_CNT_HIDRICS_TYPE_PRT"
  from (select (select pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                                  'ID_LANGUAGE'),
                                                      a.code_hidrics_type)
                  from dual) desc_hidrics_type,
               a.id_content id_cnt_hidrics_type,
               a.flg_ti_type,
               (select b.id_content
                  from hidrics_type b
                 where b.id_hidrics_type = a.id_parent) id_cnt_hidrics_type_prt
          from alert.hidrics_type a
         where a.flg_available = 'Y'
           and a.id_hidrics_type > 0)
 where desc_hidrics_type is not null
 order by 1;

