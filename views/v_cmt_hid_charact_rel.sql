create or replace force view alert.v_cmt_hid_charact_rel as
select "DESC_WAY","ID_CNT_WAY","DESC_HIDRICS","ID_CNT_HIDRICS","DESC_HID_CHARACTERIZATION","ID_CNT_HID_CHARACTERIZATION","RANK"
  from (select (select    pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), d.code_way) from dual ) desc_way,
               d.id_content id_cnt_way,
             (select  pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), c.code_hidrics)  from dual ) desc_hidrics,
               c.id_content id_cnt_hidrics,
             (select  pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), a.code_hidrics_charact)  from dual ) desc_hid_characterization,
               a.id_content id_cnt_hid_characterization,b.rank
          from alert.hidrics_charact a
         inner join alert.hidrics_charact_rel b
            on b.id_hidrics_charact = a.id_hidrics_charact
         inner join alert.hidrics c
            on c.id_hidrics = b.id_hidrics
         inner join alert.way d
            on d.id_way = b.id_way
         where b.id_institution  = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           and b.flg_available = 'Y'
           and a.flg_available = 'Y'
           AND C.FLG_AVAILABLE = 'Y'
           and d.flg_available = 'Y') res
 where desc_way is not null
   and desc_hidrics is not null
   and desc_hid_characterization is not null
 order by 1, 3, 5;

