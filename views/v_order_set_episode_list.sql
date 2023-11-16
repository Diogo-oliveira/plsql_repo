CREATE OR REPLACE VIEW V_ORDER_SET_EPISODE_LIST AS
SELECT odst_proc.id_order_set_process,
       odst_proc_tsk.id_order_set_process_task,
       odst_proc_tsk.id_task_type,
       odst_proc_tsk.flg_schedule,
       odst_proc_tsk.id_request,
       odst_proc_tsk.flg_status,
       odst_proc_tsk_dep.id_order_set_proc_task_to,
       tsk_type.id_task_type_parent,
       odst.title,
       odst.id_order_set,
       (SELECT pk_order_sets.get_task_instructions_desc(alert_context('i_lang'),
                                                        profissional(alert_context('i_prof_id'),
                                                                     alert_context('i_prof_institution'),
                                                                     alert_context('i_prof_software')),
                                                        table_number(odst_proc_tsk.id_order_set_process_task),
                                                        'Y')
          FROM dual) task_instruct,
       (SELECT pk_order_sets.get_odst_proc_task_group_desc(alert_context('i_lang'),
                                                           profissional(alert_context('i_prof_id'),
                                                                        alert_context('i_prof_institution'),
                                                                        alert_context('i_prof_software')),
                                                           odst_proc_tsk.id_order_set_process_task)
          FROM dual) task_group_desc,
       (SELECT pk_order_sets.get_odst_proc_task_group_rank(alert_context('i_lang'),
                                                           profissional(alert_context('i_prof_id'),
                                                                        alert_context('i_prof_institution'),
                                                                        alert_context('i_prof_software')),
                                                           odst_proc_tsk.id_order_set_process_task)
          FROM dual) task_group_rank,
       pk_order_sets.get_task_rank(table_number(alert_context('l_tasks_rank')), odst_proc_tsk.id_order_set_process_task) rank,
       (SELECT pk_order_sets.get_task_desc(alert_context('i_lang'),
                                           profissional(alert_context('i_prof_id'),
                                                        alert_context('i_prof_institution'),
                                                        alert_context('i_prof_software')),
                                           odst_proc_tsk.id_order_set_process_task,
                                           odst_proc_tsk.id_task_type,
                                           'Y',
                                           'Y',
                                           'E',
                                           'N',
                                           'Y')
          FROM dual) /*|| chr(10) ||
       pk_order_sets_pedro.get_rank_dep_desc(alert_context('i_lang'),
                                             profissional(alert_context('i_prof_id'),
                                                          alert_context('i_prof_institution'),
                                                          alert_context('i_prof_software')),
                                             alert_context('i_patient'),
                                             odst_proc_tsk.id_order_set_process_task,
                                             odst_proc_tsk.flg_schedule)*/ task_desc,
       
       alert_context('i_lang') i_lang,
       alert_context('i_prof_id') i_prof_id,
       alert_context('i_prof_institution') i_prof_institution,
       alert_context('i_prof_software') i_prof_software
  FROM order_set odst
 INNER JOIN order_set_process odst_proc
    ON (odst.id_order_set = odst_proc.id_order_set)
 INNER JOIN order_set_process_task odst_proc_tsk
    ON (odst_proc.id_order_set_process = odst_proc_tsk.id_order_set_process)
 INNER JOIN task_type tsk_type
    ON (odst_proc_tsk.id_task_type = tsk_type.id_task_type)
  LEFT JOIN analysis_req_det ard
    ON ard.id_analysis_req_det = odst_proc_tsk.id_request
   AND odst_proc_tsk.id_task_type = 11
  LEFT OUTER JOIN order_set_process_task_depend odst_proc_tsk_dep
    ON (odst_proc_tsk_dep.id_order_set_proc_task_to = odst_proc_tsk.id_order_set_process_task AND
       odst_proc_tsk_dep.id_order_set_process = odst_proc.id_order_set_process AND
       odst_proc_tsk_dep.id_relationship_type = 1 AND
       odst_proc_tsk_dep.id_order_set_proc_task_from NOT IN (to_number(-1), to_number(-2)))
 WHERE odst_proc.id_patient = alert_context('i_patient')
   AND pk_episode.get_id_visit(alert_context('i_episode')) = pk_episode.get_id_visit(odst_proc.id_episode)
   AND odst_proc.flg_status != 'T'
   AND odst_proc_tsk.flg_status != 'T'
   AND odst_proc_tsk.flg_discard_type = 'N'
   AND ((odst_proc_tsk.id_task_type = 11 AND (SELECT pk_lab_tests_api_db.get_lab_test_access_permission(alert_context('i_lang'),
                                                                                                        profissional(alert_context('i_prof_id'),
                                                                                                                     alert_context('i_prof_institution'),
                                                                                                                     alert_context('i_prof_software')),
                                                                                                        ard.id_analysis)
                                                FROM dual) = 'Y') OR (odst_proc_tsk.id_task_type <> 11));
