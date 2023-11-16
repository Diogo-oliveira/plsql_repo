/*-- Last Change Revision: $Rev: 2045600 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-09-19 18:27:53 +0100 (seg, 19 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_noc_alarms AS

    /********************************************************************************************
    * pk_noc_alarms.cm_validate_crisis_log returns the status of the crisis_log
    * in the Crisis Machine Application
    *
    * @param  i_id_crisis_machine  Crisis Machine ID (Mandatory)
    * @param  i_search_hours       Number of hours to search (Mandatory)
    *
    * @author      gilberto.rocha
    * @version     2.8.1.6
    * @since       24/07/2020 
    *
    ********************************************************************************************/
    FUNCTION cm_validate_crisis_log
    (
        i_id_crisis_machine IN NUMBER,
        i_search_hours      IN NUMBER,
        i_error_threshold   IN NUMBER DEFAULT 0
    ) RETURN VARCHAR2 IS
    
        l_number_error NUMBER;
    
    BEGIN
    
        IF i_search_hours IS NULL
           OR i_search_hours <= 0
        THEN
            RETURN 'i_search_hours has to be higher than 0: Please give a valid value!|2';
        END IF;
    
        SELECT COUNT(*)
          INTO l_number_error
          FROM crisis_log
         WHERE id_crisis_machine = i_id_crisis_machine
           AND flg_status = 'E'
           AND dt_upd_end_tstz > CAST(SYSDATE - i_search_hours / 24 AS TIMESTAMP WITH LOCAL TIME ZONE);
    
        IF l_number_error > i_error_threshold
        THEN
            RETURN 'Crisis machine ' || i_id_crisis_machine || ' has ' || l_number_error || ' errors in the last ' || i_search_hours || ' hour(s)|2';
        ELSE
            RETURN 'Crisis machine ' || i_id_crisis_machine || ' don''t have errors in the last ' || i_search_hours || ' hour(s)|0';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLERRM || '|3';
    END cm_validate_crisis_log;

    /********************************************************************************************
    * pk_noc_alarms.cm_validate_crisis_epis returns the status of the crisis_epis
    * in the Crisis Machine Application
    *
    * @param  i_id_crisis_machine  Crisis Machine ID (Mandatory)
    * @param  i_search_hours       Number of hours to search (Mandatory)
    *
    * @author      gilberto.rocha
    * @version     2.8.1.6
    * @since       24/07/2020 
    *
    ********************************************************************************************/
    FUNCTION cm_validate_crisis_epis
    (
        i_id_crisis_machine IN NUMBER,
        i_search_hours      IN NUMBER,
        i_error_threshold   IN NUMBER DEFAULT 0
    ) RETURN VARCHAR2 IS
    
        l_number_error NUMBER;
    
    BEGIN
    
        IF i_search_hours IS NULL
           OR i_search_hours <= 0
        THEN
            RETURN 'i_search_hours has to be higher than 0: Please give a valid value!|2';
        END IF;
    
        SELECT COUNT(*)
          INTO l_number_error
          FROM crisis_epis
         WHERE id_crisis_machine = i_id_crisis_machine
           AND flg_status IN ('E', 'R')
           AND date_last_generated_tstz > CAST(SYSDATE - i_search_hours / 24 AS TIMESTAMP WITH LOCAL TIME ZONE);
    
        IF l_number_error > i_error_threshold
        THEN
            RETURN 'Crisis machine ' || i_id_crisis_machine || ' has ' || l_number_error || ' reports in ERROR or RETRY in the last ' || i_search_hours || ' hour(s)|2';
        ELSE
            RETURN 'Crisis machine ' || i_id_crisis_machine || ' don''t have any report in ERROR or RETRY in the last ' || i_search_hours || ' hour(s)|0';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLERRM || '|3';
    END cm_validate_crisis_epis;

    /********************************************************************************************
    * pk_noc_alarms.cm_validate_reports_status returns the number of reports in the crisis_epis
    * with a specific status
    * in the Crisis Machine Application
    *
    * @param  i_id_crisis_machine  Crisis Machine ID (Mandatory)
    * @param  i_status             Crisis Epis Status (Mandatory)
    * @param  i_threshold_warn     Threshold for warning
    * @param  i_threshold_crit     Threshold for critical
    *
    * @author      gilberto.rocha
    * @version     2.8.1.6
    * @since       24/07/2020 
    *
    ********************************************************************************************/
    FUNCTION cm_validate_reports_status
    (
        i_id_crisis_machine IN NUMBER,
        i_status            IN VARCHAR2,
        i_threshold_warn    IN NUMBER DEFAULT NULL,
        i_threshold_crit    IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_message        VARCHAR2(2000);
        l_number_reports NUMBER;
    
    BEGIN
    
        l_message := '';
    
        IF i_id_crisis_machine IS NULL
        THEN
            l_message := l_message || 'i_id_crisis_machine is mandatory: Please give a valid value!';
        END IF;
    
        IF i_status IS NULL
        THEN
            IF length(l_message) > 0
            THEN
                l_message := l_message || chr(10);
            END IF;
            l_message := l_message || 'i_status is mandatory: Please give a valid value!';
        END IF;
    
        IF i_threshold_warn IS NOT NULL
           AND i_threshold_warn <= 0
        THEN
            IF length(l_message) > 0
            THEN
                l_message := l_message || chr(10);
            END IF;
            l_message := 'i_threshold_warn has to be higher than 0: Please give a valid value!';
        END IF;
    
        IF i_threshold_crit IS NOT NULL
           AND i_threshold_crit <= 0
        THEN
            IF length(l_message) > 0
            THEN
                l_message := l_message || chr(10);
            END IF;
            l_message := l_message || 'i_threshold_crit has to be higher than 0: Please give a valid value!';
        END IF;
    
        IF i_threshold_warn IS NOT NULL
           AND i_threshold_crit IS NOT NULL
           AND i_threshold_crit <= i_threshold_warn
        THEN
            IF length(l_message) > 0
            THEN
                l_message := l_message || chr(10);
            END IF;
            l_message := l_message ||
                         'i_threshold_crit has to be higher than i_threshold_warn: Please give a valid value!';
        END IF;
    
        IF length(l_message) > 0
        THEN
            RETURN l_message || '|2';
        END IF;
    
        SELECT COUNT(*)
          INTO l_number_reports
          FROM crisis_epis
         WHERE id_crisis_machine = i_id_crisis_machine
           AND flg_status = i_status;
    
        l_message := 'Number of reports with status ''' || i_status || ''': ' || l_number_reports;
    
        IF i_threshold_crit IS NOT NULL
           AND l_number_reports >= i_threshold_crit
        THEN
            l_message := l_message || '|2';
        ELSIF i_threshold_warn IS NOT NULL
              AND l_number_reports >= i_threshold_warn
        THEN
            l_message := l_message || '|1';
        ELSE
            l_message := l_message || '|0';
        END IF;
    
        RETURN l_message;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 'No reports found|0';
        WHEN OTHERS THEN
            RETURN SQLERRM || '|3';
    END cm_validate_reports_status;

END pk_noc_alarms;
/
