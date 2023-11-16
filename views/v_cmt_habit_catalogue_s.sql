CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_HABIT_CATALOGUE_S AS
SELECT DISTINCT desc_habit, id_cnt_habit, rank
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_habit)
                  FROM dual) desc_habit,
               a.id_content id_cnt_habit,
               a.rank
          FROM habit a
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'HABIT.CODE_HABIT')) t
            ON t.code_translation = a.code_habit
         WHERE a.flg_available = 'N')
 WHERE desc_habit IS NOT NULL;

