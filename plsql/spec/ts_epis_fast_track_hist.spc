/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/
CREATE OR REPLACE PACKAGE ts_epis_fast_track_hist
/*
| Generated by or retrieved - DO NOT MODIFY!
| Created On: 2018-07-10 12:34:48
| Created By: ALERT
*/
IS

-- Collection of %ROWTYPE records based on epis_fast_track_hist
TYPE epis_fast_track_hist_tc IS TABLE OF epis_fast_track_hist%ROWTYPE INDEX BY BINARY_INTEGER;
TYPE epis_fast_track_hist_ntt IS TABLE OF epis_fast_track_hist%ROWTYPE;
TYPE epis_fast_track_hist_vat IS VARRAY(100) OF epis_fast_track_hist%ROWTYPE;

-- Column Collection based on column ID_EPIS_FAST_TRACK_HIST
TYPE ID_EPIS_FAST_TRACK_HIST_CC IS TABLE OF epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column ID_EPIS_TRIAGE
TYPE ID_EPIS_TRIAGE_CC IS TABLE OF epis_fast_track_hist.ID_EPIS_TRIAGE%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column ID_FAST_TRACK
TYPE ID_FAST_TRACK_CC IS TABLE OF epis_fast_track_hist.ID_FAST_TRACK%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column FLG_STATUS
TYPE FLG_STATUS_CC IS TABLE OF epis_fast_track_hist.FLG_STATUS%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column ID_PROF_DISABLE
TYPE ID_PROF_DISABLE_CC IS TABLE OF epis_fast_track_hist.ID_PROF_DISABLE%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column DT_DISABLE
TYPE DT_DISABLE_CC IS TABLE OF epis_fast_track_hist.DT_DISABLE%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column ID_FAST_TRACK_DISABLE
TYPE ID_FAST_TRACK_DISABLE_CC IS TABLE OF epis_fast_track_hist.ID_FAST_TRACK_DISABLE%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column NOTES_DISABLE
TYPE NOTES_DISABLE_CC IS TABLE OF epis_fast_track_hist.NOTES_DISABLE%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column CREATE_USER
TYPE CREATE_USER_CC IS TABLE OF epis_fast_track_hist.CREATE_USER%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column CREATE_TIME
TYPE CREATE_TIME_CC IS TABLE OF epis_fast_track_hist.CREATE_TIME%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column CREATE_INSTITUTION
TYPE CREATE_INSTITUTION_CC IS TABLE OF epis_fast_track_hist.CREATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column UPDATE_USER
TYPE UPDATE_USER_CC IS TABLE OF epis_fast_track_hist.UPDATE_USER%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column UPDATE_TIME
TYPE UPDATE_TIME_CC IS TABLE OF epis_fast_track_hist.UPDATE_TIME%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column UPDATE_INSTITUTION
TYPE UPDATE_INSTITUTION_CC IS TABLE OF epis_fast_track_hist.UPDATE_INSTITUTION%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column FLG_TYPE
TYPE FLG_TYPE_CC IS TABLE OF epis_fast_track_hist.FLG_TYPE%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column FLG_ACTIVATION_TYPE
TYPE FLG_ACTIVATION_TYPE_CC IS TABLE OF epis_fast_track_hist.FLG_ACTIVATION_TYPE%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column DT_ENABLE
TYPE DT_ENABLE_CC IS TABLE OF epis_fast_track_hist.DT_ENABLE%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column ID_PROF_ENABLE
TYPE ID_PROF_ENABLE_CC IS TABLE OF epis_fast_track_hist.ID_PROF_ENABLE%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column NOTES_ENABLE
TYPE NOTES_ENABLE_CC IS TABLE OF epis_fast_track_hist.NOTES_ENABLE%TYPE INDEX BY BINARY_INTEGER;
-- Column Collection based on column DT_ACTIVATION
TYPE DT_ACTIVATION_CC IS TABLE OF epis_fast_track_hist.DT_ACTIVATION%TYPE INDEX BY BINARY_INTEGER;

-- Insert one row, providing primary key if present (with rows_out)
PROCEDURE ins
(
ID_EPIS_FAST_TRACK_HIST_in IN epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE,
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
handle_error_in IN BOOLEAN := TRUE,
rows_out OUT table_varchar
);

-- Insert one row, providing primary key if present (without rows_out)
PROCEDURE ins
(
ID_EPIS_FAST_TRACK_HIST_in IN epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE,
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
handle_error_in IN BOOLEAN := TRUE
);

-- Insert a row based on a record
-- Specify whether or not a primary key value should be generated
PROCEDURE ins
(
rec_in          IN epis_fast_track_hist%ROWTYPE,
gen_pky_in      IN BOOLEAN DEFAULT FALSE,
sequence_in     IN VARCHAR2 := NULL,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
);

