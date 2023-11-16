/*-- Last Change Revision: $Rev: 2028460 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_allergy IS

    /**
     * This function is used to get the list of allergy per patient
     * separated in:
     *
     * 1) Current episode's allergy
     * 2) Previous episode's allergy
     * 3) Allergy unawareness record
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_episode              Episode ID
     * @param    OUT    o_current_allergies    Current allergies cursor
     * @param    OUT    o_previous_allergies   Previous allergies cursor
     * @param    OUT    o_allergy_unawareness  Unawareness allergies cursor
     * @param    IN OUT o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        o_allergies            OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param OUT o_error                 Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-07
     * @author   Thiago Brito
    */
    FUNCTION set_allergy
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_year_begin          IN NUMBER,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_month_begin           Allergy start's month
     * @param IN  i_day_begin             Allergy start's day
     * @param IN  i_year_end              Allergy end year
     * @param IN  i_month_end             Allergy end month
     * @param IN  i_day_end               Allergy end day
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_flg_nature            Allergy Nature
     * @param OUT o_error                 Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.6.0.3.4
     * @since    2010-Nov-24
     * @author   Rui Duarte
    */

    FUNCTION set_allergy
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_year_begin          IN pat_allergy.year_begin%TYPE,
        i_month_begin         IN pat_allergy.month_begin%TYPE,
        i_day_begin           IN pat_allergy.day_begin%TYPE,
        i_year_end            IN pat_allergy.year_end%TYPE,
        i_month_end           IN pat_allergy.month_end%TYPE,
        i_day_end             IN pat_allergy.day_end%TYPE,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        i_flg_nature          IN pat_allergy.flg_nature%TYPE,
        i_dt_pat_allergy      IN pat_allergy.dt_pat_allergy_tstz%TYPE,
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function ables the user to add more than one allergy at a time.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ARRAY/ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            ARRAY/Allergy ID
     * @param IN  i_desc_allergy          ARRAY/If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 ARRAY/Allergy Notes
     * @param IN  i_flg_status            ARRAY/Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              ARRAY/Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           ARRAY/Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          ARRAY/If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            ARRAY/Allergy start's year
     * @param IN  i_id_symptoms           ARRAY/Symptoms' date
     * @param IN  i_id_allergy_severity   ARRAY/Severity of the allergy
     * @param IN  i_flg_edit              ARRAY/Edit flag
     * @param IN  i_desc_edit             ARRAY/Description: reason of the edit action
     * @param OUT o_error                 Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-07
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_array
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN table_number,
        i_id_allergy          IN table_number,
        i_desc_allergy        IN table_varchar,
        i_notes               IN table_varchar,
        i_flg_status          IN table_varchar,
        i_flg_type            IN table_varchar,
        i_flg_aproved         IN table_varchar,
        i_desc_aproved        IN table_varchar,
        i_year_begin          IN table_number,
        i_id_symptoms         IN table_table_number,
        i_id_allergy_severity IN table_number,
        i_flg_edit            IN table_varchar,
        i_desc_edit           IN table_varchar,
        o_id_pat_allergy      OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function ables the user to add allergies according to CCH specifications.
    *
    * @param IN  i_lang                  Language ID
    * @param IN  i_prof                  Professional structure
    * @param IN  i_id_patient            Patient ID
    * @param IN  i_id_episode            Episode ID
    * @param IN  i_id_pat_allergy        ARRAY/ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
    * @param IN  i_date_occur            ARRAY/Allergy's date of occurence
    * @param IN  i_id_allergy            ARRAY/Allergy ID
    * @param IN  i_desc_allergy          ARRAY/Save Allergy as free text
    * @param IN  i_notes                 ARRAY/Allergy Notes
    * @param IN  i_flg_status            ARRAY/Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
    * @param IN  i_flg_type              ARRAY/Allergy Type (A: Allergy; I: Adverse reaction)    
    * @param IN  i_id_symptoms           ARRAY/Symptoms
    * @param IN  i_id_allergy_severity   ARRAY/Severity of the allergy
    * @param IN  i_flg_edit              ARRAY/When allergy is edited indicates the reason why it was edited
    * @param IN  i_edit_reason           ARRAY/Reason of the edit action
    * @param OUT o_error                 Error structure
    *
    * @return   BOOLEAN
    *
    * @version  2.7.1.5
    * @since    2017/10/12
    * @author   Diogo Oliveira
    */

    FUNCTION set_allergy_intf
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_patient                  IN pat_allergy.id_patient%TYPE,
        i_id_episode                  IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy              IN table_number,
        i_date_occur                  IN table_varchar,
        i_id_content_allergy          IN table_varchar,
        i_desc_allergy                IN table_varchar,
        i_notes                       IN table_varchar,
        i_flg_status                  IN table_varchar,
        i_flg_type                    IN table_varchar,
        i_id_content_symptoms         IN table_table_varchar,
        i_id_content_allergy_severity IN table_varchar,
        i_flg_edit                    IN table_varchar,
        i_edit_reason                 IN table_varchar,
        o_id_pat_allergy              OUT table_number,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function cancels a patient allergy
    *
    * @param    IN  i_lang               Language ID
    * @param    IN  i_prof               Professional structure
    * @param    IN  i_id_pat_allergy     Array of ids of patient allergies
    * @param    IN  i_id_cancel_reason   Array of cancel reasons
    * @param    IN  i_cancel_notes       Array of cancel notes
    * @param    IN  o_error              Error structure
    *
    * @return   BOOLEAN
    *
    * @version  2.7.1.5
    * @since    2017/10/12
    * @author   Diogo Oliveira
    */

    FUNCTION cancel_allergy_intf
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat_allergy   IN table_number,
        i_id_cancel_reason IN table_number,
        i_cancel_notes     IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);

END pk_api_allergy;
/
