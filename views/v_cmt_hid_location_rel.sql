create or replace force view alert.v_cmt_hid_location_rel as
select "DESC_WAY","ID_CNT_WAY","DESC_HIDRICS","ID_CNT_HIDRICS","DESC_BODY_PART","ID_CNT_BODY_PART","DESC_BODY_SIDE","ID_CNT_BODY_SIDE","RANK"
  from (select (select    pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), d.code_way) from dual ) desc_way,
               d.id_content id_cnt_way,
             (select  pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), c.code_hidrics)  from dual ) desc_hidrics,
               c.id_content id_cnt_hidrics,
             (select  pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), e.code_body_part)  from dual ) desc_body_part,
               e.id_content id_cnt_body_part,
                 (select  pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), f.code_body_side)  from dual ) desc_body_side,
               f.id_content id_cnt_body_side,
                b.rank
          from alert.hidrics_location a
         inner join alert.hidrics_location_rel b
            on b.id_hidrics_location = a.id_hidrics_location
         inner join alert.hidrics c
            on c.id_hidrics = b.id_hidrics
         inner join alert.way d
            on d.id_way = b.id_way
            inner join alert.body_part e on e.id_body_part=a.id_body_part
           left outer join alert.body_side f on f.id_body_side=a.id_body_side
         where b.id_institution  = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           and b.flg_available = 'Y'
           and a.flg_available = 'Y'
           and e.flg_available='Y'
           AND C.FLG_AVAILABLE = 'Y'
           and d.flg_available = 'Y') res
 where desc_way is not null
   and desc_hidrics is not null
   and desc_body_part is not null
 order by 1, 3, 5;

