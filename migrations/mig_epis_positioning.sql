-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 
-- CHANGE REASON: [ALERT-173188] Constraints, Comments and Migrations - Update functionality positionings to function with detail and history

DECLARE

BEGIN
    FOR item IN (SELECT id_epis_positioning,
                        CASE
                             WHEN dt_exec_min > dt_status
                                  OR dt_status IS NULL THEN
                              dt_exec_min
                             ELSE
                              dt_status
                         END dt_to_update
                   FROM (SELECT ep.id_epis_positioning,
                                decode(ep.flg_status,
                                       'R',
                                       ep.dt_creation_tstz,
                                       'D',
                                       ep.dt_creation_tstz,
                                       'L',
                                       ep.dt_cancel_tstz,
                                       'C',
                                       ep.dt_cancel_tstz,
                                       'I',
                                       ep.dt_inter_tstz) dt_status,
                                MIN(epp.dt_execution_tstz) dt_exec_min
                           FROM epis_positioning ep
                          INNER JOIN epis_positioning_det epd ON ep.id_epis_positioning = epd.id_epis_positioning
                           LEFT OUTER JOIN epis_positioning_plan epp ON epd.id_epis_positioning_det =
                                                                        epp.id_epis_positioning_det
                                                                    AND epp.dt_execution_tstz IS NOT NULL
                          GROUP BY ep.id_epis_positioning,
                                   ep.dt_creation_tstz,
                                   ep.dt_cancel_tstz,
                                   ep.dt_inter_tstz,
                                   ep.flg_status) posit)
    LOOP
        UPDATE epis_positioning ep
           SET ep.dt_epis_positioning = item.dt_to_update
         WHERE ep.id_epis_positioning = item.id_epis_positioning;
    END LOOP;

END;
/

-- CHANGE END: António Neto


-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 12:07
-- CHANGE REASON: [ALERT-173188] Constraints, Comments and Migrations - Update functionality positionings to function with detail and history

DECLARE

BEGIN
    FOR item IN (SELECT id_epis_positioning,
                        CASE
                             WHEN dt_exec_min > dt_status
                                  OR dt_status IS NULL THEN
                              dt_exec_min
                             ELSE
                              dt_status
                         END dt_to_update
                   FROM (SELECT ep.id_epis_positioning,
                                decode(ep.flg_status,
                                       'R',
                                       ep.dt_creation_tstz,
                                       'D',
                                       ep.dt_creation_tstz,
                                       'L',
                                       ep.dt_cancel_tstz,
                                       'C',
                                       ep.dt_cancel_tstz,
                                       'I',
                                       ep.dt_inter_tstz) dt_status,
                                MIN(epp.dt_execution_tstz) dt_exec_min
                           FROM epis_positioning ep
                          INNER JOIN epis_positioning_det epd ON ep.id_epis_positioning = epd.id_epis_positioning
                           LEFT OUTER JOIN epis_positioning_plan epp ON epd.id_epis_positioning_det =
                                                                        epp.id_epis_positioning_det
                                                                    AND epp.dt_execution_tstz IS NOT NULL
                          GROUP BY ep.id_epis_positioning,
                                   ep.dt_creation_tstz,
                                   ep.dt_cancel_tstz,
                                   ep.dt_inter_tstz,
                                   ep.flg_status) posit)
    LOOP
        UPDATE epis_positioning ep
           SET ep.dt_epis_positioning = item.dt_to_update
         WHERE ep.id_epis_positioning = item.id_epis_positioning;
    END LOOP;

END;
/

-- CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 13:47
-- CHANGE REASON: [ALERT-173847] Constraints, Comments and Migrations - Update functionality positionings to function with detail and history

DECLARE

BEGIN
    FOR item IN (SELECT id_epis_positioning,
                        CASE
                             WHEN dt_exec_min > dt_status
                                  OR dt_status IS NULL THEN
                              dt_exec_min
                             ELSE
                              dt_status
                         END dt_to_update
                   FROM (SELECT ep.id_epis_positioning,
                                decode(ep.flg_status,
                                       'R',
                                       ep.dt_creation_tstz,
                                       'D',
                                       ep.dt_creation_tstz,
                                       'L',
                                       ep.dt_cancel_tstz,
                                       'C',
                                       ep.dt_cancel_tstz,
                                       'I',
                                       ep.dt_inter_tstz) dt_status,
                                MIN(epp.dt_execution_tstz) dt_exec_min
                           FROM epis_positioning ep
                          INNER JOIN epis_positioning_det epd ON ep.id_epis_positioning = epd.id_epis_positioning
                           LEFT OUTER JOIN epis_positioning_plan epp ON epd.id_epis_positioning_det =
                                                                        epp.id_epis_positioning_det
                                                                    AND epp.dt_execution_tstz IS NOT NULL
                          GROUP BY ep.id_epis_positioning,
                                   ep.dt_creation_tstz,
                                   ep.dt_cancel_tstz,
                                   ep.dt_inter_tstz,
                                   ep.flg_status) posit)
    LOOP
        UPDATE epis_positioning ep
           SET ep.dt_epis_positioning = item.dt_to_update
         WHERE ep.id_epis_positioning = item.id_epis_positioning;
    END LOOP;

END;
/

-- CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 14:15
-- CHANGE REASON: [ALERT-173847] Constraints, Comments and Migrations - Update functionality positionings to function with detail and history

DECLARE

BEGIN
    FOR item IN (SELECT id_epis_positioning,
                        CASE
                             WHEN dt_exec_min > dt_status
                                  OR dt_status IS NULL THEN
                              dt_exec_min
                             ELSE
                              dt_status
                         END dt_to_update
                   FROM (SELECT ep.id_epis_positioning,
                                decode(ep.flg_status,
                                       'R',
                                       ep.dt_creation_tstz,
                                       'D',
                                       ep.dt_creation_tstz,
                                       'L',
                                       ep.dt_cancel_tstz,
                                       'C',
                                       ep.dt_cancel_tstz,
                                       'I',
                                       ep.dt_inter_tstz) dt_status,
                                MIN(epp.dt_execution_tstz) dt_exec_min
                           FROM epis_positioning ep
                          INNER JOIN epis_positioning_det epd ON ep.id_epis_positioning = epd.id_epis_positioning
                           LEFT OUTER JOIN epis_positioning_plan epp ON epd.id_epis_positioning_det =
                                                                        epp.id_epis_positioning_det
                                                                    AND epp.dt_execution_tstz IS NOT NULL
                          GROUP BY ep.id_epis_positioning,
                                   ep.dt_creation_tstz,
                                   ep.dt_cancel_tstz,
                                   ep.dt_inter_tstz,
                                   ep.flg_status) posit)
    LOOP
        UPDATE epis_positioning ep
           SET ep.dt_epis_positioning = item.dt_to_update
         WHERE ep.id_epis_positioning = item.id_epis_positioning
				 and ep.dt_epis_positioning is null;
    END LOOP;

END;
/

-- CHANGE END: António Neto
