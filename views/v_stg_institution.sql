CREATE OR REPLACE view v_stg_institution AS 
SELECT id_stg_institution,
       institution_name,
       flg_type,
       abbreviation,
       address,
       city,
       district,
       zip_code,
       id_country,
       id_market,
       phone_number,
       fax_number,
       email,
			 id_stg_files,
			 id_institution
  FROM stg_institution;