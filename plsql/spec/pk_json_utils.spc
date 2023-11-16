/*-- Last Change Revision: $Rev: 1965628 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2020-10-09 09:22:44 +0100 (sex, 09 out 2020) $*/

CREATE OR REPLACE PACKAGE pk_json_utils IS

    -- Author  : ARIEL.MACHADO
    -- Created : 12/6/2013 3:45:44 PM
    -- Purpose : Utility methods to handle JSON objects and extend the existing package JSON_EXT

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Converts a nested table to a JSON list
    *
    * @param    i_table_number      Nested table
    *
    * @return   A json_array_t object
    *
    * @author   ARIEL.MACHADO
    * @version 
    * @since    12/5/2013
    */
    FUNCTION to_json_list(i_table_number IN table_number) RETURN json_array_t;

    /**
    * Converts a nested table to a JSON list
    *
    * @param    i_table_varchar      Nested table
    *
    * @return   A json_array_t object
    *
    * @author   ARIEL.MACHADO
    * @version 
    * @since    12/5/2013
    */
    FUNCTION to_json_list(i_table_varchar IN table_varchar) RETURN json_array_t;

    /**
    * Converts a nested table to a JSON list
    *
    * @param    i_table_table_number    Two-dim nested table
    *
    * @return   A json_array_t object
    *
    * @author   ARIEL.MACHADO
    * @version 
    * @since    9/12/2014
    */
    FUNCTION to_json_list(i_table_table_number IN table_table_number) RETURN json_array_t;

    /**
    * Converts a nested table to a JSON list
    *
    * @param    i_table_table_varchar   Two-dim nested table
    *
    * @return   A json_array_t object
    *
    * @author   ARIEL.MACHADO
    * @version 
    * @since    9/12/2014
    */
    FUNCTION to_json_list(i_table_table_varchar IN table_table_varchar) RETURN json_array_t;

    /**
    * JSON path getter for numeric list values
    *
    * @param    i_obj            JSON object
    * @param    i_pair_name      Pair value
    *
    * @return   Pair value as nested table (table_number) or null if not exists or is not a list of numbers
    *
    * @author   ARIEL.MACHADO
    * @version 
    * @since    12/5/2013
    */
    FUNCTION get_table_number
    (
        i_obj       IN json_object_t,
        i_pair_name IN VARCHAR2
    ) RETURN table_number;

    /**
    * JSON path getter for string list values
    *
    * @param    i_obj            JSON object
    * @param    i_pair_name      Pair value
    *
    * @return   Pair value as nested table (table_varchar) or null if not exists or is not a list of strings
    *
    * @author   ARIEL.MACHADO
    * @version 
    * @since    12/5/2013
    */
    FUNCTION get_table_varchar
    (
        i_obj       IN json_object_t,
        i_pair_name IN VARCHAR2
    ) RETURN table_varchar;

    /**
    * JSON path getter for 2D array of numeric values
    *
    * By convention, the JSON object to represent a 2D array must follow this format:
    * { "pair_name" : [ [1,2,3], [4,5,6], [7,8,9] ] }
    *
    * @param    i_obj            JSON object
    * @param    i_pair_name      Pair value
    *
    * @return   Pair value as nested table (table_table_number) or null if not exists or is not a list of numbers
    *
    * @author   ARIEL.MACHADO
    * @version 
    * @since    09/11/2014
    */
    FUNCTION get_table_table_number
    (
        i_obj       IN json_object_t,
        i_pair_name IN VARCHAR2
    ) RETURN table_table_number;

    /**
    * JSON path getter for 2D array of string values
    *
    * By convention, the JSON object to represent a 2D array must follow this format:
    * { "pair_name" : [ ["a","b","c"], ["d","e","f"], ["g","h","i"] ] }
    *
    * @param    i_obj            JSON object
    * @param    i_pair_name      Pair value
    *
    * @return   Pair value as nested table (table_table_varchar) or null if not exists or is not a list of string
    *
    * @author   ARIEL.MACHADO
    * @version 
    * @since    09/11/2014
    */
    FUNCTION get_table_table_varchar
    (
        i_obj       IN json_object_t,
        i_pair_name IN VARCHAR2
    ) RETURN table_table_varchar;

    /**
    * JSON path getter for clob values
    *
    * @param    i_obj               JSON object
    * @param    i_pair_name         Pair name 
    *
    * @return   Pair value as clob or null if not exists or is not a string
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.3
    * @since    12/5/2013
    */
    FUNCTION get_clob
    (
        i_obj       IN json_object_t,
        i_pair_name IN VARCHAR2
    ) RETURN CLOB;

END pk_json_utils;
/
