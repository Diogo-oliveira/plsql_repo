/*-- Last Change Revision: $Rev: 1102423 $*/
/*-- Last Change by: $Author: paulo.teixeira $*/
/*-- Date of last change: $Date: 2011-09-26 10:37:28 +0100 (seg, 26 set 2011) $*/

CREATE OR REPLACE PACKAGE pk_api_paramedical AS
    /********************************************************************************************
    * insert the dictation report in the plan area
    *
    * @param i_language                 language identifier
    * @param i_professional             professional identifier
    * @param i_institution              institution identifier
    * @param i_software                 software identifier
    * @param i_id_patient               patient identifier
    * @param i_num_rooms                number of rooms
    * @param i_num_bedrooms             number of bedrooms
    * @param i_num_person_room          number of persons per room
    * @param i_flg_wc_type              wc type flag
    * @param i_flg_wc_location          wc location flag
    * @param i_flg_wc_out               wc out flag
    * @param i_flg_water_distrib        water distribution flag
    * @param i_flg_water_origin         water origin flag
    * @param i_flg_conserv              state of conservation flag
    * @param i_flg_owner                ownership flag
    * @param i_flg_hab_type             home type flag
    * @param i_flg_light                has light flag
    * @param i_flg_heat                 has heat flag
    * @param i_arquitect_barrier        arquitect barrier
    * @param i_dt_registry_tstz         record date
    * @param i_flg_hab_location         home location flag
    * @param i_notes                    notes
    * @param i_flg_water_treatment      water treatment flag
    * @param i_flg_garbage_dest         garbage destination flag
    * @param i_ft_wc_type               free text wc type
    * @param i_ft_wc_location           free text wc location
    * @param i_ft_wc_out                free text wc out
    * @param i_ft_water_distrib         free text water distribution
    * @param i_ft_water_origin          free text water origin
    * @param i_ft_conserv               free text state of conservation
    * @param i_ft_owner                 free text ownership
    * @param i_ft_garbage_dest          free text garbage destination
    * @param i_ft_hab_type              free text home type
    * @param i_ft_water_treatment       free text water treatment
    * @param i_ft_light                 free text has light
    * @param i_ft_heat                  free text has heat
    * @param i_ft_hab_location          free text home location
    * @param i_flg_bath                 flag bathtub
    * @param i_ft_bath                  free text bathtub
    * @param i_cancel_notes             cancel notes
    * @param i_id_cancel_reason         cancel_reason identifier   
    * @param i_commit                   do commit 'Y' or 'N'     
    *
    * @return o_id_home     dictation report identifier
    * @return o_error
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2011/08/30
    **********************************************************************************************/
    FUNCTION api_insert_home
    (
        i_language            IN language.id_language%TYPE,
        i_professional        IN professional.id_professional%TYPE,
        i_institution         IN institution.id_institution%TYPE,
        i_software            IN software.id_software%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_num_rooms           IN home.num_rooms%TYPE,
        i_num_bedrooms        IN home.num_bedrooms%TYPE,
        i_num_person_room     IN home.num_person_room%TYPE,
        i_flg_wc_type         IN home.flg_wc_type%TYPE,
        i_flg_wc_location     IN home.flg_wc_location%TYPE,
        i_flg_wc_out          IN home.flg_wc_out%TYPE,
        i_flg_water_distrib   IN home.flg_water_distrib%TYPE,
        i_flg_water_origin    IN home.flg_water_origin%TYPE,
        i_flg_conserv         IN home.flg_conserv%TYPE,
        i_flg_owner           IN home.flg_owner%TYPE,
        i_flg_hab_type        IN home.flg_hab_type%TYPE,
        i_flg_light           IN home.flg_light%TYPE,
        i_flg_heat            IN home.flg_heat%TYPE,
        i_arquitect_barrier   IN home.arquitect_barrier%TYPE,
        i_dt_registry_tstz    IN home.dt_registry_tstz%TYPE,
        i_flg_hab_location    IN home.flg_hab_location%TYPE,
        i_notes               IN home.notes%TYPE,
        i_flg_water_treatment IN home.flg_water_treatment%TYPE,
        i_flg_garbage_dest    IN home.flg_garbage_dest%TYPE,
        i_ft_wc_type          IN home.ft_wc_type%TYPE,
        i_ft_wc_location      IN home.ft_wc_location%TYPE,
        i_ft_wc_out           IN home.ft_wc_out%TYPE,
        i_ft_water_distrib    IN home.ft_water_distrib%TYPE,
        i_ft_water_origin     IN home.ft_water_origin%TYPE,
        i_ft_conserv          IN home.ft_conserv%TYPE,
        i_ft_owner            IN home.ft_owner%TYPE,
        i_ft_garbage_dest     IN home.ft_garbage_dest%TYPE,
        i_ft_hab_type         IN home.ft_hab_type%TYPE,
        i_ft_water_treatment  IN home.ft_water_treatment%TYPE,
        i_ft_light            IN home.ft_light%TYPE,
        i_ft_heat             IN home.ft_heat%TYPE,
        i_ft_hab_location     IN home.ft_hab_location%TYPE,
        i_flg_bath            IN home.flg_bath%TYPE,
        i_ft_bath             IN home.ft_bath%TYPE,
        i_cancel_notes        IN cancel_info_det.notes_cancel_short%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_commit              IN VARCHAR2,
        o_id_home             OUT home.id_home%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    ----------------------------------------------------
    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';
    g_package_name VARCHAR2(32);
    g_error        VARCHAR2(4000 CHAR);
    g_exception EXCEPTION;
END pk_api_paramedical;
/
