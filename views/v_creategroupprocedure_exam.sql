CREATE OR REPLACE VIEW v_creategroupprocedure_exam AS 
SELECT *
  FROM (SELECT query_two.id_institution,
               query_one.id_group_procedure,
               query_one.code_translation,
               query_one.id_content,
               query_one.flg_characteristic,
               query_one.flg_available,
               row_number() over(PARTITION BY query_two.id_institution, query_one.id_group_procedure ORDER BY query_one.flg_characteristic DESC) flg_filter
          FROM (SELECT DISTINCT e.id_exam        id_exam,
                                ec.id_exam_cat   id_group_procedure,
                                ec.code_exam_cat code_translation,
                                ec.id_content,
                                -- caso seja um exame de imagem a group characterist é E, senao é X
                                decode(e.flg_type, 'I', 'E', 'X') flg_characteristic,
                                decode(ec.flg_available, 'Y', 'A', 'I') flg_available
                  FROM exam e, exam_cat ec
                 WHERE ec.id_exam_cat = e.id_exam_cat) query_one,
               (SELECT DISTINCT dcs.id_dep_clin_serv id_dep_clin_serv, er.id_exam, d.id_institution
                  FROM exam_room er, room r, dep_clin_serv dcs, department d
                 WHERE er.id_room = r.id_room
                   AND d.id_department = dcs.id_department
                   AND dcs.id_department = r.id_department) query_two
         WHERE query_two.id_exam = query_one.id_exam) inner_query
 WHERE inner_query.flg_filter = 1;
