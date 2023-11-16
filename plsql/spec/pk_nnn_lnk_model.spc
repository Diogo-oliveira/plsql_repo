/*-- Last Change Revision: $Rev: 1658137 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:21:37 +0000 (seg, 10 nov 2014) $*/

CREATE OR REPLACE PACKAGE pk_nnn_lnk_model IS

    -- Author  : ARIEL.MACHADO
    -- Created : 9/25/2013 4:08:27 PM
    -- Purpose : Linkages of NANDA-I, NIC and NOC (NNN) Model: Methods to handle the linkage data model

    -- Exceptions

    --An invalid NANDA Diagnosis not available in NAN
    e_invalid_nanda_diagnosis EXCEPTION;

    --An invalid NOC Outcome not available in NOC
    e_invalid_noc_outcome EXCEPTION;

    --An invalid NIC Intervention not available in NIC
    e_invalid_nic_intervention EXCEPTION;

    -- Public type declarations

    -- Public constant declarations

    -- NANDA, NOC, and NIC Linkages: - Intervention link type: (M)ajor, (S)uggested, (O)ptional
    g_dom_nnn_lnk_flg_link_type CONSTANT sys_domain.code_domain%TYPE := 'NAN_NOC_NIC_LINKAGE.FLG_NIC_LINK_TYPE';

    -- NANDA-NIC Linkages - Intervention link type: (M)ajor, (S)uggested, (O)ptional
    g_dom_nannic_lnk_flg_link_type CONSTANT sys_domain.code_domain%TYPE := 'NAN_NIC_LINKAGE.FLG_LINK_TYPE';

    -- NANDA-NOC Linkages - Outcome link type: (S)uggested, (A)dditional
    g_dom_nannoc_lnk_flg_link_type CONSTANT sys_domain.code_domain%TYPE := 'NAN_NOC_LINKAGE.FLG_LINK_TYPE';

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Insert/Update NANDA, NOC and NIC Linkages definition
    *
    * @param    i_terminology_version  NNN Linkages Terminology version ID
    * @param    i_diagnosis_code       NANDA Diagnosis Code 
    * @param    i_outcome_code         NOC Outcome Code
    * @param    i_intervention_code    NIC Intervention Code
    * @param    i_nic_link_type        Intervention link type: (M)ajor, (S)uggested, (O)ptional 
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   10/7/2013
    */
    PROCEDURE insert_into_nan_noc_nic_link
    (
        i_terminology_version IN nan_noc_nic_linkage.id_terminology_version%TYPE,
        i_diagnosis_code      IN nan.diagnosis_code%TYPE,
        i_outcome_code        IN noc.outcome_code%TYPE,
        i_intervention_code   IN nic.intervention_code%TYPE,
        i_nic_link_type       IN nan_noc_nic_linkage.flg_nic_link_type%TYPE
    );

    /**
    * Insert/Update NANDA/NOC Linkages definition
    *
    * @param    i_terminology_version  NOC Terminology version ID 
    * @param    i_outcome_code         NOC Outcome Code
    * @param    i_diagnosis_code       NANDA Diagnosis Code     
    * @param    i_intervention_code    NIC Intervention Code
    * @param    i_nic_link_type        Intervention link type: (M)ajor, (S)uggested, (O)ptional 
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   10/7/2013
    */
    PROCEDURE insert_into_nan_noc_link
    (
        i_terminology_version IN noc_outcome.id_terminology_version%TYPE,
        i_outcome_code        IN noc_outcome.outcome_code%TYPE,
        i_diagnosis_code      IN nan.diagnosis_code%TYPE,
        i_nic_link_type       IN nan_noc_linkage.flg_link_type%TYPE
    );

    /**
    * Insert/Update NANDA/NIC Linkages definition
    *
    * @param    i_terminology_version  NIC Terminology version ID
    * @param    i_intervention_code    NIC Intervention Code
    * @param    i_diagnosis_code       NANDA Diagnosis Code     
    * @param    i_nic_link_type        Intervention link type: (M)ajor, (S)uggested, (O)ptional
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   10/7/2013
    */
    PROCEDURE insert_into_nan_nic_link
    (
        i_terminology_version IN nic_intervention.id_terminology_version%TYPE,
        i_intervention_code   IN nic_intervention.intervention_code%TYPE,
        i_diagnosis_code      IN nan.diagnosis_code%TYPE,
        i_nic_link_type       IN nan_nic_linkage.flg_link_type%TYPE
    );

END pk_nnn_lnk_model;
/
