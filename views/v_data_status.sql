
CREATE OR REPLACE VIEW v_data_status AS
SELECT 'SCHEDULE' table_name, id_instit_requested id_institution, COUNT(0) num_records, SUM(COUNT(0)) over() total
      FROM schedule
     GROUP BY id_instit_requested
    UNION ALL
    SELECT 'VISIT' table_name, id_institution, COUNT(0) num_records, SUM(COUNT(0)) over() total
      FROM visit
     GROUP BY id_institution
    UNION ALL
    SELECT 'EPISODE' table_name, id_institution, COUNT(0) num_records, SUM(COUNT(0)) over() total
      FROM episode e
     INNER JOIN visit v ON e.id_visit = v.id_visit
     GROUP BY id_institution
     ORDER BY 1 ASC, 2 ASC;
