create or replace force view alert.v_cmt_hidrics_device as
select  DESC_HIDRICS_DEVICE , ID_CNT_HIDRICS_DEVICE , FLG_FREE_TXT
  from (select (select pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), a.code_hidrics_device)
                  from dual) desc_hidrics_device,
               a.id_content id_cnt_hidrics_device  ,a.flg_free_txt
          from alert.hidrics_device a
         where a.flg_available = 'Y'
         and a.id_hidrics_device >0)
 where desc_hidrics_device is not null
 order by 1;

