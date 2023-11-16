/*-- Last Change Revision: $Rev: 2028887 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_prof_utils IS

    --**************************************
    TYPE t_prof_info IS RECORD(
        id_language   NUMBER(24),
        desc_language VARCHAR2(1000 CHAR),
        timeout       NUMBER(24),
        first_screen  VARCHAR2(0200 CHAR),
        profphoto     VARCHAR2(1000 CHAR),
        name          VARCHAR2(1000 CHAR),
        nick_name     VARCHAR2(1000 CHAR));

    FUNCTION get_prof_info(i_prof IN profissional) RETURN t_prof_info;

    /*******************************************************************************************************************************************
    * Returns an array of names corresponding to the given array of professional IDs
    *                                                                                                                                          *    
    * @param I_LANG                   language identifier                                                                                      *
    * @param I_ID_PROF                array of professional IDs                                                                                *
    *                                                                                                                                          *
    * @return                         Array of Professional Names                                                                            *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Luís Ramos                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2009/04/28                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_names
    (
        i_lang      IN language.id_language%TYPE,
        i_prof_id   IN table_number,
        o_prof_name OUT table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    *GET_MAIN_PROF Returns the professional nick name responsible for the episode                                                              *
    *                                                                                                                                          *
    * @param I_LANG                   language identifier                                                                                      *
    * @param I_EPISODE                episode identifier                                                                                       *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Nick name of the professional                                                                            *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/08/28                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_main_prof
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    /**
    * Get the professional nickname
    *
    * @param i_lang        language
    * @param i_prof_id     professional id
    *
    * @return the professional nickname 
    * @created 17-Apr-2008
    * @author Sérgio Santos
    */
    FUNCTION get_nickname
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE -- input professional id
    ) RETURN VARCHAR2;

    /*
    * Return the name's professional
    *
    * @param   i_lang             language
    * @param   i_prof_id          professional id
    *
    * @author  Nuno Ferreira
    * @version 2.4.3
    * @since   2008/08/21
    */
    FUNCTION get_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get category of active professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids                
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  category of active professional
    * @author  José Silva
    * @version 1.0
    * @since   22/04/2008
    *
    */
    FUNCTION get_category
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get category of active professional
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_prof_id                   Professional who made the record
    * @param i_prof_inst                 Institution where professional made the record
    *
    * @RETURN  category of active professional
    * @author  Jorge Silva
    * @version 1.0
    * @since   13/02/2014
    *
    **********************************************************************************************/
    FUNCTION get_category
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_id   IN professional.id_professional%TYPE,
        i_prof_inst IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get id_category of active professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids                
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  category of active professional
    * @author  José Silva
    * @version 1.0
    * @since   22/04/2008
    *
    */
    FUNCTION get_id_category
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER;

    /********************************************************************************************
    * Get category description of given professional
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_prof_id                   Professional who made the record
    * @param i_prof_inst                 Institution where professional made the record
    * @return                            Category description
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.3
    * @since   24-Nov-09
    **********************************************************************************************/
    FUNCTION get_desc_category
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_id   IN professional.id_professional%TYPE,
        i_prof_inst IN institution.id_institution%TYPE
        
    ) RETURN VARCHAR2;
    --
    /*
    * Get the selected dep_clin_serv of a given professional
    *
    * @param   I_PROF                     professional, institution and software ids                
    *
    * @RETURN  professional dep_clin_serv (ID)
    * @author  José Silva
    * @version 1.0
    * @since   18/05/2008
    *
    */
    FUNCTION get_prof_dcs(i_prof IN profissional) RETURN NUMBER;

    /**********************************************************************************************
    * GET_PROF_MARKET                 Returns professional market
    *
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         professional market identifier
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.5 
    * @since                          12-Feb-2011
    **********************************************************************************************/
    FUNCTION get_prof_market(i_prof IN profissional) RETURN NUMBER;

    --
    /*
    * Get the active speciality of a given professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids                
    *
    * @RETURN  professional speciality (description)
    * @author  José Silva
    * @version 1.0
    * @since   18/05/2008
    *
    */
    FUNCTION get_prof_speciality
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;
    --
    /*
    * Get the active speciality of a given professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids                
    *
    * @RETURN  professional speciality id
    * @author  Alexandre Santos
    * @version v2.6
    * @since   09/12/2009
    *
    */
    FUNCTION get_prof_speciality_id
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN speciality.id_speciality%TYPE;

    /********************************************************************************************
    * Gets the id_content of the speciality of a given professional
    *
    * @param   i_lang             language
    * @param   i_prof             professional, institution and software ids
    *
    * @author  Cristina Oliveira
    * @version 2.8
    * @since   2020/11/19
    **********************************************************************************************/
    FUNCTION get_prof_speciality_content
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    --
    /********************************************************************************************
    * Returns the professional name to place in the documentation records
    *
    * @param   i_lang             language
    * @param   i_prof             professional, institution and software ids
    *
    * @author  José Silva
    * @version 2.5
    * @since   2009/02/26
    **********************************************************************************************/
    FUNCTION get_name_signature
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the speciality of a given professional within a certain date
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids  
    * @param   I_PROF_ID                  professional who made the record
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional speciality (description)
    * @author  José Silva
    * @version 1.0
    * @since   26/02/2009
    **********************************************************************************************/
    FUNCTION get_spec_signature
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        i_dt_reg  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the speciality of a given professional (to be used in P1)
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids  
    * @param   I_PROF_ID                  professional who made the record
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional speciality (description)
    * @author  José Silva
    * @version 1.0
    * @since   18/03/2009
    **********************************************************************************************/
    FUNCTION get_spec_signature
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_id   IN professional.id_professional%TYPE,
        i_prof_inst IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the speciality of a given professional within a certain date associated to a given visit
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids  
    * @param   I_PROF_ID                  professional who made the record
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional speciality (description)
    * @author  Sofia Mendes
    * @version 2.6.0.1
    * @since   30/04/2010
    **********************************************************************************************/
    FUNCTION get_spec_sign_by_visit
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_id  IN professional.id_professional%TYPE,
        i_dt_reg   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_visit IN visit.id_visit%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Return professional's PROFILE_TEMPLATE within institution and software
    *
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         ID_PROFILE_TEMPLATE from PROFILE_TEMPLATE table
    *                        
    * @author                         Sérgio Santos
    * @version                        1.0 
    * @since                          2009/06/18
    **********************************************************************************************/
    FUNCTION get_prof_profile_template(i_prof IN profissional) RETURN profile_template.id_profile_template%TYPE;

    /********************************************************************************************
    * Returns an array with all softwares that are being used by the professional
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_institution             current institution ID
    *
    *
    * @author                          José Silva
    * @version                         2.5.1.9
    * @since                           2011/11/10
    **********************************************************************************************/
    FUNCTION get_prof_softwares
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE
    ) RETURN table_number;

    /**********************************************************************************************
    * Retorna o numero da ordem do profissional
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_id                profissional para o qual pretendemos que seja retornado o numero da ordem                
    * @param o_num_order              numero da ordem do profissional pretendido
    * @param o_error                  Error message
    *
    * @author                         Rui Duarte
    * @version                        1.0 
    * @since                          2009/11/06
    **********************************************************************************************/

    FUNCTION get_num_order
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_id   IN professional.id_professional%TYPE,
        o_num_order OUT professional.num_order%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets the professional profile_template
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_new_pt             New profile_template
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.7.2
    * @since                 2009/07/31
    */
    FUNCTION set_prof_profile_template_nc
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_new_pt IN profile_template.id_profile_template%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Retorna se um determinado profissional não é um profissional externo ou *
    * de teste da aplicação.                                                  *
    *                                                                         *
    * @param i_lang                the id language                            *
    * @param i_prof                professional, software and institution ids *
    * @param i_prof_id             profissional que queremos validar          *      
    * @param i_institution_id      instituição sujeita a validação            *
    *                                                                         *
    * @author                      Gustavo Serrano                            *
    * @version                     1.0                                        *
    * @since                       2009/12/16                                 *
    **************************************************************************/
    FUNCTION is_internal_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_id        IN professional.id_professional%TYPE,
        i_institution_id IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;
    --
    /*
    * Get the clinical service of a given professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids                
    *
    * @RETURN  professional clinical service id
    * @author  Alexandre Santos
    * @version v2.6
    * @since   19/02/2009
    *
    */
    FUNCTION get_prof_clin_serv_id
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN clinical_service.id_clinical_service%TYPE;
    --
    /*
    * Gets the clinical services list to which the current professional is allocated
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     Professional ID
    *
    * @RETURN  Return the clinical services list to which the current professional is allocated
    * @author  Alexandre Santos
    * @version 1.0
    * @since   02-03-2010
    *
    */
    FUNCTION tf_prof_clin_serv_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_table_prof_clin_serv;

    /**********************************************************************************************
    * Get PROFESSIONAL DEA info
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_id                profissional para o qual pretendemos que seja retornado o numero da ordem                
    * @param o_dea                  DEA info
    * @param o_error                  Error message
    *
    * @author                         Pedro Albuquerque
    * @version                        1.0 
    * @since                          2010/05/06
    **********************************************************************************************/

    FUNCTION get_dea
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        o_dea     OUT professional.dea%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get PROFESSIONAL UPIN info
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_id                profissional para o qual pretendemos que seja retornado o numero da ordem                
    * @param o_upin                 UPIN info
    * @param o_error                  Error message
    *
    * @author                         Pedro Albuquerque
    * @version                        1.0 
    * @since                          2010/05/06
    **********************************************************************************************/

    FUNCTION get_upin
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        o_upin    OUT professional.upin%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get clinical flag for current professional
    *
    * @param   i_lang                  language associated to the professional executing the request
    * @param   i_prof                  professional, institution and software ids  
    *
    * @return                          clinical flag: (Y) clinical category (N) non-clinical category
    *
    * @author                          Carlos Loureiro
    * @since                           11/11/2010
    **********************************************************************************************/
    FUNCTION get_clinical_cat
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the professional signature.
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param O_PROF_SIGNATURE        Professional signature    
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Sofia Mendes
    * @since                         15-Feb-2011
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_name_signature
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_prof_signature OUT professional.name%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get_detail_signature      get the signature with specific format:
    *                           professional name (speciality) dd/mm/aaaa hh:mmh 
    *
    * @param i_lang                    Language associated to the professional executing the request
    * @param i_prof                    Professional, software and institution ids
    * @param i_id_episode              Episode ID
    * @param i_date_last_change        Last date changed
    * @param i_id_prof_last_change     Last prof ID changed
    *
    * Return signature format with detail conventions
    *
    * @author                          Filipe Silva
    * @version                         2.6.1.1
    * @since                           06-Jun-2011
    *
    **********************************************************************************************/
    FUNCTION get_detail_signature
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_date_last_change    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_change IN professional.id_professional%TYPE,
        i_show_contact_info   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * check_has_functionality        return if the professional has a determinate functionality (Y) or not (N)
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_intern_name             Internal name of sys functionality
    *
    * Return if the professional has a functionality (Y) or not (N)
    *
    * @author                          Filipe Silva
    * @version                         2.6.1.1
    * @since                           02-Jun-2011
    *
    **********************************************************************************************/
    FUNCTION check_has_functionality
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_intern_name IN sys_functionality.intern_name_func%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns an array with all professsional from the same dep_clin_serv of the current professional
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    *
    *
    * @author                          Elisabete Bugalho
    * @version                         2.6.1.2
    * @since                           2011/10/10
    *
    **********************************************************************************************/
    FUNCTION get_prof_dcs_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number;

    /********************************************************************************************
    * Gets the name (speciality) of a given professional
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional speciality (description)
    * @author  Pedro Santos
    * @version 1.0
    * @since   05/01/2012
    **********************************************************************************************/
    FUNCTION get_prof_name_spec
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof_last_change IN professional.id_professional%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_date                IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the episode type description
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional speciality (description)
    * @author  Pedro Santos
    * @version 1.0
    * @since   05/01/2012
    **********************************************************************************************/
    FUNCTION get_epis_type_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the selected dep_clin_serv of a given professional (ID) on a given time
    *
    * @param   I_LANG  language ID
    * @param   I_PROF professional, institution and software ids
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID
    *
    * @RETURN  professional id_dep_clin_serv
    *
    **********************************************************************************************/
    FUNCTION get_reg_prof_id_dcs
    (
        i_prof_id IN professional.id_professional%TYPE,
        i_dt_reg  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN dep_clin_serv.id_dep_clin_serv%TYPE;

    ----

    /********************************************************************************************
    * Returns a table_number with all clinical services associated to a professional
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    *
    *
    * @author                          Sergio Dias
    * @version                         2.6.2.1.4
    * @since                           3-Jul-2012
    **********************************************************************************************/
    FUNCTION get_list_prof_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN table_number;
    /********************************************************************************************
    * Get Professional CAB CONV (FR Market)
    *
    * @param i_lang                Preferred language ID
    * @param i_prof                Professional Data Type
    * @param o_prof_title          Professional title 
    * @param o_prof_adress         Professional adress        
    * @param o_prof_state          Professional state (district) 
    * @param o_prof_city           Professional City
    * @param o_prof_zip            Professional Zip Code 
    * @param o_prof_country        Professional Country 
    * @param o_prof_phone_off      Professional Office Phone 
    * @param o_prof_phone_home     Professional Home Phone                            
    * @param o_prof_cellphone      Professional cellphone 
    * @param o_prof_fax            Professional fax  
    * @param o_prof_mail           Professional mail        
    *
    * @return                      True or False
    * 
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/09/24
    ********************************************************************************************/
    FUNCTION get_prof_presc_details
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_prof_title         OUT sys_domain.val%TYPE,
        o_prof_adress        OUT professional.address%TYPE,
        o_prof_state         OUT professional.district%TYPE,
        o_prof_city          OUT professional.city%TYPE,
        o_prof_zip           OUT professional.zip_code%TYPE,
        o_prof_country       OUT pk_translation.t_desc_translation,
        o_prof_phone_off     OUT professional.work_phone%TYPE,
        o_prof_phone_home    OUT professional.num_contact%TYPE,
        o_prof_cellphone     OUT professional.cell_phone%TYPE,
        o_prof_fax           OUT professional.fax%TYPE,
        o_prof_mail          OUT professional.email%TYPE,
        o_prof_tin           OUT professional.taxpayer_number%TYPE,
        o_prof_clinical_name OUT professional.clinical_name%TYPE,
        o_agrupacion_instit  OUT VARCHAR2,
        o_agrupacion_abbr    OUT VARCHAR2,
        o_scholarship        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get username and language of given professional
    *
    * @param i_lang                   application id_language   ( for logging )
    * @param i_prof                   Professional
    * @param o_user_name              username of professional
    * @param o_id_prf_lang            language id of professional
    * @param o_error                  error process
    *
    * @return                         true or false
    *
    * @author                         CMF
    * @version                        2.6.3
    * @since                          2012/11/22
    **********************************************************************************************/
    FUNCTION get_prf_login_n_lang
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        o_user_name   OUT VARCHAR2,
        o_id_prf_lang OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_username(i_prof_id IN NUMBER) RETURN VARCHAR2;
    /********************************************************************************************
    * Get detailed prof dep_clin_serv information
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Professional Array   
    * @param i_id_prof                Id professional to search
    * @param o_list                   Cursor with colected information details
    * @param o_error                  error process
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3.1
    * @since                          2012/11/06
    **********************************************************************************************/
    FUNCTION get_prof_dcs_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /* Method that return professional work phone */
    FUNCTION get_work_phone
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the professional identifier for a given username.
    *
    * @param i_username               Username
    * @param o_id_professional        Professional identifier
    * @param o_error                  Error message
    
    * @return                         true or false on success or error
    *
    * @author                         Joao Sa
    * @since                          2014/03/19
    **********************************************************************************************/
    FUNCTION get_prof_id_by_username
    (
        i_username        IN VARCHAR2,
        o_id_professional OUT ab_user_info.id_ab_user_info%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Get PROFESSIONAL Bleep number
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_id                profissional para o qual pretendemos que seja retornado o numero da ordem
    *
    * @author                         RMGM
    * @version                        2.6.4.0 
    * @since                          2014/06/13
    **********************************************************************************************/

    FUNCTION get_bleep_num
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Returns the Professional facility IDentifier (Mecanografic number)
    *
    * @param      i_lang                     Language identification
    * @param      i_prof                     Professional identification Array
    * @param      o_mec_num                  Identifier output
    * @param      o_error                    Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Rui Gomes
    * @version                         2.6.4.1
    * @since                           2014/07/08
    **********************************************************************************************/
    FUNCTION get_prof_inst_mec_num
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_active IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the permission for profissional for that sys_config defined by professional category.
    *
    * @param      i_lang                     Language identification
    * @param      i_id_sys_config            SYS_CONFIG to evaluate
    * @param      i_prof                     Professional identification Array    
    * @param      o_have_permission                  Y/N returned if got permision
    * @param      o_error                    Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Rui Gomes
    * @version                         2.6.4.1
    * @since                           2014/07/08
    **********************************************************************************************/
    FUNCTION get_sys_config_cat
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_config   IN sys_config.id_sys_config%TYPE,
        o_have_permission OUT sys_config.value%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_blob(i_prof IN profissional) RETURN VARCHAR2;
    /********************************************************************************************
    * Get contact fields for professional in institution
    *
    * @param i_lang            Application Language
    * @param i_id_prof         Professional identifier
    * @param i_id_institution  Institution identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    * @param o_work_phone      Work phone Number value
    * @param o_home_phone      Home phone Number value
    * @param o_cell_phone      Celular phone Number value
    * @param o_fax             Fax Number value
    * @param o_email           Email adress value
    * @param o_bleep           Bleep number value
    * @param o_contact_det     other contact details info
    * @param o_error           Error object    
    *            
    * @Return                  True or False
    *
    * @author                   RMGM
    * @version                  2.6.4
    * @since                    2015/03/05
    ********************************************************************************************/
    FUNCTION get_prof_contacts
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN prof_institution.id_institution%TYPE,
        i_req_date       IN professional_hist.dt_operation%TYPE DEFAULT NULL,
        o_work_phone     OUT professional.work_phone%TYPE,
        o_home_phone     OUT professional.num_contact%TYPE,
        o_cell_phone     OUT professional.cell_phone%TYPE,
        o_fax            OUT professional.fax%TYPE,
        o_email          OUT professional.email%TYPE,
        o_bleep          OUT professional.bleep_number%TYPE,
        o_contact_det    OUT prof_institution.contact_detail%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set contact fields for professional in institution
    *
    * @param i_lang            Application Language
    * @param i_id_prof         Professional identifier
    * @param i_id_institution  Institution identifier
    * @param i_work_phone      Work phone Number value
    * @param i_home_phone      Home phone Number value
    * @param i_cell_phone      Celular phone Number value
    * @param i_fax             Fax Number value
    * @param i_email           Email adress value
    * @param i_bleep           Bleep number value
    * @param i_contact_det     other contact details info
    * @param o_error           Error object    
    *            
    * @Return                  True or False
    *
    * @author                   RMGM
    * @version                  2.6.4
    * @since                    2015/03/05
    ********************************************************************************************/
    FUNCTION set_prof_contacts
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN prof_institution.id_institution%TYPE,
        i_work_phone     IN professional.work_phone%TYPE,
        i_home_phone     IN professional.num_contact%TYPE,
        i_cell_phone     IN professional.cell_phone%TYPE,
        i_fax            IN professional.fax%TYPE,
        i_email          IN professional.email%TYPE,
        i_bleep          IN professional.bleep_number%TYPE,
        i_contact_det    IN prof_institution.contact_detail%TYPE,
        i_commit_trs     IN BOOLEAN DEFAULT TRUE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if bleep number is valid according to institution configuration
    *
    * @param i_lang                   Application language
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_task_type              Task type id
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_show_bleep_popup       'Y' or 'N'
    * @param o_error                  Error object 
    * @return                         True or False
    *
    * @author                         Nuno Alves
    * @version                        2.6.4
    * @since                          2015/03/04
    ********************************************************************************************/
    FUNCTION get_show_bleep_popup
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_tbl_id_task_type       IN table_number,
        i_cosign_def_action_type IN action.internal_name%TYPE,
        i_action                 IN action.id_action%TYPE,
        o_show_bleep_popup       OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get work phone contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.work_phone
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/10
    ********************************************************************************************/
    FUNCTION get_prof_work_phone_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.work_phone%TYPE;

    /********************************************************************************************
    * Get home  phone contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.num_contact
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/10
    ********************************************************************************************/

    FUNCTION get_prof_home_phone_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.num_contact%TYPE;

    /********************************************************************************************
    * Get bleep number contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.bleep_number
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/10
    ********************************************************************************************/

    FUNCTION get_prof_bleep_number_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.bleep_number%TYPE;

    /********************************************************************************************
    * Get cell number contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.bleep_number
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/14
    ********************************************************************************************/

    FUNCTION get_prof_cell_number_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.bleep_number%TYPE;

    /*********************************************************************************************
    * Get professional department ids
    *
    * @param i_lang             The ID of the user language
    * @param i_prof             Current professional
    *
    * @author                   rui.mendonca
    * @version                  2.6.5.2
    * @since                    2016/06/06
    **********************************************************************************************/
    FUNCTION get_prof_dept_ids
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number;
    
    /*********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_inst_dept_ids
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_department_flg_type IN department.flg_type%TYPE
    ) RETURN table_number;

    /*********************************************************************************************
    * Preferencial service ( department ) of professional
    *
    * @param i_lang             The ID of the user language
    * @param i_prof             Current professional
    *
    * @author                   rui.mendonca
    * @version                  2.6.5.2
    * @since                    2016/06/06
    **********************************************************************************************/
    FUNCTION get_preferencial_department
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION get_arabic_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    -- 
    FUNCTION get_profile_info(i_prof IN profissional) RETURN profile_template%ROWTYPE;

    ----
    /**********************************************************************************************
    * Retorna o numero da ordem do profissional
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_id                profissional para o qual pretendemos que seja retornado o numero da ordem                
    * @param o_num_order              numero da ordem do profissional pretendido
    * @param o_error                  Error message
    *
    * @author                         Rui Duarte
    * @version                        1.0 
    * @since                          2009/11/06
    **********************************************************************************************/

    FUNCTION get_prof_num_order
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION get_flg_mrp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_prof_sub_category
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION get_prof_default_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_software         IN software.id_software%TYPE,
        o_id_dep_clin_serv OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_department       OUT department.id_department%TYPE,
        o_clinical_service OUT clinical_service.id_clinical_service%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the Professional order number
    *
    * @param      i_lang                     Language identification
    * @param      i_prof                     Professional identification Array
    * @param      o_error                    Error
    *
    * @return                                Professional preferential rool
    *
    * @author                          Ana Moita
    * @version                         2.8.0
    * @since                           2019/05/16
    */
    FUNCTION get_prof_pref_room
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER;

    FUNCTION check_has_functionality
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_intern_name IN sys_functionality.intern_name_func%TYPE,
        o_flag        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Returns the Professionals associate to a sys functionality
    *
    * @param      i_lang                     Language identification
    * @param      i_prof                     Professional identification Array
    * @param      i_intern_name_func         Sys functionality internal name
    *
    * @return                                table number of id professinals
    *
    * @author                          Ana Moita
    * @version                         2.8.0
    * @since                           2019/12/10
    */
    FUNCTION get_prof_by_functionality
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_intern_name_func IN sys_functionality.intern_name_func%TYPE
    ) RETURN table_number;

    /**
    * Get profissional all functionalities from all softwares
    *
    * @param      I_LANG                               Language identification
    * @param      I_PROF                               professional, software and institution ids
    *
    * @return     table_varchar
    * @author     Anna Kurowska
    * @version    2.8
    * @since      2019/12/19
    */
    FUNCTION get_prof_func_all
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_varchar;

    -- concatenates profile_templates of all professionals from same schedules
    -- Used in alerts  
    FUNCTION get_sch_profiles
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_schedule IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_prof_data
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    ----
    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found        BOOLEAN;
    g_exception EXCEPTION;

    g_yes VARCHAR2(1 CHAR);
    g_no  VARCHAR2(1 CHAR);

    g_dcs_selected      CONSTANT prof_dep_clin_serv.flg_status%TYPE := 'S';
    g_dcs_default       CONSTANT prof_dep_clin_serv.flg_default%TYPE := 'Y';
    g_catg_surg_resp    CONSTANT category_sub.id_category%TYPE := 1;
    g_cancel            CONSTANT VARCHAR2(1) := 'C';
    g_oris              CONSTANT NUMBER(2) := 4;
    g_open_parenthesis  CONSTANT VARCHAR2(2 CHAR) := ' (';
    g_close_parenthesis CONSTANT VARCHAR2(2 CHAR) := ') ';
    g_chr_space         CONSTANT VARCHAR2(1 CHAR) := ' ';
    g_chr_colon         CONSTANT VARCHAR2(2 CHAR) := ':';
    g_chr_semi_colon    CONSTANT VARCHAR2(2 CHAR) := ';';

    g_flg_profile_template_student CONSTANT VARCHAR2(1 CHAR) := 'T'; -- profile template Student 

    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';
    g_package_name VARCHAR2(32);
END pk_prof_utils;
/
