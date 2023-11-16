/*-- Last Change Revision: $Rev: 1657387 $*/
/*-- Last Change by: $Author: renato.nunes $*/
/*-- Date of last change: $Date: 2014-11-07 13:34:10 +0000 (sex, 07 nov 2014) $*/

create or replace package pk_edis_handle_refcursor is
       
    -- Author  : ALEXANDRE.SANTOS
    -- Created : 6/9/2014 12:07:04 PM
    -- Purpose : PK_EDIS_HANDLE_REFCURSOR created to support generic cursors to be fetched dinamically 

    TYPE table_varchar_idx IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY VARCHAR2(32 CHAR);

	
    /********************************************************************************************
    * Initializes one global cursor dinamicaly
    * @param i_cursor               pk_types.cursor_type
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-Jun-2014
    **********************************************************************************************/
    PROCEDURE init_cursor(i_cursor IN OUT pk_types.cursor_type);
		
		/********************************************************************************************
    * Fetchs the cursor initialized, row per row
    * @param i_cursor               pk_types.cursor_type
    * 
		* @return fetched line number
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-Jun-2014
    **********************************************************************************************/
    FUNCTION fetch_row RETURN NUMBER;
		
		/********************************************************************************************
    * Get a value from initialized cursor by column name
    * @param i_column_name            Column name to find and return the value
    * 
		* @return column value
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-Jun-2014
    **********************************************************************************************/
    FUNCTION get_value(i_column_name IN VARCHAR2) RETURN VARCHAR2;
		
		/********************************************************************************************
    * Close cursor initialized
    * @param i_cursor               pk_types.cursor_type
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-Jun-2014
    **********************************************************************************************/
		PROCEDURE close_cursor;

end pk_edis_handle_refcursor;
/
