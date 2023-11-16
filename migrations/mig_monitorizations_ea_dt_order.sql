-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 08/Set/2011 
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
BEGIN
    UPDATE monitorizations_ea m
       SET m.dt_order =
           (SELECT mvs.dt_order
              FROM monitorization_vs mvs
             WHERE mvs.id_monitorization_vs = m.id_monitorization_vs);
END;
/

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 08/Set/2011 
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
BEGIN
    UPDATE monitorizations_ea m
       SET m.dt_order =
           (SELECT mvs.dt_order
              FROM monitorization_vs mvs
             WHERE mvs.id_monitorization_vs = m.id_monitorization_vs);
END;
/
