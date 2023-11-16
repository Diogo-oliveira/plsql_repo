/*-- Last Change Revision: $Rev: 2028441 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_adt_api_ui AS

    /********************************************************************************************
    * Returns patient s name (reports)
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_patient             patient identifier
    * @param o_deceased_date       Patient s deceased date
    * @param o_deceased_motive     Patient s deceased motive
    * @param o_deceased_place      Patient s deceased place
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2009/12/23
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_patient_deceased_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        o_deceased_date   OUT VARCHAR2,
        o_deceased_motive OUT patient.deceased_motive%TYPE,
        o_deceased_place  OUT patient.deceased_place%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns A collection with patient s valid exemptions
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_patient                   Patient id
    * @param o_exemptions                   REF CURSOR with id_pat_isencao, desc_isencao
    * @param o_error                        Error message       
    *
    * @return                        TRUE in case of success, FALSE otherwise
    *
    * @author                        BM
    * @since                         2013-09-18
    * @version                       2.6.3.8.1
    ********************************************************************************************/
    FUNCTION get_pat_exemptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_exemptions OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the nacional health plan attributes (number, entity and description)
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_patient             patient id
    * @param o_num_health_plan     health plan number
    * @param o_hp_entity           health plan entity
    * @param o_hp_desc             health plan description
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins and Jorge Matos
    * @since                       2011-08-07
    * @version                     2.5.1.7
    ********************************************************************************************/
    FUNCTION get_national_health_number
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        o_num_health_plan OUT pat_health_plan.num_health_plan%TYPE,
        o_hp_entity       OUT VARCHAR2,
        o_hp_desc         OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns patient info used in prescription
    *
    * @param i_lang                language id
    * @param i_id_patient          patient id
    * @param i_prof                professional (id, institution, software)
    * @param o_flg_recm            flag associated to recm    
    * @param o_error               error info
    * @return                      boolean if the function was called with success
    *
    * @author                      Bruno Martins
    * @since                       2011-08-30
    * @version                     2.5.1
    ********************************************************************************************/
    FUNCTION get_flg_recm
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        o_flg_recm   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient other names
    * These fields are used for KW/SA to store arabic names
    *
    * @param i_prof                           Professional executing the action
    * @param i_patient                        Patient ID
    *
    * @return                                 Patient concatenated other names
    *
    * @author                                 filipe.f.pereira
    * @version                                2.6.4.1
    * @since                                  2018-04-09
    ********************************************************************************************/
    FUNCTION get_other_names
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_other_names OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_create_patient_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
  
    FUNCTION get_epis_type_create
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_flg_type OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
      
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;

    g_package_owner VARCHAR2(10) := 'ALERT';
    g_package_name  VARCHAR2(20) := 'PK_ADT_API_UI';

END pk_adt_api_ui;
/
