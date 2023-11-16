/*-- Last Change Revision: $Rev: 1892985 $*/
/*-- Last Change by: $Author: vitor.sa $*/
/*-- Date of last change: $Date: 2019-02-14 14:41:01 +0000 (qui, 14 fev 2019) $*/

CREATE OR REPLACE PACKAGE pk_atv_api_ui AS

    ---------------------------------- Auxiliar Functions ------------------------------

    /********************************************************************************************
    * Function for translate a code
    *
    * @param i_lang          Language ID    
    * @param i_code_translation Input code translation
    * @param i_trans_type    Input translation type: T-Title; D-Description
    * @param i_id_tv_media   Input TV Media ID  
    * @param i_flg_type      Input media flag type: A-Alert; I-Institutional
    *
    * @return                Translation
    *   
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_translation
    (
        i_lang             IN NUMBER,
        i_code_translation IN VARCHAR2,
        i_trans_type       IN VARCHAR2,
        i_id_tv_media      IN NUMBER,
        i_flg_type         IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function for return BLOB for JAVA servlet
    *
    * @param i_lang          Language ID    
    * @param i_id_entity     Input professional, citizen or user ID
    * @param i_id_tv_image   Input image ID
    * @param i_flg_type      Input media flag type: A-Alert; I-Institutional
    *
    * @return                Success / Fail
    *   
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_blob
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_id_entity   IN NUMBER,
        i_id_tv_image IN NUMBER,
        i_flg_type    IN VARCHAR,
        o_img         OUT BLOB,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function for build http call for JAVA servlet
    *
    * @param i_lang          Language ID    
    * @param i_id_entity     Input professional, citizen or user ID
    * @param i_id_tv_image   Input image ID
    * @param i_flg_type      Input media flag type: A-Alert; I-Institutional
    * @param <table columns>
    *
    * @return                http string
    *   
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_media_thumb
    (
        i_lang           IN NUMBER,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        i_id_tv_image    IN NUMBER,
        i_flg_type       IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function for get video file name
    *
    * @param i_id_tv_image   Input image ID
    * @param i_flg_type      Input media flag type: A-Alert; I-Institutional
    *
    * @return                video file name
    *   
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_video_filename
    (
        i_id_tv_image IN NUMBER,
        i_flg_type    IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This function returns videos for a gallery ID
    *
    * @param i_lang          Language ID    
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_institution Input institution ID
    * @param i_id_software   Input software ID
    * @param i_prof_template_id Input Profile Template ID
    * @param i_id_gallery    Input gallery ID
    * @param i_flg_gallery_type Input gallery type: A-Alert; I-Institutional
    *
    * @return                Success / Fail                
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION format_video_duration
    (
        i_lang     LANGUAGE.id_language%TYPE,
        i_duration NUMBER,
        i_inst     NUMBER,
        i_soft     NUMBER
    ) RETURN VARCHAR2;

    -------------------------------------- FRONTOFFICE FUNCTIONS ----------------------------------

    FUNCTION get_tv_config
    (
        i_lang   IN NUMBER,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_count_video_review
    (
        i_id_product  IN VARCHAR2,
        i_id_entity   IN NUMBER,
        i_id_tv_video IN NUMBER,
        i_flg_type    IN VARCHAR2
    ) RETURN NUMBER;

    /********************************************************************************************
    * This function increments video reviews
    * For repetitive videos (like happy birthday) the begin date is added repeat defined interval
    *
    * @param i_lang          Language ID    
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_tv_video   Input video ID
    * @param i_flg_type      Input flag type: A-Alert; I-Institutional
    *
    * @return                Success / Fail
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION inc_video_reviews
    (
        i_lang        IN NUMBER,
        i_id_product  IN VARCHAR2,
        i_id_entity   IN NUMBER,
        i_id_tv_video IN NUMBER,
        i_flg_type    IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns media IDs and flg_type for galleries/videos with permissions for id_entity
    *
    * @param i_lang          Language ID    
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_tv_video   Input video ID
    * @param i_flg_type      Input flag type: A-Alert; I-Institutional
    *
    * @return                Success / Fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/

    FUNCTION get_galleries
    (
        i_lang           IN NUMBER,
        i_id_product     IN VARCHAR2,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        o_galleries      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns videos for a gallery ID
    *
    * @param i_lang          Language ID    
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_institution Input institution ID
    * @param i_id_software   Input software ID
    * @param i_prof_template_id Input Profile Template ID
    * @param i_id_gallery    Input gallery ID
    * @param i_flg_gallery_type Input gallery type: A-Alert; I-Institutional
    *
    * @return                Success / Fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_videos
    (
        i_lang             IN NUMBER,
        i_id_product       IN VARCHAR2,
        i_id_entity        IN NUMBER,
        i_id_institution   IN NUMBER DEFAULT 0,
        i_id_software      IN NUMBER DEFAULT 0,
        i_id_gallery       IN NUMBER,
        i_flg_gallery_type IN VARCHAR2,
        o_videos           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns new videos for a entity ID
    *
    * @param i_lang          Language ID    
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_institution Input institution ID
    * @param i_id_software   Input software ID
    * @param i_prof_template_id Input Profile Template ID
    *
    * @return                Success / Fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_new_videos
    (
        i_lang           IN NUMBER,
        i_id_product     IN VARCHAR2,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        o_videos         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns the number of new videos for a entity ID
    *
    * @param i_lang          Language ID
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_institution Input institution ID
    * @param i_id_software   Input software ID
    * @param i_prof_template_id Input Profile Template ID
    *
    * @return                Success / Fail
    *
    * @raises
    *
    * @author                Vítor Sá
    * @version               V.2.7.4.5
    * @since                 2018/11/09
    ********************************************************************************************/
    FUNCTION get_new_videos_count
    (
        i_lang           IN NUMBER,
        i_id_product     IN VARCHAR2,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        o_count          OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns videos for a entity ID and for a search expression based on video tags,
    * titles and descriptions
    *
    * @param i_lang          Language ID    
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_institution Input institution ID
    * @param i_id_software   Input software ID
    * @param i_prof_template_id Input Profile Template ID
    * @param i_id_video      Input video ID for search related viedos
    * @param i_flg_type      Input video type (A-Alert; I-Institutional) for search related viedos
    * @param i_search_expr   Input search expression text   
    *
    * @return                Success / Fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_search_videos
    (
        i_lang           IN NUMBER,
        i_id_product     IN VARCHAR2,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        i_search_expr    IN VARCHAR2,
        o_search_result  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns videos with tags related with i_id_video/i_flg_type video
    *
    * @param i_lang          Language ID    
    * @param i_id_product    Input id_product: PFH, PHR or AOL
    * @param i_id_entity     Input id_entity: Professional ID, Citizen ID or User ID
    * @param i_id_institution Input institution ID
    * @param i_id_software   Input software ID
    * @param i_prof_template_id Input Profile Template ID
    * @param i_id_video      Input video ID
    * @param i_flg_type      Input video type (A-Alert; I-Institutional)
    *
    * @return                Success / Fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/04/24
    ********************************************************************************************/
    FUNCTION get_related_videos
    (
        i_lang           IN NUMBER,
        i_id_product     IN VARCHAR2,
        i_id_entity      IN NUMBER,
        i_id_institution IN NUMBER DEFAULT 0,
        i_id_software    IN NUMBER DEFAULT 0,
        i_id_video       IN NUMBER,
        i_flg_type       IN VARCHAR2,
        o_search_result  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /* Last language used */
    g_last_language LANGUAGE.id_language%TYPE;
    /* Last NLS code used */
    g_last_nls_code LANGUAGE.nls_code%TYPE;

END pk_atv_api_ui;
/
