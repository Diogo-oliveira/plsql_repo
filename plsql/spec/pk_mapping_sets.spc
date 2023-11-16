/*-- Last Change Revision: $Rev: 2028788 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:57 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_mapping_sets IS

    /********************************************************************************************
    * Author  : Carlos Mota Silva
    * Created : 31-Jul-2011
    * Purpose : This package contains functions that allow to manage and navigate on cross mapping data model
    ********************************************************************************************/

    /********************************************************************************************
    * Get all mappings of a concept given a source and a target mapping set
    *
    * @param i_lang               preferred language id
    * @param i_map_concept        mapping concept id
    * @param i_mcs_source         standard id on medical classification system data model (used to get concept descriptions)     
    * @param o_error              error structure and message
    *
    * @return                     string with the pre or post-coordinated expression of the concept
    *
    * @author                     Tiago Silva
    * @since                      11-Mar-2011
    ********************************************************************************************/
    FUNCTION get_concept_coordination_expr
    (
        i_lang        IN language.id_language%TYPE,
        i_map_concept IN xmap_concept.id_map_concept%TYPE,
        i_mcs_source  IN mcs_source.id_mcs_source%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get all mappings of a concept given a source and a target mapping set
    *
    * @param i_lang               preferred language id
    * @param i_source_concept     string with the pre or post-coordinated expression of the source concept
    * @param i_source_map_set     source mapping set id
    * @param i_target_map_set     target mapping set id
    * @param i_target_mcs_src     target standard id on medical classification system data model (used to get concept descriptions)
    * @param o_target_concepts    cursor with all target concepts
    * @param o_error              error structure and message
    *
    * @return                     true or false on success or error
    *
    * @author                     Tiago Silva
    * @since                      11-Mar-2011
    ********************************************************************************************/
    FUNCTION get_mapping_concepts
    (
        i_lang            IN language.id_language%TYPE,
        i_source_concept  IN VARCHAR2,
        i_source_map_set  IN xmap_set.id_map_set%TYPE,
        i_target_map_set  IN xmap_set.id_map_set%TYPE,
        i_target_mcs_src  IN mcs_source.id_mcs_source%TYPE DEFAULT NULL,
        o_target_concepts OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

	/********************************************************************************************
    * Get all mappings of a concept given a source and a target mapping set
    *
    * @param i_lang               preferred language id
    * @param i_source_concept     list of strings string with the pre or post-coordinated expression of the source concept
    * @param i_source_map_set     source mapping set id
    * @param i_target_map_set     target mapping set id
    * @param i_target_mcs_src     target standard id on medical classification system data model (used to get concept descriptions)
    * @param o_target_concepts    cursor with all target concepts
    * @param o_error              error structure and message
    *
    * @return                     true or false on success or error
    *
    * @author                     Sofia Mendes
    * @since                      2011/03/11
    ********************************************************************************************/
    FUNCTION tf_get_mapping_concepts
    (
        i_lang           IN language.id_language%TYPE,
        i_source_concept IN table_varchar,
        i_source_map_set IN xmap_set.id_map_set%TYPE,
        i_target_map_set IN xmap_set.id_map_set%TYPE,
        i_target_mcs_src IN mcs_source.id_mcs_source%TYPE DEFAULT NULL
    ) RETURN t_table_mapping_conc;

    /********************************************************************************************
    * check if a given cross mapping is available for a software and institution
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_order_recurr_option  list of order recurrence option ids
    * @param       o_order_recurr_time    array of order recurrence times
    * @param       o_error                error structure for exception handling
    *
    * @return      varchar2               'Y' - cross mapping is available; 'N' - cross mapping is not available
    *
    * @author                             Tiago Silva
    * @since                              03-JUN-2011
    ********************************************************************************************/
    FUNCTION check_xmap_avail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_source_concept IN xmap_concept.id_map_concept%TYPE,
        i_target_concept IN xmap_concept.id_map_concept%TYPE,
        i_source_map_set IN xmap_set.id_map_set%TYPE,
        i_target_map_set IN xmap_set.id_map_set%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get concept code with given a source and a target mapping sets
    *
    * @param i_lang               preferred language id
    * @param i_prof               professional structure
    * @param i_source_concept     string with the pre or post-coordinated expression of the source concept
    * @param i_source_map_set     source mapping set id
    * @param i_target_map_set     target mapping set id
    *
    * @return                     target map concept code
    *
    * @author                     Carlos Loureiro
    * @since                      11-Mar-2011
    ********************************************************************************************/
    FUNCTION get_mapping_concept
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_source_concept IN VARCHAR2,
        i_source_map_set IN xmap_set.id_map_set%TYPE,
        i_target_map_set IN xmap_set.id_map_set%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get concept description with given a source and a target mapping sets
    *
    * @param i_lang               preferred language id
    * @param i_prof               professional structure
    * @param i_source_concept     string with the pre or post-coordinated expression of the source concept
    * @param i_source_map_set     source mapping set id
    * @param i_target_map_set     target mapping set id
    * @param i_target_mcs_src     target standard id on medical classification system data model (used to get concept description)
    *
    * @return                     target map concept description
    *
    * @author                     Carlos Loureiro
    * @since                      11-Mar-2011
    ********************************************************************************************/
    FUNCTION get_mapping_concept_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_source_concept IN VARCHAR2,
        i_source_map_set IN xmap_set.id_map_set%TYPE,
        i_target_map_set IN xmap_set.id_map_set%TYPE,
        i_target_mcs_src IN mcs_source.id_mcs_source%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    -- mapping relationship status
    g_xmr_active   VARCHAR2(1 CHAR) := 'A';
    g_xmr_inactive VARCHAR2(1 CHAR) := 'I';

    -- all mapping targets
    g_xmt_all xmap_target.id_map_target%TYPE := 0;

    -- all mapping concept
    g_xmc_all xmap_concept.id_map_concept%TYPE := 0;

    -- all mapping set
    g_xms_all xmap_set.id_map_set%TYPE := 0;

    -- general error descriptions
    g_error VARCHAR2(1000 CHAR);

    -- Log variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);

END pk_mapping_sets;
/
