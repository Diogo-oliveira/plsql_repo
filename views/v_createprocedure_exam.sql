CREATE OR REPLACE VIEW v_createprocedure_exam AS
SELECT er.id_institution,
       e.id_content,
       e.id_content_grp_prc,
       e.code_translation,
       e.flg_characteristic,
       e.duration,
       e.icd,
       e.gdh,
       e.gender,
       e.age_min,
       e.age_max,
       e.min_nbr_hresource,
       e.max_nbr_hresource,
       e.number_of_persons,
       CAST(COLLECT(to_number(er.id_department)) AS table_number) id_department_coll,
       e.flg_available
  FROM (SELECT e.id_exam id_exam,
               e.id_content id_content,
               ec.id_content id_content_grp_prc,
               e.code_exam code_translation,
               decode(e.flg_type, 'I', 'E', 'X') flg_characteristic, -- caso seja um exame de imagem a group characterist é E, senao é X
               NULL duration,
               NULL icd,
               NULL gdh,
               e.gender,
               e.age_min,
               e.age_max,
               se.num_min_profs min_nbr_hresource,
               se.num_max_profs max_nbr_hresource,
               se.num_max_patients number_of_persons,
               decode(e.flg_available, 'Y', 'A', 'I') flg_available
          FROM exam e
          JOIN exam_cat ec
            ON ec.id_exam_cat = e.id_exam_cat
          JOIN sch_event se
            ON se.dep_type = decode(e.flg_type, 'I', 'E', 'X')) e,
       (SELECT er.id_exam, d.id_institution, d.id_department
          FROM exam_room er
          JOIN room r
            ON er.id_room = r.id_room
          JOIN department d
            ON r.id_department = d.id_department
         GROUP BY er.id_exam, d.id_institution, d.id_department) er
 WHERE e.id_exam = er.id_exam
 GROUP BY er.id_institution,
          e.id_content,
          e.id_content_grp_prc,
          e.code_translation,
          e.flg_characteristic,
          e.duration,
          e.icd,
          e.gdh,
          e.gender,
          e.age_min,
          e.age_max,
          e.flg_available,
          e.min_nbr_hresource,
          e.max_nbr_hresource,
          e.number_of_persons;
