/*-- Last Change Revision: $Rev: 2028736 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_icnp_util IS

    --------------------------------------------------------------------------------
    -- METHODS
    --------------------------------------------------------------------------------

    /**
     * Throws an unexpected error. This method is used when a function, that returns 
     * a boolean to indicate the success / unsuccess of the call, is invoked and an
     * error occurs. This method was created to centralize the raise of this kind of
     * errors in only one place and because if needed we can add more information from
     * the error details to the exception text.
     * 
     * @param i_method The method where the error occurred.
     * @param i_error The details of the error, like for example: ora_sqlcode and 
     *                ora_sqlerrm.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 28/Jul/2011 (v2.6.1)
    */
    PROCEDURE raise_unexpected_error
    (
        i_method IN VARCHAR2,
        i_error  IN t_error_out
    );

    /**
     * Checks if a table with numbers is empty. The table is considered empty if it 
     * is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN table_number) RETURN BOOLEAN;

    /**
     * Checks if a table with strings is empty. The table is considered empty if it 
     * is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN table_varchar) RETURN BOOLEAN;

    /**
     * Checks if a table with icnp_epis_intervention records is empty. The table is 
     * considered empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 15/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN ts_icnp_epis_intervention.icnp_epis_intervention_tc) RETURN BOOLEAN;

    /**
     * Checks if a table with icnp_interv_plan records is empty. The table is
     * considered empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 18/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN ts_icnp_interv_plan.icnp_interv_plan_tc) RETURN BOOLEAN;

    /**
     * Checks if a table with icnp_epis_diagnosis records is empty. The table is
     * considered empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 18/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc) RETURN BOOLEAN;

    /**
     * Checks if a table with icnp_suggest_interv records is empty. The table is
     * considered empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 18/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN ts_icnp_suggest_interv.icnp_suggest_interv_tc) RETURN BOOLEAN;

    /**
     * Checks if a table with icnp_epis_diag_interv records is empty. The table is
     * considered empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 26/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN ts_icnp_epis_diag_interv.icnp_epis_diag_interv_tc) RETURN BOOLEAN;

    /**
     * Checks if a table with tables of varchars is empty. The table is considered 
     * empty if it is null or if it has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 25/Jul/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_table IN table_table_varchar) RETURN BOOLEAN;

    /**
     * Checks if a table of records that have all the data needed to correctly execute
     * an intervention is empty. The table is considered empty if it is null or if it
     * has no records.
     *
     * @param i_table Table that we want to check.
     *
     * @return True when the table is empty; false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 08/Sep/2011 (v2.6.1)
    */
    FUNCTION is_table_empty(i_exec_interv_coll IN pk_icnp_type.t_exec_interv_coll) RETURN BOOLEAN;

    /**
     * Converts a professional object to a string.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * 
     * @return A string that represents the professional.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jul/2011 (v2.6.1)
    */
    FUNCTION to_string(i_prof IN profissional) RETURN tlog.ltexte%TYPE;

    /**
     * Converts a boolean to a string.
     * 
     * @param i_input The boolean value.
     * 
     * @return A string that represents the boolean value.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jul/2011 (v2.6.1)
    */
    FUNCTION to_string(i_input IN BOOLEAN) RETURN VARCHAR2;

    /**
     * Converts a record that has all the data needed to correctly execute an 
     * intervention to a string.
     * 
     * @param i_exec_interv_rec The record with all the data needed to correctly execute 
     *                          an intervention.
     * 
     * @return A string that represents the data needed to correctly execute an 
     *         intervention.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 08/Sep/2011 (v2.6.1)
    */
    FUNCTION to_string(i_exec_interv_rec IN pk_icnp_type.t_exec_interv_rec) RETURN VARCHAR2;

    /**
     * Converts a collection of records with all the data needed to correctly execute 
     * an intervention to a string.
     * 
     * @param i_exec_interv_coll The collection with all the data needed to correctly 
     *                           execute an intervention.
     * 
     * @return A string that represents the data needed to correctly execute an 
     *         intervention.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 08/Sep/2011 (v2.6.1)
    */
    FUNCTION to_string(i_exec_interv_coll IN pk_icnp_type.t_exec_interv_coll) RETURN VARCHAR2;

    /**
    *Setup ICNP for institutions group
    *
    * @param i_lang   Language ID
    * @param i_inst   Institution ID
    *
    * @return                Return comment 
    * 
    * @author                Nuno Neves
    * @version               Version identification 
    * @since                 2012/06/21
    */
    FUNCTION mig_icnp_inst_group
    (
        i_lang IN language.id_language%TYPE,
        i_inst IN institution.id_institution%TYPE
    ) RETURN BOOLEAN;

END pk_icnp_util;
/
