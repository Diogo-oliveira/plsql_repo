/*-- Last Change Revision: $Rev: 2028487 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:06 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_api_pfh_noc IS

    /*
    * Returns the information to show in the NOC
    
    * @return    String
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/08/06
    */

    FUNCTION get_pfh_information RETURN VARCHAR2;

    /*
    * Returns the number of active episodes
    
    * @return    String
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/08/06
    */

    FUNCTION get_episodes RETURN VARCHAR2;

    /*
    * Returns the number of orders
    
    * @return    String
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/08/06
    */

    FUNCTION get_orders RETURN VARCHAR2;

    /*
    * Returns the number of lab tests on going
    
    * @return    String
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/08/06
    */

    FUNCTION get_lab_tests RETURN NUMBER;

    /*
    * Returns the number of exams on going
    
    * @return    Number
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/08/06
    */

    FUNCTION get_exams RETURN NUMBER;

    /*
    * Returns the number of prescriptions on going
    
    * @return    Number
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/08/06
    */

    FUNCTION get_prescriptions RETURN VARCHAR2;

    /*
    * Returns the number of order sets configured in an institution
    
    * @return    Number
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/08/06
    */

    FUNCTION get_order_sets RETURN VARCHAR2;

END pk_api_pfh_noc;
/
