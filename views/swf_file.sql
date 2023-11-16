CREATE OR REPLACE VIEW SWF_FILE AS
SELECT
ID_APPLICATION_FILE   ID_SWF_FILE,
FILE_NAME||'.'||FILE_EXTENSION SWF_FILE_NAME,
CREATE_USER,
CREATE_TIME,
CREATE_INSTITUTION,
UPDATE_USER,
UPDATE_TIME,
UPDATE_INSTITUTION
FROM APPLICATION_FILE;