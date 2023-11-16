--CREATE TABLES
create table xmap_target_ext
(
  ID_MAP_TARGET            NUMBER(24),
  ID_MAP_SET               NUMBER(24),
  MAP_TARGET_CODE          VARCHAR2(200 CHAR),
  MAP_TARGET_CREATION_DATE TIMESTAMP(6)
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by newline
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    LRTRIM(
    ID_MAP_TARGET,           
    ID_MAP_SET,              
    MAP_TARGET_CODE,         
    MAP_TARGET_CREATION_DATE char(25) DATE_FORMAT timestamp mask "DD-MM-YYYY HH24:MI:SSXFF"	   
	  )
    )
    location ('xmap_target_file.csv')
  )
REJECT LIMIT 0;


create table xmap_concept_ext
(
  ID_MAP_CONCEPT            NUMBER(24),
  ID_MAP_TARGET             NUMBER(24),
  ID_MAP_CONCEPT_PARENT     NUMBER(24),
  CONCEPT_ORDER             NUMBER(6),
  CONCEPT_TYPE              VARCHAR2(1 CHAR),
  CONCEPT_GROUP             NUMBER(6),
  MAP_CONCEPT_CREATION_DATE TIMESTAMP(6)
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by newline
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    LRTRIM(
    ID_MAP_CONCEPT,           
    ID_MAP_TARGET,            
    ID_MAP_CONCEPT_PARENT,    
	  CONCEPT_ORDER,            
    CONCEPT_TYPE,             
    CONCEPT_GROUP,            
    MAP_CONCEPT_CREATION_DATE char(25) DATE_FORMAT timestamp mask "DD-MM-YYYY HH24:MI:SSXFF"	   
	)
	)
    location ('xmap_concept_file.csv')
  )
REJECT LIMIT 0;

create table xmap_relationship_ext
(
  ID_SOURCE_MAP_CONCEPT   NUMBER(24),
  ID_TARGET_MAP_CONCEPT   NUMBER(24),
  ID_SOURCE_MAP_SET       NUMBER(24),
  ID_TARGET_MAP_SET       NUMBER(24),
  SOURCE_COORDINATED_EXPR VARCHAR2(1000 CHAR),
  TARGET_COORDINATED_EXPR VARCHAR2(1000 CHAR),
  MAP_STATUS              VARCHAR2(2 CHAR),
  MAP_CATEGORY            VARCHAR2(30 CHAR),
  MAP_OPTION              NUMBER(6),
  MAP_PRIORITY            NUMBER(6),
  MAP_QUALITY             NUMBER(24),
  MAP_CREATION_DATE       TIMESTAMP(6),
  MAP_ENABLE_DATE         DATE,
  MAP_DISABLE_DATE		  DATE
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by newline
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
	  LRTRIM(
		ID_SOURCE_MAP_CONCEPT, 
		ID_TARGET_MAP_CONCEPT,  
		ID_SOURCE_MAP_SET,      
		ID_TARGET_MAP_SET,      
		SOURCE_COORDINATED_EXPR,
		TARGET_COORDINATED_EXPR,
		MAP_STATUS,             
		MAP_CATEGORY,           
		MAP_OPTION,             
		MAP_PRIORITY,           
		MAP_QUALITY,            
		MAP_CREATION_DATE  char(25) DATE_FORMAT timestamp mask "DD-MM-YYYY HH24:MI:SSXFF",    
		MAP_ENABLE_DATE    char(25) DATE_FORMAT date mask "DD-MM-YYYY",
		MAP_DISABLE_DATE   char(25) DATE_FORMAT date mask "DD-MM-YYYY"
	)
    )
    location ('xmap_relationship_file.csv')
  )
REJECT LIMIT 0;
