/*-- Last Change Revision: $Rev: 2028505 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_audit AS

    /**
    * When someone opens the application
    *
    * @param   i_ip    ip of the client machine
    *
    * @return  true or false on success or error
    * @author  Rui Rocha
    * @version alpha
    * @since  2007/01/11
    */

    FUNCTION OPEN(i_ip IN VARCHAR2) RETURN BOOLEAN;

    /**
    * When someone closes the application
    *
    * @param   i_ip    ip of the client machine
    *
    * @return  true or false on success or error
    * @author  Rui Rocha
    * @version alpha
    * @since  2007/01/11
    */

    FUNCTION CLOSE(i_ip IN VARCHAR2) RETURN BOOLEAN;

    /**
    * When someone logs in the application
    *
    * @param   i_username  username of the person
    * @param   i_ip      ip of the client machine
    * @param   i_success   success or unscuccess of the login
    *
    * @return  true or false on success or error
    * @author  Rui Rocha
    * @version alpha
    * @since  2007/01/11
    */
    FUNCTION login
    (
        i_username IN VARCHAR2,
        i_ip       IN VARCHAR2,
        i_success  IN VARCHAR2
    ) RETURN BOOLEAN;

END pk_audit;
/
