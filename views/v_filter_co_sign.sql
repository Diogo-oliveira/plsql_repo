create or replace view v_filter_co_sign as
  select
  alert_context('ID_LANGUAGE')	l_lang
  ,profissional( alert_context('PROF_ID'),  alert_context('PROF_ID_INSTITUTION'), alert_context('PROF_ID_SOFTWARE') ) lprof
  ,tcs.co_sign_notes
  ,tcs.desc_instructions
  ,tcs.desc_order
  ,tcs.dt_ordered_by
  ,tcs.desc_order_type
  ,tcs.desc_prof_ordered_by
  ,tcs.desc_status
  ,tcs.desc_task_action
  ,tcs.desc_task_type
  ,tcs.dt_exec_date_sort
  ,tcs.flg_has_cosign
  ,tcs.flg_has_notes
  ,tcs.flg_status
  ,tcs.icon_status
  ,tcs.icon_task_type
  ,tcs.id_co_sign
  ,tcs.id_episode
  ,tcs.id_prof_ordered_by
  ,tcs.id_task_group
  ,tcs.id_task_type
  , first_value(tcs.dt_ordered_by) over(PARTITION BY tcs.id_task_group ORDER BY tcs.dt_ordered_by ASC) dt_ord_first_group
   FROM TABLE(pk_co_sign.tf_co_sign_tasks_info(
         i_lang   => alert_context('ID_LANGUAGE')
        ,i_prof   => profissional( alert_context('PROF_ID'),  alert_context('PROF_ID_INSTITUTION'), alert_context('PROF_ID_SOFTWARE') )
        ,i_episode   => alert_context('ID_EPISODE')
        ,i_flg_with_desc => 'Y'
        ,i_tbl_status    => table_varchar('P','CS')
        ,i_flg_filter    => 'Y'
        )
       ) tcs
;