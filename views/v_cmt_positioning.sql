create or replace force view alert.v_cmt_positioning as
select "DESC_POSITIONING","ID_CNT_POSITIONING","RANK"
  from (select (select pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                                  'ID_LANGUAGE'), a.code_positioning)
                  from dual) desc_positioning,
               id_content id_cnt_positioning,
               rank
          from alert.positioning a
         where a.flg_available = 'Y')
 WHERE desc_positioning is not null;

