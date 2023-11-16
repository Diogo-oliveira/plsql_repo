-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 
-- CHANGE REASON: [ALERT-173188] Constraints, Comments and Migrations - Update functionality positionings to function with detail and history

DECLARE

BEGIN
    FOR item IN (
                 
                 SELECT posit.id_epis_positioning,
                         CASE
                              WHEN dt_exec_min > dt_status
                                   OR dt_status IS NULL THEN
                               dt_exec_min
                              ELSE
                               dt_status
                          END dt_to_update,
                         CASE
                              WHEN dt_exec_min > dt_status
                                   OR dt_status IS NULL THEN
                               (SELECT epp.id_prof_exec
                                  FROM epis_positioning_plan epp
                                 INNER JOIN epis_positioning_det epd ON epd.id_epis_positioning_det =
                                                                        epp.id_epis_positioning_det
                                                                    AND epp.dt_execution_tstz IS NOT NULL
                                 WHERE epd.id_epis_positioning = posit.id_epis_positioning
                                   AND epp.dt_execution_tstz = posit.dt_exec_min)
                              ELSE
                               id_prof
                          END id_prof_to_update
                 
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
                                 decode(ep.flg_status,
                                        'R',
                                        ep.id_professional,
                                        'D',
                                        ep.id_professional,
                                        'L',
                                        ep.id_prof_cancel,
                                        'C',
                                        ep.id_prof_cancel,
                                        'I',
                                        ep.id_prof_inter) id_prof,
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
                                    ep.flg_status,
                                    ep.id_professional,
                                    ep.id_prof_cancel,
                                    ep.id_prof_inter) posit)
    LOOP
        UPDATE epis_positioning_det epd
           SET epd.dt_epis_positioning_det = item.dt_to_update,
               epd.flg_outdated            = 'N',
               epd.id_prof_last_upd        = item.id_prof_to_update
         WHERE epd.id_epis_positioning = item.id_epis_positioning;
    END LOOP;

END;
/
-- CHANGE END: António Neto


-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 12:10
-- CHANGE REASON: [ALERT-173188] Constraints, Comments and Migrations - Update functionality positionings to function with detail and history

DECLARE

BEGIN
    FOR item IN (
                 
                 SELECT posit.id_epis_positioning,
                         CASE
                              WHEN dt_exec_min > dt_status
                                   OR dt_status IS NULL THEN
                               dt_exec_min
                              ELSE
                               dt_status
                          END dt_to_update,
                         CASE
                              WHEN dt_exec_min > dt_status
                                   OR dt_status IS NULL THEN
                               (SELECT epp.id_prof_exec
                                  FROM epis_positioning_plan epp
                                 INNER JOIN epis_positioning_det epd ON epd.id_epis_positioning_det =
                                                                        epp.id_epis_positioning_det
                                                                    AND epp.dt_execution_tstz IS NOT NULL
                                 WHERE epd.id_epis_positioning = posit.id_epis_positioning
                                   AND epp.dt_execution_tstz = posit.dt_exec_min)
                              ELSE
                               id_prof
                          END id_prof_to_update
                 
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
                                 decode(ep.flg_status,
                                        'R',
                                        ep.id_professional,
                                        'D',
                                        ep.id_professional,
                                        'L',
                                        ep.id_prof_cancel,
                                        'C',
                                        ep.id_prof_cancel,
                                        'I',
                                        ep.id_prof_inter) id_prof,
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
                                    ep.flg_status,
                                    ep.id_professional,
                                    ep.id_prof_cancel,
                                    ep.id_prof_inter) posit)
    LOOP
        UPDATE epis_positioning_det epd
           SET epd.dt_epis_positioning_det = item.dt_to_update,
               epd.flg_outdated            = 'N',
               epd.id_prof_last_upd        = item.id_prof_to_update
         WHERE epd.id_epis_positioning = item.id_epis_positioning;
    END LOOP;

END;
/
-- CHANGE END: António Neto


