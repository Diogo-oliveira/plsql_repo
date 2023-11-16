CREATE OR REPLACE VIEW SAEH_OBSTRET
AS
SELECT clues,
       folio,
       egresso,
       gestas,
       partos,
       abortos,
       flg_extraction hayprod,
       tipaten,
       gestac,
       producto,
       planfam,
       id_institution,
       id_patient
  FROM (SELECT pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => ia.id_institution) clues,
               e.id_episode folio,
               pp.id_patient,
               e.id_institution,
               e.dt_end_tstz egresso,
               pp.num_gestations gestas,
               pp.num_births partos,
               pp.num_abortions abortos,
               pp.flg_status,
               pp.id_pat_pregnancy,
               pp.flg_extraction,
               CASE
                    WHEN pp.flg_preg_out_type = 'B' THEN
                     2
                    WHEN pp.flg_preg_out_type = 'AB' THEN
                     1
                    ELSE
                     NULL
                END tipaten,
               pk_pregnancy_core.get_preg_weeks_unk(profissional(NULL, e.id_institution, 11),
                                                    pp.dt_init_pregnancy,
                                                    pp.dt_intervention,
                                                    coalesce(pp.num_gest_weeks_us,
                                                             pp.num_gest_weeks_exam,
                                                             pp.num_gest_weeks),
                                                    pp.flg_gest_weeks,
                                                    pp.flg_gest_weeks_exam,
                                                    pp.flg_gest_weeks_us) gestac,
               CASE
                    WHEN pp.n_children = 1 THEN
                     'N'
                    WHEN pp.n_children > 1 THEN
                     'Y'
                END producto,
               (SELECT pk_multichoice.get_id_content(ppct.id_contrac_type)
                  FROM pat_preg_cont_type ppct
                 WHERE ppct.id_pat_pregnancy = pp.id_pat_pregnancy
                   AND rownum = 1) planfam
          FROM (SELECT pp.id_pat_pregnancy,
                       pp.id_patient,
                       e.id_episode,
                       e.id_visit,
                       pp.flg_status,
                       pp.n_children,
                       pp.num_gestations,
                       pp.num_abortions,
                       pp.num_births,
                       pp.flg_extraction,
                       pp.dt_init_pregnancy,
                       pp.dt_intervention,
                       pp.num_gest_weeks_us,
                       pp.num_gest_weeks_exam,
                       pp.num_gest_weeks,
                       pp.flg_preg_out_type,
                       pp.flg_gest_weeks,
                       pp.flg_gest_weeks_exam,
                       pp.flg_gest_weeks_us
                  FROM pat_pregnancy pp
                 INNER JOIN episode e
                    ON pp.id_episode = e.id_episode
                 WHERE pp.flg_type <> 'R'
                    AND ((pp.flg_status NOT IN ('A','C') and pp.flg_extraction='Y') OR (pp.flg_status NOT IN ('C') and pp.flg_extraction='N'))
                   AND e.dt_end_tstz IS NOT NULL
                   AND NOT EXISTS (SELECT 1
                          FROM epis_doc_delivery ed
                         WHERE ed.id_pat_pregnancy = pp.id_pat_pregnancy)
                UNION ALL
                SELECT DISTINCT pp.id_pat_pregnancy,
                                pp.id_patient,
                                e.id_episode,
                                e.id_visit,
                                pp.flg_status,
                                pp.n_children,
                                pp.num_gestations,
                                pp.num_abortions,
                                pp.num_births,
                                pp.flg_extraction,
                                pp.dt_init_pregnancy,
                                pp.dt_intervention,
                                pp.num_gest_weeks_us,
                                pp.num_gest_weeks_exam,
                                pp.num_gest_weeks,
                                pp.flg_preg_out_type,
                                pp.flg_gest_weeks,
                                pp.flg_gest_weeks_exam,
                                pp.flg_gest_weeks_us
                  FROM pat_pregnancy pp
                  JOIN epis_doc_delivery edo
                    ON pp.id_pat_pregnancy = edo.id_pat_pregnancy
                  JOIN epis_documentation ed
                    ON edo.id_epis_documentation = ed.id_epis_documentation
                   AND ed.id_doc_area = 1048
                 INNER JOIN episode e
                    ON ed.id_episode = e.id_episode
                 WHERE pp.flg_type <> 'R'
                   AND ((pp.flg_status NOT IN ('A','C') and pp.flg_extraction='Y') OR (pp.flg_status NOT IN ('C') and pp.flg_extraction='N'))
                   AND e.dt_end_tstz IS NOT NULL
                ) pp
         INNER JOIN episode e
            ON pp.id_visit = e.id_visit
         INNER JOIN institution ia
            ON e.id_institution = ia.id_institution
           AND e.id_epis_type = 5);
