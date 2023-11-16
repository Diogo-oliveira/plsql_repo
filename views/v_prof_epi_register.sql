CREATE OR REPLACE VIEW v_prof_epi_register AS
SELECT t.id_episode, t.id_professional, t.dt_creation_tstz
  FROM (SELECT ti.id_episode,
               ti.id_professional,
               ti.dt_creation_tstz,
               row_number() over(PARTITION BY ti.id_episode ORDER BY ti.dt_creation_tstz DESC) rn
          FROM ti_log ti
         WHERE ti.flg_type = 'SH'
           AND ti.flg_status = 'A') t
 WHERE t.rn = 1;
