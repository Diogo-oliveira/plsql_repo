-->migra_prof_profile_template
DECLARE
    l_us_mkt      market.id_market%TYPE := 2;
    l_new_profile profile_template.id_profile_template%TYPE := 17508;
    l_old_profile profile_template.id_profile_template%TYPE := 42;
    l_bo_sw       software.id_software%TYPE := 26;
    l_inst_array table_number := table_number();
BEGIN
    SELECT i.id_institution BULK COLLECT
      INTO l_inst_array
      FROM institution i
     WHERE i.flg_available = 'Y'
       AND (i.flg_external IS NULL OR i.flg_external = 'N')
       AND i.id_market = l_us_mkt;

    FORALL i IN 1 .. l_inst_array.count
        UPDATE prof_profile_template ppt
           SET ppt.id_profile_template = l_new_profile
         WHERE ppt.id_profile_template = l_old_profile
           AND ppt.id_institution = l_inst_array(i)
           AND ppt.id_software = l_bo_sw;
END;
/
