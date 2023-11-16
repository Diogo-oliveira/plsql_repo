CREATE OR REPLACE view v_ref_network AS
    SELECT pdi.flg_type,
           i_orig.id_institution    id_inst_orig,
           i_orig.flg_type          orig_flg_type,
           i_orig.ext_code          orig_ext_code,
           i_orig.code_institution  orig_code_institution,
           i_dest.id_institution,
           i_dest.abbreviation,
           i_dest.ext_code,
           i_dest.code_institution,
           i_dest.flg_type          dest_flg_type,
           v.flg_availability,
           rdis.flg_inside_ref_area,
           pdi.flg_default          flg_default_inst, -- institution default or not
           v.flg_default            flg_default_dcs, -- dep_clin_serv default or not
           rdis.flg_ref_line,
           pdi.flg_type_ins,
           v.id_external_sys,
           v.id_dep_clin_serv,
           v.flg_visible_orig,
           v.code_clinical_service,
           v.flg_spec_dcs_default,
           v.id_dept,
           v.id_clinical_service,
           v.id_department,
           -- specialities
           ps.id_speciality,
           ps.id_parent,
           ps.code_speciality,
           ps.gender,
           ps.age_min,
           ps.age_max
      FROM p1_speciality ps
      JOIN v_ref_spec_inst_dcs v
        ON (ps.id_speciality = v.id_speciality)
      JOIN p1_dest_institution pdi
        ON (v.id_institution = pdi.id_inst_dest)
      JOIN ref_dest_institution_spec rdis
        ON (rdis.id_dest_institution = pdi.id_dest_institution AND rdis.id_speciality = ps.id_speciality)
      JOIN ref_spec_market rsmt
        ON (rsmt.id_speciality = ps.id_speciality)
      JOIN institution i_orig
        ON (i_orig.id_institution = pdi.id_inst_orig AND rsmt.id_market = i_orig.id_market)
      JOIN institution i_dest
        ON (i_dest.id_institution = v.id_institution)
     WHERE v.flg_availability IN ('E', 'A')
       AND pdi.id_inst_orig <> pdi.id_inst_dest
       AND ps.flg_available = 'Y'
       AND rdis.flg_available = 'Y'
       AND rsmt.flg_available = 'Y'
       AND pdi.flg_net_type = 'A'
       AND i_dest.id_institution NOT IN (SELECT rsin.id_institution
                                           FROM ref_spec_institution rsin
                                          WHERE rsin.id_institution = i_dest.id_institution
                                            AND rsin.id_speciality = ps.id_speciality
                                            AND rsin.flg_available = 'N');