-- Insert a row based on a record
-- Specify whether or not a primary key value should be generated
PROCEDURE ins
(
rec_in          IN epis_fast_track_hist%ROWTYPE,
gen_pky_in      IN BOOLEAN DEFAULT FALSE,
sequence_in     IN VARCHAR2 := NULL,
handle_error_in IN BOOLEAN := TRUE
);

-- Insert a collection of rows using FORALL; all primary key values
-- must have already been generated, or are handled in triggers
PROCEDURE ins
(
rows_in         IN epis_fast_track_hist_tc,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
);

-- Insert a collection of rows using FORALL; all primary key values
-- must have already been generated, or are handled in triggers
PROCEDURE ins
(
rows_in         IN epis_fast_track_hist_tc,
handle_error_in IN BOOLEAN := TRUE
);

-- Return next primary key value using the named sequence
FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE;

-- Insert one row, generating hidden primary key using a sequence
PROCEDURE ins
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
);

-- Insert one row, generating hidden primary key using a sequence
PROCEDURE ins
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE
);

-- Insert one row, returning primary key generated by sequence
PROCEDURE ins
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
ID_EPIS_FAST_TRACK_HIST_OUT IN OUT epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
);

-- Insert one row, returning primary key generated by sequence
PROCEDURE ins
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
ID_EPIS_FAST_TRACK_HIST_OUT IN OUT epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE
);

-- Insert one row with function, return generated primary key
FUNCTION ins
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
) RETURN epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE;

-- Insert one row with function, return generated primary key
FUNCTION ins
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
-- Pass false if you want errors to propagate out unhandled
handle_error_in IN BOOLEAN := TRUE
) RETURN epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE;

-- Update any/all columns by primary key. If you pass NULL, then
-- the current column value is set to itself. If you need a more
-- selected UPDATE then use one of the onecol procedures below.
PROCEDURE upd
(
ID_EPIS_FAST_TRACK_HIST_in IN epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE,
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_EPIS_TRIAGE_nin IN BOOLEAN := TRUE,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
ID_FAST_TRACK_nin IN BOOLEAN := TRUE,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
FLG_STATUS_nin IN BOOLEAN := TRUE,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
ID_PROF_DISABLE_nin IN BOOLEAN := TRUE,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_nin IN BOOLEAN := TRUE,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_nin IN BOOLEAN := TRUE,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_nin IN BOOLEAN := TRUE,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_TYPE_nin IN BOOLEAN := TRUE,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_nin IN BOOLEAN := TRUE,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
DT_ENABLE_nin IN BOOLEAN := TRUE,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_nin IN BOOLEAN := TRUE,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_nin IN BOOLEAN := TRUE,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
DT_ACTIVATION_nin IN BOOLEAN := TRUE,
handle_error_in        IN BOOLEAN := TRUE,
rows_out               IN OUT table_varchar
);

-- Update any/all columns by primary key. If you pass NULL, then
-- the current column value is set to itself. If you need a more
-- selected UPDATE then use one of the onecol procedures below.
PROCEDURE upd
(
ID_EPIS_FAST_TRACK_HIST_in IN epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE,
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_EPIS_TRIAGE_nin IN BOOLEAN := TRUE,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
ID_FAST_TRACK_nin IN BOOLEAN := TRUE,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
FLG_STATUS_nin IN BOOLEAN := TRUE,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
ID_PROF_DISABLE_nin IN BOOLEAN := TRUE,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_nin IN BOOLEAN := TRUE,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_nin IN BOOLEAN := TRUE,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_nin IN BOOLEAN := TRUE,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_TYPE_nin IN BOOLEAN := TRUE,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_nin IN BOOLEAN := TRUE,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
DT_ENABLE_nin IN BOOLEAN := TRUE,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_nin IN BOOLEAN := TRUE,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_nin IN BOOLEAN := TRUE,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
DT_ACTIVATION_nin IN BOOLEAN := TRUE,
handle_error_in        IN BOOLEAN := TRUE
);

--Update any/all columns by dynamic WHERE
-- If you pass NULL, then the current column value is set to itself
PROCEDURE upd
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_EPIS_TRIAGE_nin IN BOOLEAN := TRUE,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
ID_FAST_TRACK_nin IN BOOLEAN := TRUE,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
FLG_STATUS_nin IN BOOLEAN := TRUE,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
ID_PROF_DISABLE_nin IN BOOLEAN := TRUE,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_nin IN BOOLEAN := TRUE,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_nin IN BOOLEAN := TRUE,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_nin IN BOOLEAN := TRUE,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_TYPE_nin IN BOOLEAN := TRUE,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_nin IN BOOLEAN := TRUE,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
DT_ENABLE_nin IN BOOLEAN := TRUE,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_nin IN BOOLEAN := TRUE,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_nin IN BOOLEAN := TRUE,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
DT_ACTIVATION_nin IN BOOLEAN := TRUE,
where_in               IN VARCHAR2,
handle_error_in        IN BOOLEAN := TRUE,
rows_out               IN OUT table_varchar
);

