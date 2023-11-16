DECLARE
BEGIN
    FOR c_disch IN (SELECT a.id_discharge, a.id_discharge_hist, a.id_discharge_flash_files
                      FROM (SELECT d.id_discharge,
                                   dh.id_discharge_hist,
                                   pk_disposition.get_disch_flash_file(i_institution      => epis.id_institution,
                                                                       i_discharge_reason => drd.id_discharge_reason,
                                                                       i_profile_template => dh.id_profile_template) id_discharge_flash_files
                              FROM discharge d
                              JOIN discharge_hist dh
                                ON dh.id_discharge = d.id_discharge
                              JOIN disch_reas_dest drd
                                ON drd.id_disch_reas_dest = d.id_disch_reas_dest
                              JOIN episode epis
                                ON epis.id_episode = d.id_episode
                             WHERE d.flg_market = 'US') a
                     WHERE a.id_discharge_flash_files IS NOT NULL)
    LOOP
        UPDATE discharge d
           SET d.id_discharge_flash_files = c_disch.id_discharge_flash_files
         WHERE d.id_discharge = c_disch.id_discharge;
    
        UPDATE discharge_hist dh
           SET dh.id_discharge_flash_files = c_disch.id_discharge_flash_files
         WHERE dh.id_discharge_hist = c_disch.id_discharge_hist;
    END LOOP;

    COMMIT;
END;
/
