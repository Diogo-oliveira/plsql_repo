-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 13/01/2014 14:30
-- CHANGE REASON: [ALERT-273247] 
BEGIN

    UPDATE vital_signs_ea a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

    UPDATE vital_sign_read a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

    UPDATE vital_sign_read_hist a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign_read IN (SELECT b.id_vital_sign_read
                                      FROM vital_sign_read b
                                     WHERE b.id_unit_measure = 25
                                       AND b.id_vital_sign IN (12, 13, 14, 18));

    UPDATE vital_sign_unit_measure a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

    UPDATE vs_soft_inst a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

    UPDATE vs_unit_measure_inst a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

    UPDATE vs_unit_measure_mkt a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

END;
/
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 13/01/2014 14:31
-- CHANGE REASON: [ALERT-273602] 
BEGIN

    UPDATE vital_signs_ea a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

    UPDATE vital_sign_read a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

    UPDATE vital_sign_read_hist a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign_read IN (SELECT b.id_vital_sign_read
                                      FROM vital_sign_read b
                                     WHERE b.id_unit_measure = 25
                                       AND b.id_vital_sign IN (12, 13, 14, 18));

    UPDATE vital_sign_unit_measure a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

    UPDATE vs_soft_inst a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

    UPDATE vs_unit_measure_inst a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

    UPDATE vs_unit_measure_mkt a
       SET a.id_unit_measure = NULL
     WHERE a.id_unit_measure = 25
       AND a.id_vital_sign IN (12, 13, 14, 18);

END;
/
-- CHANGE END: Paulo Teixeira