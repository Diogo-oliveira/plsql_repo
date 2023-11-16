CREATE OR REPLACE VIEW V_POSITIONING_SEARCH AS
SELECT p.id_positioning,
       p.code_positioning,
       pis.rank,
       sys_context('ALERT_CONTEXT', 'l_lang') i_lang,
       sys_context('ALERT_CONTEXT', 'l_prof_id') i_prof_id,
       sys_context('ALERT_CONTEXT', 'l_prof_institution') i_prof_institution,
       sys_context('ALERT_CONTEXT', 'l_prof_software') i_prof_software
  FROM positioning p
  JOIN positioning_instit_soft pis
    ON pis.id_positioning = p.id_positioning
   AND pis.id_institution = sys_context('ALERT_CONTEXT', 'l_prof_institution')
   AND pis.id_software = sys_context('ALERT_CONTEXT', 'l_prof_software')
   AND pis.posit_type = 1
 WHERE p.flg_available = 'Y'
   AND sys_context('ALERT_CONTEXT', 'l_sr_parent') IS NULL
   AND pis.flg_available = 'Y'
UNION ALL
SELECT t.id_positioning,
       t.code_positioning,
       t.rank,
       sys_context('ALERT_CONTEXT', 'l_lang') i_lang,
       sys_context('ALERT_CONTEXT', 'l_prof_id') i_prof_id,
       sys_context('ALERT_CONTEXT', 'l_prof_institution') i_prof_institution,
       sys_context('ALERT_CONTEXT', 'l_prof_software') i_prof_software
  FROM (SELECT p.id_positioning,
               p.code_positioning,
               pis.rank,
               rank() over(ORDER BY pis.id_institution DESC, pis.id_software DESC) origin_rank
          FROM positioning p
          JOIN positioning_instit_soft pis
            ON pis.id_positioning = p.id_positioning
           AND pis.id_institution = sys_context('ALERT_CONTEXT', 'l_prof_institution')
           AND pis.id_software = sys_context('ALERT_CONTEXT', 'l_prof_software')
         WHERE p.flg_available = 'Y'
           AND pis.posit_type IS NOT NULL
           AND pis.posit_type = sys_context('ALERT_CONTEXT', 'l_sr_parent')
           AND pis.flg_available = 'Y') t
 WHERE t.origin_rank = 1;