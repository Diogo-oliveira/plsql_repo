-- CHANGED BY: António Neto
-- CHANGE DATE: 17/Aug/2011 
-- CHANGE REASON: [ALERT-168848] H & P reformulation in INPATIENT (phase 2)
BEGIN

    UPDATE pn_dblock_mkt pndbm
       SET pndbm.flg_mandatory = 'Y'
     WHERE pndbm.id_pn_data_block IN (SELECT pndb.id_pn_data_block
                                        FROM pn_data_block pndb
                                       WHERE pndb.flg_type = 'C');

END;
/
-- CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 17/Aug/2011 
-- CHANGE REASON: [ALERT-168848] H & P reformulation in INPATIENT (phase 2)
BEGIN

    UPDATE pn_dblock_mkt pndbm
       SET pndbm.flg_mandatory = 'Y'
     WHERE pndbm.id_pn_data_block IN (SELECT pndb.id_pn_data_block
                                        FROM pn_data_block pndb
                                       WHERE pndb.flg_type = 'C');

END;
/
-- CHANGE END: António Neto
