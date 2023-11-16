CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_HABIT_CATALOGUE AS
SELECT DISTINCT desc_habit, id_cnt_habit, rank
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_habit)
                  FROM dual) desc_habit,
               a.id_content id_cnt_habit,
               a.rank
          FROM habit a
         WHERE a.flg_available = 'Y')
 WHERE desc_habit IS NOT NULL;

