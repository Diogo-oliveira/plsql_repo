CREATE OR REPLACE PACKAGE pk_complaint_ux IS

    -- Author  : ELISABETE.BUGALHO
    -- Created : 27/08/2020 09:39:04
    -- Purpose : Complaints

    -- Public type declarations
    /* Stores the package name. */
    g_package_name VARCHAR2(32);

    /********************************************************************************************
    * get_reported_by values
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param o_list                cursor values out
    * @param o_error               Error message
    *
    * @return boolean              true or false on success or error
    *
    * @author                      Paulo Teixeira
    * @since                       14/7/2016
    * @version                     2.6.5
    **********************************************************************************************/
    FUNCTION get_reported_by
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Registers an episode set of complaints.
    * It is allowed to register complaints only in active episodes.
    * When a new complaint is registered, any previous complaint and related documentation becomes inactive.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_prof_cat_type           professional category
    * @param i_epis                    the episode id
    * @param i_complaint               the array of complaint ids
    * @param i_patient_complaint       the array of patient complaints
    * @param i_flg_type                array of types of edition
    * @param i_id_epis_complaint_root  array of ids for the complaint parents
    * @param o_error                   Error message
    *
    * @value i_flg_type                {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    *
    * @return                          true (sucess), false (error)
    **********************************************************************************************/
    FUNCTION set_epis_complaints
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_prof_cat_type            IN category.flg_type%TYPE,
        i_episode                  IN episode.id_episode%TYPE,
        i_complaint                IN table_number,
         i_complaint_alias                IN table_number,
        i_patient_complaint        IN epis_complaint.patient_complaint%TYPE,
        i_patient_complaint_arabic IN epis_complaint.patient_complaint_arabic%TYPE,
        i_flg_reported_by          IN epis_complaint.flg_reported_by%TYPE,
        i_flg_type                 IN VARCHAR2,
        i_id_epis_complaint_root   IN epis_complaint.id_epis_complaint_root%TYPE,
        o_id_epis_complaint        OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    
    FUNCTION get_previous_complaints
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;    

    FUNCTION get_epis_complaint
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_episode                  IN episode.id_episode%TYPE,
        i_id_epis_complaint        IN epis_complaint.id_epis_complaint%TYPE,
        o_complaint_list           OUT pk_types.cursor_type,
        o_patient_complaint        OUT epis_complaint.patient_complaint%TYPE,
        o_patient_complaint_arabic OUT epis_complaint.patient_complaint_arabic%TYPE,
        o_flg_reported_by          OUT epis_complaint.flg_reported_by%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    
        
END pk_complaint_ux;
/
