CREATE OR REPLACE VIEW V_FIND_PROFESSIONAL AS
SELECT p.id_professional, p.name, p.gender, p.dt_birth, p.num_order, p.id_speciality, fsu.desc_user
  FROM professional p
  INNER JOIN finger_db.sys_user fsu
    ON (fsu.id_user = p.id_professional)
 WHERE nvl(p.flg_prof_test, 'N') = 'N';

 
CREATE OR REPLACE VIEW V_FIND_PROFESSIONAL AS
SELECT p.id_professional, p.name, p.gender, p.dt_birth, p.num_order, p.id_speciality, fsu.desc_user
  FROM professional p
  LEFT OUTER JOIN finger_db.sys_user fsu
    ON (fsu.id_user = p.id_professional)
 WHERE nvl(p.flg_prof_test, 'N') = 'N';