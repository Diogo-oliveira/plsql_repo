/*-- Last Change Revision: $Rev: 2028900 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:38 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_recommendation AS

    SUBTYPE obj_name IS VARCHAR2(30 CHAR);

    /********************************************************************************************
    * Inserts a new patient recommendation
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional id
    * @param i_id_patient            Patient id
    * @param i_id_episode            Episode id
    * @param i_id_recommendation     Recommendation id array
    * @param i_id_cdr_instance       CDR instance id
    * @param o_id_pat_rec            Patient Recommendations
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos
    * @version                       2.6.1.0.1
    * @since                         2011/05/04
    ********************************************************************************************/
    FUNCTION set_pat_recommendation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN alert_adtcod.patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_recommendation IN table_number,
        i_id_cdr_instance   IN cdr_instance.id_cdr_instance%TYPE,
        o_id_pat_rec        OUT table_number,
        o_error             OUT t_error_out
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets patient recommendations
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional id
    * @param i_id_patient            Patient id
    * @param o_list                  Recommendations cursor
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos
    * @version                       2.6.1.0.1
    * @since                         2011/05/04
    ********************************************************************************************/
    FUNCTION get_pat_recommendation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN alert_adtcod.patient.id_patient%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets patient recommendations conditions
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional id
    * @param i_id_patient            Patient id
    * @param o_conditions            Recommendations conditions
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos
    * @version                       2.6.1.0.1
    * @since                         2011/05/04
    ********************************************************************************************/
    FUNCTION get_pat_recommendation_cond
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN alert_adtcod.patient.id_patient%TYPE,
        i_recommendation IN recommendation.id_recommendation%TYPE,
        o_conditions     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets patient recommendations
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional id
    * @param i_id_patient            Patient id
    * @param i_id_episode            Episode id
    * @param i_id_recommendation     Recommendation id
    * @param o_list                  Recommendations cursor
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos
    * @version                       2.6.1.0.1
    * @since                         2011/05/04
    ********************************************************************************************/
    FUNCTION set_pat_recommendation_read
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN alert_adtcod.patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_recommendation IN recommendation.id_recommendation%TYPE,
        i_flg_read          IN pat_recommendation_det.flg_read%TYPE,
        o_icon_name         OUT sys_domain.img_name%TYPE,
        o_dt_read           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*************************************************************************\
    *  Global package constants                                               *
    \*************************************************************************/
    g_package_owner CONSTANT obj_name := 'ALERT';
    g_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();
    g_error VARCHAR2(1000 CHAR);
END pk_recommendation;
/
