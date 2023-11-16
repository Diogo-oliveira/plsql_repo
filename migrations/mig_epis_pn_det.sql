-- CHANGED BY: António Neto
-- CHANGE DATE: 12/Aug/2011 
-- CHANGE REASON: [ALERT-168848] H & P reformulation in INPATIENT (phase 2)
BEGIN

    FOR item IN (SELECT epn.pn_date, epnd.id_epis_pn_det
                   FROM epis_pn epn
                  INNER JOIN epis_pn_det epnd ON epn.id_epis_pn = epnd.id_epis_pn
                  INNER JOIN pn_data_block pndb ON epnd.id_pn_data_block = pndb.id_pn_data_block
                                               AND pndb.flg_type = 'C'
                                               AND pndb.data_area = 'CD'
                  WHERE epnd.dt_note IS NULL)
    LOOP
        UPDATE epis_pn_det epnd
           SET epnd.dt_note = item.pn_date
         WHERE epnd.id_epis_pn_det = item.id_epis_pn_det;
    END LOOP;

END;
/
-- CHANGE END: António Neto


-- CHANGED BY: António Neto
-- CHANGE DATE: 12/Aug/2011 
-- CHANGE REASON: [ALERT-168848] H & P reformulation in INPATIENT (phase 2)
BEGIN

    FOR item IN (SELECT epn.pn_date, epnd.id_epis_pn_det
                   FROM epis_pn epn
                  INNER JOIN epis_pn_det epnd ON epn.id_epis_pn = epnd.id_epis_pn
                  INNER JOIN pn_data_block pndb ON epnd.id_pn_data_block = pndb.id_pn_data_block
                                               AND pndb.flg_type = 'C'
                                               AND pndb.data_area = 'CD'
                  WHERE epnd.dt_note IS NULL)
    LOOP
        UPDATE epis_pn_det epnd
           SET epnd.dt_note = item.pn_date
         WHERE epnd.id_epis_pn_det = item.id_epis_pn_det;
    END LOOP;

END;
/
-- CHANGE END: António Neto