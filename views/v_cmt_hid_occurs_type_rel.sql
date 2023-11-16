create or replace force view alert.v_cmt_hid_occurs_type_rel as
select  "DESC_HIDRICS","ID_CNT_HIDRICS","DESC_HID_OCCURS_TYPE","ID_CNT_HID_OCCURS_TYPE","RANK"
  from (select
             (select  pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), c.code_hidrics)  from dual ) desc_hidrics,
               c.id_content id_cnt_hidrics,
             (select  pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), a.code_hidrics_occurs_type)  from dual ) desc_hid_occurs_type,
               a.id_content id_cnt_hid_occurs_type,b.rank
          from alert.hidrics_occurs_type a
         inner join alert.hidrics_occurs_type_rel b
            on b.id_hidrics_occurs_type = a.id_hidrics_occurs_type
         inner join alert.hidrics c
            on c.id_hidrics = b.id_hidrics
         where b.id_institution  = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           and b.flg_available = 'Y'
           and a.flg_available = 'Y'
           AND C.FLG_AVAILABLE = 'Y' ) res
 where  desc_hidrics is not null
   and desc_hid_occurs_type is not null
 order by 1, 3;

