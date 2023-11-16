BEGIN
  DELETE FROM HANDOFF_PERMISSION_INST H WHERE H.ID_INSTITUTION = 0;

  EXECUTE IMMEDIATE 'ALTER TABLE HANDOFF_PERMISSION_INST DROP CONSTRAINT HOP_PK CASCADE';

  EXECUTE IMMEDIATE 'ALTER TABLE HANDOFF_PERMISSION_INST ADD CONSTRAINT HOP_PK PRIMARY KEY (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_RESP_TYPE) USING INDEX TABLESPACE INDEX_M';

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (39, 0, 38, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (39, 0, 93, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (64, 0, 38, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (64, 0, 93, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (92, 0, 38, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (92, 0, 93, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (110, 0, 180, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (113, 0, 110, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (113, 0, 110, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (113, 0, 180, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (115, 0, 185, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (143, 0, 38, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (143, 0, 93, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (144, 0, 38, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (144, 0, 93, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (145, 0, 38, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (145, 0, 93, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (180, 0, 110, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (180, 0, 110, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (185, 0, 115, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (430, 0, 432, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (430, 0, 433, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (431, 0, 430, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (431, 0, 430, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (431, 0, 432, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (431, 0, 433, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (432, 0, 430, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (432, 0, 430, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (601, 0, 691, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (601, 0, 692, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (606, 0, 695, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (606, 0, 696, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (611, 0, 601, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (611, 0, 601, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (611, 0, 691, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (611, 0, 692, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (616, 0, 606, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (616, 0, 606, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (616, 0, 695, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (616, 0, 696, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (641, 0, 601, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (641, 0, 601, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (641, 0, 691, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (641, 0, 692, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (691, 0, 601, 'Y', 'E');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (691, 0, 601, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (695, 0, 606, 'Y', 'O');

  INSERT INTO HANDOFF_PERMISSION_INST (ID_PROFILE_TEMPLATE_REQ, ID_INSTITUTION, ID_PROFILE_TEMPLATE_DEST, FLG_AVAILABLE, FLG_RESP_TYPE)
  VALUES (695, 0, 606, 'Y', 'E');
END;
/
