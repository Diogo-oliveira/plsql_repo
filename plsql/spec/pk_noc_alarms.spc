/*-- Last Change Revision: $Rev: 2045600 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-09-19 18:27:53 +0100 (seg, 19 set 2022) $*/

CREATE OR REPLACE PACKAGE pk_noc_alarms AS

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

END pk_noc_alarms;
/
