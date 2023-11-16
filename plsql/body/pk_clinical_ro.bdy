/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/
CREATE OR REPLACE PACKAGE BODY pk_clinical_ro IS

    --=========================== Private constraints =====================

    -- Conversion for years to other values
    g_years_to_years  CONSTANT NUMBER := 1; -- The value of conversion from years to years
    g_years_to_months CONSTANT NUMBER := 12; -- The value of conversion from years to months
    g_years_to_weeks  CONSTANT NUMBER := 52.1775; -- The value of conversion from years to weeks
    g_years_to_days   CONSTANT NUMBER := 365.2425; -- The value of conversion from years to days
    g_years_to_hours  CONSTANT NUMBER := 8765.82; -- The value of conversion from years to hours

    --=========================== Error codes =====================
    --HELP: error_number is a negative integer in the range -20000..-20999 and message is a character string up to 2048 bytes long
    --References: https://docs.oracle.com/cd/B19306_01/appdev.102/b14261/errors.htm
    er_argument_null        CONSTANT NUMBER := -20101; -- Argument null exception.
    er_patient_not_found    CONSTANT NUMBER := -20701; -- When the id_patient is not found.
    er_invalid_age_type     CONSTANT NUMBER := -20702; -- When the id_age_type is not as expected.
    er_invalid_unit_measure CONSTANT NUMBER := -20703; -- When the id_unit_measure is not as expected.

    --==============================PRIVATE FUNCTIONS=================================
    --Support other internal functions / procedures

    /**
    * Using the age_type, gets the age_format to be used in pk_patient.get_pat_age and the value to convert from years.
    *
    * @param i_age_type                   The age type indentifier.
    * @param o_age_format                    The age_format to be used in pk_patient.get_pat_age.
    * @param o_years_to_value_multiplier     The value to convert from years into the value of the age type.
    *
    * @raises                                PRAGMA EXCEPTION_INIT(ex_invalid_age_type, -20702); When the id_age_type is not as expected.
    *
    * @author                                Humberto Cardoso
    * @version                               v2.7.4 
    * @since                                 2018/08/09
    */
    PROCEDURE load_from_age_type
    (
        i_age_type                  IN VARCHAR2,
        o_age_format                OUT VARCHAR2,
        o_years_to_value_multiplier OUT NUMBER
    ) IS
    BEGIN
        -- Convert from AGE_TYPE to the AGE_FORMAT used in pk_patient.get_pat_age
    
        -- Currently the AGE_TYPE and AGE_FORMAT have the same value
        o_age_format := i_age_type;
    
        -- Default ID_AGE_TYPE is years
        CASE nvl(s1 => i_age_type, s2 => g_age_type_years)
            WHEN g_age_type_years THEN
                o_years_to_value_multiplier := g_years_to_years;
            
            WHEN g_age_type_months THEN
                o_years_to_value_multiplier := g_years_to_months;
            
            WHEN g_age_type_weeks THEN
                o_years_to_value_multiplier := g_years_to_weeks;
            
            WHEN g_age_type_days THEN
                o_years_to_value_multiplier := g_years_to_days;
            
            WHEN g_age_type_hours THEN
                o_years_to_value_multiplier := g_years_to_hours;
            
            ELSE
                --Raise exception
                raise_application_error(er_invalid_age_type, 'The age_type ' || i_age_type || ' is not valid!');
        END CASE;
    
    END load_from_age_type;

    --==============================PUBLIC FUNCTIONS=================================

    /**
    * Loads the patient data related with gender and age.
    *
    * @param i_id_patient          The patient identifier.
    * @param o_gender              Output. The patient gender if any.
    * @param o_dt_birth            Output. The patient birth date if any.
    * @param o_dt_deceased         Output. The patient deceased date if any.
    * @param o_age_free_text       Output. The patient age in years when documented by the user in free text. 
    *
    * @raises                      PRAGMA EXCEPTION_INIT(ex_patient_not_found, -20701); When the patient is not found.
    *
    * @author                      Humberto Cardoso
    * @version                     v2.7.3.6 
    * @since                       2018/07/02
    */
    PROCEDURE load_patient_gender_age_data
    (
        i_id_patient    IN patient.id_patient%TYPE,
        o_gender        OUT VARCHAR2,
        o_dt_birth      OUT DATE,
        o_dt_deceased   OUT DATE,
        o_age_free_text OUT NUMBER
    ) IS
    BEGIN
        --Gets the patient data from the table
        --Casts from TIMESTAMP to date
        --Uses dt_birth_tstz if available
        --Because there was found patients with dt_birth not null and age also not null, returns both values
        SELECT p.gender,
               nvl(CAST(p.dt_birth_tstz AS DATE), p.dt_birth) AS dt_birth,
               CAST(p.dt_deceased AS DATE) AS dt_deceased,
               p.age
          INTO o_gender, o_dt_birth, o_dt_deceased, o_age_free_text
          FROM patient p
         WHERE p.id_patient = i_id_patient;
    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(er_patient_not_found, 'The patient ' || to_char(i_id_patient) || ' was not found!');
    END load_patient_gender_age_data;

    /**
    * Loads the patient data related with gender and age.
    * If patient has birth date available, the values are calculated from that birth data until the deceased date or until today.
    *
    * @param i_id_patient        The patient identifier.
    * @param o_gender            Output. The patient gender if any.
    * @param o_years             Output. The calculated patient age in years.
    * @param o_months            Output. The calculated patient age in months.
    * @param o_weeks             Output. The calculated patient age in weeks.
    * @param o_days              Output. The calculated patient age in days.
    * @param o_hours             Output. The calculated patient age in hours.
    * @param o_age_free_text     Output. The patient age in years when documented by the user in free text. 
    *
    * @raises                    PRAGMA EXCEPTION_INIT(ex_patient_not_found, -20701); When the patient is not found.
    *
    * @author                    Humberto Cardoso
    * @version                   v2.7.3.6 
    * @since                     2018/07/02
    */
    PROCEDURE load_patient_gender_age_data
    (
        i_id_patient    IN patient.id_patient%TYPE,
        o_gender        OUT VARCHAR2,
        o_years         OUT NUMBER,
        o_months        OUT NUMBER,
        o_weeks         OUT NUMBER,
        o_days          OUT NUMBER,
        o_hours         OUT NUMBER,
        o_age_free_text OUT NUMBER
    ) IS
        --Private variables
        l_dt_birth    DATE;
        l_dt_deceased DATE;
    
    BEGIN
        --Loads the values from the main function
        load_patient_gender_age_data(i_id_patient    => i_id_patient,
                                     o_gender        => o_gender,
                                     o_dt_birth      => l_dt_birth,
                                     o_dt_deceased   => l_dt_deceased,
                                     o_age_free_text => o_age_free_text);
    
        --Calculates the other values
        --Years
        o_years := pk_patient.get_pat_age(i_lang       => NULL,
                                          i_dt_start   => l_dt_birth,
                                          i_dt_end     => l_dt_deceased,
                                          i_age_format => g_age_type_years);
    
        --Months
        o_months := pk_patient.get_pat_age(i_lang       => NULL,
                                           i_dt_start   => l_dt_birth,
                                           i_dt_end     => l_dt_deceased,
                                           i_age_format => g_age_type_months);
    
        --Weeks
        o_weeks := pk_patient.get_pat_age(i_lang       => NULL,
                                          i_dt_start   => l_dt_birth,
                                          i_dt_end     => l_dt_deceased,
                                          i_age_format => g_age_type_weeks);
    
        --Days
        o_days := pk_patient.get_pat_age(i_lang       => NULL,
                                         i_dt_start   => l_dt_birth,
                                         i_dt_end     => l_dt_deceased,
                                         i_age_format => g_age_type_days);
    
        --Hours
        o_hours := pk_patient.get_pat_age(i_lang       => NULL,
                                          i_dt_start   => l_dt_birth,
                                          i_dt_end     => l_dt_deceased,
                                          i_age_format => g_age_type_hours);
    
    END load_patient_gender_age_data;

    /**
    * Loads the patient data related with gender and age. Age values are returned according to the input age type.
    * If patient has birth date available, the values are calculated from that birth data until the deceased date or until today.
    *
    * @param i_id_patient             The patient identifier.
    * @param i_age_types              The collection of age types identifiers of the values to load into o_age_values.
    * @param o_gender                 Output. The patient gender if any.
    * @param o_age_values             Output. The calculated collection of patient values in the same age_type specified in i_age_types
    * @param o_age_free_text_values   Output. The calculated collection of patient values in the same age_type specified in i_age_types when documented by the user in free text.
    *
    * @raises                         PRAGMA EXCEPTION_INIT(ex_patient_not_found, -20701); When the patient is not found.
    * @raises                         PRAGMA EXCEPTION_INIT(ex_invalid_age_type, -20702); When the age_type is not as expected.
    *
    * @author                         Humberto Cardoso
    * @version                        v2.7.4.0
    * @since                          2018/08/30
    */
    PROCEDURE load_patient_gender_age_data
    (
        i_id_patient           IN patient.id_patient%TYPE,
        i_age_types            IN table_varchar DEFAULT NULL,
        o_gender               OUT VARCHAR2,
        o_age_values           OUT table_number,
        o_age_free_text_values OUT table_number
    ) IS
        --Private variables
        l_dt_birth       DATE;
        l_dt_deceased    DATE;
        l_age_free_text  NUMBER;
        l_age_format     VARCHAR2(30 CHAR);
        l_years_to_value NUMBER;
        l_age_types      table_varchar;
    
    BEGIN
        --Loads the values from the main function
        load_patient_gender_age_data(i_id_patient    => i_id_patient,
                                     o_gender        => o_gender,
                                     o_dt_birth      => l_dt_birth,
                                     o_dt_deceased   => l_dt_deceased,
                                     o_age_free_text => l_age_free_text);
    
        --Initializes the output collections
        o_age_values           := table_number();
        o_age_free_text_values := table_number();
    
        --Inf the input collection is null, insert the default (years)
        IF ((i_age_types IS NULL) OR (i_age_types.count = 0))
        THEN
            l_age_types := table_varchar(g_age_type_years);
        ELSE
            l_age_types := i_age_types;
        END IF;
    
        -- For each age type
        FOR i IN 1 .. l_age_types.count
        LOOP
            -- Expands the collections
            o_age_values.extend();
            o_age_free_text_values.extend();
        
            --Converts the age types
            load_from_age_type(i_age_type                  => l_age_types(i),
                               o_age_format                => l_age_format,
                               o_years_to_value_multiplier => l_years_to_value);
        
            -- If there is a birth data
            IF (l_dt_birth IS NOT NULL)
            THEN
                -- Gets the values sending the correct age_format
                o_age_values(i) := pk_patient.get_pat_age(i_lang       => NULL,
                                                          i_dt_start   => l_dt_birth,
                                                          i_dt_end     => l_dt_deceased,
                                                          i_age_format => l_age_format);
            END IF;
        
            -- If there is a free_text age
            IF (l_age_free_text IS NOT NULL)
            THEN
                -- Gets the values sending the correct age_format
                o_age_free_text_values(i) := trunc(l_age_free_text * l_years_to_value);
            END IF;
        END LOOP;
    
    END load_patient_gender_age_data;

    /**
    * Gets the age_type for this unit measure.
    *
    * @param i_id_unit_measure   The unit measure identifier.
    *
    * @return                    The age_type for this unit measure.
    *
    * @raises                    PRAGMA EXCEPTION_INIT(ex_invalid_format, -20801) if the age format is not correct.
    *
    * @author                    Humberto Cardoso
    * @version                   v2.7.4
    * @since                     2018/08/10
    */
    FUNCTION get_age_type(i_id_unit_measure IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        -- According to the current values on table UNIT_MEASURE
        -- Was found some duplicated values and selected the following ones
    
        -- If null, returns null
        IF i_id_unit_measure IS NULL
        THEN
            RETURN NULL;
        
            -- ID unit measure for years. Possible ids (10373, 27217)
        ELSIF i_id_unit_measure IN (10373, 27217)
        THEN
            RETURN g_age_type_years;
        
            -- ID unit measure for months. Possible ids (1127, 2682)
        ELSIF i_id_unit_measure IN (1127, 2682)
        THEN
            RETURN g_age_type_months;
        
            -- ID unit measure for weeks. Possible ids (10375, 2681)
        ELSIF i_id_unit_measure IN (10375, 2681)
        THEN
            RETURN g_age_type_weeks;
        
            -- ID unit measure for days. Possible ids (1039, 2680, 11412)
        ELSIF i_id_unit_measure IN (1039, 2680, 11412)
        THEN
            RETURN g_age_type_days;
        
            -- ID unit measure for hours. Possible ids (1041, 11411)
        ELSIF i_id_unit_measure IN (1041, 11411)
        THEN
            RETURN g_age_type_hours;
        ELSE
            raise_application_error(er_invalid_unit_measure,
                                    'The id_unit_measure ' || i_id_unit_measure || ' is not valid for age type!');
        END IF;
    END get_age_type;

    /**
    * Gets the list of id_dep_clin_serv related with the current context.
    *
    * @param i_id_institution        The intitution identifier.
    * @param i_id_software           The software identifier.
    * @param i_id_clinical_service   The clinical service identifier.
    *
    * @returns                       The list of id_dep_clin_serv related with the current context.
    *
    * @raises                        Does not raise exceptions. Return null if notting found.
    *
    * @author                        Humberto Cardoso
    * @version                       v2.7.3.6 
    * @since                         2018/07/10
    */
    FUNCTION get_dep_clin_servs
    (
        i_id_institution      IN NUMBER,
        i_id_software         IN NUMBER,
        i_id_clinical_service IN NUMBER
    ) RETURN table_number IS
        -- Private variables
        l_out table_number;
    
    BEGIN
        --Gets the list of dep_clin_servs associated and active with the current id_clinical_service
        SELECT dcs.id_dep_clin_serv BULK COLLECT
          INTO l_out
          FROM dep_clin_serv dcs
         WHERE dcs.id_clinical_service = i_id_clinical_service
           AND dcs.id_department IN (SELECT d.id_department
                                       FROM alert.department d
                                      WHERE d.id_institution = i_id_institution
                                        AND ((d.id_software IS NULL) OR (d.id_software = i_id_software))
                                        AND d.flg_available = pk_alert_constant.g_yes)
           AND dcs.flg_available = pk_alert_constant.g_yes;
    
        --Returns
        RETURN l_out;
    
    END get_dep_clin_servs;

END pk_clinical_ro;
/
