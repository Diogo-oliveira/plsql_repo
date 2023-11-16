CREATE OR REPLACE view v_physician_institution_fr AS
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
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL state,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(6,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 68
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 68
               AND pa.id_institution = 0)) num_am,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 69
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 69
               AND pa.id_institution = 0)) cab,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 74
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 74
               AND pa.id_institution = 0)) conv,
       ---------------------------------------
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 75
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 75
               AND pa.id_institution = 0)) zsid,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 76
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 76
               AND pa.id_institution = 0)) zik,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 77
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 77
               AND pa.id_institution = 0)) spec,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 70
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 70
               AND pa.id_institution = 0)) conv_level,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 71
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 71
               AND pa.id_institution = 0)) ment_admin,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 72
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 72
               AND pa.id_institution = 0)) int_address,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 73
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 73
               AND pa.id_institution = 0)) ment_lib
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
   AND i.id_market = 9
UNION
--Profissionais externos
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
       
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       
       p.district state,
       NULL prof_cat_id,
       NULL prof_cat_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 68
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 68
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) num_am,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 69
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 69
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) cab,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 74
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 74
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) conv,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 75
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 75
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) zsid,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 76
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 76
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) zik,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 77
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 77
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) spec,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 70
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 70
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) conv_level,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 71
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 71
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) ment_admin,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 72
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 72
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) int_address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 73
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 73
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) ment_lib
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 9;


CREATE OR REPLACE view v_physician_institution_fr AS
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
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL state,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(6,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 68
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 68
               AND pa.id_institution = 0)) num_am,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 69
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 69
               AND pa.id_institution = 0)) cab,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 74
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 74
               AND pa.id_institution = 0)) conv,
       ---------------------------------------
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 75
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 75
               AND pa.id_institution = 0)) zsid,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 76
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 76
               AND pa.id_institution = 0)) zik,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 77
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 77
               AND pa.id_institution = 0)) spec,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 70
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 70
               AND pa.id_institution = 0)) conv_level,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 71
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 71
               AND pa.id_institution = 0)) ment_admin,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 72
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 72
               AND pa.id_institution = 0)) int_address,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 73
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 73
               AND pa.id_institution = 0)) ment_lib
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
   AND i.id_market = 9
UNION
--Profissionais externos
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
       
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       
       p.district state,
       NULL prof_cat_id,
       NULL prof_cat_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 68
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 68
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) num_am,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 69
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 69
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) cab,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 74
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 74
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) conv,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 75
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 75
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) zsid,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 76
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 76
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) zik,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 77
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 77
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) spec,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 70
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 70
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) conv_level,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 71
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 71
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) ment_admin,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 72
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 72
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) int_address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 73
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 73
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) ment_lib
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 9;

CREATE OR REPLACE VIEW V_PHYSICIAN_INSTITUTION_FR AS
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
       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,
       NULL state,
       to_char(pc.id_category) prof_cat_id,
       pk_translation.get_translation(6,
                                      (SELECT c.code_category
                                         FROM category c
                                        WHERE c.id_category = pc.id_category)) prof_cat_desc,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 68
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 68
               AND pa.id_institution = 0)) num_am,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 69
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 69
               AND pa.id_institution = 0)) cab,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 74
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 74
               AND pa.id_institution = 0)) conv,
       ---------------------------------------
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 75
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 75
               AND pa.id_institution = 0)) zsid,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 76
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 76
               AND pa.id_institution = 0)) zik,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 77
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 77
               AND pa.id_institution = 0)) spec,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 70
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 70
               AND pa.id_institution = 0)) conv_level,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 71
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 71
               AND pa.id_institution = 0)) ment_admin,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 72
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 72
               AND pa.id_institution = 0)) int_address,
       nvl((SELECT decode(a.fill_type,
                         'M',
                         pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                         'MM',
                         nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                         pa.value)
             FROM prof_accounts pa
            INNER JOIN accounts a
               ON (a.id_account = pa.id_account)
            WHERE pa.id_professional = p.id_professional
              AND pa.id_account = 73
              AND pa.id_institution = pi.id_institution),
           (SELECT decode(a.fill_type,
                          'M',
                          pk_sysdomain.get_domain(a.sys_domain_identifier, pa.value, 6),
                          'MM',
                          nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, pa.value, 6), NULL),
                          pa.value)
              FROM prof_accounts pa
             INNER JOIN accounts a
                ON (a.id_account = pa.id_account)
             WHERE pa.id_professional = p.id_professional
               AND pa.id_account = 73
               AND pa.id_institution = 0)) ment_lib
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
   AND i.id_market = 9
	 AND i.flg_type != 'L'
UNION
--Profissionais externos
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

       p.address,
       p.zip_code postal_code,
       p.id_country,
       p.city,
       p.work_phone,
       p.cell_phone,
       p.fax,
       p.email,

       p.district state,
       NULL prof_cat_id,
       NULL prof_cat_desc,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 68
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 68
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) num_am,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 69
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 69
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) cab,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 74
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 74
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) conv,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 75
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 75
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) zsid,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 76
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 76
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) zik,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 77
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 77
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) spec,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 70
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 70
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) conv_level,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 71
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 71
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) ment_admin,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 72
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 72
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) int_address,
       nvl((SELECT pfd.value
             FROM professional_field_data pfd
             JOIN field_market fm
               ON pfd.id_field_market = fm.id_field_market
            WHERE pfd.id_professional = p.id_professional
              AND fm.id_field = 73
              AND fm.id_market = 9
              AND pfd.id_institution = pi.id_institution),
           (SELECT pfd.value
              FROM professional_field_data pfd
              JOIN field_market fm
                ON pfd.id_field_market = fm.id_field_market
             WHERE pfd.id_professional = p.id_professional
               AND fm.id_field = 73
               AND fm.id_market = 9
               AND pfd.id_institution = 0)) ment_lib
  FROM professional p, prof_institution pi, institution i
 WHERE nvl(p.flg_prof_test, 'N') != 'Y'
   AND p.id_professional = pi.id_professional
   AND pi.flg_state = 'A'
   AND pi.flg_external = 'Y'
   AND pi.dt_end_tstz IS NULL
   AND pi.id_institution(+) = i.id_institution
   AND i.id_market = 9
	 AND i.flg_type != 'L';