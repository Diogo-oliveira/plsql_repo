CREATE OR REPLACE TYPE t_rec_hpg AS OBJECT
(
-- represents a periodic observation value
    id_health_program           NUMBER(24), -- health program identifier
    health_program_desc         VARCHAR2(1000 CHAR), -- health program description
    health_program_institutions VARCHAR2(1000 CHAR), -- health program institution description

    CONSTRUCTOR FUNCTION t_rec_hpg RETURN SELF AS RESULT,

    MAP MEMBER FUNCTION get_key RETURN VARCHAR2,

    PRAGMA RESTRICT_REFERENCES(get_key, WNDS, WNPS, RNPS, RNDS)
)
/
CREATE OR REPLACE TYPE BODY t_rec_hpg IS

    CONSTRUCTOR FUNCTION t_rec_hpg RETURN SELF AS RESULT IS
    BEGIN
        self.id_health_program           := NULL;
        self.health_program_desc         := NULL;
        self.health_program_institutions := NULL;
        RETURN;
    END;

    MAP MEMBER FUNCTION get_key RETURN VARCHAR2 IS
    BEGIN
        RETURN self.id_health_program;
    END;

END;
/
