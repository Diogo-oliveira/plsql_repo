CREATE OR REPLACE TYPE t_obj_transaction_time force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 1/29/2014 08:15:21 AM
-- Purpose : Transaction time is the time period during which a fact stored in the database is considered to be true

-- Attributes
    dt_trs_time_start TIMESTAMP WITH LOCAL TIME ZONE,
    dt_trs_time_end   TIMESTAMP WITH LOCAL TIME ZONE,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_transaction_time
    (
        SELF             IN OUT NOCOPY t_obj_transaction_time,
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
CREATE OR REPLACE TYPE BODY t_obj_transaction_time AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_transaction_time
    (
        SELF             IN OUT NOCOPY t_obj_transaction_time,
        i_trs_time_start IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_trs_time_end   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.dt_trs_time_start := i_trs_time_start;
        self.dt_trs_time_end   := i_trs_time_end;
        RETURN;
    END t_obj_transaction_time;

    -- Member functions and procedures
    MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        l_json.put('DT_TRS_TIME_START',
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => self.dt_trs_time_start, i_prof => i_prof));
        l_json.put('DT_TRS_TIME_END',
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => self.dt_trs_time_end, i_prof => i_prof));
        RETURN l_json;
    END to_json;

END;
/
