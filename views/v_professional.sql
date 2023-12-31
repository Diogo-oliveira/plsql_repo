CREATE OR REPLACE VIEW V_PROFESSIONAL AS
SELECT p.id_professional,
       name,
       nick_name,
       num_contact,
       upin,
       dea,
       id_speciality,
       num_order,
       dt_birth,
       address,
       district,
       city,
       zip_code,
       marital_status,
       gender,
       p.flg_state professional_flg_state,
       id_scholarship,
       id_country,
       barcode,
       initials,
       title,
       short_name,
       cell_phone,
       fax,
       email,
       adress_type,
       p.first_name,
       p.middle_name,
       p.last_name,
       work_phone,
       u.login desc_user,
       p.id_prof_formation,
       p.code_family_status,
       p.id_geo_state_crm,
       p.code_emitant_crm,
       p.dt_emission_id,
       p.id_geo_state_doc,
       p.code_emitant_cert,
       p.id_document,
       p.dt_emission_cert,
       p.desc_term,
       p.desc_page,
       p.desc_book,
       p.desc_balcony,
       p.code_certificate,
       p.code_doc_type,
       p.id_banq_account,
       p.desc_banq_ag,
       p.code_banq,
       p.adress_area,
       p.id_district_adress,
       p.id_geo_state_adress,
       p.address_extension,
       p.door_number,
       p.code_logr_type,
       p.flg_in_school,
       p.code_scoolarship,
       p.code_race,
       p.id_district_birth,
       p.id_geo_state_birth,
       p.father_name,
       p.mother_name,
       p.id_cns,
       p.id_cpf,
       p.id_health_plan,
       p.other_doc_desc,
       p.suffix,
       p.county,
       p.address_other_name,
       p.parent_name,
       p.first_name_sa,
       p.parent_name_sa,
       p.middle_name_sa,
       p.last_name_sa
  FROM professional p, ab_user_info u
 WHERE p.id_professional = u.id_ab_user_info(+);
