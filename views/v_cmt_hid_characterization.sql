create or replace force view alert.v_cmt_hid_characterization as
select "DESC_HID_CHARACTERIZATION","ID_CNT_HID_CHARACTERIZATION"
  from (select (select pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), a.code_hidrics_charact)
                  from dual) desc_hid_characterization,
               a.id_content id_cnt_hid_characterization
          from alert.hidrics_charact a
         where a.flg_available = 'Y'
         and a.id_hidrics_charact >0)
 where desc_hid_characterization is not null
 order by 1;

