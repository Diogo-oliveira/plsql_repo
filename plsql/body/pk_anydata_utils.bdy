/*-- Last Change Revision: $Rev: 2026650 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_anydata_utils IS

    --Wrapper functions to effectively use anyData type
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
    FUNCTION get_timestamp(val IN anydata) RETURN TIMESTAMP IS
        l_timestamp TIMESTAMP;
        x           PLS_INTEGER;
    BEGIN
        x := val.gettimestamp(l_timestamp);
        RETURN l_timestamp;
    END get_timestamp;

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
        WITH TIME ZONE IS
        l_timestamp TIMESTAMP WITH TIME ZONE;
        x           PLS_INTEGER;
    BEGIN
        x := val.gettimestamptz(l_timestamp);
        RETURN l_timestamp;
    END get_timestamp_tz;

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
    FUNCTION get_number(val IN anydata) RETURN NUMBER IS
        x     PLS_INTEGER;
        l_num NUMBER;
    BEGIN
        x := val.getnumber(l_num);
        RETURN l_num;
    END get_number;

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
    FUNCTION get_date(val IN anydata) RETURN DATE IS
        x      PLS_INTEGER;
        l_date DATE;
    BEGIN
        x := val.getdate(l_date);
        RETURN l_date;
    END get_date;

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
    FUNCTION get_varchar2(val IN sys.anydata) RETURN VARCHAR2 IS
        x          PLS_INTEGER;
        l_varchar2 VARCHAR2(32767);
    BEGIN
        x := val.getvarchar2(l_varchar2);
        RETURN l_varchar2;
    END get_varchar2;

END pk_anydata_utils;
/
