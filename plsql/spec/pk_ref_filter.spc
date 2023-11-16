/*-- Last Change Revision: $Rev: 1857420 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2018-07-27 10:04:44 +0100 (sex, 27 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_ref_filter IS

    -- Author  : ANA.MONTEIRO
    -- Created : 27-02-2013 11:53:02
    -- Purpose : Functions related with Referral filters and pagination

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
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2012
    */
    PROCEDURE init_params_ref
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

    /**
    * Gets mapping contexts in referral handoff grids 
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
    * @author  Ana Monteiro
    * @version 1.0
    * @since   07-05-2013
    */
    PROCEDURE init_params_handoff
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

    /**
    * Gets mapping contexts in referral origin institution list
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
    * @author  Ana Monteiro
    * @version 1.0
    * @since   08-10-2013
    */
    PROCEDURE init_params_inst_orig_net
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

END pk_ref_filter;
/
