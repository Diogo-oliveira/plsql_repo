CREATE OR REPLACE VIEW v_health_topic_list AS
WITH tbl_prof_dep_clin_serv AS
 (SELECT *
    FROM (SELECT 0
            FROM dual
          UNION ALL
          SELECT pdcs.id_dep_clin_serv
            FROM prof_dep_clin_serv pdcs
            JOIN dep_clin_serv dcs
              ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
            JOIN department d
              ON d.id_department = dcs.id_department
           WHERE pdcs.id_professional = alert_context('i_prof_id')
             AND d.id_institution = alert_context('i_prof_institution')
             AND pdcs.flg_status = 'S'))
SELECT o_ntt.id_nurse_tea_topic,
       o_ntt.id_nurse_tea_subject,
       o_ntt.code_nurse_tea_topic,
       o_ntt.code_topic_description,
       nts.code_nurse_tea_subject,
       o_ntt.code_topic_context_help,
       alert_context('i_lang') i_lang,
       alert_context('i_prof_id') i_prof_id,
       alert_context('i_prof_institution') i_prof_institution,
       alert_context('i_prof_software') i_prof_software
  FROM nurse_tea_topic o_ntt
  JOIN nurse_tea_subject nts
    ON nts.id_nurse_tea_subject = o_ntt.id_nurse_tea_subject
 WHERE nts.flg_available = 'Y'
   AND (alert_context('i_flg_show_others') = 'N' AND o_ntt.id_nurse_tea_topic <> 1)
    OR (alert_context('i_flg_show_others') = 'Y')
   AND o_ntt.flg_available = 'Y'
   AND (alert_context('i_id_subject') IS NULL OR
       (alert_context('i_id_subject') IS NOT NULL AND alert_context('i_id_subject') = nts.id_nurse_tea_subject))
   AND EXISTS
 (SELECT nttsi.id_nurse_tea_topic
          FROM nurse_tea_top_soft_inst nttsi
         WHERE ((alert_context('i_most_frequent') = 'N' AND nttsi.flg_type = 'P') OR
               (alert_context('i_most_frequent') = 'Y' AND nttsi.flg_type = 'M' AND
               nvl(nttsi.id_dep_clin_serv, 0) IN (SELECT *
                                                      FROM tbl_prof_dep_clin_serv)))
           AND nttsi.id_nurse_tea_topic = o_ntt.id_nurse_tea_topic
           AND nttsi.flg_available = 'Y'
           AND nttsi.id_software IN (0, alert_context('i_prof_software'))
           AND nttsi.id_institution IN (0, alert_context('i_prof_institution'))
           AND nttsi.id_market IN (0, alert_context('l_id_market'))
        MINUS
        SELECT nttsi.id_nurse_tea_topic
          FROM nurse_tea_top_soft_inst nttsi
         WHERE ((alert_context('i_most_frequent') = 'N' AND nttsi.flg_type = 'P') OR
               (alert_context('i_most_frequent') = 'Y' AND nttsi.flg_type = 'M' AND
               nvl(nttsi.id_dep_clin_serv, 0) IN (SELECT *
                                                      FROM tbl_prof_dep_clin_serv)))
           AND nttsi.id_nurse_tea_topic = o_ntt.id_nurse_tea_topic
           AND nttsi.flg_available = 'N'
           AND nttsi.id_software IN (0, alert_context('i_prof_software'))
           AND nttsi.id_institution IN (0, alert_context('i_prof_institution'))
           AND nttsi.id_market IN (0, alert_context('l_id_market')));
