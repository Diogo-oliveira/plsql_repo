/*-- Last Change Revision: $Rev: 1989382 $*/
/*-- Last Change by: $Author: humberto.cardoso $*/
/*-- Date of last change: $Date: 2021-05-18 09:34:24 +0100 (ter, 18 mai 2021) $*/
CREATE OR REPLACE PACKAGE BODY pk_cnt_cdr IS

    -- Private constant declarations
    g_yes                    CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no                     CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_flg_status_active      CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_flg_status_inactive    CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_flg_origin_default     CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_id_institution_default CONSTANT NUMBER(24) := 0;
    g_delimiter              CONSTANT VARCHAR2(1 CHAR) := '|';

    --Actions
    g_action_c     CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_action_cvers CONSTANT VARCHAR2(5 CHAR) := 'Cvers';
    g_action_d     CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_action_a     CONSTANT VARCHAR2(1 CHAR) := 'A';

    -- Errors (ALERT_CORE_CNT.PK_CNT_EXCEPTION cannot be used from this schema); ID's are the same
    k_er_id_doesnt_exist CONSTANT NUMBER := -20104; -- Use to raise an ID not exists exception.

    --=============================================================================================
    --Private rule definition --
    --=============================================================================================

    --Ok
    /**
    * Validates and transform the concatenation of CONDITION / CONCEPT internal names.
    * Private procedure. Internal use only.
    *
    * @param io_cc_name                    Test parameter 1 comment
    * @param io_condition_internal_name    Test parameter 2 comment
    * @param io_concept_internal_name      Test parameter 3 comment
    * @param o_error                       Test parameter 4 comment
    *
    * @raises                              Error if conversion not possible.
    *
    * @author                              Humberto.Cardoso
    * @version                             v2.7.0
    * @since                               2017/01/24
    */
    PROCEDURE validate_cc_concatenation
    (
        io_cc_name        IN OUT VARCHAR2,
        io_condition_name IN OUT VARCHAR2,
        io_concept_name   IN OUT VARCHAR2
    ) IS
    
        l_delimiter_position NUMBER;
    
    BEGIN
    
        --If CC_NAME is missing
        IF io_cc_name IS NULL
           AND (io_condition_name IS NOT NULL AND io_concept_name IS NOT NULL)
        THEN
        
            io_cc_name := io_condition_name || g_delimiter || io_concept_name;
        
            --IF the CONDITION and CONCEPT are missing
        ELSIF io_cc_name IS NOT NULL
              AND (io_condition_name IS NULL AND io_concept_name IS NULL)
        THEN
        
            --Transforms the CONDITION|CONCEPT into seperate values
            BEGIN
                l_delimiter_position := instr(str1 => io_cc_name, str2 => g_delimiter);
                io_condition_name    := substr(str1 => io_cc_name, pos => 0, len => (l_delimiter_position - 1));
            
                io_concept_name := substr(str1 => io_cc_name, pos => (l_delimiter_position + 1));
            END;
        
        ELSE
            NULL;
        END IF;
    END;

    --Ok
    /**
    * Gets the concatenation of the CDR_CONDITION INTERNAL_NAME with the CDR_CONCEPT INTERNAL_NAME.
    * Private
    *
    * @param i_id_cdr_definition    The ID_CDR_DEFINITION
    * @param i_position             The relative position of the rule
    *
    * @return                       Returns invalid if the Rule definition does not comply with:
    *                               -There is no more than on CDR_CONDITION with the same internal_name
    *                               -There is no more than one CDR_PARAMETER for the same CDR_DEF_COND
    *
    * @author                Humberto Cardoso
    * @version               v2.7.0
    * @since                 2017/01/24
    */
    PROCEDURE validate_rule_definition
    (
        i_id_cdr_definition IN NUMBER,
        i_position          IN NUMBER,
        o_cc_name           OUT VARCHAR2,
        o_condition         OUT VARCHAR2,
        o_concept           OUT VARCHAR2,
        o_id_cdr_parameter  OUT NUMBER,
        o_id_cdr_def_cond   OUT NUMBER
    ) IS
    
        l_duplicated_conditions VARCHAR(200);
    
    BEGIN
    
        BEGIN
            --Evaluates if there is any duplicated CDR_CONDITION
            SELECT listagg(t.internal_name, g_delimiter) within GROUP(ORDER BY t.internal_name) AS conditions
              INTO l_duplicated_conditions
              FROM (SELECT c.internal_name
                      FROM alert.cdr_def_cond dc
                      JOIN alert.cdr_condition c
                        ON c.id_cdr_condition = dc.id_cdr_condition
                       AND c.flg_available = 'Y'
                     WHERE dc.id_cdr_definition = i_id_cdr_definition
                     GROUP BY c.internal_name
                    HAVING COUNT(dc.id_cdr_def_cond) > 1) t;
        
            --If data was found, returns an error description
            --Returns the error as the result
            IF l_duplicated_conditions IS NOT NULL
            THEN
                raise_application_error(-20001, '#ERROR: CONDITIONS DUPLICATED: ' || l_duplicated_conditions);
            END IF;
        EXCEPTION
            --If no data found can continue
            WHEN no_data_found THEN
                NULL;
        END;
    
        BEGIN
            --Gets the CONDITION INTERNAL_NAME and ID_CDR_DEF for this rule at this relative position
            SELECT cnt.internal_name, cnt.id_cdr_def_cond
              INTO o_condition, o_id_cdr_def_cond
              FROM (SELECT c.internal_name,
                           dc.id_cdr_def_cond,
                           row_number() over(ORDER BY dc.rank, dc.id_cdr_def_cond) AS condition_position
                      FROM alert.cdr_definition d
                      JOIN alert.cdr_def_cond dc
                        ON dc.id_cdr_definition = d.id_cdr_definition
                      JOIN alert.cdr_condition c
                        ON c.id_cdr_condition = dc.id_cdr_condition
                     WHERE d.id_cdr_definition = i_id_cdr_definition
                       AND c.flg_available = g_yes) cnt
             WHERE cnt.condition_position = i_position;
        EXCEPTION
            WHEN no_data_found THEN
                --If no results, there is no conditions or concepts for this position
                --Exist the procedure leaving the variables to null;
                RETURN;
        END;
    
        BEGIN
            SELECT cc.internal_name, p.id_cdr_parameter
              INTO o_concept, o_id_cdr_parameter
              FROM alert.cdr_parameter p
              JOIN alert.cdr_concept cc
                ON cc.id_cdr_concept = p.id_cdr_concept
               AND cc.flg_available = g_yes
             WHERE p.id_cdr_def_cond = o_id_cdr_def_cond;
        EXCEPTION
            WHEN no_data_found THEN
                --If no results, there is no CDR_PARAMETER with a valid CONCEPT
                raise_application_error(k_er_id_doesnt_exist,
                                        '#ERROR: MISSING CONCEPT FOR ID_CDR_DEF_COND: ' || to_char(o_id_cdr_def_cond));
            WHEN too_many_rows THEN
                --If more than one result, there is more than one CDR_PARAMETER with a valid CONCEPT
                raise_application_error(k_er_id_doesnt_exist,
                                        '#ERROR: MORE THAN ONE CONCEPT FOR ID_CDR_DEF_COND: ' ||
                                        to_char(o_id_cdr_def_cond));
        END;
    
        --IF no exceptions, all variables have values
        --Uses the concatenation to fill the o_cc_name variable
        validate_cc_concatenation(io_cc_name        => o_cc_name,
                                  io_condition_name => o_condition,
                                  io_concept_name   => o_concept);
    
    END;

    --=============================================================================================
    --Public rule definition functions --
    --=============================================================================================

    --Ok
    /**
    * Gets the concatenation of the CDR_CONDITION INTERNAL_NAME with the CDR_CONCEPT INTERNAL_NAME
    *
    * @param i_id_cdr_definition    The ID_CDR_DEFINITION
    * @param i_position             The relative position of the rule
    *
    * @return                       Returns invalid if the Rule definition does not comply with:
    *                               -There is no more than on CDR_CONDITION with the same internal_name
    *                               -There is no more than one CDR_PARAMETER for the same CDR_DEF_COND
    *
    * @author                Humberto Cardoso
    * @version               v2.7.0
    * @since                 2017/01/24
    */
    FUNCTION get_rule_cc_name
    (
        i_id_cdr_definition IN NUMBER,
        i_position          IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_cc_name VARCHAR2(200);
    
        --Not used internally, only to the validation rule procedure
        l_condition        VARCHAR2(30);
        l_concept          VARCHAR2(30);
        l_id_cdr_def_cond  NUMBER(24);
        l_id_cdr_parameter NUMBER(24);
    
    BEGIN
        --Uses the main validation function to get the values
        BEGIN
        
            validate_rule_definition(i_id_cdr_definition => i_id_cdr_definition,
                                     i_position          => i_position,
                                     o_cc_name           => l_cc_name,
                                     o_condition         => l_condition,
                                     o_concept           => l_concept,
                                     o_id_cdr_parameter  => l_id_cdr_parameter,
                                     o_id_cdr_def_cond   => l_id_cdr_def_cond);
        
            --IF no exceptions, returns the l_cc_name
            RETURN l_cc_name;
        
        EXCEPTION
            WHEN OTHERS THEN
                --If any exception, returns the message
                RETURN SQLERRM;
        END;
    
    END;

    --OK
    /**
    * Gets the concatenation of the CDR_CONDITION INTERNAL_NAME with CDR_CONCEPT_INTERNAL_NAME for this ID_CDR_PARAMETER
    *
    *@i_id_cdr_parameter     The ID_CDR_PARAMETER
    *
    * @return                If rule invalid, returns #ERROR:%
    *
    * @author                Humberto Cardoso
    * @version               --
    * @since                 2017/01/24
    */
    FUNCTION get_parameter_cc_name(i_id_cdr_parameter IN NUMBER) RETURN VARCHAR2 IS
        l_condition_name VARCHAR(30);
        l_concept_name   VARCHAR(30);
        l_cc_name        VARCHAR(60);
    BEGIN
        BEGIN
            --Gets both internal names
            SELECT cd.internal_name, cc.internal_name
              INTO l_condition_name, l_concept_name
              FROM alert.cdr_parameter p
              JOIN alert.cdr_concept cc
                ON cc.id_cdr_concept = p.id_cdr_concept
              JOIN alert.cdr_def_cond dc
                ON dc.id_cdr_def_cond = p.id_cdr_def_cond
              JOIN alert.cdr_condition cd
                ON cd.id_cdr_condition = dc.id_cdr_condition
             WHERE p.id_cdr_parameter = i_id_cdr_parameter
               AND cc.flg_available = 'Y'
               AND cd.flg_available = 'Y';
        
            --Gets the CC_NAME (standard concatenation of both)
            validate_cc_concatenation(io_cc_name        => l_cc_name,
                                      io_condition_name => l_condition_name,
                                      io_concept_name   => l_concept_name);
        
            --Returns the standard concatenation of both
            RETURN l_cc_name;
        EXCEPTION
            --If no data found can continue
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    END;

    --Ok
    /**
    * Gets the relative position of the ID_CDR_PARAMETER inside the rule.
    * 
    *@i_id_cdr_parameter     The ID_CDR_PARAMETER 
    *
    * @return                If rule invalid, returns -1
    *
    * @author                Humberto Cardoso
    * @version               v2.7.0
    * @since                 2017/01/24
    */
    FUNCTION get_parameter_position(i_id_cdr_parameter IN NUMBER) RETURN NUMBER IS
    
        l_id_cdr_def_cond   NUMBER(24);
        l_id_cdr_definition NUMBER(24);
        l_out_position      NUMBER(24);
    
    BEGIN
    
        BEGIN
            --Using the id_cdr_parameter, gets the id_cdr_def_cond
            SELECT p.id_cdr_def_cond
              INTO l_id_cdr_def_cond
              FROM alert.cdr_parameter p
              JOIN alert.cdr_concept cc
                ON cc.id_cdr_concept = p.id_cdr_concept
             WHERE p.id_cdr_parameter = i_id_cdr_parameter
               AND cc.flg_available = 'Y';
        EXCEPTION
            --If the concept is not available
            WHEN no_data_found THEN
                RETURN - 1;
        END;
    
        BEGIN
            --Using the table def_condition, gets the ID_CDR_DEFINITION
            SELECT dc.id_cdr_definition
              INTO l_id_cdr_definition
              FROM alert.cdr_def_cond dc
              JOIN alert.cdr_condition c
                ON c.id_cdr_condition = dc.id_cdr_condition
             WHERE dc.id_cdr_def_cond = l_id_cdr_def_cond
               AND c.flg_available = 'Y';
        EXCEPTION
            --If the condition is not available
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    
        --Using the rule ID, orders the conditions of the rule by rank, 
        --and retrives the relative position of the current condition
        SELECT position
          INTO l_out_position
          FROM (SELECT row_number() over(ORDER BY dc.rank, dc.id_cdr_def_cond) AS position, dc.id_cdr_def_cond
                  FROM alert.cdr_def_cond dc
                 WHERE dc.id_cdr_definition = l_id_cdr_definition) dcp
         WHERE dcp.id_cdr_def_cond = l_id_cdr_def_cond;
    
        --Returns the position
        RETURN l_out_position;
    
    END;

    --=============================================================================================
    --Public get content  functions --
    --=============================================================================================

    --OK
    /**
    * Returns a concatenation with | of all values in table cdr_inst_par_val for the current id_cdr_inst_param.
    *
    * @param i_id_cdr_inst_param   The ID CDR_INST_PARAM
    *
    * @return                      A concatenation with | of all values for the current id_cdr_inst_param.
    *
    * @author                      Humberto Cardoso
    * @version                     v2.7.0 
    * @since                       2017/01/24
    */
    FUNCTION get_inst_par_values(i_id_cdr_inst_param IN NUMBER) RETURN VARCHAR2 IS
    
        l_output NVARCHAR2(30);
    
    BEGIN
    
        SELECT listagg(ipv.value, g_delimiter) within GROUP(ORDER BY ipv.value)
          INTO l_output
          FROM alert.cdr_inst_par_val ipv
         WHERE ipv.id_cdr_inst_param = i_id_cdr_inst_param;
    
        RETURN l_output;
    
    END;

    --OK
    /**
    * Returns a concatenation with | of all values in table cdr_inst_par_act_val for the current id_cdr_inst_par_action.
    *
    * @param i_id_cdr_inst_param   The ID INSTANCE_PARAMETER_ACTION
    *
    * @return                      A concatenation with | of all values for the current id_cdr_inst_par_action.
    * 
    * @author                      Humberto Cardoso
    * @version                     v2.7.0 
    * @since                       2017/01/24
    */
    FUNCTION get_inst_par_action_values(i_id_cdr_inst_par_action IN NUMBER) RETURN VARCHAR2 IS
    
        l_output NVARCHAR2(30);
    
    BEGIN
    
        SELECT listagg(ipav.value, g_delimiter) within GROUP(ORDER BY ipav.value)
          INTO l_output
          FROM alert.cdr_inst_par_act_val ipav
         WHERE ipav.id_cdr_inst_par_action = i_id_cdr_inst_par_action;
    
        RETURN l_output;
    
    END;

    --=============================================================================================
    --Private Data update--
    --=============================================================================================

    --Ok
    /**
    * Inserts the records into CDR_INST_PAR_ACT_VAL
    * Private method. Raise exception if exists.
    *
    *@Argument               Missing arguments description 
    *
    * @author                Humberto Cardoso
    * @version               v2.7.0
    * @since                 2017/01/24
    */
    PROCEDURE insert_cdr_inst_par_act_vals
    (
        i_id_cdr_inst_par_action   IN NUMBER,
        i_inst_param_action_values IN VARCHAR2
    ) IS
        l_values table_number;
    
    BEGIN
    
        --Data validations
        BEGIN
            IF i_id_cdr_inst_par_action IS NULL
            THEN
                raise_application_error(-20001, 'i_id_cdr_inst_par_action cannot be null.');
                RETURN;
            END IF;
            IF i_inst_param_action_values IS NULL
            THEN
                raise_application_error(-20001, 'i_inst_param_action_values cannot be null.');
                RETURN;
            END IF;
        END;
    
        --Gets the values  delimited by |
        BEGIN
            SELECT to_number(regexp_substr(i_inst_param_action_values, '[^|]+', 1, LEVEL))
              BULK COLLECT
              INTO l_values
              FROM dual
            CONNECT BY regexp_substr(i_inst_param_action_values, '[^|]+', 1, LEVEL) IS NOT NULL;
        END;
    
        --Inserts the record(s) into CDR_INST_PAR_ACT_VAL
        FOR i IN 1 .. l_values.count
        LOOP
            BEGIN
                INSERT INTO alert.cdr_inst_par_act_val
                    (id_cdr_inst_par_action, VALUE)
                VALUES
                    (i_id_cdr_inst_par_action, l_values(i));
                dbms_output.put_line('--CDR_INST_PAR_ACT_VAL with ID,VALUE ''' || to_char(i_id_cdr_inst_par_action) || ',' ||
                                     to_char(l_values(i)) || ''' was inserted.');
            END;
        END LOOP;
    
    END;

    --OK
    /**
    * Inserts the record into CDR_INST_PAR_ACTION and CDR_INST_PAR_ACT_VAL
    * Private method. Raise exception if exists.
    *
    *@Argument               Missing arguments description 
    *
    * @author                Humberto Cardoso
    * @version               --
    * @since                 2017/01/20
    */
    PROCEDURE insert_cdr_inst_par_action
    (
        i_id_cdr_inst_par_action   IN NUMBER,
        i_id_cdr_inst_param        IN NUMBER,
        i_cdr_action               IN VARCHAR2,
        i_flg_first_time           IN VARCHAR2,
        i_id_cdr_message           IN NUMBER,
        i_inst_param_action_values IN VARCHAR2
    ) IS
        l_id_cdr_action NUMBER(24);
    
    BEGIN
    
        --Data validations
        BEGIN
            IF i_id_cdr_inst_par_action IS NULL
            THEN
                raise_application_error(-20001, 'i_id_cdr_inst_par_action cannot be null.');
                RETURN;
            END IF;
            IF i_id_cdr_inst_param IS NULL
            THEN
                raise_application_error(-20001, 'i_id_cdr_inst_param cannot be null.');
                RETURN;
            END IF;
            IF i_cdr_action IS NULL
            THEN
                raise_application_error(-20001, 'i_cdr_action cannot be null.');
                RETURN;
            END IF;
        END;
    
        --Gets the ID_CDR_ACTION
        BEGIN
            SELECT a.id_cdr_action
              INTO l_id_cdr_action
              FROM alert.cdr_action a
             WHERE a.internal_name = i_cdr_action
               AND a.flg_available = 'Y';
        EXCEPTION
            --If the concept is not available
            WHEN no_data_found THEN
                raise_application_error(k_er_id_doesnt_exist,
                                        'i_cdr_action is not a valid INTERNAL_NAME in table CDR_ACTION.');
        END;
    
        --Inserts the record into CDR_INST_PAR_ACTION
        BEGIN
            INSERT INTO alert.cdr_inst_par_action
                (id_cdr_inst_par_action,
                 id_cdr_inst_param,
                 id_cdr_action,
                 message,
                 event_span,
                 id_event_span_umea,
                 flg_first_time,
                 id_cdr_message,
                 id_cdr_doc_instance)
            VALUES
                (i_id_cdr_inst_par_action,
                 i_id_cdr_inst_param,
                 l_id_cdr_action,
                 NULL,
                 NULL,
                 NULL,
                 i_flg_first_time,
                 i_id_cdr_message,
                 NULL);
            dbms_output.put_line('--CDR_INST_PAR_ACTION with ID ''' || to_char(i_id_cdr_inst_par_action) ||
                                 ''' was inserted.');
        END;
    
        --Inserts the record(s) into CDR_INST_PAR_ACT_VAL
        --One record for each value delimited by |
        BEGIN
            IF i_inst_param_action_values IS NOT NULL
            THEN
                insert_cdr_inst_par_act_vals(i_id_cdr_inst_par_action   => i_id_cdr_inst_par_action,
                                             i_inst_param_action_values => i_inst_param_action_values);
            END IF;
        END;
    
    END;

    --OK
    /**
    * Inserts the records into CDR_INST_PAR_VAL
    * Private method. Raise exception if exists.
    *
    *@Argument               Missing arguments description 
    *
    * @author                Humberto Cardoso
    * @version               --
    * @since                 2017/01/20
    */
    PROCEDURE insert_cdr_inst_par_vals
    (
        i_id_cdr_inst_param IN NUMBER,
        i_inst_param_values IN VARCHAR2
    ) IS
        l_values table_varchar2;
    
    BEGIN
    
        --Data validations
        BEGIN
            IF i_id_cdr_inst_param IS NULL
            THEN
                raise_application_error(-20001, 'i_id_cdr_inst_param cannot be null.');
                RETURN;
            END IF;
            IF i_inst_param_values IS NULL
            THEN
                raise_application_error(-20001, 'i_inst_param_values cannot be null.');
                RETURN;
            END IF;
        END;
    
        --Gets the values  delimited by |
        BEGIN
            SELECT regexp_substr(i_inst_param_values, '[^|]+', 1, LEVEL)
              BULK COLLECT
              INTO l_values
              FROM dual
            CONNECT BY regexp_substr(i_inst_param_values, '[^|]+', 1, LEVEL) IS NOT NULL;
        END;
    
        --Inserts the record(s) into CDR_INST_PAR_ACT_VAL
        FOR i IN 1 .. l_values.count
        LOOP
            BEGIN
                INSERT INTO alert.cdr_inst_par_val
                    (id_cdr_inst_param, VALUE)
                VALUES
                    (i_id_cdr_inst_param, l_values(i));
                dbms_output.put_line('--CDR_INST_PAR_VAL with ID,VALUE ''' || to_char(i_id_cdr_inst_param) || ',' ||
                                     to_char(l_values(i)) || ''' was inserted.');
            END;
        
        END LOOP;
    
    END;

    --OK
    /**
    * Inserts the record into CDR_INST_PARAM and CDR_INST_PAR_VAL
    * Private method. Raise exception if exists.
    *
    *@Argument               Missing arguments description 
    *
    * @author                Humberto Cardoso
    * @version               --
    * @since                 2017/01/20
    */
    PROCEDURE insert_cdr_inst_param
    (
        i_id_cdr_inst_param IN NUMBER,
        i_id_cdr_instance   IN NUMBER,
        i_id_cdr_parameter  IN NUMBER,
        i_id_element        IN VARCHAR2,
        i_validity          IN NUMBER,
        i_id_validity_umea  IN NUMBER,
        i_val_min           IN NUMBER,
        i_val_max           IN NUMBER,
        i_id_domain_umea    IN NUMBER,
        i_inst_param_values IN VARCHAR2
    ) IS
    
    BEGIN
        --Data validations
        BEGIN
            IF i_id_cdr_inst_param IS NULL
            THEN
                raise_application_error(-20001, 'i_id_cdr_inst_param cannot be null.');
                RETURN;
            END IF;
            IF i_id_cdr_instance IS NULL
            THEN
                raise_application_error(-20001, 'i_id_cdr_instance cannot be null.');
                RETURN;
            END IF;
            IF i_id_cdr_parameter IS NULL
            THEN
                raise_application_error(-20001, 'i_id_cdr_parameter cannot be null.');
                RETURN;
            END IF;
        END;
    
        --Inserts the record into CDR_INST_PARAM
        BEGIN
            INSERT INTO alert.cdr_inst_param
                (id_cdr_inst_param,
                 id_cdr_instance,
                 id_cdr_parameter,
                 id_element,
                 validity,
                 id_validity_umea,
                 val_min,
                 val_max,
                 id_domain_umea)
            VALUES
                (i_id_cdr_inst_param,
                 i_id_cdr_instance,
                 i_id_cdr_parameter,
                 i_id_element,
                 i_validity,
                 i_id_validity_umea,
                 i_val_min,
                 i_val_max,
                 i_id_domain_umea);
            dbms_output.put_line('--CDR_INST_PARAM with ID ''' || to_char(i_id_cdr_inst_param) || ''' was inserted.');
        END;
    
        --Inserts the record(s) into CDR_INST_PAR_VAL
        --One record for each value delimited by |
        IF i_inst_param_values IS NOT NULL
        THEN
            BEGIN
                insert_cdr_inst_par_vals(i_id_cdr_inst_param => i_id_cdr_inst_param,
                                         i_inst_param_values => i_inst_param_values);
            END;
        END IF;
    
    END;

    --OK
    /**
    * Inserts the record into CDR_INSTANCE.
    * Private method. Raise exception if exists.
    *
    *@Argument               Missing arguments description 
    *
    * @author                Humberto Cardoso
    * @version               --
    * @since                 2017/01/20
    */
    PROCEDURE insert_cdr_instance
    (
        i_id_cdr_definition    IN NUMBER,
        i_id_language          IN NUMBER,
        i_description_instance IN VARCHAR2,
        i_severity             IN VARCHAR2,
        i_id_content           IN VARCHAR2,
        i_id_cdr_instance      IN NUMBER
    ) IS
    
        l_code_description VARCHAR2(200);
        l_id_cdr_severity  NUMBER(24) := NULL;
    
    BEGIN
    
        --Data validations
        BEGIN
            IF i_id_cdr_definition IS NULL
            THEN
                raise_application_error(-20001, 'i_id_cdr_definition cannot be null.');
                RETURN;
            END IF;
            IF i_id_cdr_instance IS NULL
            THEN
                raise_application_error(-20001, 'i_id_cdr_instance cannot be null.');
                RETURN;
            END IF;
        END;
    
        --If i_severity is number, uses that ID
        --Else, gets the severity using the internal name.
        --If the argument is not null
        IF i_severity IS NOT NULL
        THEN
        
            BEGIN
                l_id_cdr_severity := to_number(i_severity);
            
            EXCEPTION
                WHEN value_error THEN
                    --If is not an number, try by INTERNAL_NAME
                    BEGIN
                        SELECT s.id_cdr_severity
                          INTO l_id_cdr_severity
                          FROM alert.cdr_severity s
                         WHERE s.internal_name = i_severity;
                        --AND s.flg_available = g_yes;
                    EXCEPTION
                        WHEN no_data_found THEN
                            raise_application_error(k_er_id_doesnt_exist,
                                                    'CDR_SEVERITY with INTERNAL_NAME: ' || i_severity || ' not found.');
                            RETURN;
                        WHEN too_many_rows THEN
                            raise_application_error(k_er_id_doesnt_exist,
                                                    'CDR_SEVERITY with INTERNAL_NAME: ' || i_severity ||
                                                    ' match more than one ID.');
                            RETURN;
                    END;
            END;
        END IF;
    
        --sets the translation codes
        l_code_description := 'CDR_INSTANCE.CODE_DESCRIPTION.' || to_char(i_id_cdr_instance);
    
        --Inserts the record
        BEGIN
            INSERT INTO alert.cdr_instance
                (id_cdr_instance,
                 id_cdr_definition,
                 code_description,
                 flg_status,
                 flg_origin,
                 id_cdr_severity,
                 id_institution,
                 id_prof_create,
                 id_cancel_info_det,
                 id_content,
                 flg_available)
            VALUES
                (i_id_cdr_instance,
                 i_id_cdr_definition,
                 l_code_description,
                 g_flg_status_active,
                 g_flg_origin_default,
                 l_id_cdr_severity,
                 g_id_institution_default,
                 NULL,
                 NULL,
                 i_id_content,
                 g_yes);
            dbms_output.put_line('--CDR_INSTANCE with ID ''' || i_id_cdr_instance || ''' was inserted.');
        
            --If no error, and the description and language are not empty, inserts the translation
            IF i_id_language IS NOT NULL
               AND i_description_instance IS NOT NULL
            THEN
            
                --inserts the translation
                pk_translation.insert_into_translation(i_lang       => i_id_language,
                                                       i_code_trans => l_code_description,
                                                       i_desc_trans => i_description_instance);
                dbms_output.put_line('--TRANSLATION with CODE ''' || l_code_description || ''' was inserted.');
                --i_id_language is mandatory if there is an i_description_instance
            ELSIF i_description_instance IS NOT NULL
            THEN
                raise_application_error(-20001, 'i_id_language cannot be null if i_description_instance have content.');
            END IF;
        
        END;
    END;

    --OK
    /**
    * Deactivate the record into CDR_INSTANCE.
    * Private method. .
    *
    *@Argument               Missing arguments description 
    *
    * @author                Humberto Cardoso
    * @version               --
    * @since                 2017/01/20
    */
    PROCEDURE deactivate_cdr_instance(i_id_cdr_instance IN NUMBER) IS
    
    BEGIN
    
        --Data validations
        BEGIN
            IF i_id_cdr_instance IS NULL
            THEN
                raise_application_error(-20001, 'i_id_cdr_instance cannot be null.');
                RETURN;
            END IF;
        END;
    
        --Updates the record
        BEGIN
            UPDATE alert.cdr_instance i
               SET i.flg_status = g_flg_status_inactive, i.flg_available = g_no
             WHERE i.id_cdr_instance = i_id_cdr_instance;
            dbms_output.put_line('--CDR_INSTANCE with ID ''' || i_id_cdr_instance || ''' was disabled.');
        END;
    END;

    --OK
    /**
    * Activate the record into CDR_INSTANCE.
    * Private method. .
    *
    *@Argument               Missing arguments description 
    *
    * @author                Humberto Cardoso
    * @version               --
    * @since                 2017/01/20
    */
    PROCEDURE activate_cdr_instance(i_id_cdr_instance IN NUMBER) IS
    
    BEGIN
    
        --Data validations
        BEGIN
            IF i_id_cdr_instance IS NULL
            THEN
                raise_application_error(-20001, 'i_id_cdr_instance cannot be null.');
                RETURN;
            END IF;
        END;
    
        --Updates the record
        BEGIN
            UPDATE alert.cdr_instance i
               SET i.flg_status = g_flg_status_active, i.flg_available = g_yes
             WHERE i.id_cdr_instance = i_id_cdr_instance;
            dbms_output.put_line('--CDR_INSTANCE with ID ''' || i_id_cdr_instance || ''' was activated.');
        END;
    END;

    --OK
    /**
    * Inserts the record(s) into :
    * CDR_INST_PARAM, CDR_INST_PAR_VAL, CDR_INST_PAR_ACTION, CDR_INST_PAR_VAL.
    * Uses the same value arguments as columns in view V_CNT_CDR_INSTANCE_PARAMETER to produce the same results.
    * The arguments in the VIEW i_id_cdr_definition, i_cc_name, i_parameter_position are not expected.
    * The argument i_id_cdr_parameter calculated in validation is expected.
    * Is expected that the CONCEPT_CONDITION if validated before. Needs to stay private.
    * Private method. Raise exception if exists.
    *
    * @param i_test_param1   Test parameter 1 comment
    * @param i_test_param2   Test parameter 2 comment
    * @param i_test_param3   Test parameter 3 comment
    * @param o_test_param4   Test parameter 4 comment
    *
    * @return                Return comment 
    * 
    * @raises                Error if null values
    * @raises                Error if the rule is not valid
    * @raises                Error if position/cc_name are not valid
    *
    * @author                Humberto Cardoso
    * @version               v2.7.0 
    * @since                 2017/01/24
    */
    PROCEDURE create_instance_parameter
    (
        i_id_cdr_instance          IN NUMBER,
        i_id_cdr_parameter         IN NUMBER,
        i_id_element               IN VARCHAR2,
        i_validity                 IN NUMBER,
        i_id_validity_umea         IN NUMBER,
        i_val_min                  IN NUMBER,
        i_val_max                  IN NUMBER,
        i_id_domain_umea           IN NUMBER,
        i_inst_param_values        IN VARCHAR2,
        i_cdr_action               IN VARCHAR2,
        i_flg_first_time           IN VARCHAR2,
        i_id_cdr_message           IN NUMBER,
        i_inst_param_action_values IN VARCHAR2,
        i_id_cdr_inst_param        IN NUMBER,
        i_id_cdr_inst_par_action   IN NUMBER
    ) IS
    BEGIN
    
        --Data validations
        BEGIN
            IF i_id_cdr_instance IS NULL
            THEN
                raise_application_error(-20001, 'i_ID_CDR_INSTANCE cannot be null.');
                RETURN;
            END IF;
            IF i_id_cdr_parameter IS NULL
            THEN
                raise_application_error(-20001, 'i_ID_CDR_PARAMETER cannot be null.');
                RETURN;
            END IF;
        
            --If any CDR_INST_PAR_ACTION is not null, then the ID cannot be null
            IF i_id_cdr_inst_par_action IS NULL
               AND (i_cdr_action IS NOT NULL OR i_flg_first_time IS NOT NULL OR i_id_cdr_message IS NOT NULL OR
               i_inst_param_action_values IS NOT NULL)
            THEN
                raise_application_error(-20001,
                                        'i_ID_CDR_INST_PAR_ACTION cannot be null if CDR_INST_PAR_ACTION arguments has values.');
                RETURN;
            END IF;
        END;
    
        --Insert the record(s)
        BEGIN
            --Insert the record into cdr_inst_param
        
            insert_cdr_inst_param(i_id_cdr_inst_param => i_id_cdr_inst_param,
                                  i_id_cdr_instance   => i_id_cdr_instance,
                                  i_id_cdr_parameter  => i_id_cdr_parameter,
                                  i_id_element        => i_id_element,
                                  i_validity          => i_validity,
                                  i_id_validity_umea  => i_id_validity_umea,
                                  i_val_min           => i_val_min,
                                  i_val_max           => i_val_max,
                                  i_id_domain_umea    => i_id_domain_umea,
                                  i_inst_param_values => i_inst_param_values);
        
            --if there is inst_par_act
            --The procedure validated if the arguments are no null
            IF i_id_cdr_inst_par_action IS NOT NULL
            THEN
                insert_cdr_inst_par_action(i_id_cdr_inst_par_action   => i_id_cdr_inst_par_action,
                                           i_id_cdr_inst_param        => i_id_cdr_inst_param,
                                           i_cdr_action               => i_cdr_action,
                                           i_flg_first_time           => i_flg_first_time,
                                           i_id_cdr_message           => i_id_cdr_message,
                                           i_inst_param_action_values => i_inst_param_action_values);
            END IF;
        
        END;
    END;

    --=============================================================================================
    --Public content data manipulation--
    --=============================================================================================

    --OK
    /**
    * Inserts the record(s) into :
    * CDR_INSTANCE, CDR_INST_PARAM, CDR_INST_PAR_VAL, CDR_INST_PAR_ACTION, CDR_INST_PAR_VAL.
    * Uses the same value arguments as columns in view V_CNT_CDR_INSTANCE to produce the same results.
    * Needs documentation improvements
    *
    * @param i_test_param1   Test parameter 1 comment
    * @param i_test_param2   Test parameter 2 comment
    * @param i_test_param3   Test parameter 3 comment
    * @param o_test_param4   Test parameter 4 comment
    *
    * @raises                Error if null values
    * @raises                Error if the rule is not valid
    * @raises                Error if position/cc_name are not valid
    *
    * @author                Humberto Cardoso
    * @version               v2.7.0 
    * @since                 2017/01/24
    */
    PROCEDURE set_instance
    (
        i_action                     IN VARCHAR2,
        i_id_cdr_definition          IN NUMBER,
        i_id_language                IN NUMBER DEFAULT NULL,
        i_description_instance       IN VARCHAR2 DEFAULT NULL,
        i_severity                   IN VARCHAR2 DEFAULT NULL,
        i_id_content                 IN VARCHAR2 DEFAULT NULL,
        i_cc_name_1                  IN VARCHAR2 DEFAULT NULL,
        i_id_element_1               IN VARCHAR2 DEFAULT NULL,
        i_validity_1                 IN NUMBER DEFAULT NULL,
        i_id_validity_umea_1         IN NUMBER DEFAULT NULL,
        i_val_min_1                  IN NUMBER DEFAULT NULL,
        i_val_max_1                  IN NUMBER DEFAULT NULL,
        i_id_domain_umea_1           IN NUMBER DEFAULT NULL,
        i_cdr_action_1               IN VARCHAR2 DEFAULT NULL,
        i_inst_param_values_1        IN VARCHAR2 DEFAULT NULL,
        i_flg_first_time_1           IN VARCHAR2 DEFAULT NULL,
        i_id_cdr_message_1           IN NUMBER DEFAULT NULL,
        i_inst_param_action_values_1 IN VARCHAR2 DEFAULT NULL,
        i_cc_name_2                  IN VARCHAR2 DEFAULT NULL,
        i_id_element_2               IN VARCHAR2 DEFAULT NULL,
        i_validity_2                 IN NUMBER DEFAULT NULL,
        i_id_validity_umea_2         IN NUMBER DEFAULT NULL,
        i_val_min_2                  IN NUMBER DEFAULT NULL,
        i_val_max_2                  IN NUMBER DEFAULT NULL,
        i_id_domain_umea_2           IN NUMBER DEFAULT NULL,
        i_cdr_action_2               IN VARCHAR2 DEFAULT NULL,
        i_inst_param_values_2        IN VARCHAR2 DEFAULT NULL,
        i_flg_first_time_2           IN VARCHAR2 DEFAULT NULL,
        i_id_cdr_message_2           IN NUMBER DEFAULT NULL,
        i_inst_param_action_values_2 IN VARCHAR2 DEFAULT NULL,
        i_cc_name_3                  IN VARCHAR2 DEFAULT NULL,
        i_id_element_3               IN VARCHAR2 DEFAULT NULL,
        i_validity_3                 IN NUMBER DEFAULT NULL,
        i_id_validity_umea_3         IN NUMBER DEFAULT NULL,
        i_val_min_3                  IN NUMBER DEFAULT NULL,
        i_val_max_3                  IN NUMBER DEFAULT NULL,
        i_id_domain_umea_3           IN NUMBER DEFAULT NULL,
        i_cdr_action_3               IN VARCHAR2 DEFAULT NULL,
        i_inst_param_values_3        IN VARCHAR2 DEFAULT NULL,
        i_flg_first_time_3           IN VARCHAR2 DEFAULT NULL,
        i_id_cdr_message_3           IN NUMBER DEFAULT NULL,
        i_inst_param_action_values_3 IN VARCHAR2 DEFAULT NULL,
        i_cc_name_4                  IN VARCHAR2 DEFAULT NULL,
        i_id_element_4               IN VARCHAR2 DEFAULT NULL,
        i_validity_4                 IN NUMBER DEFAULT NULL,
        i_id_validity_umea_4         IN NUMBER DEFAULT NULL,
        i_val_min_4                  IN NUMBER DEFAULT NULL,
        i_val_max_4                  IN NUMBER DEFAULT NULL,
        i_id_domain_umea_4           IN NUMBER DEFAULT NULL,
        i_cdr_action_4               IN VARCHAR2 DEFAULT NULL,
        i_inst_param_values_4        IN VARCHAR2 DEFAULT NULL,
        i_flg_first_time_4           IN VARCHAR2 DEFAULT NULL,
        i_id_cdr_message_4           IN NUMBER DEFAULT NULL,
        i_inst_param_action_values_4 IN VARCHAR2 DEFAULT NULL,
        i_id_cdr_instance            IN NUMBER,
        i_id_cdr_inst_param_1        IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_par_action_1   IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_param_2        IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_par_action_2   IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_param_3        IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_par_action_3   IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_param_4        IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_par_action_4   IN NUMBER DEFAULT NULL
    ) IS
    
        --Parameters for each rule position
        l_cc_name_in       table_varchar2 := table_varchar2(NULL, NULL, NULL, NULL);
        l_cc_name_val      table_varchar2 := table_varchar2();
        l_id_cdr_parameter table_number := table_number();
        l_position         NUMBER(2);
    
        --Not used internally, only to the validation rule procedure
        l_condition       VARCHAR2(30);
        l_concept         VARCHAR2(30);
        l_id_cdr_def_cond NUMBER(24);
    
    BEGIN
    
        --Data validations 1 (Actions A or D)
        BEGIN
            IF i_action IS NULL
            THEN
                raise_application_error(-20001, 'i_ACTION cannot be null.');
                RETURN;
            END IF;
            IF i_id_cdr_definition IS NULL
            THEN
                raise_application_error(-20001, 'i_ID_CDR_DEFINITION cannot be null.');
                RETURN;
            END IF;
            IF i_id_cdr_instance IS NULL
            THEN
                raise_application_error(-20001, 'i_ID_CDR_INSTANCE cannot be null.');
                RETURN;
            END IF;
        END;
    
        --Validates actions A and D
        IF i_action = g_action_d
        THEN
            deactivate_cdr_instance(i_id_cdr_instance => i_id_cdr_instance);
            RETURN;
        ELSIF i_action = g_action_a
        THEN
            activate_cdr_instance(i_id_cdr_instance => i_id_cdr_instance);
            RETURN;
        END IF;
    
        --Stores the input names for parameters
        l_cc_name_in(1) := i_cc_name_1;
        l_cc_name_in(2) := i_cc_name_2;
        l_cc_name_in(3) := i_cc_name_3;
        l_cc_name_in(4) := i_cc_name_4;
    
        --Data validations 2 (Action C or Cvers)
        BEGIN
        
            --Is expected the same number of parameters than the rule
            --Gets the CONDITION_CONCEPT for each position in rule;
            --The id_cdr_parameter is also returned.
        
            --For each CONDITION_CONCEPT by position, can:
            --Be a valid rule for use this procedure (all positions have a single concept and valid condition)
            ----The calculated CC_NAME is equal to the input argument for this position
            ----The calculated CC_NAME is NOT equal to the input argument for this position
            ----Both are null, meaning that the position is to ignore
            --Be an invalid rule for this procedure (there is an error at at least onde of the positions)
        
            --Gets the expected CONDITION|CONCEPT for each parameter
            BEGIN
                FOR l_position IN 1 .. 4
                LOOP
                
                    BEGIN
                    
                        l_cc_name_val.extend;
                        l_id_cdr_parameter.extend;
                        validate_rule_definition(i_id_cdr_definition => i_id_cdr_definition,
                                                 i_position          => l_position,
                                                 o_cc_name           => l_cc_name_val(l_position),
                                                 o_condition         => l_condition,
                                                 o_concept           => l_concept,
                                                 o_id_cdr_parameter  => l_id_cdr_parameter(l_position),
                                                 o_id_cdr_def_cond   => l_id_cdr_def_cond);
                    
                    EXCEPTION
                        WHEN OTHERS THEN
                            raise_application_error(k_er_id_doesnt_exist,
                                                    'An error was encountered with PARAMETER_' || l_position ||
                                                    ' of ID_CDR_INSTANCE: ' || i_id_cdr_instance || '. -ERROR- ' ||
                                                    SQLERRM);
                    END;
                END LOOP;
            END;
        
            --Validates each position
            --Gets the expected CONDITION|CONCEPT for each parameter
            BEGIN
                FOR l_position IN 1 .. 4
                LOOP
                
                    IF ((l_cc_name_val(l_position) IS NOT NULL AND l_cc_name_in(l_position) IS NULL))
                       OR ((l_cc_name_val(l_position) IS NULL AND l_cc_name_in(l_position) IS NOT NULL))
                       OR (l_cc_name_val(l_position) != l_cc_name_in(l_position))
                    THEN
                    
                        raise_application_error(-20001,
                                                'An error was encountered with PARAMETER_' || l_position ||
                                                ' of ID_CDR_INSTANCE: ' || i_id_cdr_instance || '. FOUND CC_NAME: ''' ||
                                                l_cc_name_in(l_position) || ''' when is expected: ''' ||
                                                l_cc_name_val(l_position) || '''.');
                    END IF;
                END LOOP;
            END;
        END;
    
        --According to actions
        IF i_action = g_action_c
        THEN
        
            insert_cdr_instance(i_id_cdr_definition    => i_id_cdr_definition,
                                i_id_language          => i_id_language,
                                i_description_instance => i_description_instance,
                                i_severity             => i_severity,
                                i_id_content           => i_id_content,
                                i_id_cdr_instance      => i_id_cdr_instance);
        
            --Got to creation of instance parameters
            GOTO create_inst_parameters;
        
        ELSIF i_action = g_action_cvers
        THEN
        
            BEGIN
                --for Versioning DUP_VAL_ON_INDEX error is ignored
                insert_cdr_instance(i_id_cdr_definition    => i_id_cdr_definition,
                                    i_id_language          => i_id_language,
                                    i_description_instance => i_description_instance,
                                    i_severity             => i_severity,
                                    i_id_content           => i_id_content,
                                    i_id_cdr_instance      => i_id_cdr_instance);
            
                --Got to creation of instance parameters
                GOTO create_inst_parameters;
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                    dbms_output.put_line('--CDR_INSTANCE with ID ''' || i_id_cdr_instance || ''' already exists!');
                
                    --If exists, ends execution
                    RETURN;
            END;
        
        ELSE
            raise_application_error(k_er_id_doesnt_exist, 'i_ACTION is not valid.');
        END IF;
    
        <<create_inst_parameters>>
        BEGIN
            --Position 1
            IF i_cc_name_1 IS NOT NULL
            THEN
                create_instance_parameter(i_id_cdr_instance          => i_id_cdr_instance,
                                          i_id_cdr_parameter         => l_id_cdr_parameter(1),
                                          i_id_element               => i_id_element_1,
                                          i_validity                 => i_validity_1,
                                          i_id_validity_umea         => i_id_validity_umea_1,
                                          i_val_min                  => i_val_min_1,
                                          i_val_max                  => i_val_max_1,
                                          i_id_domain_umea           => i_id_domain_umea_1,
                                          i_inst_param_values        => i_inst_param_values_1,
                                          i_cdr_action               => i_cdr_action_1,
                                          i_flg_first_time           => i_flg_first_time_1,
                                          i_id_cdr_message           => i_id_cdr_message_1,
                                          i_inst_param_action_values => i_inst_param_action_values_1,
                                          i_id_cdr_inst_param        => i_id_cdr_inst_param_1,
                                          i_id_cdr_inst_par_action   => i_id_cdr_inst_par_action_1);
            END IF;
            --Position 2
            IF i_cc_name_2 IS NOT NULL
            THEN
                create_instance_parameter(i_id_cdr_instance          => i_id_cdr_instance,
                                          i_id_cdr_parameter         => l_id_cdr_parameter(2),
                                          i_id_element               => i_id_element_2,
                                          i_validity                 => i_validity_2,
                                          i_id_validity_umea         => i_id_validity_umea_2,
                                          i_val_min                  => i_val_min_2,
                                          i_val_max                  => i_val_max_2,
                                          i_id_domain_umea           => i_id_domain_umea_2,
                                          i_inst_param_values        => i_inst_param_values_2,
                                          i_cdr_action               => i_cdr_action_2,
                                          i_flg_first_time           => i_flg_first_time_2,
                                          i_id_cdr_message           => i_id_cdr_message_2,
                                          i_inst_param_action_values => i_inst_param_action_values_2,
                                          i_id_cdr_inst_param        => i_id_cdr_inst_param_2,
                                          i_id_cdr_inst_par_action   => i_id_cdr_inst_par_action_2);
            END IF;
            --Position 3
            IF i_cc_name_3 IS NOT NULL
            THEN
                create_instance_parameter(i_id_cdr_instance          => i_id_cdr_instance,
                                          i_id_cdr_parameter         => l_id_cdr_parameter(3),
                                          i_id_element               => i_id_element_3,
                                          i_validity                 => i_validity_3,
                                          i_id_validity_umea         => i_id_validity_umea_3,
                                          i_val_min                  => i_val_min_3,
                                          i_val_max                  => i_val_max_3,
                                          i_id_domain_umea           => i_id_domain_umea_3,
                                          i_inst_param_values        => i_inst_param_values_3,
                                          i_cdr_action               => i_cdr_action_3,
                                          i_flg_first_time           => i_flg_first_time_3,
                                          i_id_cdr_message           => i_id_cdr_message_3,
                                          i_inst_param_action_values => i_inst_param_action_values_3,
                                          i_id_cdr_inst_param        => i_id_cdr_inst_param_3,
                                          i_id_cdr_inst_par_action   => i_id_cdr_inst_par_action_3);
            END IF;
            --Position 4
            IF i_cc_name_4 IS NOT NULL
            THEN
                create_instance_parameter(i_id_cdr_instance          => i_id_cdr_instance,
                                          i_id_cdr_parameter         => l_id_cdr_parameter(4),
                                          i_id_element               => i_id_element_4,
                                          i_validity                 => i_validity_4,
                                          i_id_validity_umea         => i_id_validity_umea_4,
                                          i_val_min                  => i_val_min_4,
                                          i_val_max                  => i_val_max_4,
                                          i_id_domain_umea           => i_id_domain_umea_4,
                                          i_inst_param_values        => i_inst_param_values_4,
                                          i_cdr_action               => i_cdr_action_4,
                                          i_flg_first_time           => i_flg_first_time_4,
                                          i_id_cdr_message           => i_id_cdr_message_4,
                                          i_inst_param_action_values => i_inst_param_action_values_4,
                                          i_id_cdr_inst_param        => i_id_cdr_inst_param_4,
                                          i_id_cdr_inst_par_action   => i_id_cdr_inst_par_action_4);
            END IF;
        END;
    
    END;

BEGIN
    -- Initialization
    --  <Statement>;
    NULL;
END pk_cnt_cdr;
/
