CREATE OR REPLACE VIEW alert.V_SURGICAL_PROCEDURES AS
SELECT idcs.id_institution,
            si.id_content,
            NULL id_content_group_procedure,
            si.code_intervention code_translation,
            'S' flg_characteristic,
            si.duration duration,
            --si.icd icd,
			ic.standard_code icd,
            NULL gdh,
            si.gender gender,
            si.age_min agemin,
            si.age_max agemax,
            se.num_min_profs min_nbr_hresource,
            se.num_max_profs max_nbr_hresource,
            se.num_max_patients number_of_persons,
            CAST(COLLECT(to_number(idcs.id_dep_clin_serv)) AS table_number) coll_id_dep_clin_serv,
            si.flg_status flg_available
       FROM intervention si
      INNER JOIN interv_dep_clin_serv idcs ON idcs.id_intervention = si.id_intervention
			INNER JOIN interv_codification ic on si.id_intervention = ic.id_intervention
      join sch_event se on se.id_sch_event = 14
      GROUP BY idcs.id_institution,
               si.id_content,
               si.code_intervention,
               si.duration,
               --si.icd,
							 ic.standard_code,
               --si.gdh,
               si.gender,
               si.age_min,
               si.age_max,
               si.flg_status,
               se.num_min_profs,
               se.num_max_profs,
               se.num_max_patients;
               
