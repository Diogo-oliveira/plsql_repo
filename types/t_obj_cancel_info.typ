
CREATE OR REPLACE TYPE t_obj_cancel_info force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 1/28/2014 15:45:02 AM
-- Purpose : Object type to represent information about the cancellation of a record

-- Attributes
    id_cancel_reason   NUMBER(24),
    cancel_reason_desc VARCHAR2(4000),
    cancel_notes       VARCHAR2(1000 CHAR),

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_cancel_info
    (
        SELF                 IN OUT NOCOPY t_obj_cancel_info,
        i_id_cancel_reason   IN NUMBER DEFAULT NULL,
        i_cancel_reason_desc IN VARCHAR2 DEFAULT NULL,
        i_cancel_notes       IN VARCHAR2 DEFAULT NULL
    ) RETURN SELF AS RESULT,

    CONSTRUCTOR FUNCTION t_obj_cancel_info
    (
        SELF               IN OUT NOCOPY t_obj_cancel_info,
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_cancel_reason IN NUMBER,
        i_cancel_notes     VARCHAR2 DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
;
/

CREATE OR REPLACE TYPE BODY t_obj_cancel_info AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_cancel_info
    (
        SELF                 IN OUT NOCOPY t_obj_cancel_info,
        i_id_cancel_reason   IN NUMBER DEFAULT NULL,
        i_cancel_reason_desc IN VARCHAR2 DEFAULT NULL,
        i_cancel_notes       IN VARCHAR2 DEFAULT NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_cancel_reason   := i_id_cancel_reason;
        self.cancel_reason_desc := i_cancel_reason_desc;
        self.cancel_notes       := i_cancel_notes;
        RETURN;
    END t_obj_cancel_info;

    CONSTRUCTOR FUNCTION t_obj_cancel_info
    (
        SELF               IN OUT NOCOPY t_obj_cancel_info,
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_cancel_reason IN NUMBER,
        i_cancel_notes     VARCHAR2 DEFAULT NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_cancel_reason := i_id_cancel_reason;
        IF i_id_cancel_reason IS NOT NULL
        THEN
            self.cancel_reason_desc := pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_id_cancel_reason => i_id_cancel_reason);
        END IF;
        self.cancel_notes := i_cancel_notes;
        RETURN;
    END t_obj_cancel_info;

    -- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        l_json.put('ID_CANCEL_REASON', self.id_cancel_reason);
        l_json.put('CANCEL_REASON_DESC', self.cancel_reason_desc);
        l_json.put('CANCEL_NOTES', self.cancel_notes);
        RETURN l_json;
    END to_json;
END;
/
