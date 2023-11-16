CREATE OR REPLACE view v_ref_hosp_entrance AS
    SELECT pdi.flg_type,
           pdi.id_inst_orig,
           NULL                    orig_flg_type,
           i_dest.id_institution,
           i_dest.abbreviation,
           i_dest.ext_code,
           i_dest.code_institution,
           i_dest.flg_type         dest_flg_type,
           v.flg_availability,
           NULL                    flg_inside_ref_area,
           NULL                    flg_default_inst, -- institution default
           v.flg_default           flg_default_dcs, -- dep_clin_serv default or not
           rdis.flg_ref_line       flg_ref_line,
           pdi.flg_type_ins        flg_type_ins,
           v.id_external_sys,
           v.id_dep_clin_serv,
           v.flg_visible_orig,
           v.code_clinical_service,
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
      JOIN p1_dest_institution pdi -- orig = dest
        ON (v.id_institution = pdi.id_inst_dest)
      JOIN ref_dest_institution_spec rdis -- specialities available to "At hospital entrance" workflow
        ON (rdis.id_dest_institution = pdi.id_dest_institution AND rdis.id_speciality = ps.id_speciality)
      JOIN ref_spec_market rsmt
        ON (rsmt.id_speciality = ps.id_speciality)
      JOIN institution i_dest
        ON (i_dest.id_institution = v.id_institution AND i_dest.id_market = rsmt.id_market)
     WHERE ps.flg_available = 'Y'
       AND rsmt.flg_available = 'Y'
       AND v.flg_availability IN ('P', 'A') -- at hospital entrance workflow
          --AND pdi.id_inst_orig = pdi.id_inst_dest
       AND pdi.flg_net_type = 'P'
       AND i_dest.id_institution NOT IN (SELECT rsin.id_institution
                                           FROM ref_spec_institution rsin
                                          WHERE rsin.id_institution = i_dest.id_institution
                                            AND rsin.id_speciality = ps.id_speciality
                                            AND rsin.flg_available = 'N');