--Update any/all columns by dynamic WHERE
-- If you pass NULL, then the current column value is set to itself
PROCEDURE upd
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_EPIS_TRIAGE_nin IN BOOLEAN := TRUE,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
ID_FAST_TRACK_nin IN BOOLEAN := TRUE,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
FLG_STATUS_nin IN BOOLEAN := TRUE,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
ID_PROF_DISABLE_nin IN BOOLEAN := TRUE,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_nin IN BOOLEAN := TRUE,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_nin IN BOOLEAN := TRUE,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_nin IN BOOLEAN := TRUE,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_USER_nin IN BOOLEAN := TRUE,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_TIME_nin IN BOOLEAN := TRUE,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
CREATE_INSTITUTION_nin IN BOOLEAN := TRUE,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_USER_nin IN BOOLEAN := TRUE,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_TIME_nin IN BOOLEAN := TRUE,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_nin IN BOOLEAN := TRUE,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_TYPE_nin IN BOOLEAN := TRUE,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_nin IN BOOLEAN := TRUE,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
DT_ENABLE_nin IN BOOLEAN := TRUE,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_nin IN BOOLEAN := TRUE,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_nin IN BOOLEAN := TRUE,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
DT_ACTIVATION_nin IN BOOLEAN := TRUE,
where_in               IN VARCHAR2,
handle_error_in        IN BOOLEAN := TRUE
);

--Update/insert with columns (with rows_out)
PROCEDURE upd_ins
(
ID_EPIS_FAST_TRACK_HIST_in IN epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE,
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
handle_error_in        IN BOOLEAN := TRUE,
rows_out               IN OUT table_varchar
);

--Update/insert with columns (without rows_out)
PROCEDURE upd_ins
(
ID_EPIS_FAST_TRACK_HIST_in IN epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE,
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE DEFAULT NULL,
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE DEFAULT NULL,
FLG_STATUS_in IN EPIS_FAST_TRACK_HIST.FLG_STATUS%TYPE DEFAULT NULL,
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE DEFAULT NULL,
DT_DISABLE_in IN EPIS_FAST_TRACK_HIST.DT_DISABLE%TYPE DEFAULT NULL,
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE DEFAULT NULL,
NOTES_DISABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_DISABLE%TYPE DEFAULT NULL,
CREATE_USER_in IN EPIS_FAST_TRACK_HIST.CREATE_USER%TYPE DEFAULT NULL,
CREATE_TIME_in IN EPIS_FAST_TRACK_HIST.CREATE_TIME%TYPE DEFAULT NULL,
CREATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.CREATE_INSTITUTION%TYPE DEFAULT NULL,
UPDATE_USER_in IN EPIS_FAST_TRACK_HIST.UPDATE_USER%TYPE DEFAULT NULL,
UPDATE_TIME_in IN EPIS_FAST_TRACK_HIST.UPDATE_TIME%TYPE DEFAULT NULL,
UPDATE_INSTITUTION_in IN EPIS_FAST_TRACK_HIST.UPDATE_INSTITUTION%TYPE DEFAULT NULL,
FLG_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_TYPE%TYPE DEFAULT NULL,
FLG_ACTIVATION_TYPE_in IN EPIS_FAST_TRACK_HIST.FLG_ACTIVATION_TYPE%TYPE DEFAULT NULL,
DT_ENABLE_in IN EPIS_FAST_TRACK_HIST.DT_ENABLE%TYPE DEFAULT NULL,
ID_PROF_ENABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_ENABLE%TYPE DEFAULT NULL,
NOTES_ENABLE_in IN EPIS_FAST_TRACK_HIST.NOTES_ENABLE%TYPE DEFAULT NULL,
DT_ACTIVATION_in IN EPIS_FAST_TRACK_HIST.DT_ACTIVATION%TYPE DEFAULT NULL,
handle_error_in        IN BOOLEAN := TRUE
);

--Update record (with rows_out)
PROCEDURE upd
(
rec_in          IN epis_fast_track_hist%ROWTYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        IN OUT table_varchar
);

--Update record (without rows_out)
PROCEDURE upd
(
rec_in          IN epis_fast_track_hist%ROWTYPE,
handle_error_in IN BOOLEAN := TRUE
);

