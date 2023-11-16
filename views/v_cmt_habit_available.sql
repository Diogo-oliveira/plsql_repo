CREATE OR REPLACE VIEW V_CMT_HABIT_AVAILABLE AS
SELECT DISTINCT desc_habit, id_cnt_habit
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_habit)
                  FROM dual) desc_habit,
               a.id_content id_cnt_habit
          FROM habit a
          JOIN habit_inst b
            ON a.id_habit = b.id_habit
           AND b.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
         WHERE a.flg_available = 'Y')
 WHERE desc_habit IS NOT NULL
 ORDER BY 1;
