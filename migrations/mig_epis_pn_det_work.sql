-- CHANGED BY: António Neto
-- CHANGE DATE: 12/Aug/2011 
-- CHANGE REASON: [ALERT-168848] H & P reformulation in INPATIENT (phase 2)
BEGIN

    FOR item IN (SELECT epnw.dt_pn, epndw.id_epis_pn_det
                   FROM epis_pn_work epnw
                  INNER JOIN epis_pn_det_work epndw ON epnw.id_epis_pn = epndw.id_epis_pn
                  INNER JOIN pn_data_block pndb ON epndw.id_pn_data_block = pndb.id_pn_data_block
                                               AND pndb.flg_type = 'C'
                                               AND pndb.data_area = 'CD'
                  WHERE epndw.dt_note IS NULL)
    LOOP
        UPDATE epis_pn_det_work epndw
           SET epndw.dt_note = item.dt_pn
         WHERE epndw.id_epis_pn_det = item.id_epis_pn_det;
    END LOOP;

END;
/
-- CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 12/Aug/2011 
-- CHANGE REASON: [ALERT-168848] H & P reformulation in INPATIENT (phase 2)
BEGIN

    FOR item IN (SELECT epnw.dt_pn, epndw.id_epis_pn_det
                   FROM epis_pn_work epnw
                  INNER JOIN epis_pn_det_work epndw ON epnw.id_epis_pn = epndw.id_epis_pn
                  INNER JOIN pn_data_block pndb ON epndw.id_pn_data_block = pndb.id_pn_data_block
                                               AND pndb.flg_type = 'C'
                                               AND pndb.data_area = 'CD'
                  WHERE epndw.dt_note IS NULL)
    LOOP
        UPDATE epis_pn_det_work epndw
           SET epndw.dt_note = item.dt_pn
         WHERE epndw.id_epis_pn_det = item.id_epis_pn_det;
    END LOOP;

END;
/
-- CHANGE END: António Neto