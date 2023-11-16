/*-- Last Change Revision: $Rev: 1856882 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2018-07-26 09:45:31 +0100 (qui, 26 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_adt_filter IS

    -- Author  : Bruno Martins
    -- Created : 2014-02-21
    -- Purpose : Functions related with ADT filters and pagination

    /**
    * Gets mapping contexts in referral grids
    * Used by filters
    *
    * @param i_context_ids      Predefined contexts array(prof_id, institution, patient, episode, etç)
    * @param i_context_vals     All remaining contexts array(configurable with bind variable definition)
    * @param i_name             Variable name
    * @param o_vc2              Output variable type varchar2
    * @param o_num              Output variable type NUMBER
    * @param o_id               Output variable type Id
    * @param o_tstz             Output variable type TIMESTAMP WITH LOCAL TIME ZONE
    *
    * @author  Bruno Martins
    * @version 1.0
    * @since   2014-02-21
    */
    PROCEDURE init_params_amendments
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

END pk_adt_filter;
/