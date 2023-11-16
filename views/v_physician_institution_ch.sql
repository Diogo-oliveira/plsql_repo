CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_CH AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       p.title,
       NULL suffix,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city as city_description,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL as district,
       NULL as county,
       NULL as parish,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(2, (SELECT c.code_category FROM category c WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'N'
 AND pi.dt_end_tstz IS NULL
 AND pc.id_professional = p.id_professional
 AND pc.id_category = 1
 AND pc.id_institution = pi.id_institution
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 17
 UNION
 --EXTERNAL PROFESSIONALS
 SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       p.title,
       NULL suffix,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city as city_description,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL as district,
       NULL as county,
       NULL as parish,
       NULL as prof_cat_id,
       NULL as prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'Y'
 AND pi.dt_end_tstz IS NULL
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 17;


CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_CH AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       NULL suffix,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city as city_description,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL as district,
       NULL as county,
       NULL as parish,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(2, (SELECT c.code_category FROM category c WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'N'
 AND pi.dt_end_tstz IS NULL
 AND pc.id_professional = p.id_professional
 AND pc.id_category = 1
 AND pc.id_institution = pi.id_institution
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 17
 UNION
 --EXTERNAL PROFESSIONALS
 SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       NULL suffix,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city as city_description,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL as district,
       NULL as county,
       NULL as parish,
       NULL as prof_cat_id,
       NULL as prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'Y'
 AND pi.dt_end_tstz IS NULL
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 17;

 CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_CH AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       NULL suffix,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city as city_description,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL as district,
       NULL as county,
       NULL as parish,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(2, (SELECT c.code_category FROM category c WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'N'
 AND pi.dt_end_tstz IS NULL
 AND pc.id_professional = p.id_professional
 AND pc.id_category = 1
 AND pc.id_institution = pi.id_institution
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 17
 AND i.flg_type != 'L'
 UNION
 --EXTERNAL PROFESSIONALS
 SELECT pi.id_prof_institution,
       pi.id_institution,
       pi.flg_external,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       pk_backoffice.get_prof_title_desc(pk_utils.get_institution_language(pi.id_institution), p.title) title,
       NULL suffix,
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city as city_description,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL as district,
       NULL as county,
       NULL as parish,
       NULL as prof_cat_id,
       NULL as prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'Y'
 AND pi.dt_end_tstz IS NULL
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 17
 AND i.flg_type != 'L';