-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 13:45
-- CHANGE REASON: [ALERT-173847] Constraints, Comments and Migrations - Update functionality positionings to function with detail and history

DECLARE

BEGIN
    FOR item IN (
                 
                 SELECT posit.id_epis_positioning,
                         CASE
                              WHEN dt_exec_min > dt_status
                                   OR dt_status IS NULL THEN
                               dt_exec_min
                              ELSE
                               dt_status
                          END dt_to_update,
                         CASE
                              WHEN dt_exec_min > dt_status
                                   OR dt_status IS NULL THEN
                               (SELECT epp.id_prof_exec
                                  FROM epis_positioning_plan epp
                                 INNER JOIN epis_positioning_det epd ON epd.id_epis_positioning_det =
                                                                        epp.id_epis_positioning_det
                                                                    AND epp.dt_execution_tstz IS NOT NULL
                                 WHERE epd.id_epis_positioning = posit.id_epis_positioning
                                   AND epp.dt_execution_tstz = posit.dt_exec_min)
                              ELSE
                               id_prof
                          END id_prof_to_update
                 
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
                                 decode(ep.flg_status,
                                        'R',
                                        ep.id_professional,
                                        'D',
                                        ep.id_professional,
                                        'L',
                                        ep.id_prof_cancel,
                                        'C',
                                        ep.id_prof_cancel,
                                        'I',
                                        ep.id_prof_inter) id_prof,
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
                                    ep.flg_status,
                                    ep.id_professional,
                                    ep.id_prof_cancel,
                                    ep.id_prof_inter) posit)
    LOOP
        UPDATE epis_positioning_det epd
           SET epd.dt_epis_positioning_det = item.dt_to_update,
               epd.flg_outdated            = 'N',
               epd.id_prof_last_upd        = item.id_prof_to_update
         WHERE epd.id_epis_positioning = item.id_epis_positioning;
    END LOOP;

END;
/
-- CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 14:45
-- CHANGE REASON: [ALERT-173847] Constraints, Comments and Migrations - Update functionality positionings to function with detail and history

DECLARE

BEGIN
    FOR item IN (
                 
                 SELECT posit.id_epis_positioning,
                         CASE
                              WHEN dt_exec_min > dt_status
                                   OR dt_status IS NULL THEN
                               dt_exec_min
                              ELSE
                               dt_status
                          END dt_to_update,
                         CASE
                              WHEN dt_exec_min > dt_status
                                   OR dt_status IS NULL THEN
                               (SELECT epp.id_prof_exec
                                  FROM epis_positioning_plan epp
                                 INNER JOIN epis_positioning_det epd ON epd.id_epis_positioning_det =
                                                                        epp.id_epis_positioning_det
                                                                    AND epp.dt_execution_tstz IS NOT NULL
                                 WHERE epd.id_epis_positioning = posit.id_epis_positioning
                                   AND epp.dt_execution_tstz = posit.dt_exec_min)
                              ELSE
                               id_prof
                          END id_prof_to_update
                 
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
                                 decode(ep.flg_status,
                                        'R',
                                        ep.id_professional,
                                        'D',
                                        ep.id_professional,
                                        'L',
                                        ep.id_prof_cancel,
                                        'C',
                                        ep.id_prof_cancel,
                                        'I',
                                        ep.id_prof_inter) id_prof,
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
                                    ep.flg_status,
                                    ep.id_professional,
                                    ep.id_prof_cancel,
                                    ep.id_prof_inter) posit)
    LOOP
        UPDATE epis_positioning_det epd
           SET epd.dt_epis_positioning_det = item.dt_to_update,
               epd.flg_outdated            = nvl(epd.flg_outdated, 'N'),
               epd.id_prof_last_upd        = item.id_prof_to_update
         WHERE epd.id_epis_positioning = item.id_epis_positioning
				 and epd.dt_epis_positioning_det is null;
    END LOOP;

END;
/
-- CHANGE END: António Neto
