-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 14:20
-- CHANGE REASON: [ALERT-173847] Constraints, Comments and Migrations - Update functionality positionings to function with detail and history

DECLARE

BEGIN
    FOR item IN (SELECT epp.id_epis_positioning_plan,
                        nvl(decode(ep.flg_status,
                                    'R',
                                    ep.dt_creation_tstz,
                                    'D',
                                    ep.dt_creation_tstz,
                                    'L',
                                    ep.dt_cancel_tstz,
                                    'C',
                                    ep.dt_cancel_tstz,
                                    'I',
                                    ep.dt_inter_tstz,
                                    CASE
                                        WHEN epp.dt_execution_tstz IS NOT NULL THEN
                                         epp.dt_execution_tstz
                                        ELSE
                                         (SELECT MAX(epp1.dt_execution_tstz)
                                            FROM epis_positioning_det epd1
                                           INNER JOIN epis_positioning_plan epp1 ON epd1.id_epis_positioning_det =
                                                                                    epp1.id_epis_positioning_det
                                           WHERE epd1.id_epis_positioning = ep.id_epis_positioning
                                             AND epp1.dt_execution_tstz IS NOT NULL)
                                    
                                    END),
                             ep.dt_creation_tstz) dt_to_update
                   FROM epis_positioning ep
                  INNER JOIN epis_positioning_det epd ON ep.id_epis_positioning = epd.id_epis_positioning
                  INNER JOIN epis_positioning_plan epp ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                  WHERE epp.dt_epis_positioning_plan IS NULL)
    LOOP
        UPDATE epis_positioning_plan epp
           SET epp.dt_epis_positioning_plan = item.dt_to_update
         WHERE epp.id_epis_positioning_plan = item.id_epis_positioning_plan
           AND epp.dt_epis_positioning_plan IS NULL;
    END LOOP;

END;
/

-- CHANGE END: António Neto
