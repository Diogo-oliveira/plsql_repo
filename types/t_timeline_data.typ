-- CHANGED BY: Pedro Maia
-- CHANGED DATE: 2010-JUL-29
-- CHANGING REASON: ALERT-94678

CREATE OR REPLACE TYPE "T_TIMELINE_DATA" AS OBJECT
(
		BLOCK        VARCHAR2(200),
        upper_axis   VARCHAR2(200),
        lower_axis   VARCHAR2(200),
        dt_begin     VARCHAR2(200),
        dt_end       VARCHAR2(200),
        dt_begin_tzh VARCHAR2(200)
)
/
-- CHANGE END: Pedro Maia 