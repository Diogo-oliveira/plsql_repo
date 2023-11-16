CREATE OR REPLACE TYPE t_rec_po_param AS OBJECT
(
-- represents a periodic observation parameter
    id_po_param       NUMBER(24), -- periodic observation parameter identifier
    id_inst_owner     NUMBER(24), -- owner institution identifier

    CONSTRUCTOR FUNCTION t_rec_po_param RETURN SELF AS RESULT,

    MAP MEMBER FUNCTION get_key RETURN VARCHAR2,

    PRAGMA RESTRICT_REFERENCES(get_key, WNDS, WNPS, RNPS, RNDS)
)
/
CREATE OR REPLACE TYPE BODY t_rec_po_param IS

    CONSTRUCTOR FUNCTION t_rec_po_param RETURN SELF AS RESULT IS
    BEGIN
        self.id_po_param   := NULL;
        self.id_inst_owner := NULL;
        RETURN;
    END;

    MAP MEMBER FUNCTION get_key RETURN VARCHAR2 IS
    BEGIN
        RETURN to_char(self.id_inst_owner) || lpad(self.id_po_param, 24, '0');
    END;

END;
/
