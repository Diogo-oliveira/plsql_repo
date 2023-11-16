create or replace view alert.v_cmt_diet_type as
select pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                  'ID_LANGUAGE'),
                                      a.code_diet_type) desc_diet_type,
       a.id_diet_type,
       a.rank
  from diet_type a
 where flg_available = 'Y'
 order by 1;
