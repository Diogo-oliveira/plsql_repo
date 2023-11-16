/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/
CREATE OR REPLACE PACKAGE pk_clinical_ro IS

    -- Author  : HUMBERTO.CARDOSO
    -- Created : 27/06/2018 15:24:37
    -- Purpose : Read only access to patient data and other clinical data.

    --=========================== Public contants =====================
    -- Because was found some duplicated values on table UNIT_MEASURE for time units,
    -- was decided to use the age_format(s) supported by pk_patient.get_pat_age
    -- The id_unit measure can be converted in age_type using the function get_age_type
    g_age_type_years  CONSTANT VARCHAR2(10 CHAR) := 'YEARS'; -- Age type: Years
    g_age_type_months CONSTANT VARCHAR2(10 CHAR) := 'MONTHS'; -- Age type: Months
    g_age_type_weeks  CONSTANT VARCHAR2(10 CHAR) := 'WEEKS'; -- Age type: Weeks
    g_age_type_days   CONSTANT VARCHAR2(10 CHAR) := 'DAYS'; -- Age type: Days
    g_age_type_hours  CONSTANT VARCHAR2(10 CHAR) := 'HOURS'; -- Age type: Hours
    --g_minutes CONSTANT VARCHAR2(30 CHAR) := 'MINUTES';

    --=========================== Error codes =====================
    --HELP: error_number is a negative integer in the range -20000..-20999 and message is a character string up to 2048 bytes long
    --References: https://docs.oracle.com/cd/B19306_01/appdev.102/b14261/errors.htm
    ex_argument_null EXCEPTION; ----Raised when an mandatory argument is null does not exists.
    PRAGMA EXCEPTION_INIT(ex_argument_null, -20101);

    ex_patient_not_found EXCEPTION; -- When the id_patient is not found.
    PRAGMA EXCEPTION_INIT(ex_patient_not_found, -20701);

    ex_invalid_age_type EXCEPTION; -- When the age_type is not as expected.
    PRAGMA EXCEPTION_INIT(ex_invalid_age_type, -20702);

    ex_invalid_unit_measure EXCEPTION; -- When the id_unit_measure is not as expected.
    PRAGMA EXCEPTION_INIT(ex_invalid_unit_measure, -20703);

    --=========================== Public functions =====================
    /**
    * Loads the patient data related with gender and age.
    *
    * @param i_id_patient          The patient identifier.
    * @param o_gender              Output. The patient gender if any.
    * @param o_dt_birth            Output. The patient birth date if any.
    * @param o_dt_deceased         Output. The patient deceased date if any.
    * @param o_age_free_text       Output. The patient age in years when documented by the user in free text. 
    *
    * @raises                      PRAGMA EXCEPTION_INIT(ex_invalid_unit_measure, -20701); When the id_unit_measure is not as expected.
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
    );

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
    * @raises                    PRAGMA EXCEPTION_INIT(ex_invalid_unit_measure, -20701); When the id_unit_measure is not as expected.
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
    );

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
    );

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
    FUNCTION get_age_type(i_id_unit_measure IN NUMBER) RETURN VARCHAR2;

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
    ) RETURN table_number;

END pk_clinical_ro;
/
