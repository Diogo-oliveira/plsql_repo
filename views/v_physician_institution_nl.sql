CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_NL AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
            AND ia.id_account = 13
            AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 13
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       NULL house_number,
       NULL house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NULL post_office_box,
       NULL post_office_postal_code,
       NULL post_office_box_city,
       NULL life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL informed_via,
       NULL mail_to,
       NULL city_nl,
       pc.id_category prof_cat_id,
       pk_translation.get_translation(4, (SELECT c.code_category FROM category c WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'N'
 AND pi.dt_end_tstz IS NULL
 AND pc.id_professional = p.id_professional
 AND pc.id_category = 1 -- Médico
 AND pc.id_institution = pi.id_institution
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 5
 UNION
--Profissionais externos
SELECT pi.id_prof_institution,
       pi.id_institution,
       NVL((SELECT ifd.value
            FROM institution_field_data ifd
            join field_market fm
            on ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
            AND fm.id_field = 40 and fm.id_market = 5
            AND rownum = 1), NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 20 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) agb_code,
       p.address,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 21 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) house_number,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 22 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 23 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_box,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 24 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_postal_code,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market            
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 25 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_box_city,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market            
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 26 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market            
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 27 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) alternate_email,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market            
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 28 and fm.id_market = 5            
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) informed_via,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market            
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 29 and fm.id_market = 5            
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) mail_to,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market            
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 32 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) city_nl,
        NVL((SELECT pfd.id_field_market
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market            
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 43 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) prof_cat_id,
        NVL((SELECT stgpc.ext_prof_cat_desc
            FROM stg_ext_prof_cat stgpc         
            WHERE stgpc.id_market = 5
            AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                          FROM professional_field_data pfd
                                          join field_market fm
                                          on pfd.id_field_market = fm.id_field_market            
                                          WHERE pfd.id_professional = p.id_professional
                                          AND fm.id_field = 43 and fm.id_market = 5
                                          AND pfd.id_institution = 0
                                          AND rownum = 1)
            AND rownum = 1), NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'Y'
 AND pi.dt_end_tstz IS NULL
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 5;
 
-- CHANGED BY: Bruno Martins
-- CHANGE DATE: 2010-07-29
-- CHANGE REASON: ADT-2901

CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_NL AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
            AND ia.id_account = 13
            AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 13
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       NULL house_number,
       NULL house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NULL post_office_box,
       NULL post_office_postal_code,
       NULL post_office_box_city,
       NULL life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL informed_via,
       NULL mail_to,
       NULL city_nl,
       pc.id_category prof_cat_id,
       pk_translation.get_translation(4, (SELECT c.code_category FROM category c WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'N'
 AND pi.dt_end_tstz IS NULL
 AND pc.id_professional = p.id_professional
 AND pc.id_category = 1 -- Médico
 AND pc.id_institution = pi.id_institution
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 5
 UNION
--Profissionais externos
SELECT pi.id_prof_institution,
       pi.id_institution,
       NVL((SELECT ifd.value
            FROM institution_field_data ifd
            join field_market fm
            on ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
            AND fm.id_field = 40 and fm.id_market = 5
            AND rownum = 1), NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       NVL(p.id_speciality, (SELECT pfd.id_field_market
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 44 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1)) id_speciality,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 20 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) agb_code,
       p.address,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 21 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) house_number,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 22 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 23 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_box,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 24 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_postal_code,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 25 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_box_city,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 26 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 27 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) alternate_email,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 28 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) informed_via,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 29 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) mail_to,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 32 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) city_nl,
        NVL((SELECT pfd.id_field_market
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 43 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) prof_cat_id,
        NVL((SELECT stgpc.ext_prof_cat_desc
            FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
            AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                          FROM professional_field_data pfd
                                          join field_market fm
                                          on pfd.id_field_market = fm.id_field_market
                                          WHERE pfd.id_professional = p.id_professional
                                          AND fm.id_field = 43 and fm.id_market = 5
                                          AND pfd.id_institution = 0
                                          AND rownum = 1)
            AND rownum = 1), NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'Y'
 AND pi.dt_end_tstz IS NULL
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 5;

-- CHANGE END: Bruno Martins

-- CHANGED BY: Bruno Martins
-- CHANGE DATE: 2010-08-02
-- CHANGE REASON: ADT-2902

CREATE OR REPLACE VIEW ALERT.V_PHYSICIAN_INSTITUTION_NL AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
            AND ia.id_account = 13
            AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 13
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       NULL house_number,
       NULL house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NULL post_office_box,
       NULL post_office_postal_code,
       NULL post_office_box_city,
       NULL life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL informed_via,
       NULL mail_to,
       NULL city_nl,
       pc.id_category prof_cat_id,
       pk_translation.get_translation(4, (SELECT c.code_category FROM category c WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'N'
 AND pi.dt_end_tstz IS NULL
 AND pc.id_professional = p.id_professional
 AND pc.id_category = 1 -- Médico
 AND pc.id_institution = pi.id_institution
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 5
 UNION
--Profissionais externos
SELECT pi.id_prof_institution,
       pi.id_institution,
       NVL((SELECT ifd.value
            FROM institution_field_data ifd
            join field_market fm
            on ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
            AND fm.id_field = 40 and fm.id_market = 5
            AND rownum = 1), NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       NVL(p.id_speciality, (SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 44 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1)) id_speciality,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 20 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) agb_code,
       p.address,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 21 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) house_number,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 22 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 23 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_box,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 24 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_postal_code,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 25 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_box_city,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 26 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 27 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) alternate_email,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 28 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) informed_via,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 29 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) mail_to,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 32 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) city_nl,
        NVL((SELECT to_number(pfd.value)
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 43 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) prof_cat_id,
        NVL((SELECT stgpc.ext_prof_cat_desc
            FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
            AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                          FROM professional_field_data pfd
                                          join field_market fm
                                          on pfd.id_field_market = fm.id_field_market
                                          WHERE pfd.id_professional = p.id_professional
                                          AND fm.id_field = 43 and fm.id_market = 5
                                          AND pfd.id_institution = 0
                                          AND rownum = 1)
            AND rownum = 1), NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'Y'
 AND pi.dt_end_tstz IS NULL
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 5;
 
-- CHANGE END: Bruno Martins

-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 2010-08-17
-- CHANGE REASON: ADT-2946
CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_NL AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
            AND ia.id_account = 13
            AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_specialty,
       NULL specialty_desc,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 13
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       NULL house_number,
       NULL house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NULL post_office_box,
       NULL post_office_postal_code,
       NULL post_office_box_city,
       NULL life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL informed_via,
       NULL mail_to,
       NULL city_nl,
       pc.id_category prof_cat_id,
       pk_translation.get_translation(4, (SELECT c.code_category FROM category c WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'N'
 AND pi.dt_end_tstz IS NULL
 AND pc.id_professional = p.id_professional
 AND pc.id_category = 1 -- Médico
 AND pc.id_institution = pi.id_institution
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 5
 UNION
--Profissionais externos
SELECT pi.id_prof_institution,
       pi.id_institution,
       NVL((SELECT ifd.value
            FROM institution_field_data ifd
            join field_market fm
            on ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
            AND fm.id_field = 40 and fm.id_market = 5
            AND rownum = 1), NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       NVL(to_char(p.id_speciality), (SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 44 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1)) speciality_desc,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 20 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) agb_code,
       p.address,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 21 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) house_number,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 22 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 23 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_box,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 24 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_postal_code,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 25 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) post_office_box_city,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 26 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 27 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) alternate_email,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 28 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) informed_via,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 29 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) mail_to,
       NVL((SELECT pfd.value
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 32 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) city_nl,
        NVL((SELECT to_number(pfd.value)
            FROM professional_field_data pfd
            join field_market fm
            on pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
            AND fm.id_field = 43 and fm.id_market = 5
            AND pfd.id_institution = 0
            AND rownum = 1), NULL) prof_cat_id,
        NVL((SELECT stgpc.ext_prof_cat_desc
            FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
            AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                          FROM professional_field_data pfd
                                          join field_market fm
                                          on pfd.id_field_market = fm.id_field_market
                                          WHERE pfd.id_professional = p.id_professional
                                          AND fm.id_field = 43 and fm.id_market = 5
                                          AND pfd.id_institution = 0
                                          AND rownum = 1)
            AND rownum = 1), NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
 AND p.id_professional = pi.id_professional
 AND pi.flg_state = 'A'
 AND pi.flg_external = 'Y'
 AND pi.dt_end_tstz IS NULL
 AND pi.id_institution (+)= i.id_institution
 AND i.id_market = 5;

-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 2010-10-22
-- CHANGE REASON: ALERT-134119
CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_NL AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
              AND ia.id_account = 13
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_specialty,
       NULL specialty_desc,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 13
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       NULL house_number,
       NULL house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NULL post_office_box,
       NULL post_office_postal_code,
       NULL post_office_box_city,
       NULL life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL informed_via,
       NULL mail_to,
       NULL city_nl,
       pc.id_category prof_cat_id,
       pk_translation.get_translation(4,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pc.id_professional = p.id_professional
   AND pc.id_category = 1
   AND pc.id_institution = pi.id_institution
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
UNION
--EXTERNAL_PROFESSIONAL
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 32
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
UNION
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 32
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
   AND i.flg_external = 'Y';
   
-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 2010-11-11
-- CHANGE REASON: ALERT-139947
CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_NL AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
              AND ia.id_account = 13
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_specialty,
       NULL specialty_desc,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 13
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       NULL house_number,
       NULL house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NULL post_office_box,
       NULL post_office_postal_code,
       NULL post_office_box_city,
       NULL life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL informed_via,
       NULL mail_to,
       NULL city_nl,
       pc.id_category prof_cat_id,
       pk_translation.get_translation(4,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pc.id_professional = p.id_professional
   AND pc.id_category = 1
   AND pc.id_institution = pi.id_institution
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
UNION
--EXTERNAL_PROFESSIONAL
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       NULL city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
UNION
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       NULL city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
   AND i.flg_external = 'Y';
   
-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 2010-11-11
-- CHANGE REASON: ALERT-139947
CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_NL AS
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
              AND ia.id_account = 13
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_specialty,
       NULL specialty_desc,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 13
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       NULL house_number,
       NULL house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NULL post_office_box,
       NULL post_office_postal_code,
       NULL post_office_box_city,
       NULL life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL informed_via,
       NULL mail_to,
       NULL city_nl,
       pc.id_category prof_cat_id,
       pk_translation.get_translation(4,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pc.id_professional = p.id_professional
   AND pc.id_category = 1
   AND pc.id_institution = pi.id_institution
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
UNION
--EXTERNAL_PROFESSIONAL
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       NULL city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
UNION
SELECT pi.id_prof_institution,
       pi.id_institution,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       NULL city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
   AND i.flg_external = 'Y';



CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_NL AS
SELECT pi.id_prof_institution,
       pi.id_institution,
			 pi.flg_external,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
              AND ia.id_account = 13
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_specialty,
       NULL specialty_desc,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 13
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       NULL house_number,
       NULL house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NULL post_office_box,
       NULL post_office_postal_code,
       NULL post_office_box_city,
       NULL life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL informed_via,
       NULL mail_to,
       NULL city_nl,
       pc.id_category prof_cat_id,
       pk_translation.get_translation(4,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pc.id_professional = p.id_professional
   AND pc.id_category = 1
   AND pc.id_institution = pi.id_institution
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
UNION
--EXTERNAL_PROFESSIONAL
SELECT pi.id_prof_institution,
       pi.id_institution,
			 pi.flg_external,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       NULL city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
UNION
SELECT pi.id_prof_institution,
       pi.id_institution,
			 pi.flg_external,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       NULL city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
   AND i.flg_external = 'Y';	 

CREATE OR REPLACE VIEW alert.V_PHYSICIAN_INSTITUTION_NL AS
SELECT pi.id_prof_institution,
       pi.id_institution,
			 pi.flg_external,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
              AND ia.id_account = 13
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_specialty,
       NULL specialty_desc,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 13
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       NULL house_number,
       NULL house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NULL post_office_box,
       NULL post_office_postal_code,
       NULL post_office_box_city,
       NULL life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL informed_via,
       NULL mail_to,
       NULL city_nl,
       pc.id_category prof_cat_id,
       pk_translation.get_translation(4,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pc.id_professional = p.id_professional
   AND pc.id_category = 1
   AND pc.id_institution = pi.id_institution
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
UNION
--EXTERNAL_PROFESSIONAL
SELECT pi.id_prof_institution,
       pi.id_institution,
			 pi.flg_external,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       NULL city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
UNION
SELECT pi.id_prof_institution,
       pi.id_institution,
			 pi.flg_external,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       NULL city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
   AND i.flg_external = 'Y';

CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_NL AS
SELECT pi.id_prof_institution,
       pi.id_institution,
			 pi.flg_external,
       nvl((SELECT ia.value
             FROM institution_accounts ia
            WHERE ia.id_institution = pi.id_institution
              AND ia.id_account = 13
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_specialty,
       NULL specialty_desc,
       nvl((SELECT pa.value
             FROM prof_accounts pa
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 13
              AND pa.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       NULL house_number,
       NULL house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       NULL post_office_box,
       NULL post_office_postal_code,
       NULL post_office_box_city,
       NULL life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       NULL alternate_email,
       NULL informed_via,
       NULL mail_to,
       NULL city_nl,
       pc.id_category prof_cat_id,
       pk_translation.get_translation(4,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc
  FROM professional p, prof_institution pi, prof_cat pc, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pc.id_professional = p.id_professional
   AND pc.id_category = 1
   AND pc.id_institution = pi.id_institution
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
	 AND i.flg_type != 'L'
UNION
--EXTERNAL_PROFESSIONAL
SELECT pi.id_prof_institution,
       pi.id_institution,
			 pi.flg_external,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       NULL city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
	 AND i.flg_type != 'L'
UNION
SELECT pi.id_prof_institution,
       pi.id_institution,
			 pi.flg_external,
       nvl((SELECT ifd.value
             FROM institution_field_data ifd
             JOIN field_market fm
               ON ifd.id_field_market = fm.id_field_market
            WHERE ifd.id_institution = pi.id_institution
              AND fm.id_field = 40
              AND fm.id_market = 5
              AND rownum = 1),
           NULL) institution_agb_code,
       p.id_professional,
       p.name,
       p.first_name,
       p.middle_name,
       p.last_name,
       p.gender,
       p.id_speciality id_speciality,
       nvl(to_char(p.id_speciality),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 44
               AND fm.id_market = 5
               AND pfd.id_institution = 0
               AND rownum = 1)) speciality_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 20
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) agb_code,
       p.address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 21
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 22
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) house_number_addition,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 23
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 24
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_postal_code,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 25
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) post_office_box_city,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 26
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) life_line_post_office_box,
       p.num_contact,
       p.cell_phone,
       p.fax,
       p.email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 27
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) alternate_email,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 28
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) informed_via,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 29
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) mail_to,
       NULL city_nl,
       nvl((SELECT to_number(pfd.value)
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 43
              AND fm.id_market = 5
              AND pfd.id_institution = 0
              AND rownum = 1),
           NULL) prof_cat_id,
       nvl((SELECT stgpc.ext_prof_cat_desc
             FROM stg_ext_prof_cat stgpc
            WHERE stgpc.id_market = 5
              AND stgpc.id_ext_prof_cat = (SELECT pfd.value
                                             FROM professional_field_data pfd
                                             JOIN field_market fm
                                               ON pfd.id_field_market = fm.id_field_market
                                            WHERE pfd.id_professional = p.id_professional
                                              AND fm.id_field = 43
                                              AND fm.id_market = 5
                                              AND pfd.id_institution = 0
                                              AND rownum = 1)
              AND rownum = 1),
           NULL) prof_cat_desc
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'N'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 5
   AND i.flg_external = 'Y'
	 AND i.flg_type != 'L';