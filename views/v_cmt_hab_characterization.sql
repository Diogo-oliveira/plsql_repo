CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_HAB_CHARACTERIZATION AS
SELECT "DESC_HAB_CHARACTERIZATION", "ID_CNT_HAB_CHARACTERIZATION"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      a.code_habit_characterization)
                  FROM dual) desc_hab_characterization,
               a.id_content id_cnt_hab_characterization
          FROM habit_characterization a
         WHERE a.flg_available = 'Y')
 WHERE desc_hab_characterization IS NOT NULL;

