CREATE OR REPLACE VIEW v_tech_oth_sched_req_02 AS
SELECT NULL sel_type,
                NULL event_type,
                NULL id_event_type,
                                            cs.id_patient,
                                            NULL age,
                                            NULL num_clin_record,
                                            NULL id_episode,
                                            NULL id_dept,
                                            NULL id_clinical_service,
                                            NULL id_professional,
                                            NULL id_exam_cat,
                                            NULL id_exam,
                                            cs.dt_suggest_end dt_schedule_tstz,
                                            NULL notes,
                                            cs.dt_suggest_begin dt_begin_tstz,
                                            NULL id_exam_req,
                                            NULL id_exam_req_det,
                                            cs.flg_status flg_status_req_det,
                                            NULL dt_req_tstz,
                                            NULL id_prof_req,
                                            cs.id_inst_last_update id_institution,
                                            NULL id_schedule,
                                            NULL flg_req_origin_module,
                                            NULL gender,
                                            NULL name,
                                            NULL id_room,
																						 cs.comb_name,
																						 cs.id_combination_spec,
																						 NULL id_combination_events,
																						 NULL rank,
																						 cs.dt_suggest_begin,
																						 cs.flg_single_visit
FROM combination_spec cs
             WHERE cs.id_combination_spec IN (SELECT /*+ opt_estimate(TABLE t1 rows = 1) */
                                        DISTINCT ce.id_combination_spec
                                          FROM v_tech_oth_sched_req_00 t1 
																					   inner join combination_events ce on ce.id_future_event_type = t1.id_event_type
                                         WHERE  ce.id_event = t1.id_exam_req_det
                                           AND ce.flg_status = 'A')
             AND cs.flg_status = 'A';
