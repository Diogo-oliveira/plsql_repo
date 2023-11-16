/*-- Last Change Revision: $Rev: 2017372 $*/
/*-- Last Change by: $Author: humberto.cardoso $*/
/*-- Date of last change: $Date: 2022-06-27 10:11:03 +0100 (seg, 27 jun 2022) $*/
CREATE OR REPLACE PACKAGE pk_coding_ehr IS

    -- Author  : HUMBERTO.CARDOSO
    -- Created : 30/09/2020 11:22:18
    -- Purpose : EMR-----------------------: Contains all the logic that collect data from EHR to coding software

    -- Type to return an ERH item
    TYPE t_coding_ehr_item IS RECORD(
        id_ehr               NUMBER, -- The PK that identifies the record in this area.
        ehr_description      VARCHAR2(4000), -- Description documented in this area.
        ehr_source           VARCHAR2(100 CHAR), -- The source where the ID_EHR is stored. Format should be: TABLE_NAME.COLUMN_NAME
        id_cnt               NUMBER, -- The content unique identifier that internally identifies the content related with this EHR record.
        cnt_key              VARCHAR2(60 CHAR), --The content unique identifier that replaces ID_CNT when there is more than one ID.
        cnt_source           VARCHAR2(100 CHAR), -- The source where the ID_CNT is stored. Format should be: TABLE_NAME.COLUMN_NAME
        ehr_count            NUMBER, -- The number of ocurrences of the EHR
        ehr_start_date       TIMESTAMP(6) WITH LOCAL TIME ZONE, -- The date of the start of the record/event in the EHR.
        ehr_end_date         TIMESTAMP(6) WITH LOCAL TIME ZONE, -- The date of the start of the record/event in the EHR.
        flg_status           VARCHAR2(30 CHAR), -- The status of the item in the current area.
        code_domain          VARCHAR2(30 CHAR), -- The sys_domain.code_domain value that can be used to evaluate the status.
        id_content           VARCHAR2(30 CHAR), -- The ID_CONTENT to use in mappings.
        termin_source        VARCHAR2(30 CHAR), -- The source of terminolgies in this area: TERMINOLOGY / CODIFICATION.
        id_terminology       VARCHAR2(30 CHAR), -- The identifier of the terminology in this area.
        standard_code        VARCHAR2(30 CHAR), -- The code used to represent this record.
        standard_description VARCHAR2(4000), -- The description of the terminology in this area.
        dt_last_update       TIMESTAMP(6) WITH LOCAL TIME ZONE, -- The date of the last update of the record in this area.
        rank                 NUMBER -- The rank of this item
        );

    -- Table types
    TYPE table_coding_ehr_item IS TABLE OF t_coding_ehr_item;

    -- Sub types
    SUBTYPE t_ehr_area IS VARCHAR2(30 CHAR);

    -- =========================== Constant declarations =====================
    k_key_separator VARCHAR2(1 CHAR) := '|'; -- Used in CNT_KEY and CNT_SOURE when there is more than one ID.

    -- All areas needs to be registred here
    k_main_discharge_diagnosis      CONSTANT t_ehr_area := 'MAIN_DISCHARGE_DIAGNOSES';
    k_secondary_discharge_diagnosis CONSTANT t_ehr_area := 'SECONDARY_DISCHARGE_DIAGNOSES';
    k_imaging_exams                 CONSTANT t_ehr_area := 'IMAGING_EXAMS';
    k_other_exams                   CONSTANT t_ehr_area := 'OTHER_EXAMS';
    k_procedures                    CONSTANT t_ehr_area := 'PROCEDURES';
    k_lab_tests                     CONSTANT t_ehr_area := 'LAB_TESTS';
    k_vital_signs                   CONSTANT t_ehr_area := 'VITAL_SIGNS';
    k_consult_requests              CONSTANT t_ehr_area := 'CONSULT_REQUESTS';
    k_progress_notes                CONSTANT t_ehr_area := 'PROGRESS_NOTES';
    k_supplies                      CONSTANT t_ehr_area := 'SUPPLIES';
    k_disposable_supplies           CONSTANT t_ehr_area := 'DISPOSABLE_SUPPLIES';
    k_durable_supplies              CONSTANT t_ehr_area := 'DURABLE_SUPPLIES';
    k_length_of_stay                CONSTANT t_ehr_area := 'LENGTH_OF_STAY';
    k_los_service                   CONSTANT t_ehr_area := 'LENGTH_OF_STAY_BY_SERVICE';
    k_los_bed                       CONSTANT t_ehr_area := 'LENGTH_OF_STAY_BY_BED';

    /**
    * Get the primary discharge diagnosis according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_main_discharge_diagnoses
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the secondary discharge diagnoses according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_secondary_discharge_diagnoses
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the imaging exams according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_imaging_exams
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the other exams according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_other_exams
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the procedures/interventions according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the lab tests according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_lab_tests
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the vital signs records according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_vital_signs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the consult requests/opinions according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_consult_requests
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the progress notes according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_progress_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the disposable supplies according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.4.0
    * @since                                2022/05/11
    */
    FUNCTION tf_get_disposable_supplies
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the durable / reusable supplies according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.4.0
    * @since                                2022/05/11
    */
    FUNCTION tf_get_durable_supplies
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the length of stay according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The EHR item with ehr_start_date and ehr_end_date for the episode.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.4.0
    * @since                                2022/05/11
    */
    FUNCTION tf_get_length_of_stay
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the length of stay by service according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The EHR item with ehr_start_date and ehr_end_date for each service.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.4.0
    * @since                                2022/05/11
    */
    FUNCTION tf_get_los_by_service
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

    /**
    * Get the length of stay by bed (rrom type - bed type) according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The EHR item with ehr_start_date and ehr_end_date for each room type - bed type.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.4.0
    * @since                                2022/05/11
    */
    FUNCTION tf_get_los_by_bed
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item;

END pk_coding_ehr;
/
