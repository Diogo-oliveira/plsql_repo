/*-- Last Change Revision: $Rev: 2028440 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_adt AS

    SUBTYPE t_low_char IS VARCHAR2(0100 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    FUNCTION dummy_refresh
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN professional.id_professional%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Cria todos os registos necessários ao início do planeamento de uma nova cirurgia, ainda antes
           de existir um agendamento, diagnóstico base e intervenção a realizar definidos. Se o paciente não for
       preenchido, cria um novo paciente (temporário)
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                      I_PATIENT - ID do paciente
                                         I_PROF - ID do profissional, instituição e software
           Saida:   O_EPISODE_NEW - Novo episodio criado
           O_SCHEDULE - ID do agendamento criado
                        O_ERROR - erro
    
      CRIAÇÃO: RB 2006/08/29
    
      NOTAS:
    *********************************************************************************/
    FUNCTION create_all_surgery
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN OUT patient.id_patient%TYPE,
        i_prof        IN professional.id_professional%TYPE,
        o_episode_new OUT episode.id_episode%TYPE,
        o_schedule    OUT schedule.id_schedule%TYPE,
        o_error       OUT VARCHAR2
    ) RETURN NUMBER;

    /********************************************************************************************
    * Invokes data gov events after patient creation
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_institution              institution ID
    * @param   i_software                 software ID
    * @param   i_patient                  Patient ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Bruno Martins
    * @version                        2.5
    * @since                          07-07-2009
    **********************************************************************************************/
    FUNCTION process_patient_insert
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Invokes data gov events after patient update
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_institution              institution ID
    * @param   i_software                 software ID
    * @param   i_patient                  Patient ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Bruno Martins
    * @version                        2.5
    * @since                          07-07-2009
    **********************************************************************************************/
    FUNCTION process_patient_update
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function matches all the information of the two patients (temporary and definitive).
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_patient new patient id
    * @param i_patient_temp temporary patient which data will be merged out, and then deleted
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION set_match_patient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        i_flg_unknown  IN epis_info.flg_unknown%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function deletes all the non-clinical information of the patient.
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_patient
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION delete_patient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function is used when matching two patients
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_patient the patient where the all the information is going to be merged to
    * @param i_old_visit the visit associated to the old episode
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION set_patient_match
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_old_episode IN episode.id_episode%TYPE,
        i_old_visit   IN visit.id_visit%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function deletes all the ADT VISITS related with an ALERT visit.
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_visit ALERT VISIT id
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION delete_adt_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_visit_temp IN visit_adt.id_visit%TYPE,
        i_visit      IN visit_adt.id_visit%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function deletes all the ADT EPISODES related with an ALERT episode.
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_episode ALERT EPISODE id
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION delete_adt_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode_adt.id_episode%TYPE,
        i_episode      IN episode_adt.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function sets patient status.
    *
    * @param i_lang      language id (used only for logs)
    * @param i_prof      professional context   
    * @param i_patient   patient id
    * @param i_status    new patient status
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION set_patient_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_status  IN patient.flg_status%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Updates patient table fields
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                patient id
    * @param i_name                   name
    * @param i_gender                 gender
    * @param i_dt_birth               date of birth
    * @param i_age                    age
    * @param i_is_to_insert           if the patient was created by create_dummy_patient and this is the first update
                                      then this flag should be false otherwise is always true
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/10/29
    **********************************************************************************************/
    FUNCTION set_patient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_name         IN pre_hosp_accident.name%TYPE,
        i_gender       IN pre_hosp_accident.gender%TYPE,
        i_dt_birth     IN pre_hosp_accident.dt_birth%TYPE,
        i_age          IN pre_hosp_accident.age%TYPE,
        i_is_to_insert IN BOOLEAN DEFAULT TRUE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create patients institution history.
    *
    * @param i_lang                language id
    * @param i_patient             patient id
    * @param i_institution         institution id
    * @param i_reason_type         reason type
    * @param i_reason              reason
    * @param i_dt_begin            begin date
    * @param i_institution_enroled institution enroled id
    * @param i_software            software id
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Paulo Fonseca
    * @since                       2009/05/28
    * @version                     2.5
    ********************************************************************************************/
    FUNCTION intf_update_patient_care_inst
    (
        i_lang                IN language.id_language%TYPE,
        i_patient             IN patient_care_inst.id_patient%TYPE,
        i_institution         IN patient_care_inst.id_institution%TYPE,
        i_reason_type         IN patient_care_inst.reason_type%TYPE,
        i_reason              IN patient_care_inst.reason%TYPE,
        i_dt_begin            IN patient_care_inst.dt_begin_tstz%TYPE,
        i_institution_enroled IN patient_care_inst.id_institution_enroled%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    /********************************************************************************************
    * Returns patient s emergency contact
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param i_patient             patient identifier
    * @param o_contact             Patient s emergency contact
    * @param o_error               Error out        
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2010/01/25
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_emergency_contact
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_contact OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_emergency_contact
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Add emergency contact to patient
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param i_patient             patient identifier
    * @param i_contact             Patient s emergency contact to add
    * @param o_error               Error out        
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2010/01/25
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION add_emergency_contact
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_contact IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Criar ou actualizar a informação do episódio
    *
    * @param i_lang                language id
    * @param i_epis_type           Tipo de episodio
    * @param i_institution         ID da instituicao onde e realizada a criacao/actualizacao do episodio
    * @param i_professional        Professional ID
    * @param i_software            Software ID
    * @param i_patient             Patient ID
    * @param i_episode             Episode ID
    * @param i_ext_episode         External Episode ID
    * @param i_external_sys        External System ID
    * @param i_health_plan         Health Plan ID
    * @param i_schedule            Schedule ID
    * @param i_flg_ehr             Electronic Health Record Flag
    * @param i_origin              Origin of the episode
    * @param i_dt_begin            Begin date
    * @param i_dep_clin_serv       Department Clinical Service
    * @param i_external_cause      ID of external cause
    * @param o_episode             ID do episódio associado ao ID_EPIS_EXT_SYS
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2007/02/04
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_episode_pfh
    (
        i_lang                 IN language.id_language%TYPE,
        i_epis_type            IN epis_type.id_epis_type%TYPE,
        i_institution          IN institution.id_institution%TYPE,
        i_professional         IN professional.id_professional%TYPE,
        i_software             IN software.id_software%TYPE,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_ext_episode          IN epis_ext_sys.value%TYPE,
        i_external_sys         IN external_sys.id_external_sys%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_schedule             IN epis_info.id_schedule%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE,
        i_origin               IN origin.id_origin%TYPE,
        i_dt_begin             IN episode.dt_begin_tstz%TYPE,
        i_dep_clin_serv        IN epis_info.id_dep_clin_serv%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_consultant_in_charge IN epis_multi_prof_resp.id_professional%TYPE,
        i_dt_arrival           IN announced_arrival.dt_announced_arrival%TYPE,
        i_flg_unknown in epis_info.flg_unknown%type default pk_alert_constant.g_no,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN PLS_INTEGER;

    /********************************************************************************************
    * Returns true if the patient was transferred
    *
    * @param i_lang                language id    
    * @param i_market              market id
    * @param o_error               Error out        
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2010/02/19
    * @version                     2.5
    ********************************************************************************************/
    FUNCTION update_transfer_adt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_inst IN institution.id_institution%TYPE,
        i_episode IN pat_soc_attributes.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns other names kw/sa
    *
    * @param i_prof                professional (id, institution, software)
    * @param i_patient             patient identifier
    * @param i_is_prof_resp        true if the professional is responsible for the patient (physician or nurse)
    * @param o_error               Error message
    *
    * @return                      names
    *
    * @author                      filipe.f.pereira
    * @since                       09/04/2018
    * @version                     2.7
    ********************************************************************************************/
    FUNCTION concat_other_names
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        name1           IN patient.other_names_1%TYPE,
        name2           IN patient.other_names_2%TYPE,
        name3           IN patient.other_names_3%TYPE,
        name4           IN patient.other_names_4%TYPE,
        include_sep     IN BOOLEAN DEFAULT TRUE,
        i_id_sys_config IN sys_config.id_sys_config%TYPE DEFAULT 'PATIENT_NAME_PATTERN'
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns patient s name
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_patient             patient identifier
    * @param i_is_prof_resp        true if the professional is responsible for the patient (physician or nurse)
    *                              false otherwise
    * @param i_id_sys_config sys_config identifier (DEFAULT 'PATIENT_NAME_PATTERN')
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2009/12/23
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_patient_name
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_is_prof_resp  IN BOOLEAN,
        i_id_sys_config IN sys_config.id_sys_config%TYPE DEFAULT 'PATIENT_NAME_PATTERN',
        o_error         OUT t_error_out
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns patient s name
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_patient             patient identifier
    * @param i_is_prof_resp        true if the professional is responsible for the patient (physician or nurse)
    *                              false otherwise
    * @param o_vip_status          VIP Status
    * @param o_name                Patient s name
    *
    * @author                      Bruno Martins
    * @since                       2009/12/23
    * @version                     2.6
    ********************************************************************************************/
    PROCEDURE get_patient_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_is_prof_resp IN BOOLEAN,
        o_vip_status   OUT VARCHAR2,
        o_name         OUT VARCHAR2
    );

    /********************************************************************************************
    * Returns patient s name
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_patient             patient identifier
    * @param i_is_prof_resp        true if the professional is responsible for the patient (physician or nurse)
    *                              false otherwise
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2009/12/23
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_patient_name
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_is_prof_resp  IN PLS_INTEGER,
        i_id_sys_config IN sys_config.id_sys_config%TYPE DEFAULT 'PATIENT_NAME_PATTERN'
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns show_patient_info
    *
    * @param i_lang                language id
    * @param i_patient             patient identifier
    * @param i_is_prof_resp        true if the professional is responsible for the patient (physician or nurse)
    *                              false otherwise
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2009/12/23
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION show_patient_info
    (
        i_lang         IN language.id_language%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_is_prof_resp IN PLS_INTEGER
    ) RETURN BOOLEAN;

    FUNCTION call_show_patient_info
    (
        i_lang         IN language.id_language%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_is_prof_resp IN PLS_INTEGER
    ) RETURN PLS_INTEGER;

    /********************************************************************************************
    * Returns has_non_disclosure_level
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param i_patient             patient identifier
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2009/12/23
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION has_non_disclosure_level
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns get_pat_non_disc_options
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param i_patient             patient identifier
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2009/12/23
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_pat_non_disc_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns get_pat_non_disclosure_icon
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param i_patient             patient identifier
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2009/12/23
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_pat_non_disclosure_icon
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns patient s emergency contact
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param o_vip_icons           Cursor with VIP icons
    * @param o_error               Error out        
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2010/01/25
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_vip_icons
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_vip_icons OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create an health_plan associated to an institution
    *
    * @param i_lang                           language id
    * @param i_institution                    institution id
    * @param desc_health_plan                 health plan description
    * @param i_insurance_class                insurance class
    * @param i_health_plan_entity             health plan entity (insurance company or other)
    * @param o_id_health_plan                 created health plan id
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 Susana Seixas (BM copied it to PK_ADT)
    * @version                                2.6
    * @since                                  2010-03-03
    ********************************************************************************************/

    FUNCTION create_health_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_institution        IN institution.id_institution%TYPE,
        desc_health_plan     IN VARCHAR2,
        i_insurance_class    IN health_plan.insurance_class%TYPE,
        i_health_plan_entity IN health_plan.id_health_plan_entity%TYPE,
        o_id_health_plan     OUT health_plan.id_health_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create an health_plan entity
    *
    * @param i_lang                           language id
    * @param desc_health_plan                 health plan description
    * @param o_id_health_plan_entity          created health plan entity id
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 BM
    * @version                                2.6
    * @since                                  2010-03-03
    ********************************************************************************************/
    FUNCTION create_health_plan_entity
    (
        i_lang                  IN language.id_language%TYPE,
        desc_health_plan_entity IN VARCHAR2,
        o_id_health_plan_entity OUT health_plan.id_health_plan_entity%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets patient s family physician life line post office box
    *
    * @param i_lang                           language id
    * @param i_prof                           professional info
    * @param i_patient                        patient identifier
    * @param o_po_box                         life line post office box
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 BM
    * @version                                2.6
    * @since                                  2010-03-03
    ********************************************************************************************/
    FUNCTION get_life_line_post_office_box
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_po_box  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets health plan info
    *
    * @param i_lang                           language id
    * @param i_prof                           professional info
    * @param i_patient                        patient identifier
    * @param i_episode                        episode identifier
    * @param o_error                          error message
    *
    * @return                                 health plan information
    *
    * @author                                 BM
    * @version                                2.6
    * @since                                  2010-03-04
    ********************************************************************************************/
    FUNCTION get_health_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns true if the market is a core market
    *
    * @param i_lang                language id    
    * @param i_market              market id
    * @param o_error               Error out        
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2010/02/19
    * @version                     2.5
    ********************************************************************************************/
    FUNCTION is_core_market
    (
        i_lang   IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set_inp_episode Create or update inp episode
    *
    * i_lang                Language ID
    * i_id_patient          Patient ID
    * i_id_visit            Visit ID
    * i_id_episode          Episode ID
    * i_external_cause      External cause for admission
    * i_dt_begin            Admission date in TSTZ format
    * i_id_professional     Professional ID - PROFESSIONAL(ID, INST, SOFT),
    * i_health_plan         Patient health plan
    * i_epis_type           Episode Type
    * i_id_dep_clin_serv    Dep clinical service
    * i_id_room             Room
    * i_id_episode_ext      External Episode ID
    * i_flg_type
    * i_type
    * i_dt_surgery          Date of surgery
    * i_flg_surgery
    * i_id_prev_episode     Previous Episode ID
    * i_id_external_sys     External System ID
    * i_prof_resp           Professional responsible 
    * i_id_bed              Bed ID
    * i_admition_notes      Admission notes
    * @param i_dt_creation_allocation Date in which the bed allocation was done
    * @param i_dt_creation_resp       Hand-off date
    * o_id_episode          Episode ID returned
    * o_error               Error executing function
    *
    * @author               Bruno Martins
    * @since                2009/02/18
    * @version              2.5
    *
    * @author               Luís Maia
    * @comment              Reviwed function to avoid existence of two IN parameters with episode DT_BEGIN information
    * @since                2009/09/10
    * @version              2.5.0.6
    * @dependents           ADT TEAM
    **********************************************************************************************/
    FUNCTION set_inp_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_visit               IN visit.id_visit%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_external_cause         IN visit.id_external_cause%TYPE,
        i_dt_begin               IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_disch_sched         IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_id_professional        IN profissional,
        i_health_plan            IN health_plan.id_health_plan%TYPE,
        i_epis_type              IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv       IN NUMBER,
        i_first_dep_clin_serv    IN NUMBER,
        i_id_room                IN NUMBER,
        i_id_episode_ext         IN VARCHAR2,
        i_flg_type               IN VARCHAR2,
        i_type                   IN VARCHAR2,
        i_dt_surgery             IN VARCHAR2,
        i_flg_surgery            IN VARCHAR2,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        i_id_external_sys        IN epis_ext_sys.id_external_sys%TYPE,
        i_prof_resp              IN profissional,
        i_id_bed                 IN epis_info.id_bed%TYPE,
        i_admition_notes         IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admission_notes     IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE,
        i_id_transp_entity       IN transportation.id_transp_entity%TYPE,
        i_origin                 IN visit.id_origin%TYPE,
        i_companion              IN epis_info.companion%TYPE,
        i_current_timestamp      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_ehr                IN episode.flg_ehr%TYPE,
        i_flg_bed_type           IN bed.flg_type%TYPE,
        i_desc_bed               IN bed.desc_bed%TYPE,
        i_dt_creation_allocation IN bmng_allocation_bed.dt_creation%TYPE,
        i_dt_creation_resp       IN epis_prof_resp.dt_execute_tstz%TYPE,
        i_flg_resp_type          IN VARCHAR2,
        i_flg_type_upd           IN VARCHAR2,
        i_id_schedule            IN schedule.id_schedule%TYPE,
        i_transaction_id         IN VARCHAR2,
        i_id_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE,
        i_id_waiting_list        IN waiting_list.id_waiting_list%TYPE DEFAULT NULL,
        o_id_episode             OUT NUMBER,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns patient s name (reports)
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_patient             patient identifier
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2009/12/23
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_patient_name
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_name     OUT patient.name%TYPE,
        o_vip_name OUT patient.name%TYPE,
        o_alias    OUT patient.alias%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns patient s name
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_patient             patient identifier
    * @param i_is_prof_resp        true if the professional is responsible for the patient (physician or nurse)
    *                              false otherwise
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2010/07/22
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_patient_name_to_sort
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_is_prof_resp IN PLS_INTEGER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns Insitution Health Plan Entities
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional (id, institution, software)
    * @param i_id_institution            Institution identifier
    * @param i_id_health_plan_entity_to  Health Plan Entity id for take over
    * @param o_health_plan_entities      Health Plan Entities
    * @param o_flg_hp_type               Health Plans Types applicable? Y/N
    * @param o_error                     Error message
    *
    * @return                       true (sucess), false (error)
    *
    * @author                       Tércio Soares
    * @since                        2010/05/26
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION get_health_plan_entities_list
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_institution           IN institution.id_institution%TYPE,
        i_id_health_plan_entity_to IN health_plan_entity.id_health_plan_entity%TYPE,
        o_health_plan_entities     OUT pk_types.cursor_type,
        o_flg_hp_type              OUT VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate Insitution Health Plan Entities take over dates
    *
    * @param i_lang                 Language id
    * @param i_prof                 Professional (id, institution, software)
    * @param i_id_institution       Institution identifier
    * @param o_error                Error message
    *
    * @return                       true (sucess), false (error)
    *
    * @author                       Tércio Soares
    * @since                        2010/05/31
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION validate_hpe_to
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate Health Plan Entity take overs scheduled
    *
    * @param i_lang                  Language id
    * @param i_id_health_plan_entity Health Plan Entity identifier
    *
    * @return                       true ('Y'), false ('N')
    *
    * @author                       Tércio Soares
    * @since                        2010/06/04
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION verifiy_hpe_take_over_possible
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_health_plan_entity IN health_plan_entity.id_health_plan_entity%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns Insitution Health Plans
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_institution        Institution identifier
    * @param i_id_health_plan_entity Health Plan Entity identifier
    * @param o_health_plan           Health Plans
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/26
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_health_plans_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_health_plan_entity IN health_plan_entity.id_health_plan_entity%TYPE,
        o_health_plan           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns Health Plan Entity information
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_health_plan_entity Health Plan Entity identifier
    * @param o_health_plan_entity    Health Plan Entity information
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/26
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_health_plan_entity
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_health_plan_entity IN health_plan_entity.id_health_plan_entity%TYPE,
        o_health_plan_entity    OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns Health Plan information
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_health_plan        Health Plan identifier
    * @param o_health_plan           Health Plan information
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/26
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_health_plan
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_health_plan IN health_plan.id_health_plan%TYPE,
        o_health_plan    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns Health Plan Entity created/edited in the institution
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_institution               Institution id
    * @param i_id_health_plan_entity        Health Plan Entity id
    * @param i_health_plan_entity_desc      Health Plan Entity name
    * @param i_national_identifier_number   Health Plan Entity identifier
    * @param i_short_name                   Health Plan Entity short name
    * @param i_street                       Health Plan Entity Street
    * @param i_city                         Health Plan Entity City
    * @param i_telephone                    Health Plan Entity Phone number
    * @param i_fax                          Health Plan Entity Fax number
    * @param i_email                        Health Plan Entity E-mail
    * @param i_postal_code                  Health Plan Entity Postal Code
    * @param i_postal_code_city             Health Plan Entity Postal Code City
    * @param o_id_health_plan_entity        Health Plan Entity id
    * @param o_id_health_plan_entity_instit Health Plan Entity Institution id
    * @param o_error                        Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/27
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_health_plan_entity
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_institution               IN institution.id_institution%TYPE,
        i_id_health_plan_entity        IN health_plan_entity.id_health_plan_entity%TYPE,
        i_health_plan_entity_desc      IN VARCHAR2,
        i_national_identifier_number   IN health_plan_entity.national_identifier_number%TYPE,
        i_short_name                   IN health_plan_entity.short_name%TYPE,
        i_street                       IN health_plan_entity.street%TYPE,
        i_city                         IN health_plan_entity.city%TYPE,
        i_telephone                    IN health_plan_entity.telephone%TYPE,
        i_fax                          IN health_plan_entity.fax%TYPE,
        i_email                        IN health_plan_entity.email%TYPE,
        i_postal_code                  IN health_plan_entity.postal_code%TYPE,
        i_postal_code_city             IN health_plan_entity.postal_code_city%TYPE,
        o_id_health_plan_entity        OUT health_plan_entity.id_health_plan_entity%TYPE,
        o_id_health_plan_entity_instit OUT health_plan_entity_instit.id_health_plan_entity_instit%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns Health Plan created/edited in the institution
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_institution               Institution id
    * @param i_id_health_plan               Health Plan id
    * @param i_health_plan_desc             Health Plan name
    * @param i_id_health_plan_entity        Health Plan Entity id
    * @param i_id_health_plan_type          Health Plan type
    * @param i_national_identifier_number   Health Plan Entity identifier
    * @param o_id_health_plan_entity        Health Plan id
    * @param o_id_health_plan_entity_instit Health Plan Institution id
    * @param o_error                        Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/31
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_health_plan
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_institution             IN institution.id_institution%TYPE,
        i_id_health_plan             IN health_plan.id_health_plan%TYPE,
        i_health_plan_desc           IN VARCHAR2,
        i_id_health_plan_entity      IN health_plan.id_health_plan_type%TYPE,
        i_id_health_plan_type        IN health_plan.id_health_plan_type%TYPE,
        i_national_identifier_number IN health_plan_entity.national_identifier_number%TYPE,
        o_id_health_plan             OUT health_plan.id_health_plan%TYPE,
        o_id_health_plan_instit      OUT health_plan_instit.id_health_plan_instit%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a Health Plan
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_health_plan        Health Plan id
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/31
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION cancel_health_plan
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_health_plan IN health_plan.id_health_plan%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set the Health Plan Entity take over
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_health_plan_entity Health Plan Entity id
    * @param i_id_health_plan        Health Plan id
    * @param i_take_over_time        Take Over defined Time
    * @param i_notes                 Take Over notes
    * @param o_flg_status            Take over status
    * @param o_status_desc           Description of Take over status
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/31
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_health_plan_entity_to
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_health_plan_entity IN health_plan_take_over.id_health_plan_entity%TYPE,
        i_id_health_plan        IN health_plan_take_over.id_health_plan%TYPE,
        i_take_over_time        IN VARCHAR2,
        i_notes                 IN health_plan_take_over.notes%TYPE,
        o_flg_status            OUT health_plan_take_over.flg_status%TYPE,
        o_status_desc           OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a Health Plan Entity take over
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_health_plan_entity Health Plan Entityid
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/31
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION cancel_health_plan_entity_to
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_health_plan_entity IN health_plan_take_over.id_health_plan_entity%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns Health Plan Types
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param o_health_plan_types     Health Plan Types
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_health_plan_types_list
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        o_health_plan_types OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;

    /********************************************************************************************
    * returns patient s first and last name
    *
    * i_lang                Language ID
    * i_id_professional     Professional ID - PROFESSIONAL(ID, INST, SOFT),
    * i_id_patient          Patient ID
    * o_first_name          Forename
    * o_last_name           Surname   
    * o_error               Error executing function
    *
    * @author               Bruno Martins
    * @since                2010/10/15
    * @version              2.5
    * @comment              To use with wristbands, for example
    * @dependents           ADT TEAM
    **********************************************************************************************/
    FUNCTION get_pat_divided_name
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        o_first_name     OUT VARCHAR2,
        o_second_name    OUT VARCHAR2,
        o_middle_name    OUT VARCHAR2,
        o_last_name      OUT VARCHAR2,
        o_maiden_name    OUT VARCHAR2,
        o_mother_surname OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set patient death details
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_dt_deceased            Date of death
    * @param        i_deceased_motive        Cause of death
    * @param        i_deceased_place         Place of death
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca/Bruno Martins
    * @version      2.6.0.3
    * @since        01-Jul-2010
    **********************************************************************************************/
    FUNCTION set_patient_death_details
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_dt_deceased     IN patient.dt_deceased%TYPE,
        i_deceased_motive IN patient.deceased_motive%TYPE,
        i_deceased_place  IN patient.deceased_place%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * delete_discharges Deletes ADT Discharges information (RESET ONLY!!!!)
    *
    * i_lang                Language ID
    * i_id_professional     Professional ID - PROFESSIONAL(ID, INST, SOFT),
    * i_discharge_ids       Clinical Discharge IDs
    * o_error               Error executing function
    *
    * @author               Bruno Martins
    * @since                2010/09/09
    * @version              2.5
    * @comment              Deletes ADT Discharges information (RESET ONLY!!!!)
    * @dependents           ADT TEAM
    **********************************************************************************************/
    FUNCTION delete_discharges
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_discharge_ids IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * has_external_account Returns true if patient has active external account of the 
    * given account type, false otherwise                      
    *
    * i_lang                Language ID
    * i_prof                Professional ID - PROFESSIONAL(ID, INST, SOFT)
    * i_patient             Patient ID
    * o_error               Error executing function
    *
    * @author               Bruno Martins
    * @since                2010-10-18
    * @version              2.6
    * @comment              Returns true if patient has active external account of the
    *                       given account type, false otherwise
    * @dependents           ADT TEAM
    **********************************************************************************************/
    FUNCTION has_external_account
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns patient s family physician
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_patient             patient identifier
    * @param o_fam_phys_name       Patient s gamily physician
    * @param o_error               Error out
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2010-10-22
    * @version                     2.5
    ********************************************************************************************/
    FUNCTION get_pat_family_physician
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        o_fam_phys_name OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a collection of patients by pattern name criteria
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_pattern             pattern to search for
    * @param i_dt_birth            date of birth to search for (optional)
    * @return                      a collection of patients (patient_table_type)
    *
    * @author                      Bruno Martins
    * @since                       2010-10-27
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_patients
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pattern  IN VARCHAR2,
        i_dt_birth IN DATE DEFAULT NULL
    ) RETURN patient_table_type;

    /********************************************************************************************
    * Returns a collection of contacts by pattern address criteria
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_pattern             pattern to search for
    * @return                      a collection of contact address (contact_table_type)
    *
    * @author                      Bruno Martins
    * @since                       2013-02-11
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_search_contacts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pattern IN VARCHAR2
    ) RETURN contact_table_type;

    /********************************************************************************************
    * Returns patient s tax number
    *
    * @param i_lang                           language id
    * @param i_prof                           professional info
    * @param i_patient                        patient identifier
    * @param o_error                          error message
    *
    * @return                                 patient s tax number
    *
    * @author                                 BM
    * @version                                2.6
    * @since                                  2010-12-17
    ********************************************************************************************/
    FUNCTION get_tax_number
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN pat_soc_attributes.num_contrib%TYPE;

    /********************************************************************************************
    * Disables all processes in the given institution to all patients that do not belong to 
    * RESET functionality
    * WARNING: this should be used carefully and only for demos
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_patient_list        list of patients to which we DO NOT disable processes
    * @return                      true if we do not find errors, false otherwise
    *
    * @author                      Bruno Martins
    * @since                       2011-01-12
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION reset_inactivate_patients
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient_list IN table_number
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get national health plan info
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_id_patient          patient id
    * @param o_num_health_plan     patient s health plan number
    * @param o_hp_entity           health plan entity description
    * @param o_hp_desc             health plan name
    * @return                      true if successful, false otherwise
    *
    * @author                      Bruno Martins
    * @since                       2011-02-18
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_national_health_number
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        o_hp_id_hp        OUT pat_health_plan.id_health_plan%TYPE,
        o_num_health_plan OUT pat_health_plan.num_health_plan%TYPE,
        o_hp_entity       OUT VARCHAR2,
        o_hp_desc         OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get health plan info according with nhn validation rules
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_id_patient          patient id
    * @param i_id_episode          episode id    
    * @param o_num_health_plan     patient s health plan number
    * @param o_hp_entity           health plan entity description
    * @param o_hp_desc             health plan name
    * @param o_hp_in_use           health plan in use
    * @param o_nhn_number          national health number
    * @param o_nhn_hp_entity       national health plan number entity
    * @param o_nhn_hp_desc         national health plan number description
    * @param o_nhn_status          national health number validation flag status 
    * @param o_nhn_desc_status     national health number valtidation description status
    * @param o_nhn_in_use          national health number in use or not
    * @return                      true if successful, false otherwise
    *
    * @author                      Bruno Martins
    * @since                       2011-02-07
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_health_plan
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        o_hp_id_hp        OUT pat_health_plan.id_health_plan%TYPE,
        o_num_health_plan OUT pat_health_plan.num_health_plan%TYPE,
        o_hp_entity       OUT VARCHAR2,
        o_hp_desc         OUT VARCHAR2,
        o_hp_in_use       OUT VARCHAR2,
        o_nhn_id_hp       OUT pat_health_plan.id_health_plan%TYPE,
        o_nhn_number      OUT VARCHAR2,
        o_nhn_hp_entity   OUT VARCHAR2,
        o_nhn_hp_desc     OUT VARCHAR2,
        o_nhn_status      OUT VARCHAR2,
        o_nhn_desc_status OUT VARCHAR2,
        o_nhn_in_use      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET_PAT_RECM
    *
    * @param i_lang                language id
    * @param i_prof                professional id (INTERFACE PROFESSIOAL USED FOR MIGRATION)
    * @param i_id_pat              Patient identifier
    * @param o_nkda                Indicate if there is allergies to medication ('Y'-Yes; 'N'No)
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @version                     2.6.1.1
    * @since                       2011/04/18
    * @dependents                  PK_EPISODE.GET_EPIS_HEADER
    **********************************************************************************************/
    FUNCTION get_pat_recm
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        o_nkda   IN OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET_RECM_DESCRIPTION_LIST
    *
    * @param i_lang                language id
    * @param i_prof                professional id (INTERFACE PROFESSIOAL USED FOR MIGRATION)
    * @param o_recm                RECM description
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @version                     2.6.1.1
    * @since                       2011/04/19
    * @dependents                  PK_LIST.GET_RECM_DESCRIPTION_LIST
    **********************************************************************************************/
    FUNCTION get_recm_description_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_recm  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns patient health plans
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_patient            Patient id
    * @param o_pat_health_plan       Patient health plans
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Bruno Martins
    * @since                         2011-03-21
    * @version                       2.6.1
    ********************************************************************************************/
    FUNCTION get_pat_health_plans
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        o_pat_health_plan OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns patient health plan info
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_pat_health_plan    Pat health plan id identifier
    * @param i_flg_output            (F)inancial entity, (H)ealth plan, (N)umber health plan
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Bruno Martins
    * @since                         2011-03-31
    * @version                       2.6.1
    ********************************************************************************************/
    FUNCTION get_pat_health_plan_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_pat_health_plan IN pat_health_plan.id_pat_health_plan%TYPE,
        i_flg_output         IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Replace ADT visit of an episode.
    *
    * @param i_lang                Language id
    * @param i_prof                Professional id
    * @param i_id_episode          Episode ID to have its data replaced
    * @param i_prev_id_visit       Previous visit ID, to obtain the new data
    * @param i_prev_id_epis_type   Previous episode type ID
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Brito
    * @version                     2.6.1.1
    * @since                       2011/07/01
    **********************************************************************************************/
    FUNCTION replace_visit_adt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_prev_id_visit     IN visit.id_visit%TYPE,
        i_prev_id_epis_type IN episode.id_epis_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a list of professionals assigned to the specified clinical service.
    * Used to select the responsible physician when admitting a patient to another software.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_institution              Destination institution ID
    * @param   i_software                 Destination software ID
    * @param   i_dest_service             Destination clinical service ID
    * @param   o_prof_list                List of professionals 
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         José Brito
    * @version                        2.6.1
    * @since                          07-07-2011
    **********************************************************************************************/
    FUNCTION get_admission_prof_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_dest_service IN clinical_service.id_clinical_service%TYPE,
        o_prof_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns Health Plan Entity created/edited in the institution
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_institution               Institution id
    * @param i_id_health_plan_entity        Health Plan Entity id
    * @param i_health_plan_entity_desc      Health Plan Entity name
    * @param i_flg_available                Health Plan status
    * @param i_national_identifier_number   Health Plan Entity identifier
    * @param i_short_name                   Health Plan Entity short name
    * @param i_street                       Health Plan Entity Street
    * @param i_city                         Health Plan Entity City
    * @param i_telephone                    Health Plan Entity Phone number
    * @param i_fax                          Health Plan Entity Fax number
    * @param i_email                        Health Plan Entity E-mail
    * @param i_postal_code                  Health Plan Entity Postal Code
    * @param i_postal_code_city             Health Plan Entity Postal Code City
    * @param o_id_health_plan_entity        Health Plan Entity id
    * @param o_id_health_plan_entity_instit Health Plan Entity Institution id
    * @param o_error                        Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/10/27
    * @version                       2.6.1.4
    ********************************************************************************************/
    FUNCTION set_health_plan_entity_ext
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_institution               IN institution.id_institution%TYPE,
        i_id_health_plan_entity        IN health_plan_entity.id_health_plan_entity%TYPE,
        i_health_plan_entity_desc      IN VARCHAR2,
        i_flg_available                IN health_plan_entity.flg_available%TYPE,
        i_national_identifier_number   IN health_plan_entity.national_identifier_number%TYPE,
        i_short_name                   IN health_plan_entity.short_name%TYPE,
        i_street                       IN health_plan_entity.street%TYPE,
        i_city                         IN health_plan_entity.city%TYPE,
        i_telephone                    IN health_plan_entity.telephone%TYPE,
        i_fax                          IN health_plan_entity.fax%TYPE,
        i_email                        IN health_plan_entity.email%TYPE,
        i_postal_code                  IN health_plan_entity.postal_code%TYPE,
        i_postal_code_city             IN health_plan_entity.postal_code_city%TYPE,
        o_id_health_plan_entity        OUT health_plan_entity.id_health_plan_entity%TYPE,
        o_id_health_plan_entity_instit OUT health_plan_entity_instit.id_health_plan_entity_instit%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns Health Plan created/edited in the institution
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_institution               Institution id
    * @param i_id_health_plan               Health Plan id
    * @param i_health_plan_desc             Health Plan name
    * @param i_id_health_plan_entity        Health Plan Entity id
    * @param i_id_health_plan_type          Health Plan type
    * @param i_flg_available                Health Plan status
    * @param i_national_identifier_number   Health Plan Entity identifier
    * @param o_id_health_plan_entity        Health Plan id
    * @param o_id_health_plan_entity_instit Health Plan Institution id
    * @param o_error                        Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/10/27
    * @version                       2.6.1.4
    ********************************************************************************************/
    FUNCTION set_health_plan_ext
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_institution             IN institution.id_institution%TYPE,
        i_id_health_plan             IN health_plan.id_health_plan%TYPE,
        i_health_plan_desc           IN VARCHAR2,
        i_id_health_plan_entity      IN health_plan.id_health_plan_type%TYPE,
        i_id_health_plan_type        IN health_plan.id_health_plan_type%TYPE,
        i_flg_available              IN health_plan.flg_available%TYPE,
        i_national_identifier_number IN health_plan_entity.national_identifier_number%TYPE,
        o_id_health_plan             OUT health_plan.id_health_plan%TYPE,
        o_id_health_plan_instit      OUT health_plan_instit.id_health_plan_instit%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns Y if patient came from Scheduler
    *         N otherwise
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_patient                      Patient id
    *
    * @return                        Y if patient came from Scheduler
    *                                N otherwise
    *
    * @author                        BM
    * @since                         2011-11-08
    * @version                       2.6.1.5
    ********************************************************************************************/
    FUNCTION is_contact
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns A collection with patient s valid exemptions
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_patient                   Patient id
    * @param i_current_date                 Date to use as a reference
    *
    * @return                        A collection with patient s valid exemptions
    *
    * @author                        BM
    * @since                         2011-11-21
    * @version                       2.6.1.5
    ********************************************************************************************/
    FUNCTION get_pat_exemptions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_current_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN table_varchar;

    /********************************************************************************************
    * Returns patient info used in prescription
    *
    * @param i_lang                language id
    * @param i_id_patient          patient id
    * @param i_prof                professional (id, institution, software)
    * @param i_current_timestamp   current date (timestamp format)
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
        i_lang              IN language.id_language%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_current_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_flg_recm          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns patient info used in prescription
    *
    * @param i_lang                language id
    * @param i_id_patient          patient id
    * @param i_prof                professional (id, institution, software)
    * @param i_id_episode          episode identifier
    * @param i_current_timestamp   current timestamp local time zone
    * @param i_id_prescription     prescription identifier
    * @param o_name                patient s full name
    * @param o_gender              flag gender (as it is in patient)
    * @param o_desc_gender         gender full description
    * @param o_dt_birth            date of birth
    * @param o_dt_deceased         deceased date
    * @param o_flg_migrator        flag that indicates if patient is a migrator person (calculated via health plans)
    * @param o_id_country_nation   country id (nationality related)
    * @param o_sns                 national health number policy number
    * @param o_valid_sns           Y if is a valid sns according to national standards, N otherwise
    * @param o_flg_occ_disease     occupational diseases health plan usage: Y or N
    * @param o_flg_independent     independents health plan usage: Y or N
    * @param o_num_health_plan     policy number from used health plan (possibly different from sns)
    * @param o_hp_entity           health plan description from health plan in use (do not confuse this with health plan entity)
    * @param o_id_health_plan      health plan id in use
    * @param o_num_health_plan     national health number policy number
    * @param o_flg_recm            flag associated to recm and diplomas: R, O or RO
    * @param o_main_phone          patient main phone number
    * @param o_hp_alpha2_code      country associated with a migrant patient (calculated from health plans)
    * @param o_hp_country_desc     country description associated with a migrant patient (calculated from health plans)
    * @param o_hp_national_ident_nbr national identifier of health plan associated with a migrant patient
    * @param o_hp_dt_effective     expiry date of health plan in use
    * @return                      boolean if the function was called with success
    *
    * @author                      Bruno Martins
    * @since                       2012-09-19
    * @version                     2.6.1
    ********************************************************************************************/
    FUNCTION get_pat_info
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_patient              IN patient.id_patient%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_current_timestamp       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_id_presc                IN table_number DEFAULT NULL,
        i_flg_info_for_medication IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_name                    OUT patient.name%TYPE,
        o_gender                  OUT patient.gender%TYPE,
        o_desc_gender             OUT VARCHAR2,
        o_dt_birth                OUT VARCHAR2,
        o_dt_deceased             OUT VARCHAR2,
        o_flg_migrator            OUT pat_soc_attributes.flg_migrator%TYPE,
        o_id_country_nation       OUT country.alpha2_code%TYPE,
        o_sns                     OUT pat_health_plan.num_health_plan%TYPE,
        o_valid_sns               OUT VARCHAR2,
        o_flg_occ_disease         OUT VARCHAR2,
        o_flg_independent         OUT VARCHAR2,
        o_num_health_plan         OUT pat_health_plan.num_health_plan%TYPE,
        o_hp_entity               OUT VARCHAR2,
        o_id_health_plan          OUT NUMBER,
        o_flg_recm                OUT VARCHAR2,
        o_main_phone              OUT VARCHAR2,
        o_hp_alpha2_code          OUT VARCHAR2,
        o_hp_country_desc         OUT VARCHAR2,
        o_hp_national_ident_nbr   OUT VARCHAR2,
        o_hp_dt_effective         OUT VARCHAR2,
        o_valid_hp                OUT VARCHAR2,
        o_flg_type_hp             OUT health_plan.flg_type%TYPE,
        o_hp_id_content           OUT health_plan.id_content%TYPE,
        o_hp_inst_ident_nbr       OUT pat_health_plan.inst_identifier_number%TYPE,
        o_hp_inst_ident_desc      OUT pat_health_plan.inst_identifier_desc%TYPE,
        o_hp_dt_valid             OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns Patients main contact
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_patient                   Patient id
    * @param i_id_contact_method            Patient s contact method
    * @param o_contact_method               Patient s main contact according to contact method
    *
    * @return                        True if success, false otherwise
    *
    * @author                        BM
    * @since                         2012-04-27
    * @version                       2.6.2
    ********************************************************************************************/
    FUNCTION get_main_contact
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_contact_method IN contact_method.id_contact_method%TYPE,
        o_contact           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validates SNS numbers
    *
    * @param i_str_to_validate     SNS to validate (check digit included)
    * @return                      boolean true If the string is validated against SNS rules
    *                              false, otherwise
    *
    * @author                      Bruno Martins
    * @since                       
    * @version                     2.6.1
    ********************************************************************************************/
    FUNCTION validate_sns(i_sns IN VARCHAR2) RETURN BOOLEAN;

    /********************************************************************************************
    * Validates Mexican CURP
    *
    * @param 
    * @return                      boolean true If the string is validated against CURP rules
    *                              false, otherwise
    *
    * @author                      Bruno Martins
    * @since                       
    * @version                     2.6.1
    ********************************************************************************************/
    FUNCTION validate_curp
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_first_name  IN patient.first_name%TYPE,
        i_middle_name IN patient.middle_name%TYPE,
        i_last_name   IN patient.last_name%TYPE,
        i_dt_birth    IN patient.dt_birth%TYPE,
        i_gender      IN patient.gender%TYPE,
        i_country     IN country.id_country%TYPE,
        i_state       IN rb_regional_classifier.id_rb_regional_classifier%TYPE,
        i_curp        IN person.social_security_number%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validates Italian tax number
    *
    * @param i_str_to_validate     SNS to validate (check digit included)
    * @return                      boolean true If the string is validated against SNS rules
    *                              false, otherwise
    *
    * @author                      Bruno Martins
    * @since                       
    * @version                     2.6.1
    ********************************************************************************************/
    FUNCTION validate_it_tax_number
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_first_name IN patient.first_name%TYPE,
        i_last_name  IN patient.last_name%TYPE,
        i_dt_birth   IN patient.dt_birth%TYPE,
        i_gender     IN patient.gender%TYPE,
        i_country    IN country.id_country%TYPE,
        i_commune    IN rb_regional_classifier.id_rb_regional_classifier%TYPE,
        i_tax_number IN pat_soc_attributes.num_contrib%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set ADT discharge
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_discharge           PFH discharge id
    * @param        i_id_episode             PFH episode id
    * @param        i_dt_admin_tstz          Date of administrative discharge
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Bruno Martins
    * @version      2.6
    * @since        29-Aug-2012
    **********************************************************************************************/
    FUNCTION set_discharge_adt
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_discharge  IN discharge.id_discharge%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_visit      IN visit.id_visit%TYPE,
        i_dt_admin_tstz IN discharge.dt_admin_tstz%TYPE,
        i_notes         IN discharge_adt.notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function updates admission data in ADT
    *
    * @param i_lang language id
    * @param i_prof user s object
    * @param i_episode episode id
    * @param i_origin origin id
    * @param i_ext_cause external cause information
    * @param i_transp_entity transp entity
    * @param i_notes notes on admission
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION update_admission_adt
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode_adt.id_episode%TYPE,
        i_origin        IN admission_adt.id_origin%TYPE,
        i_ext_cause     IN admission_edis.id_external_cause%TYPE,
        i_transp_entity IN admission_edis.id_transp_entity%TYPE,
        i_notes         IN admission_adt.comments%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns patient s emergency contact
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param i_patient             patient identifier
    * @param o_address             Patient s address street
    * @param o_location            Patient s address location
    * @param o_regional            Patient s district or county or parish (most specific info)
    * @param o_phone1              Patient s main phone (mobile phone)
    * @param o_phone2              Patient s secondary phone (landline)
    * @param o_error               Error out        
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2012-12-11
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_contact_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_address  OUT VARCHAR2,
        o_location OUT VARCHAR2,
        o_regional OUT VARCHAR2,
        o_phone1   OUT VARCHAR2,
        o_phone2   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns patient s emergency contact
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param i_patient             patient identifier
    * @param o_name                Emergency contact name
    * @param o_contact             Emergency contact main phone
    * @param o_family_relationship Family relationship description
    * @param o_error               Error out        
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2012-12-20
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_emergency_contact
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        o_name                OUT VARCHAR2,
        o_contact             OUT VARCHAR2,
        o_family_relationship OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns patient s emergency contact
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param i_patient             patient identifier
    * @param o_name                Emergency contact name
    * @return                      varchar2 emergency contact name
    *
    * @author                      Ana Moita
    * @since                       2012-12-20
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_emergency_contact_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns evaluates if patient has valid inail certificates
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param i_patient             patient identifier
    * @param i_episode             episode identifier
    * @param o_inail_info          Inail info flag as described
    *          N  No active INAIL present
    *          I  Patient has INAIL but there are mandatory fields do fill
    *          C  Patient has INAIL and all mandatory info is filled
    * @param o_error               Error out
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2013-01-16
    * @version                     2.6.3
    ********************************************************************************************/
    FUNCTION get_inail_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_inail_info OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns A collection with patient s valid exemptions
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_patient                   Patient id
    * @param i_current_date                 Date to use as a reference
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
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_current_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_exemptions   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns details from an exemption
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_pat_isencao               PAT_ISENCAO primary key
    *
    * @return                        Exemption description
    *
    * @author                        BM
    * @since                         2013-09-18
    * @version                       2.6.3.8.1
    ********************************************************************************************/
    FUNCTION get_pat_exemption_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_isencao IN pat_isencao.id_pat_isencao%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns patient s financial type
    *
    * @param i_lang                           language id
    * @param i_prof                           professional info
    * @param i_patient                        patient identifier
    * @param o_error                          error message
    *
    * @return                                 patient s flag financial type
    *
    * @author                                 BM
    * @version                                2.6.3
    * @since                                  2013-11-13
    ********************************************************************************************/
    FUNCTION get_flg_financial_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN patient.flg_financial_type%TYPE;

    /********************************************************************************************
    * Returns patient identification doc
    *
    * @param i_lang                           language id
    * @param i_prof                           professional info
    * @param i_patient                        patient identifier
    * @param o_error                          error message
    *
    * @return                                 patient s identification document number
    *
    * @author                                 BM
    * @version                                2.6.3
    * @since                                  2013-12-02
    ********************************************************************************************/
    FUNCTION get_identification_doc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return specific info for inpatient discharge report in KW
    * ALERT-280978[KW] :: [KIDNEY] :: [REPORTS] ::MoH Inpatient Discharge Summary:: H.S.11
    *
    * @param i_lang                           language id
    * @param i_prof                           professional info
    * @param i_id_patient                     patient identifier
    * @param i_id_episode                     episode identifier    
    * @param o_name                           patient full name
    * @param o_gender                         patient gender alert flag
    * @param o_desc_gender                    patient gender full description
    * @param o_dt_birth                       patient date of birth in YYYYMMDDHH24MISS format
    * @param o_place_of_residence_cod         place of residence external code
    * @param o_nacionality_cod                nationality external code
    * @param o_marital_status_cod             marital status external code
    * @param o_origin_cod                     origin external code                      
    *
    * @return                                 TRUE in case of success, FALSE otherwise
    *
    * @author                                 Bruno Martins
    * @version                                2.6.4
    * @since                                  2014-05-16
    ********************************************************************************************/
    FUNCTION get_pat_info_report_kw
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        o_name                   OUT patient.name%TYPE,
        o_gender                 OUT patient.gender%TYPE,
        o_desc_gender            OUT VARCHAR2,
        o_dt_birth               OUT VARCHAR2,
        o_place_of_residence_cod OUT VARCHAR2,
        o_nacionality_cod        OUT VARCHAR2,
        o_occupation_cod         OUT VARCHAR2,
        o_marital_status_cod     OUT VARCHAR2,
        o_origin_cod             OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Test if patient has other_names_1/2/3 filled
    * These fields are used for KW to store arabic names
    *
    * @param i_patient                        Patient ID
    *
    * @return                                 'Y' if other_names_1/2/3 filled, 'N' otherwise
    *
    * @author                                 Bruno Martins
    * @version                                2.6.4.1
    * @since                                  2014-07-17
    ********************************************************************************************/
    FUNCTION has_other_names(i_patient IN patient.id_patient%TYPE) RETURN VARCHAR2;

    /********************************************************************************************
    * Get patient other names
    * These fields are used for KW to store arabic names
    *
    * @param i_patient                        Patient ID
    *
    * @return                                 Patient concatenated other names
    *
    * @author                                 Bruno Martins
    * @version                                2.6.4.1
    * @since                                  2014-07-17
    ********************************************************************************************/
    FUNCTION get_other_names(i_patient IN patient.id_patient%TYPE) RETURN VARCHAR2;

    /********************************************************************************************
    * Get admission ticket number to use in waiting line
    * These was a request for KW 
    *
    * @param i_lang                           Language ID
    * @param i_prof                           Professional ID
    * @param i_id_episode                     Episode ID
    *
    * @return                                 Admission ticket number
    *
    * @author                                 Bruno Martins
    * @version                                2.6.4.2.4
    * @since                                  2014-11-27
    ********************************************************************************************/
    FUNCTION get_ticket_number
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode_adt.id_episode%TYPE
    ) RETURN VARCHAR2;

    /******************************************************************************
    * This function is used for cancelling episodes (scheduled or not) in PFH.
    * 
    * @param i_lang            Professional preferred language
    * @param i_id_episode      Episode ID
    * @param i_prof            Professional executing the action
    * @param i_cancel_reason   Reason for cancelling this episode
    * @param i_cancel_type     'E' Cancel a registration; 'S' Cancel a scheduled episode; 
    *                          'A' Cancelled in ALERT® (ADT included); 'I' Cancelled through INTER-ALERT®;
    *                          'D' Cancelled through medical discharge cancellation.
    * @param i_dt_cancel       Cancel date
    * @param i_transaction_id  scheduler 3 transaction id needed for calls to pk_schedule_api_upstream
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Bruno Martins
    * @version                 v2.6.4.3
    * @since                   2015-01-12
    *
    ******************************************************************************/
    FUNCTION call_cancel_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN episode.desc_cancel_reason%TYPE,
        i_cancel_type    IN VARCHAR2 DEFAULT 'E',
        i_dt_cancel      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * This function is used to get printing options for popup completion
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_flg_show_popup  Y - show popup, N - do not show popup
    * @param o_options         Options to show in popup
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Bruno Martins
    * @version                 v2.6.5.0.1
    * @since                   2015-04-07
    *
    ******************************************************************************/
    FUNCTION get_ges_print_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_flg_show_popup OUT VARCHAR2,
        o_options        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * This function is used to get printing job information
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param i_id_print_list_job Print job ID    
    * 
    * @return                  Printing job information
    *                          (id_print_list_job, id_print_list_area, title_desc, subtitle_desc)
    * @author                  Bruno Martins
    * @version                 v2.6.5.0.1
    * @since                   2015-04-07
    *
    ******************************************************************************/
    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job;

    /******************************************************************************
    * This function is used to compare printing jobs
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param i_print_job_context_data Print job context (ID_REPORT|ID_ISENCAO)
    * @param i_tbl_print_list_jobs Print job ids
    * 
    * @return                  Collection with existing jobs that have inputted context
    * @author                  Bruno Martins
    * @version                 v2.6.5.0.1
    * @since                   2015-04-07
    *
    ******************************************************************************/
    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_tbl_print_list_jobs    IN table_number
    ) RETURN table_number;

    /******************************************************************************
    * This function is used to add specified item to printing list
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param i_patient         Patient id
    * @param i_episode         Context episode
    * @param i_id_exemptions   Collection with exemptions ids
    * @param i_id_reports      Collection with report ids
    * @param i_print_arguments Collection with JSON string to pass to REPORTs
    * @param o_print_list_job  Collection with printing list job ids that were created
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    * @author                  Bruno Martins
    * @version                 v2.6.5.0.1
    * @since                   2015-04-07
    *
    ******************************************************************************/
    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_exemptions   IN table_number,
        i_id_reports      IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * This function checks if the patient has a specific exemption
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param i_id_patient      Patient id
    * @param i_id_isencao      Exemption to find
    * @param o_error           Error message
    * 
    * @return                  TRUE if the patient has the exemption, FALSE otherwise
    * @author                  Bruno Martins
    * @version                 v2.6.5.0.1
    * @since                   2015-04-10
    *
    ******************************************************************************/
    FUNCTION get_pat_exemption
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_isencao.id_patient%TYPE,
        i_id_isencao IN pat_isencao.id_isencao%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to map ADT parameters with external system values
    *
    * @param i_id_market                      market id
    * @param i_value_type                     type of value to be mapped
    * @param i_original_value                 value for ADT
    * @param i_condition                      condition to map value   
    *
    * @return                                 external system value
    *
    * @author                                 Bruno Martins
    * @version                                2.6.4
    * @since                                  2014-05-16
    ********************************************************************************************/
    FUNCTION map_value
    (
        i_id_market      IN market.id_market%TYPE,
        i_value_type     IN VARCHAR2,
        i_original_value IN VARCHAR2,
        i_condition      IN VARCHAR2 DEFAULT '*'
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function to check if given exemption is available
    *
    * @param i_id_isencao                    id of exemption in table ALERT_ADTCOD_CFG.ISENCAO
    *
    * @return                                 BOOLEAN if exemption is available returns true
    *
    * @author                                 Carlos Ferreira
    * @version                                2.6.5.0.1
    * @since                                  2015-04-21
    ********************************************************************************************/
    FUNCTION check_exemption_availability(i_id_isencao IN NUMBER) RETURN BOOLEAN;
    ---
    FUNCTION get_nationality
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_regional_classifier_desc
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_rb_regional_classifier IN alert_adtcod_cfg.rb_regional_classifier.id_rb_regional_classifier%TYPE
    ) RETURN VARCHAR2;
    --

    FUNCTION get_settlement_type_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_settlement_type IN alert_adtcod_cfg.settlement_type_mx.id_type_settlement%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_settlement_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_settlement      IN alert_adtcod_cfg.settlement_mx.id_settlement%TYPE,
        i_id_settlement_type IN alert_adtcod_cfg.settlement_mx.id_type_settlement%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function that returns the classifier_code of a regional_classifier
    *
    * @param i_rb_reg_class           id_rb_regional_classifier ID
    * @param i_rank                   RANK for parent pruposes (if null is the ID in self)
    *
    * @return                         CODE of the regional classifier
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          19/01/2017
    **********************************************************************************************/

    FUNCTION get_rb_reg_classifier_code
    (
        i_rb_reg_class IN rb_regional_classifier.id_rb_regional_classifier%TYPE,
        i_rank         IN NUMBER DEFAULT NULL
    ) RETURN rb_regional_classifier.reg_classifier_code%TYPE;

    FUNCTION get_rb_reg_classifier_id
    (
        i_rb_reg_class IN rb_regional_classifier.id_rb_regional_classifier%TYPE,
        i_rank         IN NUMBER DEFAULT NULL
    ) RETURN rb_regional_classifier.id_rb_regional_classifier%TYPE;

    /********************************************************************************************
    * Function that returns the id_rb_regional_classifier
    *
    * @param i_person           PERSON ID
    *
    * @return                         id_rb_regional_classifier
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          19/01/2017
    **********************************************************************************************/

    FUNCTION get_patient_address_id(i_person IN person.id_person%TYPE)
        RETURN contact_address.id_rb_regional_classifier%TYPE;

    /********************************************************************************************
    * Function that returns the ilocalation of the mai address
    *
    * @param i_person           PERSON ID
    *
    * @return                         id_rb_regional_classifier
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          20/01/2017
    **********************************************************************************************/
    FUNCTION get_patient_address_colony(i_person IN person.id_person%TYPE) RETURN contact_address.location%TYPE;

    FUNCTION get_patient_address_colony
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_person IN person.id_person%TYPE
    ) RETURN contact_address.location%TYPE;

    /********************************************************************************************
    * This function returns institution clues code
    *
    * @param i_id_clues       CLUES ID
    *
    * @return                 code
    *
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.0
    * @since                  20/01/2017
    **********************************************************************************************/
    FUNCTION get_clues_code
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * This function returns institution clues name
    *
    * @param i_id_clues       CLUES ID
    *
    * @return                 code
    *
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.0
    * @since                  20/01/2017
    **********************************************************************************************/
    FUNCTION get_clues_name
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * This function returns information  id clues of an institution
    *
    * @param i_lang           LANG ID
    * @param i_prof           PROFESSIONAL ID
    * @param i_id_institution INSTITUTION ID     
    *
    * @return                  CLUES ID
    *
    *
    * @author                  Elisabete Bugalho
    * @version                 2.7.0
    * @since                   23/01/2017
    **********************************************************************************************/

    FUNCTION get_clues_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN NUMBER
    ) RETURN NUMBER;

    /********************************************************************************************
    * This function returns institution unity_status
    *
    * @param i_id_clues       CLUES ID
    *
    * @return                 code
    *
    *
    * @author                 Carlos Ferreira
    * @version                2.7.0
    * @since                  24/01/2017
    **********************************************************************************************/
    FUNCTION get_clues_unity_status
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This function returns institution regional classifier
    *
    * @param i_id_clues       CLUES ID
    *
    * @return                 code
    *
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.0
    * @since                  20/01/2017
    **********************************************************************************************/
    FUNCTION get_clues_id_rb_regional
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;

    /********************************************************************************************
    * This function returns institution jurisdiction
    *
    * @param i_id_clues       CLUES ID
    *
    * @return                 code
    *
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.0
    * @since                  20/01/2017
    **********************************************************************************************/
    FUNCTION get_clues_jurisdiction
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_health_plan_field_mx
    (
        i_episode       IN NUMBER,
        i_flg_main      IN VARCHAR2,
        i_field_to_show IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_clues_field
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL,
        i_field          IN VARCHAR2,
        i_mode           IN VARCHAR2 DEFAULT pk_adt_core.k_rb_code
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This function returns id_content of given id_origin
    *
    * @param i_id_origin      origin identifier
    *
    * @return                 id_content
    *
    *
    * @author                 Carlos Ferreira
    * @version                2.7.1
    * @since                  2017-03
    **********************************************************************************************/
    FUNCTION get_origin_id_cnt(i_id_origin IN NUMBER) RETURN VARCHAR2;
    /********************************************************************************************
    * This function returns ithe institution name for einpatient admission
    *
    * @param i_episode      id_episode on pfh
    *
    * @return                 institution name
    *
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.1
    * @since                  2017-05-18
    **********************************************************************************************/

    FUNCTION get_admission_institution
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_health_plan_sinac
    (
        i_episode IN NUMBER,
        i_mode    IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_jurisdiction_info
    (
        i_lang             IN NUMBER,
        i_id_entity        IN NUMBER,
        i_id_municipaltity IN NUMBER,
        i_id_jurisdiction  IN NUMBER
    ) RETURN NUMBER;

    FUNCTION is_place_of_birth_inst
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_birth_inst IN pat_birthplace.id_institution%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_birth_certificate_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_flg_edition IN epis_documentation.flg_edition_type%TYPE DEFAULT 'N',
        i_data_show   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_code_birth_certificate(i_patient IN NUMBER) RETURN patient.code_birth_certificate%TYPE;

    FUNCTION get_patient_address
    (
        i_lang   IN language.id_language%TYPE,
        i_person IN person.id_person%TYPE
    ) RETURN contact_address.address_line1%TYPE;

    FUNCTION get_jurisdiction_id(id_rb_regional_classifier IN rb_regional_classifier.id_rb_regional_classifier%TYPE)
        RETURN NUMBER;

    FUNCTION get_admission_institution_id(i_episode IN episode.id_episode%TYPE) RETURN NUMBER;

    FUNCTION build_name
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_config      IN sys_config.value%TYPE,
        i_first_name  IN patient.first_name%TYPE,
        i_second_name IN patient.second_name%TYPE,
        i_midlle_name IN patient.middle_name%TYPE,
        i_last_name   IN patient.last_name%TYPE,
        o_pat_name    OUT patient.name%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns settlement code
    *
    * @param i_id_settlement_type     id settlement type ID 
    
    *
    * @return                         CODE of the settlement
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.3.1
    * @since                          04/04/2018
    **********************************************************************************************/
    FUNCTION get_settlement_code
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_settlement_type IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION set_pat_birthplace
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_id_country       IN country.id_country%TYPE,
        i_institution_code IN VARCHAR2,
        i_id_mother_nationality IN country.id_country%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_country_id_cnt(i_id_country IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_pat_health_plan_mx
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN NUMBER,
        i_flg_main IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_pat_other_names
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        o_other_names_1 OUT patient.other_names_1%TYPE,
        o_other_names_2 OUT patient.other_names_2%TYPE,
        o_other_names_3 OUT patient.other_names_3%TYPE,
        o_other_names_4 OUT patient.other_names_4%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient process number (MRN)
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_patient            Patient ID
    *
    * @return                        patient MRN
    *
    * @author                        Sofia Mendes
    * @since                         2018/08/22
    * @version                       2.7.4.0
    ********************************************************************************************/
    FUNCTION get_pat_process_nr
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN clin_record.num_clin_record%TYPE;

    /********************************************************************************************
    * This function returns the department where the patient is located for inpatient admissions
    *
    * @param i_episode      id_episode on pfh
    *
    * @return                 id department
    *
    *
    * @author                 Sofia Mendes
    * @version                2.7.4
    * @since                  2018-08-29
    **********************************************************************************************/
    FUNCTION get_department_patient_located
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN department.id_department%TYPE;

    FUNCTION cancel_episode_adt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get patient compensation
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_patient             Patient identifier
    * @param        i_id_episode             PFH episode id
    * @param        o_flg_comp               Flag que indica se há comparticipação (conforme quadro abaixo)
    * @param        o_flg_special_comp       Flag que indica se há comparticipação especial (conforme quadro abaixo)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Bruno Martins
    * @version      2.5
    * @since        02-10-2013
    *                                                       Comparticipação Comparticipação especial
    * 1.    Situações sem comparticipação do SNS    
    *   Pacientes com plano de saúde “sem comparticipação”  N               N
    * 2.    Situações com comparticipação do SNS    
    *   Pacientes com SNS                                   Y               N
    *   Pacientes migrantes (com ou sem SNS)                Y               N
    *   Pacientes da CNRPP                                  Y               N
    * 3.    Situações com comparticipação especial do SNS   
    *   Pacientes pensionistas (com RECM = R)               Y               Y
    *********************************************************************************/
    FUNCTION get_pat_comp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        o_flg_comp         OUT VARCHAR2,
        o_flg_special_comp OUT VARCHAR2,
        o_flg_plan_type    OUT VARCHAR2,
        o_flg_recm         OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_preferred_language
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Shows, when applicable, a warning message to the user. Validates Prescription Rules - ACSS Request
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_episode                Episode
    * @param i_type                   M - Medication, R - Referral
    *
    * @param      o_flg_show         Flag that indicates if exist any warning message to be shown
    * @param      o_message_title    Label for the title of the warning message screen
    * @param      o_message_text     Warning message
    * @param      o_forward_button   Label for the forward button
    * @param      o_back_button      Label for the back button
    * @param      o_error            Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Pedro Morais
    * @version                        0.1
    * @since                          2011/07/06
    **********************************************************************************************/
    FUNCTION check_patient_rules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_type            IN VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_message_title   OUT VARCHAR2,
        o_message_text    OUT VARCHAR2,
        o_forward_button  OUT VARCHAR2,
        o_back_button     OUT VARCHAR2,
        o_flg_can_proceed OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    -- Advanced Input configurations
    g_all_institution institution.id_institution%TYPE;
    g_all_software    software.id_software%TYPE;

    g_package_owner VARCHAR2(10) := 'ALERT';
    g_package_name  VARCHAR2(10) := 'PK_ADT';

    g_adtexception EXCEPTION;

    g_false PLS_INTEGER := 0;
    g_true  PLS_INTEGER := 1;

    g_vip_icon         CONSTANT VARCHAR2(10) := 'VIPIcon';
    g_vip_icon_message CONSTANT VARCHAR2(10) := 'ICON_T094';

    g_emergency_contact_type     CONSTANT NUMBER(2) := 10;
    g_nl_emergency_contact_desc  CONSTANT NUMBER(2) := 14;
    g_def_emergency_contact_desc CONSTANT NUMBER(2) := 4;
    g_mobile_contact_type        CONSTANT NUMBER(2) := 11;
    g_landline_contact_type      CONSTANT NUMBER(2) := 12;

    g_nl_market CONSTANT NUMBER(2) := 5;
    g_us_market CONSTANT NUMBER(2) := 2;
    g_uk_market CONSTANT NUMBER(2) := 8;
    g_pt_market CONSTANT NUMBER(2) := 1;
    g_br_market CONSTANT NUMBER(2) := 3;
    g_it_market CONSTANT NUMBER(2) := 4;
    g_cl_market CONSTANT NUMBER(2) := 12;
    g_ch_market CONSTANT NUMBER(2) := 17;
    g_fr_market CONSTANT NUMBER(2) := 9;
    g_mx_market CONSTANT NUMBER(2) := 16;
    g_kw_market CONSTANT NUMBER(2) := 18;

    g_adt_hplan_active     CONSTANT pat_health_plan.flg_status%TYPE := 'A';
    g_inst_grp_flg_rel_adt CONSTANT institution_group.flg_relation%TYPE := 'ADT';

    g_adt_hplan_cancel    CONSTANT health_plan.flg_status%TYPE := 'C';
    g_adt_hpe_to_sch      CONSTANT health_plan_take_over.flg_status%TYPE := 'S';
    g_adt_hpe_to_finished CONSTANT health_plan_take_over.flg_status%TYPE := 'F';

    g_origin_schedule CONSTANT patient.flg_origin%TYPE := 'C';
    g_origin_adt      CONSTANT patient.flg_origin%TYPE := 'P';

    c_seq_offset CONSTANT NUMBER(10) := 10000000;

    c_flg_inail_ok         CONSTANT VARCHAR2(1 CHAR) := 'C';
    c_flg_inail_incomplete CONSTANT VARCHAR2(1 CHAR) := 'I';
    c_flg_no_inail         CONSTANT VARCHAR2(1 CHAR) := 'N';

    c_notified_exemption   CONSTANT VARCHAR2(1 CHAR) := 'N';
    c_active_exemption     CONSTANT VARCHAR2(1 CHAR) := 'A';
    c_pend_notif_exemption CONSTANT VARCHAR2(1 CHAR) := 'P';

    g_lscore_threshold PLS_INTEGER;

    --Patient status
    g_patient_active   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_patient_inactive CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_patient_deceased CONSTANT VARCHAR2(1 CHAR) := 'O';
    g_patient_canceled CONSTANT VARCHAR2(1 CHAR) := 'C';

    k_rank_entidade   CONSTANT NUMBER := 5;
    k_rank_municipio  CONSTANT NUMBER := 10;
    k_rank_localidade CONSTANT NUMBER := 15;

    k_inst_name              CONSTANT VARCHAR2(0100 CHAR) := 'INSTITUTION_NAME';
    k_clues_inst_name        CONSTANT VARCHAR2(0100 CHAR) := 'CLUES_INST_NAME';
    k_outside_number         CONSTANT VARCHAR2(0100 CHAR) := 'OUTSIDE_NUMBER';
    k_inside_number          CONSTANT VARCHAR2(0100 CHAR) := 'INSIDE_NUMBER';
    k_code_state             CONSTANT VARCHAR2(0100 CHAR) := 'CODE_STATE';
    k_code_municipality      CONSTANT VARCHAR2(0100 CHAR) := 'CODE_MUNICIPALITY';
    k_code_city              CONSTANT VARCHAR2(0100 CHAR) := 'CODE_CITY';
    k_postal_code            CONSTANT VARCHAR2(0100 CHAR) := 'POSTAL_CODE';
    k_phone                  CONSTANT VARCHAR2(0100 CHAR) := 'PHONE';
    k_residence              CONSTANT VARCHAR2(0100 CHAR) := 'RESIDENCE';
    k_urbanization           CONSTANT VARCHAR2(0100 CHAR) := 'URBANIZATION';
    k_id_tipology            CONSTANT VARCHAR2(0100 CHAR) := 'ID_TIPOLOGY';
    k_code_clues             CONSTANT VARCHAR2(0100 CHAR) := 'CODE_CLUES';
    k_jurisdiction_id        CONSTANT VARCHAR2(0100 CHAR) := 'JURISDICTION_ID';
    k_jurisdiction_name      CONSTANT VARCHAR2(0100 CHAR) := 'JURISDICTION_NAME';
    k_institution_short_code CONSTANT VARCHAR2(0100 CHAR) := 'INSTITUTION_SHORT_CODE';
    k_street_type            CONSTANT VARCHAR2(0100 CHAR) := 'STREET_TYPE';
    k_street                 CONSTANT VARCHAR2(0100 CHAR) := 'STREET';
    k_settlement             CONSTANT VARCHAR2(0100 CHAR) := 'SETTLEMENT';
    k_code_settlement        CONSTANT VARCHAR2(0100 CHAR) := 'CODE_SETTLEMENT';

    k_first_name       CONSTANT VARCHAR2(0100 CHAR) := pk_adt_api_out.k_first_name;
    k_first_name_lang  CONSTANT VARCHAR2(0100 CHAR) := pk_adt_api_out.k_first_name_lang;
    k_family_name      CONSTANT VARCHAR2(0100 CHAR) := pk_adt_api_out.k_family_name;
    k_family_name_lang CONSTANT VARCHAR2(0100 CHAR) := pk_adt_api_out.k_family_name_lang;

    -- CMF
    FUNCTION get_fam_relationship(i_id_patient IN NUMBER) RETURN NUMBER;
    FUNCTION get_fam_relationship_spec(i_id_patient IN NUMBER) RETURN VARCHAR2;
    FUNCTION get_id_pat_relative(i_id_patient IN NUMBER) RETURN NUMBER;
    FUNCTION get_info_contact_rel_full(i_pat_relative IN NUMBER) RETURN table_varchar;
    FUNCTION get_1st_cgiver_1st_name(i_id_patient IN NUMBER) RETURN VARCHAR2;
    FUNCTION get_1st_cgiver_otname1(i_id_patient IN NUMBER) RETURN VARCHAR2;
    FUNCTION get_1st_fam_name(i_id_patient IN NUMBER) RETURN VARCHAR2;
    FUNCTION get_1st_fam_otname3(i_id_patient IN NUMBER) RETURN VARCHAR2;
    FUNCTION get_1st_mphone_no(i_id_patient IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_country_dial_code(i_lang IN NUMBER) RETURN t_tbl_core_domain;
    FUNCTION get_family_rel(i_lang IN NUMBER) RETURN t_tbl_core_domain;
    FUNCTION get_country_dial_code_desc
    (
        i_lang  IN NUMBER,
        i_value IN NUMBER
    ) RETURN VARCHAR2;
    FUNCTION get_fam_rel_domain_desc
    (
        i_lang  IN NUMBER,
        i_value IN NUMBER
    ) RETURN VARCHAR2;

    -- ******************************************************
    FUNCTION save_caregiver_info
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_patient  IN NUMBER,
        i_id_fam_rel  IN NUMBER,
        i_fam_rel_spec IN VARCHAR2,
        i_firstname   IN VARCHAR2,
        i_lastname    IN VARCHAR2,
        i_othernames1 IN VARCHAR2,
        i_othernames3 IN VARCHAR2,
        i_phone_no    IN VARCHAR2,
        i_id_care_giver IN NUMBER
    ) RETURN BOOLEAN;
    -- end cmf

    -- ****************************************
    FUNCTION get_patient_type_arabic
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    --************************************
    FUNCTION get_trl_oci_arab(i_text IN VARCHAR2) RETURN VARCHAR2;

    --********************************************
    FUNCTION get_trl_arab_oci(i_text IN VARCHAR2) RETURN VARCHAR2;

    /********************************************************************************************
    * This function returns information if patient have SUS health plan (market BR)
    *
    * @param i_lang       ID LANGUAGE
    * @param i_prof       Proffisional
    * @param i_id_patient ID Patient
    *
    * @return                 Boolean indicating if has sus or no
    *
    *
    * @author                 Sofia Mendes
    * @version                2.7.4
    * @since                  2018-08-29
    **********************************************************************************************/
    FUNCTION check_sus_health_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_has_sus    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_legal_guardian
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN NUMBER
    ) RETURN VARCHAR2;
    FUNCTION get_patient_id_county
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN NUMBER
    ) RETURN pat_soc_attributes.id_country_nation%TYPE;
    
    FUNCTION get_admission_origin_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_patient_name_search
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

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
    
END pk_adt;
/
