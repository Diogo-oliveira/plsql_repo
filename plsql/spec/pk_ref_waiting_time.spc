/*-- Last Change Revision: $Rev: 2028919 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_waiting_time IS

    /**
    * Gets domains for waiting line
    *
    * @param   i_lang                     Language associated to the professional executing the request
    * @param   i_prof                     Professional, institution and software ids
    * @param   i_code_domain              Code domain to get values    
    * @param   i_id_inst_orig             Referral origin institution
    * @param   i_id_inst_dest             Referral dest institution    
    * @param   i_flg_default              Indicates if institution is default or not
    * @param   i_flg_type                 Referral type     
    * @param   i_flg_inside_ref_area      Flag indicating if is inside referral area or not
    * @param   i_flg_ref_line             Referral line 1,2,3
    * @param   i_flg_type_ins             Referral network to which it belongs
    * @param   i_id_speciality            Referral speciality
    * @param   i_id_dcs                   Referral clinical service. Also known as Sub-speciality
    * @param   i_external_sys             External system that created referral
    * @param   i_ref_type                 Type of specialities available for referring
    * @param   o_data                     Domains information
    * @param   o_error                    An error message, set when return=false
    *
    * @value   i_flg_default              {*} 'Y' - Default institution {*} 'N' - otherwise
    * @value   i_flg_type                 {*} 'C'- Consultation {*} 'A'- Analysis {*} 'I'- Image {*} 'E'- Exam
    *                                     {*} 'P'- Procedure {*} 'F'- Physiatrics
    * @value   i_flg_inside_ref_area      {*} 'Y' - inside ref area {*} 'N' - otherwise
    * @value   i_ref_type                 {*} 'E' - External specialities {*} 'I' - Internal specialities 
    *                                     {*} 'P' - at Hospital Entrance specialities {*} 'A' - all types of specialities
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 2.6
    * @since   07-10-2010
    */
    FUNCTION get_domains
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_code_domain         IN sys_domain.code_domain%TYPE,
        i_id_inst_orig        IN p1_dest_institution.id_inst_orig%TYPE DEFAULT NULL,
        i_id_inst_dest        IN p1_dest_institution.id_inst_dest%TYPE DEFAULT NULL,
        i_flg_default         IN p1_dest_institution.flg_default%TYPE DEFAULT NULL,
        i_flg_type            IN p1_dest_institution.flg_type%TYPE DEFAULT NULL,
        i_flg_inside_ref_area IN ref_dest_institution_spec.flg_inside_ref_area%TYPE DEFAULT NULL,
        i_flg_ref_line        IN ref_dest_institution_spec.flg_ref_line%TYPE DEFAULT NULL,
        i_flg_type_ins        IN p1_dest_institution.flg_type_ins%TYPE DEFAULT NULL,
        i_id_speciality       IN p1_speciality.id_speciality%TYPE DEFAULT NULL,
        i_id_dcs              IN p1_spec_dep_clin_serv.id_spec_dep_clin_serv%TYPE DEFAULT NULL,
        i_external_sys        IN external_sys.id_external_sys%TYPE,
        i_ref_type            IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        o_data                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get waiting time for institution and speciality
    *
    * @param   i_lang                  Language identifier
    * @param   i_prof                  Professional, institution and software ids     
    * @param   i_ref_adw_column        Adw column name
    * @param   i_id_institution        Referral dest institution
    * @param   i_id_speciality         Referral speciality
    *
    * @RETURN  wating time
    *
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   2011-01-03
    */
    FUNCTION get_waiting_time
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_adw_column IN sys_config.desc_sys_config%TYPE,
        i_id_institution IN p1_external_request.id_inst_dest%TYPE,
        i_id_speciality  IN p1_external_request.id_speciality%TYPE
    ) RETURN NUMBER;

END pk_ref_waiting_time;
/
