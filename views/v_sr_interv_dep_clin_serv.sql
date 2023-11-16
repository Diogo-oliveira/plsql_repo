CREATE OR REPLACE VIEW v_sr_interv_dep_clin_serv AS
SELECT id_interv_dep_clin_serv id_sr_interv_dep_clin_serv,
       id_dep_clin_serv        id_dep_clin_serv,
       id_intervention         id_sr_intervention,
       flg_type,
       id_professional,
       id_institution,
       id_software
  FROM interv_dep_clin_serv;
