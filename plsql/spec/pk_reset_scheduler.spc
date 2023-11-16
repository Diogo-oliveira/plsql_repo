/*-- Last Change Revision: $Rev: 2028935 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:50 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_reset_scheduler AS

    /**********************************************************************************************
    * This PROCEDURE deletes/updates tables related with the schedulers on the schema ALERT
    *
    * @param i_scheduler_ids                 ID_SCHEDULER table_number
    *
    *
    * @author                                Ruben Araujo
    * @version                               1.0
    * @since                                 2016/05/17
    **********************************************************************************************/
    PROCEDURE reset_sch_alert(i_scheduler_ids IN table_number);

    /**********************************************************************************************
    * This Function calls the procedures to do the 
    * deletes/updates tables related with the schedulers on the schema 
    * ALERT/ADTCOD/PRODUCT_TR/APSSCHDLR
    *
    * @param i_lang                          ID Language NUMBER
    * @param i_inst                          ID Institution NUMBER
    *
    * @return                                true (success), false (erroR)
    * @author                                Ruben Araujo
    * @version                               1.0
    * @since                                 2016/05/17
    **********************************************************************************************/
    FUNCTION reset_sch_by_inst
    (
        i_lang  IN language.id_language%TYPE,
        i_inst  IN NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

END pk_reset_scheduler;
/
