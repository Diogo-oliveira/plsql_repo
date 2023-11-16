/*-- Last Change Revision: $Rev: 2028448 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:50 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_alerts_api_crm IS

    /*
    * Sets notifications for a given alert
    *
    * @param     i_sys_alert   Alert id
    
    * @return    String
    *
    * @author    Rui Duarte
    * @version   2.6
    * @since     2011/03/01
    */

    PROCEDURE set_notification
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_sys_alert        IN sys_alert.id_sys_alert%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    );

    /*
    * Deletes notifications for a given alert
    *
    * @param     i_sys_alert   Alert id
    
    * @author    Ana Matos
    * @version   2.7.4.0
    * @since     2018/09/10
    */

    PROCEDURE delete_notification(i_sys_alert_event IN table_number);

    /*
    * Processes notifications that are for a future date
    
    * @author    Ana Matos
    * @version   2.8.4.0
    * @since     2022/01/24
    */

    PROCEDURE process_notification;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

END pk_alerts_api_crm;
/
