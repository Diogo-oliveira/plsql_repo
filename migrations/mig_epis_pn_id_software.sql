-- CHANGED BY: Anna Kurowska
-- CHANGE DATE: 04/02/2013
-- CHANGE REASON: [ALERT-250386] Progress notes error
BEGIN
    BEGIN
        UPDATE epis_pn epn
           SET epn.id_software =
               (SELECT ei.id_software
                  FROM epis_info ei
                 WHERE ei.id_episode = epn.id_episode)
         WHERE epn.id_software IS NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, 'ERROR updating id_software in epis_pn table');
    END;

    BEGIN
        UPDATE epis_pn_hist epnh
           SET epnh.id_software =
               (SELECT ei.id_software
                  FROM epis_info ei
                 WHERE ei.id_episode = epnh.id_episode)
         WHERE epnh.id_software IS NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, 'ERROR updating id_software in epis_pn_hist table');
    END;

    BEGIN
        UPDATE epis_pn epn
           SET epn.id_software =
               (SELECT etsi.id_software
                  FROM episode e
                  JOIN epis_type_soft_inst etsi
                    ON e.id_epis_type = etsi.id_epis_type
                 WHERE e.id_episode = epn.id_episode
                   AND rownum = 1)
         WHERE epn.id_software IS NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, 'ERROR updating id_software in epis_pn table from epis_type_soft_inst');
    END;
   
    BEGIN
        UPDATE epis_pn_hist epnh
           SET epnh.id_software =
               (SELECT etsi.id_software
                  FROM episode e
                  JOIN epis_type_soft_inst etsi
                    ON e.id_epis_type = etsi.id_epis_type
                 WHERE e.id_episode = epnh.id_episode
                   AND rownum = 1)
         WHERE epnh.id_software IS NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001, 'ERROR updating id_software in epis_pn_hist table from epis_type_soft_inst');
    END; 
    
END;
/

--CHANGE END: Anna Kurowska
