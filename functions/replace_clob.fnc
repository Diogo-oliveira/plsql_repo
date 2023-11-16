    /** @headcom
    * Public Function.
    * Allow replacement inside data stored in an CLOB structure
    *
    * @param      p_clob             The CLOB data
    * @param      p_what             The search string
    * @param      p_with             The replacement string
    *
    *
    * @return     CLOB
    * @author     Luís Maia
    * @version    0.1
    * @since      2009/01/13
    *
    * NOTES: This function it was built according information from "Project HunBug - Publishing Software Development Notes"
    *
    */
CREATE OR REPLACE FUNCTION replace_clob
(
    p_clob IN CLOB,
    p_what IN VARCHAR2,
    p_with IN VARCHAR2
) RETURN CLOB IS

    c_whatlen CONSTANT PLS_INTEGER := length(p_what);
    c_withlen CONSTANT PLS_INTEGER := length(p_with);

    l_return  CLOB;
    l_segment CLOB;
    l_pos     PLS_INTEGER := 1 - c_withlen;
    l_offset  PLS_INTEGER := 1;

BEGIN

    IF p_what IS NOT NULL
    THEN
        WHILE l_offset < dbms_lob.getlength(p_clob)
        LOOP
            l_segment := dbms_lob.substr(p_clob, 32767, l_offset);
            LOOP
                l_pos := dbms_lob.instr(l_segment, p_what, l_pos + c_withlen);
                EXIT WHEN(nvl(l_pos, 0) = 0) OR(l_pos = 32767 - c_withlen);
                l_segment := to_clob(dbms_lob.substr(l_segment, l_pos - 1) || p_with ||
                                     dbms_lob.substr(l_segment,
                                                     32767 - c_whatlen - l_pos - c_whatlen + 1,
                                                     l_pos + c_whatlen));
            END LOOP;
            l_return := l_return || l_segment;
            l_offset := l_offset + 32767 - c_whatlen;
        END LOOP;
    END IF;

    RETURN(l_return);

END;
/
/
