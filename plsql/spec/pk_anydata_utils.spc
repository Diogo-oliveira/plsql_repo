/*-- Last Change Revision: $Rev: 2028456 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_anydata_utils IS
    -- Author  : ARIEL.MACHADO
    -- Created : 10-Feb-09 3:07:33 PM
    -- Purpose : Wrapper functions to effectively use anyData type

    /********************************************************************************************
    * Returns timestamp value from an anydata
    * 
    * @param val                      Anydata object                                                                                              
    * @return                         Value in a TIMESTAMP data type
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/22                                                                                               
    ********************************************************************************************/
    FUNCTION get_timestamp(val IN anydata) RETURN TIMESTAMP;

    /********************************************************************************************
    * Returns timestamp with time zone value from an anydata
    * 
    * @param val                      Anydata object                                                                                              
    * @return                         Value in a TIMESTAMP WITH TIMEZONE data type
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/22                                                                                               
    ********************************************************************************************/
    FUNCTION get_timestamp_tz(val IN anydata) RETURN TIMESTAMP
        WITH TIME ZONE;

    /********************************************************************************************
    * Returns number value from an anydata
    * 
    * @param val                      Anydata object                                                                                              
    * @return                         Value in a NUMBER data type
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/22                                                                                               
    ********************************************************************************************/
    FUNCTION get_number(val IN anydata) RETURN NUMBER;

    /********************************************************************************************
    * Returns date value from an anydata
    * 
    * @param val                      Anydata object                                                                                              
    * @return                         Value in a DATE data type
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/22                                                                                               
    ********************************************************************************************/
    FUNCTION get_date(val IN anydata) RETURN DATE;

    /********************************************************************************************
    * Returns varchar2 value from an anydata
    * 
    * @param val                      Anydata object                                                                                              
    * @return                         Value in a VARCHAR2 data type
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/22                                                                                               
    ********************************************************************************************/
    FUNCTION get_varchar2(val IN sys.anydata) RETURN VARCHAR2;

END pk_anydata_utils;
/
