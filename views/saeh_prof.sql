CREATE OR REPLACE VIEW SAEH_PROF AS
SELECT e.id_episode,
       pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => ia.id_institution) clues,
       p.num_order AS cedula,
       (nvl2(p.last_name, p.last_name || ', ', NULL) || nvl2(p.middle_name, p.middle_name || ', ', NULL) ||
       p.first_name) AS nombremed
  FROM episode e
  LEFT JOIN discharge d
    ON d.id_episode = e.id_episode
 INNER JOIN visit v
    ON e.id_visit = v.id_visit
 INNER JOIN institution ia
    ON ia.id_institution = v.id_institution
  LEFT JOIN epis_prof_resp ep
    ON ep.id_episode = e.id_episode
  LEFT JOIN professional p
    ON ep.id_prof_comp = p.id_professional
 WHERE e.dt_end_tstz IS NOT NULL
   AND ep.flg_type = 'D'
   AND ep.flg_status != 'C'
   AND d.flg_status IN ('A', 'P')
   AND pk_prof_utils.get_category(17, profissional(p.id_professional, e.id_institution, 11)) = 'D'
   AND e.id_epis_type = 5;
