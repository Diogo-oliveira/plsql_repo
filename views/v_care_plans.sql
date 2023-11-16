CREATE OR REPLACE VIEW V_CARE_PLANS AS
SELECT cpt.id_care_plan_task,
       cp.id_care_plan,
       cp.name,
       pk_care_plans.get_desc_translation(l.id_language,
                                          alert.profissional(p.id_professional, i.id_institution, s.id_software),
                                          cpt.id_item,
                                          cpt.id_task_type) desc_task,
       pk_care_plans.get_string_task(l.id_language,
                                     alert.profissional(p.id_professional, i.id_institution, s.id_software),
                                     pk_task_type.get_task_type_flg(l.id_language, nvl(cptr.id_task_type, cpt.id_task_type)),
                                     nvl(cptr.flg_status,cpt.flg_status),
                                     NULL,
                                     pk_date_utils.date_send_tsz(l.id_language,
                                                                 cpt.dt_begin,
                                                                 alert.profissional(p.id_professional,
                                                                                    i.id_institution,
                                                                                    s.id_software)),
                                     nvl(cptr.id_req, cpt.id_care_plan_task),
                                     'CARE_PLAN_TASK') status,
       l.id_language i_lang,
       p.id_professional i_prof_id,
       i.id_institution i_prof_institution,
       s.id_software i_prof_software
  FROM care_plan cp,
       care_plan_task_link cptl,
       care_plan_task cpt,
       (SELECT *
          FROM care_plan_task_req r
         WHERE r.order_num = (SELECT MIN(order_num)
                                            FROM care_plan_task_req req
                                           WHERE req.id_care_plan_task = r.id_care_plan_task
                                             AND req.FLG_STATUS not in ('R', --pk_care_plans.g_ordered
                                                                        'C', --pk_care_plans.g_canceled,
                                                                        'I', --pk_care_plans.g_interrupted,
                                                                        'S', --pk_care_plans.g_suspended,
                                                                        'F'  /*pk_care_plans.g_finished*/))) cptr,
       LANGUAGE l,
       professional p,
       institution i,
       software s
 WHERE cp.id_care_plan = cptl.id_care_plan
   AND cptl.id_care_plan_task = cpt.id_care_plan_task
   AND cpt.id_care_plan_task = cptr.id_care_plan_task(+);
