CREATE OR REPLACE VIEW SAEH_AFECCIONES
AS
SELECT t.clues,
       t.id_episode,
       t.dt_end_tstz,
       t.code_icd,
       id_institution,
       row_number() over(PARTITION BY t.id_episode ORDER BY decode(flg_final_type, 'P', 0, 1) ASC, dt_confirmed_tstz ASC) num_affec
  FROM (SELECT pk_adt.get_clues_code(i_id_clues => ia.id_clues, i_id_institution => NULL) clues,
               ed.id_episode,
               e.dt_end_tstz,
               d.code_icd,
               ed.flg_final_type,
               dt_confirmed_tstz,
               e.id_institution
          FROM episode e
         INNER JOIN epis_diagnosis ed
            ON ed.id_episode = e.id_episode
         INNER JOIN diagnosis d
            ON d.id_diagnosis = ed.id_diagnosis
         INNER JOIN episode e
            ON ed.id_episode = e.id_episode
         INNER JOIN institution ia
            ON e.id_institution = ia.id_institution
         WHERE ed.flg_type = 'D'
        --   AND ed.flg_final_type = 'S'
           AND e.id_epis_type = 5
           AND e.dt_end_tstz IS NOT NULL) t;
