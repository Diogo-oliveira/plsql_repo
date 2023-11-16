


-- CHANGED BY: Adriana Salgueiro
-- CHANGED DATE: 2021-4-20
-- CHANGED REASON: EMR-44191

grant select on ALERT.ALLERGY to ALERT_DEFAULT;
grant references on ALERT.ALLERGY to ALERT_DEFAULT;
-- CHANGE END: Adriana Salgueiro

-- CHANGED BY: Pedro Pacheco
-- CHANGED DATE: 2022-2-20
-- CHANGED REASON: EMR-17325
grant select, insert, update on ALERT.ALLERGY to alert_core_cnt;
-- CHANGE END: Pedro Pacheco
