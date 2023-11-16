CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_HABIT_CHARACT_REL AS
SELECT "DESC_HABIT", "ID_CNT_HABIT", "DESC_HAB_CHARACTERIZATION", "ID_CNT_HAB_CHARACTERIZATION"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_habit)
                  FROM dual) desc_habit,
               a.id_content id_cnt_habit,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      c.code_habit_characterization)
                  FROM dual) desc_hab_characterization,
               c.id_content id_cnt_hab_characterization
          FROM habit a
         INNER JOIN habit_charact_relation b
            ON b.id_habit = a.id_habit
         INNER JOIN habit_characterization c
            ON c.id_habit_characterization = b.id_habit_characterization
         WHERE a.flg_available = 'Y'
           AND b.flg_available = 'Y'
           AND c.flg_available = 'Y'
           AND a.id_habit IN (SELECT b.id_habit
                                FROM habit_inst b
                               WHERE b.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')))
 WHERE desc_habit IS NOT NULL
   AND desc_hab_characterization IS NOT NULL;

