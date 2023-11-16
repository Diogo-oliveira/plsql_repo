CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_HABIT AS
SELECT "DESC_HABIT", "ID_CNT_HABIT", "RANK"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_habit)
                  FROM dual) desc_habit,
               a.id_content id_cnt_habit,
               a.rank
          FROM habit a
         WHERE a.flg_available = 'Y'
           AND a.id_habit IN (SELECT b.id_habit
                                FROM habit_inst b
                               WHERE b.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')))
 WHERE desc_habit IS NOT NULL;

