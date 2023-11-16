/*-- Last Change Revision: $Rev: 2028532 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_bed IS

    /***************************************************************************************************************
    *
    * Creates a new record in Bed table and then proceeds to create a new bed allocation for the provided episode.
    *  
    * 
    * @param      i_lang             language ID
    * @param      i_prof             ALERT profissional 
    * @param      i_id_episode       ID_EPISODE that is having a bed allocation.
    * @param      i_id_room          ID_ROOM of the room where the new temporary bed is located. 
    * @param      i_desc_bed         Description of the temporary bed.
    * @param      i_notes            Notes regarding the new bed. 
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7
    * @since   14-10-2009
    *
    ****************************************************************************************************/
    FUNCTION create_tmp_bed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_room    IN room.id_room%TYPE,
        i_desc_bed   IN bed.desc_bed%TYPE,
        i_notes      IN bed.notes%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    *
    * Creates a new new bed allocation for the provided episode.
    *  
    * 
    * @param      i_lang             language ID
    * @param      i_prof             ALERT profissional 
    * @param      i_id_episode       ID_EPISODE that is having a bed allocation.
    * @param      i_id_bed           ID_BED to which the episode should be allocated. 
    * @param      o_bed_allocation   ID of the allocation.
    * @param      o_exception_info   Error message to be displayed to the user. 
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  RicardoNunoAlmeida
    * @version 2.5.0.7
    * @since   14-10-2009
    *
    ****************************************************************************************************/
    FUNCTION allocate_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_bed         IN bed.id_bed%TYPE,
        o_bed_allocation OUT VARCHAR2,
        o_exception_info OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_available_allocation
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        i_id    IN NUMBER,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    --JOSE SILVA: 06-03-2007 CABEÇALHO DA NOVA FUNÇÃO
    FUNCTION get_epis_bed_history
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_sql        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get_bed_desc                     Gets the bed description.
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_clinical_service     Clinical service ID
    * 
    * @return                          Transfer status string with icon
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           28-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_bed_desc
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /********************************************************************************************
    * get_bed_desc                     Gets the bed description.
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_clinical_service     Clinical service ID
    * 
    * @return                          descriptive
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.4
    * @since                           31-Oct-2011
    *
    **********************************************************************************************/
    FUNCTION get_bed_room_and_depart
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_bed        IN bed.id_bed%TYPE,
        o_id_room       OUT room.id_room%TYPE,
        o_id_department OUT department.id_department%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --
    --
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    --
    g_software_intern_name VARCHAR2(3);
    g_error                VARCHAR2(4000);
    g_ret                  BOOLEAN;

    g_cat_flg_available VARCHAR2(0050);
    g_cat_flg_prof      VARCHAR2(0050);

    g_epis_stat_inactive VARCHAR2(0050);

    g_episode_flg_status_active   VARCHAR2(0050);
    g_episode_flg_status_temp     VARCHAR2(0050);
    g_episode_flg_status_canceled VARCHAR2(0050);
    g_episode_flg_status_inactive VARCHAR2(0050);

    g_pat_allergy_cancel VARCHAR2(0050);
    g_pat_habit_cancel   VARCHAR2(0050);
    g_pat_problem_cancel VARCHAR2(0050);
    g_pat_notes_cancel   VARCHAR2(0050);
    g_pat_blood_active   VARCHAR2(0050);

    g_flg_available VARCHAR2(0050);

END;
/
