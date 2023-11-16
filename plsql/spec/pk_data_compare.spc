/*-- Last Change Revision: $Rev: 2028588 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_data_compare IS

    /*******************************************************************************************************************************************
    * Name :                          count_record_match                                                                                       *
    * Description:                    Count the number of times the rows in the source object appear in the target object according to the     *
    *                                 rules specified in DATA_COMPARE_RULE table                                                               *
    *                                                                                                                                          *
    * @param i_lang                   Input - Language                                                                                         *
    * @param i_id_institution         Input - Institution ID                                                                                   *
    * @param i_obj_source             Input - The object containing the data to compare from                                                   *
    * @param i_rowid_source           Input - A collection of rowids in the source object to compare                                           *
    * @param i_obj_target             Input - The object containing the data to compare to                                                     *
    * @param i_rowid_target           Input - A collection of rowids in the target object to compare                                           *
    *                                                                                                                                          *
    * @author                         Nelson Canastro                                                                                          *
    * @version                        1.0                                                                                                      *
    * @since                          25-Mar-2010                                                                                              *
    *******************************************************************************************************************************************/
    FUNCTION count_record_match
    (
        i_lang           IN NUMBER,
        i_id_institution IN NUMBER,
        i_obj_source     IN VARCHAR2,
        i_rowid_source   IN dbms_sql.urowid_table,
        i_obj_target     IN VARCHAR2,
        i_rowid_target   IN dbms_sql.urowid_table,
        o_error          OUT t_error_out
    ) RETURN NUMBER;

    -----------------------------------------------------------------------------------------------
    -- VARIABLES
    -----------------------------------------------------------------------------------------------
    g_error VARCHAR2(4000);
END;
/
