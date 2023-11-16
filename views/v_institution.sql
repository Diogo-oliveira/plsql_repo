CREATE OR REPLACE VIEW V_INSTITUTION AS
SELECT i.id_institution,
       code_institution,
       flg_type,
       abbreviation,
       address,
       district,
       zip_code,
       phone_number,
       fax_number,
       id_timezone_region,
       id_market,
       id_country,
       id_city,
       id_currency,
       email,
       id_institution_language,
       i.id_parent id_parent_institution,
       i.flg_available,
       ext_code,
       i.flg_external,
       i.location,
       decode(i.flg_external,
              'Y',
              (SELECT ifd.value
                 FROM institution_field_data ifd
                WHERE ifd.id_institution = i.id_institution
                  AND ifd.id_field_market = 58),
              'N',
              i.adress_type) adress_type
  FROM institution i, inst_attributes ia
 WHERE i.id_institution = ia.id_institution(+);

 CREATE OR REPLACE VIEW V_INSTITUTION AS
SELECT i.id_institution,
       code_institution,
       flg_type,
       abbreviation,
       address,
       district,
       zip_code,
       phone_number,
       fax_number,
       id_timezone_region,
       id_market,
       id_country,
       id_city,
       id_currency,
       email,
       id_institution_language,
       i.id_parent id_parent_institution,
       i.flg_available,
       ext_code,
       i.flg_external,
       i.location,
       decode(i.flg_external,
              'Y',
              (SELECT ifd.value
                 FROM institution_field_data ifd
                WHERE ifd.id_institution = i.id_institution
                  AND ifd.id_field_market = 58),
              'N',
              i.adress_type) adress_type,
       i.contact_detail
  FROM institution i, inst_attributes ia
 WHERE i.id_institution = ia.id_institution(+);

CREATE OR REPLACE VIEW V_INSTITUTION AS
SELECT i.id_institution,
       code_institution,
       flg_type,
       abbreviation,
       address,
       district,
       zip_code,
       phone_number,
       fax_number,
       id_timezone_region,
       id_market,
       id_country,
       id_city,
       id_currency,
       email,
       id_institution_language,
       i.id_parent id_parent_institution,
       i.flg_available,
       ext_code,
       i.flg_external,
       i.location,
       decode(i.flg_external,
              'Y',
              (SELECT ifd.value
                 FROM institution_field_data ifd
                WHERE ifd.id_institution = i.id_institution
                  AND ifd.id_field_market = 58),
              'N',
              i.adress_type) adress_type,
       i.contact_detail,
       i.county,
       i.address_other_name
  FROM institution i, inst_attributes ia
 WHERE i.id_institution = ia.id_institution(+);
 
 
CREATE OR REPLACE VIEW V_INSTITUTION AS
SELECT i.id_institution,
       code_institution,
       flg_type,
       abbreviation,
       address,
       district,
       zip_code,
       phone_number,
       fax_number,
       id_timezone_region,
       id_market,
       id_country,
       id_city,
       id_currency,
       email,
       il.id_institution_language,
       il.id_language,
       i.id_parent id_parent_institution,
       i.flg_available,
       ext_code,
       i.flg_external,
       i.location,
       decode(i.flg_external,
              'Y',
              (SELECT ifd.value
                 FROM institution_field_data ifd
                WHERE ifd.id_institution = i.id_institution
                  AND ifd.id_field_market = 58),
              'N',
              i.adress_type) adress_type,
       i.contact_detail,
       i.county,
       i.address_other_name
  FROM institution i
left join inst_attributes ia on (ia.id_institution = i.id_institution)
left join institution_language il on (il.id_institution = i.id_institution);


CREATE OR REPLACE VIEW V_INSTITUTION AS
SELECT i.id_institution,
       code_institution,
       flg_type,
       abbreviation,
       address,
       district,
       zip_code,
       phone_number,
       fax_number,
       id_timezone_region,
       id_market,
       id_country,
       id_city,
       id_currency,
       i.email,
       il.id_institution_language,
       il.id_language,
       i.id_parent id_parent_institution,
       i.flg_available,
       ext_code,
       i.flg_external,
       i.location,
       decode(i.flg_external,
              'Y',
              (SELECT ifd.value
                 FROM institution_field_data ifd
                WHERE ifd.id_institution = i.id_institution
                  AND ifd.id_field_market = 58),
              'N',
              i.adress_type) adress_type,
       i.contact_detail,
       i.county,
       i.address_other_name
  FROM institution i
left join inst_attributes ia on (ia.id_institution = i.id_institution)
left join institution_language il on (il.id_institution = i.id_institution);