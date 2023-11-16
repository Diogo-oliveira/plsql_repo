
CREATE OR REPLACE VIEW V_MCDT_NATURE AS
SELECT t.id_mcdt,
       t.flg_mcdt,
       decode(nature_count,
              1,
              (SELECT flg_nature
                 FROM mcdt_nature mn
                WHERE mn.id_mcdt = t.id_mcdt
                  AND mn.flg_mcdt = t.flg_mcdt),
              0,
              NULL,
              'Z') flg_nature,
       t.flg_available
  FROM (SELECT id_mcdt, flg_mcdt, flg_available, COUNT(flg_nature) nature_count
          FROM mcdt_nature
         GROUP BY id_mcdt, flg_mcdt, flg_available) t;
