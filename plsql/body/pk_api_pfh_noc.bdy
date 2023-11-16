/*-- Last Change Revision: $Rev: 2026717 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:40 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_api_pfh_noc IS

    FUNCTION get_pfh_information RETURN VARCHAR2 IS
    
        l_str VARCHAR2(1000 CHAR);
    
    BEGIN
    
        SELECT pk_api_pfh_noc.get_episodes || pk_api_pfh_noc.get_orders || pk_api_pfh_noc.get_prescriptions ||
               pk_api_pfh_noc.get_order_sets
          INTO l_str
          FROM dual;
    
        RETURN l_str;
    
    END get_pfh_information;

    FUNCTION get_episodes RETURN VARCHAR2 IS
    
        l_epis_count VARCHAR2(1000 CHAR);
        l_epis_edis  VARCHAR2(1000 CHAR);
        l_epis_inp   VARCHAR2(1000 CHAR);
        l_epis_outp  VARCHAR2(1000 CHAR);
        l_epis_oris  VARCHAR2(1000 CHAR);
    
        l_str VARCHAR2(1000 CHAR);
    
    BEGIN
    
        BEGIN
            SELECT COUNT(*)
              INTO l_epis_count
              FROM episode e, epis_info ei
             WHERE e.flg_status = pk_alert_constant.g_active
               AND e.dt_begin_tstz > current_timestamp - 1
               AND EXISTS (SELECT 1
                      FROM institution i, software_institution si
                     WHERE i.id_institution = e.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes
                       AND i.id_institution = si.id_institution
                       AND si.id_software = ei.id_software
                       AND si.flg_noc = pk_alert_constant.g_yes)
               AND e.id_episode = ei.id_episode
               AND ei.id_software IN (pk_alert_constant.g_soft_edis,
                                      pk_alert_constant.g_soft_inpatient,
                                      pk_alert_constant.g_soft_outpatient,
                                      pk_alert_constant.g_soft_oris);
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    
        BEGIN
            SELECT 1
              INTO l_epis_edis
              FROM software_institution si
             WHERE si.id_software = pk_alert_constant.g_soft_edis
               AND si.flg_noc = pk_alert_constant.g_yes
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = si.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND rownum = 1;
        
            SELECT '!EDIS: ' || COUNT(*)
              INTO l_epis_edis
              FROM episode e, epis_info ei
             WHERE e.flg_status = pk_alert_constant.g_active
               AND e.dt_begin_tstz > current_timestamp - 1
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = e.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND e.id_episode = ei.id_episode
               AND ei.id_software = pk_alert_constant.g_soft_edis;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_edis := '';
        END;
    
        BEGIN
            SELECT 1
              INTO l_epis_inp
              FROM software_institution si
             WHERE si.id_software = pk_alert_constant.g_soft_inpatient
               AND si.flg_noc = pk_alert_constant.g_yes
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = si.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND rownum = 1;
        
            SELECT '!INPATIENT: ' || COUNT(*)
              INTO l_epis_inp
              FROM episode e, epis_info ei
             WHERE e.flg_status = pk_alert_constant.g_active
               AND e.dt_begin_tstz > current_timestamp - 1
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = e.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND e.id_episode = ei.id_episode
               AND ei.id_software = pk_alert_constant.g_soft_inpatient;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_inp := '';
        END;
    
        BEGIN
            SELECT 1
              INTO l_epis_outp
              FROM software_institution si
             WHERE si.id_software = pk_alert_constant.g_soft_outpatient
               AND si.flg_noc = pk_alert_constant.g_yes
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = si.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND rownum = 1;
        
            SELECT '!OUTPATIENT: ' || COUNT(*)
              INTO l_epis_outp
              FROM episode e, epis_info ei
             WHERE e.flg_status = pk_alert_constant.g_active
               AND e.dt_begin_tstz > current_timestamp - 1
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = e.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND e.id_episode = ei.id_episode
               AND ei.id_software = pk_alert_constant.g_soft_outpatient;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_outp := '';
        END;
    
        BEGIN
            SELECT 1
              INTO l_epis_oris
              FROM software_institution si
             WHERE si.id_software = pk_alert_constant.g_soft_oris
               AND si.flg_noc = pk_alert_constant.g_yes
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = si.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND rownum = 1;
        
            SELECT '!ORIS: ' || COUNT(*)
              INTO l_epis_oris
              FROM episode e, epis_info ei
             WHERE e.flg_status = pk_alert_constant.g_active
               AND e.dt_begin_tstz > current_timestamp - 1
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = e.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND e.id_episode = ei.id_episode
               AND ei.id_software = pk_alert_constant.g_soft_oris;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_oris := '';
        END;
    
        IF l_epis_count > 0
        THEN
            l_str := 'Active episodes: ' || l_epis_count || l_epis_edis || l_epis_inp || l_epis_outp || l_epis_oris;
        
            RETURN l_str;
        ELSE
            RETURN NULL;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_episodes;

    FUNCTION get_orders RETURN VARCHAR2 IS
    
        l_count NUMBER;
        l_lab   NUMBER;
        l_exm   NUMBER;
    
        l_lab_str VARCHAR2(1000 CHAR);
        l_exm_str VARCHAR2(1000 CHAR);
    
        l_str VARCHAR2(1000 CHAR);
    
    BEGIN
    
        l_count := pk_api_pfh_noc.get_lab_tests + pk_api_pfh_noc.get_exams;
    
        IF l_count > 0
        THEN
            l_lab := pk_api_pfh_noc.get_lab_tests;
            l_exm := pk_api_pfh_noc.get_exams;
        
            IF l_lab > 0
            THEN
                l_lab_str := '!LAB: ' || l_lab;
            END IF;
        
            IF l_exm > 0
            THEN
                l_exm_str := '!EXAM: ' || l_exm;
            END IF;
        
            SELECT '! !Requests: ' || l_count || l_lab_str || l_exm_str
              INTO l_str
              FROM dual;
        END IF;
    
        RETURN l_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_orders;

    FUNCTION get_lab_tests RETURN NUMBER IS
    
        l_count NUMBER;
    
    BEGIN
    
        BEGIN
            SELECT COUNT(*) lab_count
              INTO l_count
              FROM analysis_req ar
             WHERE ar.flg_status NOT IN ('PD', 'X', 'P', 'F', 'LP', 'L', 'C')
               AND ar.dt_req_tstz > current_timestamp - 2
               AND EXISTS (SELECT 1
                      FROM institution i, software_institution si
                     WHERE i.id_institution = ar.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes
                       AND i.id_institution = si.id_institution
                       AND si.flg_noc = pk_alert_constant.g_yes);
        EXCEPTION
            WHEN no_data_found THEN
                l_count := NULL;
        END;
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_tests;

    FUNCTION get_exams RETURN NUMBER IS
    
        l_count NUMBER;
    
    BEGIN
    
        BEGIN
            SELECT COUNT(*) exam_count
              INTO l_count
              FROM exam_req er
             WHERE er.flg_status NOT IN ('PD', 'X', 'P', 'F', 'LP', 'L', 'C')
               AND er.dt_req_tstz > current_timestamp - 2
               AND EXISTS (SELECT 1
                      FROM institution i, software_institution si
                     WHERE i.id_institution = er.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes
                       AND i.id_institution = si.id_institution
                       AND si.flg_noc = pk_alert_constant.g_yes);
        EXCEPTION
            WHEN no_data_found THEN
                l_count := NULL;
        END;
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exams;

    FUNCTION get_prescriptions RETURN VARCHAR2 IS
    
        l_str VARCHAR2(1000 CHAR);
    
    BEGIN
    
        BEGIN
            SELECT '! !Prescription: ' || pk_api_pfh_in.get_prescriptions_noc(2) med_count
              INTO l_str
              FROM dual;
        EXCEPTION
            WHEN no_data_found THEN
                l_str := NULL;
        END;
    
        RETURN l_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prescriptions;

    FUNCTION get_order_sets RETURN VARCHAR2 IS
    
        l_os_all  NUMBER;
        l_os_edis NUMBER;
        l_os_inp  NUMBER;
        l_os_outp NUMBER;
        l_os_oris NUMBER;
    
        l_str VARCHAR2(1000 CHAR);
    
    BEGIN
    
        BEGIN
            SELECT COUNT(*) os_count
              INTO l_os_all
              FROM order_set os
             WHERE os.flg_status = pk_order_sets.g_order_set_finished
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = os.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND os.id_software = pk_alert_constant.g_soft_all;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    
        BEGIN
            SELECT 1
              INTO l_os_edis
              FROM software_institution si
             WHERE si.id_software = pk_alert_constant.g_soft_edis
               AND si.flg_noc = pk_alert_constant.g_yes
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = si.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND rownum = 1;
        
            SELECT COUNT(*) + l_os_all os_count
              INTO l_os_edis
              FROM order_set os
             WHERE os.flg_status = pk_order_sets.g_order_set_finished
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = os.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND os.id_software = pk_alert_constant.g_soft_edis;
        EXCEPTION
            WHEN no_data_found THEN
                l_os_edis := 0;
        END;
    
        BEGIN
            SELECT 1
              INTO l_os_inp
              FROM software_institution si
             WHERE si.id_software = pk_alert_constant.g_soft_inpatient
               AND si.flg_noc = pk_alert_constant.g_yes
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = si.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND rownum = 1;
        
            SELECT COUNT(*) + l_os_all os_count
              INTO l_os_inp
              FROM order_set os
             WHERE os.flg_status = pk_order_sets.g_order_set_finished
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = os.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND os.id_software = pk_alert_constant.g_soft_inpatient;
        EXCEPTION
            WHEN no_data_found THEN
                l_os_inp := 0;
        END;
    
        BEGIN
            SELECT 1
              INTO l_os_outp
              FROM software_institution si
             WHERE si.id_software = pk_alert_constant.g_soft_outpatient
               AND si.flg_noc = pk_alert_constant.g_yes
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = si.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND rownum = 1;
        
            SELECT COUNT(*) + l_os_all os_count
              INTO l_os_outp
              FROM order_set os
             WHERE os.flg_status = pk_order_sets.g_order_set_finished
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = os.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND os.id_software = pk_alert_constant.g_soft_outpatient;
        EXCEPTION
            WHEN no_data_found THEN
                l_os_outp := 0;
        END;
    
        BEGIN
            SELECT 1
              INTO l_os_oris
              FROM software_institution si
             WHERE si.id_software = pk_alert_constant.g_soft_oris
               AND si.flg_noc = pk_alert_constant.g_yes
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = si.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND rownum = 1;
        
            SELECT COUNT(*) + l_os_all os_count
              INTO l_os_oris
              FROM order_set os
             WHERE os.flg_status = pk_order_sets.g_order_set_finished
               AND EXISTS (SELECT 1
                      FROM institution i
                     WHERE i.id_institution = os.id_institution
                       AND i.flg_available = pk_alert_constant.g_yes)
               AND os.id_software = pk_alert_constant.g_soft_oris;
        EXCEPTION
            WHEN no_data_found THEN
                l_os_oris := 0;
        END;
    
        l_os_all := l_os_edis + l_os_inp + l_os_outp + l_os_oris;
    
        l_str := '! !Order Sets: ' || l_os_all;
    
        IF l_os_edis != 0
        THEN
            l_str := l_str || '!EDIS:  ' || l_os_edis;
        END IF;
    
        IF l_os_inp != 0
        THEN
            l_str := l_str || '!INPATIENT:  ' || l_os_inp;
        END IF;
    
        IF l_os_outp != 0
        THEN
            l_str := l_str || '!OUTPATIENT:  ' || l_os_outp;
        END IF;
    
        IF l_os_oris != 0
        THEN
            l_str := l_str || '!ORIS:  ' || l_os_oris;
        END IF;
    
        RETURN l_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_order_sets;

END pk_api_pfh_noc;
/
