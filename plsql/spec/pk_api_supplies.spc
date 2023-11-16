/*-- Last Change Revision: $Rev: 1877302 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-11-12 09:57:24 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE pk_api_supplies IS

    /**********************************************************************************************
    * Set a supply to a prepared status
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_supplies supplies
    * @i_unic_id unic identifier of the supply 
    * @i_prepared_by profissional who prepared the supply
    * @i_prep_notes notes about supply preparation
    * @i_new_supplies new supplies to replace existing ones
    * @o_error Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  João Almeida
    * @version 2.5.0.7
    * @since   16/11/09
    **********************************************************************************************/
    FUNCTION set_supply_preparation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_supplies     IN table_number,
        i_id_patient   IN patient.id_patient%TYPE,
        i_unic_id      IN table_number,
        i_prepared_by  IN table_varchar,
        i_prep_notes   IN table_varchar,
        i_new_supplies IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Set a supply to a prepared status
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_supplies supplies 
    * @i_barcode scanned barcode
    * @o_error Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  João Almeida
    * @version 2.5.0.7
    * @since   16/11/09
    **********************************************************************************************/

    FUNCTION set_conclude_devolution
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_supplies   IN table_number,
        i_id_episode IN supply_workflow.id_episode%TYPE,
        i_barcode    IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns a list of all the supply requests and consumptions, grouped by status.
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_patient Patient's id
    * @i_episode Current Episode
    * @o_list  list of all the supply requests and consumptions
    * @o_error Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  João Almeida
    * @version 2.5.0.7
    * @since   9/11/09
    **********************************************************************************************/

    FUNCTION get_list_req_cons
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN episode.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns a list of all the supply requests and consumptions, grouped by status to REPORTS team.
    * 
    * @i_lang        Language ID
    * @i_prof        Professional's info
    * @i_patient     Patient's id
    * @i_episode     Current Episode
    * @i_flg_type    Type of material ('M' - Activity terapist material; 'O' - Other material)
    * @o_list        list of all the supply requests and consumptions
    * @o_error       Error info
    * 
    * @return        True on success, false on error
    *
    * @Dependencies  REPORTS 
    *
    * @author        Luís Maia
    * @version       2.6.0.3
    * @since         09/Jun/2010
    **********************************************************************************************/
    FUNCTION get_list_req_cons_report
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN episode.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN supply.flg_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the translation code for Procedures
    *
    * @param i_supply               ID Supply
    *
    * @return                       Translation Code
    *
    * @author                       Teresa Coutinho 2012/02/01
    ********************************************************************************************/

    FUNCTION get_translation_code(i_supply IN supply.id_supply%TYPE) RETURN VARCHAR2;

    /**********************************************************************************************
    * Updates a supply requests status 
    * 
    * @i_lang        Language ID
    * @i_prof        Professional's info    
    * @i_supplies    Id Supply Workflow
    * @i_episode     Current Episode  
    * @i_cancel_notes Cancelation Notes
    * @i_id_cancel_reason Id Cancel Reason
    * @i_dt_cancel Cancelation Date - Interface Only
    * @i_flg_status list of Status
    * @i_notes Notes
    * @o_error       Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  Teresa Coutinho
    * @version 2.6.2
    * @since   27/03/2012
    **********************************************************************************************/

    FUNCTION update_supply_workflow_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_episode         IN supply_workflow.id_episode%TYPE,
        i_id_prof_cancel     IN professional.id_professional%TYPE,
        i_cancel_notes       IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason   IN supply_workflow.id_cancel_reason%TYPE,
        i_dt_cancel          IN supply_workflow.dt_cancel%TYPE,
        i_flg_status         IN supply_workflow.flg_status%TYPE,
        i_notes              IN supply_workflow.notes%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    g_sysdate       DATE;
    g_sysdate_tstz  TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_error         VARCHAR2(4000);
    g_package_owner VARCHAR2(32);
    g_package_name  VARCHAR2(32);
    g_exception EXCEPTION;
    g_found BOOLEAN := FALSE;

END pk_api_supplies;
/