--Update collection (with rows_out)
PROCEDURE upd
(
col_in            IN epis_fast_track_hist_tc,
ignore_if_null_in IN BOOLEAN := TRUE,
handle_error_in   IN BOOLEAN := TRUE,
rows_out          IN OUT table_varchar
);

--Update collection (without rows_out)
PROCEDURE upd
(
col_in            IN epis_fast_track_hist_tc,
ignore_if_null_in IN BOOLEAN := TRUE,
handle_error_in   IN BOOLEAN := TRUE
);

-- Use Native Dynamic SQL increment a single NUMBER column
-- for all rows specified by the dynamic WHERE clause
PROCEDURE increment_onecol
(
colname_in         IN all_tab_columns.column_name%TYPE,
where_in           IN VARCHAR2,
increment_value_in IN NUMBER DEFAULT 1,
handle_error_in    IN BOOLEAN := TRUE,
rows_out           OUT table_varchar
);

--increment column value
PROCEDURE increment_onecol
(
colname_in         IN all_tab_columns.column_name%TYPE,
where_in           IN VARCHAR2,
increment_value_in IN NUMBER DEFAULT 1,
handle_error_in    IN BOOLEAN := TRUE
);

-- Delete one row by primary key
PROCEDURE del
(
ID_EPIS_FAST_TRACK_HIST_in IN epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
);

-- Delete one row by primary key
PROCEDURE del
(
ID_EPIS_FAST_TRACK_HIST_in IN epis_fast_track_hist.ID_EPIS_FAST_TRACK_HIST%TYPE,
handle_error_in IN BOOLEAN := TRUE
);

-- Delete all rows specified by dynamic WHERE clause
PROCEDURE del_by
(
where_clause_in IN VARCHAR2,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
);

-- Delete all rows specified by dynamic WHERE clause
PROCEDURE del_by
(
where_clause_in IN VARCHAR2,
handle_error_in IN BOOLEAN := TRUE
);

-- Delete all rows for this EFTH_EFT_FK foreign key value
PROCEDURE del_EFTH_EFT_FK
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
);

-- Delete all rows for this EFTH_ETRG_FK foreign key value
PROCEDURE del_EFTH_ETRG_FK
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
);

-- Delete all rows for this EFTH_FTD_FK foreign key value
PROCEDURE del_EFTH_FTD_FK
(
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
);

-- Delete all rows for this EFTH_FT_FK foreign key value
PROCEDURE del_EFTH_FT_FK
(
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
);

-- Delete all rows for this EFTH_PROFD_FK foreign key value
PROCEDURE del_EFTH_PROFD_FK
(
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE,
handle_error_in IN BOOLEAN := TRUE,
rows_out        OUT table_varchar
);

-- Delete all rows for this EFTH_EFT_FK foreign key value
PROCEDURE del_EFTH_EFT_FK
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE,
handle_error_in IN BOOLEAN := TRUE
);

-- Delete all rows for this EFTH_ETRG_FK foreign key value
PROCEDURE del_EFTH_ETRG_FK
(
ID_EPIS_TRIAGE_in IN EPIS_FAST_TRACK_HIST.ID_EPIS_TRIAGE%TYPE,
handle_error_in IN BOOLEAN := TRUE
);

-- Delete all rows for this EFTH_FTD_FK foreign key value
PROCEDURE del_EFTH_FTD_FK
(
ID_FAST_TRACK_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK_DISABLE%TYPE,
handle_error_in IN BOOLEAN := TRUE
);

-- Delete all rows for this EFTH_FT_FK foreign key value
PROCEDURE del_EFTH_FT_FK
(
ID_FAST_TRACK_in IN EPIS_FAST_TRACK_HIST.ID_FAST_TRACK%TYPE,
handle_error_in IN BOOLEAN := TRUE
);

-- Delete all rows for this EFTH_PROFD_FK foreign key value
PROCEDURE del_EFTH_PROFD_FK
(
ID_PROF_DISABLE_in IN EPIS_FAST_TRACK_HIST.ID_PROF_DISABLE%TYPE,
handle_error_in IN BOOLEAN := TRUE
);

-- Initialize a record with default values for columns in the table (prc)
PROCEDURE initrec(epis_fast_track_hist_inout IN OUT epis_fast_track_hist%ROWTYPE);

-- Initialize a record with default values for columns in the table (fnc)
FUNCTION initrec RETURN epis_fast_track_hist%ROWTYPE;

-- Get data rowid
FUNCTION get_data_rowid(rows_in IN table_varchar) RETURN epis_fast_track_hist_tc;

-- Get data rowid pragma autonomous transaccion
FUNCTION get_data_rowid_pat(rows_in IN table_varchar) RETURN epis_fast_track_hist_tc;

end ts_epis_fast_track_hist;