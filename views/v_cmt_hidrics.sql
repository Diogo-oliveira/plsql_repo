create or replace force view alert.v_cmt_hidrics as
select "DESC_HIDRICS","ID_CNT_HIDRICS","FLG_TYPE","FLG_FREE_TXT","FLG_NR_TIMES","DESC_UNIT_MEASURE","ID_UNIT_MEASURE","GENDER","AGE_MAX","AGE_MIN","RANK"
  from (select (select pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'), a.code_hidrics)
                  from dual) desc_hidrics,
               a.id_content id_cnt_hidrics,
               a.flg_type,
               flg_free_txt,
               flg_nr_times,
           (select    pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                               'ID_LANGUAGE'),b.code_unit_measure) from dual) desc_unit_measure,
               a.id_unit_measure,
               flg_gender gender,
               age_max,
               age_min,
               rank
          from alert.hidrics a left join alert.unit_measure b on b.id_unit_measure=a.id_unit_measure
         where a.flg_available = 'Y'
         and a.id_hidrics >0)
 where desc_hidrics is not null
 order by 1;

