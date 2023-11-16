
UPDATE epis_report_section ers
   SET ers.id_rep_section = ers.id_rep_section_det
 WHERE EXISTS (SELECT 1
          FROM rep_section rs
         WHERE rs.id_rep_section = ers.id_rep_section_det);

UPDATE epis_report_section ers
   SET ers.id_rep_section = -1
 WHERE ers.id_rep_section_det NOT IN (SELECT rs.id_rep_section
                                        FROM rep_section rs);

COMMIT;
