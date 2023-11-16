CREATE OR REPLACE TYPE t_rec_sets AS OBJECT
(
-- represents a periodic observation value
    ID_TASK_TYPE NUMBER(24), -- id task type
    SETS_ID           VARCHAR2(1000 CHAR), -- set identifier
    SETS_DESC         VARCHAR2(1000 CHAR), -- set description
    SETS_INSTITUTIONS VARCHAR2(1000 CHAR), -- set institution description

    CONSTRUCTOR FUNCTION t_rec_sets RETURN SELF AS RESULT,

    MAP MEMBER FUNCTION get_key RETURN VARCHAR2,

    PRAGMA RESTRICT_REFERENCES(get_key, WNDS, WNPS, RNPS, RNDS)
)
/
CREATE OR REPLACE TYPE BODY t_rec_sets IS

    CONSTRUCTOR FUNCTION t_rec_sets RETURN SELF AS RESULT IS
    BEGIN
        self.ID_TASK_TYPE      := NULL;      
        self.SETS_ID           := NULL;
        self.SETS_DESC         := NULL;
        self.SETS_INSTITUTIONS := NULL;
        RETURN;
    END;

    MAP MEMBER FUNCTION get_key RETURN VARCHAR2 IS
    BEGIN
        RETURN self.SETS_ID;
    END;

END;
/