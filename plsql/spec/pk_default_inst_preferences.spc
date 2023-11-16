/*-- Last Change Revision: $Rev: 1471487 $*/
/*-- Last Change by: $Author: rui.gomes $*/
/*-- Date of last change: $Date: 2013-05-22 17:18:53 +0100 (qua, 22 mai 2013) $*/

CREATE OR REPLACE PACKAGE pk_default_inst_preferences IS

    /********************************************************************************************
    * Set Most frequent Default Parametrizations for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/03/01
    ********************************************************************************************/
    PROCEDURE set_default_param_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_job_name            IN VARCHAR2
    );
    /********************************************************************************************
    * Set Most frequent Default Parametrizations for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION set_inst_default_param_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Check if clinical service is content source or if need to get parent clinical_services ids
    *
    * @param i_lang                Language ID
    * @param i_clinical_service    Primary clinical service ID
    * @param i_id_software         Software ID
    * @param i_table_name          Table to process
    * @param o_id_cs               Cursor of final source clinical services
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.4
    * @since                       2011/10/20
    ********************************************************************************************/
    FUNCTION check_clinical_service
    (
        i_lang             IN language.id_language%TYPE,
        i_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_id_cs            OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Analysis for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_analysis            Most frequent Analysis Configuration
    * @param o_analysis_group      Most frequent Analysis Groups Configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION get_inst_analysis_freq
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_market             IN market.id_market%TYPE,
        i_version               IN VARCHAR2,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_software           IN software.id_software%TYPE,
        i_id_clinical_service   IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv      IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_analysis_config       OUT pk_types.cursor_type,
        o_analysis_group_config OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Analysis for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_adcs_config         Most frequent Analysis and Groups Configuration Id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION set_inst_analysis_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_adcs_config         OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Exams for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_exams               Most frequent Exams Configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION get_inst_exams_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_exams_config        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Exams for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_exams               Most frequent Exams Configuration id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION set_inst_exams_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_exams_config        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Exam Cat. for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_exams               Most frequent Exams configutation
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION get_inst_exam_cat_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_exam_cat            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Exam Cat. for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_exams               Most frequent Exams Default configutation records
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION set_inst_exam_cat_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_exam_cat_config     OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Interventions for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Deparment/Clinical Service ID
    * @param o_interv              Most frequent Interventions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION get_inst_interv_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_interv_config       OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * set Most frequent Interventions for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Deparment/Clinical Service ID
    * @param o_interv              Most frequent Interventions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION set_inst_interv_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_interv_config       OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Texts for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_text_config         Most frequent Texts configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION get_inst_sample_text_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_text_config         OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Texts for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_text_config         Most frequent Texts configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION set_inst_sample_text_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_text_config         OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Internal Medication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_int_med             Most frequent internal medication configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION get_inst_int_med_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_int_med_config      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Internal Medication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_int_med             Most frequent internal medication configured id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION set_inst_int_med_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_int_med_config      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Serum for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_serum_config       Most frequent serum configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION get_inst_serum_const_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_serum_config        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Serum for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_serum_config        Most frequent serum configured id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION set_inst_serum_const_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_serum_config        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent External Medication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_ext_med_config      Most frequent External medication configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION get_inst_ext_med_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_ext_med_config      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent External Medication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_ext_med_config      Most frequent External medication configurated id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION set_inst_ext_med_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_ext_med_config      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Body Diagrams Layouts for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_diaglay_config      Configuration cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMG
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION get_inst_diag_layout_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_diaglay_config      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Body Diagrams Layouts for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_diaglay_config      Configuration cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMG
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION set_inst_diag_layout_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_diaglay_config      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Most frequent ICNP Compo. for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_cipe                Most frequent ICNP Compo.
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION get_inst_icnp_comp_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_cipe_config         OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent ICNP Compo. for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_cipe                Most frequent ICNP Compo.
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION set_inst_icnp_comp_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_cipe_config         OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Most frequent Diagnosis for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    DepartmentClinical Service ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION set_inst_diagnosis_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Dietaries for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    DepartmentClinical Service ID
    * @param o_dietary             Most frequent Dietaries configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/16
    ********************************************************************************************/
    FUNCTION get_inst_dietary_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_dietary_config      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Dietaries for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    DepartmentClinical Service ID
    * @param o_dietary             Most frequent Dietaries configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/16
    ********************************************************************************************/
    FUNCTION set_inst_dietary_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_dietary_config      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent discharges for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_drd_config          Most frequent discharge reason
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/02/15
    ********************************************************************************************/
    FUNCTION get_inst_discharge_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_drd_config          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent discharges for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_drd_config          Most frequent discharge reason
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/02/15
    ********************************************************************************************/
    FUNCTION set_inst_discharge_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_drd_config          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent templates for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_id_institution      Institution ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_templates           Cursor of templates
    * @param o_profiles            Cursor of profiles
    * @param o_context             Cursor of contexts
    * @param o_flg_types           Cursor of templates flag types
    * @param o_id_sch_event        Cursor of scheduler events
    * @param o_context_2           Cursor of additional contexts
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION get_inst_templates_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_version             IN VARCHAR2,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_templates_config    OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent templates for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_id_institution      Institution ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_templates           Cursor of templates
    * @param o_profiles            Cursor of profiles
    * @param o_context             Cursor of contexts
    * @param o_flg_types           Cursor of templates flag types
    * @param o_id_sch_event        Cursor of scheduler events
    * @param o_context_2           Cursor of additional contexts
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION set_inst_templates_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_version             IN VARCHAR2,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_templates_config    OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent transfer option for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_transfer_option               Most frequent Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/07
    ********************************************************************************************/
    FUNCTION get_inst_transfer_option_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE,
        o_transfer_option     OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    *  Set Most frequent transfer option for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Default Clinical Service ID
    * @param i_id_dep_clin_serv    Alert Department/Clinical Service ID
    * @param o_sr_interv           Cursor with Default Configuration records
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2012/02/08
    ********************************************************************************************/
    FUNCTION set_inst_transfer_option_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_sr_interv           OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent sr_interv for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Default Clinical Service ID
    * @param i_id_dep_clin_serv    Alert Department/Clinical Service ID
    * @param o_sr_interv           Cursor with Default Configuration records
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2012/02/08
    ********************************************************************************************/
    FUNCTION get_inst_sr_interv_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_sr_interv           OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    *  Most frequent sr_interv for a specific Dep_clin_serv configuration
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Default Clinical Service ID
    * @param i_id_dep_clin_serv    Alert Department/Clinical Service ID
    * @param o_sr_interv           Cursor with Default Configuration records
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2012/02/08
    ********************************************************************************************/
    FUNCTION set_inst_sr_interv_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_sr_interv           OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Frequent Reported Medication for markets, versions and softwares
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Default id Clinical Service
    * @param i_id_dep_clin_serv    Destination id_dep_clin_Serv
    * @param o_internal_config     Cursor of internal medication records
    * @param o_external_config     Cursor of external medication records
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2012/02/08
    ********************************************************************************************/
    FUNCTION get_inst_pml_dcs_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_internal_config     OUT pk_types.cursor_type,
        o_external_config     OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Frequent Reported Medication for Dep_clin_serv in Institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Default id Clinical Service
    * @param i_id_dep_clin_serv    Destination id_dep_clin_Serv
    * @param o_results_pml         Cursor of configurations ids made
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2012/02/08
    ********************************************************************************************/
    FUNCTION set_inst_pml_dcs_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_results_pml         OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * GET_INST_ICNP_AXIS_CS by ICNP_COMPOSITION previously inserted
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_icnp_axis           outpup configuration
    * @param o_error               error identifier
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION get_inst_icnp_axis_cs
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_icnp_axis        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * SET_INST_ICNP_AXIS_CS by ICNP_COMPOSITION previously inserted
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.5.1.1 HF
    * @since                       2010/12/21
    ********************************************************************************************/
    FUNCTION set_inst_icnp_axis_cs
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_icnp_axis        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Body Structures for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_bsdcs_config        Most frequent Body Structures Configuration Details
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/05/22
    ********************************************************************************************/
    FUNCTION get_inst_body_structure_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_bsdcs_config        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Body Structures for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_bsdcs_config        Most frequent Body Structures Configuration Id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/05/22
    ********************************************************************************************/
    FUNCTION set_inst_body_structure_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_bsdcs_config        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Periodic Observations for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_pop_config          Most frequent Configurations
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/06/15
    ********************************************************************************************/
    FUNCTION get_periodic_obs_param_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_pop_config          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Periodic Observations for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_pop_config          Most frequent Configurations
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/15
    ********************************************************************************************/
    FUNCTION set_periodic_obs_param_freq
    (
        i_lang                    IN language.id_language%TYPE,
        i_market                  IN market.id_market%TYPE,
        i_version                 IN VARCHAR2,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_clinical_service     IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_inst_periodic_obs_param OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
      * Get Periodic observation param desc for a set of markets, versions and sotwares
      *
      * @param i_lang                Prefered language ID
      * @param i_market              Market ID's
      * @param i_version             ALERT version's
      * @param i_id_institution      Institution ID
      * @param i_id_software         Software ID
    * @param i_id_clinical_service  default clinical id
    * @param i_id_dep_clin_serv  alert dep_clin_serv id
      * @param o_cursor_config       Cursor of periodic observation param desc identifiers
      * @param o_error               Error
      *
      *
      * @return                      true or false on success or error
      *
      * @author                      RMGM
      * @version                     0.1
      * @since                       2012/08/29
      ********************************************************************************************/
    FUNCTION get_periodic_obs_desc_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_cursor_config       OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Periodic observations desc. for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_inst_periodic_obs_desc   Cursor of Instituition Periodic Observations Desc.
    * @param o_error                    Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION set_periodic_obs_desc_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_inst_pod            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Past History for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param o_cursor_config       Most frequent configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/18
    ********************************************************************************************/
    FUNCTION get_inst_past_history_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_cursor_config       OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Past History for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param o_inst_csad           Most frequent ids configured
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/18
    ********************************************************************************************/
    FUNCTION set_inst_past_history_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_inst_csad           OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Rehab types for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_cursor_config       Most frequent Configuration details
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/19
    ********************************************************************************************/
    FUNCTION get_inst_rehab_st_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_cursor_config       OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Rehab Types for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_bsdcs_config        Most frequent Configuration Id's generated
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/19
    ********************************************************************************************/
    FUNCTION set_inst_rehab_st_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_inst_rdcs           OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent VS Scales for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param o_cursor_config       Most frequent Configuration details
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/19
    ********************************************************************************************/
    FUNCTION get_inst_vssa_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_cursor_config       OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent VS Scales for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param o_inst_vssa           Most frequent Configuration details
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/19
    ********************************************************************************************/
    FUNCTION set_inst_vssa_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_inst_vssa           OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Most frequent Complication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param o_cursor_config       Most frequent configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/20
    ********************************************************************************************/
    FUNCTION get_inst_comp_config_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_cursor_config       OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Complication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param o_cursor_config       Most frequent configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/20
    ********************************************************************************************/
    FUNCTION set_inst_comp_config_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_market              IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_inst_cc             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Most frequent Default Parametrizations for a specific clinical_service using new engine
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_clinical_service Clinical Service ID    
    * @param i_commit_at_end       Commit automatic in transaction (Y, N)    
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION set_inst_param_freq_new
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_market              IN table_number,
        i_version             IN table_varchar,
        i_id_software         IN table_number,
        i_id_clinical_service IN table_number,
        i_id_dep_clin_serv    IN table_number,
        i_flg_dcs_all         IN VARCHAR2,
        i_commit_at_end       IN VARCHAR2,
        o_results             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get destination table Id Interv_Dep_clin_serv
    *
    * @param i_interv_cs             Alert_default Interv_clin_serv_id
    * @param i_institution           Institution ID
    * @param i_dcs                   Dep_clin_serv_id
    *
    * @return                        Id Interv_Dep_clin_serv
    *
    * @author                        RMGM
    * @version                       0.1
    * @since                         2013/05/14
    ********************************************************************************************/
    FUNCTION get_idcs_dest_id
    (
        i_interv_cs   IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_dcs         IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE;
    /********************************************************************************************
    * Set interv_dcs_most_freq_except configuration
    *
    * @param i_lang                  Language ID
    * @param i_institution           Institution ID
    * @param i_mkt                   Market Search List
    * @param i_vers                  Content Version Search List
    * @param i_software              Software Search List
    * @param i_clin_serv_in          Default Clinical Service Seach list
    * @param i_clin_serv_out         Configuration target (id_clinical_service)
    * @param i_dep_clin_serv_out     Configuration target (Dep_clin_serv_id)
    * @param o_result                Number of records inserted
    * @param o_error                 Error message    
    *
    * @return                        True or False
    *
    * @author                        RMGM
    * @version                       0.1
    * @since                         2013/05/14
    ********************************************************************************************/
    FUNCTION set_int_dcs_mf_except_all
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result            OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set Default Task Goal Task configuration Social Worker
    *
    * @param i_lang                Prefered language ID
    * @param i_institution         Institution ID
    * @param i_mkt                 Market ID list
    * @param i_vers                content version tag list
    * @param i_software            softwar ID list                
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/17
    ********************************************************************************************/
    FUNCTION set_intervplan_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result            OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    -- pk_constant vars
    g_error         VARCHAR2(2000);
    g_flg_available VARCHAR2(1);
    g_yes           VARCHAR2(1);
    g_active        VARCHAR2(1);
    g_version       VARCHAR2(30);
    g_func_name     VARCHAR2(500);
    g_table_name    VARCHAR2(500);

    g_array_size  NUMBER;
    g_array_size1 NUMBER;
    g_generic     NUMBER;

END pk_default_inst_preferences;
/
