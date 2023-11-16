CREATE OR REPLACE TYPE t_obj_bitemporal_data force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 1/29/2014 08:20:10 AM
-- Purpose : Bitemporal data combines both Valid and Transaction Time

-- Attributes
    valid_time       t_obj_valid_time,
    transaction_time t_obj_transaction_time,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_bitemporal_data
    (
        SELF               IN OUT NOCOPY t_obj_bitemporal_data,
        i_valid_time       IN t_obj_valid_time DEFAULT NULL,
        i_transaction_time IN t_obj_transaction_time DEFAULT NULL
    ) RETURN SELF AS RESULT,

    CONSTRUCTOR FUNCTION t_obj_bitemporal_data
    (
        SELF             IN OUT NOCOPY t_obj_bitemporal_data,
        i_val_time_start IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_val_time_end   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_trs_time_start IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_trs_time_end   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t
)
;
/
CREATE OR REPLACE TYPE BODY t_obj_bitemporal_data AS

    CONSTRUCTOR FUNCTION t_obj_bitemporal_data
    (
        SELF               IN OUT NOCOPY t_obj_bitemporal_data,
        i_valid_time       IN t_obj_valid_time DEFAULT NULL,
        i_transaction_time IN t_obj_transaction_time DEFAULT NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.valid_time       := i_valid_time;
        self.transaction_time := i_transaction_time;
        RETURN;
    END t_obj_bitemporal_data;

    CONSTRUCTOR FUNCTION t_obj_bitemporal_data
    (
        SELF             IN OUT NOCOPY t_obj_bitemporal_data,
        i_val_time_start IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_val_time_end   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_trs_time_start IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_trs_time_end   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.valid_time       := t_obj_valid_time(i_val_time_start => i_val_time_start,
                                                  i_val_time_end   => i_val_time_end);
        self.transaction_time := t_obj_transaction_time(i_trs_time_start => i_trs_time_start,
                                                        i_trs_time_end   => i_trs_time_end);
    
        RETURN;
    END t_obj_bitemporal_data;

    -- Member functions and procedures
    MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        IF self.valid_time IS NOT NULL
        THEN
            l_json.put('VALID_TIME', self.valid_time.to_json(i_lang => i_lang, i_prof => i_prof));
        ELSE
            l_json.put('VALID_TIME', json_object_t());
        END IF;
    
        IF self.transaction_time IS NOT NULL
        THEN
            l_json.put('TRANSACTION_TIME', self.transaction_time.to_json(i_lang => i_lang, i_prof => i_prof));
        ELSE
            l_json.put('TRANSACTION_TIME', json_object_t());
        END IF;
        RETURN l_json;
    END to_json;

END;
/
