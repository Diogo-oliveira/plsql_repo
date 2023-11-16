DECLARE
    l_error VARCHAR2(1000 CHAR);
BEGIN
    l_error := 'UPDATE p1_spec_dep_clin_serv SET flg_spec_dcs_default = ''Y''';
    UPDATE p1_spec_dep_clin_serv
       SET flg_spec_dcs_default = 'Y'
     WHERE id_dep_clin_serv IN (SELECT s.id_dep_clin_serv
                                  FROM p1_spec_dep_clin_serv s
                                 GROUP BY id_dep_clin_serv
                                HAVING COUNT(1) = 1)
       AND flg_spec_dcs_default IS NULL;
END;
/
