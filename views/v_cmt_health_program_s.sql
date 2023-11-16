create or replace force view alert.v_cmt_health_program_s as
select "DESC_HEALTH_PROGRAM",
       "ID_CNT_HEALTH_PROGRAM",
       "RANK"
  from (select (select pk_translation.get_translation(sys_context('ALERT_CONTEXT',
                                                                  'ID_LANGUAGE'),
                                                      a.code_HEALTH_PROGRAM)
                  from dual) desc_HEALTH_PROGRAM,
               a.id_content id_cnt_HEALTH_PROGRAM,
               a.rank
          from HEALTH_PROGRAM a
           inner join table(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'HEALTH_PROGRAM.CODE_HEALTH_PROGRAM')) t
    on t.code_translation = a.code_HEALTH_PROGRAM
           where a.id_HEALTH_PROGRAM not in
               (select c.id_HEALTH_PROGRAM
                  from health_program_soft_inst c
                 where c.id_institution =
                       sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   and c.id_software =
                       sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   and c.flg_active = 'Y'))
 where desc_HEALTH_PROGRAM is not null
 order by 1, 2;

