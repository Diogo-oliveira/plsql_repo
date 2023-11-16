CREATE OR REPLACE VIEW v_pn_tasks AS
SELECT CASE
            WHEN t.id_tl_task IN (17, 15) THEN
             t.dt_execution
            WHEN t.id_tl_task IN (61) THEN
             t.dt_req
            WHEN t.id_tl_task IN (86, 125) THEN
             nvl(t.dt_req, t.dt_last_update)
            WHEN t.id_tl_task IN (4, 5, 101) THEN
             t.dt_req
            ELSE
             nvl(t.dt_execution, t.dt_req)
        END dt_import,
       CASE
            WHEN t.id_tl_task IN (4, 101, 8, 17, 130, 131) THEN
             coalesce(t.dt_execution, t.dt_last_execution, t.dt_req)
            WHEN t.id_tl_task IN (86, 125) THEN
             nvl(t.dt_req, t.dt_last_update)
            ELSE
             t.dt_req
        END dt_task,
       t.id_prof_req,
       t.id_task_refid id_task,
       t.id_tl_task,
       t.code_description,
       t.id_group_import,
       t.code_desc_group,
       t.id_sub_group_import,
       t.code_desc_sub_group,
       t.dt_execution,
       t.id_doc_area,
       t.id_ref_group,
       t.id_patient,
       t.id_visit,
       t.id_episode,
       t.id_task_refid,
       t.flg_sos,
       CASE
            WHEN t.id_tl_task = 19 THEN
             nvl(t.dt_begin, t.dt_req)
            ELSE
             t.dt_begin
        END dt_begin,
       t.dt_end,
       t.id_task_aggregator,
       t.universal_desc_clob,
       CASE
            WHEN t.id_tl_task = 96 THEN
             NULL
            ELSE
             t.id_parent_task_refid
        END id_parent_task_refid,
       CASE
            WHEN t.id_tl_task = 96 THEN
             t.id_parent_task_refid
            ELSE
             NULL
        END id_parent_med,
       t.flg_status_req,
       t.flg_ongoing,
       t.flg_normal,
       t.id_prof_exec,
       pk_prof_utils.get_category(NULL,
                                  profissional(nvl(t.id_prof_exec, t.id_prof_req),
                                               pk_episode.get_epis_institution_id(NULL, NULL, t.id_episode),
                                               NULL)) prof_cat,
       t.flg_has_comments flg_has_notes,
       t.dt_last_update,
       t.id_parent_comments,
       t.dt_last_execution,
       CASE
            WHEN t.id_tl_task IN (4, 101, 8, 17, 130, 131) THEN
             CASE
                 WHEN nvl(t.dt_execution, t.dt_last_execution) IS NULL THEN
                  -1
                 ELSE
                  t.rank
             END
            ELSE
             t.rank
        END rank,
       --t.rank
       t.id_prof_review,
       t.dt_review,
       t.code_status,
       t.id_task_notes,
       t.id_sample_type,
       t.code_desc_sample_type,
       t.flg_show_method,
       t.dt_dg_last_update,
       t.flg_technical,
       t.flg_relevant,
       t.flg_outdated,
       t.id_institution,
       t.flg_stat,
       t.id_task_related,
       t.flg_type,
       t.dt_result dt_result,
       t.dt_req,
       t.code_desc_group_parent,
       t.instructions_hash,
       CASE
            WHEN t.id_episode IS NOT NULL THEN
             (SELECT id_prev_episode
                FROM episode e
               WHERE e.id_episode = t.id_episode)
            ELSE
             NULL
        END id_prev_episode
  FROM task_timeline_ea t;
