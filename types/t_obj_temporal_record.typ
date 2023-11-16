CREATE OR REPLACE TYPE t_obj_temporal_record force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 1/30/2014 08:01:08 AM
-- Purpose :Temporal record model used to track historical changes by a Slowly Changing Dimension (SCD) Type 2 implementation

-- Attributes
    bitemporal_data        t_obj_bitemporal_data,
    has_historical_changes VARCHAR2(1 CHAR),

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_temporal_record
    (
        SELF                     IN OUT NOCOPY t_obj_temporal_record,
        i_val_time_start         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_val_time_end           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_trs_time_start         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_trs_time_end           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_has_historical_changes IN VARCHAR2 DEFAULT 'N'
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t
)
NOT FINAL;
/
CREATE OR REPLACE TYPE BODY t_obj_temporal_record AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_temporal_record
    (
        SELF                     IN OUT NOCOPY t_obj_temporal_record,
        i_val_time_start         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_val_time_end           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_trs_time_start         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_trs_time_end           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_has_historical_changes IN VARCHAR2 DEFAULT 'N'
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.has_historical_changes := CASE i_has_historical_changes
                                           WHEN 'Y' THEN
                                            'Y'
                                           ELSE
                                            'N'
                                       END;
        self.bitemporal_data        := t_obj_bitemporal_data(i_val_time_start => i_val_time_start,
                                                             i_val_time_end   => i_val_time_end,
                                                             i_trs_time_start => i_trs_time_start,
                                                             i_trs_time_end   => i_trs_time_end);
        RETURN;
    END t_obj_temporal_record;

    -- Member functions and procedures
    MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        IF self.bitemporal_data IS NOT NULL
        THEN
            l_json.put('BITEMPORAL_DATA', self.bitemporal_data.to_json(i_lang => i_lang, i_prof => i_prof));
        ELSE
            l_json.put('BITEMPORAL_DATA', json_object_t());
        END IF;
        l_json.put('HAS_HISTORICAL_CHANGES', self.has_historical_changes);
    
        RETURN l_json;
    END to_json;

END;
/
